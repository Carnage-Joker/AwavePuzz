-- verify_methods.lua
-- Quick verification script to check if all required methods exist
-- This simulates what the tests are checking for

local function checkModule(modulePath, moduleName, requiredMethods)
	print(string.format("\n=== Checking %s ===", moduleName))
	
	local success, module = pcall(function()
		return require(modulePath)
	end)
	
	if not success then
		print(string.format("❌ FAILED to load %s: %s", moduleName, tostring(module)))
		return false
	end
	
	print(string.format("✓ Loaded %s successfully", moduleName))
	
	local allMethodsExist = true
	for _, methodName in ipairs(requiredMethods) do
		if module[methodName] ~= nil then
			print(string.format("  ✓ Method exists: %s", methodName))
		else
			print(string.format("  ❌ MISSING: %s", methodName))
			allMethodsExist = false
		end
	end
	
	return allMethodsExist
end

-- Check AllianceGraph
local allianceGraphPath = game:GetService("ServerScriptService"):WaitForChild("Alliance"):WaitForChild("AllianceGraph")
local allianceGraphPassed = checkModule(allianceGraphPath, "AllianceGraph", {
	"new",
	"addAlliance",
	"removeAlliance",
	"getAllies",
	"isAllied"
})

-- Check AllianceServiceV2
local allianceServicePath = game:GetService("ServerScriptService"):WaitForChild("AllianceServiceV2")
local allianceServicePassed = checkModule(allianceServicePath, "AllianceServiceV2", {
	"new",
	"proposeAlliance",
	"acceptAlliance",
	"denyAlliance",
	"breakAlliance",
	"getAlliance",
	"setPuzzleService"
})

-- Check BetrayalService
local betrayalServicePath = game:GetService("ServerScriptService"):WaitForChild("Alliance"):WaitForChild("BetrayalService")
local betrayalServicePassed = checkModule(betrayalServicePath, "BetrayalService", {
	"new",
	"initialize"
})

-- Check InventoryLedger
local inventoryLedgerPath = game:GetService("ServerScriptService"):WaitForChild("Alliance"):WaitForChild("InventoryLedger")
local inventoryLedgerPassed = checkModule(inventoryLedgerPath, "InventoryLedger", {
	"new",
	"addItem",
	"removeItem",
	"getInventory",
	"transferInventory"
})

-- Check PoolCalculator
local poolCalculatorPath = game:GetService("ServerScriptService"):WaitForChild("Alliance"):WaitForChild("PoolCalculator")
local poolCalculatorPassed = checkModule(poolCalculatorPath, "PoolCalculator", {
	"calculatePooledCurrency"
})

-- Summary
print("\n" .. string.rep("=", 50))
print("VERIFICATION SUMMARY")
print(string.rep("=", 50))
print(string.format("AllianceGraph:     %s", allianceGraphPassed and "✓ PASS" or "❌ FAIL"))
print(string.format("AllianceServiceV2: %s", allianceServicePassed and "✓ PASS" or "❌ FAIL"))
print(string.format("BetrayalService:   %s", betrayalServicePassed and "✓ PASS" or "❌ FAIL"))
print(string.format("InventoryLedger:   %s", inventoryLedgerPassed and "✓ PASS" or "❌ FAIL"))
print(string.format("PoolCalculator:    %s", poolCalculatorPassed and "✓ PASS" or "❌ FAIL"))
print(string.rep("=", 50))

local allPassed = allianceGraphPassed and allianceServicePassed and betrayalServicePassed 
	and inventoryLedgerPassed and poolCalculatorPassed

if allPassed then
	print("\n✓ ALL CHECKS PASSED - AllianceSystemTests should now pass!")
else
	print("\n❌ SOME CHECKS FAILED - Review the output above")
end

return allPassed
