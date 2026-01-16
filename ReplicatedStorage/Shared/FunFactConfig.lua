-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
-- FunFactConfig.lua
-- Configuration for randomized loading/downtime fun facts
-- Facts are categorized and have unlock conditions for progressive revelation

local FunFactConfig = {}

-- Fact categories
FunFactConfig.Categories = {
	LORE = "Lore",
	MECHANICS = "Mechanics",
	STATISTICS = "Statistics",
	DARK_HUMOR = "DarkHumor",
	PSYCHOLOGY = "Psychology"
}

-- Unlock condition types
FunFactConfig.UnlockTypes = {
	ALWAYS = "Always",
	WAVE = "Wave",
	BETRAYALS_COMMITTED = "BetrayalsCommitted",
	BETRAYALS_SURVIVED = "BetrayalsSurvived",
	CURE_ATTEMPTS = "CureAttempts",
	DEATHS = "Deaths"
}

-- Fun facts pool with categorization and unlock conditions
FunFactConfig.Facts = {
	-- LORE (Available immediately)
	{
		id = "lore_001",
		text = "The facility has been active for 23 days. You're part of the cleanup crew.",
		category = FunFactConfig.Categories.LORE,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "lore_002",
		text = "The Aether Virus doesn't kill. It transforms. No one knows if consciousness remains.",
		category = FunFactConfig.Categories.LORE,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "lore_003",
		text = "Research Team Alpha had the cure within reach. They never completed it.",
		category = FunFactConfig.Categories.LORE,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "lore_004",
		text = "The infected retain muscle memory. Former security personnel are especially dangerous.",
		category = FunFactConfig.Categories.LORE,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "lore_005",
		text = "Each component was hidden deliberately. The first team didn't trust each other either.",
		category = FunFactConfig.Categories.LORE,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "lore_006",
		text = "The base was built in 72 hours. It's held for 23 days. Will you make it 24?",
		category = FunFactConfig.Categories.LORE,
		unlockType = FunFactConfig.UnlockTypes.WAVE,
		unlockValue = 5
	},
	{
		id = "lore_007",
		text = "The convergence accelerates with each wave. They're learning from your tactics.",
		category = FunFactConfig.Categories.LORE,
		unlockType = FunFactConfig.UnlockTypes.WAVE,
		unlockValue = 3
	},
	{
		id = "lore_008",
		text = "Some infected appear to coordinate. Neural degradation may not be complete.",
		category = FunFactConfig.Categories.LORE,
		unlockType = FunFactConfig.UnlockTypes.WAVE,
		unlockValue = 7
	},

	-- MECHANICS (Subtle hints, not explicit tutorials)
	{
		id = "mech_001",
		text = "The cure station remains operational. Someone died maintaining it.",
		category = FunFactConfig.Categories.MECHANICS,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "mech_002",
		text = "Synthesis takes time. The infected won't wait.",
		category = FunFactConfig.Categories.MECHANICS,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "mech_003",
		text = "Allied forces don't register as hostile. Friendly fire protocols disabled.",
		category = FunFactConfig.Categories.MECHANICS,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "mech_004",
		text = "Resources pool among allies. So do risks.",
		category = FunFactConfig.Categories.MECHANICS,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "mech_005",
		text = "Base integrity failure is absolute. No warnings. No second chances.",
		category = FunFactConfig.Categories.MECHANICS,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "mech_006",
		text = "Synthesis puzzles were designed under combat conditions. Good luck.",
		category = FunFactConfig.Categories.MECHANICS,
		unlockType = FunFactConfig.UnlockTypes.CURE_ATTEMPTS,
		unlockValue = 1
	},
	{
		id = "mech_007",
		text = "The infected intensify attacks during synthesis. As if they know.",
		category = FunFactConfig.Categories.MECHANICS,
		unlockType = FunFactConfig.UnlockTypes.CURE_ATTEMPTS,
		unlockValue = 1
	},
	{
		id = "mech_008",
		text = "Failed synthesis wastes components. Choose your moment carefully.",
		category = FunFactConfig.Categories.MECHANICS,
		unlockType = FunFactConfig.UnlockTypes.CURE_ATTEMPTS,
		unlockValue = 2
	},

	-- STATISTICS (Meta information about player behavior)
	{
		id = "stat_001",
		text = "73% of teams form alliances. 68% of alliances end in betrayal.",
		category = FunFactConfig.Categories.STATISTICS,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "stat_002",
		text = "Solo players survive an average of 4.2 waves. Allied teams: 7.8 waves.",
		category = FunFactConfig.Categories.STATISTICS,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "stat_003",
		text = "92% of synthesis attempts fail during zombie waves 8+.",
		category = FunFactConfig.Categories.STATISTICS,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "stat_004",
		text = "Betrayers who succeed gain 75% of pooled resources. Worth considering?",
		category = FunFactConfig.Categories.STATISTICS,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "stat_005",
		text = "Average base survival time: 18 minutes. Your time starts now.",
		category = FunFactConfig.Categories.STATISTICS,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "stat_006",
		text = "Failed betrayers lose everything. All resources. All progress. All weapons.",
		category = FunFactConfig.Categories.STATISTICS,
		unlockType = FunFactConfig.UnlockTypes.BETRAYALS_COMMITTED,
		unlockValue = 1
	},
	{
		id = "stat_007",
		text = "Only 12% of players complete the cure without betraying allies.",
		category = FunFactConfig.Categories.STATISTICS,
		unlockType = FunFactConfig.UnlockTypes.WAVE,
		unlockValue = 5
	},
	{
		id = "stat_008",
		text = "The first betrayal in a team triggers a 300% increase in subsequent betrayals.",
		category = FunFactConfig.Categories.STATISTICS,
		unlockType = FunFactConfig.UnlockTypes.BETRAYALS_COMMITTED,
		unlockValue = 1
	},

	-- DARK HUMOR (Atmospheric tension)
	{
		id = "dark_001",
		text = "Your predecessors thought they were special too.",
		category = FunFactConfig.Categories.DARK_HUMOR,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "dark_002",
		text = "The facility has excellent life insurance. You're covered up to $2 million.",
		category = FunFactConfig.Categories.DARK_HUMOR,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "dark_003",
		text = "Remember: headshots are more efficient. Budget constraints apply.",
		category = FunFactConfig.Categories.DARK_HUMOR,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "dark_004",
		text = "Trust is a resource. Spend it wisely.",
		category = FunFactConfig.Categories.DARK_HUMOR,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "dark_005",
		text = "The convergence doesn't discriminate. Everyone's welcome.",
		category = FunFactConfig.Categories.DARK_HUMOR,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "dark_006",
		text = "They don't feel pain anymore. You still do. Keep that in mind.",
		category = FunFactConfig.Categories.DARK_HUMOR,
		unlockType = FunFactConfig.UnlockTypes.DEATHS,
		unlockValue = 1
	},
	{
		id = "dark_007",
		text = "Every component you find, someone else died protecting. Or hoarding.",
		category = FunFactConfig.Categories.DARK_HUMOR,
		unlockType = FunFactConfig.UnlockTypes.WAVE,
		unlockValue = 3
	},
	{
		id = "dark_008",
		text = "The cure saves humanity. But which humans, exactly?",
		category = FunFactConfig.Categories.DARK_HUMOR,
		unlockType = FunFactConfig.UnlockTypes.CURE_ATTEMPTS,
		unlockValue = 1
	},
	{
		id = "dark_009",
		text = "Betrayal is just strategic resource reallocation. Corporate approved.",
		category = FunFactConfig.Categories.DARK_HUMOR,
		unlockType = FunFactConfig.UnlockTypes.BETRAYALS_COMMITTED,
		unlockValue = 1
	},
	{
		id = "dark_010",
		text = "Dead teammates make excellent distractions. Just saying.",
		category = FunFactConfig.Categories.DARK_HUMOR,
		unlockType = FunFactConfig.UnlockTypes.DEATHS,
		unlockValue = 2
	},

	-- PSYCHOLOGY (Foreshadowing and paranoia)
	{
		id = "psych_001",
		text = "Your allies are watching you. Are you watching them?",
		category = FunFactConfig.Categories.PSYCHOLOGY,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "psych_002",
		text = "Every decision has permanent consequences. Choose carefully.",
		category = FunFactConfig.Categories.PSYCHOLOGY,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "psych_003",
		text = "The cure only needs one person to complete. Remember that.",
		category = FunFactConfig.Categories.PSYCHOLOGY,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "psych_004",
		text = "Cooperation increases survival odds. Betrayal increases profit. What's your priority?",
		category = FunFactConfig.Categories.PSYCHOLOGY,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "psych_005",
		text = "When the walls close in, who will you sacrifice?",
		category = FunFactConfig.Categories.PSYCHOLOGY,
		unlockType = FunFactConfig.UnlockTypes.ALWAYS,
		unlockValue = 0
	},
	{
		id = "psych_006",
		text = "They trusted you. You trusted them. One of you will break first.",
		category = FunFactConfig.Categories.PSYCHOLOGY,
		unlockType = FunFactConfig.UnlockTypes.WAVE,
		unlockValue = 4
	},
	{
		id = "psych_007",
		text = "The moment before betrayal feels like safety. That's when it happens.",
		category = FunFactConfig.Categories.PSYCHOLOGY,
		unlockType = FunFactConfig.UnlockTypes.BETRAYALS_SURVIVED,
		unlockValue = 1
	},
	{
		id = "psych_008",
		text = "You're thinking about it right now. They're thinking about it too.",
		category = FunFactConfig.Categories.PSYCHOLOGY,
		unlockType = FunFactConfig.UnlockTypes.WAVE,
		unlockValue = 5
	},
	{
		id = "psych_009",
		text = "The infected were human yesterday. Your ally could be infected tomorrow.",
		category = FunFactConfig.Categories.PSYCHOLOGY,
		unlockType = FunFactConfig.UnlockTypes.DEATHS,
		unlockValue = 1
	},
	{
		id = "psych_010",
		text = "You survived betrayal once. Will you learn from it, or repeat it?",
		category = FunFactConfig.Categories.PSYCHOLOGY,
		unlockType = FunFactConfig.UnlockTypes.BETRAYALS_SURVIVED,
		unlockValue = 1
	},
	{
		id = "psych_011",
		text = "The base is failing. Components are scarce. Your ally has what you need.",
		category = FunFactConfig.Categories.PSYCHOLOGY,
		unlockType = FunFactConfig.UnlockTypes.WAVE,
		unlockValue = 6
	},
	{
		id = "psych_012",
		text = "History repeats. The first team fought each other. Will you?",
		category = FunFactConfig.Categories.PSYCHOLOGY,
		unlockType = FunFactConfig.UnlockTypes.BETRAYALS_COMMITTED,
		unlockValue = 1
	},
}

