fx_version 'cerulean'
game 'gta5'
description 'cdn-fuel'
version '2.1.9'

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    '@PolyZone/client.lua',
    'client/fuel_cl.lua',
    'client/electric_cl.lua',
    'client/station_cl.lua',
    'client/utils.lua'
}

server_scripts {
    'server/fuel_sv.lua',
    'server/station_sv.lua',
    'server/electric_sv.lua',
    '@oxmysql/lib/MySQL.lua',
}

shared_scripts {
    'shared/config.lua',
    '@qb-core/shared/locale.lua',
    '@ox_lib/init.lua',
    'locales/en.lua',
}

exports {
    'GetFuel',
    'SetFuel'
}

lua54 'yes'

dependencies {
    'PolyZone',
    'interact-sound',
    'ox_lib',
    'ox_target',
}

provide 'cdn-syphoning' -- This is used to override cdn-syphoning(https://github.com/CodineDev/cdn-syphoning) if you have it installed. If you don't have it installed, don't worry about this. If you do, we recommend removing it and using this instead.
