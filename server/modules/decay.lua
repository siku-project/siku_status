local MS_PER_MINUTE <const> = 60000
local DEAD_HEALTH <const> = 100

--- Whether the character behind a session is dead.
---@param sessionId number The player server id.
---@return boolean dead Whether the ped is dead or dying.
local function isCharacterDead(sessionId)
  local ped <const> = GetPlayerPed(sessionId)

  if not ped or ped == 0 then
    return false
  end

  return GetEntityHealth(ped) <= DEAD_HEALTH
end

--- Fires every threshold a value just fell through. A threshold triggers
--- only on the crossing itself: staying below it stays silent, and rising
--- back above re-arms it for the next fall.
---@param state table The status state.
---@param name string The status name.
---@param definition table The status definition.
---@param previous number The value before the change.
---@return nil
function EvaluateThresholds(state, name, definition, previous)
  local value <const> = state.values[name]

  for index = 1, #definition.thresholds do
    local threshold <const> = definition.thresholds[index]

    if previous > threshold.value and value <= threshold.value then
      TriggerEvent('siku:status:threshold', state.sessionId, state.characterId, name, threshold.value)

      if StatusConfig.notifications and threshold.notification then
        Siku.notification.show(state.sessionId, {
          type = threshold.notification.type,
          icon = threshold.notification.icon,
          title = T(threshold.notification.title),
          description = T(threshold.notification.description),
        })
      end
    end
  end
end

--- Hurts a character whose statuses sit at their minimum, at the configured
--- pace, harder when several are empty at once.
---@param state table The status state.
---@param now number The current game timer.
---@return nil
local function applyConsequences(state, now)
  if not StatusConfig.damage.enabled then
    return
  end

  local total = 0
  local empty = 0

  StatusRegistry.forEach(function(name, definition)
    if definition.damage > 0 and state.values[name] <= definition.min then
      total = total + definition.damage
      empty = empty + 1
    end
  end)

  if empty == 0 then
    state.lastDamage = now
    return
  end

  if now - state.lastDamage < StatusConfig.damage.interval then
    return
  end

  state.lastDamage = now

  if empty > 1 then
    total = total * StatusConfig.damage.stackedMultiplier
  end

  TriggerClientEvent('siku_status:client:damage', state.sessionId, math.floor(total + 0.5))
end

--- Advances one character by the time actually elapsed since its last tick,
--- so the pace never depends on the loop frequency.
---@param state table The status state.
---@param now number The current game timer.
---@return nil
local function tickCharacter(state, now)
  if state.loading then
    return
  end

  local elapsed <const> = now - state.lastDecay
  state.lastDecay = now

  if StatusConfig.pauseWhenDead and isCharacterDead(state.sessionId) then
    return
  end

  StatusRegistry.forEach(function(name, definition)
    if definition.decayPerMinute > 0 and elapsed > 0 then
      local previous <const> = state.values[name]
      local value <const> =
        math.max(definition.min, previous - definition.decayPerMinute * (elapsed / MS_PER_MINUTE))

      if value ~= previous then
        state.values[name] = value
        EvaluateThresholds(state, name, definition, previous)
      end
    end
  end)

  applyConsequences(state, now)
  SyncCharacterStatuses(state)
end

Siku.timers.setInterval(StatusConfig.tickInterval, function()
  local now <const> = GetGameTimer()

  ForEachStatusState(function(state)
    tickCharacter(state, now)
  end)
end)
