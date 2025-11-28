-- LobbyManager.lua
-- Manages the pre-round lobby where players vote on maps
-- Handles the game flow: Lobby (voting) → Round → Scoreboard → Lobby

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local MapConfig = require(SharedFolder:WaitForChild("MapConfig"))

local LobbyManager = {}
LobbyManager.__index = LobbyManager

function LobbyManager.new()
	local self = setmetatable({}, LobbyManager)

	-- Voting state
	self.votes = {} -- mapId -> { playerIds }
	self.votingActive = false
	self.votingTimer = 0
	self.currentMapId = nil

	-- References set later
	self.mapManager = nil
	self.gameManager = nil

	-- Remote events
	self.remoteEvents = {}
	self:setupRemoteEvents()

	return self
end

function LobbyManager:setupRemoteEvents()
	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEventsFolder then
		remoteEventsFolder = Instance.new("Folder")
		remoteEventsFolder.Name = "RemoteEvents"
		remoteEventsFolder.Parent = ReplicatedStorage
	end

	local eventNames = {
		"MapVoteStart",    -- Server -> Client: Voting has started, send map options
		"MapVoteUpdate",   -- Server -> Client: Update vote counts
		"MapVoteEnd",      -- Server -> Client: Voting ended, show selected map
		"CastMapVote",     -- Client -> Server: Player casts a vote
		"LobbyStateUpdate" -- Server -> Client: Update lobby state (timer, etc.)
	}

	for _, eventName in ipairs(eventNames) do
		local event = remoteEventsFolder:FindFirstChild(eventName)
		if not event then
			event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = remoteEventsFolder
		end
		self.remoteEvents[eventName] = event
	end

	-- Listen for player votes
	if self.remoteEvents.CastMapVote then
		self.remoteEvents.CastMapVote.OnServerEvent:Connect(function(player, mapId)
			-- Validate mapId: must be a string and exist in MapConfig.Maps
			if not mapId or type(mapId) ~= "string" or not MapConfig.Maps[mapId] then
				return
			end
			self:handlePlayerVote(player, mapId)
		end)
	end
end

function LobbyManager:setMapManager(mapManager)
	self.mapManager = mapManager
end

function LobbyManager:setGameManager(gameManager)
	self.gameManager = gameManager
end

-- Get available maps for voting
function LobbyManager:getMapOptions()
	local options = {}
	for mapId, mapData in pairs(MapConfig.Maps) do
		table.insert(options, {
			id = mapId,
			name = mapData.Name,
			description = mapData.Description or ""
		})
	end
	return options
end

-- Start the voting phase
function LobbyManager:startVoting()
	if self.votingActive then
		return false
	end

	-- Reset votes
	self.votes = {}
	for mapId in pairs(MapConfig.Maps) do
		self.votes[mapId] = {}
	end

	self.votingActive = true
	self.votingTimer = GameConfig.LOBBY_VOTING_TIME

	-- Get map options
	local mapOptions = self:getMapOptions()

	-- Notify all clients that voting has started
	if self.remoteEvents.MapVoteStart then
		self.remoteEvents.MapVoteStart:FireAllClients({
			maps = mapOptions,
			duration = GameConfig.LOBBY_VOTING_TIME
		})
	end

	print("[LobbyManager] Map voting started")
	return true
end

-- Handle a player's vote
function LobbyManager:handlePlayerVote(player, mapId)
	if not self.votingActive then
		return
	end

	if not mapId or not MapConfig.Maps[mapId] then
		return
	end

	-- Remove player's previous vote from all maps
	for _, voterList in pairs(self.votes) do
		for i, voterId in ipairs(voterList) do
			if voterId == player.UserId then
				table.remove(voterList, i)
				break
			end
		end
	end

	-- Add vote to selected map
	if self.votes[mapId] then
		table.insert(self.votes[mapId], player.UserId)
	end

	-- Broadcast updated vote counts
	self:broadcastVoteCounts()
end

-- Broadcast current vote counts to all clients
function LobbyManager:broadcastVoteCounts()
	local voteCounts = {}
	for mapId, voterList in pairs(self.votes) do
		voteCounts[mapId] = #voterList
	end

	if self.remoteEvents.MapVoteUpdate then
		self.remoteEvents.MapVoteUpdate:FireAllClients({
			votes = voteCounts,
			timeRemaining = math.floor(self.votingTimer)
		})
	end
end

-- End voting and select the winning map
function LobbyManager:endVoting()
	if not self.votingActive then
		return nil
	end

	self.votingActive = false

	-- Count votes and find winner(s) - handle ties
	local winningMapId = nil
	local maxVotes = 0
	local tiedMaps = {}

	for mapId, voterList in pairs(self.votes) do
		local voteCount = #voterList
		if voteCount > maxVotes then
			maxVotes = voteCount
			tiedMaps = { mapId }
		elseif voteCount == maxVotes and voteCount > 0 then
			table.insert(tiedMaps, mapId)
		end
	end

	-- If there are tied maps or no votes, pick randomly from tied or all maps
	if #tiedMaps > 1 then
		-- Random selection among tied maps
		winningMapId = tiedMaps[math.random(1, #tiedMaps)]
	elseif #tiedMaps == 1 then
		winningMapId = tiedMaps[1]
	else
		-- No votes at all, pick a random map
		winningMapId = MapConfig.getRandom()
	end

	self.currentMapId = winningMapId

	-- Notify clients
	local mapData = MapConfig.get(winningMapId)
	if self.remoteEvents.MapVoteEnd then
		self.remoteEvents.MapVoteEnd:FireAllClients({
			selectedMapId = winningMapId,
			mapName = mapData and mapData.Name or "Unknown"
		})
	end

	print("[LobbyManager] Voting ended. Selected map: " .. tostring(winningMapId))
	return winningMapId
end

-- Update the lobby state (called from game loop)
function LobbyManager:update(deltaTime)
	if not self.votingActive then
		return
	end

	self.votingTimer = self.votingTimer - deltaTime

	-- Broadcast timer updates periodically (every second)
	if math.floor(self.votingTimer) ~= math.floor(self.votingTimer + deltaTime) then
		self:broadcastVoteCounts()
	end

	if self.votingTimer <= 0 then
		self:endVoting()
	end
end

-- Get the selected map ID after voting
function LobbyManager:getSelectedMapId()
	return self.currentMapId
end

-- Check if voting is currently active
function LobbyManager:isVotingActive()
	return self.votingActive
end

-- Reset for a new round
function LobbyManager:reset()
	self.votes = {}
	self.votingActive = false
	self.votingTimer = 0
end

-- Remove a player's vote when they leave
function LobbyManager:onPlayerLeave(player)
	for _, voterList in pairs(self.votes) do
		for i, voterId in ipairs(voterList) do
			if voterId == player.UserId then
				table.remove(voterList, i)
				break
			end
		end
	end

	if self.votingActive then
		self:broadcastVoteCounts()
	end
end

return LobbyManager