-- Total count validation
FunFactConfig.TotalFacts = #FunFactConfig.Facts

-- Helper function to get facts by category
function FunFactConfig.getFactsByCategory(category)
	local filtered = {}
	for _, fact in ipairs(FunFactConfig.Facts) do
		if fact.category == category then
			table.insert(filtered, fact)
		end
	end
	return filtered
end

-- Helper function to check if a fact is unlocked
function FunFactConfig.isFactUnlocked(fact, playerStats)
	if fact.unlockType == FunFactConfig.UnlockTypes.ALWAYS then
		return true
	end

	if not playerStats then
		return false
	end

	if fact.unlockType == FunFactConfig.UnlockTypes.WAVE then
		return (playerStats.waveReached or 0) >= fact.unlockValue
	elseif fact.unlockType == FunFactConfig.UnlockTypes.BETRAYALS_COMMITTED then
		return (playerStats.betrayalsCommitted or 0) >= fact.unlockValue
	elseif fact.unlockType == FunFactConfig.UnlockTypes.BETRAYALS_SURVIVED then
		return (playerStats.betrayalsSurvived or 0) >= fact.unlockValue
	elseif fact.unlockType == FunFactConfig.UnlockTypes.CURE_ATTEMPTS then
		return (playerStats.cureAttempts or 0) >= fact.unlockValue
	elseif fact.unlockType == FunFactConfig.UnlockTypes.DEATHS then
		return (playerStats.deaths or 0) >= fact.unlockValue
	end

	return false
end

-- Helper function to get all unlocked facts for a player
function FunFactConfig.getUnlockedFacts(playerStats)
	local unlocked = {}
	for _, fact in ipairs(FunFactConfig.Facts) do
		if FunFactConfig.isFactUnlocked(fact, playerStats) then
			table.insert(unlocked, fact)
		end
	end
	return unlocked
end

return FunFactConfig