--- Sends a state to its client, whole or only what visibly moved. The
--- client forwards it to the HUD: this resource owns the values, the HUD
--- owns their representation.
---@param state table The status state.
---@param force boolean? Whether to send every value regardless of changes.
---@return nil
function SyncCharacterStatuses(state, force)
  local payload = nil

  StatusRegistry.forEach(function(name)
    local rounded <const> = math.floor(state.values[name] + 0.5)

    if force or state.synced[name] ~= rounded then
      payload = payload or {}
      payload[name] = rounded
      state.synced[name] = rounded
    end
  end)

  if payload then
    TriggerClientEvent('siku_status:client:sync', state.sessionId, payload)
  end
end
