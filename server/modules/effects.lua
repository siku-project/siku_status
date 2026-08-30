--- Applies the status map a consumable declares. The inventory hands over
--- the used instance with its declared effects; this resource clamps and
--- applies them without ever knowing the catalogue. Returning true tells the
--- caller the consumption is earned, so the unit gets spent.
---@param source number The player server id.
---@param item table The used instance, carrying a status map.
---@return boolean applied Whether at least one status was changed.
local function consume(source, item)
  if type(item) ~= 'table' or type(item.status) ~= 'table' then
    return false
  end

  local state <const> = GetStatusState(source)

  if not state then
    return false
  end

  local applied = false

  for name, amount in pairs(item.status) do
    local definition <const> = StatusRegistry.get(name)

    if definition and type(amount) == 'number' and amount ~= 0 then
      ApplyStatusValue(state, definition, state.values[definition.name] + amount)
      applied = true
    end
  end

  return applied
end

exports('Consume', consume)
