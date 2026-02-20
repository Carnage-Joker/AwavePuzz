-- ShopUI.lua
-- Simple in-game shop interface for purchasing weapons and upgrades
-- Updated with dynamic UI scaling for mobile devices.
-- Refactored to use RemoteRegistry, UIConnectionMaid, and InputActionRegistry

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Load UI scaling utilities
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local UIScaleManager = require(SharedFolder:WaitForChild("UIScaleManager"))
local UIScaleConfig = require(SharedFolder:WaitForChild("UIScaleConfig"))
local ModalManager = require(SharedFolder:WaitForChild("ModalManager"))
local InputActionRegistry = require(SharedFolder:WaitForChild("InputActionRegistry"))
local UIDebugConfig = require(SharedFolder:WaitForChild("UIDebugConfig"))
-- at top of ShopUI module
local clickConns: { [Instance]: RBXScriptConnection } = {}

local function bindButton(btn: TextButton, callback)
	-- cleanup any existing
	local old = clickConns[btn]
	if old then old:Disconnect() end

	clickConns[btn] = btn.MouseButton1Click:Connect(callback)
end

local function cleanupButtons(parent: Instance)
	for inst, conn in pairs(clickConns) do
		if not inst:IsDescendantOf(parent) then
			conn:Disconnect()
			clickConns[inst] = nil
		end
	end
end
local UIConnectionMaid = require(SharedFolder:WaitForChild("UI"):WaitForChild("UIConnectionMaid"))
local RemoteRegistry = require(SharedFolder:WaitForChild("RemoteRegistry"))

-- Initialize scale manager
UIScaleManager.initialize()

-- Module state
local ShopUI = {}
local maid = UIConnectionMaid.new()
local remotes = nil  -- Will be set via bindRemotes()
local shopRequest = nil
local shopUpdate = nil

-- Helper functions
local function getScaledValue(baseValue, scaleType)
	return UIScaleManager.scalePixels(baseValue, scaleType or "menuElements")
end

local function getScaledTextSize(baseSize)
	return UIScaleManager.scaleTextSize(baseSize)
end

-- Minimum touch target from config with fallback
local MIN_TOUCH_TARGET = (UIScaleConfig.MinSizes.touchTarget and UIScaleConfig.MinSizes.touchTarget.width) or 44

-- Prevent duplicate UI instances
local playerGui = player:WaitForChild("PlayerGui")
local existing = playerGui:FindFirstChild("ShopUI")
if existing then
	UIDebugConfig.warnDuplicate("ShopUI")
	existing:Destroy()
end

UIDebugConfig.logUICreation("ShopUI", "Creating ScreenGui", "ShopUI.lua")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent = playerGui

-- Center the shop dialog with scaled size
local frame = Instance.new("Frame")
frame.Size = UIScaleManager.scaleSize(300, 320, "menuElements", "menuDialog")
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))
frameCorner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -getScaledValue(10, "padding"), 0, getScaledValue(30, "padding"))
title.Position = UDim2.new(0, getScaledValue(5, "padding"), 0, getScaledValue(5, "padding"))
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = getScaledTextSize(20)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "Camp Vendor"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

-- Close button with minimum touch target
local closeButtonSize = math.max(getScaledValue(30, "menuElements"), MIN_TOUCH_TARGET)
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, closeButtonSize, 0, closeButtonSize)
closeButton.Position = UDim2.new(1, -closeButtonSize - getScaledValue(5, "padding"), 0, getScaledValue(5, "padding"))
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = getScaledTextSize(18)
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, getScaledValue(5, "padding"))
closeCorner.Parent = closeButton

maid:Give(closeButton.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
	ModalManager.remove("ShopUI")
end), "closeButton")

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -getScaledValue(10, "padding"), 1, -getScaledValue(70, "padding"))
list.Position = UDim2.new(0, getScaledValue(5, "padding"), 0, getScaledValue(40, "padding"))
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.ScrollBarThickness = getScaledValue(6, "padding")
list.BackgroundTransparency = 0.4
list.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
list.BorderSizePixel = 0
list.ClipsDescendants = true
list.Parent = frame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, getScaledValue(4, "padding"))
padding.PaddingBottom = UDim.new(0, getScaledValue(4, "padding"))
padding.PaddingLeft = UDim.new(0, getScaledValue(4, "padding"))
padding.PaddingRight = UDim.new(0, getScaledValue(4, "padding"))
padding.Parent = list

