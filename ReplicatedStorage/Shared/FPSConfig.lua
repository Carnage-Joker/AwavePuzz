-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
-- FPSConfig.lua
-- Configuration for First-Person Shooter mechanics
-- Contains settings for camera, movement, weapons, recoil, and HUD

local FPSConfig = {}

--------------------------------------------------------------------------------
-- CAMERA SETTINGS
--------------------------------------------------------------------------------
FPSConfig.Camera = {
	-- Field of View settings
	DefaultFOV = 70,              -- Default FOV in degrees
	MinFOV = 50,                  -- Minimum FOV allowed
	MaxFOV = 120,                 -- Maximum FOV allowed
	ADSFOV = 50,                  -- FOV when aiming down sights
	SprintFOV = 85,               -- FOV boost when sprinting
	FOVTransitionSpeed = 8,       -- Speed of FOV transitions (higher = faster)

	-- Mouse/Look settings
	DefaultSensitivity = 0.5,     -- Default mouse sensitivity (0.1 - 2.0)
	MinSensitivity = 0.1,
	MaxSensitivity = 2.0,
	InvertY = false,              -- Invert Y-axis by default
	MouseSmoothing = false,       -- Enable mouse smoothing
	SmoothingFactor = 0.8,        -- Mouse smoothing amount (0-1, higher = more smooth)

	-- Camera positioning
	FirstPersonOffset = Vector3.new(0, 0.5, 0), -- Offset from head for camera
	HeadLockEnabled = true,       -- Lock camera to head position
}

--------------------------------------------------------------------------------
-- MOVEMENT SETTINGS
--------------------------------------------------------------------------------
FPSConfig.Movement = {
	-- Base speeds
	WalkSpeed = 16,
	SprintSpeed = 24,
	CrouchSpeed = 8,
	ADSSpeed = 10,                -- Speed when aiming down sights

	-- Jump settings
	JumpPower = 50,
	AirControlMultiplier = 0.3,   -- Reduced control when airborne

	-- Crouch settings
	CrouchHeight = 3,             -- HipHeight when crouching
	StandHeight = 2,              -- Normal HipHeight
	CrouchTransitionSpeed = 10,   -- Speed of crouch animation
	CrouchKey = "LeftControl",

	-- Sprint settings
	SprintKey = "LeftShift",
	SprintStaminaDrain = 20,
	StaminaRegenRate = 15,
	StaminaMax = 100,

	-- Keybinds
	JumpKey = "Space",
}

--------------------------------------------------------------------------------
-- WEAPON SYSTEM SETTINGS
--------------------------------------------------------------------------------
FPSConfig.Weapons = {
	-- Fire modes
	FireModes = {
		Semi = "Semi",
		Burst = "Burst",
		Auto = "Auto"
	},

	-- Default weapon behavior
	DefaultFireMode = "Semi",
	BurstCount = 3,               -- Shots per burst
	BurstDelay = 0.1,             -- Delay between burst shots

	-- Reload settings
	ReloadCancelEnabled = true,   -- Allow reload canceling
	ReloadInterruptDelay = 0.3,   -- Minimum time before reload can be canceled

	-- ADS settings
	ADSTransitionSpeed = 8,       -- Speed of ADS animation
	ADSSpreadMultiplier = 0.3,    -- Spread reduction when ADS
	ADSRecoilMultiplier = 0.7,    -- Recoil reduction when ADS

	-- General
	HeadshotMultiplier = 2.0,     -- Damage multiplier for headshots
	BodyshotMultiplier = 1.0,
	LimbshotMultiplier = 0.75,
}

