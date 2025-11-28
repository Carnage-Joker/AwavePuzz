-- UIScaleManager.lua
-- Utility module for responsive UI scaling and positioning
--[[
    This module provides functions to:
    - Detect device type and screen size
    - Calculate appropriate scale factors
    - Apply responsive sizing to UI elements
    - Handle safe areas to avoid Roblox menus
]]

local UIScaleManager = {}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

-- Get config
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Local state
local currentScaleFactors = nil
local currentDeviceType = "DESKTOP"
local currentViewportSize = Vector2.new(1920, 1080)
local updateCallbacks = {}

-- Forward declaration
local UIScaleConfig = nil

-- Load config safely (may not be available immediately)
local function loadConfig()
    if UIScaleConfig then return true end
    
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    if shared then
        local configModule = shared:FindFirstChild("UIScaleConfig")
        if configModule then
            local success, result = pcall(function()
                return require(configModule)
            end)
            if success then
                UIScaleConfig = result
                return true
            end
        end
    end
    return false
end

-- Determine device type based on input and screen size
function UIScaleManager.getDeviceType()
    loadConfig()
    
    local touchEnabled = UserInputService.TouchEnabled
    local keyboardEnabled = UserInputService.KeyboardEnabled
    local mouseEnabled = UserInputService.MouseEnabled
    
    -- Get viewport size
    local camera = workspace.CurrentCamera
    if camera then
        currentViewportSize = camera.ViewportSize
    end
    
    local width = currentViewportSize.X
    
    -- Check if mobile/tablet based on touch and screen size
    if touchEnabled and not keyboardEnabled then
        if UIScaleConfig then
            if width <= UIScaleConfig.Breakpoints.MOBILE_SMALL then
                return "MOBILE_SMALL"
            elseif width <= UIScaleConfig.Breakpoints.MOBILE_LARGE then
                return "MOBILE_LARGE"
            elseif width <= UIScaleConfig.Breakpoints.TABLET then
                return "TABLET"
            end
        else
            -- Fallback if config not loaded
            if width <= 480 then return "MOBILE_SMALL"
            elseif width <= 768 then return "MOBILE_LARGE"
            elseif width <= 1024 then return "TABLET"
            end
        end
    end
    
    -- Desktop or desktop-like device
    return "DESKTOP"
end

-- Get current scale factors
function UIScaleManager.getScaleFactors()
    loadConfig()
    
    if currentScaleFactors then
        return currentScaleFactors
    end
    
    currentDeviceType = UIScaleManager.getDeviceType()
    
    if UIScaleConfig and UIScaleConfig.ScaleFactors[currentDeviceType] then
        currentScaleFactors = UIScaleConfig.ScaleFactors[currentDeviceType]
    else
        -- Fallback defaults
        currentScaleFactors = {
            ui = 1.0,
            text = 1.0,
            padding = 1.0,
            hudElements = 1.0,
            menuElements = 1.0,
        }
    end
    
    return currentScaleFactors
end

-- Get safe area insets
function UIScaleManager.getSafeAreaInsets()
    loadConfig()
    
    local deviceType = UIScaleManager.getDeviceType()
    
    -- Map device type to safe area category
    local safeAreaKey = "DESKTOP"
    if deviceType == "MOBILE_SMALL" or deviceType == "MOBILE_LARGE" then
        safeAreaKey = "MOBILE"
    elseif deviceType == "TABLET" then
        safeAreaKey = "TABLET"
    end
    
    if UIScaleConfig and UIScaleConfig.SafeAreas[safeAreaKey] then
        return UIScaleConfig.SafeAreas[safeAreaKey]
    end
    
    -- Fallback
    return { top = 50, bottom = 50, left = 10, right = 10 }
end

-- Scale a pixel value based on current device
function UIScaleManager.scalePixels(basePixels, scaleType)
    local factors = UIScaleManager.getScaleFactors()
    local factor = factors[scaleType] or factors.ui or 1.0
    return math.floor(basePixels * factor + 0.5)
end

