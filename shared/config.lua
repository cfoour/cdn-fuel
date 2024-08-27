Config = {}
Config.FuelDebug = false                -- Used for debugging, although there are not many areas in yet (Default: false) + Enables Setfuel Commands (0, 50, 100).
Config.PolyDebug = false                -- Enables PolyZones Debugging to see PolyZones!
Config.ShowNearestGasStationOnly = true -- When enabled, only the nearest gas stations will be shown on the map.
Config.LeaveEngineRunning = false       -- When true, the vehicle's engine will be left running upon exit if the player *HOLDS* F.
Config.CostMultiplier = 1               -- Amount to multiply 1 by. This indicates fuel price. (Default: $3.0/l or 3.0)
Config.GlobalTax = 0.1                  -- The tax, in %, that people will be charged at the pump. (Default: 15% or 15.0)
Config.FuelDecor = '_FUEL_LEVEL'        -- Do not touch! (Default: '_FUEL_LEVEL')
Config.RefuelTime = 600                 -- Highly recommended to leave at 600. This value will be multiplied times the amount the player is fueling for the progress bar and cancellation logic! DON'T GO BELOW 250, performance WILL drop!

-- 2.1.1 Update --
Config.OwnersPickupFuel = true -- If an owner buys fuel, they will have to go pick it up at a configured location.
Config.PossibleDeliveryTrucks = {
    'hauler',
    'phantom',
    'packer',
    'phantom3', --  This is a fast version of the normal phantom.
}
Config.DeliveryTruckSpawns = {
    trailer = vector4(1724.0, -1649.7, 112.57, 194.24),
    truck = vector4(1727.08, -1664.01, 112.62, 189.62),
    coords = {
        vector2(1724.62, -1672.36),
        vector2(1719.01, -1648.33),
        vector2(1730.99, -1645.62),
        vector2(1734.42, -1673.32),
    },
    thickness = 5.5,

}
-- 2.1.1 End

-- 2.1.0 Update
Config.EmergencyServicesDiscount = {
    enabled = true,                 -- Enables Emergency Services Getting a discount based on the value below for Refueling & Electricity Charging Cost
    discount = 80,                  -- % Discount off of price.
    emergency_vehicles_only = true, -- Only allows discounts to be applied to Emergency Vehicles
    on_duty_only = true,            -- Discount only applies while on duty.
    job = {
        'police',
        'lssd',
        'ambulance',
        --'firefighter',
    }
}

Config.Ox = {
    Inventory = true, -- Uses OX_Inventory's metadata instead of QB-Inventory's.
    Menu = true,      -- Uses OX Libraries instead of qb-menu.
    Input = true,     -- Uses Ox Input Dialog instead of qb-input.
    DrawText = true,  -- Uses Ox DrawText instead of qb-core DrawText.
    Progress = true   -- Uses Ox ProgressBar instead of progressbar.
}

Config.PumpHose = true -- If true, it creates a hose from the pump to the nozzle the client is holding, to give it a more realistic feel.

Config.RopeType = { fuel = 1, electric = 1 }

Config.FaceTowardsVehicle = true -- Ped will turn towards the entity's boot bone for refueling, sometimes can result in incorrect nozzle placement when refueling.
Config.VehicleShutoffOnLowFuel = {
    shutOffLevel = 0.55,
    sounds = {
        enabled = true,
        audio_bank = 'DLC_PILOT_ENGINE_FAILURE_SOUNDS',
        sound = 'Landing_Tone'
    }
}

-- 2.1.0 End

-- Phone --
Config.RenewedPhonePayment = false -- Enables use of Renewed-Phone Payment System and Notifications

-- Syphoning --
Config.UseSyphoning = true         -- Follow the Syphoning Install Guide to enable this option!
Config.SyphonDebug = false         -- Used for Debugging the syphon portion!
Config.SyphonKitCap = 50           -- Maximum amount (in L) the syphon kit can fit!
Config.SyphonPoliceCallChance = 25 -- Math.Random(1, 100) Default: 25%

