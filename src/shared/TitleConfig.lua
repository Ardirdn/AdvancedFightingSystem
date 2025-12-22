--[[
    TitleConfig.lua
    Configuration for Title System
    
    Title Tiers (based on RoundsWin):
    - 10 tiers from Novice to Legendary Champion
    
    Special Titles:
    - Admin, Owner, NVM (given via admin commands)
]]

local TitleConfig = {}

-- ============================================
-- ADMIN / OWNER USER IDS
-- ============================================
-- Add your Roblox User IDs here
TitleConfig.OwnerIds = {
    -- Example: 123456789,
    -- TAMBAHKAN USER ID OWNER DI SINI
}

TitleConfig.AdminIds = {
    8714136305,
    -- TAMBAHKAN USER ID ADMIN DI SINI
}

-- Check if user is Owner
function TitleConfig.IsOwner(userId)
    return table.find(TitleConfig.OwnerIds, userId) ~= nil
end

-- Check if user is Admin (includes owners)
function TitleConfig.IsAdmin(userId)
    return TitleConfig.IsOwner(userId) or table.find(TitleConfig.AdminIds, userId) ~= nil
end

-- ============================================
-- TITLE TIERS (Based on Rounds Won)
-- ============================================
-- Semakin tinggi tier, semakin keren nama dan warnanya
TitleConfig.TierTitles = {
    -- Tier 1: Pemula
    {
        Name = "Rookie",
        DisplayName = "Rookie Fighter",
        MinRoundsWin = 0,
        Icon = "🥊",
        Color = Color3.fromRGB(150, 150, 150),      -- Gray
        TextStrokeColor = Color3.fromRGB(50, 50, 50),
    },
    
    -- Tier 2: Baru mulai
    {
        Name = "Brawler",
        DisplayName = "Street Brawler",
        MinRoundsWin = 10,
        Icon = "👊",
        Color = Color3.fromRGB(180, 180, 180),      -- Light Gray
        TextStrokeColor = Color3.fromRGB(60, 60, 60),
    },
    
    -- Tier 3: Terlatih
    {
        Name = "Fighter",
        DisplayName = "Trained Fighter",
        MinRoundsWin = 25,
        Icon = "⚔️",
        Color = Color3.fromRGB(100, 200, 100),      -- Green
        TextStrokeColor = Color3.fromRGB(30, 80, 30),
    },
    
    -- Tier 4: Warrior
    {
        Name = "Warrior",
        DisplayName = "Arena Warrior",
        MinRoundsWin = 50,
        Icon = "🛡️",
        Color = Color3.fromRGB(50, 150, 255),       -- Blue
        TextStrokeColor = Color3.fromRGB(20, 60, 120),
    },
    
    -- Tier 5: Gladiator
    {
        Name = "Gladiator",
        DisplayName = "Gladiator",
        MinRoundsWin = 100,
        Icon = "⚡",
        Color = Color3.fromRGB(200, 150, 50),       -- Bronze/Gold
        TextStrokeColor = Color3.fromRGB(100, 70, 20),
    },
    
    -- Tier 6: Elite
    {
        Name = "Elite",
        DisplayName = "Elite Champion",
        MinRoundsWin = 200,
        Icon = "🔥",
        Color = Color3.fromRGB(255, 100, 50),       -- Orange/Red
        TextStrokeColor = Color3.fromRGB(120, 40, 20),
    },
    
    -- Tier 7: Master
    {
        Name = "Master",
        DisplayName = "Combat Master",
        MinRoundsWin = 350,
        Icon = "💪",
        Color = Color3.fromRGB(255, 50, 100),       -- Pink/Red
        TextStrokeColor = Color3.fromRGB(120, 20, 50),
    },
    
    -- Tier 8: Grandmaster
    {
        Name = "Grandmaster",
        DisplayName = "Grandmaster",
        MinRoundsWin = 500,
        Icon = "👑",
        Color = Color3.fromRGB(255, 215, 0),        -- Gold
        TextStrokeColor = Color3.fromRGB(150, 100, 0),
    },
    
    -- Tier 9: Warlord
    {
        Name = "Warlord",
        DisplayName = "Legendary Warlord",
        MinRoundsWin = 750,
        Icon = "🌟",
        Color = Color3.fromRGB(200, 100, 255),      -- Purple
        TextStrokeColor = Color3.fromRGB(80, 40, 120),
    },
    
    -- Tier 10: God (Max Tier)
    {
        Name = "God",
        DisplayName = "Fighting God",
        MinRoundsWin = 1000,
        Icon = "⭐",
        Color = Color3.fromRGB(255, 255, 100),      -- Bright Yellow
        TextStrokeColor = Color3.fromRGB(150, 150, 0),
        -- Special effect: rainbow glow (optional)
        HasGlow = true,
        GlowColor = Color3.fromRGB(255, 255, 200),
    },
}

