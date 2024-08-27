if not Config.ElectricVehicleCharging then return end
if not lib then return end

local QBOX = exports.qbx_core

-- Variables

local HoldingElectricNozzle = false
local RefuelPossibleAmount = 0
local RefuelPurchaseType = 'bank'

if Config.PumpHose then
    Rope = nil
end

-- Start
AddEventHandler('onResourceStart', function(resource)
    if resource == cache.resource then
        DeleteObject(ElectricNozzle)
        HoldingElectricNozzle = false
    end
end)

-- Functions
function IsHoldingElectricNozzle()
    return HoldingElectricNozzle
end

exports('IsHoldingElectricNozzle', IsHoldingElectricNozzle)

function SetElectricNozzle(state)
    if state == 'putback' then
        --TriggerServerEvent('InteractSound_SV:PlayOnSource', 'putbackcharger', 0.4)
        Wait(250)
        DeleteObject(ElectricNozzle)
        HoldingElectricNozzle = false
        if Config.PumpHose == true then
            RopeUnloadTextures()
            DeleteRope(Rope)
        end
    elseif state == 'pickup' then
        TriggerEvent('cdn-fuel:client:grabelectricnozzle')
        HoldingElectricNozzle = true
    end
end
exports('SetElectricNozzle', SetElectricNozzle)

-- Events
RegisterNetEvent('cdn-electric:client:OpenContextMenu', function(total, fuelamounttotal, purchasetype)
    local options = {
        {
            title = Lang:t('menu_purchase_station_confirm_header'),
            description = Lang:t('menu_electric_accept'),
            icon = 'fas fa-check-circle',
            event = 'cdn-fuel:client:electric:ChargeVehicle',
            args = {
                fuelamounttotal = fuelamounttotal,
                purchasetype = purchasetype,
            }
        },
    }
    lib.registerContext({
        id = 'electric_confirmation_menu',
        title = Lang:t('menu_purchase_station_header_1') .. math.ceil(total) .. Lang:t('menu_purchase_station_header_2'),
        options = options
    })
    lib.showContext('electric_confirmation_menu')
end)

RegisterNetEvent('cdn-fuel:client:electric:FinalMenu', function(purchasetype)
    local money = nil
    if purchasetype == 'bank' then money = QBX.PlayerData.money.bank elseif purchasetype == 'cash' then money = QBX.PlayerData.money.cash end
    FuelPrice = (1 * Config.ElectricChargingPrice)
    local vehicle = GetClosestVehicle()
    -- Police Discount Math --
    if Config.EmergencyServicesDiscount.enabled and ((Config.EmergencyServicesDiscount.emergency_vehicles_only == true and GetVehicleClass(vehicle) == 18) or Config.EmergencyServicesDiscount.emergency_vehicles_only == true) then
        local discountedJobs = Config.EmergencyServicesDiscount.job
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
        if shouldRecieveDiscount == true and not QBX.PlayerData.job.onduty and Config.EmergencyServicesDiscount.on_duty_only then
            QBOX:Notify(Lang:t('you_are_discount_eligible'), 'primary', 7500)
            shouldRecieveDiscount = false
        end
        if shouldRecieveDiscount then
            local discount = Config.EmergencyServicesDiscount.discount
            if discount > 100 then
                discount = 100
            else
                if discount <= 0 then discount = 0 end
            end
            if discount ~= 0 then
                if discount == 100 then
                    FuelPrice = 0
                else
                    discount = discount / 100
                    FuelPrice = FuelPrice - (FuelPrice * discount)
                end
            end
        end
    end
    local curfuel = GetFuel(vehicle)
    local finalfuel
    if curfuel < 10 then finalfuel = string.sub(curfuel, 1, 1) else finalfuel = string.sub(curfuel, 1, 2) end
    local maxfuel = (100 - finalfuel - 1)
    local wholetankcost = (FuelPrice * maxfuel)
    local wholetankcostwithtax = math.ceil((wholetankcost) + GlobalTax(wholetankcost))
    Electricity = lib.inputDialog('Electric Charger', {
        { type = 'input', label = 'Electric Price', default = '$' .. FuelPrice .. '/KWh', disabled = true},
        { type = 'input', label = 'Current Charge', default = finalfuel .. ' KWh', disabled = true },
        { type = 'input', label = 'Required Full Charge', default = maxfuel, disabled = true },
        { type = 'slider', label = 'Full Charge Cost: $' .. wholetankcostwithtax .. '', default = maxfuel, min = 0, max = maxfuel },
    })
    if not Electricity then return end
    ElectricityAmount = tonumber(Electricity[4])
    if Electricity then
        if not ElectricityAmount then
            return
        end
        if not HoldingElectricNozzle then
            QBOX:Notify(Lang:t('electric_no_nozzle'), 'error', 7500)
            return
        end
        if (ElectricityAmount + finalfuel) >= 100 then
            QBOX:Notify(Lang:t('tank_already_full'), 'error')
        else
            if GlobalTax(ElectricityAmount * FuelPrice) + (ElectricityAmount * FuelPrice) <= money then
                TriggerServerEvent('cdn-fuel:server:electric:OpenMenu', ElectricityAmount, IsInGasStation(), false, purchasetype, FuelPrice)
            else
                QBOX:Notify(Lang:t('not_enough_money'), 'error', 7500)
            end
        end
    end
end)

