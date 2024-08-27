-- Variables
local QBOX = exports.qbx_core

if not lib then return end

local fuelSynced = false
local inGasStation = false
local inBlacklisted = false
local holdingnozzle = false
local Stations = {}

local props = {
	`prop_gas_pump_1d`,
	`prop_gas_pump_1a`,
	`prop_gas_pump_1b`,
	`prop_gas_pump_1c`,
	`prop_vintage_pump`,
	`prop_gas_pump_old2`,
	`prop_gas_pump_old3`,
}

local refueling = false
local GasStationBlips = {} -- Used for managing blips on the client, so labels can be updated.
local RefuelingType = nil
local PlayerInSpecialFuelZone = false
local Rope = nil
local CachedFuelPrice = nil

-- Functions

function GetClosestPump(coords, isElectric)
	if isElectric then
		local electricPump = nil
		electricPump = GetClosestObjectOfType(coords.x, coords.y, coords.z, 3.0, joaat('electric_charger'), true, true,
			true)
		local pumpCoords = GetEntityCoords(electricPump)

		return pumpCoords, electricPump
	else
		local pump = nil
		local pumpCoords
		for i = 1, #props, 1 do
			local currentPumpModel = props[i]
			pump = GetClosestObjectOfType(coords.x, coords.y, coords.z, 3.0, joaat(currentPumpModel), true, true, true)
			pumpCoords = GetEntityCoords(pump)
			if pump ~= 0 then break end
		end
		return pumpCoords, pump
	end
end

local function FetchStationInfo(info)
	if not Config.PlayerOwnedGasStationsEnabled then
		ReserveLevels = 1000
		StationFuelPrice = Config.CostMultiplier
		return
	end

	local result = lib.callback.await('cdn-fuel:server:fetchinfo', false, CurrentLocation)
	if result then
		for _, v in pairs(result) do
			-- Reserves --
			if info == 'all' or info == 'reserves' then
				Currentreserveamount = math.floor(v.fuel)
				ReserveLevels = tonumber(Currentreserveamount)
				if Currentreserveamount < Config.MaxFuelReserves then
					ReservesNotBuyable = false
				else
					ReservesNotBuyable = true
				end
				if Config.UnlimitedFuel then
					ReservesNotBuyable = true
				end
			end
			-- Fuel Price --
			if info == 'all' or info == 'fuelprice' then
				StationFuelPrice = v.fuelprice
			end
			-- Balance --
			if info == 'all' or info == 'balance' then
				StationBalance = v.balance
				if info == 'balance' then
					return StationBalance
				end
			end
			----------------
		end
	else
		return
	end
end
exports(FetchStationInfo, FetchStationInfo)

local function HandleFuelConsumption(vehicle)
	if not DecorExistOn(vehicle, Config.FuelDecor) then
		SetFuel(vehicle, math.random(200, 800) / 10)
	elseif not fuelSynced then
		SetFuel(vehicle, GetFuel(vehicle))
		fuelSynced = true
	end

	if IsVehicleEngineOn(vehicle) then
		SetFuel(vehicle,
			GetVehicleFuelLevel(vehicle) -
			Config.FuelUsage[Round(GetVehicleCurrentRpm(vehicle), 1)] * (Config.Classes[GetVehicleClass(vehicle)] or 1.0) /
			10)
	end
end

local function CanAfford(price, purchasetype)
	local purchasetype = purchasetype
	if purchasetype == 'bank' then
		Money = QBX.PlayerData.money.bank
	elseif purchasetype == 'cash' then
		Money = QBX.PlayerData.money.cash
	end

	if Money < price then
		return false
	else
		return true
	end
end

function FetchCurrentLocation()
	return CurrentLocation
end

function IsInGasStation()
	return inGasStation
end

-- Thread Stuff --

if Config.ShowNearestGasStationOnly then
	RegisterNetEvent('cdn-fuel:client:updatestationlabels', function(location, newLabel)
		if not location then return end
		if not newLabel then return end
		Config.GasStations[location].label = newLabel
	end)

	CreateThread(function()
		if Config.PlayerOwnedGasStationsEnabled then
			TriggerServerEvent('cdn-fuel:server:updatelocationlabels')
		end
		Wait(1000)
		local currentGasBlip = 0
		while Config.ShowNearestGasStationOnly do
			local coords = GetEntityCoords(cache.ped)
			local closest = 1000
			local closestCoords
			local closestLocation
			local location = 0
			local label = 'Gas Station' -- Prevent nil just in case, set default name.
			for _, ourCoords in pairs(Config.GasStations) do
				location = location + 1
				if not (location > #Config.GasStations) then -- Make sure we are not going over the amount of locations available.
					local pedCoords = Config.GasStations[location].pedcoords
					local gasStationCoords = vector3(pedCoords.x, pedCoords.y, pedCoords.z)
					local dstcheck = #(coords - gasStationCoords)
					if dstcheck < closest then
						closest = dstcheck
						closestCoords = gasStationCoords
						closestLocation = location
						label = Config.GasStations[closestLocation].label
					end
				else
					break
				end
			end
			if DoesBlipExist(currentGasBlip) then
				RemoveBlip(currentGasBlip)
			end
			currentGasBlip = CreateBlip(closestCoords, label)
			Wait(10000)
		end
	end)
else
	RegisterNetEvent('cdn-fuel:client:updatestationlabels', function(location, newLabel)
		if not location then return end
		if not newLabel then return end
		Config.GasStations[location].label = newLabel
		local pedCoords = Config.GasStations[location].pedcoords
		local coords = vector3(pedCoords.x, pedCoords.y, pedCoords.z)
		RemoveBlip(GasStationBlips[location])
		GasStationBlips[location] = CreateBlip(coords, Config.GasStations[location].label)
	end)

	CreateThread(function()
		TriggerServerEvent('cdn-fuel:server:updatelocationlabels')
		Wait(1000)
		local gasStationCoords
		for i = 1, #Config.GasStations, 1 do
			local location = i
			local pedCoords = Config.GasStations[location].pedcoords
			gasStationCoords = vector3(pedCoords.x, pedCoords.y, pedCoords.z)
			GasStationBlips[location] = CreateBlip(gasStationCoords, Config.GasStations[location].label)
		end
	end)
end


-- stations zones
for station_id = 1, #Config.GasStations, 1 do
	Stations[station_id] = lib.zones.poly({
		points = Config.GasStations[station_id].zones,
		thickness = Config.GasStations[station_id].thickness,
		debug = Config.PolyDebug,
	})

	Stations[station_id].inside = function()
		inGasStation = true
		CurrentLocation = station_id
		if Config.PlayerOwnedGasStationsEnabled then
			TriggerEvent('cdn-fuel:stations:updatelocation', station_id)
		end
	end

	Stations[station_id].onExit = function()
		TriggerEvent('cdn-fuel:stations:updatelocation', nil)
		inGasStation = false
	end
end

CreateThread(function()
	DecorRegister(Config.FuelDecor, 1)
	while true do
		Wait(1000)
		local vehicle = cache.vehicle
		-- Blacklist Electric Vehicles, if you disables the Config.ElectricVehicleCharging or put the vehicle in Config.NoFuelUsage!
		if vehicle then
			inBlacklisted = IsVehicleBlacklisted(vehicle)
			if not inBlacklisted and cache.seat == -1 then
				HandleFuelConsumption(vehicle)
			end
		else
			if fuelSynced then fuelSynced = false end
			if inBlacklisted then inBlacklisted = false end
			Wait(500)
		end
	end
end)

-- if LocalPlayer.state.isLoggedIn then
-- 	exports.ox_inventory:displayMetadata({ cdn_fuel = 'Fuel' })
-- end

-- RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
-- 	if GetResourceState('ox_inventory'):match('start') then
-- 		exports.ox_inventory:displayMetadata({ cdn_fuel = 'Fuel' })
-- 	end
-- end)

RegisterNetEvent('cdn-fuel:client:OpenContextMenu', function(total, fuelamounttotal, purchasetype)
	local option = {
		{
			title = Lang:t('menu_purchase_station_confirm_header'),
			description = Lang:t('menu_refuel_accept'),
			icon = 'fas fa-check-circle',
			event = 'cdn-fuel:client:RefuelVehicle',
			args = {
				fuelamounttotal = fuelamounttotal,
				purchasetype = purchasetype,
			}
		},
	}

	lib.registerContext({
		id = 'cdn_confirmation_menu',
		title = Lang:t('menu_purchase_station_header_1') .. math.ceil(total) .. Lang:t('menu_purchase_station_header_2'),
		options = option
	})
	lib.showContext('cdn_confirmation_menu')
end)

RegisterNetEvent('cdn-fuel:client:RefuelMenu', function(type)
	if not type then type = nil end
	TriggerEvent('cdn-fuel:client:SendMenuToServer', type)
end)

