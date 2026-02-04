-- @ScriptType: Script
-- useless comment here

function waitForChild(parent, child)
	while not parent:FindFirstChild(child) do parent.ChildAdded:wait() end
end

local model = script.Parent
local doorOpenTime = 3

local weld1RelativePosition = CFrame.new() + Vector3.new(0, -1.1, .55)
local weld2RelativePosition = CFrame.new() + Vector3.new(0, -1.1, -.55)


waitForChild(model, "PlayerIdTag")
waitForChild(model, "Configuration")
waitForChild(model, "Door1")
waitForChild(model, "Door2")
waitForChild(model, "TouchDoor1")
waitForChild(model, "TouchDoor2")
waitForChild(model, "OuterEdge")

local doorOwnerId = model.PlayerIdTag.Value  -- Update the owner ID
local config = model.Configuration
local doorPart1 = model.Door1
local doorPart2 = model.Door2
local doorTouch1 = model.TouchDoor1
local doorTouch2 = model.TouchDoor2
local outerEdge = model.OuterEdge

waitForChild(config, "FriendMode")
local mode = config.FriendMode


function testPermission(part)
	doorOwnerId = model.PlayerIdTag.Value -- Update the owner ID
	if part == nil then return false end   -- In case part was deleted
	pChar = part.Parent
	if pChar == nil then return false end
	pPlay = game.Players:GetPlayerFromCharacter(pChar)  -- In case player left game
	if pPlay == nil then return false end

	-- Test permissions
	if(mode.Value == "Everyone") then
		return true
	elseif (mode.Value == "Only Me") then
		if pPlay.userId == doorOwnerId then
			return true
		else
			-- no access
		end
	elseif(mode.Value == "Friends") then
		if (pPlay:IsFriendsWith(doorOwnerId)) then 
			return true 
		else
			-- no access
		end
	elseif(mode.Value == "Best Friends") then
		if (pPlay:IsBestFriendsWith(doorOwnerId)) then
			return true
		else
			-- no access
		end
	elseif(mode.Value == "Group") then
		if (pPlay:IsInGroup(doorOwnerId)) then
			return true
		else
			-- no access
		end
	end
	return false
end

local isOpen
function doorOpen()
	isOpen = true
	--if doorPart1:FindFirstChild("DoorWeld") ~= nil then doorPart1.DoorWeld:Remove() end
	--if doorPart2:FindFirstChild("DoorWeld") ~= nil then doorPart2.DoorWeld:Remove() end
	weld1 = doorPart1:FindFirstChild("DoorWeld")
	weld2 = doorPart2:FindFirstChild("DoorWeld")
	if not weld1 or not weld2 then return end

	-- horrible animation code
	for i = 1, 10 do
		weld1.C1 = weld1RelativePosition + Vector3.new(0, 0, i * .2)
		weld2.C1 = weld2RelativePosition + Vector3.new(0, 0, i * -.2)

		wait(.1)
	end
end

function doorClose()
	-- horrible animation code
	weld1 = doorPart1:FindFirstChild("DoorWeld")
	weld2 = doorPart2:FindFirstChild("DoorWeld")

	if not weld1 or not weld2 then return end

	for i = 9, 0, -1 do
		weld1.C1 = weld1RelativePosition + Vector3.new(0, 0, i * .2)
		weld2.C1 = weld2RelativePosition + Vector3.new(0, 0, i * -.2)

		wait(.1)
	end

	isOpen = false
	--doorPart2.CFrame = doorGyro.cframe -- snap shut through the player, so that it doesn't send them flying
end

local debounce = false
local stayOpenTime = 0
function touchEvent(part)
	if not part or not part.Parent or part.Parent == model then return end

	--if (part ~= door1 and part ~= door2) then
		if (testPermission(part)) then
			if not debounce and not isOpen then
				debounce = true
				doorOpen()
				wait(doorOpenTime)
				while stayOpenTime > 0 do
					local tempVariable = stayOpenTime -- allows us to use this variable in the wait while also setting it to zero
					stayOpenTime = 0
					wait(tempVariable)
				end
				doorClose()
				debounce = false
			else
				stayOpenTime = doorOpenTime
			end
		end
	--end
end


function changedEvent(prop)
	-- Only interested in CFrame (position + rotation) changes
	if(prop ~= "CFrame") then return end

	--targetPos = underDoors.Position
	--door1bp.position = side2.Position
	--door2bp.position = side1.Position
	--a = underDoors.CFrame.lookVector
	--lookVector = Vector3.new( math.abs(a.x), math.abs(a.y), math.abs(a.z) )
	--setDoorForces()
end

changedEvent("CFrame") -- Fire once to initialize

-- shut the front door
-- create door welds if we don't have them yet

weld1 = doorPart1:FindFirstChild("DoorWeld")
weld2 = doorPart2:FindFirstChild("DoorWeld")
if not weld1 or not weld2 then
	if weld1 then weld1:Remove() end
	if weld2 then weld2:Remove() end

	newDoorWeld = Instance.new("ManualWeld")
	newDoorWeld.Part0 = doorPart1
	newDoorWeld.Part1 = outerEdge
	newDoorWeld.C1 = weld1RelativePosition
	newDoorWeld.Name = "DoorWeld"
	newDoorWeld.Parent = doorPart1

	newDoorWeld = Instance.new("ManualWeld")
	newDoorWeld.Part0 = doorPart2
	newDoorWeld.Part1 = outerEdge
	newDoorWeld.C1 = weld2RelativePosition
	newDoorWeld.Name = "DoorWeld"
	newDoorWeld.Parent = doorPart2
else
	weld1.C1 = weld1RelativePosition
	weld2.C1 = weld2RelativePosition
end
isOpen = false

doorTouch1.Touched:connect(touchEvent)
doorTouch2.Touched:connect(touchEvent)

print("REACHED END")
