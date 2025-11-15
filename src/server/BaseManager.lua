-- BaseManager.lua
-- Manages the base health and defense

local GameConfig = require(script.Parent.Parent.shared.GameConfig)

local BaseManager = {}
BaseManager.__index = BaseManager

function BaseManager.new()
	local self = setmetatable({}, BaseManager)
	self.health = GameConfig.BASE_HEALTH
	self.maxHealth = GameConfig.BASE_HEALTH
	self.isDestroyed = false
	return self
end

function BaseManager:damageBase(damage)
	if self.isDestroyed then
		return false
	end
	
	self.health = math.max(0, self.health - damage)
	
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
	return true
end

function BaseManager:getHealth()
	return self.health
end

function BaseManager:getHealthPercentage()
	return (self.health / self.maxHealth) * 100
end

function BaseManager:isBaseDestroyed()
	return self.isDestroyed
end

function BaseManager:reset()
	self.health = self.maxHealth
	self.isDestroyed = false
end

return BaseManager
