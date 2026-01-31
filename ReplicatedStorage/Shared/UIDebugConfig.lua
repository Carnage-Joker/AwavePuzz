-- UIDebugConfig.lua
-- Centralized debug configuration for UI systems
-- Set DEBUG_UI_CREATION to true to enable detailed UI creation logging

local UIDebugConfig = {
	-- Master flag for UI creation debugging
	DEBUG_UI_CREATION = false,
	
	-- If true, warns when duplicate UIs are detected and destroyed
	WARN_ON_DUPLICATES = true,
}

-- Helper function to log UI creation events
function UIDebugConfig.logUICreation(uiName, action, details)
	if not UIDebugConfig.DEBUG_UI_CREATION then
		return
	end
	
	local timestamp = os.date("%H:%M:%S")
	local message = string.format("[%s] [UIDebug] %s - %s", timestamp, uiName, action)
	
	if details then
		message = message .. ": " .. tostring(details)
	end
	
	print(message)
end

-- Helper function to warn about duplicate UI
function UIDebugConfig.warnDuplicate(uiName)
	if not UIDebugConfig.WARN_ON_DUPLICATES then
		return
	end
	
	warn(string.format("[UIDebug] Removing duplicate %s from PlayerGui", uiName))
end

return UIDebugConfig
