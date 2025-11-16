--[[
    Shared configuration values that govern the overall game tuning.
    These values are required by several server systems (GameManager, Spawner, UI).
]]

local Config = {}

Config.Base = {
    MaxHealth = 1500,
    -- Amount of health restored at the end of a successful wave (optional buffer).
    WaveClearRegen = 75,
}

Config.Waves = {
    InitialCountdown = 8, -- seconds before wave 1 starts.
    Intermission = 15,    -- downtime between waves.
}

Config.Spawning = {
    SpawnInterval = 2.5, -- seconds between spawns for the same spawn point.
    DefaultAttackInterval = 1.8,
    DefaultAttackRange = 6,
}

return Config
