--[[
    FightingClient.client.lua
    Main client script for Fighting System
    
    Handles:
    - Input detection (PC & Mobile)
    - Combat actions (Attack, Block, Dodge)
    - Animation playback
    - Camera control during fight
]]

print("========================================")
print("🥊 [FightingClient] Script starting...")
print("========================================")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")

print("✅ [FightingClient] Services loaded")

local Player = Players.LocalPlayer
print("✅ [FightingClient] LocalPlayer:", Player.Name)

local Character = Player.Character or Player.CharacterAdded:Wait()
print("✅ [FightingClient] Character found")

local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")
local Animator = Humanoid:WaitForChild("Animator")
local Camera = workspace.CurrentCamera
print("✅ [FightingClient] Character components loaded")

-- Wait for Modules
print("⏳ [FightingClient] Waiting for Modules...")
local Modules = ReplicatedStorage:WaitForChild("Modules", 10)
if not Modules then
    warn("❌ [FightingClient] Modules folder not found!")
    return
end
print("✅ [FightingClient] Modules folder found")

local FightingConfig = require(Modules:WaitForChild("FightingConfig"))
print("✅ [FightingClient] FightingConfig loaded")

local AnimationConfig = require(Modules:WaitForChild("AnimationConfig"))
print("✅ [FightingClient] AnimationConfig loaded")

local SoundConfig = require(Modules:WaitForChild("SoundConfig"))
print("✅ [FightingClient] SoundConfig loaded")

-- Wait for Remotes
print("⏳ [FightingClient] Waiting for FightingRemotes...")
local FightingRemotes = ReplicatedStorage:WaitForChild("FightingRemotes", 10)
if not FightingRemotes then
    warn("❌ [FightingClient] FightingRemotes folder not found! Server might not have loaded yet.")
    return
end
print("✅ [FightingClient] FightingRemotes found")

local StartMatchEvent = FightingRemotes:WaitForChild("StartMatch")
local EndMatchEvent = FightingRemotes:WaitForChild("EndMatch")
local RoundStartEvent = FightingRemotes:WaitForChild("RoundStart")
local RoundEndEvent = FightingRemotes:WaitForChild("RoundEnd")
local UpdateStatsEvent = FightingRemotes:WaitForChild("UpdateStats")
local DealDamageEvent = FightingRemotes:WaitForChild("DealDamage")
local BlockEvent = FightingRemotes:WaitForChild("Block")
local DodgeEvent = FightingRemotes:WaitForChild("Dodge")
local CameraShakeEvent = FightingRemotes:WaitForChild("CameraShake")
print("✅ [FightingClient] All remote events loaded")

-- ============================================
-- DEBUG CONFIGURATION
-- ============================================
-- Set DEBUG_MODE = true to test animations & buttons WITHOUT being in an arena.
-- Mobile buttons become clickable everywhere, isRoundActive check is bypassed.
-- Set back to FALSE before publishing to production!
local DEBUG_MODE = true

-- ============================================
-- STATE VARIABLES
-- ============================================

local isInMatch = false
local isRoundActive = false
local currentOpponent = nil
local mySide = nil -- "A" or "B"

-- Cache helper (performance optimization)
local function _cacheEnabled()
	return FightingConfig._runtimeState and FightingConfig._runtimeState._v == 1
end

-- Combat state
local isBlocking = false
local isDodging = false
local isAttacking = false
local comboStep = 1            -- light attack combo index
local heavyComboStep = 1       -- heavy attack combo index
local lastAttackTime = 0
local lastHeavyAttackTime = 0  -- added to track heavy attack combos
local heavyAttackCooldown = 0  -- tick() timestamp when heavy cooldown expires
local dodgeCooldownEnd = 0     -- tick() timestamp when dodge cooldown expires

-- Debug dummy
local debugDummy = nil           -- Model ref set when H spawns a dummy
local SpawnDebugDummyEvent = nil -- fetched in DEBUG_MODE block
local HitDebugDummyEvent   = nil -- fetched in DEBUG_MODE block
local _cameraShakeFn       = nil -- forward-ref: assigned after cameraShake is defined

-- Stats (received from server)
local myHealth = 100
local myStamina = 100
local opponentHealth = 100
local opponentStamina = 100

-- Loaded animations
local animationTracks = {}

-- Mobile controls
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================
-- DEBUG HELPER
-- ============================================
-- Returns true if the player is allowed to perform combat actions.
-- In DEBUG_MODE this is always true; otherwise requires an active round.
local function canAct()
    return isRoundActive or DEBUG_MODE
end

-- ============================================
-- ANIMATION LOADING
-- ============================================

local function loadAnimations()
    -- Clear existing
    for _, track in pairs(animationTracks) do
        if track then
            track:Stop()
            track:Destroy()
        end
    end
    animationTracks = {}
    
    -- Block animation
    animationTracks.Block = AnimationConfig.LoadAnimation(
        Animator, 
        AnimationConfig.Block.BlockHold, 
        true, -- looped
        Enum.AnimationPriority.Action
    )
    
    -- Attack combo animations
    animationTracks.Attack = {}
    for i, animId in ipairs(AnimationConfig.Attack.Combo) do
        animationTracks.Attack[i] = AnimationConfig.LoadAnimation(
            Animator,
            animId,
            false,
            Enum.AnimationPriority.Action
        )
    end
    
    -- Hit animations
    animationTracks.Hit = {}
    for i, animId in ipairs(AnimationConfig.Attack.Hit) do
        animationTracks.Hit[i] = AnimationConfig.LoadAnimation(
            Animator,
            animId,
            false,
            Enum.AnimationPriority.Action2
        )
    end
    
    -- Heavy attack combos (array, sama seperti light attack)
    animationTracks.HeavyAttack = {}
    for i, animData in ipairs(AnimationConfig.HeavyAttack.Combo) do
        local animId = (type(animData) == "table") and animData.id or animData
        if animId then
            animationTracks.HeavyAttack[i] = AnimationConfig.LoadAnimation(
                Animator,
                animId,
                false,
                Enum.AnimationPriority.Action
            )
        end
    end

    -- Heavy hit animations (array)
    animationTracks.HeavyHit = {}
    for i, animId in ipairs(AnimationConfig.HeavyAttack.Hit) do
        animationTracks.HeavyHit[i] = AnimationConfig.LoadAnimation(
            Animator,
            animId,
            false,
            Enum.AnimationPriority.Action2
        )
    end

    -- Fight walk animation (looped, lower priority saat fight)
    animationTracks.FightWalk = AnimationConfig.LoadAnimation(
        Animator,
        AnimationConfig.Idle.FightWalk,
        true,
        Enum.AnimationPriority.Movement
    )

    print("🎬 [FightingClient] Animations loaded")
end

-- ============================================
-- DAMAGE NUMBER POPUP
-- ============================================

local function showDamageNumber(targetCharacter, damage)
    if not targetCharacter then return end
    
    local head = targetCharacter:FindFirstChild("Head")
    if not head then return end
    
    -- Create BillboardGui for the damage number
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DamageNumber"
    billboard.Size = UDim2.new(8, 0, 4, 0) -- Very big size in studs
    billboard.StudsOffset = Vector3.new(math.random(-2, 2), 4 + math.random() * 2, math.random(-1, 1)) -- Random position, higher up
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 200 -- Visible from very far away
    billboard.Parent = head
    
    -- Create the damage text
    local damageLabel = Instance.new("TextLabel")
    damageLabel.Name = "DamageText"
    damageLabel.Size = UDim2.new(1, 0, 1, 0)
    damageLabel.BackgroundTransparency = 1
    damageLabel.Font = Enum.Font.GothamBlack
    damageLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- Red color
    damageLabel.TextStrokeColor3 = Color3.fromRGB(50, 0, 0)
    damageLabel.TextStrokeTransparency = 0
    damageLabel.TextScaled = true -- Scale text to fit
    damageLabel.Text = "-" .. tostring(damage)
    damageLabel.Parent = billboard
    
    -- Animate: float up and fade out
    local startOffset = billboard.StudsOffset
    local endOffset = startOffset + Vector3.new(0, 4, 0)
    local startSize = billboard.Size
    
    task.spawn(function()
        local duration = 1.2
        local startTime = tick()
        
        while tick() - startTime < duration do
            local progress = (tick() - startTime) / duration
            local easedProgress = 1 - (1 - progress) * (1 - progress) -- Ease out
            
            -- Float up
            billboard.StudsOffset = startOffset:Lerp(endOffset, easedProgress)
            
            -- Fade out (last 40% of animation)
            if progress > 0.6 then
                local fadeProgress = (progress - 0.6) / 0.4
                damageLabel.TextTransparency = fadeProgress
                damageLabel.TextStrokeTransparency = fadeProgress
            end
            
            -- Scale down the billboard slightly
            local scaleFactor = 1 - (0.3 * easedProgress)
            billboard.Size = UDim2.new(startSize.X.Scale * scaleFactor, 0, startSize.Y.Scale * scaleFactor, 0)
            
            task.wait()
        end
        
        billboard:Destroy()
    end)
