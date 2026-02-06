-- @ScriptType: LocalScript
-- Boot.client.lua
-- SINGLE CLIENT ENTRY POINT
-- This is the ONLY LocalScript that should run in StarterPlayerScripts
-- All logic delegated to BootModule to prevent RunContext duplication issues

-- Ultra-simple guard - if this fires, there's a duplicate LocalScript somewhere
if _G.__AwavePuzzBootClientStarted then
	warn("[BOOT][CLIENT] CRITICAL: Duplicate Boot.client.lua execution detected!")
	warn("[BOOT][CLIENT] Check for multiple LocalScripts in StarterPlayerScripts")
	return
end
_G.__AwavePuzzBootClientStarted = true

print("=== [BOOT][CLIENT] Entry point - Delegating to BootModule ===")

-- Delegate all logic to BootModule (ModuleScript pattern eliminates RunContext issues)
local BootModule = require(script.Parent:WaitForChild("BootModule"))
BootModule.run()

print("=== [BOOT][CLIENT] BootModule execution complete ===")

