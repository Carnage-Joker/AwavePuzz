-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
-- WeaponValues.lua
-- Defines the value/worth of each weapon for proportional transfer calculations
-- Used by betrayal system to determine weapon transfers

local WeaponValues = {}

-- Base weapon values (in currency equivalent)
-- Higher values = more valuable weapons that get stolen first
WeaponValues.Values = {
	Pistol = 0,           -- Starting weapon, no value
	SMG = 450,            -- Matches shop price
	Shotgun = 700,        -- Matches shop price
	Rifle = 900,          -- Matches shop price
}

-- Get the value of a weapon
function WeaponValues.getValue(weaponId)
	return WeaponValues.Values[weaponId] or 0
end

-- Get total value of a weapon list
function WeaponValues.getTotalValue(weaponList)
	local total = 0
	for _, weaponId in ipairs(weaponList) do
		total = total + WeaponValues.getValue(weaponId)
	end
	return total
end

-- Sort weapons by value (descending), then by weaponId (ascending) for deterministic ordering
function WeaponValues.sortWeapons(weaponList)
	local sorted = {}
	for _, weaponId in ipairs(weaponList) do
		table.insert(sorted, weaponId)
	end

	table.sort(sorted, function(a, b)
		local valueA = WeaponValues.getValue(a)
		local valueB = WeaponValues.getValue(b)

		if valueA == valueB then
			-- Tiebreaker: alphabetical by weaponId
			return a < b
		end

		-- Higher value first
		return valueA > valueB
	end)

	return sorted
end

return WeaponValues