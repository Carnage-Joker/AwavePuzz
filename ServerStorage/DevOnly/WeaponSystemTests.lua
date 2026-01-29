-- WeaponSystemTests.lua
-- Tests for weapon systems: WeaponService, FPSWeaponService, FPSAnimationService
-- Tests weapon registration, firing, damage dealing, and ammo management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TestFramework = require(script.Parent.TestFramework)

-- Load shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
local WeaponConfig = require(SharedFolder:WaitForChild("WeaponConfig", 5))
local WeaponValues = SharedFolder:FindFirstChild("WeaponValues")

local suite = TestFramework:createSuite("WeaponSystemTests")

--------------------------------------------------------------------------------
-- WeaponConfig Tests
--------------------------------------------------------------------------------

suite.tests["WeaponConfig_LoadsSuccessfully"] = function()
	TestFramework:info("Testing WeaponConfig module loading...")
	
	TestFramework:assertNotNil(WeaponConfig, "WeaponConfig should load")
	TestFramework:assertType(WeaponConfig, "table", "WeaponConfig should be a table")
	
	TestFramework:debug("WeaponConfig loaded successfully")
end

suite.tests["WeaponConfig_HasWeapons"] = function()
	TestFramework:info("Testing WeaponConfig has weapon definitions...")
	
	TestFramework:assertNotNil(WeaponConfig.Weapons, "WeaponConfig.Weapons should exist")
	TestFramework:assertType(WeaponConfig.Weapons, "table", "Weapons should be a table")
	
	local weaponCount = 0
	for weaponName, weaponData in pairs(WeaponConfig.Weapons) do
		weaponCount = weaponCount + 1
		TestFramework:debug("Found weapon: %s", weaponName)
		
		-- Validate weapon data
		TestFramework:assertNotNil(weaponData.Damage, string.format("%s should have Damage", weaponName))
		TestFramework:assertNotNil(weaponData.FireRate, string.format("%s should have FireRate", weaponName))
		TestFramework:assertNotNil(weaponData.MagazineSize, string.format("%s should have MagazineSize", weaponName))
	end
	
	TestFramework:assertGreaterThan(weaponCount, 0, "Should have at least one weapon")
	TestFramework:debug("Found %d weapons", weaponCount)
end

suite.tests["WeaponConfig_ValidatesStats"] = function()
	TestFramework:info("Testing weapon stat validation...")
	
	for weaponName, weaponData in pairs(WeaponConfig.Weapons) do
		TestFramework:assertType(weaponData.Damage, "number",
			string.format("%s Damage should be a number", weaponName))
		TestFramework:assertGreaterThan(weaponData.Damage, 0,
			string.format("%s Damage should be positive", weaponName))
		
		TestFramework:assertType(weaponData.FireRate, "number",
			string.format("%s FireRate should be a number", weaponName))
		TestFramework:assertGreaterThan(weaponData.FireRate, 0,
			string.format("%s FireRate should be positive", weaponName))
		
		TestFramework:assertType(weaponData.MagazineSize, "number",
			string.format("%s MagazineSize should be a number", weaponName))
		TestFramework:assertGreaterThan(weaponData.MagazineSize, 0,
			string.format("%s MagazineSize should be positive", weaponName))
		
		TestFramework:debug("✓ %s stats validated", weaponName)
	end
	
	TestFramework:debug("All weapon stats are valid")
end

--------------------------------------------------------------------------------
-- WeaponService Tests
--------------------------------------------------------------------------------

suite.tests["WeaponService_LoadsSuccessfully"] = function()
	TestFramework:info("Testing WeaponService module loading...")
	
	local success, WeaponService = pcall(function()
		return require(ServerScriptService:WaitForChild("WeaponService", 5))
	end)
	
	TestFramework:assertTrue(success, "WeaponService should load without errors")
	TestFramework:assertNotNil(WeaponService, "WeaponService should not be nil")
	TestFramework:assertType(WeaponService, "table", "WeaponService should be a table")
	
	TestFramework:debug("WeaponService loaded successfully")
end

suite.tests["WeaponService_HasRequiredMethods"] = function()
	TestFramework:info("Testing WeaponService has required methods...")
	
	local WeaponService = require(ServerScriptService:WaitForChild("WeaponService", 5))
	
	local requiredMethods = {
		"new",
		"dealDamage",
		"registerZombie",
		"unregisterZombie",
		"setFPSWeaponService"
	}
	
	for _, methodName in ipairs(requiredMethods) do
		TestFramework:assertNotNil(WeaponService[methodName],
			string.format("WeaponService should have %s method", methodName))
		TestFramework:debug("✓ Method exists: %s", methodName)
	end
	
	TestFramework:debug("All required WeaponService methods present")
end

--------------------------------------------------------------------------------
-- FPSWeaponService Tests
--------------------------------------------------------------------------------

