-- @ScriptType: LocalScript
-- Boot.client.lua
-- FIRST LOAD CLIENT ENTRY POINT
-- Ensures Title Screen appears before ANY map, lobby, or character is visible
-- Implements deterministic boot order: UI → Camera → Server Ready → Spawn

-- Guard against duplicate execution
if script:GetAttribute("Initialized") then
	warn("[BOOT][CLIENT] Already initialized, skipping duplicate execution")
	return
end
script:SetAttribute("Initialized", true)

print("=== [BOOT][CLIENT] Boot.client.lua - First Load Entry Point ===")

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

----------------------------------------------------------------
-- PHASE 1: IMMEDIATE CAMERA CONTROL
----------------------------------------------------------------

print("[BOOT][CLIENT] Phase 1: Taking immediate camera control...")

-- Set camera to scriptable BEFORE anything else
camera.CameraType = Enum.CameraType.Scriptable

-- Position camera in a neutral/safe position (black void)
-- This prevents any flash of the default spawn or lobby
camera.CFrame = CFrame.new(Vector3.new(0, 10000, 0)) -- High above world

-- Disable default Roblox UI during boot
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
end)

print("[BOOT][CLIENT] Phase 1 complete: Camera controlled, screen black")

----------------------------------------------------------------
-- PHASE 2: DELEGATE TO CLIENT MAIN MODULE
----------------------------------------------------------------

print("[BOOT][CLIENT] Phase 2: Loading ClientMainModule...")

-- Load ClientMainModule to initialize all systems
-- ClientMainModule will handle:
-- - Title Screen display
-- - Waiting for server ready signal
-- - Initializing all game systems
-- - Restoring camera control
local ClientMainModule = require(script.Parent:WaitForChild("ClientMainModule"))
ClientMainModule.initialize()

print("[BOOT][CLIENT] Phase 2 complete: ClientMainModule initialized")

----------------------------------------------------------------
-- BOOT COMPLETE
----------------------------------------------------------------

print("=== [BOOT][CLIENT] Boot.client.lua initialization complete ===")

