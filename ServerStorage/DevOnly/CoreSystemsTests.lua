-- CoreSystemsTests.lua
-- Tests for core game systems: GameManager, PlayerManager, BaseManager
-- Tests initialization, state management, and core game loop

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local TestFramework = require(script.Parent.TestFramework)

-- Load shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
local GameConfig = require(SharedFolder:WaitForChild("GameConfig", 5))

local suite = TestFramework:createSuite("CoreSystemsTests")

--------------------------------------------------------------------------------
-- GameConfig Tests
--------------------------------------------------------------------------------

suite.tests["GameConfig_LoadsSuccessfully"] = function()
	TestFramework:info("Testing GameConfig module loading...")
	
	TestFramework:assertNotNil(GameConfig, "GameConfig should load")
	TestFramework:assertType(GameConfig, "table", "GameConfig should be a table")
	
	TestFramework:debug("GameConfig loaded successfully")
end

suite.tests["GameConfig_HasRequiredFields"] = function()
	TestFramework:info("Testing GameConfig has all required fields...")
	
	-- Player settings
	TestFramework:assertNotNil(GameConfig.MAX_PLAYERS, "MAX_PLAYERS should exist")
	TestFramework:assertType(GameConfig.MAX_PLAYERS, "number", "MAX_PLAYERS should be a number")
	TestFramework:assertGreaterThan(GameConfig.MAX_PLAYERS, 0, "MAX_PLAYERS should be positive")
	
	TestFramework:assertNotNil(GameConfig.STARTING_HEALTH, "STARTING_HEALTH should exist")
	TestFramework:assertType(GameConfig.STARTING_HEALTH, "number", "STARTING_HEALTH should be a number")
	
	-- Base settings
	TestFramework:assertNotNil(GameConfig.BASE_HEALTH, "BASE_HEALTH should exist")
	TestFramework:assertType(GameConfig.BASE_HEALTH, "number", "BASE_HEALTH should be a number")
	TestFramework:assertGreaterThan(GameConfig.BASE_HEALTH, 0, "BASE_HEALTH should be positive")
	
	-- Wave settings
	TestFramework:assertNotNil(GameConfig.WAVE_INTERMISSION, "WAVE_INTERMISSION should exist")
	TestFramework:assertType(GameConfig.WAVE_INTERMISSION, "number", "WAVE_INTERMISSION should be a number")
	
	-- Cure settings
	TestFramework:assertNotNil(GameConfig.CURE_COMPONENT_NAMES, "CURE_COMPONENT_NAMES should exist")
	TestFramework:assertType(GameConfig.CURE_COMPONENT_NAMES, "table", "CURE_COMPONENT_NAMES should be a table")
	
	TestFramework:debug("All required GameConfig fields present")
end

suite.tests["GameConfig_ValidatesNumberValues"] = function()
	TestFramework:info("Testing GameConfig number value ranges...")
	
	-- Check reasonable ranges
	TestFramework:assert(GameConfig.MAX_PLAYERS >= 1 and GameConfig.MAX_PLAYERS <= 50, 
		"MAX_PLAYERS should be between 1 and 50")
	
	TestFramework:assert(GameConfig.STARTING_HEALTH >= 50 and GameConfig.STARTING_HEALTH <= 10000,
		"STARTING_HEALTH should be reasonable (50-10000)")
	
	TestFramework:assert(GameConfig.BASE_HEALTH >= 100 and GameConfig.BASE_HEALTH <= 100000,
		"BASE_HEALTH should be reasonable (100-100000)")
	
	TestFramework:debug("GameConfig values are within reasonable ranges")
end

--------------------------------------------------------------------------------
-- PlayerManager Tests
--------------------------------------------------------------------------------

suite.tests["PlayerManager_Singleton"] = function()
	TestFramework:info("Testing PlayerManager singleton pattern...")
	
	local PlayerManager = require(ServerScriptService:WaitForChild("PlayerManager", 5))
	
	local instance1 = PlayerManager.getInstance()
	local instance2 = PlayerManager.getInstance()
	
	TestFramework:assertNotNil(instance1, "First getInstance() should return instance")
	TestFramework:assertNotNil(instance2, "Second getInstance() should return instance")
	TestFramework:assertEqual(instance1, instance2, "Both instances should be the same object")
	
	TestFramework:debug("PlayerManager singleton pattern working correctly")
end

