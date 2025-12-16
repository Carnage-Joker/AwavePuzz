-- SpectatorUI.client.lua
-- Client-side spectator UI + camera control
-- Works with keyboard, gamepad, and mobile buttons

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

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

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "SpectatorUI"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

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
	local hum = targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")

	-- Use Scriptable camera for third-person spectating
	-- This gives better control over camera positioning
	camera.CameraType = Enum.CameraType.Scriptable
	
	-- If target has humanoid, set as subject for tracking but camera stays scriptable
	if hum then
		camera.CameraSubject = hum
	end

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
	
	-- Position camera behind and above the target for third-person view
	local cameraOffset = Vector3.new(0, 4, 8) -- 4 studs up, 8 studs back
	local desiredPos = targetPos - (targetLook * cameraOffset.Z) + Vector3.new(0, cameraOffset.Y, 0)
	
	-- Look at target
	local cf = CFrame.new(desiredPos, targetPos)
	camera.CFrame = camera.CFrame:Lerp(cf, 0.15)
end)

-- Client -> server cycle
local function requestCycle(dir)
	if not isSpectating then return end
	SpectatorCycleTarget:FireServer(dir)
end

prevBtn.MouseButton1Click:Connect(function()
	requestCycle("prev")
end)

nextBtn.MouseButton1Click:Connect(function()
	requestCycle("next")
end)

-- Keyboard/gamepad
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not isSpectating then return end

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
EnterSpectatorMode.OnClientEvent:Connect(function(payload)
	isSpectating = true
	gui.Enabled = true

	aliveList = {}
	aliveCount = 0

	setCameraToTarget(payload and payload.targetUserId or nil)
end)

ExitSpectatorMode.OnClientEvent:Connect(function()
	isSpectating = false
	gui.Enabled = false
	targetUserId = nil

	-- Restore camera to local player
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	camera.CameraType = Enum.CameraType.Custom
	if hum then
		camera.CameraSubject = hum
	end
end)

SpectatorTargetUpdate.OnClientEvent:Connect(function(payload)
	if not isSpectating then return end
	setCameraToTarget(payload and payload.targetUserId or nil)
end)

SpectatorStateUpdate.OnClientEvent:Connect(function(payload)
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