RegisterNetEvent('cdn-fuel:client:grabnozzle', function()
	if Config.PlayerOwnedGasStationsEnabled then
		ShutOff = false

		local result = lib.callback.await('cdn-fuel:server:checkshutoff', false, CurrentLocation)
		if result == true then
			QBOX:Notify(Lang:t('emergency_shutoff_active'), 'error', 7500)
			ShutOff = true
			return
		else
			ShutOff = false
		end
	else
		ShutOff = false
	end

	if not ShutOff then
		local ped = cache.ped
		if holdingnozzle then return end
		lib.playAnim(ped, 'anim@am_hold_up@male', 'shoplift_high', 2.0, 8.0, -1, 50, 0, 0, 0, 0)
		TriggerServerEvent('InteractSound_SV:PlayOnSource', 'pickupnozzle', 0.4) -- needs to de replaced with native audio
		Wait(300)
		StopAnimTask(ped, 'anim@am_hold_up@male', 'shoplift_high', 1.0)
		fuelNozzle = CreateObject(joaat('prop_cs_fuel_nozle'), 1.0, 1.0, 1.0, true, true, false)
		local lefthand = GetPedBoneIndex(ped, 18905)
		AttachEntityToEntity(fuelNozzle, ped, lefthand, 0.13, 0.04, 0.01, -42.0, -115.0, -63.42, 0, 1, 0, 1, 0, 1)
		local grabbednozzlecoords = GetEntityCoords(ped)
		if Config.PumpHose then
			local pumpCoords, pump = GetClosestPump(grabbednozzlecoords)
			-- Load Rope Textures
			RopeLoadTextures()
			while not RopeAreTexturesLoaded() do
				Wait(0)
				RopeLoadTextures()
			end
			-- Wait for Pump to exist.
			while not pump do
				Wait(0)
			end
			Rope = AddRope(pumpCoords.x, pumpCoords.y, pumpCoords.z, 0.0, 0.0, 0.0, 3.0, Config.RopeType.fuel,
				8.0 --[[ DO NOT SET THIS TO 0.0!!! GAME WILL CRASH!]], 0.0, 1.0, false, false, false, 1.0, true)
			while not Rope do
				Wait(0)
			end
			ActivatePhysics(Rope)
			Wait(100)
			local nozzlePos = GetEntityCoords(fuelNozzle)
			nozzlePos = GetOffsetFromEntityInWorldCoords(fuelNozzle, 0.0, -0.033, -0.195)
			local PumpHeightAdd = nil
			if PumpHeightAdd == nil then
				PumpHeightAdd = 2.1
			end
			AttachEntitiesToRope(Rope, pump, fuelNozzle, pumpCoords.x, pumpCoords.y, pumpCoords.z + PumpHeightAdd,
				nozzlePos.x, nozzlePos.y, nozzlePos.z, length, false, false, nil, nil)
		end
		holdingnozzle = true
		CreateThread(function()
			while holdingnozzle do
				local currentcoords = GetEntityCoords(ped)
				local dist = #(grabbednozzlecoords - currentcoords)
				if dist > 7.5 then
					holdingnozzle = false
					DeleteObject(fuelNozzle)
					QBOX:Notify(Lang:t('nozzle_cannot_reach'), 'error')
					if Config.PumpHose == true then
						RopeUnloadTextures()
						DeleteRope(Rope)
					end
				end
				Wait(2500)
			end
		end)
	end
end)

RegisterNetEvent('cdn-fuel:client:returnnozzle', function()
	if Config.ElectricVehicleCharging then
		if IsHoldingElectricNozzle() then
			SetElectricNozzle('putback')
		else
			holdingnozzle = false
			TargetCreated = false
			TriggerServerEvent('InteractSound_SV:PlayOnSource', 'putbacknozzle', 0.4)
			Wait(250)
			DeleteObject(fuelNozzle)
		end
	else
		holdingnozzle = false
		TargetCreated = false
		TriggerServerEvent('InteractSound_SV:PlayOnSource', 'putbacknozzle', 0.4)
		Wait(250)
		DeleteObject(fuelNozzle)
	end
	if Config.PumpHose then
		RopeUnloadTextures()
		DeleteRope(Rope)
	end
end)

RegisterNetEvent('cdn-fuel:client:FinalMenu', function(purchasetype)
	if RefuelingType == nil then
		FetchStationInfo('all')
		Wait(Config.WaitTime)
		if Config.PlayerOwnedGasStationsEnabled and not Config.UnlimitedFuel then
			if ReserveLevels < 1 then
				QBOX:Notify(Lang:t('station_no_fuel'), 'error', 7500)
				return
			end
		end
		if Config.PlayerOwnedGasStationsEnabled then
			FuelPrice = (1 * StationFuelPrice)
		end
	end
	local money = nil
	if purchasetype == 'bank' then
		money = QBX.PlayerData.money.bank
	elseif purchasetype == 'cash' then
		money = QBX.PlayerData.money.cash
	end

	if not Config.PlayerOwnedGasStationsEnabled then
		FuelPrice = (1 * Config.CostMultiplier)
	end

	local vehicle = GetClosestVehicle()
	local curfuel = GetFuel(vehicle)
	local finalfuel
	if curfuel < 10 then finalfuel = string.sub(curfuel, 1, 1) else finalfuel = string.sub(curfuel, 1, 2) end
	local maxfuel = (100 - finalfuel - 1)
	if Config.AirAndWaterVehicleFueling['enabled'] then
		local vehClass = GetVehicleClass(vehicle)
		if vehClass == 14 then
			FuelPrice = Config.AirAndWaterVehicleFueling['water_fuel_price']
			RefuelingType = 'special'
		elseif vehClass == 15 or vehClass == 16 then
			FuelPrice = Config.AirAndWaterVehicleFueling['air_fuel_price']
			RefuelingType = 'special'
		end
	end

	-- Police Discount Math --
	if Config.EmergencyServicesDiscount['enabled'] == true and (Config.EmergencyServicesDiscount['emergency_vehicles_only'] == false or (Config.EmergencyServicesDiscount['emergency_vehicles_only'] == true and GetVehicleClass(vehicle) == 18)) then
		local discountedJobs = Config.EmergencyServicesDiscount['job']
		local plyJob = QBX.PlayerData.job.name
		local shouldRecieveDiscount = false
		if type(discountedJobs) == 'table' then
			for i = 1, #discountedJobs, 1 do
				if plyJob == discountedJobs[i] then
					shouldRecieveDiscount = true
					break
				end
			end
		elseif plyJob == discountedJobs then
			shouldRecieveDiscount = true
		end
		if shouldRecieveDiscount == true and not QBX.PlayerData.job.onduty and Config.EmergencyServicesDiscount['on_duty_only'] then
			QBOX:Notify(Lang:t('you_are_discount_eligible'), 'primary', 7500)
			shouldRecieveDiscount = false
		end
		if shouldRecieveDiscount then
			local discount = Config.EmergencyServicesDiscount['discount']
			if discount > 100 then
				discount = 100
			else
				if discount <= 0 then discount = 0 end
			end
			if discount ~= 0 then
				if discount == 100 then
					CachedFuelPrice = FuelPrice
					FuelPrice = 0
				else
					discount = discount / 100
					CachedFuelPrice = FuelPrice
					FuelPrice = (FuelPrice) - (FuelPrice * discount)
				end
			else
				return
			end
		end
	end

	local wholetankcost = (tonumber(FuelPrice) * maxfuel)
	local wholetankcostwithtax = math.ceil(tonumber(FuelPrice) * maxfuel + GlobalTax(wholetankcost))
	if Config.Ox.Input then
		if Config.PlayerOwnedGasStationsEnabled and not Config.UnlimitedFuel and not RefuelingType == 'special' then
			if ReserveLevels < maxfuel then
				local wholetankcost = (tonumber(FuelPrice) * ReserveLevels)
				local wholetankcostwithtax = math.ceil(tonumber(FuelPrice) * ReserveLevels + GlobalTax(wholetankcost))
				fuel = lib.inputDialog('Gas Station', {
					{ type = 'input',  label = 'Gasoline Price',                                  default = '$' .. FuelPrice .. ' Per Liter', disabled = true },
					{ type = 'input',  label = 'Current Fuel',                                    default = finalfuel .. ' Per Liter',        disabled = true },
					{ type = 'input',  label = 'Required Full Tank',                              default = maxfuel .. 'Per Liter',           disabled = true },
					{ type = 'input',  label = 'Stations Available Gasoline',                     default = ReserveLevels,                    disabled = true },
					{ type = 'slider', label = 'Full Tank Cost: $' .. wholetankcostwithtax .. '', default = ReserveLevels,                    min = 0,        max = ReserveLevels },
				})
				if not fuel then
					return
				end
				fuelAmount = tonumber(fuel[5])
			else
				fuel = lib.inputDialog('Gas Station', {
					{ type = 'input',  label = 'Gasoline Price',                                  default = '$' .. FuelPrice .. ' Per Liter', disabled = true },
					{ type = 'input',  label = 'Current Fuel',                                    default = finalfuel .. ' Per Liter',        disabled = true },
					{ type = 'input',  label = 'Required For A Full Tank',                        default = maxfuel,                          disabled = true },
					{ type = 'slider', label = 'Full Tank Cost: $' .. wholetankcostwithtax .. '', default = maxfuel,                          min = 0,        max = maxfuel },
				})
				if not fuel then
					return
				end
				fuelAmount = tonumber(fuel[4])
			end
		else
			fuel = lib.inputDialog('Gas Station', {
				{ type = 'input',  label = 'Gasoline Price',                                  default = '$' .. FuelPrice .. ' Per Liter', disabled = true },
				{ type = 'input',  label = 'Current Fuel',                                    default = finalfuel .. ' Per Liter',        disabled = true },
				{ type = 'input',  label = 'Required For A Full Tank',                        default = maxfuel,                          disabled = true },
				{ type = 'slider', label = 'Full Tank Cost: $' .. wholetankcostwithtax .. '', default = maxfuel,                          min = 0,        max = maxfuel },
			})
			if not fuel then
				return
			end
			fuelAmount = tonumber(fuel[4])
		end
		if fuel then
			if not fuelAmount then
				return
			end
			if not holdingnozzle and RefuelingType ~= 'special' then
				QBOX:Notify(Lang:t('no_nozzle'), 'error')
				return
			end
			if Config.PlayerOwnedGasStationsEnabled and not Config.UnlimitedFuel and not RefuelingType == 'special' then
				if tonumber(fuelAmount) > tonumber(ReserveLevels) then
					QBOX:Notify(Lang:t('station_not_enough_fuel'), 'error')
					return
				end
			end
			if (fuelAmount + finalfuel) >= 100 then
				QBOX:Notify(Lang:t('tank_cannot_fit'), 'error')
			else
				if GlobalTax(fuelAmount * FuelPrice) + (fuelAmount * FuelPrice) <= money then
					TriggerServerEvent('cdn-fuel:server:OpenMenu', fuelAmount, inGasStation, false, purchasetype,
						tonumber(FuelPrice))
				else
					QBOX:Notify(Lang:t('not_enough_money'), 'error', 7500)
				end
			end
		else
			return
		end
	end
end)

