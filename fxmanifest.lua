fx_version 'cerulean'
game 'gta5'
description 'cdn-fuel'
version '2.1.9'

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    --'@PolyZone/client.lua',
    'client/fuel_cl.lua',
    'client/electric_cl.lua',
    'client/station_cl.lua',
    'client/utils.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/fuel_sv.lua',
    'server/station_sv.lua',
    'server/electric_sv.lua',
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'shared/config.lua',
    'locales/en.lua',
}

exports {
    'GetFuel',
    'SetFuel'
}

lua54 'yes'

dependencies {
    --'PolyZone',
    'interact-sound',
    'ox_lib',
    'ox_target',
}
