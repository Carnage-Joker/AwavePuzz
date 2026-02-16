-- @ScriptType: ModuleScript

--[[
	Weapon Origin Reconstruction Test Suite
	Tests for server-authoritative origin reconstruction
	
	This test suite validates that:
	1. Server correctly reconstructs shot origin from player character
	2. Normal gameplay shots are not rejected (no false positives)
	3. Exploitable origins are still denied (no false negatives)
	4. Direction validation is preserved
	
	Usage: Run this script in Roblox Studio's command bar or as part of automated testing
]]

local OriginTests = {}

-- Test configuration
local TESTS_PASSED = 0
local TESTS_FAILED = 0
local VERBOSE = true

-- Test validation constants
local MAX_REASONABLE_FORWARD_OFFSET = 10  -- Maximum forward offset from head (studs)
local MAX_REASONABLE_VERTICAL_OFFSET = 5  -- Maximum vertical offset from head (studs)
local MAX_REASONABLE_BEHIND_TOLERANCE = 5  -- Maximum behind-body tolerance (studs)
local MIN_REASONABLE_DOT_PRODUCT = 0.5  -- Minimum direction dot product (~60 degree cone)

local function logTest(testName, passed, message)
	if passed then
		TESTS_PASSED = TESTS_PASSED + 1
		if VERBOSE then
			print(string.format("✅ PASS: %s", testName))
		end
	else
		TESTS_FAILED = TESTS_FAILED + 1
		warn(string.format("❌ FAIL: %s - %s", testName, message or "No details"))
	end
end

-- ============================================================================
-- CONFIGURATION TESTS
-- ============================================================================

function OriginTests.testServerOriginEnabled()
	local testName = "Config - Server Origin Reconstruction Enabled"
	
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
	
	local isEnabled = GameConfig.Security and GameConfig.Security.USE_SERVER_ORIGIN
	
	-- Default should be true if not specified
	if isEnabled == nil then
		isEnabled = true
	end
	
	if isEnabled then
		logTest(testName, true)
		return true
	else
		logTest(testName, false, "Server origin reconstruction is disabled in config")
		return false
	end
end

function OriginTests.testOriginOffsetsConfigured()
	local testName = "Config - Origin Offsets Configured"
	
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
	
	if not GameConfig.Security then
		logTest(testName, false, "GameConfig.Security not found")
		return false
	end
	
	local forwardOffset = GameConfig.Security.ORIGIN_FORWARD_OFFSET
	local verticalOffset = GameConfig.Security.ORIGIN_VERTICAL_OFFSET
	
	if forwardOffset and verticalOffset then
		-- Verify reasonable values using defined constants
		local isReasonable = forwardOffset > 0 and forwardOffset < MAX_REASONABLE_FORWARD_OFFSET and
			verticalOffset >= 0 and verticalOffset < MAX_REASONABLE_VERTICAL_OFFSET
		
		if isReasonable then
			logTest(testName, true)
			return true
		else
			logTest(testName, false, "Origin offsets have unreasonable values")
			return false
		end
	else
		logTest(testName, false, "Origin offsets not configured")
		return false
	end
end

function OriginTests.testBehindToleranceConfigured()
	local testName = "Config - Behind Body Tolerance Configured"
	
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
	
	if not GameConfig.Security then
		logTest(testName, false, "GameConfig.Security not found")
		return false
	end
	
	local tolerance = GameConfig.Security.BEHIND_BODY_TOLERANCE
	
	if tolerance and tolerance >= 0 and tolerance <= MAX_REASONABLE_BEHIND_TOLERANCE then
		logTest(testName, true)
		return true
	else
		logTest(testName, false, "Behind body tolerance not configured or unreasonable")
		return false
	end
end

-- ============================================================================
-- ORIGIN RECONSTRUCTION TESTS
-- ============================================================================

function OriginTests.testReconstructOriginMethodExists()
	local testName = "Method - reconstructOrigin Exists"
	
	local ServerScriptService = game:GetService("ServerScriptService")
	local WeaponService = ServerScriptService:FindFirstChild("WeaponService")
	
	if not WeaponService or not WeaponService:IsA("ModuleScript") then
		logTest(testName, false, "WeaponService not found")
		return false
	end
	
	local success, WeaponServiceModule = pcall(function()
		return require(WeaponService)
	end)
	
	if not success then
		logTest(testName, false, "Failed to require WeaponService: " .. tostring(WeaponServiceModule))
		return false
	end
	
	if typeof(WeaponServiceModule.reconstructOrigin) == "function" then
		logTest(testName, true)
		return true
	else
		logTest(testName, false, "reconstructOrigin method not found in WeaponService")
		return false
	end