end

-- ============================================
-- SOUND SYSTEM (with preloading and cooldown)
-- ============================================

local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

-- Preloaded sound instances
local preloadedSounds = {
    PunchHit = {},
    VictimHit = {},
    Whoosh = {},
}
local soundsPreloaded = false

-- Preload all sounds at match start
local function preloadAllSounds()
    if soundsPreloaded then return end
    print("🔊 [Sound] Preloading combat sounds...")
    
    local s = SoundConfig.Sounds
    local toLoad = {
        { name = "PunchHit", data = s.PunchHit, vol = s.PunchVolume or 0.8 },
        { name = "VictimHit", data = s.VictimHit, vol = s.HitVolume or 0.8 },
        { name = "Whoosh", data = s.Whoosh, vol = s.WhooshVolume or 0.8 },
    }
    
    local assetsToPreload = {}
    
    for _, group in ipairs(toLoad) do
        if group.data then
            for i, soundId in ipairs(group.data) do
                local sound = Instance.new("Sound")
                sound.SoundId = soundId
                sound.Volume = group.vol
                sound.Parent = SoundService
                preloadedSounds[group.name][i] = sound
                table.insert(assetsToPreload, sound)
            end
        end
    end
    
    ContentProvider:PreloadAsync(assetsToPreload)
    soundsPreloaded = true
    print("🔊 [Sound] All combat sounds preloaded!")
end

