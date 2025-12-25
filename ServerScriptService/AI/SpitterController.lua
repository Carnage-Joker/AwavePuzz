-- SpitterController.lua
-- Specialized controller for Spitter zombies with ranged attacks and cover usage

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local SpitterController = {}
SpitterController.__index = SpitterController

-- Configuration
local CONFIG = {
	MIN_RANGE = 15, -- Minimum distance to maintain from target
	IDEAL_RANGE = 25, -- Ideal distance for attacking
	MAX_RANGE = 40, -- Maximum attack range
	ATTACK_COOLDOWN = 3.0, -- Seconds between acid spit attacks
	PROJECTILE_SPEED = 50, -- Speed of acid projectile
	PROJECTILE_DAMAGE = 6, -- Damage per acid spit
	TELEGRAPH_TIME = 0.5, -- Warning time before firing
	COVER_CHECK_INTERVAL = 2.0, -- How often to seek cover
	COVER_SEARCH_RADIUS = 20, -- How far to look for cover
	COVER_MIN_SIZE = 3, -- Minimum size of cover object
	FLANK_PREFERENCE = 0.7, -- Chance to prefer flank slots
}

function SpitterController.new(zombieModel, stats, baseManager, playerManager)
	local self = setmetatable({}, SpitterController)
	
	self.zombieModel = zombieModel
	self.humanoid = zombieModel:FindFirstChildOfClass("Humanoid")
	self.rootPart = zombieModel:FindFirstChild("HumanoidRootPart")
	self.stats = stats
	self.baseManager = baseManager
	self.playerManager = playerManager
	
	self.attackCooldown = 0
	self.telegraphCooldown = 0
	self.isTelegraphing = false
	self.coverCheckCooldown = 0
	self.currentCover = nil
	self.inCover = false
	
	return self
end

-- Check if spitter has line of sight to target
function SpitterController:hasLineOfSight(targetPos)
	if not self.rootPart then
		return false
	end
	
	local origin = self.rootPart.Position + Vector3.new(0, 2, 0)
	local direction = (targetPos - origin)
	local distance = direction.Magnitude
	
	if distance > CONFIG.MAX_RANGE then
		return false
	end
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {self.zombieModel}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local result = workspace:Raycast(origin, direction, raycastParams)
	
	-- No obstacle = clear LOS
	if not result then
		return true
	end
	
	-- Check if hit target or something beyond target
	local hitDistance = (result.Position - origin).Magnitude
	return hitDistance >= distance * 0.9 -- Allow some tolerance
end

