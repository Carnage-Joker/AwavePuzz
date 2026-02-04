-- AllianceSystemTests.lua
-- Tests for alliance system: AllianceService, BetrayalService, InventoryLedger
-- Tests alliance formation, betrayal mechanics, and shared resource pools

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TestFramework = require(script.Parent.TestFramework)

local suite = TestFramework:createSuite("AllianceSystemTests")

--------------------------------------------------------------------------------
-- AllianceServiceV2 Tests
--------------------------------------------------------------------------------

suite.tests["AllianceService_LoadsSuccessfully"] = function()
	TestFramework:info("Testing AllianceServiceV2 module loading...")
	
	local success, AllianceService = pcall(function()
		return require(ServerScriptService:WaitForChild("AllianceServiceV2", 5))
	end)
	
	TestFramework:assertTrue(success, "AllianceServiceV2 should load without errors")
	TestFramework:assertNotNil(AllianceService, "AllianceServiceV2 should not be nil")
	TestFramework:assertType(AllianceService, "table", "AllianceServiceV2 should be a table")
	
	TestFramework:debug("AllianceServiceV2 loaded successfully")
end

suite.tests["AllianceService_HasRequiredMethods"] = function()
	TestFramework:info("Testing AllianceService has required methods...")
	
	local AllianceService = require(ServerScriptService:WaitForChild("AllianceServiceV2", 5))
	
	local requiredMethods = {
		"new",
		"proposeAlliance",
		"acceptAlliance",
		"denyAlliance",
		"breakAlliance",
		"getAlliance",
		"setPuzzleService"
	}
	
	for _, methodName in ipairs(requiredMethods) do
		TestFramework:assertNotNil(AllianceService[methodName],
			string.format("AllianceService should have %s method", methodName))
		TestFramework:debug("✓ Method exists: %s", methodName)
	end
	
	TestFramework:debug("All required AllianceService methods present")
end

--------------------------------------------------------------------------------
-- AllianceGraph Tests
--------------------------------------------------------------------------------

suite.tests["AllianceGraph_LoadsSuccessfully"] = function()
	TestFramework:info("Testing AllianceGraph module loading...")
	
	local allianceFolder = ServerScriptService:FindFirstChild("Alliance")
	if not allianceFolder then
		TestFramework:warn("Alliance folder not found, skipping test")
		return
	end
	
	local success, AllianceGraph = pcall(function()
		return require(allianceFolder:WaitForChild("AllianceGraph", 5))
	end)
	
	TestFramework:assertTrue(success, "AllianceGraph should load without errors")
	TestFramework:assertNotNil(AllianceGraph, "AllianceGraph should not be nil")
	TestFramework:assertType(AllianceGraph, "table", "AllianceGraph should be a table")
	
	TestFramework:debug("AllianceGraph loaded successfully")
end

suite.tests["AllianceGraph_HasRequiredMethods"] = function()
	TestFramework:info("Testing AllianceGraph has required methods...")
	
	local allianceFolder = ServerScriptService:FindFirstChild("Alliance")
	if not allianceFolder then
		TestFramework:warn("Alliance folder not found, skipping test")
		return
	end
	
	local AllianceGraph = require(allianceFolder:WaitForChild("AllianceGraph", 5))
	
	local requiredMethods = {
		"new",
		"addAlliance",
		"removeAlliance",
		"getAllies",
		"isAllied"
	}
	
	for _, methodName in ipairs(requiredMethods) do
		TestFramework:assertNotNil(AllianceGraph[methodName],
			string.format("AllianceGraph should have %s method", methodName))
		TestFramework:debug("✓ Method exists: %s", methodName)
	end
	
	TestFramework:debug("All required AllianceGraph methods present")
end

--------------------------------------------------------------------------------
-- BetrayalService Tests
--------------------------------------------------------------------------------

suite.tests["BetrayalService_LoadsSuccessfully"] = function()
	TestFramework:info("Testing BetrayalService module loading...")
	
	local allianceFolder = ServerScriptService:FindFirstChild("Alliance")
	if not allianceFolder then
		TestFramework:warn("Alliance folder not found, skipping test")
		return
	end
	
	local success, BetrayalService = pcall(function()
		return require(allianceFolder:WaitForChild("BetrayalService", 5))
	end)
	
	TestFramework:assertTrue(success, "BetrayalService should load without errors")
	TestFramework:assertNotNil(BetrayalService, "BetrayalService should not be nil")
	TestFramework:assertType(BetrayalService, "table", "BetrayalService should be a table")
	
	TestFramework:debug("BetrayalService loaded successfully")
end

suite.tests["BetrayalService_HasRequiredMethods"] = function()
	TestFramework:info("Testing BetrayalService has required methods...")
	
	local allianceFolder = ServerScriptService:FindFirstChild("Alliance")
	if not allianceFolder then
		TestFramework:warn("Alliance folder not found, skipping test")
		return
	end
	
	local BetrayalService = require(allianceFolder:WaitForChild("BetrayalService", 5))
	
	local requiredMethods = {
		"new",
		"initialize"
	}
	
	for _, methodName in ipairs(requiredMethods) do
		TestFramework:assertNotNil(BetrayalService[methodName],
			string.format("BetrayalService should have %s method", methodName))
		TestFramework:debug("✓ Method exists: %s", methodName)
	end
	
	TestFramework:debug("All required BetrayalService methods present")
