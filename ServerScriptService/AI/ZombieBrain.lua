-- @ScriptType: ModuleScript
-- ZombieBrain.lua
-- AI controller for zombies with tactical targeting and behavior
-- 
-- Features:
-- - Tactical target selection with overcrowding prevention
-- - Surround slot system for anti-pileup movement
-- - Type-specific behaviors (Spitter, Flanker, Screamer, etc.)
-- - Boss aura integration
-- - Performance-optimized with tick jitter and caching
-- - Continuous movement system to prevent pausing/hesitation
--
-- RECENT FIXES (Zombie AI Hesitation):
-- - Reduced repath interval from 1.0s to 0.4s (less waiting between updates)
-- - Reduced jitter from up to 1.2s to 0.3s (prevents long random pauses)
-- - Added movement continuity: zombies keep moving toward last target during cooldown
-- - Added waypoint skipping: zombies don't stop at intermediate waypoints
-- - Implemented fallback movement when no path available
-- - Result: Zombies now continuously pressure players without idle pauses
--
-- AI controller for zombies with attack system and intelligent targeting
-- 
-- Features:
-- - Intelligent target selection: chooses nearest player or base
-- - Proximity-based attack system with cooldowns
-- - Attack animation support
-- - Server-authoritative damage dealing
-- - Base reference caching for performance
-- - Difficulty scaling through stats inherited from spawner

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local SpitterController = require(script.Parent.SpitterController)

local ZombieBrain = {}
ZombieBrain.__index = ZombieBrain

-- LOD (Level of Detail) Configuration
local LOD_CONFIG = {
	DISTANCE_LOW = 100,    -- > 100 studs: LOW detail (simple movement)
	DISTANCE_MEDIUM = 50,  -- 50-100 studs: MEDIUM detail (basic pathfinding)
	-- < 50 studs: HIGH detail (full AI with surround system)
	LOW_COOLDOWN_MULTIPLIER = 3,  -- LOW LOD updates 3x slower
	LOW_BASE_NEAR_DISTANCE = 20  -- Distance at which LOW LOD zombies can still attack base
}

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
	-- FIX: Reduce base interval and improve jitter to prevent long pauses
	-- Old: 1.0s + up to 1.2s jitter = 2.2s max wait (too long, causes pausing)
	-- New: 0.4s + up to 0.3s jitter = 0.7s max wait (smoother, continuous pressure)
	self.repathInterval = stats.RetargetInterval or GameConfig.ZOMBIE_REPATH_INTERVAL or 0.4

	-- Add jitter for performance and desynchronization
	-- Use configured jitter values from GameConfig.AI
	local minJitter = GameConfig.AI and GameConfig.AI.DEFAULT_UPDATE_JITTER or 0.1
	local maxJitter = GameConfig.AI and GameConfig.AI.MAX_UPDATE_JITTER or 0.3
	-- Ensure maxJitter >= minJitter to avoid negative jitter while preserving a non-zero range
	if maxJitter < minJitter then
		-- Swap values instead of collapsing them to a single point
		local temp = minJitter
		minJitter = maxJitter
		maxJitter = temp
	end
	local jitter = math.random() * (maxJitter - minJitter) + minJitter
	self.repathInterval = self.repathInterval + jitter

	self.currentTarget = nil -- Last known target position
	self.currentTargetType = nil -- "player" or "base"
	self.currentTargetPlayer = nil -- Player reference if targeting player
	self.currentSlot = nil -- Current surround slot position
	self.lastMoveTarget = nil -- FIX: Track last move command for continuity

	-- Movement continuity thresholds from config
	self.waypointSkipDistance = GameConfig.AI and GameConfig.AI.WAYPOINT_SKIP_DISTANCE or 3
	self.movementReissueDistance = GameConfig.AI and GameConfig.AI.MOVEMENT_REISSUE_DISTANCE or 0.5

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

	-- LOS caching with timestamp
	self.losCache = {}
	self.losCacheTime = tick()
	self.losCacheLifetime = 5 -- Clear cache every 5 seconds to prevent memory leak

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

