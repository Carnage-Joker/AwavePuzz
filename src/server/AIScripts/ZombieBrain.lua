-- ZombieBrain.lua
-- Simple AI brain for zombies: walks toward nearest player and can be updated each frame

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

local ZombieBrain = {}
ZombieBrain.__index = ZombieBrain

function ZombieBrain.new(zombieModel, stats)
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

	self.moveCooldown = 0
	self.repathInterval = 1.0
	self.currentTarget = nil

	-- Basic speed from stats if provided
	if self.stats.Speed or self.stats.speed then
		self.humanoid.WalkSpeed = self.stats.Speed or self.stats.speed
	end

	return self
end

local function getNearestPlayerPosition(rootPart)
	local closestDist = math.huge
	local closestPos = nil

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
				end
			end
		end
	end

	return closestPos, closestDist
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

	self.moveCooldown -= deltaTime
	if self.moveCooldown > 0 then
		return
	end

	self.moveCooldown = self.repathInterval

	local targetPos = nil
	local _dist = nil

	if self.rootPart then
		targetPos, _dist = getNearestPlayerPosition(self.rootPart)
	end

	if not targetPos then
		return
	end

	-- Simple MoveTo AI (no fancy pathing yet, but can be extended)
	self.humanoid:MoveTo(targetPos)
end

function ZombieBrain:destroy()
	self.isActive = false
	self.zombieModel = nil
	self.humanoid = nil
	self.rootPart = nil
end

return ZombieBrain
