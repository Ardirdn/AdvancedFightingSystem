--[[
    DataHandler.lua (Server Module)
    Handles player data saving/loading for Fighting System
    
    Data saved:
    - RoundsWin: Total rounds won
    - MatchWin: Total matches won
    - TotalPlaytime: Total playtime in seconds
]]

local DataHandler = {}

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- DataStore
local FightingDataStore = DataStoreService:GetDataStore("FightingSystem_v1")

-- Local cache for player data
local playerDataCache = {}

-- Session tracking
local sessionStartTimes = {}

-- Default data template
local DEFAULT_DATA = {
    RoundsWin = 0,
    MatchWin = 0,
    TotalPlaytime = 0,
    LastPlayed = 0,
    
    -- Stats per session
    TotalHits = 0,
    TotalBlocks = 0,
    TotalDodges = 0,
    TotalDamageDealt = 0,
    TotalDamageTaken = 0,
    
    -- Title System
    SpecialTitle = "",      -- Admin-given special title
    EquippedTitle = "",     -- Player-selected title
}

-- ============================================
-- CORE FUNCTIONS
-- ============================================

-- Deep copy table
local function deepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = deepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

-- Load player data
function DataHandler.LoadData(player)
    if not player then return nil end
    
    local userId = player.UserId
    local key = "Player_" .. tostring(userId)
    
    -- Check cache first
    if playerDataCache[userId] then
        return playerDataCache[userId]
    end
    
    -- Load from DataStore
    local success, result = pcall(function()
        return FightingDataStore:GetAsync(key)
    end)
    
    if success and result then
        -- Merge with default data to ensure all fields exist
        local data = deepCopy(DEFAULT_DATA)
        for k, v in pairs(result) do
            data[k] = v
        end
        playerDataCache[userId] = data
        print("✅ [DataHandler] Loaded data for", player.Name)
        return data
    else
        -- Return default data
        local data = deepCopy(DEFAULT_DATA)
        playerDataCache[userId] = data
        print("📋 [DataHandler] Created new data for", player.Name)
        return data
    end
end

-- Save player data
function DataHandler.SaveData(player)
    if not player then return false end
    
    local userId = player.UserId
    local key = "Player_" .. tostring(userId)
    local data = playerDataCache[userId]
    
    if not data then return false end
    
    -- Update playtime before saving
    if sessionStartTimes[userId] then
        local sessionTime = os.time() - sessionStartTimes[userId]
        data.TotalPlaytime = data.TotalPlaytime + sessionTime
        sessionStartTimes[userId] = os.time() -- Reset for next save
    end
    
    data.LastPlayed = os.time()
    
    local success, err = pcall(function()
        FightingDataStore:SetAsync(key, data)
    end)
    
    if success then
        print("💾 [DataHandler] Saved data for", player.Name)
        return true
    else
        warn("❌ [DataHandler] Failed to save data for", player.Name, ":", err)
        return false
    end
end

-- Get player data (from cache)
function DataHandler.GetData(player)
    if not player then return nil end
    return playerDataCache[player.UserId]
end

-- ============================================
-- PLAYER STATS SYNC (for client-side reading)
-- ============================================

-- Create IntValue objects in player for client to read
function DataHandler.CreatePlayerStats(player)
    if not player then return end
    
    -- Create PlayerStats folder if not exists
    local statsFolder = player:FindFirstChild("PlayerStats")
    if not statsFolder then
        statsFolder = Instance.new("Folder")
        statsFolder.Name = "PlayerStats"
        statsFolder.Parent = player
    end
    
    -- Create RoundsWin IntValue
    local roundsWin = statsFolder:FindFirstChild("RoundsWin")
    if not roundsWin then
        roundsWin = Instance.new("IntValue")
        roundsWin.Name = "RoundsWin"
        roundsWin.Value = 0
        roundsWin.Parent = statsFolder
    end
    
    -- Create MatchWin IntValue
    local matchWin = statsFolder:FindFirstChild("MatchWin")
    if not matchWin then
        matchWin = Instance.new("IntValue")
        matchWin.Name = "MatchWin"
        matchWin.Value = 0
        matchWin.Parent = statsFolder
    end
    
    -- Sync with data
    local data = DataHandler.GetData(player)
    if data then
        roundsWin.Value = data.RoundsWin or 0
        matchWin.Value = data.MatchWin or 0
    end
    
    return statsFolder
