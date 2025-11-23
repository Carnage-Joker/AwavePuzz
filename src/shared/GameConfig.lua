-- GameConfig.lua
-- Configuration for the Zombie Wave Game
--[[
    Shared configuration values that govern the overall game tuning.
    These values are required by several server systems (GameManager, Spawner, UI).
]]
local GameConfig = {}

-- Player Settings
GameConfig.MAX_PLAYERS = 8
GameConfig.STARTING_HEALTH = 100
GameConfig.RESPAWN_ENABLED = false
GameConfig.STARTING_CURRENCY = 150
GameConfig.CURRENCY_PER_WAVE = 75
GameConfig.DEFAULT_WEAPON = "Pistol"

-- Base Settings
GameConfig.BASE_HEALTH = 1000
GameConfig.BASE_REGEN_RATE = 0 -- No regeneration by default

-- Wave Settings
GameConfig.STARTING_WAVE = 1
GameConfig.WAVE_DELAY = 30 -- Seconds between waves
GameConfig.ZOMBIES_PER_WAVE_MULTIPLIER = 1.5 -- How much zombies increase per wave
GameConfig.BASE_ZOMBIES_PER_WAVE = 5

-- Zombie Settings
GameConfig.ZOMBIE_HEALTH = 50
GameConfig.ZOMBIE_DAMAGE = 1
GameConfig.ZOMBIE_SPEED = 16
GameConfig.ZOMBIE_HEALTH_MULTIPLIER = 1.2 -- Health increase per wave

-- Cure Crafting Settings
GameConfig.CURE_COMPONENTS_REQUIRED = 5
GameConfig.CURE_COMPONENT_NAMES = {
	"Chemical A",
	"Chemical B",
	"Biological Sample",
	"Research Notes",
	"Catalyst"
}

-- Spawning Settings
GameConfig.Spawning = {
	SPAWN_INTERVAL = 2.5, -- seconds between spawns for the same spawn point
	DEFAULT_ATTACK_INTERVAL = 1.8,
	DEFAULT_ATTACK_RANGE = 6,
}

-- Alliance Settings
GameConfig.ALLIANCE_DAMAGE_MULTIPLIER = 0 -- Allies can't damage each other
GameConfig.BETRAYAL_COOLDOWN = 60 -- Seconds before can betray again

-- Resource Settings
GameConfig.RESOURCE_SPAWN_RATE = 45 -- Seconds between resource spawns
GameConfig.MAX_RESOURCES_ON_MAP = 10

-- Map Settings
GameConfig.ENABLE_MULTI_MAP = true

return GameConfig
