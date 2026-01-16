-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
-- FunFactService.lua
-- Server-side management of fun facts display
-- Tracks player stats for unlock conditions and serves facts to clients

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local FunFactConfig = require(SharedFolder:WaitForChild("FunFactConfig"))
local RemoteEventUtil = require(SharedFolder:WaitForChild("RemoteEventUtil"))

local FunFactService = {}
FunFactService.__index = FunFactService

function FunFactService.new()
	local self = setmetatable({}, FunFactService)

	-- Track player stats for unlock conditions
	-- Structure: playerStats[userId] = {waveReached, betrayalsCommitted, betrayalsSurvived, cureAttempts, deaths}
	self.playerStats = {}

	-- Track which facts have been shown to each player this session (non-repeating)
	-- Structure: shownFacts[userId] = {factId = true, ...}
	self.shownFacts = {}

	self:setupRemoteEvents()
	self:connectPlayerEvents()

	print("[FunFactService] Initialized with", FunFactConfig.TotalFacts, "total facts")

	return self
end

function FunFactService:setupRemoteEvents()
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"RequestFunFact",    -- Client -> Server: Request a fun fact
		"ShowFunFact",       -- Server -> Client: Display a fun fact
		"UpdateFactStats"    -- Server -> Client: Update unlock stats (optional, for debugging)
	})

	-- Handle fact requests from clients
	self.remoteEvents.RequestFunFact.OnServerEvent:Connect(function(player)
		self:sendRandomFactToPlayer(player)
	end)
end

function FunFactService:connectPlayerEvents()
	-- Initialize stats for new players
	Players.PlayerAdded:Connect(function(player)
		self:initializePlayerStats(player)
	end)

	-- Clean up on player leave
	Players.PlayerRemoving:Connect(function(player)
		local userId = player.UserId
		self.playerStats[userId] = nil
		self.shownFacts[userId] = nil
	end)

	-- Initialize for existing players
	for _, player in ipairs(Players:GetPlayers()) do
		self:initializePlayerStats(player)
	end
end

function FunFactService:initializePlayerStats(player)
	local userId = player.UserId

	self.playerStats[userId] = {
		waveReached = 0,
		betrayalsCommitted = 0,
		betrayalsSurvived = 0,
		cureAttempts = 0,
		deaths = 0
	}

	self.shownFacts[userId] = {}

	print("[FunFactService] Initialized stats for", player.Name)
end

-- Update a specific stat for a player
function FunFactService:updatePlayerStat(player, statName, value)
	if not player then return end

	local userId = player.UserId
	local stats = self.playerStats[userId]

	if not stats then
		self:initializePlayerStats(player)
		stats = self.playerStats[userId]
	end

	if stats[statName] ~= nil then
		stats[statName] = value
		print("[FunFactService]", player.Name, statName, "updated to", value)
	end
end

-- Increment a specific stat for a player
function FunFactService:incrementPlayerStat(player, statName)
	if not player then return end

	local userId = player.UserId
	local stats = self.playerStats[userId]

	if not stats then
		self:initializePlayerStats(player)
		stats = self.playerStats[userId]
	end

	if stats[statName] ~= nil then
		stats[statName] = stats[statName] + 1
		print("[FunFactService]", player.Name, statName, "incremented to", stats[statName])
	end
end

-- Get all unlocked facts for a player
function FunFactService:getUnlockedFactsForPlayer(player)
	local userId = player.UserId
	local stats = self.playerStats[userId]

	if not stats then
		self:initializePlayerStats(player)
		stats = self.playerStats[userId]
	end

	return FunFactConfig.getUnlockedFacts(stats)
end

-- Get a random unlocked fact that hasn't been shown yet
function FunFactService:getRandomUnshownFact(player)
	local userId = player.UserId
	local unlockedFacts = self:getUnlockedFactsForPlayer(player)
	local shownFactsMap = self.shownFacts[userId] or {}

	-- Filter out already shown facts
	local unshownFacts = {}
	for _, fact in ipairs(unlockedFacts) do
		if not shownFactsMap[fact.id] then
			table.insert(unshownFacts, fact)
		end
	end

	-- If all facts have been shown, reset the shown list
	if #unshownFacts == 0 then
		print("[FunFactService] All facts shown to", player.Name, "- resetting pool")
		self.shownFacts[userId] = {}
		unshownFacts = unlockedFacts
	end

	-- Select random fact from unshown pool
	if #unshownFacts > 0 then
		local randomIndex = math.random(1, #unshownFacts)
		local selectedFact = unshownFacts[randomIndex]

		-- Mark as shown
		if not self.shownFacts[userId] then
			self.shownFacts[userId] = {}
		end
		self.shownFacts[userId][selectedFact.id] = true

		return selectedFact
	end

	return nil
end

-- Send a random fact to a player
function FunFactService:sendRandomFactToPlayer(player)
	if not player or not player:IsDescendantOf(game) then
		return
	end

	local fact = self:getRandomUnshownFact(player)

	if fact then
		-- Send to client
		if self.remoteEvents.ShowFunFact then
			self.remoteEvents.ShowFunFact:FireClient(player, {
				text = fact.text,
				category = fact.category,
				id = fact.id
			})
		end

		print("[FunFactService] Sent fact to", player.Name, ":", fact.id)
	else
		warn("[FunFactService] No facts available for", player.Name)
	end
end

-- Broadcast a fact to all players (useful during global events like wave start)
function FunFactService:broadcastFactToAll()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:sendRandomFactToPlayer(player)
		end)
	end
end

-- Reset shown facts for a player (e.g., at start of new round)
function FunFactService:resetShownFactsForPlayer(player)
	local userId = player.UserId
	self.shownFacts[userId] = {}
	print("[FunFactService] Reset shown facts for", player.Name)
end

-- Reset shown facts for all players
function FunFactService:resetShownFactsForAll()
	self.shownFacts = {}
	print("[FunFactService] Reset shown facts for all players")
end

-- Get player stats (for debugging or display)
function FunFactService:getPlayerStats(player)
	local userId = player.UserId
	return self.playerStats[userId]
end

return FunFactService