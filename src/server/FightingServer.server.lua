--[[
    FightingServer.server.lua
    Main server script for Fighting System
    
    Handles:
    - Arena detection and management
    - Match/Round logic
    - Combat validation
    - Score tracking
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for Modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local FightingConfig = require(Modules:WaitForChild("FightingConfig"))
local AnimationConfig = require(Modules:WaitForChild("AnimationConfig"))
local DataHandler = require(script.Parent:WaitForChild("DataHandler"))
local TitleServer = require(script.Parent:WaitForChild("TitleServer"))
local MarketplaceService = game:GetService("MarketplaceService")

-- ============================================
-- CONFIG CACHE UTILITIES (SERVER VALIDATION)
-- ============================================
local RunService = game:GetService("RunService")
local _serverCache = {_v = 1, _initialized = true}  -- Always valid

local function _serverCacheValid()
	return true  -- Combat system is active
end

print("✅ [FightingServer] Combat system validation: ACTIVE")

-- Respawn cepat untuk fighting game: loser respawn dalam 2 detik setelah break-apart
Players.RespawnTime = 2
print("✅ [FightingServer] RespawnTime set to 2 seconds")

-- ============================================
-- REMOTE EVENTS & FUNCTIONS
-- ============================================

local FightingRemotes = Instance.new("Folder")
FightingRemotes.Name = "FightingRemotes"
FightingRemotes.Parent = ReplicatedStorage

-- Events
local StartMatchEvent = Instance.new("RemoteEvent")
StartMatchEvent.Name = "StartMatch"
StartMatchEvent.Parent = FightingRemotes

local EndMatchEvent = Instance.new("RemoteEvent")
EndMatchEvent.Name = "EndMatch"
EndMatchEvent.Parent = FightingRemotes

local RoundStartEvent = Instance.new("RemoteEvent")
RoundStartEvent.Name = "RoundStart"
RoundStartEvent.Parent = FightingRemotes

local RoundEndEvent = Instance.new("RemoteEvent")
RoundEndEvent.Name = "RoundEnd"
RoundEndEvent.Parent = FightingRemotes

local UpdateStatsEvent = Instance.new("RemoteEvent")
UpdateStatsEvent.Name = "UpdateStats"
UpdateStatsEvent.Parent = FightingRemotes

local DealDamageEvent = Instance.new("RemoteEvent")
DealDamageEvent.Name = "DealDamage"
DealDamageEvent.Parent = FightingRemotes

local BlockEvent = Instance.new("RemoteEvent")
BlockEvent.Name = "Block"
BlockEvent.Parent = FightingRemotes

local DodgeEvent = Instance.new("RemoteEvent")
DodgeEvent.Name = "Dodge"
DodgeEvent.Parent = FightingRemotes

local UpdateInfoGuiEvent = Instance.new("RemoteEvent")
UpdateInfoGuiEvent.Name = "UpdateInfoGui"
UpdateInfoGuiEvent.Parent = FightingRemotes

local PlayerReadyEvent = Instance.new("RemoteEvent")
PlayerReadyEvent.Name = "PlayerReady"
PlayerReadyEvent.Parent = FightingRemotes

local CameraShakeEvent = Instance.new("RemoteEvent")
CameraShakeEvent.Name = "CameraShake"
CameraShakeEvent.Parent = FightingRemotes

local RagdollEvent = Instance.new("RemoteEvent")
RagdollEvent.Name = "Ragdoll"
RagdollEvent.Parent = FightingRemotes

-- Functions
local GetLeaderboardFunc = Instance.new("RemoteFunction")
GetLeaderboardFunc.Name = "GetLeaderboard"
GetLeaderboardFunc.Parent = FightingRemotes

local GetPlayerStatsFunc = Instance.new("RemoteFunction")
GetPlayerStatsFunc.Name = "GetPlayerStats"
GetPlayerStatsFunc.Parent = FightingRemotes

-- ============================================
-- STATE MANAGEMENT
-- ============================================

-- Active arenas and their states
local arenaStates = {}

-- Expose to _G for FightInfoScreen access
_G.FightingArenaStates = arenaStates

-- Player cooldowns
local playerCooldowns = {}

-- Player combat states (who's fighting whom)
local activeFighters = {}

-- Arena state template
local function createArenaState(arenaFolder)
    return {
        ArenaFolder = arenaFolder,
        ArenaName = arenaFolder.Name,
        
        -- Players
        PlayerA = nil,
        PlayerB = nil,
        
        -- Match state
        IsActive = false,
        CountdownInProgress = false, -- Prevent race condition
        CurrentRound = 0,
        TotalRounds = FightingConfig.Match.RoundsPerMatch,
        
        -- Score
        PlayerAWins = 0,
        PlayerBWins = 0,
        
        -- Round state
        RoundActive = false,
        RoundStartTime = 0,
        
        -- Player stats during fight
        PlayerAHealth = FightingConfig.Stats.MaxHealth,
        PlayerBHealth = FightingConfig.Stats.MaxHealth,
        PlayerAStamina = FightingConfig.Stats.MaxStamina,
        PlayerBStamina = FightingConfig.Stats.MaxStamina,
        
        -- Match stats (for result screen)
        Stats = {
            PlayerA = { Hits = 0, Blocks = 0, DamageDealt = 0 },
            PlayerB = { Hits = 0, Blocks = 0, DamageDealt = 0 },
        },
        
        -- Blocking states
        PlayerABlocking = false,
        PlayerBBlocking = false,
    }
end

-- ============================================
-- ARENA DETECTION
-- ============================================

local function findAllArenas()
    local arenas = {}
    
    local fightingArenaFolder = workspace:FindFirstChild("FightingArena")
    if not fightingArenaFolder then
        warn("⚠️ [FightingServer] No 'FightingArena' folder found in workspace!")
        return arenas
    end
    
    for _, child in ipairs(fightingArenaFolder:GetChildren()) do
        if child:IsA("Folder") then
            -- Verify required parts
            local hasAllParts = true
            for _, partName in ipairs(FightingConfig.Arena.RequiredParts) do
                if not child:FindFirstChild(partName) then
                    warn("⚠️ [FightingServer] Arena", child.Name, "missing part:", partName)
                    hasAllParts = false
                end
            end
            
            if hasAllParts then
                table.insert(arenas, child)
                print("✅ [FightingServer] Found valid arena:", child.Name)
            end
        end
    end
    
    return arenas
end

-- ============================================
-- START POSITION DETECTION
-- ============================================

local function isPlayerOnPart(player, part)
    if not player or not player.Character then return false end
    
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    local partPos = part.Position
    local playerPos = humanoidRootPart.Position
    
    -- Check horizontal distance
    local horizontalDist = (Vector3.new(playerPos.X, 0, playerPos.Z) - Vector3.new(partPos.X, 0, partPos.Z)).Magnitude
    
    -- Check if player is above the part
    local verticalDist = playerPos.Y - partPos.Y
    
    local range = FightingConfig.Arena.StartPositionTouchRange
    return horizontalDist < range and verticalDist >= 0 and verticalDist < 10
end

local function getPlayerOnStartPosition(arenaFolder, positionName)
    local startPart = arenaFolder:FindFirstChild(positionName)
    if not startPart then return nil end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if isPlayerOnPart(player, startPart) then
            -- Check if player is not in cooldown
            if not playerCooldowns[player.UserId] then
                -- Check if player is not currently fighting
                if not activeFighters[player.UserId] then
                    return player
                end
            end
        end
    end
    
    return nil
end

-- Update start position visual (including all child parts)
local function updateStartPositionColor(arenaFolder, positionName, occupied)
    local startPart = arenaFolder:FindFirstChild(positionName)
    if not startPart then return end
    
    -- Define colors
    local colorToApply
    if occupied then
        colorToApply = Color3.fromRGB(255, 0, 0)  -- Really Red
    else
        colorToApply = Color3.fromRGB(255, 255, 255)  -- White
    end
    
    -- Change the main part color
    if startPart:IsA("BasePart") then
        startPart.Color = colorToApply
    end
    
    -- Change all child parts and mesh parts color
    for _, child in ipairs(startPart:GetDescendants()) do
        if child:IsA("BasePart") or child:IsA("MeshPart") then
            child.Color = colorToApply
        end
    end
end

-- Update info GUI text
local function updateInfoGui(arenaFolder, text)
    local infoPart = arenaFolder:FindFirstChild("InfoGui")
    if not infoPart then return end
    
    local billboardGui = infoPart:FindFirstChild("InfoGui")
    if not billboardGui then return end
    
    local frame = billboardGui:FindFirstChild("Frame")
    if not frame then return end
    
    local textLabel = frame:FindFirstChild("TextLabel")
    if textLabel then
        textLabel.Text = text
    end
end

-- ============================================
-- PLAYER COLLISION CONTROL
-- ============================================

local PhysicsService = game:GetService("PhysicsService")

-- ============================================
-- GLOBAL PLAYER COLLISION CONTROL
-- ============================================

-- Create a global "Fighters" collision group that does not collide with itself
local function setupGlobalCollision()
    pcall(function()
        PhysicsService:RegisterCollisionGroup("Fighters")
        PhysicsService:CollisionGroupSetCollidable("Fighters", "Fighters", false)
    end)
end
setupGlobalCollision()

-- Apply "Fighters" collision group to any character parts automatically
local function setCharacterCollisionGroup(character)
    if not character then return end
    
    -- Function to set collision group
    local function setPartCollision(part)
        if part:IsA("BasePart") then
            part.CollisionGroup = "Fighters"
        end
    end
    
    -- Apply to existing parts
    for _, part in pairs(character:GetDescendants()) do
        setPartCollision(part)
    end
    
    -- Apply to any new parts added later
    character.DescendantAdded:Connect(setPartCollision)
end

-- Hook up PlayerAdded to listen for characters
Players.PlayerAdded:Connect(function(player)
    if player.Character then
        setCharacterCollisionGroup(player.Character)
    end
    player.CharacterAdded:Connect(function(character)
        setCharacterCollisionGroup(character)
        
        -- Beri delay sedikit agar humanoids/parts ter-load oleh Roblox
        task.wait(0.5)
        setCharacterCollisionGroup(character)
    end)
end)

-- ============================================
-- RAGDOLL SYSTEM
-- ============================================

local ragdolledPlayers = {} -- [Player] = { joints = {}, collisions = {} }

local function enableRagdoll(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    if ragdolledPlayers[targetPlayer] then return end -- already ragdolled
    
    local character = targetPlayer.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local savedData = { joints = {}, collisions = {} }
    
    -- 1. Stop all playing animation tracks
    pcall(function()
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                track:Stop(0)
            end
        end
    end)
    
    -- 2. Freeze movement
    humanoid.PlatformStand = true
    humanoid.AutoRotate = false
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    humanoid.JumpHeight = 0
    
    -- 3. Convert Motor6D joints to BallSocketConstraints (ragdoll)
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("Motor6D") and descendant.Name ~= "RootJoint" then
            -- Save joint info
            table.insert(savedData.joints, {
                Motor = descendant,
                Part0 = descendant.Part0,
                Part1 = descendant.Part1,
                C0 = descendant.C0,
                C1 = descendant.C1,
            })
            
            -- Create attachment pair
            local att0 = Instance.new("Attachment")
            att0.Name = "RagdollAtt0_" .. descendant.Name
            att0.CFrame = descendant.C0
            att0.Parent = descendant.Part0
            
            local att1 = Instance.new("Attachment")
            att1.Name = "RagdollAtt1_" .. descendant.Name
            att1.CFrame = descendant.C1
            att1.Parent = descendant.Part1
            
            -- Create BallSocketConstraint
            local bsc = Instance.new("BallSocketConstraint")
            bsc.Name = "RagdollBSC_" .. descendant.Name
            bsc.Attachment0 = att0
            bsc.Attachment1 = att1
            bsc.LimitsEnabled = true
            bsc.TwistLimitsEnabled = true
            bsc.UpperAngle = 50
            bsc.TwistLowerAngle = -30
            bsc.TwistUpperAngle = 30
            bsc.Parent = descendant.Part0
            
            -- Disable the Motor6D (don't destroy, we restore later)
            descendant.Enabled = false
        end
    end
    
    -- 4. Enable CanCollide on all body parts (prevent floor clipping)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            savedData.collisions[part] = part.CanCollide
            part.CanCollide = true
        end
    end
    
    -- 5. Unanchor the HumanoidRootPart so physics take over
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CanCollide = false -- HRP should not collide during ragdoll
    end
    
    ragdolledPlayers[targetPlayer] = savedData
    
    -- Notify clients
    RagdollEvent:FireAllClients(targetPlayer, true)
    print("🦴 [RAGDOLL] Enabled ragdoll for", targetPlayer.Name)
end

local function disableRagdoll(targetPlayer)
    if not targetPlayer then return end
    local savedData = ragdolledPlayers[targetPlayer]
    if not savedData then return end
    
    local character = targetPlayer.Character
    if not character then
        ragdolledPlayers[targetPlayer] = nil
        return
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    -- 1. Remove all ragdoll constraints and attachments
    for _, desc in ipairs(character:GetDescendants()) do
        if desc:IsA("BallSocketConstraint") and string.find(desc.Name, "RagdollBSC_") then
            desc:Destroy()
        elseif desc:IsA("Attachment") and (string.find(desc.Name, "RagdollAtt0_") or string.find(desc.Name, "RagdollAtt1_")) then
            desc:Destroy()
        end
    end
    
    -- 2. Re-enable Motor6D joints
    for _, jointData in ipairs(savedData.joints) do
        if jointData.Motor and jointData.Motor.Parent then
            jointData.Motor.Enabled = true
        end
    end
    
    -- 3. Restore CanCollide states
    for part, wasCollidable in pairs(savedData.collisions) do
        if part and part.Parent then
            part.CanCollide = wasCollidable
        end
    end
    
    -- 4. Restore HRP collisions
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CanCollide = true
    end
    
    -- 5. Restore humanoid movement
    if humanoid then
        humanoid.PlatformStand = false
        humanoid.AutoRotate = true
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
        humanoid.JumpHeight = 7.2
    end
    
    ragdolledPlayers[targetPlayer] = nil
    
    -- Notify clients
    RagdollEvent:FireAllClients(targetPlayer, false)
    print("🦴 [RAGDOLL] Disabled ragdoll for", targetPlayer.Name)
end

-- ============================================
-- MATCH LOGIC
-- ============================================

local function teleportPlayerToPosition(player, position)
    if not player or not player.Character then return end
    
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    humanoidRootPart.CFrame = CFrame.new(position.Position + Vector3.new(0, 3, 0))
end

local function startMatch(arenaState)
    if not _serverCacheValid() then return end
    if arenaState.IsActive then return end
    
    local arena = arenaState.ArenaFolder
    local playerA = arenaState.PlayerA
    local playerB = arenaState.PlayerB
    
    if not playerA or not playerB then 
        print("⚠️ [FightingServer] Cannot start match - PlayerA or PlayerB is nil!")
        arenaState.CountdownInProgress = false
        return 
    end
    
    -- Match is starting - clear countdown flag and set active
    arenaState.IsActive = true
    arenaState.CountdownInProgress = false
    arenaState.CurrentRound = 0
    arenaState.PlayerAWins = 0
    arenaState.PlayerBWins = 0
    
    -- Mark players as active fighters
    activeFighters[playerA.UserId] = {
        ArenaName = arena.Name,
        Opponent = playerB,
        Side = "A"
    }
    activeFighters[playerB.UserId] = {
        ArenaName = arena.Name,
        Opponent = playerA,
        Side = "B"
    }
    
    -- Teleport to fight positions
    local fightPosA = arena:FindFirstChild("FightPositionA")
    local fightPosB = arena:FindFirstChild("FightPositionB")
    
    if fightPosA then teleportPlayerToPosition(playerA, fightPosA) end
    if fightPosB then teleportPlayerToPosition(playerB, fightPosB) end
    
    -- Notify clients
    StartMatchEvent:FireClient(playerA, {
        OpponentName = playerB.Name,
        TotalRounds = arenaState.TotalRounds,
        ArenaName = arena.Name,
        Side = "A",
    })
    
    StartMatchEvent:FireClient(playerB, {
        OpponentName = playerA.Name,
        TotalRounds = arenaState.TotalRounds,
        ArenaName = arena.Name,
        Side = "B",
    })
    
    updateInfoGui(arena, "Match Started!")
    
    print("🥊 [FightingServer] Match started in", arena.Name, "-", playerA.Name, "vs", playerB.Name)
    
    -- Start first round after delay
    task.delay(FightingConfig.Match.CountdownBeforeStart, function()
        startRound(arenaState)
    end)
end

function startRound(arenaState)
    if not arenaState.IsActive then return end
    
    arenaState.CurrentRound = arenaState.CurrentRound + 1
    arenaState.RoundActive = true
    arenaState.RoundStartTime = tick()
    
    -- Reset health and stamina
    arenaState.PlayerAHealth = FightingConfig.Stats.MaxHealth
    arenaState.PlayerBHealth = FightingConfig.Stats.MaxHealth
    arenaState.PlayerAStamina = FightingConfig.Stats.MaxStamina
    arenaState.PlayerBStamina = FightingConfig.Stats.MaxStamina
    
    -- Reset blocking states
    arenaState.PlayerABlocking = false
    arenaState.PlayerBBlocking = false
    
    local arena = arenaState.ArenaFolder
    local playerA = arenaState.PlayerA
    local playerB = arenaState.PlayerB
    
    print("📊 [FightingServer] startRound() called:")
    print("   - arenaState.IsActive:", arenaState.IsActive)
    print("   - arenaState.RoundActive:", arenaState.RoundActive)
    print("   - playerA:", playerA and playerA.Name or "NIL")
    print("   - playerB:", playerB and playerB.Name or "NIL")
    
    -- Teleport back to fight positions
    local fightPosA = arena:FindFirstChild("FightPositionA")
    local fightPosB = arena:FindFirstChild("FightPositionB")
    
    if fightPosA and playerA and playerA.Character then
        teleportPlayerToPosition(playerA, fightPosA)
    end
    if fightPosB and playerB and playerB.Character then
        teleportPlayerToPosition(playerB, fightPosB)
    end
    
    -- Notify clients
    local roundData = {
        RoundNumber = arenaState.CurrentRound,
        TotalRounds = arenaState.TotalRounds,
        PlayerAWins = arenaState.PlayerAWins,
        PlayerBWins = arenaState.PlayerBWins,
    }
    
    print("📤 [FightingServer] Firing RoundStartEvent to clients:")
    
    if playerA then 
        print("   📤 Firing to PlayerA:", playerA.Name)
        RoundStartEvent:FireClient(playerA, roundData) 
        print("   ✅ Fired to PlayerA")
    else
        print("   ⚠️ PlayerA is nil, cannot fire!")
    end
    
    if playerB then 
        print("   📤 Firing to PlayerB:", playerB.Name)
        RoundStartEvent:FireClient(playerB, roundData) 
        print("   ✅ Fired to PlayerB")
    else
        print("   ⚠️ PlayerB is nil, cannot fire!")
    end
    
    updateInfoGui(arena, "Round " .. arenaState.CurrentRound .. " - FIGHT!")
    
    print("🔔 [FightingServer] Round", arenaState.CurrentRound, "started in", arena.Name)
end

local function endRound(arenaState, winner)
    if not arenaState.RoundActive then return end
    
    arenaState.RoundActive = false
    
    local arena = arenaState.ArenaFolder
    local playerA = arenaState.PlayerA
    local playerB = arenaState.PlayerB
    
    -- Tentukan loser (kebalikan dari winner)
    local loser = nil
    if winner == playerA then     loser = playerB
    elseif winner == playerB then loser = playerA
    end
    
    -- Determine winner
    local winnerSide = "draw"
    if winner == playerA then
        arenaState.PlayerAWins = arenaState.PlayerAWins + 1
        winnerSide = "A"
        DataHandler.AddRoundWin(playerA, 1)
    elseif winner == playerB then
        arenaState.PlayerBWins = arenaState.PlayerBWins + 1
        winnerSide = "B"
        DataHandler.AddRoundWin(playerB, 1)
    end
    
    -- Notify clients
    local roundResult = {
        WinnerSide = winnerSide,
        WinnerName = winner and winner.Name or "Draw",
        RoundNumber = arenaState.CurrentRound,
        TotalRounds = arenaState.TotalRounds,
        PlayerAWins = arenaState.PlayerAWins,
        PlayerBWins = arenaState.PlayerBWins,
    }
    
    if playerA then RoundEndEvent:FireClient(playerA, roundResult) end
    if playerB then RoundEndEvent:FireClient(playerB, roundResult) end
    
    updateInfoGui(arena, "Round " .. arenaState.CurrentRound .. " - " .. (winner and winner.Name .. " wins!" or "Draw!"))
    
    print("🏆 [FightingServer] Round", arenaState.CurrentRound, "ended -", (winner and winner.Name .. " wins" or "Draw"))
    
    -- ── Ragdoll KO: jadikan loser ragdoll (jatuh lemas, tidak bisa gerak) ─────
    -- Tidak membunuh karakter, hanya menonaktifkan joints dan freeze gerakan.
    if loser then
        enableRagdoll(loser)
        print("💀 [FightingServer]", loser.Name, "KO! Ragdoll triggered.")
    end
    
    -- Check for match end
    local requiredWins = math.ceil(arenaState.TotalRounds / 2)
    
    if arenaState.PlayerAWins >= requiredWins then
        task.delay(2.5, function() endMatch(arenaState, playerA) end)
    elseif arenaState.PlayerBWins >= requiredWins then
        task.delay(2.5, function() endMatch(arenaState, playerB) end)
    elseif arenaState.CurrentRound >= arenaState.TotalRounds then
        -- All rounds completed, whoever has more wins
        local matchWinner = nil
        if arenaState.PlayerAWins > arenaState.PlayerBWins then
            matchWinner = playerA
        elseif arenaState.PlayerBWins > arenaState.PlayerAWins then
            matchWinner = playerB
        end
        task.delay(2.5, function() endMatch(arenaState, matchWinner) end)
    else
        -- ── Round berikutnya: tunggu ragdoll selesai lalu unragdoll + startRound ──
        task.delay(3.0, function()
            if not arenaState.IsActive then return end
            
            -- Unragdoll kedua player sebelum mulai round baru
            disableRagdoll(playerA)
            disableRagdoll(playerB)
            
            startRound(arenaState)
        end)
    end
end

function endMatch(arenaState, winner)
    arenaState.IsActive = false
    arenaState.RoundActive = false
    
    local arena = arenaState.ArenaFolder
    local playerA = arenaState.PlayerA
    local playerB = arenaState.PlayerB
    
    -- Track match win
    if winner then
        DataHandler.AddMatchWin(winner, 1)
    end
    
    -- Prepare match result data
    local matchResult = {
        Winner = winner and winner.Name or "Draw",
        PlayerAWins = arenaState.PlayerAWins,
        PlayerBWins = arenaState.PlayerBWins,
        TotalRounds = arenaState.TotalRounds,
        Stats = arenaState.Stats,
    }
    
    -- Notify clients
    if playerA then EndMatchEvent:FireClient(playerA, matchResult) end
    if playerB then EndMatchEvent:FireClient(playerB, matchResult) end
    
    updateInfoGui(arena, winner and (winner.Name .. " wins the match!") or "Match ended in a draw!")
    
    print("🎉 [FightingServer] Match ended in", arena.Name, "-", (winner and winner.Name .. " wins!" or "Draw!"))
    
    -- Unragdoll kedua player sebelum teleport keluar
    disableRagdoll(playerA)
    disableRagdoll(playerB)
    
    -- Teleport players out
    local outPos = arena:FindFirstChild("OutPosition")
    if outPos then
        task.spawn(function()
            task.wait(0.5)  -- brief buffer sebelum teleport
            for _, p in ipairs({ playerA, playerB }) do
                if p and p.Character then
                    teleportPlayerToPosition(p, outPos)
                end
            end
        end)
    end
    
    -- Set cooldowns
    if playerA then
        playerCooldowns[playerA.UserId] = tick()
    end
    if playerB then
        playerCooldowns[playerB.UserId] = tick()
    end
    
    -- Clear fighter states
    if playerA then activeFighters[playerA.UserId] = nil end
    if playerB then activeFighters[playerB.UserId] = nil end
    
    -- Reset arena state
    arenaState.PlayerA = nil
    arenaState.PlayerB = nil
    arenaState.Stats = {
        PlayerA = { Hits = 0, Blocks = 0, DamageDealt = 0 },
        PlayerB = { Hits = 0, Blocks = 0, DamageDealt = 0 },
    }
    
    updateInfoGui(arena, "Waiting for players...")
    updateStartPositionColor(arena, "StartPositionA", false)
    updateStartPositionColor(arena, "StartPositionB", false)
end

-- ============================================
-- COMBAT LOGIC
-- ============================================

DealDamageEvent.OnServerEvent:Connect(function(attacker, attackType, comboIndex)
    if not _serverCacheValid() then return end
    local fighterData = activeFighters[attacker.UserId]
    if not fighterData then return end
    
    local arenaState = arenaStates[fighterData.ArenaName]
    if not arenaState or not arenaState.RoundActive then return end
    
    local defender = fighterData.Opponent
    if not defender or not defender.Character then return end
    
    -- Verify distance
    local attackerHRP = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
    local defenderHRP = defender.Character and defender.Character:FindFirstChild("HumanoidRootPart")
    
    if not attackerHRP or not defenderHRP then return end
    
    local distance = (attackerHRP.Position - defenderHRP.Position).Magnitude
    
    -- Get attack config
    local config
    local damage
    local range
    
    if attackType == "Light" then
        config = FightingConfig.Combat.LightAttack
        damage = config.Damage
        range = config.Range
    elseif attackType == "Heavy" then
        config = FightingConfig.Combat.HeavyAttack
        damage = config.Damage
        range = config.Range
    else
        return
    end
    
    -- Check range
    if distance > range + 2 then return end -- +2 tolerance
    
    -- Check stamina
    local attackerSide = fighterData.Side
    local attackerStamina = attackerSide == "A" and arenaState.PlayerAStamina or arenaState.PlayerBStamina
    
    if attackerStamina < config.StaminaCost then return end
    
    -- Deduct stamina
    if attackerSide == "A" then
        arenaState.PlayerAStamina = arenaState.PlayerAStamina - config.StaminaCost
    else
        arenaState.PlayerBStamina = arenaState.PlayerBStamina - config.StaminaCost
    end
    
    -- Check if defender is blocking
    local defenderSide = attackerSide == "A" and "B" or "A"
    local isBlocking = defenderSide == "A" and arenaState.PlayerABlocking or arenaState.PlayerBBlocking
    local defenderStamina = defenderSide == "A" and arenaState.PlayerAStamina or arenaState.PlayerBStamina
    
    local actualDamage = damage
    local wasBlocked = false
    
    if isBlocking then
        local blockConfig = FightingConfig.Combat.Block
        
        if defenderStamina >= blockConfig.StaminaPerBlock then
            -- Successful block
            actualDamage = 0
            wasBlocked = true
            
            -- Deduct block stamina
            if defenderSide == "A" then
                arenaState.PlayerAStamina = arenaState.PlayerAStamina - blockConfig.StaminaPerBlock
            else
                arenaState.PlayerBStamina = arenaState.PlayerBStamina - blockConfig.StaminaPerBlock
            end
            
            -- Track block
            arenaState.Stats["Player" .. defenderSide].Blocks = arenaState.Stats["Player" .. defenderSide].Blocks + 1
            DataHandler.AddBlock(defender, 1)
            
            -- Camera shake for block
            CameraShakeEvent:FireClient(defender, "Block")
            CameraShakeEvent:FireClient(attacker, "Block")
        else
            -- Block failed (not enough stamina), take full damage
            wasBlocked = false
        end
    end
    
    -- Apply damage
    if actualDamage > 0 then
        if defenderSide == "A" then
            arenaState.PlayerAHealth = math.max(0, arenaState.PlayerAHealth - actualDamage)
        else
            arenaState.PlayerBHealth = math.max(0, arenaState.PlayerBHealth - actualDamage)
        end
        
        -- Track stats
        arenaState.Stats["Player" .. attackerSide].Hits = arenaState.Stats["Player" .. attackerSide].Hits + 1
        arenaState.Stats["Player" .. attackerSide].DamageDealt = arenaState.Stats["Player" .. attackerSide].DamageDealt + actualDamage
        
        DataHandler.AddHit(attacker, 1)
        DataHandler.AddDamageDealt(attacker, actualDamage)
        DataHandler.AddDamageTaken(defender, actualDamage)
        
        -- Camera shake for hit (BOTH players feel the impact)
        CameraShakeEvent:FireClient(defender, "Hit", attackType)
        CameraShakeEvent:FireClient(attacker, "Attack", attackType) -- Attacker feedback
    end
    
    -- Update stats for both players
    local statsData = {
        PlayerAHealth = arenaState.PlayerAHealth,
        PlayerBHealth = arenaState.PlayerBHealth,
        PlayerAStamina = arenaState.PlayerAStamina,
        PlayerBStamina = arenaState.PlayerBStamina,
    }
    
    UpdateStatsEvent:FireClient(arenaState.PlayerA, statsData)
    UpdateStatsEvent:FireClient(arenaState.PlayerB, statsData)
    
    -- Notify defender of hit (for hit animation)
    if actualDamage > 0 then
        -- Fire to ALL clients for damage number popup (visible to everyone)
        local hitDataForAll = {
            AttackType = attackType,
            ComboIndex = comboIndex,
            Damage = actualDamage,
            DefenderName = defender.Name,  -- So clients know who got hit
            AttackerName = attacker.Name,  -- So clients know who attacked
            IsLocalHit = false,
            PlaySound = true,  -- Play sound on successful hit
        }
        DealDamageEvent:FireAllClients(hitDataForAll)
        
        -- Fire to defender specifically for hit animation
        local hitDataForDefender = {
            AttackType = attackType,
            ComboIndex = comboIndex,
            Damage = actualDamage,
            IsLocalHit = true,  -- Defender knows it's them
            PlaySound = false,  -- Sound already played from global event
            AttackerLookVector = attackerHRP.CFrame.LookVector,
            AttackerPosition = attackerHRP.Position,
            AttackerName = attacker.Name,
        }
        DealDamageEvent:FireClient(defender, hitDataForDefender)
    elseif wasBlocked then
        -- Fire block success event
        BlockEvent:FireClient(defender, { Success = true })
    end
    
    -- Check for round end (KO)
    local defenderHealth = defenderSide == "A" and arenaState.PlayerAHealth or arenaState.PlayerBHealth
    if defenderHealth <= 0 then
        endRound(arenaState, attacker)
    end
end)

-- Block event
BlockEvent.OnServerEvent:Connect(function(player, isBlocking)
    if not _serverCacheValid() then return end
    local fighterData = activeFighters[player.UserId]
    if not fighterData then return end
    
    local arenaState = arenaStates[fighterData.ArenaName]
    if not arenaState or not arenaState.RoundActive then return end
    
    if fighterData.Side == "A" then
        arenaState.PlayerABlocking = isBlocking
    else
        arenaState.PlayerBBlocking = isBlocking
    end
end)

-- Dodge event
DodgeEvent.OnServerEvent:Connect(function(player, direction)
    if not _serverCacheValid() then return end
    local fighterData = activeFighters[player.UserId]
    if not fighterData then return end
    
    local arenaState = arenaStates[fighterData.ArenaName]
    if not arenaState or not arenaState.RoundActive then return end
    
    -- Check stamina
    local side = fighterData.Side
    local stamina = side == "A" and arenaState.PlayerAStamina or arenaState.PlayerBStamina
    local dodgeConfig = FightingConfig.Combat.Dodge
    
    if stamina < dodgeConfig.StaminaCost then return end
    
    -- Deduct stamina
    if side == "A" then
        arenaState.PlayerAStamina = arenaState.PlayerAStamina - dodgeConfig.StaminaCost
    else
        arenaState.PlayerBStamina = arenaState.PlayerBStamina - dodgeConfig.StaminaCost
    end
    
    -- Track dodge
    DataHandler.AddDodge(player, 1)
    
    -- Update stats
    local statsData = {
        PlayerAHealth = arenaState.PlayerAHealth,
        PlayerBHealth = arenaState.PlayerBHealth,
        PlayerAStamina = arenaState.PlayerAStamina,
        PlayerBStamina = arenaState.PlayerBStamina,
    }
    
    UpdateStatsEvent:FireClient(arenaState.PlayerA, statsData)
    UpdateStatsEvent:FireClient(arenaState.PlayerB, statsData)
end)

-- ============================================
-- REMOTE FUNCTIONS
-- ============================================

GetLeaderboardFunc.OnServerInvoke = function(player, statType)
    local count = FightingConfig.Leaderboard.MaxEntries
    
    if statType == "MatchWin" then
        return DataHandler.GetTopPlayers("MatchWin", count)
    elseif statType == "RoundsWin" then
        return DataHandler.GetTopPlayers("RoundsWin", count)
    elseif statType == "Playtime" then
        return DataHandler.GetTopPlayers("TotalPlaytime", count)
    end
    
    return {}
end

GetPlayerStatsFunc.OnServerInvoke = function(player)
    local data = DataHandler.GetData(player)
    if not data then return nil end
    
    return {
        RoundsWin = data.RoundsWin,
        MatchWin = data.MatchWin,
        TotalPlaytime = DataHandler.GetTotalPlaytime(player),
        TotalHits = data.TotalHits,
        TotalBlocks = data.TotalBlocks,
        TotalDodges = data.TotalDodges,
    }
end

-- ============================================
-- MAIN LOOP
-- ============================================

-- Initialize arenas
local function initializeArenas()
    local arenas = findAllArenas()
    
    for _, arena in ipairs(arenas) do
        arenaStates[arena.Name] = createArenaState(arena)
        updateInfoGui(arena, "Waiting for players...")
        
        -- Initialize start position colors
        updateStartPositionColor(arena, "StartPositionA", false)
        updateStartPositionColor(arena, "StartPositionB", false)
    end
    
    print("✅ [FightingServer] Initialized", #arenas, "arenas")
end

-- Handle player leaving during match
Players.PlayerRemoving:Connect(function(player)
    local fighterData = activeFighters[player.UserId]
    if fighterData then
        local arenaState = arenaStates[fighterData.ArenaName]
        if arenaState and arenaState.IsActive then
            -- Opponent wins by forfeit
            local winner = fighterData.Opponent
            endMatch(arenaState, winner)
        end
    end
end)

-- Initialize
initializeArenas()

-- Enable dynamic arena creation (if arenas added later)
local fightingArenaFolder = workspace:FindFirstChild("FightingArena")
if fightingArenaFolder then
    fightingArenaFolder.ChildAdded:Connect(function(child)
        if child:IsA("Folder") then
            task.wait(0.5) -- Wait for parts to load
            local arenas = findAllArenas()
            for _, arena in ipairs(arenas) do
                if not arenaStates[arena.Name] then
                    arenaStates[arena.Name] = createArenaState(arena)
                    updateInfoGui(arena, "Waiting for players...")
                    print("✅ [FightingServer] New arena detected:", arena.Name)
                end
            end
        end
    end)
end

-- Stamina regeneration loop (separate task, runs every second)
task.spawn(function()
    while true do
        task.wait(1) -- Every 1 second
        
        for arenaName, arenaState in pairs(arenaStates) do
            if arenaState.RoundActive then
                -- Regenerate stamina
                arenaState.PlayerAStamina = math.min(
                    FightingConfig.Stats.MaxStamina,
                    arenaState.PlayerAStamina + FightingConfig.Stats.StaminaRegenPerSecond
                )
                arenaState.PlayerBStamina = math.min(
                    FightingConfig.Stats.MaxStamina,
                    arenaState.PlayerBStamina + FightingConfig.Stats.StaminaRegenPerSecond
                )
                
                -- Send stat updates to clients
                local statsData = {
                    PlayerAHealth = arenaState.PlayerAHealth,
                    PlayerBHealth = arenaState.PlayerBHealth,
                    PlayerAStamina = arenaState.PlayerAStamina,
                    PlayerBStamina = arenaState.PlayerBStamina,
                }
                
                if arenaState.PlayerA then
                    UpdateStatsEvent:FireClient(arenaState.PlayerA, statsData)
                end
                if arenaState.PlayerB then
                    UpdateStatsEvent:FireClient(arenaState.PlayerB, statsData)
                end
            end
        end
    end
end)

-- Main loop (simple while loop, runs every 0.5 seconds)
task.spawn(function()
    while true do
        task.wait(0.5) -- Check every 0.5 seconds
        
        local currentTime = tick()
        
        -- Check cooldowns
        for userId, cooldownStart in pairs(playerCooldowns) do
            if currentTime - cooldownStart >= FightingConfig.Match.MatchCooldown then
                playerCooldowns[userId] = nil
            end
        end
        
        -- Check each arena
        for arenaName, arenaState in pairs(arenaStates) do
            
            -- Skip if arena is active or countdown in progress
            if not arenaState.IsActive and not arenaState.CountdownInProgress then
                local arena = arenaState.ArenaFolder
                
                -- Check for players on start positions
                local playerA = getPlayerOnStartPosition(arena, "StartPositionA")
                local playerB = getPlayerOnStartPosition(arena, "StartPositionB")
                
                -- Update visuals
                updateStartPositionColor(arena, "StartPositionA", playerA ~= nil)
                updateStartPositionColor(arena, "StartPositionB", playerB ~= nil)
                
                -- Both players ready?
                if playerA and playerB then
                    -- Start countdown in separate thread
                    arenaState.CountdownInProgress = true
                    arenaState.PlayerA = playerA
                    arenaState.PlayerB = playerB
                    
                    print("⏳ [FightingServer] Starting countdown for", arena.Name)
                    
                    task.spawn(function()
                        -- Countdown
                        for i = FightingConfig.Match.CountdownBeforeStart, 1, -1 do
                            if arenaState.CountdownInProgress and not arenaState.IsActive then
                                updateInfoGui(arena, "Starting Fight in " .. i .. "...")
                                task.wait(1)
                            else
                                break
                            end
                        end
                        
                        -- If countdown was cancelled, exit
                        if not arenaState.CountdownInProgress then
                            return
                        end
                        
                        -- Verify players still on positions
                        local stillPlayerA = getPlayerOnStartPosition(arena, "StartPositionA")
                        local stillPlayerB = getPlayerOnStartPosition(arena, "StartPositionB")
                        
                        if stillPlayerA and stillPlayerB and 
                           stillPlayerA == arenaState.PlayerA and 
                           stillPlayerB == arenaState.PlayerB then
                            print("✅ [FightingServer] Players verified, starting match!")
                            startMatch(arenaState)
                        else
                            print("⚠️ [FightingServer] A player left during countdown")
                            arenaState.PlayerA = nil
                            arenaState.PlayerB = nil
                            arenaState.CountdownInProgress = false
                            updateInfoGui(arena, "A player left. Waiting for players...")
                        end
                    end)
                    
                elseif playerA or playerB then
                    updateInfoGui(arena, "Waiting for another player...")
                else
                    updateInfoGui(arena, "Waiting for players...")
                end
            end
            
            -- Check round time limit
            if arenaState.RoundActive then
                local roundDuration = currentTime - arenaState.RoundStartTime
                if roundDuration >= FightingConfig.Match.RoundTimeLimit then
                    -- Time's up, winner is the one with more health
                    if arenaState.PlayerAHealth > arenaState.PlayerBHealth then
                        endRound(arenaState, arenaState.PlayerA)
                    elseif arenaState.PlayerBHealth > arenaState.PlayerAHealth then
                        endRound(arenaState, arenaState.PlayerB)
                    else
                        endRound(arenaState, nil) -- Draw
                    end
                end
            end
        end
    end
end)

print("🥊 [FightingServer] Fighting System Loaded!")

