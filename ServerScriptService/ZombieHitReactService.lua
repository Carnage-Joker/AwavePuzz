-- @ScriptType: ModuleScript

-- ZombieHitReactService.lua
-- Server-side zombie hit reaction system
-- Applies physical impulses and stability-based stagger to zombies when shot
-- Maintains per-zombie state for cooldowns and stability meter
-- Designed for 50+ active humanoid-based R15 zombies with server authority

-- ============================================================================
-- DEBUG CONFIGURATION
-- ============================================================================
local DEBUG = false  -- Set to true to enable detailed logging

-- ============================================================================
-- TUNING CONSTANTS
-- ============================================================================
-- Physics
local IMPULSE_COOLDOWN = 0.12          -- Seconds between impulse applications per zombie
local BASE_IMPULSE = 45                -- Base impulse magnitude
local UPWARD_IMPULSE = 8               -- Upward component of impulse

-- Stability System
local STABILITY_MAX = 100              -- Maximum stability value
local STABILITY_REGEN_PER_SEC = 18     -- Stability regeneration per second
local STAGGER_COOLDOWN = 0.35          -- Seconds between staggers per zombie
local STAGGER_DURATION_MIN = 0.25      -- Minimum stagger stun duration
local STAGGER_DURATION_MAX = 0.35      -- Maximum stagger stun duration
local STAGGER_STABILITY_RESTORE = 0.55 -- Restore stability to 55% of max after stagger

-- Limb Multipliers
local HEAD_STABILITY_MULT = 1.6        -- Head shots reduce stability more
local LEG_STABILITY_MULT = 1.1         -- Leg shots reduce stability slightly more
local LEG_SLOW_DURATION = 0.9          -- Duration of leg slow effect
local LEG_SLOW_SPEED = 0.6             -- Speed multiplier for leg hits (60% of normal)

-- Stagger Impulse (stronger than normal impulse)
local STAGGER_IMPULSE_MULT = 2.0       -- Multiplier for stagger impulse

-- ============================================================================
-- DEPENDENCIES
-- ============================================================================
local RunService = game:GetService("RunService")

local ZombieHitReactService = {}
ZombieHitReactService.__index = ZombieHitReactService

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
function ZombieHitReactService.new()
	local self = setmetatable({}, ZombieHitReactService)
	
	-- Per-zombie state tracking
	self.zombieStates = {}  -- [zombieModel] = { lastImpulseTime, stability, lastStaggerTime, originalSpeed, ... }
	
	-- Heartbeat connection for stability regeneration
	self.heartbeatConnection = nil
	
	-- Start stability regeneration loop
	self:startStabilityRegeneration()
	
	if DEBUG then
		print("[ZombieHitReactService] Initialized with tuning:")
		print("  IMPULSE_COOLDOWN:", IMPULSE_COOLDOWN)
		print("  STAGGER_COOLDOWN:", STAGGER_COOLDOWN)
		print("  STABILITY_MAX:", STABILITY_MAX)
		print("  STABILITY_REGEN_PER_SEC:", STABILITY_REGEN_PER_SEC)
	end
	
	return self
end

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================
function ZombieHitReactService:getOrCreateState(zombieModel)
	if not self.zombieStates[zombieModel] then
		local humanoid = zombieModel:FindFirstChild("Humanoid")
		
		self.zombieStates[zombieModel] = {
			lastImpulseTime = 0,
			stability = STABILITY_MAX,
			lastStaggerTime = 0,
			isStaggered = false,
			legSlowEndTime = 0,
			preEffectSpeed = nil,  -- Stored per-effect to preserve other speed modifiers
		}
		
		-- Clean up state when zombie is destroyed
		local ancestryConnection
		ancestryConnection = zombieModel.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				self:cleanupZombie(zombieModel)
				if ancestryConnection then
					ancestryConnection:Disconnect()
				end
			end
		end)
		
		-- Clean up state when zombie dies
		local diedConnection
		if humanoid then
			diedConnection = humanoid.Died:Connect(function()
				self:cleanupZombie(zombieModel)
				if diedConnection then
					diedConnection:Disconnect()
				end
				if ancestryConnection then
					ancestryConnection:Disconnect()
				end
			end)
		end
		
		if DEBUG then
			print(string.format("[ZombieHitReactService] Created state for %s", zombieModel.Name))
		end
	end
	
	return self.zombieStates[zombieModel]
end

function ZombieHitReactService:cleanupZombie(zombieModel)
	if self.zombieStates[zombieModel] then
		if DEBUG then
			print(string.format("[ZombieHitReactService] Cleaning up state for %s", zombieModel.Name))
		end
		self.zombieStates[zombieModel] = nil
	end
end

