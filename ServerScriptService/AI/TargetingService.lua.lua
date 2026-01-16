-- @ScriptType: Script
-- TargetingService.lua
-- Tactical target selection system for zombies
-- Features overcrowding penalty, dynamic assignments, and base pressure
--
-- Replaces simple "closest wins" logic with scoring-based assignments

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local TargetingService = {}
TargetingService.__index = TargetingService

-- Configuration
local CONFIG = {
	OVERCROWD_RADIUS = 15, -- Radius to check for overcrowding
	OVERCROWD_THRESHOLD = 3, -- Max zombies before penalty kicks in
	OVERCROWD_PENALTY = 50, -- Score penalty per zombie beyond threshold
	BASE_SCORE_BOOST = 20, -- Boost for base targeting when players are swarmed
	ASSIGNMENT_CACHE_TIME = 0.5, -- How long assignments are cached
}

function TargetingService.new(baseManager)
	local self = setmetatable({}, TargetingService)
	
	self.baseManager = baseManager
	self.targetAssignments = {} -- [zombieModel] = {target, targetType, assignedTime}
	self.targetCounts = {} -- [targetId] = count
	self.lastUpdateTime = 0
	
	return self
end

-- Get base position and ID for targeting
function TargetingService:getBaseTarget()
	if not self.baseManager then
		return nil, nil
	end
	
	local baseModel = workspace:FindFirstChild("BaseCaptureZone")
	if not baseModel then
		return nil, nil
	end
	
	local hitbox = baseModel:FindFirstChild("HitBox", true)
	if hitbox and hitbox:IsA("BasePart") then
		return hitbox.Position, "base"
	end
	
	if baseModel:IsA("Model") then
		return baseModel:GetPivot().Position, "base"
	elseif baseModel:IsA("BasePart") then
		return baseModel.Position, "base"
	end
	
	return nil, nil
end

-- Get all alive players as potential targets
function TargetingService:getPlayerTargets()
	local targets = {}
	
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local isSpectating = character:GetAttribute("IsSpectating")
			if not isSpectating then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if hrp and humanoid and humanoid.Health > 0 then
					table.insert(targets, {
						position = hrp.Position,
						targetType = "player",
						targetId = player.UserId,
						player = player,
						character = character
					})
				end
			end
		end
	end
	
	return targets
end

-- Count zombies already assigned to a target
function TargetingService:countZombiesNearTarget(targetPos, targetId)
	local count = 0
	local currentTime = tick()
	
	-- Count from assignments
	for zombie, assignment in pairs(self.targetAssignments) do
		if zombie and zombie.Parent then
			local timeSince = currentTime - assignment.assignedTime
			if timeSince < CONFIG.ASSIGNMENT_CACHE_TIME then
				if assignment.targetId == targetId then
					count = count + 1
				end
			end
		end
	end
	
	return count
end

-- Calculate overcrowding penalty for a target
function TargetingService:calculateOvercrowdPenalty(targetPos, targetId)
	local zombieCount = self:countZombiesNearTarget(targetPos, targetId)
	
	if zombieCount <= CONFIG.OVERCROWD_THRESHOLD then
		return 0
	end
	
	local excess = zombieCount - CONFIG.OVERCROWD_THRESHOLD
	return excess * CONFIG.OVERCROWD_PENALTY
end

-- Score a potential target
function TargetingService:scoreTarget(zombiePos, targetPos, targetType, targetId, waveNumber, alivePlayers, zombieStats)
	-- Base score from distance (closer = higher score)
	local distance = (targetPos - zombiePos).Magnitude
	local distanceScore = math.max(0, 200 - distance)
	
	-- Overcrowding penalty
	local overcrowdPenalty = self:calculateOvercrowdPenalty(targetPos, targetId)
	
	-- Base gets bonus when players are heavily swarmed
	local baseBonus = 0
	if targetType == "base" then
		-- Check if any player is heavily swarmed
		local playerTargets = self:getPlayerTargets()
		for _, pTarget in ipairs(playerTargets) do
			local playerSwarmCount = self:countZombiesNearTarget(pTarget.position, pTarget.targetId)
			if playerSwarmCount >= CONFIG.OVERCROWD_THRESHOLD * 1.5 then
				baseBonus = CONFIG.BASE_SCORE_BOOST * (waveNumber or 1)
			end
		end
		
		-- Apply BasePreference bonus if zombie has base preference
		if zombieStats and zombieStats.BasePreference then
			-- Scale bonus based on preference (0.0-1.0 becomes 0-100 bonus points)
			baseBonus = baseBonus + (zombieStats.BasePreference * 100)
		end
	end
	
	local finalScore = distanceScore - overcrowdPenalty + baseBonus
	return finalScore
end

-- Select best target for a zombie using tactical scoring
function TargetingService:selectBestTarget(zombieModel, zombiePos, waveNumber)
	local targets = {}
	
	-- Get zombie stats from the model's ZombieType attribute
	local zombieStats = nil
	local zombieType = zombieModel:GetAttribute("ZombieType")
	if zombieType then
		local ZombieTypes = require(game:GetService("ReplicatedStorage").Shared.ZombieTypes)
		zombieStats = ZombieTypes[zombieType]
	end
	
	-- Get player targets
	local playerTargets = self:getPlayerTargets()
	for _, pTarget in ipairs(playerTargets) do
		table.insert(targets, pTarget)
	end
	
	-- Get base target
	local basePos, baseType = self:getBaseTarget()
	if basePos then
		table.insert(targets, {
			position = basePos,
			targetType = "base",
			targetId = "base",
			player = nil,
			character = nil
		})
	end
	
	-- No targets available
	if #targets == 0 then
		return nil, nil, nil
	end
	
	-- Score all targets
	local bestTarget = nil
	local bestScore = -math.huge
	
	for _, target in ipairs(targets) do
		local score = self:scoreTarget(
			zombiePos,
			target.position,
			target.targetType,
			target.targetId,
			waveNumber,
			#playerTargets,
			zombieStats
		)
		
		if score > bestScore then
			bestScore = score
			bestTarget = target
		end
	end
	
	-- Record assignment
	if bestTarget then
		self.targetAssignments[zombieModel] = {
			targetId = bestTarget.targetId,
			targetType = bestTarget.targetType,
			assignedTime = tick()
		}
		
		return bestTarget.position, bestTarget.targetType, bestTarget.player
	end
	
	return nil, nil, nil
end

-- Clean up assignments for destroyed zombies
function TargetingService:cleanupAssignments()
	-- Collect zombies to remove first (safe iteration)
	local toRemove = {}
	for zombie, _ in pairs(self.targetAssignments) do
		if not zombie or not zombie.Parent then
			table.insert(toRemove, zombie)
		end
	end
	
	-- Remove collected zombies
	for _, zombie in ipairs(toRemove) do
		self.targetAssignments[zombie] = nil
	end
end

-- Release a zombie's target assignment
function TargetingService:releaseAssignment(zombieModel)
	self.targetAssignments[zombieModel] = nil
end

-- Get current assignment for a zombie
function TargetingService:getAssignment(zombieModel)
	return self.targetAssignments[zombieModel]
end

-- Update service (called periodically)
function TargetingService:update(deltaTime)
	self.lastUpdateTime = self.lastUpdateTime + deltaTime
	
	-- Periodic cleanup
	if self.lastUpdateTime > 5.0 then
		self:cleanupAssignments()
		self.lastUpdateTime = 0
	end
end

return TargetingService
