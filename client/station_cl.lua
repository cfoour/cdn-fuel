if not Config.PlayerOwnedGasStationsEnabled then return end -- This is so Player Owned Gas Stations are a Config Option, instead of forced. Set this option in shared/config.lua!
-- Variables
local QBOX = exports.qbx_core
local Renewed = exports['Renewed-Lib']:getLib()
local PedsSpawned = false
local TargetName = 'talk_to_ped'

-- These are for fuel pickup:
local CreatedEventHandler = false
local locationSwapHandler
local spawnedTankerTrailer
local spawnedDeliveryTruck
local ReservePickupData = {}

-- Functions

function UpdateStationInfo(info)
    local result = lib.callback.await('cdn-fuel:server:fetchinfo', false, CurrentLocation)
    if result then
        for _, v in pairs(result) do
            -- Reserves --
            if info == 'all' or info == 'reserves' then
                Currentreserveamount = v.fuel
                ReserveLevels = Currentreserveamount
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
            -- Fuel Station's Balance --
            if info == 'all' or info == 'balance' then
                StationBalance = v.balance
            end
        end
    end
end

exports(UpdateStationInfo, UpdateStationInfo)

local function SpawnGasStationPeds()
    if not Config.GasStations or not next(Config.GasStations) or PedsSpawned then return end
    for i = 1, #Config.GasStations do
        local current = Config.GasStations[i]
        current.pedmodel = type(current.pedmodel) == 'string' and joaat(current.pedmodel) or current.pedmodel
        Renewed.addPed({
            model = current.pedmodel,
            dist = 50,
            coords = vec3(current.pedcoords.x, current.pedcoords.y, current.pedcoords.z),
            heading = current.pedcoords.w,
            freeze = true,
            invincible = true,
            tempevents = true,
            scenario = 'WORLD_HUMAN_VALET',
            id = TargetName,
            interact = {
                distance = 4.0,    -- optional
                interactDst = 1.5, -- optional
                options = {
                    {
                        label = Lang:t('station_talk_to_ped'),
                        action = function()
                            TriggerEvent('cdn-fuel:stations:openmenu', CurrentLocation)
                        end,
                    }
                }
            }
        })
    end
    PedsSpawned = true
end