-- Start method for tests (safe to call even if dependencies aren't fully present)
function ZombieBrain.start()
	-- This method exists for test compatibility
	-- ZombieBrain uses update() for its main loop
	return true
end

-- Stop method for tests (alias for destroy)
function ZombieBrain:stop()
	self:destroy()
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

-- Determine Level of Detail based on distance to nearest player
-- Returns: "HIGH", "MEDIUM", or "LOW"
function ZombieBrain:determineLOD()
	-- Validate rootPart exists
	if not self.rootPart then
		return "HIGH" -- Default to full AI if we can't calculate distance
	end
	
	local closestPlayerDistance = math.huge
	
	-- Check distance to all players
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local distance = (player.Character.HumanoidRootPart.Position - self.rootPart.Position).Magnitude
			closestPlayerDistance = math.min(closestPlayerDistance, distance)
		end
	end
	
	-- If no valid players found, use HIGH LOD to ensure zombies remain active
	-- (they'll target base via fallback mechanisms)
	if closestPlayerDistance == math.huge then
		return "HIGH"
	end
	
	-- Use module-level LOD configuration constants
	if closestPlayerDistance > LOD_CONFIG.DISTANCE_LOW then
		return "LOW" -- Simple movement toward base
	elseif closestPlayerDistance > LOD_CONFIG.DISTANCE_MEDIUM then
		return "MEDIUM" -- Basic pathfinding
	else
		return "HIGH" -- Full AI with surround system
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

-- Get base position for LOW LOD zombies
-- Uses same logic as TargetingService for consistency
function ZombieBrain:getBasePosition()
	local baseModel = workspace:FindFirstChild("BaseCaptureZone")
	if not baseModel then
		return nil
	end

	local hitbox = baseModel:FindFirstChild("HitBox", true)
	if hitbox and hitbox:IsA("BasePart") then
		return hitbox.Position
	end

	if baseModel:IsA("Model") then
		return baseModel:GetPivot().Position
	elseif baseModel:IsA("BasePart") then
		return baseModel.Position
	end

	return nil
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
	
	-- If no target available (no players and no base), provide wander behavior
	if not targetPos or not targetType then
		warn("[ZombieBrain] No valid targets available. Zombie will wander.")
		
		-- Create a wander point near last known position
		local lastPos = self.currentTarget or self.rootPart.Position
		local randomOffset = Vector3.new(
			math.random(-30, 30),
			0,
			math.random(-30, 30)
		)
		local wanderPos = lastPos + randomOffset
		
		return wanderPos, "wander", nil
	end

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
			-- Validate player still exists and character is parented (not disconnecting)
			if targetPlayer.Character and targetPlayer.Character.Parent then
				local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
				if targetHumanoid and targetHumanoid.Health > 0 then
					-- Apply player damage penalty if Breacher (proper nil check to allow 0 multiplier)
					if self.aiBehavior == "breacher" and self.stats.PlayerDamagePenalty ~= nil then
						damage = damage * self.stats.PlayerDamagePenalty
					end

					if self.playerManager then
						-- Wrap in pcall for extra safety against disconnect race conditions
						local success, err = pcall(function()
							self.playerManager:damagePlayer(targetPlayer, damage)
						end)
						if not success then
							warn("[ZombieBrain] Failed to damage player (likely disconnected):", err)
						end
					end
				end
			end
		elseif targetType == "base" then
			-- Apply base damage bonus if applicable (proper nil check to allow 0 multiplier)
			if (self.aiBehavior == "bruiser" or self.aiBehavior == "breacher") and self.stats.BaseDamageBonus ~= nil then
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
		if self.zombieModel:GetAttribute("InBossAura") and self.bossAuraService.getRetargetInterval then
			local baseInterval = self.stats.RetargetInterval or GameConfig.ZOMBIE_REPATH_INTERVAL or 0.4
			self.repathInterval = self.bossAuraService:getRetargetInterval(self.zombieModel, baseInterval)
		end
	end

	-- Determine Level of Detail based on distance to players
	local lod = self:determineLOD()
	
	-- LOW LOD: Skip most AI updates for distant zombies
	if lod == "LOW" then
		-- Check if zombie is close to base - allow full AI in that case
		local basePos = self:getBasePosition()
		local isNearBase = false
		if basePos and self.rootPart then
			local distanceToBase = (self.rootPart.Position - basePos).Magnitude
			if distanceToBase <= LOD_CONFIG.LOW_BASE_NEAR_DISTANCE then
				isNearBase = true
			end
		end
		
		-- Only use simplified LOW LOD behavior when far from base
		if not isNearBase then
			-- Only do basic movement toward base every few seconds
			if self.moveCooldown <= 0 then
				-- Update less frequently using config multiplier
				self.moveCooldown = self.repathInterval * LOD_CONFIG.LOW_COOLDOWN_MULTIPLIER
				if basePos then
					self.humanoid:MoveTo(basePos)
					self.lastMoveTarget = basePos
				end
			else
				self.moveCooldown = self.moveCooldown - deltaTime
			end
			return -- Skip rest of AI processing while far from base
		end
		-- If near base, continue with full AI to allow attacks
	end
	
	-- MEDIUM LOD: Basic pathfinding only, no advanced behaviors
	local useMediumLOD = (lod == "MEDIUM")
	
	-- Periodic LOS cache cleanup to prevent memory leak
	if tick() - self.losCacheTime > self.losCacheLifetime then
		self.losCache = {}
		self.losCacheTime = tick()
	end

	-- Update attack cooldown
	if self.attackCooldown > 0 then
		self.attackCooldown = math.max(0, self.attackCooldown - deltaTime)
	end

	-- Skip advanced behaviors for MEDIUM LOD
	if not useMediumLOD then
		-- Handle Screamer behavior (HIGH LOD only)
		self:handleScreamerBehavior()
	end

	-- Handle Spitter behavior (ranged) - skip for MEDIUM LOD
	if self.spitterController and not useMediumLOD then
		local targetPos, targetType, targetPlayer = self:selectBestTarget()
		if targetPos then
			local desiredPos = self.spitterController:update(deltaTime, targetPos, targetType, targetPlayer)
			if desiredPos then
				self.humanoid:MoveTo(desiredPos)
				self.lastMoveTarget = desiredPos
			end
		end
		return -- Spitter uses its own movement logic
	end

	-- Try to attack if in range
	local didAttack = self:tryAttack()

	-- FIX: Decrement movement cooldown but don't block all movement
	self.moveCooldown = self.moveCooldown - deltaTime

	-- FIX: Instead of blocking completely, provide movement continuity
	-- Check if we need to recalculate path (cooldown expired)
	local shouldRecalculatePath = self.moveCooldown <= 0

	if shouldRecalculatePath then
		-- Reset cooldown with small random variance to prevent sync
		-- Use a small fraction of the configured jitter for micro-variance (non-negative)
		local microJitter = (GameConfig.AI and GameConfig.AI.DEFAULT_UPDATE_JITTER or 0.1) * 0.5
		local jitterOffset = math.random() * microJitter
		self.moveCooldown = self.repathInterval + jitterOffset

		-- Recalculate target and path
		if self.rootPart then
			local targetPos, targetType, targetPlayer = self:selectBestTarget()

			if targetPos then
				-- Store current target info
				self.currentTarget = targetPos
				self.currentTargetType = targetType
				self.currentTargetPlayer = targetPlayer

				local finalTarget = targetPos
				
				-- Only use surround system for HIGH LOD
				if not useMediumLOD then
					-- Get target ID for slot assignment
					local targetId = targetType == "base" and "base" or (targetPlayer and targetPlayer.UserId or "unknown")

					-- Get slot position with surround system
					local slotPos = self:getSlotPosition(targetPos, targetId)

					-- Validate slotPos before using (could be nil if target destroyed)
					if slotPos then
						finalTarget = slotPos
						-- Apply separation steering if service available
						if self.surroundService then
							local nearbyZombies = self:getNearbyZombies()
							local steeringTarget = self.surroundService:getSteeringTarget(
								self.zombieModel,
								self.rootPart.Position,
								slotPos,
								nearbyZombies
							)
							-- Validate steering target before using
							if steeringTarget then
								finalTarget = steeringTarget
							end
							-- If steering target is nil, finalTarget remains slotPos
						end
					end
					-- If slotPos is nil, finalTarget remains targetPos (fallback)
				end

				-- FIX: Issue new move command
				if finalTarget then
					self.humanoid:MoveTo(finalTarget)
					self.lastMoveTarget = finalTarget
				end
			end
		end
	else
		-- FIX: CRITICAL - Keep moving toward last known target during cooldown
		-- This prevents zombies from standing idle while waiting for next path recalc
		if self.lastMoveTarget and self.rootPart then
			-- Check if we're close to the last target
			local distanceToLastTarget = (self.lastMoveTarget - self.rootPart.Position).Magnitude

			-- If we've reached the last waypoint or are very close, move directly toward raw target
			-- Use configurable waypoint skip distance
			if distanceToLastTarget < self.waypointSkipDistance and self.currentTarget then
				-- FIX: Don't stop at waypoints - push through toward actual target
				self.humanoid:MoveTo(self.currentTarget)
				self.lastMoveTarget = self.currentTarget
			elseif distanceToLastTarget > self.movementReissueDistance then
				-- FIX: Re-issue move command to ensure continuous movement
				-- This prevents the zombie from stopping when it "thinks" it arrived
				-- Use configurable movement reissue distance
				self.humanoid:MoveTo(self.lastMoveTarget)
				-- else: distance is between reissue and skip thresholds, already moving correctly
			end
		elseif self.currentTarget then
			-- FIX: Fallback - if no last move target, use current target
			self.humanoid:MoveTo(self.currentTarget)
			self.lastMoveTarget = self.currentTarget
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
