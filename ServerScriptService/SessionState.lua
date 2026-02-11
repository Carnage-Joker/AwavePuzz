-- @ScriptType: ModuleScript
-- SessionState.lua
-- Single source of truth for player session state (title screen, queue, match membership)
-- Prevents state drift between systems by centralizing all player context tracking

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Server-only validation
if not RunService:IsServer() then
	error("[SessionState] This module can only be required on the server")
end

local SessionState = {}
SessionState.__index = SessionState

-- Singleton instance
local _instance = nil

function SessionState.getInstance()
	if not _instance then
		_instance = SessionState.new()
	end
	return _instance
end

function SessionState.new()
	local self = setmetatable({}, SessionState)
	
	-- userId -> session context
	self._sessions = {}
	
	-- Automatic cleanup on player removal
	Players.PlayerRemoving:Connect(function(player)
		self:onPlayerRemoving(player)
	end)
	
	print("[SessionState] Initialized")
	
	return self
end

--[[
	Initialize a player's session context
	Called when player joins the game
]]
function SessionState:initializePlayer(player)
	if not player or not player.UserId then
		warn("[SessionState] Cannot initialize invalid player")
		return
	end
	
	local userId = player.UserId
	
	-- Don't override existing context if player reconnects
	if self._sessions[userId] then
		print(string.format("[SessionState] Player %s (%d) already has session context", player.Name, userId))
		return
	end
	
	self._sessions[userId] = {
		player = player,
		passedTitle = false,
		inQueue = false,
		portalId = nil,
		inMatch = false,
		matchId = nil,
		isParticipant = false,
		lastUpdate = tick()
	}
	
	print(string.format("[SessionState] Initialized session for %s (%d)", player.Name, userId))
end

--[[
	Get player's current session context
	Returns: { passedTitle, inQueue, portalId, inMatch, matchId, isParticipant }
	Returns nil if player not initialized
]]
function SessionState:getPlayerContext(player)
	if not player or not player.UserId then
		return nil
	end
	
	local context = self._sessions[player.UserId]
	if not context then
		-- Auto-initialize if not present (defensive)
		self:initializePlayer(player)
		context = self._sessions[player.UserId]
	end
	
	return context
end

--[[
	Mark player as having passed the title screen
]]
function SessionState:setPassedTitle(player, passed)
	local context = self:getPlayerContext(player)
	if not context then
		warn(string.format("[SessionState] Cannot set passedTitle for invalid player"))
		return false
	end
	
	context.passedTitle = passed
	context.lastUpdate = tick()
	
	print(string.format("[SessionState] %s passedTitle = %s", player.Name, tostring(passed)))
	return true
end

--[[
	Set player's queue state
	@param portalId - Portal ID if queued, nil if not queued
]]
function SessionState:setQueued(player, portalId)
	local context = self:getPlayerContext(player)
	if not context then
		warn("[SessionState] Cannot set queue state for invalid player")
		return false
	end
	
	context.inQueue = portalId ~= nil
	context.portalId = portalId
	context.lastUpdate = tick()
	
	if portalId then
		print(string.format("[SessionState] %s queued for portal %s", player.Name, portalId))
	else
		print(string.format("[SessionState] %s left queue", player.Name))
	end
	
	return true
end

--[[
	Set player's match state
	@param matchId - Match ID if in match, nil if not in match
	@param participant - Whether player is an active participant (affects game logic)
]]
function SessionState:setMatch(player, matchId, participant)
	local context = self:getPlayerContext(player)
	if not context then
		warn("[SessionState] Cannot set match state for invalid player")
		return false
	end
	
	context.inMatch = matchId ~= nil
	context.matchId = matchId
	context.isParticipant = participant or false
	context.lastUpdate = tick()
	
	if matchId then
		print(string.format("[SessionState] %s in match %s (participant=%s)", 
			player.Name, matchId, tostring(participant)))
	else
		print(string.format("[SessionState] %s left match", player.Name))
	end
	
	return true
end

--[[
	Check if player has passed title screen
]]
function SessionState:hasPassedTitle(player)
	local context = self:getPlayerContext(player)
	return context and context.passedTitle or false
end

--[[
	Check if player is in any queue
]]
function SessionState:isPlayerQueued(player)
	local context = self:getPlayerContext(player)
	return context and context.inQueue or false
end

--[[
	Check if player is in any match
]]
function SessionState:isPlayerInMatch(player)
	local context = self:getPlayerContext(player)
	return context and context.inMatch or false
end

--[[
	Check if player is an active match participant
	(affects game logic like wave rewards, defeat conditions)
]]
function SessionState:isPlayerParticipant(player)
	local context = self:getPlayerContext(player)
	return context and context.isParticipant or false
end

--[[
	Get player's current portal queue (if any)
]]
function SessionState:getPlayerPortal(player)
	local context = self:getPlayerContext(player)
	return context and context.portalId or nil
end

--[[
	Get player's current match ID (if any)
]]
function SessionState:getPlayerMatch(player)
	local context = self:getPlayerContext(player)
	return context and context.matchId or nil
end

--[[
	Cleanup player session on removal
]]
function SessionState:onPlayerRemoving(player)
	if not player or not player.UserId then
		return
	end
	
	local userId = player.UserId
	
	if self._sessions[userId] then
		print(string.format("[SessionState] Cleaning up session for %s (%d)", player.Name, userId))
		self._sessions[userId] = nil
	end
end

--[[
	Get all players in a specific state (for debugging/diagnostics)
]]
function SessionState:getPlayersInState(stateFilter)
	local players = {}
	
	for userId, context in pairs(self._sessions) do
		local matches = true
		
		if stateFilter.passedTitle ~= nil and context.passedTitle ~= stateFilter.passedTitle then
			matches = false
		end
		if stateFilter.inQueue ~= nil and context.inQueue ~= stateFilter.inQueue then
			matches = false
		end
		if stateFilter.inMatch ~= nil and context.inMatch ~= stateFilter.inMatch then
			matches = false
		end
		if stateFilter.isParticipant ~= nil and context.isParticipant ~= stateFilter.isParticipant then
			matches = false
		end
		
		if matches then
			table.insert(players, context.player)
		end
	end
	
	return players
end

--[[
	Get statistics for monitoring
]]
function SessionState:getStats()
	local stats = {
		totalSessions = 0,
		passedTitle = 0,
		inQueue = 0,
		inMatch = 0,
		participants = 0
	}
	
	for _, context in pairs(self._sessions) do
		stats.totalSessions = stats.totalSessions + 1
		if context.passedTitle then stats.passedTitle = stats.passedTitle + 1 end
		if context.inQueue then stats.inQueue = stats.inQueue + 1 end
		if context.inMatch then stats.inMatch = stats.inMatch + 1 end
		if context.isParticipant then stats.participants = stats.participants + 1 end
	end
	
	return stats
end

return SessionState
