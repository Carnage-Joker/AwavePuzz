-- @ScriptType: ModuleScript
-- LobbySetup.lua
-- Creates a simple lobby area at the map offset so players can wait during title/epilogue/voting.
-- Exposes LOBBY_POSITION for PlayerSpawnManager.
-- Now includes portal creation for portal matchmaking system.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load configs
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
local GameConfig = Shared and require(Shared:WaitForChild("GameConfig", 5))
local PortalConfig = Shared and require(Shared:WaitForChild("PortalConfig", 5))

local LobbySetup = {}
LobbySetup.__index = LobbySetup

-- Map pivot offset
local MAP_OFFSET = Vector3.new(5000, 0, 0)

-- ✅ Lobby is 3000 studs away from map pivot (Option B)
local LOBBY_OFFSET = Vector3.new(3000, 0, 0)
local LOBBY_BASE = MAP_OFFSET + LOBBY_OFFSET

-- Public constant used by PlayerSpawnManager (standing height on platform)
LobbySetup.LOBBY_POSITION = LOBBY_BASE + Vector3.new(0, 8, 0)

local LOBBY_MODEL_NAME = "LobbyArea"

function LobbySetup.new()
	local self = setmetatable({}, LobbySetup)
	self.lobbyModel = nil
	return self
end

-- Get or create lobby (idempotent)
-- Reuses existing lobby if found, or creates a new one if needed
function LobbySetup:getOrCreateLobby()
	-- Check if we already have a valid lobby
	if self.lobbyModel and self.lobbyModel.Parent then
		print("[LobbySetup] Reusing existing lobby")
		return self.lobbyModel
	end
	
	-- Check for existing lobby in Workspace
	local existing = Workspace:FindFirstChild(LOBBY_MODEL_NAME)
	if existing then
		print("[LobbySetup] Reusing existing lobby from Workspace")
		self.lobbyModel = existing
		return self.lobbyModel
	end
	
	-- No existing lobby, create a new one
	return self:createLobby()
end

function LobbySetup:createLobby()
	print("[LobbySetup] Creating lobby area")

	-- Destroy old lobby if present
	if self.lobbyModel and self.lobbyModel.Parent then
		print("[LobbySetup] Destroying stale lobby")
		self.lobbyModel:Destroy()
	end

	-- Also clear stray lobby models (defensive)
	local existing = Workspace:FindFirstChild(LOBBY_MODEL_NAME)
	if existing then
		print("[LobbySetup] Destroying stale lobby from Workspace")
		existing:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = LOBBY_MODEL_NAME

	-- Platform
	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Anchored = true
	platform.CanCollide = true
	platform.Size = Vector3.new(60, 2, 60)
	platform.Position = LOBBY_BASE + Vector3.new(0, 5, 0)
	platform.TopSurface = Enum.SurfaceType.Smooth
	platform.BottomSurface = Enum.SurfaceType.Smooth
	platform.Parent = model

	-- Simple walls (optional, helps stop sliding off)
	local function wall(name, size, pos)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = true
		p.Size = size
		p.Position = pos
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end

	wall("Wall_N", Vector3.new(60, 12, 2), platform.Position + Vector3.new(0, 6, 31))
	wall("Wall_S", Vector3.new(60, 12, 2), platform.Position + Vector3.new(0, 6, -31))
	wall("Wall_E", Vector3.new(2, 12, 60), platform.Position + Vector3.new(31, 6, 0))
	wall("Wall_W", Vector3.new(2, 12, 60), platform.Position + Vector3.new(-31, 6, 0))

	-- SpawnLocation (optional)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = platform.Position + Vector3.new(0, 2, 0)
	spawn.Transparency = 1
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = model

	model.Parent = Workspace

	self.lobbyModel = model
	print(string.format("[LobbySetup] Lobby created at position %d, %d, %d", LOBBY_BASE.X, 5, LOBBY_BASE.Z))
	
	-- Create portals if portal matchmaking is enabled
	if GameConfig and GameConfig.USE_PORTAL_MATCHMAKING then
		self:createPortals()
	end
	
	return model
end

