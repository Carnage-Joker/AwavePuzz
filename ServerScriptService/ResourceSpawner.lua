-- @ScriptType: ModuleScript
--[[
    ResourceSpawner.lua (ModuleScript)
    Phase 3: Manages spawning of cure components around the map
    Components appear as pickable objects that players can collect
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not sharedFolder then
	error("[ResourceSpawner] CRITICAL: Failed to load Shared folder after 10 seconds")
end

local GameConfig = require(sharedFolder:WaitForChild("GameConfig", 5))

local ResourceSpawner = {}
ResourceSpawner.__index = ResourceSpawner

local CONFIG = {
	GROUND_CHECK_DISTANCE = 120,
	SPAWN_HEIGHT_OFFSET = 2,
	VALIDATION_RADIUS = 6,
	OPENNESS_RAY_LENGTH = 22,
	OPENNESS_RAYS = 8,
	MIN_DISTANCE_FROM_PLAYERS = 10,
	MIN_DISTANCE_FROM_BASE = 20,
	MAX_ATTEMPTS = 30,
	OUTER_RING_MULTIPLIER = 1.10, -- > 110% of avg zombie ring distance
}

function ResourceSpawner.new()
	local self = setmetatable({}, ResourceSpawner)

	self.cureService = nil
	self.activeResources = {}
	self.spawnTimer = 0
	self.spawnPoints = {}

	-- NEW: optional externally provided zombie spawn points
	self.zombieSpawnPoints = nil

	-- Create resource folder in workspace
	self.resourceFolder = workspace:FindFirstChild("CureResources")
	if not self.resourceFolder then
		self.resourceFolder = Instance.new("Folder")
		self.resourceFolder.Name = "CureResources"
		self.resourceFolder.Parent = workspace
	end

	-- Note: Spawn points must be injected via setSpawnPoints()
	-- No automatic workspace scanning

	print("[ResourceSpawner] Initialized (spawn points must be set via setSpawnPoints)")

	return self
end

-- Initialize method for tests (idempotent, safe to call multiple times)
function ResourceSpawner:initialize()
	if self._initialized then
		return true
	end
	self._initialized = true
	return true
end

-- Start spawning resources (for test compatibility)
function ResourceSpawner:startSpawning()
	-- ResourceSpawner uses update() for spawning logic
	-- This method exists for test interface compatibility
	return true
end

-- Stop spawning resources (for test compatibility)
function ResourceSpawner:stopSpawning()
	-- Clear all active resources to stop spawning
	self:clearAllResources()
	return true
end

function ResourceSpawner:setCureService(cureService)
	self.cureService = cureService
end

-- NEW (non-breaking): spawner can inject combined zombie spawn points
function ResourceSpawner:setZombieSpawnPoints(points)
	if typeof(points) ~= "table" then
		warn("[ResourceSpawner] setZombieSpawnPoints expected table, got", typeof(points))
		self.zombieSpawnPoints = nil
		return
	end
	local copy = {}
	for _, p in ipairs(points) do
		if typeof(p) == "Vector3" then
			table.insert(copy, p)
		end
	end
	self.zombieSpawnPoints = copy
end

function ResourceSpawner:setSpawnPoints(points)
	if typeof(points) ~= "table" then
		warn("[ResourceSpawner] setSpawnPoints expected table, got", typeof(points))
		return
	end

	self.spawnPoints = {}
	local invalidCount = 0
	for _, pos in ipairs(points) do
		if typeof(pos) == "Vector3" then
			table.insert(self.spawnPoints, pos)
		else
			invalidCount = invalidCount + 1
		end
	end

	-- Warn about invalid spawn point data
	if invalidCount > 0 then
		warn(string.format("[ResourceSpawner] Skipped %d non-Vector3 spawn point(s) during configuration", invalidCount))
	end

	if #self.spawnPoints == 0 then
		warn("[ResourceSpawner] WARNING: No spawn points set! Resources will not spawn.")
	else
		print("[ResourceSpawner] Configured with " .. #self.spawnPoints .. " spawn points")
	end
end

local function getPivotPosition(inst)
	if not inst then return nil end
	if inst:IsA("BasePart") then
		return inst.Position
	end
	if inst:IsA("Model") then
		return inst:GetPivot().Position
	end
	return nil
end

function ResourceSpawner:tryFindBasePosition()
	-- Heuristic: look for common “base” objects across maps
	local candidates = {
		Workspace:FindFirstChild("Base"),
		Workspace:FindFirstChild("BaseCore"),
		Workspace:FindFirstChild("BaseStation"),
		Workspace:FindFirstChild("CureStation1"),
		Workspace:FindFirstChild("CureStations"),
	}

	for _, c in ipairs(candidates) do
		local pos = getPivotPosition(c)
		if pos then
			return pos
		end
		-- If folder/model, try children
		if c and c.GetDescendants then
			for _, d in ipairs(c:GetDescendants()) do
				local p = getPivotPosition(d)
				if p then
					return p
				end
			end
		end
	end

	return Vector3.new(0, 0, 0)
end

function ResourceSpawner:getPlayerPositions()
	local positions = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			table.insert(positions, hrp.Position)
		end
	end
	return positions
end

function ResourceSpawner:getPlayerCenter(playerPositions)
	if not playerPositions or #playerPositions == 0 then
		return nil
	end
	local sum = Vector3.new(0, 0, 0)
	for _, p in ipairs(playerPositions) do
		sum += p
	end
	return sum / #playerPositions
end

function ResourceSpawner:getZombieSpawnPointsFallback()
	-- If we weren’t injected, read manual + generated markers from workspace
	local points = {}

	local manual = Workspace:FindFirstChild("ZombieSpawnPoints")
	if manual then
		for _, ch in ipairs(manual:GetChildren()) do
			if ch:IsA("BasePart") then
				table.insert(points, ch.Position)
			elseif ch:IsA("Model") then
				table.insert(points, ch:GetPivot().Position)
			end
		end
	end

	local generated = Workspace:FindFirstChild("GeneratedZombieSpawnPoints")
	if generated then
		for _, ch in ipairs(generated:GetChildren()) do
			if ch:IsA("BasePart") then
				table.insert(points, ch.Position)
			end
		end
	end

	return points
end

function ResourceSpawner:getZombieRingDistance(basePos, zombieSpawns)
	if not zombieSpawns or #zombieSpawns == 0 then
		return nil
	end

	local sum = 0
	local count = 0
	for _, z in ipairs(zombieSpawns) do
		sum += (z - basePos).Magnitude
		count += 1
	end

	if count == 0 then return nil end
	return sum / count
end

function ResourceSpawner:raycastToGround(pos)
	local rayStart = Vector3.new(pos.X, pos.Y + CONFIG.GROUND_CHECK_DISTANCE, pos.Z)
	local rayDir = Vector3.new(0, -CONFIG.GROUND_CHECK_DISTANCE * 2, 0)

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { self.resourceFolder }
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true

	local result = Workspace:Raycast(rayStart, rayDir, params)
	if result and result.Position then
		return result.Position
	end
	return nil
end

function ResourceSpawner:isSpawnAreaClear(pos)
	-- Define the same region extents you had:
	local halfX = CONFIG.VALIDATION_RADIUS
	local halfZ = CONFIG.VALIDATION_RADIUS
	local minY = pos.Y - 3
	local maxY = pos.Y + 8

	local size = Vector3.new(halfX * 2, maxY - minY, halfZ * 2)
	local centerY = (minY + maxY) * 0.5

	-- Box CFrame centered on the region
	local boxCFrame = CFrame.new(pos.X, centerY, pos.Z)

	-- Ignore our own resource folder (and anything else you want)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { self.resourceFolder }
	params.MaxParts = 80

	local parts = Workspace:GetPartBoundsInBox(boxCFrame, size, params)

	for _, part in ipairs(parts) do
		if part and part.Parent and part.CanCollide and part.Transparency < 0.95 then
			return false
		end
	end

	return true
end


function ResourceSpawner:getOpennessScore(pos)
	-- Favour open spaces: fewer hits in radial raycasts
	local hits = 0
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { self.resourceFolder }
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true

	local origin = pos + Vector3.new(0, 3, 0)
	for i = 1, CONFIG.OPENNESS_RAYS do
		local angle = (i / CONFIG.OPENNESS_RAYS) * math.pi * 2
		local dir = Vector3.new(math.cos(angle), 0, math.sin(angle)) * CONFIG.OPENNESS_RAY_LENGTH
		local result = Workspace:Raycast(origin, dir, params)
		if result and result.Instance and result.Instance.CanCollide then
			hits += 1
		end
	end

	-- 0 hits = best, more hits = more cover
	return (CONFIG.OPENNESS_RAYS - hits) / CONFIG.OPENNESS_RAYS
end

function ResourceSpawner:pickSmartSpawnPoint()
	local basePos = self:tryFindBasePosition()
	local playerPositions = self:getPlayerPositions()
	local playerCenter = self:getPlayerCenter(playerPositions)

	local zombieSpawns = self.zombieSpawnPoints
	if not zombieSpawns then
		zombieSpawns = self:getZombieSpawnPointsFallback()
	end

	local zombieRing = self:getZombieRingDistance(basePos, zombieSpawns)
	local minOuter = zombieRing and (zombieRing * CONFIG.OUTER_RING_MULTIPLIER) or nil

	-- If we have no spawn points, error loudly
	if #self.spawnPoints == 0 then
		error("[ResourceSpawner] No spawn points configured! Resources cannot spawn. Call setSpawnPoints() first or check map validation.")
		return nil
	end

	local bestPos = nil
	local bestScore = -math.huge

	-- Evaluate a handful of candidates
	for attempt = 1, CONFIG.MAX_ATTEMPTS do
		local candidate = self.spawnPoints[math.random(1, #self.spawnPoints)]
		local grounded = self:raycastToGround(candidate)
		if not grounded then
			continue
		end

		local pos = Vector3.new(grounded.X, grounded.Y + CONFIG.SPAWN_HEIGHT_OFFSET, grounded.Z)

		-- Safety constraints
		local dBase = (pos - basePos).Magnitude
		if dBase < CONFIG.MIN_DISTANCE_FROM_BASE then
			continue
		end

		if minOuter and dBase < minOuter then
			-- Must be beyond the average zombie ring to pull players outward
			continue
		end

		if playerCenter then
			local dPlayers = (pos - playerCenter).Magnitude
			if dPlayers < CONFIG.MIN_DISTANCE_FROM_PLAYERS then
				continue
			end
		end

		if not self:isSpawnAreaClear(pos) then
			continue
		end

		-- Scoring
		local score = 0

		-- Push outward from base (strong)
		score += dBase * 1.0

		-- Prefer opposite direction of current player push
		if playerCenter then
			local pv = (playerCenter - basePos)
			if pv.Magnitude > 0.01 then
				local playerDir = pv.Unit
				local spawnDir = (pos - basePos).Unit
				local alignment = playerDir:Dot(spawnDir) -- 1 = same direction, -1 = opposite
				score += (-alignment * 80)
			end
		end

		-- Prefer open areas (less cover)
		local open = self:getOpennessScore(pos)
		score += open * 60

		-- Small randomness so it’s not chess-perfect
		score += math.random(-10, 10)

		if score > bestScore then
			bestScore = score
			bestPos = pos
		end
	end

	-- Hard fallback
	if not bestPos then
		local fallback = self.spawnPoints[math.random(1, #self.spawnPoints)]
		local grounded = self:raycastToGround(fallback)
		if grounded then
			bestPos = grounded + Vector3.new(0, CONFIG.SPAWN_HEIGHT_OFFSET, 0)
		else
			bestPos = fallback + Vector3.new(0, CONFIG.SPAWN_HEIGHT_OFFSET, 0)
		end
	end

	return bestPos
end


function ResourceSpawner:getRandomComponent()
	local components = GameConfig.CURE_COMPONENT_NAMES
	return components[math.random(1, #components)]
end

function ResourceSpawner:getRandomSpawnPoint()
	if #self.spawnPoints == 0 then
		warn("[ResourceSpawner] No spawn points available")
		return nil
	end
	return self.spawnPoints[math.random(1, #self.spawnPoints)]
end

function ResourceSpawner:spawnResource()
	if self:getActiveResourceCount() >= GameConfig.MAX_RESOURCES_ON_MAP then
		return nil
	end

	-- NEW: intelligent selection
	local spawnPoint = self:pickSmartSpawnPoint()
	if not spawnPoint then
		-- No spawn points configured, cannot spawn
		return nil
	end

	local componentName = self:getRandomComponent()
	local resourceId = "resource_" .. os.time() .. "_" .. math.random(1000, 9999)

	local part = Instance.new("Part")
	part.Name = componentName .. "_Resource"
	part.Color = self:getComponentColor(componentName)
	part.Material = Enum.Material.Neon
	part.Size = Vector3.new(2, 0.5, 2)
	part.Position = spawnPoint + Vector3.new(0, 0, 0)
	part.Anchored = true
	part.CanCollide = false
	part:SetAttribute("ComponentName", componentName)
	part:SetAttribute("ResourceId", resourceId)
	part.Parent = self.resourceFolder

	local RunService = game:GetService("RunService")
	local rotationSpeed = 2
	local rotationConnection
	rotationConnection = RunService.Heartbeat:Connect(function(dt)
		if not part or not part.Parent then
			if rotationConnection then
				rotationConnection:Disconnect()
			end
			return
		end
		part.CFrame = part.CFrame * CFrame.Angles(0, rotationSpeed * dt, 0)
	end)

	part.Destroying:Connect(function()
		if rotationConnection then
			rotationConnection:Disconnect()
		end
	end)

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 40)
	billboard.AlwaysOnTop = true
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.Parent = part

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.5
	textLabel.TextScaled = true
	textLabel.Text = componentName
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Parent = billboard

	local debouncing = false
	local touchConnection = part.Touched:Connect(function(hit)
		if debouncing then
			return
		end

		local character = hit and hit.Parent
		if not character then
			return
		end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		debouncing = true
		self:onResourceCollected(player, resourceId, componentName, part)
	end)

	self.activeResources[resourceId] = {
		component = componentName,
		instance = part,
		connection = touchConnection
	}

	print("Spawned " .. componentName .. " resource at " .. tostring(spawnPoint))

	return part
end

function ResourceSpawner:getComponentColor(componentName)
	local colors = {
		["Chemical A"] = Color3.fromRGB(85, 170, 255),
		["Chemical B"] = Color3.fromRGB(255, 170, 85),
		["Biological Sample"] = Color3.fromRGB(85, 255, 85),
		["Research Notes"] = Color3.fromRGB(255, 255, 100),
		["Catalyst"] = Color3.fromRGB(255, 85, 255),
	}
	return colors[componentName] or Color3.fromRGB(255, 255, 255)
end

function ResourceSpawner:onResourceCollected(player, resourceId, componentName, part)
	local resource = self.activeResources[resourceId]
	if not resource then
		-- Resource already collected or removed - not an error
		return
	end

	print(player.Name .. " collected " .. componentName)

	-- Handle the collection
	if self.cureService then
		local success = pcall(function()
			self.cureService:handleDepositComponent(player, componentName)
		end)
		if not success then
			warn("[ResourceSpawner] Failed to deposit component for " .. player.Name)
		end
	end

	-- Always cleanup the resource, even if deposit fails
	if resource.connection then
		resource.connection:Disconnect()
	end

	if part and part.Parent then
		part:Destroy()
	end

	self.activeResources[resourceId] = nil
end

function ResourceSpawner:update(deltaTime)
	self.spawnTimer = self.spawnTimer + deltaTime

	if self.spawnTimer >= GameConfig.RESOURCE_SPAWN_RATE then
		self.spawnTimer = 0
		self:spawnResource()
	end
end

function ResourceSpawner:getActiveResourceCount()
	local count = 0
	for _ in pairs(self.activeResources) do
		count = count + 1
	end
	return count
end

function ResourceSpawner:clearAllResources()
	for resourceId, resource in pairs(self.activeResources) do
		if resource.connection then
			resource.connection:Disconnect()
		end
		if resource.instance and resource.instance.Parent then
			resource.instance:Destroy()
		end
	end
	self.activeResources = {}
end

return ResourceSpawner