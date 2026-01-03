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
	
	-- Store original transparency values for proper restoration
	self.originalTransparency = {} -- userId -> { [part] = transparency }
	
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
	print(string.format("[PlayerSpawnManager] Player %s added, preparing spawn management", player.Name))
	
	-- Initialize spawn state to waiting (lobby mode)
	self.playerSpawnState[player.UserId] = "waiting"
	self.playersSpawnedOnMap[player.UserId] = false
	
	-- Connect to character added event to manage spawning
	local connection = player.CharacterAdded:Connect(function(character)
		self:onCharacterAdded(player, character)
	end)
	
	self.playerConnections[player.UserId] = connection
	
	-- If player already has a character, handle it immediately
	if player.Character then
		self:onCharacterAdded(player, player.Character)
	end
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
	if spawnState == "waiting" then
		-- Player is in waiting/lobby state - put them in a safe location far away
		-- This effectively makes them invisible to the game while in lobby
		local lobbyPosition = Vector3.new(5000, 10000, 0) -- High in the sky at X=5000
		humanoidRootPart.CFrame = CFrame.new(lobbyPosition)
		
		-- Store original transparency values before modifying
		if not self.originalTransparency[player.UserId] then
			self.originalTransparency[player.UserId] = {}
		end
		
		-- Make them essentially invisible/non-interactive
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				-- Store original transparency
				self.originalTransparency[player.UserId][part] = part.Transparency
				
				part.CanCollide = false
				part.Transparency = 1
			end
		end
		
		print(string.format("[PlayerSpawnManager] Positioned %s in lobby waiting area (high above map)", player.Name))
		
	elseif spawnState == "map" then
		-- Player should spawn on the map
		local spawnPosition = self:getMapSpawnPosition()
		humanoidRootPart.CFrame = CFrame.new(spawnPosition)
		
		-- Restore visibility and collision for all character parts
		local storedTransparency = self.originalTransparency[player.UserId] or {}
		
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				-- Restore collision for all parts except HumanoidRootPart
				if part ~= humanoidRootPart then
					part.CanCollide = true
				end
				
				-- Restore original transparency if we stored it, otherwise set to 0
				if storedTransparency[part] ~= nil then
					part.Transparency = storedTransparency[part]
				else
					-- Default to visible for character parts
					-- Most body parts should be visible (transparency = 0)
					part.Transparency = 0
				end
			end
		end
		
		-- Note: Don't clear stored transparency yet - keep it for potential respawns during the round
		
		print(string.format("[PlayerSpawnManager] Positioned %s on map at %s", player.Name, tostring(spawnPosition)))
		
		-- Note: First-person camera is handled by the FPS system on the client side
	end
end

-- Keep player in lobby waiting state
function PlayerSpawnManager:keepPlayerInLobby(player)
	print(string.format("[PlayerSpawnManager] Keeping %s in lobby waiting state", player.Name))
	
	self.playerSpawnState[player.UserId] = "waiting"
	
	-- If character exists, move it to lobby position
	if player.Character then
		local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local lobbyPosition = Vector3.new(5000, 10000, 0) -- High above map
			humanoidRootPart.CFrame = CFrame.new(lobbyPosition)
			
			-- Store original transparency values before modifying (only if not already stored)
			if not self.originalTransparency[player.UserId] then
				self.originalTransparency[player.UserId] = {}
				
				-- Store transparency values only on first call
				for _, part in ipairs(player.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						self.originalTransparency[player.UserId][part] = part.Transparency
					end
				end
			end
			
			-- Make invisible
			for _, part in ipairs(player.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
					part.Transparency = 1
				end
			end
		end
	end
end

-- Spawn player on the map after voting completes
function PlayerSpawnManager:spawnPlayerOnMap(player)
	print(string.format("[PlayerSpawnManager] Spawning %s on map", player.Name))
	
	-- Clear any stored transparency data tied to the old lobby character
	self.originalTransparency[player.UserId] = nil
	
	-- Mark that this player has been spawned onto the map
	self.playersSpawnedOnMap[player.UserId] = true
	
	-- Load character to spawn them on the map (this destroys the old character)
	player:LoadCharacter()
	
	-- After initiating the character load, set the spawn state to map
	self.playerSpawnState[player.UserId] = "map"
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
		local baseCamp = workspace:FindFirstChild("BaseCamp")
		
		if baseCamp then
			-- Try to get position from PrimaryPart
			if baseCamp.PrimaryPart then
				local baseCampPos = baseCamp.PrimaryPart.Position
				-- Add some randomness to spread out players
				local offset = Vector3.new(
					math.random(-10, 10),
					5,
					math.random(-10, 10)
				)
				return baseCampPos + offset
			else
				-- Fallback: find any BasePart in BaseCamp to get position
				for _, child in ipairs(baseCamp:GetChildren()) do
					if child:IsA("BasePart") then
						local baseCampPos = child.Position
						local offset = Vector3.new(
							math.random(-10, 10),
							5,
							math.random(-10, 10)
						)
						return baseCampPos + offset
					end
				end
			end
		end
	end
	
	-- Fallback: spawn at map offset with some height
	return MAP_OFFSET + Vector3.new(0, 10, 0)
end

-- Reset player spawn state for new round
function PlayerSpawnManager:resetForNewRound()
	print("[PlayerSpawnManager] Resetting for new round")
	
	-- Clear spawn tracking
	self.playersSpawnedOnMap = {}
	
	-- Clear stored transparency values for new round
	self.originalTransparency = {}
	
	-- Reset all players to waiting state
	for userId, _ in pairs(self.playerSpawnState) do
		self.playerSpawnState[userId] = "waiting"
	end
end

-- Handle player leaving
function PlayerSpawnManager:onPlayerRemoving(player)
	self.playersSpawnedOnMap[player.UserId] = nil
	self.playerSpawnState[player.UserId] = nil
	self.originalTransparency[player.UserId] = nil
	
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
