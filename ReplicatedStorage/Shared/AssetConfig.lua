-- @ScriptType: ModuleScript
-- AssetConfig.lua
-- Central configuration file for all animation and sound asset IDs
-- This file acts as a .env-style configuration for easy asset management
-- 
-- HOW TO USE:
-- 1. Replace placeholder IDs with your actual Roblox asset IDs
-- 2. Format: "rbxassetid://XXXXXXXX" where XXXXXXXX is the asset ID
-- 3. For zombie animations, use modern "rbxassetid://" format instead of legacy "http://www.roblox.com/asset/?id="
-- 4. This file is referenced by FPSConfig, FPSAudioController, StoryConfig, and other systems
-- 5. Update IDs here once; changes propagate throughout the entire game

local AssetConfig = {}

-- ========================================
-- ANIMATION ASSET IDs
-- ========================================

AssetConfig.Animations = {
	-- FPS Weapon Animations
	-- These animations are for first-person viewmodel weapons
	WeaponAnimations = {
		Pistol = {
			idle = "rbxassetid://77700472496946",      -- Idle holding animation
			fire = "rbxassetid://107261819756829",      -- Fire/shoot animation
			reload = "rbxassetid://136927034232244",    -- Reload animation
			equip = "rbxassetid://106310870423679",     -- Draw/equip animation
			sprint = "rbxassetid://102565289526730",    -- Sprint (lowered weapon) animation
			ads = "rbxassetid://0",                     -- Aim down sights animation (placeholder)
		},
		SMG = {
			idle = "rbxassetid://77700472496946",      -- Idle holding animation
			fire = "rbxassetid://107261819756829",      -- Fire/shoot animation
			reload = "rbxassetid://136927034232244",    -- Reload animation
			equip = "rbxassetid://106310870423679",     -- Draw/equip animation
			sprint = "rbxassetid://102565289526730",    -- Sprint animation
			ads = "rbxassetid://0",                     -- Aim down sights animation (placeholder)
		},
		Shotgun = {
			idle = "rbxassetid://77700472496946",      -- Idle holding animation
			fire = "rbxassetid://107261819756829",      -- Fire/shoot animation
			reload = "rbxassetid://136927034232244",    -- Shell-by-shell reload animation
			equip = "rbxassetid://106310870423679",     -- Draw/equip animation
			sprint = "rbxassetid://102565289526730",    -- Sprint animation
			ads = "rbxassetid://0",                     -- Aim down sights animation (placeholder)
		},
		Rifle = {
			idle = "rbxassetid://77700472496946",      -- Idle holding animation
			fire = "rbxassetid://107261819756829",      -- Fire/shoot animation
			reload = "rbxassetid://136927034232244",    -- Reload animation
			equip = "rbxassetid://106310870423679",     -- Draw/equip animation
			sprint = "rbxassetid://102565289526730",    -- Sprint animation
			ads = "rbxassetid://0",                     -- Aim down sights animation (placeholder)
		},
	},

	-- Zombie Animations (R15 Humanoid)
	-- Legacy zombie animations from ServerStorage/ZombieModels/Walker/Animate.lua
	-- Note: These use Roblox default animation IDs. Replace if you have custom zombie animations.
	ZombieAnimations = {
		idle = {
			{ id = "rbxassetid://507766666", weight = 1 },
			{ id = "rbxassetid://507766951", weight = 1 },
			{ id = "rbxassetid://507766388", weight = 9 }
		},
		walk = {
			{ id = "rbxassetid://507777826", weight = 10 }
		},
		run = {
			{ id = "rbxassetid://507767714", weight = 10 }
		},
		swim = {
			{ id = "rbxassetid://507784897", weight = 10 }
		},
		swimidle = {
			{ id = "rbxassetid://507785072", weight = 10 }
		},
		jump = {
			{ id = "rbxassetid://507765000", weight = 10 }
		},
		fall = {
			{ id = "rbxassetid://507767968", weight = 10 }
		},
		climb = {
			{ id = "rbxassetid://507765644", weight = 10 }
		},
		sit = {
			{ id = "rbxassetid://2506281703", weight = 10 }
		},
		toolnone = {
			{ id = "rbxassetid://507768375", weight = 10 }
		},
		toolslash = {
			{ id = "rbxassetid://522635514", weight = 10 }
		},
		toollunge = {
			{ id = "rbxassetid://522638767", weight = 10 }
		},
		wave = {
			{ id = "rbxassetid://507770239", weight = 10 }
		},
		point = {
			{ id = "rbxassetid://507770453", weight = 10 }
		},
		dance = {
			{ id = "rbxassetid://507771019", weight = 10 },
			{ id = "rbxassetid://507771955", weight = 10 },
			{ id = "rbxassetid://507772104", weight = 10 }
		},
		dance2 = {
			{ id = "rbxassetid://507776043", weight = 10 },
			{ id = "rbxassetid://507776720", weight = 10 },
			{ id = "rbxassetid://507776879", weight = 10 }
		},
		dance3 = {
			{ id = "rbxassetid://507777268", weight = 10 },
			{ id = "rbxassetid://507777451", weight = 10 },
			{ id = "rbxassetid://507777623", weight = 10 }
		},
		laugh = {
			{ id = "rbxassetid://507770818", weight = 10 }
		},
		cheer = {
			{ id = "rbxassetid://507770677", weight = 10 }
		},
	},
}

-- ========================================
-- SOUND ASSET IDs
-- ========================================