-- ============================================================================
-- STABILITY REGENERATION
-- ============================================================================
function ZombieHitReactService:startStabilityRegeneration()
	if self.heartbeatConnection then
		warn("[ZombieHitReactService] Stability regeneration already running")
		return
	end
	
	self.heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
		for zombieModel, state in pairs(self.zombieStates) do
			-- Check if zombie is dead and clean up
			local humanoid = zombieModel:FindFirstChild("Humanoid")
			if not humanoid or humanoid.Health <= 0 then
				self:cleanupZombie(zombieModel)
			else
				-- Regenerate stability over time (capped at max)
				if state.stability < STABILITY_MAX then
					state.stability = math.min(STABILITY_MAX, state.stability + (STABILITY_REGEN_PER_SEC * deltaTime))
				end
				
				-- Check if leg slow effect has expired
				if state.legSlowEndTime > 0 and tick() >= state.legSlowEndTime then
					self:restoreSpeed(zombieModel, state)
				end
			end
		end
	end)
	
	if DEBUG then
		print("[ZombieHitReactService] Started stability regeneration loop")
	end
end

function ZombieHitReactService:stopStabilityRegeneration()
	if self.heartbeatConnection then
		self.heartbeatConnection:Disconnect()
		self.heartbeatConnection = nil
		if DEBUG then
			print("[ZombieHitReactService] Stopped stability regeneration loop")
		end
	end
end

-- ============================================================================
-- MAIN API: OnBulletHit
-- ============================================================================
--[[
	OnBulletHit: Called when a bullet hits a zombie
	
	Parameters:
	- zombieModel: The zombie model that was hit
	- hitPart: The specific BasePart that was hit (for limb detection)
	- hitPos: Vector3 position where bullet hit
	- rayDirUnit: Unit vector of bullet direction
	- damage: Damage dealt by the bullet (post-multiplier)
	- isHeadshot: Boolean indicating if this was a headshot (optional)
]]
function ZombieHitReactService:OnBulletHit(zombieModel, hitPart, hitPos, rayDirUnit, damage, isHeadshot)
	-- Validate inputs
	if not zombieModel or not hitPart or not hitPos or not rayDirUnit or not damage then
		if DEBUG then
			warn("[ZombieHitReactService] Invalid parameters passed to OnBulletHit")
		end
		return
	end
	
	-- Check if zombie is valid
	local humanoid = zombieModel:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		if DEBUG and humanoid then
			print(string.format("[ZombieHitReactService] Zombie %s is dead (health: %.1f), skipping reaction", 
				zombieModel.Name, humanoid.Health))
		end
		return
	end
	
	-- Get or create state for this zombie
	local state = self:getOrCreateState(zombieModel)
	local currentTime = tick()
	
	-- Apply impulse (with cooldown)
	if (currentTime - state.lastImpulseTime) >= IMPULSE_COOLDOWN then
		self:applyImpulse(zombieModel, rayDirUnit)
		state.lastImpulseTime = currentTime
	end
	
	-- Detect limb type and calculate stability damage
	local limbType = self:detectLimbType(hitPart, isHeadshot)
	local stabilityDamage = self:calculateStabilityDamage(damage, limbType)
	
	-- Reduce stability
	state.stability = math.max(0, state.stability - stabilityDamage)
	
	if DEBUG then
		print(string.format("[ZombieHitReactService] %s hit on %s - Stability: %.1f -> %.1f (damage: %.1f)", 
			limbType, zombieModel.Name, state.stability + stabilityDamage, state.stability, stabilityDamage))
	end
	
	-- Apply limb-specific effects
	if limbType == "leg" then
		self:applyLegSlow(zombieModel, state)
	end
	
	-- Check for stagger
	if state.stability <= 0 and (currentTime - state.lastStaggerTime) >= STAGGER_COOLDOWN then
		self:triggerStagger(zombieModel, state, rayDirUnit)
	end
end

-- ============================================================================
-- IMPULSE APPLICATION
-- ============================================================================
function ZombieHitReactService:applyImpulse(zombieModel, rayDirUnit)
	local root = zombieModel:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	
	-- Calculate impulse magnitude scaled by mass
	local mass = root.AssemblyMass
	local impulseMagnitude = BASE_IMPULSE * mass
	
	-- Add upward component
	local impulseDirection = rayDirUnit + Vector3.new(0, UPWARD_IMPULSE / BASE_IMPULSE, 0)
	impulseDirection = impulseDirection.Unit
	
	-- Apply impulse
	local impulseVector = impulseDirection * impulseMagnitude
	
	local success, err = pcall(function()
		root:ApplyImpulse(impulseVector)
	end)
	
	if not success then
		warn(string.format("[ZombieHitReactService] Failed to apply impulse to %s: %s", 
			zombieModel.Name, tostring(err)))
	elseif DEBUG then
		print(string.format("[ZombieHitReactService] Applied impulse to %s (magnitude: %.1f)", 
			zombieModel.Name, impulseMagnitude))
	end
end

-- ============================================================================
-- LIMB DETECTION AND STABILITY
-- ============================================================================
function ZombieHitReactService:detectLimbType(hitPart, isHeadshot)
	if isHeadshot then
		return "head"
	end
	
	local partName = hitPart.Name:lower()
	
	-- Leg detection
	if partName:find("leg") or partName:find("foot") then
		return "leg"
	end
	
	-- Arm detection
	if partName:find("arm") or partName:find("hand") then
		return "arm"
	end
	
	-- Default to body
	return "body"
