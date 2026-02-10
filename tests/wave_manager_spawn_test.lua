-- wave_manager_spawn_test.lua
-- Test script to verify WaveManager queue-based spawning prevents race conditions
-- Run this in Roblox Studio Server console to test concurrent spawn behavior

local ServerScriptService = game:GetService("ServerScriptService")

-- Load WaveManager
local WaveManager = require(ServerScriptService:WaitForChild("WaveManager"))

print("==============================================")
print("=== WAVE MANAGER SPAWN RACE CONDITION TEST ===")
print("==============================================")

local function testConcurrentSpawning()
	print("\n--- Test 1: Concurrent Spawning ---")
	
	-- Create a new WaveManager instance
	local waveManager = WaveManager.new()
	
	-- Start wave 1
	local waveInfo = waveManager:startWave()
	print(string.format("Started Wave %d, Max Zombies: %d", waveInfo.waveNumber, waveInfo.zombieCount))
	
	-- Simulate concurrent spawn requests
	local successfulSpawns = 0
	local spawnMutex = false
	
	-- Fire multiple spawn requests concurrently (simulating race condition)
	for i = 1, waveInfo.zombieCount + 10 do -- Try to spawn more than max
		task.spawn(function()
			local result = waveManager:spawnZombie()
			if result ~= nil then
				-- Use atomic-like increment
				while spawnMutex do task.wait() end
				spawnMutex = true
				successfulSpawns = successfulSpawns + 1
				spawnMutex = false
			end
		end)
	end
	
	-- Allow all spawn tasks to complete before verification
	task.wait(0.5)
	
	-- Verify results
	print(string.format("Spawn requests: %d", waveInfo.zombieCount + 10))
	print(string.format("Successful spawns: %d", successfulSpawns))
	print(string.format("Expected max zombies: %d", waveInfo.zombieCount))
	print(string.format("Actual zombies spawned: %d", waveManager.zombiesSpawned))
	print(string.format("Actual zombies alive: %d", waveManager.zombiesAlive))
	
	-- Check if spawn count doesn't exceed max
	local test1Pass = waveManager.zombiesSpawned == waveInfo.zombieCount
	if test1Pass then
		print("✅ Test 1 PASSED: Spawn count matches max zombies exactly")
	else
		warn(string.format("❌ Test 1 FAILED: Expected %d zombies, got %d", waveInfo.zombieCount, waveManager.zombiesSpawned))
	end
	
	return test1Pass
end

local function testMultipleWavesSpawning()
	print("\n--- Test 2: Multiple Waves Sequential Spawning ---")
	
	local waveManager = WaveManager.new()
	local allWavesPass = true
	
	for wave = 1, 3 do
		local waveInfo = waveManager:startWave()
		print(string.format("\nWave %d - Max Zombies: %d", wave, waveInfo.zombieCount))
		
		-- Spawn all zombies for this wave
		local spawnedCount = 0
		for i = 1, waveInfo.zombieCount + 5 do
			local result = waveManager:spawnZombie()
			if result ~= nil then
				spawnedCount = spawnedCount + 1
			end
		end
		
		print(string.format("Wave %d spawned: %d / %d", wave, spawnedCount, waveInfo.zombieCount))
		
		if spawnedCount ~= waveInfo.zombieCount then
			warn(string.format("❌ Wave %d: Expected %d spawns, got %d", wave, waveInfo.zombieCount, spawnedCount))
			allWavesPass = false
		else
			print(string.format("✅ Wave %d: Correct spawn count", wave))
		end
		
		-- Simulate all zombies dying
		for i = 1, waveInfo.zombieCount do
			waveManager:onZombieDeath()
		end
	end
	
	if allWavesPass then
		print("\n✅ Test 2 PASSED: All waves spawned correct zombie count")
	else
		warn("\n❌ Test 2 FAILED: Some waves had incorrect spawn counts")
	end
	
	return allWavesPass
end

local function testQueueProcessing()
	print("\n--- Test 3: Queue Processing Under Load ---")
	
	local waveManager = WaveManager.new()
	local waveInfo = waveManager:startWave()
	
	-- Simulate rapid concurrent requests using task.spawn
	local totalRequests = waveInfo.zombieCount * 3 -- 3x the max zombies
	local completedRequests = 0
	local completionMutex = false
	
	for i = 1, totalRequests do
		task.spawn(function()
			waveManager:spawnZombie()
			-- Track completion
			while completionMutex do task.wait() end
			completionMutex = true
			completedRequests = completedRequests + 1
			completionMutex = false
		end)
	end
	
	-- Wait for all spawns to complete (deterministic)
	local maxWaitTime = 5 -- 5 second timeout
	local startTime = tick()
	while completedRequests < totalRequests and (tick() - startTime) < maxWaitTime do
		task.wait(0.1)
	end
	
	if completedRequests < totalRequests then
		warn(string.format("⚠️ Test 3 timeout: Only %d/%d requests completed", completedRequests, totalRequests))
	end
	
	print(string.format("Total spawn requests: %d", totalRequests))
	print(string.format("Actual zombies spawned: %d", waveManager.zombiesSpawned))
	print(string.format("Expected max zombies: %d", waveInfo.zombieCount))
	
	local test3Pass = waveManager.zombiesSpawned == waveInfo.zombieCount
	if test3Pass then
		print("✅ Test 3 PASSED: Queue prevented over-spawning under load")
	else
		warn(string.format("❌ Test 3 FAILED: Expected %d zombies, got %d", 
			waveInfo.zombieCount, waveManager.zombiesSpawned))
	end
	
	return test3Pass
end

local function testInactiveWaveSpawning()
	print("\n--- Test 4: Spawning When Wave Inactive ---")
	
	local waveManager = WaveManager.new()
	
	-- Try to spawn without starting a wave
	local result = waveManager:spawnZombie()
	
	local test4Pass = result == nil
	if test4Pass then
		print("✅ Test 4 PASSED: Cannot spawn when wave is inactive")
	else
		warn("❌ Test 4 FAILED: Spawned zombie when wave was inactive")
	end
	
	return test4Pass
end

-- Run all tests
print("\n" .. string.rep("=", 46))
print("RUNNING TESTS...")
print(string.rep("=", 46))

local test1 = testConcurrentSpawning()
local test2 = testMultipleWavesSpawning()
local test3 = testQueueProcessing()
local test4 = testInactiveWaveSpawning()

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
	print("Wave spawning race condition has been fixed.")
else
	warn(string.format("\n❌ %d TEST(S) FAILED", totalTests - passedTests))
	warn("Wave spawning race condition may still exist.")
end

print("\n" .. string.rep("=", 46))
print("=== TEST COMPLETE ===")
print(string.rep("=", 46))
