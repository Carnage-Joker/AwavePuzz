-- @ScriptType: ModuleScript
-- CureStationSetup.lua
-- Module for setting up cure stations with ProximityPrompts
-- Returns a table/class that can be instantiated and initialized

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

local CureStationSetup = {}
CureStationSetup.__index = CureStationSetup

-- Load GameConfig to check dev settings (with safe fallback)
local SharedFolder = ReplicatedStorage:FindFirstChild("Shared")
local GameConfig
if SharedFolder then
	local GameConfigModule = SharedFolder:FindFirstChild("GameConfig")
	if GameConfigModule then
		local success, result = pcall(require, GameConfigModule)
		if success then
			GameConfig = result
		else
			warn("[CureStationSetup] Failed to load GameConfig:", result)
		end
	end
end
-- Constructor
function CureStationSetup.new()
	local self = setmetatable({}, CureStationSetup)
	self._initialized = false
	return self
end

-- Function to setup a cure station
local function setupCureStation(station)
	-- Ensure station has a ProximityPrompt
	local proximityPrompt = station:FindFirstChildOfClass("ProximityPrompt")
	if not proximityPrompt then
		proximityPrompt = Instance.new("ProximityPrompt")
		proximityPrompt.ActionText = "Access Cure Station"
		proximityPrompt.ObjectText = "Cure Station"
		proximityPrompt.MaxActivationDistance = 10
		proximityPrompt.RequiresLineOfSight = false
		proximityPrompt.Parent = station
	end
	
	-- Connect to RemoteEvent for puzzle requests
	proximityPrompt.Triggered:Connect(function(player)
		print(player.Name .. " interacted with cure station")
		
		-- Check what component puzzles the player can attempt
		-- This will be handled by sending a request to the server
		local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if not remoteEvents then
			remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
			if not remoteEvents then
				warn("[CureStationSetup] RemoteEvents folder not found after 10 seconds. Cure interactions may not work.")
				return
			end
		end
		
		if remoteEvents:FindFirstChild("RequestPuzzle") then
			-- For now, let player choose which puzzle to attempt
			-- In a full implementation, we'd show a UI to select component
			-- For MVP, we'll just attempt the first available component puzzle
			
			-- Send notification to show puzzle menu
			if remoteEvents:FindFirstChild("CureUpdate") then
				remoteEvents.CureUpdate:FireClient(player, {
					type = "show_puzzle_menu",
					message = "Select a component puzzle to attempt"
				})
			end
		end
	end)
	
	print("Cure station setup complete:", station.Name)
end

-- Find or create cure stations
local function initializeCureStations()
	-- Look for CureStations folder
	local cureStationsFolder = workspace:FindFirstChild("CureStations")
	
	if not cureStationsFolder then
		-- Check if we should auto-create in Studio
		local isStudio = RunService:IsStudio()
		local allowAutoCreate = GameConfig and GameConfig.DEV_AUTO_CREATE_CURE_STATIONS
		
		if isStudio and allowAutoCreate then
			warn("[CureStationSetup] No CureStations folder found in Workspace. Creating example station (Studio mode)...")
			
			-- Create a folder for cure stations
			cureStationsFolder = Instance.new("Folder")
			cureStationsFolder.Name = "CureStations"
			cureStationsFolder.Parent = workspace
			
			-- Create a basic cure station
			local station = Instance.new("Part")
			station.Name = "CureStation1"
			station.Size = Vector3.new(6, 8, 6)
			station.Position = Vector3.new(0, 4, 0)
			station.Anchored = true
			station.Color = Color3.fromRGB(100, 255, 100)
			station.Material = Enum.Material.Neon
			station.Parent = cureStationsFolder
			
			-- Add a label
			local billboard = Instance.new("BillboardGui")
			billboard.Size = UDim2.new(0, 200, 0, 50)
			billboard.AlwaysOnTop = true
			billboard.StudsOffset = Vector3.new(0, 5, 0)
			billboard.Parent = station
			
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = "CURE STATION"
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.TextScaled = true
			label.Font = Enum.Font.GothamBold
			label.Parent = billboard
			
			print("[CureStationSetup] Created example cure station at origin (Studio mode)")
		else
			if not isStudio then
				warn("[CureStationSetup] WARNING: No CureStations folder found in Workspace. This is required for gameplay. Auto-creation is disabled in non-Studio environments.")
			else
				warn("[CureStationSetup] WARNING: No CureStations folder found in Workspace. Set GameConfig.DEV_AUTO_CREATE_CURE_STATIONS = true to auto-create in Studio.")
			end
			return
		end
	end
	
	-- Setup all stations
	for _, station in ipairs(cureStationsFolder:GetChildren()) do
		if station:IsA("BasePart") or station:IsA("Model") then
			setupCureStation(station)
		end
	end
	
	print("[CureStationSetup] Cure stations initialized:", #cureStationsFolder:GetChildren())
end

-- Initialize method (idempotent)
function CureStationSetup:initialize()
	if self._initialized then 
		return true 
	end
	self._initialized = true
	
	initializeCureStations()
	return true
end

-- Auto-initialize in Studio if running as a script (backwards compatibility)
-- This only runs when directly executed, not when required as a module
if RunService:IsStudio() and GameConfig and GameConfig.DEV_AUTO_CREATE_CURE_STATIONS then
	task.defer(function()
		-- Auto-create an instance and initialize only in Studio with feature flag
		local autoInstance = CureStationSetup.new()
		autoInstance:initialize()
	end)
end

return CureStationSetup
