-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
-- PuzzleConfig.lua
-- Configuration for puzzle mini-games required to synthesize cure components
-- Each component type requires solving a specific puzzle when 5 pieces are collected

local PuzzleConfig = {}

-- Puzzle types available in the game
PuzzleConfig.PuzzleTypes = {
	MATHEMATICAL = "Mathematical",
	PATTERN = "Pattern",
	COLOR = "Color",
	LOGIC = "Logic",
	ABSTRACT = "Abstract",
	SYNTHESIS = "Synthesis"
}

-- Component-specific puzzle definitions
-- Each component requires a puzzle to be solved at a cure station before it can be used
PuzzleConfig.ComponentPuzzles = {
	["Chemical A"] = {
		type = PuzzleConfig.PuzzleTypes.MATHEMATICAL,
		name = "Arithmetic Sequence",
		description = "Solve the mathematical sequence to stabilize Chemical A",
		difficulty = "Medium",
		-- Puzzle generates a sequence with pattern, player must find missing numbers
		-- Example: 2, 4, 8, ?, 32 (answer: 16)
		timeLimit = 60, -- seconds
	},

	["Chemical B"] = {
		type = PuzzleConfig.PuzzleTypes.PATTERN,
		name = "Pattern Recognition",
		description = "Identify the pattern to complete Chemical B synthesis",
		difficulty = "Medium",
		-- Puzzle shows a series of shapes/symbols with a pattern, player must select next
		-- Example: Circle, Square, Triangle, Circle, Square, ? (answer: Triangle)
		timeLimit = 60,
	},

	["Biological Sample"] = {
		type = PuzzleConfig.PuzzleTypes.COLOR,
		name = "Chromatic Alignment",
		description = "Arrange the color spectrum to activate the biological sample",
		difficulty = "Easy",
		-- Puzzle shows scrambled colors, player must arrange them in correct order
		-- Example: Arrange RGB gradient correctly
		timeLimit = 45,
	},

	["Research Notes"] = {
		type = PuzzleConfig.PuzzleTypes.LOGIC,
		name = "Deduction Grid",
		description = "Use logical deduction to decode the research notes",
		difficulty = "Hard",
		-- Puzzle presents clues, player must deduce correct arrangement
		-- Example: 3 scientists, 3 elements, 3 locations - match correctly using clues
		timeLimit = 90,
	},

	["Catalyst"] = {
		type = PuzzleConfig.PuzzleTypes.ABSTRACT,
		name = "Neural Network",
		description = "Connect the nodes to complete the catalyst circuit",
		difficulty = "Medium",
		-- Puzzle shows nodes that need to be connected following rules
		-- Example: Connect all nodes without crossing lines, or create specific pattern
		timeLimit = 60,
	}
}

-- Final synthesis puzzle - combines elements from all component puzzles
PuzzleConfig.FinalPuzzle = {
	type = PuzzleConfig.PuzzleTypes.SYNTHESIS,
	name = "Cure Synthesis Protocol",
	description = "Combine all components in the correct sequence to synthesize the cure",
	difficulty = "Very Hard",
	timeLimit = 120,
	-- Requires solving a multi-stage puzzle that incorporates elements from all 5 component puzzles
	-- Stage 1: Math calculation
	-- Stage 2: Pattern recognition
	-- Stage 3: Color arrangement
	-- Stage 4: Logic deduction
	-- Stage 5: Network connection
}

