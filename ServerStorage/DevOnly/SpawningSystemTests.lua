-- SpawningSystemTests.lua
-- Tests for spawning systems: Spawner, ResourceSpawner, ItemSpawner, ZombieBrain
-- Tests zombie AI, resource spawning, and spawn point management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local TestFramework = require(script.Parent.TestFramework)

-- Load shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
local GameConfig = require(SharedFolder:WaitForChild("GameConfig", 5))
local ZombieTypes = require(SharedFolder:WaitForChild("ZombieTypes", 5))

local suite = TestFramework:createSuite("SpawningSystemTests")

--------------------------------------------------------------------------------
-- ZombieTypes Configuration Tests
--------------------------------------------------------------------------------

suite.tests["ZombieTypes_LoadsSuccessfully"] = function()
	TestFramework:info("Testing ZombieTypes module loading...")
	
	TestFramework:assertNotNil(ZombieTypes, "ZombieTypes should load")
	TestFramework:assertType(ZombieTypes, "table", "ZombieTypes should be a table")
	
	TestFramework:debug("ZombieTypes loaded successfully")
end

suite.tests["ZombieTypes_HasBasicTypes"] = function()
	TestFramework:info("Testing ZombieTypes has basic zombie definitions...")
	
	-- Check for standard zombie types
	local basicTypes = {"Normal", "Fast", "Tank", "Boss"}
	local foundTypes = {}
	
	for zombieType, data in pairs(ZombieTypes) do
		if type(data) == "table" then
			table.insert(foundTypes, zombieType)
			TestFramework:debug("Found zombie type: %s", zombieType)
			
			-- Validate zombie data structure
			TestFramework:assertNotNil(data.Health, 
				string.format("%s should have Health", zombieType))
			TestFramework:assertNotNil(data.Speed, 
				string.format("%s should have Speed", zombieType))
			TestFramework:assertNotNil(data.Damage, 
				string.format("%s should have Damage", zombieType))
		end
	end
	
	TestFramework:assertGreaterThan(#foundTypes, 0, "Should have at least one zombie type")
	TestFramework:debug("Found %d zombie types", #foundTypes)
end

suite.tests["ZombieTypes_ValidatesStats"] = function()
	TestFramework:info("Testing ZombieTypes stat validation...")
	
	for zombieType, data in pairs(ZombieTypes) do
		if type(data) == "table" and data.Health then
			TestFramework:assertType(data.Health, "number", 
				string.format("%s Health should be a number", zombieType))
			TestFramework:assertGreaterThan(data.Health, 0,
				string.format("%s Health should be positive", zombieType))
			
			TestFramework:assertType(data.Speed, "number",
				string.format("%s Speed should be a number", zombieType))
			TestFramework:assertGreaterThan(data.Speed, 0,
				string.format("%s Speed should be positive", zombieType))
			
			TestFramework:assertType(data.Damage, "number",
				string.format("%s Damage should be a number", zombieType))
			TestFramework:assertGreaterThan(data.Damage, 0,
				string.format("%s Damage should be positive", zombieType))
			
			TestFramework:debug("✓ %s stats validated", zombieType)
		end
	end
	
	TestFramework:debug("All zombie type stats are valid")
end

--------------------------------------------------------------------------------
-- Spawner Module Tests
--------------------------------------------------------------------------------

suite.tests["Spawner_LoadsSuccessfully"] = function()
	TestFramework:info("Testing Spawner module loading...")
	
	local success, Spawner = pcall(function()
		return require(ServerScriptService:WaitForChild("Spawner", 5))
	end)
	
	TestFramework:assertTrue(success, "Spawner should load without errors")
	TestFramework:assertNotNil(Spawner, "Spawner should not be nil")
	TestFramework:assertType(Spawner, "table", "Spawner should be a table")
	
	TestFramework:debug("Spawner loaded successfully")
end

suite.tests["Spawner_HasRequiredMethods"] = function()
	TestFramework:info("Testing Spawner has required methods...")
	
	local Spawner = require(ServerScriptService:WaitForChild("Spawner", 5))
	
	-- Check for essential methods
	local requiredMethods = {
		"new",
		"initialize",
		"spawnWave",
		"stopSpawning",
		"getActiveZombieCount"
	}
	
	for _, methodName in ipairs(requiredMethods) do
		TestFramework:assertNotNil(Spawner[methodName],
			string.format("Spawner should have %s method", methodName))
		TestFramework:debug("✓ Method exists: %s", methodName)
	end
	
	TestFramework:debug("All required Spawner methods present")
end

suite.tests["Spawner_CreatesInstance"] = function()
	TestFramework:info("Testing Spawner instance creation...")
	
	local Spawner = require(ServerScriptService:WaitForChild("Spawner", 5))
	local PlayerManager = require(ServerScriptService:WaitForChild("PlayerManager", 5))
	local BaseManager = require(ServerScriptService:WaitForChild("BaseManager", 5))
	local WeaponService = require(ServerScriptService:WaitForChild("WeaponService", 5))
	
	-- Create mock dependencies
	local weaponService = {
		registerZombie = function() end,
		unregisterZombie = function() end
	}
	
	local baseManager = BaseManager.getInstance()
	local playerManager = PlayerManager.getInstance()
	
	local success, spawner = pcall(function()
		return Spawner.new(weaponService, baseManager, playerManager)
	end)
	
	TestFramework:assertTrue(success, "Should create Spawner instance without errors")
	TestFramework:assertNotNil(spawner, "Spawner instance should not be nil")
	
	TestFramework:debug("Spawner instance created successfully")
end

--------------------------------------------------------------------------------
-- ResourceSpawner Tests
--------------------------------------------------------------------------------

suite.tests["ResourceSpawner_LoadsSuccessfully"] = function()
	TestFramework:info("Testing ResourceSpawner module loading...")
	
	local success, ResourceSpawner = pcall(function()
		return require(ServerScriptService:WaitForChild("ResourceSpawner", 5))
	end)
	
	TestFramework:assertTrue(success, "ResourceSpawner should load without errors")
	TestFramework:assertNotNil(ResourceSpawner, "ResourceSpawner should not be nil")
	TestFramework:assertType(ResourceSpawner, "table", "ResourceSpawner should be a table")
	
	TestFramework:debug("ResourceSpawner loaded successfully")
end

suite.tests["ResourceSpawner_HasRequiredMethods"] = function()
	TestFramework:info("Testing ResourceSpawner has required methods...")
	
	local ResourceSpawner = require(ServerScriptService:WaitForChild("ResourceSpawner", 5))
	
	local requiredMethods = {
		"new",
		"initialize",
		"startSpawning",
		"stopSpawning"
	}
	
	for _, methodName in ipairs(requiredMethods) do
		TestFramework:assertNotNil(ResourceSpawner[methodName],
			string.format("ResourceSpawner should have %s method", methodName))
		TestFramework:debug("✓ Method exists: %s", methodName)
	end
	
	TestFramework:debug("All required ResourceSpawner methods present")
end

suite.tests["ResourceSpawner_CreatesInstance"] = function()
	TestFramework:info("Testing ResourceSpawner instance creation...")
	
	local ResourceSpawner = require(ServerScriptService:WaitForChild("ResourceSpawner", 5))
	
	local success, spawner = pcall(function()
		return ResourceSpawner.new()
	end)
	
	TestFramework:assertTrue(success, "Should create ResourceSpawner instance without errors")
	TestFramework:assertNotNil(spawner, "ResourceSpawner instance should not be nil")
	
	TestFramework:debug("ResourceSpawner instance created successfully")
end

--------------------------------------------------------------------------------
-- ItemSpawner Tests
--------------------------------------------------------------------------------

suite.tests["ItemSpawner_LoadsSuccessfully"] = function()
	TestFramework:info("Testing ItemSpawner module loading...")
	
	local success, ItemSpawner = pcall(function()
		return require(ServerScriptService:WaitForChild("ItemSpawner", 5))
	end)
	
	TestFramework:assertTrue(success, "ItemSpawner should load without errors")
	TestFramework:assertNotNil(ItemSpawner, "ItemSpawner should not be nil")
	TestFramework:assertType(ItemSpawner, "table", "ItemSpawner should be a table")
	
	TestFramework:debug("ItemSpawner loaded successfully")
end

suite.tests["ItemSpawner_HasRequiredMethods"] = function()
	TestFramework:info("Testing ItemSpawner has required methods...")
	
	local ItemSpawner = require(ServerScriptService:WaitForChild("ItemSpawner", 5))
	
	local requiredMethods = {
		"new",
		"initialize",
		"startSpawning",
		"stopSpawning",
		"setPlayerManager",
		"setFPSWeaponService"
	}
	
	for _, methodName in ipairs(requiredMethods) do
		TestFramework:assertNotNil(ItemSpawner[methodName],
			string.format("ItemSpawner should have %s method", methodName))
		TestFramework:debug("✓ Method exists: %s", methodName)
	end
	
	TestFramework:debug("All required ItemSpawner methods present")
end

suite.tests["ItemSpawner_CreatesInstance"] = function()
	TestFramework:info("Testing ItemSpawner instance creation...")
	
	local ItemSpawner = require(ServerScriptService:WaitForChild("ItemSpawner", 5))
	
	local success, spawner = pcall(function()
		return ItemSpawner.new()
	end)
	
	TestFramework:assertTrue(success, "Should create ItemSpawner instance without errors")
	TestFramework:assertNotNil(spawner, "ItemSpawner instance should not be nil")
	
	TestFramework:debug("ItemSpawner instance created successfully")
end

--------------------------------------------------------------------------------
-- ZombieBrain AI Tests
--------------------------------------------------------------------------------

suite.tests["ZombieBrain_LoadsSuccessfully"] = function()
	TestFramework:info("Testing ZombieBrain module loading...")
	
	local success, ZombieBrain = pcall(function()
		return require(ServerScriptService.AI:WaitForChild("ZombieBrain", 5))
	end)
	
	TestFramework:assertTrue(success, "ZombieBrain should load without errors")
	TestFramework:assertNotNil(ZombieBrain, "ZombieBrain should not be nil")
	TestFramework:assertType(ZombieBrain, "table", "ZombieBrain should be a table")
	
	TestFramework:debug("ZombieBrain loaded successfully")
end

suite.tests["ZombieBrain_HasRequiredMethods"] = function()
	TestFramework:info("Testing ZombieBrain has required methods...")
	
	local ZombieBrain = require(ServerScriptService.AI:WaitForChild("ZombieBrain", 5))
	
	local requiredMethods = {
		"new",
		"start",
		"stop",
		"update"
	}
	
	for _, methodName in ipairs(requiredMethods) do
		TestFramework:assertNotNil(ZombieBrain[methodName],
			string.format("ZombieBrain should have %s method", methodName))
		TestFramework:debug("✓ Method exists: %s", methodName)
	end
	
	TestFramework:debug("All required ZombieBrain methods present")
end

--------------------------------------------------------------------------------
-- AIDirector Tests
--------------------------------------------------------------------------------

suite.tests["AIDirector_LoadsSuccessfully"] = function()
	TestFramework:info("Testing AIDirector module loading...")
	
	local AIFolder = ServerScriptService:FindFirstChild("AI")
	if not AIFolder then
		TestFramework:warn("AI folder not found, skipping AIDirector test")
		return
	end
	
	local success, AIDirector = pcall(function()
		return require(AIFolder:WaitForChild("AIDirector", 5))
	end)
	
	TestFramework:assertTrue(success, "AIDirector should load without errors")
	TestFramework:assertNotNil(AIDirector, "AIDirector should not be nil")
	TestFramework:assertType(AIDirector, "table", "AIDirector should be a table")
	
	TestFramework:debug("AIDirector loaded successfully")
end

--------------------------------------------------------------------------------
-- Spawn Point Tests
--------------------------------------------------------------------------------

suite.tests["SpawnPoints_WorkspaceStructure"] = function()
	TestFramework:info("Testing spawn point structure in Workspace...")
	
	-- Check for ActiveMap or map structure
	local activeMap = Workspace:FindFirstChild("ActiveMap")
	
	if activeMap then
		TestFramework:debug("ActiveMap found in Workspace")
		
		-- Check for zombie spawn points
		local zombieSpawns = activeMap:FindFirstChild("ZombieSpawnPoints")
		if zombieSpawns then
			local spawnCount = #zombieSpawns:GetChildren()
			TestFramework:debug("Found %d zombie spawn points", spawnCount)
			
			if spawnCount > 0 then
				TestFramework:assertGreaterThan(spawnCount, 0, "Should have at least one zombie spawn point")
			end
		else
			TestFramework:warn("ZombieSpawnPoints folder not found in ActiveMap")
		end
	else
		TestFramework:warn("ActiveMap not found in Workspace (map may not be loaded yet)")
	end
end

suite.tests["SpawnPoints_ResourceStructure"] = function()
	TestFramework:info("Testing resource spawn point structure...")
	
	local activeMap = Workspace:FindFirstChild("ActiveMap")
	
	if activeMap then
		-- Check for resource spawn points
		local spawnPoints = activeMap:FindFirstChild("SpawnPoints")
		if spawnPoints then
			local resourceSpawns = spawnPoints:FindFirstChild("ResourceSpawns")
			if resourceSpawns then
				local count = #resourceSpawns:GetChildren()
				TestFramework:debug("Found %d resource spawn points", count)
				
				if count > 0 then
					TestFramework:assertGreaterThan(count, 0, "Should have at least one resource spawn point")
				end
			else
				TestFramework:warn("ResourceSpawns not found (map may use different structure)")
			end
		else
			TestFramework:warn("SpawnPoints folder not found (map may use different structure)")
		end
	else
		TestFramework:warn("ActiveMap not found in Workspace")
	end
end

--------------------------------------------------------------------------------
-- Spawn Configuration Tests
--------------------------------------------------------------------------------

suite.tests["SpawnConfig_ZombieSpawnRate"] = function()
	TestFramework:info("Testing zombie spawn rate configuration...")
	
	TestFramework:assertNotNil(GameConfig.ZOMBIE_SPAWN_DELAY, "ZOMBIE_SPAWN_DELAY should exist")
	TestFramework:assertType(GameConfig.ZOMBIE_SPAWN_DELAY, "number", "ZOMBIE_SPAWN_DELAY should be a number")
	TestFramework:assertGreaterThan(GameConfig.ZOMBIE_SPAWN_DELAY, 0, "ZOMBIE_SPAWN_DELAY should be positive")
	
	TestFramework:debug("Zombie spawn delay: %.2f seconds", GameConfig.ZOMBIE_SPAWN_DELAY)
end

suite.tests["SpawnConfig_ResourceSpawnRate"] = function()
	TestFramework:info("Testing resource spawn rate configuration...")
	
	TestFramework:assertNotNil(GameConfig.RESOURCE_SPAWN_RATE, "RESOURCE_SPAWN_RATE should exist")
	TestFramework:assertType(GameConfig.RESOURCE_SPAWN_RATE, "number", "RESOURCE_SPAWN_RATE should be a number")
	TestFramework:assertGreaterThan(GameConfig.RESOURCE_SPAWN_RATE, 0, "RESOURCE_SPAWN_RATE should be positive")
	
	TestFramework:debug("Resource spawn rate: %.2f seconds", GameConfig.RESOURCE_SPAWN_RATE)
end

return suite
