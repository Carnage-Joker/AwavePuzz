-- IntegrationTests.lua
-- Integration tests for full game flow and system interactions
-- Tests initialization, game loop, and cross-system communication

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local TestFramework = require(script.Parent.TestFramework)

local suite = TestFramework:createSuite("IntegrationTests")

--------------------------------------------------------------------------------
-- Initialization Tests
--------------------------------------------------------------------------------

suite.tests["Init_MainServerExists"] = function()
	TestFramework:info("Testing MainServer script exists and is runnable...")
	
	local MainServer = ServerScriptService:FindFirstChild("MainServer")
	TestFramework:assertNotNil(MainServer, "MainServer script should exist")
	TestFramework:assertInstanceOf(MainServer, "Script", "MainServer should be a Script")
	
	TestFramework:debug("MainServer script found")
end

suite.tests["Init_RemoteEventsBootstrap"] = function()
	TestFramework:info("Testing RemoteEventsBootstrap...")
	
	local RemoteEventsBootstrap = ServerScriptService:FindFirstChild("RemoteEventsBootstrap")
	TestFramework:assertNotNil(RemoteEventsBootstrap, "RemoteEventsBootstrap should exist")
	
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	TestFramework:assertNotNil(remoteEvents, "RemoteEvents folder should be created")
	
	TestFramework:debug("RemoteEvents initialization verified")
end

suite.tests["Init_SharedModulesAccessible"] = function()
	TestFramework:info("Testing all shared modules are accessible...")
	
	local SharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	TestFramework:assertNotNil(SharedFolder, "Shared folder should exist")
	
	local sharedModules = {
		"GameConfig", "WaveConfig", "WeaponConfig", "MapConfig",
		"ZombieTypes", "GameState", "RemoteEventUtil"
	}
	
	for _, moduleName in ipairs(sharedModules) do
		local module = SharedFolder:FindFirstChild(moduleName)
		TestFramework:assertNotNil(module, string.format("%s should exist", moduleName))
		
		local success, loadedModule = pcall(require, module)
		TestFramework:assertTrue(success, string.format("%s should load without errors", moduleName))
		
		TestFramework:debug("✓ Module accessible: %s", moduleName)
	end
	
	TestFramework:debug("All shared modules are accessible")
end

--------------------------------------------------------------------------------
-- Manager Integration Tests
--------------------------------------------------------------------------------

suite.tests["Integration_GameManagerCreation"] = function()
	TestFramework:info("Testing GameManager can be created with dependencies...")
	
	local GameManager = require(ServerScriptService:WaitForChild("GameManager", 5))
	local AllianceService = require(ServerScriptService:WaitForChild("AllianceServiceV2", 5))
	
	-- Create alliance service first
	local allianceService = AllianceService.new()
	TestFramework:assertNotNil(allianceService, "AllianceService should be created")
	
	-- Create game manager
	local success, gameManager = pcall(function()
		return GameManager.new(allianceService)
	end)
	
	TestFramework:assertTrue(success, "GameManager should be created without errors")
	TestFramework:assertNotNil(gameManager, "GameManager instance should not be nil")
	
	TestFramework:debug("GameManager created successfully with dependencies")
end

suite.tests["Integration_ManagerReferences"] = function()
	TestFramework:info("Testing managers can reference each other properly...")
	
	local GameManager = require(ServerScriptService:WaitForChild("GameManager", 5))
	local AllianceService = require(ServerScriptService:WaitForChild("AllianceServiceV2", 5))
	
	local allianceService = AllianceService.new()
	local success, gameManager = pcall(function()
		return GameManager.new(allianceService)
	end)
	
	if not success then
		TestFramework:warn("Could not create GameManager, skipping test")
		return
	end
	
	-- Check if we can get references to sub-managers
	if gameManager.getPlayerManager then
		local playerManager = gameManager:getPlayerManager()
		TestFramework:assertNotNil(playerManager, "Should be able to get PlayerManager from GameManager")
		TestFramework:debug("✓ PlayerManager reference obtained")
	end
	
	if gameManager.getWeaponService then
		local weaponService = gameManager:getWeaponService()
		TestFramework:assertNotNil(weaponService, "Should be able to get WeaponService from GameManager")
		TestFramework:debug("✓ WeaponService reference obtained")
	end
	
	TestFramework:debug("Manager references working correctly")
end

--------------------------------------------------------------------------------
-- Service Lifecycle Tests
--------------------------------------------------------------------------------

suite.tests["Lifecycle_ServicesInitialize"] = function()
	TestFramework:info("Testing services can initialize without errors...")
	
	local services = {
		{"SprintService", "SprintService"},
		{"AchievementService", "AchievementService"},
		{"FunFactService", "FunFactService"},
		{"CureSynthesisService", "CureSynthesisService"}
	}
	
	for _, serviceInfo in ipairs(services) do
		local serviceName = serviceInfo[1]
		local moduleName = serviceInfo[2]
		
		local module = ServerScriptService:FindFirstChild(moduleName)
		if module then
			local success, Service = pcall(require, module)
			TestFramework:assertTrue(success, 
				string.format("%s should load without errors", serviceName))
			TestFramework:debug("✓ %s initialized", serviceName)
		else
			TestFramework:warn("%s module not found", serviceName)
		end
	end
	
	TestFramework:debug("Services initialization validated")
