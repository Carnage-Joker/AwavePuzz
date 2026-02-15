-- ammo_consumption_ordering_test.lua
-- Verifies BUG-012: server validates shot BEFORE consuming ammo
-- Run in Roblox Studio Server console (requires at least one connected player)

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("=== AMMO CONSUMPTION ORDERING TEST (BUG-012) ===")

local testPlayers = Players:GetPlayers()
if #testPlayers < 1 then
    warn("❌ Test requires at least one player in the server")
    return
end
local player = testPlayers[1]

-- Ensure player has a character and HRP
if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
    warn("❌ Test player must have an active character. Spawn a character and re-run the test.")
    return
end
local hrp = player.Character:FindFirstChild("HumanoidRootPart")

-- Load modules
local WeaponServiceModule = require(ServerScriptService:WaitForChild("WeaponService"))
local WeaponConfig = require(ReplicatedStorage:WaitForChild("Shared", 5):WaitForChild("WeaponConfig", 5))

-- Minimal mock PlayerManager for WeaponService instance
local MockPlayerManager = {}
function MockPlayerManager:getEquippedWeapon(p)
    return WeaponConfig.DefaultWeapon
end
function MockPlayerManager:ownsWeapon(p, id)
    return true
end
function MockPlayerManager:addWeapon() end
function MockPlayerManager:equipWeapon() end

-- Minimal mocks
local MockAllianceService = {}

-- Mock FPSWeaponService to observe consumeAmmo calls and to provide ammo state
local MockFPS = {}
MockFPS.__index = MockFPS
function MockFPS.new()
    local self = setmetatable({}, MockFPS)
    self.playerAmmo = {} -- userId -> { weaponId -> { current, reserve, max } }
    return self
end
function MockFPS:isReloading(p) return false end
function MockFPS:validateShot(p, weaponId)
    local u = p.UserId
    local ammo = self.playerAmmo[u] and self.playerAmmo[u][weaponId]
    return ammo and ammo.current > 0
end
function MockFPS:consumeAmmo(p, weaponId, amount)
    amount = amount or 1
    local u = p.UserId
    local ammo = self.playerAmmo[u] and self.playerAmmo[u][weaponId]
    if not ammo or ammo.current < amount then return false end
    ammo.current = ammo.current - amount
    return true
end
function MockFPS:onWeaponEquipped(p, weaponId)
    local u = p.UserId
    self.playerAmmo[u] = self.playerAmmo[u] or {}
    self.playerAmmo[u][weaponId] = { current = 5, reserve = 10, max = 5 }
end
function MockFPS:getAmmo(p, weaponId)
    local u = p.UserId
    return self.playerAmmo[u] and self.playerAmmo[u][weaponId] or nil
end

-- Create WeaponService instance with mocks
local ws = WeaponServiceModule.new(MockPlayerManager, MockAllianceService, nil)
local mockFPS = MockFPS.new()
ws:setFPSWeaponService(mockFPS)

-- Prepare test state
local weaponId = WeaponConfig.DefaultWeapon
mockFPS:onWeaponEquipped(player, weaponId)

local function ammoCount()
    local a = mockFPS:getAmmo(player, weaponId)
    return a and a.current or nil
end

local initialAmmo = ammoCount()
print("Initial ammo:", initialAmmo)

-- Test A: Invalid origin (too far) should NOT consume ammo
local payloadA = {
    origin = hrp.Position + Vector3.new(1000, 0, 0), -- way outside MAX_WEAPON_FIRE_DISTANCE
    direction = Vector3.new(1, 0, 0),
    timestamp = tick()
}
ws:handleWeaponFire(player, payloadA)
if ammoCount() == initialAmmo then
    print("✅ Test A PASSED: Invalid origin did not consume ammo")
else
    warn("❌ Test A FAILED: Ammo changed for invalid origin")
end

-- Test B: Invalid direction magnitude should NOT consume ammo
local payloadB = {
    origin = hrp.Position + hrp.CFrame.LookVector * 1,
    direction = Vector3.new(0,0,0), -- invalid magnitude
    timestamp = tick()
}
ws:handleWeaponFire(player, payloadB)
if ammoCount() == initialAmmo then
    print("✅ Test B PASSED: Invalid direction did not consume ammo")
