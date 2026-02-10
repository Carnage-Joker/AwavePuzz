-- Security Test Runner
-- Copy and paste this script into Roblox Studio's Command Bar to run security tests
-- This validates BUG-004 (Wallhack) and BUG-009 (Client Authority) fixes

local SecurityTests = require(game.ReplicatedStorage.Parent.tests.security_validation_tests)
SecurityTests.runAll()
