-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
-- AIDirector.lua
-- Dynamic base pressure and spawn composition director
-- Controls zombie distribution and surge timing based on game state

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local AIDirector = {}
AIDirector.__index = AIDirector

-- Configuration
local CONFIG = {
	BASE_PRESSURE_MIN = 0.2, -- Minimum % of zombies assigned to base
	BASE_PRESSURE_MAX = 0.6, -- Maximum % of zombies assigned to base
	HIGH_WAVE_THRESHOLD = 5, -- Waves above this get more base pressure
	LOW_PLAYER_THRESHOLD = 3, -- Below this, reduce base pressure
	LOW_BASE_HP_THRESHOLD = 40, -- Base HP% below this increases player pressure
	SURGE_INTERVAL_MIN = 30, -- Minimum seconds between surges
	SURGE_INTERVAL_MAX = 60, -- Maximum seconds between surges
	SURGE_DURATION = 15, -- How long surge lasts
}

function AIDirector.new(baseManager, playerManager)
	local self = setmetatable({}, AIDirector)

	self.baseManager = baseManager
	self.playerManager = playerManager

	self.basePressurePercent = 0.3 -- Current % of zombies to send to base
	self.currentSurge = false
	self.surgeEndTime = 0
	self.nextSurgeTime = 0

	self.lastUpdateTime = tick()

	return self
end

-- Count alive players
function AIDirector:countAlivePlayers()
	local count = 0

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local isSpectating = character:GetAttribute("IsSpectating")
			if not isSpectating then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					count = count + 1
				end
			end
		end
	end

	return count
end

-- Get average player HP percentage
function AIDirector:getAveragePlayerHP()
	local totalHP = 0
	local count = 0

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local isSpectating = character:GetAttribute("IsSpectating")
			if not isSpectating then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					local hpPercent = (humanoid.Health / humanoid.MaxHealth) * 100
					totalHP = totalHP + hpPercent
					count = count + 1
				end
			end
		end
	end

	if count == 0 then
		return 100
	end

	return totalHP / count
end

-- Calculate zombies per player ratio
function AIDirector:getZombiesPerPlayer(totalZombies)
	local playerCount = self:countAlivePlayers()
	if playerCount == 0 then
		return totalZombies
	end

	return totalZombies / playerCount
end

-- Calculate base pressure based on game state
function AIDirector:calculateBasePressure(waveNumber, totalZombies)
	local alivePlayers = self:countAlivePlayers()
	local avgPlayerHP = self:getAveragePlayerHP()
	local baseHPPercent = self.baseManager:getHealthPercentage()
	local zombiesPerPlayer = self:getZombiesPerPlayer(totalZombies)

	local pressure = CONFIG.BASE_PRESSURE_MIN

	-- Wave number influence (higher waves = more base pressure)
	if waveNumber >= CONFIG.HIGH_WAVE_THRESHOLD then
		local waveBonus = math.min(0.3, (waveNumber - CONFIG.HIGH_WAVE_THRESHOLD) * 0.05)
		pressure = pressure + waveBonus
	end

	-- Player count influence (fewer players = less base pressure, protect the players)
	if alivePlayers <= CONFIG.LOW_PLAYER_THRESHOLD then
		pressure = pressure - 0.15
	end

	-- Base HP influence (low base HP = reduce base pressure, let them repair)
	if baseHPPercent < CONFIG.LOW_BASE_HP_THRESHOLD then
		pressure = pressure - 0.2
	end

	-- Player HP influence (low player HP = reduce base pressure)
	if avgPlayerHP < 40 then
		pressure = pressure - 0.1
	end

	-- Zombie density influence (more zombies per player = increase base pressure)
	if zombiesPerPlayer > 5 then
		pressure = pressure + 0.15
	end

	-- Clamp to valid range
	pressure = math.clamp(pressure, CONFIG.BASE_PRESSURE_MIN, CONFIG.BASE_PRESSURE_MAX)

	self.basePressurePercent = pressure
	return pressure
end

-- Check if surge should trigger
function AIDirector:checkSurge()
	local currentTime = tick()

	-- Check if current surge is active
	if self.currentSurge then
		if currentTime >= self.surgeEndTime then
			self.currentSurge = false
			print("[AIDirector] Surge ended")
		end
		return self.currentSurge
	end

	-- Check if it's time for new surge
	if currentTime >= self.nextSurgeTime then
		self.currentSurge = true
		self.surgeEndTime = currentTime + CONFIG.SURGE_DURATION

		-- Schedule next surge
		local nextInterval = math.random(CONFIG.SURGE_INTERVAL_MIN, CONFIG.SURGE_INTERVAL_MAX)
		self.nextSurgeTime = currentTime + nextInterval

		print("[AIDirector] Surge started! Duration:", CONFIG.SURGE_DURATION, "Next surge in:", nextInterval)
		return true
	end

	return false