-- ============================================
-- SPECIAL TITLES (Given by Admin/Owner)
-- ============================================
TitleConfig.SpecialTitles = {
    -- Owner Title
    Owner = {
        DisplayName = "Owner",
        Icon = "👑",
        Color = Color3.fromRGB(255, 215, 0),        -- Gold
        TextStrokeColor = Color3.fromRGB(150, 100, 0),
        Priority = 100,                              -- Higher = displays first
        HasGlow = true,
        GlowColor = Color3.fromRGB(255, 200, 100),
    },
    
    -- Admin Title
    Admin = {
        DisplayName = "Admin",
        Icon = "⚙️",
        Color = Color3.fromRGB(255, 100, 100),      -- Red
        TextStrokeColor = Color3.fromRGB(120, 40, 40),
        Priority = 90,
        HasGlow = true,
        GlowColor = Color3.fromRGB(255, 150, 150),
    },
    
    -- NVM Title (Special VIP or custom title)
    NVM = {
        DisplayName = "💎 NVM",
        Icon = "💎",
        Color = Color3.fromRGB(100, 200, 255),      -- Diamond Blue
        TextStrokeColor = Color3.fromRGB(40, 80, 120),
        Priority = 80,
        HasGlow = true,
        GlowColor = Color3.fromRGB(150, 220, 255),
    },
    
    -- VIP Title
    VIP = {
        DisplayName = "⭐ VIP",
        Icon = "⭐",
        Color = Color3.fromRGB(255, 200, 50),       -- Yellow/Gold
        TextStrokeColor = Color3.fromRGB(150, 100, 20),
        Priority = 70,
        HasGlow = false,
    },
    
    -- Moderator
    Moderator = {
        DisplayName = "🔷 Moderator",
        Icon = "🔷",
        Color = Color3.fromRGB(50, 150, 255),       -- Blue
        TextStrokeColor = Color3.fromRGB(20, 60, 120),
        Priority = 75,
        HasGlow = false,
    },
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get tier title based on rounds won
function TitleConfig.GetTierByRoundsWin(roundsWin)
    local highestTier = TitleConfig.TierTitles[1]
    
    for _, tierData in ipairs(TitleConfig.TierTitles) do
        if roundsWin >= tierData.MinRoundsWin then
            highestTier = tierData
        else
            break
        end
    end
    
    return highestTier
end

-- Get special title data by name
function TitleConfig.GetSpecialTitle(titleName)
    return TitleConfig.SpecialTitles[titleName]
end

-- Get tier title data by name
function TitleConfig.GetTierTitle(titleName)
    for _, tierData in ipairs(TitleConfig.TierTitles) do
        if tierData.Name == titleName then
            return tierData
        end
    end
    return nil
end

-- Get any title data (special or tier)
function TitleConfig.GetTitleData(titleName)
    -- Check special titles first
    local specialTitle = TitleConfig.GetSpecialTitle(titleName)
    if specialTitle then
        return {
            Name = titleName,
            DisplayName = specialTitle.DisplayName,
            Icon = specialTitle.Icon,
            Color = specialTitle.Color,
            TextStrokeColor = specialTitle.TextStrokeColor,
            Priority = specialTitle.Priority,
            HasGlow = specialTitle.HasGlow,
            GlowColor = specialTitle.GlowColor,
            IsSpecial = true,
        }
    end
    
    -- Check tier titles
    local tierTitle = TitleConfig.GetTierTitle(titleName)
    if tierTitle then
        return {
            Name = tierTitle.Name,
            DisplayName = tierTitle.DisplayName,
            Icon = tierTitle.Icon,
            Color = tierTitle.Color,
            TextStrokeColor = tierTitle.TextStrokeColor,
            MinRoundsWin = tierTitle.MinRoundsWin,
            Priority = 0,
            HasGlow = tierTitle.HasGlow,
            GlowColor = tierTitle.GlowColor,
            IsSpecial = false,
        }
    end
    
    return nil
end

-- Get list of all available titles
function TitleConfig.GetAllTitles()
    local allTitles = {}
    
    -- Add tier titles
    for _, tierData in ipairs(TitleConfig.TierTitles) do
        table.insert(allTitles, {
            Name = tierData.Name,
            DisplayName = tierData.DisplayName,
            Type = "Tier",
            MinRoundsWin = tierData.MinRoundsWin,
        })
    end
    
    -- Add special titles
    for name, data in pairs(TitleConfig.SpecialTitles) do
        table.insert(allTitles, {
            Name = name,
            DisplayName = data.DisplayName,
            Type = "Special",
            Priority = data.Priority,
        })
    end
    
    return allTitles
end

-- ============================================
-- UI CONFIGURATION (for billboard)
-- ============================================
TitleConfig.UI = {
    -- Billboard size and offset
    BillboardSize = UDim2.new(6, 0, 2.5, 0),
    BillboardOffset = Vector3.new(0, 3.5, 0),
    MaxDistance = 100,
    
    -- Name display
    NameFont = Enum.Font.GothamBold,
    NameTextSize = 20,
    NameColor = Color3.fromRGB(255, 255, 255),
    
    -- Title display
    TitleFont = Enum.Font.GothamSemibold,
    TitleTextSize = 16,
    
    -- Glow effect
    GlowTransparency = 0.7,
    GlowSize = 3,
}

return TitleConfig
