---
applyTo: "src/shared/**/*.lua"
---

# Shared Code Instructions

## Shared Module Guidelines

These scripts live in ReplicatedStorage and can be accessed by both server and client.

### What Belongs in Shared

1. **Configuration** - Game constants, tuning values
2. **Data Structures** - Pure data definitions (zombie types, wave configs)
3. **Utility Functions** - Helper functions with no side effects
4. **Enums/Constants** - Shared constant values

### What Does NOT Belong in Shared

1. **Game State** - Player health, cure progress (server only)
2. **Server Logic** - Damage calculation, validation (server only)
3. **UI Logic** - Display code (client only)
4. **Side Effects** - No RemoteEvent firing, no instance manipulation

### Module Pattern

```lua
-- GameConfig.lua
local Config = {}

-- Player Settings
Config.MAX_PLAYERS = 8
Config.STARTING_HEALTH = 100
Config.RESPAWN_ENABLED = false

-- Base Settings
Config.BASE_HEALTH = 1000
Config.BASE_REGENERATION = 0

-- Wave Settings
Config.WAVE_DELAY = 30
Config.BASE_ZOMBIES_PER_WAVE = 5
Config.ZOMBIE_MULTIPLIER = 1.5
Config.HEALTH_MULTIPLIER = 1.2

-- Zombie Settings
Config.ZOMBIE_HEALTH = 50
Config.ZOMBIE_DAMAGE = 10
Config.ZOMBIE_SPEED = 16

-- Resource Settings
Config.RESOURCE_SPAWN_RATE = 45
Config.MAX_RESOURCES_ON_MAP = 10
Config.COMPONENTS_REQUIRED = 5

-- Cure Components
Config.CURE_COMPONENTS = {
    "Chemical A",
    "Chemical B", 
    "Biological Sample",
    "Research Notes",
    "Catalyst"
}

return Config
```

### Zombie Types Definition

```lua
-- ZombieTypes.lua
local ZombieTypes = {
    Walker = {
        Model = "Walker",
        Speed = 10,
        Damage = 10,
        Health = 60,
        Reward = 5
    },
    Runner = {
        Model = "Runner",
        Speed = 18,
        Damage = 8,
        Health = 45,
        Reward = 6
    },
    Brute = {
        Model = "Brute",
        Speed = 8,
        Damage = 20,
        Health = 150,
        Reward = 20
    },
    Spitter = {
        Model = "Spitter",
        Speed = 12,
        Damage = 6,
        Health = 70,
        Reward = 12
    },
    Boss = {
        Model = "Boss",
        Speed = 10,
        Damage = 28,
        Health = 550,
        Reward = 100
    }
}

return ZombieTypes
```

### Wave Configuration

```lua
-- WaveConfig.lua
local WaveConfig = {}

-- Wave 1
WaveConfig[1] = {
    Number = 1,
    TimeLimit = 120,
    Zombies = {
        Walker = 5
    }
}

-- Wave 2
WaveConfig[2] = {
    Number = 2,
    TimeLimit = 150,
    Zombies = {
        Walker = 6,
        Runner = 2
    }
}

-- etc...

return WaveConfig
```

### Utility Functions

Keep utilities pure (no side effects):

```lua
-- MathUtils.lua
local MathUtils = {}

function MathUtils.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function MathUtils.lerp(a, b, t)
    return a + (b - a) * t
end

function MathUtils.calculateDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

return MathUtils
```

### Immutability

Shared config should be read-only:

```lua
-- Good: Read values
local maxPlayers = Config.MAX_PLAYERS

-- Bad: Don't modify shared config at runtime
Config.MAX_PLAYERS = 10 -- NO!
```

### Documentation

Always document config values:

```lua
local Config = {}

-- Maximum number of players allowed in a server instance
-- Default: 8, Range: 1-50
Config.MAX_PLAYERS = 8

-- Starting health for each player when they spawn
-- Default: 100, Range: 1-1000
Config.STARTING_HEALTH = 100

return Config
```

### Versioning

Consider adding version info:

```lua
local Config = {}

Config.VERSION = "1.0.0"
Config.LAST_UPDATED = "2024-01-15"

-- rest of config...

return Config
```

### Testing Checklist

- [ ] No side effects in module code
- [ ] No RemoteEvent usage
- [ ] No instance creation/manipulation
- [ ] Pure functions only
- [ ] Well-documented constants
- [ ] Accessible from both server and client
