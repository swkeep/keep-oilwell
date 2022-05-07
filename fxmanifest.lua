fx_version 'cerulean'
games { 'gta5' }

author "Swkeep#7049"

shared_script { 'config.lua', 'shared/shared_main.lua' }

client_scripts { 'client/client_main.lua', 'client/client_lib/client_lib_entry.lua' }

server_script { 'server/server_main.lua', 'server/server_lib/server_lib_entry.lua' }

-- dependency 'oxmysql'

lua54 'yes'
