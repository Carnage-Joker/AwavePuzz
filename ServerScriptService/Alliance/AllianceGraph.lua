-- @ScriptType: ModuleScript
-- AllianceGraph.lua
-- Manages undirected alliance edges between players as a graph structure
-- Used for networked alliance pooling system

local Players = game:GetService("Players")

local AllianceGraph = {}
AllianceGraph.__index = AllianceGraph

function AllianceGraph.new()
	local self = setmetatable({}, AllianceGraph)

	-- Store edges as adjacency list: userId -> {allyUserId = true, ...}
	self.edges = {}
	
	-- BUGFIX (MEDIUM): Add mutex for thread safety
	self._edgeMutex = false

	return self
end

-- Add an undirected edge between two players
function AllianceGraph:addEdge(player1, player2)
	if not player1 or not player2 then
		return false
	end

	-- BUGFIX (MEDIUM): Add mutex to prevent race condition on concurrent addEdge calls
	-- NOTE: Lua mutexes are not truly atomic. This assumes single-threaded execution
	-- with potential concurrent calls through yielding. The check-and-set pattern
	-- creates a small race condition window, but is acceptable for this use case.
	if self._edgeMutex then
		return false
	end
	self._edgeMutex = true

	local userId1 = player1.UserId
	local userId2 = player2.UserId

	if userId1 == userId2 then
		self._edgeMutex = false
		return false
	end

	-- Initialize adjacency lists if needed
	if not self.edges[userId1] then
		self.edges[userId1] = {}
	end
	if not self.edges[userId2] then
		self.edges[userId2] = {}
	end

	-- Add undirected edge
	self.edges[userId1][userId2] = true
	self.edges[userId2][userId1] = true

	self._edgeMutex = false
	return true
end

-- Remove an undirected edge between two players
function AllianceGraph:removeEdge(player1, player2)
	if not player1 or not player2 then
		return false
	end

	local userId1 = player1.UserId
	local userId2 = player2.UserId

	if self.edges[userId1] then
		self.edges[userId1][userId2] = nil
	end
	if self.edges[userId2] then
		self.edges[userId2][userId1] = nil
	end

	return true
end

-- Remove all edges connected to a player
function AllianceGraph:removeAllEdges(player)
	if not player then
		return false
	end

	local userId = player.UserId

	-- Remove edges from this player's adjacency list
	if self.edges[userId] then
		-- First remove this player from all allies' adjacency lists
		for allyId in pairs(self.edges[userId]) do
			if self.edges[allyId] then
				self.edges[allyId][userId] = nil
			end
		end

		-- Then clear this player's adjacency list
		self.edges[userId] = {}
	end

	return true
end

-- Get list of direct allies (players with direct edges)
function AllianceGraph:getDirectAllies(player)
	if not player then
		return {}
	end

	local userId = player.UserId
	local allies = {}

	if self.edges[userId] then
		for allyId in pairs(self.edges[userId]) do
			local allyPlayer = Players:GetPlayerByUserId(allyId)
			if allyPlayer then
				table.insert(allies, allyPlayer)
			end
		end
	end

	return allies
end

-- Check if two players have a direct edge
function AllianceGraph:areDirectAllies(player1, player2)
	if not player1 or not player2 then
		return false
	end

	local userId1 = player1.UserId
	local userId2 = player2.UserId

	if not self.edges[userId1] then
		return false
	end

	return self.edges[userId1][userId2] == true
end

-- Get all players in the connected component containing the given player
-- Uses BFS to find all reachable players
function AllianceGraph:getComponent(player)
	if not player then
		return {}
	end

	local userId = player.UserId
	local component = {}
	local visited = {}
	local queue = {userId}

	visited[userId] = true

	while #queue > 0 do
		local currentId = table.remove(queue, 1)
		table.insert(component, currentId)

		-- Add all unvisited neighbors to queue
		if self.edges[currentId] then
			for neighborId in pairs(self.edges[currentId]) do
				if not visited[neighborId] then
					visited[neighborId] = true
					table.insert(queue, neighborId)
				end
			end
		end
	end

	return component
end

-- Clean up a player's data when they leave
function AllianceGraph:cleanupPlayer(player)
	if not player then
		return
	end

	local userId = player.UserId

	-- Remove all edges
	self:removeAllEdges(player)

	-- Clean up the adjacency list
	self.edges[userId] = nil
end

--------------------------------------------------------------------------------
-- Adapter methods for test compatibility
--------------------------------------------------------------------------------

-- Alias for addEdge (test-compatible method name)
function AllianceGraph:addAlliance(playerA, playerB, meta)
	-- meta parameter is optional (timestamp, trust, etc.) - currently not used
	-- but included for future extensibility
	return self:addEdge(playerA, playerB)
end

-- Alias for removeEdge (test-compatible method name)
function AllianceGraph:removeAlliance(playerA, playerB)
	return self:removeEdge(playerA, playerB)
end

-- Alias for getDirectAllies (test-compatible method name)
function AllianceGraph:getAllies(player)
	return self:getDirectAllies(player)
end

-- Alias for areDirectAllies (test-compatible method name)
function AllianceGraph:isAllied(player1, player2)
	return self:areDirectAllies(player1, player2)
end

return AllianceGraph