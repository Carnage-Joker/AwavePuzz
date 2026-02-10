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
	self._spawnQueue = {} -- Queue-based spawning to prevent race conditions
	return self
end

function WaveManager:calculateZombiesForWave(waveNumber)
	-- Apply intensity multiplier for synthesis system
	return math.floor(GameConfig.BASE_ZOMBIES_PER_WAVE * (GameConfig.ZOMBIES_PER_WAVE_MULTIPLIER ^ (waveNumber - 1)) * self.intensityMultiplier)
end

function WaveManager:calculateZombieHealthForWave(waveNumber)
	-- Apply intensity multiplier for synthesis system
	return math.floor(GameConfig.ZOMBIE_HEALTH * (GameConfig.ZOMBIE_HEALTH_MULTIPLIER ^ (waveNumber - 1)) * self.intensityMultiplier)
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

	-- Queue-based spawning to prevent race conditions
	-- Add this request to the spawn queue
	table.insert(self._spawnQueue, tick())
	
	-- If there are multiple requests in queue, only the first one processes
	if #self._spawnQueue > 1 then
		return nil -- Another spawn is already processing
	end
	
	-- Process all queued spawn requests
	while #self._spawnQueue > 0 do
		table.remove(self._spawnQueue, 1) -- Remove the request we're processing
		
		local maxZombies = self:calculateZombiesForWave(self.currentWave)
		if self.zombiesSpawned >= maxZombies then
			-- Max zombies reached, skip remaining queue items
			continue
		end
		
		self.zombiesSpawned = self.zombiesSpawned + 1
		self.zombiesAlive = self.zombiesAlive + 1
		
		-- Return the first successful spawn
		return {
			health = self:calculateZombieHealthForWave(self.currentWave),
			damage = GameConfig.ZOMBIE_DAMAGE,
			speed = GameConfig.ZOMBIE_SPEED,
			id = "zombie_" .. self.currentWave .. "_" .. self.zombiesSpawned
		}
	end
	
	return nil
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