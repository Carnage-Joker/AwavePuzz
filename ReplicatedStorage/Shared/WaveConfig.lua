--[[
    Lists all wave definitions in order. The GameManager reads this table
    sequentially and loops the final wave if players manage to survive beyond it.
    Each wave defines a total zombie count, the time limit in seconds, and a
    composition table that indicates the weighted distribution of zombie types.
]]

local waves = {
    {
        number = 1,
        timeLimit = 75,
        zombieCount = 15,
        composition = { Walker = 0.8, Runner = 0.2 },
    },
    {
        number = 2,
        timeLimit = 85,
        zombieCount = 22,
        composition = { Walker = 0.65, Runner = 0.25, Spitter = 0.1 },
    },
    {
        number = 3,
        timeLimit = 95,
        zombieCount = 28,
        composition = { Walker = 0.5, Runner = 0.25, Spitter = 0.15, Brute = 0.1 },
    },
    {
        number = 4,
        timeLimit = 105,
        zombieCount = 34,
        composition = { Walker = 0.4, Runner = 0.25, Spitter = 0.2, Brute = 0.15 },
    },
    {
        number = 5,
        timeLimit = 120,
        zombieCount = 40,
        composition = { Walker = 0.35, Runner = 0.25, Spitter = 0.2, Brute = 0.15, Boss = 0.05 },
    },
}

return waves
