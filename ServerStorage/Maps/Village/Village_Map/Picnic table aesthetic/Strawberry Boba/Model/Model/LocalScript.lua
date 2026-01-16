-- @ScriptType: LocalScript
-- Decompiled with the Synapse X Luau decompiler.

script.Parent:TweenPosition(UDim2.new(0.5, -200, 0.5, -75));
local l__barista__1 = script.Parent.Parent:WaitForChild("barista");
local v2 = nil;
local l__next__3 = next;
local v4, v5 = script.Parent.Parent:GetChildren();
while true do
	local v6, v7 = l__next__3(v4, v5);
	if not v6 then
		break;
	end;
	v5 = v6;
	if v7.ClassName == "Tool" then
		if v7:FindFirstChild("topbun") == nil then
			v2 = v7;
		else
			v2 = game.Lighting[v7.Name]:Clone();
		end;
	end;
end;
function onYes()
	Workspace.GiveMeThisOMG.AddPoint:FireServer(script.Parent.Parent.barista.Value);
	v2.Parent = game.Players.LocalPlayer.Backpack;
	script.Parent:TweenPosition(UDim2.new(0.5, -200, 0, -121));
	wait(1);
	script.Parent:Destroy();
end;
function onWrong()
	Workspace.GiveMeThisOMG.RevokePoint:FireServer(script.Parent.Parent.barista.Value);
	script.Parent:TweenPosition(UDim2.new(0.5, -200, 0, -121));
	wait(1);
	script.Parent:Destroy();
end;
function onNo()
	script.Parent:TweenPosition(UDim2.new(0.5, -200, 0, -121));
	wait(1);
	script.Parent:Destroy();
end;
script.Parent.y.MouseButton1Click:connect(onYes);
script.Parent.n.MouseButton1Click:connect(onNo);
script.Parent.w.MouseButton1Click:connect(onWrong);
print("Built by Anuxo");
