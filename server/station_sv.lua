if not Config.PlayerOwnedGasStationsEnabled then return end -- This is so Player Owned Gas Stations are a Config Option, instead of forced. Set this option in shared/config.lua!

-- Variables
local QBOX = exports.qbx_core
local FuelPickupSent = {}     -- This is in case of an issue with vehicles not spawning when picking up vehicles.

-- Functions
local function GlobalTax(value)
    local tax = (value / 100 * Config.GlobalTax)
    return tax
end

function math.percent(percent, maxvalue)
    if tonumber(percent) and tonumber(maxvalue) then
        return (maxvalue * percent) / 100
    end
    return false
end

local function UpdateStationLabel(location, newLabel, src)
    if not newLabel or newLabel == nil then
        MySQL.Async.fetchAll('SELECT label FROM fuel_stations WHERE location = ?', { location }, function(result)
            if result then
                local data = result[1]
                if data == nil then return end
                local newLabel = data.label
                TriggerClientEvent('cdn-fuel:client:updatestationlabels', -1, location, newLabel)
            else
                return false
                --cb(false)
            end
        end)
    else
        MySQL.Async.execute('UPDATE fuel_stations SET label = ? WHERE `location` = ?', { newLabel, location })
        if src then
            TriggerClientEvent('cdn-fuel:client:updatestationlabels', src, location, newLabel)
        else
            TriggerClientEvent('cdn-fuel:client:updatestationlabels', -1, location, newLabel)
        end
    end
end

-- Events
RegisterNetEvent('cdn-fuel:server:updatelocationlabels', function()
    local src = source
    local location = 0
    for _ in pairs(Config.GasStations) do
        location = location + 1
        UpdateStationLabel(location, nil, src)
    end
end)

RegisterNetEvent('cdn-fuel:server:buyStation', function(location, CitizenID)
    local src = source
    local Player = QBOX:GetPlayer(src)
    local CostOfStation = Config.GasStations[location].cost + GlobalTax(Config.GasStations[location].cost)
    if Player.Functions.RemoveMoney("bank", CostOfStation, Lang:t("station_purchased_location_payment_label") .. Config.GasStations[location].label) then
        MySQL.Async.execute('UPDATE fuel_stations SET owned = ? WHERE `location` = ?', { 1, location })
        MySQL.Async.execute('UPDATE fuel_stations SET owner = ? WHERE `location` = ?', { CitizenID, location })
    end
end)

RegisterNetEvent('cdn-fuel:stations:server:sellstation', function(location)
    local src = source
    local Player = QBOX:GetPlayer(src)
    local GasStationCost = Config.GasStations[location].cost + GlobalTax(Config.GasStations[location].cost)
    local SalePrice = math.percent(Config.GasStationSellPercentage, GasStationCost)
    if Player.Functions.AddMoney("bank", SalePrice, Lang:t("station_sold_location_payment_label") .. Config.GasStations[location].label) then
        MySQL.Async.execute('UPDATE fuel_stations SET owned = ? WHERE `location` = ?', { 0, location })
        MySQL.Async.execute('UPDATE fuel_stations SET owner = ? WHERE `location` = ?', { 0, location })
        QBOX:Notify(src, Lang:t("station_sold_success"), 'success')
    else
        QBOX:Notify(src, Lang:t("station_cannot_sell"), 'error')
    end
end)

RegisterNetEvent('cdn-fuel:station:server:Withdraw', function(amount, location, StationBalance)
    local src = source
    local Player = QBOX:GetPlayer(src)
    local setamount = (StationBalance - amount)
    if amount > StationBalance then
        QBOX:Notify(src, Lang:t("station_withdraw_too_much"), 'success')
        return
    end
    MySQL.Async.execute('UPDATE fuel_stations SET balance = ? WHERE `location` = ?', { setamount, location })
    Player.Functions.AddMoney("bank", amount, Lang:t("station_withdraw_payment_label") .. Config.GasStations[location].label)
    QBOX:Notify(src, Lang:t("station_success_withdrew_1") .. amount .. Lang:t("station_success_withdrew_2"), 'success')
end)

