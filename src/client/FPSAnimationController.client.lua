-- FPSAnimationController.client.lua
-- Manages all weapon and viewmodel animations for the FPS system
-- Handles idle, fire, reload, equip, sprint, and ADS animations
-- Includes procedural animations like weapon sway and recoil recovery

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- Wait for shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local FPSConfig = require(SharedFolder:WaitForChild("FPSConfig"))
local RemoteEventUtil = require(SharedFolder:WaitForChild("RemoteEventUtil"))

--------------------------------------------------------------------------------
-- ANIMATION STATE
--------------------------------------------------------------------------------

local FPSAnimationController = {
	-- Viewmodel
	viewmodel = nil,
	viewmodelArms = nil,
	currentWeaponModel = nil,
	
	-- Animation tracks
	currentAnimations = {
		idle = nil,
		fire = nil,
		reload = nil,
		equip = nil,
		sprint = nil,
		ads = nil,
	},
	
	-- State
	isReloading = false,
	isSprinting = false,
	isADS = false,
	currentWeapon = nil,
	
	-- Procedural animation
	swayOffset = CFrame.new(),
	recoilOffset = CFrame.new(),
	breathOffset = CFrame.new(),
	breathTime = 0,
	
	-- Remote events for server replication
	remoteEvents = nil,
	
	-- Settings
	enabled = true,
}

--------------------------------------------------------------------------------
-- VIEWMODEL CREATION
--------------------------------------------------------------------------------

-- Create or retrieve the viewmodel (first-person arms)
function FPSAnimationController:createViewmodel()
	-- Check if viewmodel already exists in camera
	local existingViewmodel = camera:FindFirstChild("Viewmodel")
	if existingViewmodel then
		self.viewmodel = existingViewmodel
		self.viewmodelArms = existingViewmodel:FindFirstChild("Arms")
		return
	end
	
	-- Create new viewmodel folder
	local viewmodel = Instance.new("Model")
	viewmodel.Name = "Viewmodel"
	viewmodel.Parent = camera
	self.viewmodel = viewmodel
	
	-- Create arms (placeholder - will be replaced with actual arm models)
	local arms = Instance.new("Model")
	arms.Name = "Arms"
	arms.Parent = viewmodel
	self.viewmodelArms = arms
	
	-- Create attachment points for weapons
	local rightHand = Instance.new("Part")
	rightHand.Name = "RightHand"
	rightHand.Size = Vector3.new(0.2, 0.2, 0.2)
	rightHand.Transparency = 1
	rightHand.CanCollide = false
	rightHand.Anchored = false
	rightHand.Parent = arms
	
	local leftHand = Instance.new("Part")
	leftHand.Name = "LeftHand"
	leftHand.Size = Vector3.new(0.2, 0.2, 0.2)
	leftHand.Transparency = 1
	leftHand.CanCollide = false
	leftHand.Anchored = false
	leftHand.Parent = arms
	
	-- Create welds/Motor6Ds for animation
	-- This is a simplified setup - actual implementation would use proper rig
	local rightWeld = Instance.new("Weld")
	rightWeld.Name = "RightWeld"
	rightWeld.Part0 = camera
	rightWeld.Part1 = rightHand
	rightWeld.C0 = CFrame.new(0.5, -0.5, -1)
	rightWeld.Parent = rightHand
	
	local leftWeld = Instance.new("Weld")
	leftWeld.Name = "LeftWeld"
	leftWeld.Part0 = camera
	leftWeld.Part1 = leftHand
	leftWeld.C0 = CFrame.new(-0.5, -0.5, -1.2)
	leftWeld.Parent = leftHand
	
	print("[FPSAnimationController] Created viewmodel")
end

