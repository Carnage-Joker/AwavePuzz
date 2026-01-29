-- ShopSystemTests.lua
-- Tests for shop system: ShopService, item purchases, currency management

local ServerScriptService = game:GetService("ServerScriptService")
local TestFramework = require(script.Parent.TestFramework)

local suite = TestFramework:createSuite("ShopSystemTests")

suite.tests["ShopService_LoadsSuccessfully"] = function()
	TestFramework:info("Testing ShopService module loading...")
	local success, ShopService = pcall(function()
		return require(ServerScriptService:WaitForChild("ShopService", 5))
	end)
	TestFramework:assertTrue(success, "ShopService should load without errors")
	TestFramework:assertNotNil(ShopService, "ShopService should not be nil")
	TestFramework:debug("ShopService loaded successfully")
end

suite.tests["ShopService_HasRequiredMethods"] = function()
	TestFramework:info("Testing ShopService has required methods...")
	local ShopService = require(ServerScriptService:WaitForChild("ShopService", 5))
	local requiredMethods = {"new", "purchaseItem"}
	for _, methodName in ipairs(requiredMethods) do
		TestFramework:assertNotNil(ShopService[methodName],
			string.format("ShopService should have %s method", methodName))
		TestFramework:debug("✓ Method exists: %s", methodName)
	end
	TestFramework:debug("All required ShopService methods present")
end

return suite
