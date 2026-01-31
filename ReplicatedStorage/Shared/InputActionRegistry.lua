-- InputActionRegistry.lua
-- Central registry for all input actions with conflict detection
-- Provides startup audit to identify and log input binding conflicts

local InputActionRegistry = {}
InputActionRegistry._registeredActions = {}
InputActionRegistry._initialized = false

-- Priority levels for conflict resolution
InputActionRegistry.Priority = {
	FULLSCREEN_STATE = 0,  -- Title, Lobby, Epilogue (exclusive states)
	MODAL_UI = 1,          -- Shop, Puzzle, Alliance (blocks gameplay)
	TOGGLE_UI = 2,         -- Scoreboard (overlay)
	CORE_GAMEPLAY = 3,     -- Movement, Combat (always active unless blocked)
	PASSIVE_DISPLAY = 4    -- HUD elements (no input)
}

--------------------------------------------------------------------------------
-- REGISTRATION
--------------------------------------------------------------------------------

-- Register an input action
-- @param actionName: Unique identifier for this action
-- @param owner: Name of the module/system that owns this action
-- @param keys: Table of KeyCode or UserInputType enums
-- @param priority: Priority level (see Priority enum above)
-- @param enabled: Optional boolean, defaults to true
function InputActionRegistry.register(actionName, owner, keys, priority, enabled)
	assert(type(actionName) == "string", "actionName must be a string")
	assert(type(owner) == "string", "owner must be a string")
	assert(type(keys) == "table", "keys must be a table")
	priority = priority or InputActionRegistry.Priority.CORE_GAMEPLAY
	if enabled == nil then enabled = true end
	
	-- Check if already registered
	if InputActionRegistry._registeredActions[actionName] then
		local existing = InputActionRegistry._registeredActions[actionName]
		
		-- Check if this is an idempotent re-registration (same owner and same configuration)
		local isSameOwner = existing.owner == owner
		local isSamePriority = existing.priority == priority
		local isSameEnabled = existing.enabled == enabled
		
		-- Compare keys arrays
		local isSameKeys = #existing.keys == #keys
		if isSameKeys then
			for i, key in ipairs(keys) do
				if existing.keys[i] ~= key then
					isSameKeys = false
					break
				end
			end
		end
		
		-- If everything matches, this is a duplicate registration - skip silently
		if isSameOwner and isSamePriority and isSameEnabled and isSameKeys then
			-- Idempotent re-registration - skip without warning
			return
		end
		
		-- Otherwise, this is a conflict - warn about it
		warn(string.format(
			"[InputActionRegistry] Action '%s' registered multiple times! Previous owner: %s, New owner: %s",
			actionName,
			existing.owner,
			owner
		))
	end
	
	-- Store action info
	InputActionRegistry._registeredActions[actionName] = {
		owner = owner,
		keys = keys,
		priority = priority,
		enabled = enabled,
	}
	
	print(string.format(
		"[InputActionRegistry] Registered: %s (owner: %s, priority: %d, keys: %d, enabled: %s)",
		actionName, owner, priority, #keys, tostring(enabled)
	))
end

-- Unregister an action (useful for cleanup)
function InputActionRegistry.unregister(actionName)
	if InputActionRegistry._registeredActions[actionName] then
		InputActionRegistry._registeredActions[actionName] = nil
		print(string.format("[InputActionRegistry] Unregistered: %s", actionName))
		return true
	end
	return false
end

-- Enable an action (makes it active for conflict detection and usage)
function InputActionRegistry.enable(actionName)
	local action = InputActionRegistry._registeredActions[actionName]
	if action then
		action.enabled = true
		return true
	end
	return false
end

-- Disable an action (makes it inactive, resolves conflicts)
function InputActionRegistry.disable(actionName)
	local action = InputActionRegistry._registeredActions[actionName]
	if action then
		action.enabled = false
		return true
	end
	return false
end

-- Enable all actions owned by a specific owner
function InputActionRegistry.enableOwner(owner)
	local count = 0
	for actionName, data in pairs(InputActionRegistry._registeredActions) do
		if data.owner == owner then
			data.enabled = true
			count = count + 1
		end
	end
	if count > 0 then
		print(string.format("[InputActionRegistry] Enabled %d action(s) for owner: %s", count, owner))
	end
	return count
end

-- Disable all actions owned by a specific owner
function InputActionRegistry.disableOwner(owner)
	local count = 0
	for actionName, data in pairs(InputActionRegistry._registeredActions) do
		if data.owner == owner then
			data.enabled = false
			count = count + 1
		end
	end
	if count > 0 then
		print(string.format("[InputActionRegistry] Disabled %d action(s) for owner: %s", count, owner))
	end
	return count
end

--------------------------------------------------------------------------------
-- CONFLICT DETECTION
--------------------------------------------------------------------------------

