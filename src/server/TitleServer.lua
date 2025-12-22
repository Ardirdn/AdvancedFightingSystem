--[[
    TitleServer.lua (Server Module)
    Handles title system logic on the server
    
    Features:
    - Auto-assign tier titles based on RoundsWin
    - Special titles given by admin
    - Broadcast title changes to all clients
    - Save/Load title data
]]

local TitleServer = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for modules
local DataHandler = require(script.Parent.DataHandler)

-- Try to get TitleConfig from shared (Modules folder)
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
    warn("⚠️ [TitleServer] TitleConfig not found in ReplicatedStorage.Modules")
    return false
end

-- Create RemoteEvents/Functions for title system
local remoteFolder = ReplicatedStorage:FindFirstChild("TitleRemotes")
if not remoteFolder then
    remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "TitleRemotes"
    remoteFolder.Parent = ReplicatedStorage
end

-- Remote to update a player's title on all clients
local UpdateTitleEvent = remoteFolder:FindFirstChild("UpdateTitle") or Instance.new("RemoteEvent")
UpdateTitleEvent.Name = "UpdateTitle"
UpdateTitleEvent.Parent = remoteFolder

-- Remote for clients to request title data
local GetTitleFunc = remoteFolder:FindFirstChild("GetTitle") or Instance.new("RemoteFunction")
GetTitleFunc.Name = "GetTitle"
GetTitleFunc.Parent = remoteFolder

