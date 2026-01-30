-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
-- StoryConfig.lua
-- Story, lore, and narrative configuration for Aether Wave: Convergence
-- Contains the backstory of the Aether Wave outbreak and narrative elements

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local AssetConfig = require(SharedFolder:WaitForChild("AssetConfig"))

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
-- EPILOGUE CONFIGURATION (DIEGETIC SYSTEM LOGS)
-- ========================================

-- New diegetic epilogue - framed as system logs and warnings, not tutorials
-- Delivered as voiceover-style documentation
StoryConfig.EpiloguePages = {
	-- Log 1: System Initialization
	{
		Title = "SYSTEM LOG :: INITIALIZATION",
		Text = [[
AETHER CONTAINMENT FACILITY - DAY 23
STATUS: CRITICAL FAILURE

Neural interface active.
You are being documented.

The facility is compromised.
The infected are learning.
Extraction is not available.]],
		DisplayTime = 7,
		VoiceoverStyle = "System"
	},

	-- Log 2: Threat Assessment
	{
		Title = "THREAT ASSESSMENT :: WAVE PROTOCOL",
		Text = [[
WARNING: Hostiles escalate indefinitely.
Wave intensity increases exponentially.
No plateau. No mercy.

Historical data: Longest survival - 47 minutes.
Average survival - 18 minutes.

Your timer starts now.]],
		DisplayTime = 7,
		VoiceoverStyle = "System"
	},

	-- Log 3: Base Defense Protocol
	{
		Title = "PRIORITY ALERT :: BASE INTEGRITY",
		Text = [[
The base is your final line of defense.
Base integrity failure is absolute.

No warnings.
No countdown.
Breach → Immediate termination.

Defend it. Or lose everything.]],
		DisplayTime = 7,
		VoiceoverStyle = "Warning"
	},

	-- Log 4: Cure Synthesis Parameters
	{
		Title = "OBJECTIVE :: CURE SYNTHESIS",
		Text = [[
Five components exist in this facility.
Chemical A. Chemical B. Biological Sample.
Research Notes. Catalyst.

Synthesis protocol:
→ Collect all five components
→ Access base cure station
→ Complete timed puzzle sequence under combat conditions

Failure → Components wasted.
Success → Convergence contained.

Choose your moment carefully.]],
		DisplayTime = 10,
		VoiceoverStyle = "System"
	},

	-- Log 5: Synthesis Warning
	{
		Title = "SYNTHESIS WARNING",
		Text = [[
NOTE: Infected intensify attacks during synthesis.
As if they understand what you're doing.

The cure station cannot be moved.
You will be vulnerable.
They will not wait.

Coordinate. Defend. Survive.]],
		DisplayTime = 8,
		VoiceoverStyle = "Warning"
	},

	-- Log 6: Alliance Protocol
	{
		Title = "TACTICAL NOTE :: ALLIANCE SYSTEMS",
		Text = [[
Friendly fire protocols: ACTIVE.
Exception: Allied personnel.

Alliance benefits:
→ Shared resources
→ Coordinated defense
→ Pooled cure progress

Historical data: Allied teams survive 85% longer.
Solo operators: 4.2 waves average.

Cooperation is statistically optimal.]],
		DisplayTime = 9,
		VoiceoverStyle = "System"
	},

	-- Log 7: Betrayal Mechanics
	{
		Title = "RISK ASSESSMENT :: BETRAYAL PROTOCOL",
		Text = [[
Betrayal parameters documented:

Hostile action against ally → Betrayal window opens (30 seconds)

Outcome A: Betrayer eliminates target → 75% resource transfer
Outcome B: Target survives → No penalty
Outcome C: Target eliminates betrayer → 100% resource seizure

Risk: High. Reward: Significant. Choice: Yours.

Previous team destroyed themselves over resources.
You can be different.
History suggests you won't be.]],
		DisplayTime = 12,
		VoiceoverStyle = "System"
	},

	-- Log 8: Final Transmission
	{
		Title = "FINAL TRANSMISSION",
		Text = [[
You are not being instructed.
You are being documented.

The convergence does not stop.
The base will not hold forever.
Your allies may not remain allies.

Five components.
One cure.
Multiple survivors.

Do the math.

Good luck, operator.
You'll need it.]],
		DisplayTime = 10,
		VoiceoverStyle = "Warning"
	}
}

-- Total pages in epilogue
StoryConfig.TotalEpiloguePages = #StoryConfig.EpiloguePages

-- Can the epilogue be skipped?
StoryConfig.EpilogueSkippable = true

-- Skip button text
StoryConfig.SkipButtonText = "[ESC] Skip Briefing"

-- Mute button text
StoryConfig.MuteButtonText = "[M] Mute Audio"

-- Continue button text
StoryConfig.ContinueButtonText = "[SPACE] Continue"

-- Audio settings
StoryConfig.EpilogueAudioEnabled = true
StoryConfig.EpilogueDefaultVolume = 0.7

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
-- CREDITS
-- ========================================

StoryConfig.Credits = {
	Title = "AETHER WAVE: CONVERGENCE",
	Subtitle = "The Cure Has Been Found",

	Sections = {
		{
			Header = "SURVIVORS",
			Type = "players", -- Will be populated with actual player names and stats
		},
		{
			Header = "GAME DESIGN",
			Credits = {
				"Carnage-Joker"
			}
		},
		{
			Header = "DEVELOPMENT",
			Credits = {
				"Carnage-Joker",
				"GitHub Copilot"
			}
		},
		{
			Header = "SPECIAL THANKS",
			Credits = {
				"The Roblox Development Community",
				"All Players Who Fought the Convergence",
				"Those Who Chose to Trust"
			}
		},
		{
			Header = "IN MEMORY",
			Credits = {
				"The First Research Team",
				"Who Had the Cure Within Reach",
				"But Lost Themselves to Betrayal"
			}
		}
	},

	ClosingMessage = "Thank you for playing.\nThe choice was always yours.",
	CreditsDisplayTime = 20, -- Total seconds to display credits
	ScrollSpeed = 30 -- Pixels per second
}

-- ========================================
-- ACHIEVEMENT DEFINITIONS
-- ========================================

StoryConfig.Achievements = {
	-- Combat Achievements
	{
		Id = "first_blood",
		Name = "First Blood",
		Description = "Eliminated your first infected",
		Icon = "🎯",
		Rarity = "Common"
	},
	{
		Id = "headshot_specialist",
		Name = "Headshot Specialist",
		Description = "Landed 10 headshots in a single round",
		Icon = "🎯",
		Rarity = "Uncommon"
	},
	{
		Id = "last_stand",
		Name = "Last Stand",
		Description = "Survived as the last player alive",
		Icon = "⚔️",
		Rarity = "Rare"
	},

	-- Cooperation Achievements
	{
		Id = "trusted_ally",
		Name = "Trusted Ally",
		Description = "Completed a round without breaking alliances",
		Icon = "🤝",
		Rarity = "Uncommon"
	},
	{
		Id = "team_player",
		Name = "Team Player",
		Description = "Formed alliances with all players",
		Icon = "👥",
		Rarity = "Rare"
	},

	-- Betrayal Achievements
	{
		Id = "betrayer",
		Name = "The Betrayer",
		Description = "Broke an alliance and survived",
		Icon = "🗡️",
		Rarity = "Uncommon"
	},
	{
		Id = "lone_wolf",
		Name = "Lone Wolf",
		Description = "Won without forming any alliances",
		Icon = "🐺",
		Rarity = "Epic"
	},

	-- Cure Achievements
	{
		Id = "component_collector",
		Name = "Component Collector",
		Description = "Collected 10 cure components in one round",
		Icon = "🧪",
		Rarity = "Uncommon"
	},
	{
		Id = "savior",
		Name = "The Savior",
		Description = "Completed the cure and saved humanity",
		Icon = "⭐",
		Rarity = "Rare"
	},

	-- Challenge Achievements
	{
		Id = "perfect_run",
		Name = "Perfect Run",
		Description = "Completed the cure without anyone dying",
		Icon = "💎",
		Rarity = "Legendary"
	},
	{
		Id = "clutch_save",
		Name = "Clutch Save",
		Description = "Completed the cure with base health at 10% or less",
		Icon = "🔥",
		Rarity = "Epic"
	}
}

-- ========================================
-- MUSIC CONFIGURATION
-- All music asset IDs are now centralized in AssetConfig.lua
-- To update music IDs, edit ReplicatedStorage/Shared/AssetConfig.lua
-- ========================================

StoryConfig.Music = AssetConfig.Music

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