RegisterNetEvent('cdn-fuel:client:SendMenuToServer', function(type)
	local vehicle = GetClosestVehicle()
	local NotElectric = false
	if Config.ElectricVehicleCharging then
		local isElectric = GetCurrentVehicleType(vehicle)
		if isElectric == 'electricvehicle' then
			QBOX:Notify(Lang:t('need_electric_charger'), 'error', 7500)
			return
		end
		NotElectric = true
	else
		NotElectric = true
	end
	Wait(50)
	if NotElectric then
		local CurFuel = GetVehicleFuelLevel(vehicle)
		local playercashamount = QBX.PlayerData.money['cash']
		if not holdingnozzle and not type == 'special' then return end
		local header
		if type == 'special' then
			header = 'Refuel Vehicle'
			RefuelingType = 'special'
		else
			header = Config.GasStations[CurrentLocation].label
		end
		if CurFuel < 95 then
			if Config.Ox.Menu then
				lib.registerContext({
					id = 'cdn_fueld_main_menu',
					title = 'Gas Station',
					icon = 'fas fa-gas-pump',
					options = {
						{
							title = Lang:t('menu_header_cash'),
							description = Lang:t('menu_pay_with_cash') .. playercashamount,
							icon = 'fas fa-usd',
							onSelect = function()
								TriggerEvent('cdn-fuel:client:FinalMenu', 'cash')
							end,
						},
						{
							title = Lang:t('menu_header_bank'),
							description = Lang:t('menu_pay_with_bank'),
							icon = 'fas fa-credit-card',
							onSelect = function()
								TriggerEvent('cdn-fuel:client:FinalMenu', 'bank')
							end,
						},
					},
				})
				lib.showContext('cdn_fueld_main_menu')
			end
		else
			QBOX:Notify(Lang:t('tank_already_full'), 'error')
		end
	else
		QBOX:Notify(Lang:t('need_electric_charger'), 'error', 7500)
	end
end)

RegisterNetEvent('cdn-fuel:client:RefuelVehicle', function(data)
	if RefuelingType == nil then
		FetchStationInfo('all')
		Wait(100)
	end
	local purchasetype, amount, fuelamount
	if not Config.RenewedPhonePayment then
		purchasetype = data.purchasetype
	elseif data.purchasetype == 'cash' then
		purchasetype = 'cash'
	else
		purchasetype = RefuelPurchaseType
	end

	if not Config.RenewedPhonePayment then
		amount = data.fuelamounttotal
	elseif data.purchasetype == 'cash' then
		amount = data.fuelamounttotal
	elseif not data.fuelamounttotal then
		amount = RefuelPossibleAmount
	end

	if Config.PlayerOwnedGasStationsEnabled and RefuelingType == nil then
		FuelPrice = (1 * StationFuelPrice)
	else
		FuelPrice = (1 * Config.CostMultiplier)
	end
	if not holdingnozzle and RefuelingType == nil then return end
	amount = tonumber(amount)
	if amount < 1 then return end
	if amount < 10 then fuelamount = string.sub(amount, 1, 1) else fuelamount = string.sub(amount, 1, 2) end
	local vehicle = GetClosestVehicle()
	if Config.AirAndWaterVehicleFueling['enabled'] then
		local vehClass = GetVehicleClass(vehicle)
		if vehClass == 14 then
			FuelPrice = Config.AirAndWaterVehicleFueling['water_fuel_price']
		elseif vehClass == 15 or vehClass == 16 then
			FuelPrice = Config.AirAndWaterVehicleFueling['air_fuel_price']
		end
	end
	-- Police Discount Math --
	if Config.EmergencyServicesDiscount['enabled'] == true and (Config.EmergencyServicesDiscount['emergency_vehicles_only'] == false or (Config.EmergencyServicesDiscount['emergency_vehicles_only'] == true and GetVehicleClass(vehicle) == 18)) then
		local discountedJobs = Config.EmergencyServicesDiscount['job']
		local plyJob = QBX.PlayerData.job.name
		local shouldRecieveDiscount = false
		if type(discountedJobs) == 'table' then
			for i = 1, #discountedJobs, 1 do
				if plyJob == discountedJobs[i] then
					shouldRecieveDiscount = true
					break
				end
			end
		elseif plyJob == discountedJobs then
			shouldRecieveDiscount = true
		end
		if shouldRecieveDiscount == true and not QBX.PlayerData.job.onduty and Config.EmergencyServicesDiscount['on_duty_only'] then
			QBOX:Notify(Lang:t('you_are_discount_eligible'), 'primary', 7500)
			shouldRecieveDiscount = false
		end
		if shouldRecieveDiscount then
			local discount = Config.EmergencyServicesDiscount['discount']
			if discount > 100 then
				discount = 100
			else
				if discount <= 0 then discount = 0 end
			end
			if discount ~= 0 then
				if discount == 100 then
					CachedFuelPrice = FuelPrice
					FuelPrice = 0
				else
					discount = discount / 100

					CachedFuelPrice = FuelPrice
					FuelPrice = FuelPrice - (FuelPrice * discount)
				end
			end
		end
	end
	local refillCost = (amount * FuelPrice) + GlobalTax(amount * FuelPrice)
	local ped = cache.ped
	local time = amount * Config.RefuelTime
	if amount < 10 then time = 10 * Config.RefuelTime end
	local vehicleCoords = GetEntityCoords(vehicle)
	if inGasStation then
		if IsPlayerNearVehicle() then
			if Config.FaceTowardsVehicle and RefuelingType ~= 'special' then
				local bootBoneIndex = GetEntityBoneIndexByName(vehicle --[[ Entity ]], 'boot' --[[ string ]])
				local vehBootCoords = GetWorldPositionOfEntityBone(vehicle --[[ Entity ]],
					joaat(bootBoneIndex) --[[ integer ]])
				TaskTurnPedToFaceCoord(cache.ped, vehBootCoords, 500)
				Wait(500)
			end
			lib.playAnim(ped, Config.RefuelAnimationDictionary, Config.RefuelAnimation, 8.0, 1.0, -1, 1, 0, 0, 0, 0)
			refueling = true
			Refuelamount = 0
			CreateThread(function()
				while refueling do
					if Refuelamount == nil then Refuelamount = 0 end
					Wait(Config.RefuelTime)
					Refuelamount = Refuelamount + 1
					if Cancelledrefuel then
						local finalrefuelamount = math.floor(Refuelamount)
						local refillCost = (finalrefuelamount * FuelPrice) + GlobalTax(finalrefuelamount * FuelPrice)
						TriggerServerEvent('cdn-fuel:server:PayForFuel', refillCost, purchasetype, FuelPrice, false,
							CachedFuelPrice)
						CachedFuelPrice = nil
						if RefuelingType == nil then
							if Config.PlayerOwnedGasStationsEnabled and not Config.UnlimitedFuel then
								TriggerServerEvent('cdn-fuel:station:server:updatereserves', 'remove', finalrefuelamount,
									ReserveLevels, CurrentLocation)
								if CachedFuelPrice ~= nil then
									TriggerServerEvent('cdn-fuel:station:server:updatebalance', 'add', finalrefuelamount,
										StationBalance, CurrentLocation, CachedFuelPrice)
									CachedFuelPrice = nil
								else
									TriggerServerEvent('cdn-fuel:station:server:updatebalance', 'add', finalrefuelamount,
										StationBalance, CurrentLocation, FuelPrice)
								end
							end
						end
						local curfuel = GetFuel(vehicle)
						local finalfuel = (curfuel + Refuelamount)
						if finalfuel >= 98 and finalfuel < 100 then
							SetFuel(vehicle, 100)
						else
							SetFuel(vehicle, finalfuel)
						end
						Cancelledrefuel = false
					end
				end
			end)
			TriggerServerEvent('InteractSound_SV:PlayOnSource', 'refuel', 0.3)
			if lib.progressCircle({
					duration = time,
					label = Lang:t('prog_refueling_vehicle'),
					position = 'bottom',
					useWhileDead = false,
					canCancel = true,
					disable = { move = true, combat = true },
				}) then
				refueling = false

				if purchasetype == 'cash' then
					TriggerServerEvent('cdn-fuel:server:PayForFuel', refillCost, purchasetype, FuelPrice, false,
						CachedFuelPrice)
				elseif purchasetype == 'bank' then
					TriggerServerEvent('cdn-fuel:server:PayForFuel', refillCost, purchasetype, FuelPrice, false,
						CachedFuelPrice)
				end

				local curfuel = GetFuel(vehicle)
				local finalfuel = (curfuel + fuelamount)
				if finalfuel > 99 and finalfuel < 100 then
					SetFuel(vehicle, 100)
				else
					SetFuel(vehicle, finalfuel)
				end
				if RefuelingType == nil then
					if Config.PlayerOwnedGasStationsEnabled and not Config.UnlimitedFuel then
						TriggerServerEvent('cdn-fuel:station:server:updatereserves', 'remove', fuelamount, ReserveLevels,
							CurrentLocation)
						if CachedFuelPrice ~= nil then
							TriggerServerEvent('cdn-fuel:station:server:updatebalance', 'add', fuelamount, StationBalance,
								CurrentLocation, CachedFuelPrice)
							CachedFuelPrice = nil
						else
							TriggerServerEvent('cdn-fuel:station:server:updatebalance', 'add', fuelamount, StationBalance,
								CurrentLocation, FuelPrice)
						end
					else
						return
					end
				end
				StopAnimTask(ped, Config.RefuelAnimationDictionary, Config.RefuelAnimation, 3.0)
				TriggerServerEvent('InteractSound_SV:PlayOnSource', 'fuelstop', 0.4)
			else
				refueling = false
				Cancelledrefuel = true
				StopAnimTask(ped, Config.RefuelAnimationDictionary, Config.RefuelAnimation, 3.0)
				TriggerServerEvent('InteractSound_SV:PlayOnSource', 'fuelstop', 0.4)
			end
		end
	else
		return
	end
end)

