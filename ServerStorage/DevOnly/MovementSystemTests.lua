-- MovementSystemTests.lua
-- Tests for movement systems: SprintService, movement validation

local ServerScriptService = game:GetService("ServerScriptService")
local TestFramework = require(script.Parent.TestFramework)

local suite = TestFramework:createSuite("MovementSystemTests")

suite.tests["SprintService_LoadsSuccessfully"] = function()
	TestFramework:info("Testing SprintService module loading...")
	local success, SprintService = pcall(function()
		return require(ServerScriptService:WaitForChild("SprintService", 5))
	end)
	TestFramework:assertTrue(success, "SprintService should load without errors")
	TestFramework:assertNotNil(SprintService, "SprintService should not be nil")
	TestFramework:debug("SprintService loaded successfully")
end

return suite
