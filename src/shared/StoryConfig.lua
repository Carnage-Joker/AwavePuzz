-- StoryConfig.lua
-- Story, lore, and narrative configuration for AwavePuzz
-- Contains the backstory of the Aether Wave outbreak and narrative elements

local StoryConfig = {}

-- ========================================
-- GAME TITLE
-- ========================================
StoryConfig.GameTitle = "Aether Wave: Convergence"
StoryConfig.GameSubtitle = "Survive. Cooperate. Betray."

-- ========================================
-- THE OUTBREAK: AETHER VIRUS (A-WAVE)
-- ========================================

StoryConfig.OutbreakName = "The Aether Wave"
StoryConfig.VirusName = "Aether Virus (A-Wave Strain)"

-- Core Backstory
StoryConfig.Backstory = {
	-- The Discovery
	Discovery = [[
Twenty-three days ago, the Aether Energy Facility detected an anomaly.
What began as a groundbreaking quantum research project became humanity's greatest threat.
The Aether Virus—codename "A-Wave"—escaped containment.
]],

	-- The Infection
	Infection = [[
The infected don't die. They change.
The A-Wave virus rewrites neural pathways, consuming rational thought.
What remains is driven by a singular, terrible purpose: spread the convergence.
They were your friends. Your colleagues. Your family.
Now they're something else entirely.
]],

	-- The Symptoms
	Symptoms = [[
First: Fever and disorientation. The neural degradation begins.
Second: Loss of higher reasoning. Base instincts take over.
Third: Photosensitivity and heightened aggression.
Final Stage: Complete transformation. No cure. No return.
Unless we act now.
]],

	-- The Cure
	TheCure = [[
Five components. Five chances.
Chemical A stabilizes the neural pathways.
Chemical B reverses the cellular decay.
The Biological Sample provides the antibody template.
Research Notes contain the synthesis protocol.
The Catalyst triggers the reaction.

Together, they can save what's left of humanity.
Scattered across this facility, waiting to be found.
But time is running out.
]]
}

-- ========================================
-- THE STAKES: ALLIANCE & BETRAYAL
-- ========================================

StoryConfig.AllianceNarrative = {
	-- The Dilemma
	TheDilemma = [[
You're not alone in this facility.
Other survivors. Other scientists. Other chances.
In this nightmare, alliance is survival.

Together, you can cover more ground.
Together, you can defend the base.
Together, you can complete the cure.
]],

	-- The Temptation
	TheTemptation = [[
But resources are scarce.
And the cure only needs one person to complete it.

What happens when you've collected the pieces?
What happens when your ally has what you need?
What happens when survival demands a choice?
]],

	-- The Truth
	TheTruth = [[
The facility's logs tell a darker story:
The first research team had the cure within reach.
They turned on each other.
They all died, fighting over the final components.

You can be different.
You can work together.
You can trust.

Or you can repeat history.
The choice has always been yours.
]],

	-- The Hope
	TheHope = [[
But here's the truth they didn't understand:
The infected are getting stronger.
The waves are growing larger.
No one survives alone.

Form your alliances carefully.
Guard your trust fiercely.
Because when the walls close in and the cure is within reach,
the bonds you've forged will determine who walks out alive.

Cooperation is survival.
Betrayal is tempting.
The convergence is coming.

What will you choose?
]]
}

-- ========================================
-- EPILOGUE CONFIGURATION
-- ========================================

-- Full epilogue text - displayed in sequence
StoryConfig.EpiloguePages = {
	-- Page 1: The Outbreak
	{
		Title = "THE OUTBREAK",
		Text = StoryConfig.Backstory.Discovery .. "\n\n" .. StoryConfig.Backstory.Infection,
		DisplayTime = 8
	},
	
	-- Page 2: The Virus
	{
		Title = "THE AETHER VIRUS",
		Text = StoryConfig.Backstory.Symptoms,
		DisplayTime = 7
	},
	
	-- Page 3: The Cure
	{
		Title = "THE CURE",
		Text = StoryConfig.Backstory.TheCure,
		DisplayTime = 8
	},
	
	-- Page 4: The Alliance Question
	{
		Title = "SURVIVE TOGETHER",
		Text = StoryConfig.AllianceNarrative.TheDilemma,
		DisplayTime = 6
	},
	
	-- Page 5: The Betrayal Temptation
	{
		Title = "OR DIE ALONE",
		Text = StoryConfig.AllianceNarrative.TheTemptation,
		DisplayTime = 6
	},
	
	-- Page 6: The Historical Warning
	{
		Title = "HISTORY REPEATS",
		Text = StoryConfig.AllianceNarrative.TheTruth,
		DisplayTime = 8
	},
	
	-- Page 7: The Final Choice
	{
		Title = "THE CONVERGENCE",
		Text = StoryConfig.AllianceNarrative.TheHope,
		DisplayTime = 10
	}
}

-- Total pages in epilogue
StoryConfig.TotalEpiloguePages = #StoryConfig.EpiloguePages

-- Can the epilogue be skipped?
StoryConfig.EpilogueSkippable = true

-- Skip button text
StoryConfig.SkipButtonText = "Press ESC to Skip"

-- Continue button text
StoryConfig.ContinueButtonText = "Click to Continue"

-- ========================================
-- VICTORY/DEFEAT MESSAGES
-- ========================================

StoryConfig.VictoryMessages = {
	"The cure is complete. You've stopped the convergence.",
	"Against all odds, humanity survives.",
	"The Aether Wave has been contained. For now.",
	"You proved that cooperation can overcome even the darkest threats."
}

StoryConfig.DefeatMessages = {
	BaseDestroyed = {
		"The base has fallen. The convergence spreads.",
		"Without shelter, there is no hope.",
		"The facility is lost. So is humanity."
	},
	AllDead = {
		"No survivors remain.",
		"The Aether Wave claims another team.",
		"History repeats itself.",
		"Perhaps the next team will fare better."
	}
}

-- ========================================
-- UI TEXT SNIPPETS
-- ========================================

StoryConfig.UIText = {
	TitlePrompt = "Press Any Key to Begin",
	Loading = "Initializing Neural Interface...",
	Connecting = "Establishing Secure Connection...",
	Ready = "Ready to Deploy"
}

-- ========================================
-- ATMOSPHERIC QUOTES
-- ========================================

StoryConfig.AtmosphericQuotes = {
	"The infected don't sleep. Neither can you.",
	"Trust is a weapon. Use it wisely.",
	"Every component brings us closer to salvation—or extinction.",
	"The cure won't craft itself. Move.",
	"They were human once. Remember that.",
	"Alliances are temporary. Survival is permanent.",
	"The facility has stood for 23 days. Can you make it 24?",
	"Your choices echo in the convergence."
}

return StoryConfig