-- Jerry Can --
RegisterNetEvent('cdn-fuel:jerrycan:refuelmenu', function(itemData)
	if cache.vehicle then
		QBOX:Notify(Lang:t('cannot_refuel_inside'), 'error')
		return
	end

	local vehicle = GetClosestVehicle()
	local vehiclecoords = GetEntityCoords(vehicle)
	local pedcoords = GetEntityCoords(cache.ped)
	if GetVehicleBodyHealth(vehicle) < 100 then
		QBOX:Notify(Lang:t('vehicle_is_damaged'), 'error')
		return
	end
	local jerrycanamount
	jerrycanamount = tonumber(itemData.metadata.cdn_fuel)
	if holdingnozzle then
		local fulltank
		if jerrycanamount == Config.JerryCanCap then
			fulltank = true
			GasString = Lang:t('menu_jerry_can_footer_full_gas')
		else
			fulltank = false
			GasString = Lang:t('menu_jerry_can_footer_refuel_gas')
		end
		lib.registerContext({
			id = 'cdnrefuelmenu',
			title = Lang:t('menu_header_jerry_can'),
			options = {
				{
					title = Lang:t('menu_header_refuel_jerry_can'),
					icon = 'fas fa-gas-pump',
					event = 'cdn-fuel:jerrycan:refueljerrycan',
					args = { itemData = itemData },
					disabled = fulltank
				},
			},
		})
		lib.showContext('cdnrefuelmenu')
	else
		if #(vehiclecoords - pedcoords) > 2.5 then return end
		local nogas
		if jerrycanamount < 1 then
			nogas = true
			GasString = Lang:t('menu_jerry_can_footer_no_gas')
		else
			nogas = false
			GasString = Lang:t('menu_jerry_can_footer_use_gas')
		end
		lib.registerContext({
			id = 'cdnrefuelmenu2',
			title = Lang:t('menu_header_jerry_can'),
			options = {
				{
					title = Lang:t('menu_header_refuel_vehicle'),
					event = 'cdn-fuel:jerrycan:refuelvehicle',
					args = { itemData = itemData },
					disabled = nogas,
				},
			},
		})
		lib.showContext('cdnrefuelmenu2')
	end
end)

RegisterNetEvent('cdn-fuel:client:jerrycanfinalmenu', function(purchasetype)
	local moneyAmount = nil
	if purchasetype == 'bank' then
		moneyAmount = QBX.PlayerData.money.bank
	elseif purchasetype == 'cash' then
		moneyAmount = QBX.PlayerData.money.cash
	end
	if moneyAmount > math.ceil(Config.JerryCanPrice + GlobalTax(Config.JerryCanPrice)) then
		TriggerServerEvent('cdn-fuel:server:purchaseJerryCan', purchasetype)
	else
		QBOX:Notify(
			purchasetype == 'bank' and Lang:t('not_enough_money_in_bank') or Lang:t('not_enough_money_in_cash'), 'error')
		--if purchasetype == 'bank' then QBOX:Notify(Lang:t('not_enough_money_in_bank'), 'error') end
		--if purchasetype == 'cash' then QBOX:Notify(Lang:t('not_enough_money_in_cash'), 'error') end
	end
end)

RegisterNetEvent('cdn-fuel:client:purchasejerrycan', function()
	local playerCashAmount = QBX.PlayerData.money.cash
	lib.registerContext({
		id = 'purchase_jerry_can',
		title = Lang:t('menu_jerry_can_purchase_header') ..
			(math.ceil(Config.JerryCanPrice + GlobalTax(Config.JerryCanPrice))),
		options = {
			{
				title = Lang:t('menu_header_cash'),
				description = Lang:t('menu_pay_with_cash') .. playerCashAmount,
				icon = 'fas fa-usd',
				event = 'cdn-fuel:client:jerrycanfinalmenu',
				args = 'cash',
			},
			{
				title = Lang:t('menu_header_bank'),
				description = Lang:t('menu_pay_with_bank'),
				icon = 'fas fa-credit-card',
				event = 'cdn-fuel:client:jerrycanfinalmenu',
				args = 'bank',
			},
		},
	})
	lib.showContext('purchase_jerry_can')
end)

RegisterNetEvent('cdn-fuel:jerrycan:refuelvehicle', function(data)
	local ped = cache.ped
	local vehicle = GetClosestVehicle()
	local vehfuel = math.floor(GetFuel(vehicle))
	local maxvehrefuel = (100 - math.ceil(vehfuel))
	local itemData = data.itemData
	local jerrycanfuelamount

	jerrycanfuelamount = tonumber(itemData.metadata.cdn_fuel)

	local vehicle = GetClosestVehicle()
	local NotElectric = false
	if Config.ElectricVehicleCharging then
		local isElectric = GetCurrentVehicleType(vehicle)
		if isElectric == 'electricvehicle' then
			QBOX:Notify(Lang:t('need_electric_charger'), 'error', 7500)
			return
		end
		NotElectric = true
	else
		NotElectric = true
	end
	Wait(50)
	if NotElectric then
		if maxvehrefuel < Config.JerryCanCap then
			maxvehrefuel = maxvehrefuel
		else
			maxvehrefuel = Config.JerryCanCap
		end
		if maxvehrefuel >= jerrycanfuelamount then
			maxvehrefuel = jerrycanfuelamount
		elseif maxvehrefuel < jerrycanfuelamount then
			maxvehrefuel = maxvehrefuel
		end
		-- Need to Convert to OX --
		if Config.Ox.Input then
			local refuel = lib.inputDialog(Lang:t('input_select_refuel_header'),
				{ Lang:t('input_max_fuel_footer_1') .. maxvehrefuel .. Lang:t('input_max_fuel_footer_2') })
			if not refuel then return end
			local refuelAmount = tonumber(refuel[1])
			--
			if refuel and refuelAmount then
				if tonumber(refuelAmount) == 0 then
					QBOX:Notify(Lang:t('more_than_zero'), 'error')
					return
				elseif tonumber(refuelAmount) < 0 then
					QBOX:Notify(Lang:t('more_than_zero'), 'error')
					return
				end
				if tonumber(refuelAmount) > jerrycanfuelamount then
					QBOX:Notify(Lang:t('jerry_can_not_enough_fuel'), 'error')
					return
				end
				local refueltimer = Config.RefuelTime * tonumber(refuelAmount)
				if tonumber(refuelAmount) < 10 then refueltimer = Config.RefuelTime * 10 end
				if vehfuel + tonumber(refuelAmount) > 100 then
					QBOX:Notify(Lang:t('tank_cannot_fit'), 'error')
					return
				end
				local refuelAmount = tonumber(refuelAmount)
				JerrycanProp = CreateObject(joaat('w_am_jerrycan'), 1.0, 1.0, 1.0, true, true, false)
				local lefthand = GetPedBoneIndex(ped, 18905)
				AttachEntityToEntity(JerrycanProp, ped, lefthand, 0.11 --[[Left - Right (Kind of)]], 0.0 --[[Up - Down]],
					0.25 --[[Forward - Backward]], 15.0, 170.0, 90.42, 0, 1, 0, 1, 0, 1)
				if lib.progressCircle({
						duration = refueltimer,
						label = Lang:t('prog_refueling_vehicle'),
						position = 'bottom',
						useWhileDead = false,
						canCancel = true,
						disable = { car = true, move = true, combat = true },
						anim = { dict = Config.JerryCanAnimDict, clip = Config.JerryCanAnim },
					}) then
					DeleteObject(JerrycanProp)
					StopAnimTask(ped, Config.JerryCanAnimDict, Config.JerryCanAnim, 1.0)
					QBOX:Notify(Lang:t('jerry_can_success_vehicle'), 'success')
					local JerryCanItemData = data.itemData
					local srcPlayerData = QBX.PlayerData
					TriggerServerEvent('cdn-fuel:info', 'remove', tonumber(refuelAmount), srcPlayerData,
						JerryCanItemData)
					SetFuel(vehicle, (vehfuel + refuelAmount))
				else
					DeleteObject(JerrycanProp)
					StopAnimTask(ped, Config.JerryCanAnimDict, Config.JerryCanAnim, 1.0)
					QBOX:Notify(Lang:t('cancelled'), 'error')
				end
			end
		end
	else
		QBOX:Notify(Lang:t('need_electric_charger'), 'error', 7500)
		return
	end
end)

