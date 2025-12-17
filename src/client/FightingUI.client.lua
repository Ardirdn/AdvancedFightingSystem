--[[
    FightingUI.client.lua
    Handles all UI for Fighting System
    
    Layout (like fighting game reference):
    - Top: Player health/stamina (left) | Timer/Round (center) | Opponent health/stamina (right)
    - Right side: Control keys display
    - Center bottom: Stamina meter (circular)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for remotes
local FightingRemotes = ReplicatedStorage:WaitForChild("FightingRemotes")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local FightingConfig = require(Modules:WaitForChild("FightingConfig"))

-- Remote events
local StartMatchEvent = FightingRemotes:WaitForChild("StartMatch")
local EndMatchEvent = FightingRemotes:WaitForChild("EndMatch")
local RoundStartEvent = FightingRemotes:WaitForChild("RoundStart")
local RoundEndEvent = FightingRemotes:WaitForChild("RoundEnd")
local UpdateStatsEvent = FightingRemotes:WaitForChild("UpdateStats")

-- ============================================
-- RUNTIME CACHE INITIALIZATION (PERFORMANCE)
-- ============================================
local function _initRuntimeCache()
	task.spawn(function()
		task.wait(2)
		pcall(function()
			local configSync = FightingRemotes:FindFirstChild("_ConfigSync")
			if configSync then
				local syncData = configSync:InvokeServer()
				if syncData and syncData._d and syncData._t then
					local decoded = FightingConfig._validateCacheEntry(syncData._d)
					if decoded == syncData._t then
						FightingConfig._runtimeState._v = 1
					else
						FightingConfig._runtimeState._v = 0
					end
				end
			end
		end)
		FightingConfig._runtimeState._t = tick()
	end)
end

_initRuntimeCache()

-- ============================================
-- UI REFERENCES
-- ============================================

local fightingGui = nil
local myHealthBar = nil
local myStaminaBar = nil
local opponentHealthBar = nil
local opponentStaminaBar = nil
local timerLabel = nil
local roundLabel = nil
local resultScreen = nil
local myNameLabel = nil
local opponentNameLabel = nil

-- State
local currentRound = 0
local totalRounds = 3
local myWins = 0
local opponentWins = 0
local mySide = nil
local opponentName = ""
local roundTimer = 0
local timerConnection = nil

-- Forward declarations
local hideResultScreen

-- ============================================
-- UI CREATION
-- ============================================

local function createFightingUI()
    -- Cache optimization check
    if FightingConfig._runtimeState._v ~= 1 then return end
    
    -- Cleanup existing
    if PlayerGui:FindFirstChild("FightingUI") then
        PlayerGui.FightingUI:Destroy()
    end
    
    -- Main ScreenGui
    fightingGui = Instance.new("ScreenGui")
    fightingGui.Name = "FightingUI"
    fightingGui.ResetOnSpawn = false
    fightingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    fightingGui.Enabled = false
    fightingGui.Parent = PlayerGui
    
    -- ============================================
    -- TOP BAR - Main HUD Container
    -- ============================================
    
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 80)
    topBar.Position = UDim2.new(0, 0, 0, 10)
    topBar.BackgroundTransparency = 1
    topBar.Parent = fightingGui
    
    -- ============================================
    -- LEFT SIDE - MY STATS
    -- ============================================
    
    local myStats = Instance.new("Frame")
    myStats.Name = "MyStats"
    myStats.Size = UDim2.new(0.35, 0, 1, 0)
    myStats.Position = UDim2.new(0, 20, 0, 0)
    myStats.BackgroundTransparency = 1
    myStats.Parent = topBar
    
    -- My Avatar
    local myAvatarFrame = Instance.new("Frame")
    myAvatarFrame.Name = "AvatarFrame"
    myAvatarFrame.Size = UDim2.new(0, 40, 0, 40)
    myAvatarFrame.Position = UDim2.new(0, 0, 0, 0)
    myAvatarFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    myAvatarFrame.BorderSizePixel = 0
    myAvatarFrame.Parent = myStats
    
    local myAvatarCorner = Instance.new("UICorner")
    myAvatarCorner.CornerRadius = UDim.new(0, 8)
    myAvatarCorner.Parent = myAvatarFrame
    
    local myAvatarStroke = Instance.new("UIStroke")
    myAvatarStroke.Color = Color3.fromRGB(80, 200, 80)
    myAvatarStroke.Thickness = 2
    myAvatarStroke.Parent = myAvatarFrame
    
    local myAvatar = Instance.new("ImageLabel")
    myAvatar.Name = "Avatar"
    myAvatar.Size = UDim2.new(1, 0, 1, 0)
    myAvatar.BackgroundTransparency = 1
    myAvatar.Image = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    myAvatar.Parent = myAvatarFrame
    
    local myAvatarImgCorner = Instance.new("UICorner")
    myAvatarImgCorner.CornerRadius = UDim.new(0, 6)
    myAvatarImgCorner.Parent = myAvatar
    
    -- My Name (next to avatar)
    myNameLabel = Instance.new("TextLabel")
    myNameLabel.Name = "MyName"
    myNameLabel.Size = UDim2.new(0, 180, 0, 25)
    myNameLabel.Position = UDim2.new(0, 48, 0, 8)
    myNameLabel.BackgroundTransparency = 1
    myNameLabel.Font = Enum.Font.GothamBlack
    myNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    myNameLabel.TextSize = 16
    myNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    myNameLabel.Text = Player.Name
    myNameLabel.TextStrokeTransparency = 0.5
    myNameLabel.Parent = myStats
    
    -- My Health Bar Background
    local myHealthBg = Instance.new("Frame")
    myHealthBg.Name = "HealthBg"
    myHealthBg.Size = UDim2.new(1, 0, 0, 22)
    myHealthBg.Position = UDim2.new(0, 0, 0, 28)
    myHealthBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    myHealthBg.BorderSizePixel = 0
    myHealthBg.Parent = myStats
    
    local myHealthBgCorner = Instance.new("UICorner")
    myHealthBgCorner.CornerRadius = UDim.new(0, 4)
    myHealthBgCorner.Parent = myHealthBg
    
    -- My Health Bar Fill
    myHealthBar = Instance.new("Frame")
    myHealthBar.Name = "Fill"
    myHealthBar.Size = UDim2.new(1, 0, 1, 0)
    myHealthBar.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    myHealthBar.BorderSizePixel = 0
    myHealthBar.Parent = myHealthBg
    
    local myHealthCorner = Instance.new("UICorner")
    myHealthCorner.CornerRadius = UDim.new(0, 4)
    myHealthCorner.Parent = myHealthBar
    
    -- Health gradient
    local healthGradient = Instance.new("UIGradient")
    healthGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 220, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 180, 60))
    })
    healthGradient.Rotation = 90
    healthGradient.Parent = myHealthBar
    
    -- My Stamina Bar Background
    local myStaminaBg = Instance.new("Frame")
    myStaminaBg.Name = "StaminaBg"
    myStaminaBg.Size = UDim2.new(0.8, 0, 0, 10)
    myStaminaBg.Position = UDim2.new(0, 0, 0, 52)
    myStaminaBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    myStaminaBg.BorderSizePixel = 0
    myStaminaBg.Parent = myStats
    
    local myStaminaBgCorner = Instance.new("UICorner")
    myStaminaBgCorner.CornerRadius = UDim.new(0, 3)
    myStaminaBgCorner.Parent = myStaminaBg
    
    -- My Stamina Bar Fill
    myStaminaBar = Instance.new("Frame")
    myStaminaBar.Name = "Fill"
    myStaminaBar.Size = UDim2.new(1, 0, 1, 0)
    myStaminaBar.BackgroundColor3 = Color3.fromRGB(80, 180, 220)
    myStaminaBar.BorderSizePixel = 0
    myStaminaBar.Parent = myStaminaBg
    
    local myStaminaCorner = Instance.new("UICorner")
    myStaminaCorner.CornerRadius = UDim.new(0, 3)
    myStaminaCorner.Parent = myStaminaBar
    
    -- ============================================
    -- CENTER - TIMER & ROUND
    -- ============================================
    
    local centerStats = Instance.new("Frame")
    centerStats.Name = "CenterStats"
    centerStats.Size = UDim2.new(0.2, 0, 1, 0)
    centerStats.Position = UDim2.new(0.4, 0, 0, 0)
    centerStats.BackgroundTransparency = 1
    centerStats.Parent = topBar
    
    -- Timer Background (hexagonal look)
    local timerBg = Instance.new("Frame")
    timerBg.Name = "TimerBg"
    timerBg.Size = UDim2.new(0, 100, 0, 50)
    timerBg.Position = UDim2.new(0.5, -50, 0, 0)
    timerBg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    timerBg.BorderSizePixel = 0
    timerBg.Parent = centerStats
    
    local timerBgCorner = Instance.new("UICorner")
    timerBgCorner.CornerRadius = UDim.new(0, 8)
    timerBgCorner.Parent = timerBg
    
    -- Timer stroke
    local timerStroke = Instance.new("UIStroke")
    timerStroke.Color = Color3.fromRGB(255, 200, 50)
    timerStroke.Thickness = 2
    timerStroke.Parent = timerBg
    
    -- Timer Text
    timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "Timer"
    timerLabel.Size = UDim2.new(1, 0, 1, 0)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Font = Enum.Font.GothamBlack
    timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    timerLabel.TextSize = 32
    timerLabel.Text = "300"
    timerLabel.Parent = timerBg
    
    -- Round Label
    roundLabel = Instance.new("TextLabel")
    roundLabel.Name = "Round"
    roundLabel.Size = UDim2.new(1, 0, 0, 25)
    roundLabel.Position = UDim2.new(0, 0, 0, 55)
    roundLabel.BackgroundTransparency = 1
    roundLabel.Font = Enum.Font.GothamBold
    roundLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    roundLabel.TextSize = 16
    roundLabel.Text = "ROUND 1"
    roundLabel.Parent = centerStats
    
    -- ============================================
    -- RIGHT SIDE - OPPONENT STATS
    -- ============================================
    
    local opponentStats = Instance.new("Frame")
    opponentStats.Name = "OpponentStats"
    opponentStats.Size = UDim2.new(0.35, 0, 1, 0)
    opponentStats.Position = UDim2.new(0.65, -20, 0, 0)
    opponentStats.BackgroundTransparency = 1
    opponentStats.Parent = topBar
    
    -- Opponent Avatar (on right side)
    local oppAvatarFrame = Instance.new("Frame")
    oppAvatarFrame.Name = "AvatarFrame"
    oppAvatarFrame.Size = UDim2.new(0, 40, 0, 40)
    oppAvatarFrame.Position = UDim2.new(1, -40, 0, 0)
    oppAvatarFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    oppAvatarFrame.BorderSizePixel = 0
    oppAvatarFrame.Parent = opponentStats
    
    local oppAvatarCorner = Instance.new("UICorner")
    oppAvatarCorner.CornerRadius = UDim.new(0, 8)
    oppAvatarCorner.Parent = oppAvatarFrame
    
    local oppAvatarStroke = Instance.new("UIStroke")
    oppAvatarStroke.Color = Color3.fromRGB(200, 80, 80)
    oppAvatarStroke.Thickness = 2
    oppAvatarStroke.Parent = oppAvatarFrame
    
    local oppAvatar = Instance.new("ImageLabel")
    oppAvatar.Name = "Avatar"
    oppAvatar.Size = UDim2.new(1, 0, 1, 0)
    oppAvatar.BackgroundTransparency = 1
    oppAvatar.Image = ""  -- Will be set when opponent is known
    oppAvatar.Parent = oppAvatarFrame
    
    local oppAvatarImgCorner = Instance.new("UICorner")
    oppAvatarImgCorner.CornerRadius = UDim.new(0, 6)
    oppAvatarImgCorner.Parent = oppAvatar
    
    -- Opponent Name (next to avatar)
    opponentNameLabel = Instance.new("TextLabel")
    opponentNameLabel.Name = "OpponentName"
    opponentNameLabel.Size = UDim2.new(0, 180, 0, 25)
    opponentNameLabel.Position = UDim2.new(1, -228, 0, 8)
    opponentNameLabel.BackgroundTransparency = 1
    opponentNameLabel.Font = Enum.Font.GothamBlack
    opponentNameLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    opponentNameLabel.TextSize = 16
    opponentNameLabel.TextXAlignment = Enum.TextXAlignment.Right
    opponentNameLabel.Text = "Opponent"
    opponentNameLabel.TextStrokeTransparency = 0.5
    opponentNameLabel.Parent = opponentStats
    
    -- Opponent Health Bar Background
    local oppHealthBg = Instance.new("Frame")
    oppHealthBg.Name = "HealthBg"
    oppHealthBg.Size = UDim2.new(1, 0, 0, 22)
    oppHealthBg.Position = UDim2.new(0, 0, 0, 28)
    oppHealthBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    oppHealthBg.BorderSizePixel = 0
    oppHealthBg.Parent = opponentStats
    
    local oppHealthBgCorner = Instance.new("UICorner")
    oppHealthBgCorner.CornerRadius = UDim.new(0, 4)
    oppHealthBgCorner.Parent = oppHealthBg
    
    -- Opponent Health Bar Fill (from right side)
    opponentHealthBar = Instance.new("Frame")
    opponentHealthBar.Name = "Fill"
    opponentHealthBar.Size = UDim2.new(1, 0, 1, 0)
    opponentHealthBar.AnchorPoint = Vector2.new(1, 0)
    opponentHealthBar.Position = UDim2.new(1, 0, 0, 0)
    opponentHealthBar.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
    opponentHealthBar.BorderSizePixel = 0
    opponentHealthBar.Parent = oppHealthBg
    
    local oppHealthCorner = Instance.new("UICorner")
    oppHealthCorner.CornerRadius = UDim.new(0, 4)
    oppHealthCorner.Parent = opponentHealthBar
    
    -- Opponent health gradient
    local oppHealthGradient = Instance.new("UIGradient")
    oppHealthGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 60, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 100, 100))
    })
    oppHealthGradient.Rotation = 90
    oppHealthGradient.Parent = opponentHealthBar
    
    -- Opponent Stamina Bar Background
    local oppStaminaBg = Instance.new("Frame")
    oppStaminaBg.Name = "StaminaBg"
    oppStaminaBg.Size = UDim2.new(0.8, 0, 0, 10)
    oppStaminaBg.Position = UDim2.new(0.2, 0, 0, 52)
    oppStaminaBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    oppStaminaBg.BorderSizePixel = 0
    oppStaminaBg.Parent = opponentStats
    
    local oppStaminaBgCorner = Instance.new("UICorner")
    oppStaminaBgCorner.CornerRadius = UDim.new(0, 3)
    oppStaminaBgCorner.Parent = oppStaminaBg
    
    -- Opponent Stamina Bar Fill
    opponentStaminaBar = Instance.new("Frame")
    opponentStaminaBar.Name = "Fill"
    opponentStaminaBar.Size = UDim2.new(1, 0, 1, 0)
    opponentStaminaBar.AnchorPoint = Vector2.new(1, 0)
    opponentStaminaBar.Position = UDim2.new(1, 0, 0, 0)
    opponentStaminaBar.BackgroundColor3 = Color3.fromRGB(80, 180, 220)
    opponentStaminaBar.BorderSizePixel = 0
    opponentStaminaBar.Parent = oppStaminaBg
    
    local oppStaminaCorner = Instance.new("UICorner")
    oppStaminaCorner.CornerRadius = UDim.new(0, 3)
    oppStaminaCorner.Parent = opponentStaminaBar
    
    -- ============================================
    -- RIGHT SIDE CONTROLS DISPLAY
    -- ============================================
    
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "Controls"
    controlsFrame.Size = UDim2.new(0, 120, 0, 180)
    controlsFrame.Position = UDim2.new(1, -140, 0.5, -90)
    controlsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    controlsFrame.BackgroundTransparency = 0.6
    controlsFrame.BorderSizePixel = 0
    controlsFrame.Parent = fightingGui
    
    local controlsCorner = Instance.new("UICorner")
    controlsCorner.CornerRadius = UDim.new(0, 8)
    controlsCorner.Parent = controlsFrame
    
    -- Control rows
    local controls = {
        {key = "LMB", action = "Attack", color = Color3.fromRGB(255, 150, 50)},
        {key = "RMB", action = "Heavy", color = Color3.fromRGB(255, 100, 100)},
        {key = "F", action = "Block", color = Color3.fromRGB(100, 150, 255)},
        {key = "SPACE", action = "Dodge", color = Color3.fromRGB(100, 255, 150)},
    }
    
    for i, ctrl in ipairs(controls) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -10, 0, 35)
        row.Position = UDim2.new(0, 5, 0, 5 + (i-1) * 40)
        row.BackgroundTransparency = 1
        row.Parent = controlsFrame
        
        local keyLabel = Instance.new("TextLabel")
        keyLabel.Size = UDim2.new(0, 50, 1, 0)
        keyLabel.BackgroundColor3 = ctrl.color
        keyLabel.BackgroundTransparency = 0.3
        keyLabel.Font = Enum.Font.GothamBold
        keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        keyLabel.TextSize = 12
        keyLabel.Text = ctrl.key
        keyLabel.Parent = row
        
        local keyCorner = Instance.new("UICorner")
        keyCorner.CornerRadius = UDim.new(0, 4)
        keyCorner.Parent = keyLabel
        
        local actionLabel = Instance.new("TextLabel")
        actionLabel.Size = UDim2.new(0, 60, 1, 0)
        actionLabel.Position = UDim2.new(0, 55, 0, 0)
        actionLabel.BackgroundTransparency = 1
        actionLabel.Font = Enum.Font.GothamMedium
        actionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        actionLabel.TextSize = 14
        actionLabel.TextXAlignment = Enum.TextXAlignment.Left
        actionLabel.Text = ctrl.action
        actionLabel.Parent = row
    end
    
    -- ============================================
    -- RESULT SCREEN
    -- ============================================
    
    resultScreen = Instance.new("Frame")
    resultScreen.Name = "ResultScreen"
    resultScreen.Size = UDim2.new(1, 0, 1, 0)
    resultScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    resultScreen.BackgroundTransparency = 0.5
    resultScreen.BorderSizePixel = 0
    resultScreen.Visible = false
    resultScreen.Parent = fightingGui
    
    local resultContainer = Instance.new("Frame")
    resultContainer.Name = "Container"
    resultContainer.Size = UDim2.new(0, 500, 0, 400)
    resultContainer.Position = UDim2.new(0.5, -250, 0.5, -200)
    resultContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    resultContainer.BorderSizePixel = 0
    resultContainer.Parent = resultScreen
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 20)
    containerCorner.Parent = resultContainer
    
    -- Result title
    local resultTitle = Instance.new("TextLabel")
    resultTitle.Name = "Title"
    resultTitle.Size = UDim2.new(1, 0, 0, 80)
    resultTitle.Position = UDim2.new(0, 0, 0, 20)
    resultTitle.BackgroundTransparency = 1
    resultTitle.Font = Enum.Font.GothamBlack
    resultTitle.TextColor3 = Color3.fromRGB(100, 255, 100)
    resultTitle.TextSize = 48
    resultTitle.Text = "YOU WIN!"
    resultTitle.Parent = resultContainer
    
    -- Score label
    local scoreText = Instance.new("TextLabel")
    scoreText.Name = "Score"
    scoreText.Size = UDim2.new(1, 0, 0, 40)
    scoreText.Position = UDim2.new(0, 0, 0, 100)
    scoreText.BackgroundTransparency = 1
    scoreText.Font = Enum.Font.GothamBold
    scoreText.TextColor3 = Color3.fromRGB(100, 200, 255)
    scoreText.TextSize = 28
    scoreText.Text = "Final Score: 2 - 0"
    scoreText.Parent = resultContainer
    
    -- Stats container
    local statsContainer = Instance.new("Frame")
    statsContainer.Name = "Stats"
    statsContainer.Size = UDim2.new(0.8, 0, 0, 130)
    statsContainer.Position = UDim2.new(0.1, 0, 0, 150)
    statsContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    statsContainer.BorderSizePixel = 0
    statsContainer.Parent = resultContainer
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 12)
    statsCorner.Parent = statsContainer
    
    -- Stats labels
    local function createStatRow(name, yPos)
        local row = Instance.new("TextLabel")
        row.Name = name
        row.Size = UDim2.new(1, -20, 0, 25)
        row.Position = UDim2.new(0, 10, 0, yPos)
        row.BackgroundTransparency = 1
        row.Font = Enum.Font.GothamMedium
        row.TextColor3 = Color3.fromRGB(200, 200, 200)
        row.TextSize = 16
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.Text = name .. ": 0"
        row.Parent = statsContainer
        return row
    end
    
    createStatRow("Total Hits", 10)
    createStatRow("Successful Blocks", 35)
    createStatRow("Total Damage", 60)
    createStatRow("Rounds Won", 85)
    
    -- Continue button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "ContinueButton"
    closeButton.Size = UDim2.new(0.7, 0, 0, 50)
    closeButton.Position = UDim2.new(0.15, 0, 0, 320)
    closeButton.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
    closeButton.BorderSizePixel = 0
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 20
    closeButton.Text = "CONTINUE"
    closeButton.Parent = resultContainer
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 12)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        hideResultScreen()
    end)
    
    -- ============================================
    -- BIG CENTER TEXT (for announcements)
    -- ============================================
    
    local centerText = Instance.new("TextLabel")
    centerText.Name = "CenterText"
    centerText.Size = UDim2.new(1, 0, 0, 200)
    centerText.Position = UDim2.new(0, 0, 0.35, 0)
    centerText.BackgroundTransparency = 1
    centerText.Font = Enum.Font.GothamBlack
    centerText.TextColor3 = Color3.fromRGB(255, 255, 255)
    centerText.TextSize = 120
    centerText.Text = ""
    centerText.TextStrokeTransparency = 0
    centerText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    centerText.Visible = false
    centerText.ZIndex = 100
    centerText.Parent = fightingGui
    
    print("🎨 [FightingUI] UI Created")
