fx_version 'cerulean'
game 'gta5'

author 'Siku Studio'
description 'A modular status system for the SIKU ecosystem — managing persistent character needs such as hunger and thirst with scalable state handling, configurable decay, thresholds, effects, and seamless integration across immersive FiveM roleplay experiences.'
version '0.2.0'

name 'siku_status'

lua54 'yes'

shared_scripts {
  '@siku_core/init.lua',
  'config/translation.lua',
  'config/status.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'config/migration.lua',
  'server/init.lua',
  'server/modules/registry.lua',
  'server/modules/store.lua',
  'server/modules/sync.lua',
  'server/modules/decay.lua',
  'server/modules/api.lua',
  'server/modules/effects.lua',
  'server/modules/lifecycle.lua',
}

client_scripts {
  'client/main.lua',
}

files {
  'translations/*.lua',
}

dependencies {
  'siku_core',
  'oxmysql',
}