local function playSoundEffect(soundCategory)
    local soundList = preloadedSounds[soundCategory]
    if not soundList or #soundList == 0 then return end
    
    -- Pick random preloaded sound and play
    local randomIndex = math.random(1, #soundList)
    local sound = soundList[randomIndex]
    
    if sound and not sound.IsPlaying then
        sound:Play()
    else
        -- If sound is playing, try another random one
        for i = 1, #soundList do
            local altSound = soundList[((randomIndex + i - 1) % #soundList) + 1]
            if altSound and not altSound.IsPlaying then
                altSound:Play()
                break
            end
        end
    end
end

local function playResultSound(isWin)
    local soundId = isWin and SoundConfig.Sounds.Win or SoundConfig.Sounds.Lose
    if not soundId then return end
    
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = SoundConfig.Sounds.WinLoseVolume or 0.7
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- ============================================
-- COMBAT ACTIONS
-- ============================================

local function stopAllCombatAnimations()
    for name, track in pairs(animationTracks) do
        if type(track) == "table" then
            for _, t in pairs(track) do
                if t and t.IsPlaying then t:Stop() end
            end
        elseif track and track.IsPlaying then
            track:Stop()
        end
    end
end

-- ============================================
-- HIT PARTICLES
-- ============================================
local EffectsFolder = ReplicatedStorage:FindFirstChild("Effects")

local function playHitParticles(targetCharacter)
    if not EffectsFolder or not targetCharacter then return end
    
    -- Selalu munculkan di tengah badan (Torso / UpperTorso / HRP)
    local targetPart = targetCharacter:FindFirstChild("UpperTorso") 
                    or targetCharacter:FindFirstChild("Torso")
                    or targetCharacter:FindFirstChild("HumanoidRootPart")
    
    if not targetPart then return end
    
    -- Selalu munculkan efek "Hit"
    local effectsToPlay = {"Hit"}
    
    -- BloodSplat lebih jarang (misal ~25% chance), mainkan BERSAMAAN dengan Hit
    if math.random(1, 100) <= 25 then
        table.insert(effectsToPlay, "BloodSplat")
    end
    
    for _, effectName in ipairs(effectsToPlay) do
        local effectPrefab = EffectsFolder:FindFirstChild(effectName)
        if effectPrefab then
            local sourceAtt = effectPrefab:FindFirstChild("Middle")
            if sourceAtt and sourceAtt:IsA("Attachment") then
                -- Clone attachment berisi particle
                local cloneAtt = sourceAtt:Clone()
                
                -- Posisi selalu konstan di titik tengah (offset 0)
                cloneAtt.Position = Vector3.zero
                cloneAtt.Parent = targetPart
                
                -- Emit partikel 1 kali
                for _, child in ipairs(cloneAtt:GetChildren()) do
                    if child:IsA("ParticleEmitter") then
                        child.Enabled = false
                        child:Emit(1)
                    end
                end
                
                -- Cleanup setelah 1.5 detik
                task.delay(1.5, function()
                    if cloneAtt and cloneAtt.Parent then
                        cloneAtt:Destroy()
                    end
                end)
            end
        end
    end
end

-- ============================================
-- DEBUG DUMMY HIT HELPER
-- ============================================
-- Checks if debugDummy is within attack range and registers a hit on it.
-- Only active when DEBUG_MODE = true.
local function hitDebugDummy(attackType, comboStep)
    if not DEBUG_MODE then return end
    if not debugDummy or not debugDummy.Parent then return end
    local dHRP = debugDummy:FindFirstChild("HumanoidRootPart")
    if not dHRP then return end

    local cfg  = attackType == "Heavy"
                 and FightingConfig.Combat.HeavyAttack
                 or  FightingConfig.Combat.LightAttack
    local dist = (HRP.Position - dHRP.Position).Magnitude

    if dist <= (cfg.Range + 3) then   -- +3 studs buffer (dummy is stationary)
        print("🎯 [DEBUG] Hit dummy with", attackType, "| dist:", string.format("%.1f", dist))

        -- Audio + screen shake feedback (client only)
        playSoundEffect("PunchHit")
        playHitParticles(debugDummy)  -- Spawn particles
        local sh = FightingConfig.Camera.AttackShake
        if _cameraShakeFn then   -- assigned later once cameraShake is defined
            _cameraShakeFn(sh.Amplitude, sh.Frequency, sh.Duration, sh.ZoomAmount, false)
        end

        -- Tell server to register hit (shows HP on billboard)
        if HitDebugDummyEvent then
            HitDebugDummyEvent:FireServer(attackType, comboStep)
        end
    end
end

-- ============================================
-- ATTACKER PUSH FORWARD
-- ============================================
-- Saat hit connect, attacker melaju 3 stud ke depan (ke arah musuh).
local function pushAttackerForward()
    if not HRP then return end
    task.spawn(function()
        local cfg = FightingConfig.Combat.PushMechanics.Attacker
        
        if cfg.Delay > 0 then
            task.wait(cfg.Delay)
        end
        
        local pushDir = HRP.CFrame.LookVector
        pushDir = Vector3.new(pushDir.X, 0, pushDir.Z).Unit
        
        local speed = cfg.Distance / cfg.Duration
        local bv = Instance.new("BodyVelocity")
        bv.Velocity  = pushDir * speed
        bv.MaxForce  = Vector3.new(1e6, 0, 1e6)     -- horizontal only
        bv.P         = 1e6
        bv.Parent    = HRP
        
        task.wait(cfg.Duration)
        if bv and bv.Parent then bv:Destroy() end
    end)
end

local function performLightAttack()
    if not _cacheEnabled() then return end
    print("👊 [COMBAT] performLightAttack() called")
    print("   - isRoundActive:", isRoundActive)
    print("   - isBlocking:", isBlocking)
    print("   - isDodging:", isDodging)
    print("   - isAttacking:", isAttacking)
    
    if not canAct() then
        print("   ❌ BLOCKED: Round not active (and DEBUG_MODE is off)")
        return
    end
    if isBlocking then
        print("   ❌ BLOCKED: Currently blocking")
        return
    end
    if isDodging then
        print("   ❌ BLOCKED: Currently dodging")
        return
    end
    if isAttacking then
        print("   ❌ BLOCKED: Currently attacking")
        return
    end
    
    local config = FightingConfig.Combat.LightAttack
    local currentTime = tick()
    
    -- Check combo window
    if currentTime - lastAttackTime > config.ComboWindow then
        comboStep = 1
    end
    
    -- Check cooldown
    if currentTime - lastAttackTime < config.Cooldown then
        print("   ❌ BLOCKED: On cooldown")
        return
    end
    
    -- Check stamina (skipped in DEBUG_MODE)
    print("   - myStamina:", myStamina, "/ required:", config.StaminaCost)
    if not DEBUG_MODE and myStamina < config.StaminaCost then
        print("   ❌ BLOCKED: Not enough stamina")
        return
    end
    
    print("   ✅ All checks passed! Executing attack...")
    
    isAttacking = true
    lastAttackTime = currentTime
    
    -- Play attack animation
    local attackTrack = animationTracks.Attack and animationTracks.Attack[comboStep]
    print("   - comboStep:", comboStep)
    print("   - attackTrack exists:", attackTrack ~= nil)
    
    if attackTrack then
        stopAllCombatAnimations()
        attackTrack:Play()
        print("   ✅ Animation playing")
        -- Wait for windup then fire damage event
        local windupTime = attackTrack.Length * 0.3
        task.delay(windupTime, function()
            playSoundEffect("Whoosh")
            pushAttackerForward()
            hitDebugDummy("Light", comboStep)
            if isRoundActive then
                DealDamageEvent:FireServer("Light", comboStep)
            end
        end)
        
        -- Animation finished callback
        local conn
        conn = attackTrack.Stopped:Connect(function()
            conn:Disconnect()
            isAttacking = false
            
            -- Advance combo: flexible, pakai jumlah animasi yg di-load (bukan MaxComboHits)
            local numAnims = #animationTracks.Attack
            if numAnims > 0 then
                comboStep = (comboStep % numAnims) + 1
            end
        end)
    else
        isAttacking = false
        DealDamageEvent:FireServer("Light", comboStep)
        comboStep = 1
    end
end

local function performHeavyAttack()
    if not _cacheEnabled() then return end
    print("💪 [COMBAT] performHeavyAttack() called")
    print("   - isRoundActive:", isRoundActive)
    print("   - isBlocking:", isBlocking)
    print("   - isDodging:", isDodging)
    print("   - isAttacking:", isAttacking)
    
    if not canAct() then print("   ❌ Not in active round (and DEBUG_MODE is off)") return end
    if isBlocking then print("   ❌ Currently blocking") return end
    if isDodging  then print("   ❌ Currently dodging")  return end
    if isAttacking then print("   ❌ Currently attacking") return end
    
    local config = FightingConfig.Combat.HeavyAttack
    local currentTime = tick()
    
    -- Check combo window: Jika lebih lama dari cooldown + jeda waktu, reset ke hit 1
    -- (Menggunakan ComboWindow milik LightAttack sebagai fallback tolerance jika user telat mencet)
    local comboWindow = FightingConfig.Combat.LightAttack.ComboWindow or 1.5
    if currentTime - lastHeavyAttackTime > (config.Cooldown + comboWindow) then
        heavyComboStep = 1
    end
    
    -- Check cooldown
    if currentTime < heavyAttackCooldown then
        print("   ❌ On cooldown")
        return
    end
    
    -- Check stamina (skipped in DEBUG_MODE)
    print("   - myStamina:", myStamina, "/ required:", config.StaminaCost)
    if not DEBUG_MODE and myStamina < config.StaminaCost then
        print("   ❌ Not enough stamina")
        return
    end
    
    print("   ✅ All checks passed! Executing heavy attack...")
    
    isAttacking = true
    lastHeavyAttackTime = currentTime
    heavyAttackCooldown = currentTime + config.Cooldown
    
    -- Pick heavy attack track from combo array
    local numHeavy  = #animationTracks.HeavyAttack
    local heavyTrack = numHeavy > 0 and animationTracks.HeavyAttack[heavyComboStep] or nil

    if heavyTrack then
        stopAllCombatAnimations()
        heavyTrack:Play()
        
        -- Ambil DamageTime dari konfigurasi HeavyAttack di AnimationConfig
        local damageTime = config.ChargeTime
        if AnimationConfig.HeavyAttack and AnimationConfig.HeavyAttack.Combo and AnimationConfig.HeavyAttack.Combo[heavyComboStep] then
            local animData = AnimationConfig.HeavyAttack.Combo[heavyComboStep]
            if type(animData) == "table" and animData.DamageTime then
                damageTime = animData.DamageTime
            end
        end
        
        -- Charge / Delay time before dealing damage and pushforward
        task.delay(damageTime, function()
            playSoundEffect("Whoosh")
            pushAttackerForward()
            hitDebugDummy("Heavy", heavyComboStep)
            if isRoundActive then
                DealDamageEvent:FireServer("Heavy", heavyComboStep)
            end
        end)
        
        local conn
        conn = heavyTrack.Stopped:Connect(function()
            conn:Disconnect()
            isAttacking = false
            -- Advance heavy combo step
            heavyComboStep = (heavyComboStep % math.max(1, numHeavy)) + 1
        end)
    else
        isAttacking = false
        DealDamageEvent:FireServer("Heavy", heavyComboStep)
        heavyComboStep = (heavyComboStep % math.max(1, #animationTracks.HeavyAttack)) + 1
    end
end

local function startBlock()
    if not _cacheEnabled() then return end
    print("🛡️ [COMBAT] startBlock() called")
    print("   - isRoundActive:", isRoundActive)
    print("   - isAttacking:", isAttacking)
    print("   - isDodging:", isDodging)
    print("   - isBlocking:", isBlocking)
    
    if not canAct() then print("   ❌ Not in active round (and DEBUG_MODE is off)") return end
    if isAttacking then print("   ❌ Currently attacking") return end
    if isDodging   then print("   ❌ Currently dodging")  return end
    if isBlocking  then print("   ❌ Already blocking")   return end
    
    local config = FightingConfig.Combat.Block
    
    -- Check stamina (skipped in DEBUG_MODE)
    print("   - myStamina:", myStamina, "/ required:", config.StaminaCost)
    if not DEBUG_MODE and myStamina < config.StaminaCost then
        print("   ❌ Not enough stamina")
        return
    end
    
    print("   ✅ Block started!")
    isBlocking = true
    BlockEvent:FireServer(true)
    
    -- Play block animation
    local blockTrack = animationTracks.Block
    if blockTrack then
        stopAllCombatAnimations()
        blockTrack:Play()
    end
end

local function stopBlock()
    if not isBlocking then return end
    
    isBlocking = false
    BlockEvent:FireServer(false)
    
    local blockTrack = animationTracks.Block
    if blockTrack and blockTrack.IsPlaying then
        blockTrack:Stop()
    end
end

local function performDodge(direction)
    if not _cacheEnabled() then return end
    if not canAct() or isBlocking or isAttacking or isDodging then return end
    
    local config = FightingConfig.Combat.Dodge
    
    -- Check stamina (skipped in DEBUG_MODE)
    if not DEBUG_MODE and myStamina < config.StaminaCost then return end
    
    isDodging = true
    DodgeEvent:FireServer(direction)
    
    -- Calculate movement direction
    local moveDir = Vector3.new(0, 0, 0)
    
    if direction == "Forward" then
        moveDir = HRP.CFrame.LookVector
    elseif direction == "Backward" then
        moveDir = -HRP.CFrame.LookVector
    elseif direction == "Left" then
        moveDir = -HRP.CFrame.RightVector
    elseif direction == "Right" then
        moveDir = HRP.CFrame.RightVector
    end
    
    -- Normalize direction on horizontal plane
    moveDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
    
    -- Play dodge animation
    local dodgeTrack = animationTracks.Dodge
    if dodgeTrack then
        stopAllCombatAnimations()
        dodgeTrack:Play()
    end
    
    -- ============================================
    -- COLLISION-AWARE DODGE USING BODYVELOCITY
    -- ============================================
    -- Hitung speed yang dibutuhkan dari Distance dan Duration di config
    local duration = config.Duration or 0.3
    local distance = config.Distance or 15
    local speed = distance / duration
    
    task.spawn(function()
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = moveDir * speed
        bv.MaxForce = Vector3.new(1e6, 0, 1e6) -- Horizontal drift only
        bv.P = 1e6
        bv.Parent = HRP
        
        task.wait(duration)
        if bv and bv.Parent then bv:Destroy() end
        isDodging = false
    end)
    
    -- Fallback timeout safety
    task.delay(duration + 0.1, function()
        isDodging = false
    end)

    -- Reset combo saat dodge (player interrupted)
    comboStep = 1
    heavyComboStep = 1
end

-- ============================================
-- CAMERA SYSTEM
-- ============================================

local fightCameraActive = false
local fightCameraConn = nil
local previousCameraCFrame = nil
local previousCameraSubject = nil
local previousAutoRotate = nil


local function startFightCamera()
    if fightCameraActive then return end
    
    fightCameraActive = true
    previousCameraCFrame = Camera.CFrame
    previousCameraSubject = Camera.CameraSubject
    
    -- Disable auto rotate for manual control
    if Humanoid then
        previousAutoRotate = Humanoid.AutoRotate
        if FightingConfig.Camera.LockPlayerRotation then
            Humanoid.AutoRotate = false
        end
    end
    
    -- Lock player zoom to fight distance
    Player.CameraMinZoomDistance = FightingConfig.Camera.FightCameraDistance
    Player.CameraMaxZoomDistance = FightingConfig.Camera.FightCameraDistance
    
    -- Set camera to scriptable mode for full control
    Camera.CameraType = Enum.CameraType.Scriptable
    
    -- Tween FOV to fight mode
    local fightFOV = FightingConfig.Camera.FightFieldOfView or 60
    TweenService:Create(Camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        FieldOfView = fightFOV
    }):Play()
    
    -- Store current player rotation for smooth interpolation
    local currentPlayerYRotation = 0
    if HRP then
        local _, y, _ = HRP.CFrame:ToEulerAnglesYXZ()
        currentPlayerYRotation = y
    end
    
    fightCameraConn = RunService.RenderStepped:Connect(function(dt)
        if not fightCameraActive then return end
        if not HRP or not HRP.Parent then return end
        
        -- Get opponent position for look-at
        local opponentPos = nil
        if currentOpponent and currentOpponent.Character then
            local opponentHRP = currentOpponent.Character:FindFirstChild("HumanoidRootPart")
            if opponentHRP then
                opponentPos = opponentHRP.Position
            end
        end
        -- DEBUG: fall back to dummy when no real opponent
        if not opponentPos and debugDummy and debugDummy.Parent then
            local dHRP = debugDummy:FindFirstChild("HumanoidRootPart")
            if dHRP then opponentPos = dHRP.Position end
        end
        
        -- Calculate look direction (toward opponent or forward)
        local lookDir
        if opponentPos then
            lookDir = (opponentPos - HRP.Position).Unit
        else
            lookDir = HRP.CFrame.LookVector
        end
        
        -- Calculate right vector (perpendicular to look direction, on horizontal plane)
        local rightVector = lookDir:Cross(Vector3.new(0, 1, 0)).Unit
        
        -- Camera offset configuration
        local offset = FightingConfig.Camera.FightCameraOffset
        
        -- Calculate camera position
        local behindOffset = -lookDir * offset.Z
        local sideOffset = rightVector * offset.X
        local upOffset = Vector3.new(0, offset.Y, 0)
        
        local cameraPos = HRP.Position + behindOffset + sideOffset + upOffset
        
        -- Look at opponent
        local lookTarget
        if opponentPos then
            lookTarget = opponentPos + Vector3.new(0, 1.5, 0)
        else
            lookTarget = HRP.Position + lookDir * 10 + Vector3.new(0, 2, 0)
        end
        
        -- Create target camera CFrame
        local targetCFrame = CFrame.new(cameraPos, lookTarget)
        
        -- Frame-rate independent smooth camera
        local lerpSpeed = 1 - math.pow(1 - FightingConfig.Camera.CameraLerpSpeed, dt * 60)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, lerpSpeed)
        
        -- SMOOTH PLAYER ROTATION: Make player always face opponent
        if FightingConfig.Camera.LockPlayerRotation and opponentPos and Humanoid then
            local dirToOpponent = (opponentPos - HRP.Position) * Vector3.new(1, 0, 1)
            if dirToOpponent.Magnitude > 0.1 then
                -- Calculate target Y rotation
                local targetYRotation = math.atan2(-dirToOpponent.X, -dirToOpponent.Z)
                
                -- Smooth interpolation for rotation (frame-rate independent)
                local rotLerpSpeed = 1 - math.pow(1 - (FightingConfig.Camera.PlayerRotationLerpSpeed or 0.15), dt * 60)
                
                -- Handle angle wrapping
                local diff = targetYRotation - currentPlayerYRotation
                if diff > math.pi then diff = diff - 2 * math.pi end
                if diff < -math.pi then diff = diff + 2 * math.pi end
                
                currentPlayerYRotation = currentPlayerYRotation + diff * rotLerpSpeed
                
                -- Apply rotation (only Y axis, preserve position)
                HRP.CFrame = CFrame.new(HRP.Position) * CFrame.Angles(0, currentPlayerYRotation, 0)
            end
        end
    end)
    
    print("📷 [FightingClient] Fight camera started")
end

local function stopFightCamera()
    if not fightCameraActive then return end
    
    fightCameraActive = false
    
    if fightCameraConn then
        fightCameraConn:Disconnect()
        fightCameraConn = nil
    end
    
    -- Restore AutoRotate
    if Humanoid and previousAutoRotate ~= nil then
        Humanoid.AutoRotate = previousAutoRotate
    end
    
    -- Smooth transition back
    local transitionDuration = FightingConfig.Camera.TransitionDuration
    local startCFrame = Camera.CFrame
    local startTime = tick()
    
    -- Restore zoom
    Player.CameraMinZoomDistance = 0.5
    Player.CameraMaxZoomDistance = 400
    
    -- Restore FOV back to base
    TweenService:Create(Camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        FieldOfView = BASE_FOV
    }):Play()
    
    local transitionConn
    transitionConn = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        local alpha = math.min(elapsed / transitionDuration, 1)
        
        -- Ease out
        local easedAlpha = 1 - (1 - alpha) * (1 - alpha)
        
        if previousCameraCFrame then
            Camera.CFrame = startCFrame:Lerp(previousCameraCFrame, easedAlpha)
        end
        
        if alpha >= 1 then
            transitionConn:Disconnect()
            
            Camera.CameraType = Enum.CameraType.Custom
            Camera.CameraSubject = Humanoid
            
            print("📷 [FightingClient] Camera restored")
        end
    end)
end

-- Camera shake using BindToRenderStep (higher priority than fight camera)
local isShaking = false
local shakeStartTime = 0
local shakeAmplitude = 0   -- Studs - how far camera moves
local shakeFrequency = 0   -- Hz - oscillations per second  
local shakeDuration = 0    -- Seconds
local shakeZoomAmount = 0  -- Zoom in amount
local BASE_FOV = FightingConfig.Camera.BaseFOV or 70  -- Base FOV saat tidak fight

-- Shake update function bound to RenderStep (CFrame positional offset only — does NOT touch FOV)
local function updateCameraShake()
    if not isShaking then return end
    
    local elapsed = tick() - shakeStartTime
    
    if elapsed >= shakeDuration then
        isShaking = false
        RunService:UnbindFromRenderStep("FightingCameraShake")
        return
    end
    
    -- Decreasing intensity over time (ease out)
    local progress = elapsed / shakeDuration
    local currentAmplitude = shakeAmplitude * (1 - progress)
    
    -- Convert frequency (Hz) to angular velocity
    local time = tick()
    local angularVelocity = shakeFrequency * 2 * math.pi
    
    -- Sinusoidal CFrame offset (no FOV changes)
    local offsetX = math.sin(time * angularVelocity) * currentAmplitude
    local offsetY = math.cos(time * angularVelocity * 1.1) * currentAmplitude
    Camera.CFrame = Camera.CFrame * CFrame.new(offsetX, offsetY, 0)
end

local function cameraShake(amplitude, frequency, duration, zoomAmount, isHitEffect)
    -- ── FOV PUNCH EFFECT ──────────────────────────────────────────────────────
    -- Quick FOV dip on every hit/attack for cinematic impact feel.
    -- Only active when fight camera is running; never alters BASE_FOV.
    if fightCameraActive then
        local fightFOV  = FightingConfig.Camera.FightFieldOfView or 60
        local dipAmount = math.random(0, 1) == 0 and 2 or 5   -- random -5 or -10
        local dipFOV    = fightFOV - dipAmount
        local punchIn   = 0.06
        local springOut = duration * 0.8

        TweenService:Create(Camera, TweenInfo.new(punchIn, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            FieldOfView = dipFOV
        }):Play()
        task.delay(punchIn, function()
            TweenService:Create(Camera, TweenInfo.new(springOut, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                FieldOfView = fightFOV
            }):Play()
        end)
    end

    -- Set shake parameters
    shakeAmplitude  = amplitude
    shakeFrequency  = frequency
    shakeDuration   = duration
    shakeZoomAmount = zoomAmount or 0
    shakeStartTime  = tick()

    
    print("📷 [SHAKE] Started: amp=" .. amplitude .. ", freq=" .. frequency .. "Hz, dur=" .. duration .. "s, zoom=" .. (zoomAmount or 0))
    
    -- Unbind if already bound
    if isShaking then
        pcall(function()
            RunService:UnbindFromRenderStep("FightingCameraShake")
        end)
    end
    
    isShaking = true
    
    -- Bind with priority HIGHER than camera (Camera.Value + 1)
    RunService:BindToRenderStep("FightingCameraShake", Enum.RenderPriority.Camera.Value + 1, updateCameraShake)
    
    -- ============================================
    -- BLOOD SCREEN EFFECT (ColorCorrection)
    -- ============================================
    if isHitEffect then
        local hitFx = FightingConfig.Camera.HitEffects
        
        local colorCorrection = Lighting:FindFirstChild("ColorCorrection")
        if colorCorrection and hitFx then
            -- Animate to red tint + high contrast
            TweenService:Create(colorCorrection, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TintColor = hitFx.BloodTintColor or Color3.fromRGB(255, 100, 100),
                Contrast = hitFx.BloodContrast or 0.5,
            }):Play()
            
            -- Return to normal after duration
            task.delay(duration * 0.5, function()
                TweenService:Create(colorCorrection, TweenInfo.new(duration * 0.5, Enum.EasingStyle.Quad), {
                    TintColor = hitFx.DefaultTintColor or Color3.fromRGB(255, 255, 255),
                    Contrast = hitFx.DefaultContrast or 0.1,
                }):Play()
            end)
        end
        
        -- ============================================
        -- BLUR EFFECT
        -- ============================================
        local blur = Lighting:FindFirstChild("Blur")
        if blur and hitFx then
            -- Enable and animate blur in
            blur.Enabled = true
            TweenService:Create(blur, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = hitFx.BlurAmount or 10,
            }):Play()
            
            -- Animate blur out and disable
            task.delay(duration * 0.5, function()
                TweenService:Create(blur, TweenInfo.new(duration * 0.5, Enum.EasingStyle.Quad), {
                    Size = 0,
                }):Play()
                
                task.delay(duration * 0.5, function()
                    blur.Enabled = false
                end)
            end)
        end
    end
