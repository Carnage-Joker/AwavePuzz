-- MapConfig.lua
-- Describes available maps and the helper utilities for the multi-map system

local MapConfig = {}

MapConfig.Maps = {
        ResearchOutpost = {
                Name = "Research Outpost",
                Model = "ResearchOutpost",
                Description = "Compact lab surrounded by frozen wasteland.",
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
