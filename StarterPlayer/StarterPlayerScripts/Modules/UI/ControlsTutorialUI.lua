-- ControlsTutorialUI.lua
-- Tutorial screen shown before a player's first round to explain controls
-- Adapts display based on device type (keyboard/mouse, touch, gamepad)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local InputManager = require(SharedFolder:WaitForChild("InputManager"))

local ControlsTutorialUI = {}

-- State
local screenGui = nil
local tutorialActive = false

-- Check if player has seen tutorial (stored in player attribute)
local function hasSeenTutorial()
	-- Check if the player has a flag set
	local hasSeen = player:GetAttribute("HasSeenControlsTutorial")
	return hasSeen == true
end

-- Mark tutorial as seen
local function markTutorialSeen()
	player:SetAttribute("HasSeenControlsTutorial", true)
end

-- Get control info based on device type
local function getControlInfo()
	local deviceType = InputManager.getActiveDevice()
	
	if deviceType == InputManager.DeviceType.TOUCH then
		return {
			title = "TOUCH CONTROLS",
			controls = {
				{icon = "🕹️", name = "Movement", desc = "Use left joystick to move"},
				{icon = "🏃", name = "Sprint", desc = "Press Sprint button above joystick"},
				{icon = "🔫", name = "Fire", desc = "Tap Fire button (bottom right)"},
				{icon = "🎯", name = "Aim", desc = "Hold Aim button to zoom"},
				{icon = "⬆️", name = "Jump", desc = "Tap Jump button"},
				{icon = "⬇️", name = "Crouch", desc = "Tap Crouch button"},
				{icon = "🔄", name = "Reload", desc = "Tap R button to reload weapon"},
			},
			tips = {
				"Swipe anywhere on screen to look around",
				"Touch controls appear automatically",
				"Collect cure components to win!"
			}
		}
	elseif deviceType == InputManager.DeviceType.GAMEPAD then
		return {
			title = "GAMEPAD CONTROLS",
			controls = {
				{icon = "🕹️", name = "Movement", desc = "Left Stick"},
				{icon = "👀", name = "Look", desc = "Right Stick"},
				{icon = "🏃", name = "Sprint", desc = "Click Left Stick (L3)"},
				{icon = "🔫", name = "Fire", desc = "Right Trigger (R2)"},
				{icon = "🎯", name = "Aim", desc = "Left Trigger (L2)"},
				{icon = "⬆️", name = "Jump", desc = "A Button"},
				{icon = "⬇️", name = "Crouch", desc = "B Button"},
				{icon = "🔄", name = "Reload", desc = "X Button"},
			},
			tips = {
				"Use bumpers (L1/R1) to switch weapons",
				"Start button opens menu",
				"Work together to survive waves!"
			}
		}
	else -- Keyboard & Mouse
		return {
			title = "KEYBOARD & MOUSE CONTROLS",
			controls = {
				{icon = "⌨️", name = "Movement", desc = "W/A/S/D keys"},
				{icon = "🖱️", name = "Look", desc = "Move mouse"},
				{icon = "🏃", name = "Sprint", desc = "Hold Left Shift"},
				{icon = "🔫", name = "Fire", desc = "Left Mouse Button"},
				{icon = "🎯", name = "Aim", desc = "Left Alt"},
				{icon = "⬆️", name = "Jump", desc = "Space Bar"},
				{icon = "⬇️", name = "Crouch", desc = "Left Ctrl or C"},
				{icon = "🔄", name = "Reload", desc = "R key"},
			},
			tips = {
				"Number keys (1-4) switch weapons",
				"Tab shows scoreboard",
				"Survive waves and craft the cure!"
			}
		}
	end
end

