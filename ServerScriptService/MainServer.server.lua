-- @ScriptType: Script
-- MainServer.server.lua
-- Compatibility shim for legacy test/tool compatibility
-- Delegates to the modern Main.server.lua entry point

-- Guard against duplicate execution
if script:GetAttribute("Initialized") then
	warn("[MainServer.server] Already initialized, skipping duplicate execution")
	return
end
script:SetAttribute("Initialized", true)

print("[MainServer.server] Legacy entry point detected - delegating to Main.server.lua")

-- Delegate to the modern entry point
local Main = script.Parent:FindFirstChild("Main")
if Main then
	require(Main)
else
	error("[MainServer.server] CRITICAL: Main.server.lua not found")
end