-- Scale a UDim2 size
function UIScaleManager.scaleSize(baseWidth, baseHeight, scaleType, elementType)
    loadConfig()
    
    local factors = UIScaleManager.getScaleFactors()
    local factor = factors[scaleType] or factors.ui or 1.0
    
    local scaledWidth = math.floor(baseWidth * factor + 0.5)
    local scaledHeight = math.floor(baseHeight * factor + 0.5)
    
    -- Apply min/max constraints if config available
    if UIScaleConfig and elementType then
        local maxSizes = UIScaleConfig.MaxSizes[elementType]
        local minSizes = UIScaleConfig.MinSizes[elementType]
        
        if maxSizes then
            scaledWidth = math.min(scaledWidth, maxSizes.width)
            scaledHeight = math.min(scaledHeight, maxSizes.height)
        end
        
        if minSizes then
            scaledWidth = math.max(scaledWidth, minSizes.width)
            scaledHeight = math.max(scaledHeight, minSizes.height)
        end
    end
    
    return UDim2.new(0, scaledWidth, 0, scaledHeight)
end

-- Get scaled text size
function UIScaleManager.scaleTextSize(baseSize)
    local factors = UIScaleManager.getScaleFactors()
    local scaled = math.floor(baseSize * (factors.text or 1.0) + 0.5)
    -- Minimum readable text size
    return math.max(scaled, 10)
end

-- Create position with safe area offsets
function UIScaleManager.getPositionWithSafeArea(positionPreset, offsetX, offsetY)
    loadConfig()
    
    offsetX = offsetX or 0
    offsetY = offsetY or 0
    
    local safeArea = UIScaleManager.getSafeAreaInsets()
    local factors = UIScaleManager.getScaleFactors()
    
    -- Scale offsets
    local scaledOffsetX = math.floor(offsetX * (factors.padding or 1.0) + 0.5)
    local scaledOffsetY = math.floor(offsetY * (factors.padding or 1.0) + 0.5)
    
    if positionPreset == "topLeft" then
        return UDim2.new(0, safeArea.left + scaledOffsetX, 0, safeArea.top + scaledOffsetY)
    elseif positionPreset == "topCenter" then
        return UDim2.new(0.5, scaledOffsetX, 0, safeArea.top + scaledOffsetY)
    elseif positionPreset == "topRight" then
        return UDim2.new(1, -(safeArea.right + scaledOffsetX), 0, safeArea.top + scaledOffsetY)
    elseif positionPreset == "bottomLeft" then
        return UDim2.new(0, safeArea.left + scaledOffsetX, 1, -(safeArea.bottom + scaledOffsetY))
    elseif positionPreset == "bottomRight" then
        return UDim2.new(1, -(safeArea.right + scaledOffsetX), 1, -(safeArea.bottom + scaledOffsetY))
    elseif positionPreset == "center" then
        return UDim2.new(0.5, scaledOffsetX, 0.5, scaledOffsetY)
    end
    
    -- Default: top-left with safe area
    return UDim2.new(0, safeArea.left + scaledOffsetX, 0, safeArea.top + scaledOffsetY)
end

-- Apply scaling to an existing GUI element
function UIScaleManager.applyScaling(guiElement, options)
    if not guiElement then return end
    
    options = options or {}
    local scaleType = options.scaleType or "ui"
    local elementType = options.elementType
    local baseWidth = options.baseWidth
    local baseHeight = options.baseHeight
    local baseTextSize = options.baseTextSize
    local positionPreset = options.positionPreset
    local offsetX = options.offsetX or 0
    local offsetY = options.offsetY or 0
    
    -- Scale size if base dimensions provided
    if baseWidth and baseHeight then
        guiElement.Size = UIScaleManager.scaleSize(baseWidth, baseHeight, scaleType, elementType)
    end
    
    -- Scale text if applicable
    if baseTextSize and (guiElement:IsA("TextLabel") or guiElement:IsA("TextButton") or guiElement:IsA("TextBox")) then
        guiElement.TextSize = UIScaleManager.scaleTextSize(baseTextSize)
    end
    
    -- Position with safe area
    if positionPreset then
        guiElement.Position = UIScaleManager.getPositionWithSafeArea(positionPreset, offsetX, offsetY)
    end
end

-- Register a callback to be called when screen size changes
function UIScaleManager.onScaleChanged(callback)
    if type(callback) == "function" then
        table.insert(updateCallbacks, callback)
    end
