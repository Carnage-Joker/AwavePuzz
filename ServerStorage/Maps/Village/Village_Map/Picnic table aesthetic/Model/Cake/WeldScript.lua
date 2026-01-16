-- @ScriptType: Script
function weld(base, part)
	local p = CFrame.new(base.Position)
	local C0 = base.CFrame:inverse() * p
	local C1 = part.CFrame:inverse() * p

	local weld = Instance.new("Weld")
	weld.Part0 = base
	weld.Part1 = part
	weld.C0 = C0
	weld.C1 = C1
	weld.Parent = part
end

for i,child in pairs(script.Parent:getChildren()) do
	if child.className == "Part" and child.Name ~= "Base" then
		weld(script.Parent.Base, child)
	end
end