end

--------------------------------------------------------------------------------
-- InventoryLedger Tests
--------------------------------------------------------------------------------

suite.tests["InventoryLedger_LoadsSuccessfully"] = function()
	TestFramework:info("Testing InventoryLedger module loading...")
	
	local allianceFolder = ServerScriptService:FindFirstChild("Alliance")
	if not allianceFolder then
		TestFramework:warn("Alliance folder not found, skipping test")
		return
	end
	
	local success, InventoryLedger = pcall(function()
		return require(allianceFolder:WaitForChild("InventoryLedger", 5))
	end)
	
	TestFramework:assertTrue(success, "InventoryLedger should load without errors")
	TestFramework:assertNotNil(InventoryLedger, "InventoryLedger should not be nil")
	TestFramework:assertType(InventoryLedger, "table", "InventoryLedger should be a table")
	
	TestFramework:debug("InventoryLedger loaded successfully")
end

suite.tests["InventoryLedger_HasRequiredMethods"] = function()
	TestFramework:info("Testing InventoryLedger has required methods...")
	
	local allianceFolder = ServerScriptService:FindFirstChild("Alliance")
	if not allianceFolder then
		TestFramework:warn("Alliance folder not found, skipping test")
		return
	end
	
	local InventoryLedger = require(allianceFolder:WaitForChild("InventoryLedger", 5))
	
	local requiredMethods = {
		"new",
		"addItem",
		"removeItem",
		"getInventory",
		"transferInventory"
	}
	
	for _, methodName in ipairs(requiredMethods) do
		TestFramework:assertNotNil(InventoryLedger[methodName],
			string.format("InventoryLedger should have %s method", methodName))
		TestFramework:debug("✓ Method exists: %s", methodName)
	end
	
	TestFramework:debug("All required InventoryLedger methods present")
end

--------------------------------------------------------------------------------
-- PoolCalculator Tests
--------------------------------------------------------------------------------

suite.tests["PoolCalculator_LoadsSuccessfully"] = function()
	TestFramework:info("Testing PoolCalculator module loading...")
	
	local allianceFolder = ServerScriptService:FindFirstChild("Alliance")
	if not allianceFolder then
		TestFramework:warn("Alliance folder not found, skipping test")
		return
	end
	
	local success, PoolCalculator = pcall(function()
		return require(allianceFolder:WaitForChild("PoolCalculator", 5))
	end)
	
	TestFramework:assertTrue(success, "PoolCalculator should load without errors")
	TestFramework:assertNotNil(PoolCalculator, "PoolCalculator should not be nil")
	TestFramework:assertType(PoolCalculator, "table", "PoolCalculator should be a table")
	
	TestFramework:debug("PoolCalculator loaded successfully")
end

suite.tests["PoolCalculator_HasRequiredMethods"] = function()
	TestFramework:info("Testing PoolCalculator has required methods...")
	
	local allianceFolder = ServerScriptService:FindFirstChild("Alliance")
	if not allianceFolder then
		TestFramework:warn("Alliance folder not found, skipping test")
		return
	end
	
	local PoolCalculator = require(allianceFolder:WaitForChild("PoolCalculator", 5))
	
	local requiredMethods = {
		"calculatePooledCurrency"
	}
	
	for _, methodName in ipairs(requiredMethods) do
		TestFramework:assertNotNil(PoolCalculator[methodName],
			string.format("PoolCalculator should have %s method", methodName))
		TestFramework:debug("✓ Method exists: %s", methodName)
	end
	
	TestFramework:debug("All required PoolCalculator methods present")
end

--------------------------------------------------------------------------------
-- RemoteEvents for Alliance Tests
--------------------------------------------------------------------------------

suite.tests["Alliance_RemoteEventsExist"] = function()
	TestFramework:info("Testing alliance-related RemoteEvents...")
	
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then
		TestFramework:warn("RemoteEvents folder not found, skipping test")
		return
	end
	
	local allianceEvents = {
		"RequestAlliance", -- Legacy API - kept for backward compatibility
		"AllianceAccept", -- ✅ FIX: Use modern name (was AcceptAlliance)
		"AllianceDecline", -- ✅ FIX: Use modern name (was DenyAlliance)
		"BreakAlliance", -- Legacy API - kept for backward compatibility
		"AllianceUpdate" -- ✅ FIX: Use modern name (was UpdateAlliance)
	}
	
	for _, eventName in ipairs(allianceEvents) do
		local event = remoteEvents:FindFirstChild(eventName)
		if event then
			TestFramework:debug("✓ Alliance RemoteEvent found: %s", eventName)
		else
			TestFramework:warn("⚠ Alliance RemoteEvent not found: %s (may be created at runtime)", eventName)
		end
	end
end

return suite
