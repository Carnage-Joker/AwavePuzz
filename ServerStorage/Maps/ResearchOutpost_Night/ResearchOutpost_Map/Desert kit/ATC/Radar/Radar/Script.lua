-- @ScriptType: Script
local model = script.Parent
local rad = math.rad
local rotateAmount = 1 --In 

while true do
	wait()
	local NewCFrame = model.PrimaryPart.CFrame * CFrame.Angles(rad(rotateAmount) , 0, 0)
	model:SetPrimaryPartCFrame(NewCFrame)
end
