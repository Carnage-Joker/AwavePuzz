-- TestRunner.lua
-- Main test runner that executes all test suites with verbose logging
-- Run in Roblox Studio Command Bar: require(game.ServerStorage.DevOnly.TestRunner).runAll()

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

-- Only run in Studio
if not RunService:IsStudio() then
	warn("[TestRunner] Tests can only be run in Roblox Studio")
	return
end

local TestRunner = {}

-- Test framework
local TestFramework = require(script.Parent.TestFramework)

-- Test suites (loaded dynamically)
local testSuites = {}

--------------------------------------------------------------------------------
-- Load Test Suites
--------------------------------------------------------------------------------

function TestRunner.loadTestSuites()
	print("[TestRunner] Loading test suites...")
	
	local testsFolder = script.Parent
	local loadedCount = 0
	
	-- Core system tests
	local testFiles = {
		"CoreSystemsTests",
		"SpawningSystemTests",
		"WeaponSystemTests",
		"CureAndPuzzleTests",
		"AllianceSystemTests",
		"ShopSystemTests",
		"MapSystemTests",
		"LobbySystemTests",
		"UISystemTests",
		"MovementSystemTests",
		"SpectatorSystemTests",
		"ConfigurationTests",
		"IntegrationTests"
	}
	
	for _, fileName in ipairs(testFiles) do
		local testModule = testsFolder:FindFirstChild(fileName)
		if testModule then
			local success, suite = pcall(require, testModule)
			if success and suite then
				table.insert(testSuites, suite)
				loadedCount = loadedCount + 1
				print(string.format("[TestRunner] ✓ Loaded: %s", fileName))
			else
				warn(string.format("[TestRunner] ✗ Failed to load %s: %s", fileName, tostring(suite)))
			end
		else
			warn(string.format("[TestRunner] ⚠ Test suite not found: %s", fileName))
		end
	end
	
	print(string.format("[TestRunner] Loaded %d test suites", loadedCount))
	return loadedCount > 0
end

--------------------------------------------------------------------------------
-- Run Tests
--------------------------------------------------------------------------------

function TestRunner.runAll(logLevel)
	print("")
	print("╔═══════════════════════════════════════════════════════════════╗")
	print("║              AWAVEPUZZ COMPREHENSIVE TEST SUITE               ║")
	print("╔═══════════════════════════════════════════════════════════════╗")
	print("║ Purpose: Comprehensive testing with verbose bug detection    ║")
	print("║ Coverage: All game systems with detailed logging             ║")
	print("╚═══════════════════════════════════════════════════════════════╝")
	print("")
	
	-- Set log level (default to DEBUG for maximum verbosity)
	if logLevel then
		TestFramework:setLogLevel(logLevel)
	else
		TestFramework:setLogLevel(TestFramework.LogLevel.DEBUG)
	end
	
	-- Reset framework
	TestFramework:reset()
	TestFramework.stats.startTime = os.clock()
	
	-- Load test suites
	if not TestRunner.loadTestSuites() then
		warn("[TestRunner] No test suites loaded. Aborting.")
		return false
	end
	
	-- Run all test suites
	for _, suite in ipairs(testSuites) do
		TestFramework:runSuite(suite)
	end
	
	-- Generate final report
	TestFramework.stats.endTime = os.clock()
	local allPassed = TestFramework:generateReport()
	
	print("")
	print("╔═══════════════════════════════════════════════════════════════╗")
	print("║                  TEST EXECUTION COMPLETE                      ║")
	print("╚═══════════════════════════════════════════════════════════════╝")
	
	return allPassed
end

function TestRunner.runSuite(suiteName, logLevel)
	print(string.format("[TestRunner] Running specific test suite: %s", suiteName))
	
	-- Set log level
	if logLevel then
		TestFramework:setLogLevel(logLevel)
	else
		TestFramework:setLogLevel(TestFramework.LogLevel.INFO)
	end
	
	-- Reset framework
	TestFramework:reset()
	TestFramework.stats.startTime = os.clock()
	
	-- Load and run specific suite
	local testsFolder = script.Parent
	local testModule = testsFolder:FindFirstChild(suiteName)
	
	if not testModule then
		warn(string.format("[TestRunner] Test suite not found: %s", suiteName))
		return false
	end
	
	local success, suite = pcall(require, testModule)
	if not success or not suite then
		warn(string.format("[TestRunner] Failed to load suite: %s", tostring(suite)))
		return false
	end
	
	-- Run the suite
	TestFramework:runSuite(suite)
	
	-- Generate report
	TestFramework.stats.endTime = os.clock()
	local allPassed = TestFramework:generateReport()
	
	return allPassed
end

--------------------------------------------------------------------------------
-- Quick Test Functions
--------------------------------------------------------------------------------

-- Run all tests with debug logging
function TestRunner.debug()
	return TestRunner.runAll(TestFramework.LogLevel.DEBUG)
end

-- Run all tests with info logging (less verbose)
function TestRunner.test()
	return TestRunner.runAll(TestFramework.LogLevel.INFO)
end

-- Run all tests with minimal logging
function TestRunner.quiet()
	return TestRunner.runAll(TestFramework.LogLevel.WARN)
end

-- Run specific suite with debug logging
function TestRunner.testSuite(suiteName)
	return TestRunner.runSuite(suiteName, TestFramework.LogLevel.DEBUG)
end

return TestRunner
