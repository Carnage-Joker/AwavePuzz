-- LobbyManager.lua
-- Manages the pre-round lobby where players vote on maps
-- Handles the game flow: Lobby (voting) → Round → Scoreboard → Lobby

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local MapConfig = require(SharedFolder:WaitForChild("MapConfig"))
local RemoteEventUtil = require(SharedFolder:WaitForChild("RemoteEventUtil"))

local LobbyManager = {}
LobbyManager.__index = LobbyManager

function LobbyManager.new()
	local self = setmetatable({}, LobbyManager)

	-- Voting state
	self.votes = {} -- mapId -> { playerIds }
	self.votingActive = false
	self.votingTimer = 0
	self.currentMapId = nil

	-- Ready/Waiting state
	self.playersReady = {} -- userId -> boolean (true if ready to start)
	self.playersWaiting = {} -- userId -> boolean (true if waiting for friends)
	self.extendedTimer = false -- Whether timer has been extended

	-- References set later
	self.mapManager = nil
	self.gameManager = nil

	-- Remote events
	self.remoteEvents = {}
	self:setupRemoteEvents()

	return self
end

function LobbyManager:setupRemoteEvents()
	-- Use shared utility to create remote events
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"MapVoteStart",    -- Server -> Client: Voting has started, send map options
		"MapVoteUpdate",   -- Server -> Client: Update vote counts
		"MapVoteEnd",      -- Server -> Client: Voting ended, show selected map
		"CastMapVote",     -- Client -> Server: Player casts a vote
		"LobbyStateUpdate", -- Server -> Client: Update lobby state (timer, etc.)
		"PlayerReady",     -- Client -> Server: Player marks ready
		"PlayerWaiting",   -- Client -> Server: Player is waiting for friends
		"SwitchServer",    -- Client -> Server: Player wants to switch servers
		"LobbyPlayersUpdate" -- Server -> Client: Update player ready/waiting status
	})

	-- Listen for player votes
	self.remoteEvents.CastMapVote.OnServerEvent:Connect(function(player, mapId)
		-- Validate mapId: must be a string and exist in MapConfig.Maps
		if not mapId or type(mapId) ~= "string" or not MapConfig.Maps[mapId] then
			return
		end
		self:handlePlayerVote(player, mapId)
	end)
	
	-- Listen for player ready status
	self.remoteEvents.PlayerReady.OnServerEvent:Connect(function(player)
		self:handlePlayerReady(player)
	end)
	
	-- Listen for player waiting status
	self.remoteEvents.PlayerWaiting.OnServerEvent:Connect(function(player, isWaiting)
		self:handlePlayerWaiting(player, isWaiting)
	end)
	
	-- Listen for server switch requests
	self.remoteEvents.SwitchServer.OnServerEvent:Connect(function(player)
		self:handleServerSwitch(player)
	end)
end

function LobbyManager:setMapManager(mapManager)
	self.mapManager = mapManager
end

function LobbyManager:setGameManager(gameManager)
	self.gameManager = gameManager
end

-- Get available maps for voting
function LobbyManager:getMapOptions()
	local ServerStorage = game:GetService("ServerStorage")
	local mapsFolder = ServerStorage:FindFirstChild("Maps")
	
	local options = {}
	for mapId, mapData in pairs(MapConfig.Maps) do
		-- Only include maps that have models in ServerStorage.Maps
		if mapsFolder then
			local mapModel = mapsFolder:FindFirstChild(mapData.Model)
			if mapModel then
				table.insert(options, {
					id = mapId,
					name = mapData.Name,
					description = mapData.Description or ""
				})
			else
				warn(string.format("[LobbyManager] Skipping map '%s' - model '%s' not found in ServerStorage.Maps", mapId, mapData.Model))
			end
		else
			warn("[LobbyManager] Maps folder not found in ServerStorage, cannot validate map availability")
		end
	end
	
	-- If no maps are available, log error
	if #options == 0 then
		warn("[LobbyManager] No valid maps found for voting!")
	end
	
	return options
end

