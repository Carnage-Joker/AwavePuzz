-- @ScriptType: ModuleScript
-- WaveManager.lua
-- Manages zombie waves and spawning

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local WaveManager = {}
WaveManager.__index = WaveManager

function WaveManager.new()
	local self = setmetatable({}, WaveManager)
	self.currentWave = 0
	self.zombiesAlive = 0
	self.zombiesSpawned = 0
	self.waveActive = false
	self.intensityMultiplier = 1.0 -- For synthesis system to increase zombie intensity
	return self
end

function WaveManager:calculateZombiesForWave(waveNumber)
	return math.floor(GameConfig.BASE_ZOMBIES_PER_WAVE * (GameConfig.ZOMBIES_PER_WAVE_MULTIPLIER ^ (waveNumber - 1)))
end

function WaveManager:calculateZombieHealthForWave(waveNumber)
	return math.floor(GameConfig.ZOMBIE_HEALTH * (GameConfig.ZOMBIE_HEALTH_MULTIPLIER ^ (waveNumber - 1)))
end

function WaveManager:startWave()
	self.currentWave = self.currentWave + 1
	self.zombiesSpawned = 0
	self.waveActive = true

	local zombieCount = self:calculateZombiesForWave(self.currentWave)

	return {
		waveNumber = self.currentWave,
		zombieCount = zombieCount,
		zombieHealth = self:calculateZombieHealthForWave(self.currentWave)
	}
end

function WaveManager:spawnZombie()
	if not self.waveActive then
		return nil
	end

	local maxZombies = self:calculateZombiesForWave(self.currentWave)
	if self.zombiesSpawned >= maxZombies then
		return nil
	end

	self.zombiesSpawned = self.zombiesSpawned + 1
	self.zombiesAlive = self.zombiesAlive + 1

	return {
		health = self:calculateZombieHealthForWave(self.currentWave),
		damage = GameConfig.ZOMBIE_DAMAGE,
		speed = GameConfig.ZOMBIE_SPEED,
		id = "zombie_" .. self.currentWave .. "_" .. self.zombiesSpawned
	}
end

function WaveManager:onZombieDeath()
	self.zombiesAlive = math.max(0, self.zombiesAlive - 1)

	-- Check if wave is complete
	if self.zombiesAlive == 0 and self.zombiesSpawned >= self:calculateZombiesForWave(self.currentWave) then
		self.waveActive = false
		return true -- Wave complete
	end

	return false
end

function WaveManager:isWaveActive()
	return self.waveActive
end

function WaveManager:getCurrentWave()
	return self.currentWave
end

function WaveManager:getZombiesRemaining()
	return self.zombiesAlive
end

-- Set intensity multiplier for special events (like cure synthesis)
function WaveManager:setIntensityMultiplier(multiplier)
	self.intensityMultiplier = multiplier or 1.0
	print("[WaveManager] Intensity multiplier set to", self.intensityMultiplier)
end

-- Get current intensity multiplier
function WaveManager:getIntensityMultiplier()
	return self.intensityMultiplier
end

return WaveManager