else
    warn("❌ Test B FAILED: Ammo changed for invalid direction")
end

-- Test C: Origin behind player (localOffset.Z < -3) should NOT consume ammo
-- Use forward-facing direction to pass dot product check, but origin behind player
local behindOrigin = hrp.CFrame * CFrame.new(0, 0, -4)
local payloadC = {
    origin = behindOrigin.p,
    direction = hrp.CFrame.LookVector, -- forward-facing direction (passes dot product validation)
    timestamp = tick()
}
ws:handleWeaponFire(player, payloadC)
if ammoCount() == initialAmmo then
    print("✅ Test C PASSED: Behind-origin shot did not consume ammo")
else
    warn("❌ Test C FAILED: Ammo changed for behind-origin shot")
end

-- Test D: Valid shot should consume ammo (even on miss)
local payloadD = {
    origin = hrp.Position + Vector3.new(0, 1.5, 0),
    direction = hrp.CFrame.LookVector,
    timestamp = tick()
}
ws:handleWeaponFire(player, payloadD)
if ammoCount() == initialAmmo - 1 then
    print("✅ Test D PASSED: Valid shot consumed 1 ammo")
else
    warn(string.format("❌ Test D FAILED: Expected ammo %d but got %d", initialAmmo - 1, ammoCount() or -1))
end

-- Establish baseline after a known-valid shot
local ammoAfterValid = ammoCount()

-- Test E: NaN direction values should NOT consume ammo
local nanValue = 0/0
local payloadE = {
    origin = hrp.Position + Vector3.new(0, 1.5, 0),
    direction = Vector3.new(nanValue, 0, 1),
    timestamp = tick()
}
ws:handleWeaponFire(player, payloadE)
if ammoCount() == ammoAfterValid then
    print("✅ Test E PASSED: NaN direction did not consume ammo")
else
    warn("❌ Test E FAILED: Ammo changed for NaN direction")
end

-- Test F: Excessive vertical offset (Y > 10) should NOT consume ammo
local highOrigin = hrp.Position + Vector3.new(0, 11, 0)
local payloadF = {
    origin = highOrigin,
    direction = (highOrigin - hrp.Position).Unit,
    timestamp = tick()
}
ws:handleWeaponFire(player, payloadF)
if ammoCount() == ammoAfterValid then
    print("✅ Test F PASSED: High-origin shot did not consume ammo")
else
    warn("❌ Test F FAILED: Ammo changed for high-origin shot")
end

-- Test G: Dot product validation failure should NOT consume ammo
local offOrigin = hrp.Position + hrp.CFrame.LookVector * 5
local offDirection = -(offOrigin - hrp.Position).Unit -- deliberately opposite
local payloadG = {
    origin = offOrigin,
    direction = offDirection,
    timestamp = tick()
}
ws:handleWeaponFire(player, payloadG)
if ammoCount() == ammoAfterValid then
    print("✅ Test G PASSED: Misaligned direction did not consume ammo")
else
    warn("❌ Test G FAILED: Ammo changed for misaligned direction")
end

-- Test H: Line-of-sight validation failure should NOT consume ammo
local blocker = Instance.new("Part")
blocker.Size = Vector3.new(4, 4, 1)
blocker.Anchored = true
blocker.CanCollide = true
blocker.CFrame = CFrame.new(hrp.Position + hrp.CFrame.LookVector * 5)
blocker.Name = "AmmoTest_LOS_Blocker"
blocker.Parent = workspace

local losOrigin = hrp.Position + hrp.CFrame.LookVector * 10
local payloadH = {
    origin = losOrigin,
    direction = (losOrigin - hrp.Position).Unit,
    timestamp = tick()
}
ws:handleWeaponFire(player, payloadH)
if ammoCount() == ammoAfterValid then
    print("✅ Test H PASSED: Blocked line-of-sight shot did not consume ammo")
else
    warn("❌ Test H FAILED: Ammo changed for blocked line-of-sight shot")
end

blocker:Destroy()
print("=== AMMO CONSUMPTION ORDERING TEST COMPLETE ===")