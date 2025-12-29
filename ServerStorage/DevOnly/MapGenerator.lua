-- MapGenerator.lua
-- Helper script to generate placeholder map models with proper folder structure
-- Run this in Roblox Studio's Command Bar to create map models in ServerStorage.Maps
-- Usage: require(game.ServerStorage.DevOnly.MapGenerator).generateAll()

local ServerStorage = game:GetService("ServerStorage")

local MapGenerator = {}

-- Helper to create a Part spawn point
local function createSpawnPart(position, name)
	local part = Instance.new("Part")
	part.Name = name or "SpawnPoint"
	part.Size = Vector3.new(2, 1, 2)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 0.5
	part.Color = Color3.fromRGB(0, 255, 0)
	return part
end

-- Helper to create a ground plane
local function createGroundPlane(position, size, color)
	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Size = size
	ground.Position = position
	ground.Anchored = true
	ground.Color = color or Color3.fromRGB(100, 100, 100)
	ground.Material = Enum.Material.Concrete
	ground.TopSurface = Enum.SurfaceType.Smooth
	ground.BottomSurface = Enum.SurfaceType.Smooth
	return ground
end

-- Generate ResearchOutpost map
function MapGenerator.generateResearchOutpost()
	local map = Instance.new("Model")
	map.Name = "ResearchOutpost"
	
	-- Ground
	local ground = createGroundPlane(Vector3.new(0, 0, 0), Vector3.new(200, 1, 200), Color3.fromRGB(80, 80, 80))
	ground.Parent = map
	
	-- ZombieSpawnPoints - 16 points in outer ring
	local zombieFolder = Instance.new("Folder")
	zombieFolder.Name = "ZombieSpawnPoints"
	zombieFolder.Parent = map
	
	local radius = 90
	for i = 1, 16 do
		local angle = (i / 16) * math.pi * 2
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local spawn = createSpawnPart(Vector3.new(x, 2, z), "ZombieSpawn_" .. i)
		spawn.Color = Color3.fromRGB(255, 0, 0)
		spawn.Parent = zombieFolder
	end
	
	-- SpawnPoints folder for standard convention
	local spawnPointsFolder = Instance.new("Folder")
	spawnPointsFolder.Name = "SpawnPoints"
	spawnPointsFolder.Parent = map
	
	-- ResourceSpawns - 10 points in mid ring
	local resourceFolder = Instance.new("Folder")
	resourceFolder.Name = "ResourceSpawns"
	resourceFolder.Parent = spawnPointsFolder
	
	local resourceRadius = 50
	for i = 1, 10 do
		local angle = (i / 10) * math.pi * 2
		local x = math.cos(angle) * resourceRadius
		local z = math.sin(angle) * resourceRadius
		local spawn = createSpawnPart(Vector3.new(x, 2, z), "ResourceSpawn_" .. i)
		spawn.Color = Color3.fromRGB(0, 0, 255)
		spawn.Parent = resourceFolder
	end
	
	-- ItemSpawns - 8 points near center
	local itemFolder = Instance.new("Folder")
	itemFolder.Name = "ItemSpawns"
	itemFolder.Parent = spawnPointsFolder
	
	local itemRadius = 20
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local x = math.cos(angle) * itemRadius
		local z = math.sin(angle) * itemRadius
		local spawn = createSpawnPart(Vector3.new(x, 2, z), "ItemSpawn_" .. i)
		spawn.Color = Color3.fromRGB(255, 255, 0)
		spawn.Parent = itemFolder
	end
	
	print("[MapGenerator] Created ResearchOutpost with 16 zombie, 10 resource, and 8 item spawns")
	return map
end

-- Generate Village map
function MapGenerator.generateVillage()
	local map = Instance.new("Model")
	map.Name = "Village"
	
	-- Ground with different color
	local ground = createGroundPlane(Vector3.new(0, 0, 0), Vector3.new(180, 1, 180), Color3.fromRGB(120, 100, 70))
	ground.Parent = map
	
	-- ZombieSpawnPoints - 16 points
	local zombieFolder = Instance.new("Folder")
	zombieFolder.Name = "ZombieSpawnPoints"
	zombieFolder.Parent = map
	
	local radius = 80
	for i = 1, 16 do
		local angle = (i / 16) * math.pi * 2
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local spawn = createSpawnPart(Vector3.new(x, 2, z), "ZombieSpawn_" .. i)
		spawn.Color = Color3.fromRGB(255, 0, 0)
		spawn.Parent = zombieFolder
	end
	
	-- SpawnPoints folder
	local spawnPointsFolder = Instance.new("Folder")
	spawnPointsFolder.Name = "SpawnPoints"
	spawnPointsFolder.Parent = map
	
	-- ResourceSpawns - 10 points
	local resourceFolder = Instance.new("Folder")
	resourceFolder.Name = "ResourceSpawns"
	resourceFolder.Parent = spawnPointsFolder
	
	local resourceRadius = 45
	for i = 1, 10 do
		local angle = (i / 10) * math.pi * 2
		local x = math.cos(angle) * resourceRadius
		local z = math.sin(angle) * resourceRadius
		local spawn = createSpawnPart(Vector3.new(x, 2, z), "ResourceSpawn_" .. i)
		spawn.Color = Color3.fromRGB(0, 0, 255)
		spawn.Parent = resourceFolder
	end
	
	-- ItemSpawns - 8 points
	local itemFolder = Instance.new("Folder")
	itemFolder.Name = "ItemSpawns"
	itemFolder.Parent = spawnPointsFolder
	
	local itemRadius = 18
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local x = math.cos(angle) * itemRadius
		local z = math.sin(angle) * itemRadius
		local spawn = createSpawnPart(Vector3.new(x, 2, z), "ItemSpawn_" .. i)
		spawn.Color = Color3.fromRGB(255, 255, 0)
		spawn.Parent = itemFolder
	end
	
	print("[MapGenerator] Created Village with 16 zombie, 10 resource, and 8 item spawns")
	return map
