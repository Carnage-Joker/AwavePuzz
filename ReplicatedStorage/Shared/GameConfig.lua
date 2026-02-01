-- @ScriptType: ModuleScript
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
GameConfig.DEBUG_SPAWNS = false -- Enable spawn point visualization (Studio only)

-- Player Settings
GameConfig.MAX_PLAYERS = 8
GameConfig.STARTING_HEALTH = 100
GameConfig.RESPAWN_ENABLED = false
GameConfig.STARTING_CURRENCY = 150
GameConfig.CURRENCY_PER_WAVE = 75
GameConfig.DEFAULT_WEAPON = "Pistol" -- Must match WeaponConfig.DefaultWeapon

-- Sprint Settings
GameConfig.SPRINT_SPEED_MULTIPLIER = 1.5 -- How much faster sprinting is compared to walking
GameConfig.STAMINA_MAX = 100 -- Maximum stamina
GameConfig.STAMINA_DEPLETION_RATE = 20 -- Stamina lost per second while sprinting
GameConfig.STAMINA_REGEN_RATE = 15 -- Stamina gained per second while not sprinting
GameConfig.STAMINA_REGEN_DELAY = 1.0 -- Seconds to wait after stopping sprint before regen starts
GameConfig.SPRINT_HOTKEY = "LeftShift" -- Key to hold for sprinting
GameConfig.STAMINA_UPDATE_THRESHOLD = 0.5 -- Minimum stamina change to trigger network update

-- Base Settings
GameConfig.BASE_HEALTH = 1000
GameConfig.BASE_REGEN_RATE = 0 -- No regeneration by default
GameConfig.AUTO_CREATE_BASE_CAMP = true -- Automatically create base camp in map center

-- Development Settings
-- WARNING: These should only be true in Studio during development
GameConfig.DEV_AUTO_CREATE_CURE_STATIONS = false -- Auto-create cure stations when missing (Studio only)

-- Base Camp Configuration
-- These values can be overridden per-map in MapConfig
GameConfig.BASE_CAMP = {
	-- Base structure
	BASE_SIZE = 30, -- Size of the central base structure (studs)
	WALL_HEIGHT = 12, -- Height of defensive walls
	WALL_THICKNESS = 2, -- Thickness of walls
	DEFAULT_HEIGHT = 5, -- Default Y position if ground detection fails

	-- Defensive features
	GATE_WIDTH = 8, -- Width of gates in walls
	GATE_TRANSPARENCY = 0.3, -- Transparency of gates (0=opaque, 1=invisible)
	NUM_GATES = 4, -- Number of gates (one per cardinal direction)
	COVER_COUNT = 8, -- Number of cover positions
	COVER_SIZE = Vector3.new(4, 3, 1), -- Size of cover objects

	-- Colors and materials
	WALL_COLOR = Color3.fromRGB(80, 80, 80), -- Gray walls
	BASE_COLOR = Color3.fromRGB(100, 100, 100), -- Base platform color
	GATE_COLOR = Color3.fromRGB(120, 80, 40), -- Brownish gates
	COVER_COLOR = Color3.fromRGB(70, 70, 70), -- Dark gray cover

	WALL_MATERIAL = Enum.Material.Concrete,
	BASE_MATERIAL = Enum.Material.Concrete,
	GATE_MATERIAL = Enum.Material.Wood,
	COVER_MATERIAL = Enum.Material.Metal,
}

-- Wave Settings
GameConfig.STARTING_WAVE = 1
GameConfig.WAVE_DELAY = 30 -- Seconds between waves
GameConfig.WAVE_INTERMISSION = GameConfig.WAVE_DELAY -- Alias for WAVE_DELAY (used by tests)
GameConfig.ZOMBIES_PER_WAVE_MULTIPLIER = 1.5 -- How much zombies increase per wave
GameConfig.BASE_ZOMBIES_PER_WAVE = 5

-- Spawning Settings (defined early for aliasing)
GameConfig.Spawning = {
	SPAWN_INTERVAL = 2.5, -- seconds between spawns for the same spawn point
	DEFAULT_ATTACK_INTERVAL = 1.8,
	DEFAULT_ATTACK_RANGE = 6,
}

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
GameConfig.ZOMBIE_SPAWN_DELAY = GameConfig.Spawning.SPAWN_INTERVAL -- Delay between zombie spawns (alias for Spawning.SPAWN_INTERVAL)

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
GameConfig.ALLIANCE_DAMAGE_MULTIPLIER = 0 -- Direct allies can't damage each other (only direct edges)
GameConfig.BETRAYAL_COOLDOWN = 60 -- Seconds before can betray again
GameConfig.BETRAYAL_WINDOW = 30 -- Seconds for betrayal combat window

