--[[
    FightInfoScreen.server.lua
    Handles updating SurfaceGui displays in arena for fight information
    
    Setup:
    - Create folder "FightInfoScreen" inside each FightingArena
    - Add Parts with SurfaceGui inside that folder
    - Each SurfaceGui should have a Frame called "MainFrame"
    
    Display shows:
    - Player A avatar, name, health bar
    - "VS" in the middle
    - Player B avatar, name, health bar
    - "No Fight" when arena is empty
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Wait for modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local FightingConfig = require(Modules:WaitForChild("FightingConfig"))

local FightingRemotes = ReplicatedStorage:WaitForChild("FightingRemotes")

-- Store screen references and update connections
local screenUpdaters = {}

-- ============================================
-- UI CREATION FUNCTIONS
-- ============================================

local function createFightInfoUI(surfaceGui)
    local mainFrame = surfaceGui:FindFirstChild("MainFrame")
    if not mainFrame then
        mainFrame = Instance.new("Frame")
        mainFrame.Name = "MainFrame"
        mainFrame.Size = UDim2.new(1, 0, 1, 0)
        mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        mainFrame.BorderSizePixel = 0
        mainFrame.Parent = surfaceGui
    end
    
    -- Clear existing children (except layouts)
    for _, child in ipairs(mainFrame:GetChildren()) do
        if not child:IsA("UILayout") then
            child:Destroy()
        end
    end
    
    -- Dark gradient background
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15))
    })
    gradient.Rotation = 90
    gradient.Parent = mainFrame
    
    -- ============================================
    -- PLAYER A (LEFT SIDE)
    -- ============================================
    
    local playerAFrame = Instance.new("Frame")
    playerAFrame.Name = "PlayerA"
    playerAFrame.Size = UDim2.new(0.4, 0, 1, 0)
    playerAFrame.Position = UDim2.new(0, 0, 0, 0)
    playerAFrame.BackgroundTransparency = 1
    playerAFrame.Parent = mainFrame
    
    -- Avatar A (left aligned)
    local avatarAFrame = Instance.new("Frame")
    avatarAFrame.Name = "AvatarFrame"
    avatarAFrame.Size = UDim2.new(0.3, 0, 0.5, 0)
    avatarAFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
    avatarAFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    avatarAFrame.BorderSizePixel = 0
    avatarAFrame.Parent = playerAFrame
    
    local avatarACorner = Instance.new("UICorner")
    avatarACorner.CornerRadius = UDim.new(0, 8)
    avatarACorner.Parent = avatarAFrame
    
    local avatarAStroke = Instance.new("UIStroke")
    avatarAStroke.Color = Color3.fromRGB(80, 200, 80)
    avatarAStroke.Thickness = 3
    avatarAStroke.Parent = avatarAFrame
    
    local avatarA = Instance.new("ImageLabel")
    avatarA.Name = "Avatar"
    avatarA.Size = UDim2.new(1, 0, 1, 0)
    avatarA.BackgroundTransparency = 1
    avatarA.ScaleType = Enum.ScaleType.Crop
    avatarA.Parent = avatarAFrame
    
    local avatarAImgCorner = Instance.new("UICorner")
    avatarAImgCorner.CornerRadius = UDim.new(0, 6)
    avatarAImgCorner.Parent = avatarA
    
    -- Name A
    local nameA = Instance.new("TextLabel")
    nameA.Name = "Name"
    nameA.Size = UDim2.new(0.6, 0, 0.15, 0)
    nameA.Position = UDim2.new(0.38, 0, 0.2, 0)
    nameA.BackgroundTransparency = 1
    nameA.Font = Enum.Font.GothamBlack
    nameA.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameA.TextScaled = true
    nameA.TextXAlignment = Enum.TextXAlignment.Left
    nameA.Text = "Player A"
    nameA.Parent = playerAFrame
    
    -- Health Bar A
    local healthBgA = Instance.new("Frame")
    healthBgA.Name = "HealthBg"
    healthBgA.Size = UDim2.new(0.55, 0, 0.1, 0)
    healthBgA.Position = UDim2.new(0.38, 0, 0.38, 0)
    healthBgA.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    healthBgA.BorderSizePixel = 0
    healthBgA.Parent = playerAFrame
    
    local healthBgACorner = Instance.new("UICorner")
    healthBgACorner.CornerRadius = UDim.new(0, 6)
    healthBgACorner.Parent = healthBgA
    
    local healthFillA = Instance.new("Frame")
    healthFillA.Name = "HealthFill"
    healthFillA.Size = UDim2.new(1, 0, 1, 0)
    healthFillA.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    healthFillA.BorderSizePixel = 0
    healthFillA.Parent = healthBgA
    
    local healthFillACorner = Instance.new("UICorner")
    healthFillACorner.CornerRadius = UDim.new(0, 6)
    healthFillACorner.Parent = healthFillA
    
    -- Stamina Bar A
    local staminaBgA = Instance.new("Frame")
    staminaBgA.Name = "StaminaBg"
    staminaBgA.Size = UDim2.new(0.45, 0, 0.06, 0)
    staminaBgA.Position = UDim2.new(0.38, 0, 0.52, 0)
    staminaBgA.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    staminaBgA.BorderSizePixel = 0
    staminaBgA.Parent = playerAFrame
    
    local staminaBgACorner = Instance.new("UICorner")
    staminaBgACorner.CornerRadius = UDim.new(0, 4)
    staminaBgACorner.Parent = staminaBgA
    
    local staminaFillA = Instance.new("Frame")
    staminaFillA.Name = "StaminaFill"
    staminaFillA.Size = UDim2.new(1, 0, 1, 0)
    staminaFillA.BackgroundColor3 = Color3.fromRGB(80, 180, 220)
    staminaFillA.BorderSizePixel = 0
    staminaFillA.Parent = staminaBgA
    
    local staminaFillACorner = Instance.new("UICorner")
    staminaFillACorner.CornerRadius = UDim.new(0, 4)
    staminaFillACorner.Parent = staminaFillA
    
    -- ============================================
    -- VS TEXT (CENTER)
    -- ============================================
    
    local vsFrame = Instance.new("Frame")
    vsFrame.Name = "VSFrame"
    vsFrame.Size = UDim2.new(0.2, 0, 1, 0)
    vsFrame.Position = UDim2.new(0.4, 0, 0, 0)
    vsFrame.BackgroundTransparency = 1
    vsFrame.Parent = mainFrame
    
    local vsText = Instance.new("TextLabel")
    vsText.Name = "VSText"
    vsText.Size = UDim2.new(1, 0, 0.4, 0)
    vsText.Position = UDim2.new(0, 0, 0.3, 0)
    vsText.BackgroundTransparency = 1
    vsText.Font = Enum.Font.GothamBlack
    vsText.TextColor3 = Color3.fromRGB(200, 60, 60)
    vsText.TextScaled = true
    vsText.Text = "VS"
    vsText.TextStrokeTransparency = 0.5
    vsText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    vsText.Parent = vsFrame
    
    -- ============================================
    -- PLAYER B (RIGHT SIDE - MIRRORED)
    -- ============================================
    
    local playerBFrame = Instance.new("Frame")
    playerBFrame.Name = "PlayerB"
    playerBFrame.Size = UDim2.new(0.4, 0, 1, 0)
    playerBFrame.Position = UDim2.new(0.6, 0, 0, 0)
    playerBFrame.BackgroundTransparency = 1
    playerBFrame.Parent = mainFrame
    
    -- Avatar B (right aligned)
    local avatarBFrame = Instance.new("Frame")
    avatarBFrame.Name = "AvatarFrame"
    avatarBFrame.Size = UDim2.new(0.3, 0, 0.5, 0)
    avatarBFrame.Position = UDim2.new(0.65, 0, 0.15, 0)
    avatarBFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    avatarBFrame.BorderSizePixel = 0
    avatarBFrame.Parent = playerBFrame
    
    local avatarBCorner = Instance.new("UICorner")
    avatarBCorner.CornerRadius = UDim.new(0, 8)
    avatarBCorner.Parent = avatarBFrame
    
    local avatarBStroke = Instance.new("UIStroke")
    avatarBStroke.Color = Color3.fromRGB(200, 80, 80)
    avatarBStroke.Thickness = 3
    avatarBStroke.Parent = avatarBFrame
    
    local avatarB = Instance.new("ImageLabel")
    avatarB.Name = "Avatar"
    avatarB.Size = UDim2.new(1, 0, 1, 0)
    avatarB.BackgroundTransparency = 1
    avatarB.ScaleType = Enum.ScaleType.Crop
    avatarB.Parent = avatarBFrame
    
    local avatarBImgCorner = Instance.new("UICorner")
    avatarBImgCorner.CornerRadius = UDim.new(0, 6)
    avatarBImgCorner.Parent = avatarB
    
    -- Name B (right aligned)
    local nameB = Instance.new("TextLabel")
    nameB.Name = "Name"
    nameB.Size = UDim2.new(0.6, 0, 0.15, 0)
    nameB.Position = UDim2.new(0.02, 0, 0.2, 0)
    nameB.BackgroundTransparency = 1
    nameB.Font = Enum.Font.GothamBlack
    nameB.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameB.TextScaled = true
    nameB.TextXAlignment = Enum.TextXAlignment.Right
    nameB.Text = "Player B"
    nameB.Parent = playerBFrame
    
    -- Health Bar B
    local healthBgB = Instance.new("Frame")
    healthBgB.Name = "HealthBg"
    healthBgB.Size = UDim2.new(0.55, 0, 0.1, 0)
    healthBgB.Position = UDim2.new(0.07, 0, 0.38, 0)
    healthBgB.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    healthBgB.BorderSizePixel = 0
    healthBgB.Parent = playerBFrame
    
    local healthBgBCorner = Instance.new("UICorner")
    healthBgBCorner.CornerRadius = UDim.new(0, 6)
    healthBgBCorner.Parent = healthBgB
    
    local healthFillB = Instance.new("Frame")
    healthFillB.Name = "HealthFill"
    healthFillB.Size = UDim2.new(1, 0, 1, 0)
    healthFillB.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
    healthFillB.BorderSizePixel = 0
    healthFillB.Parent = healthBgB
    
    local healthFillBCorner = Instance.new("UICorner")
    healthFillBCorner.CornerRadius = UDim.new(0, 6)
    healthFillBCorner.Parent = healthFillB
    
    -- Stamina Bar B
    local staminaBgB = Instance.new("Frame")
    staminaBgB.Name = "StaminaBg"
    staminaBgB.Size = UDim2.new(0.45, 0, 0.06, 0)
    staminaBgB.Position = UDim2.new(0.17, 0, 0.52, 0)
    staminaBgB.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    staminaBgB.BorderSizePixel = 0
    staminaBgB.Parent = playerBFrame
    
    local staminaBgBCorner = Instance.new("UICorner")
    staminaBgBCorner.CornerRadius = UDim.new(0, 4)
    staminaBgBCorner.Parent = staminaBgB
    
    local staminaFillB = Instance.new("Frame")
    staminaFillB.Name = "StaminaFill"
    staminaFillB.Size = UDim2.new(1, 0, 1, 0)
    staminaFillB.BackgroundColor3 = Color3.fromRGB(80, 180, 220)
    staminaFillB.BorderSizePixel = 0
    staminaFillB.Parent = staminaBgB
    
    local staminaFillBCorner = Instance.new("UICorner")
    staminaFillBCorner.CornerRadius = UDim.new(0, 4)
    staminaFillBCorner.Parent = staminaFillB
    
    -- ============================================
    -- NO FIGHT TEXT (shown when no fight active)
    -- ============================================
    
    local noFightText = Instance.new("TextLabel")
    noFightText.Name = "NoFightText"
    noFightText.Size = UDim2.new(0.8, 0, 0.3, 0)
    noFightText.Position = UDim2.new(0.1, 0, 0.35, 0)
    noFightText.BackgroundTransparency = 1
    noFightText.Font = Enum.Font.GothamBlack
    noFightText.TextColor3 = Color3.fromRGB(100, 100, 110)
    noFightText.TextScaled = true
    noFightText.Text = "NO FIGHT"
    noFightText.Visible = true
    noFightText.ZIndex = 10
    noFightText.Parent = mainFrame
    
    -- Initially hide fight UI, show no fight text
    playerAFrame.Visible = false
    playerBFrame.Visible = false
    vsFrame.Visible = false
    
    return mainFrame
