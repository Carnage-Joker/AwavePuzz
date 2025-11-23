--[[
    ResourceSpawner.lua (ModuleScript)
    Phase 3: Manages spawning of cure components around the map
    Components appear as pickable objects that players can collect
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(sharedFolder:WaitForChild("GameConfig"))

local ResourceSpawner = {}
ResourceSpawner.__index = ResourceSpawner

function ResourceSpawner.new()
	local self = setmetatable({}, ResourceSpawner)

	self.cureService = nil
	self.activeResources = {}
	self.spawnTimer = 0
	self.spawnPoints = {}

	-- Create resource folder in workspace
	self.resourceFolder = workspace:FindFirstChild("CureResources")
	if not self.resourceFolder then
		self.resourceFolder = Instance.new("Folder")
		self.resourceFolder.Name = "CureResources"
		self.resourceFolder.Parent = workspace
	end

	-- Find or create spawn points
	self:findSpawnPoints()

	print("ResourceSpawner initialized with " .. #self.spawnPoints .. " spawn points")

	return self
end

function ResourceSpawner:setCureService(cureService)
	self.cureService = cureService
end

function ResourceSpawner:setSpawnPoints(points)
	if typeof(points) ~= "table" then
		warn("[ResourceSpawner] setSpawnPoints expected table, got", typeof(points))
		return
	end

	self.spawnPoints = {}

	-- Defensive copy, in case the source table gets modified elsewhere
	for _, pos in ipairs(points) do
		table.insert(self.spawnPoints, pos)
	end

	print("[ResourceSpawner] Set spawn points:", #self.spawnPoints)
end

function ResourceSpawner:findSpawnPoints()
	-- Look for ItemSpawns or ResourceSpawns in workspace
	local spawnPointsFolder = workspace:FindFirstChild("SpawnPoints")

	if spawnPointsFolder then
		local itemSpawns = spawnPointsFolder:FindFirstChild("ItemSpawns") or spawnPointsFolder:FindFirstChild("ResourceSpawns")

		if itemSpawns then
			for _, spawnPoint in ipairs(itemSpawns:GetChildren()) do
				if spawnPoint:IsA("BasePart") then
					table.insert(self.spawnPoints, spawnPoint.Position)
				end
			end
		end
	end

	-- If no spawn points found, create some defaults
	if #self.spawnPoints == 0 then
		warn("No resource spawn points found. Creating default spawn locations...")

		-- Create spawn points in a circle around the origin
		local radius = 40
		for i = 1, 8 do
			local angle = (i / 8) * math.pi * 2
			local x = math.cos(angle) * radius
			local z = math.sin(angle) * radius
			table.insert(self.spawnPoints, Vector3.new(x, 2, z))
		end
	end
end

function ResourceSpawner:getRandomComponent()
	local components = GameConfig.CURE_COMPONENT_NAMES
	return components[math.random(1, #components)]
end

function ResourceSpawner:getRandomSpawnPoint()
	if #self.spawnPoints == 0 then
		return Vector3.new(0, 2, 0) -- Fallback position
	end
	return self.spawnPoints[math.random(1, #self.spawnPoints)]
end

function ResourceSpawner:spawnResource()
	if self:getActiveResourceCount() >= GameConfig.MAX_RESOURCES_ON_MAP then
		return nil
	end

	local spawnPoint = self:getRandomSpawnPoint()
	local componentName = self:getRandomComponent()
	local resourceId = "resource_" .. os.time() .. "_" .. math.random(1000, 9999)

	-- Create visual resource part
	local part = Instance.new("Part")
	part.Name = componentName .. "_Resource"
	part.Color = self:getComponentColor(componentName)
	part.Material = Enum.Material.Neon
	part.Size = Vector3.new(2, 0.5, 2)
	part.Position = spawnPoint + Vector3.new(0, 2, 0)
	part.Anchored = true
	part.CanCollide = false
	part:SetAttribute("ComponentName", componentName)
	part:SetAttribute("ResourceId", resourceId)
	part.Parent = self.resourceFolder

	-- Add rotating effect (modern approach for anchored parts)
	local RunService = game:GetService("RunService")
	-- Store the initial CFrame for reference
	local initialCFrame = part.CFrame
	-- We'll rotate at 2 radians per second around Y axis
	local rotationSpeed = 2 -- radians per second
	-- Create a connection to rotate the part every Heartbeat
	local rotationConnection
	rotationConnection = RunService.Heartbeat:Connect(function(dt)
		if not part or not part.Parent then
			if rotationConnection then
				rotationConnection:Disconnect()
			end
			return
		end
		-- Incremental rotation
		part.CFrame = part.CFrame * CFrame.Angles(0, rotationSpeed * dt, 0)
	end)

	-- Optionally, store the connection for cleanup if you remove the part elsewhere
	part.Destroying:Connect(function()
		if rotationConnection then
			rotationConnection:Disconnect()
		end
	end)

	-- Add label
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

	-- Touch detection
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

	-- Store resource data
	self.activeResources[resourceId] = {
		component = componentName,
		instance = part,
		connection = touchConnection
	}

	print("Spawned " .. componentName .. " resource at " .. tostring(spawnPoint))

	return part
end

function ResourceSpawner:getComponentColor(componentName)
	-- Assign unique colors to each component type
	local colors = {
		["Chemical A"] = Color3.fromRGB(85, 170, 255),   -- Blue
		["Chemical B"] = Color3.fromRGB(255, 170, 85),   -- Orange
		["Biological Sample"] = Color3.fromRGB(85, 255, 85),  -- Green
		["Research Notes"] = Color3.fromRGB(255, 255, 100),   -- Yellow
		["Catalyst"] = Color3.fromRGB(255, 85, 255),     -- Purple
	}

	return colors[componentName] or Color3.fromRGB(255, 255, 255)
end

function ResourceSpawner:onResourceCollected(player, resourceId, componentName, part)
	local resource = self.activeResources[resourceId]
	if not resource then
		return
	end

	print(player.Name .. " collected " .. componentName)

	-- Notify CureService to add component
	if self.cureService then
		self.cureService:handleDepositComponent(player, componentName)
	end

	-- Clean up resource
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
