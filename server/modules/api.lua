--- Resolves the state and definition an export call targets.
---@param source any The player server id.
---@param name any The status name.
---@return table? state, table? definition The state and definition, or nils.
local function resolveTarget(source, name)
  local definition <const> = StatusRegistry.get(name)

  if not definition then
    Siku.print.warn(T('status_unknown', tostring(name)))
    return nil, nil
  end

  local state <const> = GetStatusState(source)

  if not state then
    return nil, nil
  end

  return state, definition
end

--- Writes a value into a state, clamped, firing thresholds and syncing.
---@param state table The status state.
---@param definition table The status definition.
---@param value number The requested value.
---@return number value The value actually applied.
function ApplyStatusValue(state, definition, value)
  local previous <const> = state.values[definition.name]
  local clamped <const> = math.min(definition.max, math.max(definition.min, value))

  if clamped ~= previous then
    state.values[definition.name] = clamped
    EvaluateThresholds(state, definition.name, definition, previous)
    SyncCharacterStatuses(state)
  end

  return clamped
end

--- Reads one status of the character a session is playing.
---@param source number The player server id.
---@param name string The status name.
---@return number? value The current value, or nil.
local function getStatus(source, name)
  local state <const>, definition <const> = resolveTarget(source, name)

  if not state or not definition then
    return nil
  end

  return state.values[definition.name]
end

--- Reads every status of the character a session is playing.
---@param source number The player server id.
---@return table? values One entry per status, or nil when none is loaded.
local function getStatuses(source)
  local state <const> = GetStatusState(source)

  if not state then
    return nil
  end

  local values <const> = {}

  StatusRegistry.forEach(function(name)
    values[name] = state.values[name]
  end)

  return values
end

--- Sets one status to an absolute value.
---@param source number The player server id.
---@param name string The status name.
---@param value number The requested value, clamped into the status bounds.
---@return number? value The value actually applied, or nil.
local function setStatus(source, name, value)
  local state <const>, definition <const> = resolveTarget(source, name)

  if not state or not definition then
    return nil
  end

  if type(value) ~= 'number' then
    Siku.print.warn(T('status_invalid_value', definition.name))
    return nil
  end

  return ApplyStatusValue(state, definition, value)
end

--- Adds to one status. A food item feeds hunger this way.
---@param source number The player server id.
---@param name string The status name.
---@param amount number How much to add, clamped into the status bounds.
---@return number? value The value actually applied, or nil.
local function addStatus(source, name, amount)
  local state <const>, definition <const> = resolveTarget(source, name)

  if not state or not definition then
    return nil
  end

  if type(amount) ~= 'number' then
    Siku.print.warn(T('status_invalid_value', definition.name))
    return nil
  end

  return ApplyStatusValue(state, definition, state.values[definition.name] + amount)
end

--- Removes from one status.
---@param source number The player server id.
---@param name string The status name.
---@param amount number How much to remove, clamped into the status bounds.
---@return number? value The value actually applied, or nil.
local function removeStatus(source, name, amount)
  if type(amount) ~= 'number' then
    Siku.print.warn(T('status_invalid_value', tostring(name)))
    return nil
  end

  return addStatus(source, name, -amount)
end

--- Resets one status, or every status, to its default.
---@param source number The player server id.
---@param name string? The status name, or nil for all of them.
---@return boolean reset Whether anything was reset.
local function resetStatus(source, name)
  if name ~= nil then
    local state <const>, definition <const> = resolveTarget(source, name)

    if not state or not definition then
      return false
    end

    ApplyStatusValue(state, definition, definition.default)
    return true
  end

  local state <const> = GetStatusState(source)

  if not state then
    return false
  end

  StatusRegistry.forEach(function(_, definition)
    ApplyStatusValue(state, definition, definition.default)
  end)

  return true
end

exports('GetStatus', getStatus)
exports('GetStatuses', getStatuses)
exports('SetStatus', setStatus)
exports('AddStatus', addStatus)
exports('RemoveStatus', removeStatus)
exports('ResetStatus', resetStatus)
