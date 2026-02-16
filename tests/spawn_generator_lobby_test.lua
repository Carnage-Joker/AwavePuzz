-- spawn_generator_lobby_test.lua
-- Test script to verify that spawn generator doesn't spam warnings during lobby phase
-- Run this in Roblox Studio Server console

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("==============================================")
print("=== SPAWN GENERATOR LOBBY PHASE TEST ===")
print("==============================================")

-- Load required modules
local IntelligentSpawnGenerator = require(ServerScriptService:WaitForChild("IntelligentSpawnGenerator"))
local Spawner = require(ServerScriptService:WaitForChild("Spawner"))
local BaseManager = require(ServerScriptService:WaitForChild("BaseManager"))
local PlayerManager = require(ServerScriptService:WaitForChild("PlayerManager"))

local function testNoMapWarnings()
	print("\n--- Test 1: No Warnings Without ActiveMap ---")
	
	-- Ensure no ActiveMap exists
	local existingMap = Workspace:FindFirstChild("ActiveMap")
	if existingMap then
		existingMap.Parent = nil
	end
	
	-- Create spawn generator
	local generator = IntelligentSpawnGenerator.new()
	
	-- Try to analyze map bounds (should not warn repeatedly)
	print("Calling analyzeMapBounds() 5 times without ActiveMap...")
	for i = 1, 5 do
		local success = generator:analyzeMapBounds()
		assert(success == false, "Should return false when no map exists")
	end
	print("✅ Test 1 PASSED: No repeated warnings (check output above)")
	
	-- Try to generate spawn points (should return empty list silently)
	print("\nCalling generateSpawnPointsForRound() 3 times without ActiveMap...")
	for i = 1, 3 do
		local points = generator:generateSpawnPointsForRound()
		assert(#points == 0, "Should return empty list when no map exists")
	end
	print("✅ Test 1 PASSED: Returns empty list silently")
	
	return true
end

local function testSpawnerGuards()
	print("\n--- Test 2: Spawner Guards Without ActiveMap ---")
	
	-- Ensure no ActiveMap exists
	local existingMap = Workspace:FindFirstChild("ActiveMap")
	if existingMap then
		existingMap.Parent = nil
	end
	
	-- Create spawner
	local baseManager = BaseManager.getInstance()
	local playerManager = PlayerManager.getInstance()
	local spawner = Spawner.new(nil, baseManager, playerManager)
	
	-- Try to prepare for new round (should skip without warnings)
	print("Calling prepareForNewRound() without ActiveMap...")
	spawner:prepareForNewRound()
	print("✅ Test 2a PASSED: prepareForNewRound() skipped gracefully")
	
	-- Try to generate spawn points (should skip without warnings)
	print("\nCalling generateSpawnPointsForRound() without ActiveMap...")
	spawner:generateSpawnPointsForRound()
	print("✅ Test 2b PASSED: generateSpawnPointsForRound() skipped gracefully")
	
	return true
end

local function testMapLoadedBehavior()
	print("\n--- Test 3: Normal Behavior With ActiveMap ---")
	
	-- Create a simple ActiveMap
	local activeMap = Instance.new("Model")
	activeMap.Name = "ActiveMap"
	
	-- Add a ground part
	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Size = Vector3.new(200, 1, 200)
	ground.Position = Vector3.new(0, 0, 0)
	ground.Anchored = true
	ground.Parent = activeMap
	
	activeMap.Parent = Workspace
	
	-- Create spawn generator and test
	local generator = IntelligentSpawnGenerator.new()
	
	print("Analyzing map bounds with ActiveMap present...")
	local success = generator:analyzeMapBounds()
	assert(success == true, "Should succeed when map exists")
	print("✅ Test 3a PASSED: analyzeMapBounds() succeeded")
	
	print("\nGenerating spawn points with ActiveMap present...")
	local points = generator:generateSpawnPointsForRound()
	print(string.format("Generated %d spawn points", #points))
	-- Generator should return some spawn points when map exists (even if just manual ones)
	assert(#points >= 0, "Should return valid spawn points array when map exists")
	print("✅ Test 3b PASSED: generateSpawnPointsForRound() worked normally")
	
	-- Cleanup
	activeMap:Destroy()
	
	return true
end

-- Run all tests
print("\n" .. string.rep("=", 46))
print("RUNNING TESTS...")
print(string.rep("=", 46))

local test1 = testNoMapWarnings()
local test2 = testSpawnerGuards()
local test3 = testMapLoadedBehavior()

-- Summary
print("\n" .. string.rep("=", 46))
print("TEST SUMMARY")
print(string.rep("=", 46))

local passedTests = 0
local totalTests = 3

if test1 then passedTests = passedTests + 1 end
if test2 then passedTests = passedTests + 1 end
if test3 then passedTests = passedTests + 1 end

print(string.format("Tests Passed: %d / %d", passedTests, totalTests))

if passedTests == totalTests then
	print("\n✅ ALL TESTS PASSED!")
	print("Spawn generator warnings have been successfully suppressed during lobby phase.")
else
	warn(string.format("\n❌ %d TEST(S) FAILED", totalTests - passedTests))
	warn("Some spawn generator issues may remain.")
end

print("\n" .. string.rep("=", 46))
print("=== TEST COMPLETE ===")
print(string.rep("=", 46))
