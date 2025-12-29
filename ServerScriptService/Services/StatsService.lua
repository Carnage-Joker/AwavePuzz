--[[
	StatsService.lua
	Manages player stats (Grace, Elegance, Confidence, Care)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)

local StatsService = {}
StatsService.__index = StatsService

-- Reference to DataService (set during initialization)
local DataService = nil

function StatsService.new()
	local self = setmetatable({}, StatsService)
	self.initialized = false
	return self
end

function StatsService:initialize(dataService)
	print("📈 StatsService initializing...")
	
	DataService = dataService
	self.initialized = true
	
	print("✅ StatsService initialized")
	return true
end

-- Get player stats
function StatsService:getStats(player: Player)
	if not DataService then
		warn("DataService not initialized")
		return nil
	end
	
	local profile = DataService:getProfile(player)
	if not profile then
		return nil
	end
	
	return profile.stats
end

-- Add to a stat
function StatsService:add(player: Player, statName: string, amount: number)
	if not DataService then
		warn("DataService not initialized")
		return false
	end
	
	local profile = DataService:getProfile(player)
	if not profile then
		warn(string.format("No profile for player %s", player.Name))
		return false
	end
	
	if not profile.stats[statName] then
		warn(string.format("Invalid stat name: %s", statName))
		return false
	end
	
	-- Add to stat
	profile.stats[statName] = profile.stats[statName] + amount
	
	-- Sync to client
	self:syncStats(player)
	
	print(string.format("%s gained +%d %s (Total: %d)", player.Name, amount, statName, profile.stats[statName]))
	return true
end

-- Set stat to specific value
function StatsService:set(player: Player, statName: string, value: number)
	if not DataService then
		warn("DataService not initialized")
		return false
	end
	
	local profile = DataService:getProfile(player)
	if not profile then
		return false
	end
	
	if not profile.stats[statName] then
		warn(string.format("Invalid stat name: %s", statName))
		return false
	end
	
	profile.stats[statName] = value
	self:syncStats(player)
	return true
end

-- Sync stats to client
function StatsService:syncStats(player: Player)
	local stats = self:getStats(player)
	if stats then
		local syncEvent = Remotes.getEvent("SyncStats")
		syncEvent:FireClient(player, stats)
	end
end

return StatsService