-- Load weapon model into viewmodel
function FPSAnimationController:loadWeaponModel(weaponId)
	-- Remove existing weapon model
	if self.currentWeaponModel then
		self.currentWeaponModel:Destroy()
		self.currentWeaponModel = nil
	end
	
	-- Try to find weapon model in ReplicatedStorage
	local weaponModel = nil
	local gunsFolder = ReplicatedStorage:FindFirstChild("Guns")
	
	if gunsFolder then
		local modelTemplate = gunsFolder:FindFirstChild(weaponId)
		local modelTemplate = gunsFolder:FindFirstChild(weaponId)
		if modelTemplate then
			weaponModel = modelTemplate:Clone()
		end
	end
	
	-- Fallback: create placeholder weapon model
	if not weaponModel then
		weaponModel = Instance.new("Model")
		weaponModel.Name = weaponId
		
		-- Create simple gun shape
		local barrel = Instance.new("Part")
		barrel.Name = "Barrel"
		barrel.Size = Vector3.new(0.1, 0.1, 0.8)
		barrel.Color = Color3.fromRGB(60, 60, 60)
		barrel.CanCollide = false
		barrel.Anchored = false
		barrel.Parent = weaponModel
		
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.2, 0.3, 0.1)
		handle.Color = Color3.fromRGB(40, 40, 40)
		handle.CanCollide = false
		handle.Anchored = false
		handle.Parent = weaponModel
		
		weaponModel.PrimaryPart = handle
		
		-- Position relative to barrel
		local weld = Instance.new("Weld")
		weld.Part0 = handle
		weld.Part1 = barrel
		weld.C0 = CFrame.new(0, 0.2, -0.3)
		weld.Parent = handle
	end
	
	-- Parent to viewmodel
	weaponModel.Parent = self.viewmodel
	self.currentWeaponModel = weaponModel
	
	-- Attach to right hand
	local rightHand = self.viewmodelArms:FindFirstChild("RightHand")
	if rightHand and weaponModel.PrimaryPart then
		local weld = Instance.new("Weld")
		weld.Name = "WeaponWeld"
		weld.Part0 = rightHand
		weld.Part1 = weaponModel.PrimaryPart
		weld.C0 = self:getWeaponOffset(weaponId)
		weld.Parent = weaponModel.PrimaryPart
	end
	
	print("[FPSAnimationController] Loaded weapon model:", weaponId)
end

-- Get weapon-specific offset for proper positioning
function FPSAnimationController:getWeaponOffset(weaponId)
	local animConfig = FPSConfig.Animations
	if animConfig and animConfig.WeaponOffsets and animConfig.WeaponOffsets[weaponId] then
		return animConfig.WeaponOffsets[weaponId]
	end
	
	-- Default offset
	return CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
end

--------------------------------------------------------------------------------
-- ANIMATION LOADING
--------------------------------------------------------------------------------

-- Load animation for a weapon
function FPSAnimationController:loadAnimation(weaponId, animationType)
	if not self.enabled then return nil end
	
	-- Try to find animation asset
	local animConfig = FPSConfig.Animations
	if not animConfig or not animConfig.WeaponAnimations then
		return nil
	end
	
	local weaponAnims = animConfig.WeaponAnimations[weaponId]
	if not weaponAnims or not weaponAnims[animationType] then
		return nil
	end
	
	local animationId = weaponAnims[animationType]
	if not animationId or animationId == "" or animationId == "rbxassetid://0" then
		return nil
	end
	
	-- Create and load animation
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	
	local character = player.Character
	if not character then return nil end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	
	local animTrack = animator:LoadAnimation(animation)
	return animTrack
end

--------------------------------------------------------------------------------
-- ANIMATION PLAYBACK
--------------------------------------------------------------------------------

-- Play idle animation
function FPSAnimationController:playIdle(weaponId)
	self:stopAnimation("idle")
	
	local idleAnim = self:loadAnimation(weaponId, "idle")
	if idleAnim then
		idleAnim.Looped = true
		idleAnim.Priority = Enum.AnimationPriority.Idle
		idleAnim:Play()
		self.currentAnimations.idle = idleAnim
	end
end

