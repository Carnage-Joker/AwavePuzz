-- @ScriptType: LocalScript
-- ClientMain.client.lua
-- Thin loader for ClientMainModule - prevents RunContext warning
-- ✅ FIX: Converted main client code to ModuleScript (ClientMainModule)

local ClientMainModule = require(script.Parent:WaitForChild("ClientMainModule"))
ClientMainModule.initialize()