-- Create the tutorial UI
local function createTutorialUI()
	-- Remove existing UI if present
	local existing = playerGui:FindFirstChild("ControlsTutorialUI")
	if existing then
		existing:Destroy()
	end
	
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ControlsTutorialUI"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 1000 -- Very high to be on top
	screenGui.Enabled = false
	screenGui.Parent = playerGui
	
	-- Dark overlay background
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.3
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui
	
	-- Main content frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 700, 0, 550)
	mainFrame.Position = UDim2.new(0.5, -350, 0.5, -275)
	mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = overlay
	
	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 16)
	mainCorner.Parent = mainFrame
	
	local mainStroke = Instance.new("UIStroke")
	mainStroke.Thickness = 3
	mainStroke.Color = Color3.fromRGB(100, 150, 255)
	mainStroke.Parent = mainFrame
	
	-- Get control info for current device
	local controlInfo = getControlInfo()
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 0, 50)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = controlInfo.title
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 32
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame
	
	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, -40, 0, 30)
	subtitle.Position = UDim2.new(0, 20, 0, 70)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Master these controls to survive!"
	subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	subtitle.TextSize = 18
	subtitle.Font = Enum.Font.Gotham
	subtitle.Parent = mainFrame
	
	-- Scrolling frame for controls
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ControlsList"
	scrollFrame.Size = UDim2.new(1, -40, 0, 300)
	scrollFrame.Position = UDim2.new(0, 20, 0, 110)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.Parent = mainFrame
	
	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 8)
	scrollCorner.Parent = scrollFrame
	
	-- List layout for controls
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 8)
	listLayout.Parent = scrollFrame
	
	-- Add each control
	for i, control in ipairs(controlInfo.controls) do
		local controlFrame = Instance.new("Frame")
		controlFrame.Name = "Control" .. i
		controlFrame.Size = UDim2.new(1, -10, 0, 50)
		controlFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
		controlFrame.BorderSizePixel = 0
		controlFrame.LayoutOrder = i
		controlFrame.Parent = scrollFrame
		
		local controlCorner = Instance.new("UICorner")
		controlCorner.CornerRadius = UDim.new(0, 6)
		controlCorner.Parent = controlFrame
		
		-- Icon
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "Icon"
		iconLabel.Size = UDim2.new(0, 50, 1, 0)
		iconLabel.Position = UDim2.new(0, 0, 0, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = control.icon
		iconLabel.TextSize = 28
		iconLabel.Font = Enum.Font.GothamBold
		iconLabel.Parent = controlFrame
		
		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Size = UDim2.new(0, 150, 0, 24)
		nameLabel.Position = UDim2.new(0, 55, 0, 5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = control.name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 18
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = controlFrame
		
		-- Description
		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "Description"
		descLabel.Size = UDim2.new(1, -210, 0, 20)
		descLabel.Position = UDim2.new(0, 55, 0, 25)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = control.desc
		descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		descLabel.TextSize = 14
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextWrapped = true
		descLabel.Parent = controlFrame
	end
	
	-- Update canvas size
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	
	-- Tips section
	local tipsLabel = Instance.new("TextLabel")
	tipsLabel.Name = "TipsTitle"
	tipsLabel.Size = UDim2.new(1, -40, 0, 25)
	tipsLabel.Position = UDim2.new(0, 20, 0, 420)
	tipsLabel.BackgroundTransparency = 1
	tipsLabel.Text = "💡 TIPS"
	tipsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	tipsLabel.TextSize = 20
	tipsLabel.Font = Enum.Font.GothamBold
	tipsLabel.TextXAlignment = Enum.TextXAlignment.Left
	tipsLabel.Parent = mainFrame
	
	local tipsText = ""
	for i, tip in ipairs(controlInfo.tips) do
		tipsText = tipsText .. "• " .. tip
		if i < #controlInfo.tips then
			tipsText = tipsText .. "\n"
		end
	end
	
	local tipsContent = Instance.new("TextLabel")
	tipsContent.Name = "TipsContent"
	tipsContent.Size = UDim2.new(1, -40, 0, 60)
	tipsContent.Position = UDim2.new(0, 20, 0, 450)
	tipsContent.BackgroundTransparency = 1
	tipsContent.Text = tipsText
	tipsContent.TextColor3 = Color3.fromRGB(200, 200, 200)
	tipsContent.TextSize = 14
	tipsContent.Font = Enum.Font.Gotham
	tipsContent.TextXAlignment = Enum.TextXAlignment.Left
	tipsContent.TextYAlignment = Enum.TextYAlignment.Top
	tipsContent.TextWrapped = true
	tipsContent.Parent = mainFrame
	
	-- Got It button
	local gotItButton = Instance.new("TextButton")
	gotItButton.Name = "GotItButton"
	gotItButton.Size = UDim2.new(0, 200, 0, 50)
	gotItButton.Position = UDim2.new(0.5, -100, 1, -70)
	gotItButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	gotItButton.Text = "GOT IT!"
	gotItButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	gotItButton.TextSize = 24
	gotItButton.Font = Enum.Font.GothamBold
	gotItButton.Parent = mainFrame
	
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 12)
	buttonCorner.Parent = gotItButton
	
	-- Button click effect
	gotItButton.MouseButton1Click:Connect(function()
		ControlsTutorialUI.hide()
	end)
	
	-- Hover effect
	gotItButton.MouseEnter:Connect(function()
		TweenService:Create(gotItButton, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(60, 180, 60)
		}):Play()
	end)
	
	gotItButton.MouseLeave:Connect(function()
		TweenService:Create(gotItButton, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		}):Play()
	end)
	
	return screenGui