-- Play fire animation
function FPSAnimationController:playFire(weaponId)
	local fireAnim = self:loadAnimation(weaponId, "fire")
	if fireAnim then
		fireAnim.Looped = false
		fireAnim.Priority = Enum.AnimationPriority.Action
		fireAnim:Play()
		self.currentAnimations.fire = fireAnim
		
		-- Clean up after animation finishes
		fireAnim.Stopped:Once(function()
			if self.currentAnimations.fire == fireAnim then
				self.currentAnimations.fire = nil
			end
		end)
	end
	
	-- Replicate to server for other players
	if self.remoteEvents and self.remoteEvents.AnimationFire then
		self.remoteEvents.AnimationFire:FireServer(weaponId)
	end
end

-- Play reload animation
function FPSAnimationController:playReload(weaponId, reloadTime)
	self:stopAnimation("reload")
	
	local reloadAnim = self:loadAnimation(weaponId, "reload")
	if reloadAnim then
		reloadAnim.Looped = false
		reloadAnim.Priority = Enum.AnimationPriority.Action2
		
		-- Adjust speed to match reload time
		if reloadTime then
			local animLength = reloadAnim.Length
			if animLength > 0 then
				reloadAnim:AdjustSpeed(animLength / reloadTime)
			end
		end
		
		reloadAnim:Play()
		self.currentAnimations.reload = reloadAnim
		self.isReloading = true
		
		-- Clean up when finished
		reloadAnim.Stopped:Once(function()
			self.isReloading = false
			if self.currentAnimations.reload == reloadAnim then
				self.currentAnimations.reload = nil
			end
		end)
	end
end

-- Play equip animation
function FPSAnimationController:playEquip(weaponId)
	self:stopAnimation("equip")
	
	local equipAnim = self:loadAnimation(weaponId, "equip")
	if equipAnim then
		equipAnim.Looped = false
		equipAnim.Priority = Enum.AnimationPriority.Action
		equipAnim:Play()
		self.currentAnimations.equip = equipAnim
		
		equipAnim.Stopped:Once(function()
			if self.currentAnimations.equip == equipAnim then
				self.currentAnimations.equip = nil
			end
		end)
	end
end

-- Update sprint animation state
function FPSAnimationController:setSprinting(isSprinting)
	self.isSprinting = isSprinting
	
	if isSprinting then
		local sprintAnim = self:loadAnimation(self.currentWeapon, "sprint")
		if sprintAnim and self.currentAnimations.sprint ~= sprintAnim then
			self:stopAnimation("sprint")
			sprintAnim.Looped = true
			sprintAnim.Priority = Enum.AnimationPriority.Movement
			sprintAnim:Play()
			self.currentAnimations.sprint = sprintAnim
		end
	else
		self:stopAnimation("sprint")
	end
	
	-- Replicate to server for other players
	if self.remoteEvents and self.remoteEvents.AnimationSprint then
		self.remoteEvents.AnimationSprint:FireServer(isSprinting)
	end
end

-- Update ADS animation state
function FPSAnimationController:setADS(isADS)
	self.isADS = isADS
	
	if isADS then
		local adsAnim = self:loadAnimation(self.currentWeapon, "ads")
		if adsAnim and self.currentAnimations.ads ~= adsAnim then
			self:stopAnimation("ads")
			adsAnim.Looped = true
			adsAnim.Priority = Enum.AnimationPriority.Action
			adsAnim:Play()
			self.currentAnimations.ads = adsAnim
		end
	else
		self:stopAnimation("ads")
	end
	
	-- Replicate to server for other players
	if self.remoteEvents and self.remoteEvents.AnimationADS then
		self.remoteEvents.AnimationADS:FireServer(isADS)
	end
end

-- Stop specific animation
function FPSAnimationController:stopAnimation(animationType)
	local anim = self.currentAnimations[animationType]
	if anim then
		anim:Stop()
		self.currentAnimations[animationType] = nil
	end
end

-- Stop all animations
function FPSAnimationController:stopAllAnimations()
	for animType, anim in pairs(self.currentAnimations) do
		if anim then
			anim:Stop()
			self.currentAnimations[animType] = nil
		end
	end
end

