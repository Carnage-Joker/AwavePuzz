-- SurroundService.lua
-- Manages surround slots and anti-pileup behavior for zombies
-- Features slot reservation, ring distribution, and local separation steering

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local SurroundService = {}
SurroundService.__index = SurroundService

-- Configuration
local CONFIG = {
	INNER_RING_RADIUS = 8, -- Distance for inner ring slots
	MIDDLE_RING_RADIUS = 15, -- Distance for middle ring slots
	OUTER_RING_RADIUS = 25, -- Distance for outer ring slots
	SLOTS_PER_RING = 8, -- Number of slots per ring
	SLOT_RESERVATION_TIME = 2.0, -- How long a slot is reserved
	SEPARATION_RADIUS = 3, -- Minimum distance between zombies
	SEPARATION_STRENGTH = 0.5, -- Strength of separation steering
	SLOT_TIMEOUT = 5.0, -- Time before re-rolling slot if unreachable
}

function SurroundService.new()
	local self = setmetatable({}, SurroundService)
	
	self.slotReservations = {} -- [slotKey] = {zombie, reservedTime, ringIndex, slotIndex}
	self.zombieSlots = {} -- [zombieModel] = {slotKey, targetPos, assignedTime}
	
	return self
end

-- Generate slot key for tracking
local function generateSlotKey(targetId, ringIndex, slotIndex)
	return string.format("%s_r%d_s%d", tostring(targetId), ringIndex, slotIndex)
end

-- Calculate slot position around a target
local function calculateSlotPosition(targetPos, ringIndex, slotIndex, totalSlots)
	local radius
	if ringIndex == 1 then
		radius = CONFIG.INNER_RING_RADIUS
	elseif ringIndex == 2 then
		radius = CONFIG.MIDDLE_RING_RADIUS
	else
		radius = CONFIG.OUTER_RING_RADIUS
	end
	
	local angleStep = (math.pi * 2) / totalSlots
	local angle = angleStep * slotIndex
	
	local offsetX = math.cos(angle) * radius
	local offsetZ = math.sin(angle) * radius
	
	return targetPos + Vector3.new(offsetX, 0, offsetZ)
end

-- Check if a slot is available
function SurroundService:isSlotAvailable(slotKey, currentTime)
	local reservation = self.slotReservations[slotKey]
	
	if not reservation then
		return true
	end
	
	-- Check if reservation expired
	local timeSince = currentTime - reservation.reservedTime
	if timeSince > CONFIG.SLOT_RESERVATION_TIME then
		return true
	end
	
	-- Check if zombie still exists
	if not reservation.zombie or not reservation.zombie.Parent then
		return true
	end
	
	return false
end

-- Find available slot around target
function SurroundService:findAvailableSlot(targetPos, targetId, preferRing, preferSide)
	local currentTime = tick()
	
	-- Determine ring priority based on preference
	local ringPriority
	if preferRing == "inner" then
		ringPriority = {1, 2, 3}
	elseif preferRing == "outer" then
		ringPriority = {3, 2, 1}
	else
		ringPriority = {2, 1, 3} -- Default to middle
	end
	
	-- Try each ring in priority order
	for _, ringIndex in ipairs(ringPriority) do
		local totalSlots = CONFIG.SLOTS_PER_RING
		
		-- Determine slot search order based on side preference
		local slotOrder = {}
		if preferSide == "flank" then
			-- Prefer side slots (2, 3, 6, 7) for flanking
			for i = 1, totalSlots do
				if i == 2 or i == 3 or i == 6 or i == 7 then
					table.insert(slotOrder, 1, i) -- Priority
				else
					table.insert(slotOrder, i)
				end
			end
		elseif preferSide == "back" then
			-- Prefer back slots (5, 6, 7) for rear attacks
			for i = 1, totalSlots do
				if i == 5 or i == 6 or i == 7 then
					table.insert(slotOrder, 1, i)
				else
					table.insert(slotOrder, i)
				end
			end
		else
			-- Normal order
			for i = 1, totalSlots do
				table.insert(slotOrder, i)
			end
		end
		
		-- Try each slot in order
		for _, slotIndex in ipairs(slotOrder) do
			local slotKey = generateSlotKey(targetId, ringIndex, slotIndex)
			
			if self:isSlotAvailable(slotKey, currentTime) then
				local slotPos = calculateSlotPosition(targetPos, ringIndex, slotIndex, totalSlots)
				return slotPos, slotKey, ringIndex, slotIndex
			end
		end
	end
	
	-- No slots available, return outer ring random position
	local randomSlot = math.random(1, CONFIG.SLOTS_PER_RING)
	local fallbackPos = calculateSlotPosition(targetPos, 3, randomSlot, CONFIG.SLOTS_PER_RING)
	local fallbackKey = generateSlotKey(targetId, 3, randomSlot)
	return fallbackPos, fallbackKey, 3, randomSlot
