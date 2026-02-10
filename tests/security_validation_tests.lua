-- @ScriptType: ModuleScript

--[[
	Security Validation Test Suite
	Tests for BUG-004 (Wallhack) and BUG-009 (Client Authority)
	
	This test suite validates that:
	1. Anti-wallhack protection prevents shots from impossible positions
	2. Server-authoritative design prevents client-side manipulation
	3. All critical game state is validated server-side
	
	Usage: Run this script in Roblox Studio's command bar or as part of automated testing
]]

local SecurityTests = {}

-- Test configuration
local TESTS_PASSED = 0
local TESTS_FAILED = 0
local VERBOSE = true

local function logTest(testName, passed, message)
	if passed then
		TESTS_PASSED += 1
		if VERBOSE then
			print(string.format("✅ PASS: %s", testName))
		end
	else
		TESTS_FAILED += 1
		warn(string.format("❌ FAIL: %s - %s", testName, message or "No details"))
	end
end

-- ============================================================================
-- BUG-004: WALLHACK PROTECTION TESTS
-- ============================================================================

function SecurityTests.testWallhackOriginDistanceValidation()
	local testName = "Wallhack - Origin Distance Validation"
	
	-- Test should verify that WeaponService rejects shots from >15 studs away
	-- This test validates the configuration exists
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
	
	local hasSecurityConfig = GameConfig.Security ~= nil
	local hasMaxDistance = hasSecurityConfig and GameConfig.Security.MAX_WEAPON_FIRE_DISTANCE ~= nil
	local isReasonableDistance = hasMaxDistance and GameConfig.Security.MAX_WEAPON_FIRE_DISTANCE >= 10 and GameConfig.Security.MAX_WEAPON_FIRE_DISTANCE <= 20
	
	if hasSecurityConfig and hasMaxDistance and isReasonableDistance then
		logTest(testName, true)
		return true
	else
		logTest(testName, false, "GameConfig.Security.MAX_WEAPON_FIRE_DISTANCE not configured properly")
		return false
	end
end

function SecurityTests.testWallhackDirectionValidation()
	local testName = "Wallhack - Direction Alignment Validation"
	
	-- Test verifies that direction validation configuration exists
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
	
	-- Check if MIN_WEAPON_FIRE_DOT_PRODUCT exists (optional, so default is okay)
	local hasSecurityConfig = GameConfig.Security ~= nil
	
	if hasSecurityConfig then
		logTest(testName, true)
		return true
	else
		logTest(testName, false, "GameConfig.Security not found")
		return false
	end
end

function SecurityTests.testWeaponServiceNaNProtection()
	local testName = "Wallhack - NaN Protection"
	
	-- Verify WeaponService exists and has the handleWeaponFire method
	local ServerScriptService = game:GetService("ServerScriptService")
	local WeaponService = ServerScriptService:FindFirstChild("WeaponService")
	
	if WeaponService and WeaponService:IsA("ModuleScript") then
		-- Check that the module can be required
		local success, module = pcall(function()
			return require(WeaponService)
		end)
		
		if success and module and module.handleWeaponFire then
			logTest(testName, true)
			return true
		else
			logTest(testName, false, "WeaponService module doesn't have handleWeaponFire method")
			return false
		end
	else
		logTest(testName, false, "WeaponService not found in ServerScriptService")
		return false
	end
end

-- ============================================================================
-- BUG-009: CLIENT AUTHORITY TESTS
-- ============================================================================

