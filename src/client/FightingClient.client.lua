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
-- STATE VARIABLES
-- ============================================

local isInMatch = false
local isRoundActive = false
local currentOpponent = nil
local mySide = nil -- "A" or "B"

-- Combat state
local isBlocking = false
local isDodging = false
local isAttacking = false
local comboStep = 1
local lastAttackTime = 0
local heavyAttackCooldown = 0

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
    
    -- Heavy attack
    animationTracks.HeavyAttack = AnimationConfig.LoadAnimation(
        Animator,
        AnimationConfig.HeavyAttack.Attack,
        false,
        Enum.AnimationPriority.Action
    )
    
    animationTracks.HeavyHit = AnimationConfig.LoadAnimation(
        Animator,
        AnimationConfig.HeavyAttack.Hit,
        false,
        Enum.AnimationPriority.Action2
    )
    
    -- Dodge animations (optional)
    animationTracks.Dodge = AnimationConfig.LoadAnimation(
        Animator,
        AnimationConfig.Dodge.Universal,
        false,
        Enum.AnimationPriority.Action
    )
    
    -- Idle
    animationTracks.FightIdle = AnimationConfig.LoadAnimation(
        Animator,
        AnimationConfig.Idle.FightIdle,
        true,
        Enum.AnimationPriority.Idle
    )
    
    print("🎬 [FightingClient] Animations loaded")
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

local function performLightAttack()
    print("👊 [COMBAT] performLightAttack() called")
    print("   - isRoundActive:", isRoundActive)
    print("   - isBlocking:", isBlocking)
    print("   - isDodging:", isDodging)
    print("   - isAttacking:", isAttacking)
    
    if not isRoundActive then 
        print("   ❌ BLOCKED: Round not active")
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
    
    -- Check stamina (basic client check, server will validate)
    print("   - myStamina:", myStamina, "/ required:", config.StaminaCost)
    if myStamina < config.StaminaCost then 
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
            if isRoundActive then
                DealDamageEvent:FireServer("Light", comboStep)
            end
        end)
        
        -- Animation finished callback
        local conn
        conn = attackTrack.Stopped:Connect(function()
            conn:Disconnect()
            isAttacking = false
            
            -- Advance combo
            comboStep = comboStep + 1
            if comboStep > config.MaxComboHits then
                comboStep = 1
            end
        end)
    else
        isAttacking = false
        DealDamageEvent:FireServer("Light", comboStep)
        comboStep = 1
    end
end

local function performHeavyAttack()
    print("💪 [COMBAT] performHeavyAttack() called")
    print("   - isRoundActive:", isRoundActive)
    print("   - isBlocking:", isBlocking)
    print("   - isDodging:", isDodging)
    print("   - isAttacking:", isAttacking)
    
    if not isRoundActive then print("   ❌ Not in active round") return end
    if isBlocking then print("   ❌ Currently blocking") return end
    if isDodging then print("   ❌ Currently dodging") return end
    if isAttacking then print("   ❌ Currently attacking") return end
    
    local config = FightingConfig.Combat.HeavyAttack
    local currentTime = tick()
    
    -- Check cooldown
    if currentTime < heavyAttackCooldown then 
        print("   ❌ On cooldown")
        return 
    end
    
    -- Check stamina
    print("   - myStamina:", myStamina, "/ required:", config.StaminaCost)
    if myStamina < config.StaminaCost then 
        print("   ❌ Not enough stamina")
        return 
    end
    
    print("   ✅ All checks passed! Executing heavy attack...")
    
    isAttacking = true
    heavyAttackCooldown = currentTime + config.Cooldown
    
    -- Play heavy attack animation
    local heavyTrack = animationTracks.HeavyAttack
    if heavyTrack then
        stopAllCombatAnimations()
        heavyTrack:Play()
        
        -- Charge time before dealing damage
        task.delay(config.ChargeTime, function()
            if isRoundActive then
                DealDamageEvent:FireServer("Heavy", 0)
            end
        end)
        
        local conn
        conn = heavyTrack.Stopped:Connect(function()
            conn:Disconnect()
            isAttacking = false
        end)
    else
        isAttacking = false
        DealDamageEvent:FireServer("Heavy", 0)
    end
end

