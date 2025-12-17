-- ZombieBrain.lua
-- AI controller for zombies with tactical targeting and behavior
-- 
-- Features:
-- - Tactical target selection with overcrowding prevention
-- - Surround slot system for anti-pileup movement
-- - Type-specific behaviors (Spitter, Flanker, Screamer, etc.)
-- - Boss aura integration
-- - Performance-optimized with tick jitter and caching

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local SpitterController = require(script.Parent.SpitterController)

local ZombieBrain = {}
ZombieBrain.__index = ZombieBrain

function ZombieBrain.new(zombieModel, stats, baseManager, playerManager, targetingService, surroundService, bossAuraService, waveNumber)
	if not zombieModel or not zombieModel:IsA("Model") then
		return nil
	end

	local humanoid = zombieModel:FindFirstChildOfClass("Humanoid")
	local rootPart = zombieModel:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then
		warn("[ZombieBrain] Missing Humanoid or HumanoidRootPart on zombie model:", zombieModel.Name)
		return nil
	end

	local self = setmetatable({}, ZombieBrain)

	self.zombieModel = zombieModel
	self.humanoid = humanoid
	self.rootPart = rootPart
	self.stats = stats or {}
	self.isActive = true
	self.zombieType = zombieModel:GetAttribute("ZombieType") or "Walker"

	-- Managers and services
	self.baseManager = baseManager
	self.playerManager = playerManager
	self.targetingService = targetingService
	self.surroundService = surroundService
	self.bossAuraService = bossAuraService
	self.waveNumber = waveNumber or 1

	-- Movement and targeting
	self.moveCooldown = 0
	self.repathInterval = stats.RetargetInterval or GameConfig.ZOMBIE_REPATH_INTERVAL or 1.0
	
	-- Add jitter for performance
	local jitter = math.random() * (GameConfig.AI.MAX_UPDATE_JITTER - GameConfig.AI.DEFAULT_UPDATE_JITTER)
	self.repathInterval = self.repathInterval + jitter
	
	self.currentTarget = nil
	self.currentTargetType = nil
	self.currentTargetPlayer = nil
	self.currentSlot = nil

	-- Cache base reference for performance
	self.cachedBase = nil

	-- Attack system
	self.attackCooldown = 0
	self.attackInterval = GameConfig.ZOMBIE_ATTACK_INTERVAL or 1.5
	self.attackRange = GameConfig.ZOMBIE_ATTACK_RANGE or 6
	self.attackDamage = self.stats.Damage or GameConfig.ZOMBIE_DAMAGE or 10

	-- Animation support
	self.attackAnimationTrack = nil
	self:loadAttackAnimation()

	-- Type-specific behavior
	self.aiBehavior = stats.AIBehavior or "standard"
	self.spitterController = nil
	
	-- Special behavior timers
	self.screamerCallCooldown = 0
	self.lastCallTime = 0
	
	-- LOS caching
	self.losCache = {}
	self.losCacheTime = 0

	-- Initialize type-specific controller
	if self.aiBehavior == "ranged" then
		self.spitterController = SpitterController.new(zombieModel, stats, baseManager, playerManager)
	end

	-- Basic speed from stats if provided
	if self.stats.Speed or self.stats.speed then
		self.humanoid.WalkSpeed = self.stats.Speed or self.stats.speed
	end
	
	-- Register with boss aura if this is a boss
	if stats.HasAura and bossAuraService then
		bossAuraService:registerBoss(zombieModel)
	end

	return self
end

-- Load attack animation if available
function ZombieBrain:loadAttackAnimation()
	local animator = self.humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = self.humanoid
	end

	-- Try to find attack animation in the zombie model
	local attackAnim = self.zombieModel:FindFirstChild("AttackAnimation", true)
	if attackAnim and attackAnim:IsA("Animation") then
		self.attackAnimationTrack = animator:LoadAnimation(attackAnim)
	end
end

-- Play attack animation if available
function ZombieBrain:playAttackAnimation()
	if self.attackAnimationTrack then
		self.attackAnimationTrack:Play()
	end
end

-- Get all nearby zombies for separation steering
function ZombieBrain:getNearbyZombies()
	local nearby = {}
	local zombiesFolder = workspace:FindFirstChild("Zombies")
	
	if zombiesFolder then
		for _, zombie in ipairs(zombiesFolder:GetChildren()) do
			if zombie ~= self.zombieModel and zombie:IsA("Model") then
				local distance = (zombie:GetPivot().Position - self.rootPart.Position).Magnitude
				if distance < 15 then -- Only consider nearby zombies
					table.insert(nearby, zombie)
				end
			end
		end
	end
	
	return nearby
