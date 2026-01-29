-- LobbySystemTests.lua
-- Tests for lobby system: LobbyManager, PortalMatchmaking, LobbySetup

local ServerScriptService = game:GetService("ServerScriptService")
local TestFramework = require(script.Parent.TestFramework)

local suite = TestFramework:createSuite("LobbySystemTests")

suite.tests["LobbyManager_LoadsSuccessfully"] = function()
	TestFramework:info("Testing LobbyManager module loading...")
	local success, LobbyManager = pcall(function()
		return require(ServerScriptService:WaitForChild("LobbyManager", 5))
	end)
	TestFramework:assertTrue(success, "LobbyManager should load without errors")
	TestFramework:assertNotNil(LobbyManager, "LobbyManager should not be nil")
	TestFramework:debug("LobbyManager loaded successfully")
end

suite.tests["LobbySetup_LoadsSuccessfully"] = function()
	TestFramework:info("Testing LobbySetup module loading...")
	local success, LobbySetup = pcall(function()
		return require(ServerScriptService:WaitForChild("LobbySetup", 5))
	end)
	TestFramework:assertTrue(success, "LobbySetup should load without errors")
	TestFramework:assertNotNil(LobbySetup, "LobbySetup should not be nil")
	TestFramework:debug("LobbySetup loaded successfully")
end

return suite