RegisterNetEvent('cdn-fuel:client:electric:SendMenuToServer', function()
    local vehicle = GetClosestVehicle()
    local vehModel = GetEntityModel(vehicle)
    local vehiclename = string.lower(GetDisplayNameFromVehicleModel(vehModel))
    AwaitingElectricCheck = true
    FoundElectricVehicle = false
    :: ChargingMenu :: -- Register the starting point for the goto
    if not AwaitingElectricCheck then return end
    if not AwaitingElectricCheck and FoundElectricVehicle then
        local CurFuel = GetVehicleFuelLevel(vehicle)
        local playercashamount = QBX.PlayerData.money.cash
        if not IsHoldingElectricNozzle() then
            QBOX:Notify(Lang:t('electric_no_nozzle'), 'error', 7500)
            return
        end
        if CurFuel < 95 then
            lib.registerContext({
                id = 'electricmenu',
                title = Config.GasStations[FetchCurrentLocation()].label,
                options = {
                    {
                        title = Lang:t('menu_header_cash'),
                        description = Lang:t('menu_pay_with_cash') .. playercashamount,
                        icon = 'fas fa-usd',
                        event = 'cdn-fuel:client:electric:FinalMenu',
                        args = 'cash',
                    },
                    {
                        title = Lang:t('menu_header_bank'),
                        description = Lang:t('menu_pay_with_bank'),
                        icon = 'fas fa-credit-card',
                        event = 'cdn-fuel:client:electric:FinalMenu',
                        args = 'bank',
                    },
                },
            })
            lib.showContext('electricmenu')
        else
            QBOX:Notify(Lang:t('tank_already_full'), 'error')
        end
    else
        if AwaitingElectricCheck then
            if Config.ElectricVehicles[vehiclename] then
                AwaitingElectricCheck = false
                FoundElectricVehicle = true
                Wait(50)
                goto ChargingMenu -- Attempt to go to the charging menu, now that we have found that there was an electric vehicle.
            else
                FoundElectricVehicle = false
                AwaitingElectricCheck = false
                Wait(50)
                goto ChargingMenu -- Attempt to go to the charging menu, now that we have not found that there was an electric vehicle.
            end
        else
            QBOX:Notify(Lang:t('electric_vehicle_not_electric'), 'error', 7500)
        end
    end
end)
RegisterNetEvent('cdn-fuel:client:electric:ChargeVehicle', function(data)
    if data.purchasetype == 'cash' then
        purchasetype = 'cash'
    else
        purchasetype = data.purchasetype
    end

    if data.purchasetype == 'cash' then
        amount = data.fuelamounttotal
    elseif not data.fuelamounttotal then
        amount = data.fuelamounttotal
    end

    if not HoldingElectricNozzle then return end
    amount = tonumber(amount)
    if amount < 1 then return end
    if amount < 10 then fuelamount = string.sub(amount, 1, 1) else fuelamount = string.sub(amount, 1, 2) end
    local FuelPrice = (Config.ElectricChargingPrice * 1)
    local vehicle = GetClosestVehicle()
    -- Police Discount Math --
    if Config.EmergencyServicesDiscount.enabled == true and (Config.EmergencyServicesDiscount['emergency_vehicles_only'] == false or (Config.EmergencyServicesDiscount['emergency_vehicles_only'] == true and GetVehicleClass(vehicle) == 18)) then
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
                    FuelPrice = 0
                else
                    discount = discount / 100
                    FuelPrice = FuelPrice - (FuelPrice * discount)
                end
            else
              return
            end
        end
    end

    local refillCost = (fuelamount * FuelPrice) + GlobalTax(fuelamount * FuelPrice)
    local vehicle = GetClosestVehicle()
    local ped = cache.ped
    local time = amount * Config.RefuelTime
    if amount < 10 then time = 10 * Config.RefuelTime end
    local vehicleCoords = GetEntityCoords(vehicle)
    if IsInGasStation() then
        if IsPlayerNearVehicle() then
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
                        TriggerServerEvent('cdn-fuel:server:PayForFuel', refillCost, purchasetype, FuelPrice)
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
            TriggerServerEvent('InteractSound_SV:PlayOnSource', 'charging', 0.3)
            if lib.progressCircle({
                        duration = time,
                        label = Lang:t('prog_electric_charging'),
                        position = 'bottom',
                        useWhileDead = false,
                        canCancel = true,
                        disable = { move = true, combat = true },
                    }) then
                    refueling = false
                    if purchasetype == 'cash' then
                        TriggerServerEvent('cdn-fuel:server:PayForFuel', refillCost, purchasetype, FuelPrice, true)
                    elseif purchasetype == 'bank' then
                        TriggerServerEvent('cdn-fuel:server:PayForFuel', refillCost, purchasetype, FuelPrice, true)
                    end
                    local curfuel = GetFuel(vehicle)
                    local finalfuel = (curfuel + fuelamount)
                    if finalfuel > 99 and finalfuel < 100 then
                        SetFuel(vehicle, 100)
                    else
                        SetFuel(vehicle, finalfuel)
                    end
                    StopAnimTask(ped, Config.RefuelAnimationDictionary, Config.RefuelAnimation, 3.0, 3.0, -1, 2, 0, 0, 0, 0)
                    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'chargestop', 0.4)
            else
                refueling = false
                Cancelledrefuel = true
                StopAnimTask(ped, Config.RefuelAnimationDictionary, Config.RefuelAnimation, 3.0, 3.0, -1, 2, 0, 0, 0, 0)
                TriggerServerEvent('InteractSound_SV:PlayOnSource', 'chargestop', 0.4)
            end
        end
    else
        return
    end