--------------------------------------------------------------------------------
-- WEAPON DEFINITIONS (Extended from WeaponConfig)
--------------------------------------------------------------------------------
FPSConfig.WeaponStats = {
	Pistol = {
		-- Base stats (from WeaponConfig)
		Damage = 18,
		FireRate = 0.35,
		Range = 175,

		-- Fire mode
		FireMode = "Semi",
		Automatic = false,

		-- Magazine
		MagSize = 12,
		ReserveAmmo = 48,
		ReloadTime = 1.5,

		-- Recoil (camera kick)
		RecoilVertical = 1.5,      -- Degrees up per shot
		RecoilHorizontal = 0.5,    -- Max degrees left/right per shot
		RecoilRecovery = 5,        -- Speed of recoil recovery
		RecoilPattern = "random",  -- "random" or "pattern"

		-- Spread (bullet deviation)
		HipSpread = 3.0,           -- Degrees of spread when hip-firing
		ADSSpread = 0.5,           -- Degrees of spread when ADS
		MoveSpreadMultiplier = 1.5, -- Spread multiplier when moving
		SpreadIncreasePerShot = 0.3, -- Spread increase per consecutive shot
		SpreadRecovery = 8,        -- Speed of spread recovery
		MaxSpread = 8,             -- Maximum spread cap

		-- ADS
		ADSZoom = 1.2,             -- Zoom multiplier when ADS
		ADSSpeed = 0.15,           -- Time to ADS
	},

	SMG = {
		Damage = 12,
		FireRate = 0.12,
		Range = 150,

		FireMode = "Auto",
		Automatic = true,

		MagSize = 30,
		ReserveAmmo = 120,
		ReloadTime = 2.0,

		RecoilVertical = 0.8,
		RecoilHorizontal = 0.8,
		RecoilRecovery = 6,
		RecoilPattern = "random",

		HipSpread = 4.0,
		ADSSpread = 1.5,
		MoveSpreadMultiplier = 1.3,
		SpreadIncreasePerShot = 0.15,
		SpreadRecovery = 10,
		MaxSpread = 10,

		ADSZoom = 1.15,
		ADSSpeed = 0.12,
	},

	Shotgun = {
		Damage = 35,
		FireRate = 0.8,
		Range = 90,

		FireMode = "Semi",
		Automatic = false,
		PelletCount = 6,

		MagSize = 6,
		ReserveAmmo = 24,
		ReloadTime = 2.5,
		ReloadType = "single",     -- "single" = one shell at a time

		RecoilVertical = 4.0,
		RecoilHorizontal = 1.5,
		RecoilRecovery = 3,
		RecoilPattern = "random",

		HipSpread = 6.0,
		ADSSpread = 4.0,
		MoveSpreadMultiplier = 1.1,
		SpreadIncreasePerShot = 0,
		SpreadRecovery = 0,
		MaxSpread = 6,

		ADSZoom = 1.1,
		ADSSpeed = 0.2,
	},

	Rifle = {
		Damage = 42,
		FireRate = 0.6,
		Range = 250,

		FireMode = "Semi",
		Automatic = false,

		MagSize = 10,
		ReserveAmmo = 40,
		ReloadTime = 2.2,

		RecoilVertical = 2.5,
		RecoilHorizontal = 0.3,
		RecoilRecovery = 4,
		RecoilPattern = "pattern",

		HipSpread = 5.0,
		ADSSpread = 0.2,
		MoveSpreadMultiplier = 2.0,
		SpreadIncreasePerShot = 0.1,
		SpreadRecovery = 6,
		MaxSpread = 8,

		ADSZoom = 2.0,
		ADSSpeed = 0.25,
	},
}

--------------------------------------------------------------------------------
-- HUD SETTINGS
--------------------------------------------------------------------------------
FPSConfig.HUD = {
	-- Crosshair
	CrosshairEnabled = true,
	CrosshairSize = 8,            -- Base size in pixels
	CrosshairThickness = 2,
	CrosshairGap = 4,             -- Center gap
	CrosshairColor = Color3.new(1, 1, 1),
	CrosshairOutline = true,
	CrosshairOutlineColor = Color3.new(0, 0, 0),
	CrosshairDot = false,         -- Center dot
	DynamicCrosshair = true,      -- Expand when firing/moving

	-- Hitmarkers
	HitmarkerEnabled = true,
	HitmarkerSize = 12,
	HitmarkerDuration = 0.15,
	HitmarkerColor = Color3.new(1, 1, 1),
	HeadshotHitmarkerColor = Color3.new(1, 0.3, 0.3),
	KillHitmarkerColor = Color3.new(1, 0.1, 0.1),

	-- Ammo display
	AmmoDisplayPosition = "BottomRight",
	ShowReserveAmmo = true,
	LowAmmoWarning = true,
	LowAmmoThreshold = 0.3,       -- Percentage of mag

	-- Weapon info
	ShowWeaponName = true,
	ShowFireMode = true,

	-- Damage indicators
	DamageIndicatorEnabled = true,
	DamageIndicatorDuration = 0.5,
	LowHealthVignette = true,
	LowHealthThreshold = 30,
}