local function startBlock()
    print("🛡️ [COMBAT] startBlock() called")
    print("   - isRoundActive:", isRoundActive)
    print("   - isAttacking:", isAttacking)
    print("   - isDodging:", isDodging)
    print("   - isBlocking:", isBlocking)
    
    if not isRoundActive then print("   ❌ Not in active round") return end
    if isAttacking then print("   ❌ Currently attacking") return end
    if isDodging then print("   ❌ Currently dodging") return end
    if isBlocking then print("   ❌ Already blocking") return end
    
    local config = FightingConfig.Combat.Block
    
    -- Check stamina
    print("   - myStamina:", myStamina, "/ required:", config.StaminaCost)
    if myStamina < config.StaminaCost then 
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
    if not isRoundActive or isBlocking or isAttacking or isDodging then return end
    
    local config = FightingConfig.Combat.Dodge
    
    -- Check stamina
    if myStamina < config.StaminaCost then return end
    
    isDodging = true
    DodgeEvent:FireServer(direction)
    
    -- Calculate movement
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
    
    -- Play dodge animation
    local dodgeTrack = animationTracks.Dodge
    if dodgeTrack then
        stopAllCombatAnimations()
        dodgeTrack:Play()
    end
    
    -- Apply movement
    local startPos = HRP.Position
    local targetPos = startPos + moveDir * config.Distance
    
    local dodgeTween = TweenService:Create(
        HRP,
        TweenInfo.new(config.Duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { CFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.rad(HRP.Orientation.Y), 0) }
    )
    
    dodgeTween:Play()
    dodgeTween.Completed:Connect(function()
        isDodging = false
    end)
    
    -- Also reset after duration just in case
    task.delay(config.Duration + 0.1, function()
        isDodging = false
    end)
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
local originalFOV = 70     -- Default FOV

-- Shake update function bound to RenderStep
local function updateCameraShake()
    if not isShaking then return end
    
    local elapsed = tick() - shakeStartTime
    
    if elapsed >= shakeDuration then
        isShaking = false
        -- Restore FOV smoothly
        TweenService:Create(Camera, TweenInfo.new(0.15), {FieldOfView = originalFOV}):Play()
        RunService:UnbindFromRenderStep("FightingCameraShake")
        return
    end
    
    -- Decreasing intensity over time (ease out)
    local progress = elapsed / shakeDuration
    local currentAmplitude = shakeAmplitude * (1 - progress)
    local currentZoom = shakeZoomAmount * (1 - progress)
    
    -- Convert frequency (Hz) to angular velocity
    local time = tick()
    local angularVelocity = shakeFrequency * 2 * math.pi
    
    -- Sinusoidal shake
    local offsetX = math.sin(time * angularVelocity) * currentAmplitude
    local offsetY = math.cos(time * angularVelocity * 1.1) * currentAmplitude
    
    -- Apply offset to camera
    local shakeOffset = Vector3.new(offsetX, offsetY, 0)
    Camera.CFrame = Camera.CFrame * CFrame.new(shakeOffset)
    
    -- Apply zoom effect (lower FOV = zoom in)
    if shakeZoomAmount > 0 then
        Camera.FieldOfView = originalFOV - currentZoom
    end
end

local function cameraShake(amplitude, frequency, duration, zoomAmount, isHitEffect)
    -- Set shake parameters
    shakeAmplitude = amplitude
    shakeFrequency = frequency
    shakeDuration = duration
    shakeZoomAmount = zoomAmount or 0
    shakeStartTime = tick()
    originalFOV = Camera.FieldOfView
    
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
-- ACTION BUTTONS (VISIBLE ON ALL PLATFORMS)
-- ============================================

local actionButtonsUI = nil
local attackButton = nil
local heavyButton = nil
local blockButton = nil
local dodgeButton = nil

