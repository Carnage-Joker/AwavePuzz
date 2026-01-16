-- @ScriptType: LocalScript
-- PlayerHUD (LocalScript) - DROP-IN REPLACEMENT
-- Put this LocalScript in StarterGui named "PlayerHUD"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local existing = playerGui:FindFirstChild("PlayerHUDGui")
if existing then existing:Destroy() end
-- ScreenGui (ResetOnSpawn belongs here)
local gui = Instance.new("ScreenGui")
gui.Name = "PlayerHUDGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundTransparency = 1
root.Size = UDim2.fromScale(1, 1)
root.Parent = gui

-- Health container
local healthWrap = Instance.new("Frame")
healthWrap.Name = "HealthWrap"
healthWrap.AnchorPoint = Vector2.new(0, 1)
healthWrap.Position = UDim2.new(0, 20, 1, -20)
healthWrap.Size = UDim2.fromOffset(320, 64)
healthWrap.BorderSizePixel = 0
healthWrap.BackgroundTransparency = 0.3
healthWrap.Parent = root

local healthLabel = Instance.new("TextLabel")
healthLabel.Name = "HealthLabel"
healthLabel.BackgroundTransparency = 1
healthLabel.Position = UDim2.fromOffset(10, 6)
healthLabel.Size = UDim2.new(1, -20, 0, 20)
healthLabel.Font = Enum.Font.GothamBold
healthLabel.TextSize = 16
healthLabel.TextXAlignment = Enum.TextXAlignment.Left
healthLabel.Text = "Health"
healthLabel.Parent = healthWrap

local barBack = Instance.new("Frame")
barBack.Name = "BarBack"
barBack.Position = UDim2.fromOffset(10, 30)
barBack.Size = UDim2.new(1, -20, 0, 18)
barBack.BorderSizePixel = 0
barBack.BackgroundTransparency = 0.5
barBack.Parent = healthWrap

local barFill = Instance.new("Frame")
barFill.Name = "BarFill"
barFill.Size = UDim2.new(1, 0, 1, 0)
barFill.BorderSizePixel = 0
barFill.Parent = barBack

-- State text (optional)
local stateText = Instance.new("TextLabel")
stateText.Name = "StateText"
stateText.BackgroundTransparency = 1
stateText.AnchorPoint = Vector2.new(0.5, 0)
stateText.Position = UDim2.new(0.5, 0, 0, 18)
stateText.Size = UDim2.fromOffset(400, 28)
stateText.Font = Enum.Font.Gotham
stateText.TextSize = 18
stateText.Text = ""
stateText.Parent = root

local humanoid : Humanoid? = nil

local function updateHealth()
	if not humanoid then
		healthLabel.Text = "Health"
		barFill.Size = UDim2.new(1, 0, 1, 0)
		return
	end

	local hp = math.max(0, humanoid.Health)
	local maxHp = math.max(1, humanoid.MaxHealth)
	local pct = hp / maxHp

	healthLabel.Text = string.format("Health  %d / %d", math.floor(hp + 0.5), math.floor(maxHp + 0.5))
	barFill.Size = UDim2.new(pct, 0, 1, 0)
end

local function getAttr(name)
	local char = player.Character
	if char and char:GetAttribute(name) ~= nil then
		return char:GetAttribute(name)
	end
	if player:GetAttribute(name) ~= nil then
		return player:GetAttribute(name)
	end
	return nil
end

local function updateState()
	local s = getAttr("GameState") or getAttr("State") or ""
	stateText.Text = (s ~= "" and ("State: " .. tostring(s)) or "")
end

local function bindCharacter(char: Model)
	humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = char:WaitForChild("Humanoid", 5)
	end

	if humanoid then
		humanoid.HealthChanged:Connect(updateHealth)
		updateHealth()
	end

	char:GetAttributeChangedSignal("GameState"):Connect(updateState)
	char:GetAttributeChangedSignal("State"):Connect(updateState)
	updateState()
end

player.CharacterAdded:Connect(bindCharacter)
if player.Character then
	bindCharacter(player.Character)
end

player:GetAttributeChangedSignal("GameState"):Connect(updateState)
player:GetAttributeChangedSignal("State"):Connect(updateState)

RunService.RenderStepped:Connect(function()
	-- cheap, keeps bar correct even if MaxHealth changes or humanoid swaps
	updateHealth()
end)
