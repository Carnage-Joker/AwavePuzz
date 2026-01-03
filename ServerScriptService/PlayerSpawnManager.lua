-- PlayerSpawnManager.lua
-- Manages player character spawning to ensure players spawn in lobby first, then on the map after voting
-- Integrates with GameManager and LobbyManager to control spawn timing
-- In lobby state, players have no character (menu-only mode)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerSpawnManager = {}
PlayerSpawnManager.__index = PlayerSpawnManager

-- Spawn locations
local MAP_OFFSET = Vector3.new(5000, 0, 0) -- Maps are loaded at this offset

function PlayerSpawnManager.new()
	local self = setmetatable({}, PlayerSpawnManager)
	
	-- Track which players have spawned on the map
	self.playersSpawnedOnMap = {} -- userId -> boolean
	
	-- Track player spawn state
	self.playerSpawnState = {} -- userId -> "waiting" | "map" | "dead"
	
	-- Reference to GameManager (set later)
	self.gameManager = nil
	
	-- Store player connections to manage character spawning
	self.playerConnections = {} -- userId -> connection
	
	return self
end

function PlayerSpawnManager:setGameManager(gameManager)
	self.gameManager = gameManager
end

-- Initialize player spawning - called when player joins
function PlayerSpawnManager:onPlayerAdded(player)
	print(string.format("[PlayerSpawnManager] Player %s added, holding in menu-only lobby", player.Name))
	
	-- Initialize spawn state to waiting (no character)
	self.playerSpawnState[player.UserId] = "waiting"
	self.playersSpawnedOnMap[player.UserId] = false
	
	-- Prevent character from auto-loading by destroying it immediately
	if player.Character then
		player.Character:Destroy()
	end
	
	-- Connect to character added event to manage spawning
	local connection = player.CharacterAdded:Connect(function(character)
		self:onCharacterAdded(player, character)
	end)
	
	self.playerConnections[player.UserId] = connection
end

-- Handle character added event
function PlayerSpawnManager:onCharacterAdded(player, character)
	local spawnState = self.playerSpawnState[player.UserId]
	
	print(string.format("[PlayerSpawnManager] Character added for %s, state: %s", player.Name, tostring(spawnState)))
	
	-- If player is in waiting state (lobby), destroy the character
	-- They should only have a character when spawning on the map
	if spawnState == "waiting" then
		print(string.format("[PlayerSpawnManager] Player %s is in waiting state, removing character (menu-only mode)", player.Name))
		character:Destroy()
		return
	end
	
	-- Wait for character to fully load
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoidRootPart then
		warn(string.format("[PlayerSpawnManager] Failed to get HumanoidRootPart for %s", player.Name))
		return
	end
	
	-- Position character based on current spawn state
	if spawnState == "map" then
		-- Player should spawn on the map
		local spawnPosition = self:getMapSpawnPosition()
		humanoidRootPart.CFrame = CFrame.new(spawnPosition)
		print(string.format("[PlayerSpawnManager] Positioned %s on map at %s", player.Name, tostring(spawnPosition)))
		
		-- Set camera to first-person
		self:setFirstPersonCamera(player)
	end
end

-- Keep player in menu-only lobby state (no character)
function PlayerSpawnManager:keepPlayerInLobby(player)
	print(string.format("[PlayerSpawnManager] Keeping %s in menu-only lobby", player.Name))
	
	self.playerSpawnState[player.UserId] = "waiting"
	
	-- Destroy character if it exists
	if player.Character then
		player.Character:Destroy()
	end
end

-- Spawn player on the map after voting completes
function PlayerSpawnManager:spawnPlayerOnMap(player)
	print(string.format("[PlayerSpawnManager] Spawning %s on map", player.Name))
	
	self.playerSpawnState[player.UserId] = "map"
	self.playersSpawnedOnMap[player.UserId] = true
	
	-- Load character to spawn them on the map
	player:LoadCharacter()
end

-- Spawn all players on the map (called when map voting completes)
function PlayerSpawnManager:spawnAllPlayersOnMap()
	print("[PlayerSpawnManager] Spawning all players on map")
	
	for _, player in ipairs(Players:GetPlayers()) do
		-- Only spawn players who haven't been spawned on map yet
		if not self.playersSpawnedOnMap[player.UserId] then
			self:spawnPlayerOnMap(player)
		end
	end
end

-- Get spawn position on the map
function PlayerSpawnManager:getMapSpawnPosition()
	-- Get base camp position from GameManager if available
	if self.gameManager and self.gameManager.baseManager then
		local baseManager = self.gameManager.baseManager
		local baseCamp = workspace:FindFirstChild("BaseCamp")
		
		if baseCamp and baseCamp.PrimaryPart then
			-- Spawn near base camp
			local baseCampPos = baseCamp.PrimaryPart.Position
			-- Add some randomness to spread out players
			local offset = Vector3.new(
				math.random(-10, 10),
				5,
				math.random(-10, 10)
			)
			return baseCampPos + offset
		end
	end
	
	-- Fallback: spawn at map offset with some height
	return MAP_OFFSET + Vector3.new(0, 10, 0)
end

-- Set player camera to first-person mode
function PlayerSpawnManager:setFirstPersonCamera(player)
	-- Set camera mode via player properties
	if player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
			-- Set camera to first person
			player.CameraMode = Enum.CameraMode.LockFirstPerson
			player.CameraMaxZoomDistance = 0.5
			player.CameraMinZoomDistance = 0.5
			
			print(string.format("[PlayerSpawnManager] Set first-person camera for %s", player.Name))
		end
	end
end

-- Reset player spawn state for new round
function PlayerSpawnManager:resetForNewRound()
	print("[PlayerSpawnManager] Resetting for new round")
	
	-- Clear spawn tracking
	self.playersSpawnedOnMap = {}
	
	-- Reset all players to waiting state (no character)
	for userId, _ in pairs(self.playerSpawnState) do
		self.playerSpawnState[userId] = "waiting"
	end
end

-- Handle player leaving
function PlayerSpawnManager:onPlayerRemoving(player)
	self.playersSpawnedOnMap[player.UserId] = nil
	self.playerSpawnState[player.UserId] = nil
	
	-- Disconnect character added connection
	if self.playerConnections[player.UserId] then
		self.playerConnections[player.UserId]:Disconnect()
		self.playerConnections[player.UserId] = nil
	end
end

-- Check if player has spawned on map
function PlayerSpawnManager:hasPlayerSpawnedOnMap(player)
	return self.playersSpawnedOnMap[player.UserId] or false
end

-- Get current spawn state for a player
function PlayerSpawnManager:getPlayerSpawnState(player)
	return self.playerSpawnState[player.UserId] or "waiting"
end

return PlayerSpawnManager