end)

RegisterNetEvent('cdn-fuel:client:grabelectricnozzle', function()
    local ped = cache.ped
    if HoldingElectricNozzle then return end
    lib.playAnim(ped, 'anim@am_hold_up@male', 'shoplift_high', 2.0, 8.0, -1, 50, 0, 0, 0, 0)
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'pickupnozzle', 0.4)
    Wait(300)
    StopAnimTask(ped, 'anim@am_hold_up@male', 'shoplift_high', 1.0)
    ElectricNozzle = CreateObject(joaat('electric_nozzle'), 1.0, 1.0, 1.0, true, true, false)
    local lefthand = GetPedBoneIndex(ped, 18905)
    AttachEntityToEntity(ElectricNozzle, ped, lefthand, 0.24, 0.10, -0.052 --[[FWD BWD]], -45.0 --[[ClockWise]],
        120.0 --[[Weird Middle Axis]], 75.00 --[[Counter Clockwise]], 0, 1, 0, 1, 0, 1)
    local grabbedelectricnozzlecoords = GetEntityCoords(ped)
    HoldingElectricNozzle = true
    if Config.PumpHose == true then
        local pumpCoords, pump = GetClosestPump(grabbedelectricnozzlecoords, true)
        RopeLoadTextures()
        while not RopeAreTexturesLoaded() do
            Wait(0)
            RopeLoadTextures()
        end
        while not pump do
            Wait(0)
        end
        Rope = AddRope(pumpCoords.x, pumpCoords.y, pumpCoords.z, 0.0, 0.0, 0.0, 3.0, Config.RopeType['electric'], 1000.0, 0.0, 1.0, false, false, false, 1.0, true)
        while not Rope do
            Wait(0)
        end
        ActivatePhysics(Rope)
        Wait(100)
        local nozzlePos = GetEntityCoords(ElectricNozzle)
        nozzlePos = GetOffsetFromEntityInWorldCoords(ElectricNozzle, -0.005, 0.185, -0.05)
        AttachEntitiesToRope(Rope, pump, ElectricNozzle, pumpCoords.x, pumpCoords.y, pumpCoords.z + 1.76, nozzlePos.x, nozzlePos.y, nozzlePos.z, 5.0, false, false, nil, nil)
    end

    CreateThread(function()
        while HoldingElectricNozzle do
            local currentcoords = GetEntityCoords(ped)
            local dist = #(grabbedelectricnozzlecoords - currentcoords)
            if dist > 7.5 then
                HoldingElectricNozzle = false
                DeleteObject(ElectricNozzle)
                QBOX:Notify(Lang:t('nozzle_cannot_reach'), 'error')
                if Config.PumpHose == true then
                    RopeUnloadTextures()
                    DeleteRope(Rope)
                end
            end
            Wait(2500)
        end
    end)
