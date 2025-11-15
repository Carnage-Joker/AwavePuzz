-- GameConfig.lua
-- Configuration for the Zombie Wave Game

local GameConfig = {}

-- Player Settings
GameConfig.MAX_PLAYERS = 8
GameConfig.STARTING_HEALTH = 100
GameConfig.RESPAWN_ENABLED = false

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
GameConfig.ZOMBIE_DAMAGE = 10
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

-- Alliance Settings
GameConfig.ALLIANCE_DAMAGE_MULTIPLIER = 0 -- Allies can't damage each other
GameConfig.BETRAYAL_COOLDOWN = 60 -- Seconds before can betray again

-- Resource Settings
GameConfig.RESOURCE_SPAWN_RATE = 45 -- Seconds between resource spawns
GameConfig.MAX_RESOURCES_ON_MAP = 10

return GameConfig