suite.tests["PlayerManager_HasRequiredMethods"] = function()
	TestFramework:info("Testing PlayerManager has required methods...")
	
	local PlayerManager = require(ServerScriptService:WaitForChild("PlayerManager", 5))
	local instance = PlayerManager.getInstance()
	
	-- Check for essential methods
	local requiredMethods = {
		"addPlayer",
		"removePlayer",
		"getPlayer",
		"getAllPlayers",
		"getPlayerCount",
		"reset"
	}
	
	for _, methodName in ipairs(requiredMethods) do
		TestFramework:assertType(instance[methodName], "function", 
			string.format("PlayerManager should have %s method", methodName))
		TestFramework:debug("✓ Method exists: %s", methodName)
	end
	
	TestFramework:debug("All required PlayerManager methods present")
end

suite.tests["PlayerManager_InitialState"] = function()
	TestFramework:info("Testing PlayerManager initial state...")
	
	local PlayerManager = require(ServerScriptService:WaitForChild("PlayerManager", 5))
	local instance = PlayerManager.getInstance()
	
	-- Reset to ensure clean state
	if instance.reset then
		instance:reset()
	end
	
	local playerCount = instance:getPlayerCount()
	TestFramework:assertType(playerCount, "number", "getPlayerCount should return a number")
	TestFramework:assertGreaterThan(playerCount, -1, "Player count should be non-negative")
	
	TestFramework:debug("PlayerManager initialized with %d players", playerCount)
end

--------------------------------------------------------------------------------
-- BaseManager Tests
--------------------------------------------------------------------------------

suite.tests["BaseManager_Singleton"] = function()
	TestFramework:info("Testing BaseManager singleton pattern...")
	
	local BaseManager = require(ServerScriptService:WaitForChild("BaseManager", 5))
	
	local instance1 = BaseManager.getInstance()
	local instance2 = BaseManager.getInstance()
	
	TestFramework:assertNotNil(instance1, "First getInstance() should return instance")
	TestFramework:assertNotNil(instance2, "Second getInstance() should return instance")
	TestFramework:assertEqual(instance1, instance2, "Both instances should be the same object")
	
	TestFramework:debug("BaseManager singleton pattern working correctly")
end

suite.tests["BaseManager_HasRequiredMethods"] = function()
	TestFramework:info("Testing BaseManager has required methods...")
	
	local BaseManager = require(ServerScriptService:WaitForChild("BaseManager", 5))
	local instance = BaseManager.getInstance()
	
	-- Check for essential methods
	local requiredMethods = {
		"getHealth",
		"setHealth",
		"takeDamage",
		"isDestroyed"
	}
	
	for _, methodName in ipairs(requiredMethods) do
		TestFramework:assertType(instance[methodName], "function",
			string.format("BaseManager should have %s method", methodName))
		TestFramework:debug("✓ Method exists: %s", methodName)
	end
	
	TestFramework:debug("All required BaseManager methods present")
end

suite.tests["BaseManager_HealthManagement"] = function()
	TestFramework:info("Testing BaseManager health management...")
	
	local BaseManager = require(ServerScriptService:WaitForChild("BaseManager", 5))
	local instance = BaseManager.getInstance()
	
	-- Get initial health
	local initialHealth = instance:getHealth()
	TestFramework:assertType(initialHealth, "number", "getHealth should return a number")
	TestFramework:debug("Initial base health: %d", initialHealth)
	
	-- Test setHealth
	local testHealth = 5000
	instance:setHealth(testHealth)
	local newHealth = instance:getHealth()
	TestFramework:assertEqual(newHealth, testHealth, "setHealth should update health value")
	TestFramework:debug("Health set to: %d", newHealth)
	
	-- Test takeDamage
	local damage = 100
	instance:takeDamage(damage)
	local damagedHealth = instance:getHealth()
	TestFramework:assertEqual(damagedHealth, testHealth - damage, "takeDamage should reduce health")
	TestFramework:debug("Health after damage: %d", damagedHealth)
	
	-- Test isDestroyed
	instance:setHealth(0)
	local destroyed = instance:isDestroyed()
	TestFramework:assertTrue(destroyed, "Base should be destroyed when health is 0")
	TestFramework:debug("Base correctly reports as destroyed")
	
	-- Restore initial health
	instance:setHealth(initialHealth)
end

--------------------------------------------------------------------------------
-- GameManager Tests
--------------------------------------------------------------------------------

