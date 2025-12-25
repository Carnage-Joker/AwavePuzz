-- MapConfig.lua
-- Describes available maps and the helper utilities for the multi-map system
-- Note: Map voting between rounds can be implemented by:
--   1. Calling MapConfig.getRandom() or collecting player votes
--   2. Passing the selected mapId to MapManager:load(mapId)

-- Map definitions
-- Each map is a table with the following fields:
--   Name: Display name for the map
--   Model: Name of the map model in ReplicatedStorage.Maps
--   Description: Brief description of the map

local MapConfig = {}

MapConfig.Maps = {
	ResearchOutpost = {
		Name = "Villiage",
		Model = "Villiage",
		Description = "Compact Villiage surrounded by wasteland.",
		Default = true
	},
	DesertRuins = {
		Name = "Desert Ruins",
		Model = "DesertRuins",
		Description = "Open space with long sight-lines and scattered cover."
	}
}

function MapConfig.getDefault()
	for id, data in pairs(MapConfig.Maps) do
		if data.Default then
			return id, data
		end
	end
	-- Fall back to first map in table
	for id, data in pairs(MapConfig.Maps) do
		return id, data
	end
	return nil, nil
end

function MapConfig.getRandom()
	local keys = {}
	for id in pairs(MapConfig.Maps) do
		table.insert(keys, id)
	end
	if #keys == 0 then
		return MapConfig.getDefault()
	end
	local randomId = keys[math.random(1, #keys)]
	return randomId, MapConfig.Maps[randomId]
end

function MapConfig.get(mapId)
	return MapConfig.Maps[mapId]
end

return MapConfig
