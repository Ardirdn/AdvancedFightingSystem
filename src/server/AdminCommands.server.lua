--[[
    AdminCommands.server.lua
    Server script for admin chat commands
    
    Available Commands (Admin Only):
    =====================================
    
    TITLE COMMANDS:
    - !settitle [player] [titlename]      : Set player's special title
    - !removetitle [player]               : Remove player's special title
    - !listtitles                         : List all available titles
    
    TELEPORT COMMANDS:
    - !tp [player]                        : Teleport yourself to target player
    - !tphere [player]                    : Teleport target player to you
    - !tpall                              : Teleport all players to you
    
    PLAYER MANAGEMENT:
    - !kick [player] [reason]             : Kick player from server
    - !respawn [player]                   : Respawn player
    
    DATA MANAGEMENT:
    - !resetdata [player] [stat]          : Reset specific stat (RoundsWin, MatchWin, etc.)
    - !resetalldata [player]              : Reset ALL data for player
    - !setstat [player] [stat] [value]    : Set specific stat value
    - !viewdata [player]                  : View player's current data
    - !clearleaderboard [type]            : Clear leaderboard data (RoundsWin/MatchWin)
    - !removefrommleaderboard [username] [type] : Remove specific player from leaderboard
    
    NOTES:
    - [player] can be partial name (e.g., "Joh" for "John123")
    - Title names are case-sensitive
    - Admin list is defined in TitleConfig.lua
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local TextChatService = game:GetService("TextChatService")

-- DataStores for leaderboard
local MatchWinLeaderboard = DataStoreService:GetOrderedDataStore("FightingLeaderboard_MatchWin_v1")
local RoundsWinLeaderboard = DataStoreService:GetOrderedDataStore("FightingLeaderboard_RoundsWin_v1")
local FightingDataStore = DataStoreService:GetDataStore("FightingSystem_v1")

-- Wait for modules
local TitleConfig
local TitleServer
local DataHandler

local function loadModules()
    -- Load TitleConfig
    local modules = ReplicatedStorage:WaitForChild("Modules", 10)
    if modules then
        local configModule = modules:FindFirstChild("TitleConfig")
        if configModule then
            TitleConfig = require(configModule)
        end
    end
    
    -- Load TitleServer
    local serverFolder = script.Parent
    local titleServerModule = serverFolder:FindFirstChild("TitleServer")
    if titleServerModule then
        TitleServer = require(titleServerModule)
    end
    
    -- Load DataHandler
    local dataHandlerModule = serverFolder:FindFirstChild("DataHandler")
    if dataHandlerModule then
        DataHandler = require(dataHandlerModule)
    end
    
    return TitleConfig and DataHandler
end

-- Command prefix
local PREFIX = "!"

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Check if player is admin
local function isAdmin(player)
    if not TitleConfig then
        loadModules()
    end
    
    if TitleConfig then
        return TitleConfig.IsAdmin(player.UserId)
    end
    
    return false
end

-- Find player by partial name
local function findPlayer(partialName)
    partialName = partialName:lower()
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(partialName) or p.DisplayName:lower():find(partialName) then
            return p
        end
    end
    
    return nil
end

-- Find player by exact username (for offline players)
local function findPlayerByUsername(username)
    -- Try to find online player first
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == username:lower() then
            return p, p.UserId
        end
    end
    
    -- Try to get UserId for offline player
    local success, userId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)
    
    if success and userId then
        return nil, userId
    end
    
    return nil, nil
end

-- Remote for private admin messages (created later in initialization)
local AdminMessageRemote = nil

-- Send message to player (via private remote - not visible to others)
local function sendMessage(player, message)
    -- Print to server output
    print("[AdminCmd -> " .. player.Name .. "]:", message)
    
    -- Send private message to admin via remote
    if not AdminMessageRemote then
        AdminMessageRemote = ReplicatedStorage:FindFirstChild("AdminPrivateMessage")
    end
    
    if AdminMessageRemote then
        AdminMessageRemote:FireClient(player, message)
    end
end

-- Parse command arguments
local function parseArgs(message)
    local args = {}
    for arg in message:gmatch("%S+") do
        table.insert(args, arg)
    end
    return args
end

-- ============================================
-- COMMAND HANDLERS
-- ============================================

local Commands = {}

-- !settitle [player] [titlename]
Commands["settitle"] = function(admin, args)
    if #args < 3 then
        sendMessage(admin, "Usage: !settitle [player] [titlename]")
        return
    end
    
    local targetPlayer = findPlayer(args[2])
    if not targetPlayer then
        sendMessage(admin, "Player not found: " .. args[2])
        return
    end
    
    -- Combine remaining args for title name (in case of spaces)
    local titleName = table.concat(args, " ", 3)
    
    if TitleServer then
        local success = TitleServer:SetSpecialTitle(targetPlayer, titleName)
        if success then
            sendMessage(admin, "✅ Set title for " .. targetPlayer.Name .. " to: " .. titleName)
        else
            sendMessage(admin, "❌ Failed to set title. Check if title '" .. titleName .. "' exists.")
        end
    else
        sendMessage(admin, "❌ TitleServer not loaded!")
    end
end

-- !removetitle [player]
Commands["removetitle"] = function(admin, args)
    if #args < 2 then
        sendMessage(admin, "Usage: !removetitle [player]")
        return
    end
    
    local targetPlayer = findPlayer(args[2])
    if not targetPlayer then
        sendMessage(admin, "Player not found: " .. args[2])
        return
    end
    
    if TitleServer then
        TitleServer:RemoveSpecialTitle(targetPlayer)
        sendMessage(admin, "✅ Removed special title from " .. targetPlayer.Name)
    else
        sendMessage(admin, "❌ TitleServer not loaded!")
    end
end

-- !listtitles
Commands["listtitles"] = function(admin, args)
    if not TitleConfig then
        sendMessage(admin, "❌ TitleConfig not loaded!")
        return
    end
    
    local titles = TitleConfig.GetAllTitles()
    sendMessage(admin, "===== AVAILABLE TITLES =====")
    
    sendMessage(admin, "-- TIER TITLES (earned by RoundsWin) --")
    for _, titleData in ipairs(TitleConfig.TierTitles) do
        sendMessage(admin, string.format("  %s (%s) - Min Rounds: %d", 
            titleData.Name, titleData.DisplayName, titleData.MinRoundsWin))
    end
    
    sendMessage(admin, "-- SPECIAL TITLES (admin given) --")
    for name, data in pairs(TitleConfig.SpecialTitles) do
        sendMessage(admin, string.format("  %s (%s)", name, data.DisplayName))
    end
end

-- !tp [player] - Teleport to target
Commands["tp"] = function(admin, args)
    if #args < 2 then
        sendMessage(admin, "Usage: !tp [player]")
        return
    end
    
    local targetPlayer = findPlayer(args[2])
    if not targetPlayer then
        sendMessage(admin, "Player not found: " .. args[2])
        return
    end
    
    if targetPlayer == admin then
        sendMessage(admin, "Cannot teleport to yourself!")
        return
    end
    
    local adminChar = admin.Character
    local targetChar = targetPlayer.Character
    
    if not adminChar or not targetChar then
        sendMessage(admin, "❌ Character not found!")
        return
    end
    
    local adminHRP = adminChar:FindFirstChild("HumanoidRootPart")
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    
    if not adminHRP or not targetHRP then
        sendMessage(admin, "❌ HumanoidRootPart not found!")
        return
    end
    
    adminHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
    sendMessage(admin, "✅ Teleported to " .. targetPlayer.Name)
end

-- !tphere [player] - Teleport target to you
Commands["tphere"] = function(admin, args)
    if #args < 2 then
        sendMessage(admin, "Usage: !tphere [player]")
        return
    end
    
    local targetPlayer = findPlayer(args[2])
    if not targetPlayer then
        sendMessage(admin, "Player not found: " .. args[2])
        return
    end
    
    if targetPlayer == admin then
        sendMessage(admin, "Cannot teleport yourself to yourself!")
        return
    end
    
    local adminChar = admin.Character
    local targetChar = targetPlayer.Character
    
    if not adminChar or not targetChar then
        sendMessage(admin, "❌ Character not found!")
        return
    end
    
    local adminHRP = adminChar:FindFirstChild("HumanoidRootPart")
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    
    if not adminHRP or not targetHRP then
        sendMessage(admin, "❌ HumanoidRootPart not found!")
        return
    end
    
    targetHRP.CFrame = adminHRP.CFrame * CFrame.new(0, 0, 3)
    sendMessage(admin, "✅ Teleported " .. targetPlayer.Name .. " to you")
end

-- !tpall - Teleport all players to you
Commands["tpall"] = function(admin, args)
    local adminChar = admin.Character
    if not adminChar then
        sendMessage(admin, "❌ Your character not found!")
        return
    end
    
    local adminHRP = adminChar:FindFirstChild("HumanoidRootPart")
    if not adminHRP then
        sendMessage(admin, "❌ Your HumanoidRootPart not found!")
        return
    end
    
    local count = 0
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= admin then
            local targetChar = targetPlayer.Character
            if targetChar then
                local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                if targetHRP then
                    targetHRP.CFrame = adminHRP.CFrame * CFrame.new(count * 3, 0, 3)
                    count = count + 1
                end
            end
        end
    end
    
    sendMessage(admin, "✅ Teleported " .. count .. " players to you")
end

-- !kick [player] [reason]
Commands["kick"] = function(admin, args)
    if #args < 2 then
        sendMessage(admin, "Usage: !kick [player] [reason]")
        return
    end
    
    local targetPlayer = findPlayer(args[2])
    if not targetPlayer then
        sendMessage(admin, "Player not found: " .. args[2])
        return
    end
    
    -- Don't allow kicking other admins
    if isAdmin(targetPlayer) then
        sendMessage(admin, "❌ Cannot kick an admin!")
        return
    end
    
    local reason = "Kicked by admin"
    if #args >= 3 then
        reason = table.concat(args, " ", 3)
    end
    
    targetPlayer:Kick(reason)
    sendMessage(admin, "✅ Kicked " .. targetPlayer.Name .. " - Reason: " .. reason)
end

-- !respawn [player]
Commands["respawn"] = function(admin, args)
    if #args < 2 then
        sendMessage(admin, "Usage: !respawn [player]")
        return
    end
    
    local targetPlayer = findPlayer(args[2])
    if not targetPlayer then
        sendMessage(admin, "Player not found: " .. args[2])
        return
    end
    
    targetPlayer:LoadCharacter()
    sendMessage(admin, "✅ Respawned " .. targetPlayer.Name)
end

-- !resetdata [player] [stat]
-- Stats: RoundsWin, MatchWin, TotalPlaytime, TotalHits, TotalBlocks, TotalDodges, etc.
Commands["resetdata"] = function(admin, args)
    if #args < 3 then
        sendMessage(admin, "Usage: !resetdata [player] [stat]")
        sendMessage(admin, "Stats: RoundsWin, MatchWin, TotalPlaytime, TotalHits, TotalBlocks, TotalDodges, TotalDamageDealt, TotalDamageTaken")
        return
    end
    
    local targetPlayer = findPlayer(args[2])
    if not targetPlayer then
        sendMessage(admin, "Player not found: " .. args[2])
        return
    end
    
    local statName = args[3]
    
    if DataHandler then
        local data = DataHandler.GetData(targetPlayer)
        if data and data[statName] ~= nil then
            local oldValue = data[statName]
            data[statName] = 0
            DataHandler.SaveData(targetPlayer)
            
            -- Also update leaderboard
            if statName == "RoundsWin" then
                pcall(function()
                    RoundsWinLeaderboard:SetAsync(tostring(targetPlayer.UserId), 0)
                end)
            elseif statName == "MatchWin" then
                pcall(function()
                    MatchWinLeaderboard:SetAsync(tostring(targetPlayer.UserId), 0)
                end)
            end
            
            sendMessage(admin, "✅ Reset " .. statName .. " for " .. targetPlayer.Name .. " (was: " .. tostring(oldValue) .. ")")
            
            -- Update title if RoundsWin changed
            if statName == "RoundsWin" and TitleServer then
                TitleServer:UpdateTierTitle(targetPlayer)
            end
        else
            sendMessage(admin, "❌ Invalid stat: " .. statName)
        end
    else
        sendMessage(admin, "❌ DataHandler not loaded!")
    end
end

-- !resetalldata [player]
Commands["resetalldata"] = function(admin, args)
    if #args < 2 then
        sendMessage(admin, "Usage: !resetalldata [player]")
        return
    end
    
    local targetPlayer = findPlayer(args[2])
    if not targetPlayer then
        sendMessage(admin, "Player not found: " .. args[2])
        return
    end
    
    if DataHandler then
        local data = DataHandler.GetData(targetPlayer)
        if data then
            -- Reset all stats
            data.RoundsWin = 0
            data.MatchWin = 0
            data.TotalPlaytime = 0
            data.TotalHits = 0
            data.TotalBlocks = 0
            data.TotalDodges = 0
            data.TotalDamageDealt = 0
            data.TotalDamageTaken = 0
            data.SpecialTitle = ""
            data.EquippedTitle = ""
            
            DataHandler.SaveData(targetPlayer)
            
            -- Clear from leaderboards
            pcall(function()
                RoundsWinLeaderboard:SetAsync(tostring(targetPlayer.UserId), 0)
                MatchWinLeaderboard:SetAsync(tostring(targetPlayer.UserId), 0)
            end)
            
            -- Update title
            if TitleServer then
                TitleServer:UpdateTierTitle(targetPlayer)
            end
            
            sendMessage(admin, "✅ Reset ALL data for " .. targetPlayer.Name)
        else
            sendMessage(admin, "❌ No data found for player!")
        end
    else
        sendMessage(admin, "❌ DataHandler not loaded!")
    end
end

-- !setstat [player] [stat] [value]
Commands["setstat"] = function(admin, args)
    if #args < 4 then
        sendMessage(admin, "Usage: !setstat [player] [stat] [value]")
        return
    end
    
    local targetPlayer = findPlayer(args[2])
    if not targetPlayer then
        sendMessage(admin, "Player not found: " .. args[2])
        return
    end
    
    local statName = args[3]
    local newValue = tonumber(args[4])
    
    if not newValue then
        sendMessage(admin, "❌ Invalid value. Must be a number.")
        return
    end
    
    if DataHandler then
        local data = DataHandler.GetData(targetPlayer)
        if data and data[statName] ~= nil then
            local oldValue = data[statName]
            data[statName] = newValue
            DataHandler.SaveData(targetPlayer)
            
            -- Also update leaderboard
            if statName == "RoundsWin" then
                pcall(function()
                    RoundsWinLeaderboard:SetAsync(tostring(targetPlayer.UserId), newValue)
                end)
            elseif statName == "MatchWin" then
                pcall(function()
                    MatchWinLeaderboard:SetAsync(tostring(targetPlayer.UserId), newValue)
                end)
            end
            
            sendMessage(admin, "✅ Set " .. statName .. " for " .. targetPlayer.Name .. " to " .. tostring(newValue) .. " (was: " .. tostring(oldValue) .. ")")
            
            -- Update title if RoundsWin changed
            if statName == "RoundsWin" and TitleServer then
                TitleServer:UpdateTierTitle(targetPlayer)
            end
        else
            sendMessage(admin, "❌ Invalid stat: " .. statName)
        end
    else
        sendMessage(admin, "❌ DataHandler not loaded!")
    end
end

-- !viewdata [player]
Commands["viewdata"] = function(admin, args)
    if #args < 2 then
        sendMessage(admin, "Usage: !viewdata [player]")
        return
    end
    
    local targetPlayer = findPlayer(args[2])
    if not targetPlayer then
        sendMessage(admin, "Player not found: " .. args[2])
        return
    end
    
    if DataHandler then
        local data = DataHandler.GetData(targetPlayer)
        if data then
            sendMessage(admin, "===== DATA FOR " .. targetPlayer.Name .. " =====")
            sendMessage(admin, "RoundsWin: " .. tostring(data.RoundsWin or 0))
            sendMessage(admin, "MatchWin: " .. tostring(data.MatchWin or 0))
            sendMessage(admin, "TotalPlaytime: " .. tostring(data.TotalPlaytime or 0) .. "s")
            sendMessage(admin, "TotalHits: " .. tostring(data.TotalHits or 0))
            sendMessage(admin, "TotalBlocks: " .. tostring(data.TotalBlocks or 0))
            sendMessage(admin, "TotalDodges: " .. tostring(data.TotalDodges or 0))
            sendMessage(admin, "SpecialTitle: " .. tostring(data.SpecialTitle or "none"))
            sendMessage(admin, "EquippedTitle: " .. tostring(data.EquippedTitle or "none"))
            
            if TitleServer then
                sendMessage(admin, "CurrentTitle: " .. TitleServer:GetPlayerTitle(targetPlayer))
            end
        else
            sendMessage(admin, "❌ No data found for player!")
        end
    else
        sendMessage(admin, "❌ DataHandler not loaded!")
    end
end

-- !clearleaderboard [type] - type: RoundsWin, MatchWin, or all
Commands["clearleaderboard"] = function(admin, args)
    if #args < 2 then
        sendMessage(admin, "Usage: !clearleaderboard [type]")
        sendMessage(admin, "Types: RoundsWin, MatchWin, all")
        return
    end
    
    local lbType = args[2]:lower()
    
    if lbType == "roundswin" or lbType == "all" then
        -- Note: Cannot fully clear OrderedDataStore, but can set all known entries to 0
        sendMessage(admin, "⚠️ Note: OrderedDataStore cannot be fully cleared. Setting visible entries to 0...")
        
        pcall(function()
            local pages = RoundsWinLeaderboard:GetSortedAsync(false, 100)
            local data = pages:GetCurrentPage()
            for _, entry in ipairs(data) do
                RoundsWinLeaderboard:SetAsync(entry.key, 0)
            end
        end)
        
        sendMessage(admin, "✅ Cleared RoundsWin leaderboard entries")
    end
    
    if lbType == "matchwin" or lbType == "all" then
        pcall(function()
            local pages = MatchWinLeaderboard:GetSortedAsync(false, 100)
            local data = pages:GetCurrentPage()
            for _, entry in ipairs(data) do
                MatchWinLeaderboard:SetAsync(entry.key, 0)
            end
        end)
        
        sendMessage(admin, "✅ Cleared MatchWin leaderboard entries")
    end
    
    if lbType ~= "roundswin" and lbType ~= "matchwin" and lbType ~= "all" then
        sendMessage(admin, "❌ Invalid type. Use: RoundsWin, MatchWin, or all")
    end
end

-- !removefromleaderboard [username] [type] - Remove specific player from leaderboard
Commands["removefromleaderboard"] = function(admin, args)
    if #args < 3 then
        sendMessage(admin, "Usage: !removefromleaderboard [username] [type]")
        sendMessage(admin, "Types: RoundsWin, MatchWin, all")
        return
    end
    
    local username = args[2]
    local lbType = args[3]:lower()
    
    -- Get UserId from username
    local _, userId = findPlayerByUsername(username)
    if not userId then
        sendMessage(admin, "❌ Could not find user: " .. username)
        return
    end
    
    if lbType == "roundswin" or lbType == "all" then
        pcall(function()
            RoundsWinLeaderboard:SetAsync(tostring(userId), 0)
        end)
        sendMessage(admin, "✅ Removed " .. username .. " from RoundsWin leaderboard")
    end
    
    if lbType == "matchwin" or lbType == "all" then
        pcall(function()
            MatchWinLeaderboard:SetAsync(tostring(userId), 0)
        end)
        sendMessage(admin, "✅ Removed " .. username .. " from MatchWin leaderboard")
    end
    
    if lbType ~= "roundswin" and lbType ~= "matchwin" and lbType ~= "all" then
        sendMessage(admin, "❌ Invalid type. Use: RoundsWin, MatchWin, or all")
    end
end

-- !help - Show all commands
Commands["help"] = function(admin, args)
    sendMessage(admin, "===== ADMIN COMMANDS =====")
    sendMessage(admin, "")
    sendMessage(admin, "TITLE COMMANDS:")
    sendMessage(admin, "  !settitle [player] [title] - Set special title")
    sendMessage(admin, "  !removetitle [player] - Remove special title")
    sendMessage(admin, "  !listtitles - List all titles")
    sendMessage(admin, "")
    sendMessage(admin, "TELEPORT COMMANDS:")
    sendMessage(admin, "  !tp [player] - Teleport to player")
    sendMessage(admin, "  !tphere [player] - Teleport player to you")
    sendMessage(admin, "  !tpall - Teleport all to you")
    sendMessage(admin, "")
    sendMessage(admin, "PLAYER MANAGEMENT:")
    sendMessage(admin, "  !kick [player] [reason] - Kick player")
    sendMessage(admin, "  !respawn [player] - Respawn player")
    sendMessage(admin, "")
    sendMessage(admin, "DATA MANAGEMENT:")
    sendMessage(admin, "  !resetdata [player] [stat] - Reset stat")
    sendMessage(admin, "  !resetalldata [player] - Reset ALL data")
    sendMessage(admin, "  !setstat [player] [stat] [value] - Set stat")
    sendMessage(admin, "  !viewdata [player] - View player data")
    sendMessage(admin, "  !clearleaderboard [type] - Clear leaderboard")
    sendMessage(admin, "  !removefromleaderboard [username] [type] - Remove from leaderboard")
end

-- ============================================
-- CHAT LISTENER
-- ============================================

local function onPlayerChatted(player, message)
    -- Check if message starts with prefix
    if not message:sub(1, 1) == PREFIX then return end
    
    -- Check if player is admin
    if not isAdmin(player) then return end
    
    -- Parse command
    local args = parseArgs(message)
    if #args == 0 then return end
    
    -- Get command name (remove prefix)
    local commandName = args[1]:sub(2):lower() -- Remove "!" and lowercase
    
    -- Execute command
    local commandFunc = Commands[commandName]
    if commandFunc then
        print("[AdminCmd] " .. player.Name .. " executed: " .. message)
        commandFunc(player, args)
    end
end

-- ============================================
-- INITIALIZATION
-- ============================================

-- Load modules
task.spawn(function()
    task.wait(2)
    loadModules()
    print("✅ [AdminCommands] Modules loaded")
end)

-- Connect to player chat
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        onPlayerChatted(player, message)
    end)
