-- @ScriptType: LocalScript
-- @RunContext: Legacy
-- Boot.client.lua
-- FIRST LOAD CLIENT ENTRY POINT
-- Ensures Title Screen appears before ANY map, lobby, or character is visible
-- Implements deterministic boot order: UI → Camera → Server Ready → Spawn
-- NOTE: RunContext=Legacy prevents duplicate execution warnings in Studio

-- Guard against duplicate execution (singleton across all Boot.client.lua instances)
if shared.__AwavePuzzBootClientInitialized then
	warn("[BOOT][CLIENT] Already initialized, skipping duplicate execution")
	return
end
shared.__AwavePuzzBootClientInitialized = true
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
camera.CFrame = CFrame.new(Vector3.new(0, 100000, 0)) -- Far above world to avoid any map/skybox content

-- Disable default Roblox UI during boot
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
end)

print("[BOOT][CLIENT] Phase 1 complete: Camera controlled, screen black")

----------------------------------------------------------------
-- PHASE 0.5: CREATE TITLE SCREEN IMMEDIATELY
----------------------------------------------------------------

print("[BOOT][CLIENT] Phase 0.5: Creating TitleScreenUI immediately...")

-- Load TitleScreenUI module and create instance BEFORE other systems
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local clientModules = script.Parent:WaitForChild("Modules", 10)
local uiFolder = clientModules and clientModules:FindFirstChild("UI")
local titleScreenModule = uiFolder and uiFolder:FindFirstChild("TitleScreenUI")

local titleScreenInstance = nil

if titleScreenModule then
	local success, TitleScreenClass = pcall(function()
		return require(titleScreenModule)
	end)
	if success and TitleScreenClass then
		-- TitleScreenUI.new() creates the UI and sets DisplayOrder=200
		titleScreenInstance = TitleScreenClass.new()
		-- Store globally so ClientMainModule can bind remotes later
		shared.__AwavePuzzTitleScreenInstance = titleScreenInstance
		print("[BOOT][CLIENT] ✓ TitleScreenUI created immediately with DisplayOrder=200")
		print("[BOOT][CLIENT] ✓ Title screen ready (remotes will be bound later)")
	else
		warn("[BOOT][CLIENT] ✗ Failed to load TitleScreenUI:", TitleScreenClass)
	end
else
	warn("[BOOT][CLIENT] ✗ TitleScreenUI module not found")
end

print("[BOOT][CLIENT] Phase 0.5 complete: TitleScreenUI created")

----------------------------------------------------------------
-- PHASE 2: DELEGATE TO CLIENT MAIN MODULE
----------------------------------------------------------------

print("[BOOT][CLIENT] Phase 2: Loading ClientMainModule...")

-- Load ClientMainModule to initialize all systems
-- ClientMainModule will handle:
-- - Title Screen display
-- - Initializing all game systems
-- - Restoring camera control
local ClientMainModule = require(script.Parent:WaitForChild("ClientMainModule"))
ClientMainModule.initialize()

print("[BOOT][CLIENT] Phase 2 complete: ClientMainModule initialized")

----------------------------------------------------------------
-- BOOT COMPLETE
----------------------------------------------------------------

print("=== [BOOT][CLIENT] Boot.client.lua initialization complete ===")

