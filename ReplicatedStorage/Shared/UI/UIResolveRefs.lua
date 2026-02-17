--!strict
-- @ScriptType: ModuleScript
-- UIResolveRefs.lua
-- Utility for safely resolving UI instance references with retry logic and timeouts
-- Prevents "attempt to index nil" errors by deferring UI access until Init() is called
-- Version: 1.0.0

local UIResolveRefs = {}

-- Default retry configuration
local DEFAULT_TIMEOUT = 10 -- seconds
local DEFAULT_RETRY_DELAY = 0.1 -- seconds
local DEFAULT_MAX_RETRIES = math.floor(DEFAULT_TIMEOUT / DEFAULT_RETRY_DELAY)

--[[
	Safely waits for a child with retry logic and timeout
	
	@param parent Instance - The parent instance to search in
	@param childName string - The name of the child to wait for
	@param timeout number? - Maximum time to wait in seconds (default: 10)
	@return Instance? - The found child, or nil if not found
]]
function UIResolveRefs.waitForChild(parent: Instance, childName: string, timeout: number?): Instance?
	local actualTimeout = timeout or DEFAULT_TIMEOUT
	local maxRetries = math.floor(actualTimeout / DEFAULT_RETRY_DELAY)
	local retries = 0
	
	while retries < maxRetries do
		local child = parent:FindFirstChild(childName)
		if child then
			return child
		end
		
		retries = retries + 1
		task.wait(DEFAULT_RETRY_DELAY)
	end
	
	return nil
end

--[[
	Safely resolves a chain of UI references with retry logic
	Returns nil if any part of the chain fails
	
	@param moduleName string - Name of the UI module for logging
	@param playerGui Instance - PlayerGui instance
	@param screenGuiName string - Name of the ScreenGui to find
	@param path table - Array of child names to traverse (e.g., {"Frame", "Button"})
	@param timeout number? - Maximum time to wait in seconds (default: 10)
	@return Instance? - The final instance in the chain, or nil if not found
]]
function UIResolveRefs.resolveUIChain(moduleName: string, playerGui: Instance, screenGuiName: string, path: {string}, timeout: number?): Instance?
	local actualTimeout = timeout or DEFAULT_TIMEOUT
	
	-- Wait for ScreenGui
	local screenGui = UIResolveRefs.waitForChild(playerGui, screenGuiName, actualTimeout)
	if not screenGui then
		warn(string.format("[UI:%s] ScreenGui '%s' not found after %ds timeout", moduleName, screenGuiName, actualTimeout))
		return nil
	end
	
	-- Traverse the path
	local current: Instance = screenGui
	for i, childName in ipairs(path) do
		local child = UIResolveRefs.waitForChild(current, childName, actualTimeout)
		if not child then
			warn(string.format("[UI:%s] Child '%s' not found in path at index %d after %ds timeout", moduleName, childName, i, actualTimeout))
			return nil
		end
		current = child
	end
	
	return current
end

--[[
	Helper to resolve a single UI element by name
	
	@param moduleName string - Name of the UI module for logging
	@param playerGui Instance - PlayerGui instance
	@param screenGuiName string - Name of the ScreenGui to find
	@param elementName string - Name of the element to find
	@param timeout number? - Maximum time to wait in seconds (default: 10)
	@return Instance? - The element, or nil if not found
]]
function UIResolveRefs.resolveElement(moduleName: string, playerGui: Instance, screenGuiName: string, elementName: string, timeout: number?): Instance?
	return UIResolveRefs.resolveUIChain(moduleName, playerGui, screenGuiName, {elementName}, timeout)
end

--[[
	Validates that a UI element exists and is of the expected type
	Logs warning if validation fails
	
	@param moduleName string - Name of the UI module for logging
	@param element Instance? - The element to validate
	@param elementName string - Name of the element for logging
	@param expectedType string - Expected ClassName (e.g., "TextButton", "Frame")
	@return boolean - True if valid, false otherwise
]]
function UIResolveRefs.validateElement(moduleName: string, element: Instance?, elementName: string, expectedType: string): boolean
	if not element then
		warn(string.format("[UI:%s] Element '%s' is nil", moduleName, elementName))
		return false
	end
	
	if not element:IsA(expectedType) then
		warn(string.format("[UI:%s] Element '%s' is not a %s (got %s)", moduleName, elementName, expectedType, element.ClassName))
		return false
	end
	
	return true
end

--[[
	Logs UI initialization events with consistent formatting
	
	@param moduleName string - Name of the UI module
	@param message string - The log message
	@param level string? - Log level: "INFO", "WARN", "ERROR" (default: "INFO")
]]
function UIResolveRefs.log(moduleName: string, message: string, level: string?)
	local actualLevel = level or "INFO"
	local prefix = string.format("[UI:%s]", moduleName)
	
	if actualLevel == "WARN" then
		warn(prefix, message)
	elseif actualLevel == "ERROR" then
		error(prefix .. " " .. message)
	else
		print(prefix, message)
	end
end

--[[
	Creates a retry loop for a function that may initially fail
	Useful for UI elements that depend on game state or remote data
	
	@param moduleName string - Name of the UI module for logging
	@param fn () -> boolean - Function to retry; should return true on success
	@param maxRetries number? - Maximum number of retry attempts (default: 100)
	@param retryDelay number? - Delay between retries in seconds (default: 0.1)
	@return boolean - True if function succeeded, false if all retries failed
]]
function UIResolveRefs.retryUntilSuccess(moduleName: string, fn: () -> boolean, maxRetries: number?, retryDelay: number?): boolean
	local actualMaxRetries = maxRetries or DEFAULT_MAX_RETRIES
	local actualRetryDelay = retryDelay or DEFAULT_RETRY_DELAY
	local retries = 0
	
	while retries < actualMaxRetries do
		local success, result = pcall(fn)
		if success and result == true then
			return true
		end
		
		retries = retries + 1
		task.wait(actualRetryDelay)
	end
	
	warn(string.format("[UI:%s] Function failed after %d retries", moduleName, actualMaxRetries))
	return false
end

return UIResolveRefs
