-- BaseManager.lua
-- Manages shared base health for the entire game
-- Features live updates broadcast to clients on damage
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local BaseManager = {}
BaseManager.__index = BaseManager

-- Singleton instance
local _instance = nil

-----------------------------------------------------
-- Constructor
-----------------------------------------------------
function BaseManager.new()
	local self = setmetatable({}, BaseManager)

	self.maxHealth = GameConfig.BASE_HEALTH
	self.health = GameConfig.BASE_HEALTH
	self.isDestroyed = false

	return self
end

-----------------------------------------------------
-- Singleton accessor
-----------------------------------------------------
function BaseManager.getInstance()
	if not _instance then
		_instance = BaseManager.new()
	end
	return _instance
end

-----------------------------------------------------
-- Live update broadcast
-----------------------------------------------------
function BaseManager:broadcastHealthUpdate()
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local baseHealthEvent = remoteEvents:FindFirstChild("BaseHealthUpdate")
		if baseHealthEvent then
			baseHealthEvent:FireAllClients(self.health, self.maxHealth)
		end
	end
end

-----------------------------------------------------
-- Damage & Repair
-----------------------------------------------------
function BaseManager:damageBase(damage)
	if self.isDestroyed then
		return false
	end

	self.health = math.max(0, self.health - damage)
	
	-- Broadcast live update to all clients
	self:broadcastHealthUpdate()

	if self.health <= 0 then
		self.isDestroyed = true
		return true -- Base destroyed
	end

	return false
end

function BaseManager:repairBase(amount)
	if self.isDestroyed then
		return false
	end

	self.health = math.min(self.maxHealth, self.health + amount)
	
	-- Broadcast live update to all clients
	self:broadcastHealthUpdate()
	
	return true
end

-----------------------------------------------------
-- Getters
-----------------------------------------------------
function BaseManager:getHealth()
	return self.health
end

function BaseManager:getHealthPercentage()
	return (self.health / self.maxHealth) * 100
end

function BaseManager:isBaseDestroyed()
	return self.isDestroyed
end

-----------------------------------------------------
-- Reset (for restarting game)
-----------------------------------------------------
function BaseManager:reset()
	self.health = self.maxHealth
	self.isDestroyed = false
	
	-- Broadcast reset health to all clients
	self:broadcastHealthUpdate()
end

return BaseManager