end

-- Reserve a slot for a zombie
function SurroundService:reserveSlot(zombieModel, slotKey, slotPos, ringIndex, slotIndex)
	local currentTime = tick()
	
	-- Release any existing slot
	self:releaseSlot(zombieModel)
	
	-- Reserve new slot
	self.slotReservations[slotKey] = {
		zombie = zombieModel,
		reservedTime = currentTime,
		ringIndex = ringIndex,
		slotIndex = slotIndex
	}
	
	self.zombieSlots[zombieModel] = {
		slotKey = slotKey,
		targetPos = slotPos,
		assignedTime = currentTime,
		ringIndex = ringIndex,
		slotIndex = slotIndex
	}
end

-- Release a zombie's slot reservation
function SurroundService:releaseSlot(zombieModel)
	local zombieSlot = self.zombieSlots[zombieModel]
	if zombieSlot then
		self.slotReservations[zombieSlot.slotKey] = nil
		self.zombieSlots[zombieModel] = nil
	end
end

-- Get zombie's current slot
function SurroundService:getZombieSlot(zombieModel)
	return self.zombieSlots[zombieModel]
end

-- Check if zombie should re-roll slot (timeout or unreachable)
function SurroundService:shouldRerollSlot(zombieModel, zombiePos)
	local zombieSlot = self.zombieSlots[zombieModel]
	if not zombieSlot then
		return true
	end
	
	local currentTime = tick()
	local timeSince = currentTime - zombieSlot.assignedTime
	
	-- Timeout check
	if timeSince > CONFIG.SLOT_TIMEOUT then
		return true
	end
	
	-- Distance check - if stuck far from slot for too long
	local distanceToSlot = (zombiePos - zombieSlot.targetPos).Magnitude
	if timeSince > 3.0 and distanceToSlot > 30 then
		return true
	end
	
	return false
end

-- Calculate separation steering to avoid clumping
function SurroundService:calculateSeparationSteering(zombieModel, zombiePos, nearbyZombies)
	local separation = Vector3.new(0, 0, 0)
	local count = 0
	
	for _, otherZombie in ipairs(nearbyZombies) do
		if otherZombie ~= zombieModel and otherZombie.Parent then
			local otherRoot = otherZombie:FindFirstChild("HumanoidRootPart")
			if otherRoot then
				local distance = (otherRoot.Position - zombiePos).Magnitude
				
				if distance < CONFIG.SEPARATION_RADIUS and distance > 0.1 then
					-- Push away from nearby zombie
					local direction = (zombiePos - otherRoot.Position).Unit
					local strength = (CONFIG.SEPARATION_RADIUS - distance) / CONFIG.SEPARATION_RADIUS
					separation = separation + (direction * strength)
					count = count + 1
				end
			end
		end
	end
	
	if count > 0 then
		separation = separation / count
		separation = separation * CONFIG.SEPARATION_STRENGTH
	end
	
	return separation
end

-- Get target position with separation applied
function SurroundService:getSteeringTarget(zombieModel, zombiePos, baseTargetPos, nearbyZombies)
	-- Get separation vector
	local separation = self:calculateSeparationSteering(zombieModel, zombiePos, nearbyZombies)
	
	-- Apply separation to target
	local steeringTarget = baseTargetPos + (separation * 10) -- Scale up separation influence
	
	return steeringTarget
end

-- Clean up expired reservations
function SurroundService:cleanup()
	local currentTime = tick()
	
	-- Collect slots to remove (safe iteration)
	local slotsToRemove = {}
	for slotKey, reservation in pairs(self.slotReservations) do
		if not reservation.zombie or not reservation.zombie.Parent then
			table.insert(slotsToRemove, slotKey)
		else
			local timeSince = currentTime - reservation.reservedTime
			if timeSince > CONFIG.SLOT_RESERVATION_TIME * 2 then
				table.insert(slotsToRemove, slotKey)
			end
		end
	end
	
	-- Remove collected slots
	for _, slotKey in ipairs(slotsToRemove) do
		self.slotReservations[slotKey] = nil
	end
	
	-- Collect zombie slots to remove (safe iteration)
	local zombiesToRemove = {}
	for zombie, _ in pairs(self.zombieSlots) do
		if not zombie or not zombie.Parent then
			table.insert(zombiesToRemove, zombie)
		end
	end
	
	-- Remove collected zombie slots
	for _, zombie in ipairs(zombiesToRemove) do
		self.zombieSlots[zombie] = nil
	end
end

-- Update service
function SurroundService:update(deltaTime)
	self:cleanup()
end

return SurroundService
