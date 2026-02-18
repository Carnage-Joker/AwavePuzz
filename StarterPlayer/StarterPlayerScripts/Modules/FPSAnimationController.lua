-- @ScriptType: ModuleScript
-- FPSAnimationController.client.lua
-- Manages all weapon and viewmodel animations for the FPS system

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- Shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local FPSConfig = require(SharedFolder:WaitForChild("FPSConfig"))
local RemotesFolder = SharedFolder:WaitForChild("Remotes")
local RemoteRegistry = require(RemotesFolder:WaitForChild("RemoteRegistry"))

--------------------------------------------------------------------------------
-- CONTROLLER
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

	-- Internal
	_connections = {},
}

--------------------------------------------------------------------------------
-- VIEWMODEL
--------------------------------------------------------------------------------

function FPSAnimationController:createViewmodel()
	local existing = camera:FindFirstChild("Viewmodel")
	if existing then
		self.viewmodel = existing
		self.viewmodelArms = existing:FindFirstChild("Arms")
		return
	end

	local viewmodel = Instance.new("Model")
	viewmodel.Name = "Viewmodel"
	viewmodel.Parent = camera
	self.viewmodel = viewmodel

	local arms = Instance.new("Model")
	arms.Name = "Arms"
	arms.Parent = viewmodel
	self.viewmodelArms = arms

	local rightHand = Instance.new("Part")
	rightHand.Name = "RightHand"
	rightHand.Size = Vector3.new(0.2, 0.2, 0.2)
	rightHand.Transparency = 1
	rightHand.CanCollide = false
	rightHand.Anchored = true
	rightHand.Parent = arms

	local leftHand = Instance.new("Part")
	leftHand.Name = "LeftHand"
	leftHand.Size = Vector3.new(0.2, 0.2, 0.2)
	leftHand.Transparency = 1
	leftHand.CanCollide = false
	leftHand.Anchored = true
	leftHand.Parent = arms

	print("[FPSAnimationController] Created viewmodel")
end

function FPSAnimationController:loadWeaponModel(weaponId)
	if self.currentWeaponModel then
		self.currentWeaponModel:Destroy()
		self.currentWeaponModel = nil
	end

	local weaponModel
	local gunsFolder = ReplicatedStorage:FindFirstChild("Guns")
	if gunsFolder then
		local template = gunsFolder:FindFirstChild(weaponId) -- ✅ removed duplicate line
		if template then
			weaponModel = template:Clone()
		end
	end

	if not weaponModel then
		weaponModel = Instance.new("Model")
		weaponModel.Name = weaponId

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

		local weld = Instance.new("Weld")
		weld.Part0 = handle
		weld.Part1 = barrel
		weld.C0 = CFrame.new(0, 0.2, -0.3)
		weld.Parent = handle
	end

	weaponModel.Parent = self.viewmodel
	self.currentWeaponModel = weaponModel

	local rightHand = self.viewmodelArms and self.viewmodelArms:FindFirstChild("RightHand")
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

function FPSAnimationController:getWeaponOffset(weaponId)
	local animConfig = FPSConfig.Animations
	if animConfig and animConfig.WeaponOffsets and animConfig.WeaponOffsets[weaponId] then
		return animConfig.WeaponOffsets[weaponId]
	end
	return CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
end

--------------------------------------------------------------------------------
-- ANIMATION LOADING
--------------------------------------------------------------------------------

function FPSAnimationController:loadAnimation(weaponId, animationType)
	if not self.enabled then return nil end

	local animConfig = FPSConfig.Animations
	if not animConfig or not animConfig.WeaponAnimations then return nil end

	local weaponAnims = animConfig.WeaponAnimations[weaponId]
	if not weaponAnims or not weaponAnims[animationType] then return nil end

	local animationId = weaponAnims[animationType]
	if not animationId or animationId == "" or animationId == "rbxassetid://0" then
		return nil
	end

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

	-- Wrap animation loading with error handling to prevent spam
	local success, result = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	
	if not success then
		warn("[FPSAnimationController] Failed to load animation: " .. tostring(result))
		return nil
	end
	
	return result
end

--------------------------------------------------------------------------------
-- ANIMATION PLAYBACK
--------------------------------------------------------------------------------