-- Betrayal Transfer Percentages
GameConfig.POOLED_TRANSFER_PERCENT = 0.75 -- 75% pooled transfer on Outcome 1 & 2
GameConfig.PERSONAL_TRANSFER_PERCENT_ON_STALEMATE = 1.00 -- 100% personal transfer on Outcome 3

-- Resource Settings
GameConfig.RESOURCE_SPAWN_RATE = 20 -- Seconds between resource spawns
GameConfig.MAX_RESOURCES_ON_MAP = 10

-- Item Spawn Settings (Ammo & Health Packs)
GameConfig.ITEM_SPAWN_INTERVAL = 60 -- Seconds between item spawns
GameConfig.ITEM_SPAWN_RADIUS = 15 -- Radius around base to spawn items
GameConfig.AMMO_PACK_AMOUNT = 30 -- Amount of ammo given per pack
GameConfig.HEALTH_PACK_AMOUNT = 50 -- Amount of health given per pack
GameConfig.MAX_ITEMS_ON_MAP = 5 -- Maximum number of item packs on map at once

-- Map Settings
GameConfig.ENABLE_MULTI_MAP = true

-- Lobby & Round Settings
GameConfig.LOBBY_VOTING_TIME = 5 -- Seconds for map voting
GameConfig.LOBBY_MIN_PLAYERS = 1 -- Minimum players to start voting
GameConfig.MIN_PLAYERS_TO_START = 1 -- Minimum players required before game can start (recommended: 2 for alliance mechanics)
GameConfig.SCOREBOARD_DISPLAY_TIME = 10 -- Seconds to show scoreboard after round
GameConfig.ROUND_COUNTDOWN_TIME = 5 -- Countdown before round starts after voting
GameConfig.ONE_LIFE_PER_ROUND = true -- Players only have one life per round

-- Portal Matchmaking Settings (New System)
GameConfig.USE_PORTAL_MATCHMAKING = true -- Feature flag: enable portal-based matchmaking instead of voting
GameConfig.PORTAL_MATCHMAKING = {
	MAX_PLAYERS_PER_MATCH = 8, -- Maximum players per match instance
	DEFAULT_MIN_PLAYERS = 1, -- Default minimum players to start countdown (can be overridden per-portal)
	DEFAULT_COUNTDOWN_TIME = 10, -- Default countdown seconds before match starts (can be overridden per-portal)
	COUNTDOWN_CANCEL_THRESHOLD = 1, -- If queue drops below this during countdown, cancel countdown
	POST_LAUNCH_COOLDOWN = 3, -- Seconds to wait after launching a match before portal accepts new players
	TOUCH_DEBOUNCE_TIME = 0.5, -- Seconds between processing touches from same player
	QUEUE_UPDATE_INTERVAL = 1, -- Seconds between queue status broadcasts
}

-- Title Screen & Epilogue Settings
GameConfig.SHOW_TITLE_SCREEN = true -- Show title screen on game start
GameConfig.SHOW_EPILOGUE = true -- Show epilogue/intro cinematic
GameConfig.INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN = false -- Show epilogue on first join (before lobby). If false, epilogue only shows after rounds.
GameConfig.EPILOGUE_SKIPPABLE = true -- Allow players to skip the epilogue
GameConfig.TITLE_SCREEN_TIMEOUT = 30 -- Auto-continue after this many seconds if no input

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
	DEFAULT_UPDATE_JITTER = 0.1, -- Base random offset for update intervals (reduced from 0.3)
	MAX_UPDATE_JITTER = 0.3, -- Max random offset for update intervals (reduced from 1.2)
	LOS_CACHE_TIME = 0.5, -- Cache line-of-sight checks

	-- Movement Continuity (Hesitation Fix)
	WAYPOINT_SKIP_DISTANCE = 3, -- Distance threshold to skip intermediate waypoints and push toward target
	MOVEMENT_REISSUE_DISTANCE = 0.5, -- Distance threshold to re-issue move commands

	-- Debug
	DEBUG_MODE = false, -- Enable visual debug indicators
}

-- Security Settings
GameConfig.Security = {
	MAX_WEAPON_FIRE_DISTANCE = 15, -- Maximum distance from player for weapon fire origin (anti-wallhack)
	LOBBY_DEBOUNCE_TIME = 1.0, -- Seconds between lobby resolution attempts (prevent race conditions)
}

return GameConfig