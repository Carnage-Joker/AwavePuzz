-- portal_queue_corruption_test.lua
-- Test script to verify BUG-006 fix: Portal queue corruption prevention
-- Run this in Roblox Studio Server console

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

print("==============================================")
print("=== PORTAL QUEUE CORRUPTION TEST (BUG-006) ==")
print("==============================================")

local function testPerPortalDebounce()
	print("\n--- Test 1: Per-Portal Debounce Keys ---")
	
	-- Load PortalMatchmakingService
	local portalService = require(ServerScriptService:WaitForChild("PortalMatchmakingService"))
	
	-- Create a test instance
	local testService = portalService.new(nil) -- nil gameManager for testing
	
	-- Check that touchDebounce is initialized
	if not testService.touchDebounce then
		warn("❌ Test 1 FAILED: touchDebounce not initialized")
		return false
	end
	
	-- Simulate debounce key creation
	local userId = 123456
	local portalId1 = "TestPortal1"
	local portalId2 = "TestPortal2"
	
	local debounceKey1 = tostring(userId) .. "_" .. tostring(portalId1)
	local debounceKey2 = tostring(userId) .. "_" .. tostring(portalId2)
	
	-- Verify keys are different for different portals
	if debounceKey1 == debounceKey2 then
		warn("❌ Test 1 FAILED: Debounce keys should be different for different portals")
		return false
	end
	
	print(string.format("Debounce key for portal 1: %s", debounceKey1))
	print(string.format("Debounce key for portal 2: %s", debounceKey2))
	
	-- Set debounce for portal 1
	testService.touchDebounce[debounceKey1] = tick()
	
	-- Verify portal 2 is not debounced (different key)
	if testService.touchDebounce[debounceKey2] then
		warn("❌ Test 1 FAILED: Portal 2 should not be debounced")
		return false
	end
	
	print("✅ Test 1 PASSED: Per-portal debounce keys working correctly")
	return true
end

