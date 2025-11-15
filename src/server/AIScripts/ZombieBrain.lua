-- ZombieBrain.lua
-- AI script for zombie pathfinding and attacking behavior
-- This script should be placed in each zombie model

local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local ZombieBrain = {}
ZombieBrain.__index = ZombieBrain

function ZombieBrain.new(zombie, stats)
	local self = setmetatable({}, ZombieBrain)
	
	self.zombie = zombie
	self.humanoid = zombie:FindFirstChild("Humanoid")
	self.rootPart = zombie:FindFirstChild("HumanoidRootPart")
	
	if not self.humanoid or not self.rootPart then
		warn("Zombie missing Humanoid or HumanoidRootPart!")
		return nil
	end
	
	-- Stats
	self.speed = stats.Speed or 10
	self.damage = stats.Damage or 10
	self.maxHealth = stats.Health or 60
	
	-- Setup humanoid
	self.humanoid.MaxHealth = self.maxHealth
	self.humanoid.Health = self.maxHealth
	self.humanoid.WalkSpeed = self.speed
	
	-- Target tracking
	self.currentTarget = nil
	self.targetType = nil -- "player" or "base"
	
	-- Pathfinding
	self.path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		WaypointSpacing = 4,
		Costs = {
			Water = math.huge, -- Avoid water
		}
	})
	
	self.waypoints = {}
	self.currentWaypointIndex = 1
	self.pathfindingCooldown = 0
	self.pathfindingInterval = 1 -- Recalculate path every second
	
	-- Attack
	self.attackCooldown = 0
	self.attackInterval = 1.5 -- Attack every 1.5 seconds
	self.attackRange = 6
	
	-- State
	self.isActive = true
	
	return self
end

function ZombieBrain:findTarget()
	-- Priority 1: Find nearest player
	local nearestPlayer = nil
	local nearestDistance = math.huge
	
	local players = game.Players:GetPlayers()
	for _, player in ipairs(players) do
		if player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
			
			if humanoid and humanoid.Health > 0 and rootPart then
				local distance = (self.rootPart.Position - rootPart.Position).Magnitude
				if distance < nearestDistance then
					nearestDistance = distance
					nearestPlayer = player.Character
				end
			end
		end
	end
	
	if nearestPlayer then
		self.currentTarget = nearestPlayer
		self.targetType = "player"
		return true
	end
	
	-- Priority 2: Attack the base
	local base = workspace:FindFirstChild("Base")
	if base then
		local baseTarget = base:FindFirstChild("CaptureZone") or base:FindFirstChild("Core") or base
		self.currentTarget = baseTarget
		self.targetType = "base"
		return true
	end
	
	return false
end

function ZombieBrain:computePath()
	if not self.currentTarget then
		return false
	end
	
	local targetPosition
	if self.targetType == "player" then
		local targetRoot = self.currentTarget:FindFirstChild("HumanoidRootPart")
		if not targetRoot then
			return false
		end
		targetPosition = targetRoot.Position
	else
		targetPosition = self.currentTarget.Position
	end
	
	local success, errorMessage = pcall(function()
		self.path:ComputeAsync(self.rootPart.Position, targetPosition)
	end)
	
	if success and self.path.Status == Enum.PathStatus.Success then
		self.waypoints = self.path:GetWaypoints()
		self.currentWaypointIndex = 1
		return true
	else
		warn("Path computation failed:", errorMessage)
		return false
	end
end

function ZombieBrain:followPath()
	if not self.waypoints or #self.waypoints == 0 then
		return
	end
	
	if self.currentWaypointIndex > #self.waypoints then
		-- Reached end of path, recompute
		self.pathfindingCooldown = 0
		return
	end
	
	local waypoint = self.waypoints[self.currentWaypointIndex]
	
	-- Move to waypoint
	self.humanoid:MoveTo(waypoint.Position)
	
	-- Check if reached waypoint
	local distance = (self.rootPart.Position - waypoint.Position).Magnitude
	if distance < 4 then
		self.currentWaypointIndex = self.currentWaypointIndex + 1
		
		-- Handle jump
		if waypoint.Action == Enum.PathWaypointAction.Jump then
			self.humanoid.Jump = true
		end
	end
end

function ZombieBrain:tryAttack(deltaTime)
	if not self.currentTarget then
		return
	end
	
	-- Update attack cooldown
	self.attackCooldown = self.attackCooldown - deltaTime
	if self.attackCooldown > 0 then
		return
	end
	
	-- Check distance to target
	local targetPosition
	if self.targetType == "player" then
		local targetRoot = self.currentTarget:FindFirstChild("HumanoidRootPart")
		if not targetRoot then
			return
		end
		targetPosition = targetRoot.Position
	else
		targetPosition = self.currentTarget.Position
	end
	
	local distance = (self.rootPart.Position - targetPosition).Magnitude
	
	if distance <= self.attackRange then
		-- In range, perform attack
		self:performAttack()
		self.attackCooldown = self.attackInterval
	end
end

function ZombieBrain:performAttack()
	if not self.currentTarget then
		return
	end
	
	if self.targetType == "player" then
		-- Damage player
		local humanoid = self.currentTarget:FindFirstChild("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid:TakeDamage(self.damage)
		end
	elseif self.targetType == "base" then
		-- Damage base (through RemoteEvent or direct if in server script)
		local baseHealthValue = self.currentTarget:FindFirstChild("Health")
		if baseHealthValue and baseHealthValue:IsA("NumberValue") then
			baseHealthValue.Value = math.max(0, baseHealthValue.Value - self.damage)
		end
	end
	
	-- Play attack animation if available
	-- TODO: Add attack animation here
end

function ZombieBrain:update(deltaTime)
	if not self.isActive then
		return
	end
	
	if not self.humanoid or self.humanoid.Health <= 0 then
		self:destroy()
		return
	end
	
	-- Update pathfinding cooldown
	self.pathfindingCooldown = self.pathfindingCooldown - deltaTime
	
	-- Find or update target
	if not self.currentTarget or self.pathfindingCooldown <= 0 then
		if self:findTarget() then
			self:computePath()
			self.pathfindingCooldown = self.pathfindingInterval
		end
	end
	
	-- Follow path
	self:followPath()
	
	-- Try to attack
	self:tryAttack(deltaTime)
end

function ZombieBrain:destroy()
	self.isActive = false
	
	-- Clean up
	if self.zombie then
		-- Give reward to players
		-- TODO: Implement reward distribution
		
		-- Remove zombie after short delay
		task.wait(2)
		if self.zombie and self.zombie.Parent then
			self.zombie:Destroy()
		end
	end
end

return ZombieBrain