--- Jerry Can -----
Config.UseJerryCan = true -- Enable the Jerry Can functionality. Will only work if properly installed.
Config.JerryCanCap = 50   -- Maximum amount (in L) the jerrycan can fit! (Default: 50L)
Config.JerryCanPrice = 30 -- The price of a jerry can, not including tax.
Config.JerryCanGas = 25   -- The amount of Gas that the Jerry Can you purchase comes with. This should not be bigger that your Config.JerryCanCap!

-- Animations --
Config.StealAnimDict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@'   -- Used for Syphoning
Config.StealAnim = 'machinic_loop_mechandplayer'                    -- Used for Syphoning
Config.JerryCanAnimDict = 'weapon@w_sp_jerrycan'                    -- Used for Syphoning & Jerry Can
Config.JerryCanAnim = 'fire'                                        -- Used for Syphoning & Jerry Can
Config.RefuelAnimation = 'gar_ig_5_filling_can'                     -- This is for refueling and charging.
Config.RefuelAnimationDictionary = 'timetable@gardener@filling_can' -- This is for refueling and charging.

--- Player Owned Gas (Gasoline) Ergonomic Refueling Stations (Poggers) ---
Config.PlayerOwnedGasStationsEnabled = true -- When true, peds will be located at all gas stations, and players will be able to talk with peds & purchase gas stations, having to manage fuel supplies.
Config.StationFuelSalePercentage = 0.45     -- % of sales that the station gets. If they sell 4 Liters of Gas for $16 (not including taxes), they will get 16*Config.StationFuelSalePercentage back from the sale. Treat this as tax, also, it balances the profit margins a bit.
Config.EmergencyShutOff = false             -- When true, players can walk up to the ped and shut off the pumps at a gas station. While false, this option is disabled, because it can obviously be an issue.
Config.UnlimitedFuel = false                -- When true, the fuel stations will not require refuelling by gas station owners, this is for the early stages of implementation.
Config.MaxFuelReserves = 100000             -- This is the maximum amount that the fuel station's reserves can hold.
Config.FuelReservesPrice = 1.0              -- This is the price of fuel reserves for gas station owners.
Config.GasStationSellPercentage = 70        -- This is the percentage that players will get of the gas stations price, when they sell a location!
Config.MinimumFuelPrice = 1                 -- This is the minimum value you want to let players set their fuel prices to.
Config.MaxFuelPrice = 6                     -- This is the maximum value you want to let players set their fuel prices to.
Config.PlayerControlledFuelPrices = true    -- This gives you the option to disable people being able to control fuel prices. When true, players can control the fuel prices via to management menu for the location.
Config.GasStationNameChanges = true         -- This gives you the option to disable people being able to change the name of their gas station, only recommended if it becomes a problem.
Config.NameChangeMinChar = 10               -- This is the minimum length that a Gas Station's name must be.
Config.NameChangeMaxChar = 25               -- This is the maximum length that a Gas Station's name must be.
Config.WaitTime = 400                       -- This is the wait time after callbacks, if you are having issues with menus not popping up, or being greyed out, up this to around ~300, it is not recommended to go over ~750, as menus will get slower and more unresponsive the higher you go. (Fixes this issue: https://www.shorturl.at/eqS19)
Config.OneStationPerPerson = true           -- This prevents players that already own one station from buying another, to prevent monopolies over Gas Stations.

--- Electric Vehicles
Config.ElectricVehicleCharging = true -- When true, electric vehicles will actually consume resources and decrease 'Fuel / Battery' while driving. This means players will have to recharge their vehicle!
Config.ElectricChargingPrice = 4      -- Per 'KW'. This value is multiplied times the amount of electricity someone put into their vehicle, to constitute the final cost of the charge. Players whom own the gas station will not recieve the money from electric charging.

Config.ElectricVehicles = {           -- List of Electric Vehicles in the Base Game.
    surge = { isElectric = true },
    iwagen = { isElectric = true },
    voltic = { isElectric = true },
    voltic2 = { isElectric = true },
    raiden = { isElectric = true },
    cyclone = { isElectric = true },
    tezeract = { isElectric = true },
    neon = { isElectric = true },
    omnisegt = { isElectric = true },
    caddy = { isElectric = true },
    caddy2 = { isElectric = true },
    caddy3 = { isElectric = true },
    airtug = { isElectric = true },
    rcbandito = { isElectric = true },
    imorgon = { isElectric = true },
    dilettante = { isElectric = true },
    khamelion = { isElectric = true },
}

Config.ElectricSprite = 620        -- This is for when the player is in an electric charger, the blips with change to this sprite. (Sprite with a car with a bolt going through it: 620)
Config.ElectricChargerModel = true -- If you wish, you can set this to false to add your own props, or use a ymap for the props instead.

Config.NoFuelUsage = {             -- This is for you to put vehicles that you don't want to use fuel.
    bmx = { blacklisted = true },
}

Config.Classes = { -- Class multipliers. If you want SUVs to use less fuel, you can change it to anything under 1.0, and vise versa.
    [0] = 1.0,     -- Compacts
    [1] = 1.0,     -- Sedans
    [2] = 1.0,     -- SUVs
    [3] = 1.0,     -- Coupes
    [4] = 1.0,     -- Muscle
    [5] = 1.0,     -- Sports Classics
    [6] = 1.0,     -- Sports
    [7] = 1.0,     -- Super
    [8] = 0.8,     -- Motorcycles
    [9] = 1.0,     -- Off-road
    [10] = 1.0,    -- Industrial
    [11] = 1.0,    -- Utility
    [12] = 1.0,    -- Vans
    [13] = 0.0,    -- Cycles
    [14] = 1.0,    -- Boats
    [15] = 1.0,    -- Helicopters
    [16] = 1.0,    -- Planes
    [17] = 0.7,    -- Service
    [18] = 0.5,    -- Emergency
    [19] = 1.0,    -- Military
    [20] = 1.0,    -- Commercial
    [21] = 1.0,    -- Trains
}

Config.FuelUsage = { -- The left part is at percentage RPM, and the right is how much fuel (divided by 10) you want to remove from the tank every second
    [1.0] = 1.3,
    [0.9] = 1.1,
    [0.8] = 0.9,
    [0.7] = 0.8,
    [0.6] = 0.7,
    [0.5] = 0.5,
    [0.4] = 0.3,
    [0.3] = 0.2,
    [0.2] = 0.1,
    [0.1] = 0.1,
    [0.0] = 0.0,
}

Config.AirAndWaterVehicleFueling = {
    enabled = false,
    locations = {
        [1] = {
            coords = {
                vector2(-701.34, -1441.48),
                vector2(-728.05, -1473.15),
                vector2(-712.1, -1486.4),
                vector2(-685.58, -1454.86),
            },
            thickness = 5.5,
            draw_text = '[G] Refuel Aircraft',
            type = 'air',
            whitelist = {
                enabled = false,
                on_duty_only = false,
                whitelisted_jobs = { 'police', 'ambulance' }
            },
            prop = {
                model = 'prop_gas_pump_1d',
                coords = vector4(-706.13, -1464.14, 4.04, 320.0)
            }
        },
        [2] = {
            coords = {
                vector2(-793.1, -1482.94),
                vector2(-786.39, -1500.85),
                vector2(-809.39, -1508.94),
                vector2(-817.48, -1491.62),
            },
            thickness = 5.5,

            draw_text = '[G] Refuel Watercraft',
            type = 'water',
            whitelist = {
                enabled = false,
                on_duty_only = false,
                whitelisted_jobs = { 'police', 'ambulance' }
            },
            prop = {
                model = 'prop_gas_pump_1d',
                coords = vector4(-805.9, -1496.68, 0.6, 200.00)
            }
        },
        [3] = {
            coords = {
                vector2(-1133.49, -2860.32),
                vector2(-1143.33, -2877.61),
                vector2(-1191.03, -2850.14),
                vector2(-1180.98, -2832.84),
            },
            thickness = 5.5,

            draw_text = '[G] Refuel Helicopter',
            type = 'air',
            whitelist = {
                enabled = false,
                on_duty_only = false,
                whitelisted_jobs = { 'police', 'ambulance' }
            },
            prop = {
                model = 'prop_gas_pump_1d',
                coords = vector4(-1158.29, -2848.67, 12.95, 240.0)
            }
        },
        [4] = {
            coords = {
                vector2(-1124.63, -2865.31),
                vector2(-1134.74, -2882.56),
                vector2(-1108.76, -2897.71),
                vector2(-1099.04, -2880.39),
            },
            thickness = 5.5,

            draw_text = '[G] Refuel Helicopter',
            type = 'air',
            whitelist = {
                enabled = false,
                on_duty_only = false,
                whitelisted_jobs = { 'police', 'ambulance' }
            },
            prop = {
                model = 'prop_gas_pump_1d',
                coords = vector4(-1125.15, -2866.97, 12.95, 240.0)
            }
        },
        [5] = {
            coords = {
                vector2(1764.15, 3226.34),
                vector2(1758.66, 3246.44),
                vector2(1777.28, 3250.51),
                vector2(1781.89, 3230.8),
            },
            thickness = 5.5,

            draw_text = '[G] Refuel Helicopter',
            type = 'air',
            whitelist = {
                enabled = false,
                on_duty_only = false,
                whitelisted_jobs = { 'police', 'ambulance' }
            },
            prop = {
                model = 'prop_gas_pump_1d',
                coords = vector4(1771.81, 3229.24, 41.51, 15.00)
            }
        }
    },
    refuel_button = 47,
    nozzle_length = 20.0,
    air_fuel_price = 10,
    water_fuel_price = 4
}

Config.GasStations = { -- Configuration options for various gas station related things, including peds, coords and labels.
    [1] = {
        zones = {
            vec3(177.0, -1542.0, 31.0),
            vec3(153.0, -1566.0, 31.0),
            vec3(171.0, -1580.0, 31.0),
            vec3(196.0, -1565.0, 31.0),
        },
        thickness = 5.5,
        pedmodel = 'a_m_m_indian_01',
        cost = 150000,
        shutoff = false,
        pedcoords = vec4(167.06, -1553.56, 28.26, 220.44),
        electriccharger = nil,
        electricChargerCoords = vector4(175.9, -1546.65, 28.26, 224.29),
        label = 'Davis Avenue Ron',
    },
    [2] = {
        zones = {
            vec3(-55.0, -1736.80, 30.65),
            vec3(-97.0, -1755.0, 30.65),
            vec3(-65.75, -1781.5, 30.65),
            vec3(-37.84, -1750.80, 30.65),
            vec3(-38.0, -1750.0, 30.65),
        },
        thickness = 7.35,
        pedmodel = 'a_m_m_indian_01',
        cost = 150000,
        shutoff = false,
        pedcoords = vec4(-40.94, -1751.7, 28.42, 140.72),
        electriccharger = nil,
        electricChargerCoords = vec4(-54.98, -1741.38, 28.57, 144.12),
        label = 'Grove Street LTD',
    },
    [3] = {
        zones = {
            vec3(-522.0, -1226.0, 20.0),
            vec3(-545.0, -1215.0, 20.0),
            vec3(-533.0, -1189.0, 20.0),
            vec3(-505.0, -1203.0, 20.0),
        },
        thickness = 7.0,

        pedmodel = 'a_m_m_indian_01',
        cost = 250000,
        shutoff = false,
        pedcoords = vec4(-531.18, -1221.05, 17.45, 335.73),
        electriccharger = nil,
        electricChargerCoords = vec4(-514.06, -1216.25, 17.46, 66.29),
        label = 'Dutch London Xero',
    },
    [4] = {
        zones = {
            vec3(-697.0, -906.3, 21.9),
            vec3(-697.0, -946.0, 21.9),
            vec3(-748.0, -949.0, 21.9),
            vec3(-739.0, -906.0, 21.9),
            vec3(-711.0, -902.0, 21.9),
            vec3(-703.0, -898.0, 21.9),
        },
        thickness = 10.0,
        pedmodel = 'a_m_m_indian_01',
        cost = 250000,
        shutoff = false,
        pedcoords = vec4(-708.190, -903.478, 18.215, 185.91),
        electriccharger = nil,
        electricChargerCoords = vec4(-704.64, -935.71, 18.21, 90.02),
        label = 'Little Seoul LTD',
    },
    [5] = {
        zones = {
            vec3(240.0, -1284.0, 30.5),
            vec3(290.35, -1284.0, 30.5),
            vec3(290.0, -1249.0, 30.5),
            vec3(244.25, -1248.0, 30.5),
        },
        thickness = 9.5,
        pedmodel = 'a_m_m_indian_01',
        cost = 250000,
        shutoff = false,
        pedcoords = vec4(288.83, -1267.01, 28.44, 93.81),
        electriccharger = nil,
        electricChargerCoords = vec4(279.79, -1237.35, 28.35, 181.07),
        label = 'Strawberry Ave Xero',
    },
    [6] = {
        zones = {
            vec3(803.70, -1047.65, 27.7),
            vec3(835.59, -1041.59, 27.7),
            vec3(835.5, -1015.5, 27.7),
            vec3(801.0, -1017.0, 27.7),
        },
        thickness = 5.25,
        pedmodel = 'a_m_m_indian_01',
        cost = 150000,
        shutoff = false,
        pedcoords = vec4(816.42, -1040.51, 25.75, 2.07),
        electriccharger = nil,
        electricChargerCoords = vector4(834.27, -1028.7, 26.16, 88.39),
        label = 'Popular Street Ron',
    },
    [7] = {
        zones = {
            vec3(1222.0, -1379.0, 37.0),
            vec3(1192.59, -1379.0, 37.0),
            vec3(1193.0, -1419.0, 37.0),
            vec3(1211.0, -1416.0, 37.0),
            vec3(1213.0, -1415.0, 37.0),
            vec3(1218.0, -1411.0, 37.0),
            vec3(1221.5, -1405.80, 37.0),
            vec3(1224.0, -1395.0, 37.0),
        },
        thickness = 6.2,
        pedmodel = 'a_m_m_indian_01',
        cost = 250000,
        shutoff = false,
        pedcoords = vec4(1211.13, -1389.18, 34.38, 177.39),
        electriccharger = nil,
        electricChargerCoords = vector4(1194.41, -1394.44, 34.37, 270.3),
        label = 'Capital Blvd Ron',
    },
    [8] = {
        zones = {
            vec3(1150.0, -347.0, 70.4),
            vec3(1196.0, -358.0, 70.4),
            vec3(1198.0, -341.0, 70.4),
            vec3(1195.5, -324.0, 70.4),
            vec3(1188.0, -305.0, 70.4),
            vec3(1144.0, -313.0, 70.4),
        },
        thickness = 8.6,
        pedmodel = 'a_m_m_indian_01',
        cost = 250000,
        shutoff = false,
        pedcoords = vec4(1163.64, -314.21, 68.21, 190.92),

        electriccharger = nil,
        electricChargerCoords = vector4(1168.38, -323.56, 68.3, 280.22),
        label = 'Mirror Park LTD',
    },
    [9] = {
        zones = {
            vec3(632.0, 237.0, 100.0),
            vec3(586.0, 260.0, 100.0),
            vec3(607.0, 298.0, 100.0),
            vec3(632.0, 295.0, 100.0),
            vec3(672.09, 273.0, 100.0),
            vec3(648.0, 232.0, 100.0),
        },
        thickness = 17.8,
        pedmodel = 'a_m_m_indian_01',
        cost = 120000,
        shutoff = false,
        pedcoords = vec4(642.08, 260.59, 102.3, 61.39),

        electriccharger = nil,
        electricChargerCoords = vector4(633.64, 247.22, 102.3, 60.29),
        label = 'Clinton Ave Globe Oil',
    },
    [10] = {
        zones = {
            vec3(-1400.0, -275.0, 49.1),
            vec3(-1431.0, -302.0, 49.1),
            vec3(-1459.0, -270.0, 49.1),
            vec3(-1429.5, -242.19, 49.1),
        },
        thickness = 10.8,
        pedmodel = 'a_m_m_indian_01',
        cost = 150000,
        shutoff = false,
        pedcoords = vec4(-1428.4, -268.69, 45.21, 132.94),
        electriccharger = nil,
        electricChargerCoords = vector4(-1420.51, -278.76, 45.26, 137.35),
        label = 'North Rockford Ron',
    },
    [11] = {
        zones = {
            vec3(-2062.0, -349.0, 15.0),
            vec3(-2090.0, -347.0, 15.0),
            vec3(-2105.0, -344.0, 15.0),
            vec3(-2125.0, -335.0, 15.0),
            vec3(-2134.0, -322.0, 15.0),
            vec3(-2136.0, -304.0, 15.0),
            vec3(-2132.0, -287.0, 15.0),
            vec3(-2055.0, -296.0, 15.0),
        },
        thickness = 8.0,
        pedmodel = 'a_m_m_indian_01',
        cost = 200000,
        shutoff = false,
        pedcoords = vec4(-2073.45, -327.39, 12.32, 88.47),
        electriccharger = nil,
        electricChargerCoords = vector4(-2080.61, -338.52, 12.26, 352.21),
        label = 'Great Ocean Xero',
    },
    [12] = {
        zones = {
            vec3(-92.44, 6387.10, 33.45),
            vec3(-114.69, 6409.0, 33.45),
            vec3(-78.0, 6445.5, 33.45),
            vec3(-56.0, 6424.0, 33.45),
        },
        thickness = 7.2,
        pumpheightadd = 1.5, --  For Config.PumpHose
        pedmodel = 'a_m_m_indian_01',
        cost = 75000,
        shutoff = false,
        pedcoords = vec4(-93.02, 6410.11, 30.64, 49.19),
        electriccharger = nil,
        electricChargerCoords = vector4(-98.12, 6403.39, 30.64, 141.49),
        label = 'Paleto Blvd Xero',
    },
    [13] = {
        zones = {
            vec3(211.0, 6574.0, 34.0),
            vec3(211.0, 6634.0, 34.0),
            vec3(191.0, 6639.0, 34.0),
            vec3(184.0, 6639.0, 34.0),
            vec3(178.30, 6640.29, 34.0),
            vec3(178.10, 6646.20, 34.0),
            vec3(159.0, 6665.29, 34.0),
            vec3(99.0, 6605.0, 34.0),
            vec3(159.0, 6548.0, 34.0),
        },
        thickness = 7.0,
        pedmodel = 'a_m_m_indian_01',
        cost = 175000,
        shutoff = false,
        pedcoords = vec4(162.15, 6636.61, 30.55, 139.71),
        electriccharger = nil,
        electricChargerCoords = vector4(181.14, 6636.17, 30.61, 179.96),
        label = 'Paleto Ron',
    },
    [14] = {
        zones = {
            vec3(1683.59, 6449.75, 33.65),
            vec3(1727.05, 6429.0, 33.65),
            vec3(1710.0, 6392.0, 33.65),
            vec3(1660.0, 6404.0, 33.65),
        },
        thickness = 10.3,
        pedmodel = 'a_m_m_indian_01',
        cost = 90000,
        shutoff = false,
        pedcoords = vec4(1698.76, 6426.06, 31.76, 162.47),

        electriccharger = nil,
        electricChargerCoords = vector4(1714.14, 6425.44, 31.79, 155.94),
        label = 'Paleto Globe Oil',
    },
    [15] = {
        zones = {
            vec3(1672.05, 4919.25, 44.0),
            vec3(1677.69, 4917.25, 44.0),
            vec3(1701.5, 4900.5, 44.0),
            vec3(1726.0, 4935.0, 44.0),
            vec3(1701.5, 4953.5, 44.0),
            vec3(1686.0, 4944.0, 44.0),
            vec3(1682.75, 4941.0, 44.0),
            vec3(1679.25, 4937.0, 44.0),
        },
        thickness = 6.5,
        pumpheightadd = 1.5, --  For Config.PumpHose
        pedmodel = 'a_m_m_indian_01',
        cost = 100000,
        shutoff = false,
        pedcoords = vec4(1704.59, 4917.5, 41.06, 52.16),
        electriccharger = nil,
        electricChargerCoords = vector4(1703.57, 4937.23, 41.08, 55.74),
        label = 'Grapeseed LTD',
    },
    [16] = {
        zones = {
            vec3(2027.0, 3769.0, 34.0),
            vec3(1979.0, 3741.0, 34.0),
            vec3(1966.0, 3764.0, 34.0),
            vec3(1974.0, 3769.0, 34.0),
            vec3(1966.0, 3784.0, 34.0),
            vec3(2005.94, 3806.80, 34.0),
        },
        thickness = 6.0,
        pumpheightadd = 1.5, --  For Config.PumpHose
        pedmodel = 'a_m_m_indian_01',
        cost = 90000,
        shutoff = false,
        pedcoords = vec4(2001.33, 3779.87, 31.18, 211.44),
        electriccharger = nil,
        electricChargerCoords = vector4(1994.54, 3778.44, 31.18, 215.25),
        label = 'Sandy Shores Xero',
    },
    [17] = {
        zones = {
            vec3(1778.0, 3353.0, 44.0),
            vec3(1793.0, 3328.0, 44.0),
            vec3(1762.0, 3311.0, 44.0),
            vec3(1750.0, 3330.0, 44.0),
        },
        thickness = 10.0,
        pumpheightadd = 1.5, --  For Config.PumpHose
        pedmodel = 'a_m_m_indian_01',
        cost = 60000,
        shutoff = false,
        pedcoords = vec4(1776.57, 3327.36, 40.43, 297.57),
        electriccharger = nil,
        electricChargerCoords = vector4(1770.86, 3337.97, 40.43, 301.1),
        label = 'Sandy Shores Globe Oil',
    },
    [18] = {
        zones = {
            vec3(2649.75, 3264.0, 56.75),
            vec3(2657.10, 3257.69, 56.75),
            vec3(2680.25, 3244.80, 56.75),
            vec3(2702.69, 3285.14, 56.75),
            vec3(2679.30, 3298.19, 56.75),
            vec3(2677.0, 3294.0, 56.75),
            vec3(2675.10, 3295.0, 56.75),
            vec3(2671.25, 3295.85, 56.75),
            vec3(2664.0, 3282.64, 56.75),
            vec3(2661.05, 3284.64, 56.75),
        },
        thickness = 5.45,
        pumpheightadd = 1.5, --  For Config.PumpHose
        pedmodel = 'a_m_m_indian_01',
        cost = 120000,
        shutoff = false,
        pedcoords = vec4(2673.98, 3266.87, 54.24, 240.9),
        electriccharger = nil,
        electricChargerCoords = vector4(2690.25, 3265.62, 54.24, 58.98),
        label = 'Senora Freeway Xero',
    },
    [19] = {
        zones                 = {
            vec3(1194.0, 2676.0, 39.0),
            vec3(1194.0, 2668.0, 39.0),
            vec3(1190.0, 2662.0, 39.0),
            vec3(1182.0, 2655.0, 39.0),
            vec3(1197.75, 2639.0, 39.0),
            vec3(1202.25, 2631.75, 39.0),
            vec3(1208.75, 2636.0, 39.0),
            vec3(1213.75, 2642.75, 39.0),
            vec3(1216.0, 2648.0, 39.0),
            vec3(1218.0, 2659.25, 39.0),
            vec3(1216.0, 2676.0, 39.0),
        },
        thickness             = 5.25,
        pumpheightadd         = 1.5, --  For Config.PumpHose
        pedmodel              = 'a_m_m_indian_01',
        cost                  = 100000,
        shutoff               = false,
        pedcoords             = vec4(1201.68, 2655.24, 36.85, 322.97),
        electriccharger       = nil,
        electricChargerCoords = vector4(1208.26, 2649.46, 36.85, 222.32),
        label                 = 'Harmony Globe Oil',
    },
    [20] = {
        zones = {
            vec3(1017.25, 2685.0, 40.5),
            vec3(1017.5, 2648.0, 40.5),
            vec3(1068.5, 2648.25, 40.5),
            vec3(1069.25, 2682.0, 40.5),
        },
        thickness = 5.5,
        pumpheightadd = 1.5, --  For Config.PumpHose
        pedmodel = 'a_m_m_indian_01',
        cost = 100000,
        shutoff = false,
        pedcoords = vec4(1039.44, 2664.37, 38.55, 10.07),
        electriccharger = nil,
        electricChargerCoords = vector4(1033.32, 2662.91, 38.55, 95.38),
        label = 'Route 68 Globe Oil',
    },
    [21] = {
        zones = {
            vec3(270.0, 2597.0, 47.6),
            vec3(267.0, 2618.0, 47.6),
            vec3(248.0, 2614.0, 47.6),
            vec3(243.0, 2614.0, 47.6),
            vec3(248.0, 2592.0, 47.6),
        },
        thickness = 8.05,
        pumpheightadd = 1.5, --  For Config.PumpHose
        pedmodel = 'a_m_m_indian_01',
        cost = 80000,
        shutoff = false,
        pedcoords = vec4(252.481, 2595.838, 43.901, 11.598),
        electriccharger = nil,
        electricChargerCoords = vector4(258.92, 2605.90, 43.97, 15.60),
        label = 'Route 68 Workshop Globe Oil',
    },
    [22] = {
        zones = {
            vec3(20.0, 2784.0, 61.0),
            vec3(46.0, 2815.0, 61.0),
            vec3(71.0, 2794.0, 61.0),
            vec3(75.0, 2785.0, 61.0),
            vec3(55.0, 2759.0, 61.0),
        },
        thickness = 10.0,
        pumpheightadd = 1.5, --  For Config.PumpHose
        pedmodel = 'a_m_m_indian_01',
        cost = 100000,
        shutoff = false,
        pedcoords = vec4(58.903, 2795.002, 56.878, 329.969),
        electriccharger = nil,
        electricChargerCoords = vector4(50.21, 2787.38, 56.88, 147.2),
        label = 'Route 68 Xero',
    },
    [23] = {
        zones = {
            vec3(-2569.0, 2349.0, 34.75),
            vec3(-2565.0, 2297.0, 34.75),
            vec3(-2522.0, 2300.25, 34.75),
            vec3(-2513.25, 2317.5, 34.75),
            vec3(-2512.0, 2331.5, 34.75),
            vec3(-2526.0, 2351.75, 34.75),
        },
        thickness = 6.0,
        pedmodel = 'a_m_m_indian_01',
        cost = 100000,
        shutoff = false,
        pedcoords = vec4(-2565.70, 2307.18, 32.22, 97.00),
        electriccharger = nil,
        electricChargerCoords = vector4(-2570.04, 2317.1, 32.22, 21.29),
        label = 'Route 68 Ron',
    },
    [24] = {
        zones = {
            vec3(2542.0, 347.0, 109.7),
            vec3(2598.0, 344.0, 109.7),
            vec3(2600.0, 378.0, 109.7),
            vec3(2562.25, 379.14, 109.7),
            vec3(2564.0, 404.0, 109.7),
            vec3(2543.0, 403.0, 109.7),
        },
        thickness = 5.75,
        pedmodel = 'a_m_m_indian_01',
        cost = 100000,
        shutoff = false,
        pedcoords = vec4(2559.36, 373.68, 107.62, 272.2),
        electriccharger = nil,
        electricChargerCoords = vector4(2561.24, 357.3, 107.62, 266.65),
        label = 'Palmino Freeway Ron',
    },
    [25] = {
        zones = {
            vec3(-1774.4, 801.6, 141.0),
            vec3(-1798.0, 825.0, 141.0),
            vec3(-1813.0, 819.0, 141.0),
            vec3(-1829.0, 806.0, 141.0),
            vec3(-1842.0, 791.5, 141.0),
            vec3(-1830.6, 779.3, 141.0),
            vec3(-1814.0, 794.0, 141.0),
            vec3(-1800.0, 779.0, 141.0),
        },
        thickness = 10.4,
        pedmodel = 'a_m_m_indian_01',
        cost = 100000,
        shutoff = false,
        pedcoords = vec4(-1828.46, 800.35, 137.16, 223.25),
        electriccharger = nil,
        electricChargerCoords = vector4(-1819.22, 798.51, 137.16, 315.13),
        label = 'North Rockford LTD',
    },
    [26] = {
        zones = {
            vec3(-344.0, -1500.0, 32.2),
            vec3(-303.0, -1500.0, 32.2),
            vec3(-299.39, -1466.09, 32.2),
            vec3(-300.0, -1464.09, 32.2),
            vec3(-305.39, -1454.5, 32.2),
            vec3(-314.0, -1454.0, 32.2),
            vec3(-345.20, -1454.30, 32.2),
        },
        thickness = 6.8,
        pedmodel = 'a_m_m_indian_01',
        cost = 100000,
        shutoff = false,
        pedcoords = vec4(-342.559, -1475.067, 29.748, 274.465),
        electriccharger = nil,
        electricChargerCoords = vector4(-341.63, -1459.39, 29.76, 271.73),
        label = 'Alta Street Globe Oil',
    },
}