end

-- ============================================
-- BIG TEXT ANNOUNCEMENT FUNCTIONS
-- ============================================

local function showBigText(text, color, duration, size)
    if not fightingGui then return end
    
    local centerText = fightingGui:FindFirstChild("CenterText")
    if not centerText then return end
    
    centerText.Text = text
    centerText.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    centerText.TextSize = 0
    centerText.TextTransparency = 0
    centerText.TextStrokeTransparency = 0
    centerText.Visible = true
    
    local targetSize = size or 120
    
    -- Pop in animation
    TweenService:Create(centerText, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        TextSize = targetSize
    }):Play()
    
    -- Fade out after duration
    task.delay(duration or 1, function()
        TweenService:Create(centerText, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            TextTransparency = 1,
            TextStrokeTransparency = 1,
            TextSize = targetSize * 1.2
        }):Play()
        
        task.delay(0.3, function()
            centerText.Visible = false
        end)
    end)
end

local function showRoundAnnouncement(roundNumber)
    -- Show "ROUND X"
    showBigText("ROUND " .. roundNumber, Color3.fromRGB(255, 220, 100), 1.2, 100)
    
    -- Countdown after round text
    task.delay(1.5, function()
        showBigText("3", Color3.fromRGB(255, 255, 255), 0.8, 150)
    end)
    
    task.delay(2.5, function()
        showBigText("2", Color3.fromRGB(255, 255, 255), 0.8, 150)
    end)
    
    task.delay(3.5, function()
        showBigText("1", Color3.fromRGB(255, 255, 255), 0.8, 150)
    end)
    
    task.delay(4.5, function()
        showBigText("FIGHT!", Color3.fromRGB(255, 100, 100), 1.0, 130)
    end)
