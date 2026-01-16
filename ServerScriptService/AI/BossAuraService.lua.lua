-- @ScriptType: Script
-- BossAuraService.lua
-- Commander aura system for Boss zombies
-- Provides tactical buffs to nearby zombies when Boss is present

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local BossAuraService = {}
BossAuraService.__index = BossAuraService

-- Configuration
local CONFIG = {
	AURA_RADIUS = 40, -- Range of boss aura effect
	RETARGET_SPEED_BOOST = 0.5, -- Reduce retarget interval by this much
	FLANK_CHANCE_BOOST = 0.3, -- Increase chance to pick flank slots
	MOVE_SPEED_BOOST = 1.1, -- 10% move speed increase
	OVERCROWD_PENALTY_REDUCTION = 0.5, -- Reduce overcrowd penalty by 50%
	UPDATE_INTERVAL = 1.0, -- How often to update aura effects
}

function BossAuraService.new()
	local self = setmetatable({}, BossAuraService)
	
	self.activeBosses = {} -- [bossModel] = {position, model}
	self.affectedZombies = {} -- [zombieModel] = {bossModel, lastUpdate}
	self.debugMode = false
	self.debugParts = {} -- Visual indicators
	self.lastUpdateTime = 0
	
	return self
end

-- Register a boss zombie
function BossAuraService:registerBoss(bossModel)
	if not bossModel or not bossModel.Parent then
		return
	end
	
	local rootPart = bossModel:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end
	
	self.activeBosses[bossModel] = {
		position = rootPart.Position,
		model = bossModel
	}
	
	print("[BossAura] Boss registered:", bossModel.Name)
	
	-- Create debug visual if enabled
	if self.debugMode then
		self:createDebugVisual(bossModel)
	end
end

-- Unregister a boss zombie
function BossAuraService:unregisterBoss(bossModel)
	self.activeBosses[bossModel] = nil
	
	-- Remove affected zombies linked to this boss
	for zombie, data in pairs(self.affectedZombies) do
		if data.bossModel == bossModel then
			self.affectedZombies[zombie] = nil
		end
	end
	
	-- Remove debug visual
	if self.debugParts[bossModel] then
		if self.debugParts[bossModel].Parent then
			self.debugParts[bossModel]:Destroy()
		end
		self.debugParts[bossModel] = nil
	end
	
	print("[BossAura] Boss unregistered:", bossModel and bossModel.Name or "unknown")
end

-- Check if any boss is active
function BossAuraService:hasBossActive()
	for boss, _ in pairs(self.activeBosses) do
		if boss and boss.Parent then
			return true
		end
	end
	return false
end

-- Find nearest boss to a position
function BossAuraService:findNearestBoss(position)
	local nearestBoss = nil
	local nearestDistance = math.huge
	
	for bossModel, bossData in pairs(self.activeBosses) do
		if bossModel and bossModel.Parent then
			local rootPart = bossModel:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local distance = (rootPart.Position - position).Magnitude
				if distance < nearestDistance then
					nearestDistance = distance
					nearestBoss = bossModel
				end
			end
		end
	end
	
	return nearestBoss, nearestDistance
end

-- Check if zombie is within aura range of any boss
function BossAuraService:isZombieInAura(zombieModel, zombiePos)
	local nearestBoss, distance = self:findNearestBoss(zombiePos)
	
	if nearestBoss and distance <= CONFIG.AURA_RADIUS then
		return true, nearestBoss
	end
	
	return false, nil
end

-- Apply aura buffs to a zombie
function BossAuraService:applyAuraBuffs(zombieModel, zombieBrain)
	local rootPart = zombieModel:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end
	
	local inAura, nearestBoss = self:isZombieInAura(zombieModel, rootPart.Position)
	
	if inAura then
		-- Track affected zombie
		self.affectedZombies[zombieModel] = {
			bossModel = nearestBoss,
			lastUpdate = tick()
		}
		
		-- Apply move speed boost (if not already applied)
		local humanoid = zombieModel:FindFirstChildOfClass("Humanoid")
		if humanoid and not zombieModel:GetAttribute("AuraSpeedApplied") then
			local baseSpeed = zombieBrain.stats.Speed or GameConfig.ZOMBIE_SPEED or 16
			humanoid.WalkSpeed = baseSpeed * CONFIG.MOVE_SPEED_BOOST
			zombieModel:SetAttribute("AuraSpeedApplied", true)
		end
		
		-- Mark zombie as aura-affected for other systems to check
		zombieModel:SetAttribute("InBossAura", true)
	else
		-- Remove aura effects
		if self.affectedZombies[zombieModel] then
			self.affectedZombies[zombieModel] = nil
		end
		
		-- Remove move speed boost
		local humanoid = zombieModel:FindFirstChildOfClass("Humanoid")
		if humanoid and zombieModel:GetAttribute("AuraSpeedApplied") then
			local baseSpeed = zombieBrain.stats.Speed or GameConfig.ZOMBIE_SPEED or 16
			humanoid.WalkSpeed = baseSpeed
			zombieModel:SetAttribute("AuraSpeedApplied", false)
		end
		
		zombieModel:SetAttribute("InBossAura", false)
	end