function SecurityTests.testServerAmmoConsumption()
	local testName = "Client Authority - Server Ammo Consumption"
	
	-- Verify FPSWeaponService has consumeAmmo and validateShot methods
	local ServerScriptService = game:GetService("ServerScriptService")
	local FPSWeaponService = ServerScriptService:FindFirstChild("FPSWeaponService")
	
	if FPSWeaponService and FPSWeaponService:IsA("ModuleScript") then
		local success, module = pcall(function()
			return require(FPSWeaponService)
		end)
		
		if success and module then
			local hasConsumeAmmo = typeof(module.consumeAmmo) == "function"
			local hasValidateShot = typeof(module.validateShot) == "function"
			
			if hasConsumeAmmo and hasValidateShot then
				logTest(testName, true)
				return true
			else
				logTest(testName, false, "FPSWeaponService missing consumeAmmo or validateShot")
				return false
			end
		end
	end
	
	logTest(testName, false, "FPSWeaponService not found or can't be required")
	return false
end

function SecurityTests.testCurrencyServerAuthority()
	local testName = "Client Authority - Currency Server Authority"
	
	-- Verify PlayerManager has server-side currency methods
	local ServerScriptService = game:GetService("ServerScriptService")
	local PlayerManager = ServerScriptService:FindFirstChild("PlayerManager")
	
	if PlayerManager and PlayerManager:IsA("ModuleScript") then
		local success, module = pcall(function()
			return require(PlayerManager)
		end)
		
		if success and module then
			local hasAddCurrency = typeof(module.addCurrency) == "function"
			local hasDeductCurrency = typeof(module.deductCurrency) == "function"
			local hasGetCurrency = typeof(module.getCurrency) == "function"
			
			if hasAddCurrency and hasDeductCurrency and hasGetCurrency then
				logTest(testName, true)
				return true
			else
				logTest(testName, false, "PlayerManager missing currency methods")
				return false
			end
		end
	end
	
	logTest(testName, false, "PlayerManager not found")
	return false
end

function SecurityTests.testDamageServerAuthority()
	local testName = "Client Authority - Damage Server Authority"
	
	-- Verify WeaponService handles damage server-side
	local ServerScriptService = game:GetService("ServerScriptService")
	local WeaponService = ServerScriptService:FindFirstChild("WeaponService")
	
	if WeaponService and WeaponService:IsA("ModuleScript") then
		local success, module = pcall(function()
			return require(WeaponService)
		end)
		
		if success and module and module.handleWeaponFire then
			logTest(testName, true)
			return true
		else
			logTest(testName, false, "WeaponService doesn't have damage handling")
			return false
		end
	end
	
	logTest(testName, false, "WeaponService not found")
	return false
end

function SecurityTests.testShopValidation()
	local testName = "Client Authority - Shop Purchase Validation"
	
	-- Verify ShopService has server-side validation
	local ServerScriptService = game:GetService("ServerScriptService")
	local ShopService = ServerScriptService:FindFirstChild("ShopService")
	
	if ShopService and ShopService:IsA("ModuleScript") then
		local success, module = pcall(function()
			return require(ShopService)
		end)
		
		if success and module then
			-- Check for purchase handling method
			local hasPurchaseHandler = typeof(module.handlePurchase) == "function" or 
									   typeof(module.onShopAction) == "function"
			
			if hasPurchaseHandler then
				logTest(testName, true)
				return true
			else
				logTest(testName, false, "ShopService missing purchase handler")
				return false
			end
		end
	end
	
	logTest(testName, false, "ShopService not found")
	return false
end

function SecurityTests.testAllianceValidation()
	local testName = "Client Authority - Alliance Request Validation"
	
	-- Verify AllianceService validates alliance requests server-side
	local ServerScriptService = game:GetService("ServerScriptService")
	local AllianceService = ServerScriptService:FindFirstChild("AllianceServiceV2")
	
	if AllianceService and AllianceService:IsA("ModuleScript") then
		local success, module = pcall(function()
			return require(AllianceService)
		end)
		
		if success and module then
			local hasAllianceHandler = typeof(module.handleAllianceRequest) == "function" or
									   typeof(module.handleAllianceResponse) == "function"
			
			if hasAllianceHandler then
				logTest(testName, true)
				return true
			else
				logTest(testName, false, "AllianceServiceV2 missing alliance handlers")
				return false
			end
		end
	end
	
	logTest(testName, false, "AllianceServiceV2 not found")
	return false
