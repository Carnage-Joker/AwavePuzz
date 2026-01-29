-- CureAndPuzzleTests.lua
-- Tests for cure and puzzle systems: CureService, PuzzleService, CureSynthesisService
-- Tests cure progress tracking, puzzle generation, and cure synthesis

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TestFramework = require(script.Parent.TestFramework)

-- Load shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
local GameConfig = require(SharedFolder:WaitForChild("GameConfig", 5))
local PuzzleConfig = SharedFolder:FindFirstChild("PuzzleConfig")

local suite = TestFramework:createSuite("CureAndPuzzleTests")

--------------------------------------------------------------------------------
-- PuzzleConfig Tests
--------------------------------------------------------------------------------

suite.tests["PuzzleConfig_LoadsSuccessfully"] = function()
	TestFramework:info("Testing PuzzleConfig module loading...")
	
	if not PuzzleConfig then
		TestFramework:warn("PuzzleConfig not found, skipping puzzle tests")
		return
	end
	
	local success, config = pcall(require, PuzzleConfig)
	TestFramework:assertTrue(success, "PuzzleConfig should load without errors")
	TestFramework:assertNotNil(config, "PuzzleConfig should not be nil")
	TestFramework:assertType(config, "table", "PuzzleConfig should be a table")
	
	TestFramework:debug("PuzzleConfig loaded successfully")
end

suite.tests["PuzzleConfig_HasComponentPuzzles"] = function()
	TestFramework:info("Testing PuzzleConfig has component puzzles...")
	
	if not PuzzleConfig then
		TestFramework:warn("PuzzleConfig not found, skipping test")
		return
	end
	
	local config = require(PuzzleConfig)
	TestFramework:assertNotNil(config.ComponentPuzzles, "ComponentPuzzles should exist")
	TestFramework:assertType(config.ComponentPuzzles, "table", "ComponentPuzzles should be a table")
	
	local puzzleCount = 0
	for componentName, puzzleData in pairs(config.ComponentPuzzles) do
		puzzleCount = puzzleCount + 1
		TestFramework:debug("Found puzzle for component: %s", componentName)
		
		TestFramework:assertNotNil(puzzleData.type, string.format("%s should have type", componentName))
		TestFramework:assertNotNil(puzzleData.name, string.format("%s should have name", componentName))
	end
	
	TestFramework:assertGreaterThan(puzzleCount, 0, "Should have at least one component puzzle")
	TestFramework:debug("Found %d component puzzles", puzzleCount)
end

--------------------------------------------------------------------------------
-- CureService Tests
--------------------------------------------------------------------------------

suite.tests["CureService_LoadsSuccessfully"] = function()
	TestFramework:info("Testing CureService module loading...")
	
	local success, CureService = pcall(function()
		return require(ServerScriptService:WaitForChild("CureService", 5))
	end)
	
	TestFramework:assertTrue(success, "CureService should load without errors")
	TestFramework:assertNotNil(CureService, "CureService should not be nil")
	TestFramework:assertType(CureService, "table", "CureService should be a table")
	
	TestFramework:debug("CureService loaded successfully")
end

suite.tests["CureService_HasRequiredMethods"] = function()
	TestFramework:info("Testing CureService has required methods...")
	
	local CureService = require(ServerScriptService:WaitForChild("CureService", 5))
	
	local requiredMethods = {
		"new",
		"getCureProgress",
		"addComponentProgress",
		"setPuzzleService",
		"setAllianceService"
	}
	
	for _, methodName in ipairs(requiredMethods) do
		TestFramework:assertNotNil(CureService[methodName],
			string.format("CureService should have %s method", methodName))
		TestFramework:debug("✓ Method exists: %s", methodName)
	end
	
	TestFramework:debug("All required CureService methods present")
end

--------------------------------------------------------------------------------
-- PuzzleService Tests
--------------------------------------------------------------------------------

