local QBOX = exports.qbx_core

-- Functions
local function GlobalTax(value)
	local tax = (value / 100 * Config.GlobalTax)
	return tax
end

-- Events

RegisterNetEvent('cdn-fuel:server:electric:OpenMenu', function(amount, inGasStation, hasWeapon, purchasetype, FuelPrice)
	local src = source
	if not src then return end
	local player = QBOX:GetPlayer(src)
	if not player then return end
	local FuelCost = amount * FuelPrice
	local tax = GlobalTax(FuelCost)
	local total = tonumber(FuelCost + tax)
	if not amount then
		QBOX:Notify( src, Lang:t('electric_more_than_zero'), 'error')
		return
	end
	Wait(50)
	if inGasStation and not hasWeapon then
		TriggerClientEvent('cdn-electric:client:OpenContextMenu', src, math.ceil(total), amount, purchasetype)
	end
end)