end
-- Forward-ref assignment: hitDebugDummy can now find cameraShake via _cameraShakeFn
_cameraShakeFn = cameraShake

-- ============================================
-- INPUT HANDLING
-- ============================================

local movementKeys = {
    [Enum.KeyCode.W] = "Forward",
    [Enum.KeyCode.S] = "Backward",
    [Enum.KeyCode.A] = "Left",
    [Enum.KeyCode.D] = "Right",
}

local pressedKeys = {}
local altPressed = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Always track movement keys (for dodge direction)
    if input.KeyCode and movementKeys[input.KeyCode] then
        pressedKeys[input.KeyCode] = true
    end
    
    -- Alt key tracking (always track)
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        altPressed = true
    end
    
    -- Skip if UI is processing (but make exceptions for fight controls)
    -- During a fight, we want to capture all combat inputs
    if gameProcessed then 
        -- During active round, still allow combat inputs
        if isRoundActive then
            -- Allow keyboard and mouse combat inputs
            local isCombatKey = input.KeyCode == Enum.KeyCode.E or 
                               input.KeyCode == Enum.KeyCode.F or
                               input.KeyCode == Enum.KeyCode.R or
                               input.KeyCode == Enum.KeyCode.Q or
                               input.KeyCode == Enum.KeyCode.Space or
                               input.KeyCode == Enum.KeyCode.LeftAlt
            local isCombatMouse = input.UserInputType == Enum.UserInputType.MouseButton1 or
                                  input.UserInputType == Enum.UserInputType.MouseButton2
            
            if not isCombatKey and not isCombatMouse then
                return
            end
        else
            return
        end
    end
    
    -- Only process combat inputs if round is active
    if not isRoundActive then return end
    
    -- Space + direction = Dodge
    if input.KeyCode == Enum.KeyCode.Space then
        for keyCode, direction in pairs(movementKeys) do
            if pressedKeys[keyCode] then
                print("💨 [INPUT] Dodge triggered via keyboard:", direction)
                performDodge(direction)
                return
            end
        end
        -- If no direction, dodge backward
        print("💨 [INPUT] Dodge backward (no direction)")
        performDodge("Backward")
        return
    end
    
    -- Keyboard shortcuts for attack (E = punch, R = heavy)
    if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.F then
        print("👊 [INPUT] Light attack via keyboard (E/F key)")
        performLightAttack()
        return
    end
    
    if input.KeyCode == Enum.KeyCode.R then
        print("💪 [INPUT] Heavy attack via keyboard (R key)")
        performHeavyAttack()
        return
    end
    
    if input.KeyCode == Enum.KeyCode.Q then
        print("🛡️ [INPUT] Block started via keyboard (Q key)")
        startBlock()
        return
    end
    
    -- Mouse inputs
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        print("🖱️ [INPUT] Left mouse button detected!")
        if altPressed then
            print("💪 [INPUT] Heavy attack (Alt+LMB)")
            performHeavyAttack()
        else
            print("👊 [INPUT] Light attack (LMB)")
            performLightAttack()
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        print("🛡️ [INPUT] Right mouse button - Block start")
        startBlock()
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    -- Always track movement keys release
    if input.KeyCode and movementKeys[input.KeyCode] then
        pressedKeys[input.KeyCode] = nil
    end
    
    -- Alt key release
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        altPressed = false
    end
    
    -- Q key release (keyboard block)
    if input.KeyCode == Enum.KeyCode.Q then
        stopBlock()
    end
    
    -- Release block (right mouse button)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        print("🛡️ [INPUT] Right mouse button - Block end")
        stopBlock()
    end