end

-- Get target using tactical targeting service
function ZombieBrain:selectBestTarget()
	if not self.targetingService then
		return nil, nil, nil
	end
	
	-- Use targeting service for tactical selection
	local targetPos, targetType, targetPlayer = self.targetingService:selectBestTarget(
		self.zombieModel,
		self.rootPart.Position,
		self.waveNumber
	)
	
	return targetPos, targetType, targetPlayer
end

-- Get slot position for surround behavior
function ZombieBrain:getSlotPosition(targetPos, targetId)
	if not self.surroundService then
		return targetPos
	end
	
	-- Check if should re-roll slot
	if self.surroundService:shouldRerollSlot(self.zombieModel, self.rootPart.Position) then
		self.surroundService:releaseSlot(self.zombieModel)
		self.currentSlot = nil
	end
	
	-- Get or assign slot
	if not self.currentSlot then
		local slotPreference = self.stats.SlotPreference or "middle"
		local sidePreference = nil
		
		-- Determine side preference based on type
		if self.stats.PreferBackSlots then
			sidePreference = "back"
		elseif self.stats.FlankChance then
			-- Roll for flank
			local flankChance = self.stats.FlankChance
			
			-- Boss aura boosts flank chance
			if self.bossAuraService then
				flankChance = self.bossAuraService:getFlankChance(self.zombieModel, flankChance)
			end
			
			if math.random() < flankChance then
				sidePreference = "flank"
			end
		end
		
		local slotPos, slotKey, ringIndex, slotIndex = self.surroundService:findAvailableSlot(
			targetPos,
			targetId,
			slotPreference,
			sidePreference
		)
		
		if slotPos then
			self.surroundService:reserveSlot(self.zombieModel, slotKey, slotPos, ringIndex, slotIndex)
			self.currentSlot = slotPos
		end
	end
	
	return self.currentSlot or targetPos
end

-- Apply special behavior for Screamer type
function ZombieBrain:handleScreamerBehavior()
	if self.aiBehavior ~= "screamer" then
		return
	end
	
	local callCooldown = self.stats.CallCooldown or 10.0
	local currentTime = tick()
	
	if currentTime - self.lastCallTime >= callCooldown then
		-- Emit "call" effect
		self.lastCallTime = currentTime
		
		local callRadius = self.stats.CallRadius or 30
		local callDuration = self.stats.CallDuration or 5.0
		
		-- Mark nearby zombies with call buff
		local zombiesFolder = workspace:FindFirstChild("Zombies")
		if zombiesFolder then
			for _, zombie in ipairs(zombiesFolder:GetChildren()) do
				if zombie ~= self.zombieModel and zombie:IsA("Model") then
					local distance = (zombie:GetPivot().Position - self.rootPart.Position).Magnitude
					if distance <= callRadius then
						-- Set temporary buff attribute
						zombie:SetAttribute("ScreamerBuffed", true)
						zombie:SetAttribute("ScreamerBuffExpire", currentTime + callDuration)
					end
				end
			end
		end
		
		print("[ZombieBrain] Screamer called! Buffing nearby zombies")
	end
end

-- Attempt to attack target if in range
function ZombieBrain:tryAttack()
	if not self.rootPart or self.attackCooldown > 0 then
		return false
	end

	local targetPos, targetType, targetPlayer = self.currentTarget, self.currentTargetType, self.currentTargetPlayer
	if not targetPos then
		return false
	end

	local distance = (targetPos - self.rootPart.Position).Magnitude

	-- Check if in attack range
	if distance <= self.attackRange then
		self.attackCooldown = self.attackInterval
		self:playAttackAnimation()

		-- Calculate damage (with type-specific modifiers)
		local damage = self.attackDamage
		
		-- Deal damage to appropriate target
		if targetType == "player" and targetPlayer then
			-- Validate player still exists and has character
			if targetPlayer and targetPlayer.Character then
				local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
				if targetHumanoid and targetHumanoid.Health > 0 then
					-- Apply player damage penalty if Breacher
					if self.aiBehavior == "breacher" and self.stats.PlayerDamagePenalty then
						damage = damage * self.stats.PlayerDamagePenalty
					end
					
					if self.playerManager then
						self.playerManager:damagePlayer(targetPlayer, damage)
					end
				end
			end
		elseif targetType == "base" then
			-- Apply base damage bonus if applicable
			if (self.aiBehavior == "bruiser" or self.aiBehavior == "breacher") and self.stats.BaseDamageBonus then
				damage = damage * self.stats.BaseDamageBonus
			end
			
			if self.baseManager then
				self.baseManager:damageBase(damage)
			end
		end

		return true
	end

	return false