end)

-- Connect for existing players
for _, player in ipairs(Players:GetPlayers()) do
    player.Chatted:Connect(function(message)
        onPlayerChatted(player, message)
    end)
end

-- ============================================
-- HIDE ADMIN COMMANDS FROM CHAT (TextChatService)
-- ============================================

-- Create remote for private admin messages
local AdminMessageRemote = Instance.new("RemoteEvent")
AdminMessageRemote.Name = "AdminPrivateMessage"
AdminMessageRemote.Parent = ReplicatedStorage

-- Setup TextChatService filter to hide commands
task.spawn(function()
    task.wait(3) -- Wait for TextChatService to fully initialize
    
    pcall(function()
        -- For new TextChatService
        local textChannels = TextChatService:WaitForChild("TextChannels", 5)
        if textChannels then
            local rbxGeneral = textChannels:WaitForChild("RBXGeneral", 5)
            if rbxGeneral then
                -- Intercept incoming messages
                rbxGeneral.ShouldDeliverCallback = function(message, textSource)
                    -- Check if this is an admin command
                    local messageText = message.Text
                    if messageText and messageText:sub(1, 1) == PREFIX then
                        -- Find the sender
                        local senderId = message.TextSource and message.TextSource.UserId
                        if senderId then
                            local sender = Players:GetPlayerByUserId(senderId)
                            if sender and isAdmin(sender) then
                                -- Don't deliver admin commands to anyone
                                return false
                            end
                        end
                    end
                    return true
                end
                
                print("✅ [AdminCommands] TextChatService filter active - commands will be hidden")
            end
        end
    end)
end)

-- Alternative: Use OnIncomingMessage to filter (for compatibility)
task.spawn(function()
    task.wait(4)
    
    pcall(function()
        local textChannels = TextChatService:FindFirstChild("TextChannels")
        if textChannels then
            for _, channel in ipairs(textChannels:GetChildren()) do
                if channel:IsA("TextChannel") then
                    channel.OnIncomingMessage = function(message)
                        local properties = Instance.new("TextChatMessageProperties")
                        
                        -- Check if this is an admin command
                        local messageText = message.Text
                        if messageText and messageText:sub(1, 1) == PREFIX then
                            local senderId = message.TextSource and message.TextSource.UserId
                            if senderId then
                                local sender = Players:GetPlayerByUserId(senderId)
                                if sender and isAdmin(sender) then
                                    -- Hide the message completely
                                    properties.PrefixText = ""
                                    properties.Text = ""
                                    return properties
                                end
                            end
                        end
                        
                        return properties
                    end
                end
            end
        end
    end)
end)

print("✅ [AdminCommands] Admin command system initialized")
print("   Use !help in chat to see all commands (admin only)")
print("   Commands are hidden from other players")

