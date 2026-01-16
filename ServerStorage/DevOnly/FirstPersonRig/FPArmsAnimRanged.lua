-- @ScriptType: LocalScript
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local FIRST_PERSON_ZOOM_THRESHOLD = 2.5

-- Editable offsets
local rightArmOffset = Vector3.new(1.4, -1.3, -2.0)
local leftArmOffset = Vector3.new(0.5, -1.4, -1.8)

-- Editable separate rotations for each arm
local rightArmRotation = CFrame.Angles(math.rad(0), math.rad(180), math.rad(-90)) * CFrame.Angles(math.rad(0), math.rad(90), math.rad(-90))
local leftArmRotation = CFrame.Angles(math.rad(0), math.rad(180), math.rad(-90)) * CFrame.Angles(math.rad(25), math.rad(90), math.rad(-90))

local idleAmplitude = 0.02
local idleSpeed = 3

-- Separate recoil for moving and standing
local movingRecoilOffset = CFrame.new(0, 0.2, 0)
local standingRecoilOffset = CFrame.new(0, 0.3, 0)

local recoilDuration = 0.1
local recoilRecoverTime = 0.15

local recoilTimer = 100 -- no recoil initially

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
		recoilTimer = 0
	end
end)

RunService.RenderStepped:Connect(function(deltaTime)
	local arms = _G.FirstPersonArms
	if not arms then return end
	local leftArm = arms.Left
	local rightArm = arms.Right

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		leftArm.Transparency = 1
		rightArm.Transparency = 1
		return
	end

	local zoom = (camera.CFrame.Position - hrp.Position).Magnitude
	local inFirstPerson = zoom < FIRST_PERSON_ZOOM_THRESHOLD

	leftArm.Transparency = inFirstPerson and 0 or 1
	rightArm.Transparency = inFirstPerson and 0 or 1

	if inFirstPerson then
		local camCF = camera.CFrame
		local velocity = hrp.Velocity
		local isMoving = velocity.Magnitude > 1

		local recoilBase = isMoving and movingRecoilOffset or standingRecoilOffset

		-- Update recoil timer and calculate recoil CFrame
		local recoilCFrame
		if recoilTimer < recoilDuration then
			local alpha = recoilTimer / recoilDuration
			recoilCFrame = recoilBase:Lerp(CFrame.new(), 1 - alpha)
			recoilTimer = recoilTimer + deltaTime
		elseif recoilTimer < recoilDuration + recoilRecoverTime then
			local alpha = (recoilTimer - recoilDuration) / recoilRecoverTime
			recoilCFrame = CFrame.new():Lerp(recoilBase, 1 - alpha)
			recoilTimer = recoilTimer + deltaTime
		else
			recoilCFrame = CFrame.new()
			recoilTimer = recoilDuration + recoilRecoverTime
		end

		-- Idle bob
		local t = tick()
		local bob = math.sin(t * idleSpeed) * idleAmplitude
		local idleCFrame = CFrame.new(0, bob, 0)

		local animOffset = idleCFrame * recoilCFrame

		rightArm.CFrame = camCF * CFrame.new(rightArmOffset) * rightArmRotation * animOffset
		leftArm.CFrame = camCF * CFrame.new(leftArmOffset) * leftArmRotation * animOffset
	end
end)
