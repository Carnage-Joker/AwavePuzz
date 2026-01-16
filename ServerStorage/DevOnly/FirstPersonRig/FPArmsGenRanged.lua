-- @ScriptType: LocalScript
-- FirstPersonArmsSetup.lua
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function createArm(name)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(1, 2, 1)
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = workspace
	return part
end

local function applyShirtFromCharacter(leftArm, rightArm)
	local character = player.Character or player.CharacterAdded:Wait()
	local shirt = character:FindFirstChildOfClass("Shirt")
	if not shirt then return end

	local function setupFakeCharacterPart(part, limbName)
		local fakeChar = Instance.new("Model")
		fakeChar.Name = "ArmWrapper_" .. limbName

		local humanoid = Instance.new("Humanoid")
		humanoid.Name = "FakeHumanoid"
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.Parent = fakeChar

		local shirtClone = shirt:Clone()
		shirtClone.Parent = fakeChar

		part.Name = limbName
		part.Parent = fakeChar

		fakeChar.Parent = workspace
	end

	for _, child in pairs(workspace:GetChildren()) do
		if child:IsA("Model") and (child.Name == "ArmWrapper_Left Arm" or child.Name == "ArmWrapper_Right Arm") then
			child:Destroy()
		end
	end

	setupFakeCharacterPart(leftArm, "Left Arm")
	setupFakeCharacterPart(rightArm, "Right Arm")
end

local leftArm = createArm("LeftArm")
local rightArm = createArm("RightArm")

applyShirtFromCharacter(leftArm, rightArm)

player.CharacterAdded:Connect(function()
	task.wait(1)
	applyShirtFromCharacter(leftArm, rightArm)
end)

-- Store arms in _G to access from animation script
_G.FirstPersonArms = {
	Left = leftArm,
	Right = rightArm,
}
