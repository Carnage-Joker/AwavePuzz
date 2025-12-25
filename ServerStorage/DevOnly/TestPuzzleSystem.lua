-- DEV/TEST SCRIPT - Only runs in Studio
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
return
end

-- TestPuzzleSystem.lua
-- Simple test script to verify puzzle system structure
-- This can be run in Roblox Studio Command Bar for quick testing
--
-- WHO RUNS: Server (test/debug only)
-- PURPOSE: Validates puzzle system configuration and structure
-- REQUIRES: GameConfig.DEBUG = true to execute

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Early exit if DEBUG mode is not enabled
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
if not GameConfig.DEBUG then
	return
end

print("=== Testing Puzzle System ===")

-- Test 1: Load PuzzleConfig
print("\n[Test 1] Loading PuzzleConfig...")
local success1, PuzzleConfig = pcall(function()
	return require(ReplicatedStorage.Shared.PuzzleConfig)
end)

if success1 then
	print("✓ PuzzleConfig loaded successfully")
	print("  - Puzzle types:", #PuzzleConfig.ComponentPuzzles)
	for componentName, puzzle in pairs(PuzzleConfig.ComponentPuzzles) do
		print("    -", componentName, ":", puzzle.name, "(" .. puzzle.type .. ")")
	end
else
	warn("✗ Failed to load PuzzleConfig:", PuzzleConfig)
end

-- Test 2: Check GameConfig updates
print("\n[Test 2] Checking GameConfig...")
local success2, GameConfig = pcall(function()
	return require(ReplicatedStorage.Shared.GameConfig)
end)

if success2 then
	print("✓ GameConfig loaded successfully")
	print("  - Component names:", #GameConfig.CURE_COMPONENT_NAMES)
	print("  - Components required per type:", GameConfig.CURE_COMPONENTS_REQUIRED)
	print("  - Resource spawn rate:", GameConfig.RESOURCE_SPAWN_RATE)
else
	warn("✗ Failed to load GameConfig:", GameConfig)
end

-- Test 3: Check server scripts exist
print("\n[Test 3] Checking server scripts...")
local scriptsToCheck = {
	"PuzzleService",
	"CureService",
	"CureStationSetup",
	"AllianceService"
}

for _, scriptName in ipairs(scriptsToCheck) do
	local script = ServerScriptService:FindFirstChild(scriptName)
	if script then
		print("✓", scriptName, "exists")
	else
		warn("✗", scriptName, "not found")
	end
end

-- Test 4: Check client UI scripts
print("\n[Test 4] Checking client UI scripts...")
local uiScriptsToCheck = {
	"PuzzleUI",
	"PuzzleMenuUI"
}

-- Note: These would be in StarterPlayer.StarterPlayerScripts or StarterGui
-- For now just verify they're in the source
print("  (Client scripts should be placed in StarterPlayer.StarterPlayerScripts or StarterGui)")

-- Test 5: Check RemoteEvents
print("\n[Test 5] Checking RemoteEvents...")
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if remoteEvents then
	print("✓ RemoteEvents folder exists")
	
	local expectedEvents = {
		"RequestPuzzle",
		"SubmitPuzzleAnswer",
		"OpenPuzzleUI",
		"PuzzleCompleted",
		"PuzzleFailed",
		"CureUpdate"
	}
	
	for _, eventName in ipairs(expectedEvents) do
		local event = remoteEvents:FindFirstChild(eventName)
		if event then
			print("  ✓", eventName)
		else
			print("  ⚠", eventName, "not created yet (will be created on server start)")
		end
	end
else
	print("⚠ RemoteEvents folder not found (will be created on server start)")
end

-- Test 6: Generate sample puzzles
print("\n[Test 6] Testing puzzle generation...")
if success1 then
	-- Test math puzzle generation
	local mathPuzzle = PuzzleConfig.generateMathPuzzle()
	print("✓ Math puzzle generated:")
	if mathPuzzle.equation then
		print("  - Equation:", mathPuzzle.equation)
	elseif mathPuzzle.sequence then
		local seqStr = ""
		for i = 1, #mathPuzzle.sequence + 1 do
			seqStr = seqStr .. (mathPuzzle.sequence[i] or "?") .. " "
		end
		print("  - Sequence:", seqStr)
	end
	print("  - Answer:", mathPuzzle.answer)
	
	-- Test pattern puzzle generation
	local patternPuzzle = PuzzleConfig.generatePatternPuzzle()
	print("✓ Pattern puzzle generated:")
	local patSeqStr = ""
	if patternPuzzle.sequence then
		for i = 1, #patternPuzzle.sequence + 1 do
			patSeqStr = patSeqStr .. tostring(patternPuzzle.sequence[i] or "?") .. " "
		end
		print("  - Sequence:", patSeqStr)
	end
	print("  - Answer:", patternPuzzle.answer)
end

print("\n=== Puzzle System Test Complete ===")
print("If all tests passed, the puzzle system is ready for integration testing!")
