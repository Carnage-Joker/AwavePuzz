-- ConfigurationTests.lua
-- Tests for all configuration modules to ensure proper setup
-- Tests GameConfig, WaveConfig, WeaponConfig, MapConfig, and other configs

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestFramework = require(script.Parent.TestFramework)

local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)

local suite = TestFramework:createSuite("ConfigurationTests")

--------------------------------------------------------------------------------
-- GameConfig Tests
--------------------------------------------------------------------------------

suite.tests["GameConfig_AllRequiredFields"] = function()
	TestFramework:info("Testing GameConfig has all required configuration fields...")
	
	local GameConfig = require(SharedFolder:WaitForChild("GameConfig", 5))
	
	local requiredFields = {
		"MAX_PLAYERS", "STARTING_HEALTH", "BASE_HEALTH",
		"WAVE_INTERMISSION", "CURE_COMPONENT_NAMES",
		"CURE_COMPONENTS_REQUIRED", "RESOURCE_SPAWN_RATE",
		"ZOMBIE_SPAWN_DELAY", "DEBUG"
	}
	
	for _, field in ipairs(requiredFields) do
		TestFramework:assertNotNil(GameConfig[field], 
			string.format("GameConfig.%s should exist", field))
		TestFramework:debug("✓ Field exists: %s = %s", field, tostring(GameConfig[field]))
	end
	
	TestFramework:debug("All required GameConfig fields present")
end

--------------------------------------------------------------------------------
-- WaveConfig Tests
--------------------------------------------------------------------------------

suite.tests["WaveConfig_LoadsSuccessfully"] = function()
	TestFramework:info("Testing WaveConfig module loading...")
	
	local WaveConfig = require(SharedFolder:WaitForChild("WaveConfig", 5))
	
	TestFramework:assertNotNil(WaveConfig, "WaveConfig should load")
	TestFramework:assertType(WaveConfig, "table", "WaveConfig should be a table")
	
	TestFramework:debug("WaveConfig loaded successfully")
end

suite.tests["WaveConfig_HasWaveDefinitions"] = function()
	TestFramework:info("Testing WaveConfig has wave definitions...")
	
	local WaveConfig = require(SharedFolder:WaitForChild("WaveConfig", 5))
	
	TestFramework:assertNotNil(WaveConfig.Waves, "WaveConfig.Waves should exist")
	TestFramework:assertType(WaveConfig.Waves, "table", "Waves should be a table")
	
	local waveCount = #WaveConfig.Waves
	TestFramework:assertGreaterThan(waveCount, 0, "Should have at least one wave")
	TestFramework:debug("Found %d wave definitions", waveCount)
	
	-- Validate first wave structure
	local wave1 = WaveConfig.Waves[1]
	TestFramework:assertNotNil(wave1.ZombieCount, "Wave 1 should have ZombieCount")
	TestFramework:assertNotNil(wave1.Types, "Wave 1 should have Types")
	
	TestFramework:debug("Wave definitions validated")
end

--------------------------------------------------------------------------------
-- MapConfig Tests
--------------------------------------------------------------------------------

suite.tests["MapConfig_LoadsSuccessfully"] = function()
	TestFramework:info("Testing MapConfig module loading...")
	
	local MapConfig = require(SharedFolder:WaitForChild("MapConfig", 5))
	
	TestFramework:assertNotNil(MapConfig, "MapConfig should load")
	TestFramework:assertType(MapConfig, "table", "MapConfig should be a table")
	
	TestFramework:debug("MapConfig loaded successfully")
end

