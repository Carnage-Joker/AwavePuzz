-- @ScriptType: ModuleScript
-- BaseManager.lua
-- Manages shared base health for the entire game
-- Features live updates broadcast to clients on damage

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BaseManager = {}
BaseManager.__index = BaseManager

local _instance = nil

-- Cached references
local _baseHealthEvent = nil

local function safeWaitForChild(parent, name, timeout)
	local obj = parent:WaitForChild(name, timeout or 5)
	if not obj then
		error(("[BaseManager] Missing required child '%s' under %s"):format(name, parent:GetFullName()))
	end
	return obj
end

local function getGameConfig()
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	if not shared then
		shared = safeWaitForChild(ReplicatedStorage, "Shared", 5)
	end

	local gameConfigModule = shared:FindFirstChild("GameConfig")
	if not gameConfigModule then
		gameConfigModule = safeWaitForChild(shared, "GameConfig", 5)
	end

	return require(gameConfigModule)
end

local function resolveRemotes()
	if _baseHealthEvent then
		return _baseHealthEvent
	end

	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEventsFolder then
		return nil
	end

	_baseHealthEvent = remoteEventsFolder:FindFirstChild("BaseHealthUpdate")
	return _baseHealthEvent
end

-----------------------------------------------------
-- Constructor
-----------------------------------------------------
function BaseManager.new()
	-- Hard fail if used on client; this is server authority state
	assert(RunService:IsServer(), "[BaseManager] Must be created/used on the server")

	local self = setmetatable({}, BaseManager)

	local GameConfig = getGameConfig()
	local baseHealth = tonumber(GameConfig.BASE_HEALTH) or 100

	self.maxHealth = math.max(0, baseHealth)
	self.health = self.maxHealth
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
	local evt = resolveRemotes()
	if not evt then
		-- Don’t warn every tick. Only warn once per session.
		if not self._warnedMissingRemotes then
			self._warnedMissingRemotes = true
			warn("[BaseManager] BaseHealthUpdate RemoteEvent not available yet")
		end
		return
	end

	evt:FireAllClients(self.health, self.maxHealth)
end

-----------------------------------------------------
-- Damage & Repair
-----------------------------------------------------
function BaseManager:damageBase(damage)
	if self.isDestroyed then
		return false
	end

	damage = tonumber(damage) or 0
	if damage <= 0 then
		return false
	end

	self.health = math.max(0, self.health - damage)
	self:broadcastHealthUpdate()

	if self.health <= 0 then
		self.isDestroyed = true
		return true
	end

	return false
end

function BaseManager:repairBase(amount)
	if self.isDestroyed then
		return false
	end

	amount = tonumber(amount) or 0
	if amount <= 0 then
		return false
	end

	self.health = math.min(self.maxHealth, self.health + amount)
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
	if self.maxHealth <= 0 then
		return 0
	end
	return (self.health / self.maxHealth) * 100
end

function BaseManager:setHealth(value)
	value = tonumber(value) or 0
	
	-- Clamp health between 0 and maxHealth
	self.health = math.clamp(value, 0, self.maxHealth)
	
	-- Update isDestroyed flag based on new health
	if self.health <= 0 then
		self.isDestroyed = true
	else
		self.isDestroyed = false
	end
	
	-- Broadcast the health update
	self:broadcastHealthUpdate()
	
	return self.health
end

function BaseManager:takeDamage(damage)
	-- Alias for damageBase to match test expectations
	return self:damageBase(damage)
end

function BaseManager:isDestroyed()
	-- Alias for isBaseDestroyed to match test expectations
	return self.isBaseDestroyed
end

function BaseManager:isBaseDestroyed()
	return self.isDestroyed
end

-----------------------------------------------------
-- Reset (for restarting game)
-----------------------------------------------------
function BaseManager:reset(opts)
	-- opts = { refreshMaxHealth = true/false }
	opts = opts or {}

	if opts.refreshMaxHealth then
		local GameConfig = getGameConfig()
		local baseHealth = tonumber(GameConfig.BASE_HEALTH) or self.maxHealth
		self.maxHealth = math.max(0, baseHealth)
	end

	self.health = self.maxHealth
	self.isDestroyed = false
	self:broadcastHealthUpdate()
end

return BaseManager