suite.tests["PuzzleService_LoadsSuccessfully"] = function()
	TestFramework:info("Testing PuzzleService module loading...")
	
	local success, PuzzleService = pcall(function()
		return require(ServerScriptService:WaitForChild("PuzzleService", 5))
	end)
	
	TestFramework:assertTrue(success, "PuzzleService should load without errors")
	TestFramework:assertNotNil(PuzzleService, "PuzzleService should not be nil")
	TestFramework:assertType(PuzzleService, "table", "PuzzleService should be a table")
	
	TestFramework:debug("PuzzleService loaded successfully")
end

suite.tests["PuzzleService_HasRequiredMethods"] = function()
	TestFramework:info("Testing PuzzleService has required methods...")
	
	local PuzzleService = require(ServerScriptService:WaitForChild("PuzzleService", 5))
	
	local requiredMethods = {
		"new",
		"requestPuzzle",
		"submitAnswer",
		"generatePuzzle"
	}
	
	for _, methodName in ipairs(requiredMethods) do
		TestFramework:assertNotNil(PuzzleService[methodName],
			string.format("PuzzleService should have %s method", methodName))
		TestFramework:debug("✓ Method exists: %s", methodName)
	end
	
	TestFramework:debug("All required PuzzleService methods present")
end

--------------------------------------------------------------------------------
-- CureSynthesisService Tests
--------------------------------------------------------------------------------

suite.tests["CureSynthesisService_LoadsSuccessfully"] = function()
	TestFramework:info("Testing CureSynthesisService module loading...")
	
	local success, CureSynthesisService = pcall(function()
		return require(ServerScriptService:WaitForChild("CureSynthesisService", 5))
	end)
	
	TestFramework:assertTrue(success, "CureSynthesisService should load without errors")
	TestFramework:assertNotNil(CureSynthesisService, "CureSynthesisService should not be nil")
	TestFramework:assertType(CureSynthesisService, "table", "CureSynthesisService should be a table")
	
	TestFramework:debug("CureSynthesisService loaded successfully")
end

suite.tests["CureSynthesisService_HasRequiredMethods"] = function()
	TestFramework:info("Testing CureSynthesisService has required methods...")
	
	local CureSynthesisService = require(ServerScriptService:WaitForChild("CureSynthesisService", 5))
	
	local requiredMethods = {
		"new",
		"initialize"
	}
	
	for _, methodName in ipairs(requiredMethods) do
		TestFramework:assertNotNil(CureSynthesisService[methodName],
			string.format("CureSynthesisService should have %s method", methodName))
		TestFramework:debug("✓ Method exists: %s", methodName)
	end
	
	TestFramework:debug("All required CureSynthesisService methods present")
end

--------------------------------------------------------------------------------
-- Cure Configuration Tests
--------------------------------------------------------------------------------

