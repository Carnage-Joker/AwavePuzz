-- @ScriptType: LocalScript
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")

local viewmodelClone = nil
local currentTool = nil

local offset = CFrame.new(1.3, -0.9, -3)
local firstPersonThreshold = 1.1

local function setLocalVisibility(model, visible)
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = visible and 0 or 1
		end
	end
end

local function onEquipped(tool)
	currentTool = tool

	if viewmodelClone then
		viewmodelClone:Destroy()
	end

	local handle = tool:FindFirstChild("Handle")
	if handle then
		viewmodelClone = handle:Clone()
		viewmodelClone.Name = "Viewmodel"
		viewmodelClone.Parent = nil

		viewmodelClone.Anchored = true
		viewmodelClone.CanCollide = false
		viewmodelClone.LocalTransparencyModifier = 0
	end

	_G.FirstPersonViewmodel = viewmodelClone
end

local function onUnequipped()
	if viewmodelClone then
		viewmodelClone:Destroy()
		viewmodelClone = nil
	end

	if currentTool then
		setLocalVisibility(currentTool, true)
	end

	_G.FirstPersonViewmodel = nil
	currentTool = nil
end

local function connectTool(tool)
	if tool:IsA("Tool") then
		tool.Equipped:Connect(function() onEquipped(tool) end)
		tool.Unequipped:Connect(onUnequipped)
	end
end

local function onCharacterAdded(character)
	for _, child in ipairs(character:GetChildren()) do
		connectTool(child)
	end
	character.ChildAdded:Connect(connectTool)
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

runService.RenderStepped:Connect(function()
	local isFirstPerson = (camera.CFrame.Position - camera.Focus.Position).Magnitude < firstPersonThreshold

	if viewmodelClone then
		if isFirstPerson then
			viewmodelClone.Parent = camera
			viewmodelClone.CFrame = camera.CFrame * offset -- Keep Handle synced to camera
		else
			viewmodelClone.Parent = nil
		end
	end

	if currentTool then
		setLocalVisibility(currentTool, not isFirstPerson)
	end
end)
