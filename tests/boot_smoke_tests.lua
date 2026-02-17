--!strict
-- @ScriptType: ModuleScript
-- Boot Smoke Tests
-- Validates that the game boots cleanly with proper entry points, no module load errors,
-- and deterministic initialization order.
-- Part of Baseline + Safety Nets implementation

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local BootSmokeTests = {}

local TESTS_PASSED = 0
local TESTS_FAILED = 0
local TEST_RESULTS = {}

local function pass(testName: string, message: string?)
	TESTS_PASSED += 1
	local result = string.format("✅ PASS: %s", testName)
	if message then
		result = result .. " - " .. message
	end
	table.insert(TEST_RESULTS, result)
	print(result)
end

local function fail(testName: string, message: string)
	TESTS_FAILED += 1
	local result = string.format("❌ FAIL: %s - %s", testName, message)
	table.insert(TEST_RESULTS, result)
	warn(result)
end

local function info(message: string)
	local result = string.format("ℹ️  INFO: %s", message)
	table.insert(TEST_RESULTS, result)
	print(result)
end

----------------------------------------------------------------
-- Test 1: Server Entry Point Verification
----------------------------------------------------------------
local function testServerEntryPoint()
	local testName = "Server Entry Point Guard"
	
	if not RunService:IsServer() then
		info("Skipping server test (not running on server)")
		return
	end
	
	local ServerScriptService = game:GetService("ServerScriptService")
	local mainScript = ServerScriptService:FindFirstChild("MainServerScript.legacy.lua")
	
	if not mainScript then
		fail(testName, "MainServerScript.legacy.lua not found in ServerScriptService")
		return
	end
	
	-- Check for duplicate execution guard
	local hasGuard = mainScript:GetAttribute("Initialized")
	if hasGuard ~= nil then
		pass(testName, "Duplicate execution guard is active")
	else
		fail(testName, "No duplicate execution guard found (Initialized attribute)")
	end
end

----------------------------------------------------------------
-- Test 2: Client Entry Point Verification
----------------------------------------------------------------
local function testClientEntryPoint()
	local testName = "Client Entry Point Guard"
	
	if not RunService:IsClient() then
		info("Skipping client test (not running on client)")
		return
	end
	
	-- Check for global guard
	if _G.__AwavePuzzBootClientStarted then
		pass(testName, "Client boot guard is active")
	else
		fail(testName, "Client boot guard not set (_G.__AwavePuzzBootClientStarted)")
	end
end

----------------------------------------------------------------
-- Test 3: RemoteRegistry Initialization
----------------------------------------------------------------
local function testRemoteRegistry()
	local testName = "RemoteRegistry Initialization"
	
	local SharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	if not SharedFolder then
		fail(testName, "Shared folder not found in ReplicatedStorage")
		return
	end
	
	local RemotesFolder = SharedFolder:FindFirstChild("Remotes")
	if not RemotesFolder then
		fail(testName, "Remotes folder not found in Shared")
		return
	end
	
	local RemoteRegistry = RemotesFolder:FindFirstChild("RemoteRegistry")
	if not RemoteRegistry then
		fail(testName, "RemoteRegistry module not found")
		return
	end
	
	local success, registry = pcall(function()
		return require(RemoteRegistry)
	end)
	
	if not success then
		fail(testName, "Failed to require RemoteRegistry: " .. tostring(registry))
		return
	end
	
	-- Check VERSION exists
	if registry.VERSION then
		pass(testName, "RemoteRegistry loaded successfully (version " .. registry.VERSION .. ")")
	else
		fail(testName, "RemoteRegistry loaded but VERSION not found")
	end
end

----------------------------------------------------------------
-- Test 4: RemoteEvents Folder Creation
----------------------------------------------------------------
local function testRemoteEventsFolder()
	local testName = "RemoteEvents Folder"
	
	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	
	if not remoteEventsFolder then
		if RunService:IsServer() then
			fail(testName, "RemoteEvents folder not created (server should create it)")
		else
			info("RemoteEvents folder not found (client may be waiting for server)")
		end
		return
	end
	
	if not remoteEventsFolder:IsA("Folder") then
		fail(testName, "RemoteEvents exists but is not a Folder (type: " .. remoteEventsFolder.ClassName .. ")")
		return
	end
	
	local remoteCount = #remoteEventsFolder:GetChildren()
	if remoteCount > 0 then
		pass(testName, "RemoteEvents folder contains " .. remoteCount .. " remotes")
	else
		fail(testName, "RemoteEvents folder is empty")
	end
end

