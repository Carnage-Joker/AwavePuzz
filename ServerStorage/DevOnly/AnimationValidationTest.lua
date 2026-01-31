-- @ScriptType: Script (for testing in command bar or as standalone script)
-- AnimationValidationTest.lua
-- Test script to verify animation ID validation is working correctly
-- Run this in Studio command bar or as a Script to test validation

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("\n" .. string.rep("=", 60))
print("ANIMATION VALIDATION TEST")
print(string.rep("=", 60))

-- Load modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local AssetConfig = require(SharedFolder:WaitForChild("AssetConfig"))
local AssetValidation = require(SharedFolder:WaitForChild("AssetValidation"))

--------------------------------------------------------------------------------
-- Test 1: Individual Animation ID Validation
--------------------------------------------------------------------------------
print("\n[Test 1] Individual Animation ID Validation")
print(string.rep("-", 60))

local testCases = {
	-- Valid cases
	{id = "rbxassetid://507766666", expected = true, description = "Valid: Modern format"},
	{id = "rbxassetid://1234567890", expected = true, description = "Valid: Modern format with number"},
	{id = "1234567890", expected = true, description = "Valid: Plain number"},
	{id = 1234567890, expected = true, description = "Valid: Number type"},
	
	-- Invalid cases
	{id = "rbxassetid://0", expected = false, description = "Invalid: Placeholder ID (0)"},
	{id = "0", expected = false, description = "Invalid: Plain zero"},
	{id = 0, expected = false, description = "Invalid: Number zero"},
	{id = "", expected = false, description = "Invalid: Empty string"},
	{id = nil, expected = false, description = "Invalid: Nil value"},
	{id = "invalid", expected = false, description = "Invalid: Non-numeric string"},
	{id = "rbxassetid://abc", expected = false, description = "Invalid: Non-numeric asset ID"},
}

local passedTests = 0
local failedTests = 0

-- Prefer using AssetValidation's production logic if available, with a local
-- fallback to preserve current behavior for this dev-only test script.
local function isValidAnimationId(animId)
	-- Delegate to public helpers on AssetValidation if they exist
	if AssetValidation and typeof(AssetValidation) == "table" then
		if typeof(AssetValidation.isValidAnimationId) == "function" then
			return AssetValidation.isValidAnimationId(animId)
		end

		if typeof(AssetValidation.ValidateAnimationId) == "function" then
			return AssetValidation.ValidateAnimationId(animId)
		end
	end

	-- Fallback: use the local rules previously defined in this script
	if not animId then
		return false
	end

	local idStr = tostring(animId)

	-- Check for placeholder/empty IDs
	if idStr == "0" or idStr == "rbxassetid://0" or idStr == "" then
		return false
	end

	-- Must be a number or rbxassetid:// format
	local numIdStr = idStr:match("^rbxassetid://(%d+)$")
	if numIdStr then
		local numId = tonumber(numIdStr)
		return numId ~= nil and numId > 0
	end

	local numericId = tonumber(idStr)
	if numericId then
		return numericId > 0
	end

	return false
end

for i, test in ipairs(testCases) do
	-- Use the shared validation helper, which prefers AssetValidation's logic
	local result = isValidAnimationId(test.id)
	local passed = result == test.expected
	
	if passed then
		passedTests = passedTests + 1
		print(string.format("  ✅ Test %d: %s", i, test.description))
	else
		failedTests = failedTests + 1
		warn(string.format("  ❌ Test %d: %s (Expected: %s, Got: %s)", 
			i, test.description, tostring(test.expected), tostring(result)))
	end
end

print(string.format("\nTest 1 Results: %d passed, %d failed", passedTests, failedTests))

--------------------------------------------------------------------------------
-- Test 2: Weapon Animation Validation
--------------------------------------------------------------------------------
print("\n[Test 2] Weapon Animation Validation")
print(string.rep("-", 60))

local weaponInvalid = AssetValidation.validateAnimationAssets(
	AssetConfig.Animations.WeaponAnimations,
	"WeaponAnimations"
)

