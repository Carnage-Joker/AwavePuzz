--!strict
-- @ScriptType: ModuleScript
-- UIConnectionMaid.lua
-- Universal connection cleanup utility for UI modules
-- Safely tracks and cleans up RBXScriptConnections, unsubscribe functions, and disconnectable objects
-- Version: 1.0.0

local UIConnectionMaid = {}
UIConnectionMaid.__index = UIConnectionMaid

export type ConnectionType = RBXScriptConnection | (() -> ()) | { Disconnect: () -> () }
export type Maid = typeof(setmetatable({} :: {
	_tasks: { [string | number]: ConnectionType },
	_nextIndex: number,
}, UIConnectionMaid))

--[[
	Creates a new Maid instance for tracking connections and cleanup tasks
	
	Usage:
		local maid = UIConnectionMaid.new()
		maid:Give(button.MouseButton1Click:Connect(handler))
		maid:GiveFn(unsubscribeCallback)
		maid:GiveTask({Disconnect = function() ... end})
		maid:Cleanup() -- Safely disconnects everything
]]
function UIConnectionMaid.new(): Maid
	local self = setmetatable({}, UIConnectionMaid)
	self._tasks = {}
	self._nextIndex = 1
	return self
end

--[[
	Adds an RBXScriptConnection to be tracked
	Returns the connection for chaining
	
	@param connection RBXScriptConnection - The connection to track
	@param name string? - Optional name for the connection (for debugging)
	@return RBXScriptConnection - The same connection that was passed in
]]
function UIConnectionMaid:Give(connection: RBXScriptConnection, name: string?): RBXScriptConnection
	local key = name or self._nextIndex
	if name == nil then
		self._nextIndex = self._nextIndex + 1
	end
	
	self._tasks[key] = connection
	return connection
end

--[[
	Adds an unsubscribe function to be tracked
	Returns the function for chaining
	
	@param unsubscribeFn () -> () - The unsubscribe function to call on cleanup
	@param name string? - Optional name for the task (for debugging)
	@return () -> () - The same function that was passed in
]]
function UIConnectionMaid:GiveFn(unsubscribeFn: () -> (), name: string?): () -> ()
	local key = name or self._nextIndex
	if name == nil then
		self._nextIndex = self._nextIndex + 1
	end
	
	self._tasks[key] = unsubscribeFn
	return unsubscribeFn
end

--[[
	Adds a disconnectable object (with Disconnect method) to be tracked
	Returns the object for chaining
	
	@param disconnectable { Disconnect: () -> () } - Object with Disconnect method
	@param name string? - Optional name for the task (for debugging)
	@return { Disconnect: () -> () } - The same object that was passed in
]]
function UIConnectionMaid:GiveTask(disconnectable: { Disconnect: () -> () }, name: string?): { Disconnect: () -> () }
	local key = name or self._nextIndex
	if name == nil then
		self._nextIndex = self._nextIndex + 1
	end
	
	self._tasks[key] = disconnectable
	return disconnectable
end

--[[
	Removes and cleans up a specific task by name
	Safe to call even if task doesn't exist
	
	@param name string | number - The name or index of the task to remove
]]
function UIConnectionMaid:Remove(name: string | number)
	local task = self._tasks[name]
	if not task then
		return
	end
	
	self._tasks[name] = nil
	self:_cleanupTask(task)
end

--[[
	Internal method to safely cleanup a single task
	Handles all connection types without throwing errors
	
	@param task ConnectionType - The task to cleanup
]]
function UIConnectionMaid:_cleanupTask(task: any)
	local taskType = typeof(task)
	
	-- Handle RBXScriptConnection
	if taskType == "RBXScriptConnection" then
		if task.Connected then
			local success, err = pcall(function()
				task:Disconnect()
			end)
			if not success then
				warn("[UIConnectionMaid] Error disconnecting RBXScriptConnection:", err)
			end
		end
	-- Handle unsubscribe function
	elseif taskType == "function" then
		local success, err = pcall(task)
		if not success then
			warn("[UIConnectionMaid] Error calling unsubscribe function:", err)
		end
	-- Handle disconnectable object with Disconnect method
	elseif taskType == "table" then
		if task.Disconnect and typeof(task.Disconnect) == "function" then
			local success, err = pcall(task.Disconnect, task)
			if not success then
				warn("[UIConnectionMaid] Error calling Disconnect method:", err)
			end
		else
			warn("[UIConnectionMaid] Table task provided without valid Disconnect method")
		end
	else
		warn("[UIConnectionMaid] Unknown task type:", taskType)
	end
end

--[[
	Cleans up all tracked connections and tasks
	Safe to call multiple times - will never throw errors
	Clears all internal state after cleanup
]]
function UIConnectionMaid:Cleanup()
	for key, task in pairs(self._tasks) do
		self:_cleanupTask(task)
	end
	
	table.clear(self._tasks)
	self._nextIndex = 1
end

--[[
	Alias for Cleanup() for compatibility with different naming conventions
]]
function UIConnectionMaid:Destroy()
	self:Cleanup()
end

--[[
	Returns the number of tasks currently tracked
	Useful for debugging and detecting leaks
	
	@return number - Number of tracked tasks
]]
function UIConnectionMaid:GetTaskCount(): number
	local count = 0
	for _ in pairs(self._tasks) do
		count = count + 1
	end
	return count
end

--[[
	Checks if a specific task exists by name
	
	@param name string | number - The name or index to check
	@return boolean - True if task exists
]]
function UIConnectionMaid:HasTask(name: string | number): boolean
	return self._tasks[name] ~= nil
end

return UIConnectionMaid
