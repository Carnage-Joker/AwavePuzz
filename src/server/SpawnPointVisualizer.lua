-- SpawnPointVisualizer.lua
-- Visualizes spawn points for debugging purposes
-- Creates parts at spawn point locations to help verify placement

local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local SpawnPointVisualizer = {}
SpawnPointVisualizer.__index = SpawnPointVisualizer

local VISUAL_CONFIG = {
	MANUAL_SPAWN_COLOR = BrickColor.new("Bright blue"),
	GENERATED_SPAWN_COLOR = BrickColor.new("Bright orange"),
	SELECTED_SPAWN_COLOR = BrickColor.new("Bright red"),
	SPAWN_PART_SIZE = Vector3.new(2, 0.5, 2),
	BEAM_HEIGHT = 10,
	VISUAL_DURATION = 30
}

function SpawnPointVisualizer.new()
	local self = setmetatable({}, SpawnPointVisualizer)
	self.visualFolder = nil
	self.activeVisuals = {}
	return self
end

function SpawnPointVisualizer:ensureVisualFolder()
	if not self.visualFolder then
		self.visualFolder = Workspace:FindFirstChild("SpawnPointVisuals")
		if not self.visualFolder then
			self.visualFolder = Instance.new("Folder")
			self.visualFolder.Name = "SpawnPointVisuals"
			self.visualFolder.Parent = Workspace
		end
	end
end

function SpawnPointVisualizer:createSpawnVisual(position, spawnType, index)
	self:ensureVisualFolder()

	local basePart = Instance.new("Part")
	basePart.Name = "SpawnVisual_" .. spawnType .. "_" .. tostring(index)
	basePart.Size = VISUAL_CONFIG.SPAWN_PART_SIZE
	basePart.Anchored = true
	basePart.CanCollide = false
	basePart.Transparency = 0.3

	if spawnType == "manual" then
		basePart.BrickColor = VISUAL_CONFIG.MANUAL_SPAWN_COLOR
	elseif spawnType == "generated" then
		basePart.BrickColor = VISUAL_CONFIG.GENERATED_SPAWN_COLOR
	elseif spawnType == "selected" then
		basePart.BrickColor = VISUAL_CONFIG.SELECTED_SPAWN_COLOR
	else
		basePart.BrickColor = BrickColor.new("White")
	end

	basePart.Position = position
	basePart.Parent = self.visualFolder

	local beam = Instance.new("Part")
	beam.Name = "Beam_" .. spawnType .. "_" .. tostring(index)
	beam.Size = Vector3.new(0.2, VISUAL_CONFIG.BEAM_HEIGHT, 0.2)
	beam.Anchored = true
	beam.CanCollide = false
	beam.Transparency = 0.5
	beam.BrickColor = basePart.BrickColor
	beam.Position = position + Vector3.new(0, VISUAL_CONFIG.BEAM_HEIGHT / 2, 0)
	beam.Parent = self.visualFolder

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Billboard_" .. spawnType .. "_" .. tostring(index)
	billboard.Size = UDim2.new(0, 100, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Parent = basePart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = spawnType .. "\n(" .. math.floor(position.X) .. ", " .. math.floor(position.Y) .. ", " .. math.floor(position.Z) .. ")"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = billboard

	table.insert(self.activeVisuals, { basePart = basePart, beam = beam, billboard = billboard })

	Debris:AddItem(basePart, VISUAL_CONFIG.VISUAL_DURATION)
	Debris:AddItem(beam, VISUAL_CONFIG.VISUAL_DURATION)
	Debris:AddItem(billboard, VISUAL_CONFIG.VISUAL_DURATION)

	return basePart
end

function SpawnPointVisualizer:visualizeSpawnPoints(manualSpawns, generatedSpawns)
	print("[SpawnPointVisualizer] Visualizing spawn points...")

	self:clearVisuals()

	if manualSpawns then
		for i, pos in ipairs(manualSpawns) do
			self:createSpawnVisual(pos, "manual", i)
		end
	end

	if generatedSpawns then
		for i, pos in ipairs(generatedSpawns) do
			self:createSpawnVisual(pos, "generated", i)
		end
	end

	print("[SpawnPointVisualizer] Created visuals for",
		(manualSpawns and #manualSpawns or 0), "manual and",
		(generatedSpawns and #generatedSpawns or 0), "generated spawn points")
end

function SpawnPointVisualizer:highlightSelectedSpawn(position, zombieType)
	if position then
		local visual = self:createSpawnVisual(position, "selected", zombieType)
		visual.Transparency = 0
		print("[SpawnPointVisualizer] Highlighted selected spawn for", zombieType, "at", position)
	end
end

function SpawnPointVisualizer:clearVisuals()
	if self.visualFolder then
		self.visualFolder:ClearAllChildren()
	end
	self.activeVisuals = {}
	print("[SpawnPointVisualizer] Cleared all spawn point visuals")
end

function SpawnPointVisualizer:enableDebugMode(enabled)
	if enabled then
		self:ensureVisualFolder()
		print("[SpawnPointVisualizer] Debug mode enabled")
	else
		self:clearVisuals()
		print("[SpawnPointVisualizer] Debug mode disabled")
	end
end

return SpawnPointVisualizer
