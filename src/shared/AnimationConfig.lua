--[[
    AnimationConfig.lua
    All animation IDs for Fighting System
    
    Format: rbxassetid://ID
    Jika animasi kosong/belum ada, set nil dan akan di-skip tanpa error
]]

local AnimationConfig = {}

-- ============================================
-- BLOCK ANIMATIONS
-- ============================================
AnimationConfig.Block = {
    -- Animasi saat blocking (loop selama hold block)
    BlockHold = "rbxassetid://121918883757512",
    
    -- Animasi saat berhasil block hit (optional, single play)
    BlockSuccess = nil,
}

-- ============================================
-- ATTACK ANIMATIONS (COMBO)
-- ============================================
AnimationConfig.Attack = {
    -- Combo attacks (urutan)
    Combo = {
        [1] = "rbxassetid://81442291322583",
        [2] = "rbxassetid://87048626485725",
    },
    
    -- Animasi saat terkena hit (sesuai dengan attack combo)
    -- Ini adalah "paired animation" yang play di korban
    Hit = {
        [1] = "rbxassetid://133411118324472",
        [2] = "rbxassetid://133411118324472",
        [3] = "rbxassetid://133411118324472",
    },
}

-- ============================================
-- HEAVY ATTACK ANIMATIONS
-- ============================================
AnimationConfig.HeavyAttack = {
    -- Animasi heavy attack
    Attack = "rbxassetid://121358890086382",
    
    -- Animasi saat terkena heavy attack
    Hit = "rbxassetid://133411118324472",
}

-- ============================================
-- DODGE ANIMATIONS
-- ============================================
AnimationConfig.Dodge = {
    -- Dodge ke berbagai arah (set nil jika belum ada)
    Forward = nil,
    Backward = nil,
    Left = nil,
    Right = nil,
    
    -- Atau gunakan satu animasi untuk semua arah
    Universal = nil,
}

-- ============================================
-- IDLE & STANCE ANIMATIONS
-- ============================================
AnimationConfig.Idle = {
    -- Idle stance saat dalam fight mode
    FightIdle = nil,
    
    -- Normal idle (diluar fight)
    NormalIdle = nil,
}

-- ============================================
-- VICTORY & DEFEAT ANIMATIONS
-- ============================================
AnimationConfig.Result = {
    -- Animasi saat menang ronde/match
    Victory = nil,
    
    -- Animasi saat kalah ronde/match
    Defeat = nil,
}

-- ============================================
-- STUN/KNOCKBACK ANIMATIONS
-- ============================================
AnimationConfig.Status = {
    -- Animasi saat stamina habis (stunned)
    Stunned = nil,
    
    -- Animasi saat terkena knockback
    Knockback = nil,
}

-- ============================================
-- HELPER FUNCTION
-- ============================================

-- Safe load animation - returns nil if ID is nil or empty
function AnimationConfig.SafeGetAnimationId(category, name, index)
    local categoryData = AnimationConfig[category]
    if not categoryData then return nil end
    
    if index then
        local subData = categoryData[name]
        if not subData then return nil end
        return subData[index]
    else
        return categoryData[name]
    end
end

-- Create animation instance
function AnimationConfig.CreateAnimation(animId)
    if not animId or animId == "" then return nil end
    
    local animation = Instance.new("Animation")
    animation.AnimationId = animId
    return animation
end

-- Load animation to animator
function AnimationConfig.LoadAnimation(animator, animId, looped, priority)
    if not animator or not animId or animId == "" then return nil end
    
    local animation = Instance.new("Animation")
    animation.AnimationId = animId
    
    local track = animator:LoadAnimation(animation)
    track.Looped = looped or false
    track.Priority = priority or Enum.AnimationPriority.Action
    
    return track
end

return AnimationConfig