end

-- Get spawn composition mix for current wave
function AIDirector:getSpawnComposition(waveNumber, totalZombies)
	local composition = {}

	-- Base mix
	local walkerPercent = 0.4
	local runnerPercent = 0.3
	local spitterPercent = 0.15
	local bruiserPercent = 0.1
	local bossPercent = 0
	local flankerPercent = 0
	local breacherPercent = 0
	local screamerPercent = 0.05

	-- Adjust based on wave number
	if waveNumber >= 3 then
		flankerPercent = 0.15
		runnerPercent = 0.2
		walkerPercent = 0.25
	end

	if waveNumber >= 5 then
		breacherPercent = 0.1
		spitterPercent = 0.2
		walkerPercent = 0.2
	end

	if waveNumber >= 7 then
		screamerPercent = 0.1
		bruiserPercent = 0.15
	end

	-- Boss waves (every 5 waves)
	if waveNumber % 5 == 0 then
		bossPercent = 0.05
		-- Reduce walkers for boss
		walkerPercent = math.max(0.1, walkerPercent - 0.1)
	end

	-- Surge modifies composition (more aggressive types)
	if self.currentSurge then
		runnerPercent = runnerPercent + 0.1
		flankerPercent = flankerPercent + 0.1
		walkerPercent = math.max(0.1, walkerPercent - 0.15)
	end

	-- Normalize to 1.0
	local total = walkerPercent + runnerPercent + spitterPercent + bruiserPercent + 
		bossPercent + flankerPercent + breacherPercent + screamerPercent

	if total > 0 then
		walkerPercent = walkerPercent / total
		runnerPercent = runnerPercent / total
		spitterPercent = spitterPercent / total
		bruiserPercent = bruiserPercent / total
		bossPercent = bossPercent / total
		flankerPercent = flankerPercent / total
		breacherPercent = breacherPercent / total
		screamerPercent = screamerPercent / total
	end

	-- Convert to counts
	composition.Walker = math.floor(totalZombies * walkerPercent)
	composition.Runner = math.floor(totalZombies * runnerPercent)
	composition.Spitter = math.floor(totalZombies * spitterPercent)
	composition.Brute = math.floor(totalZombies * bruiserPercent)
	composition.Boss = math.floor(totalZombies * bossPercent)
	composition.Flanker = math.floor(totalZombies * flankerPercent)
	composition.Breacher = math.floor(totalZombies * breacherPercent)
	composition.Screamer = math.floor(totalZombies * screamerPercent)

	-- Ensure at least totalZombies are spawned (rounding fix)
	local actualTotal = 0
	for _, count in pairs(composition) do
		actualTotal = actualTotal + count
	end

	if actualTotal < totalZombies then
		composition.Walker = composition.Walker + (totalZombies - actualTotal)
	end

	return composition
end

-- Should this zombie target base? (based on pressure %)
function AIDirector:shouldTargetBase(waveNumber, totalZombies)
	local pressure = self:calculateBasePressure(waveNumber, totalZombies)

	-- During surge, increase base pressure
	if self.currentSurge then
		pressure = pressure + 0.2
	end

	-- Random roll against pressure percentage
	return math.random() < pressure
end

-- Initialize surge timing
function AIDirector:initializeSurgeTimer()
	local firstSurgeDelay = math.random(CONFIG.SURGE_INTERVAL_MIN, CONFIG.SURGE_INTERVAL_MAX)
	self.nextSurgeTime = tick() + firstSurgeDelay
	print("[AIDirector] First surge scheduled in", firstSurgeDelay, "seconds")
end

-- Get current state info (for debugging)
function AIDirector:getStateInfo()
	return {
		basePressurePercent = self.basePressurePercent,
		currentSurge = self.currentSurge,
		nextSurgeIn = math.max(0, self.nextSurgeTime - tick()),
		surgeTimeLeft = self.currentSurge and math.max(0, self.surgeEndTime - tick()) or 0
	}
end

-- Update director
function AIDirector:update(deltaTime, waveNumber, totalZombies)
	self:checkSurge()
	self:calculateBasePressure(waveNumber or 1, totalZombies or 0)
end

return AIDirector
