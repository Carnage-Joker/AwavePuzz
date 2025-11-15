-- PlayerManager.lua
-- Manages player data, health, and alliances

local GameConfig = require(script.Parent.Parent.shared.GameConfig)

local PlayerManager = {}
PlayerManager.__index = PlayerManager

function PlayerManager.new()
	local self = setmetatable({}, PlayerManager)
	self.players = {} -- player userId -> player data
	self.alliances = {} -- player userId -> table of allied player userIds
	return self
end

function PlayerManager:addPlayer(player)
	if #self:getActivePlayers() >= GameConfig.MAX_PLAYERS then
		return false, "Server is full"
	end
	
	self.players[player.UserId] = {
		player = player,
		health = GameConfig.STARTING_HEALTH,
		isAlive = true,
		cureComponents = {},
		lastBetrayalTime = 0
	}
	
	self.alliances[player.UserId] = {}
	
	return true, "Player added successfully"
end

function PlayerManager:removePlayer(player)
	self.players[player.UserId] = nil
	self.alliances[player.UserId] = nil
end

function PlayerManager:getPlayerData(player)
	return self.players[player.UserId]
end

function PlayerManager:damagePlayer(player, damage)
	local playerData = self.players[player.UserId]
	if not playerData or not playerData.isAlive then
		return false
	end
	
	playerData.health = math.max(0, playerData.health - damage)
	
	if playerData.health <= 0 then
		playerData.isAlive = false
		return true -- Player died
	end
	
	return false
end

function PlayerManager:healPlayer(player, amount)
	local playerData = self.players[player.UserId]
	if not playerData or not playerData.isAlive then
		return false
	end
	
	playerData.health = math.min(GameConfig.STARTING_HEALTH, playerData.health + amount)
	return true
end

function PlayerManager:getActivePlayers()
	local active = {}
	for _, playerData in pairs(self.players) do
		if playerData.isAlive then
			table.insert(active, playerData.player)
		end
	end
	return active
end

function PlayerManager:getAllPlayers()
	local all = {}
	for _, playerData in pairs(self.players) do
		table.insert(all, playerData.player)
	end
	return all
end

function PlayerManager:addAlliance(player1, player2)
	local userId1 = player1.UserId
	local userId2 = player2.UserId
	
	if not self.alliances[userId1] then
		self.alliances[userId1] = {}
	end
	if not self.alliances[userId2] then
		self.alliances[userId2] = {}
	end
	
	table.insert(self.alliances[userId1], userId2)
	table.insert(self.alliances[userId2], userId1)
	
	return true
end

function PlayerManager:removeAlliance(player1, player2)
	local userId1 = player1.UserId
	local userId2 = player2.UserId
	
	-- Remove player2 from player1's alliance list
	if self.alliances[userId1] then
		for i, allyId in ipairs(self.alliances[userId1]) do
			if allyId == userId2 then
				table.remove(self.alliances[userId1], i)
				break
			end
		end
	end
	
	-- Remove player1 from player2's alliance list
	if self.alliances[userId2] then
		for i, allyId in ipairs(self.alliances[userId2]) do
			if allyId == userId1 then
				table.remove(self.alliances[userId2], i)
				break
			end
		end
	end
	
	return true
end

function PlayerManager:areAllied(player1, player2)
	local userId1 = player1.UserId
	local userId2 = player2.UserId
	
	if not self.alliances[userId1] then
		return false
	end
	
	for _, allyId in ipairs(self.alliances[userId1]) do
		if allyId == userId2 then
			return true
		end
	end
	
	return false
end

function PlayerManager:addCureComponent(player, componentName)
	local playerData = self.players[player.UserId]
	if not playerData then
		return false
	end
	
	if not playerData.cureComponents[componentName] then
		playerData.cureComponents[componentName] = 0
	end
	
	playerData.cureComponents[componentName] = playerData.cureComponents[componentName] + 1
	return true
end

function PlayerManager:getCureComponents(player)
	local playerData = self.players[player.UserId]
	if not playerData then
		return {}
	end
	
	return playerData.cureComponents
end

return PlayerManager