end

-- Get aura-modified retarget interval
function BossAuraService:getRetargetInterval(zombieModel, baseInterval)
	if zombieModel:GetAttribute("InBossAura") then
		return baseInterval * (1 - CONFIG.RETARGET_SPEED_BOOST)
	end
	return baseInterval
end

-- Get aura-modified flank chance
function BossAuraService:getFlankChance(zombieModel, baseChance)
	if zombieModel:GetAttribute("InBossAura") then
		return math.min(1.0, baseChance + CONFIG.FLANK_CHANCE_BOOST)
	end
	return baseChance
end

-- Get aura-modified overcrowd penalty
function BossAuraService:getOvercrowdPenalty(zombieModel, basePenalty)
	if zombieModel:GetAttribute("InBossAura") then
		return basePenalty * (1 - CONFIG.OVERCROWD_PENALTY_REDUCTION)
	end
	return basePenalty
end

-- Create debug visual for boss aura
function BossAuraService:createDebugVisual(bossModel)
	local rootPart = bossModel:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end
	
	-- Create aura sphere
	local auraPart = Instance.new("Part")
	auraPart.Name = "BossAuraDebug"
	auraPart.Shape = Enum.PartType.Ball
	auraPart.Size = Vector3.new(CONFIG.AURA_RADIUS * 2, CONFIG.AURA_RADIUS * 2, CONFIG.AURA_RADIUS * 2)
	auraPart.Transparency = 0.8
	auraPart.Color = Color3.fromRGB(255, 100, 100)
	auraPart.Material = Enum.Material.Neon
	auraPart.CanCollide = false
	auraPart.Anchored = true
	auraPart.Parent = workspace
	
	-- Position at boss
	auraPart.Position = rootPart.Position
	
	self.debugParts[bossModel] = auraPart
end

-- Update debug visuals
function BossAuraService:updateDebugVisuals()
	for bossModel, debugPart in pairs(self.debugParts) do
		if bossModel and bossModel.Parent then
			local rootPart = bossModel:FindFirstChild("HumanoidRootPart")
			if rootPart and debugPart.Parent then
				debugPart.Position = rootPart.Position
			end
		else
			-- Clean up
			if debugPart.Parent then
				debugPart:Destroy()
			end
			self.debugParts[bossModel] = nil
		end
	end
end

-- Enable/disable debug mode
function BossAuraService:setDebugMode(enabled)
	self.debugMode = enabled
	
	if not enabled then
		-- Clean up all debug visuals
		for _, debugPart in pairs(self.debugParts) do
			if debugPart.Parent then
				debugPart:Destroy()
			end
		end
		self.debugParts = {}
	else
		-- Create visuals for existing bosses
		for bossModel, _ in pairs(self.activeBosses) do
			if bossModel and bossModel.Parent then
				self:createDebugVisual(bossModel)
			end
		end
	end
	
	print("[BossAura] Debug mode:", enabled and "enabled" or "disabled")
end

-- Clean up invalid bosses
function BossAuraService:cleanup()
	-- Collect bosses to remove (safe iteration)
	local bossesToRemove = {}
	for bossModel, _ in pairs(self.activeBosses) do
		if not bossModel or not bossModel.Parent then
			table.insert(bossesToRemove, bossModel)
		end
	end
	
	-- Remove collected bosses
	for _, bossModel in ipairs(bossesToRemove) do
		self:unregisterBoss(bossModel)
	end
	
	-- Collect affected zombies to remove (safe iteration)
	local zombiesToRemove = {}
	for zombieModel, _ in pairs(self.affectedZombies) do
		if not zombieModel or not zombieModel.Parent then
			table.insert(zombiesToRemove, zombieModel)
		end
	end
	
	-- Remove collected zombies
	for _, zombieModel in ipairs(zombiesToRemove) do
		self.affectedZombies[zombieModel] = nil
	end
end

-- Update service
function BossAuraService:update(deltaTime, allZombies)
	self.lastUpdateTime = self.lastUpdateTime + deltaTime
	
	-- Update at interval
	if self.lastUpdateTime >= CONFIG.UPDATE_INTERVAL then
		self.lastUpdateTime = 0
		
		-- Cleanup invalid entries
		self:cleanup()
		
		-- Update debug visuals
		if self.debugMode then
			self:updateDebugVisuals()
		end
	end
end

-- Get stats for debugging
function BossAuraService:getStats()
	return {
		activeBosses = self:countActiveBosses(),
		affectedZombies = self:countAffectedZombies(),
		auraRadius = CONFIG.AURA_RADIUS
	}
end

function BossAuraService:countActiveBosses()
	local count = 0
	for boss, _ in pairs(self.activeBosses) do
		if boss and boss.Parent then
			count = count + 1
		end
	end
	return count
end

function BossAuraService:countAffectedZombies()
	local count = 0
	for zombie, _ in pairs(self.affectedZombies) do
		if zombie and zombie.Parent then
			count = count + 1
		end
	end
	return count
end

return BossAuraService
