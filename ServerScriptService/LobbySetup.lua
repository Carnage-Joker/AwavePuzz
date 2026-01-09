-- @ScriptType: ModuleScript
-- LobbySetup.lua
-- Creates a simple lobby area at the map offset so players can wait during title/epilogue/voting.
-- Exposes LOBBY_POSITION for PlayerSpawnManager.

local Workspace = game:GetService("Workspace")

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

function LobbySetup:createLobby()
	print("[LobbySetup] Creating lobby area")

	-- Destroy old lobby if present
	if self.lobbyModel and self.lobbyModel.Parent then
		self.lobbyModel:Destroy()
	end

	-- Also clear stray lobby models (defensive)
	local existing = Workspace:FindFirstChild(LOBBY_MODEL_NAME)
	if existing then
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
end

return LobbySetup
