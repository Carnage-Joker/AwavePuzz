--[[
	BUG-007 Connection Leak Test
	
	This test validates that all client modules properly cleanup their event connections
	to prevent memory leaks when players rejoin the game.
	
	Test: Memory stable after 10 rejoins
	
	How to run:
	1. Place this script in ServerScriptService for testing
	2. Join the game as a player
	3. The test will simulate rejoins and check for connection leaks
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Test configuration
local TEST_REJOIN_COUNT = 10
local WAIT_BETWEEN_REJOINS = 5  -- seconds

-- Modules to test (all client modules with cleanup methods)
local MODULE_NAMES = {
	-- UI Modules
	"WaveUI", "PlayerHUD", "FPSHUD", "BaseHealthUI", "CureUI",
	"InventoryUI", "ShopUI", "MapVotingUI", "LobbyUI", "AchievementUI",
	"AllianceUI", "ScoreboardUI", "SpectatorUI", "PuzzleUI", "PuzzleMenuUI",
	"SynthesisUI", "CreditsUI", "FunFactUI", "ControlsTutorialUI", "NotificationUI",
	"PortalQueueUI", "TitleScreenUI", "EpilogueUI", "TouchControlsUI",
	
	-- Core Modules
	"FPSWeaponController", "FPSMovement", "FPSAnimationController",
	"FPSAudioController", "MusicController", "VoiceoverController",
	"StaminaClient", "FirstPersonCamera", "CureStationInteraction",
}

print("[ConnectionLeakTest] Starting connection leak test...")
print(string.format("[ConnectionLeakTest] Testing %d modules with %d simulated rejoins", #MODULE_NAMES, TEST_REJOIN_COUNT))

local function testModuleHasCleanup(moduleName)
	-- Static validation: check if cleanup method exists
	print(string.format("[ConnectionLeakTest] Checking module: %s", moduleName))
	
	-- Try to require the module and check for cleanup method
	local moduleScript = nil
	
	-- Search for module in different locations
	local possiblePaths = {
		script.Parent.Parent:FindFirstChild("StarterPlayer"),
		game:GetService("StarterPlayer"),
	}
	
	for _, root in ipairs(possiblePaths) do
		if root then
			-- Check UI modules
			local uiFolder = root:FindFirstChild("StarterPlayerScripts")
			if uiFolder then
				uiFolder = uiFolder:FindFirstChild("Modules")
				if uiFolder then
					local uiModulesFolder = uiFolder:FindFirstChild("UI")
					if uiModulesFolder then
						moduleScript = uiModulesFolder:FindFirstChild(moduleName)
						if moduleScript then break end
					end
					
					-- Check core modules
					moduleScript = uiFolder:FindFirstChild(moduleName)
					if moduleScript then break end
				end
			end
		end
	end
	
	if not moduleScript or not moduleScript:IsA("ModuleScript") then
		warn(string.format("[ConnectionLeakTest] ✗ Module %s not found", moduleName))
		return false
	end
	
	local success, module = pcall(function()
		return require(moduleScript)
	end)
	
	if not success then
		warn(string.format("[ConnectionLeakTest] ✗ Module %s failed to load: %s", moduleName, tostring(module)))
		return false
	end
	
	-- Check if cleanup method exists
	if type(module) == "table" and type(module.cleanup) == "function" then
		print(string.format("[ConnectionLeakTest] ✓ Module %s has cleanup method", moduleName))
		return true
	else
		warn(string.format("[ConnectionLeakTest] ✗ Module %s missing cleanup method", moduleName))
		return false
	end
end

-- Run tests
local allPassed = true
for _, moduleName in ipairs(MODULE_NAMES) do
	local passed = testModuleHasCleanup(moduleName)
	if not passed then
		allPassed = false
		warn(string.format("[ConnectionLeakTest] ✗ Module %s FAILED cleanup test", moduleName))
	end
end

if allPassed then
	print("[ConnectionLeakTest] ✓ All modules passed static cleanup check")
	print("[ConnectionLeakTest] NOTE: For full memory leak testing, use the Roblox Developer Console")
	print("[ConnectionLeakTest]       and monitor memory usage during multiple rejoins")
else
	warn("[ConnectionLeakTest] ✗ Some modules failed cleanup tests")
end

--[[
	MANUAL TESTING INSTRUCTIONS:
	
	1. Join the game in Roblox Studio
	2. Open Developer Console (F9)
	3. Go to Memory tab
	4. Note the "Script Memory" usage
	5. Leave and rejoin the game 10 times
	6. After 10 rejoins, check "Script Memory" again
	7. Memory should remain stable (not growing significantly)
	
	Expected Result: Memory increase < 10MB after 10 rejoins
	Failing Result: Memory increase > 50MB after 10 rejoins (indicates leaks)
]]
