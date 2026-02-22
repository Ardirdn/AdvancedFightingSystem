--[[
    SoundConfig.lua
    Configuration for all sound effects in the Fighting System
]]

local SoundConfig = {}

SoundConfig.Sounds = {
    -- Suara Punch + Hit untuk attacker (saat attack kena)
    PunchHit = {
        "rbxassetid://137163256711828",
        "rbxassetid://89589573386788",
        "rbxassetid://99762057380475",
    },
    
    -- Suara saat victim terkena hit (untuk korban)
    VictimHit = {
        "rbxassetid://97019432447649",
        "rbxassetid://98330897555423",
        "rbxassetid://113828106042161",
        "rbxassetid://128800126046142",
    },

    -- Suara whoosh ayunan punch (selalu play saat mencet attack)
    Whoosh = {
        "rbxassetid://127183292018512",
        "rbxassetid://124728589942760",
    },
    
    -- Win/Lose sounds
    Win = "rbxassetid://96210781050936",
    Lose = "rbxassetid://92158718098402",
    
    -- Volume settings (Diperbesar sesuai request)
    PunchVolume = 2.0,
    HitVolume = 2.0,
    WhooshVolume = 1.5,
    WinLoseVolume = 1.0,
}

return SoundConfig