end)
RegisterNetEvent('cdn-fuel:client:electric:RefuelMenu', function()
    TriggerEvent('cdn-fuel:client:electric:SendMenuToServer')
end)

-- Threads
if Config.ElectricChargerModel then
    CreateThread(function()
        lib.requestModel('electric_charger', 10000)
        for i = 1, #Config.GasStations do
            local gStastion = Config.GasStations[i]
            if gStastion.electricChargerCoords ~= nil then
                local heading = gStastion.electricChargerCoords[4] - 180 gStastion.electriccharger = CreateObject('electric_charger', gStastion.electricChargerCoords.x, gStastion.electricChargerCoords.y, gStastion.electricChargerCoords.z, false, true, true)
                SetEntityHeading(gStastion.electriccharger, heading)
                FreezeEntityPosition(gStastion.electriccharger, true)
            end
        end
    end)
end

-- Resource Stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for i = 1, #Config.GasStations do
            if Config.GasStations[i].electricChargerCoords ~= nil then
                DeleteEntity(Config.GasStations[i].electriccharger)
                if IsHoldingElectricNozzle() then DeleteEntity(ElectricNozzle) end
            end
        end
        if Config.PumpHose then
            RopeUnloadTextures()
            DeleteObject(Rope)
        end
    end
end)

exports.interact:AddModelInteraction({
    model = `electric_charger`,
    offset = vec3(0.0, 0.0, 1.0), -- optional
    distance = 4.0, -- optional
    interactDst = 1.5, -- optional
    id = 'electric_options', -- needed for removing interactions
    options = {
        {
            label = Lang:t('grab_electric_nozzle'),
            event = 'cdn-fuel:client:grabelectricnozzle',
            canInteract = function()
                if not IsHoldingElectricNozzle() and not cache.vehicle then
                    return true
                end
            end
        },
        {
            label = Lang:t('return_nozzle'),
            event = 'cdn-fuel:client:returnnozzle',
            canInteract = function()
                if IsHoldingElectricNozzle() and not refueling then
                    return true
                end
            end
        },
    },
})