-- Variables
local QBOX = exports.qbx_core

-- Functions
local function GlobalTax(value)
	local tax = (value / 100 * Config.GlobalTax)
	return tax
end

--- Events

RegisterNetEvent('cdn-fuel:server:OpenMenu', function(amount, inGasStation, hasWeapon, purchasetype, FuelPrice)
	local src = source
	if not src then return end
	local player = QBOX:GetPlayer(src)
	if not player then return end
	if not amount then
		QBOX:Notify(src, Lang:t('more_than_zero'), 'error')
		return
	end
	local FuelCost = amount * FuelPrice
	local tax = GlobalTax(FuelCost)
	local total = tonumber(FuelCost + tax)
	if inGasStation == true and not hasWeapon then
		TriggerClientEvent('cdn-fuel:client:OpenContextMenu', src, total, amount, purchasetype)
	end
end)

RegisterNetEvent('cdn-fuel:server:PayForFuel', function(amount, purchasetype, FuelPrice, electric)
	local src = source
	if not src then return end
	local Player = QBOX:GetPlayer(src)
	if not Player then return end
	local total = math.ceil(amount)
	if amount < 1 then
		total = 0
	end
	local moneyremovetype = purchasetype
	if purchasetype == 'bank' then
		moneyremovetype = 'bank'
	elseif purchasetype == 'cash' then
		moneyremovetype = 'cash'
	end
	local payString = Lang:t('menu_pay_label_1') .. FuelPrice .. Lang:t('menu_pay_label_2')
	if electric then payString = Lang:t('menu_electric_payment_label_1') ..
		FuelPrice .. Lang:t('menu_electric_payment_label_2') end
	Player.Functions.RemoveMoney(moneyremovetype, total, payString)
end)

RegisterNetEvent('cdn-fuel:server:purchaseJerryCan', function(purchasetype)
	local src = source
	if not src then return end
	local Player = QBOX:GetPlayer(src)
	if not Player then return end
	local tax = GlobalTax(Config.JerryCanPrice)
	local total = math.ceil(Config.JerryCanPrice + tax)
	local moneyremovetype = purchasetype
	if purchasetype == 'bank' then
		moneyremovetype = 'bank'
	elseif purchasetype == 'cash' then
		moneyremovetype = 'cash'
	end
	local info = { cdn_fuel = tostring(Config.JerryCanGas) }
	exports.ox_inventory:AddItem(src, 'jerrycan', 1, info)
	local hasItem = exports.ox_inventory:GetItem(src, 'jerrycan', info, 1)
	if hasItem then
		Player.Functions.RemoveMoney(moneyremovetype, total, Lang:t('jerry_can_payment_label'))
	end
end)

--- Jerry Can
if Config.UseJerryCan then
	QBOX:CreateUseableItem('jerrycan', function(source, item)
		local src = source
		TriggerClientEvent('cdn-fuel:jerrycan:refuelmenu', src, item)
	end)
end

--- Syphoning
if Config.UseSyphoning then
	QBOX:CreateUseableItem('syphoningkit', function(source, item)
		local src = source
		if item.metadata.cdn_fuel == nil then
			item.metadata.cdn_fuel = '0'
			exports.ox_inventory:SetMetadata(src, item.slot, item.metadata)
		end
		TriggerClientEvent('cdn-syphoning:syphon:menu', src, item)
	end)
end

RegisterNetEvent('cdn-fuel:info', function(type, amount, srcPlayerData, itemdata)
	local src = source
	local Player = QBOX:GetPlayer(src)
	local srcPlayerData = srcPlayerData
	local ItemName = itemdata.name

	if itemdata == 'jerrycan' then
		if amount < 1 or amount > Config.JerryCanCap then
			return
		end
	elseif itemdata == 'syphoningkit' then
		if amount < 1 or amount > Config.SyphonKitCap then
			return
		end
	end
	if ItemName ~= nil then
		-- Ignore --
		itemdata.metadata = itemdata.metadata
		itemdata.slot = itemdata.slot
		if ItemName == 'jerrycan' then
			local fuel_amount = tonumber(itemdata.metadata.cdn_fuel)
			if type == 'add' then
				fuel_amount = fuel_amount + amount
				itemdata.metadata.cdn_fuel = tostring(fuel_amount)
				exports.ox_inventory:SetMetadata(src, itemdata.slot, itemdata.metadata)
			elseif type == 'remove' then
				fuel_amount = fuel_amount - amount
				itemdata.metadata.cdn_fuel = tostring(fuel_amount)
				exports.ox_inventory:SetMetadata(src, itemdata.slot, itemdata.metadata)
			else
				return
			end
		elseif ItemName == 'syphoningkit' then
			local fuel_amount = tonumber(itemdata.metadata.cdn_fuel)
			if type == 'add' then
				fuel_amount = fuel_amount + amount
				itemdata.metadata.cdn_fuel = tostring(fuel_amount)
				exports.ox_inventory:SetMetadata(src, itemdata.slot, itemdata.metadata)
			elseif type == 'remove' then
				fuel_amount = fuel_amount - amount
				itemdata.metadata.cdn_fuel = tostring(fuel_amount)
				exports.ox_inventory:SetMetadata(src, itemdata.slot, itemdata.metadata)
			end
		end
	end
end)