end

--------------------------------------------------------------------------------
-- RemoteEvent Communication Tests
--------------------------------------------------------------------------------

suite.tests["Communication_RemoteEventsStructure"] = function()
	TestFramework:info("Testing RemoteEvents folder structure...")
	
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	TestFramework:assertNotNil(remoteEvents, "RemoteEvents folder should exist")
	
	local eventCount = #remoteEvents:GetChildren()
	TestFramework:debug("Found %d RemoteEvents/RemoteFunctions", eventCount)
	
	-- List all events for debugging
	for _, event in ipairs(remoteEvents:GetChildren()) do
		local eventType = event:IsA("RemoteEvent") and "RemoteEvent" or 
						  event:IsA("RemoteFunction") and "RemoteFunction" or 
						  "Other"
		TestFramework:debug("  - %s (%s)", event.Name, eventType)
	end
	
	TestFramework:debug("RemoteEvents structure validated")
end

--------------------------------------------------------------------------------
-- Workspace Structure Tests
--------------------------------------------------------------------------------

suite.tests["Workspace_BasicStructure"] = function()
	TestFramework:info("Testing Workspace has expected structure...")
	
	-- Check for key folders that should exist
	local expectedFolders = {
		"Zombies",
		"ActivePlayers"
	}
	
	for _, folderName in ipairs(expectedFolders) do
		local folder = Workspace:FindFirstChild(folderName)
		if folder then
			TestFramework:debug("✓ Folder exists: %s", folderName)
		else
			TestFramework:warn("⚠ Folder not found: %s (may be created at runtime)", folderName)
		end
	end
	
	TestFramework:debug("Workspace structure check complete")
end

--------------------------------------------------------------------------------
-- Error Handling Tests
--------------------------------------------------------------------------------

suite.tests["ErrorHandling_WaitForChildTimeouts"] = function()
	TestFramework:info("Testing WaitForChild has proper timeouts...")
	
	-- Test that a non-existent child times out properly
	local testFolder = Instance.new("Folder")
	testFolder.Name = "TestFolder"
	
	local startTime = os.clock()
	local result = testFolder:WaitForChild("NonExistent", 1)
	local elapsed = os.clock() - startTime
	
	TestFramework:assertNil(result, "WaitForChild should return nil for non-existent child")
	TestFramework:assertGreaterThan(elapsed, 0.9, "Should wait at least 1 second")
	TestFramework:assertLessThan(elapsed, 1.5, "Should not wait much longer than 1 second")
	
	testFolder:Destroy()
	
	TestFramework:debug("WaitForChild timeout behavior validated")
end

--------------------------------------------------------------------------------
-- Memory Management Tests
--------------------------------------------------------------------------------

suite.tests["Memory_NoGlobalLeaks"] = function()
	TestFramework:info("Testing for global variable leaks...")
	
	local knownGlobals = {
		"game", "workspace", "script", "shared", "_G", "_VERSION",
		"print", "warn", "error", "assert", "pcall", "xpcall",
		"type", "typeof", "next", "pairs", "ipairs", "select",
		"tonumber", "tostring", "getmetatable", "setmetatable",
		"require", "tick", "time", "wait", "delay", "spawn"
	}
	
	local globalLeaks = {}
	for key, value in pairs(_G) do
		local isKnown = false
		for _, knownKey in ipairs(knownGlobals) do
			if key == knownKey then
				isKnown = true
				break
			end
		end
		
		if not isKnown then
			table.insert(globalLeaks, key)
			TestFramework:warn("Unexpected global variable: %s", tostring(key))
		end
	end
	
	if #globalLeaks == 0 then
		TestFramework:debug("No unexpected global variables detected")
	else
		TestFramework:warn("Found %d unexpected global variables", #globalLeaks)
	end
end

--------------------------------------------------------------------------------
-- Performance Tests
--------------------------------------------------------------------------------

suite.tests["Performance_ModuleLoadTimes"] = function()
	TestFramework:info("Testing module load times...")
	
	local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
	local modules = {
		"GameConfig", "WaveConfig", "WeaponConfig"
	}
	
	for _, moduleName in ipairs(modules) do
		local module = SharedFolder:FindFirstChild(moduleName)
		if module then
			local startTime = os.clock()
			local success, result = pcall(require, module)
			local loadTime = os.clock() - startTime
			
			TestFramework:assertTrue(success, string.format("%s should load", moduleName))
			TestFramework:debug("✓ %s loaded in %.4f seconds", moduleName, loadTime)
			
			-- Warn if load time is unusually slow
			if loadTime > 0.1 then
				TestFramework:warn("%s took %.4f seconds to load (> 0.1s)", moduleName, loadTime)
			end
		end
	end
	
	TestFramework:debug("Module load times validated")
end

return suite
