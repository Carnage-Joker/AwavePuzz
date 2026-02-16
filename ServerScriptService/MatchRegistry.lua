-- @ScriptType: ModuleScript
-- MatchRegistry.lua
-- Tracks active match instances and player membership
-- Ensures proper cleanup and prevents player duplication across matches

local MatchRegistry = {}
MatchRegistry.__index = MatchRegistry

-- Match-specific states (independent of global GameManager state)
-- Note: These state names intentionally match GameManager.States for compatibility
-- Alternative: Could import from shared constants module, but this keeps MatchRegistry independent
MatchRegistry.MatchStates = {
	COUNTDOWN = "Countdown",
	WAVE_ACTIVE = "WaveActive",
	INTERMISSION = "Intermission",
	VICTORY = "Victory",
	DEFEAT = "Defeat"
}

function MatchRegistry.new()
	local self = setmetatable({}, MatchRegistry)
	
	-- matchId -> { players = {}, mapId = "", startTime = tick(), active = bool, state = string }
	self.activeMatches = {}
	
	-- userId -> matchId (quick lookup)
	self.playerToMatch = {}
	
	-- Counter for generating unique match IDs
	self.matchIdCounter = 0
	
	return self
end

-- Generate a unique match ID
function MatchRegistry:generateMatchId()
	self.matchIdCounter = self.matchIdCounter + 1
	return "Match_" .. tostring(self.matchIdCounter) .. "_" .. tostring(tick())
end

-- Create a new match and register players
function MatchRegistry:createMatch(players, mapId)
	if not players or #players == 0 then
		warn("[MatchRegistry] Cannot create match with no players")
		return nil
	end
	
	if not mapId then
		warn("[MatchRegistry] Cannot create match without mapId")
		return nil
	end
	
	local matchId = self:generateMatchId()
	
	-- Create match record with initial Countdown state
	self.activeMatches[matchId] = {
		players = {},
		mapId = mapId,
		startTime = tick(),
		active = true,
		state = MatchRegistry.MatchStates.COUNTDOWN
	}
	
	-- Register each player
	for _, player in ipairs(players) do
		if player and player.UserId then
			-- Remove from any existing match first
			self:removePlayerFromMatch(player)
			
			-- Add to new match
			table.insert(self.activeMatches[matchId].players, player)
			self.playerToMatch[player.UserId] = matchId
			
			print(string.format("[MatchRegistry] Player %s registered to match %s", player.Name, matchId))
		end
	end
	
	print(string.format("[MatchRegistry] Created match %s with %d players on map %s", 
		matchId, #self.activeMatches[matchId].players, mapId))
	
	return matchId
end

-- Get match ID for a player
function MatchRegistry:getPlayerMatch(player)
	if not player or not player.UserId then return nil end
	return self.playerToMatch[player.UserId]
end

-- Get match data
function MatchRegistry:getMatch(matchId)
	return self.activeMatches[matchId]
end

-- Get the current state of a match
function MatchRegistry:getMatchState(matchId)
	local match = self.activeMatches[matchId]
	if not match or not match.active then
		return nil
	end
	return match.state
end

-- Set the state of a match
function MatchRegistry:setMatchState(matchId, state)
	local match = self.activeMatches[matchId]
	if not match then
		warn(string.format("[MatchRegistry] Cannot set state for non-existent match %s", tostring(matchId)))
		return false
	end
	
	if not match.active then
		warn(string.format("[MatchRegistry] Cannot set state for inactive match %s", tostring(matchId)))
		return false
	end
	
	-- Validate state
	local validState = false
	for _, validStateValue in pairs(MatchRegistry.MatchStates) do
		if state == validStateValue then
			validState = true
			break
		end
	end
	
	if not validState then
		warn(string.format("[MatchRegistry] Invalid match state '%s' for match %s", tostring(state), matchId))
		return false
	end
	
	local oldState = match.state
	match.state = state
	print(string.format("[MatchRegistry] Match %s state: %s → %s", matchId, tostring(oldState), state))
	return true
end

-- Check if a player is in any match
function MatchRegistry:isPlayerInMatch(player)
	if not player or not player.UserId then return false end
	return self.playerToMatch[player.UserId] ~= nil
end

-- Remove a player from their current match
function MatchRegistry:removePlayerFromMatch(player)
	if not player or not player.UserId then return end
	
	local matchId = self.playerToMatch[player.UserId]
	if not matchId then return end
	
	local match = self.activeMatches[matchId]
	if match then
		-- Remove from players list
		for i, p in ipairs(match.players) do
			if p.UserId == player.UserId then
				table.remove(match.players, i)
				print(string.format("[MatchRegistry] Removed player %s from match %s", player.Name, matchId))
				break
			end
		end
		
		-- If match is now empty, mark for cleanup
		if #match.players == 0 then
			match.active = false
			print(string.format("[MatchRegistry] Match %s is now empty and marked inactive", matchId))
		end
	end
	
	-- Remove player mapping
	self.playerToMatch[player.UserId] = nil
end

-- End a match and cleanup
function MatchRegistry:endMatch(matchId)
	local match = self.activeMatches[matchId]
	if not match then 
		warn(string.format("[MatchRegistry] Attempted to end non-existent match %s", tostring(matchId)))
		return 
	end
	
	print(string.format("[MatchRegistry] Ending match %s", matchId))
	
	-- Remove all player mappings
	for _, player in ipairs(match.players) do
		if player and player.UserId then
			self.playerToMatch[player.UserId] = nil
		end
	end
	
	-- Mark inactive
	match.active = false
	match.players = {}
end

-- Get all players in a match
function MatchRegistry:getMatchPlayers(matchId)
	local match = self.activeMatches[matchId]
	if not match then return {} end
	return match.players
end

-- Get all active matches
function MatchRegistry:getActiveMatches()
	local matches = {}
	for matchId, match in pairs(self.activeMatches) do
		if match.active then
			table.insert(matches, {
				id = matchId,
				playerCount = #match.players,
				mapId = match.mapId,
				startTime = match.startTime
			})
		end
	end
	return matches
end

-- Cleanup inactive matches (call periodically)
function MatchRegistry:cleanupInactiveMatches()
	local removed = 0
	for matchId, match in pairs(self.activeMatches) do
		if not match.active then
			self.activeMatches[matchId] = nil
			removed = removed + 1
		end
	end
	
	if removed > 0 then
		print(string.format("[MatchRegistry] Cleaned up %d inactive matches", removed))
	end
	
	return removed
end

-- Get statistics
function MatchRegistry:getStats()
	local activeCount = 0
	local totalPlayers = 0
	
	for _, match in pairs(self.activeMatches) do
		if match.active then
			activeCount = activeCount + 1
			totalPlayers = totalPlayers + #match.players
		end
	end
	
	return {
		activeMatches = activeCount,
		totalPlayers = totalPlayers,
		totalMatchesCreated = self.matchIdCounter
	}
end

return MatchRegistry