-- Cancel reload animation
function FPSAnimationController:cancelReload()
	if self.isReloading then
		self:stopAnimation("reload")
		self.isReloading = false
	end
end

--------------------------------------------------------------------------------
-- PROCEDURAL ANIMATIONS
--------------------------------------------------------------------------------

-- Update weapon sway based on movement
function FPSAnimationController:updateWeaponSway(deltaTime)
	local animConfig = FPSConfig.Animations
	if not animConfig or not animConfig.WeaponSwayEnabled then
		return CFrame.new()
	end
	
	-- Get mouse delta
	local mouseDelta = UserInputService:GetMouseDelta()
	
	-- Calculate sway
	local swayAmount = animConfig.SwayAmount or 0.02
	local swaySpeed = animConfig.SwaySpeed or 10
	
	local targetSway = CFrame.new(
		-mouseDelta.X * swayAmount * 0.01,
		-mouseDelta.Y * swayAmount * 0.01,
		0
	) * CFrame.Angles(
		math.rad(mouseDelta.Y * swayAmount * 2),
		math.rad(-mouseDelta.X * swayAmount * 2),
		0
	)
	
	-- Smooth interpolation
	self.swayOffset = self.swayOffset:Lerp(targetSway, deltaTime * swaySpeed)
	
	return self.swayOffset
end

-- Update breathing idle motion
function FPSAnimationController:updateBreathing(deltaTime)
	local animConfig = FPSConfig.Animations
	if not animConfig or not animConfig.BreathingEnabled then
		return CFrame.new()
	end
	
	self.breathTime = self.breathTime + deltaTime
	
	local breathSpeed = animConfig.BreathSpeed or 2
	local breathAmount = animConfig.BreathAmount or 0.01
	
	local breathY = math.sin(self.breathTime * breathSpeed) * breathAmount
	local breathZ = math.cos(self.breathTime * breathSpeed * 0.5) * breathAmount * 0.5
	
	self.breathOffset = CFrame.new(0, breathY, breathZ)
	
	return self.breathOffset
end

-- Apply recoil offset (called from weapon controller)
function FPSAnimationController:applyRecoilOffset(vertical, horizontal)
	local animConfig = FPSConfig.Animations
	if not animConfig or not animConfig.RecoilAnimationEnabled then
		return
	end
	
	-- Convert degrees to radians and apply
	local verticalRad = math.rad(vertical)
	local horizontalRad = math.rad(horizontal)
	
	local recoilCFrame = CFrame.Angles(-verticalRad, horizontalRad, 0)
	self.recoilOffset = self.recoilOffset * recoilCFrame
end

-- Update recoil recovery
function FPSAnimationController:updateRecoilRecovery(deltaTime)
	local animConfig = FPSConfig.Animations
	if not animConfig then return end
	
	local recoverySpeed = animConfig.RecoilRecoverySpeed or 10
	
	-- Smooth recovery back to zero
	self.recoilOffset = self.recoilOffset:Lerp(CFrame.new(), deltaTime * recoverySpeed)
	
	return self.recoilOffset
end

-- Update viewmodel position (combines all procedural animations)
function FPSAnimationController:updateViewmodelPosition(deltaTime)
	if not self.enabled or not self.viewmodel then return end
	
	-- Combine all procedural offsets
	local sway = self:updateWeaponSway(deltaTime)
	local breath = self:updateBreathing(deltaTime)
	local recoil = self:updateRecoilRecovery(deltaTime)
	
	-- Apply combined offset to viewmodel
	local combinedOffset = sway * breath * recoil
	
	-- Apply to viewmodel arms
	if self.viewmodelArms then
		local rightHand = self.viewmodelArms:FindFirstChild("RightHand")
		if rightHand then
			local weld = rightHand:FindFirstChild("RightWeld")
			if weld then
				-- Apply offset to base position
				local baseOffset = CFrame.new(0.5, -0.5, -1)
				if self.isADS then
					baseOffset = CFrame.new(0, -0.3, -0.8) -- Closer for ADS
				elseif self.isSprinting then
					baseOffset = CFrame.new(0.3, -0.8, -0.5) -- Lower for sprint
				end
				
				weld.C0 = baseOffset * combinedOffset
			end
		end
	end
