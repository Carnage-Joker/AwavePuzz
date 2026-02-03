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
-- DROP-IN SAFETY FIXES (this rewrite):
-- - FIX: self.model nil crash in base damage (use self.zombieModel)
-- - PERF: LOD determination throttled (no longer every frame)
-- - STABILITY: MoveTo rate-limited to avoid spam/state churn
-- - CONSISTENCY: Aura retarget interval keeps per-zombie jitter

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService") -- kept for future use/compat
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local SpitterController = require(script.Parent.SpitterController)

local ZombieBrain = {}
ZombieBrain.__index = ZombieBrain

-- LOD (Level of Detail) Configuration
local LOD_CONFIG = {
	DISTANCE_LOW = 100,          -- > 100 studs: LOW detail (simple movement)
	DISTANCE_MEDIUM = 50,        -- 50-100 studs: MEDIUM detail (basic pathfinding)
	-- < 50 studs: HIGH detail (full AI with surround system)
	LOW_COOLDOWN_MULTIPLIER = 3, -- LOW LOD updates 3x slower
	LOW_BASE_NEAR_DISTANCE = 20, -- Distance at which LOW LOD zombies can still attack base
}

-- Small helper to avoid nil indexing and keep calls compact
local function clampNonNegative(x)
	if x < 0 then return 0 end
	return x
end

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

	-- Base repath interval (before jitter / aura)
	self._baseRepathInterval = self.stats.RetargetInterval or GameConfig.ZOMBIE_REPATH_INTERVAL or 0.4

	-- Jitter for performance and desync (stored so aura updates preserve it)
	local minJitter = (GameConfig.AI and GameConfig.AI.DEFAULT_UPDATE_JITTER) or 0.1
	local maxJitter = (GameConfig.AI and GameConfig.AI.MAX_UPDATE_JITTER) or 0.3
	if maxJitter < minJitter then
		local temp = minJitter
		minJitter = maxJitter
		maxJitter = temp
	end
	self._repathJitter = (math.random() * (maxJitter - minJitter)) + minJitter
	self.repathInterval = self._baseRepathInterval + self._repathJitter

	self.currentTarget = nil -- Last known target position (Vector3)
	self.currentTargetType = nil -- "player" or "base" or "wander"
	self.currentTargetPlayer = nil -- Player reference if targeting player
	self.currentSlot = nil -- Current surround slot position
	self.lastMoveTarget = nil -- Track last move command for continuity

	-- Movement continuity thresholds from config
	self.waypointSkipDistance = (GameConfig.AI and GameConfig.AI.WAYPOINT_SKIP_DISTANCE) or 3
	self.movementReissueDistance = (GameConfig.AI and GameConfig.AI.MOVEMENT_REISSUE_DISTANCE) or 0.5

	-- MoveTo rate limiting (prevents spam + state churn)
	self._lastMoveIssueT = 0
	self._minMoveIssueInterval = (GameConfig.AI and GameConfig.AI.MIN_MOVETO_REISSUE_INTERVAL) or 0.15

	-- LOD throttling (avoid per-frame all-player scanning)
	self._lod = "HIGH"
	self._lodCooldown = 0
	self._lodInterval = (GameConfig.AI and GameConfig.AI.LOD_CHECK_INTERVAL) or 0.4

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
	self.aiBehavior = self.stats.AIBehavior or "standard"
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
		self.spitterController = SpitterController.new(zombieModel, self.stats, baseManager, playerManager)
	end

	-- Basic speed from stats if provided
	if self.stats.Speed or self.stats.speed then
		self.humanoid.WalkSpeed = self.stats.Speed or self.stats.speed
	end

	-- Register with boss aura if this is a boss
	if self.stats.HasAura and bossAuraService then
		bossAuraService:registerBoss(zombieModel)
	end

	return self
end

-- Safe MoveTo wrapper (rate-limited)
function ZombieBrain:_moveTo(dest)
	if not dest or not self.humanoid then return end

	local now = tick()
	if now - (self._lastMoveIssueT or 0) < (self._minMoveIssueInterval or 0) then
		return
	end

	self._lastMoveIssueT = now
	self.humanoid:MoveTo(dest)
	self.lastMoveTarget = dest
end

