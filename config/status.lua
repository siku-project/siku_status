StatusConfig = {
  --- Tick interval
  ---
  --- How often the server evaluates decay, thresholds and consequences, in
  --- milliseconds. Decay itself is computed from elapsed time, so this only
  --- bounds how fresh the values are — not how fast they fall.
  tickInterval = 4000,

  --- Save interval
  ---
  --- How often every loaded character is written back to the database, in
  --- milliseconds. Characters are also saved when they unload, when their
  --- player disconnects and when the resource stops.
  saveInterval = 300000,

  --- Pause when dead
  ---
  --- Whether statuses stop decaying (and stop hurting) while the character
  --- is dead.
  pauseWhenDead = true,

  --- Notifications
  ---
  --- Whether crossing a threshold shows a notification through
  --- siku_notification. Threshold events fire either way, so other
  --- resources can react even with notifications turned off.
  notifications = true,

  --- Damage
  ---
  --- What happens while a status sits at its minimum. Each status declares
  --- how hard it hits; what is shared is the pace and the stacking rule.
  damage = {
    enabled = true,

    --- Milliseconds between two damage applications.
    interval = 10000,

    --- Multiplier applied to the summed damage when at least two statuses
    --- are at their minimum at the same time.
    stackedMultiplier = 1.5,
  },

  --- Statuses
  ---
  --- The registry every part of the resource reads. Adding a status later
  --- means adding an entry here (and its translation keys) — nothing else.
  ---
  --- Per status:
  --- - enabled: whether the status exists at all.
  --- - default: the value a fresh character starts with.
  --- - min / max: the bounds every write is clamped into.
  --- - decayPerMinute: how many points an active character loses per minute.
  --- - damage: health points lost per damage interval while at the minimum.
  --- - thresholds: fired once when crossed downward, re-armed by rising
  ---   back above. Each may carry a notification whose title and
  ---   description are translation keys.
  statuses = {
    hunger = {
      enabled = true,
      default = 100,
      min = 0,
      max = 100,
      decayPerMinute = 0.35,
      damage = 2,
      thresholds = {
        {
          value = 25,
          notification = {
            type = 'warning',
            icon = 'mdi-hamburger',
            title = 'hunger_low_title',
            description = 'hunger_low_description',
          },
        },
        {
          value = 10,
          notification = {
            type = 'error',
            icon = 'mdi-hamburger',
            title = 'hunger_critical_title',
            description = 'hunger_critical_description',
          },
        },
        {
          value = 0,
          notification = {
            type = 'error',
            icon = 'mdi-hamburger',
            title = 'hunger_empty_title',
            description = 'hunger_empty_description',
          },
        },
      },
    },

    thirst = {
      enabled = true,
      default = 100,
      min = 0,
      max = 100,
      decayPerMinute = 0.45,
      damage = 3,
      thresholds = {
        {
          value = 25,
          notification = {
            type = 'warning',
            icon = 'mdi-water-outline',
            title = 'thirst_low_title',
            description = 'thirst_low_description',
          },
        },
        {
          value = 10,
          notification = {
            type = 'error',
            icon = 'mdi-water-outline',
            title = 'thirst_critical_title',
            description = 'thirst_critical_description',
          },
        },
        {
          value = 0,
          notification = {
            type = 'error',
            icon = 'mdi-water-outline',
            title = 'thirst_empty_title',
            description = 'thirst_empty_description',
          },
        },
      },
    },
  },
}
