--[[
	ColorPalettes.lua
	Color palette definitions and harmony scoring
]]

local ColorPalettes = {}

-- Define color palettes
ColorPalettes.palettes = {
	Pastel = {"Pink", "Lavender", "MintGreen", "PeachPuff", "LightBlue"},
	Monochrome = {"Black", "White", "Gray", "Silver", "Charcoal"},
	Warm = {"Red", "Orange", "Gold", "Coral", "Amber"},
	Cool = {"Blue", "Teal", "Purple", "Indigo", "Cyan"},
	Nature = {"Green", "Brown", "Tan", "Olive", "Sage"},
	Vibrant = {"Magenta", "Yellow", "Lime", "Turquoise", "HotPink"},
	Elegant = {"Navy", "Burgundy", "Ivory", "Champagne", "Platinum"},
	Casual = {"Denim", "Khaki", "Cream", "SkyBlue", "Beige"},
}

-- Harmony scoring rules
-- Items from the same palette = high harmony
-- Items from complementary palettes = medium harmony
-- Mixed random palettes = low harmony
ColorPalettes.harmonyPairs = {
	-- Same palette = perfect (handled separately)
	-- Complementary pairs
	{palette1 = "Warm", palette2 = "Cool", score = 0.7},
	{palette1 = "Pastel", palette2 = "Elegant", score = 0.8},
	{palette1 = "Monochrome", palette2 = "Vibrant", score = 0.6},
	{palette1 = "Nature", palette2 = "Casual", score = 0.75},
}

-- Calculate color harmony score for an outfit
-- Takes an array of items with paletteTags
-- Returns a score from 0-100
function ColorPalettes.calculateHarmony(items)
	if #items == 0 then
		return 0
	end
	
	-- Collect all palette tags from all items
	local allPalettes = {}
	for _, item in ipairs(items) do
		for _, palette in ipairs(item.paletteTags or {}) do
			allPalettes[palette] = (allPalettes[palette] or 0) + 1
		end
	end
	
	-- If only one palette is used (monochromatic), high score
	local paletteCount = 0
	for _ in pairs(allPalettes) do
		paletteCount = paletteCount + 1
	end
	
	if paletteCount == 1 then
		return 100  -- Perfect monochromatic harmony
	elseif paletteCount == 2 then
		-- Check if it's a good complementary pair
		local palettes = {}
		for palette, _ in pairs(allPalettes) do
			table.insert(palettes, palette)
		end
		
		for _, pair in ipairs(ColorPalettes.harmonyPairs) do
			if (palettes[1] == pair.palette1 and palettes[2] == pair.palette2) or
			   (palettes[1] == pair.palette2 and palettes[2] == pair.palette1) then
				return math.floor(pair.score * 100)
			end
		end
		
		-- Not a defined pair, medium score
		return 60
	else
		-- Too many palettes, lower score
		return math.max(20, 70 - (paletteCount * 10))
	end
end

-- Get palette color list
function ColorPalettes.getPalette(paletteName: string)
	return ColorPalettes.palettes[paletteName]
end

return ColorPalettes
