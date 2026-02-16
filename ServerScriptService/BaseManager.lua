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
	self._destroyed = false
	
	-- Per-attacker cooldown tracking (prevents instant melt from multiple zombies)
	-- Maps attacker identifier (string) -> last damage timestamp (tick())
	self._attackerCooldowns = {}
	self._baseDamageCooldown = tonumber(GameConfig.BASE_DAMAGE_COOLDOWN) or 2.0

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
-- @param damage - Amount of damage to apply
-- @param source - Optional source identifier (zombie name, player name, etc.)
function BaseManager:damageBase(damage, source)
	if self._destroyed then
		return false
	end

	damage = tonumber(damage) or 0
	if damage <= 0 then
		return false
	end
	
	-- Per-attacker cooldown check (prevent instant melt from multiple zombies)
	local sourceStr = source and tostring(source) or "Unknown"
	local currentTime = tick()
	
	if self._attackerCooldowns[sourceStr] then
		local timeSinceLastAttack = currentTime - self._attackerCooldowns[sourceStr]
		if timeSinceLastAttack < self._baseDamageCooldown then
			-- Still on cooldown, reject damage
			return false
		end
	end
	
	-- Apply damage and record attack time
	self.health = math.max(0, self.health - damage)
	self._attackerCooldowns[sourceStr] = currentTime
	
	-- Security: Log base damage events with source tracking
	print(string.format("[BaseManager] DAMAGE: Base took %.1f damage from %s (Health: %.1f/%.1f)", 
		damage, sourceStr, self.health, self.maxHealth))
	
	self:broadcastHealthUpdate()

	if self.health <= 0 then
		self._destroyed = true
		return true
	end

	return false
end

function BaseManager:repairBase(amount)
	if self._destroyed then
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
	
	-- Clamp health to be at least 0 (allow values above maxHealth, e.g. for tests)
	self.health = math.max(0, value)
	
	-- Update _destroyed flag based on new health
	if self.health <= 0 then
		self._destroyed = true
	else
		self._destroyed = false
	end
	
	-- Broadcast the health update
	self:broadcastHealthUpdate()
	
	return self.health
end

function BaseManager:takeDamage(damage, source)
	-- Alias for damageBase to match test expectations
	return self:damageBase(damage, source)
end

-- Clean up cooldown entry for a specific attacker (e.g., when zombie dies/despawns)
-- @param attackerName - The identifier used in damageBase source parameter
function BaseManager:removeAttackerCooldown(attackerName)
	if attackerName then
		local key = tostring(attackerName)
		if self._attackerCooldowns[key] then
			self._attackerCooldowns[key] = nil
			-- Optional: log cleanup for debugging
			-- print(string.format("[BaseManager] Cleaned up cooldown for attacker: %s", key))
		end
	end
end

-- Clear all attacker cooldowns (useful for testing/reset)
function BaseManager:clearAttackerCooldowns()
	self._attackerCooldowns = {}
end

-- Compatibility shim: isDestroyed() method for test API
-- Direct access to _destroyed flag (optimized, no extra indirection)
function BaseManager:isDestroyed()
	return self._destroyed
end

function BaseManager:isBaseDestroyed()
	return self._destroyed
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
		self._baseDamageCooldown = tonumber(GameConfig.BASE_DAMAGE_COOLDOWN) or 2.0
	end

	self.health = self.maxHealth
	self._destroyed = false
	self:clearAttackerCooldowns() -- Clear cooldowns on reset
	self:broadcastHealthUpdate()
end

return BaseManager
