--[[
	Activities.lua
	Defines activities players can complete for rewards
]]

local Activities = {}

-- Activity definitions
-- Fields:
--   id: unique identifier
--   name: display name
--   description: what the activity involves
--   cooldown: seconds before can repeat
--   rewards: what player receives
--     - statRewards: {statName = amount}
--     - currencyRewards: {currencyName = amount}
Activities.list = {
	{
		id = "mirror_pose",
		name = "Mirror Pose Practice",
		description = "Practice elegant poses in front of the mirror",
		cooldown = 300,  -- 5 minutes
		rewards = {
			statRewards = {
				Confidence = 5,
				Grace = 3,
			},
			currencyRewards = {
				Coins = 50,
			},
		},
	},
	{
		id = "styling_desk",
		name = "Styling Desk Organization",
		description = "Organize your styling desk with care and attention",
		cooldown = 300,  -- 5 minutes
		rewards = {
			statRewards = {
				Care = 8,
				Elegance = 2,
			},
			currencyRewards = {
				Coins = 50,
			},
		},
	},
	{
		id = "garden_decor",
		name = "Garden Decoration",
		description = "Arrange flowers and decorations in the garden",
		cooldown = 300,  -- 5 minutes
		rewards = {
			statRewards = {
				Elegance = 6,
				Care = 4,
			},
			currencyRewards = {
				Coins = 60,
				Gems = 1,  -- Small gem reward
			},
		},
	},
}

-- Get activity by ID
function Activities.getActivity(activityId: string)
	for _, activity in ipairs(Activities.list) do
		if activity.id == activityId then
			return activity
		end
	end
	return nil
end

return Activities