end

-- Update IntValue objects when data changes
function DataHandler.UpdatePlayerStats(player)
    if not player then return end
    
    local statsFolder = player:FindFirstChild("PlayerStats")
    if not statsFolder then
        statsFolder = DataHandler.CreatePlayerStats(player)
    end
    
    local data = DataHandler.GetData(player)
    if not data then return end
    
    local roundsWin = statsFolder:FindFirstChild("RoundsWin")
    if roundsWin then
        roundsWin.Value = data.RoundsWin or 0
    end
    
    local matchWin = statsFolder:FindFirstChild("MatchWin")
    if matchWin then
        matchWin.Value = data.MatchWin or 0
    end
end

-- ============================================
-- STAT UPDATE FUNCTIONS
-- ============================================

-- Add round win
function DataHandler.AddRoundWin(player, count)
    local data = DataHandler.GetData(player)
    if data then
        data.RoundsWin = data.RoundsWin + (count or 1)
        -- Update OrderedDataStore for leaderboard
        task.spawn(function()
            DataHandler.UpdateLeaderboard(player, "RoundsWin", data.RoundsWin)
        end)
        
        -- Update IntValue for client-side reading
        DataHandler.UpdatePlayerStats(player)
        
        -- Notify TitleServer to update tier title
        task.spawn(function()
            if _G.TitleServer then
                _G.TitleServer:UpdateTierTitle(player)
            end
        end)
        
        return data.RoundsWin
    end
    return 0
end

-- Add match win
function DataHandler.AddMatchWin(player, count)
    local data = DataHandler.GetData(player)
    if data then
        data.MatchWin = data.MatchWin + (count or 1)
        -- Update OrderedDataStore for leaderboard
        task.spawn(function()
            DataHandler.UpdateLeaderboard(player, "MatchWin", data.MatchWin)
        end)
        
        -- Update IntValue for client-side reading
        DataHandler.UpdatePlayerStats(player)
        
        return data.MatchWin
    end
    return 0
end

-- Add hit count
function DataHandler.AddHit(player, count)
    local data = DataHandler.GetData(player)
    if data then
        data.TotalHits = data.TotalHits + (count or 1)
        return data.TotalHits
    end
    return 0
end

-- Add block count
function DataHandler.AddBlock(player, count)
    local data = DataHandler.GetData(player)
    if data then
        data.TotalBlocks = data.TotalBlocks + (count or 1)
        return data.TotalBlocks
    end
    return 0
end

-- Add dodge count
function DataHandler.AddDodge(player, count)
    local data = DataHandler.GetData(player)
    if data then
        data.TotalDodges = data.TotalDodges + (count or 1)
        return data.TotalDodges
    end
    return 0
end

-- Add damage dealt
function DataHandler.AddDamageDealt(player, amount)
    local data = DataHandler.GetData(player)
    if data then
        data.TotalDamageDealt = data.TotalDamageDealt + amount
        return data.TotalDamageDealt
    end
    return 0
end

-- Add damage taken
function DataHandler.AddDamageTaken(player, amount)
    local data = DataHandler.GetData(player)
    if data then
        data.TotalDamageTaken = data.TotalDamageTaken + amount
        return data.TotalDamageTaken
    end
    return 0
end

-- ============================================
-- LEADERBOARD FUNCTIONS (using OrderedDataStore)
-- ============================================

-- OrderedDataStores for leaderboard
local MatchWinLeaderboard = DataStoreService:GetOrderedDataStore("FightingLeaderboard_MatchWin_v1")
local RoundsWinLeaderboard = DataStoreService:GetOrderedDataStore("FightingLeaderboard_RoundsWin_v1")

-- Update ordered datastore when stat changes
function DataHandler.UpdateLeaderboard(player, statName, value)
    if not player or not statName then return end
    
    local success, err = pcall(function()
        if statName == "MatchWin" then
            MatchWinLeaderboard:SetAsync(tostring(player.UserId), value)
        elseif statName == "RoundsWin" then
            RoundsWinLeaderboard:SetAsync(tostring(player.UserId), value)
        end
    end)
    
    if not success then
        warn("❌ [DataHandler] Failed to update leaderboard:", err)
    end
