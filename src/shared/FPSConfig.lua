-- FPSConfig.lua
-- Central configuration for first-person camera and controls
-- Adjust these values to tune the FPS feel without touching scripts.

local FPSConfig = {
        DefaultFOV = 90, -- Default camera field of view
        MinFOV = 70,
        MaxFOV = 110,

        MouseSensitivity = 0.15, -- Base multiplier for mouse delta
        MouseSmoothing = 0.15, -- 0 disables smoothing, 0.05-0.2 recommended
        PitchClamp = 80, -- Max up/down angle in degrees

        CameraOffset = Vector3.new(0, 0, 0), -- Applied after head position
        HeadOffset = Vector3.new(0, 0.4, 0), -- Raises the camera slightly above the head attachment

        -- Gameplay toggles
        HideCharacterInFirstPerson = true, -- Makes character locally invisible to avoid clipping
}

return FPSConfig
