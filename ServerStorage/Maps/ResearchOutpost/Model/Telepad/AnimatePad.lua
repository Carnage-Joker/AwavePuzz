-- @ScriptType: Script
function waitForChild(instance, name)
	while not instance:FindFirstChild(name) do
		instance.ChildAdded:wait()
	end
end

-- Animate stuff
waitForChild(script.Parent, "Base")
local base = script.Parent.Base
waitForChild(base, "Fire")
waitForChild(base, "Smoke")

local onColor = BrickColor.new(1,1,1)
local offColor = BrickColor.new(.2,.2,.2)
base.BrickColor = onColor

base.Fire.Enabled = true
base.Smoke.Enabled = true
wait(0.5)
base.Fire.Enabled = false
wait(0.5)
base.Smoke.Enabled = false
base.BrickColor = offColor