end

-- Get top players by stat (from OrderedDataStore - shows all players, not just online)
function DataHandler.GetTopPlayers(statName, count)
    count = count or 10
    
    local leaderboard = {}
    
    -- Get OrderedDataStore based on stat
    local orderedStore
    if statName == "MatchWin" then
        orderedStore = MatchWinLeaderboard
    elseif statName == "RoundsWin" then
        orderedStore = RoundsWinLeaderboard
    else
        -- Fallback to cache for other stats
        for userId, data in pairs(playerDataCache) do
            local player = Players:GetPlayerByUserId(userId)
            if player then
                table.insert(leaderboard, {
                    UserId = userId,
                    Name = player.Name,
                    Value = data[statName] or 0,
                })
            end
        end
        table.sort(leaderboard, function(a, b) return a.Value > b.Value end)
        local result = {}
        for i = 1, math.min(count, #leaderboard) do result[i] = leaderboard[i] end
        return result
    end
    
    -- Get from OrderedDataStore
    local success, pages = pcall(function()
        return orderedStore:GetSortedAsync(false, count)
    end)
    
    if success and pages then
        local data = pages:GetCurrentPage()
        for rank, entry in ipairs(data) do
            local userId = tonumber(entry.key)
            local value = entry.value
            
            -- Try to get player name
            local playerName = "Player_" .. tostring(userId)
            local player = Players:GetPlayerByUserId(userId)
            if player then
                playerName = player.Name
            else
                -- Try to get username from cache or use UserId
                local success2, name = pcall(function()
                    return Players:GetNameFromUserIdAsync(userId)
                end)
                if success2 and name then
                    playerName = name
                end
            end
            
            table.insert(leaderboard, {
                UserId = userId,
                Name = playerName,
                Value = value,
            })
        end
    else
        warn("❌ [DataHandler] Failed to get leaderboard data")
    end
    
    return leaderboard
end

-- ============================================
-- SESSION TRACKING
-- ============================================

-- Start session tracking
function DataHandler.StartSession(player)
    if not player then return end
    sessionStartTimes[player.UserId] = os.time()
end

-- Get session playtime
function DataHandler.GetSessionPlaytime(player)
    if not player or not sessionStartTimes[player.UserId] then return 0 end
    return os.time() - sessionStartTimes[player.UserId]
end

-- Get total playtime (including current session)
function DataHandler.GetTotalPlaytime(player)
    local data = DataHandler.GetData(player)
    if not data then return 0 end
    
    local sessionTime = DataHandler.GetSessionPlaytime(player)
    return data.TotalPlaytime + sessionTime
end

-- ============================================
-- PLAYER EVENTS
-- ============================================

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
    DataHandler.LoadData(player)
    DataHandler.StartSession(player)
    
    -- Create PlayerStats IntValue objects for client to read
    task.delay(1, function()
        if player and player.Parent then
            DataHandler.CreatePlayerStats(player)
        end
    end)
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
    DataHandler.SaveData(player)
    
    -- Cleanup cache
    playerDataCache[player.UserId] = nil
    sessionStartTimes[player.UserId] = nil
end)

-- Auto-save periodically
task.spawn(function()
    while true do
        task.wait(300) -- Save every 5 minutes
        
        for _, player in ipairs(Players:GetPlayers()) do
            DataHandler.SaveData(player)
        end
        
        print("💾 [DataHandler] Auto-saved all player data")
    end
end)

-- Save all on server shutdown
game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        DataHandler.SaveData(player)
    end
    print("💾 [DataHandler] Saved all data on shutdown")
end)

-- Load data for existing players (if script loads late)
for _, player in ipairs(Players:GetPlayers()) do
    if not playerDataCache[player.UserId] then
        DataHandler.LoadData(player)
        DataHandler.StartSession(player)
    end
    
    -- Create PlayerStats for existing players
    task.spawn(function()
        task.wait(1)
        if player and player.Parent then
            DataHandler.CreatePlayerStats(player)
        end
    end)
end

return DataHandler