-- Check for conflicts between actions at the same priority level
-- Only checks enabled actions to avoid false positives
local function detectConflicts()
	local conflicts = {}
	local keyUsage = {}  -- Maps keyCode -> list of {action, priority, owner}
	
	-- Build key usage map (only for enabled actions)
	for actionName, data in pairs(InputActionRegistry._registeredActions) do
		-- Skip disabled actions
		if data.enabled ~= false then
			for _, keyCode in ipairs(data.keys) do
				local keyStr = tostring(keyCode)
				
				if not keyUsage[keyStr] then
					keyUsage[keyStr] = {}
				end
				
				table.insert(keyUsage[keyStr], {
					action = actionName,
					priority = data.priority,
					owner = data.owner
				})
			end
		end
	end
	
	-- Find conflicts (same key at same priority)
	for keyStr, usages in pairs(keyUsage) do
		if #usages > 1 then
			-- Group by priority
			local priorityGroups = {}
			for _, usage in ipairs(usages) do
				if not priorityGroups[usage.priority] then
					priorityGroups[usage.priority] = {}
				end
				table.insert(priorityGroups[usage.priority], usage)
			end
			
			-- Report conflicts within same priority
			for priority, group in pairs(priorityGroups) do
				if #group > 1 then
					table.insert(conflicts, {
						key = keyStr,
						priority = priority,
						actions = group
					})
				end
			end
		end
	end
	
	return conflicts
end

-- Run a full audit and print results
function InputActionRegistry.audit()
	print("=================================")
	print("=== INPUT ACTION REGISTRY AUDIT ===")
	print("=================================")
	
	-- List all registered actions
	print("\n--- Registered Actions ---")
	local actionCount = 0
	for actionName, data in pairs(InputActionRegistry._registeredActions) do
		actionCount = actionCount + 1
		local keyNames = {}
		for _, key in ipairs(data.keys) do
			local keyName = tostring(key):match("%.(.+)$") or tostring(key)
			table.insert(keyNames, keyName)
		end
		print(string.format(
			"  %s: %s (priority %d) - Keys: %s",
			actionName,
			data.owner,
			data.priority,
			table.concat(keyNames, ", ")
		))
	end
	print(string.format("Total actions: %d\n", actionCount))
	
	-- Detect and report conflicts
	local conflicts = detectConflicts()
	
	if #conflicts > 0 then
		print("--- CONFLICTS DETECTED ---")
		print(string.format("⚠️ Found %d input conflicts:\n", #conflicts))
		
		for i, conflict in ipairs(conflicts) do
			local keyName = conflict.key:match("%.(.+)$") or conflict.key
			print(string.format("Conflict #%d: Key '%s' (priority %d)", i, keyName, conflict.priority))
			
			for _, action in ipairs(conflict.actions) do
				print(string.format("  - Action '%s' (%s)", action.action, action.owner))
			end
			print()
		end
		
		warn(string.format("[InputActionRegistry] ⚠️ %d input conflicts detected! See audit output above.", #conflicts))
	else
		print("✓ No conflicts detected - All input actions are unique within their priority levels\n")
	end
	
	print("=================================")
end

--------------------------------------------------------------------------------
-- QUERY UTILITIES
--------------------------------------------------------------------------------

-- Get all actions using a specific key
function InputActionRegistry.getActionsForKey(keyCode)
	local actions = {}
	local keyStr = tostring(keyCode)
	
	for actionName, data in pairs(InputActionRegistry._registeredActions) do
		for _, key in ipairs(data.keys) do
			if tostring(key) == keyStr then
				table.insert(actions, {
					action = actionName,
					owner = data.owner,
					priority = data.priority
				})
			end
		end
	end
	
	return actions
end

-- Get action info by name
function InputActionRegistry.getAction(actionName)
	return InputActionRegistry._registeredActions[actionName]
end

-- Get all registered action names
function InputActionRegistry.getAllActionNames()
	local names = {}
	for actionName, _ in pairs(InputActionRegistry._registeredActions) do
		table.insert(names, actionName)
	end
	table.sort(names)
	return names
end

-- Check if an action is registered
function InputActionRegistry.isRegistered(actionName)
	return InputActionRegistry._registeredActions[actionName] ~= nil
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function InputActionRegistry.initialize()
	if InputActionRegistry._initialized then
		warn("[InputActionRegistry] Already initialized")
		return
	end
	
	InputActionRegistry._initialized = true
	print("[InputActionRegistry] Initialized")
end

-- Run audit automatically after initialization
function InputActionRegistry.runStartupAudit()
	-- Wait a moment for all systems to register their actions
	task.wait(1)
	InputActionRegistry.audit()
end

--------------------------------------------------------------------------------
-- HELPER: Register from InputManager Action enum
--------------------------------------------------------------------------------

-- Convenience function to register InputManager actions
function InputActionRegistry.registerInputManagerAction(action, owner, priority)
	local InputManager = require(script.Parent:WaitForChild("InputManager"))
	local binding = InputManager.getBinding(action)
	
	if binding then
		InputActionRegistry.register(action, owner, binding, priority)
	else
		warn(string.format("[InputActionRegistry] No binding found for action '%s'", action))
	end
end

return InputActionRegistry