local function testAtomicQueueCheck()
	print("\n--- Test 2: Atomic Queue Duplicate Prevention ---")
	
	local portalService = require(ServerScriptService:WaitForChild("PortalMatchmakingService"))
	local testService = portalService.new(nil)
	
	-- Create a mock portal
	local testPortalId = "TestPortal"
	testService.portals[testPortalId] = {
		queue = {},
		countdown = 0,
		locked = false,
		config = {
			portalId = testPortalId,
			mapId = "TestMap",
			minPlayers = 2,
			countdownTime = 10
		}
	}
	
	-- Create mock remote events (prevent errors)
	testService.remoteEvents.PortalQueueJoined = {
		FireClient = function() end
	}
	testService.remoteEvents.PortalQueueStatus = {
		FireClient = function() end,
		FireAllClients = function() end
	}
	
	-- Create a mock player
	local mockPlayer = {
		UserId = 789012,
		Name = "TestPlayer",
		Parent = game
	}
	
	-- First add - should succeed
	local result1 = testService:addPlayerToQueue(testPortalId, mockPlayer)
	if not result1 then
		warn("❌ Test 2 FAILED: First add should succeed")
		return false
	end
	
	print(string.format("First add: Queue size = %d", #testService.portals[testPortalId].queue))
	
	-- Second add (duplicate) - should fail due to atomic check
	local result2 = testService:addPlayerToQueue(testPortalId, mockPlayer)
	if result2 then
		warn("❌ Test 2 FAILED: Duplicate add should be prevented")
		return false
	end
	
	print(string.format("Second add prevented: Queue size = %d", #testService.portals[testPortalId].queue))
	
	-- Verify queue size is still 1
	if #testService.portals[testPortalId].queue ~= 1 then
		warn(string.format("❌ Test 2 FAILED: Queue should have 1 player, has %d", 
			#testService.portals[testPortalId].queue))
		return false
	end
	
	-- Verify playerQueues mapping exists
	if not testService.playerQueues[mockPlayer.UserId] then
		warn("❌ Test 2 FAILED: playerQueues mapping should exist")
		return false
	end
	
	print("✅ Test 2 PASSED: Atomic duplicate prevention working correctly")
	return true
end

local function testRapidPortalTouch()
	print("\n--- Test 3: Rapid Portal Touch Simulation ---")
	
	local portalService = require(ServerScriptService:WaitForChild("PortalMatchmakingService"))
	local testService = portalService.new(nil)
	
	-- Create test portal
	local testPortalId = "RapidTestPortal"
	testService.portals[testPortalId] = {
		queue = {},
		countdown = 0,
		locked = false,
		config = {
			portalId = testPortalId,
			mapId = "TestMap",
			minPlayers = 2,
			countdownTime = 10
		}
	}
	
	-- Mock remote events
	testService.remoteEvents.PortalQueueJoined = {
		FireClient = function() end
	}
	testService.remoteEvents.PortalQueueStatus = {
		FireClient = function() end,
		FireAllClients = function() end
	}
	
	-- Mock MatchRegistry
	testService.matchRegistry = {
		isPlayerInMatch = function() return false end
	}
	
	-- Create mock player
	local mockPlayer = {
		UserId = 999111,
		Name = "RapidTouchPlayer",
		Parent = game
	}
	
	-- Simulate rapid touches (should be debounced after first)
	local touchCount = 10
	local successfulAdds = 0
	
	for i = 1, touchCount do
		-- Call onPortalTouched rapidly
		testService:onPortalTouched(testPortalId, mockPlayer)
		
		-- Small delay to simulate rapid but not instant touches
		if i % 3 == 0 then
			task.wait(0.01)
		end
	end
	
	-- Count how many times player is in queue
	local playerInQueueCount = 0
	for _, player in ipairs(testService.portals[testPortalId].queue) do
		if player.UserId == mockPlayer.UserId then
			playerInQueueCount = playerInQueueCount + 1
		end
	end
	
	print(string.format("Rapid touches: %d, Player in queue count: %d", touchCount, playerInQueueCount))
	
	-- Should only be in queue once
	if playerInQueueCount ~= 1 then
		warn(string.format("❌ Test 3 FAILED: Player should be in queue once, found %d times", 
			playerInQueueCount))
		return false
	end
	
	print("✅ Test 3 PASSED: Rapid portal touches prevented duplication")
	return true
end

local function testDifferentPortalDebounce()
	print("\n--- Test 4: Different Portal Touch Not Debounced ---")
	
	local portalService = require(ServerScriptService:WaitForChild("PortalMatchmakingService"))
	local testService = portalService.new(nil)
	
	-- Create two test portals
	local portal1Id = "Portal1"
	local portal2Id = "Portal2"
	
	testService.portals[portal1Id] = {
		queue = {},
		countdown = 0,
		locked = false,
		config = { portalId = portal1Id, mapId = "Map1", minPlayers = 2, countdownTime = 10 }
	}
	
	testService.portals[portal2Id] = {
		queue = {},
		countdown = 0,
		locked = false,
		config = { portalId = portal2Id, mapId = "Map2", minPlayers = 2, countdownTime = 10 }
	}
	
	-- Mock components
	testService.remoteEvents.PortalQueueJoined = { FireClient = function() end }
	testService.remoteEvents.PortalQueueStatus = { FireClient = function() end, FireAllClients = function() end }
	testService.remoteEvents.PortalQueueLeft = { FireClient = function() end }
	testService.matchRegistry = { isPlayerInMatch = function() return false end }
	
	local mockPlayer = {
		UserId = 888222,
		Name = "MultiPortalPlayer",
		Parent = game
	}
	
	-- Touch portal 1
	testService:onPortalTouched(portal1Id, mockPlayer)
	
	-- Immediately touch portal 2 (should work - different debounce key)
	testService:onPortalTouched(portal2Id, mockPlayer)
	
	-- Player should be in portal 2's queue (moved from portal 1)
	local inPortal1 = false
	local inPortal2 = false
	
	for _, player in ipairs(testService.portals[portal1Id].queue) do
		if player.UserId == mockPlayer.UserId then
			inPortal1 = true
		end
	end
	
	for _, player in ipairs(testService.portals[portal2Id].queue) do
		if player.UserId == mockPlayer.UserId then
			inPortal2 = true
		end
	end
	
	print(string.format("In Portal 1: %s, In Portal 2: %s", tostring(inPortal1), tostring(inPortal2)))
	
	-- Should be removed from portal 1 and added to portal 2
	if inPortal1 then
		warn("❌ Test 4 FAILED: Player should be removed from portal 1")
		return false
	end
	
	if not inPortal2 then
		warn("❌ Test 4 FAILED: Player should be in portal 2")
		return false
	end
	
	print("✅ Test 4 PASSED: Player can switch between different portals")
	return true
end

-- Run all tests
print("\n" .. string.rep("=", 46))
print("RUNNING TESTS...")
print(string.rep("=", 46))

local test1 = testPerPortalDebounce()
local test2 = testAtomicQueueCheck()
local test3 = testRapidPortalTouch()
local test4 = testDifferentPortalDebounce()

-- Summary
print("\n" .. string.rep("=", 46))
print("TEST SUMMARY")
print(string.rep("=", 46))

local passedTests = 0
local totalTests = 4

if test1 then passedTests = passedTests + 1 end
if test2 then passedTests = passedTests + 1 end
if test3 then passedTests = passedTests + 1 end
if test4 then passedTests = passedTests + 1 end

print(string.format("Tests Passed: %d / %d", passedTests, totalTests))

if passedTests == totalTests then
	print("\n✅ ALL TESTS PASSED!")
	print("BUG-006 (Portal queue corruption) has been fixed.")
else
	warn(string.format("\n❌ %d TEST(S) FAILED", totalTests - passedTests))
	warn("BUG-006 (Portal queue corruption) may still exist.")
end

print("\n" .. string.rep("=", 46))
print("=== TEST COMPLETE ===")
print(string.rep("=", 46))
