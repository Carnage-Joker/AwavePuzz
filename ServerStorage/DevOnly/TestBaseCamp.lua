-- TestBaseCamp.lua
-- Test script to verify base camp creation works correctly
-- Place in ServerStorage/DevOnly for testing purposes

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("===== Base Camp Test Script =====")

-- Load required modules
local BaseCampSetup = require(ServerScriptService:WaitForChild("BaseCampSetup"))
local GameConfig = require(ReplicatedStorage.Shared:WaitForChild("GameConfig"))

print("✓ Modules loaded successfully")

-- Test 1: Check if AUTO_CREATE_BASE_CAMP is enabled
print("\n--- Test 1: Configuration ---")
print("AUTO_CREATE_BASE_CAMP:", GameConfig.AUTO_CREATE_BASE_CAMP)
assert(type(GameConfig.AUTO_CREATE_BASE_CAMP) == "boolean", "AUTO_CREATE_BASE_CAMP should be a boolean")
print("✓ Configuration check passed")

-- Test 2: Create BaseCampSetup instance
print("\n--- Test 2: BaseCampSetup Instance ---")
local baseCampSetup = BaseCampSetup.new()
assert(baseCampSetup ~= nil, "Failed to create BaseCampSetup instance")
print("✓ BaseCampSetup instance created")

-- Test 3: Create test zombie spawn points
print("\n--- Test 3: Test Spawn Points ---")
local testSpawnPoints = {
	Vector3.new(50, 5, 0),
	Vector3.new(0, 5, 50),
	Vector3.new(-50, 5, 0),
	Vector3.new(0, 5, -50),
}
print("✓ Created 4 test spawn points")

-- Test 4: Calculate map center
print("\n--- Test 4: Calculate Map Center ---")
local centerPos = baseCampSetup:calculateMapCenter(testSpawnPoints)
assert(centerPos ~= nil, "Failed to calculate map center")
print("Calculated center:", centerPos)
assert(centerPos.X == 0, "Center X should be 0")
assert(centerPos.Z == 0, "Center Z should be 0")
print("✓ Map center calculation correct")

-- Test 5: Build base camp
print("\n--- Test 5: Build Base Camp ---")
local baseCamp, baseCaptureZone = baseCampSetup:buildBaseCamp(Vector3.new(0, 5, 0))
assert(baseCamp ~= nil, "Failed to create base camp")
assert(baseCamp:IsA("Model"), "Base camp should be a Model")
assert(baseCamp.Name == "BaseCamp", "Base camp should be named 'BaseCamp'")
print("✓ Base camp model created:", baseCamp.Name)

assert(baseCaptureZone ~= nil, "Failed to create BaseCaptureZone")
assert(baseCaptureZone:IsA("Model"), "BaseCaptureZone should be a Model")
assert(baseCaptureZone.Name == "BaseCaptureZone", "Should be named 'BaseCaptureZone'")
print("✓ BaseCaptureZone model created:", baseCaptureZone.Name)

-- Test 6: Verify base camp components
print("\n--- Test 6: Verify Base Camp Components ---")
local platform = baseCamp:FindFirstChild("BasePlatform")
assert(platform ~= nil, "Base platform not found")
print("✓ Base platform exists")

local walls = {}
-- Walls are now split into segments to create gaps for gates
local wallNames = {
	"NorthWallLeft", "NorthWallRight",
	"SouthWallLeft", "SouthWallRight",
	"EastWallTop", "EastWallBottom",
	"WestWallTop", "WestWallBottom"
}
for _, wallName in ipairs(wallNames) do
	local wall = baseCamp:FindFirstChild(wallName)
	assert(wall ~= nil, wallName .. " not found")
	table.insert(walls, wall)
end
print("✓ All 8 wall segments exist (split to allow gate passage)")

local gates = {}
for _, gateName in ipairs({"NorthGate", "SouthGate", "EastGate", "WestGate"}) do
	local gate = baseCamp:FindFirstChild(gateName)
	assert(gate ~= nil, gateName .. " not found")
	-- Note: Transparency value (0.3) matches GameConfig.BASE_CAMP.GATE_TRANSPARENCY
	assert(gate.Transparency == 0.3, gateName .. " should be semi-transparent (0.3)")
	assert(gate.CanCollide == false, gateName .. " should not collide")
	table.insert(gates, gate)
end
print("✓ All 4 gates exist with correct properties")

local coverCount = 0
for _, child in ipairs(baseCamp:GetChildren()) do
	if string.match(child.Name, "^Cover_") then
		coverCount = coverCount + 1
	end
end
assert(coverCount == 8, "Should have 8 cover positions, found " .. coverCount)
print("✓ All 8 cover positions exist")

-- Test 7: Verify BaseCaptureZone
print("\n--- Test 7: Verify BaseCaptureZone ---")
local hitBox = baseCaptureZone:FindFirstChild("HitBox")
assert(hitBox ~= nil, "HitBox not found in BaseCaptureZone")
assert(hitBox.Transparency == 1, "HitBox should be invisible")
assert(hitBox.CanCollide == false, "HitBox should not collide")
assert(baseCaptureZone.PrimaryPart == hitBox, "HitBox should be the PrimaryPart")
print("✓ HitBox configured correctly")

local healthValue = baseCaptureZone:FindFirstChild("Health")
assert(healthValue ~= nil, "Health NumberValue not found")
assert(healthValue:IsA("NumberValue"), "Health should be a NumberValue")
assert(healthValue.Value == GameConfig.BASE_HEALTH, "Health should match GameConfig.BASE_HEALTH")
print("✓ Health value configured correctly")

-- Test 8: Verify workspace placement
print("\n--- Test 8: Verify Workspace Placement ---")
assert(baseCamp.Parent == workspace, "Base camp should be in workspace")
print("✓ Base camp is in workspace")
assert(baseCaptureZone.Parent == workspace, "BaseCaptureZone should be in workspace")
print("✓ BaseCaptureZone is in workspace")

-- Test 9: Test cleanup
print("\n--- Test 9: Test Cleanup ---")
baseCampSetup:cleanup()
task.wait(0.1) -- Wait for cleanup to process
assert(workspace:FindFirstChild("BaseCamp") == nil, "Base camp should be removed after cleanup")
assert(workspace:FindFirstChild("BaseCaptureZone") == nil, "BaseCaptureZone should be removed after cleanup")
print("✓ Cleanup successful")

-- All tests passed!
print("\n===================================")
print("✅ ALL TESTS PASSED!")
print("Base camp system is working correctly")
print("===================================")
