-- FirstPersonController.client.lua
-- Bootstrap script for the MODULAR first-person camera
--
-- NOTE: This bootstraps the FPS/FirstPersonCamera.lua module.
-- This is an ALTERNATIVE to the standalone FirstPersonCamera.client.lua
--
-- See CODE_ARCHITECTURE.md for details on the dual camera setup.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local FPSConfig = require(SharedFolder:WaitForChild("FPSConfig"))
local FirstPersonCamera = require(script.Parent:WaitForChild("FirstPersonCamera"))

local controller = {}
controller.camera = FirstPersonCamera.new(FPSConfig)

local function bindCoreActions()
        -- Disable Roblox default mouse lock toggle and shift-lock behaviour
        player.DevEnableMouseLock = false
        ContextActionService:BindActionAtPriority(
                "DisableMouseLockToggle",
                function()
                        return Enum.ContextActionResult.Sink
                end,
                false,
                Enum.ContextActionPriority.High.Value,
                Enum.KeyCode.LeftShift
        )
end

local function onCharacterAdded(character)
        controller.camera:start(character)
end

local function onCharacterRemoving()
        controller.camera:stop()
end

local function initialize()
        bindCoreActions()
        player.CharacterAdded:Connect(onCharacterAdded)
        player.CharacterRemoving:Connect(onCharacterRemoving)

        if player.Character then
                onCharacterAdded(player.Character)
        end
end

initialize()
