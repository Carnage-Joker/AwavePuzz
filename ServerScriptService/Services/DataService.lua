--[[
	DataService.lua
	Manages player profile data, autosave, and reconciliation
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Util = require(ReplicatedStorage.Shared.Util)

local DataService = {}
DataService.__index = DataService

-- In-memory player profiles (UserId -> profile)
local profiles = {}

-- Mock data store (in production, use DataStoreService)
local mockDataStore = {}

-- Autosave interval (seconds)
local AUTOSAVE_INTERVAL = 60

function DataService.new()
	local self = setmetatable({}, DataService)
	self.initialized = false
	return self
end

function DataService:initialize()
	print("📊 DataService initializing...")
	
	-- Start autosave loop
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			self:autosaveAll()
		end
	end)
	
	-- Handle player leaving
	Players.PlayerRemoving:Connect(function(player)
		self:saveProfile(player)
		profiles[player.UserId] = nil
	end)
	
	self.initialized = true
	print("✅ DataService initialized")
	return true
end

-- Load or create player profile
function DataService:loadProfile(player: Player)
	local userId = player.UserId
	
	-- Check if already loaded
	if profiles[userId] then
		return profiles[userId]
	end
	
	-- Try to load from mock data store
	local savedData = mockDataStore[userId]
	
	local profile
	if savedData then
		-- Reconcile with defaults (add missing fields)
		profile = Util.reconcileProfile(savedData, Constants.DEFAULT_PROFILE)
		print(string.format("Loaded profile for %s (UserId: %d)", player.Name, userId))
	else
		-- Create new profile
		profile = Util.deepCopy(Constants.DEFAULT_PROFILE)
		-- Give starting items (optional)
		-- profile.ownedItems = {"hat_beret", "dress_casual", "shoes_flats"}
		print(string.format("Created new profile for %s (UserId: %d)", player.Name, userId))
	end
	
	profiles[userId] = profile
	return profile
end

-- Save player profile
function DataService:saveProfile(player: Player)
	local userId = player.UserId
	local profile = profiles[userId]
	
	if not profile then
		warn(string.format("No profile to save for %s", player.Name))
		return false
	end
	
	-- Save to mock data store (in production, use DataStoreService:SetAsync)
	mockDataStore[userId] = Util.deepCopy(profile)
	print(string.format("Saved profile for %s (UserId: %d)", player.Name, userId))
	return true
end

-- Get player profile
function DataService:getProfile(player: Player)
	return profiles[player.UserId]
end

-- Update profile field
function DataService:updateProfile(player: Player, updates: {[string]: any})
	local profile = self:getProfile(player)
	if not profile then
		warn(string.format("Cannot update profile - no profile for %s", player.Name))
		return false
	end
	
	for key, value in pairs(updates) do
		profile[key] = value
	end
	
	return true
end

-- Autosave all players
function DataService:autosaveAll()
	local saveCount = 0
	for userId, profile in pairs(profiles) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			self:saveProfile(player)
			saveCount = saveCount + 1
		end
	end
	
	if saveCount > 0 then
		print(string.format("💾 Autosaved %d player profiles", saveCount))
	end
end

-- Add item to owned items
function DataService:addItem(player: Player, itemId: string)
	local profile = self:getProfile(player)
	if not profile then
		return false
	end
	
	-- Check if already owned
	if Util.contains(profile.ownedItems, itemId) then
		return false  -- Already owned
	end
	
	table.insert(profile.ownedItems, itemId)
	return true
end

-- Check if player owns item
function DataService:ownsItem(player: Player, itemId: string): boolean
	local profile = self:getProfile(player)
	if not profile then
		return false
	end
	
	return Util.contains(profile.ownedItems, itemId)
end

-- Equip item to outfit slot
function DataService:equipItem(player: Player, slot: string, itemId: string?)
	local profile = self:getProfile(player)
	if not profile then
		return false
	end
	
	profile.equippedOutfit[slot] = itemId
	return true
end

-- Get equipped outfit
function DataService:getEquippedOutfit(player: Player)
	local profile = self:getProfile(player)
	if not profile then
		return nil
	end
	
	return profile.equippedOutfit
end

return DataService
