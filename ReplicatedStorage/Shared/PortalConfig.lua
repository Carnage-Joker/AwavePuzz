-- @ScriptType: ModuleScript
-- PortalConfig.lua
-- Configuration for portal matchmaking system
-- Defines portal types and their behavior

local PortalConfig = {}

-- Portal type definitions
PortalConfig.PortalTypes = {
	-- Specific map portals
	ResearchOutpost = {
		Name = "Research Outpost",
		MapId = "ResearchOutpost",
		Description = "Abandoned research facility",
		Color = Color3.fromRGB(100, 150, 255),
	},
	Village = {
		Name = "Village",
		MapId = "Village",
		Description = "Compact village surrounded by wasteland",
		Color = Color3.fromRGB(150, 200, 100),
	},
	Dockyards = {
		Name = "Dockyards",
		MapId = "Dockyards",
		Description = "Industrial dockyards with cargo containers",
		Color = Color3.fromRGB(200, 150, 50),
	},
	ResearchOutpost_Night = {
		Name = "Research Outpost (Night)",
		MapId = "ResearchOutpost_Night",
		Description = "Research facility at night",
		Color = Color3.fromRGB(80, 100, 180),
	},
	
	-- Random portal (selects a map at match start)
	Random = {
		Name = "Random Map",
		MapId = "Random",
		Description = "Play on a random map",
		Color = Color3.fromRGB(200, 100, 200),
	},
}

-- Helper function to get portal type by ID
function PortalConfig.getPortalType(portalId)
	return PortalConfig.PortalTypes[portalId]
end

-- Helper function to get all portal types
function PortalConfig.getAllPortalTypes()
	local types = {}
	for id, data in pairs(PortalConfig.PortalTypes) do
		table.insert(types, {
			id = id,
			name = data.Name,
			mapId = data.MapId,
			description = data.Description,
			color = data.Color
		})
	end
	return types
end

return PortalConfig
