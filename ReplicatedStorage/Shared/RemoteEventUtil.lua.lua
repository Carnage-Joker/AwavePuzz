-- @ScriptType: Script
-- RemoteEventUtil.lua
-- Shared utility for creating and managing remote events
-- Consolidates the duplicate remote event setup pattern from multiple server services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEventUtil = {}

-- Get or create the RemoteEvents folder
local function getRemoteEventsFolder()
	local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "RemoteEvents"
		folder.Parent = ReplicatedStorage
	end
	return folder
end

-- Get or create a RemoteEvent by name
function RemoteEventUtil.getOrCreateEvent(eventName)
	assert(typeof(eventName) == "string", "Event name must be a string")
	
	local folder = getRemoteEventsFolder()
	local event = folder:FindFirstChild(eventName)
	
	-- Verify the instance is actually a RemoteEvent, not some other type
	if not event or not event:IsA("RemoteEvent") then
		-- If wrong type exists, warn and recreate
		if event then
			warn(string.format("[RemoteEventUtil] Instance '%s' exists but is not a RemoteEvent (is %s). Recreating.", eventName, event.ClassName))
			event:Destroy()
		end
		event = Instance.new("RemoteEvent")
		event.Name = eventName
		event.Parent = folder
	end
	
	return event
end

-- Get or create multiple RemoteEvents at once
-- Usage: local events = RemoteEventUtil.getOrCreateEvents({"Event1", "Event2", "Event3"})
function RemoteEventUtil.getOrCreateEvents(eventNames)
	assert(typeof(eventNames) == "table", "Event names must be a table")
	
	local events = {}
	for _, name in ipairs(eventNames) do
		events[name] = RemoteEventUtil.getOrCreateEvent(name)
	end
	
	return events
end

-- Get or create a RemoteFunction by name
function RemoteEventUtil.getOrCreateFunction(functionName)
	assert(typeof(functionName) == "string", "Function name must be a string")
	
	local folder = getRemoteEventsFolder()
	local remoteFunction = folder:FindFirstChild(functionName)
	
	-- Verify the instance is actually a RemoteFunction, not some other type
	if not remoteFunction or not remoteFunction:IsA("RemoteFunction") then
		-- If wrong type exists, warn and recreate
		if remoteFunction then
			warn(string.format("[RemoteEventUtil] Instance '%s' exists but is not a RemoteFunction (is %s). Recreating.", functionName, remoteFunction.ClassName))
			remoteFunction:Destroy()
		end
		remoteFunction = Instance.new("RemoteFunction")
		remoteFunction.Name = functionName
		remoteFunction.Parent = folder
	end
	
	return remoteFunction
end

-- Get or create multiple RemoteFunctions at once
function RemoteEventUtil.getOrCreateFunctions(functionNames)
	assert(typeof(functionNames) == "table", "Function names must be a table")
	
	local functions = {}
	for _, name in ipairs(functionNames) do
		functions[name] = RemoteEventUtil.getOrCreateFunction(name)
	end
	
	return functions
end

-- Helper to wait for a remote event (client-side)
function RemoteEventUtil.waitForEvent(eventName, timeout)
	local folder = ReplicatedStorage:WaitForChild("RemoteEvents", timeout or 10)
	if folder then
		return folder:WaitForChild(eventName, timeout or 10)
	end
	return nil
end

return RemoteEventUtil