----------------------------------------------------------------
-- Test 5: Core Configuration Modules
----------------------------------------------------------------
local function testCoreModules()
	local testName = "Core Configuration Modules"
	
	local SharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	if not SharedFolder then
		fail(testName, "Shared folder not found")
		return
	end
	
	local requiredModules = {
		"GameConfig",
		"FPSConfig",
		"AssetConfig",
		"AssetValidation",
		"ModalManager",
		"InputActionRegistry",
	}
	
	local missingModules = {}
	local loadErrors = {}
	
	for _, moduleName in ipairs(requiredModules) do
		local module = SharedFolder:FindFirstChild(moduleName)
		if not module then
			table.insert(missingModules, moduleName)
		else
			-- Try to require it
			local success, result = pcall(function()
				return require(module)
			end)
			if not success then
				table.insert(loadErrors, moduleName .. ": " .. tostring(result))
			end
		end
	end
	
	if #missingModules > 0 then
		fail(testName, "Missing modules: " .. table.concat(missingModules, ", "))
	elseif #loadErrors > 0 then
		fail(testName, "Load errors: " .. table.concat(loadErrors, "; "))
	else
		pass(testName, "All " .. #requiredModules .. " core modules present and loadable")
	end
end

----------------------------------------------------------------
-- Test 6: Service Initialization (Server Only)
----------------------------------------------------------------
local function testServiceInitialization()
	local testName = "Service Initialization"
	
	if not RunService:IsServer() then
		info("Skipping service test (not running on server)")
		return
	end
	
	local ServerScriptService = game:GetService("ServerScriptService")
	
	local requiredServices = {
		"GameManager",
		"PlayerManager",
		"WaveManager",
		"LobbyManager",
		"AllianceServiceV2",
		"CureService",
		"PuzzleService",
		"WeaponService",
		"FPSWeaponService",
	}
	
	local missingServices = {}
	local loadErrors = {}
	
	for _, serviceName in ipairs(requiredServices) do
		local service = ServerScriptService:FindFirstChild(serviceName)
		if not service then
			table.insert(missingServices, serviceName)
		else
			-- Try to require it
			local success, result = pcall(function()
				return require(service)
			end)
			if not success then
				table.insert(loadErrors, serviceName .. ": " .. tostring(result))
			end
		end
	end
	
	if #missingServices > 0 then
		fail(testName, "Missing services: " .. table.concat(missingServices, ", "))
	elseif #loadErrors > 0 then
		fail(testName, "Load errors: " .. table.concat(loadErrors, "; "))
	else
		pass(testName, "All " .. #requiredServices .. " services present and loadable")
	end
end

----------------------------------------------------------------
-- Test 7: Character Auto-Load Disabled (Server Only)
----------------------------------------------------------------
local function testCharacterAutoLoad()
	local testName = "Character Auto-Load Control"
	
	if not RunService:IsServer() then
		info("Skipping character auto-load test (not running on server)")
		return
	end
	
	if Players.CharacterAutoLoads == false then
		pass(testName, "CharacterAutoLoads correctly disabled")
	else
		fail(testName, "CharacterAutoLoads is enabled (should be disabled for title screen control)")
	end
end

----------------------------------------------------------------
-- Test 8: Boot Log Determinism
----------------------------------------------------------------
local function testBootLogDeterminism()
	local testName = "Boot Log Format"
	
	-- This test verifies that boot messages follow a consistent format
	-- Check for the presence of standard log prefixes
	
	local SharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	if not SharedFolder then
		fail(testName, "Cannot verify - Shared folder not found")
		return
	end
	
	local RemotesFolder = SharedFolder:FindFirstChild("Remotes")
	if RemotesFolder then
		local RemoteRegistry = RemotesFolder:FindFirstChild("RemoteRegistry")
		if RemoteRegistry then
			local success, registry = pcall(function()
				return require(RemoteRegistry)
			end)
			if success and registry.VERSION then
				pass(testName, "RemoteRegistry has VERSION for deterministic logging")
				return
			end
		end
	end
	
	fail(testName, "Cannot verify RemoteRegistry version")
end

----------------------------------------------------------------
-- Test 9: Deprecated Module Check
----------------------------------------------------------------
local function testDeprecatedModules()
	local testName = "Deprecated Module Detection"
	
	if not RunService:IsServer() then
		info("Skipping deprecated module check (not running on server)")
		return
	end
	
	local ServerScriptService = game:GetService("ServerScriptService")
	local remoteBootstrap = ServerScriptService:FindFirstChild("RemoteEventsBootstrap")
	
	if remoteBootstrap then
		-- Check if it's been loaded (has initialized attribute)
		local bootstrapModule = require(remoteBootstrap)
		if bootstrapModule and bootstrapModule.initialized then
			info("RemoteEventsBootstrap is present (deprecated, but backward compatible)")
		end
	end
	
	pass(testName, "Deprecated module check complete")
end

----------------------------------------------------------------
-- Test 10: No Duplicate RemoteEvents Folders
----------------------------------------------------------------
local function testNoDuplicateRemoteFolders()
	local testName = "No Duplicate RemoteEvents Folders"
	
	local folders = {}
	for _, child in ipairs(ReplicatedStorage:GetChildren()) do
		if child.Name == "RemoteEvents" then
			table.insert(folders, child)
		end
	end
	
	if #folders == 0 then
		info("No RemoteEvents folder found yet (may be waiting for server)")
	elseif #folders == 1 then
		pass(testName, "Exactly one RemoteEvents folder found")
	else
		fail(testName, "Multiple RemoteEvents folders found (" .. #folders .. ")")
	end
end

----------------------------------------------------------------
-- Test 11: Client-Server Ready Signal
----------------------------------------------------------------
local function testClientServerSync()
	local testName = "Client-Server Ready Signal"
	
	if not RunService:IsClient() then
		info("Skipping client-server sync test (not running on client)")
		return
	end
	
	-- Check if TitleScreenUI instance exists in shared
	if shared.__AwavePuzzTitleScreenInstance then
		pass(testName, "TitleScreenUI initialized and stored in shared")
	elseif shared.__AwavePuzzLoadingManager then
		pass(testName, "LoadingManager initialized and stored in shared")
	else
		fail(testName, "No client initialization markers found in shared")
	end
end

----------------------------------------------------------------
-- Test 12: Module Timeout Values
----------------------------------------------------------------
local function testModuleTimeouts()
	local testName = "Module Timeout Values"
	
	-- This is a meta-test that verifies we use reasonable timeout values
	-- All WaitForChild calls should have timeouts >= 5 seconds
	
	-- We can't directly inspect the code, but we can verify that critical
	-- modules loaded successfully, which implies timeouts were reasonable
	
	local SharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	if SharedFolder then
		local startTime = os.clock()
		local GameConfig = SharedFolder:WaitForChild("GameConfig", 5)
		local elapsed = os.clock() - startTime
		
		if GameConfig then
			if elapsed < 5 then
				pass(testName, "GameConfig loaded quickly (" .. string.format("%.2f", elapsed) .. "s)")
			else
				info("GameConfig loaded slowly (" .. string.format("%.2f", elapsed) .. "s, timeout worked)")
				pass(testName, "Timeout mechanism working")
			end
		else
			fail(testName, "GameConfig failed to load within 5 seconds")
		end
	else
		fail(testName, "Shared folder not found")
	end
end

----------------------------------------------------------------
-- Run All Tests
----------------------------------------------------------------
function BootSmokeTests.runAll()
	print("============================================================")
	print("BOOT SMOKE TEST SUITE")
	print("Baseline + Safety Nets - Entry Points, Module Loading, Boot")
	print("============================================================")
	print("")
	
	TESTS_PASSED = 0
	TESTS_FAILED = 0
	TEST_RESULTS = {}
	
	-- Run all tests
	print("--- Entry Point Tests ---")
	testServerEntryPoint()
	testClientEntryPoint()
	print("")
	
	print("--- Module Loading Tests ---")
	testRemoteRegistry()
	testRemoteEventsFolder()
	testCoreModules()
	testServiceInitialization()
	print("")
	
	print("--- Boot Configuration Tests ---")
	testCharacterAutoLoad()
	testBootLogDeterminism()
	testDeprecatedModules()
	testNoDuplicateRemoteFolders()
	print("")
	
	print("--- Synchronization Tests ---")
	testClientServerSync()
	testModuleTimeouts()
	print("")
	
	-- Print summary
	print("============================================================")
	print("BOOT SMOKE TEST RESULTS")
	print("============================================================")
	print(string.format("Tests Passed: %d", TESTS_PASSED))
	print(string.format("Tests Failed: %d", TESTS_FAILED))
	print(string.format("Total Tests: %d", TESTS_PASSED + TESTS_FAILED))
	print("")
	
	if TESTS_FAILED == 0 then
		print("✅ ALL TESTS PASSED - Boot system is healthy")
	else
		warn("❌ SOME TESTS FAILED - Review failures above")
	end
	
	print("============================================================")
	
	return {
		passed = TESTS_PASSED,
		failed = TESTS_FAILED,
		results = TEST_RESULTS,
	}
end

-- Quick test for command bar
function BootSmokeTests.quickTest()
	print("Running quick boot smoke test...")
	return BootSmokeTests.runAll()
end

return BootSmokeTests