-- Mathematical puzzle generation
PuzzleConfig.MathPuzzles = {
	-- Arithmetic sequences
	{
		type = "arithmetic",
		generator = function()
			local start = math.random(1, 10)
			local step = math.random(2, 5)
			local sequence = {}
			for i = 1, 5 do
				sequence[i] = start + (i - 1) * step
			end
			-- Remove one element for player to find
			local missingIndex = math.random(2, 4)
			local answer = sequence[missingIndex]
			sequence[missingIndex] = nil
			return {sequence = sequence, answer = answer, missingIndex = missingIndex}
		end
	},
	-- Geometric sequences
	{
		type = "geometric",
		generator = function()
			local start = math.random(1, 5)
			local multiplier = math.random(2, 3)
			local sequence = {}
			for i = 1, 5 do
				sequence[i] = start * (multiplier ^ (i - 1))
			end
			local missingIndex = math.random(2, 4)
			local answer = sequence[missingIndex]
			sequence[missingIndex] = nil
			return {sequence = sequence, answer = answer, missingIndex = missingIndex}
		end
	},
	-- Simple equations
	{
		type = "equation",
		generator = function()
			local a = math.random(1, 10)
			local b = math.random(1, 10)
			local operator = math.random(1, 3)
			local equation, answer
			if operator == 1 then
				equation = string.format("%d + %d = ?", a, b)
				answer = a + b
			elseif operator == 2 then
				equation = string.format("%d × %d = ?", a, b)
				answer = a * b
			else
				local product = a * b
				equation = string.format("%d ÷ %d = ?", product, a)
				answer = b
			end
			return {equation = equation, answer = answer}
		end
	}
}

-- Pattern puzzle templates
PuzzleConfig.PatternPuzzles = {
	{
		type = "shape_sequence",
		patterns = {
			{"Circle", "Square", "Triangle"},
			{"Star", "Diamond", "Hexagon"},
			{"Plus", "Cross", "Circle"}
		}
	},
	{
		type = "number_pattern",
		patterns = {
			{2, 4, 6}, -- even numbers
			{1, 3, 5}, -- odd numbers
			{1, 4, 9}, -- squares
		}
	},
	{
		type = "rotation",
		-- Visual patterns that rotate or transform
		patterns = {"rotate90", "rotate180", "mirror", "flip"}
	}
}

-- Color puzzle configurations
PuzzleConfig.ColorPuzzles = {
	{
		type = "spectrum",
		colors = {
			Color3.fromRGB(255, 0, 0),     -- Red
			Color3.fromRGB(255, 127, 0),   -- Orange
			Color3.fromRGB(255, 255, 0),   -- Yellow
			Color3.fromRGB(0, 255, 0),     -- Green
			Color3.fromRGB(0, 0, 255),     -- Blue
			Color3.fromRGB(75, 0, 130),    -- Indigo
			Color3.fromRGB(148, 0, 211),   -- Violet
		}
	},
	{
		type = "matching",
		-- Match colors to their complementary colors
		pairs = {
			{Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 255)},   -- Red - Cyan
			{Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 0, 255)},   -- Green - Magenta
			{Color3.fromRGB(0, 0, 255), Color3.fromRGB(255, 255, 0)},   -- Blue - Yellow
		}
	}
}

-- Logic puzzle templates (deduction grids)
PuzzleConfig.LogicPuzzles = {
	{
		type = "scientists",
		-- 3 scientists studied 3 elements in 3 different labs
		elements = {"Compound X", "Enzyme Y", "Protein Z"},
		scientists = {"Dr. Smith", "Dr. Jones", "Dr. Brown"},
		labs = {"Lab A", "Lab B", "Lab C"},
		-- Clues will be generated to lead to unique solution
	},
	{
		type = "sequence",
		-- Find the correct order based on clues
		items = {"Alpha", "Beta", "Gamma", "Delta"},
	}
}

-- Abstract puzzle configurations (node connection)
PuzzleConfig.AbstractPuzzles = {
	{
		type = "connect_all",
		-- Connect all nodes without crossing lines
		nodeCount = 6,
		difficulty = "medium"
	},
	{
		type = "path_find",
		-- Find the path that connects start to end visiting all nodes
		nodeCount = 8,
		difficulty = "hard"
	},
	{
		type = "circuit",
		-- Create a complete circuit through all nodes
		nodeCount = 6,
		difficulty = "medium"
	}
}

