--[[
    Defines all zombie archetypes available to the wave spawner.
    Each entry references a model that must exist under ServerStorage.ZombieModels.
]]

local ZombieTypes = {
    Walker = {Model = "Walker", Speed = 10, Damage = 12, Health = 70, Reward = 5},
    Runner = {Model = "Runner", Speed = 17, Damage = 10, Health = 55, Reward = 6},
    Brute  = {Model = "Brute",  Speed = 8,  Damage = 24, Health = 180, Reward = 20},
    Spitter  = {Model = "Spitter",Speed = 13, Damage = 8,  Health = 90, Reward = 12},
    Boss   = {Model = "Boss",   Speed = 11, Damage = 32, Health = 600, Reward = 125},
}

return ZombieTypes
