-- ResourceSpawner.lua
-- Manages spawning of cure components around the map

local GameConfig = require(script.Parent.Parent.shared.GameConfig)

local ResourceSpawner = {}
ResourceSpawner.__index = ResourceSpawner

function ResourceSpawner.new()
	local self = setmetatable({}, ResourceSpawner)
	self.activeResources = {}
	self.spawnTimer = 0
	self.spawnPoints = {} -- Will be populated with spawn locations
	return self
end

function ResourceSpawner:addSpawnPoint(position)
	table.insert(self.spawnPoints, position)
end

function ResourceSpawner:getRandomComponent()
	local components = GameConfig.CURE_COMPONENT_NAMES
	return components[math.random(1, #components)]
end

function ResourceSpawner:getRandomSpawnPoint()
	if #self.spawnPoints == 0 then
		return nil
	end
	return self.spawnPoints[math.random(1, #self.spawnPoints)]
end

function ResourceSpawner:spawnResource()
	if #self.activeResources >= GameConfig.MAX_RESOURCES_ON_MAP then
		return nil
	end
	
	local spawnPoint = self:getRandomSpawnPoint()
	if not spawnPoint then
		return nil
	end
	
	local componentName = self:getRandomComponent()
	local resourceId = "resource_" .. os.time() .. "_" .. math.random(1000, 9999)
	
	local resource = {
		id = resourceId,
		componentName = componentName,
		position = spawnPoint,
		spawnTime = os.time()
	}
	
	self.activeResources[resourceId] = resource
	
	return resource
end

function ResourceSpawner:collectResource(resourceId)
	local resource = self.activeResources[resourceId]
	if not resource then
		return nil
	end
	
	self.activeResources[resourceId] = nil
	return resource.componentName
end

function ResourceSpawner:update(deltaTime)
	self.spawnTimer = self.spawnTimer + deltaTime
	
	if self.spawnTimer >= GameConfig.RESOURCE_SPAWN_RATE then
		self.spawnTimer = 0
		return self:spawnResource()
	end
	
	return nil
end

function ResourceSpawner:getActiveResourceCount()
	local count = 0
	for _ in pairs(self.activeResources) do
		count = count + 1
	end
	return count
end

return ResourceSpawner
