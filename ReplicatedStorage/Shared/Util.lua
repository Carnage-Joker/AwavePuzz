--[[
	Util.lua
	Shared utility functions
]]

local Util = {}

-- Deep copy a table
function Util.deepCopy(original)
	local copy
	if type(original) == "table" then
		copy = {}
		for key, value in next, original, nil do
			copy[Util.deepCopy(key)] = Util.deepCopy(value)
		end
		setmetatable(copy, Util.deepCopy(getmetatable(original)))
	else
		copy = original
	end
	return copy
end

-- Merge two tables (shallow)
function Util.merge(target, source)
	for key, value in pairs(source) do
		target[key] = value
	end
	return target
end

-- Check if table contains value
function Util.contains(tbl, value)
	for _, v in ipairs(tbl) do
		if v == value then
			return true
		end
	end
	return false
end

-- Get table size (works for dictionaries)
function Util.tableSize(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

-- Reconcile profile with defaults (fill in missing fields)
function Util.reconcileProfile(profile, defaults)
	local reconciled = Util.deepCopy(defaults)
	
	for key, value in pairs(profile) do
		if type(value) == "table" and type(reconciled[key]) == "table" then
			-- Recursively reconcile nested tables
			reconciled[key] = Util.merge(Util.deepCopy(reconciled[key]), value)
		else
			reconciled[key] = value
		end
	end
	
	return reconciled
end

-- Format number with commas
function Util.formatNumber(num)
	local formatted = tostring(num)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then
			break
		end
	end
	return formatted
end

return Util
