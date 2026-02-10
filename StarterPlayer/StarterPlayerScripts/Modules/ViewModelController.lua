--!strict
-- ViewModelController.client.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local ViewModelController = {}
ViewModelController.__index = ViewModelController

local RENDER_NAME = "FPSViewModel"

local currentVM: Model? = nil
local conns: {RBXScriptConnection} = {}

local function disconnectAll()
	for _, c in ipairs(conns) do
		if c.Connected then c:Disconnect() end
	end
	table.clear(conns)
end

local function ensureCamera()
	if not camera then camera = workspace.CurrentCamera end
end

local function setPartFlags(model: Model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.CastShadow = false
		end
	end
end

function ViewModelController:DestroyViewModel()
	RunService:UnbindFromRenderStep(RENDER_NAME)
	if currentVM then
		currentVM:Destroy()
		currentVM = nil
	end
end

function ViewModelController:SpawnViewModel()
	self:DestroyViewModel()
	ensureCamera()

	local folder = ReplicatedStorage:WaitForChild("ViewModels")
	local template = folder:WaitForChild("ArmsR15") :: Model
	local vm = template:Clone()
	vm.Name = "ViewModel"
	vm.Parent = camera

	if not vm.PrimaryPart then
		vm.PrimaryPart = vm:FindFirstChild("Root") or vm:FindFirstChildWhichIsA("BasePart")
	end
	assert(vm.PrimaryPart, "ViewModel has no PrimaryPart/Root")

	setPartFlags(vm)
	currentVM = vm

	-- Render AFTER camera update so it follows perfectly
	RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Camera.Value + 1, function()
		if not currentVM or not currentVM.PrimaryPart then return end
		ensureCamera()
		-- tweak offsets to taste
		local offset = CFrame.new(0.7, -0.9, -1.2) * CFrame.Angles(0, math.rad(180), 0)
		currentVM:PivotTo(camera.CFrame * offset)
	end)
end

return ViewModelController
