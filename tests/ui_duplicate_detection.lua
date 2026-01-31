-- UI Duplicate Detection Test
-- Place this in a LocalScript and run in Roblox Studio to verify no duplicate UIs
-- This should be run AFTER joining the game and all UIs have initialized

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for client to initialize
task.wait(5)

print("========================================")
print("UI DUPLICATE DETECTION TEST")
print("========================================")

-- List of all UI ScreenGuis that should exist
local expectedUIs = {
	"FPSHUD",
	"PlayerHUD",
	"WaveUI",
	"CureUI",
	"BaseHealthUI",
	"InventoryUI",
	"ShopUI",
	"AllianceUI",
	"PuzzleUI",
	"PuzzleMenuUI",
	"ScoreboardUI",
	"MapVotingUI",
	"LobbyUI",
	"SpectatorUI",
	"TitleScreenUI",
	"EpilogueUI",
	"AchievementUI",
	"CreditsUI",
	"FunFactUI",
	"SynthesisUI",
	"ControlsTutorialUI",
	"TouchControls" -- Note: This is "TouchControls" not "TouchControlsUI"
}

local totalDuplicates = 0
local missingUIs = {}
local duplicateUIs = {}

-- Check each expected UI
for _, uiName in ipairs(expectedUIs) do
	local instances = {}
	
	-- Find all instances of this UI
	for _, child in ipairs(playerGui:GetChildren()) do
		if child:IsA("ScreenGui") and child.Name == uiName then
			table.insert(instances, child)
		end
	end
	
	local count = #instances
	
	if count == 0 then
		table.insert(missingUIs, uiName)
		print(string.format("⚠️  %s: MISSING (expected 1, found 0)", uiName))
	elseif count == 1 then
		print(string.format("✅ %s: OK (1 instance)", uiName))
	else
		table.insert(duplicateUIs, {name = uiName, count = count})
		totalDuplicates = totalDuplicates + (count - 1)
		print(string.format("❌ %s: DUPLICATE (expected 1, found %d)", uiName, count))
	end
end

-- Check for unexpected UIs
print("\n--- Additional ScreenGuis in PlayerGui ---")
for _, child in ipairs(playerGui:GetChildren()) do
	if child:IsA("ScreenGui") then
		local isExpected = false
		for _, expectedName in ipairs(expectedUIs) do
			if child.Name == expectedName then
				isExpected = true
				break
			end
		end
		
		if not isExpected then
			print(string.format("ℹ️  Unexpected: %s", child.Name))
		end
	end
end

-- Summary
print("\n========================================")
print("SUMMARY")
print("========================================")
print(string.format("Total Expected UIs: %d", #expectedUIs))
print(string.format("Missing UIs: %d", #missingUIs))
print(string.format("Duplicate UIs: %d", #duplicateUIs))
print(string.format("Total Duplicate Instances: %d", totalDuplicates))

if #duplicateUIs > 0 then
	print("\n❌ TEST FAILED - Duplicates detected!")
	print("Duplicate UIs:")
	for _, dup in ipairs(duplicateUIs) do
		print(string.format("  - %s (%d instances)", dup.name, dup.count))
	end
else
	print("\n✅ TEST PASSED - No duplicates detected!")
end

if #missingUIs > 0 then
	print("\nℹ️  Missing UIs (may be intentional if not enabled):")
	for _, missing in ipairs(missingUIs) do
		print(string.format("  - %s", missing))
	end
end

print("========================================")
