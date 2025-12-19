-- GameConfig.lua
-- Configuration for the Zombie Wave Game
--[[
    Shared configuration values that govern the overall game tuning.
    These values are required by several server systems (GameManager, Spawner, UI).
]]
local GameConfig = {}

-- Debug & Testing
-- Set to true to enable test and debug scripts
-- WARNING: Should always be false in production
GameConfig.DEBUG = false

-- Player Settings
GameConfig.MAX_PLAYERS = 8
GameConfig.STARTING_HEALTH = 100
GameConfig.RESPAWN_ENABLED = false
GameConfig.STARTING_CURRENCY = 150
GameConfig.CURRENCY_PER_WAVE = 75
GameConfig.DEFAULT_WEAPON = "Pistol"

-- Sprint Settings
GameConfig.SPRINT_SPEED_MULTIPLIER = 1.5 -- How much faster sprinting is compared to walking
GameConfig.STAMINA_MAX = 100 -- Maximum stamina
GameConfig.STAMINA_DEPLETION_RATE = 20 -- Stamina lost per second while sprinting
GameConfig.STAMINA_REGEN_RATE = 15 -- Stamina gained per second while not sprinting
GameConfig.STAMINA_REGEN_DELAY = 1.0 -- Seconds to wait after stopping sprint before regen starts
GameConfig.SPRINT_HOTKEY = "LeftShift" -- Key to hold for sprinting

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
GameConfig.ZOMBIE_DAMAGE = 10  -- Increased from 1 to make zombie attacks meaningful. 
-- With 100 player HP: 10 hits to kill player
-- With 1000 base HP: 100 hits to destroy base
GameConfig.ZOMBIE_SPEED = 16
GameConfig.ZOMBIE_HEALTH_MULTIPLIER = 1.2 -- Health increase per wave
GameConfig.ZOMBIE_ATTACK_RANGE = 6 -- Range at which zombies attack (studs)
GameConfig.ZOMBIE_ATTACK_INTERVAL = 1.5 -- Seconds between zombie attacks
GameConfig.ZOMBIE_REPATH_INTERVAL = 0.4 -- How often zombies recalculate path (reduced from 1.0 to prevent pausing)

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
GameConfig.BETRAYAL_WINDOW = 30 -- Seconds for betrayal combat window

-- Resource Settings
GameConfig.RESOURCE_SPAWN_RATE = 20 -- Seconds between resource spawns
GameConfig.MAX_RESOURCES_ON_MAP = 10

-- Map Settings
GameConfig.ENABLE_MULTI_MAP = true

-- Lobby & Round Settings
GameConfig.LOBBY_VOTING_TIME = 20 -- Seconds for map voting
GameConfig.LOBBY_MIN_PLAYERS = 1 -- Minimum players to start voting
GameConfig.SCOREBOARD_DISPLAY_TIME = 10 -- Seconds to show scoreboard after round
GameConfig.ROUND_COUNTDOWN_TIME = 5 -- Countdown before round starts after voting
GameConfig.ONE_LIFE_PER_ROUND = true -- Players only have one life per round

-- Tactical AI Settings
GameConfig.AI = {
	-- Targeting
	OVERCROWD_RADIUS = 15, -- Radius to check for overcrowding
	OVERCROWD_THRESHOLD = 3, -- Max zombies before penalty
	OVERCROWD_PENALTY = 50, -- Score penalty per zombie beyond threshold
	
	-- Surround System
	INNER_RING_RADIUS = 8,
	MIDDLE_RING_RADIUS = 15,
	OUTER_RING_RADIUS = 25,
	SLOTS_PER_RING = 8,
	SEPARATION_RADIUS = 3,
	
	-- AI Director
	BASE_PRESSURE_MIN = 0.2,
	BASE_PRESSURE_MAX = 0.6,
	SURGE_INTERVAL_MIN = 30,
	SURGE_INTERVAL_MAX = 60,
	
	-- Boss Aura
	BOSS_AURA_RADIUS = 40,
	AURA_MOVE_SPEED_BOOST = 1.1,
	AURA_RETARGET_BOOST = 0.5,
	
	-- Performance
	DEFAULT_UPDATE_JITTER = 0.3, -- Random offset for update intervals
	MAX_UPDATE_JITTER = 1.2,
	LOS_CACHE_TIME = 0.5, -- Cache line-of-sight checks
	
	-- Debug
	DEBUG_MODE = false, -- Enable visual debug indicators
}

return GameConfig
