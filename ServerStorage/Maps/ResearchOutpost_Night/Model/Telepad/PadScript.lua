-- @ScriptType: Script
--This call will cause a "wait" until the data comes back

-- DP bug is caused by below while loop, since DebugString never reaches "Got teleball" for any of the broken telepads.

function waitForChild(instance, name)
	while not instance:FindFirstChild(name) do
		instance.ChildAdded:wait()
	end
end

waitForChild(script.Parent, "DebugString")
script.Parent.DebugString.Value = "Starting"

local danceBomb = Instance.new("Part")
danceBomb.Name = "Ball"
danceBomb.BrickColor = BrickColor.new("Institutional white")
danceBomb.formFactor = "Symmetric"
danceBomb.Size = Vector3.new(2, 2, 2)
danceBomb.Shape = "Ball"
danceBomb.TopSurface = "Smooth"
danceBomb.BottomSurface = "Smooth"
danceBomb.Reflectance = 0

local whiteFire = Instance.new("Fire")
whiteFire.Color = Color3.new(95/256, 95/256, 95/256)
whiteFire.Heat = 25
whiteFire.Size = 3
whiteFire.SecondaryColor = Color3.new(51/256, 51/256, 51/256)
whiteFire.Parent = danceBomb

--danceBomb.Parent = nil -- should keep DanceBomb model only in memory

local debris = game:GetService("Debris")

local pad = script.Parent
waitForChild(pad, "Base")
waitForChild(pad, "FakeBase")
waitForChild(pad, "AnimatePad")
waitForChild(pad, "Configuration")
waitForChild(pad, "KillDelayScript")
waitForChild(pad, "TeleportAnimate")
waitForChild(pad, "RestoreCamera")
waitForChild(pad.Configuration, "MyColor")
waitForChild(pad.Configuration, "DestinationColor")
--waitForChild(pad.Configuration, "CanBlockOff")
waitForChild(pad.Configuration, "Animated")

local base = pad.Base
local base2 = pad.FakeBase
local animatePad = pad.AnimatePad
local myColor = pad.Configuration.MyColor
local destinationColor = pad.Configuration.DestinationColor
--local canBlockOff = pad.Configuration.CanBlockOff
local isAnimated = pad.Configuration.Animated
local killDelayScript = pad.KillDelayScript
local teleportAnimate = pad.TeleportAnimate
local restoreCamera = pad.RestoreCamera

local cloakedPartList = {}

function lockModel(model, boolValue)
	local modelChildren = model:GetChildren()
	for m = 1, #modelChildren do
		if modelChildren[m].className == "Part" or modelChildren[m].className == "WedgePart" or modelChildren[m].className == "TrussPart" then
			modelChildren[m].Locked = boolValue
		end
	end
end

function dematerialize(pChar)
	local pCharChildren = pChar:GetChildren()
	for i = 1, #pCharChildren do
		if pCharChildren[i].Name == "face" then
			table.insert(cloakedPartList, pCharChildren[i])
			pCharChildren[i].Parent = game.Lighting
		end

		if pCharChildren[i].className == "Part" and pCharChildren[i].Transparency < 1 then
			table.insert(cloakedPartList, pCharChildren[i])
			pCharChildren[i].Transparency = 1
		end

		if pCharChildren[i].className == "Tool" or pCharChildren[i].className == "Hat" or pCharChildren[i].Name == "Head" then
			dematerialize(pCharChildren[i])
		end
	end
end

function rematerialize(pChar)
	for i = 1, #cloakedPartList do
		if cloakedPartList[i].Name == "face" then cloakedPartList[i].Parent = pChar.Head
		else cloakedPartList[i].Transparency = 0 end
	end
	cloakedPartList = {}
end


function findAllTeleports(matchColor)
	local teleportList = {}

	-- search through their baseplate and find all Telepads of matching color
	local allModels = pad.Parent:GetChildren()
	for j = 1, #allModels do
		if allModels[j].Name == "Telepad" and allModels[j].Configuration.MyColor.Value == matchColor and allModels[j] ~= pad then -- if it's a telepad then it will have a color, so we check it
			table.insert(teleportList, allModels[j])
		end
	end

	return teleportList