RegisterNetEvent('cdn-fuel:jerrycan:refueljerrycan', function(data)
	FetchStationInfo('all')
	Wait(100)
	if Config.PlayerOwnedGasStationsEnabled then
		FuelPrice = (1 * StationFuelPrice)
	else
		FuelPrice = (1 * Config.CostMultiplier)
	end
	local itemData = data.itemData
	local jerrycanfuelamount
	jerrycanfuelamount = tonumber(itemData.metadata.cdn_fuel)

	local ped = cache.ped

	if Config.Ox.Input then
		local JerryCanMaxRefuel = (Config.JerryCanCap - jerrycanfuelamount)
		local refuel = lib.inputDialog(Lang:t('input_select_refuel_header'),
			{ Lang:t('input_max_fuel_footer_1') .. JerryCanMaxRefuel .. Lang:t('input_max_fuel_footer_2') })
		if not refuel then return end
		local refuelAmount = tonumber(refuel[1])
		if refuel then
			if tonumber(refuelAmount) == 0 then
				QBOX:Notify(Lang:t('more_than_zero'), 'error')
				return
			elseif tonumber(refuelAmount) < 0 then
				QBOX:Notify(Lang:t('more_than_zero'), 'error')
				return
			end
			if tonumber(refuelAmount) + tonumber(jerrycanfuelamount) > Config.JerryCanCap then
				QBOX:Notify(Lang:t('jerry_can_not_fit_fuel'), 'error')
				return
			end
			if tonumber(refuelAmount) > Config.JerryCanCap then
				QBOX:Notify(Lang:t('jerry_can_not_fit_fuel'), 'error')
				return
			end
			local refueltimer = Config.RefuelTime * tonumber(refuelAmount)
			if tonumber(refuelAmount) < 10 then refueltimer = Config.RefuelTime * 10 end
			local price = (tonumber(refuelAmount) * FuelPrice) + GlobalTax(tonumber(refuelAmount) * FuelPrice)
			if not CanAfford(price, 'cash') then
				QBOX:Notify(Lang:t('not_enough_money_in_cash'), 'error')
				return
			end

			JerrycanProp = CreateObject(joaat('w_am_jerrycan'), 1.0, 1.0, 1.0, true, true, false)
			local lefthand = GetPedBoneIndex(ped, 18905)
			AttachEntityToEntity(JerrycanProp, ped, lefthand, 0.11 --[[Left - Right]], 0.05 --[[Up - Down]],
				0.27 --[[Forward - Backward]], -15.0, 170.0, -90.42, 0, 1, 0, 1, 0, 1)
			SetEntityVisible(fuelNozzle, false, 0)
			if lib.progressCircle({
					duration = refueltimer,
					label = Lang:t('prog_jerry_can_refuel'),
					position = 'bottom',
					useWhileDead = false,
					canCancel = true,
					disable = {
						car = true,
						move = true,
						combat = true
					},
					anim = {
						dict = Config.JerryCanAnimDict,
						clip = Config.JerryCanAnim
					},
				}) then
				SetEntityVisible(fuelNozzle, true, 0)
				DeleteObject(JerrycanProp)
				StopAnimTask(ped, Config.JerryCanAnimDict, Config.JerryCanAnim, 1.0)
				QBOX:Notify(Lang:t('jerry_can_success'), 'success')
				local srcPlayerData = QBX.PlayerData
				TriggerServerEvent('cdn-fuel:info', 'add', tonumber(refuelAmount), srcPlayerData, itemData)
				if Config.PlayerOwnedGasStationsEnabled and not Config.UnlimitedFuel then
					TriggerServerEvent('cdn-fuel:station:server:updatereserves', 'remove', tonumber(refuelAmount),
						ReserveLevels, CurrentLocation)
					if CachedFuelPrice ~= nil then
						TriggerServerEvent('cdn-fuel:station:server:updatebalance', 'add', tonumber(refuelAmount),
							StationBalance, CurrentLocation, CachedFuelPrice)
					else
						TriggerServerEvent('cdn-fuel:station:server:updatebalance', 'add', tonumber(refuelAmount),
							StationBalance, CurrentLocation, FuelPrice)
					end
				else
					return
				end
				local total = (tonumber(refuelAmount) * FuelPrice) + GlobalTax(tonumber(refuelAmount) * FuelPrice)
				TriggerServerEvent('cdn-fuel:server:PayForFuel', total, 'cash', FuelPrice)
			else
				SetEntityVisible(fuelNozzle, true, 0)
				DeleteObject(JerrycanProp)
				StopAnimTask(ped, Config.JerryCanAnimDict, Config.JerryCanAnim, 1.0)
				QBOX:Notify(Lang:t('cancelled'), 'error')
			end
		end
	end
end)

--- Syphoning ---
local function PoliceAlert()
	local chance = math.random(1, 100)
	if chance < Config.SyphonPoliceCallChance then
		exports['ps-dispatch']:SuspiciousActivity()
	end
end

-- Events --
RegisterNetEvent('cdn-syphoning:syphon:menu', function(itemData)
	if cache.vehicle then
		QBOX:Notify(Lang:t('syphon_inside_vehicle'), 'error')
		return
	end
	local vehicle = GetClosestVehicle()
	local vehModel = GetEntityModel(vehicle)
	local vehiclename = string.lower(GetDisplayNameFromVehicleModel(vehModel))
	local vehiclecoords = GetEntityCoords(vehicle)
	local pedcoords = GetEntityCoords(cache.ped)
	if Config.ElectricVehicleCharging then
		NotElectric = true
		if Config.ElectricVehicles[vehiclename] and Config.ElectricVehicles[vehiclename].isElectric then
			NotElectric = false
			QBOX:Notify(Lang:t('syphon_electric_vehicle'), 'error', 7500)
			return
		end
	else
		NotElectric = true
	end
	if NotElectric then
		if #(vehiclecoords - pedcoords) > 2.5 then return end
		if GetVehicleBodyHealth(vehicle) < 100 then
			QBOX:Notify(Lang:t('vehicle_is_damaged'), 'error')
			return
		end
		local nogas
		local syphonfull

		if Config.Ox.Inventory then
			if tonumber(itemData.metadata.cdn_fuel) < 1 then
				nogas = true
				Nogasstring = Lang:t('menu_syphon_empty')
			else
				nogas = false
				Nogasstring = Lang:t('menu_syphon_refuel')
			end
			if tonumber(itemData.metadata.cdn_fuel) == Config.SyphonKitCap then
				syphonfull = true
				Stealfuelstring = Lang:t('menu_syphon_kit_full')
			elseif GetFuel(vehicle) < 1 then
				syphonfull = true
				Stealfuelstring = Lang:t('menu_syphon_vehicle_empty')
			else
				syphonfull = false
				Stealfuelstring = Lang:t('menu_syphon_allowed')
			end -- Disable Options based on item data
		else
			if not itemData.info.gasamount then
				nogas = true
				Nogasstring = Lang:t('menu_syphon_empty')
			end
			if itemData.info.gasamount < 1 then
				nogas = true
				Nogasstring = Lang:t('menu_syphon_empty')
			else
				nogas = false
				Nogasstring = Lang:t('menu_syphon_refuel')
			end
			if itemData.info.gasamount == Config.SyphonKitCap then
				syphonfull = true
				Stealfuelstring = Lang:t('menu_syphon_kit_full')
			elseif GetFuel(vehicle) < 1 then
				syphonfull = true
				Stealfuelstring = Lang:t('menu_syphon_vehicle_empty')
			else
				syphonfull = false
				Stealfuelstring = Lang:t('menu_syphon_allowed')
			end -- Disable Options based on item data
		end
		lib.registerContext({
			id = 'syphoningmenu',
			title = 'Syphoning Kit',
			options = {
				{
					title = Lang:t('menu_syphon_header'),
					description = Stealfuelstring,
					icon = 'fas fa-fire-flame-simple',
					event = 'cdn-syphoning:syphon',
					args = {
						itemData = itemData,
						reason = 'syphon',
					},
					disabled = syphonfull,
				},
				{
					title = Lang:t('menu_syphon_refuel_header'),
					description = Nogasstring,
					icon = 'fas fa-gas-pump',
					event = 'cdn-syphoning:syphon',
					args = {
						itemData = itemData,
						reason = 'refuel',
					},
					disabled = nogas,
				},
			},
		})
		lib.showContext('syphoningmenu')
	end
end)