local function createActionButtons()
    local playerGui = Player:WaitForChild("PlayerGui")
    
    -- Check if already exists
    if playerGui:FindFirstChild("FightingActionButtons") then
        playerGui.FightingActionButtons:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FightingActionButtons"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 10
    screenGui.Enabled = false -- Will be enabled when match starts
    screenGui.Parent = playerGui
    
    actionButtonsUI = screenGui
    
    -- Container for action buttons (bottom right area)
    local buttonsContainer = Instance.new("Frame")
    buttonsContainer.Name = "ButtonsContainer"
    buttonsContainer.Size = UDim2.new(0, 200, 0, 200)
    buttonsContainer.Position = UDim2.new(1, -220, 1, -280)
    buttonsContainer.BackgroundTransparency = 1
    buttonsContainer.Parent = screenGui
    
    -- Button template function
    local function createButton(name, position, size, text, color, icon)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Size = size or UDim2.new(0, 75, 0, 75)
        button.Position = position
        button.BackgroundColor3 = color or Color3.fromRGB(50, 50, 60)
        button.BackgroundTransparency = 0.2
        button.BorderSizePixel = 0
        button.Text = ""
        button.AutoButtonColor = false
        button.Parent = buttonsContainer
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 15)
        corner.Parent = button
        
        -- Inner shadow/glow effect
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Transparency = 0.7
        stroke.Thickness = 2
        stroke.Parent = button
        
        -- Icon/Text label
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, 0, 0.6, 0)
        label.Position = UDim2.new(0, 0, 0.2, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBlack
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 14
        label.Text = text
        label.TextStrokeTransparency = 0.5
        label.Parent = button
        
        -- Keybind hint (for PC)
        if not isMobile then
            local keybind = Instance.new("TextLabel")
            keybind.Name = "Keybind"
            keybind.Size = UDim2.new(1, 0, 0.25, 0)
            keybind.Position = UDim2.new(0, 0, 0.75, 0)
            keybind.BackgroundTransparency = 1
            keybind.Font = Enum.Font.Gotham
            keybind.TextColor3 = Color3.fromRGB(180, 180, 180)
            keybind.TextSize = 10
            keybind.Text = icon or ""
            keybind.Parent = button
        end
        
        -- Press animation
        button.MouseButton1Down:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.1), {
                Size = UDim2.new(0, size.X.Offset - 8, 0, size.Y.Offset - 8),
                BackgroundTransparency = 0.1
            }):Play()
        end)
        
        button.MouseButton1Up:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.1), {
                Size = size,
                BackgroundTransparency = 0.2
            }):Play()
        end)
        
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.1), {
                Size = size,
                BackgroundTransparency = 0.2
            }):Play()
        end)
        
        return button
    end
    
    -- Attack Button (Large, center-right) - Left Click
    attackButton = createButton(
        "AttackButton",
        UDim2.new(0.5, -45, 0.5, -45),
        UDim2.new(0, 90, 0, 90),
        "PUNCH",
        Color3.fromRGB(220, 70, 70),
        "[LMB]"
    )
    
    attackButton.MouseButton1Click:Connect(function()
        print("👊 [DEBUG] Attack button clicked!")
        if isRoundActive then
            performLightAttack()
        end
    end)
    
    -- Heavy Attack Button (Top) - Alt + Left Click
    heavyButton = createButton(
        "HeavyButton",
        UDim2.new(0.5, -35, 0, 0),
        UDim2.new(0, 70, 0, 70),
        "HEAVY",
        Color3.fromRGB(255, 140, 50),
        "[Alt+LMB]"
    )
    
    heavyButton.MouseButton1Click:Connect(function()
        print("💪 [DEBUG] Heavy attack button clicked!")
        if isRoundActive then
            performHeavyAttack()
        end
    end)
    
    -- Block Button (Left) - Right Click (hold)
    blockButton = createButton(
        "BlockButton",
        UDim2.new(0, 0, 0.5, -35),
        UDim2.new(0, 70, 0, 70),
        "BLOCK",
        Color3.fromRGB(70, 140, 220),
        "[RMB]"
    )
    
    blockButton.MouseButton1Down:Connect(function()
        print("🛡️ [DEBUG] Block started!")
        if isRoundActive then
            startBlock()
        end
    end)
    
    blockButton.MouseButton1Up:Connect(function()
        print("🛡️ [DEBUG] Block ended!")
        stopBlock()
    end)
    
    -- Also handle touch end for mobile
    blockButton.TouchLongPress:Connect(function()
        if isRoundActive then
            startBlock()
        end
    end)
    
    -- Dodge Button (Bottom) - Space + Direction
    dodgeButton = createButton(
        "DodgeButton",
        UDim2.new(0.5, -35, 1, -70),
        UDim2.new(0, 70, 0, 70),
        "DODGE",
        Color3.fromRGB(80, 200, 120),
        "[Space+Dir]"
    )
    
    dodgeButton.MouseButton1Click:Connect(function()
        print("💨 [DEBUG] Dodge button clicked!")
        if isRoundActive then
            -- Default to backward dodge, or use current movement direction
            local direction = "Backward"
            for keyCode, dir in pairs(movementKeys) do
                if pressedKeys[keyCode] then
                    direction = dir
                    break
                end
            end
            performDodge(direction)
        end
    end)
    
    -- Instructions label (top of container)
    local instructionLabel = Instance.new("TextLabel")
    instructionLabel.Name = "Instructions"
    instructionLabel.Size = UDim2.new(1, 40, 0, 25)
    instructionLabel.Position = UDim2.new(0, -20, 0, -35)
    instructionLabel.BackgroundTransparency = 1
    instructionLabel.Font = Enum.Font.GothamMedium
    instructionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    instructionLabel.TextSize = 12
    instructionLabel.Text = "⚔️ COMBAT ACTIONS"
    instructionLabel.Parent = buttonsContainer
    
    print("🎮 [FightingClient] Action buttons created (visible on all platforms)")
