--[[
	Remotes.lua
	Centralized remote event/function management
	Creates all remotes under ReplicatedStorage/Remotes
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

-- Remote definitions
-- Format: {name, type ("Event" or "Function")}
local REMOTE_DEFINITIONS = {
	-- Client → Server functions (return results)
	{"EquipOutfit", "Function"},
	{"GetCatalog", "Function"},
	{"CompleteActivity", "Function"},
	{"GetProfile", "Function"},
	{"SetTitle", "Function"},
	
	-- Server → Client events (one-way notifications)
	{"PushToast", "Event"},  -- server → client
	{"SyncStats", "Event"},  -- server → client
}

-- Container folder for all remotes
local remotesFolder: Folder

-- Initialize remotes (call once on server startup)
function Remotes.initialize()
	-- Create or get Remotes folder
	remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "Remotes"
		remotesFolder.Parent = ReplicatedStorage
	end
	
	-- Create each remote
	for _, def in ipairs(REMOTE_DEFINITIONS) do
		local name, remoteType = def[1], def[2]
		
		local existing = remotesFolder:FindFirstChild(name)
		if not existing then
			local remote
			if remoteType == "Event" then
				remote = Instance.new("RemoteEvent")
			elseif remoteType == "Function" then
				remote = Instance.new("RemoteFunction")
			else
				error("Invalid remote type: " .. tostring(remoteType))
			end
			
			remote.Name = name
			remote.Parent = remotesFolder
			print(string.format("Created %s: %s", remoteType, name))
		end
	end
	
	print("✅ Remotes initialized")
	return true
end

-- Get a remote by name (for both client and server)
function Remotes.getRemote(name: string): RemoteEvent | RemoteFunction
	if not remotesFolder then
		remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
		if not remotesFolder then
			error("Remotes folder not found in ReplicatedStorage")
		end
	end
	
	local remote = remotesFolder:WaitForChild(name, 10)
	if not remote then
		error(string.format("Remote '%s' not found", name))
	end
	
	return remote
end

-- Get remote event (syntactic sugar)
function Remotes.getEvent(name: string): RemoteEvent
	return Remotes.getRemote(name) :: RemoteEvent
end

-- Get remote function (syntactic sugar)
function Remotes.getFunction(name: string): RemoteFunction
	return Remotes.getRemote(name) :: RemoteFunction
end

return Remotes