end

-- Check if current device is mobile
function UIScaleManager.isMobile()
    local deviceType = UIScaleManager.getDeviceType()
    return deviceType == "MOBILE_SMALL" or deviceType == "MOBILE_LARGE"
end

-- Check if current device is tablet
function UIScaleManager.isTablet()
    return UIScaleManager.getDeviceType() == "TABLET"
end

-- Check if current device is desktop
function UIScaleManager.isDesktop()
    return UIScaleManager.getDeviceType() == "DESKTOP"
end

-- Get viewport size
function UIScaleManager.getViewportSize()
    local camera = workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end
    return Vector2.new(1920, 1080)
end

-- Initialize scale manager (call from client scripts)
function UIScaleManager.initialize()
    loadConfig()
    
    -- Initial calculation
    currentDeviceType = UIScaleManager.getDeviceType()
    currentScaleFactors = nil -- Force recalculation
    UIScaleManager.getScaleFactors()
    
    -- Track the active ViewportSize connection to avoid duplicates
    local viewportConnection = nil
    
    -- Helper to connect to the current camera's ViewportSize changes
    local function connectViewportSizeListener(camera)
        if viewportConnection then
            viewportConnection:Disconnect()
            viewportConnection = nil
        end
        if camera then
            currentViewportSize = camera.ViewportSize
            currentScaleFactors = nil -- Force recalculation
            viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                local newViewport = camera.ViewportSize
                if newViewport ~= currentViewportSize then
                    currentViewportSize = newViewport
                    currentScaleFactors = nil -- Force recalculation
                    currentDeviceType = UIScaleManager.getDeviceType()
                    
                    -- Notify all registered callbacks
                    for _, callback in ipairs(updateCallbacks) do
                        task.spawn(callback)
                    end
                end
            end)
        end
    end
    
    -- Initial connection for current camera
    connectViewportSizeListener(workspace.CurrentCamera)
    
    -- Listen for camera changes and reconnect
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        connectViewportSizeListener(workspace.CurrentCamera)
    end)
    
    return UIScaleManager
end

-- Utility: Create a scaled frame with common properties
function UIScaleManager.createScaledFrame(name, options)
    options = options or {}
    
    local frame = Instance.new("Frame")
    frame.Name = name or "ScaledFrame"
    frame.BackgroundColor3 = options.backgroundColor or Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = options.backgroundTransparency or 0.3
    frame.BorderSizePixel = options.borderSize or 0
    
    if options.baseWidth and options.baseHeight then
        frame.Size = UIScaleManager.scaleSize(
            options.baseWidth, 
            options.baseHeight, 
            options.scaleType or "hudElements",
            options.elementType
        )
    end
    
    if options.positionPreset then
        frame.Position = UIScaleManager.getPositionWithSafeArea(
            options.positionPreset,
            options.offsetX or 0,
            options.offsetY or 0
        )
    end
    
    if options.anchorPoint then
        frame.AnchorPoint = options.anchorPoint
    end
    
    -- Add corner radius if specified
    if options.cornerRadius then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, UIScaleManager.scalePixels(options.cornerRadius, "padding"))
        corner.Parent = frame
    end
    
    return frame
end

-- Utility: Create scaled text label
function UIScaleManager.createScaledTextLabel(name, options)
    options = options or {}
    
    local label = Instance.new("TextLabel")
    label.Name = name or "ScaledLabel"
    label.BackgroundTransparency = 1
    label.TextColor3 = options.textColor or Color3.fromRGB(255, 255, 255)
    label.Font = options.font or Enum.Font.Gotham
    label.Text = options.text or ""
    label.TextXAlignment = options.textXAlignment or Enum.TextXAlignment.Left
    label.TextYAlignment = options.textYAlignment or Enum.TextYAlignment.Center
    
    if options.baseTextSize then
        label.TextSize = UIScaleManager.scaleTextSize(options.baseTextSize)
    else
        label.TextSize = UIScaleManager.scaleTextSize(14)
    end
    
    if options.baseWidth and options.baseHeight then
        label.Size = UIScaleManager.scaleSize(
            options.baseWidth,
            options.baseHeight,
            options.scaleType or "text"
        )
    end
    
    return label
end

return UIScaleManager