RegisterNetEvent('cdn-syphoning:syphon', function(data)
	local reason = data.reason
	local ped = cache.ped
	local vehicle = GetClosestVehicle()
	local NotElectric = false
	if Config.ElectricVehicleCharging then
		local isElectric = GetCurrentVehicleType(vehicle)
		if isElectric == 'electricvehicle' then
			QBOX:Notify(Lang:t('need_electric_charger'), 'error', 7500)
			return
		end
		NotElectric = true
	else
		NotElectric = true
	end
	Wait(50)
	if NotElectric then
		local currentsyphonamount = nil

		currentsyphonamount = tonumber(data.itemData.metadata.cdn_fuel)
		HasSyphon = exports.ox_inventory:Search('count', 'syphoningkit')

		if HasSyphon then
			local fitamount = (Config.SyphonKitCap - currentsyphonamount)
			local vehicle = GetClosestVehicle()
			local vehiclecoords = GetEntityCoords(vehicle)
			local pedcoords = GetEntityCoords(ped)
			if #(vehiclecoords - pedcoords) > 2.5 then return end
			local cargasamount = GetFuel(vehicle)
			local maxsyphon = math.floor(GetFuel(vehicle))
			if Config.SyphonKitCap <= 100 then
				if maxsyphon > Config.SyphonKitCap then
					maxsyphon = Config.SyphonKitCap
				end
			end
			if maxsyphon >= fitamount then
				Stealstring = fitamount
			else
				Stealstring = maxsyphon
			end
			if reason == 'syphon' then
				local syphon = lib.inputDialog('Begin Syphoning',
					{ { type = 'number', label = 'You can steal ' .. Stealstring .. 'L from the car.', default = Stealstring } })
				if not syphon then return end
				syphonAmount = tonumber(syphon[1])
				if syphon then
					if not syphonAmount then return end
					if tonumber(syphonAmount) < 0 then
						QBOX:Notify(Lang:t('syphon_more_than_zero'), 'error')
						return
					end
					if tonumber(syphonAmount) == 0 then
						QBOX:Notify(Lang:t('syphon_more_than_zero'), 'error')
						return
					end
					if tonumber(syphonAmount) > maxsyphon then
						QBOX:Notify(
							Lang:t('syphon_kit_cannot_fit_1') .. fitamount .. Lang:t('syphon_kit_cannot_fit_2'), 'error')
						return
					end
					if currentsyphonamount + syphonAmount > Config.SyphonKitCap then
						QBOX:Notify(
							Lang:t('syphon_kit_cannot_fit_1') .. fitamount .. Lang:t('syphon_kit_cannot_fit_2'), 'error')
						return
					end
					if (tonumber(syphonAmount) <= tonumber(cargasamount)) then
						local removeamount = (tonumber(cargasamount) - tonumber(syphonAmount))
						local syphontimer = Config.RefuelTime * syphonAmount
						if tonumber(syphonAmount) < 10 then syphontimer = Config.RefuelTime * 10 end
						if lib.progressCircle({
								duration = syphontimer,
								label = Lang:t('prog_syphoning'),
								position = 'bottom',
								useWhileDead = false,
								canCancel = true,
								disable = { car = true, move = true, combat = true },
								anim = { dict = Config.StealAnimDict, clip = Config.StealAnim },
							}) then
							StopAnimTask(ped, Config.StealAnimDict, Config.StealAnim, 1.0)
							if GetFuel(vehicle) >= syphonAmount then
								PoliceAlert()
								QBOX:Notify(Lang:t('syphon_success'), 'success')
								SetFuel(vehicle, removeamount)
								local syphonData = data.itemData
								local srcPlayerData = QBX.PlayerData
								TriggerServerEvent('cdn-fuel:info', 'add', tonumber(syphonAmount), srcPlayerData,
									syphonData)
							else
								QBOX:Notify(Lang:t('menu_syphon_vehicle_empty'), 'error')
							end
						else
							PoliceAlert()
							StopAnimTask(ped, Config.StealAnimDict, Config.StealAnim, 1.0)
							QBOX:Notify(Lang:t('cancelled'), 'error')
						end
					end
				end
			elseif reason == 'refuel' then
				if 100 - math.ceil(cargasamount) < Config.SyphonKitCap then
					Maxrefuel = 100 - math.ceil(cargasamount)
					if Maxrefuel > currentsyphonamount then Maxrefuel = currentsyphonamount end
				else
					Maxrefuel = currentsyphonamount
				end
				local refuel = lib.inputDialog(Lang:t('input_select_refuel_header'),
					{ { type = 'number', label = Lang:t('input_max_fuel_footer_1') .. Maxrefuel .. Lang:t('input_max_fuel_footer_2'), default = Maxrefuel } })
				if not refuel then return end
				refuelAmount = tonumber(refuel[1])
				if refuel then
					if tonumber(refuelAmount) == 0 then
						QBOX:Notify(Lang:t('more_than_zero'), 'error')
						return
					elseif tonumber(refuelAmount) < 0 then
						QBOX:Notify(Lang:t('more_than_zero'), 'error')
						return
					elseif tonumber(refuelAmount) > 100 then
						QBOX:Notify('You can\'t refuel more than 100L!', 'error')
						return
					end
					if tonumber(refuelAmount) > tonumber(currentsyphonamount) then
						QBOX:Notify(Lang:t('syphon_not_enough_gas'), 'error')
						return
					end
					if tonumber(refuelAmount) + tonumber(cargasamount) > 100 then
						QBOX:Notify(Lang:t('tank_cannot_fit'), 'error')
						return
					end
					local refueltimer = Config.RefuelTime * tonumber(refuelAmount)
					if tonumber(refuelAmount) < 10 then refueltimer = Config.RefuelTime * 10 end
					if lib.progressCircle({
							duration = refueltimer,
							label = Lang:t('prog_refueling_vehicle'),
							position = 'bottom',
							useWhileDead = false,
							canCancel = true,
							disable = {
								car = true,
								move = true,
								combat = true
							},
							anim = {
								dict = Config.JerryCanAnimDict,
								clip = Config.JerryCanAnim
							},
						}) then
						StopAnimTask(ped, Config.JerryCanAnimDict, Config.JerryCanAnim, 1.0)
						QBOX:Notify(Lang:t('syphon_success_vehicle'), 'success')
						SetFuel(vehicle, cargasamount + tonumber(refuelAmount))
						local syphonData = data.itemData
						local srcPlayerData = QBX.PlayerData
						TriggerServerEvent('cdn-fuel:info', 'remove', tonumber(refuelAmount), srcPlayerData, syphonData)
					else
						StopAnimTask(ped, Config.JerryCanAnimDict, Config.JerryCanAnim, 1.0)
						QBOX:Notify(Lang:t('cancelled'), 'error')
					end
				end
			end
		else
			QBOX:Notify(Lang:t('syphon_no_syphon_kit'), 'error', 7500)
		end
	else
		QBOX:Notify(Lang:t('need_electric_charger'), 'error', 7500)
		return
	end
end)

