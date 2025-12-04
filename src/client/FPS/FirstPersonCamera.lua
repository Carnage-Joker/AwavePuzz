-- FirstPersonCamera.lua
-- Handles scriptable first-person camera with configurable FOV, sensitivity, and smoothing.
-- This module is purely client-side and does not alter character movement physics.

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local FirstPersonCamera = {}
FirstPersonCamera.__index = FirstPersonCamera

function FirstPersonCamera.new(config)
        local self = setmetatable({}, FirstPersonCamera)
        self.config = config
        self.yaw = 0
        self.pitch = 0
        self._pendingDelta = Vector2.new(0, 0)
        self._connections = {}
        self._character = nil
        self._head = nil
        self._running = false
        return self
end

local function clamp(value, min, max)
        return math.max(min, math.min(max, value))
end

local function setCharacterTransparency(character, visible)
        for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                        part.LocalTransparencyModifier = visible and 0 or 1
                end
        end
end

function FirstPersonCamera:_bindInput()
        self._connections[#self._connections + 1] = UserInputService.InputChanged:Connect(function(input, processed)
                if processed then
                        return
                end
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                        self._pendingDelta += Vector2.new(input.Delta.x, input.Delta.y)
                end
        end)
end

function FirstPersonCamera:_bindCharacter(character)
        self._character = character
        self._head = character:WaitForChild("Head", 5)

        if self.config.HideCharacterInFirstPerson then
                        setCharacterTransparency(character, false)
        end

        -- Restore visibility when character is removed (e.g., player dies)
        self._connections[#self._connections + 1] = character.AncestryChanged:Connect(function(_, parent)
                if not parent and self.config.HideCharacterInFirstPerson then
                        setCharacterTransparency(character, true)
                end
        end)

        local hrp = character:WaitForChild("HumanoidRootPart", 5)
        if hrp then
                local lookVector = hrp.CFrame.LookVector
                self.yaw = math.deg(math.atan2(-lookVector.X, -lookVector.Z))
        end
end

function FirstPersonCamera:_update(dt)
        if not self._head or not self._head:IsDescendantOf(workspace) then
                return
        end

        camera.CameraType = Enum.CameraType.Scriptable

        local smooth = self.config.MouseSmoothing or 0
        local sensitivity = self.config.MouseSensitivity or 0.1

        local delta = self._pendingDelta
        self._pendingDelta = Vector2.new(0, 0)

        if smooth > 0 then
                delta = delta * (1 - clamp(smooth, 0, 1))
        end

        self.yaw -= delta.X * sensitivity
        self.pitch -= delta.Y * sensitivity

        local clampAngle = self.config.PitchClamp or 80
        self.pitch = clamp(self.pitch, -clampAngle, clampAngle)

        local headPosition = self._head.Position + (self.config.HeadOffset or Vector3.new())
        local rotation = CFrame.fromEulerAnglesYXZ(math.rad(self.pitch), math.rad(self.yaw), 0)
        local offset = self.config.CameraOffset or Vector3.new()
        local targetCFrame = CFrame.new(headPosition) * rotation * CFrame.new(offset)

        camera.CFrame = targetCFrame
        camera.FieldOfView = clamp(self.config.DefaultFOV or 90, self.config.MinFOV or 70, self.config.MaxFOV or 110)
end

function FirstPersonCamera:start(character)
        if self._running then
                self:stop()
        end

        self:_bindCharacter(character)
        if not self._head then
                warn("[FirstPersonCamera] Character missing head; cannot enable first person")
                return
        end

        self._running = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false

        self:_bindInput()
        self._connections[#self._connections + 1] = RunService.RenderStepped:Connect(function(dt)
                self:_update(dt)
        end)
end

function FirstPersonCamera:stop()
        for _, conn in ipairs(self._connections) do
                conn:Disconnect()
        end
        table.clear(self._connections)
        self._running = false

        -- Restore character visibility before clearing references
        if self._character and self.config.HideCharacterInFirstPerson then
                setCharacterTransparency(self._character, true)
        end

        self._character = nil
        self._head = nil

        camera.CameraType = Enum.CameraType.Custom
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
end

return FirstPersonCamera
