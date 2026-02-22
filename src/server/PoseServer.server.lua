--[[
    PoseServer.server.lua
    Server script for Pose/Dance System
    
    Handles:
    - Replicating pose animations to all players
    - Validating pose requests
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🎭 [PoseServer] Loading...")

-- Wait for Modules
local Modules = ReplicatedStorage:WaitForChild("Modules", 10)
if not Modules then
    warn("❌ [PoseServer] Modules folder not found!")
    return
end

local PoseConfig = require(Modules:WaitForChild("PoseConfig"))

-- ============================================
-- CREATE REMOTE EVENTS
-- ============================================
local PoseRemotes = Instance.new("Folder")
PoseRemotes.Name = "PoseRemotes"
PoseRemotes.Parent = ReplicatedStorage

-- PlayPose: Client -> Server -> All Clients
local PlayPoseEvent = Instance.new("RemoteEvent")
PlayPoseEvent.Name = "PlayPose"
PlayPoseEvent.Parent = PoseRemotes

-- StopPose: Client -> Server -> All Clients
local StopPoseEvent = Instance.new("RemoteEvent")
StopPoseEvent.Name = "StopPose"
StopPoseEvent.Parent = PoseRemotes

print("✅ [PoseServer] Remote events created")

-- ============================================
-- VALID ANIMATION IDS (for security)
-- ============================================
local validAnimationIds = {}
for _, pose in ipairs(PoseConfig.Poses) do
    validAnimationIds[pose.AnimationId] = true
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

-- Track who is currently posing
local activePoses = {} -- [Player] = animationId

PlayPoseEvent.OnServerEvent:Connect(function(player, animationId)
    -- Validate animation ID
    if not validAnimationIds[animationId] then
        warn("⚠️ [PoseServer] Invalid animation ID from", player.Name, ":", animationId)
        return
    end
    
    print("🎭 [PoseServer]", player.Name, "playing pose:", animationId)
    
    -- Store active pose
    activePoses[player] = animationId
    
    -- Replicate to all OTHER clients (not the sender)
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            PlayPoseEvent:FireClient(otherPlayer, player, animationId)
        end
    end
end)

StopPoseEvent.OnServerEvent:Connect(function(player)
    print("🎭 [PoseServer]", player.Name, "stopped pose")
    
    -- Clear active pose
    activePoses[player] = nil
    
    -- Replicate to all OTHER clients
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            StopPoseEvent:FireClient(otherPlayer, player)
        end
    end
end)

-- Cleanup when player leaves
Players.PlayerRemoving:Connect(function(player)
    activePoses[player] = nil
end)

print("========================================")
print("🎭 [PoseServer] Pose Server Loaded!")
print("========================================")