end

function ZombieHitReactService:calculateStabilityDamage(damage, limbType)
	local baseDamage = damage
	
	if limbType == "head" then
		return baseDamage * HEAD_STABILITY_MULT
	elseif limbType == "leg" then
		return baseDamage * LEG_STABILITY_MULT
	else
		return baseDamage
	end
end

-- ============================================================================
-- LEG SLOW EFFECT
-- ============================================================================
function ZombieHitReactService:applyLegSlow(zombieModel, state)
	local humanoid = zombieModel:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end
	
	-- Apply slow if not already staggered
	if not state.isStaggered then
		-- Capture current speed as pre-effect speed to preserve other modifiers
		state.preEffectSpeed = humanoid.WalkSpeed
		
		local targetSpeed = humanoid.WalkSpeed * LEG_SLOW_SPEED
		humanoid.WalkSpeed = targetSpeed
		state.legSlowEndTime = tick() + LEG_SLOW_DURATION
		
		if DEBUG then
			print(string.format("[ZombieHitReactService] Applied leg slow to %s (%.1f -> %.1f for %.1fs)", 
				zombieModel.Name, state.preEffectSpeed, targetSpeed, LEG_SLOW_DURATION))
		end
	end
end

function ZombieHitReactService:restoreSpeed(zombieModel, state)
	local humanoid = zombieModel:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end
	
	-- Only restore if not staggered and we have a pre-effect speed
	if not state.isStaggered and state.preEffectSpeed then
		humanoid.WalkSpeed = state.preEffectSpeed
		state.legSlowEndTime = 0
		state.preEffectSpeed = nil
		
		if DEBUG then
			print(string.format("[ZombieHitReactService] Restored speed for %s (%.1f)", 
				zombieModel.Name, humanoid.WalkSpeed))
		end
	end
end

-- ============================================================================
-- STAGGER SYSTEM
-- ============================================================================
function ZombieHitReactService:triggerStagger(zombieModel, state, rayDirUnit)
	local humanoid = zombieModel:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end
	
	-- Mark as staggered
	state.isStaggered = true
	state.lastStaggerTime = tick()
	
	-- Capture current speed as pre-effect speed to preserve other modifiers
	state.preEffectSpeed = humanoid.WalkSpeed
	
	-- Apply stronger stagger impulse
	local root = zombieModel:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		local mass = root.AssemblyMass
		local staggerImpulseMagnitude = BASE_IMPULSE * STAGGER_IMPULSE_MULT * mass
		local impulseDirection = rayDirUnit + Vector3.new(0, UPWARD_IMPULSE / BASE_IMPULSE * 1.5, 0)
		impulseDirection = impulseDirection.Unit
		
		local success, err = pcall(function()
			root:ApplyImpulse(impulseDirection * staggerImpulseMagnitude)
		end)
		
		if not success then
			warn(string.format("[ZombieHitReactService] Failed to apply stagger impulse to %s: %s", 
				zombieModel.Name, tostring(err)))
		end
	end
	
	-- Brief stun: WalkSpeed = 0
	humanoid.WalkSpeed = 0
	
	-- Restore speed after stagger duration
	local staggerDuration = math.random(STAGGER_DURATION_MIN * 100, STAGGER_DURATION_MAX * 100) / 100
	
	task.delay(staggerDuration, function()
		if humanoid and humanoid.Health > 0 and state.preEffectSpeed then
			humanoid.WalkSpeed = state.preEffectSpeed
			state.isStaggered = false
			state.legSlowEndTime = 0  -- Clear any leg slow
			state.preEffectSpeed = nil
			
			if DEBUG then
				print(string.format("[ZombieHitReactService] Stagger ended for %s, restored speed to %.1f", 
					zombieModel.Name, humanoid.WalkSpeed))
			end
		end
	end)
	
	-- Restore stability to 55% of max
	state.stability = STABILITY_MAX * STAGGER_STABILITY_RESTORE
	
	if DEBUG then
		print(string.format("[ZombieHitReactService] STAGGER triggered for %s (duration: %.2fs, stability restored to %.1f)", 
			zombieModel.Name, staggerDuration, state.stability))
	end
	
	-- TODO: Play flinch animation on stagger (requires animation assets)
	-- self:playFlinchAnimation(zombieModel)
end

--[[
	playFlinchAnimation: Stub for future animation integration
	
	To implement:
	1. Load flinch animation asset
	2. Get zombie Animator or Humanoid
	3. Play animation track
	4. Handle cleanup
]]
function ZombieHitReactService:playFlinchAnimation(zombieModel)
	-- TODO: Implement when animation assets are available
	if DEBUG then
		print(string.format("[ZombieHitReactService] TODO: Play flinch animation for %s", zombieModel.Name))
	end
end

-- ============================================================================
-- CLEANUP
-- ============================================================================
function ZombieHitReactService:cleanup()
	self:stopStabilityRegeneration()
	self.zombieStates = {}
	
	if DEBUG then
		print("[ZombieHitReactService] Cleaned up all state")
	end
end

return ZombieHitReactService
