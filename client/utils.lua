function GetFuel(vehicle)
	return DecorGetFloat(vehicle, Config.FuelDecor)
end

function SetFuel(vehicle, fuel)
	if type(fuel) == 'number' and fuel >= 0 and fuel <= 100 then
		SetVehicleFuelLevel(vehicle, fuel + 0.0)
		DecorSetFloat(vehicle, Config.FuelDecor, GetVehicleFuelLevel(vehicle))
	end
end

function LoadAnimDict(dict)
	lib.requestAnimDict(dict)
end

function RequestAndLoadModel(model)
    lib.requestModel(model)
end

function GlobalTax(value)
	if Config.GlobalTax < 0.1 then
		return 0
	end
	local tax = (value / 100 * Config.GlobalTax)
	return tax
end

function Comma_Value(amount)
	local formatted = amount
	while true do
		formatted, k = string.gsub(formatted, '^(-?%d+)(%d%d%d)', '%1,%2')
		if (k == 0) then
			break
		end
	end
	return formatted
end

function math.percent(percent, maxvalue)
	if tonumber(percent) and tonumber(maxvalue) then
		return (maxvalue * percent) / 100
	end
	return false
end

function GetCurrentVehicleType(vehicle)
	if not vehicle then
		vehicle = GetVehiclePedIsIn(cache.ped, true)
	end
	if not vehicle then return false end
	local vehModel = GetEntityModel(vehicle)
	local vehiclename = string.lower(GetDisplayNameFromVehicleModel(vehModel))

	if Config.ElectricVehicles[vehiclename] then
		return 'electricvehicle'
	else
		return 'gasvehicle'
	end
end

function CreateBlip(coords, label)
	local blip = AddBlipForCoord(coords)
	local vehicle = GetCurrentVehicleType()
	local electricbolt = Config.ElectricSprite -- Sprite
	if vehicle == 'electricvehicle' then
		SetBlipSprite(blip, electricbolt)   -- This is where the fuel thing will get changed into the electric bolt instead of the pump.
		SetBlipColour(blip, 15)
	else
		SetBlipSprite(blip, 361)
		SetBlipColour(blip, 6)
	end
	SetBlipScale(blip, 0.6)
	SetBlipDisplay(blip, 4)
	SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString(label)
	EndTextCommandSetBlipName(blip)
	return blip
end

function GetClosestVehicle(coords)
	local vehicles = GetGamePool('CVehicle')
	local closestDistance = -1
	local closestVehicle = -1
	if coords then
		coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
	else
		coords = GetEntityCoords(cache.ped)
	end
	for i = 1, #vehicles, 1 do
		local vehicleCoords = GetEntityCoords(vehicles[i])
		local distance = #(vehicleCoords - coords)
		if closestDistance == -1 or closestDistance > distance then
			closestVehicle = vehicles[i]
			closestDistance = distance
		end
	end
	return closestVehicle, closestDistance
end

function IsPlayerNearVehicle()
	local vehicle = GetClosestVehicle()
	local closestVehCoords = GetEntityCoords(vehicle)
	if #(GetEntityCoords(cache.ped, closestVehCoords)) > 3.0 then
		return true
	end
	return false
end

function IsVehicleBlacklisted(veh)
	if veh and veh ~= 0 then
		veh = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(veh)))
		-- Puts Vehicles In Blacklist if you have electric charging on.
		if not Config.ElectricVehicleCharging then
			if Config.ElectricVehicles[veh] then
				return true
			end
		end

		if Config.NoFuelUsage[veh] then
			-- If the veh equals a vehicle in the list then return true.
			return true
		end

		-- Default False
		return false
	else
		return false
	end
	-- return true
end