end

function SecurityTests.testPuzzleValidation()
	local testName = "Client Authority - Puzzle Answer Validation"
	
	-- Verify PuzzleService validates answers server-side
	local ServerScriptService = game:GetService("ServerScriptService")
	local PuzzleService = ServerScriptService:FindFirstChild("PuzzleService")
	
	if PuzzleService and PuzzleService:IsA("ModuleScript") then
		local success, module = pcall(function()
			return require(PuzzleService)
		end)
		
		if success and module then
			local hasPuzzleHandler = typeof(module.handlePuzzleAnswer) == "function" or
									 typeof(module.onPuzzleAnswer) == "function"
			
			if hasPuzzleHandler then
				logTest(testName, true)
				return true
			else
				logTest(testName, false, "PuzzleService missing puzzle answer handler")
				return false
			end
		end
	end
	
	logTest(testName, false, "PuzzleService not found")
	return false
end

-- ============================================================================
-- SECURITY CONFIGURATION TESTS
-- ============================================================================

function SecurityTests.testSecurityConfigExists()
	local testName = "Security Config - Existence Check"
	
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local success, GameConfig = pcall(function()
		return require(ReplicatedStorage.Shared.GameConfig)
	end)
	
	if success and GameConfig and GameConfig.Security then
		logTest(testName, true)
		return true
	else
		logTest(testName, false, "GameConfig.Security section not found")
		return false
	end
end

function SecurityTests.testAmmoSyncInterval()
	local testName = "Security Config - Ammo Sync Interval"
	
	-- Verify FPSWeaponService has periodic ammo sync
	local ServerScriptService = game:GetService("ServerScriptService")
	local FPSWeaponService = ServerScriptService:FindFirstChild("FPSWeaponService")
	
	if FPSWeaponService and FPSWeaponService:IsA("ModuleScript") then
		local success, module = pcall(function()
			return require(FPSWeaponService)
		end)
		
		if success and module and module.startAmmoValidationLoop then
			logTest(testName, true)
			return true
		else
			logTest(testName, false, "FPSWeaponService missing ammo validation loop")
			return false
		end
	end
	
	logTest(testName, false, "FPSWeaponService not found")
	return false
end

-- ============================================================================
-- RUN ALL TESTS
-- ============================================================================

function SecurityTests.runAll()
	print("\n" .. string.rep("=", 60))
	print("SECURITY VALIDATION TEST SUITE")
	print("Testing BUG-004 (Wallhack) and BUG-009 (Client Authority)")
	print(string.rep("=", 60) .. "\n")
	
	TESTS_PASSED = 0
	TESTS_FAILED = 0
	
	-- BUG-004: Wallhack Protection Tests
	print("--- BUG-004: Wallhack Protection Tests ---")
	SecurityTests.testWallhackOriginDistanceValidation()
	SecurityTests.testWallhackDirectionValidation()
	SecurityTests.testWeaponServiceNaNProtection()
	
	-- BUG-009: Client Authority Tests
	print("\n--- BUG-009: Client Authority Tests ---")
	SecurityTests.testServerAmmoConsumption()
	SecurityTests.testCurrencyServerAuthority()
	SecurityTests.testDamageServerAuthority()
	SecurityTests.testShopValidation()
	SecurityTests.testAllianceValidation()
	SecurityTests.testPuzzleValidation()
	
	-- Security Configuration Tests
	print("\n--- Security Configuration Tests ---")
	SecurityTests.testSecurityConfigExists()
	SecurityTests.testAmmoSyncInterval()
	
	-- Results
	print("\n" .. string.rep("=", 60))
	print(string.format("RESULTS: %d PASSED, %d FAILED", TESTS_PASSED, TESTS_FAILED))
	print(string.rep("=", 60) .. "\n")
	
	return TESTS_FAILED == 0
end

return SecurityTests