-- Puzzle rewards and progression
PuzzleConfig.Rewards = {
	componentPuzzleSolved = 50, -- Currency reward per component puzzle
	finalPuzzleSolved = 200, -- Currency reward for final synthesis
	timeBonusMultiplier = 1.5, -- Bonus for solving quickly
}

-- Puzzle failure penalties
PuzzleConfig.Penalties = {
	retryDelay = 10, -- Seconds before can retry failed puzzle
	maxAttempts = 3, -- Max attempts per player per puzzle (0 = unlimited)
	failureShareWithAllies = true, -- If true, allies can retry failed puzzles
}

-- Betrayal mechanics for puzzles
PuzzleConfig.BetrayalMechanics = {
	canStealSolvedPuzzles = true, -- Betraying allows stealing completed puzzles
	canStealComponents = true, -- Betraying allows stealing collected components
	betrayalPuzzleResetChance = 0.5, -- 50% chance betrayed player's puzzles reset
	stealPercentage = 0.5, -- Steal 50% of victim's progress
}

-- Helper function to get puzzle config for a component
function PuzzleConfig.getPuzzleForComponent(componentName)
	return PuzzleConfig.ComponentPuzzles[componentName]
end

-- Helper function to get all required puzzles
function PuzzleConfig.getAllComponentPuzzles()
	return PuzzleConfig.ComponentPuzzles
end

-- Helper function to check if all puzzles are solved
function PuzzleConfig.areAllPuzzlesSolved(solvedPuzzles)
	for componentName, _ in pairs(PuzzleConfig.ComponentPuzzles) do
		if not solvedPuzzles[componentName] then
			return false
		end
	end
	return true
end

-- Generate a random mathematical puzzle
function PuzzleConfig.generateMathPuzzle()
	local puzzleTemplate = PuzzleConfig.MathPuzzles[math.random(1, #PuzzleConfig.MathPuzzles)]
	return puzzleTemplate.generator()
end

-- Generate a random pattern puzzle
function PuzzleConfig.generatePatternPuzzle()
	-- Wrap in pcall for safety
	local success, result = pcall(function()
		local template = PuzzleConfig.PatternPuzzles[math.random(1, #PuzzleConfig.PatternPuzzles)]
		
		-- Handle different pattern types
		if template.type == "rotation" then
			-- For rotation patterns, use the configured pattern list from the template
			local pattern = template.patterns
			if type(pattern) ~= "table" or #pattern < 3 then
				error("Rotation pattern must be a table with at least 3 entries")
			end

			local sequence = {}
			for i = 1, #pattern do
				sequence[i] = pattern[i]
			end
			local missingIndex = math.random(2, #sequence - 1)
			local answer = sequence[missingIndex]
			sequence[missingIndex] = nil
			return {sequence = sequence, answer = answer, missingIndex = missingIndex, type = template.type}
		end
		
		-- For shape_sequence and number_pattern types
		local pattern = template.patterns[math.random(1, #template.patterns)]
		
		-- Ensure pattern is a table
		if type(pattern) ~= "table" then
			error("Pattern must be a table")
		end
		
		-- Generate sequence with missing element
		local sequence = {}
		for i = 1, #pattern do
			sequence[i] = pattern[(i - 1) % #pattern + 1]
		end
		table.insert(sequence, pattern[1]) -- Add one more to complete cycle
		
		-- Ensure we have enough elements for a missing index
		if #sequence < 3 then
			error("Sequence too short")
		end
		
		local missingIndex = math.random(2, #sequence - 1)
		local answer = sequence[missingIndex]
		sequence[missingIndex] = nil
		return {sequence = sequence, answer = answer, missingIndex = missingIndex, type = template.type}
	end)
	
	if success then
		return result
	else
		-- Safe fallback if generation fails
		warn("[PuzzleConfig] Pattern puzzle generation failed:", result, "- using fallback")
		return {
			type = "pattern",
			sequence = {2, 4, nil, 8},
			answer = 6,
			missingIndex = 3,
			prompt = "What comes next? 2, 4, ?, 8"
		}
	end
end

return PuzzleConfig