suite.tests["CureConfig_ComponentNames"] = function()
	TestFramework:info("Testing cure component names configuration...")
	
	TestFramework:assertNotNil(GameConfig.CURE_COMPONENT_NAMES, "CURE_COMPONENT_NAMES should exist")
	TestFramework:assertType(GameConfig.CURE_COMPONENT_NAMES, "table", "CURE_COMPONENT_NAMES should be a table")
	TestFramework:assertGreaterThan(#GameConfig.CURE_COMPONENT_NAMES, 0, "Should have at least one component name")
	
	TestFramework:debug("Found %d cure component names", #GameConfig.CURE_COMPONENT_NAMES)
	for i, name in ipairs(GameConfig.CURE_COMPONENT_NAMES) do
		TestFramework:debug("  %d. %s", i, name)
	end
end

suite.tests["CureConfig_ComponentRequirements"] = function()
	TestFramework:info("Testing cure component requirements...")
	
	TestFramework:assertNotNil(GameConfig.CURE_COMPONENTS_REQUIRED, "CURE_COMPONENTS_REQUIRED should exist")
	TestFramework:assertType(GameConfig.CURE_COMPONENTS_REQUIRED, "number", "CURE_COMPONENTS_REQUIRED should be a number")
	TestFramework:assertGreaterThan(GameConfig.CURE_COMPONENTS_REQUIRED, 0, "CURE_COMPONENTS_REQUIRED should be positive")
	
	TestFramework:debug("Components required per type: %d", GameConfig.CURE_COMPONENTS_REQUIRED)
end

suite.tests["CureConfig_ProgressTracking"] = function()
	TestFramework:info("Testing cure progress tracking configuration...")
	
	-- Calculate total components needed
	local componentTypes = #GameConfig.CURE_COMPONENT_NAMES
	local componentsPerType = GameConfig.CURE_COMPONENTS_REQUIRED
	local totalComponents = componentTypes * componentsPerType
	
	TestFramework:debug("Total components needed for cure: %d", totalComponents)
	TestFramework:debug("  Component types: %d", componentTypes)
	TestFramework:debug("  Components per type: %d", componentsPerType)
	
	TestFramework:assertGreaterThan(totalComponents, 0, "Total components should be positive")
end

--------------------------------------------------------------------------------
-- CureStation Tests
--------------------------------------------------------------------------------

suite.tests["CureStationSetup_LoadsSuccessfully"] = function()
	TestFramework:info("Testing CureStationSetup module loading...")
	
	local success, CureStationSetup = pcall(function()
		return require(ServerScriptService:WaitForChild("CureStationSetup", 5))
	end)
	
	TestFramework:assertTrue(success, "CureStationSetup should load without errors")
	TestFramework:assertNotNil(CureStationSetup, "CureStationSetup should not be nil")
	TestFramework:assertType(CureStationSetup, "table", "CureStationSetup should be a table")
	
	TestFramework:debug("CureStationSetup loaded successfully")
end

--------------------------------------------------------------------------------
-- Puzzle Generation Tests
--------------------------------------------------------------------------------

suite.tests["PuzzleGeneration_MathPuzzles"] = function()
	TestFramework:info("Testing math puzzle generation...")
	
	if not PuzzleConfig then
		TestFramework:warn("PuzzleConfig not found, skipping test")
		return
	end
	
	local config = require(PuzzleConfig)
	
	if not config.generateMathPuzzle then
		TestFramework:warn("generateMathPuzzle function not found")
		return
	end
	
	-- Generate a few puzzles to test
	for i = 1, 3 do
		local success, puzzle = pcall(config.generateMathPuzzle)
		TestFramework:assertTrue(success, string.format("Math puzzle %d should generate without errors", i))
		TestFramework:assertNotNil(puzzle, string.format("Math puzzle %d should not be nil", i))
		TestFramework:assertNotNil(puzzle.answer, string.format("Math puzzle %d should have an answer", i))
		
		TestFramework:debug("Generated math puzzle %d with answer: %s", i, tostring(puzzle.answer))
	end
end

suite.tests["PuzzleGeneration_PatternPuzzles"] = function()
	TestFramework:info("Testing pattern puzzle generation...")
	
	if not PuzzleConfig then
		TestFramework:warn("PuzzleConfig not found, skipping test")
		return
	end
	
	local config = require(PuzzleConfig)
	
	if not config.generatePatternPuzzle then
		TestFramework:warn("generatePatternPuzzle function not found")
		return
	end
	
	-- Generate a few puzzles to test
	for i = 1, 3 do
		local success, puzzle = pcall(config.generatePatternPuzzle)
		TestFramework:assertTrue(success, string.format("Pattern puzzle %d should generate without errors", i))
		TestFramework:assertNotNil(puzzle, string.format("Pattern puzzle %d should not be nil", i))
		TestFramework:assertNotNil(puzzle.answer, string.format("Pattern puzzle %d should have an answer", i))
		
		TestFramework:debug("Generated pattern puzzle %d with answer: %s", i, tostring(puzzle.answer))
	end
end

return suite