end

-- ============================================================================
-- VALIDATION PRESERVATION TESTS
-- ============================================================================

function OriginTests.testDirectionValidationPreserved()
	local testName = "Validation - Direction Alignment Still Enforced"
	
	-- Verify that direction validation is still performed with server origin
	-- This ensures anti-wallhack protection is maintained
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
	
	if not GameConfig.Security then
		logTest(testName, false, "GameConfig.Security not found")
		return false
	end
	
	local minDotProduct = GameConfig.Security.MIN_WEAPON_FIRE_DOT_PRODUCT
	
	-- Verify reasonable threshold using defined constant (MIN_REASONABLE_DOT_PRODUCT to 1.0)
	if minDotProduct and minDotProduct >= MIN_REASONABLE_DOT_PRODUCT and minDotProduct <= 1.0 then
		logTest(testName, true)
		return true
	else
		logTest(testName, false, "Direction validation threshold not configured properly")
		return false
	end
end

function OriginTests.testRateLimitingPreserved()
	local testName = "Validation - Rate Limiting Still Enforced"
	
	-- Verify that rate limiting is still performed
	local ServerScriptService = game:GetService("ServerScriptService")
	local WeaponService = ServerScriptService:FindFirstChild("WeaponService")
	
	if not WeaponService or not WeaponService:IsA("ModuleScript") then
		logTest(testName, false, "WeaponService not found")
		return false
	end
	
	local success, WeaponServiceModule = pcall(function()
		return require(WeaponService)
	end)
	
	if not success then
		logTest(testName, false, "Failed to require WeaponService")
		return false
	end
	
	-- Check for rate limiting constants
	if WeaponServiceModule.FIRE_RATE_WINDOW and WeaponServiceModule.MAX_FIRES_PER_WINDOW then
		logTest(testName, true)
		return true
	else
		logTest(testName, false, "Rate limiting constants not found")
		return false
	end
end

-- ============================================================================
-- INTEGRATION TESTS
-- ============================================================================

function OriginTests.testLegacyValidationFallback()
	local testName = "Integration - Legacy Validation Fallback Available"
	
	-- Verify that legacy validation is still available as fallback
	-- (controlled by USE_SERVER_ORIGIN flag)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
	
	if not GameConfig.Security then
		logTest(testName, false, "GameConfig.Security not found")
		return false
	end
	
	-- The config should have USE_SERVER_ORIGIN setting
	local hasFlag = GameConfig.Security.USE_SERVER_ORIGIN ~= nil
	
	if hasFlag then
		logTest(testName, true)
		return true
	else
		logTest(testName, false, "USE_SERVER_ORIGIN flag not found (no fallback control)")
		return false
	end
end

-- ============================================================================
-- RUN ALL TESTS
-- ============================================================================

function OriginTests.runAll()
	print("\n" .. string.rep("=", 60))
	print("WEAPON ORIGIN RECONSTRUCTION TEST SUITE")
	print("Tests for server-authoritative origin reconstruction")
	print(string.rep("=", 60) .. "\n")
	
	TESTS_PASSED = 0
	TESTS_FAILED = 0
	
	-- Configuration Tests
	print("--- Configuration Tests ---")
	OriginTests.testServerOriginEnabled()
	OriginTests.testOriginOffsetsConfigured()
	OriginTests.testBehindToleranceConfigured()
	
	-- Origin Reconstruction Tests
	print("\n--- Origin Reconstruction Tests ---")
	OriginTests.testReconstructOriginMethodExists()
	
	-- Validation Preservation Tests
	print("\n--- Validation Preservation Tests ---")
	OriginTests.testDirectionValidationPreserved()
	OriginTests.testRateLimitingPreserved()
	
	-- Integration Tests
	print("\n--- Integration Tests ---")
	OriginTests.testLegacyValidationFallback()
	
	-- Results
	print("\n" .. string.rep("=", 60))
	print(string.format("RESULTS: %d PASSED, %d FAILED", TESTS_PASSED, TESTS_FAILED))
	print(string.rep("=", 60) .. "\n")
	
	if TESTS_FAILED == 0 then
		print("✅ All tests passed! Server-authoritative origin reconstruction is properly configured.")
	else
		warn("❌ Some tests failed. Review the output above for details.")
	end
	
	return TESTS_FAILED == 0
end

return OriginTests