function FPSAnimationController:stopAnimation(animationType)
	local anim = self.currentAnimations[animationType]
	if anim then
		anim:Stop()
		self.currentAnimations[animationType] = nil
	end
end

function FPSAnimationController:stopAllAnimations()
	for t, anim in pairs(self.currentAnimations) do
		if anim then
			anim:Stop()
			self.currentAnimations[t] = nil
		end
	end
end

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

function FPSAnimationController:playFire(weaponId)
	local fireAnim = self:loadAnimation(weaponId, "fire")
	if fireAnim then
		fireAnim.Looped = false
		fireAnim.Priority = Enum.AnimationPriority.Action
		fireAnim:Play()
		self.currentAnimations.fire = fireAnim

		fireAnim.Stopped:Once(function()
			if self.currentAnimations.fire == fireAnim then
				self.currentAnimations.fire = nil
			end
		end)
	end

	if self.remoteEvents and self.remoteEvents.AnimationFire then
		self.remoteEvents.AnimationFire:FireServer(weaponId)
	end
end

function FPSAnimationController:playReload(weaponId, reloadTime)
	self:stopAnimation("reload")

	local reloadAnim = self:loadAnimation(weaponId, "reload")
	if reloadAnim then
		reloadAnim.Looped = false
		reloadAnim.Priority = Enum.AnimationPriority.Action2

		if reloadTime then
			local len = reloadAnim.Length
			if len > 0 then
				reloadAnim:AdjustSpeed(len / reloadTime)
			end
		end

		reloadAnim:Play()
		self.currentAnimations.reload = reloadAnim
		self.isReloading = true

		reloadAnim.Stopped:Once(function()
			self.isReloading = false
			if self.currentAnimations.reload == reloadAnim then
				self.currentAnimations.reload = nil
			end
		end)
	end
end

function FPSAnimationController:cancelReload()
	if self.isReloading then
		self:stopAnimation("reload")
		self.isReloading = false
	end
end

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

	if self.remoteEvents and self.remoteEvents.AnimationSprint then
		self.remoteEvents.AnimationSprint:FireServer(isSprinting)
	end
end

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

	if self.remoteEvents and self.remoteEvents.AnimationADS then
		self.remoteEvents.AnimationADS:FireServer(isADS)
	end
end

--------------------------------------------------------------------------------
-- PROCEDURAL ANIMATION
--------------------------------------------------------------------------------

function FPSAnimationController:updateWeaponSway(dt)
	local animConfig = FPSConfig.Animations
	if not animConfig or not animConfig.WeaponSwayEnabled then
		return CFrame.new()
	end

	local mouseDelta = UserInputService:GetMouseDelta()
	local swayAmount = animConfig.SwayAmount or 0.02
	local swaySpeed = animConfig.SwaySpeed or 10

	local target = CFrame.new(
		-mouseDelta.X * swayAmount * 0.01,
		-mouseDelta.Y * swayAmount * 0.01,
		0
	) * CFrame.Angles(
		math.rad(mouseDelta.Y * swayAmount * 2),
		math.rad(-mouseDelta.X * swayAmount * 2),
		0
	)

	self.swayOffset = self.swayOffset:Lerp(target, dt * swaySpeed)
	return self.swayOffset
end

function FPSAnimationController:updateBreathing(dt)
	local animConfig = FPSConfig.Animations
	if not animConfig or not animConfig.BreathingEnabled then
		return CFrame.new()
	end

	self.breathTime += dt

	local speed = animConfig.BreathSpeed or 2
	local amt = animConfig.BreathAmount or 0.01

	local y = math.sin(self.breathTime * speed) * amt
	local z = math.cos(self.breathTime * speed * 0.5) * amt * 0.5

	self.breathOffset = CFrame.new(0, y, z)
	return self.breathOffset
end

function FPSAnimationController:applyRecoilOffset(vertical, horizontal)
	local animConfig = FPSConfig.Animations
	if not animConfig or not animConfig.RecoilAnimationEnabled then return end

	local v = math.rad(vertical)
	local h = math.rad(horizontal)

	self.recoilOffset = self.recoilOffset * CFrame.Angles(-v, h, 0)
end

function FPSAnimationController:updateRecoilRecovery(dt)
	local animConfig = FPSConfig.Animations
	local speed = (animConfig and animConfig.RecoilRecoverySpeed) or 10
	self.recoilOffset = self.recoilOffset:Lerp(CFrame.new(), dt * speed)
	return self.recoilOffset
