-- @ScriptType: ModuleScript
-- CureStationInteraction.lua
-- Handles cure station interaction with both ProximityPrompt and manual 'E'/'F' key support
-- Provides fallback interaction method for players who might miss the proximity prompt
-- Supports mobile devices through touch button integration

local CureStationInteraction = {}
CureStationInteraction.__index = CureStationInteraction

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Configuration
local INTERACTION_DISTANCE = 15 -- Maximum distance to interact with cure station
local CHECK_INTERVAL = 0.5 -- How often to check for nearby cure stations (in seconds)

function CureStationInteraction.new()
	local self = setmetatable({}, CureStationInteraction)
	
	self.enabled = false
	self.nearestStation = nil
	self.distanceToNearest = math.huge
	self.connections = {}
	self.promptVisible = false
	self.isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	
	return self
end

-- Find the nearest cure station to the player
function CureStationInteraction:findNearestCureStation()
	local character = player.Character
	if not character or not character.PrimaryPart then
		return nil, math.huge
	end
	
	local playerPos = character.PrimaryPart.Position
	local workspace = game:GetService("Workspace")
	local cureStationsFolder = workspace:FindFirstChild("CureStations")
	
	if not cureStationsFolder then
		return nil, math.huge
	end
	
	local nearestStation = nil
	local minDistance = math.huge
	
	for _, station in ipairs(cureStationsFolder:GetChildren()) do
		if station:IsA("BasePart") or station:IsA("Model") then
			local stationPos
			if station:IsA("BasePart") then
				stationPos = station.Position
			elseif station:IsA("Model") and station.PrimaryPart then
				stationPos = station.PrimaryPart.Position
			elseif station:IsA("Model") then
				-- Get model pivot position
				stationPos = station:GetPivot().Position
			end
			
			if stationPos then
				local distance = (playerPos - stationPos).Magnitude
				if distance < minDistance then
					minDistance = distance
					nearestStation = station
				end
			end
		end
	end
	
	return nearestStation, minDistance
end

-- Show on-screen prompt for interaction (keyboard or touch button)
function CureStationInteraction:showInteractionPrompt()
	if self.promptVisible then return end
	
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Create a simple interaction prompt
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CureStationPrompt"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	
	if self.isMobile then
		-- Mobile: Show touch button
		local button = Instance.new("TextButton")
		button.Name = "CureStationButton"
		button.Size = UDim2.new(0, 120, 0, 60)
		button.Position = UDim2.new(0.5, 0, 0.8, 0)
		button.AnchorPoint = Vector2.new(0.5, 0.5)
		button.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
		button.BackgroundTransparency = 0.2
		button.BorderSizePixel = 3
		button.BorderColor3 = Color3.fromRGB(50, 200, 50)
		button.Text = "🧪\nCURE\nSTATION"
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextSize = 16
		button.Font = Enum.Font.GothamBold
		button.Parent = screenGui
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = button
		
		-- Connect touch event
		button.MouseButton1Click:Connect(function()
			self:triggerInteraction()
		end)
	else
		-- Keyboard: Show key prompt
		local promptFrame = Instance.new("Frame")
		promptFrame.Name = "PromptFrame"
		promptFrame.Size = UDim2.new(0, 220, 0, 50)
		promptFrame.Position = UDim2.new(0.5, 0, 0.7, 0)
		promptFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		promptFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		promptFrame.BackgroundTransparency = 0.2
		promptFrame.BorderSizePixel = 2
		promptFrame.BorderColor3 = Color3.fromRGB(100, 255, 100)
		promptFrame.Parent = screenGui
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = promptFrame
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = "[F] or [E] Access Cure Station"
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextSize = 18
		label.Font = Enum.Font.GothamBold
		label.Parent = promptFrame
	end
	
	self.promptVisible = true
end

-- Hide on-screen prompt
function CureStationInteraction:hideInteractionPrompt()
	if not self.promptVisible then return end
	
	local playerGui = player:WaitForChild("PlayerGui")
	local existingPrompt = playerGui:FindFirstChild("CureStationPrompt")
	if existingPrompt then
		existingPrompt:Destroy()
	end
	
	self.promptVisible = false
end

-- Trigger cure station interaction (request puzzle menu)
function CureStationInteraction:triggerInteraction()
	-- Recompute nearest station and distance at the moment of interaction
	local station, distance = self:findNearestCureStation()
	if not station then return end
	if distance > INTERACTION_DISTANCE then return end

	-- Keep internal state in sync with the most recent calculation
	self.nearestStation = station
	self.distanceToNearest = distance
	
	print("[CureStationInteraction] Player interacted with cure station:", station.Name)
	
	-- Fire remote event to request puzzle progress from server
	-- The server will then send CureUpdate with "show_puzzle_menu" back to the client
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 5)
	if remoteEvents then
		local requestPuzzle = remoteEvents:FindFirstChild("RequestPuzzleProgress")
		if requestPuzzle then
			-- Request puzzle progress from server, which will trigger the puzzle menu UI
			requestPuzzle:FireServer()
		else
			warn("[CureStationInteraction] RequestPuzzleProgress remote event not found")
		end
	end
end

-- Update loop to check for nearby cure stations
function CureStationInteraction:update()
	if not self.enabled then return end
	
	local station, distance = self:findNearestCureStation()
	
	self.nearestStation = station
	self.distanceToNearest = distance
	
	-- Show/hide prompt based on distance
	if station and distance <= INTERACTION_DISTANCE then
		self:showInteractionPrompt()
	else
		self:hideInteractionPrompt()
	end
end

-- Initialize the interaction system
function CureStationInteraction:initialize()
	if self.enabled then
		warn("[CureStationInteraction] Already initialized")
		return
	end
	
	self.enabled = true
	
	-- Connect to keyboard input for 'F' and 'E' keys
	-- 'F' is the primary interaction key (no conflicts)
	-- 'E' works as a context-sensitive override when very close to cure station
	self.connections.inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end
		
		-- Check for 'F' key press (primary interaction key - no conflicts)
		if input.KeyCode == Enum.KeyCode.F then
			-- Only trigger if we're near a cure station
			if self.nearestStation and self.distanceToNearest <= INTERACTION_DISTANCE then
				self:triggerInteraction()
			end
		end
		
		-- Check for 'E' key press (context-sensitive - only when VERY close)
		-- This provides convenience for players who expect 'E' to interact
		-- When within 5 studs of cure station, interaction takes priority
		if input.KeyCode == Enum.KeyCode.E then
			-- Only trigger if we're VERY close to cure station (within 5 studs)
			if self.nearestStation and self.distanceToNearest <= 5 then
				self:triggerInteraction()
				-- Note: We can't fully prevent weapon switching from this hook
				-- The weapon controller will still process the E key
				-- However, the puzzle menu will open and may block further input
			end
		end
	end)
	
	-- Use a slower update rate to check for nearby stations
	local lastCheck = 0
	self.connections.stepped = RunService.Stepped:Connect(function()
		local now = tick()
		if now - lastCheck >= CHECK_INTERVAL then
			lastCheck = now
			self:update()
		end
	end)
	
	print("[CureStationInteraction] Initialized - Press 'F' (or 'E' when very close) near cure stations to interact")
end

-- Cleanup
function CureStationInteraction:cleanup()
	self.enabled = false
	
	-- Disconnect all connections
	for _, connection in pairs(self.connections) do
		if connection then
			connection:Disconnect()
		end
	end
	self.connections = {}
	
	-- Hide prompt
	self:hideInteractionPrompt()
	
	print("[CureStationInteraction] Cleaned up")
end

return CureStationInteraction