end)

-- ============================================
-- MOBILE BUTTONS (ControlsPanelMobile in StarterGui > FightingHUD)
-- ============================================
--
-- Structure expected:
--   FightingHUD > ControlsPanelMobile
--       Frame_LightAttackBtn  > ImageButton
--       Frame_BlockBtn        > ImageButton
--       Frame_DodgeBtn        > ImageButton
--                               CooldownFrame > TextLabel (cooldown timer)
--       Frame_HeavyAttackBtn  > ImageButton
--                               CooldownFrame > TextLabel (cooldown timer)
-- ============================================

-- Refs filled by initMobileButtons()
local MobilePanel = nil
local HeavyCooldownFrame = nil
local HeavyCooldownLabel = nil
local DodgeCooldownFrame  = nil
local DodgeCooldownLabel  = nil

-- ── Helper: run cooldown display loop for a given button ──────────────────
local function runCooldownDisplay(cooldownFrame, cooldownLabel, getCooldownEnd)
    if not cooldownFrame or not cooldownLabel then return end
    cooldownFrame.Visible = true

    task.spawn(function()
        while true do
            local remaining = getCooldownEnd() - tick()
            if remaining <= 0 then
                cooldownFrame.Visible = false
                cooldownLabel.Text = ""
                break
            end
            cooldownLabel.Text = string.format("%.1f", remaining)
            task.wait(0.05)
        end
    end)
end

