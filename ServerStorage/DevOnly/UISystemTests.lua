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

return suite