end

local function showActionButtons()
    if actionButtonsUI then
        actionButtonsUI.Enabled = true
        print("🎮 [FightingClient] Action buttons shown")
    end
end

local function hideActionButtons()
    if actionButtonsUI then
        actionButtonsUI.Enabled = false
        print("🎮 [FightingClient] Action buttons hidden")
    end
end


-- ============================================
-- EVENT HANDLERS
-- ============================================

StartMatchEvent.OnClientEvent:Connect(function(data)
    print("🥊 [FightingClient] Match starting! Opponent:", data.OpponentName)
    
    isInMatch = true
    mySide = data.Side
    
    -- Find opponent
    currentOpponent = Players:FindFirstChild(data.OpponentName)
    
    -- Disable jumping (space is used for dodge instead)
    if Humanoid then
        Humanoid:SetAttribute("OriginalJumpPower", Humanoid.JumpPower)
        Humanoid.JumpPower = 0
        Humanoid.JumpHeight = 0
        print("🚫 [FightingClient] Jump disabled for fight")
    end
    
    -- Load animations
    loadAnimations()
    
    -- Show action buttons (visible on all platforms)
    showActionButtons()
end)

EndMatchEvent.OnClientEvent:Connect(function(data)
    print("🏆 [FightingClient] Match ended! Winner:", data.Winner)
    
    isInMatch = false
    isRoundActive = false
    currentOpponent = nil
    
    -- Stop camera
    stopFightCamera()
    
    -- Re-enable jumping
    if Humanoid then
        local originalJump = Humanoid:GetAttribute("OriginalJumpPower") or 50
        Humanoid.JumpPower = originalJump
        Humanoid.JumpHeight = 7.2  -- Default Roblox jump height
        print("✅ [FightingClient] Jump re-enabled")
    end
    
    -- Hide action buttons
    hideActionButtons()
    
    -- Stop all animations
    stopAllCombatAnimations()
end)

RoundStartEvent.OnClientEvent:Connect(function(data)
    print("========================================")
    print("🔔 [FightingClient] Round", data.RoundNumber, "starting!")
    print("========================================")
    
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
    
    -- Start fight camera
    startFightCamera()
    
    print("✅ [FightingClient] Round ready! You can now attack!")
end)

RoundEndEvent.OnClientEvent:Connect(function(data)
    print("🏅 [FightingClient] Round ended! Winner:", data.WinnerName)
    
    isRoundActive = false
    
    -- Stop blocking
    stopBlock()
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

-- Handle being hit
DealDamageEvent.OnClientEvent:Connect(function(hitData)
    print("💥 [FightingClient] Got hit! Damage:", hitData.Damage)
    
    -- Play hit animation
    if hitData.AttackType == "Heavy" then
        local hitTrack = animationTracks.HeavyHit
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
-- INITIALIZATION
-- ============================================

print("⏳ [FightingClient] Starting initialization...")

-- Create action buttons on start (visible on all platforms)
local success, err = pcall(function()
    createActionButtons()
end)

if success then
    print("✅ [FightingClient] Action buttons created successfully")
else
    warn("❌ [FightingClient] Failed to create action buttons:", err)
end

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
