-- Security Test Runner
-- Copy and paste this script into Roblox Studio's Command Bar to run security tests
-- This validates BUG-004 (Wallhack) and BUG-009 (Client Authority) fixes

-- Note: Place security_validation_tests.lua in ReplicatedStorage.tests or adjust path
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local testsFolder = ReplicatedStorage:FindFirstChild("tests")
if not testsFolder then
	error("tests folder not found in ReplicatedStorage. Please create it and place security_validation_tests.lua inside.")
end

local SecurityTests = require(testsFolder.security_validation_tests)
SecurityTests.runAll()