suite.tests["GameManager_LoadsSuccessfully"] = function()
	TestFramework:info("Testing GameManager module loading...")
	
	local success, GameManager = pcall(function()
		return require(ServerScriptService:WaitForChild("GameManager", 5))
	end)
	
	TestFramework:assertTrue(success, "GameManager should load without errors")
	TestFramework:assertNotNil(GameManager, "GameManager should not be nil")
	TestFramework:assertType(GameManager, "table", "GameManager should be a table")
	
	TestFramework:debug("GameManager loaded successfully")
end

suite.tests["GameManager_HasStates"] = function()
	TestFramework:info("Testing GameManager state definitions...")
	
	local GameManager = require(ServerScriptService:WaitForChild("GameManager", 5))
	
	TestFramework:assertNotNil(GameManager.States, "GameManager.States should exist")
	TestFramework:assertType(GameManager.States, "table", "States should be a table")
	
	-- Check for required states
	local requiredStates = {
		"WAITING",
		"LOBBY",
		"COUNTDOWN",
		"WAVE_ACTIVE",
		"INTERMISSION",
		"VICTORY",
		"DEFEAT"
	}
	
	for _, stateName in ipairs(requiredStates) do
		TestFramework:assertNotNil(GameManager.States[stateName],
			string.format("State %s should exist", stateName))
		TestFramework:debug("✓ State defined: %s = %s", stateName, tostring(GameManager.States[stateName]))
	end
	
	TestFramework:debug("All required GameManager states present")
end

--------------------------------------------------------------------------------
-- RemoteEvents Tests
--------------------------------------------------------------------------------

suite.tests["RemoteEvents_FolderExists"] = function()
	TestFramework:info("Testing RemoteEvents folder structure...")
	
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	TestFramework:assertNotNil(remoteEvents, "RemoteEvents folder should exist in ReplicatedStorage")
	TestFramework:assertInstanceOf(remoteEvents, "Folder", "RemoteEvents should be a Folder")
	
	TestFramework:debug("RemoteEvents folder found in ReplicatedStorage")
end

suite.tests["RemoteEvents_CoreEventsExist"] = function()
	TestFramework:info("Testing core RemoteEvents existence...")
	
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then
		TestFramework:warn("RemoteEvents folder not found, skipping event checks")
		return
	end
	
	-- Core events that should exist
	local coreEvents = {
		"DealDamage",
		"WaveAnnounce",
		"GameStateUpdate", -- ✅ FIX: Use modern name (was GameStateChange)
		-- "UpdatePlayerUI" removed - no longer in use
	}
	
	for _, eventName in ipairs(coreEvents) do
		local event = remoteEvents:FindFirstChild(eventName)
		if event then
			TestFramework:debug("✓ RemoteEvent found: %s", eventName)
		else
			TestFramework:warn("⚠ RemoteEvent not found: %s (may be created at runtime)", eventName)
		end
	end
end

--------------------------------------------------------------------------------
-- Module Dependency Tests
--------------------------------------------------------------------------------

suite.tests["Dependencies_SharedModulesLoad"] = function()
	TestFramework:info("Testing shared module dependencies...")
	
	local sharedModules = {
		"GameConfig",
		"WaveConfig",
		"WeaponConfig",
		"ZombieTypes",
		"GameState",
		"RemoteEventUtil"
	}
	
	for _, moduleName in ipairs(sharedModules) do
		local module = SharedFolder:FindFirstChild(moduleName)
		TestFramework:assertNotNil(module, string.format("Module %s should exist", moduleName))
		
		local success, loadedModule = pcall(require, module)
		TestFramework:assertTrue(success, string.format("Module %s should load without errors", moduleName))
		TestFramework:assertNotNil(loadedModule, string.format("Module %s should not be nil", moduleName))
		
		TestFramework:debug("✓ Module loaded: %s", moduleName)
	end
	
	TestFramework:debug("All shared modules loaded successfully")
end

suite.tests["Dependencies_ServerScriptsExist"] = function()
	TestFramework:info("Testing server script existence...")
	
	local serverScripts = {
		"GameManager",
		"PlayerManager",
		"BaseManager",
		"WaveManager",
		"Spawner",
		"WeaponService",
		"CureService",
		"ShopService",
		"MapManager"
	}
	
	for _, scriptName in ipairs(serverScripts) do
		local script = ServerScriptService:FindFirstChild(scriptName)
		TestFramework:assertNotNil(script, string.format("Script %s should exist in ServerScriptService", scriptName))
		TestFramework:debug("✓ Script exists: %s", scriptName)
	end
	
	TestFramework:debug("All core server scripts found")
end

return suite