--------------------------------------------------------------------------------
-- EFFECTS SETTINGS
--------------------------------------------------------------------------------
FPSConfig.Effects = {
	-- Camera effects
	ScreenShakeEnabled = true,
	ScreenShakeIntensity = 1.0,   -- Multiplier

	-- Muzzle flash
	MuzzleFlashEnabled = true,
	MuzzleFlashDuration = 0.05,

	-- Bullet tracers
	TracersEnabled = true,
	TracerSpeed = 500,            -- Studs per second
	TracerLength = 4,
	TracerColor = Color3.fromRGB(255, 220, 150),

	-- Impact effects
	ImpactEffectsEnabled = true,

	-- Weapon sway
	WeaponSwayEnabled = true,
	SwayAmount = 0.5,
	SwaySpeed = 2,
}

--------------------------------------------------------------------------------
-- AUDIO SETTINGS
--------------------------------------------------------------------------------
FPSConfig.Audio = {
	-- Volume defaults
	MasterVolume = 1.0,
	SFXVolume = 0.8,
	MusicVolume = 0.5,

	-- Sound settings
	FootstepsEnabled = true,
	FootstepVolume = 0.5,

	-- Weapon sounds
	FireSoundEnabled = true,
	ReloadSoundEnabled = true,
	EmptyClickEnabled = true,

	-- Feedback sounds
	HitmarkerSoundEnabled = true,
	HeadshotSoundEnabled = true,
	LowHealthHeartbeat = true,
}

--------------------------------------------------------------------------------
-- MENU/CONTROLS SETTINGS
--------------------------------------------------------------------------------
FPSConfig.Controls = {
	-- Fire
	FireKey = Enum.UserInputType.MouseButton1,
	ADSKey = Enum.UserInputType.MouseButton2,
	ReloadKey = Enum.KeyCode.R,

	-- Movement
	MoveForward = Enum.KeyCode.W,
	MoveBackward = Enum.KeyCode.S,
	MoveLeft = Enum.KeyCode.A,
	MoveRight = Enum.KeyCode.D,

	-- Weapon switching
	WeaponSlot1 = Enum.KeyCode.One,
	WeaponSlot2 = Enum.KeyCode.Two,
	WeaponSlot3 = Enum.KeyCode.Three,
	WeaponSlot4 = Enum.KeyCode.Four,

	-- UI
	PauseKey = Enum.KeyCode.Escape,
	ScoreboardKey = Enum.KeyCode.Tab,

	-- Menu navigation
	MenuUp = Enum.KeyCode.W,
	MenuDown = Enum.KeyCode.S,
	MenuLeft = Enum.KeyCode.A,
	MenuRight = Enum.KeyCode.D,
	MenuSelect = Enum.KeyCode.Return,
	MenuBack = Enum.KeyCode.Escape,
}

--------------------------------------------------------------------------------
-- SETTINGS PERSISTENCE
--------------------------------------------------------------------------------
FPSConfig.Settings = {
	-- These are the default user settings that can be changed
	UserDefaults = {
		MouseSensitivity = 0.5,
		InvertY = false,
		FieldOfView = 70,
		MasterVolume = 1.0,
		SFXVolume = 0.8,
		MusicVolume = 0.5,
		CrosshairStyle = "default",
		HitmarkersEnabled = true,
	},
}

