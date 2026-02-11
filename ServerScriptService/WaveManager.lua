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
	self._isProcessingQueue = false -- Atomic flag to prevent concurrent queue processing
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
	self._spawnQueue = {} -- Clear spawn queue when starting new wave
	self._isProcessingQueue = false -- Reset processing flag

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

	-- Queue-based spawning to serialize spawn requests
	-- Add this request to the spawn queue first
	table.insert(self._spawnQueue, true)
	
	-- Check if another call is already processing the queue
	-- CRITICAL: Do not yield between this check and setting the flag below
	if self._isProcessingQueue then
		-- Another thread is processing, it will handle our queued request
		return nil
	end
	
	-- Claim exclusive queue processing rights
	self._isProcessingQueue = true
	
	-- Process all currently queued spawn requests in this batch
	-- Wrap in pcall to ensure flag is always reset even if an error occurs
	local success, result = pcall(function()
		local firstSpawnData = nil
		local maxZombies = self:calculateZombiesForWave(self.currentWave)
		
		while #self._spawnQueue > 0 do
			-- Remove one request from queue
			table.remove(self._spawnQueue, 1)
			
			-- Spawn one zombie per queued request, up to max
			if self.zombiesSpawned < maxZombies then
				self.zombiesSpawned = self.zombiesSpawned + 1
				self.zombiesAlive = self.zombiesAlive + 1
				
				-- Only return data for the first spawn (the one from the original call)
				if not firstSpawnData then
					firstSpawnData = {
						health = self:calculateZombieHealthForWave(self.currentWave),
						damage = GameConfig.ZOMBIE_DAMAGE,
						speed = GameConfig.ZOMBIE_SPEED,
						id = "zombie_" .. self.currentWave .. "_" .. self.zombiesSpawned
					}
				end
			end
		end
		
		return firstSpawnData
	end)
	
	-- Always release queue processing lock, even if an error occurred
	self._isProcessingQueue = false
	
	-- Re-throw the error if one occurred
	if not success then
		error(result)
	end
	
	return result
end

function WaveManager:onZombieDeath()
	self.zombiesAlive = math.max(0, self.zombiesAlive - 1)

	-- Check if wave is complete
	if self.zombiesAlive == 0 and self.zombiesSpawned >= self:calculateZombiesForWave(self.currentWave) then
		self.waveActive = false
		self._spawnQueue = {} -- Clear spawn queue when wave ends
		self._isProcessingQueue = false -- Reset processing flag
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