-- ── initMobileButtons: connect StarterGui mobile buttons to actions ───────
local function initMobileButtons()
    local PlayerGui = Player:WaitForChild("PlayerGui", 10)
    if not PlayerGui then
        warn("❌ [FightingClient] PlayerGui not found")
        return
    end

    local FightingHUD = PlayerGui:WaitForChild("FightingHUD", 10)
    if not FightingHUD then
        warn("❌ [FightingClient] FightingHUD not found in PlayerGui")
        return
    end

    MobilePanel = FightingHUD:WaitForChild("ControlsPanelMobile", 5)
    if not MobilePanel then
        warn("❌ [FightingClient] ControlsPanelMobile not found in FightingHUD")
        return
    end

    -- ── Mobile panel: visible on ALL platforms (PC + Android) ───────────────
    -- StartMatchEvent will show it; EndMatchEvent will hide it.
    -- Keep true here so it's visible in Studio without starting a match.
    MobilePanel.Visible = true

    -- ── Light Attack ───────────────────────────────────────────────────────
    local Frame_LightAttackBtn = MobilePanel:FindFirstChild("Frame_LightAttackBtn")
    if Frame_LightAttackBtn then
        local LightBtn = Frame_LightAttackBtn:FindFirstChildOfClass("ImageButton")
        if LightBtn then
            LightBtn.MouseButton1Click:Connect(function()
                if canAct() then
                    print("📱 [MOBILE] Light Attack button pressed")
                    performLightAttack()
                end
            end)
            print("✅ [FightingClient] LightAttack mobile button connected")
        else
            warn("⚠️ [FightingClient] ImageButton not found inside Frame_LightAttackBtn")
        end
    else
        warn("⚠️ [FightingClient] Frame_LightAttackBtn not found")
    end

    -- ── Block ──────────────────────────────────────────────────────────────
    local Frame_BlockBtn = MobilePanel:FindFirstChild("Frame_BlockBtn")
    if Frame_BlockBtn then
        local BlockBtn = Frame_BlockBtn:FindFirstChildOfClass("ImageButton")
        if BlockBtn then
            BlockBtn.MouseButton1Down:Connect(function()
                if canAct() then
                    print("📱 [MOBILE] Block button pressed")
                    startBlock()
                end
            end)
            BlockBtn.MouseButton1Up:Connect(function()
                stopBlock()
            end)
            print("✅ [FightingClient] Block mobile button connected")
        else
            warn("⚠️ [FightingClient] ImageButton not found inside Frame_BlockBtn")
        end
    else
        warn("⚠️ [FightingClient] Frame_BlockBtn not found")
    end

    -- ── Dodge (with cooldown display) ──────────────────────────────────────
    local Frame_DodgeBtn = MobilePanel:FindFirstChild("Frame_DodgeBtn")
    if Frame_DodgeBtn then
        local DodgeBtn = Frame_DodgeBtn:FindFirstChildOfClass("ImageButton")
        DodgeCooldownFrame = Frame_DodgeBtn:FindFirstChild("CooldownFrame")
        if DodgeCooldownFrame then
            DodgeCooldownLabel = DodgeCooldownFrame:FindFirstChildOfClass("TextLabel")
            DodgeCooldownFrame.Visible = false  -- hidden by default at game start
        end

        if DodgeBtn then
            DodgeBtn.MouseButton1Click:Connect(function()
                if not canAct() then return end
                if tick() < dodgeCooldownEnd then
                    print("📱 [MOBILE] Dodge on cooldown")
                    return
                end

                -- Determine dodge direction from held movement keys
                local direction = "Backward"
                for keyCode, dir in pairs(movementKeys) do
                    if pressedKeys[keyCode] then
                        direction = dir
                        break
                    end
                end

                print("📱 [MOBILE] Dodge button pressed:", direction)
                performDodge(direction)

                -- Set dodge cooldown (use Duration from config, fallback 1s)
                local dodgeDuration = (FightingConfig.Combat and FightingConfig.Combat.Dodge and FightingConfig.Combat.Dodge.Duration) or 1
                dodgeCooldownEnd = tick() + dodgeDuration + 0.3  -- small buffer
                runCooldownDisplay(DodgeCooldownFrame, DodgeCooldownLabel, function()
                    return dodgeCooldownEnd
                end)
            end)
            print("✅ [FightingClient] Dodge mobile button connected")
        else
            warn("⚠️ [FightingClient] ImageButton not found inside Frame_DodgeBtn")
        end
    else
        warn("⚠️ [FightingClient] Frame_DodgeBtn not found")
    end

    -- ── Heavy Attack (with cooldown display) ───────────────────────────────
    local Frame_HeavyAttackBtn = MobilePanel:FindFirstChild("Frame_HeavyAttackBtn")
    if Frame_HeavyAttackBtn then
        local HeavyBtn = Frame_HeavyAttackBtn:FindFirstChildOfClass("ImageButton")
        HeavyCooldownFrame = Frame_HeavyAttackBtn:FindFirstChild("CooldownFrame")
        if HeavyCooldownFrame then
            HeavyCooldownLabel = HeavyCooldownFrame:FindFirstChildOfClass("TextLabel")
            HeavyCooldownFrame.Visible = false  -- hidden by default at game start
        end

        if HeavyBtn then
            HeavyBtn.MouseButton1Click:Connect(function()
                if not canAct() then return end
                if tick() < heavyAttackCooldown then
                    print("📱 [MOBILE] Heavy Attack on cooldown")
                    return
                end

                print("📱 [MOBILE] Heavy Attack button pressed")
                performHeavyAttack()

                -- heavyAttackCooldown already set inside performHeavyAttack;
                -- start the visual countdown loop
                task.defer(function()  -- defer so performHeavyAttack sets the value first
                    runCooldownDisplay(HeavyCooldownFrame, HeavyCooldownLabel, function()
                        return heavyAttackCooldown
                    end)
                end)
            end)
            print("✅ [FightingClient] HeavyAttack mobile button connected")
        else
            warn("⚠️ [FightingClient] ImageButton not found inside Frame_HeavyAttackBtn")
        end
    else
        warn("⚠️ [FightingClient] Frame_HeavyAttackBtn not found")
    end

    print("📱 [FightingClient] Mobile buttons initialised from StarterGui FightingHUD")
end

