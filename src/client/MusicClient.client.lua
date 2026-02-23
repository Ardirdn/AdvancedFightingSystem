--[[
    MusicClient.client.lua
    Client-side music system
    
    Features:
    - Ambient music playlist (plays in rotation)
    - Fight music (loops during fight)
    - Smooth transitions between tracks
    - Only fight music plays for fighters, not spectators
]]

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- ============================================
-- MUSIC CONFIGURATION
-- ============================================

local AMBIENT_MUSIC = {
    -- -- "rbxassetid://103426481887414",
    -- "rbxassetid://136984059275458",
    -- "rbxassetid://73362118774963",
    -- "rbxassetid://88650162439186",
    "rbxassetid://1836516329",
}

local FIGHT_MUSIC = "rbxassetid://9038254260"

local MUSIC_VOLUME = 0.7          -- Default volume
local FIGHT_MUSIC_VOLUME = 0.7   -- Fight music volume
local FADE_DURATION = 1.5         -- Fade in/out duration in seconds

-- ============================================
-- MUSIC STATE
-- ============================================

local currentAmbientIndex = 1
local isInFight = false
local ambientSound = nil
local fightSound = nil

-- ============================================
-- SOUND CREATION
-- ============================================

local function createSound(soundId, name, looped, volume)
    local sound = Instance.new("Sound")
    sound.Name = name
    sound.SoundId = soundId
    sound.Volume = volume or MUSIC_VOLUME
    sound.Looped = looped or false
    sound.PlaybackSpeed = 1
    sound.RollOffMode = Enum.RollOffMode.Linear
    sound.Parent = SoundService
    return sound
end

-- Create ambient sound
ambientSound = createSound(AMBIENT_MUSIC[1], "AmbientMusic", false, MUSIC_VOLUME)

-- Create fight sound (looped)
fightSound = createSound(FIGHT_MUSIC, "FightMusic", true, 0) -- Start at 0 volume

-- ============================================
-- FADE FUNCTIONS
-- ============================================

local function fadeIn(sound, targetVolume, duration)
    if not sound then return end
    
    sound.Volume = 0
    sound:Play()
    
    local tweenInfo = TweenInfo.new(duration or FADE_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(sound, tweenInfo, {Volume = targetVolume or MUSIC_VOLUME})
    tween:Play()
    
    return tween
end

local function fadeOut(sound, duration)
    if not sound or not sound.IsPlaying then return end
    
    local tweenInfo = TweenInfo.new(duration or FADE_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local tween = TweenService:Create(sound, tweenInfo, {Volume = 0})
    tween:Play()
    
    tween.Completed:Connect(function()
        sound:Stop()
    end)
    
    return tween
end

-- ============================================
-- AMBIENT MUSIC PLAYER
-- ============================================

local function playNextAmbient()
    if isInFight then return end -- Don't play ambient during fight
    
    -- Update to next track
    currentAmbientIndex = currentAmbientIndex + 1
    if currentAmbientIndex > #AMBIENT_MUSIC then
        currentAmbientIndex = 1
    end
    
    -- Set new track
    ambientSound.SoundId = AMBIENT_MUSIC[currentAmbientIndex]
    
    -- Play with fade in
    fadeIn(ambientSound, MUSIC_VOLUME)
    
    print("🎵 [Music] Now playing ambient track:", currentAmbientIndex)
end

local function startAmbientMusic()
    if isInFight then return end
    
    -- Shuffle start position (optional - make it random on join)
    currentAmbientIndex = math.random(1, #AMBIENT_MUSIC)
    
    ambientSound.SoundId = AMBIENT_MUSIC[currentAmbientIndex]
    fadeIn(ambientSound, MUSIC_VOLUME)
    
    print("🎵 [Music] Starting ambient music playlist")
end

-- Listen for ambient track ending
ambientSound.Ended:Connect(function()
    if not isInFight then
        task.wait(1) -- Short pause between tracks
        playNextAmbient()
    end
end)

-- ============================================
-- FIGHT MUSIC
-- ============================================

local function startFightMusic()
    if isInFight then return end
    
    isInFight = true
    
    -- Fade out ambient
    fadeOut(ambientSound, FADE_DURATION * 0.5)
    
    -- Wait a bit then start fight music
    task.delay(FADE_DURATION * 0.3, function()
        if isInFight then
            fadeIn(fightSound, FIGHT_MUSIC_VOLUME)
            print("🎵 [Music] Fight music started!")
        end
    end)
end

local function stopFightMusic()
    if not isInFight then return end
    
    isInFight = false
    
    -- Fade out fight music
    fadeOut(fightSound, FADE_DURATION)
    
    -- Resume ambient music after fade
    task.delay(FADE_DURATION + 0.5, function()
        if not isInFight then
            startAmbientMusic()
            print("🎵 [Music] Resuming ambient music")
        end
    end)
end

-- ============================================
-- EVENT LISTENERS (Fighting System)
-- ============================================

-- Wait for FightingRemotes
local function setupFightingEvents()
    local remotes = ReplicatedStorage:WaitForChild("FightingRemotes", 10)
    if not remotes then
        warn("⚠️ [Music] FightingRemotes not found")
        return
    end
    
    -- Listen for match start
    local startMatchEvent = remotes:FindFirstChild("StartMatch")
    if startMatchEvent then
        startMatchEvent.OnClientEvent:Connect(function(matchData)
            -- This event is only fired to the fighters, so we know we're in a fight
            print("🎵 [Music] Match started - switching to fight music")
            startFightMusic()
        end)
    end
    
    -- Listen for match end
    -- Note: Fight music will stop when player closes result screen (via _G.StopFightMusic)
    local endMatchEvent = remotes:FindFirstChild("EndMatch")
    if endMatchEvent then
        endMatchEvent.OnClientEvent:Connect(function(matchResult)
            -- Music will continue until result screen is closed
            -- FightingUI.client.lua will call _G.StopFightMusic() when close button is pressed
            print("🎵 [Music] Match ended - waiting for result screen close")
        end)
    end
    
    print("✅ [Music] Fighting events connected")
end

-- ============================================
-- GLOBAL MUSIC CONTROL (for other scripts to use)
-- ============================================

-- Expose music control functions globally
_G.StopFightMusic = function()
    print("🎵 [Music] StopFightMusic called - resuming ambient")
    stopFightMusic()
end

_G.StartFightMusic = function()
    print("🎵 [Music] StartFightMusic called")
    startFightMusic()
end

_G.SetMusicVolume = function(volume)
    MUSIC_VOLUME = volume
    if not isInFight and ambientSound then
        ambientSound.Volume = volume
    end
end

_G.SetFightMusicVolume = function(volume)
    FIGHT_MUSIC_VOLUME = volume
    if isInFight and fightSound then
        fightSound.Volume = volume
    end
end

-- ============================================
-- INITIALIZATION
-- ============================================

-- Start ambient music when player joins
task.spawn(function()
    task.wait(2) -- Wait for game to initialize
    startAmbientMusic()
end)

-- Setup fighting event listeners
task.spawn(function()
    setupFightingEvents()
end)

-- Cleanup when player leaves (optional)
Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        if ambientSound then ambientSound:Stop() end
        if fightSound then fightSound:Stop() end
    end
end)

print("✅ [MusicClient] Music system initialized")
print("   Ambient tracks:", #AMBIENT_MUSIC)
print("   Fight music ready")
print("   Use _G.StopFightMusic() to resume ambient music")
