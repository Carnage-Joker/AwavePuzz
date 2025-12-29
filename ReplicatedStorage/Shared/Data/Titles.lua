--[[
	Titles.lua
	Defines unlockable titles and their requirements
]]

local Titles = {}

-- Title definitions
-- Fields:
--   id: unique identifier
--   name: display name
--   description: what the title represents
--   unlockRequirements: conditions to unlock
--     - type: "stat", "currency", "items", "activities"
--     - condition: specific requirement details
Titles.list = {
	{
		id = "novice",
		name = "Style Novice",
		description = "Just beginning your style journey",
		unlockRequirements = {
			type = "default",  -- Everyone starts with this
		},
	},
	{
		id = "graceful",
		name = "Graceful",
		description = "Achieved notable grace in movement",
		unlockRequirements = {
			type = "stat",
			stat = "Grace",
			amount = 50,
		},
	},
	{
		id = "elegant",
		name = "Elegant Soul",
		description = "Embodies elegance in all things",
		unlockRequirements = {
			type = "stat",
			stat = "Elegance",
			amount = 50,
		},
	},
	{
		id = "confident",
		name = "Confident",
		description = "Radiates self-assurance",
		unlockRequirements = {
			type = "stat",
			stat = "Confidence",
			amount = 50,
		},
	},
	{
		id = "caring",
		name = "Caring Heart",
		description = "Shows care in every detail",
		unlockRequirements = {
			type = "stat",
			stat = "Care",
			amount = 50,
		},
	},
	{
		id = "fashionista",
		name = "Fashionista",
		description = "Owns an impressive wardrobe",
		unlockRequirements = {
			type = "items",
			count = 15,  -- Own 15 items
		},
	},
	{
		id = "dedicated",
		name = "Dedicated",
		description = "Completed many activities with dedication",
		unlockRequirements = {
			type = "activities",
			count = 20,  -- Complete 20 activities total
		},
	},
	{
		id = "icon",
		name = "Style Icon",
		description = "A true master of self-expression",
		unlockRequirements = {
			type = "all_stats",
			amount = 100,  -- All stats >= 100
		},
	},
}

-- Get title by ID
function Titles.getTitle(titleId: string)
	for _, title in ipairs(Titles.list) do
		if title.id == titleId then
			return title
		end
	end
	return nil
end

-- Check if requirements are met
function Titles.checkUnlockRequirements(title, profile)
	local req = title.unlockRequirements
	
	if req.type == "default" then
		return true
	elseif req.type == "stat" then
		return (profile.stats[req.stat] or 0) >= req.amount
	elseif req.type == "items" then
		return #(profile.ownedItems or {}) >= req.count
	elseif req.type == "activities" then
		-- Would need activity completion tracking in profile
		-- For now, return false (implement later)
		return false
	elseif req.type == "all_stats" then
		for _, statValue in pairs(profile.stats) do
			if statValue < req.amount then
				return false
			end
		end
		return true
	end
	
	return false
end

return Titles
