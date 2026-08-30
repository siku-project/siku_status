# siku_status

A modular status system for the SIKU ecosystem — managing persistent character needs such as hunger and thirst with scalable state handling, configurable decay, thresholds, effects, and seamless integration across immersive FiveM roleplay experiences.

![Version](https://img.shields.io/badge/version-0.2.0-4785bd)
![FiveM](https://img.shields.io/badge/fx__version-cerulean-4785bd)
![Lua](https://img.shields.io/badge/Lua-5.4-4785bd)

## Features

- **Hunger and thirst** — per character, not per player: each character owns its values, loaded when it becomes active and never bleeding into another one.
- **Server authoritative** — the server owns every value, every change and every consequence. The client only ever receives what it needs to display; it is never believed.
- **Elapsed-time decay** — values fall by `elapsed × rate`, not by a fixed step per loop turn, so the pace never depends on tick frequency. Thirst falls slightly faster than hunger; both rates are configuration.
- **Registry-driven** — statuses are declared once in `config/status.lua` (default, bounds, decay, damage, thresholds). Adding a future status (fatigue, stress…) is a new entry and its translation keys, not a rewrite.
- **Edge-triggered thresholds** — each threshold fires once when crossed downward, stays silent while the value sits below it, and re-arms when it rises back above. Every crossing raises a server event; a notification goes out through `siku_notification` when it is available (soft dependency — the system runs fine without it).
- **Consequences at zero** — an empty status slowly hurts the character at a configurable pace, thirst slightly harder than hunger, with a multiplier when several statuses are empty at once.
- **Efficient persistence** — values live in memory as one JSON object per character, written periodically and on character unload, disconnect and resource stop. No SQL per tick, one row per character, `schema_version` ready for future reshaping.
- **No offline decay** — an unloaded character does not get hungrier. Decay only runs while the character is active, and pauses while it is dead (configurable).
- **HUD integration** — value changes flow `siku_status → siku_hud → NUI`. This resource never touches the interface; it hands the HUD its numbers through the HUD's own API, at most one small event when something visibly changed.
- **Restart resilient** — restarting the resource reloads the statuses of every character already in the world.

## Dependencies

| Resource | Required | Purpose |
|---|---|---|
| [`siku_core`](https://github.com/siku-project/siku_core) | Yes | Framework core: character cache, migrations, timers, locale, notification proxy. |
| [oxmysql](https://github.com/CommunityOx/oxmysql) | Yes | Database access. |
| [`siku_notification`](https://github.com/siku-project/siku_notification) | No | Threshold notifications, through the core proxy. |
| [`siku_hud`](https://github.com/siku-project/siku_hud) | No | Displays the values. The HUD depends on this resource, not the reverse. |

`siku_core` must be started **before** `siku_status`.

### server.cfg

```cfg
ensure oxmysql
ensure siku_core
ensure siku_status
ensure siku_hud
```

## Configuration

All options live in `config/` and are documented inline.

| File | Options |
|---|---|
| `config/status.lua` | `tickInterval`, `saveInterval`, `pauseWhenDead`, `notifications`, `damage` (`enabled`, `interval`, `stackedMultiplier`), and the `statuses` registry — per status: `enabled`, `default`, `min`, `max`, `decayPerMinute`, `damage`, `thresholds` (value + optional notification) |
| `config/migration.lua` | Schema declaration, applied additively through the core migration service |
| `config/translation.lua` | `language` (`fr` / `en`) |

## API

Everything goes through server exports. Values are always clamped into the status bounds — asking for `+500` hunger lands on the maximum.

### Server exports

| Export | Arguments | Returns | Purpose |
|---|---|---|---|
| `GetStatus` | `source`, `name` | `number?` | Current value of one status. |
| `GetStatuses` | `source` | `table?` | Every status of the active character. |
| `SetStatus` | `source`, `name`, `value` | `number?` | Sets an absolute value. |
| `AddStatus` | `source`, `name`, `amount` | `number?` | Adds (a food item feeds hunger this way). |
| `RemoveStatus` | `source`, `name`, `amount` | `number?` | Removes. |
| `ResetStatus` | `source`, `name?` | `boolean` | Resets one status, or all of them, to defaults. |
| `Consume` | `source`, `item` | `boolean` | Applies the `status` map a consumable declares — the export food and drink items point to. Returns whether anything was applied, which tells the inventory to spend the unit. |

```lua
-- Direct API, server-side, once the action was validated:
exports.siku_status:AddStatus(source, 'hunger', 25)
exports.siku_status:AddStatus(source, 'thirst', 35)

-- Reading:
local thirst = exports.siku_status:GetStatus(source, 'thirst')
```

### Consumables

Food and drink never call this resource themselves: the inventory item declares its effects and points its use at the `Consume` export —

```lua
-- In siku_inventory's shared/items.lua:
burger = {
  -- …
  status = { hunger = 35 },
  server = { export = 'siku_status.Consume' },
},
```

— and using the item flows through the inventory's declared-use pipeline. Amounts are clamped like every other write, negative values work (salty chips can cost thirst), and the unit is only spent when something was actually applied.

### Events

| Event | Side | Payload | Fired |
|---|---|---|---|
| `siku:status:threshold` | server | `sessionId, characterId, name, threshold` | Once per downward crossing of a configured threshold. |

## How it talks to siku_hud

The chain is strict and one-directional:

```
gameplay / inventory
        ↓  exports.siku_status:AddStatus(...)
siku_status (owns the values, decays them, clamps them, persists them)
        ↓  siku_status:client:sync — only when a displayed value changed
siku_status client
        ↓  exports.siku_hud:SetStatus(name, value)
siku_hud → NUI
```

`siku_status` never manipulates the HUD's interface. If the HUD is absent the sync is simply dropped, and if the HUD is replaced someday, nothing here changes.

## Extending

Adding a status later:

1. Add its entry to `StatusConfig.statuses` in `config/status.lua`.
2. Add its notification strings to `translations/fr.lua` and `translations/en.lua`.

Stored rows merge with the registry defaults on load, so existing characters pick the new status up at its default value automatically.

## Credits

Part of the [SIKU project](https://github.com/siku-project) — © Siku Studio.
