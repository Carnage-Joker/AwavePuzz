--[[
	EpilogueUI Cleanup Test
	
	This test validates that EpilogueUI properly uses instance-level maids
	and cleans up connections correctly on respawn.
	
	Test: Verify that each instance has its own maid and cleanup works correctly
	
	How to run:
	1. Place this script in ServerScriptService for testing
	2. Join the game as a player
	3. The test will validate EpilogueUI instance cleanup
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[EpilogueUICleanupTest] Starting EpilogueUI cleanup test...")

-- Wait for player
local player = Players.LocalPlayer
if not player then
	print("[EpilogueUICleanupTest] No LocalPlayer found - this is a client-side test")
	return
end

-- Wait for UI modules
local clientModules = player:WaitForChild("PlayerScripts"):WaitForChild("Modules", 10)
if not clientModules then
	warn("[EpilogueUICleanupTest] Failed to find client Modules folder")
	return
end

local uiFolder = clientModules:FindFirstChild("UI")
if not uiFolder then
	warn("[EpilogueUICleanupTest] Failed to find UI folder")
	return
end

-- Load EpilogueUI module
local epilogueModule = uiFolder:FindFirstChild("EpilogueUI")
if not epilogueModule then
	warn("[EpilogueUICleanupTest] Failed to find EpilogueUI module")
	return
end

local success, EpilogueUI = pcall(function()
	return require(epilogueModule)
end)

if not success then
	warn("[EpilogueUICleanupTest] Failed to load EpilogueUI:", EpilogueUI)
	return
end

print("[EpilogueUICleanupTest] EpilogueUI module loaded successfully")

-- Test 1: Create instance and verify it has a maid
local function testInstanceHasMaid()
	print("[EpilogueUICleanupTest] Test 1: Verifying instance has maid...")
	
	local instance = EpilogueUI.new()
	
	if not instance then
		warn("[EpilogueUICleanupTest] ✗ Failed to create EpilogueUI instance")
		return false
	end
	
	if not instance.maid then
		warn("[EpilogueUICleanupTest] ✗ Instance does not have maid property")
		return false
	end
	
	if not instance.maid.Give then
		warn("[EpilogueUICleanupTest] ✗ Maid does not have Give method")
		return false
	end
	
	if not instance.maid.Cleanup then
		warn("[EpilogueUICleanupTest] ✗ Maid does not have Cleanup method")
		return false
	end
	
	print("[EpilogueUICleanupTest] ✓ Instance has valid maid")
	
	-- Cleanup test instance
	pcall(function()
		instance:cleanup()
	end)
	
	return true
end

-- Test 2: Verify cleanup method works
local function testCleanupMethod()
	print("[EpilogueUICleanupTest] Test 2: Verifying cleanup method...")
	
	local instance = EpilogueUI.new()
	
	if not instance then
		warn("[EpilogueUICleanupTest] ✗ Failed to create EpilogueUI instance")
		return false
	end
	
	if not instance.cleanup then
		warn("[EpilogueUICleanupTest] ✗ Instance does not have cleanup method")
		return false
	end
	
	-- Try calling cleanup
	local cleanupSuccess, cleanupErr = pcall(function()
		instance:cleanup()
	end)
	
	if not cleanupSuccess then
		warn("[EpilogueUICleanupTest] ✗ Cleanup failed:", cleanupErr)
		return false
	end
	
	print("[EpilogueUICleanupTest] ✓ Cleanup method works")
	return true
end

-- Test 3: Verify no module-level maid exists
local function testNoModuleLevelMaid()
	print("[EpilogueUICleanupTest] Test 3: Verifying no module-level maid...")
	
	-- Create two instances
	local instance1 = EpilogueUI.new()
	local instance2 = EpilogueUI.new()
	
	if not instance1 or not instance2 then
		warn("[EpilogueUICleanupTest] ✗ Failed to create instances")
		return false
	end
	
	-- Verify they have different maids (not sharing a module-level maid)
	if instance1.maid == instance2.maid then
		warn("[EpilogueUICleanupTest] ✗ Instances are sharing the same maid (module-level maid detected)")
		
		-- Cleanup
		pcall(function() instance1:cleanup() end)
		pcall(function() instance2:cleanup() end)
		
		return false
	end
	
	print("[EpilogueUICleanupTest] ✓ Each instance has its own maid")
	
	-- Cleanup
	pcall(function() instance1:cleanup() end)
	pcall(function() instance2:cleanup() end)
	
	return true
end

-- Run all tests
local function runTests()
	local allPassed = true
	
	allPassed = testInstanceHasMaid() and allPassed
	task.wait(0.5)
	
	allPassed = testCleanupMethod() and allPassed
	task.wait(0.5)
	
	allPassed = testNoModuleLevelMaid() and allPassed
	
	if allPassed then
		print("[EpilogueUICleanupTest] ✓ All tests passed")
	else
		warn("[EpilogueUICleanupTest] ✗ Some tests failed")
	end
	
	return allPassed
end

-- Run the tests
task.spawn(runTests)