RegisterNetEvent('cdn-fuel:station:server:Deposit', function(amount, location, StationBalance)
    local src = source
    local Player = QBOX:GetPlayer(src)
    local setamount = (StationBalance + amount)
    if Player.Functions.RemoveMoney("bank", amount, Lang:t("station_deposit_payment_label") .. Config.GasStations[location].label) then
        MySQL.Async.execute('UPDATE fuel_stations SET balance = ? WHERE `location` = ?', { setamount, location })
        QBOX:Notify(src, Lang:t("station_success_deposit_1") .. amount .. Lang:t("station_success_deposit_2"), 'success')
    else
        QBOX:Notify(src, Lang:t("station_cannot_afford_deposit") .. amount .. "!", 'success')
    end
end)

RegisterNetEvent('cdn-fuel:stations:server:Shutoff', function(location)
    local src = source
    Config.GasStations[location].shutoff = not Config.GasStations[location].shutoff
    QBOX:Notify(src, Lang:t("station_shutoff_success"), 'success')
end)

RegisterNetEvent('cdn-fuel:station:server:updatefuelprice', function(fuelprice, location)
    local src = source
    MySQL.Async.execute('UPDATE fuel_stations SET fuelprice = ? WHERE `location` = ?', { fuelprice, location })
    QBOX:Notify(src, Lang:t("station_fuel_price_success") .. fuelprice .. Lang:t("station_per_liter"), 'success')
end)

RegisterNetEvent('cdn-fuel:station:server:updatereserves', function(reason, amount, currentlevel, location)
    if reason == "remove" then
        NewLevel = (currentlevel - amount)
    elseif reason == "add" then
        NewLevel = (currentlevel + amount)
    else
        return
    end
    MySQL.Async.execute('UPDATE fuel_stations SET fuel = ? WHERE `location` = ?', { NewLevel, location })
end)

RegisterNetEvent('cdn-fuel:station:server:updatebalance', function(reason, amount, StationBalance, location, FuelPrice)
    local Price = (FuelPrice * tonumber(amount))
    local StationGetAmount = math.floor(Config.StationFuelSalePercentage * Price)
    if reason == "remove" then
        NewBalance = (StationBalance - StationGetAmount)
    elseif reason == "add" then
        NewBalance = (StationBalance + StationGetAmount)
    else
        return
    end
    MySQL.Async.execute('UPDATE fuel_stations SET balance = ? WHERE `location` = ?', { NewBalance, location })
end)


RegisterNetEvent('cdn-fuel:stations:server:buyreserves', function(location, price, amount)
    local location = location
    local price = math.ceil(price)
    local amount = amount
    local src = source
    local Player = QBOX:GetPlayer(src)
    local result = MySQL.Sync.fetchAll('SELECT * FROM fuel_stations WHERE `location` = ?', { location })
    if result then
        for k, v in pairs(result) do
            if v.fuel + amount > Config.MaxFuelReserves then
                ReserveBuyPossible = false
                QBOX:Notify(src, Lang:t("station_reserves_over_max"), 'error')
            elseif v.fuel + amount <= Config.MaxFuelReserves then
                ReserveBuyPossible = true
                OldAmount = v.fuel
                NewAmount = OldAmount + amount
            else
                return
            end
        end
    else
        return
    end
    local text = ('Purchased %sL of Reserves for: %s @ $%s / L!'):format(amount, Config.GasStations[location].label, Config.FuelReservesPrice)
    if ReserveBuyPossible and Player.Functions.RemoveMoney("bank", price, text) then
        if not Config.OwnersPickupFuel then
            MySQL.Async.execute('UPDATE fuel_stations SET fuel = ? WHERE `location` = ?', { NewAmount, location })
        else
            FuelPickupSent[location] = {
                ['src'] = src,
                ['refuelAmount'] = NewAmount,
                ['amountBought'] = amount,
            }
            TriggerClientEvent('cdn-fuel:station:client:initiatefuelpickup', src, amount, NewAmount, location)
        end
    elseif ReserveBuyPossible then
        QBOX:Notify(src, Lang:t("not_enough_money"), 'error')
    end
end)

