-- @ScriptType: Script
-- WaveConfig.lua
-- Configuration for wave progression and zombie composition

local WaveConfig = {}

WaveConfig.Waves = {
	-- Wave 1: Tutorial wave with only walkers
	{
		Number = 1,
		TimeLimit = 120, -- 2 minutes
		ZombieCount = 8,
		Composition = {
			Walker = 8
		}
	},

	-- Wave 2: Introduce runners
	{
		Number = 2,
		TimeLimit = 150,
		ZombieCount = 12,
		Composition = {
			Walker = 8,
			Runner = 4
		}
	},

	-- Wave 3: More variety
	{
		Number = 3,
		TimeLimit = 180,
		ZombieCount = 15,
		Composition = {
			Walker = 8,
			Runner = 5,
			Brute = 2
		}
	},

	-- Wave 4: Adding spitters
	{
		Number = 4,
		TimeLimit = 180,
		ZombieCount = 18,
		Composition = {
			Walker = 8,
			Runner = 6,
			Brute = 2,
			Spitter = 2
		}
	},

	-- Wave 5: Boss wave
	{
		Number = 5,
		TimeLimit = 240,
		ZombieCount = 21,
		Composition = {
			Walker = 10,
			Runner = 5,
			Brute = 3,
			Spitter = 2,
			Boss = 1
		}
	},

	-- Wave 6: Post-boss difficulty spike
	{
		Number = 6,
		TimeLimit = 200,
		ZombieCount = 25,
		Composition = {
			Walker = 10,
			Runner = 8,
			Brute = 4,
			Spitter = 3
		}
	},

	-- Wave 7: Double trouble
	{
		Number = 7,
		TimeLimit = 240,
		ZombieCount = 30,
		Composition = {
			Walker = 12,
			Runner = 10,
			Brute = 5,
			Spitter = 3
		}
	},

	-- Wave 8: Multiple brutes
	{
		Number = 8,
		TimeLimit = 240,
		ZombieCount = 32,
		Composition = {
			Walker = 10,
			Runner = 10,
			Brute = 8,
			Spitter = 4
		}
	},

	-- Wave 9: Nightmare mode
	{
		Number = 9,
		TimeLimit = 300,
		ZombieCount = 38,
		Composition = {
			Walker = 12,
			Runner = 12,
			Brute = 8,
			Spitter = 4,
			Boss = 2
		}
	},

	-- Wave 10: Final wave
	{
		Number = 10,
		TimeLimit = 360,
		ZombieCount = 45,
		Composition = {
			Walker = 15,
			Runner = 12,
			Brute = 10,
			Spitter = 5,
			Boss = 3
		}
	}
}

-- Function to get wave configuration
function WaveConfig.getWave(waveNumber)
	return WaveConfig.Waves[waveNumber]
end

-- Function to get total number of configured waves
function WaveConfig.getTotalWaves()
	return #WaveConfig.Waves
end

-- Function to check if a wave exists
function WaveConfig.isValidWave(waveNumber)
	return waveNumber >= 1 and waveNumber <= #WaveConfig.Waves
end

return WaveConfig
