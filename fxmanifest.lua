fx_version 'cerulean'
games { 'gta5' }

author "Swkeep#7049"

shared_script { 'config.lua', 'shared/shared_main.lua' }

client_scripts {
     '@menuv/menuv.lua',
     'client/client.lua',
     'client/client_lib/client_lib_entry.lua',
     'client/client_lib/menu/CDU_menu.lua',
     'client/client_lib/menu/edit_menu.lua',
     'client/client_lib/menu/pump_menu.lua',
     'client/client_lib/menu/storage_menu.lua',
     'client/client_lib/menu/blender_menu.lua',
     'client/client_lib/menu/transport_menu.lua',
     'client/target/target.lua',
     'client/target/qb_target.lua',
}

server_script {
     '@oxmysql/lib/MySQL.lua',
     'server/server_lib/server_lib_entry.lua',
     'server/server_lib/Server_GlobalScirptData.lua',
     'server/server_lib/refund.lua',
     'server/server_main.lua',
}


dependency 'oxmysql'

lua54 'yes'