RegisterNetEvent('cdn-fuel:station:server:fuelpickup:failed', function(location)
    local src = source
    if location then
        if FuelPickupSent[location] then
            local cid = QBOX:GetPlayer(src).PlayerData.citizenid
            MySQL.Async.execute('UPDATE fuel_stations SET fuel = ? WHERE `location` = ?', { FuelPickupSent[location]['refuelAmount'], location })
            QBOX:Notify(src, Lang:t("fuel_pickup_failed"), 'success')
            -- This will print player information just in case someone figures out a way to exploit this.
            print("User encountered an error with fuel pickup, so we are updating the fuel level anyways, and cancelling the pickup. SQL Execute Update: fuel_station level to: " ..
            FuelPickupSent[location].refuelAmount .. " | Source: " .. src .. " | Citizen Id: " .. cid .. ".")
            FuelPickupSent[location] = nil
        else
            -- They are probably exploiting in some way/shape/form.
        end
    end
end)

RegisterNetEvent('cdn-fuel:station:server:fuelpickup:finished', function(location)
    local src = source
    if location then
        if FuelPickupSent[location] then
            local cid = QBOX:GetPlayer(src).PlayerData.citizenid
            MySQL.Async.execute('UPDATE fuel_stations SET fuel = ? WHERE `location` = ?', { FuelPickupSent[location].refuelAmount, location })
            QBOX:Notify(src, string.format(Lang:t("fuel_pickup_success"), tostring(tonumber(FuelPickupSent[location].refuelAmount))), 'success')
            -- This will print player information just in case someone figures out a way to exploit this.
            if Config.FuelDebug then
                print("User successfully dropped off fuel truck, so we are updating the fuel level and clearing the pickup table. SQL Execute Update: fuel_station level to: " ..
                FuelPickupSent[location].refuelAmount .. " | Source: " .. src .. " | Citizen Id: " .. cid .. ".")
            end
            FuelPickupSent[location] = nil
        else
            -- They are probably exploiting in some way/shape/form.
        end
    end
end)

RegisterNetEvent('cdn-fuel:station:server:updatelocationname', function(newName, location)
    local src = source
    MySQL.Async.execute('UPDATE fuel_stations SET label = ? WHERE `location` = ?', { newName, location })
    QBOX:Notify(src, Lang:t("station_name_change_success") .. newName .. "!", 'success')
    TriggerClientEvent('cdn-fuel:client:updatestationlabels', -1, location, newName)
end)

-- Callbacks
lib.callback.register('cdn-fuel:server:locationpurchased', function(source, location)
    local result = MySQL.Sync.fetchAll('SELECT * FROM fuel_stations WHERE `location` = ?', { location })
    if result then
        for k, v in pairs(result) do
            local gasstationinfo = json.encode(v)
            local owned = false
            if v.owned == 1 then
                owned = true
            elseif v.owned == 0 then
                owned = false
            else
                return
            end
            return owned
        end
    else
        if Config.FuelDebug then print("No Result Fetched!!") end
    end
end)

lib.callback.register('cdn-fuel:server:doesPlayerOwnStation', function(source)
    local src = source
    local Player = QBOX:GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local result = MySQL.Sync.fetchAll('SELECT * FROM fuel_stations WHERE `owner` = ?', { citizenid })
    local tableEmpty = next(result) == nil
    if result and not tableEmpty then
        return true
    else
        return false
    end
end)

lib.callback.register('cdn-fuel:server:isowner', function(source)
    local src = source
    local Player = QBOX:GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local result = MySQL.Sync.fetchAll('SELECT * FROM fuel_stations WHERE `owner` = ? AND location = ?', { citizenid, location })
    if result then
        for _, v in pairs(result) do
            if v.owner == citizenid and v.owned == 1 then
                return true
            else
                return false
            end
        end
    else
        return false
    end
end)

lib.callback.register('cdn-fuel:server:fetchinfo', function(source, location)
    local result = MySQL.Async.fetchAll('SELECT * FROM fuel_stations WHERE location = ?', { location })
    if result then
        return result
    else
        return false
    end
end)

lib.callback.register('cdn-fuel:server:checkshutoff', function(source, location)
    return Config.GasStations[location].shutoff
end)

lib.callback.register('cdn-fuel:server:fetchlabel', function(source, location)
    MySQL.Async.fetchAll('SELECT label FROM fuel_stations WHERE location = ?', { location }, function(result)
        if result then
            return result
        else
            return false
        end
    end)
end)

-- Startup Process
local function Startup()
    local location = 0
    for value in ipairs(Config.GasStations) do
        location = location + 1
        UpdateStationLabel(location)
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource == cache.resource then
        Startup()
    end
end)