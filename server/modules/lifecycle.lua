--- Loads the statuses of a character as soon as the core made it active.
---@param sessionId number The player server ID.
---@param characterData table The character row from the database.
---@return nil
local function handleCharacterReady(sessionId, characterData)
  if type(sessionId) ~= 'number' or type(characterData) ~= 'table' then
    return
  end

  if type(characterData.id) ~= 'number' then
    return
  end

  ForgetCharacter(sessionId, true)
  LoadCharacterStatuses(sessionId, characterData.id)
end

AddEventHandler('siku:server:createCharacterInstance', handleCharacterReady)

AddEventHandler('playerDropped', function()
  ForgetCharacter(source, true)
end)

AddEventHandler('onResourceStop', function(resource)
  if resource ~= GetCurrentResourceName() then
    return
  end

  SaveAllStatuses(true)
end)

--- Rebuilds what a restart erased, for the players already in the world.
--- A character becomes active once, and everyone playing when this resource
--- restarts already went through that moment: their statuses are read back
--- from the database instead.
---@return nil
function RestoreConnectedSessions()
  Siku.cache.forEach(function(sessionId)
    local character <const> = Siku.cache.getCurrentCharacter(sessionId)

    if character and type(character.id) == 'number' then
      LoadCharacterStatuses(sessionId, character.id)
    end
  end)
end