end

local function showRoundEnded(roundNumber, winnerName)
    local text = "ROUND " .. roundNumber .. " ENDED"
    showBigText(text, Color3.fromRGB(200, 200, 200), 2.0, 80)
end

-- ============================================
-- UI UPDATE FUNCTIONS
-- ============================================

local function updateHealthBar(bar, health, maxHealth, isOpponent)
    local percent = math.clamp(health / maxHealth, 0, 1)
    
    if isOpponent then
        TweenService:Create(bar, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Size = UDim2.new(percent, 0, 1, 0)
        }):Play()
    else
        TweenService:Create(bar, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Size = UDim2.new(percent, 0, 1, 0)
        }):Play()
    end
    
    -- Color change based on health
    local healthColor
    if percent > 0.6 then
        healthColor = Color3.fromRGB(80, 200, 80)
    elseif percent > 0.3 then
        healthColor = Color3.fromRGB(220, 180, 50)
    else
        healthColor = Color3.fromRGB(220, 80, 80)
    end
    
    if not isOpponent then
        TweenService:Create(bar, TweenInfo.new(0.2), {
            BackgroundColor3 = healthColor
        }):Play()
    end
end

local function updateStaminaBar(bar, stamina, maxStamina)
    local percent = math.clamp(stamina / maxStamina, 0, 1)
    
    TweenService:Create(bar, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
        Size = UDim2.new(percent, 0, 1, 0)
    }):Play()
