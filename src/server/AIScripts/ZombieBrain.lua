-- ZombieBrain.lua
-- AI brain for zombies: walks toward nearest player or base and attacks when in range
-- Improvements:
-- - Attacks players and base (not just walks into them)
-- - Target selection prioritizes nearest threat (player or base)
-- - Attack animations support
-- - Attack cooldown system

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local ZombieBrain = {}
ZombieBrain.__index = ZombieBrain

function ZombieBrain.new(zombieModel, stats, baseManager, playerManager)
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
	
	-- Managers for dealing damage
	self.baseManager = baseManager
	self.playerManager = playerManager

	-- Movement and pathing
	self.moveCooldown = 0
	self.repathInterval = GameConfig.ZOMBIE_REPATH_INTERVAL or 1.0
	self.currentTarget = nil
	self.currentTargetType = nil -- "player" or "base"
	
	-- Cache base reference for performance
	self.cachedBase = nil
	self.baseCacheTime = 0
	self.baseCacheInterval = 5 -- Re-cache base every 5 seconds
	
	-- Attack system
	self.attackCooldown = 0
	self.attackInterval = GameConfig.ZOMBIE_ATTACK_INTERVAL or 1.5
	self.attackRange = GameConfig.ZOMBIE_ATTACK_RANGE or 6
	self.attackDamage = self.stats.Damage or GameConfig.ZOMBIE_DAMAGE or 10
	
	-- Animation support
	self.attackAnimationTrack = nil
	self:loadAttackAnimation()

	-- Basic speed from stats if provided
	if self.stats.Speed or self.stats.speed then
		self.humanoid.WalkSpeed = self.stats.Speed or self.stats.speed
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

-- Get the base position from workspace (with caching)
function ZombieBrain:getBasePosition()
	-- Return cached base if still valid
	if self.cachedBase and self.cachedBase.Parent then
		if self.cachedBase:IsA("Model") then
			return self.cachedBase:GetPivot().Position
		elseif self.cachedBase:IsA("BasePart") then
			return self.cachedBase.Position
		end
	end
	
	-- Cache expired or invalid, find base again
	local base = workspace:FindFirstChild("Base")
	if base then
		self.cachedBase = base
		if base:IsA("Model") then
			return base:GetPivot().Position
		elseif base:IsA("BasePart") then
			return base.Position
		end
	end
	
	self.cachedBase = nil
	return nil
end

local function getNearestPlayerPosition(rootPart)
	local closestDist = math.huge
	local closestPos = nil
	local closestPlayer = nil

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if hrp and humanoid and humanoid.Health > 0 then
				local dist = (hrp.Position - rootPart.Position).Magnitude
				if dist < closestDist then
					closestDist = dist
					closestPos = hrp.Position
					closestPlayer = player
				end
			end
		end
	end

	return closestPos, closestDist, closestPlayer
end

-- Choose between attacking nearest player or the base
function ZombieBrain:selectBestTarget()
	local playerPos, playerDist, player = getNearestPlayerPosition(self.rootPart)
	local basePos = self:getBasePosition()
	
	if not playerPos and not basePos then
		return nil, nil, nil
	end
	
	-- If only one target exists, choose that
	if playerPos and not basePos then
		return playerPos, "player", player
	end
	
	if basePos and not playerPos then
		return basePos, "base", nil
	end
	
	-- Both exist, choose closest
	local baseDist = (basePos - self.rootPart.Position).Magnitude
	if playerDist < baseDist then
		return playerPos, "player", player
	else
		return basePos, "base", nil
	end
end

-- Attempt to attack target if in range
function ZombieBrain:tryAttack()
	if not self.rootPart or self.attackCooldown > 0 then
		return false
	end
	
	local targetPos, targetType, targetPlayer = self:selectBestTarget()
	if not targetPos then
		return false
	end
	
	local distance = (targetPos - self.rootPart.Position).Magnitude
	
	-- Check if in attack range
	if distance <= self.attackRange then
		self.attackCooldown = self.attackInterval
		self:playAttackAnimation()
		
		-- Deal damage to appropriate target
		if targetType == "player" and targetPlayer then
			-- Validate player still exists and has character
			if targetPlayer and targetPlayer.Character then
				local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
				if targetHumanoid and targetHumanoid.Health > 0 then
					if self.playerManager then
						self.playerManager:damagePlayer(targetPlayer, self.attackDamage)
					end
				end
			end
		elseif targetType == "base" then
			if self.baseManager then
				self.baseManager:damageBase(self.attackDamage)
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
	
	-- Update attack cooldown
	if self.attackCooldown > 0 then
		self.attackCooldown = math.max(0, self.attackCooldown - deltaTime)
	end

	-- Try to attack if in range
	local didAttack = self:tryAttack()
	
	-- Update movement cooldown
	self.moveCooldown -= deltaTime
	if self.moveCooldown > 0 then
		return
	end

	self.moveCooldown = self.repathInterval

	-- Select best target (player or base)
	local targetPos, targetType = nil, nil
	if self.rootPart then
		targetPos, targetType = self:selectBestTarget()
	end

	if not targetPos then
		return
	end
	
	-- Store current target info
	self.currentTarget = targetPos
	self.currentTargetType = targetType

	-- Move toward target (Humanoid:MoveTo provides basic pathfinding)
	self.humanoid:MoveTo(targetPos)
end

function ZombieBrain:destroy()
	self.isActive = false
	
	-- Stop and cleanup animation
	if self.attackAnimationTrack then
		self.attackAnimationTrack:Stop()
		self.attackAnimationTrack = nil
	end
	
	self.zombieModel = nil
	self.humanoid = nil
	self.rootPart = nil
	self.baseManager = nil
	self.playerManager = nil
	self.cachedBase = nil
end

return ZombieBrain