local layout = Instance.new("UIListLayout")
layout.Parent = list
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, getScaledValue(6, "padding"))

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -getScaledValue(10, "padding"), 0, getScaledValue(20, "padding"))
statusLabel.Position = UDim2.new(0, getScaledValue(5, "padding"), 1, -getScaledValue(25, "padding"))
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Arcade
statusLabel.TextSize = getScaledTextSize(14)
statusLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
statusLabel.Text = "Press B to toggle shop"
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

-- Function to update UI scaling when screen size changes
local function updateUIScaling()
	frame.Size = UIScaleManager.scaleSize(300, 320, "menuElements", "menuDialog")
	frameCorner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))

	title.Size = UDim2.new(1, -getScaledValue(10, "padding"), 0, getScaledValue(30, "padding"))
	title.Position = UDim2.new(0, getScaledValue(5, "padding"), 0, getScaledValue(5, "padding"))
	title.TextSize = getScaledTextSize(20)

	local newCloseSize = math.max(getScaledValue(30, "menuElements"), MIN_TOUCH_TARGET)
	closeButton.Size = UDim2.new(0, newCloseSize, 0, newCloseSize)
	closeButton.Position = UDim2.new(1, -newCloseSize - getScaledValue(5, "padding"), 0, getScaledValue(5, "padding"))
	closeButton.TextSize = getScaledTextSize(18)
	closeCorner.CornerRadius = UDim.new(0, getScaledValue(5, "padding"))

	list.Size = UDim2.new(1, -getScaledValue(10, "padding"), 1, -getScaledValue(70, "padding"))
	list.Position = UDim2.new(0, getScaledValue(5, "padding"), 0, getScaledValue(40, "padding"))
	list.ScrollBarThickness = getScaledValue(6, "padding")

	padding.PaddingTop = UDim.new(0, getScaledValue(4, "padding"))
	padding.PaddingBottom = UDim.new(0, getScaledValue(4, "padding"))
	padding.PaddingLeft = UDim.new(0, getScaledValue(4, "padding"))
	padding.PaddingRight = UDim.new(0, getScaledValue(4, "padding"))
	layout.Padding = UDim.new(0, getScaledValue(6, "padding"))

	statusLabel.Size = UDim2.new(1, -getScaledValue(10, "padding"), 0, getScaledValue(20, "padding"))
	statusLabel.Position = UDim2.new(0, getScaledValue(5, "padding"), 1, -getScaledValue(25, "padding"))
	statusLabel.TextSize = getScaledTextSize(14)
end

-- Register for scale changes (returns unsubscribe function)
maid:GiveFn(UIScaleManager.onScaleChanged(updateUIScaling), "scaleChanged")

local catalogCache = {}
local debounce = false
local selectedItemIndex = 1
local shopItems = {} -- Track shop item buttons for keyboard navigation
local buttonMaid = UIConnectionMaid.new() -- Separate maid for transient button connections

-- Shared purchase function used by both click and keyboard selection
local function purchaseItem(item)
	if debounce or not shopRequest then
		return
	end
	debounce = true
	
	statusLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
	statusLabel.Text = "Processing purchase..."
	shopRequest:FireServer("purchase", { itemId = item.Id })
	
	task.delay(0.25, function()
		debounce = false
	end)
end

local function updateItemSelection()
	-- Update visual indication of selected item
	for i, button in ipairs(shopItems) do
		if i == selectedItemIndex then
			button.BackgroundColor3 = Color3.fromRGB(80, 120, 200) -- Highlight selected
			button.BorderSizePixel = 2
			button.BorderColor3 = Color3.fromRGB(150, 200, 255)
		else
			button.BackgroundColor3 = Color3.fromRGB(45, 45, 45) -- Normal
			button.BorderSizePixel = 0
		end
	end
	
	-- Scroll to selected item if needed
	if #shopItems > 0 and shopItems[selectedItemIndex] then
		local selectedButton = shopItems[selectedItemIndex]
		local buttonPos = selectedButton.AbsolutePosition.Y - list.AbsolutePosition.Y
		local listHeight = list.AbsoluteSize.Y
		local canvasPos = list.CanvasPosition.Y
		
		-- Scroll down if item is below visible area
		if buttonPos + selectedButton.AbsoluteSize.Y > canvasPos + listHeight then
			list.CanvasPosition = Vector2.new(0, buttonPos + selectedButton.AbsoluteSize.Y - listHeight)
		-- Scroll up if item is above visible area
		elseif buttonPos < canvasPos then
			list.CanvasPosition = Vector2.new(0, buttonPos)
		end
	end