end


function teleporterBlocked(teleporter)
	-- check the region3 immediately above teleporter for any parts
	local blockingParts = game.Workspace:FindPartsInRegion3(Region3.new(teleporter.Base.Position-teleporter.Base.Size/2, teleporter.Base.Position+teleporter.Base.Size/2 + Vector3.new(0,6,0)), teleporter, 1)
	return blockingParts ~= nil and #blockingParts > 0
end


local debounce = false
function touchHandler(part)
	if debounce then return end
	if part.Parent == nil then return end
	if(part.Parent:FindFirstChild("Humanoid") == nil) then return end
	local telD = part.Parent:FindFirstChild("TeleportDelay")
	if telD then 
		if telD.Value == Vector3.new(-math.huge, -math.huge, -math.huge) then return -- yes; I use math.huge and -math.huge as separate boolean toggles...  it's more memory efficient, but it hurts me.  I should change this.  Please don't judge.
		elseif telD.Value == Vector3.new(math.huge,math.huge,math.huge) then telD.Value = Vector3.new(-math.huge, -math.huge, -math.huge) end -- can stop queuing hits from this character
	end
	while part.Parent:FindFirstChild("TeleportDelay") do part.Parent.ChildRemoved:wait() end -- must not have teleport delay to be teleported
	while debounce do wait() end -- in case someone else beat us there
	debounce = true
	-- If part is the arm or leg of a humanoid, then move everything to the torso.
	-- This is so we can't double up forces on a humanoid (scripts inside each leg, arm, etc)
	waitForChild(part.Parent, "Torso")	
	part = part.Parent.Torso

	-- If Y velocity is too big (it's bouncing) then do nothing
	if(math.abs(part.Velocity.y) > 10) then debounce = false return end

	print("touchHandler:", part.Name)

	if (part.Position - base.Position):Dot(part.Position - base.Position) > 25 then debounce = false return end -- if they've stepped off...  kill teleport

	-- find the destination teleports
	local teleports = findAllTeleports(destinationColor.Value)

	if teleports == nil or #teleports < 1 then debounce = false return end -- need to have other teleport pads to function

	-- Animate the pad
	animatePad.Disabled = true
	animatePad.Disabled = false

	print(#teleports)

	-- choose one at random
	toTeleport = teleports[math.random(1, #teleports)]

	print("picked: ", toTeleport.DebugString.Value)

	-- see if blocked:
	--if toTeleport.Configuration.CanBlockOff.Value and teleporterBlocked(toTeleport) then -- don't teleport if blocked

	-- in either case add in teleportation sickness
	teleportDelay = Instance.new("Vector3Value")
	teleportDelay.Name = "TeleportDelay"
	teleportDelay.Parent = part.Parent
	teleportDelay.Value = toTeleport.Base.Position -- to define region of delayed teleporter
	

	if isAnimated.Value then
		-- don't let teleporters get deleted mid-flight!!
		lockModel(toTeleport, true)
		lockModel(pad, true)

		-- add in teleportation sickness
		--teleportDelay = Instance.new("Vector3Value")
		--teleportDelay.Name = "TeleportDelay"
		--teleportDelay.Parent = part.Parent
		--teleportDelay.Value = toTeleport.Base.Position -- to define region of delayed teleporter


		--part.Anchored = true
		local anchorForce = Instance.new("BodyPosition")
		anchorForce.P = 100000
		anchorForce.maxForce = Vector3.new(anchorForce.P, anchorForce.P, anchorForce.P)
		anchorForce.position = part.Position
		anchorForce.Parent = part

		dematerialize(part.Parent)

		-- animate the teleportation
		local dbClone = danceBomb:Clone()
		dbClone.Archivable = false
		dbClone.CanCollide = false
		teleBall = dbClone
		teleBall.CanCollide = false
		--teleBall.Name = "TeleBall"

		local teleForce = Instance.new("BodyVelocity")
		teleForce.P = 100000 --10000
		teleForce.maxForce = Vector3.new(teleForce.P, teleForce.P, teleForce.P)
		teleForce.velocity = (toTeleport.Base.Position - base.Position)

		teleBall.Velocity = Vector3.new(0,0,0)
		teleBall.CFrame = CFrame.new((base.Position+Vector3.new(0,4,0)), base.Position + teleForce.velocity)
		--teleBall.CFrame = part.CFrame -- face the same way as the person, initially
		--local teleGyro = Instance.new("BodyGyro")
		--teleGyro.P = 100
		--teleGyro.maxTorque = Vector3.new(teleGyro.P, teleGyro.P, teleGyro.P)
		--teleGyro.cframe = CFrame.new(base.Position, base.Position + teleForce.velocity)
		--teleGyro.Parent = teleBall

		teleForce.Parent = teleBall
		--teleBall.Parent = game.Workspace
		
		dbClone.Parent = game.Workspace

		teleBallPointer = Instance.new("ObjectValue")
		teleBallPointer.Name = "TeleBallPointer"
		teleBallPointer.Value = teleBall

		-- now just need to shift camera on it and then off it
		newTeleAnim = teleportAnimate:Clone()
		teleBallPointer.Parent = newTeleAnim
		newTeleAnim.Parent = part.Parent
		newTeleAnim.Disabled = false

		--while (part.Parent:FindFirstChild("TeleportAnimate")) do part.Parent.ChildRemoved:wait() end
		while (toTeleport.Base.Position - teleBall.Position):Dot(teleForce.velocity) > 0 do teleForce.velocity = (toTeleport.Base.Position - teleBall.Position).unit*(teleForce.velocity.magnitude) wait(.125) end --teleForce.velocity = (toTeleport.Base.Position - base.Position)/2 end
		newTeleAnim:remove()

		--game.Workspace.CurrentCamera.CameraType = "Attach"
		--game.Workspace.CurrentCamera.CameraSubject = teleBall
		--wait(1.5)
		--game.Workspace.CurrentCamera.CameraSubject = part.Parent.Humanoid
		--game.Workspace.CurrentCamera.CameraType = "Custom"

		-- actually teleport them
		--part.CFrame = part.CFrame + toTeleport.Base.Position - base.Position
		
		part.CFrame = part.CFrame - part.CFrame.p + toTeleport.Base.Position + Vector3.new(0, 2, 0)
		anchorForce.position = part.CFrame.p
		--teleBall.Parent = nil
		dbClone.Parent = nil
		
		newRestoreCamera = restoreCamera:Clone()
		newRestoreCamera.Parent = part.Parent
		newRestoreCamera.Disabled = false

		-- after animation, teleporters should be made deletable
		lockModel(toTeleport, false)
		lockModel(pad, false)

		rematerialize(part.Parent)

		--part.Parent.Humanoid.WalkSpeed = 16
		--part.Anchored = false
		anchorForce:remove()
		--part.Velocity = Vector3.new(0,0,0)
	else
		-- just regular teleport

		-- still add in teleportation sickness
		--teleportDelay = Instance.new("Vector3Value")
		--teleportDelay.Name = "TeleportDelay"
		--teleportDelay.Parent = part.Parent
		--teleportDelay.Value = toTeleport.Base.Position -- to define region of delayed teleporter

		--part.CFrame = part.CFrame + toTeleport.Base.Position - base.Position
		part.CFrame = part.CFrame - part.Position + toTeleport.Base.Position + Vector3.new(0, 2, 0)

		--wait(1) -- give the system a little time to actually teleport them [1 sec. before next teleport]
	end

	-- make teleportation sickness only temporary
	debris:AddItem(teleportDelay, 5) -- 5 second delay on teleporting (unless they run off teleporter first: TODO--ADD THAT SCRIPT IMMEDIATELY BELOW HERE!)
	killTeleDelayScript = killDelayScript:Clone()
	killTeleDelayScript.Parent = teleportDelay
	killTeleDelayScript.Disabled = false

	wait(1) -- give the system a little time to actually teleport them [1 sec. before next teleport]

	debounce = false
end

print("PadScript: Adding event.")
base.Touched:connect(touchHandler)
--base2.Touched:connect(touchHandler)

script.Parent.DebugString.Value = "Got to end of script!"
