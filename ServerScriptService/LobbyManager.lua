-- @ScriptType: ModuleScript
-- LobbyManager.lua
-- Server-authoritative map voting.
-- API used by GameManager:
-- - startVoting()
-- - update(dt)
-- - reset()
-- - onPlayerLeave(player)
-- - isVotingActive()
-- - getSelectedMapId()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
if not Shared then
	error("[LobbyManager] CRITICAL: Failed to load Shared folder after 10 seconds")
end

local MapConfig = Shared:WaitForChild("MapConfig", 5)
if not MapConfig then
	error("[LobbyManager] CRITICAL: Failed to load MapConfig after 5 seconds")
end
MapConfig = require(MapConfig)

local GameConfig = Shared:WaitForChild("GameConfig", 5)
if not GameConfig then
	error("[LobbyManager] CRITICAL: Failed to load GameConfig after 5 seconds")
end
GameConfig = require(GameConfig)

local LobbyManager = {}
LobbyManager.__index = LobbyManager

local function getRemoteEventsFolder()
	local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "RemoteEvents"
		folder.Parent = ReplicatedStorage
	end
	return folder
end

local function getOrCreateRemote(name)
	local folder = getRemoteEventsFolder()
	local evt = folder:FindFirstChild(name)
	if not evt then
		evt = Instance.new("RemoteEvent")
		evt.Name = name
		evt.Parent = folder
	end
	return evt
end

function LobbyManager.new()
	local self = setmetatable({}, LobbyManager)

	self.mapManager = nil
	self.gameManager = nil

	self.votingActive = false
	self.voteTimeRemaining = 0
	self.availableMaps = {}
	self.votes = {} -- userId -> mapId
	self.selectedMapId = nil

	-- Remotes (non-breaking: if your UI already uses different ones, this won’t crash)
	self.remoteEvents = {
		MapVotingState = getOrCreateRemote("MapVotingState"),   -- start/stop payload
		MapVoteCast = getOrCreateRemote("MapVoteCast"),         -- client -> server (mapId)
		MapVotingUpdate = getOrCreateRemote("MapVotingUpdate"), -- server -> clients (counts/time)
	}

	-- Hook vote casting
	self.remoteEvents.MapVoteCast.OnServerEvent:Connect(function(player, mapId)
		self:castVote(player, mapId)
	end)

	return self
end

function LobbyManager:setMapManager(mapManager)
	self.mapManager = mapManager
end

function LobbyManager:setGameManager(gameManager)
	self.gameManager = gameManager
end

function LobbyManager:reset()
	self.votingActive = false
	self.voteTimeRemaining = 0
	self.availableMaps = {}
	self.votes = {}
	self.selectedMapId = nil
end

function LobbyManager:onPlayerLeave(player)
	if not player then return end
	self.votes[player.UserId] = nil
end

function LobbyManager:isVotingActive()
	return self.votingActive
end

function LobbyManager:getSelectedMapId()
	return self.selectedMapId
end

function LobbyManager:_buildAvailableMaps()
	local list = {}
	for id, data in pairs(MapConfig.Maps) do
		table.insert(list, {
			id = id,
			name = data.Name or id,
			description = data.Description or "",
		})
	end

	-- stable order for UI
	table.sort(list, function(a, b)
		return tostring(a.name) < tostring(b.name)
	end)

	return list
end

function LobbyManager:_countVotes()
	local counts = {}
	for _, map in ipairs(self.availableMaps) do
		counts[map.id] = 0
	end
	for _, mapId in pairs(self.votes) do
		if counts[mapId] ~= nil then
			counts[mapId] += 1
		end
	end
	return counts
end

function LobbyManager:_chooseWinner(counts)
	-- Winner = highest votes; tie-break = default map; else alphabetical
	local bestId, bestCount = nil, -1

	for mapId, c in pairs(counts) do
		if c > bestCount then
			bestCount = c
			bestId = mapId
		elseif c == bestCount and bestId then
			-- tie-break: prefer default
			local defaultId = select(1, MapConfig.getDefault())
			if mapId == defaultId then
				bestId = mapId
			elseif bestId ~= defaultId then
				-- stable tie-break by string id
				if tostring(mapId) < tostring(bestId) then
					bestId = mapId
				end
			end
		end
	end

	-- If no votes or no maps, fallback default
	if not bestId then
		bestId = select(1, MapConfig.getDefault())
	end

	return bestId
end

function LobbyManager:startVoting()
	self:reset()

	self.votingActive = true
	self.voteTimeRemaining = GameConfig.LOBBY_VOTING_TIME or 20
	self.availableMaps = self:_buildAvailableMaps()

	print(string.format("[LobbyManager] Map voting started with %d available maps", #self.availableMaps))

	-- Broadcast start state
	self.remoteEvents.MapVotingState:FireAllClients({
		active = true,
		timeRemaining = math.ceil(self.voteTimeRemaining),
		maps = self.availableMaps,
		votes = self:_countVotes(),
	})

	-- Auto-cast current players to default (optional, prevents empty)
	local defaultId = select(1, MapConfig.getDefault())
	for _, p in ipairs(Players:GetPlayers()) do
		if not self.votes[p.UserId] then
			self.votes[p.UserId] = defaultId
		end
	end

	-- initial update push
	self.remoteEvents.MapVotingUpdate:FireAllClients({
		timeRemaining = math.ceil(self.voteTimeRemaining),
		votes = self:_countVotes(),
	})
end

function LobbyManager:castVote(player, mapId)
	if not self.votingActive then return end
	if not player or typeof(mapId) ~= "string" then return end

	-- validate mapId exists
	if not MapConfig.get(mapId) then
		return
	end

	self.votes[player.UserId] = mapId

	self.remoteEvents.MapVotingUpdate:FireAllClients({
		timeRemaining = math.ceil(self.voteTimeRemaining),
		votes = self:_countVotes(),
	})
end

function LobbyManager:update(dt)
	if not self.votingActive then return end

	self.voteTimeRemaining -= dt
	if self.voteTimeRemaining < 0 then
		self.voteTimeRemaining = 0
	end

	-- push updates ~1/sec (cheap)
	-- If you want tighter, remove this throttle.
	self._acc = (self._acc or 0) + dt
	if self._acc >= 1 then
		self._acc = 0
		self.remoteEvents.MapVotingUpdate:FireAllClients({
			timeRemaining = math.ceil(self.voteTimeRemaining),
			votes = self:_countVotes(),
		})
	end

	if self.voteTimeRemaining <= 0 then
		-- finalize
		self.votingActive = false
		local counts = self:_countVotes()
		self.selectedMapId = self:_chooseWinner(counts)

		print(string.format("[LobbyManager] Voting ended. Selected map: %s", tostring(self.selectedMapId)))

		self.remoteEvents.MapVotingState:FireAllClients({
			active = false,
			timeRemaining = 0,
			selectedMapId = self.selectedMapId,
			votes = counts,
		})
	end
end

return LobbyManager