--------------------------------------------------------------------------------
-- DEVICE-SPECIFIC SETTINGS
--------------------------------------------------------------------------------
FPSConfig.Device = {
	-- Mobile/Touch settings
	Touch = {
		-- Sensitivity adjustments for touch controls
		LookSensitivity = 0.3,        -- Lower sensitivity for touch
		MovementDeadzone = 0.15,      -- Joystick deadzone
		FireButtonSize = 80,          -- Touch button sizes
		JoystickSize = 150,
		AutoFire = false,             -- Enable auto-fire when holding fire button
		GyroAiming = false,           -- Use device gyroscope for aiming (if available)

		-- UI adjustments
		HUDScale = 0.7,               -- Scale down HUD elements
		CrosshairScale = 0.8,
		ButtonOpacity = 0.7,

		-- Performance
		ReducedEffects = true,        -- Lower visual effects for better performance
		LowerParticles = true,
	},

	-- Gamepad/Console settings
	Gamepad = {
		-- Sensitivity
		LookSensitivity = 0.6,
		MovementDeadzone = 0.15,
		LookDeadzone = 0.15,

		-- Response curves
		LookAcceleration = 1.2,       -- Multiplier for faster look speeds
		AimAssist = true,             -- Enable aim assist for controllers
		AimAssistStrength = 0.3,      -- How much to pull toward targets (0-1)
		AimAssistRange = 100,         -- Range in studs for aim assist

		-- Vibration
		VibrationEnabled = true,
		VibrationIntensity = 0.7,

		-- Button mapping (see InputManager for full mapping)
		InvertY = false,
	},

	-- VR settings
	VR = {
		-- Camera
		VRCameraSmoothing = 0.2,
		VRHeadTracking = true,
		ComfortVignette = true,       -- Reduce motion sickness
		ComfortVignetteStrength = 0.5,

		-- Locomotion
		VRLocomotionType = "Smooth",  -- "Smooth" or "Teleport"
		VRTurnType = "Smooth",        -- "Smooth" or "Snap"
		VRSnapTurnAngle = 45,         -- Degrees per snap turn
		VRSmoothTurnSpeed = 90,       -- Degrees per second

		-- Controllers
		VRHandTracking = true,
		VRWeaponPositioning = true,   -- Position weapons based on controller position
		VRTwoHandedGrip = true,       -- Allow two-handed weapon grip for stability

		-- Comfort
		VRReduceHeadBob = true,
		VRStationaryReload = false,   -- Require standing still to reload

		-- UI
		VRUIDistance = 2,             -- Distance of UI panels in VR (meters)
		VRUIScale = 1.2,              -- Scale up UI for readability
	},

	-- Desktop/PC settings (reference)
	Desktop = {
		LookSensitivity = 0.5,
		HighQualityEffects = true,
		UnlimitedFramerate = true,
	},
}