-- Helicopter Fueling --
RegisterNetEvent('cdn-fuel:client:grabnozzle:special', function()
	local ped = cache.ped
	if HoldingSpecialNozzle then return end
	lib.playAnim(ped, 'anim@am_hold_up@male', 'shoplift_high', 2.0, 8.0, -1, 50, 0, 0, 0, 0)
	TriggerServerEvent('InteractSound_SV:PlayOnSource', 'pickupnozzle', 0.4)
	Wait(300)
	StopAnimTask(ped, 'anim@am_hold_up@male', 'shoplift_high', 1.0)
	SpecialFuelNozzleObj = CreateObject(joaat('prop_cs_fuel_nozle'), 1.0, 1.0, 1.0, true, true, false)
	local lefthand = GetPedBoneIndex(ped, 18905)
	AttachEntityToEntity(SpecialFuelNozzleObj, ped, lefthand, 0.13, 0.04, 0.01, -42.0, -115.0, -63.42, 0, 1, 0, 1, 0, 1)
	local grabbednozzlecoords = GetEntityCoords(ped)
	HoldingSpecialNozzle = true
	QBOX:Notify(Lang:t('show_input_key_special'))
	if Config.PumpHose then
		local pumpCoords, pump = GetClosestPump(grabbednozzlecoords)
		-- Load Rope Textures
		RopeLoadTextures()
		while not RopeAreTexturesLoaded() do
			Wait(0)
			RopeLoadTextures()
		end
		-- Wait for Pump to exist.
		while not pump do
			Wait(0)
		end
		Rope = AddRope(pumpCoords.x, pumpCoords.y, pumpCoords.z + 2.0, 0.0, 0.0, 0.0, 3.0, Config.RopeType['fuel'],
			8.0 --[[ DO NOT SET THIS TO 0.0!!! GAME WILL CRASH!]], 0.0, 1.0, false, false, false, 1.0, true)
		while not Rope do
			Wait(0)
		end
		ActivatePhysics(Rope)
		Wait(100)
		local nozzlePos = GetEntityCoords(SpecialFuelNozzleObj)
		nozzlePos = GetOffsetFromEntityInWorldCoords(SpecialFuelNozzleObj, 0.0, -0.033, -0.195)
		AttachEntitiesToRope(Rope, pump, SpecialFuelNozzleObj, pumpCoords.x, pumpCoords.y, pumpCoords.z + 2.1,
			nozzlePos.x, nozzlePos.y, nozzlePos.z, length, false, false, nil, nil)
	end

	CreateThread(function()
		while HoldingSpecialNozzle do
			local currentcoords = GetEntityCoords(ped)
			local dist = #(grabbednozzlecoords - currentcoords)
			TargetCreated = true
			if dist > Config.AirAndWaterVehicleFueling.nozzle_length or cache.vehicle then
				HoldingSpecialNozzle = false
				DeleteObject(SpecialFuelNozzleObj)
				QBOX:Notify(Lang:t('nozzle_cannot_reach'), 'error')
				if Config.PumpHose then
					RopeUnloadTextures()
					DeleteRope(Rope)
				end
			end
			Wait(2500)
		end
	end)
end)

RegisterNetEvent('cdn-fuel:client:returnnozzle:special', function()
	HoldingSpecialNozzle = false
	TriggerServerEvent('InteractSound_SV:PlayOnSource', 'putbacknozzle', 0.4)
	Wait(250)
	DeleteObject(SpecialFuelNozzleObj)
	if Config.PumpHose then
		RopeUnloadTextures()
		DeleteRope(Rope)
	end
end)

local AirSeaFuelZones = {}
local vehicle = nil
-- Create Polyzones with In-Out functions for handling fueling --

AddEventHandler('onResourceStart', function(resource)
	if resource == cache.resource then
		if LocalPlayer.state.isLoggedIn then
			for i = 1, #Config.AirAndWaterVehicleFueling.locations, 1 do
				local currentLocation = Config.AirAndWaterVehicleFueling.locations[i]
				local k = #AirSeaFuelZones + 1
				local GeneratedName = ('air_sea_fuel_zone_%s'):format(k)

				AirSeaFuelZones[k] = {} -- Make a new table inside of the Vehicle Pullout Zones representing this zone.

				-- Create Zone
				AirSeaFuelZones[k] = lib.zones.poly({
					points = currentLocation.coords,
					thickness = currentLocation.thickness,
					debug = Config.PolyDebug,
				})

				-- Setup onPlayerInOut Events for zone that is created.
				AirSeaFuelZones[k].inside = function()
					local canUseThisStation = false
					if currentLocation.whitelist.enabled then
						local whitelisted_jobs = currentLocation.whitelist.whitelisted_jobs
						local plyJob = QBX.PlayerData.job

						if type(whitelisted_jobs) == 'table' then
							for i = 1, #whitelisted_jobs, 1 do
								if plyJob.name == whitelisted_jobs[i] then
									if currentLocation.whitelist.on_duty_only then
										if plyJob.onduty == true then
											canUseThisStation = true
										else
											canUseThisStation = false
										end
									else
										canUseThisStation = true
									end
								end
							end
						end
					else
						canUseThisStation = true
					end

					if canUseThisStation then
						-- Inside
						PlayerInSpecialFuelZone = true
						inGasStation = true
						RefuelingType = 'special'

						local DrawText = currentLocation.draw_text

						lib.showTextUI(DrawText, { position = 'left-center' })

						CreateThread(function()
							while PlayerInSpecialFuelZone do
								Wait(3000)
								vehicle = GetClosestVehicle()
							end
						end)

						CreateThread(function()
							while PlayerInSpecialFuelZone do
								Wait(0)
								if PlayerInSpecialFuelZone ~= true then
									break
								end
								if IsControlJustReleased(0, Config.AirAndWaterVehicleFueling.refuel_button) --[[ Control in Config ]] then
									local vehCoords = GetEntityCoords(vehicle)
									local dist = #(GetEntityCoords(cache.ped) - vehCoords)

									if not HoldingSpecialNozzle then
										QBOX:Notify(Lang:t('no_nozzle'), 'error', 1250)
									elseif dist > 4.5 then
										QBOX:Notify(Lang:t('vehicle_too_far'), 'error', 1250)
									elseif IsPedInAnyVehicle(cache.ped, true) then
										QBOX:Notify(Lang:t('inside_vehicle'), 'error', 1250)
									else
										TriggerEvent('cdn-fuel:client:RefuelMenu', 'special')
									end
								end
							end
						end)
					end
				end

				AirSeaFuelZones[k].onExit = function()
					if HoldingSpecialNozzle then
						QBOX:Notify(Lang:t('nozzle_cannot_reach'), 'error')
						HoldingSpecialNozzle = false
						if Config.PumpHose then
							RopeUnloadTextures()
							DeleteObject(Rope)
						end
						DeleteObject(SpecialFuelNozzleObj)
					end
					if Config.PumpHose then
						if Rope ~= nil then
							RopeUnloadTextures()
							DeleteObject(Rope)
						end
					end
					-- Outside
					lib.hideTextUI()
					PlayerInSpecialFuelZone = false
					inGasStation = false
					RefuelingType = nil
				end


				if currentLocation.prop then
					local model = currentLocation.prop.model
					local modelCoords = currentLocation.prop.coords
					local heading = modelCoords[4] - 180.0
					AirSeaFuelZones[k].prop = CreateObject(model, modelCoords.x, modelCoords.y, modelCoords.z, false, true, true)
					SetEntityHeading(AirSeaFuelZones[k].prop, heading)
					FreezeEntityPosition(AirSeaFuelZones[k].prop, true)
				else
					return
				end
			end
		end
	end
end)

--[[RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
	for i = 1, #Config.AirAndWaterVehicleFueling['locations'], 1 do
		local currentLocation = currentLocation
		local k = #AirSeaFuelZones + 1
		local GeneratedName = ('air_sea_fuel_zone_%s'):format(k)

		AirSeaFuelZones[k] = {} -- Make a new table inside of the Vehicle Pullout Zones representing this zone.

		-- Get Coords for Zone from Config.
		AirSeaFuelZones[k].zoneCoords = currentLocation['PolyZone']['coords']

		-- Grab MinZ & MaxZ from Config.
		local minimumZ, maximumZ = currentLocation['PolyZone']['minmax']['min'], currentLocation['PolyZone']['minmax']['max']

		-- Create Zone
		AirSeaFuelZones[k].PolyZone = PolyZone:Create(AirSeaFuelZones[k].zoneCoords, {
			name = GeneratedName,
			minZ = minimumZ,
			maxZ = maximumZ,
			debugPoly = Config.PolyDebug
		})

		AirSeaFuelZones[k].name = GeneratedName

		-- Setup onPlayerInOut Events for zone that is created.
		AirSeaFuelZones[k].PolyZone:onPlayerInOut(function(isPointInside)
			if isPointInside then
				local canUseThisStation = false
				if currentLocation.whitelist.enabled then
					local whitelisted_jobs = currentLocation.whitelist.whitelisted_jobs
					local plyJob = QBX.PlayerData.job

					if type(whitelisted_jobs) == 'table' then
						for i = 1, #whitelisted_jobs, 1 do
							if plyJob.name == whitelisted_jobs[i] then
								if currentLocation.whitelist.on_duty_only then
									if plyJob.onduty == true then
										canUseThisStation = true
									else
										canUseThisStation = false
									end
								else
									canUseThisStation = true
								end
							end
						end
					end
				else
					canUseThisStation = true
				end

				if canUseThisStation then
					-- Inside
					PlayerInSpecialFuelZone = true
					inGasStation = true
					RefuelingType = 'special'

					local DrawText = currentLocation.draw_text

					lib.showTextUI(DrawText, { position = 'left-center' })

					CreateThread(function()
						while PlayerInSpecialFuelZone do
							Wait(3000)
							vehicle = GetClosestVehicle()
						end
					end)

					CreateThread(function()
						while PlayerInSpecialFuelZone do
							Wait(0)
							if PlayerInSpecialFuelZone ~= true then
								break
							end
							if IsControlJustReleased(0, Config.AirAndWaterVehicleFueling['refuel_button']) then
								local vehCoords = GetEntityCoords(vehicle)
								local dist = #(GetEntityCoords(cache.ped) - vehCoords)

								if not HoldingSpecialNozzle then
									QBOX:Notify(Lang:t('no_nozzle'), 'error', 1250)
								elseif dist > 4.5 then
									QBOX:Notify(Lang:t('vehicle_too_far'), 'error', 1250)
								elseif IsPedInAnyVehicle(cache.ped, true) then
									QBOX:Notify(Lang:t('inside_vehicle'), 'error', 1250)
								else
									TriggerEvent('cdn-fuel:client:RefuelMenu', 'special')
								end
							end
						end
					end)
				end
			else
				if HoldingSpecialNozzle then
					QBOX:Notify(Lang:t('nozzle_cannot_reach'), 'error')
					HoldingSpecialNozzle = false
					if Config.PumpHose then
						RopeUnloadTextures()
						DeleteObject(Rope)
					end
					DeleteObject(SpecialFuelNozzleObj)
				end
				if Config.PumpHose then
					if Rope ~= nil then
						RopeUnloadTextures()
						DeleteObject(Rope)
					end
				end
				-- Outside
				lib.hideTextUI()
				PlayerInSpecialFuelZone = false
				inGasStation = false
				RefuelingType = nil
			end
		end)

		if currentLocation.prop then
			local model = currentLocation.prop.model
			local modelCoords = currentLocation.prop.coords
			local heading = modelCoords[4] - 180.0
			AirSeaFuelZones[k].prop = CreateObject(model, modelCoords.x, modelCoords.y, modelCoords.z, false, true, true)
			SetEntityHeading(AirSeaFuelZones[k].prop, heading)
			FreezeEntityPosition(AirSeaFuelZones[k].prop, true)
		else
			return
		end
	end
end) ]]

