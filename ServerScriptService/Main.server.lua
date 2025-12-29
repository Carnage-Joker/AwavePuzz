--[[
	Main.server.lua
	Main server initialization and remote event handlers
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Import networking
local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)

-- Import services
local DataService = require(ServerScriptService.Services.DataService).new()
local StatsService = require(ServerScriptService.Services.StatsService).new()
local CurrencyService = require(ServerScriptService.Services.CurrencyService).new()
local OutfitService = require(ServerScriptService.Services.OutfitService).new()
local ActivityService = require(ServerScriptService.Services.ActivityService).new()
local TitleService = require(ServerScriptService.Services.TitleService).new()
local AffirmationService = require(ServerScriptService.Services.AffirmationService).new()

print("🎮 Main.server.lua starting...")

-- Initialize remotes first
Remotes.initialize()

-- Initialize services
DataService:initialize()
StatsService:initialize(DataService)
CurrencyService:initialize(DataService)
OutfitService:initialize(DataService, CurrencyService)
ActivityService:initialize(DataService, StatsService, CurrencyService)
TitleService:initialize(DataService)
AffirmationService:initialize()

print("✅ All services initialized")

-- ============================================================
-- REMOTE HANDLERS
-- ============================================================

-- GetCatalog - Return outfit catalog
local getCatalogFunc = Remotes.getFunction("GetCatalog")
getCatalogFunc.OnServerInvoke = function(player)
	return OutfitService:getCatalog()
end

-- EquipOutfit - Equip an item
local equipOutfitFunc = Remotes.getFunction("EquipOutfit")
equipOutfitFunc.OnServerInvoke = function(player, itemId)
	-- Validate input
	if type(itemId) ~= "string" then
		return {success = false, message = "Invalid item ID"}
	end
	
	return OutfitService:equipItem(player, itemId)
end

-- GetProfile - Return player profile
local getProfileFunc = Remotes.getFunction("GetProfile")
getProfileFunc.OnServerInvoke = function(player)
	local profile = DataService:getProfile(player)
	if not profile then
		return nil
	end
	
	-- Return safe copy (don't expose internal data structures)
	return {
		stats = profile.stats,
		currencies = profile.currencies,
		ownedItems = profile.ownedItems,
		equippedOutfit = profile.equippedOutfit,
		unlockedTitles = profile.unlockedTitles,
		activeTitle = profile.activeTitle,
	}
end

-- CompleteActivity - Complete an activity
local completeActivityFunc = Remotes.getFunction("CompleteActivity")
completeActivityFunc.OnServerInvoke = function(player, activityId)
	-- Validate input
	if type(activityId) ~= "string" then
		return {success = false, message = "Invalid activity ID"}
	end
	
	local result = ActivityService:completeActivity(player, activityId)
	
	-- Check for title unlocks after activity completion
	if result.success then
		local newTitles = TitleService:checkUnlocks(player)
		if #newTitles > 0 then
			-- Notify player of new titles
			local toastEvent = Remotes.getEvent("PushToast")
			for _, title in ipairs(newTitles) do
				toastEvent:FireClient(player, {
					type = "Success",
					title = "🏆 Title Unlocked!",
					message = title.name,
					duration = 5,
				})
			end
		end
	end
	
	return result
end

-- SetTitle - Set active title
local setTitleFunc = Remotes.getFunction("SetTitle")
setTitleFunc.OnServerInvoke = function(player, titleId)
	-- Validate input (nil is allowed for unequipping)
	if titleId ~= nil and type(titleId) ~= "string" then
		return {success = false, message = "Invalid title ID"}
	end
	
	return TitleService:setTitle(player, titleId)
end

-- ============================================================
-- PLAYER LIFECYCLE
-- ============================================================

Players.PlayerAdded:Connect(function(player)
	print(string.format("Player %s joined", player.Name))
	
	-- Load profile
	local profile = DataService:loadProfile(player)
	
	-- Unlock default title if not already unlocked
	local hasNovice = false
	for _, titleId in ipairs(profile.unlockedTitles) do
		if titleId == "novice" then
			hasNovice = true
			break
		end
	end
	
	if not hasNovice then
		table.insert(profile.unlockedTitles, "novice")
		if not profile.activeTitle then
			profile.activeTitle = "novice"
		end
	end
	
	-- Sync initial stats
	task.wait(1)  -- Give client time to initialize
	StatsService:syncStats(player)
	
	-- Send welcome affirmation
	task.wait(3)
	AffirmationService:triggerAffirmation(player)
end)

Players.PlayerRemoving:Connect(function(player)
	print(string.format("Player %s leaving", player.Name))
end)

print("🎮 Main.server.lua initialized - Game ready!")
