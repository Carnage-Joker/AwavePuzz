-- Death Tracking Table Leak Test (BUG-013)
-- Place this in ServerScriptService and run in Roblox Studio to verify table cleanup
-- This test simulates 1000 player joins/leaves and verifies tables don't grow

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for GameManager to initialize
local GameManager = require(ServerScriptService:WaitForChild("GameManager"))

print("========================================")
print("DEATH TRACKING TABLE LEAK TEST (BUG-013)")
print("========================================")

-- Get the GameManager instance (assuming it's a singleton accessed via MainServer)
-- For testing purposes, we'll create a mock player simulation
local function createMockPlayer(userId, userName)
	-- Create a mock player object with required properties
	local mockPlayer = {
		UserId = userId,
		Name = userName,
		Character = nil,
		Parent = game.Players
	}
	return mockPlayer
end

-- Function to count table entries
local function countTableEntries(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

-- Test function
local function runLeakTest()
	print("\n[TEST] Starting memory leak test...")
	print("[TEST] Simulating 1000 player join/leave cycles")
	
	-- Create a new GameManager instance for testing
	local gm = GameManager.new()
	gm:initialize()
	
	-- Track table sizes before test
	local initialStats = {
		playerStats = countTableEntries(gm.playerStats),
		deathDebounce = countTableEntries(gm._deathDebounce),
		deathConnections = countTableEntries(gm._deathConnections),
		spectatorCycleCooldown = countTableEntries(gm._spectatorCycleCooldown),
		playersReadyForEpilogue = countTableEntries(gm.playersReadyForEpilogue),
		playersCompletedEpilogue = countTableEntries(gm.playersCompletedEpilogue),
		characterAddedConnections = countTableEntries(gm._characterAddedConnections or {})
	}
	
	print(string.format("\n[BEFORE TEST] Table sizes:"))
	print(string.format("  playerStats: %d", initialStats.playerStats))
	print(string.format("  _deathDebounce: %d", initialStats.deathDebounce))
	print(string.format("  _deathConnections: %d", initialStats.deathConnections))
	print(string.format("  _spectatorCycleCooldown: %d", initialStats.spectatorCycleCooldown))
	print(string.format("  playersReadyForEpilogue: %d", initialStats.playersReadyForEpilogue))
	print(string.format("  playersCompletedEpilogue: %d", initialStats.playersCompletedEpilogue))
	print(string.format("  _characterAddedConnections: %d", initialStats.characterAddedConnections))
	
	-- Simulate 1000 player join/leave cycles
	local testIterations = 1000
	for i = 1, testIterations do
		local userId = 1000000 + i
		local mockPlayer = createMockPlayer(userId, "TestPlayer" .. i)
		
		-- Initialize player stats (simulates player joining)
		gm:initializePlayerStats(mockPlayer)
		gm._deathDebounce[userId] = true
		gm._spectatorCycleCooldown[userId] = os.clock()
		gm.playersReadyForEpilogue[userId] = true
		gm.playersCompletedEpilogue[userId] = false
		
		-- Simulate player leaving
		gm:onPlayerRemoving(mockPlayer)
		
		-- Progress indicator
		if i % 100 == 0 then
			print(string.format("[PROGRESS] %d/%d player cycles completed", i, testIterations))
		end
	end
	
	-- Track table sizes after test
	local finalStats = {
		playerStats = countTableEntries(gm.playerStats),
		deathDebounce = countTableEntries(gm._deathDebounce),
		deathConnections = countTableEntries(gm._deathConnections),
		spectatorCycleCooldown = countTableEntries(gm._spectatorCycleCooldown),
		playersReadyForEpilogue = countTableEntries(gm.playersReadyForEpilogue),
		playersCompletedEpilogue = countTableEntries(gm.playersCompletedEpilogue),
		characterAddedConnections = countTableEntries(gm._characterAddedConnections or {})
	}
	
	print(string.format("\n[AFTER TEST] Table sizes:"))
	print(string.format("  playerStats: %d", finalStats.playerStats))
	print(string.format("  _deathDebounce: %d", finalStats.deathDebounce))
	print(string.format("  _deathConnections: %d", finalStats.deathConnections))
	print(string.format("  _spectatorCycleCooldown: %d", finalStats.spectatorCycleCooldown))
	print(string.format("  playersReadyForEpilogue: %d", finalStats.playersReadyForEpilogue))
	print(string.format("  playersCompletedEpilogue: %d", finalStats.playersCompletedEpilogue))
	print(string.format("  _characterAddedConnections: %d", finalStats.characterAddedConnections))
	
	-- Calculate growth
	local growth = {
		playerStats = finalStats.playerStats - initialStats.playerStats,
		deathDebounce = finalStats.deathDebounce - initialStats.deathDebounce,
		deathConnections = finalStats.deathConnections - initialStats.deathConnections,
		spectatorCycleCooldown = finalStats.spectatorCycleCooldown - initialStats.spectatorCycleCooldown,
		playersReadyForEpilogue = finalStats.playersReadyForEpilogue - initialStats.playersReadyForEpilogue,
		playersCompletedEpilogue = finalStats.playersCompletedEpilogue - initialStats.playersCompletedEpilogue,
		characterAddedConnections = finalStats.characterAddedConnections - initialStats.characterAddedConnections
	}
	
	print(string.format("\n[GROWTH] Table growth after %d cycles:", testIterations))
	print(string.format("  playerStats: %+d", growth.playerStats))
	print(string.format("  _deathDebounce: %+d", growth.deathDebounce))
	print(string.format("  _deathConnections: %+d", growth.deathConnections))
	print(string.format("  _spectatorCycleCooldown: %+d", growth.spectatorCycleCooldown))
	print(string.format("  playersReadyForEpilogue: %+d", growth.playersReadyForEpilogue))
	print(string.format("  playersCompletedEpilogue: %+d", growth.playersCompletedEpilogue))
	print(string.format("  _characterAddedConnections: %+d", growth.characterAddedConnections))
	
	-- Determine if test passed
	local totalGrowth = growth.playerStats + growth.deathDebounce + growth.deathConnections + 
	                    growth.spectatorCycleCooldown + growth.playersReadyForEpilogue + 
	                    growth.playersCompletedEpilogue + growth.characterAddedConnections
	
	print("\n========================================")
	print("SUMMARY")
	print("========================================")
	print(string.format("Test iterations: %d", testIterations))
	print(string.format("Total table growth: %d entries", totalGrowth))
	
	if totalGrowth == 0 then
		print("\n✅ TEST PASSED - No memory leaks detected!")
		print("All tables properly cleaned up on player removal.")
	else
		print("\n❌ TEST FAILED - Memory leak detected!")
		print("The following tables are leaking:")
		
		if growth.playerStats > 0 then
			print(string.format("  ❌ playerStats: +%d entries (LEAK)", growth.playerStats))
		end
		if growth.deathDebounce > 0 then
			print(string.format("  ❌ _deathDebounce: +%d entries (LEAK)", growth.deathDebounce))
		end
		if growth.deathConnections > 0 then
			print(string.format("  ❌ _deathConnections: +%d entries (LEAK)", growth.deathConnections))
		end
		if growth.spectatorCycleCooldown > 0 then
			print(string.format("  ❌ _spectatorCycleCooldown: +%d entries (LEAK)", growth.spectatorCycleCooldown))
		end
		if growth.playersReadyForEpilogue > 0 then
			print(string.format("  ❌ playersReadyForEpilogue: +%d entries (LEAK)", growth.playersReadyForEpilogue))
		end
		if growth.playersCompletedEpilogue > 0 then
			print(string.format("  ❌ playersCompletedEpilogue: +%d entries (LEAK)", growth.playersCompletedEpilogue))
		end
		if growth.characterAddedConnections > 0 then
			print(string.format("  ❌ _characterAddedConnections: +%d entries (LEAK)", growth.characterAddedConnections))
		end
	end
	
	print("========================================\n")
	
	return totalGrowth == 0
end

-- Run the test
local success, error = pcall(runLeakTest)

if not success then
	print("\n❌ TEST ERROR:")
	print(error)
end
