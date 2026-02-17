-- Boot Smoke Test Runner
-- Quick runner for boot validation tests
-- Run this in Roblox Studio Command Bar to validate boot system health
--
-- Usage (in Command Bar):
-- local tests = require(game.ReplicatedStorage.tests.boot_smoke_tests)
-- tests.runAll()

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Try to find the tests folder
local testsFolder = ReplicatedStorage:FindFirstChild("tests")
if not testsFolder then
	error("tests folder not found in ReplicatedStorage. Please create it and place boot_smoke_tests.lua inside.")
end

-- Load and run the boot smoke tests
local BootSmokeTests = require(testsFolder.boot_smoke_tests)
return BootSmokeTests.runAll()