end

local function updateFightScreen(mainFrame, arenaState)
    if not mainFrame then return end
    
    local playerAFrame = mainFrame:FindFirstChild("PlayerA")
    local playerBFrame = mainFrame:FindFirstChild("PlayerB")
    local vsFrame = mainFrame:FindFirstChild("VSFrame")
    local noFightText = mainFrame:FindFirstChild("NoFightText")
    
    if not arenaState or not arenaState.IsActive then
        -- Show "No Fight" state
        if playerAFrame then playerAFrame.Visible = false end
        if playerBFrame then playerBFrame.Visible = false end
        if vsFrame then vsFrame.Visible = false end
        if noFightText then noFightText.Visible = true end
        return
    end
    
    -- Show fight UI
    if playerAFrame then playerAFrame.Visible = true end
    if playerBFrame then playerBFrame.Visible = true end
    if vsFrame then vsFrame.Visible = true end
    if noFightText then noFightText.Visible = false end
    
    -- Update Player A
    if playerAFrame and arenaState.PlayerA then
        local nameA = playerAFrame:FindFirstChild("Name")
        if nameA then nameA.Text = arenaState.PlayerA.Name end
        
        local avatarFrame = playerAFrame:FindFirstChild("AvatarFrame")
        if avatarFrame then
            local avatar = avatarFrame:FindFirstChild("Avatar")
            if avatar then
                pcall(function()
                    avatar.Image = Players:GetUserThumbnailAsync(
                        arenaState.PlayerA.UserId, 
                        Enum.ThumbnailType.HeadShot, 
                        Enum.ThumbnailSize.Size100x100
                    )
                end)
            end
        end
        
        local healthBg = playerAFrame:FindFirstChild("HealthBg")
        if healthBg then
            local fill = healthBg:FindFirstChild("HealthFill")
            if fill then
                local percent = (arenaState.PlayerAHealth or 100) / FightingConfig.Stats.MaxHealth
                fill.Size = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0)
            end
        end
        
        local staminaBg = playerAFrame:FindFirstChild("StaminaBg")
        if staminaBg then
            local fill = staminaBg:FindFirstChild("StaminaFill")
            if fill then
                local percent = (arenaState.PlayerAStamina or 100) / FightingConfig.Stats.MaxStamina
                fill.Size = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0)
            end
        end
    end
    
    -- Update Player B
    if playerBFrame and arenaState.PlayerB then
        local nameB = playerBFrame:FindFirstChild("Name")
        if nameB then nameB.Text = arenaState.PlayerB.Name end
        
        local avatarFrame = playerBFrame:FindFirstChild("AvatarFrame")
        if avatarFrame then
            local avatar = avatarFrame:FindFirstChild("Avatar")
            if avatar then
                pcall(function()
                    avatar.Image = Players:GetUserThumbnailAsync(
                        arenaState.PlayerB.UserId, 
                        Enum.ThumbnailType.HeadShot, 
                        Enum.ThumbnailSize.Size100x100
                    )
                end)
            end
        end
        
        local healthBg = playerBFrame:FindFirstChild("HealthBg")
        if healthBg then
            local fill = healthBg:FindFirstChild("HealthFill")
            if fill then
                local percent = (arenaState.PlayerBHealth or 100) / FightingConfig.Stats.MaxHealth
                fill.Size = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0)
            end
        end
        
        local staminaBg = playerBFrame:FindFirstChild("StaminaBg")
        if staminaBg then
            local fill = staminaBg:FindFirstChild("StaminaFill")
            if fill then
                local percent = (arenaState.PlayerBStamina or 100) / FightingConfig.Stats.MaxStamina
                fill.Size = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0)
            end
        end
    end
