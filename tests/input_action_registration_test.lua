-- input_action_registration_test.lua
-- Test script to verify Phase 3 input action registrations
-- Run this in a Roblox Studio test environment to verify all actions are properly registered

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)

if not SharedFolder then
	error("[Test] Failed to load Shared folder")
end

local InputActionRegistry = require(SharedFolder:WaitForChild("InputActionRegistry", 5))

print("==============================================")
print("=== INPUT ACTION REGISTRATION TEST ===")
print("==============================================")

-- Expected actions from Phase 3
local expectedActions = {
	-- Weapon switching (FPSWeaponController)
	"WeaponSwitch",
	"WeaponSwitchGamepad",
	"NextWeapon",
	"NextWeaponGamepad",
	"PrevWeapon",
	"PrevWeaponGamepad",
	
	-- Interact (TouchControlsUI)
	"Interact",
	"InteractGamepad",
	
	-- Pause menu (FPSMenuController)
	"PauseMenu",
	"PauseMenuGamepad",
	
	-- Inventory UI
	"InventoryToggle",
	"InventoryToggleGamepad",
	
	-- Map display
	"MapToggle",
	"MapToggleGamepad",
}

print("\n--- Phase 3 Action Registration Check ---")
local registeredCount = 0
local missingActions = {}

for _, actionName in ipairs(expectedActions) do
	local actionInfo = InputActionRegistry.getAction(actionName)
	if actionInfo then
		registeredCount = registeredCount + 1
		
		-- Get key names
		local keyNames = {}
		for _, key in ipairs(actionInfo.keys) do
			local keyName = tostring(key):match("%.(.+)$") or tostring(key)
			table.insert(keyNames, keyName)
		end
		
		print(string.format("✓ %s: %s (priority: %d, keys: %s)", 
			actionName, 
			actionInfo.owner, 
			actionInfo.priority,
			table.concat(keyNames, ", ")
		))
	else
		table.insert(missingActions, actionName)
		warn(string.format("✗ %s: NOT REGISTERED", actionName))
	end
end

print("\n--- Summary ---")
print(string.format("Registered: %d / %d", registeredCount, #expectedActions))

if #missingActions > 0 then
	warn(string.format("Missing actions: %s", table.concat(missingActions, ", ")))
	warn("⚠️ TEST FAILED: Some actions are not registered")
else
	print("✓ ALL PHASE 3 ACTIONS REGISTERED SUCCESSFULLY")
end

-- Run full audit to detect any conflicts
print("\n--- Running Full InputActionRegistry Audit ---")
InputActionRegistry.audit()

print("\n==============================================")
print("=== TEST COMPLETE ===")
print("==============================================")
