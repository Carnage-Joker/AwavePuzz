-- @ScriptType: Script
-- CureStationSetup.lua
-- Server script to setup cure stations with ProximityPrompts
-- Place in ServerScriptService or run once to setup stations

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")

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
		warn("No CureStations folder found in Workspace. Creating example station...")
		
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
		
		print("Created example cure station at origin")
	end
	
	-- Setup all stations
	for _, station in ipairs(cureStationsFolder:GetChildren()) do
		if station:IsA("BasePart") or station:IsA("Model") then
			setupCureStation(station)
		end
	end
	
	print("Cure stations initialized:", #cureStationsFolder:GetChildren())
end

-- Initialize cure stations
initializeCureStations()

return true