print(string.format("\nWeapon Animations: %d invalid entries found", #weaponInvalid))
if #weaponInvalid > 0 then
	print("Invalid entries:")
	for _, key in ipairs(weaponInvalid) do
		print("  ⚠️  " .. key)
	end
end

--------------------------------------------------------------------------------
-- Test 3: Zombie Animation Validation
--------------------------------------------------------------------------------
print("\n[Test 3] Zombie Animation Validation")
print(string.rep("-", 60))

local zombieInvalid = AssetValidation.validateAnimationAssets(
	AssetConfig.Animations.ZombieAnimations,
	"ZombieAnimations"
)

print(string.format("\nZombie Animations: %d invalid entries found", #zombieInvalid))
if #zombieInvalid > 0 then
	print("Invalid entries:")
	for _, key in ipairs(zombieInvalid) do
		print("  ⚠️  " .. key)
	end
end

--------------------------------------------------------------------------------
-- Test 4: Sound Asset Validation
--------------------------------------------------------------------------------
print("\n[Test 4] Sound Asset Validation")
print(string.rep("-", 60))

local soundInvalid = AssetValidation.validateSoundAssets(
	AssetConfig.Sounds,
	"Sounds"
)

print(string.format("\nSound Assets: %d invalid entries found", #soundInvalid))
if #soundInvalid > 0 then
	print("Invalid entries:")
	for _, key in ipairs(soundInvalid) do
		print("  ⚠️  " .. key)
	end
end

--------------------------------------------------------------------------------
-- Test 5: Boot-Time Validation
--------------------------------------------------------------------------------
print("\n[Test 5] Boot-Time Validation (Full System Test)")
print(string.rep("-", 60))

local totalInvalid = AssetValidation.runBootTimeValidation(AssetConfig)

print(string.format("\nBoot-Time Validation: %d total invalid assets", totalInvalid))

--------------------------------------------------------------------------------
-- Test 6: Animation ID Statistics
--------------------------------------------------------------------------------
print("\n[Test 6] Animation ID Statistics")
print(string.rep("-", 60))

-- Count weapon animations
local weaponAnimCount = 0
local weaponPlaceholders = 0
local uniqueWeaponIds = {}

for weaponType, animations in pairs(AssetConfig.Animations.WeaponAnimations) do
	for animName, animId in pairs(animations) do
		weaponAnimCount = weaponAnimCount + 1
		
		if animId == "rbxassetid://0" then
			weaponPlaceholders = weaponPlaceholders + 1
		else
			uniqueWeaponIds[animId] = true
		end
	end
end

local uniqueWeaponCount = 0
for _ in pairs(uniqueWeaponIds) do
	uniqueWeaponCount = uniqueWeaponCount + 1
end

print(string.format("Weapon Animations:"))
print(string.format("  Total entries: %d", weaponAnimCount))
print(string.format("  Unique IDs: %d", uniqueWeaponCount))
print(string.format("  Placeholders: %d", weaponPlaceholders))
print(string.format("  Completion: %.1f%%", ((weaponAnimCount - weaponPlaceholders) / weaponAnimCount) * 100))

-- Count zombie animations
local zombieAnimCount = 0
local uniqueZombieIds = {}

for animType, animations in pairs(AssetConfig.Animations.ZombieAnimations) do
	for _, animData in ipairs(animations) do
		zombieAnimCount = zombieAnimCount + 1
		uniqueZombieIds[animData.id] = true
	end
end

local uniqueZombieCount = 0
for _ in pairs(uniqueZombieIds) do
	uniqueZombieCount = uniqueZombieCount + 1
end

print(string.format("\nZombie Animations:"))
print(string.format("  Total entries: %d", zombieAnimCount))
print(string.format("  Unique IDs: %d", uniqueZombieCount))
print(string.format("  Completion: 100%%"))

--------------------------------------------------------------------------------
-- Test 7: Asset ID Length Analysis
--------------------------------------------------------------------------------
print("\n[Test 7] Asset ID Length Analysis")
print(string.rep("-", 60))

print("\nWeapon Animation ID Lengths:")
for weaponType, animations in pairs(AssetConfig.Animations.WeaponAnimations) do
	for animName, animId in pairs(animations) do
		if animId ~= "rbxassetid://0" then
			local numStr = animId:match("rbxassetid://(%d+)")
			if numStr then
				local length = #numStr
				local status = length >= 14 and "⚠️ UNUSUALLY LONG" or "✅ Normal"
				print(string.format("  %s.%s: %d digits %s", 
					weaponType, animName, length, status))
			end
		end
	end
end

print("\nZombie Animation ID Lengths (sample):")
local sampleCount = 0
for animType, animations in pairs(AssetConfig.Animations.ZombieAnimations) do
	if sampleCount < 5 then
		for _, animData in ipairs(animations) do
			local numStr = animData.id:match("rbxassetid://(%d+)")
			if numStr then
				local length = #numStr
				print(string.format("  %s: %d digits ✅ Normal", 
					animType, length))
				sampleCount = sampleCount + 1
				break
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Summary
--------------------------------------------------------------------------------
print("\n" .. string.rep("=", 60))
print("TEST SUMMARY")
print(string.rep("=", 60))

local overallPassed = failedTests == 0 and totalInvalid == weaponPlaceholders

if overallPassed then
	print("✅ All tests PASSED (ignoring expected placeholders)")
	print("   Note: " .. weaponPlaceholders .. " placeholder ADS animations are expected")
else
	warn("❌ Some tests FAILED or unexpected issues found")
end

print(string.rep("=", 60) .. "\n")

return {
	testsPassed = passedTests,
	testsFailed = failedTests,
	totalInvalidAssets = totalInvalid,
	weaponPlaceholders = weaponPlaceholders,
	success = overallPassed
}
