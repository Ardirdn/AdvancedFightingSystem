--[[
    PoseConfig.lua
    Configuration for Pose/Dance System
    
    Add as many poses/dances as you want!
    Format: { Name = "Display Name", AnimationId = "rbxassetid://ID" }
]]

local PoseConfig = {}

-- ============================================
-- POSE/DANCE LIST
-- ============================================
-- AnimationId format: "rbxassetid://ANIMATIONID"
-- Note: Numbers only, the rbxassetid:// prefix is added automatically

PoseConfig.Poses = {
    {
        Name = "V Pose",
        AnimationId = "135109197572082",
        Icon = "✌️", -- Optional emoji icon
    },
    {
        Name = "Sturdy",
        AnimationId = "72764399876931",
        Icon = "💪",
    },
    {
        Name = "Bow Animation",
        AnimationId = "128816570496896",
        Icon = "🙇",
    },
    -- Add more poses below:
    -- {
    --     Name = "Dance Name",
    --     AnimationId = "ANIMATION_ID_HERE",
    --     Icon = "💃",
    -- },
}

-- ============================================
-- UI CONFIGURATION
-- ============================================
PoseConfig.UI = {
    -- Toggle key
    ToggleKey = Enum.KeyCode.P, -- Press P to toggle pose menu
    
    -- ============================================
    -- MAIN FRAME SIZING (Easy to adjust!)
    -- ============================================
    FrameWidthScale = 0.12,     -- Width as % of screen (0.12 = 12%)
    FrameAspectRatio = 0.5,     -- Width / Height ratio (lower = taller, higher = shorter)
                                 -- Example: 0.5 = frame is 2x taller than wide
                                 --          1.0 = frame is square
                                 --          0.3 = frame is 3.3x taller than wide
    
    -- Toggle button sizing
    ToggleButtonWidthScale = 0.06,  -- Width as % of screen
    ToggleButtonAspectRatio = 2.5,  -- Width / Height ratio
    
    -- Item sizing (scale-based)
    ItemHeightScale = 0.18,     -- Height as % of frame height
    Padding = 8,                -- Padding in pixels
    
    -- Colors (Dark mode)
    BackgroundColor = Color3.fromRGB(25, 25, 30),
    BackgroundTransparency = 0.15,
    ItemBackgroundColor = Color3.fromRGB(35, 35, 45),
    ItemHoverColor = Color3.fromRGB(50, 50, 65),
    ItemSelectedColor = Color3.fromRGB(80, 100, 180),
    TextColor = Color3.fromRGB(230, 230, 235),
    TitleColor = Color3.fromRGB(180, 180, 190),
    
    -- Stroke
    StrokeColor = Color3.fromRGB(60, 60, 70),
    StrokeThickness = 1.5,
    SelectedStrokeColor = Color3.fromRGB(120, 140, 255),
    SelectedStrokeThickness = 2,
    
    -- Animation
    FadeInDuration = 0.2,
    FadeOutDuration = 0.15,
}

return PoseConfig
