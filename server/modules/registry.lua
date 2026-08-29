StatusRegistry = {}

local definitions <const> = {}
local ordered <const> = {}

--- Checks that a status definition is usable.
---@param definition table The raw definition from the config.
---@return string? fault What is wrong with it, or nil when it is valid.
local function validateDefinition(definition)
  if type(definition.min) ~= 'number' or type(definition.max) ~= 'number' then
    return 'min and max must be numbers'
  end

  if definition.min >= definition.max then
    return 'min must be below max'
  end

  if type(definition.default) ~= 'number' then
    return 'default must be a number'
  end

  if type(definition.decayPerMinute) ~= 'number' or definition.decayPerMinute < 0 then
    return 'decayPerMinute must be a positive number'
  end

  if definition.damage ~= nil and (type(definition.damage) ~= 'number' or definition.damage < 0) then
    return 'damage must be a positive number'
  end

  if definition.thresholds ~= nil and type(definition.thresholds) ~= 'table' then
    return 'thresholds must be a table'
  end

  return nil
end

--- Orders thresholds from the highest to the lowest, so a large drop fires
--- them in the order the player lives them.
---@param thresholds table The threshold entries.
---@return table thresholds The same entries, sorted.
local function sortThresholds(thresholds)
  table.sort(thresholds, function(a, b)
    return a.value > b.value
  end)

  return thresholds
end

for name, definition in pairs(StatusConfig.statuses) do
  if definition.enabled then
    local fault <const> = validateDefinition(definition)

    if fault then
      Siku.print.error(T('status_invalid_definition', name, fault))
    else
      definitions[name] = {
        name = name,
        default = math.min(definition.max, math.max(definition.min, definition.default)),
        min = definition.min,
        max = definition.max,
        decayPerMinute = definition.decayPerMinute,
        damage = definition.damage or 0,
        thresholds = sortThresholds(definition.thresholds or {}),
      }
      ordered[#ordered + 1] = definitions[name]
    end
  end
end

--- Gets a validated status definition.
---@param name any The status name.
---@return table? definition The definition, or nil when unknown.
function StatusRegistry.get(name)
  if type(name) ~= 'string' then
    return nil
  end

  return definitions[name]
end

--- Runs a function over every enabled status.
---@param handler function Receives (name, definition).
---@return nil
function StatusRegistry.forEach(handler)
  for index = 1, #ordered do
    local definition <const> = ordered[index]
    handler(definition.name, definition)
  end
end

--- Builds a fresh table of default values.
---@return table values One entry per enabled status.
function StatusRegistry.defaults()
  local values <const> = {}

  for index = 1, #ordered do
    local definition <const> = ordered[index]
    values[definition.name] = definition.default
  end

  return values
end

--- Counts the enabled statuses.
---@return number count How many statuses are registered.
function StatusRegistry.count()
  return #ordered
end