local function GenerateRandomTruckModel()
    local possibleTrucks = Config.PossibleDeliveryTrucks
    if possibleTrucks then
        return possibleTrucks[math.random(#possibleTrucks)]
    end
end

local function SpawnPickupVehicles()
    local trailer = joaat('tanker')
    local truckToSpawn = joaat(GenerateRandomTruckModel())
    if truckToSpawn then
        RequestAndLoadModel(truckToSpawn)
        RequestAndLoadModel(trailer)
        spawnedDeliveryTruck = CreateVehicle(truckToSpawn, Config.DeliveryTruckSpawns.truck, true, false)
        spawnedTankerTrailer = CreateVehicle(trailer, Config.DeliveryTruckSpawns.trailer, true, false)
        SetModelAsNoLongerNeeded(truckToSpawn) -- removes model from game memory as we no longer need it
        SetModelAsNoLongerNeeded(trailer)      -- removes model from game memory as we no longer need it
        SetEntityAsMissionEntity(spawnedDeliveryTruck, true, true)
        SetEntityAsMissionEntity(spawnedTankerTrailer, true, true)
        AttachVehicleToTrailer(spawnedDeliveryTruck, spawnedTankerTrailer, 15.0)
        SetFuel(spawnedDeliveryTruck, 100.0)

        -- Now our vehicle is spawned.
        if spawnedDeliveryTruck ~= 0 and spawnedTankerTrailer ~= 0 then
            TriggerEvent('vehiclekeys:client:SetOwner', qbx.getVehiclePlate(spawnedDeliveryTruck))
            return true
        else
            return false
        end
    end
end

-- Events
RegisterNetEvent('cdn-fuel:stations:updatelocation', function(updatedlocation)
    CurrentLocation = updatedlocation or 0
end)

RegisterNetEvent('cdn-fuel:stations:client:buyreserves', function(data)
    local location = data.location
    local price = data.price
    local amount = data.amount
    TriggerServerEvent('cdn-fuel:stations:server:buyreserves', location, price, amount)
end)

local function startTankerThread()
    CreateThread(function()
        local ped = cache.ped
        local alreadyHasTruck = false
        local hasArrivedAtLocation = false
        local VehicleDelivered = false
        local EndAwaitListener = false
        local stopNotifyTemp = false
        local AwaitingInput = false
        while true do
            Wait(100)
            if VehicleDelivered then break end
            if cache.vehicle and cache.vehicle == spawnedDeliveryTruck then
                if not alreadyHasTruck then
                    local loc = {}
                    loc = Config.GasStations[ReservePickupData.location].pedcoords
                    SetNewWaypoint(loc.x, loc.y)
                    SetUseWaypointAsDestination(true)
                    alreadyHasTruck = true
                else
                    if not CreatedEventHandler then
                        local function AwaitInput()
                            if AwaitingInput then return end
                            AwaitingInput = true
                            CreateThread(function()
                                while true do
                                    Wait(0)
                                    if EndAwaitListener or not hasArrivedAtLocation then
                                        AwaitingInput = false
                                        break
                                    end
                                    if IsControlJustReleased(2, 38) then
                                        local distBetweenTruckAndTrailer = #(GetEntityCoords(spawnedDeliveryTruck) - GetEntityCoords(spawnedTankerTrailer))
                                        if distBetweenTruckAndTrailer > 10.0 then
                                            distBetweenTruckAndTrailer = nil
                                            if not stopNotifyTemp then
                                                QBOX:Notify(Lang:t('trailer_too_far'), 'error', 7500)
                                            end
                                            stopNotifyTemp = true
                                            Wait(1000)
                                            stopNotifyTemp = false
                                        else
                                            EndAwaitListener = true
                                            local ped = cache.ped
                                            VehicleDelivered = true
                                            -- Handle Vehicle Dropoff
                                            -- Remove PolyZone --
                                            ReservePickupData.PolyZone:remove()
                                            ReservePickupData.PolyZone = nil
                                            -- Get Ped Out of Vehicle if Inside --
                                            if cache.vehicle == spawnedDeliveryTruck then
                                                TaskLeaveVehicle(ped, spawnedDeliveryTruck, 1 --[[ flags | integer ]])
                                                Wait(5000)
                                            end
                                            lib.hideTextUI()

                                            -- Remove Vehicle --
                                            DeleteEntity(spawnedDeliveryTruck)
                                            DeleteEntity(spawnedTankerTrailer)
                                            -- Send Data to Server to Put Into Station --
                                            TriggerServerEvent('cdn-fuel:station:server:fuelpickup:finished',
                                                ReservePickupData.location)
                                            -- Remove Handler
                                            RemoveEventHandler(locationSwapHandler)
                                            AwaitingInput = false
                                            CreatedEventHandler = false
                                            ReservePickupData = nil
                                            ReservePickupData = {}
                                            -- Break Loop
                                            break
                                        end
                                    end
                                end
                            end)
                            AwaitingInput = true
                        end
                        locationSwapHandler = AddEventHandler('cdn-fuel:stations:updatelocation', function(location)
                            if location == nil or location ~= ReservePickupData.location then
                                hasArrivedAtLocation = false
                                lib.hideTextUI()
                                -- Break Listener
                                EndAwaitListener = true
                                Wait(50)
                                EndAwaitListener = false
                            else
                                hasArrivedAtLocation = true
                                lib.showTextUI(Lang:t('draw_text_fuel_dropoff'), { position = 'left-center' })
                                -- Add Listner for Keypress
                                AwaitInput()
                            end
                        end)
                    end
                end
            end
        end
    end)
end

RegisterNetEvent('cdn-fuel:station:client:initiatefuelpickup',
    function(amountBought, finalReserveAmountAfterPurchase, location)
        if amountBought and finalReserveAmountAfterPurchase and location then
            ReservePickupData = nil
            ReservePickupData = {
                finalAmount = finalReserveAmountAfterPurchase,
                amountBought = amountBought,
                location = location,
            }

            if SpawnPickupVehicles() then
                QBOX:Notify(Lang:t('fuel_order_ready'), 'success')
                local truckSpawn = Config.DeliveryTruckSpawns.truck
                SetNewWaypoint(truckSpawn.x, truckSpawn.y)
                SetUseWaypointAsDestination(true)
                ReservePickupData.blip = CreateBlip(vec3(truckSpawn.x, truckSpawn.y, truckSpawn.z), 'Truck Pickup')
                SetBlipColour(ReservePickupData.blip, 5)

                -- Create Zone
                ReservePickupData.PolyZone = lib.zones.poly({
                    name = 'delivery_truck_pickup',
                    points = Config.DeliveryTruckSpawns.coords,
                    thickness = Config.DeliveryTruckSpawns.PolyZone.thickness,
                    debug = Config.PolyDebug
                })

                ReservePickupData.PolyZone.onExit = function()

                end

                ReservePickupData.PolyZone.inside = function()
                    RemoveBlip(ReservePickupData.blip)
                    ReservePickupData.blip = nil
                    startTankerThread()
                end
            else
                -- This is just a worst case scenario event, if the vehicles somehow do not spawn.
                TriggerServerEvent('cdn-fuel:station:server:fuelpickup:failed', location)
            end
        else
            return
        end
    end)

RegisterNetEvent('cdn-fuel:stations:client:purchaselocation', function(data)
    local location = data.location
    local CitizenID = QBX.PlayerData.citizenid
    CanOpen = false
    lib.callback.await('cdn-fuel:server:locationpurchased', false, function(result)
        if result then
            IsOwned = true
        else
            IsOwned = false
        end
    end, CurrentLocation)
    Wait(Config.WaitTime)

    if not IsOwned then
        TriggerServerEvent('cdn-fuel:server:buyStation', location, CitizenID)
    elseif IsOwned then
        QBOX:Notify(Lang:t('station_already_owned'), 'error', 7500)
    end
end)

RegisterNetEvent('cdn-fuel:stations:client:sellstation', function(data)
    local location = data.location
    local SalePrice = data.SalePrice
    CanSell = false
    local result = lib.callback.await('cdn-fuel:server:isowner', false, location)
    if result then
        CanSell = true
    else
        QBOX:Notify(Lang:t('station_not_owner'), 'error', 7500)
        CanSell = false
    end

    Wait(Config.WaitTime)
    if CanSell then
        TriggerServerEvent('cdn-fuel:stations:server:sellstation', location)
    else
        QBOX:Notify(Lang:t('station_cannot_sell'), 'error', 7500)
    end
end)

RegisterNetEvent('cdn-fuel:stations:client:purchasereserves:final',
    function(location, price, amount) -- Menu, seens after selecting the 'purchase reserves' option.
        local location = location
        local price = price
        local amount = amount
        CanOpen = false
        lib.callback.await('cdn-fuel:server:isowner', false, function(result)
            if result then
                CanOpen = true
            else
                QBOX:Notify(Lang:t('station_not_owner'), 'error', 7500)
                CanOpen = false
            end
        end, location)

        Wait(Config.WaitTime)
        if CanOpen then
            lib.registerContext({
                id = 'purchasereservesmenu',
                title = Lang:t('menu_station_reserves_header') .. Config.GasStations[location].label,
                options = {
                    {
                        title = Lang:t('menu_station_reserves_purchase_header') .. price,
                        description = Lang:t('menu_station_reserves_purchase_footer') .. price .. '!',
                        icon = 'fas fa-usd',
                        event = 'cdn-fuel:stations:client:buyreserves',
                        args = {
                            location = location,
                            price = price,
                            amount = amount,
                        }
                    },
                    {
                        title = Lang:t('menu_header_close'),
                        description = Lang:t('menu_ped_close_footer'),
                        icon = 'fas fa-times-circle',
                        onSelect = function()
                            lib.hideContext()
                        end,
                    },
                },
            })
            lib.showContext('purchasereservesmenu')
        else
            return
        end
    end)

RegisterNetEvent('cdn-fuel:stations:client:purchasereserves', function(data)
    local CanOpen = false
    local location = data.location
    lib.callback.await('cdn-fuel:server:isowner', function(result)
        local CitizenID = QBX.PlayerData.citizenid
        if result then
            CanOpen = true
        else
            QBOX:Notify(Lang:t('station_not_owner'), 'error', 7500)
            CanOpen = false
        end
    end, location)

    Wait(Config.WaitTime)

    if CanOpen then
        local bankmoney = QBX.PlayerData.money.bank
            local reserves = lib.inputDialog('Purchase Reserves', {
                { type = 'input',  label = 'Current Price',                                                                                                                                                                                                 default = '$' .. Config.FuelReservesPrice .. ' Per Liter', disabled = true },
                { type = 'input',  label = 'Current Reserves',                                                                                                                                                                                              default = Currentreserveamount,                            disabled = true },
                { type = 'input',  label = 'Required Reserves',                                                                                                                                                                                             default = Config.MaxFuelReserves - Currentreserveamount,   disabled = true },
                { type = 'slider', label = 'Full Reserve Cost: $' .. math.ceil(GlobalTax((Config.MaxFuelReserves - Currentreserveamount) * Config.FuelReservesPrice) + ((Config.MaxFuelReserves - Currentreserveamount) * Config.FuelReservesPrice)) .. '', default = Config.MaxFuelReserves - Currentreserveamount,   min = 0,        max = Config.MaxFuelReserves - Currentreserveamount },
            })
            if not reserves then return end
            reservesAmount = tonumber(reserves[4])
            if reserves then
                local amount = reservesAmount
                if not reservesAmount then
                    QBOX:Notify(Lang:t('station_amount_invalid'), 'error', 7500)
                    return
                end
                Reservebuyamount = tonumber(reservesAmount)
                if Reservebuyamount < 1 then
                    QBOX:Notify(Lang:t('station_more_than_one'), 'error', 7500)
                    return
                end
                if (Reservebuyamount + Currentreserveamount) > Config.MaxFuelReserves then
                    QBOX:Notify(Lang:t('station_reserve_cannot_fit'), 'error')
                else
                    if math.ceil(GlobalTax(Reservebuyamount * Config.FuelReservesPrice) + (Reservebuyamount * Config.FuelReservesPrice)) <= bankmoney then
                        local price = math.ceil(GlobalTax(Reservebuyamount * Config.FuelReservesPrice) +
                            (Reservebuyamount * Config.FuelReservesPrice))
                        TriggerEvent('cdn-fuel:stations:client:purchasereserves:final', location, price, amount)
                    else
                        QBOX:Notify(Lang:t('not_enough_money_in_bank'), 'error', 7500)
                    end
                end
            end
    end
end)

RegisterNetEvent('cdn-fuel:stations:client:changefuelprice', function(data)
    CanOpen = false
    local location = data.location
    lib.callback.await('cdn-fuel:server:isowner', false, function(result)
        local CitizenID = QBX.PlayerData.citizenid
        if result then
            CanOpen = true
        else
            QBOX:Notify(Lang:t('station_not_owner'), 'error', 7500)
            CanOpen = false
        end
    end, location)
    Wait(Config.WaitTime)
    if CanOpen then
            local fuelprice = lib.inputDialog('Fuel Prices', {
                { type = 'input',  label = 'Current Price',                  default = '$' .. Comma_Value(StationFuelPrice) .. ' Per Liter', disabled = true },
                { type = 'number', label = 'Enter New Fuel Price Per Liter', default = StationFuelPrice,                                     min = Config.MinimumFuelPrice, max = Config.MaxFuelPrice },
            })
            if not fuelprice then return end
            fuelPrice = tonumber(fuelprice[2])
            if fuelprice then
                if not fuelPrice then
                    QBOX:Notify(Lang:t('station_amount_invalid'), 'error', 7500)
                    return
                end
                NewFuelPrice = tonumber(fuelPrice)
                if NewFuelPrice < Config.MinimumFuelPrice then
                    QBOX:Notify(Lang:t('station_price_too_low'), 'error', 7500)
                    return
                end
                if NewFuelPrice > Config.MaxFuelPrice then
                    QBOX:Notify(Lang:t('station_price_too_high'), 'error')
                else
                    TriggerServerEvent('cdn-fuel:station:server:updatefuelprice', NewFuelPrice, CurrentLocation)
                end
            end
        
    end
end)

RegisterNetEvent('cdn-fuel:stations:client:sellstation:menu',
    function(data) -- Menu, seen after selecting the Sell this Location option.
        local location = data.location
        lib.callback.await('cdn-fuel:server:isowner', false, function(result)
            if result then
                CanOpen = true
            else
                QBOX:Notify(Lang:t('station_not_owner'), 'error', 7500)
                CanOpen = false
            end
        end, CurrentLocation)
        Wait(Config.WaitTime)
        if CanOpen then
            local GasStationCost = Config.GasStations[location].cost + GlobalTax(Config.GasStations[location].cost)
            local SalePrice = math.percent(Config.GasStationSellPercentage, GasStationCost)
            lib.registerContext({
                id = 'sellstationmenu',
                title = Lang:t('menu_sell_station_header') .. Config.GasStations[location].label,
                options = {
                    {
                        title = Lang:t('menu_sell_station_header_accept'),
                        description = Lang:t('menu_sell_station_footer_accept') .. Comma_Value(SalePrice) .. '.',
                        icon = 'fas fa-usd',
                        event = 'cdn-fuel:stations:client:sellstation',
                        args = {
                            location = location,
                            SalePrice = SalePrice,
                        }
                    },
                },
            })
            lib.showContext('sellstationmenu')
            TriggerServerEvent('cdn-fuel:stations:server:stationsold', location)
        end
    end)

RegisterNetEvent('cdn-fuel:stations:client:changestationname',
    function() -- Menu for changing the label of the owned station.
        CanOpen = false
        lib.callback.await('cdn-fuel:server:isowner', false, function(result)
            if result then
                CanOpen = true
            else
                QBOX:Notify(Lang:t('station_not_owner'), 'error', 7500)
                CanOpen = false
            end
        end, CurrentLocation)
        Wait(Config.WaitTime)
        if CanOpen then
                local NewName = lib.inputDialog('Name Changer', {
                    { type = 'input', label = 'Current Name',           default = Config.GasStations[CurrentLocation].label, disabled = true },
                    { type = 'input', label = 'Enter New Station Name', placeholder = 'New Name' },
                })
                if not NewName then return end
                NewNameName = NewName[2]
                if NewName then
                    if not NewNameName then
                        QBOX:Notify(Lang:t('station_name_invalid'), 'error', 7500)
                        return
                    end
                    NewName = NewNameName
                    if type(NewName) ~= 'string' then
                        QBOX:Notify(Lang:t('station_name_invalid'), 'error')
                        return
                    end

                    if string.len(NewName) > Config.NameChangeMaxChar then
                        QBOX:Notify(Lang:t('station_name_too_long'), 'error')
                        return
                    end
                    if string.len(NewName) < Config.NameChangeMinChar then
                        QBOX:Notify(Lang:t('station_name_too_short'), 'error')
                        return
                    end
                    Wait(100)
                    TriggerServerEvent('cdn-fuel:station:server:updatelocationname', NewName, CurrentLocation)
                end
            
        end
    end)

RegisterNetEvent('cdn-fuel:stations:client:managemenu',
    function(location) -- Menu, seen after selecting the Manage this Location Option.
        location = CurrentLocation
        lib.callback.await('cdn-fuel:server:isowner', false, function(result)
            local CitizenID = QBX.PlayerData.citizenid
            if result then
                CanOpen = true
            else
                QBOX:Notify(Lang:t('station_not_owner'), 'error', 7500)
                CanOpen = false
            end
        end, CurrentLocation)
        UpdateStationInfo('all')
        if Config.PlayerControlledFuelPrices then CanNotChangeFuelPrice = false else CanNotChangeFuelPrice = true end
        Wait(5)
        Wait(Config.WaitTime)
        if CanOpen then
            local GasStationCost = (Config.GasStations[location].cost + GlobalTax(Config.GasStations[location].cost))
            lib.registerContext({
                id = 'stationmanagemenu',
                title = Lang:t('menu_manage_header') .. Config.GasStations[location].label,
                options = {
                    {
                        title = Lang:t('menu_manage_reserves_header'),
                        description = 'Buy your reserve fuel here!',
                        icon = 'fas fa-info-circle',
                        arrow = true, -- puts arrow to the right
                        event = 'cdn-fuel:stations:client:purchasereserves',
                        args = {
                            location = location,
                        },
                        metadata = {
                            { label = 'Reserve Stock: ', value = ReserveLevels .. Lang:t('menu_manage_reserves_footer_1') .. Config.MaxFuelReserves },
                        },
                        disabled = ReservesNotBuyable,
                    },
                    {
                        title = Lang:t('menu_alter_fuel_price_header'),
                        description = 'I want to change the price of fuel at my Gas Station!',
                        icon = 'fas fa-usd',
                        event = 'cdn-fuel:stations:client:changefuelprice',
                        args = {
                            location = location,
                        },
                        metadata = {
                            { label = 'Current Fuel Price: ', value = '$' .. Comma_Value(StationFuelPrice) .. Lang:t('input_alter_fuel_price_header_2') },
                        },
                        disabled = CanNotChangeFuelPrice,
                    },
                    {
                        title = Lang:t('menu_manage_company_funds_header'),
                        description = Lang:t('menu_manage_company_funds_footer'),
                        icon = 'fas fa-usd',
                        event = 'cdn-fuel:stations:client:managefunds'
                    },
                    {
                        title = Lang:t('menu_manage_change_name_header'),
                        description = Lang:t('menu_manage_change_name_footer'),
                        icon = 'fas fa-pen',
                        event = 'cdn-fuel:stations:client:changestationname',
                        disabled = not Config.GasStationNameChanges,
                    },
                    {
                        title = Lang:t('menu_sell_station_header_accept'),
                        description = Lang:t('menu_manage_sell_station_footer') ..
                            Comma_Value(math.percent(Config.GasStationSellPercentage, GasStationCost)),
                        icon = 'fas fa-usd',
                        arrow = false, -- puts arrow to the right
                        event = 'cdn-fuel:stations:client:sellstation:menu',
                        args = {
                            location = location,
                        },
                    },
                },
            })
            lib.showContext('stationmanagemenu')
        end
    end)

RegisterNetEvent('cdn-fuel:stations:client:managefunds',
    function(location) -- Menu, seen after selecting the Manage this Location Option.
        lib.callback.await('cdn-fuel:server:isowner', false, function(result)
            local CitizenID = QBX.PlayerData.citizenid
            if result then
                CanOpen = true
            else
                QBOX:Notify(Lang:t('station_not_owner'), 'error', 7500)
                CanOpen = false
            end
        end, CurrentLocation)
        UpdateStationInfo('all')
        Wait(5)
        Wait(Config.WaitTime)
        if CanOpen then
            lib.registerContext({
                id = 'managefundsmenu',
                title = Lang:t('menu_manage_company_funds_header_2') .. Config.GasStations[CurrentLocation].label,
                options = {
                    {
                        title = Lang:t('menu_manage_company_funds_withdraw_header'),
                        description = Lang:t('menu_manage_company_funds_withdraw_footer'),
                        icon = 'fas fa-arrow-left',
                        event = 'cdn-fuel:stations:client:WithdrawFunds',
                        args = {
                            location = location,
                        }
                    },
                    {
                        title = Lang:t('menu_manage_company_funds_deposit_header'),
                        description = Lang:t('menu_manage_company_funds_deposit_footer'),
                        icon = 'fas fa-arrow-right',
                        event = 'cdn-fuel:stations:client:DepositFunds',
                        args = {
                            location = location,
                        }
                    },
                    {
                        title = Lang:t('menu_manage_company_funds_return_header'),
                        description = Lang:t('menu_manage_company_funds_return_footer'),
                        icon = 'fas fa-circle-left',
                        event = 'cdn-fuel:stations:client:managemenu',
                        args = {
                            location = location,
                        }
                    },
                },
            })
            lib.showContext('managefundsmenu')
        end
    end)

RegisterNetEvent('cdn-fuel:stations:client:WithdrawFunds', function(data)
    CanOpen = false
    local location = CurrentLocation
    lib.callback.await('cdn-fuel:server:isowner', false, function(result)
        if result then
            CanOpen = true
        else
            QBOX:Notify(Lang:t('station_not_owner'), 'error', 7500)
            CanOpen = false
        end
    end, CurrentLocation)

    Wait(Config.WaitTime)

    if CanOpen then
        UpdateStationInfo('balance')
        Wait(50)
        local Withdraw = lib.inputDialog('Withdraw Funds', {
            { type = 'input',  label = 'Current Station Balance', default = '$' .. Comma_Value(StationBalance), disabled = true },
            { type = 'number', label = 'Withdraw Amount' },
        })
        if not Withdraw then return end
        WithdrawAmounts = tonumber(Withdraw[2])
        if Withdraw then
            local amount = tonumber(WithdrawAmounts)
            if not WithdrawAmounts then
                QBOX:Notify(Lang:t('station_amount_invalid'), 'error', 7500)
                return
            end
            if amount < 1 then
                QBOX:Notify(Lang:t('station_withdraw_too_little'), 'error', 7500)
                return
            end
            if amount > StationBalance then
                QBOX:Notify(Lang:t('station_withdraw_too_much'), 'error', 7500)
                return
            end
            WithdrawAmount = tonumber(amount)
            if (StationBalance - WithdrawAmount) < 0 then
                QBOX:Notify(Lang:t('station_withdraw_too_much'), 'error', 7500)
            else
                TriggerServerEvent('cdn-fuel:station:server:Withdraw', amount, location, StationBalance)
            end
        end
    end
end)

RegisterNetEvent('cdn-fuel:stations:client:DepositFunds', function(data)
    CanOpen = false
    local location = CurrentLocation
    lib.callback.await('cdn-fuel:server:isowner', function(result)
        if result then
            CanOpen = true
        else
            QBOX:Notify(Lang:t('station_not_owner'), 'error', 7500)
            CanOpen = false
        end
    end, CurrentLocation)
    Wait(Config.WaitTime)
    if CanOpen then
        local bankmoney = QBX.PlayerData.money.bank
        UpdateStationInfo('balance')
        Wait(50)
            local Deposit = lib.inputDialog('Deposit Funds', {
                { type = 'input',  label = 'Current Station Balance', default = '$' .. Comma_Value(StationBalance), disabled = true },
                { type = 'number', label = 'Deposit Amount' },
            })
            if not Deposit then return end
            DepositAmounts = tonumber(Deposit[2])
            if Deposit then
                local amount = tonumber(DepositAmounts)
                if not DepositAmounts then
                    QBOX:Notify(Lang:t('station_amount_invalid'), 'error', 7500)
                    return
                end
                if amount < 1 then
                    QBOX:Notify(Lang:t('station_deposit_too_little'), 'error', 7500)
                    return
                end
                DepositAmount = tonumber(amount)
                if (DepositAmount) > bankmoney then
                    QBOX:Notify(Lang:t('station_deposity_too_much'), 'error')
                else
                    TriggerServerEvent('cdn-fuel:station:server:Deposit', amount, location, StationBalance)
                end
            end
        
    end
end)

RegisterNetEvent('cdn-fuel:stations:client:Shutoff', function(location)
    TriggerServerEvent('cdn-fuel:stations:server:Shutoff', location)
end)

RegisterNetEvent('cdn-fuel:stations:client:purchasemenu', function(location)
    local bankmoney = QBX.PlayerData.money.bank
    local costofstation = Config.GasStations[location].cost + GlobalTax(Config.GasStations[location].cost)

    if Config.OneStationPerPerson == true then
        lib.callback.await('cdn-fuel:server:doesPlayerOwnStation', false, function(result)
            if result then
                PlayerOwnsAStation = true
            else
                PlayerOwnsAStation = false
            end
        end)

        Wait(Config.WaitTime)

        if PlayerOwnsAStation == true then
            QBOX:Notify('You can only buy one station, and you already own one!', 'error')
            return
        end
    end


    if bankmoney < costofstation then
        QBOX:Notify(Lang:t('not_enough_money_in_bank') .. ' $' .. costofstation, 'error', 7500)
        return
    end

    lib.registerContext({
        id = 'purchasemenu',
        title = Config.GasStations[location].label,
        options = {
            {
                title = Lang:t('menu_purchase_station_confirm_header'),
                description = 'I am interested in purchasing this station!',
                icon = 'fas fa-usd',
                arrow = true, -- puts arrow to the right
                event = 'cdn-fuel:stations:client:purchaselocation',
                args = {
                    location = location,
                },
                metadata = {
                    { label = 'Station Cost: $', value = Comma_Value(costofstation) .. Lang:t('menu_purchase_station_header_2') },
                },
            },
        },
    })
    lib.showContext('purchasemenu')
end)

RegisterNetEvent('cdn-fuel:stations:openmenu', function() -- Menu #1, the first menu you see.
    DisablePurchase = true
    DisableOwnerMenu = true
    ShutOffDisabled = false

    lib.callback.await('cdn-fuel:server:locationpurchased', false, function(result)
        if result then
            DisablePurchase = true
        else
            DisablePurchase = false
            DisableOwnerMenu = true
        end
    end, CurrentLocation)

    lib.callback.await('cdn-fuel:server:isowner', false, function(result)
        if result then
            DisableOwnerMenu = false
        else
            DisableOwnerMenu = true
        end
    end, CurrentLocation)

    if Config.EmergencyShutOff then
        local result = lib.callback.await('cdn-fuel:server:checkshutoff', false, CurrentLocation)
        if result == true then
            PumpState = 'disabled.'
        elseif result == false then
            PumpState = 'enabled.'
        else
            PumpState = 'nil'
        end
    else
        PumpState = 'enabled.'
        ShutOffDisabled = true
    end

    Wait(Config.WaitTime)

    lib.registerContext({
        id = 'station_main_menu',
        title = Config.GasStations[CurrentLocation].label,
        options = {
            {
                title = Lang:t('menu_ped_manage_location_header'),
                description = Lang:t('menu_ped_manage_location_footer'),
                icon = 'fas fa-gas-pump',
                event = 'cdn-fuel:stations:client:managemenu',
                args = CurrentLocation,
                disabled = DisableOwnerMenu,
            },
            {
                title = Lang:t('menu_ped_purchase_location_header'),
                description = Lang:t('menu_ped_purchase_location_footer'),
                icon = 'fas fa-usd',
                event = 'cdn-fuel:stations:client:purchasemenu',
                args = CurrentLocation,
                disabled = DisablePurchase,
            },
            {
                title = Lang:t('menu_ped_emergency_shutoff_header'),
                description = Lang:t('menu_ped_emergency_shutoff_footer') .. PumpState,
                icon = 'fas fa-gas-pump',
                event = 'cdn-fuel:stations:client:Shutoff',
                args = CurrentLocation,
                disabled = ShutOffDisabled,
            },
        },
    })
    lib.showContext('station_main_menu')
end)

-- Spawn the Peds for Gas Stations when the resource starts.
SpawnGasStationPeds()