end

-- Show the tutorial
function ControlsTutorialUI.show()
	if tutorialActive then return end
	if hasSeenTutorial() then return end
	
	print("[ControlsTutorialUI] Showing tutorial for first-time player")
	
	if not screenGui then
		createTutorialUI()
	end
	
	tutorialActive = true
	screenGui.Enabled = true
	
	-- Animate in
	local mainFrame = screenGui:FindFirstChild("Overlay"):FindFirstChild("MainFrame")
	if mainFrame then
		mainFrame.Size = UDim2.new(0, 0, 0, 0)
		mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 700, 0, 550),
			Position = UDim2.new(0.5, -350, 0.5, -275)
		}):Play()
	end
end

-- Hide the tutorial
function ControlsTutorialUI.hide()
	if not tutorialActive then return end
	
	print("[ControlsTutorialUI] Hiding tutorial")
	
	tutorialActive = false
	markTutorialSeen()
	
	if screenGui then
		local mainFrame = screenGui:FindFirstChild("Overlay"):FindFirstChild("MainFrame")
		if mainFrame then
			local tween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Size = UDim2.new(0, 0, 0, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0)
			})
			tween.Completed:Connect(function()
				screenGui.Enabled = false
			end)
			tween:Play()
		else
			screenGui.Enabled = false
		end
	end
end

-- Check if should show (called from game flow)
function ControlsTutorialUI.shouldShow()
	return not hasSeenTutorial() and not tutorialActive
end

-- Initialize
function ControlsTutorialUI.initialize()
	-- InputManager.initialize() is already idempotent but check explicitly for clarity
	if not InputManager.getActiveDevice() then
		InputManager.initialize()
	end
	createTutorialUI()
	
	-- Listen for first wave to show tutorial
	task.spawn(function()
		local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
		if remoteEvents then
			local waveAnnounceEvent = remoteEvents:WaitForChild("WaveAnnounce", 10)
			if waveAnnounceEvent then
				waveAnnounceEvent.OnClientEvent:Connect(function(waveNum)
					-- Show tutorial before wave 1 for first-time players
					if waveNum == 1 and ControlsTutorialUI.shouldShow() then
						task.wait(0.5) -- Small delay for loading
						ControlsTutorialUI.show()
					end
				end)
			else
				warn("[ControlsTutorialUI] Failed to find RemoteEvents.WaveAnnounce within 10 seconds; controls tutorial will not auto-show.")
			end
		else
			warn("[ControlsTutorialUI] Failed to find ReplicatedStorage.RemoteEvents within 10 seconds; controls tutorial will not auto-show.")
		end
	end)
	
	print("[ControlsTutorialUI] Initialized")
end

return ControlsTutorialUI
