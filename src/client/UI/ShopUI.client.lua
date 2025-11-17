-- ShopUI.client.lua
-- Simple in-game shop interface for purchasing weapons and upgrades

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local shopRequest = remoteFolder:WaitForChild("ShopRequest")
local shopUpdate = remoteFolder:WaitForChild("ShopUpdate")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 320)
frame.Position = UDim2.new(0.5, -150, 0.5, -160)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -10, 0, 30)
title.Position = UDim2.new(0, 5, 0, 5)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "Camp Vendor"
title.Parent = frame

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -10, 1, -50)
list.Position = UDim2.new(0, 5, 0, 40)
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.ScrollBarThickness = 6
list.BackgroundTransparency = 0.4
list.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
list.BorderSizePixel = 0
list.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Parent = list
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 20)
statusLabel.Position = UDim2.new(0, 5, 1, -25)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamSemibold
statusLabel.TextSize = 14
statusLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
statusLabel.Text = "Press B to toggle shop"
statusLabel.Parent = frame

local catalogCache = {}

local function rebuildList(items)
        list:ClearAllChildren()
        layout.Parent = list

        for _, item in ipairs(items) do
                local button = Instance.new("TextButton")
                button.Size = UDim2.new(1, -10, 0, 60)
                button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                button.TextColor3 = Color3.new(1, 1, 1)
                button.TextWrapped = true
                button.Font = Enum.Font.Gotham
                button.TextSize = 14
                button.Text = string.format("%s\n$%d - %s", item.Type == "weapon" and item.WeaponId or item.UpgradeId, item.Price, item.Description)
                button.Parent = list

                button.MouseButton1Click:Connect(function()
                        shopRequest:FireServer("purchase", {itemId = item.Id})
                end)
        end

        list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
end

shopUpdate.OnClientEvent:Connect(function(payload)
        if payload.type == "catalog" then
                catalogCache = payload.items or {}
                rebuildList(catalogCache)
        elseif payload.type == "result" then
                statusLabel.TextColor3 = payload.success and Color3.new(0.7, 1, 0.7) or Color3.new(1, 0.6, 0.6)
                statusLabel.Text = payload.message or "Unknown"
        end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then
                return
        end

        if input.KeyCode == Enum.KeyCode.B then
                screenGui.Enabled = not screenGui.Enabled
                if screenGui.Enabled then
                        statusLabel.Text = "Purchasing..."
                        shopRequest:FireServer("catalog")
                else
                        statusLabel.Text = "Press B to toggle shop"
                end
        end
end)
