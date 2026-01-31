-- UISystemTests.lua
-- Tests for UI systems: InputActionRegistry, ModalManager, UI controllers

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestFramework = require(script.Parent.TestFramework)

local suite = TestFramework:createSuite("UISystemTests")

suite.tests["InputActionRegistry_Available"] = function()
	TestFramework:info("Testing InputActionRegistry availability...")
	local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
	local InputActionRegistry = SharedFolder:FindFirstChild("InputActionRegistry")
	if InputActionRegistry then
		local success, module = pcall(require, InputActionRegistry)
		TestFramework:assertTrue(success, "InputActionRegistry should load")
		TestFramework:debug("InputActionRegistry available")
	else
		TestFramework:warn("InputActionRegistry not found")
	end
end

suite.tests["ModalManager_Available"] = function()
	TestFramework:info("Testing ModalManager availability...")
	local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
	local ModalManager = SharedFolder:FindFirstChild("ModalManager")
	if ModalManager then
		local success, module = pcall(require, ModalManager)
		TestFramework:assertTrue(success, "ModalManager should load")
		TestFramework:debug("ModalManager available")
	else
		TestFramework:warn("ModalManager not found")
	end
end

suite.tests["InputActionRegistry_IdempotentRegistration"] = function()
	TestFramework:info("Testing InputActionRegistry idempotent registration...")
	local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
	local InputActionRegistry = SharedFolder:FindFirstChild("InputActionRegistry")
	
	if not InputActionRegistry then
		TestFramework:warn("InputActionRegistry not found, skipping test")
		return
	end
	
	local success, Registry = pcall(require, InputActionRegistry)
	if not success then
		TestFramework:fail("Failed to load InputActionRegistry: " .. tostring(Registry))
		return
	end
	
	-- Clear any existing test registrations
	Registry.unregister("TestAction1")
	
	-- Register an action for the first time
	Registry.register("TestAction1", "TestOwner", {Enum.KeyCode.T}, Registry.Priority.CORE_GAMEPLAY, true)
	
	-- Verify it's registered
	local action = Registry.getAction("TestAction1")
	TestFramework:assertTrue(action ~= nil, "Action should be registered")
	TestFramework:assertEqual(action.owner, "TestOwner", "Owner should match")
	
	-- Register the same action again with identical parameters (idempotent)
	-- This should NOT produce a warning
	Registry.register("TestAction1", "TestOwner", {Enum.KeyCode.T}, Registry.Priority.CORE_GAMEPLAY, true)
	
	-- Verify it's still registered correctly
	action = Registry.getAction("TestAction1")
	TestFramework:assertTrue(action ~= nil, "Action should still be registered")
	TestFramework:assertEqual(action.owner, "TestOwner", "Owner should still match")
	
	-- Try to register with a different owner (should warn)
	Registry.register("TestAction1", "DifferentOwner", {Enum.KeyCode.T}, Registry.Priority.CORE_GAMEPLAY, true)
	
	-- Verify the registration was updated
	action = Registry.getAction("TestAction1")
	TestFramework:assertEqual(action.owner, "DifferentOwner", "Owner should be updated")
	
	-- Clean up
	Registry.unregister("TestAction1")
	TestFramework:debug("Idempotent registration test completed")
end

return suite
