-- @ScriptType: Script
-- script to kill the teleport delay if they step off the teleporter (checked by taking the point distance from torso center to teleport pad center)

local teleDelay = script.Parent
if teleDelay ~= nil then
	local telePos = teleDelay.Value
	teleDelay.Value = Vector3.new(math.huge, math.huge, math.huge) -- signals that we've retrieved this value (acts as a lock: super-gross hack; a little part of me died when I coded this D': )
	local vChar = teleDelay.Parent
	if vChar ~= nil and telePos ~= nil then
		local vTorso = vChar:FindFirstChild("Torso")
		
		if vTorso ~= nil then
			while (vTorso.Position - telePos):Dot(vTorso.Position - telePos) < 25 do -- currently hard-coded to the right distance
				wait(.1)
			end
			teleDelay:remove()
		end
	end
end