-- Start the voting phase
function LobbyManager:startVoting()
	if self.votingActive then
		return false
	end

	-- Get map options (filtered for available models)
	local mapOptions = self:getMapOptions()
	
	if #mapOptions == 0 then
		warn("[LobbyManager] Cannot start voting - no valid maps available")
		return false
	end

	-- Reset votes (only for available maps)
	self.votes = {}
	for _, mapOption in ipairs(mapOptions) do
		self.votes[mapOption.id] = {}
	end

	self.votingActive = true
	self.votingTimer = GameConfig.LOBBY_VOTING_TIME
	self.extendedTimer = false -- Reset extended flag

	-- Notify all clients that voting has started
	if self.remoteEvents.MapVoteStart then
		self.remoteEvents.MapVoteStart:FireAllClients({
			maps = mapOptions,
			duration = GameConfig.LOBBY_VOTING_TIME
		})
	end
	
	-- Broadcast initial player status
	self:broadcastPlayerStatus()

	print(string.format("[LobbyManager] Map voting started with %d available maps", #mapOptions))
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

	-- Only maps with actual votes are included in tiedMaps.
	-- If no votes are cast (maxVotes == 0), tiedMaps will be empty,
	-- and the fallback to MapConfig.getRandom() below will select a random map.
	for mapId, voterList in pairs(self.votes) do
		local voteCount = #voterList
		if voteCount > maxVotes then
			maxVotes = voteCount
			tiedMaps = { mapId }
		elseif voteCount == maxVotes and voteCount > 0 then
			-- Only include maps with actual votes in tie-breaking
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

	-- Track previous second before updating timer
	local lastSecond = math.floor(self.votingTimer)
	self.votingTimer = self.votingTimer - deltaTime
	local currentSecond = math.floor(self.votingTimer)

	-- Broadcast timer updates when the second changes
	if lastSecond ~= currentSecond then
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
	self.playersReady = {}
	self.playersWaiting = {}
	self.extendedTimer = false
end

-- Handle player marking themselves as ready
function LobbyManager:handlePlayerReady(player)
	if not player then return end
	
	self.playersReady[player.UserId] = true
	self.playersWaiting[player.UserId] = false -- Can't be ready and waiting
	
	print(string.format("[LobbyManager] Player %s is ready", player.Name))
	self:broadcastPlayerStatus()
end

-- Handle player waiting for friends/others
function LobbyManager:handlePlayerWaiting(player, isWaiting)
	if not player then return end
	
	self.playersWaiting[player.UserId] = isWaiting
	if isWaiting then
		self.playersReady[player.UserId] = false -- Can't be waiting and ready
		
		-- Extend timer if not already extended and voting is active
		if not self.extendedTimer and self.votingActive then
			self.votingTimer = math.max(self.votingTimer, GameConfig.LOBBY_VOTING_TIME)
			self.extendedTimer = true
			print(string.format("[LobbyManager] Timer extended due to %s waiting for friends", player.Name))
		end
	end
	
	print(string.format("[LobbyManager] Player %s waiting status: %s", player.Name, tostring(isWaiting)))
	self:broadcastPlayerStatus()
end

-- Handle server switch request
function LobbyManager:handleServerSwitch(player)
	if not player then return end
	
	local TeleportService = game:GetService("TeleportService")
	local placeId = game.PlaceId
	
	print(string.format("[LobbyManager] Player %s requesting server switch", player.Name))
	
	-- Teleport player to a different server
	local success, errorMessage = pcall(function()
		TeleportService:Teleport(placeId, player)
	end)
	
	if not success then
		warn(string.format("[LobbyManager] Failed to teleport %s: %s", player.Name, tostring(errorMessage)))
	end
end

-- Broadcast player ready/waiting status to all clients
function LobbyManager:broadcastPlayerStatus()
	local Players = game:GetService("Players")
	local statusData = {
		totalPlayers = #Players:GetPlayers(),
		readyPlayers = 0,
		waitingPlayers = 0,
		players = {}
	}
	
	for _, player in ipairs(Players:GetPlayers()) do
		local isReady = self.playersReady[player.UserId] or false
		local isWaiting = self.playersWaiting[player.UserId] or false
		
		if isReady then
			statusData.readyPlayers = statusData.readyPlayers + 1
		end
		if isWaiting then
			statusData.waitingPlayers = statusData.waitingPlayers + 1
		end
		
		table.insert(statusData.players, {
			name = player.Name,
			userId = player.UserId,
			ready = isReady,
			waiting = isWaiting
		})
	end
	
	if self.remoteEvents.LobbyPlayersUpdate then
		self.remoteEvents.LobbyPlayersUpdate:FireAllClients(statusData)
	end
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
