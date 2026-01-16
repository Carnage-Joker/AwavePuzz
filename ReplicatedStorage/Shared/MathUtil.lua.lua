-- @ScriptType: Script
-- MathUtil.lua
-- Shared mathematical utility functions used across client and server
-- Consolidates duplicate utility functions from multiple files

local MathUtil = {}

-- Clamp a value between min and max
function MathUtil.clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

-- Linear interpolation between a and b by factor t
function MathUtil.lerp(a, b, t)
	return a + (b - a) * t
end

-- Smooth interpolation using cosine
function MathUtil.smoothLerp(a, b, t)
	local smoothT = (1 - math.cos(t * math.pi)) / 2
	return MathUtil.lerp(a, b, smoothT)
end

-- Map a value from one range to another
function MathUtil.map(value, inMin, inMax, outMin, outMax)
	-- Validate input range to prevent division by zero
	if inMin == inMax then
		warn("[MathUtil.map] Input range is zero (inMin == inMax). Returning outMin.")
		return outMin
	end

	-- Validate that the input range is not inverted
	if inMax < inMin then
		warn("[MathUtil.map] Input range is inverted (inMax < inMin). Swapping inMin and inMax.")
		inMin, inMax = inMax, inMin
	end
	return outMin + (outMax - outMin) * ((value - inMin) / (inMax - inMin))
end

-- Round to nearest integer
function MathUtil.round(value)
	return math.floor(value + 0.5)
end

-- Round to specified number of decimal places
function MathUtil.roundToDecimal(value, decimals)
	local mult = 10 ^ decimals
	return math.floor(value * mult + 0.5) / mult
end

return MathUtil