end

local function updateCanvasSize()
	list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
end

maid:Give(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize), "layoutChanged")

local function rebuildList(items)
	-- Clean up all existing button connections
	buttonMaid:Cleanup()
	
	-- Preserve layout and padding while clearing entries
	for _, child in ipairs(list:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
	
	-- Clear shop items array
	shopItems = {}
	selectedItemIndex = 1

	for _, item in ipairs(items) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 60)
		button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextWrapped = true
		button.Font = Enum.Font.Gotham
		button.TextSize = 14

		local idText = item.Type == "weapon" and item.WeaponId or item.UpgradeId or item.Id or "Unknown"
		local price = tonumber(item.Price) or 0
		local desc = item.Description or ""

		button.Text = string.format("%s\n$%d - %s", idText, price, desc)
		button.AutoButtonColor = true
		button.Parent = list
		
		-- Store button and item data
		table.insert(shopItems, button)

		-- Track button connection in buttonMaid for automatic cleanup on next rebuild
		buttonMaid:Give(button.MouseButton1Click:Connect(function()
			purchaseItem(item)
		end))
	end

	updateCanvasSize()
	
	-- Update selection visuals
	if #shopItems > 0 then
		updateItemSelection()
	end
end

-- Bind remotes from RemoteRegistry (called by ClientMainModule)
function ShopUI.bindRemotes()
	-- Use RemoteRegistry as the source of truth for remote instances.
	-- Note: bindRemotes may be invoked as a method (self, remotes) by ClientMainModule,
	-- so we look up remotes via RemoteRegistry.getRemote() rather than the passed argument.
	local ok1, sr = pcall(RemoteRegistry.getRemote, "ShopRequest")
	local ok2, su = pcall(RemoteRegistry.getRemote, "ShopUpdate")

	if not ok1 then
		warn("[ShopUI] Failed to get ShopRequest remote:", sr)
	end

	if not ok2 then
		warn("[ShopUI] Failed to get ShopUpdate remote:", su)
	end
	shopRequest = ok1 and sr or nil
	shopUpdate  = ok2 and su or nil

	-- Debug: list found remotes and their full instance paths
	print(string.format("[ShopUI] bindRemotes: ShopRequest=%s",
		shopRequest and shopRequest:GetFullName() or "not found"))
	print(string.format("[ShopUI] bindRemotes: ShopUpdate=%s",
		shopUpdate and shopUpdate:GetFullName() or "not found"))

	if not shopRequest or not shopUpdate then
		warn("[ShopUI] Missing required remotes: ShopRequest or ShopUpdate")
		return
	end

	-- Connect to shop update events
	maid:Give(shopUpdate.OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			return
		end
		
		if payload.type == "catalog" then
			catalogCache = payload.items or {}
			rebuildList(catalogCache)
			statusLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
			statusLabel.Text = "↑/↓ or W/S: Navigate • Enter: Purchase • Backspace: Close"
		elseif payload.type == "result" then
			local success = payload.success == true
			statusLabel.TextColor3 = success and Color3.new(0.7, 1, 0.7) or Color3.new(1, 0.6, 0.6)
			statusLabel.Text = payload.message or (success and "Purchase successful" or "Purchase failed")
		end
	end), "shopUpdate")
	
	print("[ShopUI] Remotes bound successfully")
end

