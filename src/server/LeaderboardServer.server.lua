--[[
    LeaderboardServer.server.lua
    Handles leaderboard display in workspace
    
    Setup: Create a folder called "Leaderboard" in workspace with SurfaceGuis on Parts
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Wait for modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local FightingConfig = require(Modules:WaitForChild("FightingConfig"))
local DataHandler = require(script.Parent:WaitForChild("DataHandler"))

-- ============================================
-- LEADERBOARD SETUP
-- ============================================

local LeaderboardFolder = workspace:FindFirstChild("Leaderboard")

-- Template for leaderboard entry
local function createEntryTemplate()
    local frame = Instance.new("Frame")
    frame.Name = "EntryTemplate"
    frame.Size = UDim2.new(1, -10, 0, 45)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.5  -- Semi-transparent
    frame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local rank = Instance.new("TextLabel")
    rank.Name = "Rank"
    rank.Size = UDim2.new(0, 50, 1, 0)
    rank.Position = UDim2.new(0, 8, 0, 0)
    rank.BackgroundTransparency = 1
    rank.Font = Enum.Font.GothamBlack
    rank.TextColor3 = Color3.fromRGB(255, 200, 50)
    rank.TextSize = 24  -- Larger
    rank.Text = "#1"
    rank.Parent = frame
    
    local name = Instance.new("TextLabel")
    name.Name = "PlayerName"
    name.Size = UDim2.new(0.5, -60, 1, 0)
    name.Position = UDim2.new(0, 60, 0, 0)
    name.BackgroundTransparency = 1
    name.Font = Enum.Font.GothamBold
    name.TextColor3 = Color3.fromRGB(255, 255, 255)
    name.TextSize = 20  -- Larger
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Text = "PlayerName"
    name.Parent = frame
    
    local value = Instance.new("TextLabel")
    value.Name = "Value"
    value.Size = UDim2.new(0.3, 0, 1, 0)
    value.Position = UDim2.new(0.7, 0, 0, 0)
    value.BackgroundTransparency = 1
    value.Font = Enum.Font.GothamBlack
    value.TextColor3 = Color3.fromRGB(100, 255, 150)
    value.TextSize = 22  -- Larger
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.Text = "0"
    value.Parent = frame
    
    return frame
end

-- Create leaderboard UI on a SurfaceGui
local function setupLeaderboardGui(surfaceGui, title, statName)
    -- Clear existing
    for _, child in ipairs(surfaceGui:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Main container (TRANSPARENT)
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1  -- Fully transparent
    container.BorderSizePixel = 0
    container.Parent = surfaceGui
    
    -- Title (LARGER)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 60)
    titleLabel.Position = UDim2.new(0, 0, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
    titleLabel.TextSize = 32  -- Much larger
    titleLabel.TextStrokeTransparency = 0.5  -- Add stroke for visibility
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.Text = title
    titleLabel.Parent = container
    
    -- Divider
    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Size = UDim2.new(0.9, 0, 0, 3)
    divider.Position = UDim2.new(0.05, 0, 0, 65)
    divider.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
    divider.BackgroundTransparency = 0.3
    divider.BorderSizePixel = 0
    divider.Parent = container
    
    -- Entries container
    local entriesFrame = Instance.new("ScrollingFrame")
    entriesFrame.Name = "Entries"
    entriesFrame.Size = UDim2.new(0.95, 0, 1, -85)
    entriesFrame.Position = UDim2.new(0.025, 0, 0, 75)
    entriesFrame.BackgroundTransparency = 1
    entriesFrame.BorderSizePixel = 0
    entriesFrame.ScrollBarThickness = 6
    entriesFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 50)
    entriesFrame.ScrollBarImageTransparency = 0.3
    entriesFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    entriesFrame.Parent = container
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 8)  -- More spacing
    listLayout.Parent = entriesFrame
    
    -- Store stat name for updates
    container:SetAttribute("StatName", statName)
    
    return entriesFrame
end

-- Update leaderboard entries
local function updateLeaderboard(entriesFrame, statName)
    if not entriesFrame then return end
    
    -- Get data
    local leaderboardData = DataHandler.GetTopPlayers(statName, FightingConfig.Leaderboard.MaxEntries)
    
    -- Clear existing entries (except UIListLayout)
    for _, child in ipairs(entriesFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Create entries
    for i, entry in ipairs(leaderboardData) do
        local entryFrame = createEntryTemplate()
        entryFrame.Name = "Entry_" .. i
        entryFrame.LayoutOrder = i
        
        local rankLabel = entryFrame:FindFirstChild("Rank")
        local nameLabel = entryFrame:FindFirstChild("PlayerName")
        local valueLabel = entryFrame:FindFirstChild("Value")
        
        if rankLabel then
            rankLabel.Text = "#" .. i
            
            -- Top 3 special colors
            if i == 1 then
                rankLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
            elseif i == 2 then
                rankLabel.TextColor3 = Color3.fromRGB(192, 192, 192) -- Silver
            elseif i == 3 then
                rankLabel.TextColor3 = Color3.fromRGB(205, 127, 50) -- Bronze
            end
        end
        
        if nameLabel then
            nameLabel.Text = entry.Name
        end
        
        if valueLabel then
            if statName == "TotalPlaytime" then
                -- Format playtime as hours:minutes
                local hours = math.floor(entry.Value / 3600)
                local minutes = math.floor((entry.Value % 3600) / 60)
                valueLabel.Text = string.format("%dh %dm", hours, minutes)
            else
                valueLabel.Text = tostring(entry.Value)
            end
        end
        
        entryFrame.Parent = entriesFrame
    end
    
    -- Update canvas size
    local listLayout = entriesFrame:FindFirstChild("UIListLayout")
    if listLayout then
        entriesFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end
end

-- ============================================
-- INITIALIZATION
-- ============================================

local leaderboards = {}

local function initializeLeaderboards()
    if not LeaderboardFolder then
        warn("⚠️ [LeaderboardServer] No 'Leaderboard' folder found in workspace!")
        print([[
========================================
LEADERBOARD SETUP GUIDE:
========================================

1. Buat folder di workspace bernama "Leaderboard"

2. Didalam folder tersebut, buat 3 Part:
   - "MatchWinsBoard"
   - "RoundsWinsBoard" 
   - "PlaytimeBoard"

3. Untuk setiap Part, tambahkan SurfaceGui dengan properties:
   - Name: "LeaderboardGui"
   - Face: Front (atau sesuai kebutuhan)
   - SizingMode: PixelsPerStud
   - PixelsPerStud: 50 (optional, adjust as needed)

4. Pastikan Part cukup besar untuk menampilkan leaderboard
   Contoh size: Vector3.new(8, 6, 0.5)

5. Atur posisi Part sesuai keinginan di map hangout

========================================
        ]])
        return
    end
    
    -- Find and setup each leaderboard type
    local boardConfigs = {
        { PartName = "MatchWinsBoard", Title = "🏆 TOP MATCH WINS", StatName = "MatchWin" },
        { PartName = "RoundsWinsBoard", Title = "🥊 TOP ROUNDS WINS", StatName = "RoundsWin" },
        { PartName = "PlaytimeBoard", Title = "⏱️ TOP PLAYTIME", StatName = "TotalPlaytime" },
    }
    
    for _, config in ipairs(boardConfigs) do
        local boardPart = LeaderboardFolder:FindFirstChild(config.PartName)
        if boardPart then
            local surfaceGui = boardPart:FindFirstChild("LeaderboardGui")
            if not surfaceGui then
                -- Create SurfaceGui if not exists
                surfaceGui = Instance.new("SurfaceGui")
                surfaceGui.Name = "LeaderboardGui"
                surfaceGui.Face = Enum.NormalId.Front
                surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
                surfaceGui.PixelsPerStud = 50
                surfaceGui.Parent = boardPart
            end
            
            local entriesFrame = setupLeaderboardGui(surfaceGui, config.Title, config.StatName)
            leaderboards[config.StatName] = entriesFrame
            
            print("✅ [LeaderboardServer] Setup", config.PartName)
        else
            warn("⚠️ [LeaderboardServer]", config.PartName, "not found in Leaderboard folder")
        end
    end
end

-- ============================================
-- UPDATE LOOP
-- ============================================

local function updateAllLeaderboards()
    for statName, entriesFrame in pairs(leaderboards) do
        updateLeaderboard(entriesFrame, statName)
    end
end

-- Initialize
initializeLeaderboards()
updateAllLeaderboards()

-- Periodic update
task.spawn(function()
    while true do
        task.wait(FightingConfig.Leaderboard.RefreshRate)
        updateAllLeaderboards()
        print("🔄 [LeaderboardServer] Updated all leaderboards")
    end
end)

-- Update when player data changes (immediate feedback)
Players.PlayerAdded:Connect(function(player)
    task.wait(2) -- Wait for data to load
    updateAllLeaderboards()
end)

print("📊 [LeaderboardServer] Leaderboard System Loaded!")
