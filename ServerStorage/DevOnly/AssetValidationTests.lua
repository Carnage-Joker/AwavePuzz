-- AssetValidationTests.lua
-- Tests for AssetValidation module to ensure proper ID validation
-- Tests that long asset IDs are not rejected

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestFramework = require(script.Parent.TestFramework)

local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)

local suite = TestFramework:createSuite("AssetValidationTests")

--------------------------------------------------------------------------------
-- AssetValidation Tests
--------------------------------------------------------------------------------

suite.tests["AssetValidation_AcceptsLongIDs"] = function()
	TestFramework:info("Testing AssetValidation accepts long asset IDs...")
	
	local AssetValidation = require(SharedFolder:WaitForChild("AssetValidation", 5))
	
	-- Test with various length IDs
	local testAssets = {
		-- Short ID (9 digits) - should pass
		ShortID = "rbxassetid://123456789",
		-- Medium ID (13 digits) - should pass
		MediumID = "rbxassetid://1234567890123",
		-- Long ID (15 digits) - should pass (this was being rejected before)
		LongID = "rbxassetid://123456789012345",
		-- Very long ID (20 digits) - should pass
		VeryLongID = "rbxassetid://12345678901234567890",
		-- Invalid: zero
		InvalidZero = "rbxassetid://0",
		-- Invalid: empty
		InvalidEmpty = "",
	}
	
	TestFramework:info("Running validation on test assets...")
	local invalidKeys = AssetValidation.validateSoundAssets(testAssets, "LongIDTest")
	
	-- Should only have 2 invalid assets (InvalidZero and InvalidEmpty)
	TestFramework:assertEqual(#invalidKeys, 2, "Should have exactly 2 invalid assets")
	
	-- Verify that the invalid keys are the expected ones
	local hasInvalidZero = false
	local hasInvalidEmpty = false
	for _, key in ipairs(invalidKeys) do
		if key:match("InvalidZero") then
			hasInvalidZero = true
		elseif key:match("InvalidEmpty") then
			hasInvalidEmpty = true
		end
	end
	
	TestFramework:assertTrue(hasInvalidZero, "InvalidZero should be flagged as invalid")
	TestFramework:assertTrue(hasInvalidEmpty, "InvalidEmpty should be flagged as invalid")
	
	TestFramework:debug("Long ID validation test passed")
end

suite.tests["AssetValidation_ExtractsDigitsCorrectly"] = function()
	TestFramework:info("Testing AssetValidation extracts digits after rbxassetid://...")
	
	local AssetValidation = require(SharedFolder:WaitForChild("AssetValidation", 5))
	
	-- Test with various formats
	local testAssets = {
		-- Valid formats
		Valid1 = "rbxassetid://123456789",
		Valid2 = "rbxassetid://999999999999999999",
		Valid3 = 123456789, -- numeric format
		-- Invalid formats
		Invalid1 = "rbxassetid://", -- no number
		Invalid2 = "rbxassetid://abc123", -- contains letters
		Invalid3 = "rbxassetid://-123", -- malformed format (contains minus sign)
	}
	
	TestFramework:info("Running validation on format test...")
	local invalidKeys = AssetValidation.validateSoundAssets(testAssets, "FormatTest")
	
	-- Should have 3 invalid assets
	TestFramework:assertEqual(#invalidKeys, 3, "Should have exactly 3 invalid assets")
	
	TestFramework:debug("Format extraction test passed")
end

suite.tests["AssetValidation_RejectsZeroAndNegative"] = function()
	TestFramework:info("Testing AssetValidation rejects zero and negative IDs...")
	
	local AssetValidation = require(SharedFolder:WaitForChild("AssetValidation", 5))
	
	-- Test with edge cases
	local testAssets = {
		Zero1 = "rbxassetid://0",
		Zero2 = 0,
		Zero3 = "0",
		Negative1 = -123, -- raw negative number
		Negative2 = "-123", -- string negative number
		PositiveValid = "rbxassetid://1", -- minimum valid ID
		LargeValid = "rbxassetid://99999999999999999999", -- very large ID
	}
	
	TestFramework:info("Running validation on zero/negative test...")
	local invalidKeys = AssetValidation.validateSoundAssets(testAssets, "ZeroTest")
	
	-- Should have 5 invalid assets (all the zeros and negatives)
	TestFramework:assertEqual(#invalidKeys, 5, "Should have exactly 5 invalid assets (zeros and negatives)")
	
	TestFramework:debug("Zero/negative rejection test passed")
end

return suite
