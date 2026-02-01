--!strict
-- @ScriptType: ModuleScript
-- RemoteRegistry.lua
-- Single source of truth for all RemoteEvents and RemoteFunctions in the game
-- Server creates remotes on boot, client waits for them with timeouts
-- Version: 1.0

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteRegistry = {}

-- Version for compatibility checking
RemoteRegistry.VERSION = "1.0.0"

-- Log prefix for consistent logging
local LOG_PREFIX = "[RemoteRegistry]"

--[[
	CANONICAL REMOTE DEFINITIONS
	All remotes used in the game must be defined here.
	Format: {Name = "EventName", Type = "Event" | "Function"}
]]
local REMOTE_DEFINITIONS = {
	-- Animation replication (FPS system)
	{Name = "AnimationFire", Type = "Event"},
	{Name = "AnimationSprint", Type = "Event"},
	{Name = "AnimationADS", Type = "Event"},
	{Name = "AnimationFireReplicate", Type = "Event"},
	{Name = "AnimationSprintReplicate", Type = "Event"},
	{Name = "AnimationADSReplicate", Type = "Event"},
	
	-- Game state and waves
	{Name = "WaveAnnounce", Type = "Event"},
	{Name = "WaveUpdate", Type = "Event"},
	{Name = "GameStateUpdate", Type = "Event"},
	
	-- Cure system
	{Name = "CureUpdate", Type = "Event"},
	{Name = "CureProgress", Type = "Event"},
	
	-- Base and map
	{Name = "BaseHealthUpdate", Type = "Event"},
	{Name = "MapUpdate", Type = "Event"},
	
	-- UI state management
	{Name = "ShowScoreboard", Type = "Event"},
	{Name = "HideScoreboard", Type = "Event"},
	{Name = "ScoreboardUpdate", Type = "Event"},
	{Name = "ShowTitleScreen", Type = "Event"},
	{Name = "HideTitleScreen", Type = "Event"},
	{Name = "TitleScreenContinue", Type = "Event"},
	{Name = "ShowEpilogue", Type = "Event"},
	{Name = "HideEpilogue", Type = "Event"},
	{Name = "EpilogueComplete", Type = "Event"},
	{Name = "ShowCredits", Type = "Event"},
	{Name = "HideCredits", Type = "Event"},
	
	-- Player systems
	{Name = "AchievementUnlocked", Type = "Event"},
	{Name = "BetrayalStarted", Type = "Event"},
	{Name = "SpectatorCycleTarget", Type = "Event"},
	{Name = "SprintRequest", Type = "Event"},
	
	-- Matchmaking and lobby
	{Name = "PortalQueueUpdate", Type = "Event"},
	{Name = "LobbyVoteUpdate", Type = "Event"},
	
	-- Puzzle and items
	{Name = "PuzzlePickup", Type = "Event"},
	{Name = "PuzzleSubmit", Type = "Event"},
	{Name = "ItemPickup", Type = "Event"},
	
	-- Weapons and combat
	{Name = "WeaponFire", Type = "Event"},
	{Name = "WeaponReload", Type = "Event"},
	{Name = "WeaponEquip", Type = "Event"},
	{Name = "DealDamage", Type = "Event"},
	
	-- Shop and economy
	{Name = "ShopPurchase", Type = "Event"},
	{Name = "ShopOpen", Type = "Event"},
	{Name = "ShopClose", Type = "Event"},
	
	-- Alliance system
	{Name = "AllianceRequest", Type = "Event"},
	{Name = "AllianceAccept", Type = "Event"},
	{Name = "AllianceDecline", Type = "Event"},
	{Name = "AllianceDisband", Type = "Event"},
	{Name = "AllianceUpdate", Type = "Event"},
	
	-- Fun facts
	{Name = "FunFactUpdate", Type = "Event"},
}

-- Private: Get or create the RemoteEvents folder
local function getOrCreateRemoteEventsFolder(): Folder
	local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "RemoteEvents"
		folder.Parent = ReplicatedStorage
		print(string.format("%s Created RemoteEvents folder", LOG_PREFIX))
	end
	return folder
end

-- Private: Clean up duplicate instances with the same name
local function cleanupDuplicates(folder: Folder, name: string)
	local instances = {}
	for _, child in ipairs(folder:GetChildren()) do
		if child.Name == name then
			table.insert(instances, child)
		end
	end
	
	-- Keep first valid instance, destroy others
	if #instances > 1 then
		local kept = instances[1]
		for i = 2, #instances do
			warn(string.format("%s Destroying duplicate '%s' (keeping first)", LOG_PREFIX, name))
			instances[i]:Destroy()
		end
	end
end

