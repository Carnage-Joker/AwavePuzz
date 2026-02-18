--!strict
-- @ScriptType: ModuleScript
-- RemoteRegistry.lua
-- Single source of truth for all RemoteEvents and RemoteFunctions in the game
-- Server creates remotes on boot, client waits for them with timeouts
-- Version: 1.0.0

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteRegistry = {}

RemoteRegistry.VERSION = "1.0.0"
local LOG_PREFIX = "[RemoteRegistry]"

export type RemoteDef = {
	Name: string,
	Type: "Event" | "Function",
}

export type RemoteMap = { [string]: RemoteEvent | RemoteFunction }

local REMOTE_DEFINITIONS: { RemoteDef } = {
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
	-- Reserved for future client-server synchronization; currently unused on the client.
	{Name = "ClientReady", Type = "Event"},

	-- Cure system
	{Name = "CureUpdate", Type = "Event"},
	{Name = "CureProgress", Type = "Event"},
	{Name = "PlayerCureProgressUpdate", Type = "Event"},

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
	{Name = "SpectatorStateUpdate", Type = "Event"},
	{Name = "SpectatorTargetUpdate", Type = "Event"},
	{Name = "SprintRequest", Type = "Event"},
	{Name = "PlayerHealthUpdate", Type = "Event"},
	{Name = "StaminaUpdate", Type = "Event"},
	{Name = "EnterSpectatorMode", Type = "Event"},
	{Name = "ExitSpectatorMode", Type = "Event"},
	{Name = "CrouchUpdate", Type = "Event"}, -- Client movement crouch state updates

	-- Matchmaking and lobby
	{Name = "PortalQueueUpdate", Type = "Event"},
	{Name = "LobbyVoteUpdate", Type = "Event"},
	{Name = "LobbyStateUpdate", Type = "Event"},
	{Name = "MapVoteStart", Type = "Event"},
	{Name = "MapVoteUpdate", Type = "Event"},
	{Name = "MapVoteEnd", Type = "Event"},
	{Name = "CastMapVote", Type = "Event"},
	-- Legacy map voting API (used by LobbyManager) - kept for backward compatibility
	{Name = "MapVotingState", Type = "Event"},
	{Name = "MapVoteCast", Type = "Event"},
	{Name = "MapVotingUpdate", Type = "Event"},

	-- Puzzle and items
	{Name = "PuzzlePickup", Type = "Event"},
	{Name = "PuzzleSubmit", Type = "Event"},
	{Name = "ItemPickup", Type = "Event"},
	{Name = "PuzzleUpdate", Type = "Event"},
	{Name = "PuzzleCompleted", Type = "Event"},
	{Name = "PuzzleFailed", Type = "Event"},
	{Name = "OpenPuzzleUI", Type = "Event"},
	{Name = "RequestPuzzle", Type = "Event"},
	{Name = "RequestPuzzleProgress", Type = "Event"},
	{Name = "SubmitPuzzleAnswer", Type = "Event"},
	{Name = "OpenCureStationMenu", Type = "Event"}, -- Client requests to open cure station menu

	-- Weapons and combat
	{Name = "WeaponFire", Type = "Event"},
	{Name = "WeaponReload", Type = "Event"},
	{Name = "WeaponEquip", Type = "Event"},
	{Name = "WeaponHitConfirm", Type = "Event"},
	{Name = "WeaponLoadoutUpdate", Type = "Event"},
	{Name = "DealDamage", Type = "Event"},
	{Name = "AmmoUpdate", Type = "Event"},
	{Name = "ReloadConfirm", Type = "Event"}, -- Server confirmation for reload requests

	-- Shop and economy
	{Name = "ShopPurchase", Type = "Event"},
	{Name = "ShopOpen", Type = "Event"},
	{Name = "ShopClose", Type = "Event"},
	{Name = "ShopRequest", Type = "Event"},
	{Name = "ShopUpdate", Type = "Event"},
	{Name = "CurrencyUpdate", Type = "Event"},
	{Name = "InventoryUpdate", Type = "Event"},

	-- Alliance system (modern API)
	{Name = "AllianceRequest", Type = "Event"},
	{Name = "AllianceAccept", Type = "Event"},
	{Name = "AllianceDecline", Type = "Event"},
	{Name = "AllianceDisband", Type = "Event"},
	{Name = "AllianceUpdate", Type = "Event"},
	-- Alliance system (legacy API - kept for backward compatibility)
	{Name = "RequestAlliance", Type = "Event"},
	{Name = "RespondAlliance", Type = "Event"},
	{Name = "BreakAlliance", Type = "Event"},

	-- Fun facts
	{Name = "FunFactUpdate", Type = "Event"},
}

local function getOrCreateRemoteEventsFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if existing then
		if existing:IsA("Folder") then
			return existing
		end
		warn(string.format("%s RemoteEvents exists but is %s; destroying and recreating Folder", LOG_PREFIX, existing.ClassName))
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "RemoteEvents"
	folder.Parent = ReplicatedStorage
	print(string.format("%s Created RemoteEvents folder", LOG_PREFIX))
	return folder
end

local function cleanupDuplicates(folder: Folder, name: string)
	local instances: { Instance } = {}
	for _, child in ipairs(folder:GetChildren()) do
		if child.Name == name then
			table.insert(instances, child)
		end
	end

	if #instances > 1 then
		for i = 2, #instances do
			warn(string.format("%s Destroying duplicate '%s' (keeping first)", LOG_PREFIX, name))
			instances[i]:Destroy()
		end
	end
end

local function ensureRemote(folder: Folder, name: string, remoteType: "Event" | "Function"): RemoteEvent | RemoteFunction
	local existing: Instance? = folder:FindFirstChild(name)
	local expectedClass = (remoteType == "Event") and "RemoteEvent" or "RemoteFunction"

	if existing then
		if remoteType == "Event" and existing:IsA("RemoteEvent") then
			return existing :: RemoteEvent
		elseif remoteType == "Function" and existing:IsA("RemoteFunction") then
			return existing :: RemoteFunction
		end

		warn(string.format(
			"%s '%s' exists but is wrong type (%s, expected %s). Recreating.",
			LOG_PREFIX,
			name,
			existing.ClassName,
			expectedClass
		))
		existing:Destroy()
	end

	if remoteType == "Event" then
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		return remote
	else
		local remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = folder
		return remote
	end
end

function RemoteRegistry.initializeServer(): RemoteMap
	if not RunService:IsServer() then
		error(string.format("%s initializeServer() must only be called from the server", LOG_PREFIX))
	end

	print(string.format("%s [BOOT][SERVER] Initializing remote registry (version %s)", LOG_PREFIX, RemoteRegistry.VERSION))

	local folder = getOrCreateRemoteEventsFolder()
	local remotes: RemoteMap = {}
	local created = 0
	local existed = 0

	for _, def in ipairs(REMOTE_DEFINITIONS) do
		cleanupDuplicates(folder, def.Name)
		local wasExisting = folder:FindFirstChild(def.Name) ~= nil

		local remote = ensureRemote(folder, def.Name, def.Type)
		remotes[def.Name] = remote

		if wasExisting then
			existed += 1
		else
			created += 1
		end
	end

	local definedNames: { [string]: boolean } = {}
	for _, def in ipairs(REMOTE_DEFINITIONS) do
		definedNames[def.Name] = true
	end

	local unexpected = 0
	local unexpectedList: { string } = {}
	for _, child in ipairs(folder:GetChildren()) do
		if not definedNames[child.Name] then
			unexpected += 1
			table.insert(unexpectedList, child.Name)
		end
	end

	if unexpected > 0 then
		warn(string.format("%s Found %d unexpected remote(s) not in registry:", LOG_PREFIX, unexpected))
		warn(string.format("%s   %s", LOG_PREFIX, table.concat(unexpectedList, ", ")))
		warn(string.format("%s   Consider adding these to RemoteRegistry or moving to a legacy folder", LOG_PREFIX))
	end

	print(string.format(
		"%s [BOOT][SERVER] Registry initialized: %d created, %d existing, %d unexpected, %d total",
		LOG_PREFIX,
		created,
		existed,
		unexpected,
		#REMOTE_DEFINITIONS
	))

	return remotes