-- Setup InputActionRegistry handlers
local function setupInputActions()
	-- Register input actions with InputActionRegistry for conflict detection
	-- ShopToggle remains enabled to allow opening the shop
	-- Navigation actions disabled by default until shop opens to avoid conflicts
	InputActionRegistry.register("ShopToggle", "ShopUI", {Enum.KeyCode.B}, InputActionRegistry.Priority.TOGGLE_UI, true)
	InputActionRegistry.register("ShopNavigateUp", "ShopUI", {Enum.KeyCode.Up, Enum.KeyCode.W}, InputActionRegistry.Priority.MODAL_UI, false)
	InputActionRegistry.register("ShopNavigateDown", "ShopUI", {Enum.KeyCode.Down, Enum.KeyCode.S}, InputActionRegistry.Priority.MODAL_UI, false)
	InputActionRegistry.register("ShopSelect", "ShopUI", {Enum.KeyCode.Return}, InputActionRegistry.Priority.MODAL_UI, false)
	
	-- Set up actual input handling via UserInputService (gated by InputActionRegistry state)
	local UserInputService = game:GetService("UserInputService")
	maid:Give(UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		-- ALWAYS check gameProcessedEvent first
		if gameProcessedEvent then
			return
		end
		
		-- Handle shop toggle (B key)
		if input.KeyCode == Enum.KeyCode.B then
			-- Check if ShopToggle action is enabled in registry
			local action = InputActionRegistry.getAction("ShopToggle")
			if not action or not action.enabled then
				return
			end
			
			screenGui.Enabled = not screenGui.Enabled
			
			if screenGui.Enabled then
				statusLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
				statusLabel.Text = "Loading shop..."
				if shopRequest then
					shopRequest:FireServer("catalog")
				end
				
				-- Register with ModalManager and enable shop input actions
				ModalManager.push("ShopUI", function()
					screenGui.Enabled = false
					statusLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
					statusLabel.Text = "Press B to toggle shop"
					-- Disable shop input actions when closing
					InputActionRegistry.disableOwner("ShopUI")
				end, ModalManager.Priority.MODAL)
				
				-- Enable shop input actions when opening
				InputActionRegistry.enableOwner("ShopUI")
			else
				statusLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
				statusLabel.Text = "Press B to toggle shop"
				ModalManager.remove("ShopUI")
				-- Disable shop input actions when closing
				InputActionRegistry.disableOwner("ShopUI")
			end
			return
		end
		
		-- Handle navigation when shop is open
		if not screenGui.Enabled or #shopItems == 0 then
			return
		end
		
		-- Only process if this shop is the top modal
		if not ModalManager.isTopModal("ShopUI") then
			return
		end
		
		-- Navigate up
		if input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.W then
			local action = InputActionRegistry.getAction("ShopNavigateUp")
			if action and action.enabled then
				selectedItemIndex = selectedItemIndex - 1
				if selectedItemIndex < 1 then
					selectedItemIndex = #shopItems
				end
				updateItemSelection()
			end
		-- Navigate down
		elseif input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.S then
			local action = InputActionRegistry.getAction("ShopNavigateDown")
			if action and action.enabled then
				selectedItemIndex = selectedItemIndex + 1
				if selectedItemIndex > #shopItems then
					selectedItemIndex = 1
				end
				updateItemSelection()
			end
		-- Select item with Enter
		elseif input.KeyCode == Enum.KeyCode.Return then
			local action = InputActionRegistry.getAction("ShopSelect")
			if action and action.enabled then
				-- Get the item data from the catalog cache
				if shopItems[selectedItemIndex] and catalogCache[selectedItemIndex] then
					purchaseItem(catalogCache[selectedItemIndex])
				end
			end
		end
	end), "inputBegan")
end

-- Initialize input actions (called at module load time)
setupInputActions()

function ShopUI.cleanup()
	-- Unregister input actions
	InputActionRegistry.unregister("ShopToggle")
	InputActionRegistry.unregister("ShopNavigateUp")
	InputActionRegistry.unregister("ShopNavigateDown")
	InputActionRegistry.unregister("ShopSelect")
	
	-- Clean up all connections
	maid:Cleanup()
	buttonMaid:Cleanup()
	
	-- Close modal if open
	if ModalManager.isModalOpen("ShopUI") then
		ModalManager.remove("ShopUI")
	end
	
	-- Destroy UI
	if screenGui then
		screenGui:Destroy()
		screenGui = nil
	end
end

return ShopUI
