-- SpectatorSystemTests.lua
-- Tests for spectator system: SpectatorManager, death handling

local ServerScriptService = game:GetService("ServerScriptService")
local TestFramework = require(script.Parent.TestFramework)

local suite = TestFramework:createSuite("SpectatorSystemTests")

suite.tests["SpectatorManager_LoadsSuccessfully"] = function()
	TestFramework:info("Testing SpectatorManager module loading...")
	local success, SpectatorManager = pcall(function()
		return require(ServerScriptService:WaitForChild("SpectatorManager", 5))
	end)
	TestFramework:assertTrue(success, "SpectatorManager should load without errors")
	TestFramework:assertNotNil(SpectatorManager, "SpectatorManager should not be nil")
	TestFramework:debug("SpectatorManager loaded successfully")
end

return suite