suite.tests["FPSWeaponService_LoadsSuccessfully"] = function()
	TestFramework:info("Testing FPSWeaponService module loading...")
	
	local success, FPSWeaponService = pcall(function()
		return require(ServerScriptService:WaitForChild("FPSWeaponService", 5))
	end)
	
	TestFramework:assertTrue(success, "FPSWeaponService should load without errors")
	TestFramework:assertNotNil(FPSWeaponService, "FPSWeaponService should not be nil")
	TestFramework:assertType(FPSWeaponService, "table", "FPSWeaponService should be a table")
	
	TestFramework:debug("FPSWeaponService loaded successfully")
end

suite.tests["FPSWeaponService_HasRequiredMethods"] = function()
	TestFramework:info("Testing FPSWeaponService has required methods...")
	
	local FPSWeaponService = require(ServerScriptService:WaitForChild("FPSWeaponService", 5))
	
	local requiredMethods = {
		"new",
		"addPlayer",
		"removePlayer",
		"equipWeapon",
		"reloadWeapon",
		"fireWeapon"
	}
	
	for _, methodName in ipairs(requiredMethods) do
		TestFramework:assertNotNil(FPSWeaponService[methodName],
			string.format("FPSWeaponService should have %s method", methodName))
		TestFramework:debug("✓ Method exists: %s", methodName)
	end
	
	TestFramework:debug("All required FPSWeaponService methods present")
end

--------------------------------------------------------------------------------
-- FPSAnimationService Tests
--------------------------------------------------------------------------------

suite.tests["FPSAnimationService_LoadsSuccessfully"] = function()
	TestFramework:info("Testing FPSAnimationService module loading...")
	
	local success, FPSAnimationService = pcall(function()
		return require(ServerScriptService:WaitForChild("FPSAnimationService", 5))
	end)
	
	TestFramework:assertTrue(success, "FPSAnimationService should load without errors")
	TestFramework:assertNotNil(FPSAnimationService, "FPSAnimationService should not be nil")
	TestFramework:assertType(FPSAnimationService, "table", "FPSAnimationService should be a table")
	
	TestFramework:debug("FPSAnimationService loaded successfully")
end

suite.tests["FPSAnimationService_HasRequiredMethods"] = function()
	TestFramework:info("Testing FPSAnimationService has required methods...")
	
	local FPSAnimationService = require(ServerScriptService:WaitForChild("FPSAnimationService", 5))
	
	local requiredMethods = {
		"new",
		"initialize"
	}
	
	for _, methodName in ipairs(requiredMethods) do
		TestFramework:assertNotNil(FPSAnimationService[methodName],
			string.format("FPSAnimationService should have %s method", methodName))
		TestFramework:debug("✓ Method exists: %s", methodName)
	end
	
	TestFramework:debug("All required FPSAnimationService methods present")
end

--------------------------------------------------------------------------------
-- WeaponValues Tests
--------------------------------------------------------------------------------

suite.tests["WeaponValues_ModuleExists"] = function()
	TestFramework:info("Testing WeaponValues module existence...")
	
	if WeaponValues then
		TestFramework:assertNotNil(WeaponValues, "WeaponValues should exist")
		TestFramework:debug("WeaponValues module found in Shared")
		
		local success, loadedValues = pcall(require, WeaponValues)
		TestFramework:assertTrue(success, "WeaponValues should load without errors")
		TestFramework:assertType(loadedValues, "table", "WeaponValues should be a table")
	else
		TestFramework:warn("WeaponValues module not found (may be optional)")
	end
end

--------------------------------------------------------------------------------
-- Weapon Configuration Validation
--------------------------------------------------------------------------------

suite.tests["WeaponConfig_RaycastParameters"] = function()
	TestFramework:info("Testing raycast parameters in WeaponConfig...")
	
	TestFramework:assertNotNil(WeaponConfig.RAYCAST_MAX_DISTANCE, "RAYCAST_MAX_DISTANCE should exist")
	TestFramework:assertType(WeaponConfig.RAYCAST_MAX_DISTANCE, "number", "RAYCAST_MAX_DISTANCE should be a number")
	TestFramework:assertGreaterThan(WeaponConfig.RAYCAST_MAX_DISTANCE, 0, "RAYCAST_MAX_DISTANCE should be positive")
	
	TestFramework:debug("Raycast max distance: %d studs", WeaponConfig.RAYCAST_MAX_DISTANCE)
end

suite.tests["WeaponConfig_HeadshotMultiplier"] = function()
	TestFramework:info("Testing headshot multiplier configuration...")
	
	if WeaponConfig.HEADSHOT_MULTIPLIER then
		TestFramework:assertType(WeaponConfig.HEADSHOT_MULTIPLIER, "number", "HEADSHOT_MULTIPLIER should be a number")
		TestFramework:assertGreaterThan(WeaponConfig.HEADSHOT_MULTIPLIER, 1, "HEADSHOT_MULTIPLIER should be > 1")
		
		TestFramework:debug("Headshot multiplier: %.1fx", WeaponConfig.HEADSHOT_MULTIPLIER)
	else
		TestFramework:warn("HEADSHOT_MULTIPLIER not found (may not be implemented)")
	end
end

return suite
