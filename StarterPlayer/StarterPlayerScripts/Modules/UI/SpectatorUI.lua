-- SpectatorUI.client.lua
-- Client-side spectator UI + camera control
-- Works with keyboard, gamepad, and mobile buttons

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local ModalManager = require(SharedFolder:WaitForChild("ModalManager"))
local InputActionRegistry = require(SharedFolder:WaitForChild("InputActionRegistry"))
local UIDebugConfig = require(SharedFolder:WaitForChild("UIDebugConfig"))

-- Connection tracking for cleanup
local connections = {}

-- Camera configuration
local SPECTATOR_CAMERA_HEIGHT = 4 -- Studs above target
local SPECTATOR_CAMERA_DISTANCE = 8 -- Studs behind target
local CAMERA_LERP_ALPHA = 0.15 -- Camera smoothing factor

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local EnterSpectatorMode = remoteEvents:WaitForChild("EnterSpectatorMode")
local ExitSpectatorMode = remoteEvents:WaitForChild("ExitSpectatorMode")
local SpectatorTargetUpdate = remoteEvents:WaitForChild("SpectatorTargetUpdate")
local SpectatorCycleTarget = remoteEvents:WaitForChild("SpectatorCycleTarget")
local SpectatorStateUpdate = remoteEvents:WaitForChild("SpectatorStateUpdate")

local isSpectating = false
local targetUserId = nil
local aliveList = {}
local aliveCount = 0

-- Prevent duplicate UI instances
local playerGui = player:WaitForChild("PlayerGui")
local existing = playerGui:FindFirstChild("SpectatorUI")
if existing then
	UIDebugConfig.warnDuplicate("SpectatorUI")
	existing:Destroy()
end

UIDebugConfig.logUICreation("SpectatorUI", "Creating ScreenGui", "SpectatorUI.lua")

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "SpectatorUI"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(0.5, 0)
root.Position = UDim2.new(0.5, 0, 0, 18)
root.Size = UDim2.new(0, 520, 0, 70)
root.BackgroundTransparency = 0.25
root.BorderSizePixel = 0
root.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = root

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Transparency = 0.35
stroke.Parent = root

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 14, 0, 8)
title.Size = UDim2.new(1, -28, 0, 22)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "SPECTATING"
title.Parent = root

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(0, 14, 0, 30)
subtitle.Size = UDim2.new(1, -28, 0, 18)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 14
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextTransparency = 0.1
subtitle.Text = "Target: — | Alive: —"
subtitle.Parent = root

local function makeButton(name, text, xScale)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, xScale, 0.5, 0)
	btn.Size = UDim2.new(0, 92, 0, 40)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.Text = text
	btn.AutoButtonColor = true
	btn.Parent = root

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = btn

	return btn
end

local prevBtn = makeButton("Prev", "◀ Prev", -206)
local nextBtn = makeButton("Next", "Next ▶", -106)

local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.BackgroundTransparency = 1
hint.AnchorPoint = Vector2.new(1, 1)
hint.Position = UDim2.new(1, -10, 1, -6)
hint.Size = UDim2.new(0, 260, 0, 18)
hint.Font = Enum.Font.Gotham
hint.TextSize = 12
hint.TextXAlignment = Enum.TextXAlignment.Right
hint.TextTransparency = 0.3
hint.Text = "Q/E or A/D • DPad ◀/▶ • Buttons"
hint.Parent = root

-- Camera helpers
local function getPlayerByUserId(userId)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.UserId == userId then
			return p
		end
	end
	return nil
end

local function getFocusPartForPlayer(p)
	if not p or not p.Character then return nil end
	return p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Head")
end

local function setCameraToTarget(userId)
	targetUserId = userId

	if not isSpectating then
		return
	end

	if not userId then
		-- No target: leave camera in Scriptable but don't explode
		camera.CameraType = Enum.CameraType.Scriptable
		subtitle.Text = ("Target: — | Alive: %d"):format(aliveCount or 0)
		return
	end

	local targetPlayer = getPlayerByUserId(userId)

	-- Use Scriptable camera for third-person spectating
	-- This gives better control over camera positioning
	camera.CameraType = Enum.CameraType.Scriptable

	local targetName = targetPlayer and targetPlayer.Name or "—"
	subtitle.Text = ("Target: %s | Alive: %d"):format(targetName, aliveCount or 0)
end

