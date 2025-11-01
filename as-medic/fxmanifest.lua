fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'as-medical'
author 'AS.DEV'
description 'NPC-Heiler: Spieler heilen oder wiederbeleben gegen Geld (ESX)'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua', 
    'server.lua'
}