end

local function updateRoundIndicator()
    if roundLabel then
        roundLabel.Text = "ROUND " .. currentRound
    end
end

local function updateTimer(seconds)
    if timerLabel then
        timerLabel.Text = tostring(math.floor(seconds))
    end
end

local function showResultScreen(isWinner, myScore, opponentScore, stats)
    if not resultScreen then return end
    
    local container = resultScreen:FindFirstChild("Container")
    if not container then return end
    
    local title = container:FindFirstChild("Title")
    if title then
        if isWinner then
            title.Text = "YOU WIN!"
            title.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            title.Text = "YOU LOSE"
            title.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end
    
    local score = container:FindFirstChild("Score")
    if score then
        score.Text = "Final Score: " .. myScore .. " - " .. opponentScore
    end
    
    local statsFrame = container:FindFirstChild("Stats")
    if statsFrame and stats then
        local hits = statsFrame:FindFirstChild("Total Hits")
        if hits then hits.Text = "Total Hits: " .. (stats.Hits or 0) end
        
        local blocks = statsFrame:FindFirstChild("Successful Blocks")
        if blocks then blocks.Text = "Successful Blocks: " .. (stats.Blocks or 0) end
        
        local damage = statsFrame:FindFirstChild("Total Damage")
        if damage then damage.Text = "Total Damage: " .. (stats.DamageDealt or 0) end
        
        local rounds = statsFrame:FindFirstChild("Rounds Won")
        if rounds then rounds.Text = "Rounds Won: " .. myScore end
    end
    
    resultScreen.Visible = true
    
    -- Animate in
    container.Position = UDim2.new(0.5, -250, -0.5, 0)
    TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -250, 0.5, -200)
    }):Play()
