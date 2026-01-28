-- @ScriptType: ModuleScript
-- AssetValidation.lua
-- Validates audio and animation asset IDs to prevent runtime errors
-- Provides clear, actionable error messages for invalid assets

local AssetValidation = {}

--------------------------------------------------------------------------------
-- VALIDATION FUNCTIONS
--------------------------------------------------------------------------------

-- Validates a single sound ID
-- @param soundId: String or number asset ID
-- @return boolean: true if valid, false otherwise
local function isValidSoundId(soundId)
	if not soundId then return false end
	
	local idStr = tostring(soundId)
	
	-- Check for placeholder/empty IDs
	if idStr == "0" or idStr == "rbxassetid://0" or idStr == "" then
		return false
	end
	
	-- Must be a number or rbxassetid:// format
	-- Ensure numeric IDs are greater than 0
	local numIdStr = idStr:match("^rbxassetid://(%d+)$")
	if numIdStr then
		local numId = tonumber(numIdStr)
		return numId ~= nil and numId > 0
	end
	
	local numericId = tonumber(idStr)
	if numericId then
		return numericId > 0
	end
	
	return false
end

-- Validates a single animation ID
-- @param animId: String or number asset ID
-- @return boolean: true if valid, false otherwise
local function isValidAnimationId(animId)
	-- Same validation as sound IDs for now
	return isValidSoundId(animId)
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

-- Validates a table of sound assets and logs errors
-- @param assetTable: Table of sound asset IDs (can be nested)
-- @param prefix: String prefix for logging (e.g., "WeaponFire")
-- @return invalidKeys: Table of invalid asset keys for reference
function AssetValidation.validateSoundAssets(assetTable, prefix)
	if not assetTable or type(assetTable) ~= "table" then
		warn("[AssetValidation] validateSoundAssets: assetTable must be a table")
		return {}
	end
	
	prefix = prefix or "SoundAsset"
	local invalidKeys = {}
	
	local function validateRecursive(tbl, path)
		for key, value in pairs(tbl) do
			local fullPath = path and (path .. "." .. key) or key
			
			if type(value) == "table" then
				-- Recurse into nested tables
				validateRecursive(value, fullPath)
			else
				-- Validate the asset ID
				if not isValidSoundId(value) then
					table.insert(invalidKeys, fullPath)
					warn(string.format(
						"[AssetValidation] Invalid SoundId for '%s': '%s' (not a valid asset ID)",
						fullPath,
						tostring(value)
					))
				end
			end
		end
	end
	
	validateRecursive(assetTable, prefix)
	
	if #invalidKeys == 0 then
		print(string.format("[AssetValidation] All sound assets validated successfully (%s)", prefix))
	else
		warn(string.format(
			"[AssetValidation] Found %d invalid sound asset(s) in %s. See warnings above.",
			#invalidKeys,
			prefix
		))
	end
	
	return invalidKeys
end

-- Validates a table of animation assets and logs errors
-- @param assetTable: Table of animation asset IDs (can be nested)
-- @param prefix: String prefix for logging (e.g., "WeaponAnims")
-- @return invalidKeys: Table of invalid asset keys for reference
function AssetValidation.validateAnimationAssets(assetTable, prefix)
	if not assetTable or type(assetTable) ~= "table" then
		warn("[AssetValidation] validateAnimationAssets: assetTable must be a table")
		return {}
	end
	
	prefix = prefix or "AnimationAsset"
	local invalidKeys = {}
	
	local function validateRecursive(tbl, path)
		for key, value in pairs(tbl) do
			local fullPath = path and (path .. "." .. key) or key
			
			if type(value) == "table" then
				-- Recurse into nested tables
				validateRecursive(value, fullPath)
			else
				-- Validate the asset ID
				if not isValidAnimationId(value) then
					table.insert(invalidKeys, fullPath)
					warn(string.format(
						"[AssetValidation] Invalid AnimationId for '%s': '%s' (not a valid asset ID)",
						fullPath,
						tostring(value)
					))
				end
			end
		end
	end
	
	validateRecursive(assetTable, prefix)
	
	if #invalidKeys == 0 then
		print(string.format("[AssetValidation] All animation assets validated successfully (%s)", prefix))
	else
		warn(string.format(
			"[AssetValidation] Found %d invalid animation asset(s) in %s. See warnings above.",
			#invalidKeys,
			prefix
		))
	end
	
	return invalidKeys
end

-- Safely loads a sound with pcall and error handling
-- @param soundId: Asset ID to load
-- @param parent: Parent instance for the sound
-- @param properties: Optional table of properties to set on the sound
-- @return sound: Sound instance or nil if failed
function AssetValidation.safeLoadSound(soundId, parent, properties)
	if not isValidSoundId(soundId) then
		warn(string.format("[AssetValidation] Cannot load invalid sound ID: %s", tostring(soundId)))
		return nil
	end
	
	local success, result = pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		
		-- Apply properties if provided
		if properties then
			for prop, value in pairs(properties) do
				sound[prop] = value
			end
		end
		
		if parent then
			sound.Parent = parent
		end
		
		return sound
	end)
	
	if not success then
		warn(string.format(
			"[AssetValidation] Failed to load sound '%s': %s",
			tostring(soundId),
			tostring(result)
		))
		return nil
	end
	
	return result
end

-- Safely loads an animation with pcall and error handling
-- @param animId: Asset ID to load
-- @param animator: Animator instance to load the animation on
-- @return animTrack: AnimationTrack or nil if failed
function AssetValidation.safeLoadAnimation(animId, animator)
	if not isValidAnimationId(animId) then
		warn(string.format("[AssetValidation] Cannot load invalid animation ID: %s", tostring(animId)))
		return nil
	end
	
	if not animator or not animator:IsA("Animator") then
		warn("[AssetValidation] Invalid animator instance provided")
		return nil
	end
	
	local success, result = pcall(function()
		local animation = Instance.new("Animation")
		animation.AnimationId = animId
		
		local track = animator:LoadAnimation(animation)
		return track
	end)
	
	if not success then
		warn(string.format(
			"[AssetValidation] Failed to load animation '%s': %s",
			tostring(animId),
			tostring(result)
		))
		return nil
	end
	
	return result
end

--------------------------------------------------------------------------------
-- BOOT-TIME VALIDATION
--------------------------------------------------------------------------------

-- Runs validation at boot time for all asset tables
-- Call this early in initialization to catch issues before they cause runtime errors
function AssetValidation.runBootTimeValidation()
	print("=== AssetValidation: Boot-Time Validation ===")
	
	-- Note: This is a placeholder for future integration
	-- Individual controllers should call validateSoundAssets/validateAnimationAssets
	-- with their specific asset tables during initialization
	
	print("=== AssetValidation: Validation Complete ===")
end

return AssetValidation