-- Private: Ensure a remote exists and is the correct type
local function ensureRemote(folder: Folder, name: string, remoteType: string): RemoteEvent | RemoteFunction
	local existing = folder:FindFirstChild(name)
	
	-- Check if exists and is correct type
	local expectedClass = remoteType == "Event" and "RemoteEvent" or "RemoteFunction"
	
	if existing then
		if existing:IsA(expectedClass) then
			return existing :: any
		else
			-- Wrong type, destroy and recreate
			warn(string.format("%s '%s' exists but is wrong type (%s, expected %s). Recreating.", 
				LOG_PREFIX, name, existing.ClassName, expectedClass))
			existing:Destroy()
		end
	end
	
	-- Create new remote
	local remote
	if remoteType == "Event" then
		remote = Instance.new("RemoteEvent")
	else
		remote = Instance.new("RemoteFunction")
	end
	remote.Name = name
	remote.Parent = folder
	
	return remote :: any
end

--[[
	SERVER: Initialize all remotes
	Call this from server entry point before any services start
	Returns: table of remotes by name
]]
function RemoteRegistry.initializeServer()
	if not RunService:IsServer() then
		error(string.format("%s initializeServer() must only be called from the server", LOG_PREFIX))
	end
	
	print(string.format("%s [BOOT][SERVER] Initializing remote registry (version %s)", LOG_PREFIX, RemoteRegistry.VERSION))
	
	local folder = getOrCreateRemoteEventsFolder()
	local remotes = {}
	local created = 0
	local existing = 0
	
	-- Create or validate each remote
	for _, def in ipairs(REMOTE_DEFINITIONS) do
		cleanupDuplicates(folder, def.Name)
		local wasExisting = folder:FindFirstChild(def.Name) ~= nil
		
		local remote = ensureRemote(folder, def.Name, def.Type)
		remotes[def.Name] = remote
		
		if wasExisting then
			existing = existing + 1
		else
			created = created + 1
		end
	end
	
	-- Check for unexpected remotes (not in definition list)
	local definedNames = {}
	for _, def in ipairs(REMOTE_DEFINITIONS) do
		definedNames[def.Name] = true
	end
	
	local unexpected = 0
	for _, child in ipairs(folder:GetChildren()) do
		if not definedNames[child.Name] then
			warn(string.format("%s Unexpected remote '%s' found (not in registry). Consider adding to RemoteRegistry.", 
				LOG_PREFIX, child.Name))
			unexpected = unexpected + 1
		end
	end
	
	print(string.format("%s [BOOT][SERVER] Registry initialized: %d created, %d existing, %d unexpected, %d total", 
		LOG_PREFIX, created, existing, unexpected, #REMOTE_DEFINITIONS))
	
	return remotes
end

--[[
	CLIENT: Wait for all remotes with timeout
	Call this from client entry point during boot
	Returns: table of remotes by name, or nil if timeout
]]
function RemoteRegistry.initializeClient(timeout: number?): {[string]: RemoteEvent | RemoteFunction}?
	if not RunService:IsClient() then
		error(string.format("%s initializeClient() must only be called from the client", LOG_PREFIX))
	end
	
	local actualTimeout = timeout or 10
	print(string.format("%s [BOOT][CLIENT] Waiting for remote registry (timeout: %ds)", LOG_PREFIX, actualTimeout))
	
	local folder = ReplicatedStorage:WaitForChild("RemoteEvents", actualTimeout)
	if not folder then
		error(string.format("%s [BOOT][CLIENT] CRITICAL: RemoteEvents folder not found after %ds", LOG_PREFIX, actualTimeout))
	end
	
	local remotes = {}
	local missing = {}
	
	-- Wait for each remote
	for _, def in ipairs(REMOTE_DEFINITIONS) do
		local remote = folder:WaitForChild(def.Name, actualTimeout)
		if remote then
			remotes[def.Name] = remote
		else
			table.insert(missing, def.Name)
		end
	end
	
	if #missing > 0 then
		error(string.format("%s [BOOT][CLIENT] CRITICAL: Missing remotes after %ds: %s", 
			LOG_PREFIX, actualTimeout, table.concat(missing, ", ")))
	end
	
	print(string.format("%s [BOOT][CLIENT] Registry initialized: %d remotes ready", LOG_PREFIX, #REMOTE_DEFINITIONS))
	
	return remotes
end

--[[
	Get a remote by name (for use after initialization)
	This is a convenience method for systems that need individual remotes
]]
function RemoteRegistry.getRemote(name: string): RemoteEvent | RemoteFunction
	local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not folder then
		error(string.format("%s RemoteEvents folder not found. Did you call initialize?", LOG_PREFIX))
	end
	
	local remote = folder:FindFirstChild(name)
	if not remote then
		error(string.format("%s Remote '%s' not found. Is it defined in RemoteRegistry?", LOG_PREFIX, name))
	end
	
	return remote :: any
end

--[[
	Get all remote names (useful for debugging)
]]
function RemoteRegistry.getAllRemoteNames(): {string}
	local names = {}
	for _, def in ipairs(REMOTE_DEFINITIONS) do
		table.insert(names, def.Name)
	end
	return names
end

return RemoteRegistry
