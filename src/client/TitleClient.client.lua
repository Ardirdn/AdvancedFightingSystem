--[[
    TitleClient.client.lua
    Client script to display player titles above heads
    
    Features:
    - BillboardGui above player heads
    - Shows player name + title
    - Updated when title changes
    - Glow effects for special titles
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Wait for TitleConfig
local TitleConfig
local function loadTitleConfig()
    local modules = ReplicatedStorage:WaitForChild("Modules", 10)
    if modules then
        local configModule = modules:FindFirstChild("TitleConfig")
        if configModule then
            TitleConfig = require(configModule)
            return true
        end
    end
    warn("❌ [TitleClient] TitleConfig not found!")
    return false
end

-- Wait for remotes
local remoteFolder = ReplicatedStorage:WaitForChild("TitleRemotes", 10)
if not remoteFolder then
    warn("❌ [TitleClient] TitleRemotes not found!")
    return
end

local GetTitleFunc = remoteFolder:WaitForChild("GetTitle", 5)
local BroadcastTitleEvent = remoteFolder:WaitForChild("BroadcastTitle", 5)

-- Billboard cache
local billboardCache = {}

-- ============================================
-- BILLBOARD CREATION
-- ============================================

local function createBillboard(character, targetPlayer)
    local head = character:WaitForChild("Head", 5)
    if not head then return nil end
    
    -- Remove existing
    local existing = head:FindFirstChild("TitleBillboard")
    if existing then existing:Destroy() end
    
    if not TitleConfig then loadTitleConfig() end
    local uiConfig = TitleConfig and TitleConfig.UI or {
        BillboardSize = UDim2.new(6, 0, 2.5, 0),
        BillboardOffset = Vector3.new(0, 3.5, 0),
        MaxDistance = 100,
        NameFont = Enum.Font.GothamBold,
        NameTextSize = 20,
        NameColor = Color3.fromRGB(255, 255, 255),
        TitleFont = Enum.Font.GothamSemibold,
        TitleTextSize = 16,
    }
    
    -- Create billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TitleBillboard"
    billboard.Size = uiConfig.BillboardSize
    billboard.StudsOffset = uiConfig.BillboardOffset
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = uiConfig.MaxDistance
    billboard.LightInfluence = 0
    billboard.Parent = head
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = billboard
    
    -- Note: Glow effect removed - was causing double title visual bug
    -- Using UIStroke instead for title outline effect
    
    -- Title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0.35, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = uiConfig.TitleFont or Enum.Font.GothamSemibold
    titleLabel.TextScaled = true
    titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.Text = "🥊 Rookie Fighter"
    titleLabel.ZIndex = 2
    titleLabel.Parent = mainFrame
    
    local titleStroke = Instance.new("UIStroke")
    titleStroke.Color = Color3.fromRGB(0, 0, 0)
    titleStroke.Thickness = 1.8
    titleStroke.Transparency = 0.2
    titleStroke.Parent = titleLabel
    
    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.35, 0)
    nameLabel.Position = UDim2.new(0, 0, 0.35, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = uiConfig.NameFont or Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.TextColor3 = uiConfig.NameColor or Color3.fromRGB(255, 255, 255)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.Text = targetPlayer.DisplayName
    nameLabel.ZIndex = 2
    nameLabel.Parent = mainFrame
    
    local nameStroke = Instance.new("UIStroke")
    nameStroke.Color = Color3.fromRGB(0, 0, 0)
    nameStroke.Thickness = 2
    nameStroke.Transparency = 0.2
    nameStroke.Parent = nameLabel
    
    -- Stats label (RoundsWin / MatchWin)
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Name = "StatsLabel"
    statsLabel.Size = UDim2.new(1, 0, 0.2, 0)
    statsLabel.Position = UDim2.new(0, 0, 0.72, 0)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.TextScaled = true
    statsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    statsLabel.TextXAlignment = Enum.TextXAlignment.Center
    statsLabel.Text = "🏆 0 | 🥊 0"
    statsLabel.ZIndex = 2
    statsLabel.Parent = mainFrame
    
    local statsStroke = Instance.new("UIStroke")
    statsStroke.Color = Color3.fromRGB(0, 0, 0)
    statsStroke.Thickness = 1.2
    statsStroke.Transparency = 0.3
    statsStroke.Parent = statsLabel
    
    billboardCache[targetPlayer] = billboard
    return billboard
end

-- ============================================
-- UPDATE FUNCTIONS
-- ============================================

local function updateTitle(targetPlayer, titleName)
    local billboard = billboardCache[targetPlayer]
    if not billboard then return end
    
    local mainFrame = billboard:FindFirstChild("MainFrame")
    if not mainFrame then return end
    
    local titleLabel = mainFrame:FindFirstChild("TitleLabel")
    if not titleLabel then return end
    
    if not TitleConfig then loadTitleConfig() end
    if not TitleConfig then return end
    
    local titleData = TitleConfig.GetTitleData(titleName)
    
    if titleData then
        -- Set title text
        local displayText = titleData.Icon .. " " .. titleData.DisplayName
        titleLabel.Text = displayText
        titleLabel.TextColor3 = titleData.Color
        
        -- Update stroke color for special glow effect
        local stroke = titleLabel:FindFirstChildOfClass("UIStroke")
        if stroke then
            if titleData.HasGlow and titleData.GlowColor then
                -- Use glow color for stroke with thicker outline
                stroke.Color = titleData.GlowColor
                stroke.Thickness = 2.5
                stroke.Transparency = 0.3
            else
                -- Normal stroke
                stroke.Color = titleData.TextStrokeColor or Color3.fromRGB(0, 0, 0)
                stroke.Thickness = 1.8
                stroke.Transparency = 0.2
            end
        end
    else
        -- Default title
        titleLabel.Text = "🥊 Rookie Fighter"
        titleLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        
        local stroke = titleLabel:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = Color3.fromRGB(0, 0, 0)
            stroke.Thickness = 1.8
            stroke.Transparency = 0.2
        end
    end
end

local function updateStats(targetPlayer)
    local billboard = billboardCache[targetPlayer]
    if not billboard then return end
    
    local mainFrame = billboard:FindFirstChild("MainFrame")
    if not mainFrame then return end
    
    local statsLabel = mainFrame:FindFirstChild("StatsLabel")
    if not statsLabel then return end
    
    -- Try to get player stats from leaderstats or PlayerStats folder
    local roundsWin = 0
    local matchWin = 0
    
    -- Check for PlayerStats folder
    local playerStats = targetPlayer:FindFirstChild("PlayerStats")
    if playerStats then
        local roundsValue = playerStats:FindFirstChild("RoundsWin")
        local matchValue = playerStats:FindFirstChild("MatchWin")
        
        if roundsValue and roundsValue:IsA("IntValue") then
            roundsWin = roundsValue.Value
        end
        if matchValue and matchValue:IsA("IntValue") then
            matchWin = matchValue.Value
        end
    end
    
    -- Check leaderstats as fallback
    local leaderstats = targetPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local roundsValue = leaderstats:FindFirstChild("RoundsWin") or leaderstats:FindFirstChild("Rounds")
        local matchValue = leaderstats:FindFirstChild("MatchWin") or leaderstats:FindFirstChild("Wins")
        
        if roundsValue and roundsValue:IsA("IntValue") then
            roundsWin = roundsValue.Value
        end
        if matchValue and matchValue:IsA("IntValue") then
            matchWin = matchValue.Value
        end
    end
    
    statsLabel.Text = string.format("🏆 %d | 🥊 %d", matchWin, roundsWin)
end

-- ============================================
-- PLAYER SETUP
-- ============================================

local function hideDefaultName(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
end

local function setupPlayer(targetPlayer)
    local function onCharacterAdded(character)
        task.wait(0.5)
        hideDefaultName(character)
        
        local billboard = createBillboard(character, targetPlayer)
        if not billboard then return end
        
        -- Get initial title from server
        task.spawn(function()
            task.wait(1)
            if not targetPlayer or not targetPlayer.Parent then return end
            
            local success, title = pcall(function()
                return GetTitleFunc:InvokeServer(targetPlayer)
            end)
            
            if success and title then
                updateTitle(targetPlayer, title)
            end
        end)
        
        -- Wait for PlayerStats folder to be created by server
        task.spawn(function()
            local playerStats = nil
            
            -- Wait up to 10 seconds for PlayerStats folder
            for i = 1, 20 do
                playerStats = targetPlayer:FindFirstChild("PlayerStats")
                if playerStats then break end
                task.wait(0.5)
            end
            
            if not playerStats then
                -- Still try to update stats even if folder not found
                updateStats(targetPlayer)
                return
            end
            
            -- Initial stats update
            updateStats(targetPlayer)
            
            -- Watch for current stats
            for _, stat in ipairs(playerStats:GetChildren()) do
                if stat:IsA("IntValue") then
                    stat:GetPropertyChangedSignal("Value"):Connect(function()
                        updateStats(targetPlayer)
                    end)
                end
            end
            
            -- Watch for new stats added
            playerStats.ChildAdded:Connect(function(stat)
                if stat:IsA("IntValue") then
                    stat:GetPropertyChangedSignal("Value"):Connect(function()
                        updateStats(targetPlayer)
                    end)
                    updateStats(targetPlayer)
                end
            end)
        end)
    end
    
    targetPlayer.CharacterAdded:Connect(onCharacterAdded)
    if targetPlayer.Character then
        onCharacterAdded(targetPlayer.Character)
    end
    
    -- Also watch for PlayerStats folder being added to player directly
    targetPlayer.ChildAdded:Connect(function(child)
        if child.Name == "PlayerStats" then
            updateStats(targetPlayer)
            
            for _, stat in ipairs(child:GetChildren()) do
                if stat:IsA("IntValue") then
                    stat:GetPropertyChangedSignal("Value"):Connect(function()
                        updateStats(targetPlayer)
                    end)
                end
            end
            
            child.ChildAdded:Connect(function(stat)
                if stat:IsA("IntValue") then
                    stat:GetPropertyChangedSignal("Value"):Connect(function()
                        updateStats(targetPlayer)
                    end)
                    updateStats(targetPlayer)
                end
            end)
        end
    end)
end

local function cleanupPlayer(targetPlayer)
    billboardCache[targetPlayer] = nil
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

-- Listen for title broadcasts from server
if BroadcastTitleEvent then
    BroadcastTitleEvent.OnClientEvent:Connect(function(targetPlayer, titleName)
        if not targetPlayer then return end
        
        -- Wait for billboard to be created
        task.spawn(function()
            for _ = 1, 10 do
                if billboardCache[targetPlayer] then
                    updateTitle(targetPlayer, titleName)
                    return
                end
                task.wait(0.3)
            end
        end)
    end)
end

-- ============================================
-- INITIALIZATION
-- ============================================

-- Load config
loadTitleConfig()

-- Setup existing players
for _, targetPlayer in ipairs(Players:GetPlayers()) do
    setupPlayer(targetPlayer)
end

-- Setup new players
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(cleanupPlayer)

-- Periodic refresh (every 30 seconds)
task.spawn(function()
    while true do
        task.wait(30)
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if billboardCache[targetPlayer] then
                task.spawn(function()
                    local success, title = pcall(function()
                        return GetTitleFunc:InvokeServer(targetPlayer)
                    end)
                    
                    if success and title then
                        updateTitle(targetPlayer, title)
                    end
                    
                    updateStats(targetPlayer)
                end)
                task.wait(0.1)
            end
        end
    end
end)

print("✅ [TitleClient] Title display system initialized")
