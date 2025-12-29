--[[
	Constants.lua
	Game-wide constants and configuration values
]]

local Constants = {}

-- Stats
Constants.STATS = {
	GRACE = "Grace",
	ELEGANCE = "Elegance",
	CONFIDENCE = "Confidence",
	CARE = "Care",
}

-- Currencies
Constants.CURRENCIES = {
	GEMS = "Gems",
	COINS = "Coins",
}

-- Outfit slots
Constants.OUTFIT_SLOTS = {
	HAT = "Hat",
	DRESS = "Dress",
	SHOES = "Shoes",
	ACCESSORY1 = "Accessory1",
	ACCESSORY2 = "Accessory2",
	ACCESSORY3 = "Accessory3",
}

-- Max accessories allowed
Constants.MAX_ACCESSORIES = 3

-- Item rarity levels
Constants.RARITY = {
	COMMON = "Common",
	UNCOMMON = "Uncommon",
	RARE = "Rare",
	EPIC = "Epic",
	LEGENDARY = "Legendary",
}

-- Activity cooldowns (in seconds)
Constants.ACTIVITY_COOLDOWN = 300  -- 5 minutes

-- Default profile values
Constants.DEFAULT_PROFILE = {
	stats = {
		Grace = 0,
		Elegance = 0,
		Confidence = 0,
		Care = 0,
	},
	currencies = {
		Gems = 0,
		Coins = 100,  -- Starting coins
	},
	ownedItems = {},  -- Array of item IDs
	equippedOutfit = {
		Hat = nil,
		Dress = nil,
		Shoes = nil,
		Accessory1 = nil,
		Accessory2 = nil,
		Accessory3 = nil,
	},
	unlockedTitles = {},  -- Array of title IDs
	activeTitle = nil,
	activityCooldowns = {},  -- {activityId = timestamp}
}

-- Toast notification types
Constants.TOAST_TYPES = {
	INFO = "Info",
	SUCCESS = "Success",
	WARNING = "Warning",
	ERROR = "Error",
	AFFIRMATION = "Affirmation",
}

return Constants