suite.tests["MapConfig_HasMaps"] = function()
	TestFramework:info("Testing MapConfig has map definitions...")
	
	local MapConfig = require(SharedFolder:WaitForChild("MapConfig", 5))
	
	TestFramework:assertNotNil(MapConfig.Maps, "MapConfig.Maps should exist")
	TestFramework:assertType(MapConfig.Maps, "table", "Maps should be a table")
	
	local mapCount = 0
	for mapId, mapData in pairs(MapConfig.Maps) do
		mapCount = mapCount + 1
		TestFramework:debug("Found map: %s - %s", mapId, mapData.Name or "Unnamed")
		
		TestFramework:assertNotNil(mapData.Name, string.format("Map %s should have Name", mapId))
		TestFramework:assertNotNil(mapData.Model, string.format("Map %s should have Model", mapId))
	end
	
	TestFramework:assertGreaterThan(mapCount, 0, "Should have at least one map")
	TestFramework:debug("Found %d map definitions", mapCount)
end

--------------------------------------------------------------------------------
-- FPSConfig Tests
--------------------------------------------------------------------------------

suite.tests["FPSConfig_LoadsSuccessfully"] = function()
	TestFramework:info("Testing FPSConfig module loading...")
	
	local FPSConfig = SharedFolder:FindFirstChild("FPSConfig")
	if not FPSConfig then
		TestFramework:warn("FPSConfig not found (may be optional)")
		return
	end
	
	local config = require(FPSConfig)
	TestFramework:assertNotNil(config, "FPSConfig should load")
	TestFramework:assertType(config, "table", "FPSConfig should be a table")
	
	TestFramework:debug("FPSConfig loaded successfully")
end

--------------------------------------------------------------------------------
-- AssetValidation Tests
--------------------------------------------------------------------------------

suite.tests["AssetValidation_LoadsSuccessfully"] = function()
	TestFramework:info("Testing AssetValidation module loading...")
	
	local AssetValidation = SharedFolder:FindFirstChild("AssetValidation")
	if not AssetValidation then
		TestFramework:warn("AssetValidation not found (may be optional)")
		return
	end
	
	local module = require(AssetValidation)
	TestFramework:assertNotNil(module, "AssetValidation should load")
	TestFramework:assertType(module, "table", "AssetValidation should be a table")
	
	TestFramework:debug("AssetValidation loaded successfully")
end

--------------------------------------------------------------------------------
-- ModalManager Tests
--------------------------------------------------------------------------------

suite.tests["ModalManager_LoadsSuccessfully"] = function()
	TestFramework:info("Testing ModalManager module loading...")
	
	local ModalManager = SharedFolder:FindFirstChild("ModalManager")
	if not ModalManager then
		TestFramework:warn("ModalManager not found (may be optional)")
		return
	end
	
	local module = require(ModalManager)
	TestFramework:assertNotNil(module, "ModalManager should load")
	TestFramework:assertType(module, "table", "ModalManager should be a table")
	
	-- Check for key methods
	if module.isActive then
		TestFramework:assertType(module.isActive, "function", "isActive should be a function")
		TestFramework:debug("✓ ModalManager.isActive method exists")
	end
	
	TestFramework:debug("ModalManager loaded successfully")
end

--------------------------------------------------------------------------------
-- InputActionRegistry Tests
--------------------------------------------------------------------------------

suite.tests["InputActionRegistry_LoadsSuccessfully"] = function()
	TestFramework:info("Testing InputActionRegistry module loading...")
	
	local InputActionRegistry = SharedFolder:FindFirstChild("InputActionRegistry")
	if not InputActionRegistry then
		TestFramework:warn("InputActionRegistry not found (may be optional)")
		return
	end
	
	local module = require(InputActionRegistry)
	TestFramework:assertNotNil(module, "InputActionRegistry should load")
	TestFramework:assertType(module, "table", "InputActionRegistry should be a table")
	
	-- Check for key methods
	local keyMethods = {"enable", "disable", "enableOwner", "disableOwner"}
	for _, methodName in ipairs(keyMethods) do
		if module[methodName] then
			TestFramework:assertType(module[methodName], "function",
				string.format("%s should be a function", methodName))
			TestFramework:debug("✓ InputActionRegistry.%s method exists", methodName)
		end
	end
	
	TestFramework:debug("InputActionRegistry loaded successfully")
end

return suite