-- Start method for tests (safe to call even if dependencies aren't fully present)
function ZombieBrain:start()
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

	local attackAnim = self.zombieModel:FindFirstChild("AttackAnimation", true)
	if attackAnim and attackAnim:IsA("Animation") then
		self.attackAnimationTrack = animator:LoadAnimation(attackAnim)
	end
end

function ZombieBrain:playAttackAnimation()
	if self.attackAnimationTrack then
		self.attackAnimationTrack:Play()
	end
end

-- Determine Level of Detail based on distance to nearest player
function ZombieBrain:determineLOD()
	if not self.rootPart then
		return "HIGH"
	end

	local closestPlayerDistance = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local distance = (hrp.Position - self.rootPart.Position).Magnitude
				if distance < closestPlayerDistance then
					closestPlayerDistance = distance
				end
			end
		end
	end

	if closestPlayerDistance == math.huge then
		return "HIGH"
	end

	if closestPlayerDistance > LOD_CONFIG.DISTANCE_LOW then
		return "LOW"
	elseif closestPlayerDistance > LOD_CONFIG.DISTANCE_MEDIUM then
		return "MEDIUM"
	else
		return "HIGH"
	end
end

function ZombieBrain:getNearbyZombies()
	local nearby = {}
	local zombiesFolder = workspace:FindFirstChild("Zombies")

	if zombiesFolder then
		for _, zombie in ipairs(zombiesFolder:GetChildren()) do
			if zombie ~= self.zombieModel and zombie:IsA("Model") then
				-- Avoid GetPivot() allocations if HRP exists
				local zhrp = zombie:FindFirstChild("HumanoidRootPart")
				local zpos = zhrp and zhrp.Position or zombie:GetPivot().Position
				local distance = (zpos - self.rootPart.Position).Magnitude
				if distance < 15 then
					table.insert(nearby, zombie)
				end
			end
		end
	end

	return nearby
end

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

function ZombieBrain:selectBestTarget()
	if not self.targetingService then
		return nil, nil, nil
	end

	local targetPos, targetType, targetPlayer = self.targetingService:selectBestTarget(
		self.zombieModel,
		self.rootPart.Position,
		self.waveNumber
	)

	if not targetPos or not targetType then
		-- Wander fallback (keep this warn, but it's noisy; switch to print if you want)
		warn("[ZombieBrain] No valid targets available. Zombie will wander.")

		local lastPos = self.currentTarget or self.rootPart.Position
		local randomOffset = Vector3.new(math.random(-30, 30), 0, math.random(-30, 30))
		local wanderPos = lastPos + randomOffset

		return wanderPos, "wander", nil
	end

	return targetPos, targetType, targetPlayer
end

function ZombieBrain:getSlotPosition(targetPos, targetId)
	if not self.surroundService then
		return targetPos
	end

	if self.surroundService:shouldRerollSlot(self.zombieModel, self.rootPart.Position) then
		self.surroundService:releaseSlot(self.zombieModel)
		self.currentSlot = nil
	end

	if not self.currentSlot then
		local slotPreference = self.stats.SlotPreference or "middle"
		local sidePreference = nil

		if self.stats.PreferBackSlots then
			sidePreference = "back"
		elseif self.stats.FlankChance then
			local flankChance = self.stats.FlankChance

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

function ZombieBrain:handleScreamerBehavior()
	if self.aiBehavior ~= "screamer" then
		return
	end

	local callCooldown = self.stats.CallCooldown or 10.0
	local currentTime = tick()

	if currentTime - self.lastCallTime >= callCooldown then
		self.lastCallTime = currentTime

		local callRadius = self.stats.CallRadius or 30
		local callDuration = self.stats.CallDuration or 5.0

		local zombiesFolder = workspace:FindFirstChild("Zombies")
		if zombiesFolder then
			for _, zombie in ipairs(zombiesFolder:GetChildren()) do
				if zombie ~= self.zombieModel and zombie:IsA("Model") then
					local zpos = zombie:GetPivot().Position
					local distance = (zpos - self.rootPart.Position).Magnitude
					if distance <= callRadius then
						zombie:SetAttribute("ScreamerBuffed", true)
						zombie:SetAttribute("ScreamerBuffExpire", currentTime + callDuration)
					end
				end
			end
		end

		print("[ZombieBrain] Screamer called! Buffing nearby zombies")
	end
end

function ZombieBrain:tryAttack()
	if not self.rootPart or self.attackCooldown > 0 then
		return false
	end

	local targetPos, targetType, targetPlayer = self.currentTarget, self.currentTargetType, self.currentTargetPlayer
	if not targetPos then
		return false
	end

	local distance = (targetPos - self.rootPart.Position).Magnitude
	if distance <= self.attackRange then
		self.attackCooldown = self.attackInterval
		self:playAttackAnimation()

		local damage = self.attackDamage

		if targetType == "player" and targetPlayer then
			if targetPlayer.Character and targetPlayer.Character.Parent then
				local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
				if targetHumanoid and targetHumanoid.Health > 0 then
					-- Allow 0 multipliers (use ~= nil)
					if self.aiBehavior == "breacher" and self.stats.PlayerDamagePenalty ~= nil then
						damage = damage * self.stats.PlayerDamagePenalty
					end

					if self.playerManager then
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
			if (self.aiBehavior == "bruiser" or self.aiBehavior == "breacher") and self.stats.BaseDamageBonus ~= nil then
				damage = damage * self.stats.BaseDamageBonus
			end

			if self.baseManager then
				-- FIX: self.model was nil; use self.zombieModel safely
				local zombieName = (self.zombieModel and self.zombieModel.Name) or "Unknown Zombie"
				self.baseManager:damageBase(damage, zombieName)
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

		-- Adjust retarget interval based on aura (preserve this zombie's jitter)
		if self.zombieModel:GetAttribute("InBossAura") and self.bossAuraService.getRetargetInterval then
			local auraBase = self._baseRepathInterval or (self.stats.RetargetInterval or GameConfig.ZOMBIE_REPATH_INTERVAL or 0.4)
			local auraInterval = self.bossAuraService:getRetargetInterval(self.zombieModel, auraBase)
			self.repathInterval = auraInterval + (self._repathJitter or 0)
		end
	end

	-- Throttled LOD calc (avoid per-frame all-player scan)
	self._lodCooldown -= deltaTime
	if self._lodCooldown <= 0 then
		self._lodCooldown = self._lodInterval
		self._lod = self:determineLOD()
	end
	local lod = self._lod

	-- LOW LOD: Skip most AI updates for distant zombies
	if lod == "LOW" then
		local basePos = self:getBasePosition()
		local isNearBase = false

		if basePos and self.rootPart then
			local distanceToBase = (self.rootPart.Position - basePos).Magnitude
			if distanceToBase <= LOD_CONFIG.LOW_BASE_NEAR_DISTANCE then
				isNearBase = true
			end
		end

		if not isNearBase then
			if self.moveCooldown <= 0 then
				self.moveCooldown = self.repathInterval * LOD_CONFIG.LOW_COOLDOWN_MULTIPLIER
				if basePos then
					self:_moveTo(basePos)
				end
			else
				self.moveCooldown -= deltaTime
			end
			return
		end
	end

	local useMediumLOD = (lod == "MEDIUM")

	-- LOS cache cleanup
	if tick() - self.losCacheTime > self.losCacheLifetime then
		self.losCache = {}
		self.losCacheTime = tick()
	end

	-- Update attack cooldown
	if self.attackCooldown > 0 then
		self.attackCooldown = clampNonNegative(self.attackCooldown - deltaTime)
	end

	-- High-only behaviors
	if not useMediumLOD then
		self:handleScreamerBehavior()
	end

	-- Spitter behavior (ranged) - skip for MEDIUM LOD
	if self.spitterController and not useMediumLOD then
		local targetPos, targetType, targetPlayer = self:selectBestTarget()
		if targetPos then
			local desiredPos = self.spitterController:update(deltaTime, targetPos, targetType, targetPlayer)
			if desiredPos and typeof(desiredPos) == "Vector3" then
				self:_moveTo(desiredPos)
			end
		end
		return
	end

	-- Try attack if in range
	self:tryAttack()

	-- Decrement movement cooldown (but do not block movement)
	self.moveCooldown -= deltaTime
	local shouldRecalculatePath = (self.moveCooldown <= 0)

	if shouldRecalculatePath then
		-- Reset cooldown with small micro variance
		local microBase = ((GameConfig.AI and GameConfig.AI.DEFAULT_UPDATE_JITTER) or 0.1) * 0.5
		local jitterOffset = math.random() * microBase
		self.moveCooldown = self.repathInterval + jitterOffset

		if self.rootPart then
			local targetPos, targetType, targetPlayer = self:selectBestTarget()

			if targetPos then
				self.currentTarget = targetPos
				self.currentTargetType = targetType
				self.currentTargetPlayer = targetPlayer

				local finalTarget = targetPos

				if not useMediumLOD then
					local targetId = (targetType == "base") and "base" or ((targetPlayer and targetPlayer.UserId) or "unknown")
					local slotPos = self:getSlotPosition(targetPos, targetId)

					if slotPos then
						finalTarget = slotPos

						if self.surroundService then
							local nearbyZombies = self:getNearbyZombies()
							local steeringTarget = self.surroundService:getSteeringTarget(
								self.zombieModel,
								self.rootPart.Position,
								slotPos,
								nearbyZombies
							)
							if steeringTarget then
								finalTarget = steeringTarget
							end
						end
					end
				end

				if finalTarget then
					self:_moveTo(finalTarget)
				end
			end
		end
	else
		-- Movement continuity during cooldown
		if self.lastMoveTarget and self.rootPart then
			local distanceToLastTarget = (self.lastMoveTarget - self.rootPart.Position).Magnitude

			if distanceToLastTarget < self.waypointSkipDistance and self.currentTarget then
				self:_moveTo(self.currentTarget)
			elseif distanceToLastTarget > self.movementReissueDistance then
				self:_moveTo(self.lastMoveTarget)
			end
		elseif self.currentTarget then
			self:_moveTo(self.currentTarget)
		end
	end
end

function ZombieBrain:destroy()
	if self._destroying then return end
	self._destroying = true

	self.isActive = false

	if self.surroundService then
		self.surroundService:releaseSlot(self.zombieModel)
	end

	if self.targetingService then
		self.targetingService:releaseAssignment(self.zombieModel)
	end

	if self.stats.HasAura and self.bossAuraService then
		self.bossAuraService:unregisterBoss(self.zombieModel)
	end

	if self.attackAnimationTrack then
		self.attackAnimationTrack:Stop()
		self.attackAnimationTrack = nil
	end

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
