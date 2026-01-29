-- MapSystemTests.lua
-- Tests for map system: MapManager, MapValidator, map loading

local ServerScriptService = game:GetService("ServerScriptService")
local TestFramework = require(script.Parent.TestFramework)

local suite = TestFramework:createSuite("MapSystemTests")

suite.tests["MapManager_LoadsSuccessfully"] = function()
	TestFramework:info("Testing MapManager module loading...")
	local success, MapManager = pcall(function()
		return require(ServerScriptService:WaitForChild("MapManager", 5))
	end)
	TestFramework:assertTrue(success, "MapManager should load without errors")
	TestFramework:assertNotNil(MapManager, "MapManager should not be nil")
	TestFramework:debug("MapManager loaded successfully")
end

suite.tests["MapValidator_LoadsSuccessfully"] = function()
	TestFramework:info("Testing MapValidator module loading...")
	local success, MapValidator = pcall(function()
		return require(ServerScriptService:WaitForChild("MapValidator", 5))
	end)
	TestFramework:assertTrue(success, "MapValidator should load without errors")
	TestFramework:assertNotNil(MapValidator, "MapValidator should not be nil")
	TestFramework:debug("MapValidator loaded successfully")
end

return suite