-- Remote to broadcast title to all clients (when someone's title changes)
local BroadcastTitleEvent = remoteFolder:FindFirstChild("BroadcastTitle") or Instance.new("RemoteEvent")
BroadcastTitleEvent.Name = "BroadcastTitle"
BroadcastTitleEvent.Parent = remoteFolder

-- Player title cache (for quick access)
local playerTitles = {}

-- ============================================
-- CORE FUNCTIONS
-- ============================================

-- Get player's earned tier title based on RoundsWin
function TitleServer:GetEarnedTierTitle(player)
    if not TitleConfig then
        if not loadTitleConfig() then
            return "Rookie"
        end
    end
    
    local data = DataHandler.GetData(player)
    if not data then return "Rookie" end
    
    local roundsWin = data.RoundsWin or 0
    local tierData = TitleConfig.GetTierByRoundsWin(roundsWin)
    
    return tierData.Name
end

-- Get player's current active title (special or tier)
function TitleServer:GetPlayerTitle(player)
    if not player then return "Rookie" end
    
    -- Check cache first
    if playerTitles[player.UserId] then
        return playerTitles[player.UserId]
    end
    
    local data = DataHandler.GetData(player)
    if not data then return "Rookie" end
    
    -- Priority: SpecialTitle > Equipped Title > Tier Title
    if data.SpecialTitle and data.SpecialTitle ~= "" then
        return data.SpecialTitle
    end
    
    if data.EquippedTitle and data.EquippedTitle ~= "" then
        return data.EquippedTitle
    end
    
    -- Get tier title based on rounds won
    return self:GetEarnedTierTitle(player)
end

-- Set player's special title (admin given)
function TitleServer:SetSpecialTitle(player, titleName)
    if not player then return false end
    
    local data = DataHandler.GetData(player)
    if not data then return false end
    
    -- Validate title exists
    if titleName and titleName ~= "" then
        if not TitleConfig then loadTitleConfig() end
        
        local titleData = TitleConfig and TitleConfig.GetTitleData(titleName)
        if not titleData then
            warn("[TitleServer] Invalid title:", titleName)
            return false
        end
    end
    
    -- Update data
    data.SpecialTitle = titleName or ""
    playerTitles[player.UserId] = titleName or self:GetEarnedTierTitle(player)
    
    -- Save data
    DataHandler.SaveData(player)
    
    -- Broadcast to all clients
    self:BroadcastTitle(player)
    
    print("🏆 [TitleServer] Set special title for", player.Name, ":", titleName or "(removed)")
    return true
end

-- Set player's equipped title (any title they have access to)
function TitleServer:SetEquippedTitle(player, titleName)
    if not player then return false end
    
    local data = DataHandler.GetData(player)
    if not data then return false end
    
    -- Update data
    data.EquippedTitle = titleName or ""
    
    if not data.SpecialTitle or data.SpecialTitle == "" then
        playerTitles[player.UserId] = titleName or self:GetEarnedTierTitle(player)
    end
    
    DataHandler.SaveData(player)
    self:BroadcastTitle(player)
    
    print("🏆 [TitleServer] Set equipped title for", player.Name, ":", titleName or "(default tier)")
    return true
end

-- Remove player's special title
function TitleServer:RemoveSpecialTitle(player)
    return self:SetSpecialTitle(player, nil)
end

-- Update player's tier title when they win rounds
function TitleServer:UpdateTierTitle(player)
    if not player then return end
    
    local data = DataHandler.GetData(player)
    if not data then return end
    
    -- Only update if no special title
    if data.SpecialTitle and data.SpecialTitle ~= "" then
        return
    end
    
    local newTierTitle = self:GetEarnedTierTitle(player)
    local currentTitle = playerTitles[player.UserId]
    
    -- Check if tier changed
    if currentTitle ~= newTierTitle then
        playerTitles[player.UserId] = newTierTitle
        self:BroadcastTitle(player)
        
        -- Notify player of new title
        if not TitleConfig then loadTitleConfig() end
        local titleData = TitleConfig and TitleConfig.GetTitleData(newTierTitle)
        if titleData then
            print("🎉 [TitleServer]", player.Name, "achieved new title:", titleData.DisplayName)
        end
    end
end

-- Broadcast player's title to all clients
function TitleServer:BroadcastTitle(player)
    if not player or not player.Parent then return end
    
    local titleName = self:GetPlayerTitle(player)
    
    -- Fire to all clients
    BroadcastTitleEvent:FireAllClients(player, titleName)
end

-- Initialize player on join
function TitleServer:InitializePlayer(player)
    if not TitleConfig then loadTitleConfig() end
    
    local data = DataHandler.GetData(player)
    if not data then
        -- Wait for data to load
        task.wait(2)
        data = DataHandler.GetData(player)
    end
    
    -- Ensure title fields exist
    if data then
        if data.SpecialTitle == nil then
            data.SpecialTitle = ""
        end
        if data.EquippedTitle == nil then
            data.EquippedTitle = ""
        end
    end
    
    -- Auto-set Owner/Admin titles
    if TitleConfig then
        if TitleConfig.IsOwner(player.UserId) then
            self:SetSpecialTitle(player, "Owner")
        elseif TitleConfig.IsAdmin(player.UserId) then
            self:SetSpecialTitle(player, "Admin")
        end
    end
    
    -- Cache current title
    playerTitles[player.UserId] = self:GetPlayerTitle(player)
    
    -- Broadcast to all clients
    task.delay(2, function()
        if player and player.Parent then
            self:BroadcastTitle(player)
        end
    end)
    
    print("🏆 [TitleServer] Initialized title for", player.Name, ":", playerTitles[player.UserId])
end

-- Cleanup when player leaves
function TitleServer:CleanupPlayer(player)
    playerTitles[player.UserId] = nil
end

-- ============================================
-- REMOTE HANDLERS
-- ============================================

-- Client requests title for a specific player
GetTitleFunc.OnServerInvoke = function(caller, targetPlayer)
    if not targetPlayer or not targetPlayer:IsA("Player") then
        return "Rookie"
    end
    return TitleServer:GetPlayerTitle(targetPlayer)
end

-- ============================================
-- EVENT CONNECTIONS
-- ============================================

Players.PlayerAdded:Connect(function(player)
    -- Wait a bit for data to load
    task.delay(3, function()
        if player and player.Parent then
            TitleServer:InitializePlayer(player)
        end
    end)
    
    -- Also handle character respawn
    player.CharacterAdded:Connect(function()
        task.delay(1, function()
            if player and player.Parent then
                TitleServer:BroadcastTitle(player)
            end
        end)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    TitleServer:CleanupPlayer(player)
end)

-- Initialize for existing players (if script loads late)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        task.wait(1)
        if player and player.Parent then
            TitleServer:InitializePlayer(player)
        end
    end)
end

-- Load config
task.spawn(function()
    loadTitleConfig()
end)

-- ============================================
-- EXPOSE TO OTHER SCRIPTS
-- ============================================
_G.TitleServer = TitleServer

return TitleServer
