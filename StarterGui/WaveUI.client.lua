--[[
    WaveUI
    Displays the current wave, zombies remaining, time left, and base health.
    Relies on the WaveUpdate RemoteEvent for server-authoritative data.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WaveStatusGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local container = Instance.new("Frame")
container.Size = UDim2.new(0, 260, 0, 130)
container.Position = UDim2.new(0, 20, 0, 20)
container.BackgroundTransparency = 0.3
container.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
container.BorderSizePixel = 0
container.Parent = screenGui

local function createLabel(text, order, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 24)
    label.Position = UDim2.new(0, 10, 0, 10 + (order * 30))
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.Font = Enum.Font.Gotham
    label.TextScaled = true
    label.Text = text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    return label
end

local title = createLabel("Wave 0", 0, Color3.fromRGB(255, 255, 255))
local zombiesLabel = createLabel("Zombies: 0", 1, Color3.fromRGB(200, 255, 200))
local timerLabel = createLabel("Time: 0", 2, Color3.fromRGB(255, 220, 150))
local baseLabel = createLabel("Base HP: 0", 3, Color3.fromRGB(255, 120, 120))

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local waveUpdate = remoteFolder:WaitForChild("WaveUpdate")
local waveAnnounce = remoteFolder:WaitForChild("WaveAnnounce")

local function updateUI(data)
    if data.wave then
        title.Text = string.format("Wave %d", data.wave)
    end
    if data.zombiesAlive then
        zombiesLabel.Text = string.format("Zombies: %d", data.zombiesAlive)
    end
    if data.timeLeft then
        timerLabel.Text = string.format("Time: %d", data.timeLeft)
    end
    if data.baseHealth then
        baseLabel.Text = string.format("Base HP: %d", data.baseHealth)
    end
end

waveUpdate.OnClientEvent:Connect(updateUI)
waveAnnounce.OnClientEvent:Connect(function(payload)
    if payload and payload.message then
        timerLabel.Text = payload.message
    end
end)
