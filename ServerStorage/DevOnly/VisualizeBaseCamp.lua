-- VisualizeBaseCamp.lua
-- Visual test script for base camp creation
-- Run this in Studio Command Bar or as a Script to see the base camp

local ServerScriptService = game:GetService("ServerScriptService")
local workspace = game:GetService("Workspace")

-- Clean up any existing test structures
local existingBaseCamp = workspace:FindFirstChild("BaseCamp")
if existingBaseCamp then
	existingBaseCamp:Destroy()
end

local existingZone = workspace:FindFirstChild("BaseCaptureZone")
if existingZone then
	existingZone:Destroy()
end

-- Create test spawn points if they don't exist
local spawnFolder = workspace:FindFirstChild("ZombieSpawnPoints")
if not spawnFolder then
	print("Creating test zombie spawn points...")
	spawnFolder = Instance.new("Folder")
	spawnFolder.Name = "ZombieSpawnPoints"
	spawnFolder.Parent = workspace
	
	-- Create 8 spawn points in a circle around origin
	local radius = 75
	for i = 1, 8 do
		local angle = (i - 1) * (math.pi * 2 / 8)
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		
		local spawnPoint = Instance.new("Part")
		spawnPoint.Name = "SpawnPoint_" .. i
		spawnPoint.Size = Vector3.new(5, 1, 5)
		spawnPoint.Position = Vector3.new(x, 5, z)
		spawnPoint.Anchored = true
		spawnPoint.BrickColor = BrickColor.new("Bright red")
		spawnPoint.Material = Enum.Material.Neon
		spawnPoint.Transparency = 0.5
		spawnPoint.Parent = spawnFolder
	end
	print("✓ Test spawn points created")
end

-- Load and execute base camp setup
print("\n===== Visual Base Camp Test =====")
local BaseCampSetup = require(ServerScriptService:WaitForChild("BaseCampSetup"))
local baseCampSetup = BaseCampSetup.new()

-- Collect spawn points
local spawnPoints = {}
for _, point in ipairs(spawnFolder:GetChildren()) do
	if point:IsA("BasePart") then
		table.insert(spawnPoints, point.Position)
	end
end

print("Found", #spawnPoints, "spawn points")

-- Calculate center and create base camp
local centerPos = baseCampSetup:calculateMapCenter(spawnPoints)
print("Center position:", centerPos)

local baseCamp, baseCaptureZone = baseCampSetup:buildBaseCamp(centerPos)

print("\n✅ Base Camp Created!")
print("Base Camp Model:", baseCamp.Name, "- Children:", #baseCamp:GetChildren())
print("BaseCaptureZone Model:", baseCaptureZone.Name)
print("\nComponents:")
print("  - Platform: 30x30 studs")
print("  - Walls: 4 sides, 12 studs high")
print("  - Gates: 4 gates (semi-transparent)")
print("  - Cover: 8 positions")
print("\nZoom camera to center to view the base camp!")
print("===================================")

-- Add a visual marker at the center for debugging
local centerMarker = Instance.new("Part")
centerMarker.Name = "CenterMarker"
centerMarker.Size = Vector3.new(2, 20, 2)
centerMarker.Position = centerPos + Vector3.new(0, 10, 0)
centerMarker.Anchored = true
centerMarker.BrickColor = BrickColor.new("Bright green")
centerMarker.Material = Enum.Material.Neon
centerMarker.Parent = workspace

print("✓ Center marker added (green beam)")
