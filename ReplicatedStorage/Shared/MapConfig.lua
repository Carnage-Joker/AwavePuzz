-- @ScriptType: ModuleScript
-- MapConfig.lua
-- Describes available maps and helper utilities for the multi-map system

local MapConfig = {}

MapConfig.Maps = {
	ResearchOutpost = {
		Name = "Research Outpost",
		Model = "ResearchOutpost",
		Description = "Abandoned research facility with tight corridors and defensive positions.",
		Default = true,
	},
	Village = {
		Name = "Village",
		Model = "Village",
		Description = "Compact village surrounded by wasteland with mixed terrain.",
	},
	Dockyards = {
		Name = "Dockyards",
		Model = "Dockyards",
		Description = "Industrial dockyards with cargo containers and open water hazards.",
	},
	ResearchOutpost_Night = {
		Name = "Research Outpost (Night)",
		Model = "ResearchOutpost_Night",
		Description = "Research facility at night with limited visibility and atmospheric tension.",
	},
}

function MapConfig.getDefault()
	-- Prefer explicit Default=true
	for id, data in pairs(MapConfig.Maps) do
		if data and data.Default then
			return id, data
		end
	end

	-- Fallback: first entry
	for id, data in pairs(MapConfig.Maps) do
		return id, data
	end

	return nil, nil
end

function MapConfig.getRandom()
	local keys = {}
	for id, _ in pairs(MapConfig.Maps) do
		table.insert(keys, id)
	end

	if #keys == 0 then
		return MapConfig.getDefault()
	end

	-- ✅ Correct bracket/paren usage
	local randomId = keys[math.random(1, #keys)]
	return randomId, MapConfig.Maps[randomId]
end

function MapConfig.get(mapId)
	return MapConfig.Maps[mapId]
end

return MapConfig