-- Create portal system for matchmaking
function LobbySetup:createPortals()
	if not PortalConfig then
		warn("[LobbySetup] Cannot create portals - PortalConfig not loaded")
		return
	end
	
	print("[LobbySetup] Creating portals for matchmaking")
	
	-- Create or get Lobby folder in workspace
	local lobby = Workspace:FindFirstChild("Lobby")
	if not lobby then
		lobby = Instance.new("Folder")
		lobby.Name = "Lobby"
		lobby.Parent = Workspace
	end
	
	-- Create or clear Portals folder
	local portalsFolder = lobby:FindFirstChild("Portals")
	if portalsFolder then
		portalsFolder:ClearAllChildren()
	else
		portalsFolder = Instance.new("Folder")
		portalsFolder.Name = "Portals"
		portalsFolder.Parent = lobby
	end
	
	-- Portal positions (spread across the lobby platform)
	local portalPositions = {
		Vector3.new(-20, 12, 0),  -- Left
		Vector3.new(0, 12, 0),    -- Center
		Vector3.new(20, 12, 0),   -- Right
	}
	
	-- Create portals for each map
	local portalTypes
	
	-- Prefer portal definitions from PortalConfig if available
	if PortalConfig then
		if type(PortalConfig.getAllPortalTypes) == "function" then
			portalTypes = PortalConfig.getAllPortalTypes()
		end
	end
	
	-- Fallback to built-in defaults if config does not provide a usable list
	if type(portalTypes) ~= "table" or #portalTypes == 0 then
		portalTypes = {
			{ id = "ResearchOutpost", mapId = "ResearchOutpost", name = "Research Outpost" },
			{ id = "Random", mapId = "Random", name = "Random Map" },
			{ id = "Village", mapId = "Village", name = "Village" },
		}
	end
	
	for i, portalInfo in ipairs(portalTypes) do
		if portalPositions[i] then
			local portal = self:createPortal(
				portalInfo.id,
				portalInfo.mapId,
				portalInfo.name,
				LOBBY_BASE + portalPositions[i]
			)
			portal.Parent = portalsFolder
		end
	end
	
	print(string.format("[LobbySetup] Created %d portals", #portalTypes))
end

-- Create a single portal
function LobbySetup:createPortal(portalId, mapId, displayName, position)
	local portal = Instance.new("Model")
	portal.Name = portalId
	
	-- Main portal part (touchable)
	local touchPart = Instance.new("Part")
	touchPart.Name = "TouchPart"
	touchPart.Size = Vector3.new(8, 10, 2)
	touchPart.Position = position
	touchPart.Anchored = true
	touchPart.CanCollide = false
	touchPart.Transparency = 0.3
	touchPart.BrickColor = BrickColor.new("Bright blue")
	touchPart.Material = Enum.Material.Neon
	touchPart.Parent = portal
	
	-- Portal frame (visual)
	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Size = Vector3.new(10, 12, 0.5)
	frame.Position = position
	frame.Anchored = true
	frame.CanCollide = false
	frame.BrickColor = BrickColor.new("Dark stone grey")
	frame.Material = Enum.Material.Metal
	frame.Parent = portal
	
	-- Set portal attributes
	portal:SetAttribute("PortalId", portalId)
	portal:SetAttribute("MapId", mapId)
	
	-- Use shared matchmaking defaults from GameConfig, with safe fallbacks
	local matchmakingConfig = GameConfig and GameConfig.PORTAL_MATCHMAKING
	local minPlayers = (matchmakingConfig and matchmakingConfig.DEFAULT_MIN_PLAYERS) or 1
	local countdownSeconds = (matchmakingConfig and matchmakingConfig.DEFAULT_COUNTDOWN_TIME) or 10
	
	portal:SetAttribute("MinPlayers", minPlayers)
	portal:SetAttribute("CountdownSeconds", countdownSeconds)
	
	-- Add billboard GUI for queue status
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "QueueIndicator"
	billboard.Size = UDim2.new(6, 0, 3, 0)
	billboard.StudsOffset = Vector3.new(0, 6, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = touchPart
	
	-- Title label
	local titleFrame = Instance.new("Frame")
	titleFrame.Size = UDim2.new(1, 0, 0.3, 0)
	titleFrame.Position = UDim2.new(0, 0, 0, 0)
	titleFrame.BackgroundTransparency = 0.2
	titleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	titleFrame.Parent = billboard
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = displayName
	titleLabel.Parent = titleFrame
	
	-- Status label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 0.7, 0)
	statusLabel.Position = UDim2.new(0, 0, 0.3, 0)
	statusLabel.BackgroundTransparency = 0.3
	statusLabel.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
	statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.Text = "0/8"
	statusLabel.Parent = billboard
	
	local corner1 = Instance.new("UICorner")
	corner1.CornerRadius = UDim.new(0, 8)
	corner1.Parent = titleFrame
	
	local corner2 = Instance.new("UICorner")
	corner2.CornerRadius = UDim.new(0, 8)
	corner2.Parent = statusLabel
	
	-- Set primary part for model
	portal.PrimaryPart = touchPart
	
	print(string.format("[LobbySetup] Created portal: %s (Map: %s)", portalId, mapId))
	
	return portal
end

function LobbySetup:cleanup()
	if self.lobbyModel and self.lobbyModel.Parent then
		self.lobbyModel:Destroy()
	end
	self.lobbyModel = nil

	local existing = Workspace:FindFirstChild(LOBBY_MODEL_NAME)
	if existing then
		existing:Destroy()
	end
	
	-- Clean up portals if they exist
	local lobby = Workspace:FindFirstChild("Lobby")
	if lobby then
		local portalsFolder = lobby:FindFirstChild("Portals")
		if portalsFolder then
			portalsFolder:Destroy()
		end
	end
end

return LobbySetup
