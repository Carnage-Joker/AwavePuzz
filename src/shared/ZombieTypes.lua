-- ZombieTypes.lua
-- Configuration for different zombie types and their stats
-- Extended with tactical AI parameters for each archetype

local ZombieTypes = {
	Walker = {
		Model = "Walker",
		Speed = 10,
		Damage = 10,
		Health = 60,
		Reward = 5,
		Description = "Basic slow zombie, easy to kill but dangerous in numbers",
		-- AI Parameters
		AIBehavior = "standard",
		RetargetInterval = 1.0,
		SlotPreference = "middle", -- inner, middle, outer
		FlankChance = 0.1,
	},
	Runner = {
		Model = "Runner",
		Speed = 18,
		Damage = 8,
		Health = 45,
		Reward = 6,
		Description = "Fast zombie that can quickly close distance",
		-- AI Parameters
		AIBehavior = "aggressive",
		RetargetInterval = 0.6,
		SlotPreference = "inner",
		FlankChance = 0.3,
	},
	Brute = {
		Model = "Brute",
		Speed = 8,
		Damage = 20,
		Health = 150,
		Reward = 20,
		Description = "Tank zombie with high health and damage",
		-- AI Parameters
		AIBehavior = "bruiser",
		RetargetInterval = 1.2,
		SlotPreference = "inner",
		FlankChance = 0.0,
		BasePreference = 0.7, -- Higher chance to target base
	},
	Spitter = {
		Model = "Spitter",
		Speed = 12,
		Damage = 6,
		Health = 70,
		Reward = 12,
		Description = "Ranged zombie that attacks from distance",
		-- AI Parameters
		AIBehavior = "ranged",
		RetargetInterval = 0.8,
		SlotPreference = "outer",
		FlankChance = 0.7,
		MinRange = 15,
		IdealRange = 25,
		MaxRange = 40,
	},
	Boss = {
		Model = "Boss",
		Speed = 10,
		Damage = 28,
		Health = 550,
		Reward = 100,
		Description = "Powerful boss zombie with massive health",
		-- AI Parameters
		AIBehavior = "boss",
		RetargetInterval = 0.8,
		SlotPreference = "middle",
		FlankChance = 0.2,
		HasAura = true,
		AuraRadius = 40,
	},
	-- New Archetypes
	Flanker = {
		Model = "Runner", -- Reuse Runner model
		Speed = 20,
		Damage = 8,
		Health = 40,
		Reward = 8,
		Description = "Fast zombie that prioritizes side and back attacks",
		-- AI Parameters
		AIBehavior = "flanker",
		RetargetInterval = 0.5,
		SlotPreference = "middle",
		FlankChance = 0.9, -- Almost always flanks
		PreferBackSlots = true,
	},
	Bruiser = {
		Model = "Brute", -- Reuse Brute model
		Speed = 7,
		Damage = 22,
		Health = 180,
		Reward = 25,
		Description = "Slow tank that pushes to base and breaks formations",
		-- AI Parameters
		AIBehavior = "bruiser",
		RetargetInterval = 1.5,
		SlotPreference = "inner",
		FlankChance = 0.0,
		BasePreference = 0.8, -- Strongly prefers base
		BaseDamageBonus = 1.5, -- 50% more damage to base
	},
	Screamer = {
		Model = "Walker", -- Reuse Walker model
		Speed = 11,
		Damage = 7,
		Health = 50,
		Reward = 10,
		Description = "Support zombie that calls others to swarm targets",
		-- AI Parameters
		AIBehavior = "screamer",
		RetargetInterval = 1.0,
		SlotPreference = "middle",
		FlankChance = 0.2,
		CallCooldown = 10.0, -- Seconds between calls
		CallRadius = 30, -- Radius of call effect
		CallDuration = 5.0, -- How long call effect lasts
	},
	Breacher = {
		Model = "Brute", -- Reuse Brute model
		Speed = 9,
		Damage = 15,
		Health = 120,
		Reward = 18,
		Description = "Specialized in breaking base defenses, weak vs players",
		-- AI Parameters
		AIBehavior = "breacher",
		RetargetInterval = 1.0,
		SlotPreference = "inner",
		FlankChance = 0.0,
		BasePreference = 0.9, -- Almost always targets base
		BaseDamageBonus = 2.0, -- Double damage to base
		PlayerDamagePenalty = 0.5, -- Half damage to players
	}
}

return ZombieTypes
