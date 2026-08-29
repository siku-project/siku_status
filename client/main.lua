local HUD_RESOURCE <const> = 'siku_hud'
local STARTED <const> = 'started'

RegisterNetEvent('siku_status:client:sync', function(payload)
  if type(payload) ~= 'table' then
    return
  end

  if GetResourceState(HUD_RESOURCE) ~= STARTED then
    return
  end

  for name, value in pairs(payload) do
    if type(name) == 'string' and type(value) == 'number' then
      exports[HUD_RESOURCE]:SetStatus(name, value)
    end
  end
end)

RegisterNetEvent('siku_status:client:damage', function(amount)
  if type(amount) ~= 'number' or amount <= 0 then
    return
  end

  local ped <const> = PlayerPedId()

  if IsEntityDead(ped) then
    return
  end

  ApplyDamageToPed(ped, math.floor(amount), false)
end)