-- Find nearby cover points
function SpitterController:findCover()
	if not self.rootPart then
		return nil
	end
	
	local myPos = self.rootPart.Position
	local searchSize = Vector3.new(CONFIG.COVER_SEARCH_RADIUS, 10, CONFIG.COVER_SEARCH_RADIUS)
	
	-- Use GetPartBoundsInBox instead of deprecated Region3
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = {self.zombieModel}
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local partsInRegion = workspace:GetPartBoundsInBox(CFrame.new(myPos), searchSize, overlapParams)
	
	local coverCandidates = {}
	for _, part in ipairs(partsInRegion) do
		-- Look for solid objects large enough to be cover
		if part:IsA("BasePart") and part.CanCollide then
			local size = part.Size
			if size.X >= CONFIG.COVER_MIN_SIZE or size.Z >= CONFIG.COVER_MIN_SIZE then
				-- Check if this blocks LOS to a position
				table.insert(coverCandidates, part)
			end
		end
	end
	
	-- Return random cover point
	if #coverCandidates > 0 then
		return coverCandidates[math.random(1, #coverCandidates)]
	end
	
	return nil
end

-- Get position near cover
function SpitterController:getCoverPosition(coverPart)
	if not coverPart then
		return nil
	end
	
	-- Position behind cover relative to target
	local coverPos = coverPart.Position
	local offset = Vector3.new(
		math.random(-3, 3),
		0,
		math.random(-3, 3)
	)
	
	return coverPos + offset
end

-- Check if should seek cover
function SpitterController:shouldSeekCover(targetPos)
	if not self.rootPart then
		return false
	end
	
	-- If already in cover, stay there
	if self.inCover then
		return false
	end
	
	-- Check LOS - if target can see us, seek cover
	local hasLOS = self:hasLineOfSight(targetPos)
	if hasLOS then
		-- Roll for cover seeking
		return math.random() < 0.4 -- 40% chance to seek cover when exposed
	end
	
	return false
end

-- Create and fire acid projectile
function SpitterController:fireAcidSpit(targetPos)
	if not self.rootPart then
		return
	end
	
	local origin = self.rootPart.Position + Vector3.new(0, 2, 0)
	local direction = (targetPos - origin).Unit
	
	-- Create acid projectile
	local projectile = Instance.new("Part")
	projectile.Name = "AcidSpit"
	projectile.Size = Vector3.new(1, 1, 1)
	projectile.Shape = Enum.PartType.Ball
	projectile.Color = Color3.fromRGB(100, 255, 100)
	projectile.Material = Enum.Material.Neon
	projectile.CanCollide = false
	projectile.Anchored = false
	projectile.Position = origin
	projectile.Parent = workspace
	
	-- Add velocity
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = direction * CONFIG.PROJECTILE_SPEED
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Parent = projectile
	
	-- Store damage info
	projectile:SetAttribute("Damage", CONFIG.PROJECTILE_DAMAGE)
	projectile:SetAttribute("IsZombieProjectile", true)
	
	-- Handle collision
	local hitConnection
	hitConnection = projectile.Touched:Connect(function(hit)
		if hit:IsDescendantOf(self.zombieModel) then
			return -- Don't hit self
		end
		
		-- Check if hit player
		local character = hit.Parent
		if character and character:FindFirstChildOfClass("Humanoid") then
			local player = game.Players:GetPlayerFromCharacter(character)
			if player and self.playerManager then
				self.playerManager:damagePlayer(player, CONFIG.PROJECTILE_DAMAGE)
			end
		end
		
		-- Check if hit base
		if hit.Name == "HitBox" or hit.Parent.Name == "BaseCaptureZone" then
			if self.baseManager then
				self.baseManager:damageBase(CONFIG.PROJECTILE_DAMAGE)
			end
		end
		
		-- Create splash effect
		local splash = Instance.new("Part")
		splash.Size = Vector3.new(3, 0.5, 3)
		splash.Transparency = 0.5
		splash.Color = Color3.fromRGB(100, 255, 100)
		splash.Material = Enum.Material.Neon
		splash.CanCollide = false
		splash.Anchored = true
		splash.Position = projectile.Position
		splash.Parent = workspace
		Debris:AddItem(splash, 0.5)
		
		-- Destroy projectile
		hitConnection:Disconnect()
		projectile:Destroy()
	end)
	
	-- Auto-destroy after 3 seconds
	Debris:AddItem(projectile, 3)
	
	print("[SpitterController] Fired acid spit at", targetPos)
end

-- Telegraph attack (visual warning)
function SpitterController:telegraphAttack()
	if not self.rootPart then
		return
	end
	
	-- Create telegraph indicator
	local indicator = Instance.new("Part")
	indicator.Name = "AttackTelegraph"
	indicator.Size = Vector3.new(2, 4, 2)
	indicator.Transparency = 0.5
	indicator.Color = Color3.fromRGB(255, 200, 0)
	indicator.Material = Enum.Material.Neon
	indicator.CanCollide = false
	indicator.Anchored = true
	indicator.Position = self.rootPart.Position + Vector3.new(0, 3, 0)
	indicator.Parent = self.zombieModel
	
	Debris:AddItem(indicator, CONFIG.TELEGRAPH_TIME)
	
	self.isTelegraphing = true
	self.telegraphCooldown = CONFIG.TELEGRAPH_TIME
end

-- Try to attack target
function SpitterController:tryAttack(targetPos, targetType, targetPlayer)
	if not self.rootPart then
		return false
	end
	
	if self.attackCooldown > 0 or self.telegraphCooldown > 0 then
		return false
	end
	
	local distance = (targetPos - self.rootPart.Position).Magnitude
	
	-- Check if in attack range
	if distance >= CONFIG.MIN_RANGE and distance <= CONFIG.MAX_RANGE then
		-- Check LOS
		if self:hasLineOfSight(targetPos) then
			-- Telegraph attack
			self:telegraphAttack()
			self.attackCooldown = CONFIG.ATTACK_COOLDOWN
			
			-- Store reference for safe callback
			local zombieModel = self.zombieModel
			local rootPart = self.rootPart
			
			-- Fire after telegraph with validation
			task.delay(CONFIG.TELEGRAPH_TIME, function()
				-- Validate objects still exist before firing
				if zombieModel and zombieModel.Parent and rootPart and rootPart.Parent then
					self:fireAcidSpit(targetPos)
					self.isTelegraphing = false
				end
			end)
			
			return true
		end
	end
	
	return false
end

-- Get desired position (maintain range, use cover)
function SpitterController:getDesiredPosition(targetPos)
	if not self.rootPart then
		return targetPos
	end
	
	local myPos = self.rootPart.Position
	local distance = (targetPos - myPos).Magnitude
	
	-- If too close, back away
	if distance < CONFIG.MIN_RANGE then
		local direction = (myPos - targetPos).Unit
		return myPos + (direction * 5)
	end
	
	-- If too far, move closer (but not too close)
	if distance > CONFIG.MAX_RANGE then
		local direction = (targetPos - myPos).Unit
		return myPos + (direction * 5)
	end
	
	-- Check if should seek cover
	if self.coverCheckCooldown <= 0 then
		self.coverCheckCooldown = CONFIG.COVER_CHECK_INTERVAL
		
		if self:shouldSeekCover(targetPos) then
			local cover = self:findCover()
			if cover then
				self.currentCover = cover
				self.inCover = true
				return self:getCoverPosition(cover)
			end
		end
	end
	
	-- Stay at current position (ideal range)
	return myPos
end

-- Update controller
function SpitterController:update(deltaTime, targetPos, targetType, targetPlayer)
	if not self.zombieModel or not self.zombieModel.Parent then
		return nil
	end
	
	-- Update cooldowns
	if self.attackCooldown > 0 then
		self.attackCooldown = math.max(0, self.attackCooldown - deltaTime)
	end
	
	if self.telegraphCooldown > 0 then
		self.telegraphCooldown = math.max(0, self.telegraphCooldown - deltaTime)
	end
	
	if self.coverCheckCooldown > 0 then
		self.coverCheckCooldown = math.max(0, self.coverCheckCooldown - deltaTime)
	end
	
	if not targetPos then
		return nil
	end
	
	-- Try to attack if possible
	self:tryAttack(targetPos, targetType, targetPlayer)
	
	-- Get desired position (maintains range, uses cover)
	local desiredPos = self:getDesiredPosition(targetPos)
	
	return desiredPos
end

-- Cleanup
function SpitterController:destroy()
	self.zombieModel = nil
	self.humanoid = nil
	self.rootPart = nil
	self.currentCover = nil
end

return SpitterController
