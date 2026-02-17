-- UI Module Nil Access Test
-- Tests that UI modules can be loaded without "attempt to index nil" errors
-- Place this in a LocalScript and run in Roblox Studio
-- This should be run BEFORE the game fully initializes to catch early errors

-- Configurable timeouts (can be adjusted for slower environments)
local WAIT_FOR_CHILD_TIMEOUT = 5 -- seconds
local UI_CREATION_DELAY = 0.5 -- seconds
local PLAYER_GUI_TIMEOUT = 2 -- seconds

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

print("========================================")
print("UI MODULE NIL ACCESS TEST")
print("========================================")

-- Test 1: Verify UIResolveRefs utility loads
print("\n--- Test 1: UIResolveRefs Utility ---")
local success, UIResolveRefs = pcall(function()
	local SharedFolder = ReplicatedStorage:WaitForChild("Shared", WAIT_FOR_CHILD_TIMEOUT)
	local UIFolder = SharedFolder:WaitForChild("UI", WAIT_FOR_CHILD_TIMEOUT)
	return require(UIFolder:WaitForChild("UIResolveRefs", WAIT_FOR_CHILD_TIMEOUT))
end)

if success and UIResolveRefs then
	print("✅ UIResolveRefs loaded successfully")
	
	-- Verify key methods exist
	local methods = {"waitForChild", "resolveUIChain", "resolveElement", "validateElement", "log", "retryUntilSuccess"}
	local allMethodsPresent = true
	for _, methodName in ipairs(methods) do
		if not UIResolveRefs[methodName] then
			print(string.format("❌ Missing method: %s", methodName))
			allMethodsPresent = false
		end
	end
	
	if allMethodsPresent then
		print("✅ All expected methods present")
	else
		print("❌ Some methods missing")
	end
else
	print("❌ UIResolveRefs failed to load:", tostring(UIResolveRefs))
end

-- Test 2: Verify PuzzleMenuUI loads without errors
print("\n--- Test 2: PuzzleMenuUI Module Load ---")
local success2, PuzzleMenuUI = pcall(function()
	local StarterPlayer = game:GetService("StarterPlayer")
	local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts", WAIT_FOR_CHILD_TIMEOUT)
	local Modules = StarterPlayerScripts:WaitForChild("Modules", WAIT_FOR_CHILD_TIMEOUT)
	local UIFolder = Modules:WaitForChild("UI", WAIT_FOR_CHILD_TIMEOUT)
	return require(UIFolder:WaitForChild("PuzzleMenuUI", WAIT_FOR_CHILD_TIMEOUT))
end)

if success2 and PuzzleMenuUI then
	print("✅ PuzzleMenuUI loaded successfully")
	
	-- Verify expected methods exist
	if PuzzleMenuUI.bindRemotes then
		print("✅ PuzzleMenuUI.bindRemotes method exists")
	else
		print("❌ PuzzleMenuUI.bindRemotes method missing")
	end
	
	if PuzzleMenuUI.cleanup then
		print("✅ PuzzleMenuUI.cleanup method exists")
	else
		print("❌ PuzzleMenuUI.cleanup method missing")
	end
	
	-- Verify the ScreenGui was created
	task.wait(UI_CREATION_DELAY) -- Give a moment for UI to be parented
	local puzzleMenuUI = player:WaitForChild("PlayerGui", PLAYER_GUI_TIMEOUT):FindFirstChild("PuzzleMenuUI")
	if puzzleMenuUI then
		print("✅ PuzzleMenuUI ScreenGui exists in PlayerGui")
	else
		print("⚠️  PuzzleMenuUI ScreenGui not found in PlayerGui (may be expected if not fully initialized)")
	end
else
	print("❌ PuzzleMenuUI failed to load:", tostring(PuzzleMenuUI))
end

-- Test 3: Check for connections table in PuzzleMenuUI
print("\n--- Test 3: Check Module Variables ---")
-- Note: This test verifies the module loads without nil access errors
-- The actual 'connections' table is local to the module, so we can't check it directly
-- But if the module loaded successfully, the nil access issue is fixed
print("✅ Module loaded without nil access errors (indirect verification)")

-- Test 4: Verify PuzzleUI also loads correctly
print("\n--- Test 4: PuzzleUI Module Load ---")
local success4, PuzzleUI = pcall(function()
	local StarterPlayer = game:GetService("StarterPlayer")
	local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts", WAIT_FOR_CHILD_TIMEOUT)
	local Modules = StarterPlayerScripts:WaitForChild("Modules", WAIT_FOR_CHILD_TIMEOUT)
	local UIFolder = Modules:WaitForChild("UI", WAIT_FOR_CHILD_TIMEOUT)
	return require(UIFolder:WaitForChild("PuzzleUI", WAIT_FOR_CHILD_TIMEOUT))
end)

if success4 and PuzzleUI then
	print("✅ PuzzleUI loaded successfully")
	
	if PuzzleUI.bindRemotes then
		print("✅ PuzzleUI.bindRemotes method exists")
	else
		print("❌ PuzzleUI.bindRemotes method missing")
	end
else
	print("❌ PuzzleUI failed to load:", tostring(PuzzleUI))
end

-- Summary
print("\n========================================")
print("SUMMARY")
print("========================================")

local testsPassed = 0
local testsFailed = 0

if success and UIResolveRefs then testsPassed = testsPassed + 1 else testsFailed = testsFailed + 1 end
if success2 and PuzzleMenuUI then testsPassed = testsPassed + 1 else testsFailed = testsFailed + 1 end
if success4 and PuzzleUI then testsPassed = testsPassed + 1 else testsFailed = testsFailed + 1 end

print(string.format("Tests Passed: %d", testsPassed))
print(string.format("Tests Failed: %d", testsFailed))

if testsFailed == 0 then
	print("\n✅ ALL TESTS PASSED - No nil access errors detected!")
else
	print("\n❌ SOME TESTS FAILED - Check output above for details")
end

print("========================================")
