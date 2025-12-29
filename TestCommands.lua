--[[
	TestCommands.lua
	Quick test commands for Roblox Studio Command Bar
	
	Usage: Copy and paste these commands into the Command Bar (View → Command Bar)
	       to test the game systems without building a full UI.
]]

-- ============================================================
-- SETUP (Run this first)
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Get player (assumes one player in Studio)
local player = Players:GetChildren()[1]

if not player then
	print("❌ No player found! Make sure you're in Play mode.")
	return
end

-- Get services (server-side testing)
local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)

print("✅ Test environment ready!")
print("Player:", player.Name)

-- ============================================================
-- TEST COMMANDS
-- ============================================================

-- TEST 1: Get Player Profile
-- Shows all player data including stats, currencies, items, titles
do
	local getProfileFunc = Remotes.getFunction("GetProfile")
	local profile = getProfileFunc:InvokeServer()
	
	print("\n=== PLAYER PROFILE ===")
	print("Stats:", profile.stats)
	print("Currencies:", profile.currencies)
	print("Owned Items:", #profile.ownedItems, "items")
	print("Unlocked Titles:", #profile.unlockedTitles, "titles")
	print("Active Title:", profile.activeTitle or "none")
end

-- TEST 2: Get Outfit Catalog
-- Shows all available items
do
	local getCatalogFunc = Remotes.getFunction("GetCatalog")
	local catalog = getCatalogFunc:InvokeServer()
	
	print("\n=== OUTFIT CATALOG ===")
	print("Total Items:", #catalog)
	
	-- Show first 5 items as sample
	for i = 1, math.min(5, #catalog) do
		local item = catalog[i]
		print(string.format("  %s: %s (%s, %d Coins)", 
			item.id, item.name, item.rarity, item.price))
	end
end

-- TEST 3: Complete Activity
-- Completes "mirror_pose" activity and shows rewards
do
	local completeActivityFunc = Remotes.getFunction("CompleteActivity")
	local result = completeActivityFunc:InvokeServer("mirror_pose")
	
	print("\n=== COMPLETE ACTIVITY: Mirror Pose ===")
	if result.success then
		print("✅ Success:", result.message)
		if result.rewards then
			print("Rewards:", table.concat(result.rewards, ", "))
		end
	else
		print("❌ Failed:", result.message)
		if result.cooldownRemaining then
			print("Cooldown:", result.cooldownRemaining, "seconds remaining")
		end
	end
end

-- TEST 4: Set Title
-- Equips the "novice" title (unlocked by default)
do
	local setTitleFunc = Remotes.getFunction("SetTitle")
	local result = setTitleFunc:InvokeServer("novice")
	
	print("\n=== SET TITLE: Novice ===")
	if result.success then
		print("✅ Success:", result.message)
	else
		print("❌ Failed:", result.message)
	end
end

-- TEST 5: Give Player Items (Server-Side Only)
-- This requires direct service access, only works on server
if ServerScriptService:FindFirstChild("Services") then
	local DataService = require(ServerScriptService.Services.DataService)
	local dataServiceInstance = nil
	
	-- Find or create DataService instance
	-- In the actual game, this is managed by Main.server.lua
	-- For testing, we access the profile directly
	
	print("\n=== GRANT TEST ITEMS ===")
	print("Note: To give items, use OutfitService:purchaseItem() or add to profile manually")
	print("Example: Add 'hat_beret' to ownedItems in DataService")
end

-- TEST 6: Try All Activities
do
	print("\n=== AVAILABLE ACTIVITIES ===")
	
	local activities = {
		{id = "mirror_pose", name = "Mirror Pose Practice"},
		{id = "styling_desk", name = "Styling Desk Organization"},
		{id = "garden_decor", name = "Garden Decoration"},
	}
	
	local completeActivityFunc = Remotes.getFunction("CompleteActivity")
	
	for _, activity in ipairs(activities) do
		local result = completeActivityFunc:InvokeServer(activity.id)
		if result.success then
			print(string.format("✅ %s: %s", activity.name, result.message))
		else
			print(string.format("⏱️  %s: On cooldown", activity.name))
		end
		task.wait(0.1)
	end
end

-- TEST 7: Check Title Unlocks
-- Shows which titles are unlocked based on current stats
do
	print("\n=== TITLE UNLOCK STATUS ===")
	
	local getProfileFunc = Remotes.getFunction("GetProfile")
	local profile = getProfileFunc:InvokeServer()
	
	local Titles = require(ReplicatedStorage.Shared.Data.Titles)
	
	for _, title in ipairs(Titles.list) do
		local isUnlocked = false
		for _, unlockedId in ipairs(profile.unlockedTitles) do
			if unlockedId == title.id then
				isUnlocked = true
				break
			end
		end
		
		local status = isUnlocked and "✅ UNLOCKED" or "🔒 LOCKED"
		print(string.format("%s %s - %s", status, title.name, title.description))
	end
end

-- TEST 8: Show Stats After Activities
do
	print("\n=== CURRENT STATS ===")
	
	local getProfileFunc = Remotes.getFunction("GetProfile")
	local profile = getProfileFunc:InvokeServer()
	
	for statName, value in pairs(profile.stats) do
		print(string.format("  %s: %d", statName, value))
	end
	
	print("\nCurrencies:")
	for currencyName, value in pairs(profile.currencies) do
		print(string.format("  %s: %d", currencyName, value))
	end
end

print("\n✅ All tests complete!")

-- ============================================================
-- ADVANCED TESTING (Server-Side)
-- ============================================================

--[[
	To test server-side features directly:
	
	-- Give player coins
	local CurrencyService = require(ServerScriptService.Services.CurrencyService)
	-- Note: You need the service instance from Main.server.lua
	
	-- Grant stats
	local StatsService = require(ServerScriptService.Services.StatsService)
	-- Note: You need the service instance from Main.server.lua
	
	-- Add items to inventory
	local DataService = require(ServerScriptService.Services.DataService)
	local profile = DataService:getProfile(player)
	table.insert(profile.ownedItems, "hat_beret")
	table.insert(profile.ownedItems, "dress_casual")
	table.insert(profile.ownedItems, "shoes_flats")
	
	-- Then try equipping
	local result = Remotes.getFunction("EquipOutfit"):InvokeServer("hat_beret")
	print(result.success, result.message)
]]

-- ============================================================
-- CLEANUP / RESET (Use carefully!)
-- ============================================================

--[[
	To reset a player's profile:
	
	local DataService = require(ServerScriptService.Services.DataService)
	local Constants = require(ReplicatedStorage.Shared.Constants)
	local Util = require(ReplicatedStorage.Shared.Util)
	
	-- Get fresh default profile
	local newProfile = Util.deepCopy(Constants.DEFAULT_PROFILE)
	
	-- Set it (this requires direct access to profiles table in DataService)
	-- In production, you'd save/reload or create a reset remote
]]
