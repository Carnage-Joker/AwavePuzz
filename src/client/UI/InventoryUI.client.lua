-- InventoryUI.client.lua
-- Displays the player's cure components and currency balance

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local inventoryEvent = remoteFolder:WaitForChild("InventoryUpdate")
local currencyEvent = remoteFolder:WaitForChild("CurrencyUpdate")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 120)
frame.Position = UDim2.new(0, 15, 0, 15)
frame.BackgroundTransparency = 0.35
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -10, 0, 20)
title.Position = UDim2.new(0, 5, 0, 5)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Inventory"
title.Parent = frame

local currencyLabel = Instance.new("TextLabel")
currencyLabel.Size = UDim2.new(1, -10, 0, 20)
currencyLabel.Position = UDim2.new(0, 5, 0, 30)
currencyLabel.BackgroundTransparency = 1
currencyLabel.Font = Enum.Font.GothamSemibold
currencyLabel.TextSize = 14
currencyLabel.TextColor3 = Color3.new(0.8, 0.95, 0.8)
currencyLabel.TextXAlignment = Enum.TextXAlignment.Left
currencyLabel.Text = "Currency: 0"
currencyLabel.Parent = frame

local componentsLabel = Instance.new("TextLabel")
componentsLabel.Size = UDim2.new(1, -10, 0, 60)
componentsLabel.Position = UDim2.new(0, 5, 0, 55)
componentsLabel.BackgroundTransparency = 1
componentsLabel.Font = Enum.Font.Gotham
componentsLabel.TextSize = 13
componentsLabel.TextWrapped = true
componentsLabel.TextXAlignment = Enum.TextXAlignment.Left
componentsLabel.TextYAlignment = Enum.TextYAlignment.Top
componentsLabel.TextColor3 = Color3.new(1, 1, 1)
componentsLabel.Text = "Components: none"
componentsLabel.Parent = frame

local function formatInventory(inventory)
        local parts = {}
        for name, count in pairs(inventory or {}) do
                table.insert(parts, string.format("%s x%d", name, count))
        end
        table.sort(parts)
        if #parts == 0 then
                return "Components: none"
        end
        return "Components: " .. table.concat(parts, ", ")
end

inventoryEvent.OnClientEvent:Connect(function(payload)
        componentsLabel.Text = formatInventory(payload.inventory)
end)

currencyEvent.OnClientEvent:Connect(function(payload)
        currencyLabel.Text = "Currency: " .. tostring(payload.balance or 0)
end)
