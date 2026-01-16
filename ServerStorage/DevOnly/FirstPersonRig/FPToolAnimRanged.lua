-- @ScriptType: LocalScript
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Animation parameters
local idleAmplitude = 0.01
local idleSpeed = 4
local baseRecoilOffset = CFrame.new(0, 0, 0.1)
local stillRecoilOffset = CFrame.new(0, 0, 0.3)
local recoilDuration = 0.1
local recoilRecoverTime = 0.15

local offset = CFrame.new(1.3, -0.9, -3)
local firstPersonThreshold = 1.1

local recoilTimer = 100

-- Trigger recoil
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
		recoilTimer = 0
	end
end)

RunService.RenderStepped:Connect(function(deltaTime)
	local viewmodel = _G.FirstPersonViewmodel
	if not viewmodel then return end

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Check if in first person
	local zoom = (camera.CFrame.Position - camera.Focus.Position).Magnitude
	local inFirstPerson = zoom < firstPersonThreshold

	if not inFirstPerson then
		-- Hide tool if not first person
		viewmodel.Parent = nil
		return
	end

	-- Ensure it's parented to camera
	if viewmodel.Parent ~= camera then
		viewmodel.Parent = camera
	end

	local camCF = camera.CFrame
	local velocity = hrp.Velocity
	local isMoving = velocity.Magnitude > 1
	local recoilBase = isMoving and baseRecoilOffset or stillRecoilOffset

	-- Recoil calculation
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

	-- Apply final offset
	viewmodel.CFrame = camCF * offset * idleCFrame * recoilCFrame
end)