end

function RemoteRegistry.initializeClient(timeout: number?): RemoteMap
	if not RunService:IsClient() then
		error(string.format("%s initializeClient() must only be called from the client", LOG_PREFIX))
	end

	local actualTimeout = timeout or 10
	print(string.format("%s [BOOT][CLIENT] Waiting for remote registry (timeout: %ds)", LOG_PREFIX, actualTimeout))

	local folderInst = ReplicatedStorage:WaitForChild("RemoteEvents", actualTimeout)
	if not folderInst then
		error(string.format("%s [BOOT][CLIENT] CRITICAL: RemoteEvents folder not found after %ds", LOG_PREFIX, actualTimeout))
	end
	if not folderInst:IsA("Folder") then
		error(string.format("%s [BOOT][CLIENT] CRITICAL: RemoteEvents is not a Folder (got %s)", LOG_PREFIX, folderInst.ClassName))
	end
	local folder = folderInst :: Folder

	local remotes: RemoteMap = {}
	local missing: { string } = {}

	for _, def in ipairs(REMOTE_DEFINITIONS) do
		local remoteInst = folder:WaitForChild(def.Name, actualTimeout)
		if not remoteInst then
			table.insert(missing, def.Name)
			continue
		end

		if def.Type == "Event" then
			if remoteInst:IsA("RemoteEvent") then
				remotes[def.Name] = remoteInst
			else
				table.insert(missing, def.Name)
				warn(string.format("%s Remote '%s' exists but is %s (expected RemoteEvent)", LOG_PREFIX, def.Name, remoteInst.ClassName))
			end
		else
			if remoteInst:IsA("RemoteFunction") then
				remotes[def.Name] = remoteInst
			else
				table.insert(missing, def.Name)
				warn(string.format("%s Remote '%s' exists but is %s (expected RemoteFunction)", LOG_PREFIX, def.Name, remoteInst.ClassName))
			end
		end
	end

	if #missing > 0 then
		error(string.format(
			"%s [BOOT][CLIENT] CRITICAL: Missing/invalid remotes after %ds: %s",
			LOG_PREFIX,
			actualTimeout,
			table.concat(missing, ", ")
		))
	end

	print(string.format("%s [BOOT][CLIENT] Registry initialized: %d remotes ready", LOG_PREFIX, #REMOTE_DEFINITIONS))
	return remotes
end

function RemoteRegistry.getRemote(name: string): RemoteEvent | RemoteFunction
	local folderInst = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not folderInst or not folderInst:IsA("Folder") then
		error(string.format("%s RemoteEvents folder not found. Did you call initialize?", LOG_PREFIX))
	end
	local folder = folderInst :: Folder

	local remoteInst = folder:FindFirstChild(name)
	if not remoteInst then
		error(string.format("%s Remote '%s' not found. Is it defined in RemoteRegistry?", LOG_PREFIX, name))
	end

	if remoteInst:IsA("RemoteEvent") then
		return remoteInst :: RemoteEvent
	elseif remoteInst:IsA("RemoteFunction") then
		return remoteInst :: RemoteFunction
	end

	error(string.format("%s Remote '%s' is not a RemoteEvent/RemoteFunction (got %s)", LOG_PREFIX, name, remoteInst.ClassName))
end

function RemoteRegistry.getAllRemoteNames(): { string }
	local names: { string } = {}
	for _, def in ipairs(REMOTE_DEFINITIONS) do
		table.insert(names, def.Name)
	end
	return names
end

-- ------------------------------------------------------------------
-- Compatibility helpers (so client code can just do RemoteRegistry.GetClientRemotes())
-- ------------------------------------------------------------------

function RemoteRegistry.GetClientRemotes(timeout: number?): RemoteMap
	return RemoteRegistry.initializeClient(timeout)
end

function RemoteRegistry.GetServerRemotes(): RemoteMap
	return RemoteRegistry.initializeServer()
end

return RemoteRegistry