end

--------------------------------------------------------------------------------
-- WEAPON SWITCHING
--------------------------------------------------------------------------------

-- Equip a new weapon
function FPSAnimationController:equipWeapon(weaponId)
	if weaponId == self.currentWeapon then return end
	
	-- Stop all current animations
	self:stopAllAnimations()
	
	-- Load weapon model
	self:loadWeaponModel(weaponId)
	
	-- Play equip animation
	self:playEquip(weaponId)
	
	-- Start idle animation after equip
	task.delay(0.5, function()
		if self.currentWeapon == weaponId then
			self:playIdle(weaponId)
		end
	end)
	
	self.currentWeapon = weaponId
	print("[FPSAnimationController] Equipped weapon:", weaponId)
end

--------------------------------------------------------------------------------
-- EVENT CONNECTIONS
--------------------------------------------------------------------------------

-- Connect to weapon events
function FPSAnimationController:setupEventListeners()
	-- Wait for bindable events
	local bindableFolder = playerGui:WaitForChild("BindableEvents", 10)
	if not bindableFolder then
		warn("[FPSAnimationController] BindableEvents folder not found")
		return
	end
	
	-- Weapon fired
	local weaponFiredEvent = bindableFolder:FindFirstChild("WeaponFired")
	if weaponFiredEvent then
		weaponFiredEvent.Event:Connect(function(data)
			if data and data.weaponId then
				self:playFire(data.weaponId)
			end
		end)
	end
	
	-- Reload started
	local reloadStartedEvent = bindableFolder:FindFirstChild("ReloadStarted")
	if reloadStartedEvent then
		reloadStartedEvent.Event:Connect(function(data)
			if data and data.weaponId then
				local reloadTime = data.duration or 2.0
				self:playReload(data.weaponId, reloadTime)
			end
		end)
	end
	
	-- Reload canceled
	local reloadCanceledEvent = bindableFolder:FindFirstChild("ReloadCanceled")
	if reloadCanceledEvent then
		reloadCanceledEvent.Event:Connect(function()
			self:cancelReload()
		end)
	end
	
	-- Sprint state changed
	local sprintChangedEvent = bindableFolder:FindFirstChild("SprintStateChanged")
	if sprintChangedEvent then
		sprintChangedEvent.Event:Connect(function(isSprinting)
			self:setSprinting(isSprinting)
		end)
	end
	
	-- ADS state changed
	local adsChangedEvent = bindableFolder:FindFirstChild("ADSStateChanged")
	if adsChangedEvent then
		adsChangedEvent.Event:Connect(function(isADS)
			self:setADS(isADS)
		end)
	end
	
	-- Weapon equipped
	local weaponEquippedEvent = bindableFolder:FindFirstChild("WeaponEquipped")
	if weaponEquippedEvent then
		weaponEquippedEvent.Event:Connect(function(weaponId)
			self:equipWeapon(weaponId)
		end)
	end
end

--------------------------------------------------------------------------------
-- UPDATE LOOP
--------------------------------------------------------------------------------

-- Main update function
RunService.RenderStepped:Connect(function(deltaTime)
	if FPSAnimationController.enabled then
		FPSAnimationController:updateViewmodelPosition(deltaTime)
	end
end)

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function FPSAnimationController:initialize()
	-- Initialize remote events for server replication
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"AnimationFire",
		"AnimationSprint",
		"AnimationADS",
	})
	
	-- Create viewmodel
	self:createViewmodel()
	
	-- Setup event listeners
	self:setupEventListeners()
	
	-- Equip default weapon (will be updated by weapon controller)
	local defaultWeapon = "Pistol"
	self:equipWeapon(defaultWeapon)
	
	print("[FPSAnimationController] Initialized")
end

-- Auto-initialize
FPSAnimationController:initialize()

-- Export for external use
return FPSAnimationController