AssetConfig.Sounds = {
	-- Weapon Fire Sounds
	WeaponFire = {
		Pistol = "rbxassetid://1905367471",        -- Pistol fire sound
		SMG = "rbxassetid://77130830495173",       -- SMG fire sound
		Shotgun = "rbxassetid://8429881678",       -- Shotgun fire sound
		Rifle = "rbxassetid://6862108495",         -- Rifle fire sound
		Default = "rbxassetid://1905367471",       -- Default fire sound (fallback)
	},

	-- Weapon Reload Sounds
	WeaponReload = {
		Pistol = "rbxassetid://138084889",         -- Pistol reload sound
		SMG = "rbxassetid://138084889",            -- SMG reload sound
		Shotgun = "rbxassetid://86072977471971",   -- Shotgun reload sound (shell-by-shell)
		Rifle = "rbxassetid://138084889",          -- Rifle reload sound
		Default = "rbxassetid://138084889",        -- Default reload sound (fallback)
	},

	-- UI & Feedback Sounds
	EmptyClick = "rbxassetid://96880586397913",          -- Click when trying to fire with no ammo
	HeadshotHitmarker = "rbxassetid://131472999032031",  -- Headshot hitmarker sound
	Hitmarker = "rbxassetid://79356893392985",           -- Standard hitmarker sound
	KillConfirm = "rbxassetid://86596819653473",         -- Kill confirmation sound

	-- Movement Sounds
	Footsteps = {
		Concrete = "rbxassetid://127328919401626", -- Footstep on concrete
		Grass = "rbxassetid://126726565555894",    -- Footstep on grass
		Metal = "rbxassetid://127328919401626",    -- Footstep on metal
		Wood = "rbxassetid://128186716150447",     -- Footstep on wood
		Default = "rbxassetid://127328919401626",  -- Default footstep sound (fallback)
	},

	-- Damage Feedback Sounds
	DamageTaken = "rbxassetid://106256862427202",        -- Sound when player takes damage
	LowHealthHeartbeat = "rbxassetid://120008174551190", -- Heartbeat sound when low HP

	-- Menu/UI Navigation Sounds
	MenuSelect = "rbxassetid://104003605923230",   -- Menu item selection sound
	MenuNavigate = "rbxassetid://9055474333",      -- Menu navigation sound
}

-- ========================================
-- MUSIC ASSET IDs
-- ========================================

AssetConfig.Music = {
	-- Title/Menu Music
	TitleTheme = {
		SoundId = "rbxassetid://134645167323648",  -- Title screen theme music
		Volume = 0.5,
		Looped = true
	},

	-- Gameplay Music
	GameplayAmbient = {
		SoundId = "rbxassetid://83451793513373",   -- Calm ambient gameplay music
		Volume = 0.3,
		Looped = true
	},
	CombatIntense = {
		SoundId = "rbxassetid://1131937949",       -- Intense combat music
		Volume = 0.6,
		Looped = true
	},

	-- End-Game Music
	Victory = {
		SoundId = "rbxassetid://135116298613253",  -- Victory/win music
		Volume = 0.7,
		Looped = false
	},
	Defeat = {
		SoundId = "rbxassetid://1839772694",       -- Defeat/game over music
		Volume = 0.5,
		Looped = false
	},

	-- Credits Music
	Credits = {
		SoundId = "rbxassetid://81857578704617",   -- End credits music
		Volume = 0.4,
		Looped = true
	}
}

-- ========================================
-- VOICEOVER AUDIO IDs
-- ========================================
-- NOTE: Audio assets not yet created - these are placeholders
-- When voiceover assets are created, replace the empty strings with actual asset IDs

AssetConfig.Voiceovers = {
	-- Epilogue Voiceovers
	EpilogueIntro = {
		SoundId = "",  -- Placeholder - epilogue introduction voiceover
		Duration = 10
	},
	
	-- Wave Announcements
	WaveStart = {
		SoundId = "",  -- Placeholder - "Wave incoming" announcement
		Duration = 3
	},
	WaveComplete = {
		SoundId = "",  -- Placeholder - "Wave complete" announcement
		Duration = 2
	},
	
	-- Synthesis Events
	SynthesisStart = {
		SoundId = "",  -- Placeholder - "Cure synthesis initiated"
		Duration = 4
	},
	SynthesisWarning = {
		SoundId = "",  -- Placeholder - "Increased hostile activity detected"
		Duration = 3
	},
	SynthesisComplete = {
		SoundId = "",  -- Placeholder - "Synthesis complete"
		Duration = 3
	},
	
	-- Victory/Defeat
	Victory = {
		SoundId = "",  -- Placeholder - "Cure complete, outbreak contained"
		Duration = 5
	},
	Defeat = {
		SoundId = "",  -- Placeholder - "Base compromised, evacuation initiated"
		Duration = 5
	},
	
	-- Alliance Events
	AllianceFormed = {
		SoundId = "",  -- Placeholder - "Alliance established"
		Duration = 2
	},
	AllianceBetrayed = {
		SoundId = "",  -- Placeholder - "Alliance broken"
		Duration = 2
	}
}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Get a specific animation ID by weapon type and animation name
function AssetConfig:GetWeaponAnimation(weaponType, animName)
	if self.Animations.WeaponAnimations[weaponType] then
		return self.Animations.WeaponAnimations[weaponType][animName]
	end
	return nil
end

-- Get a specific sound ID by category
function AssetConfig:GetSound(category, subcategory)
	if subcategory then
		if self.Sounds[category] and self.Sounds[category][subcategory] then
			return self.Sounds[category][subcategory]
		end
	else
		return self.Sounds[category]
	end
	return nil
end

-- Get a specific music configuration
function AssetConfig:GetMusic(musicName)
	return self.Music[musicName]
end

-- Get a specific voiceover configuration
function AssetConfig:GetVoiceover(voiceoverName)
	return self.Voiceovers[voiceoverName]
end

return AssetConfig
