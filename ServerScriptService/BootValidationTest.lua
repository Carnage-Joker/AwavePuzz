-- @ScriptType: Script
-- BootValidationTest.lua
-- Test script to verify boot stabilization fixes
-- Place in ServerScriptService temporarily for testing, then remove

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

print("=== Boot Stabilization Validation Test ===")

-- Wait a bit for all systems to initialize
task.wait(2)

--------------------------------------------------------------------------------
-- Test A: Lobby Creation Idempotency
--------------------------------------------------------------------------------
print("\n[Test A] Checking Lobby Idempotency...")
local lobbiesInWorkspace = 0
for _, obj in ipairs(Workspace:GetChildren()) do
	if obj.Name == "LobbyArea" or obj.Name == "Lobby" then
		lobbiesInWorkspace = lobbiesInWorkspace + 1
		print("  - Found lobby:", obj.Name)
	end
end

if lobbiesInWorkspace == 1 then
	print("  ✓ PASS: Exactly one lobby found in Workspace")
elseif lobbiesInWorkspace == 0 then
	print("  ⚠ WARNING: No lobby found (might be expected if not yet created)")
else
	print("  ✗ FAIL: Multiple lobbies found (" .. lobbiesInWorkspace .. ")")
end

--------------------------------------------------------------------------------
-- Test B: Map Pivot Position
--------------------------------------------------------------------------------
print("\n[Test B] Checking Map Pivot Position...")
local activeMap = Workspace:FindFirstChild("ActiveMap")
if activeMap then
	local pivot = activeMap:GetPivot()
	local expectedPos = Vector3.new(5000, 0, 0)
	local distance = (pivot.Position - expectedPos).Magnitude
	
	print(string.format("  - Map pivot: (%.2f, %.2f, %.2f)", pivot.Position.X, pivot.Position.Y, pivot.Position.Z))
	print(string.format("  - Expected: (%.2f, %.2f, %.2f)", expectedPos.X, expectedPos.Y, expectedPos.Z))
	print(string.format("  - Distance: %.4f studs", distance))
	
	if distance < 0.01 then
		print("  ✓ PASS: Map pivot is at correct position")
	else
		print("  ✗ FAIL: Map pivot is off by " .. distance .. " studs")
	end
else
	print("  ⚠ WARNING: No ActiveMap found (might not be loaded yet)")
end

--------------------------------------------------------------------------------
-- Test C: CureStations Dev Gating
--------------------------------------------------------------------------------
print("\n[Test C] Checking CureStations Dev Gating...")
local SharedFolder = ReplicatedStorage:FindFirstChild("Shared")
if SharedFolder then
	local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
	local isStudio = RunService:IsStudio()
	local devFlag = GameConfig.DEV_AUTO_CREATE_CURE_STATIONS
	
	print("  - Running in Studio:", isStudio)
	print("  - DEV_AUTO_CREATE_CURE_STATIONS:", devFlag)
	
	local cureStations = Workspace:FindFirstChild("CureStations")
	if cureStations then
		print("  - CureStations folder found with", #cureStations:GetChildren(), "stations")
		print("  ✓ PASS: CureStations setup completed")
	else
		if not isStudio or not devFlag then
			print("  ✓ PASS: No auto-created stations (as expected in production/disabled mode)")
		else
			print("  ⚠ WARNING: No CureStations found despite being in Studio with flag enabled")
		end
	end
else
	print("  ✗ FAIL: Cannot load GameConfig")
end

--------------------------------------------------------------------------------
-- Test D: Asset Validation Module
--------------------------------------------------------------------------------
print("\n[Test D] Checking Asset Validation Module...")
if SharedFolder then
	local AssetValidation = require(SharedFolder:WaitForChild("AssetValidation", 5))
	if AssetValidation then
		print("  ✓ PASS: AssetValidation module loaded successfully")
		
		-- Test with sample invalid assets
		local testAssets = {
			ValidSound = "rbxassetid://123456789",
			InvalidSound = "rbxassetid://0",
			EmptySound = "",
		}
		
		print("  - Running validation test on sample assets...")
		local invalidKeys = AssetValidation.validateSoundAssets(testAssets, "TestAssets")
		print("  - Found", #invalidKeys, "invalid asset(s) (expected: 2)")
		
		if #invalidKeys == 2 then
			print("  ✓ PASS: Asset validation working correctly")
		else
			print("  ⚠ WARNING: Asset validation found unexpected number of invalid assets")
		end
	else
		print("  ✗ FAIL: AssetValidation module not found")
	end
else
	print("  ✗ FAIL: Cannot access Shared folder")
end

--------------------------------------------------------------------------------
-- Test E: ModalManager Improvements
--------------------------------------------------------------------------------
print("\n[Test E] Checking ModalManager...")
if SharedFolder then
	local ModalManager = require(SharedFolder:WaitForChild("ModalManager", 5))
	if ModalManager then
		print("  ✓ PASS: ModalManager module loaded")
		
		-- Test isActive method
		if type(ModalManager.isActive) == "function" then
			print("  ✓ PASS: ModalManager.isActive() method exists")
		else
			print("  ✗ FAIL: ModalManager.isActive() method not found")
		end
		
		-- Test remove returns boolean
		local removeResult = ModalManager.remove("NonExistentModal")
		if type(removeResult) == "boolean" then
			print("  ✓ PASS: ModalManager.remove() returns boolean")
		else
			print("  ✗ FAIL: ModalManager.remove() does not return boolean")
		end
	else
		print("  ✗ FAIL: ModalManager module not found")
	end
else
	print("  ✗ FAIL: Cannot access Shared folder")
end

--------------------------------------------------------------------------------
-- Test G: InputActionRegistry Conflict Detection
--------------------------------------------------------------------------------
print("\n[Test G] Checking InputActionRegistry...")
if SharedFolder then
	local InputActionRegistry = require(SharedFolder:WaitForChild("InputActionRegistry", 5))
	if InputActionRegistry then
		print("  ✓ PASS: InputActionRegistry module loaded")
		
		-- Check for enable/disable methods
		if type(InputActionRegistry.enable) == "function" and
		   type(InputActionRegistry.disable) == "function" and
		   type(InputActionRegistry.enableOwner) == "function" and
		   type(InputActionRegistry.disableOwner) == "function" then
			print("  ✓ PASS: All enable/disable methods exist")
		else
			print("  ✗ FAIL: Missing enable/disable methods")
		end
		
		-- Note: Actual conflict detection test would require UI initialization
		print("  ℹ INFO: Run InputActionRegistry.audit() after UI loads to check for conflicts")
	else
		print("  ✗ FAIL: InputActionRegistry module not found")
	end
else
	print("  ✗ FAIL: Cannot access Shared folder")
end

print("\n=== Boot Stabilization Validation Complete ===")
print("NOTE: Some tests may show warnings if systems haven't fully initialized yet.")
print("Run this script after entering lobby or starting a round for complete validation.")
