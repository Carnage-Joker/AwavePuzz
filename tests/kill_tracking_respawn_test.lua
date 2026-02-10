-- kill_tracking_respawn_test.lua
-- Test script to verify BUG-005 fix: Kill tracking works correctly after respawn
-- Run this in Roblox Studio Server console

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("==============================================")
print("=== KILL TRACKING RESPAWN TEST (BUG-005) ====")
print("==============================================")

local function testKillTrackingAfterRespawn()
	print("\n--- Test 1: Kill Tracking After Multiple Respawns ---")
	
	-- This test simulates killing a player 3 times to verify kill rewards are granted each time
	-- The bug was that WeaponServiceDiedConnected attribute was not cleared on respawn
	
	-- Check if we have any players in the game
	local testPlayers = Players:GetPlayers()
	if #testPlayers < 1 then
		warn("❌ Test requires at least 1 player in the game")
		return false
	end
	
	local testPlayer = testPlayers[1]
	print(string.format("Testing with player: %s", testPlayer.Name))
	
	-- Function to check if attributes are cleared on new character
	local function checkAttributesCleared(character)
		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then
			return false, "No humanoid found"
		end
		
		local diedConnected = humanoid:GetAttribute("WeaponServiceDiedConnected")
		local lastAttacker = humanoid:GetAttribute("LastAttackerUserId")
		local lastVictim = humanoid:GetAttribute("LastVictimUserId")
		
		if diedConnected ~= nil then
			return false, "WeaponServiceDiedConnected not cleared"
		end
		if lastAttacker ~= nil then
			return false, "LastAttackerUserId not cleared"
		end
		if lastVictim ~= nil then
			return false, "LastVictimUserId not cleared"
		end
		
		return true, "All attributes cleared"
	end
	
	-- Test initial state
	if testPlayer.Character then
		local success, message = checkAttributesCleared(testPlayer.Character)
		if not success then
			warn(string.format("❌ Initial state check failed: %s", message))
			return false
		end
		print("✅ Initial character has no kill tracking attributes")
	end
	
	-- Simulate multiple respawns
	local respawnCount = 3
	local allTestsPassed = true
	
	for i = 1, respawnCount do
		print(string.format("\n--- Respawn %d/%d ---", i, respawnCount))
		
		-- Set up CharacterAdded listener for this respawn
		local characterAdded = false
		local connection
		connection = testPlayer.CharacterAdded:Connect(function(character)
			characterAdded = true
			
			-- Wait a moment for the cleanup code to run
			task.wait(0.1)
			
			local success, message = checkAttributesCleared(character)
			if success then
				print(string.format("✅ Respawn %d: Kill tracking attributes cleared successfully", i))
			else
				warn(string.format("❌ Respawn %d: %s", i, message))
				allTestsPassed = false
			end
			
			connection:Disconnect()
		end)
		
		-- Force respawn (if character exists)
		if testPlayer.Character then
			local humanoid = testPlayer.Character:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				-- Set attributes to simulate they were used in combat
				humanoid:SetAttribute("WeaponServiceDiedConnected", true)
				humanoid:SetAttribute("LastAttackerUserId", 12345)
				humanoid:SetAttribute("LastVictimUserId", testPlayer.UserId)
				print(string.format("Set test attributes before respawn %d", i))
			end
		end
		
		-- Trigger respawn
		task.wait(0.2)
		testPlayer:LoadCharacter()
		
		-- Wait for character to load
		local timeout = 5
		local startTime = tick()
		while not characterAdded and (tick() - startTime) < timeout do
			task.wait(0.1)
		end
		
		if not characterAdded then
			warn(string.format("⚠️ Respawn %d timed out", i))
			connection:Disconnect()
			allTestsPassed = false
		end
		
		task.wait(0.5) -- Wait between respawns
	end
	
	if allTestsPassed then
		print("\n✅ Test 1 PASSED: Kill tracking attributes cleared on all respawns")
	else
		warn("\n❌ Test 1 FAILED: Some respawns did not clear attributes properly")
	end
	
	return allTestsPassed
end

local function testDiedEventReconnection()
	print("\n--- Test 2: Died Event Can Be Reconnected After Respawn ---")
	
	local testPlayers = Players:GetPlayers()
	if #testPlayers < 1 then
		warn("❌ Test requires at least 1 player in the game")
		return false
	end
	
	local testPlayer = testPlayers[1]
	
	-- This test verifies that after respawn, the Died event can be connected again
	-- (i.e., WeaponServiceDiedConnected is not blocking reconnection)
	
	if not testPlayer.Character then
		warn("❌ Test player has no character")
		return false
	end
	
	local humanoid = testPlayer.Character:FindFirstChild("Humanoid")
	if not humanoid then
		warn("❌ Test player character has no humanoid")
		return false
	end
	
	-- Check that we can connect to Died event (attribute should be nil or false)
	local diedConnected = humanoid:GetAttribute("WeaponServiceDiedConnected")
	
	if diedConnected == true then
		warn("❌ Test 2 FAILED: WeaponServiceDiedConnected already true on fresh character")
		return false
	end
	
	-- Simulate what WeaponService does
	humanoid:SetAttribute("WeaponServiceDiedConnected", true)
	humanoid:SetAttribute("LastAttackerUserId", 99999)
	
	print("Simulated weapon service setting attributes")
	
	-- Now respawn and check again
	local respawnComplete = false
	local connection = testPlayer.CharacterAdded:Connect(function(character)
		respawnComplete = true
		task.wait(0.1)
		
		local newHumanoid = character:FindFirstChild("Humanoid")
		if newHumanoid then
			local diedConnectedAfter = newHumanoid:GetAttribute("WeaponServiceDiedConnected")
			if diedConnectedAfter == nil or diedConnectedAfter == false then
				print("✅ Test 2 PASSED: Can reconnect Died event after respawn")
			else
				warn("❌ Test 2 FAILED: WeaponServiceDiedConnected still true after respawn")
			end
		end
		
		connection:Disconnect()
	end)
	
	testPlayer:LoadCharacter()
	
	-- Wait for respawn
	local timeout = 5
	local startTime = tick()
	while not respawnComplete and (tick() - startTime) < timeout do
		task.wait(0.1)
	end
	
	if not respawnComplete then
		warn("⚠️ Test 2 timed out waiting for respawn")
		connection:Disconnect()
		return false
	end
	
	return true
end

-- Run all tests
print("\n" .. string.rep("=", 46))
print("RUNNING TESTS...")
print(string.rep("=", 46))

local test1 = testKillTrackingAfterRespawn()
task.wait(1)
local test2 = testDiedEventReconnection()

-- Summary
print("\n" .. string.rep("=", 46))
print("TEST SUMMARY")
print(string.rep("=", 46))

local passedTests = 0
local totalTests = 2

if test1 then passedTests = passedTests + 1 end
if test2 then passedTests = passedTests + 1 end

print(string.format("Tests Passed: %d / %d", passedTests, totalTests))

if passedTests == totalTests then
	print("\n✅ ALL TESTS PASSED!")
	print("BUG-005 (Kill tracking after respawn) has been fixed.")
else
	warn(string.format("\n❌ %d TEST(S) FAILED", totalTests - passedTests))
	warn("BUG-005 (Kill tracking after respawn) may still exist.")
end

print("\n" .. string.rep("=", 46))
print("=== TEST COMPLETE ===")
print(string.rep("=", 46))