end

function ZombieBrain:update(deltaTime)
	if not self.isActive then
		return
	end

	if not self.zombieModel or not self.zombieModel.Parent then
		self.isActive = false
		return
	end

	if not self.humanoid or self.humanoid.Health <= 0 then
		self.isActive = false
		return
	end

	-- Apply boss aura buffs if service available
	if self.bossAuraService and not self.stats.HasAura then
		self.bossAuraService:applyAuraBuffs(self.zombieModel, self)
		
		-- Adjust retarget interval based on aura
		if self.zombieModel:GetAttribute("InBossAura") then
			local baseInterval = self.stats.RetargetInterval or GameConfig.ZOMBIE_REPATH_INTERVAL or 1.0
			self.repathInterval = self.bossAuraService:getRetargetInterval(self.zombieModel, baseInterval)
		end
	end

	-- Update attack cooldown
	if self.attackCooldown > 0 then
		self.attackCooldown = math.max(0, self.attackCooldown - deltaTime)
	end
	
	-- Handle Screamer behavior
	self:handleScreamerBehavior()

	-- Handle Spitter behavior (ranged)
	if self.spitterController then
		local targetPos, targetType, targetPlayer = self:selectBestTarget()
		if targetPos then
			local desiredPos = self.spitterController:update(deltaTime, targetPos, targetType, targetPlayer)
			if desiredPos then
				self.humanoid:MoveTo(desiredPos)
			end
		end
		return -- Spitter uses its own movement logic
	end

	-- Try to attack if in range
	local didAttack = self:tryAttack()

	-- Update movement cooldown
	self.moveCooldown -= deltaTime
	if self.moveCooldown > 0 then
		return
	end

	self.moveCooldown = self.repathInterval

	-- Select best target using tactical targeting
	if self.rootPart then
		local targetPos, targetType, targetPlayer = self:selectBestTarget()
		
		if targetPos then
			-- Store current target info
			self.currentTarget = targetPos
			self.currentTargetType = targetType
			self.currentTargetPlayer = targetPlayer
			
			-- Get target ID for slot assignment
			local targetId = targetType == "base" and "base" or (targetPlayer and targetPlayer.UserId or "unknown")
			
			-- Get slot position with surround system
			local slotPos = self:getSlotPosition(targetPos, targetId)
			
			-- Apply separation steering if service available
			local finalTarget = slotPos
			if self.surroundService then
				local nearbyZombies = self:getNearbyZombies()
				finalTarget = self.surroundService:getSteeringTarget(
					self.zombieModel,
					self.rootPart.Position,
					slotPos,
					nearbyZombies
				)
			end
			
			-- Move toward target
			self.humanoid:MoveTo(finalTarget)
		end
	end
end

function ZombieBrain:destroy()
	self.isActive = false

	-- Release slot reservation
	if self.surroundService then
		self.surroundService:releaseSlot(self.zombieModel)
	end
	
	-- Release target assignment
	if self.targetingService then
		self.targetingService:releaseAssignment(self.zombieModel)
	end
	
	-- Unregister from boss aura if this is a boss
	if self.stats.HasAura and self.bossAuraService then
		self.bossAuraService:unregisterBoss(self.zombieModel)
	end

	-- Stop and cleanup animation
	if self.attackAnimationTrack then
		self.attackAnimationTrack:Stop()
		self.attackAnimationTrack = nil
	end
	
	-- Cleanup spitter controller
	if self.spitterController then
		self.spitterController:destroy()
		self.spitterController = nil
	end

	self.zombieModel = nil
	self.humanoid = nil
	self.rootPart = nil
	self.baseManager = nil
	self.playerManager = nil
	self.targetingService = nil
	self.surroundService = nil
	self.bossAuraService = nil
	self.cachedBase = nil
end

return ZombieBrain
