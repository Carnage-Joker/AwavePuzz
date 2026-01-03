-- PlayerSpawnManager.lua
-- Manages player character spawning to ensure players spawn in lobby first, then on the map after voting
-- Integrates with GameManager and LobbyManager to control spawn timing

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
	self.playerSpawnState = {} -- userId -> "lobby" | "map" | "dead"
	
	-- Reference to GameManager (set later)
	self.gameManager = nil
	
	-- Lobby spawn position (will be retrieved from LobbySetup)
	self.lobbySpawnPosition = Vector3.new(0, 10, 0) -- Default fallback
	
	return self
end

function PlayerSpawnManager:setGameManager(gameManager)
	self.gameManager = gameManager
	
	-- Get lobby spawn position from LobbySetup if available
	if gameManager.lobbySetup and gameManager.lobbySetup.getLobbySpawnPosition then
		self.lobbySpawnPosition = gameManager.lobbySetup:getLobbySpawnPosition()
		print("[PlayerSpawnManager] Set lobby spawn position to", self.lobbySpawnPosition)
	end
end

-- Initialize player spawning - called when player joins
function PlayerSpawnManager:onPlayerAdded(player)
	-- Disable automatic character spawning
	-- Note: This must be done before the player's character loads
	-- In practice, we'll manage this through custom spawn handling
	
	print(string.format("[PlayerSpawnManager] Player %s added, preparing for lobby spawn", player.Name))
	
	-- Initialize spawn state
	self.playerSpawnState[player.UserId] = "none"
	self.playersSpawnedOnMap[player.UserId] = false
	
	-- Connect to character added event to manage spawning
	player.CharacterAdded:Connect(function(character)
		self:onCharacterAdded(player, character)
	end)
	
	-- Spawn player in lobby initially
	self:spawnPlayerInLobby(player)
end

-- Handle character added event
function PlayerSpawnManager:onCharacterAdded(player, character)
	local spawnState = self.playerSpawnState[player.UserId]
	
	print(string.format("[PlayerSpawnManager] Character added for %s, state: %s", player.Name, tostring(spawnState)))
	
	-- Wait for character to fully load
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoidRootPart then
		warn(string.format("[PlayerSpawnManager] Failed to get HumanoidRootPart for %s", player.Name))
		return
	end
	
	-- Position character based on current spawn state
	if spawnState == "lobby" then
		-- Player is in lobby, position at lobby spawn
		humanoidRootPart.CFrame = CFrame.new(self.lobbySpawnPosition)
		print(string.format("[PlayerSpawnManager] Positioned %s in lobby", player.Name))
		
	elseif spawnState == "map" then
		-- Player should spawn on the map
		local spawnPosition = self:getMapSpawnPosition()
		humanoidRootPart.CFrame = CFrame.new(spawnPosition)
		print(string.format("[PlayerSpawnManager] Positioned %s on map at %s", player.Name, tostring(spawnPosition)))
		
		-- Set camera to first-person
		self:setFirstPersonCamera(player)
	end
end

-- Spawn player in lobby (waiting area before map voting completes)
function PlayerSpawnManager:spawnPlayerInLobby(player)
	print(string.format("[PlayerSpawnManager] Spawning %s in lobby", player.Name))
	
	self.playerSpawnState[player.UserId] = "lobby"
	
	-- Load character if it doesn't exist
	if not player.Character then
		player:LoadCharacter()
	else
		-- Character already exists, just reposition it
		local character = player.Character
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			humanoidRootPart.CFrame = CFrame.new(self.lobbySpawnPosition)
		end
	end
end

-- Spawn player on the map after voting completes
function PlayerSpawnManager:spawnPlayerOnMap(player)
	print(string.format("[PlayerSpawnManager] Spawning %s on map", player.Name))
	
	self.playerSpawnState[player.UserId] = "map"
	self.playersSpawnedOnMap[player.UserId] = true
	
	-- Reload character to spawn them on the map
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
	
	-- Reset all players to lobby state
	for userId, _ in pairs(self.playerSpawnState) do
		self.playerSpawnState[userId] = "none"
	end
end

-- Handle player leaving
function PlayerSpawnManager:onPlayerRemoving(player)
	self.playersSpawnedOnMap[player.UserId] = nil
	self.playerSpawnState[player.UserId] = nil
end

-- Check if player has spawned on map
function PlayerSpawnManager:hasPlayerSpawnedOnMap(player)
	return self.playersSpawnedOnMap[player.UserId] or false
end

-- Get current spawn state for a player
function PlayerSpawnManager:getPlayerSpawnState(player)
	return self.playerSpawnState[player.UserId] or "none"
end

return PlayerSpawnManager
