-- TestBaseCampCleanup.lua
-- Test script to verify BaseCampSetup only cleans up its own models
-- Place in ServerStorage/DevOnly for testing purposes

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

print("===== BaseCamp Cleanup Test Script =====")

-- Load required modules
local BaseCampSetup = require(ServerScriptService:WaitForChild("BaseCampSetup"))
local GameConfig = require(ReplicatedStorage.Shared:WaitForChild("GameConfig"))

print("✓ Modules loaded successfully")

-- Test 1: Create manual base camp models (simulating manually placed camps)
print("\n--- Test 1: Create Manual Models ---")
local manualBaseCamp = Instance.new("Model")
manualBaseCamp.Name = "BaseCamp"
manualBaseCamp.Parent = Workspace

local manualPart = Instance.new("Part")
manualPart.Name = "ManualPlatform"
manualPart.Size = Vector3.new(10, 1, 10)
manualPart.Position = Vector3.new(100, 5, 100) -- Far away from test position
manualPart.Anchored = true
manualPart.Parent = manualBaseCamp

local manualCaptureZone = Instance.new("Model")
manualCaptureZone.Name = "BaseCaptureZone"
manualCaptureZone.Parent = Workspace

local manualHitBox = Instance.new("Part")
manualHitBox.Name = "HitBox"
manualHitBox.Size = Vector3.new(8, 8, 8)
manualHitBox.Position = Vector3.new(100, 5, 100)
manualHitBox.Anchored = true
manualHitBox.Transparency = 1
manualHitBox.Parent = manualCaptureZone

print("✓ Created manual BaseCamp and BaseCaptureZone models")

-- Test 2: Verify manual models exist
print("\n--- Test 2: Verify Manual Models ---")
assert(Workspace:FindFirstChild("BaseCamp") == manualBaseCamp, "Manual BaseCamp should exist")
assert(Workspace:FindFirstChild("BaseCaptureZone") == manualCaptureZone, "Manual BaseCaptureZone should exist")
print("✓ Manual models are in workspace")

-- Test 3: Create first BaseCampSetup instance and build camp
print("\n--- Test 3: Create First Base Camp ---")
local baseCampSetup1 = BaseCampSetup.new()
local testSpawnPoints = {
	Vector3.new(50, 5, 0),
	Vector3.new(0, 5, 50),
	Vector3.new(-50, 5, 0),
	Vector3.new(0, 5, -50),
}
local centerPos = baseCampSetup1:calculateMapCenter(testSpawnPoints)
local baseCamp1, captureZone1 = baseCampSetup1:buildBaseCamp(centerPos)

assert(baseCamp1 ~= nil, "First base camp should be created")
assert(captureZone1 ~= nil, "First capture zone should be created")
print("✓ First base camp created at position:", centerPos)

-- Test 4: Verify multiple BaseCamp models exist in workspace
print("\n--- Test 4: Multiple BaseCamp Models ---")
local baseCampCount = 0
for _, child in ipairs(Workspace:GetChildren()) do
	if child.Name == "BaseCamp" then
		baseCampCount = baseCampCount + 1
	end
end
assert(baseCampCount >= 2, "Should have at least 2 BaseCamp models (manual + auto)")
print("✓ Multiple BaseCamp models exist in workspace:", baseCampCount)

-- Test 5: Cleanup first BaseCampSetup - should only remove its own models
print("\n--- Test 5: Cleanup First Instance ---")
baseCampSetup1:cleanup()
task.wait(0.1) -- Wait for cleanup to process

-- Verify manual models still exist
assert(Workspace:FindFirstChild("BaseCamp") ~= nil, "A BaseCamp should still exist (manual one)")
assert(manualBaseCamp.Parent == Workspace, "Manual BaseCamp should still be in workspace")
assert(manualCaptureZone.Parent == Workspace, "Manual BaseCaptureZone should still be in workspace")

-- Verify created models were destroyed
assert(baseCamp1.Parent == nil, "First created base camp should be destroyed")
assert(captureZone1.Parent == nil, "First created capture zone should be destroyed")
print("✓ Cleanup only removed instance's own models, manual models preserved")

-- Test 6: Create second BaseCampSetup instance
print("\n--- Test 6: Create Second Base Camp ---")
local baseCampSetup2 = BaseCampSetup.new()
local baseCamp2, captureZone2 = baseCampSetup2:buildBaseCamp(Vector3.new(-50, 5, -50))

assert(baseCamp2 ~= nil, "Second base camp should be created")
assert(captureZone2 ~= nil, "Second capture zone should be created")
print("✓ Second base camp created")

-- Test 7: Verify manual + second camp exist
print("\n--- Test 7: Verify Multiple Camps Coexist ---")
baseCampCount = 0
for _, child in ipairs(Workspace:GetChildren()) do
	if child.Name == "BaseCamp" then
		baseCampCount = baseCampCount + 1
	end
end
assert(baseCampCount >= 2, "Should still have multiple BaseCamp models")
assert(manualBaseCamp.Parent == Workspace, "Manual BaseCamp should still exist")
assert(baseCamp2.Parent == Workspace, "Second base camp should exist")
print("✓ Manual and second base camp coexist")

-- Test 8: Cleanup second instance
print("\n--- Test 8: Cleanup Second Instance ---")
baseCampSetup2:cleanup()
task.wait(0.1)

assert(baseCamp2.Parent == nil, "Second base camp should be destroyed")
assert(captureZone2.Parent == nil, "Second capture zone should be destroyed")
assert(manualBaseCamp.Parent == Workspace, "Manual BaseCamp should still exist after second cleanup")
assert(manualCaptureZone.Parent == Workspace, "Manual BaseCaptureZone should still exist after second cleanup")
print("✓ Second cleanup only removed its own models")

-- Test 9: Multiple cleanup calls should be safe
print("\n--- Test 9: Multiple Cleanup Calls ---")
baseCampSetup1:cleanup() -- Second cleanup call
baseCampSetup2:cleanup() -- Second cleanup call
task.wait(0.1)

assert(manualBaseCamp.Parent == Workspace, "Manual models should survive multiple cleanup calls")
print("✓ Multiple cleanup calls are safe and don't affect manual models")

-- Test 10: Create third instance and verify tracking
print("\n--- Test 10: Third Instance Tracking ---")
local baseCampSetup3 = BaseCampSetup.new()
assert(baseCampSetup3.baseCampModel == nil, "New instance should have nil baseCampModel")
assert(baseCampSetup3.baseCaptureZoneModel == nil, "New instance should have nil baseCaptureZoneModel")

local baseCamp3, captureZone3 = baseCampSetup3:buildBaseCamp(Vector3.new(50, 5, 50))
assert(baseCampSetup3.baseCampModel == baseCamp3, "Instance should track its base camp")
assert(baseCampSetup3.baseCaptureZoneModel == captureZone3, "Instance should track its capture zone")
print("✓ Instance correctly tracks its own models")

-- Cleanup test models
baseCampSetup3:cleanup()
manualBaseCamp:Destroy()
manualCaptureZone:Destroy()
task.wait(0.1)

-- All tests passed!
print("\n===================================")
print("✅ ALL TESTS PASSED!")
print("BaseCampSetup cleanup correctly scopes to instance's own models")
print("Manual and alternative camps are not affected")
print("===================================")