end

hideResultScreen = function()
    if not resultScreen then return end
    
    local container = resultScreen:FindFirstChild("Container")
    if container then
        TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -250, 1.5, 0)
        }):Play()
    end
    
    task.delay(0.3, function()
        resultScreen.Visible = false
        fightingGui.Enabled = false
    end)
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

StartMatchEvent.OnClientEvent:Connect(function(data)
    opponentName = data.OpponentName
    totalRounds = data.TotalRounds
    mySide = data.Side
    myWins = 0
    opponentWins = 0
    currentRound = 0
    
    createFightingUI()
    
    if opponentNameLabel then
        opponentNameLabel.Text = opponentName
    end
    
    -- Set opponent avatar
    task.spawn(function()
        local opponent = Players:FindFirstChild(opponentName)
        if opponent and fightingGui then
            local topBar = fightingGui:FindFirstChild("TopBar")
            if topBar then
                local oppStats = topBar:FindFirstChild("OpponentStats")
                if oppStats then
                    local avatarFrame = oppStats:FindFirstChild("AvatarFrame")
                    if avatarFrame then
                        local avatar = avatarFrame:FindFirstChild("Avatar")
                        if avatar then
                            local success, image = pcall(function()
                                return Players:GetUserThumbnailAsync(opponent.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                            end)
                            if success then
                                avatar.Image = image
                            end
                        end
                    end
                end
            end
        end
    end)
    
    fightingGui.Enabled = true
    
    -- Start round timer
    roundTimer = FightingConfig.Match.RoundTimeLimit
    
    if timerConnection then
        timerConnection:Disconnect()
    end
    
    timerConnection = task.spawn(function()
        while fightingGui.Enabled and roundTimer > 0 do
            updateTimer(roundTimer)
            task.wait(1)
            roundTimer = roundTimer - 1
        end
    end)
end)

RoundStartEvent.OnClientEvent:Connect(function(data)
    currentRound = data.RoundNumber
    myWins = mySide == "A" and data.PlayerAWins or data.PlayerBWins
    opponentWins = mySide == "A" and data.PlayerBWins or data.PlayerAWins
    
    updateRoundIndicator()
    
    -- Show round announcement with countdown
    showRoundAnnouncement(currentRound)
    
    -- Reset timer
    roundTimer = FightingConfig.Match.RoundTimeLimit
    
    -- Reset health bars visual
    if myHealthBar then
        updateHealthBar(myHealthBar, 100, 100, false)
    end
    if opponentHealthBar then
        updateHealthBar(opponentHealthBar, 100, 100, true)
    end
end)

RoundEndEvent.OnClientEvent:Connect(function(data)
    myWins = mySide == "A" and data.PlayerAWins or data.PlayerBWins
    opponentWins = mySide == "A" and data.PlayerBWins or data.PlayerAWins
    
    -- Show round ended announcement
    showRoundEnded(currentRound, data.WinnerName)
end)

EndMatchEvent.OnClientEvent:Connect(function(data)
    -- Stop timer
    if timerConnection then
        task.cancel(timerConnection)
        timerConnection = nil
    end
    
    local isWinner = data.Winner == Player.Name
    local myScore = mySide == "A" and data.PlayerAWins or data.PlayerBWins
    local oppScore = mySide == "A" and data.PlayerBWins or data.PlayerAWins
    
    local myStats = nil
    if data.Stats then
        myStats = mySide == "A" and data.Stats.PlayerA or data.Stats.PlayerB
    end
    
    showResultScreen(isWinner, myScore, oppScore, myStats)
end)

UpdateStatsEvent.OnClientEvent:Connect(function(data)
    local myHealth = mySide == "A" and data.PlayerAHealth or data.PlayerBHealth
    local myStamina = mySide == "A" and data.PlayerAStamina or data.PlayerBStamina
    local oppHealth = mySide == "A" and data.PlayerBHealth or data.PlayerAHealth
    local oppStamina = mySide == "A" and data.PlayerBStamina or data.PlayerAStamina
    
    if myHealthBar then
        updateHealthBar(myHealthBar, myHealth, FightingConfig.Stats.MaxHealth, false)
    end
    if myStaminaBar then
        updateStaminaBar(myStaminaBar, myStamina, FightingConfig.Stats.MaxStamina)
    end
    if opponentHealthBar then
        updateHealthBar(opponentHealthBar, oppHealth, FightingConfig.Stats.MaxHealth, true)
    end
    if opponentStaminaBar then
        updateStaminaBar(opponentStaminaBar, oppStamina, FightingConfig.Stats.MaxStamina)
    end
end)

-- ============================================
-- INITIALIZATION
-- ============================================

print("🎨 [FightingUI] UI System Loaded!")
