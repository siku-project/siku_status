local SCHEMA_VERSION <const> = 1
local PRECISION <const> = 100
local UPSERT_QUERY <const> = table.concat({
  'INSERT INTO character_statuses (character_id, statuses, schema_version)',
  'VALUES (?, ?, ?)',
  'ON DUPLICATE KEY UPDATE statuses = VALUES(statuses), schema_version = VALUES(schema_version)',
}, ' ')

local states <const> = {}
local characterBySession <const> = {}

--- Rounds a value to what the database keeps.
---@param value number The in-memory value.
---@return number value The rounded value.
local function roundStored(value)
  return math.floor(value * PRECISION + 0.5) / PRECISION
end

--- Gets the status state of the character a session is playing.
---@param sessionId any The player server id.
---@return table? state The state, or nil when no character is loaded.
function GetStatusState(sessionId)
  local characterId <const> = characterBySession[sessionId]

  if not characterId then
    return nil
  end

  return states[characterId]
end

--- Runs a function over every loaded state.
---@param handler function Receives the state.
---@return nil
function ForEachStatusState(handler)
  for _, state in pairs(states) do
    handler(state)
  end
end

--- Builds the payload a state is stored as.
---@param state table The status state.
---@return string payload The JSON object of rounded values.
local function encodeValues(state)
  local values <const> = {}

  StatusRegistry.forEach(function(name)
    values[name] = roundStored(state.values[name])
  end)

  return json.encode(values)
end

--- Writes one state to the database.
---@param state table The status state.
---@param await boolean? Whether to block until the write is done.
---@return nil
function SaveCharacterStatuses(state, await)
  local parameters <const> = { state.characterId, encodeValues(state), SCHEMA_VERSION }

  if await then
    local affected <const> = MySQL.update.await(UPSERT_QUERY, parameters)

    if not affected then
      Siku.print.error(T('status_save_failed', state.characterId))
    end

    return
  end

  MySQL.update(UPSERT_QUERY, parameters, function(affected)
    if not affected then
      Siku.print.error(T('status_save_failed', state.characterId))
    end
  end)
end

--- Writes every loaded state to the database.
---@param await boolean? Whether to block until the writes are done.
---@return nil
function SaveAllStatuses(await)
  for _, state in pairs(states) do
    SaveCharacterStatuses(state, await)
  end
end

--- Merges a stored row into a fresh set of defaults, so a status added
--- after the row was written starts at its default instead of vanishing.
---@param state table The status state.
---@param raw any The stored JSON payload.
---@return nil
local function applyStoredValues(state, raw)
  local ok <const>, stored <const> = pcall(json.decode, raw)

  if not ok or type(stored) ~= 'table' then
    Siku.print.error(T('status_load_failed', state.characterId, 'corrupted payload'))
    return
  end

  StatusRegistry.forEach(function(name, definition)
    if type(stored[name]) == 'number' then
      state.values[name] = math.min(definition.max, math.max(definition.min, stored[name]))
    end
  end)
end

--- Loads the statuses of a character, registering its state immediately and
--- filling it from the database when the row answers.
---@param sessionId number The player server id.
---@param characterId number The character id.
---@return nil
function LoadCharacterStatuses(sessionId, characterId)
  local now <const> = GetGameTimer()

  local state <const> = {
    sessionId = sessionId,
    characterId = characterId,
    values = StatusRegistry.defaults(),
    synced = {},
    lastDecay = now,
    lastDamage = now,
    loading = true,
  }

  characterBySession[sessionId] = characterId
  states[characterId] = state

  MySQL.single(
    'SELECT statuses FROM character_statuses WHERE character_id = ?',
    { characterId },
    function(row)
      if states[characterId] ~= state then
        return
      end

      if row then
        applyStoredValues(state, row.statuses)
      end

      state.loading = false
      state.lastDecay = GetGameTimer()
      SyncCharacterStatuses(state, true)

      Siku.print.debug(('Statuses ready for character %d'):format(characterId))
    end
  )
end

--- Forgets the character a session was playing.
---@param sessionId number The player server id.
---@param persist boolean Whether the state is written before it goes.
---@return nil
function ForgetCharacter(sessionId, persist)
  local characterId <const> = characterBySession[sessionId]

  if not characterId then
    return
  end

  local state <const> = states[characterId]

  characterBySession[sessionId] = nil
  states[characterId] = nil

  if state and persist and not state.loading then
    SaveCharacterStatuses(state)
  end
end

Siku.timers.setInterval(StatusConfig.saveInterval, function()
  SaveAllStatuses(false)
end)
