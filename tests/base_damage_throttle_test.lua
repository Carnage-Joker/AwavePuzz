-- base_damage_throttle_test.lua
-- Test script to verify BaseManager per-attacker cooldown prevents instant melt
-- Run this in Roblox Studio Server console to test base damage throttling
--
-- USAGE:
-- 1. Copy this script to ServerScriptService in Studio
-- 2. Run in command bar: loadstring(game:GetService("ServerScriptService"):WaitForChild("tests").base_damage_throttle_test.Source)()
-- 3. Or create a Script and paste the content, then run

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load BaseManager
local BaseManager = require(ServerScriptService:WaitForChild("BaseManager"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

print("==============================================")
print("===   BASE DAMAGE THROTTLE TEST            ===")
print("==============================================")

-- Test configuration
local NUM_ZOMBIES = 10
local ZOMBIE_DAMAGE = 10
local BASE_HEALTH = 1000
local COOLDOWN = GameConfig.BASE_DAMAGE_COOLDOWN or 2.0

local function testWithoutThrottle()
	print("\n--- Test 1: Without Throttle (Expected: Instant Melt) ---")
	local baseManager = BaseManager.new()
	
	local startTime = tick()
	local attackCount = 0
	
	-- Simulate 10 zombies attacking 100 times each without cooldown
	for i = 1, NUM_ZOMBIES do
		for j = 1, 100 do
			attackCount = attackCount + 1
		end
	end
	
	local timeWithoutCooldown = (attackCount * ZOMBIE_DAMAGE) / BASE_HEALTH
	print(string.format("Without cooldown: %d attacks would destroy base in < %.1fs", attackCount, timeWithoutCooldown))
	print(string.format("Expected: Near-instant destruction (< 5 seconds)"))
end

local function testWithThrottle()
	print("\n--- Test 2: With Throttle (Expected: Controlled Damage) ---")
	local baseManager = BaseManager.new()
	
	-- Reset base to full health
	baseManager:reset({refreshMaxHealth = true})
	print(string.format("Initial Base Health: %.1f/%.1f", baseManager:getHealth(), baseManager.maxHealth))
	print(string.format("Cooldown per attacker: %.1fs", COOLDOWN))
	
	local startTime = tick()
	local successfulAttacks = 0
	local blockedAttacks = 0
	
	-- Simulate 10 zombies attacking rapidly (frame-by-frame)
	-- Each zombie tries to attack every 0.1 seconds
	-- Run long enough to potentially destroy base (up to 100 seconds)
	for wave = 1, 1000 do -- 100 seconds at 0.1s intervals
		for zombieId = 1, NUM_ZOMBIES do
			local zombieName = string.format("Zombie_%d", zombieId)
			local healthBefore = baseManager:getHealth()
			local destroyed = baseManager:damageBase(ZOMBIE_DAMAGE, zombieName)
			local healthAfter = baseManager:getHealth()
			
			-- Track if damage was actually applied
			if healthAfter < healthBefore then
				successfulAttacks = successfulAttacks + 1
			else
				blockedAttacks = blockedAttacks + 1
			end
			
			if destroyed or baseManager:isDestroyed() then
				break
			end
		end
		
		if baseManager:isDestroyed() then
			break
		end
		
		task.wait(0.1) -- Simulate 0.1s per wave
	end
	
	local endTime = tick()
	local duration = endTime - startTime
	
	print(string.format("\n--- Results ---"))
	print(string.format("Duration: %.1f seconds", duration))
	print(string.format("Final Base Health: %.1f/%.1f", baseManager:getHealth(), baseManager.maxHealth))
	print(string.format("Successful attacks: %d", successfulAttacks))
	print(string.format("Blocked attacks (cooldown): %d", blockedAttacks))
	print(string.format("Total attack attempts: %d", successfulAttacks + blockedAttacks))
	print(string.format("Base Destroyed: %s", tostring(baseManager:isDestroyed())))
	
	-- Calculate expected time to destruction
	local totalDamageNeeded = BASE_HEALTH
	local damagePerInterval = NUM_ZOMBIES * ZOMBIE_DAMAGE
	local expectedTime = (totalDamageNeeded / damagePerInterval) * COOLDOWN
	
	print(string.format("\n--- Analysis ---"))
	print(string.format("Expected time to destruction: %.1f seconds", expectedTime))
	print(string.format("Actual time: %.1f seconds", duration))
	
	-- Check if time is reasonable (should be in the 15-30s range with current settings)
	if duration >= 15 and duration <= 30 then
		print("✅ PASS: Time-to-destruction is within acceptable range (15-30s)")
		if duration >= 15 and duration <= 30 then
			print("✅ OPTIMAL: Time is in optimal range (15-30s)")
		end
	else
		print("❌ FAIL: Time-to-destruction is outside acceptable range")
	end
	
	if blockedAttacks > 0 then
		print(string.format("✅ PASS: Cooldown is working (%d attacks blocked)", blockedAttacks))
	else
		print("❌ FAIL: No attacks were blocked by cooldown")
	end
end

local function testMemoryCleanup()
	print("\n--- Test 3: Memory Cleanup ---")
	local baseManager = BaseManager.new()
	baseManager:reset({refreshMaxHealth = true})
	
	-- Simulate zombie attacks
	for i = 1, 5 do
		baseManager:damageBase(10, string.format("Zombie_%d", i))
	end
	
	-- Count cooldown entries before cleanup
	local entriesBefore = 0
	for _ in pairs(baseManager._attackerCooldowns) do
		entriesBefore = entriesBefore + 1
	end
	print(string.format("Cooldown entries before cleanup: %d", entriesBefore))
	
	-- Simulate zombie deaths by removing cooldowns
	for i = 1, 3 do
		baseManager:removeAttackerCooldown(string.format("Zombie_%d", i))
	end
	
	local remainingEntries = 0
	for _ in pairs(baseManager._attackerCooldowns) do
		remainingEntries = remainingEntries + 1
	end
	
	print(string.format("Cooldown entries after cleanup: %d", remainingEntries))
	
	if remainingEntries == 2 then
		print("✅ PASS: Memory cleanup working correctly")
	else
		print("❌ FAIL: Memory cleanup not working as expected")
	end
end

local function testSingleZombieCooldown()
	print("\n--- Test 4: Single Zombie Cooldown Enforcement ---")
	local baseManager = BaseManager.new()
	baseManager:reset({refreshMaxHealth = true})
	
	local zombieName = "TestZombie"
	local attacks = 0
	local lastHealth = baseManager:getBaseHealth()
	
	-- Try to attack 10 times rapidly
	for i = 1, 10 do
		baseManager:damageBase(ZOMBIE_DAMAGE, zombieName)
		
		local currentHealth = baseManager:getBaseHealth()
		if currentHealth < lastHealth then
			attacks = attacks + 1
			lastHealth = currentHealth
		end
		
		task.wait(0.1) -- 0.1s between attempts (faster than cooldown)
	end
	
	print(string.format("Attacks attempted: 10"))
	print(string.format("Successful attacks: %d", attacks))
	
	-- With 2s cooldown and 0.1s intervals, only first attack should succeed in first 1 second
	if attacks == 1 then
		print("✅ PASS: Single zombie cooldown working correctly")
	else
		print("❌ FAIL: Single zombie cooldown not enforcing properly")
	end
end

-- Run all tests
testWithoutThrottle()
testWithThrottle()
testMemoryCleanup()
testSingleZombieCooldown()

print("\n==============================================")
print("===   TEST COMPLETE                        ===")
print("==============================================")
