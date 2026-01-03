-- LobbySetup.lua
-- Creates a safe lobby area where players spawn before the map loads
-- This lobby is separate from the game map and provides a waiting area

local LobbySetup = {}
LobbySetup.__index = LobbySetup

-- Lobby position (at origin, separate from map at 5000, 0, 0)
local LOBBY_POSITION = Vector3.new(0, 5, 0)
local LOBBY_SIZE = Vector3.new(50, 1, 50)

function LobbySetup.new()
	local self = setmetatable({}, LobbySetup)
	self.lobbyModel = nil
	return self
end

-- Create the lobby area
function LobbySetup:createLobby()
	print("[LobbySetup] Creating lobby area")
	
	-- Check if lobby already exists
	local existingLobby = workspace:FindFirstChild("Lobby")
	if existingLobby then
		existingLobby:Destroy()
	end
	
	-- Create lobby model
	local lobbyModel = Instance.new("Model")
	lobbyModel.Name = "Lobby"
	
	-- Create lobby platform
	local platform = Instance.new("Part")
	platform.Name = "LobbyPlatform"
	platform.Size = LOBBY_SIZE
	platform.Position = LOBBY_POSITION
	platform.Anchored = true
	platform.CanCollide = true
	platform.Material = Enum.Material.SmoothPlastic
	platform.Color = Color3.fromRGB(100, 100, 150) -- Light blue-gray
	platform.Transparency = 0
	platform.Parent = lobbyModel
	
	-- Create spawn location for players
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "LobbySpawn"
	spawnLocation.Size = Vector3.new(10, 1, 10)
	spawnLocation.Position = LOBBY_POSITION + Vector3.new(0, 5, 0) -- Above platform
	spawnLocation.Anchored = true
	spawnLocation.CanCollide = false
	spawnLocation.Transparency = 1 -- Invisible
	spawnLocation.Duration = 0 -- Instant respawn
	spawnLocation.Neutral = true -- All players can spawn here
	spawnLocation.Parent = lobbyModel
	
	-- Create some walls around the lobby for aesthetic
	local wallHeight = 8
	local wallThickness = 1
	
	-- North wall
	local northWall = Instance.new("Part")
	northWall.Name = "NorthWall"
	northWall.Size = Vector3.new(LOBBY_SIZE.X, wallHeight, wallThickness)
	northWall.Position = LOBBY_POSITION + Vector3.new(0, wallHeight/2, LOBBY_SIZE.Z/2)
	northWall.Anchored = true
	northWall.CanCollide = true
	northWall.Material = Enum.Material.Concrete
	northWall.Color = Color3.fromRGB(80, 80, 90)
	northWall.Parent = lobbyModel
	
	-- South wall
	local southWall = Instance.new("Part")
	southWall.Name = "SouthWall"
	southWall.Size = Vector3.new(LOBBY_SIZE.X, wallHeight, wallThickness)
	southWall.Position = LOBBY_POSITION + Vector3.new(0, wallHeight/2, -LOBBY_SIZE.Z/2)
	southWall.Anchored = true
	southWall.CanCollide = true
	southWall.Material = Enum.Material.Concrete
	southWall.Color = Color3.fromRGB(80, 80, 90)
	southWall.Parent = lobbyModel
	
	-- East wall
	local eastWall = Instance.new("Part")
	eastWall.Name = "EastWall"
	eastWall.Size = Vector3.new(wallThickness, wallHeight, LOBBY_SIZE.Z)
	eastWall.Position = LOBBY_POSITION + Vector3.new(LOBBY_SIZE.X/2, wallHeight/2, 0)
	eastWall.Anchored = true
	eastWall.CanCollide = true
	eastWall.Material = Enum.Material.Concrete
	eastWall.Color = Color3.fromRGB(80, 80, 90)
	eastWall.Parent = lobbyModel
	
	-- West wall
	local westWall = Instance.new("Part")
	westWall.Name = "WestWall"
	westWall.Size = Vector3.new(wallThickness, wallHeight, LOBBY_SIZE.Z)
	westWall.Position = LOBBY_POSITION + Vector3.new(-LOBBY_SIZE.X/2, wallHeight/2, 0)
	westWall.Anchored = true
	westWall.CanCollide = true
	westWall.Material = Enum.Material.Concrete
	westWall.Color = Color3.fromRGB(80, 80, 90)
	westWall.Parent = lobbyModel
	
	-- Add some lighting
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 60
	light.Color = Color3.fromRGB(255, 255, 200)
	light.Parent = platform
	
	-- Parent to workspace
	lobbyModel.Parent = workspace
	self.lobbyModel = lobbyModel
	
	print("[LobbySetup] Lobby created at position", LOBBY_POSITION)
	return lobbyModel
end

-- Get the lobby spawn position
function LobbySetup:getLobbySpawnPosition()
	return LOBBY_POSITION + Vector3.new(0, 5, 0)
end

-- Clean up the lobby
function LobbySetup:cleanup()
	if self.lobbyModel and self.lobbyModel.Parent then
		self.lobbyModel:Destroy()
	end
	self.lobbyModel = nil
end

return LobbySetup
