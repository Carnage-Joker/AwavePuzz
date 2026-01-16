-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
-- UIScaleConfig.lua
-- Configuration for dynamic UI scaling based on device/screen size
--[[
    This module provides scale factors and breakpoints for responsive UI.
    Mobile devices need smaller UI elements to avoid blocking player vision.
    Roblox-specific safe areas are accounted for (top bar, bottom controls).
]]

local UIScaleConfig = {}

-- Screen size breakpoints (based on viewport width in pixels)
UIScaleConfig.Breakpoints = {
	MOBILE_SMALL = 480,   -- Small phones
	MOBILE_LARGE = 768,   -- Large phones / small tablets
	TABLET = 1024,        -- Tablets
	DESKTOP = 1280,       -- Desktop / large screens
}

-- Scale factors for each device category
-- Values < 1.0 make elements smaller, > 1.0 makes them larger
UIScaleConfig.ScaleFactors = {
	MOBILE_SMALL = {
		ui = 0.65,           -- General UI scale
		text = 0.7,          -- Text size multiplier
		padding = 0.6,       -- Spacing/padding multiplier
		hudElements = 0.55,  -- HUD elements (health, compass, etc.)
		menuElements = 0.75, -- Menu/dialog elements
	},
	MOBILE_LARGE = {
		ui = 0.75,
		text = 0.8,
		padding = 0.75,
		hudElements = 0.65,
		menuElements = 0.85,
	},
	TABLET = {
		ui = 0.85,
		text = 0.9,
		padding = 0.85,
		hudElements = 0.8,
		menuElements = 0.9,
	},
	DESKTOP = {
		ui = 1.0,
		text = 1.0,
		padding = 1.0,
		hudElements = 1.0,
		menuElements = 1.0,
	},
}

-- Safe area insets for Roblox UI (approximate values)
-- These account for Roblox's top bar and mobile controls
UIScaleConfig.SafeAreas = {
	MOBILE = {
		top = 50,     -- Roblox top bar
		bottom = 90,  -- Mobile jump button / controls
		left = 10,
		right = 10,
	},
	TABLET = {
		top = 50,
		bottom = 70,
		left = 10,
		right = 10,
	},
	DESKTOP = {
		top = 36,     -- Roblox top bar
		bottom = 10,
		left = 10,
		right = 10,
	},
}

-- Priority levels for UI elements (higher = more important to keep visible)
-- Elements with lower priority can be hidden or minimized on smaller screens
UIScaleConfig.ElementPriority = {
	CRITICAL = 5,    -- Must always be visible (health, game-over screens)
	HIGH = 4,        -- Very important (wave info, cure progress)
	MEDIUM = 3,      -- Important but can be minimized (inventory, base health)
	LOW = 2,         -- Can be hidden/collapsed (scoreboard, alliance list)
	OPTIONAL = 1,    -- Can be hidden entirely on mobile (hints, detailed stats)
}

-- Maximum UI element sizes (prevents elements from getting too large)
UIScaleConfig.MaxSizes = {
	healthBar = { width = 300, height = 30 },
	compass = { width = 350, height = 40 },
	waveInfo = { width = 280, height = 140 },
	cureProgress = { width = 320, height = 110 },
	inventory = { width = 280, height = 140 },
	baseHealth = { width = 320, height = 70 },
	menuDialog = { width = 500, height = 600 },
}

-- Minimum sizes to maintain usability
UIScaleConfig.MinSizes = {
	healthBar = { width = 120, height = 18 },
	compass = { width = 150, height = 22 },
	waveInfo = { width = 140, height = 70 },
	cureProgress = { width = 160, height = 60 },
	inventory = { width = 140, height = 70 },
	baseHealth = { width = 160, height = 40 },
	menuDialog = { width = 280, height = 300 },
	-- Minimum touch target size per iOS Human Interface Guidelines (44pt)
	-- Android Material Design recommends 48dp, but 44px works well for Roblox cross-platform
	touchTarget = { width = 44, height = 44 },
}

-- Opacity settings for mobile (can make UI more transparent)
UIScaleConfig.MobileOpacity = {
	hudBackground = 0.4,      -- More transparent backgrounds
	hudText = 1.0,            -- Keep text fully visible
	overlayBackground = 0.15, -- Light overlay for menus
}

-- Position presets that account for safe areas and Roblox menus
-- These are normalized positions (0-1) with offsets
UIScaleConfig.Positions = {
	-- Top-left: Inventory/Stats
	topLeft = {
		anchor = Vector2.new(0, 0),
		position = UDim2.new(0, 0, 0, 0), -- Will be adjusted by safe area
	},
	-- Top-center: Compass/Wave info
	topCenter = {
		anchor = Vector2.new(0.5, 0),
		position = UDim2.new(0.5, 0, 0, 0),
	},
	-- Top-right: Cure progress
	topRight = {
		anchor = Vector2.new(1, 0),
		position = UDim2.new(1, 0, 0, 0),
	},
	-- Bottom-left: Health bar
	bottomLeft = {
		anchor = Vector2.new(0, 1),
		position = UDim2.new(0, 0, 1, 0),
	},
	-- Center: Menus/Dialogs
	center = {
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.new(0.5, 0, 0.5, 0),
	},
}

return UIScaleConfig
