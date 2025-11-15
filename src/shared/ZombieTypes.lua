-- ZombieTypes.lua
-- Configuration for different zombie types and their stats

local ZombieTypes = {
	Walker = {
		Model = "Walker",
		Speed = 10,
		Damage = 10,
		Health = 60,
		Reward = 5,
		Description = "Basic slow zombie, easy to kill but dangerous in numbers"
	},
	Runner = {
		Model = "Runner",
		Speed = 18,
		Damage = 8,
		Health = 45,
		Reward = 6,
		Description = "Fast zombie that can quickly close distance"
	},
	Brute = {
		Model = "Brute",
		Speed = 8,
		Damage = 20,
		Health = 150,
		Reward = 20,
		Description = "Tank zombie with high health and damage"
	},
	Spitter = {
		Model = "Spitter",
		Speed = 12,
		Damage = 6,
		Health = 70,
		Reward = 12,
		Description = "Ranged zombie that attacks from distance"
	},
	Boss = {
		Model = "Boss",
		Speed = 10,
		Damage = 28,
		Health = 550,
		Reward = 100,
		Description = "Powerful boss zombie with massive health"
	}
}

return ZombieTypes