-- Legacy stubs (kept so any older code that calls them doesn't error)
local function showActionButtons() end
local function hideActionButtons() end

-- ============================================
-- JUMP BUTTON TOGGLE (mobile Roblox TouchGui)
-- ============================================
--
-- On mobile, Roblox puts a jump button inside:
--   PlayerGui > TouchGui > TouchControlFrame > JumpButton
-- We hide this during a fight so it doesn't overlap the attack buttons.
-- We also set Humanoid.JumpEnabled to block keyboard/spacebar jump.

local function setJumpEnabled(enabled)
    -- 1. Toggle Roblox Humanoid jump ability
    if Humanoid then
        Humanoid.JumpEnabled = enabled
    end

    -- 2. Show/hide the TouchGui jump button visually (mobile only)
    task.spawn(function()
        local playerGui = Player:WaitForChild("PlayerGui", 5)
        if not playerGui then return end

        local TouchGui = playerGui:FindFirstChild("TouchGui")
        if not TouchGui then return end  -- desktop, skip

        local TouchControlFrame = TouchGui:FindFirstChild("TouchControlFrame")
        if not TouchControlFrame then return end

        local JumpButton = TouchControlFrame:FindFirstChild("JumpButton")
        if JumpButton then
            JumpButton.Visible = enabled
            print("📱 [FightingClient] JumpButton visible:", enabled)
        end
    end)
end
-- ============================================
-- EVENT HANDLERS
-- ============================================

StartMatchEvent.OnClientEvent:Connect(function(data)
    print("🥊 [FightingClient] Match starting! Opponent:", data.OpponentName)
    
    isInMatch = true
    mySide = data.Side
    
    -- Preloading can also be run here, but it's safe if already called
    preloadAllSounds()
    
    -- Find opponent
    currentOpponent = Players:FindFirstChild(data.OpponentName)
    
    -- Disable jump: blocks space-bar + hides mobile jump button
    -- (space is used for Dodge during fight)
    if Humanoid then
        Humanoid:SetAttribute("OriginalJumpPower", Humanoid.JumpPower)
        Humanoid.JumpPower  = 0
        Humanoid.JumpHeight = 0
    end
    setJumpEnabled(false)   -- hides TouchGui JumpButton on mobile
    
    -- Show mobile action panel
    if MobilePanel then
        MobilePanel.Visible = true
    end
    
    -- Load animations
    loadAnimations()
end)

EndMatchEvent.OnClientEvent:Connect(function(data)
    print("🏆 [FightingClient] Match ended! Winner:", data.Winner)
    
    isInMatch = false
    isRoundActive = false
    currentOpponent = nil
    
    -- Stop death animation if playing
    if _G.currentDeathAnimation then
        _G.currentDeathAnimation:Stop()
        _G.currentDeathAnimation = nil
    end
    
    -- Play win/lose sound
    local didWin = (data.Winner == Player.Name)
    playResultSound(didWin)
    
    -- Stop camera
    stopFightCamera()
    
    -- Re-enable jumping and movement
    if Humanoid then
        local originalJump = Humanoid:GetAttribute("OriginalJumpPower") or 50
        Humanoid.JumpPower = originalJump
        Humanoid.JumpHeight = 7.2  -- Default Roblox jump height
        Humanoid.WalkSpeed = 16    -- Default walk speed
        Humanoid.AutoRotate = true
        Humanoid.PlatformStand = false
        print("✅ [FightingClient] Movement re-enabled")
    end
    setJumpEnabled(true)    -- re-shows TouchGui JumpButton on mobile
    
    -- Hide mobile action panel
    if MobilePanel then
        MobilePanel.Visible = false
    end
    
    -- Stop all animations
    stopAllCombatAnimations()
end)

RoundStartEvent.OnClientEvent:Connect(function(data)
    print("========================================")
    print("🔔 [FightingClient] Round", data.RoundNumber, "starting!")
    print("========================================")
    
    -- Stop death animation if playing
    if _G.currentDeathAnimation then
        _G.currentDeathAnimation:Stop()
        _G.currentDeathAnimation = nil
    end
    
    -- Restore movement and rotation
    if Humanoid then
        Humanoid.WalkSpeed = 16  -- Default walk speed
        Humanoid.JumpPower = 50  -- Default jump power
        Humanoid.AutoRotate = true  -- Re-enable auto rotate
        Humanoid.PlatformStand = false  -- Re-enable control
    end
    
    isRoundActive = true
    comboStep = 1
    isBlocking = false
    isDodging = false
    isAttacking = false
    
    print("📊 [FightingClient] Combat state reset:")
    print("   - isRoundActive:", isRoundActive)
    print("   - isBlocking:", isBlocking)
    print("   - isDodging:", isDodging)
    print("   - isAttacking:", isAttacking)
    print("   - myStamina:", myStamina)
    print("   - myHealth:", myHealth)
    
    -- Reset camera FOV to base value (fix zoom accumulation)
    Camera.FieldOfView = BASE_FOV
    
    -- Start fight camera
    startFightCamera()
    
    print("✅ [FightingClient] Round ready! You can now attack!")
end)

RoundEndEvent.OnClientEvent:Connect(function(data)
    print("🏅 [FightingClient] Round ended! Winner:", data.WinnerName)
    
    isRoundActive = false
    
    -- Stop blocking
    stopBlock()
    
    -- Check if local player lost this round
    local didPlayerWin = (data.WinnerName == Player.Name)
    
    -- If player lost, play death animation and lock movement
    if not didPlayerWin then
        -- Stop all combat animations first
        stopAllCombatAnimations()
        
        -- Load and play death animation in loop
        if Animator and FightingConfig.Animations and FightingConfig.Animations.DeathAnimation then
            local deathAnim = Instance.new("Animation")
            deathAnim.AnimationId = FightingConfig.Animations.DeathAnimation
            local deathTrack = Animator:LoadAnimation(deathAnim)
            deathTrack.Looped = true
            deathTrack.Priority = Enum.AnimationPriority.Action4
            deathTrack:Play()
            
            -- Store for cleanup on next round
            _G.currentDeathAnimation = deathTrack
        end
        
        -- Completely lock movement and rotation
        if Humanoid then
            Humanoid.WalkSpeed = 0
            Humanoid.JumpPower = 0
            Humanoid.AutoRotate = false  -- Disable auto rotate
            Humanoid.PlatformStand = true  -- Lock character completely
        end
    end
end)

UpdateStatsEvent.OnClientEvent:Connect(function(data)
    if mySide == "A" then
        myHealth = data.PlayerAHealth
        myStamina = data.PlayerAStamina
        opponentHealth = data.PlayerBHealth
        opponentStamina = data.PlayerBStamina
    else
        myHealth = data.PlayerBHealth
        myStamina = data.PlayerBStamina
        opponentHealth = data.PlayerAHealth
        opponentStamina = data.PlayerAStamina
    end
    
    -- Fire to UI (handled in FightingUI)
    _G.UpdateFightingStats = {
        MyHealth = myHealth,
        MyStamina = myStamina,
        OpponentHealth = opponentHealth,
        OpponentStamina = opponentStamina,
    }
end)

-- Handle damage events (both global for popup and local for animation)
DealDamageEvent.OnClientEvent:Connect(function(hitData)
    -- Global event - show damage number popup on defender (visible to everyone)
    if hitData.DefenderName and not hitData.IsLocalHit then
        -- Find the defender's character
        local defenderPlayer = Players:FindFirstChild(hitData.DefenderName)
        if defenderPlayer and defenderPlayer.Character then
            showDamageNumber(defenderPlayer.Character, hitData.Damage)
            playHitParticles(defenderPlayer.Character) -- Spawn particle untuk semua orang yg melihat musuh kena hit
            -- Attacker plays sound locally in performLightAttack/performHeavyAttack
        end
        return -- Don't process further for global events
    end
    
    -- Local event - this is the defender receiving their own hit event
    if hitData.IsLocalHit then
        print("💥 [FightingClient] Got hit! Damage:", hitData.Damage)
        
        -- Play hit sound for victim (HANYA untuk victim)
        playSoundEffect("VictimHit")
        -- Reset combo saat terkena hit (player ter-interrupt)
        comboStep = 1
        heavyComboStep = 1

        -- ── Hit animation (defender plays on their own character) ─────────────
        if hitData.AttackType == "Heavy" then
            -- HeavyHit is now an array — use ComboIndex or fallback to 1
            local idx = hitData.ComboIndex or 1
            local hitTrack = (animationTracks.HeavyHit and animationTracks.HeavyHit[idx])
                          or (animationTracks.HeavyHit and animationTracks.HeavyHit[1])
            if hitTrack then
                stopAllCombatAnimations()
                hitTrack:Play()
            end
        else
            local hitTrack = animationTracks.Hit[hitData.ComboIndex] or animationTracks.Hit[1]
            if hitTrack then
                stopAllCombatAnimations()
                hitTrack:Play()
            end
        end

        -- ── Pushback via BodyVelocity (respects collision — mentok di tembok) ──────
        if HRP then
            task.spawn(function()
                -- Auto-rotate to face attacker
                -- (Jika ada auto-lock system loop, dia akan meng-override ini otomatis)
                if hitData.AttackerPosition then
                    local lookPos = Vector3.new(hitData.AttackerPosition.X, HRP.Position.Y, hitData.AttackerPosition.Z)
                    HRP.CFrame = CFrame.lookAt(HRP.Position, lookPos)
                end

                -- Push direction sama dengan arah penyerang
                local pushDir   = hitData.AttackerLookVector or -HRP.CFrame.LookVector
                pushDir         = Vector3.new(pushDir.X, 0, pushDir.Z).Unit
                
                -- Menentukan konfigurasi pushback
                local isFar = hitData.ComboIndex and hitData.ComboIndex % 4 == 0
                local cfg = isFar and FightingConfig.Combat.PushMechanics.DefenderFar or FightingConfig.Combat.PushMechanics.DefenderNormal
                
                if cfg.Delay > 0 then task.wait(cfg.Delay) end
                
                -- Enemy speed & duration dari Config
                local speed     = cfg.Distance / cfg.Duration
                local duration  = cfg.Duration
                
                if isFar then
                    print("🚀 [FightingClient] Hit ke-4 terdeteksi! Pushback 2x lebih jauh.")
                end

                -- BodyVelocity applies constant velocity; Roblox physics stops it at walls
                local bv = Instance.new("BodyVelocity")
                bv.Velocity  = pushDir * speed
                bv.MaxForce  = Vector3.new(1e6, 0, 1e6)  -- horizontal only, no Y override
                bv.P         = 1e6
                bv.Parent    = HRP

                task.wait(duration)
                if bv and bv.Parent then bv:Destroy() end
            end)
        end

        -- ── Full-body red Highlight flash (Occluded = tidak nembus player) ────
        if Character then
            task.spawn(function()
                local hl = Instance.new("Highlight")
                hl.FillColor          = Color3.fromRGB(255, 40, 40)
                hl.FillTransparency   = 0.65 -- Intensitas merah diturunkan 50%+ 
                hl.OutlineColor       = Color3.fromRGB(255, 0, 0)
                hl.OutlineTransparency = 0.7
                hl.DepthMode          = Enum.HighlightDepthMode.Occluded  -- respects depth, no X-ray
                hl.Parent             = Character

                task.wait(0.15)
                TweenService:Create(hl, TweenInfo.new(0.1), {
                    FillTransparency    = 1,
                    OutlineTransparency = 1,
                }):Play()
                task.wait(0.12)
                if hl and hl.Parent then hl:Destroy() end
            end)
        end
    end
end)

-- Block success feedback
BlockEvent.OnClientEvent:Connect(function(data)
    if data.Success then
        print("🛡️ [FightingClient] Block successful!")
    end
end)

-- Camera shake events
CameraShakeEvent.OnClientEvent:Connect(function(shakeType)
    local config = FightingConfig.Camera
    
    print("📷 [SHAKE] Received shake event:", shakeType)
    
    if shakeType == "Hit" and config.HitShake then
        local s = config.HitShake
        -- Hit gets blood + blur effects (isHitEffect = true)
        cameraShake(s.Amplitude, s.Frequency, s.Duration, s.ZoomAmount or 0, true)
    elseif shakeType == "Block" and config.BlockShake then
        local s = config.BlockShake
        cameraShake(s.Amplitude, s.Frequency, s.Duration, s.ZoomAmount or 0, false)
    elseif shakeType == "Attack" and config.AttackShake then
        local s = config.AttackShake
        cameraShake(s.Amplitude, s.Frequency, s.Duration, s.ZoomAmount or 0, false)
        
        -- Attacker receives this when their attack hits a REAL ENEMY
        playSoundEffect("PunchHit")
    end
end)

-- ============================================
-- CHARACTER RESPAWN HANDLING
-- ============================================

Player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = newCharacter:WaitForChild("Humanoid")
    HRP = newCharacter:WaitForChild("HumanoidRootPart")
    Animator = Humanoid:WaitForChild("Animator")
    
    -- Reload animations if in match
    if isInMatch then
        loadAnimations()
    end
    
    print("🔄 [FightingClient] Character respawned, references updated")
end)