--------------------------------------------------------------------------------
-- ANIMATION SETTINGS
--------------------------------------------------------------------------------
FPSConfig.Animations = {
	-- Enable/disable animations
	Enabled = true,

	-- Procedural animations
	WeaponSwayEnabled = true,
	SwayAmount = 0.02,           -- Amount of sway from mouse movement
	SwaySpeed = 10,              -- Speed of sway interpolation

	BreathingEnabled = true,
	BreathSpeed = 2,             -- Breathing cycle speed
	BreathAmount = 0.01,         -- Amount of vertical breathing motion

	RecoilAnimationEnabled = true,
	RecoilRecoverySpeed = 10,    -- Speed of recoil recovery

	-- Viewmodel settings
	ViewmodelFOV = 70,           -- FOV for viewmodel (separate from camera)
	ViewmodelOffset = Vector3.new(0, -0.5, -1), -- Base offset from camera

	-- Animation IDs (Replace with actual Roblox animation asset IDs)
	-- Format: "rbxassetid://0" (placeholder; replace 0 with your animation asset ID)
	WeaponAnimations = {
		Pistol = {
			idle = "rbxassetid://77700472496946",      -- Idle holding animation
			fire = "rbxassetid://107261819756829",      -- Fire/shoot animation
			reload = "rbxassetid://136927034232244",    -- Reload animation
			equip = "rbxassetid://106310870423679",     -- Draw/equip animation
			sprint = "rbxassetid://102565289526730",    -- Sprint (lowered weapon) animation
			ads = "rbxassetid://0",       -- Aim down sights animation
		},
		SMG = {
			idle = "rbxassetid://91849136252846",      -- Idle holding animation
			fire = "rbxassetid://121818582669361",      -- Fire/shoot animation
			reload = "rbxassetid://136927034232244",    -- Reload animation
			equip = "rbxassetid://106310870423679",     -- Draw/equip animation
			sprint = "rbxassetid://74003080620998",
			ads = "rbxassetid://0",
		},
		Shotgun = {
			idle = "rbxassetid://0",
			fire = "rbxassetid://0",
			reload = "rbxassetid://0",    -- Shell-by-shell reload
			equip = "rbxassetid://0",
			sprint = "rbxassetid://0",
			ads = "rbxassetid://0",
		},
		Rifle = {
			idle = "rbxassetid://0",
			fire = "rbxassetid://0",
			reload = "rbxassetid://0",
			equip = "rbxassetid://0",
			sprint = "rbxassetid://0",
			ads = "rbxassetid://0",
		},
	},

	-- Weapon-specific offsets for proper positioning in viewmodel
	WeaponOffsets = {
		Pistol = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(0), 0),
		SMG = CFrame.new(0, 0.1, 0) * CFrame.Angles(0, math.rad(0), 0),
		Shotgun = CFrame.new(0, 0.05, 0.1) * CFrame.Angles(0, math.rad(0), 0),
		Rifle = CFrame.new(0, 0, 0.1) * CFrame.Angles(0, math.rad(0), 0),
	},

	-- Animation blending settings
	BlendTime = 0.1,             -- Time to blend between animations

	-- Animation priorities (Roblox AnimationPriority enum values)
	Priorities = {
		Idle = Enum.AnimationPriority.Idle,
		Movement = Enum.AnimationPriority.Movement,
		Action = Enum.AnimationPriority.Action,
		Action2 = Enum.AnimationPriority.Action2,
		Action3 = Enum.AnimationPriority.Action3,
		Action4 = Enum.AnimationPriority.Action4,
	},
}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------

-- Get weapon stats with FPS extensions
function FPSConfig.getWeaponStats(weaponId)
	return FPSConfig.WeaponStats[weaponId]
end

-- Get default ammo for a weapon
function FPSConfig.getDefaultAmmo(weaponId)
	local stats = FPSConfig.WeaponStats[weaponId]
	if stats then
		return {
			current = stats.MagSize,
			reserve = stats.ReserveAmmo,
			max = stats.MagSize
		}
	end
	return nil
end

-- Calculate effective spread based on state
function FPSConfig.calculateSpread(weaponId, isADS, isMoving, consecutiveShots)
	local stats = FPSConfig.WeaponStats[weaponId]
	if not stats then return 3.0 end

	local baseSpread = isADS and stats.ADSSpread or stats.HipSpread

	-- Apply movement penalty
	if isMoving then
		baseSpread = baseSpread * stats.MoveSpreadMultiplier
	end

	-- Apply consecutive shot penalty
	local shotPenalty = (consecutiveShots or 0) * stats.SpreadIncreasePerShot
	baseSpread = baseSpread + shotPenalty

	-- Clamp to max spread
	return math.min(baseSpread, stats.MaxSpread)
end

-- Calculate recoil for a shot
function FPSConfig.calculateRecoil(weaponId, isADS)
	local stats = FPSConfig.WeaponStats[weaponId]
	if not stats then return 0, 0 end

	local vertical = stats.RecoilVertical
	local horizontal = stats.RecoilHorizontal

	-- Apply ADS reduction
	if isADS then
		local multiplier = FPSConfig.Weapons.ADSRecoilMultiplier
		vertical = vertical * multiplier
		horizontal = horizontal * multiplier
	end

	-- Add randomness to horizontal
	horizontal = horizontal * (math.random() * 2 - 1)

	return vertical, horizontal
end

-- Get device-specific settings
function FPSConfig.getDeviceSettings(deviceType)
	return FPSConfig.Device[deviceType] or FPSConfig.Device.Desktop
end

-- Get appropriate sensitivity for current device
function FPSConfig.getSensitivityForDevice(deviceType)
	local deviceSettings = FPSConfig.getDeviceSettings(deviceType)
	return deviceSettings.LookSensitivity or FPSConfig.Camera.DefaultSensitivity
end

return FPSConfig