end

function FPSAnimationController:updateViewmodelPosition(dt)
	if not self.enabled or not self.viewmodel or not self.viewmodelArms then return end

	local sway = self:updateWeaponSway(dt)
	local breath = self:updateBreathing(dt)
	local recoil = self:updateRecoilRecovery(dt)
	local combined = sway * breath * recoil

	local rightHand = self.viewmodelArms:FindFirstChild("RightHand")
	if rightHand then
		local base = CFrame.new(0.5, -0.5, -1)
		if self.isADS then
			base = CFrame.new(0, -0.3, -0.8)
		elseif self.isSprinting then
			base = CFrame.new(0.3, -0.8, -0.5)
		end
		rightHand.CFrame = camera.CFrame * base * combined
	end

	local leftHand = self.viewmodelArms:FindFirstChild("LeftHand")
	if leftHand then
		local base = CFrame.new(-0.5, -0.5, -1.2)
		if self.isADS then
			base = CFrame.new(-0.2, -0.3, -0.8)
		elseif self.isSprinting then
			base = CFrame.new(-0.3, -0.8, -0.5)
		end
		leftHand.CFrame = camera.CFrame * base * combined
	end
end

--------------------------------------------------------------------------------
-- WEAPON SWITCHING
--------------------------------------------------------------------------------

function FPSAnimationController:equipWeapon(weaponId)
	if weaponId == self.currentWeapon then return end

	self:stopAllAnimations()
	self.currentWeapon = weaponId

	self:loadWeaponModel(weaponId)
	self:playEquip(weaponId)

	task.delay(0.5, function()
		if self.currentWeapon == weaponId then
			self:playIdle(weaponId)
		end
	end)

	print("[FPSAnimationController] Equipped weapon:", weaponId)
end

--------------------------------------------------------------------------------
-- EVENTS
--------------------------------------------------------------------------------

function FPSAnimationController:setupEventListeners()
	local bindableFolder = playerGui:WaitForChild("BindableEvents", 10)
	if not bindableFolder then
		warn("[FPSAnimationController] BindableEvents folder not found")
		return
	end

	local function hook(name, fn)
		local ev = bindableFolder:FindFirstChild(name)
		if ev then
			table.insert(self._connections, ev.Event:Connect(fn))
		end
	end

	hook("WeaponFired", function(data)
		if data and data.weaponId then
			self:playFire(data.weaponId)
		end
	end)

	hook("ReloadStarted", function(data)
		if data and data.weaponId then
			self:playReload(data.weaponId, data.duration or 2.0)
		end
	end)

	hook("ReloadCanceled", function()
		self:cancelReload()
	end)

	hook("SprintStateChanged", function(isSprinting)
		self:setSprinting(isSprinting)
	end)

	hook("ADSStateChanged", function(isADS)
		self:setADS(isADS)
	end)

	hook("WeaponEquipped", function(weaponId)
		self:equipWeapon(weaponId)
	end)
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function FPSAnimationController.update(dt)
	if FPSAnimationController.enabled then
		FPSAnimationController:updateViewmodelPosition(dt)
	end
end

function FPSAnimationController.initialize()
	-- remote replication
	local remotes = RemoteRegistry.GetClientRemotes()
	FPSAnimationController.remoteEvents = {
		AnimationFire = remotes.AnimationFire,
		AnimationSprint = remotes.AnimationSprint,
		AnimationADS = remotes.AnimationADS,
	}

	FPSAnimationController:createViewmodel()
	FPSAnimationController:setupEventListeners()

	-- ✅ one loop only
	table.insert(FPSAnimationController._connections, RunService.RenderStepped:Connect(function(dt)
		FPSAnimationController.update(dt)
	end))

	-- Optional default weapon (if your weapon controller will drive this, remove it)
	FPSAnimationController:equipWeapon("Pistol")

	print("[FPSAnimationController] Initialized")
end

function FPSAnimationController.onCharacterAdded(character) end
function FPSAnimationController.onCharacterRemoving() end

function FPSAnimationController.cleanup()
	for _, connection in ipairs(FPSAnimationController._connections) do
		connection:Disconnect()
	end
	table.clear(FPSAnimationController._connections)
	print("[FPSAnimationController] Cleanup complete")
end

return FPSAnimationController