-- ============================================
-- INVISIBLE BLOCKER (MINIMUM DISTANCE ENFORCEMENT)
-- ============================================
RunService.Stepped:Connect(function()
    if not Character or not HRP then return end
    
    local targetHRP = nil
    
    -- Tentukan target yang akan dilock/dicek
    if isInMatch and targetPlayer and targetPlayer.Character then
        targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    elseif DEBUG_MODE and debugDummy then
        targetHRP = debugDummy:FindFirstChild("HumanoidRootPart")
    end
    
    if targetHRP then
        local minDist = FightingConfig.Combat.MinDistance or 2.5
        
        -- Cek jarak 2D pada bidang XZ saja (mengabaikan Y tinggi)
        local p1 = Vector3.new(HRP.Position.X, 0, HRP.Position.Z)
        local p2 = Vector3.new(targetHRP.Position.X, 0, targetHRP.Position.Z)
        
        local separation = p1 - p2
        local dist = separation.Magnitude
        
        if dist > 0 and dist < minDist then
            -- Cari seberapa banyak tubuh kita harus digeser mundur
            local correction = minDist - dist
            local pushDir = separation.Unit
            
            -- Terapkan CFrame ke posisi XZ baru tanpa mengubah Y atau rotasi karakter
            local newPos = HRP.Position + (pushDir * correction)
            HRP.CFrame = CFrame.new(newPos) * HRP.CFrame.Rotation
        end
    end
end)

-- ============================================
-- INITIALIZATION
-- ============================================

print("⏳ [FightingClient] Starting initialization...")

-- Initialise mobile buttons from StarterGui
local success, err = pcall(function()
    initMobileButtons()
end)

if success then
    print("✅ [FightingClient] Mobile buttons initialised successfully")
else
    warn("❌ [FightingClient] Failed to initialise mobile buttons:", err)
end

-- DEBUG MODE: load animations immediately so buttons work without a match
if DEBUG_MODE then
    warn("========================================")
    warn("🐞 [DEBUG_MODE] = TRUE")
    warn("🐞 Buttons bypass isRoundActive check.")
    warn("🐞 Loading animations immediately for testing.")
    warn("🐞 Camera: fight-style, follows behind character when no opponent.")
    warn("🐞 Press H to spawn a hittable dummy NPC in front of you.")
    warn("🐞 Set DEBUG_MODE = false before publishing!")
    warn("========================================")

    -- Fetch debug remote events (created by DebugServer.server.lua)
    task.spawn(function()
        SpawnDebugDummyEvent = FightingRemotes:WaitForChild("SpawnDebugDummy", 10)
        HitDebugDummyEvent   = FightingRemotes:WaitForChild("HitDebugDummy",   10)
        if SpawnDebugDummyEvent then
            print("✅ [DEBUG] SpawnDebugDummy remote ready — press H to spawn dummy")
        else
            warn("⚠️ [DEBUG] SpawnDebugDummy remote not found — is DebugServer.server.lua in game?")
        end
    end)

    -- H key: spawn debug dummy in front of player
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.H then
            if SpawnDebugDummyEvent then
                print("🎯 [DEBUG] Spawning debug dummy...")
                SpawnDebugDummyEvent:FireServer()
            else
                warn("⚠️ [DEBUG] SpawnDebugDummyEvent not ready yet")
            end
        end
    end)

    -- Auto-track dummy reference (updates whenever H is pressed and dummy spawns)
    task.spawn(function()
        while DEBUG_MODE do
            local found = workspace:FindFirstChild("DebugDummy_" .. Player.Name)
            if found ~= debugDummy then
                debugDummy = found
                if debugDummy then
                    print("🎯 [DEBUG] Dummy reference acquired:", debugDummy.Name)
                end
            end
            task.wait(0.5)
        end
    end)

    task.delay(1, function()   -- small delay so Character/Animator + UI are ready
        -- Load animations
        local ok2, err2 = pcall(loadAnimations)
        if ok2 then
            print("✅ [DEBUG] Animations loaded for offline testing")
        else
            warn("❌ [DEBUG] loadAnimations failed:", err2)
        end

        -- Force-enable FightingHUD so ControlsPanelMobile is visible
        local playerGui = Player:WaitForChild("PlayerGui", 5)
        if playerGui then
            local hud = playerGui:FindFirstChild("FightingHUD")
            if hud then
                hud.Enabled = true
                print("✅ [DEBUG] FightingHUD force-enabled")
            else
                warn("⚠️ [DEBUG] FightingHUD not found in PlayerGui — did you put it in StarterGui?")
            end
        end

        -- Make sure the mobile panel is visible
        if MobilePanel then
            MobilePanel.Visible = true
            print("✅ [DEBUG] ControlsPanelMobile forced visible")
        else
            warn("⚠️ [DEBUG] MobilePanel ref is nil — initMobileButtons may have failed")
        end

        -- Start fight camera (no opponent = follows behind character naturally)
        startFightCamera()
        print("📷 [DEBUG] Fight camera started for animation testing")
    end)
end

-- Force preload right away so dummy and local tests have audio immediately
task.spawn(function()
    preloadAllSounds()
end)

-- Expose functions to global for UI script
_G.FightingClientFunctions = {
    PerformLightAttack = performLightAttack,
    PerformHeavyAttack = performHeavyAttack,
    StartBlock = startBlock,
    StopBlock = stopBlock,
    PerformDodge = performDodge,
    
    IsInMatch = function() return isInMatch end,
    IsRoundActive = function() return isRoundActive end,
    GetMyHealth = function() return myHealth end,
    GetMyStamina = function() return myStamina end,
    GetOpponentHealth = function() return opponentHealth end,
    GetOpponentStamina = function() return opponentStamina end,
}

print("========================================")
print("🥊 [FightingClient] Fighting Client Loaded!")
print("========================================")
print("")
print("📝 CONTROLS:")
print("   PC Mouse: Left Click = Punch, Right Click = Block")
print("   PC Keyboard: E/F = Punch, R = Heavy, Q = Block, Space = Dodge")
print("   Or use the on-screen buttons")
print("")
print("⚠️ Waiting for match to start...")
print("   Stand on StartPosition to begin!")
print("")
