-- @ScriptType: ModuleScript
-- MapValidator.lua
-- Validates that map models have the required structure for gameplay
-- Checks for required folders and spawn points

local MapValidator = {}

local REQUIRED_FOLDERS = {
	"ZombieSpawnPoints"
}

local MIN_ZOMBIE_SPAWNS = 8
local MIN_RESOURCE_SPAWNS = 4
local MIN_ITEM_SPAWNS = 4

local function countSpawnPoints(folder)
	if not folder then
		return 0
	end

	local count = 0
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("BasePart") then
			count += 1
		elseif child:IsA("Attachment") then
			count += 1
		elseif child:IsA("Model") and child.PrimaryPart then
			count += 1
		end
	end
	return count
end

function MapValidator.validateMapModel(mapModel)
	if not mapModel then
		return false, {"Map model is nil"}, {}, nil
	end

	local errors = {}
	local warnings = {}

	-- Required folders
	for _, folderName in ipairs(REQUIRED_FOLDERS) do
		local folder = mapModel:FindFirstChild(folderName)
		if not folder then
			table.insert(errors, "Missing required folder: " .. folderName)
		end
	end

	-- Zombie spawns
	local zombieSpawnFolder = mapModel:FindFirstChild("ZombieSpawnPoints")
	local zombieCount = countSpawnPoints(zombieSpawnFolder)

	-- Resource spawns
	local resourceCount = 0
	local resourceFolderLegacy = mapModel:FindFirstChild("ResourceSpawnPoints")
	if resourceFolderLegacy then
		resourceCount = countSpawnPoints(resourceFolderLegacy)
	else
		local spawnPointsFolder = mapModel:FindFirstChild("SpawnPoints")
		if spawnPointsFolder then
			local resourceSpawns = spawnPointsFolder:FindFirstChild("ResourceSpawns")
			if resourceSpawns then
				resourceCount = countSpawnPoints(resourceSpawns)
			end
		end
	end

	-- Item spawns
	local itemCount = 0
	local spawnPointsFolder = mapModel:FindFirstChild("SpawnPoints")
	if spawnPointsFolder then
		local itemSpawns = spawnPointsFolder:FindFirstChild("ItemSpawns")
		if itemSpawns then
			itemCount = countSpawnPoints(itemSpawns)
		end
	end

	-- Validate counts
	if zombieCount < MIN_ZOMBIE_SPAWNS then
		table.insert(errors, string.format("Insufficient zombie spawn points: %d (minimum: %d)", zombieCount, MIN_ZOMBIE_SPAWNS))
	end

	if resourceCount < MIN_RESOURCE_SPAWNS then
		table.insert(warnings, string.format("Low resource spawn points: %d (recommended: %d)", resourceCount, MIN_RESOURCE_SPAWNS))
	end

	if itemCount < MIN_ITEM_SPAWNS then
		table.insert(warnings, string.format("Low item spawn points: %d (recommended: %d)", itemCount, MIN_ITEM_SPAWNS))
	end

	-- Optional
	local mapBounds = mapModel:FindFirstChild("MapBounds")
	if not mapBounds then
		table.insert(warnings, "No MapBounds defined (optional)")
	end

	local isValid = (#errors == 0)
	return isValid, errors, warnings, {
		zombieSpawns = zombieCount,
		resourceSpawns = resourceCount,
		itemSpawns = itemCount
	}
end

function MapValidator.logValidation(mapName, isValid, errors, warnings, counts)
	if isValid then
		print(string.format("[MapValidator] Map '%s' is valid", tostring(mapName)))
		if counts then
			print(string.format("  - Zombie spawns: %d", counts.zombieSpawns))
			print(string.format("  - Resource spawns: %d", counts.resourceSpawns))
			print(string.format("  - Item spawns: %d", counts.itemSpawns))
		end
	else
		warn(string.format("[MapValidator] Map '%s' validation FAILED", tostring(mapName)))
		for _, err in ipairs(errors) do
			warn("  ERROR: " .. tostring(err))
		end
	end

	if warnings and #warnings > 0 then
		for _, w in ipairs(warnings) do
			warn("  WARNING: " .. tostring(w))
		end
	end
end

return MapValidator