-- Third-person camera follow for spectating
RunService.RenderStepped:Connect(function()
	if not isSpectating then return end
	if not targetUserId then return end
	if camera.CameraType ~= Enum.CameraType.Scriptable then return end

	local t = getPlayerByUserId(targetUserId)
	local part = getFocusPartForPlayer(t)
	if not part then return end

	-- Third-person camera positioning (behind and above the target)
	local targetPos = part.Position
	local targetLook = part.CFrame.LookVector
	
	-- Calculate camera offset behind the target
	local horizontalOffset = -targetLook * SPECTATOR_CAMERA_DISTANCE  -- Negative to position behind
	local verticalOffset = Vector3.new(0, SPECTATOR_CAMERA_HEIGHT, 0)
	
	-- Position camera behind and above the target for third-person view
	local desiredPos = targetPos + horizontalOffset + verticalOffset
	
	-- Look at target
	local cf = CFrame.new(desiredPos, targetPos)
	camera.CFrame = camera.CFrame:Lerp(cf, CAMERA_LERP_ALPHA)
end)

-- Client -> server cycle
local function requestCycle(dir)
	if not isSpectating then return end
	SpectatorCycleTarget:FireServer(dir)
end

connections.prevBtn = prevBtn.MouseButton1Click:Connect(function()
	requestCycle("prev")
end)

connections.nextBtn = nextBtn.MouseButton1Click:Connect(function()
	requestCycle("next")
end)

-- Keyboard/gamepad input with modal check
connections.inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not isSpectating then return end
	
	-- Check if spectator UI is allowed to receive input (PANEL priority allows other panels)
	-- We only block input if a higher priority modal (MODAL/FULLSCREEN) is active
	if ModalManager.shouldBlockGameplay() then
		return
	end

	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.A then
		requestCycle("prev")
	elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.D then
		requestCycle("next")
	elseif input.KeyCode == Enum.KeyCode.DPadLeft then
		requestCycle("prev")
	elseif input.KeyCode == Enum.KeyCode.DPadRight then
		requestCycle("next")
	end
end)

-- Server events
connections.enterSpectator = EnterSpectatorMode.OnClientEvent:Connect(function(payload)
	isSpectating = true
	gui.Enabled = true

	aliveList = {}
	aliveCount = 0

	setCameraToTarget(payload and payload.targetUserId or nil)
	
	-- Register with ModalManager at PANEL priority (allows other panels to overlay)
	ModalManager.push("SpectatorUI", function()
		-- Don't auto-close spectator mode from ESC - let server control it
		-- Just acknowledge modal presence for input blocking
	end, ModalManager.Priority.PANEL)
end)

connections.exitSpectator = ExitSpectatorMode.OnClientEvent:Connect(function()
	isSpectating = false
	gui.Enabled = false
	targetUserId = nil
	
	-- Remove from ModalManager
	ModalManager.remove("SpectatorUI")

	-- Restore camera to local player
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	camera.CameraType = Enum.CameraType.Custom
	if hum then
		camera.CameraSubject = hum
	end
end)

connections.targetUpdate = SpectatorTargetUpdate.OnClientEvent:Connect(function(payload)
	if not isSpectating then return end
	setCameraToTarget(payload and payload.targetUserId or nil)
end)

connections.stateUpdate = SpectatorStateUpdate.OnClientEvent:Connect(function(payload)
	if not payload then return end
	aliveList = payload.alivePlayers or {}
	aliveCount = payload.aliveCount or 0

	-- Keep subtitle current
	local targetName = "—"
	if targetUserId then
		local t = getPlayerByUserId(targetUserId)
		targetName = t and t.Name or "—"
	end
	subtitle.Text = ("Target: %s | Alive: %d"):format(targetName, aliveCount or 0)
end)

-- Register input actions with InputActionRegistry
InputActionRegistry.register("SpectatorPrev", "SpectatorUI", {Enum.KeyCode.Q, Enum.KeyCode.A}, InputActionRegistry.Priority.TOGGLE_UI)
InputActionRegistry.register("SpectatorNext", "SpectatorUI", {Enum.KeyCode.E, Enum.KeyCode.D}, InputActionRegistry.Priority.TOGGLE_UI)
InputActionRegistry.register("SpectatorPrevGamepad", "SpectatorUI", {Enum.KeyCode.DPadLeft}, InputActionRegistry.Priority.TOGGLE_UI)
InputActionRegistry.register("SpectatorNextGamepad", "SpectatorUI", {Enum.KeyCode.DPadRight}, InputActionRegistry.Priority.TOGGLE_UI)

-- Cleanup function
local function cleanup()
	for name, connection in pairs(connections) do
		if connection then
			connection:Disconnect()
		end
	end
	connections = {}
	
	-- Remove from ModalManager if still active
	if isSpectating then
		ModalManager.remove("SpectatorUI")
	end
end

-- Handle respawn - cleanup connections
connections.characterRemoving = player.CharacterRemoving:Connect(cleanup)

-- Return module table (required for ModuleScript compatibility)
local SpectatorUI = {}
SpectatorUI.cleanup = cleanup
return SpectatorUI