RegisterNetEvent('QBCore:Server:OnPlayerUnload', function()
	for i = 1, #AirSeaFuelZones, 1 do
		AirSeaFuelZones[i]:remove()
		if AirSeaFuelZones[i].prop then
			DeleteObject(AirSeaFuelZones[i].prop)
		end
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		for i = 1, #AirSeaFuelZones, 1 do
			DeleteObject(AirSeaFuelZones[i].prop)
		end
	end
end)

CreateThread(function()
	local options = {
		{
			name = 'cdn-fuel:options:1',
			icon = "fas fa-gas-pump",
			event = 'cdn-fuel:client:RefuelMenu',
			label = tostring(Lang:t("input_insert_nozzle")),
			distance = 2.0,
			canInteract = function()
				if inGasStation and not refueling and holdingnozzle then
					return true
				end
			end,
		},
		{
			name = 'cdn-fuel:options:2',
			icon = "fas fa-bolt",
			label = tostring(Lang:t("insert_electric_nozzle")),
			distance = 2.0,
			canInteract = function()
				if Config.ElectricVehicleCharging == true then
					if inGasStation and not refueling and IsHoldingElectricNozzle() then
						return true
					else
						return false
					end
				else
					return false
				end
			end,
			event = "cdn-fuel:client:electric:RefuelMenu",
		}
	}

	exports.ox_target:addGlobalVehicle(options)

	options = {
		{
			event = 'cdn-fuel:client:grabnozzle',
			label = Lang:t('grab_nozzle'),
			canInteract = function()
				if PlayerInSpecialFuelZone then return false end
				return not cache.vehicle and not holdingnozzle and not HoldingSpecialNozzle and inGasStation == true and
					not PlayerInSpecialFuelZone
			end,
		},
		{
			event = 'cdn-fuel:client:purchasejerrycan',
			label = Lang:t('buy_jerrycan'),
			canInteract = function()
				return not cache.vehicle and not holdingnozzle and not HoldingSpecialNozzle and inGasStation == true
			end,
		},
		{
			event = 'cdn-fuel:client:returnnozzle',
			label = Lang:t('return_nozzle'),
			canInteract = function()
				return holdingnozzle and not refueling
			end,
		},
		{
			event = 'cdn-fuel:client:grabnozzle:special',
			label = Lang:t('grab_special_nozzle'),
			canInteract = function()
				return not HoldingSpecialNozzle and not cache.vehicle and PlayerInSpecialFuelZone
			end,
		},
		{
			event = 'cdn-fuel:client:returnnozzle:special',
			label = Lang:t('return_special_nozzle'),
			canInteract = function()
				return HoldingSpecialNozzle and not cache.vehicle
			end
		},
	}

	for i = 1, #props do
		exports.interact:AddModelInteraction({
			model = props[i],
			offset = vec3(0.0, 0.0, 1.0),
			distance = 5.0,
			interactDst = 1.5,
			id = 'fuel_options',
			options = options,
		})
	end
end)

CreateThread(function()
	while true do
		Wait(3000)
		local vehPedIsIn = GetVehiclePedIsIn(cache.ped, false)
		if not vehPedIsIn or vehPedIsIn == 0 then
			Wait(2500)
			if inBlacklisted then
				inBlacklisted = false
			end
		else
			local vehType = GetCurrentVehicleType(vehPedIsIn)
			if not Config.ElectricVehicleCharging and vehType == 'electricvehicle' then
			else
				if not IsVehicleBlacklisted(vehPedIsIn) then
					local vehFuelLevel = GetFuel(vehPedIsIn)
					local vehFuelShutoffLevel = Config.VehicleShutoffOnLowFuel['shutOffLevel'] or 1
					if vehFuelLevel <= vehFuelShutoffLevel then
						if GetIsVehicleEngineRunning(vehPedIsIn) then
							-- If the vehicle is on, we shut the vehicle off:
							SetVehicleEngineOn(vehPedIsIn, false, true, true)
							-- Then alert the client with notify.
							QBOX:Notify(Lang:t('no_fuel'), 'error', 3500)
							-- Play Sound, if enabled in config.
							if Config.VehicleShutoffOnLowFuel['sounds']['enabled'] then
								RequestAmbientAudioBank('DLC_PILOT_ENGINE_FAILURE_SOUNDS', 0)
								PlaySoundFromEntity(l_2613, 'Landing_Tone', vehPedIsIn, 'DLC_PILOT_ENGINE_FAILURE_SOUNDS',
									false, 0)
								Wait(1500)
								StopSound(l_2613)
							end
						end
					else
						if vehFuelLevel - 10 > vehFuelShutoffLevel then
							Wait(7500)
						end
					end
				end
			end
		end
	end
end)

if Config.VehicleShutoffOnLowFuel.shutOffLevel == 0 then
	Config.VehicleShutoffOnLowFuel.shutOffLevel = 0.55
end

-- This loop does use quite a bit of performance, but,
-- is needed due to electric vehicles running without fuel & normal vehicles driving backwards!
-- You can remove if you need the performance, but we believe it is very important.
CreateThread(function()
	while cache.vehicle do
		Wait(0)
		local ped = cache.ped
		local veh = GetVehiclePedIsIn(ped, false)
		if veh ~= 0 and veh ~= nil then
			if not IsVehicleBlacklisted(veh) then
				-- Check if we are below the threshold for the Fuel Shutoff Level, if so, disable the 'W' key, if not, enable it again.
				if IsPedInVehicle(ped, veh, false) and (GetIsVehicleEngineRunning(veh) == false) or GetFuel(veh) < (Config.VehicleShutoffOnLowFuel['shutOffLevel'] or 1) then
					DisableControlAction(0, 71, true)
				elseif IsPedInVehicle(ped, veh, false) and (GetIsVehicleEngineRunning(veh) == true) and GetFuel(veh) > (Config.VehicleShutoffOnLowFuel['shutOffLevel'] or 1) then
					EnableControlAction(0, 71, true)
				end
				-- Now, we check if the fuel level is currently 5 above the level it should shut off,
				-- if this is true, we will then enable the 'W' key if currently disabled, and then,
				-- we will add a 5 second wait, in order to reduce system impact.
				if GetFuel(veh) > (Config.VehicleShutoffOnLowFuel['shutOffLevel'] + 5) then
					if not IsControlEnabled(0, 71) then
						-- Enable 'W' Key if it is currently disabled.
						EnableControlAction(0, 71, true)
					end
					Wait(5000)
				end
			end
		end
	end
end)


AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		DeleteObject(fuelNozzle)
		DeleteObject(SpecialFuelNozzleObj)
		if Config.PumpHose then
			RopeUnloadTextures()
			DeleteObject(Rope)
		end
		exports.ox_target:removeGlobalVehicle('cdn-fuel:options:1')
		exports.ox_target:removeGlobalVehicle('cdn-fuel:options:2')
		for i = 1, #props, 1 do
			exports.interact:RemoveModelInteraction(props[i], 'fuel_options')
		end

		-- Remove Blips from map so they dont double up.
		for i = 1, #GasStationBlips, 1 do
			RemoveBlip(GasStationBlips[i])
		end
	end
end)