end

-- Generate Dockyards map
function MapGenerator.generateDockyards()
	local map = Instance.new("Model")
	map.Name = "Dockyards"
	
	-- Ground with industrial color
	local ground = createGroundPlane(Vector3.new(0, 0, 0), Vector3.new(220, 1, 220), Color3.fromRGB(60, 60, 70))
	ground.Parent = map
	
	-- ZombieSpawnPoints - 16 points
	local zombieFolder = Instance.new("Folder")
	zombieFolder.Name = "ZombieSpawnPoints"
	zombieFolder.Parent = map
	
	local radius = 100
	for i = 1, 16 do
		local angle = (i / 16) * math.pi * 2
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local spawn = createSpawnPart(Vector3.new(x, 2, z), "ZombieSpawn_" .. i)
		spawn.Color = Color3.fromRGB(255, 0, 0)
		spawn.Parent = zombieFolder
	end
	
	-- SpawnPoints folder
	local spawnPointsFolder = Instance.new("Folder")
	spawnPointsFolder.Name = "SpawnPoints"
	spawnPointsFolder.Parent = map
	
	-- ResourceSpawns - 10 points
	local resourceFolder = Instance.new("Folder")
	resourceFolder.Name = "ResourceSpawns"
	resourceFolder.Parent = spawnPointsFolder
	
	local resourceRadius = 55
	for i = 1, 10 do
		local angle = (i / 10) * math.pi * 2
		local x = math.cos(angle) * resourceRadius
		local z = math.sin(angle) * resourceRadius
		local spawn = createSpawnPart(Vector3.new(x, 2, z), "ResourceSpawn_" .. i)
		spawn.Color = Color3.fromRGB(0, 0, 255)
		spawn.Parent = resourceFolder
	end
	
	-- ItemSpawns - 8 points
	local itemFolder = Instance.new("Folder")
	itemFolder.Name = "ItemSpawns"
	itemFolder.Parent = spawnPointsFolder
	
	local itemRadius = 22
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local x = math.cos(angle) * itemRadius
		local z = math.sin(angle) * itemRadius
		local spawn = createSpawnPart(Vector3.new(x, 2, z), "ItemSpawn_" .. i)
		spawn.Color = Color3.fromRGB(255, 255, 0)
		spawn.Parent = itemFolder
	end
	
	print("[MapGenerator] Created Dockyards with 16 zombie, 10 resource, and 8 item spawns")
	return map
end

-- Generate ResearchOutpost_Night (variant with same geometry)
function MapGenerator.generateResearchOutpostNight()
	-- Start with the base map
	local map = MapGenerator.generateResearchOutpost()
	map.Name = "ResearchOutpost_Night"
	
	-- Make the ground darker for night atmosphere
	local ground = map:FindFirstChild("Ground")
	if ground then
		ground.Color = Color3.fromRGB(30, 30, 35)
	end
	
	print("[MapGenerator] Created ResearchOutpost_Night variant")
	return map
end

-- Generate all maps and place them in ServerStorage.Maps
function MapGenerator.generateAll()
	local mapsFolder = ServerStorage:FindFirstChild("Maps")
	if not mapsFolder then
		mapsFolder = Instance.new("Folder")
		mapsFolder.Name = "Maps"
		mapsFolder.Parent = ServerStorage
		print("[MapGenerator] Created Maps folder in ServerStorage")
	end
	
	-- Remove placeholder files if they exist
	local placeholders = {
		"DesertOutpost_PLACEHOLDER.txt",
		"ResearchFacility_PLACEHOLDER.txt",
		"UrbanRuins_PLACEHOLDER.txt"
	}
	for _, name in ipairs(placeholders) do
		local placeholder = mapsFolder:FindFirstChild(name)
		if placeholder then
			placeholder:Destroy()
		end
	end
	
	-- Generate and place each map
	local maps = {
		MapGenerator.generateResearchOutpost(),
		MapGenerator.generateVillage(),
		MapGenerator.generateDockyards(),
		MapGenerator.generateResearchOutpostNight()
	}
	
	for _, map in ipairs(maps) do
		-- Remove existing map with same name
		local existing = mapsFolder:FindFirstChild(map.Name)
		if existing then
			existing:Destroy()
			warn("[MapGenerator] Replaced existing map: " .. map.Name)
		end
		
		map.Parent = mapsFolder
		print("[MapGenerator] ✓ Placed " .. map.Name .. " in ServerStorage.Maps")
	end
	
	print("\n[MapGenerator] ✓ All maps generated successfully!")
	print("Maps created: ResearchOutpost, Village, Dockyards, ResearchOutpost_Night")
	print("\nTo test, run the game and check the map voting system.")
	
	return true
end

-- Cleanup function to remove all generated maps
function MapGenerator.cleanup()
	local mapsFolder = ServerStorage:FindFirstChild("Maps")
	if not mapsFolder then
		warn("[MapGenerator] Maps folder not found")
		return
	end
	
	local mapNames = {"ResearchOutpost", "Village", "Dockyards", "ResearchOutpost_Night"}
	for _, name in ipairs(mapNames) do
		local map = mapsFolder:FindFirstChild(name)
		if map then
			map:Destroy()
			print("[MapGenerator] Removed " .. name)
		end
	end
	
	print("[MapGenerator] Cleanup complete")
end

return MapGenerator
