-- @ScriptType: Script
-- MainServer.server.lua
-- Compatibility shim for legacy test/tool compatibility
-- NOTE: This is a compatibility marker for tests expecting "MainServer" to exist.
-- The actual server initialization happens in Main.server.lua (modern entry point)
-- which runs automatically as a server script.

-- Guard against duplicate execution
if script:GetAttribute("Initialized") then
	warn("[MainServer.server] Already initialized, skipping duplicate execution")
	return
end
script:SetAttribute("Initialized", true)

print("[MainServer.server] Legacy compatibility marker - actual boot logic in Main.server.lua")

-- Verify the modern entry point exists
local Main = script.Parent:FindFirstChild("Main")
if not Main then
	error("[MainServer.server] CRITICAL: Main.server.lua not found in ServerScriptService")
end

-- The Main.server.lua script runs automatically as a server script
-- This shim exists solely to satisfy tests checking for "MainServer" existence
print("[MainServer.server] Modern entry point verified: Main.server.lua exists")