end

-- ============================================
-- INITIALIZATION
-- ============================================

local function initializeFightScreens()
    local fightingArenaFolder = workspace:FindFirstChild("FightingArena")
    if not fightingArenaFolder then
        warn("⚠️ [FightInfoScreen] FightingArena folder not found")
        return
    end
    
    -- Find all FightInfoScreen folders in arenas
    for _, arena in ipairs(fightingArenaFolder:GetChildren()) do
        if arena:IsA("Folder") then
            local infoScreenFolder = arena:FindFirstChild("FightInfoScreen")
            if infoScreenFolder then
                print("📺 [FightInfoScreen] Found info screen folder in", arena.Name)
                
                -- Find all Parts with SurfaceGui
                for _, part in ipairs(infoScreenFolder:GetChildren()) do
                    if part:IsA("BasePart") then
                        local surfaceGui = part:FindFirstChildOfClass("SurfaceGui")
                        if surfaceGui then
                            local mainFrame = createFightInfoUI(surfaceGui)
                            
                            -- Store reference for updates
                            table.insert(screenUpdaters, {
                                ArenaName = arena.Name,
                                MainFrame = mainFrame,
                            })
                            
                            print("  ✅ Created UI for", part.Name)
                        end
                    end
                end
            end
        end
    end
    
    print("📺 [FightInfoScreen] Initialized", #screenUpdaters, "screens")
end

-- Wait for FightingServer to expose arenaStates
local function getArenaState(arenaName)
    -- Access shared arenaStates from FightingServer via _G
    if _G.FightingArenaStates then
        return _G.FightingArenaStates[arenaName]
    end
    return nil
end

-- Update loop
task.spawn(function()
    task.wait(3) -- Wait for FightingServer to initialize
    initializeFightScreens()
    
    while true do
        for _, screen in ipairs(screenUpdaters) do
            local arenaState = getArenaState(screen.ArenaName)
            updateFightScreen(screen.MainFrame, arenaState)
        end
        task.wait(0.5) -- Update every 0.5 seconds
    end
end)

print("📺 [FightInfoScreen] Server script loaded!")
