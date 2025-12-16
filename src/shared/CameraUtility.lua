--[[
    CameraUtility.lua
    Shared camera utility functions
    
    Can be used by client scripts for advanced camera effects
]]

local CameraUtility = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer

-- ============================================
-- CAMERA SHAKE SYSTEM
-- ============================================

local isShaking = false
local shakeConnection = nil

-- Simple camera shake
function CameraUtility.Shake(magnitude, speed, duration)
    if isShaking then return end
    
    isShaking = true
    local startTime = tick()
    
    if shakeConnection then
        shakeConnection:Disconnect()
    end
    
    shakeConnection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        
        if elapsed >= duration then
            shakeConnection:Disconnect()
            shakeConnection = nil
            isShaking = false
            return
        end
        
        -- Decreasing intensity over time
        local progress = elapsed / duration
        local currentMagnitude = magnitude * (1 - progress)
        
        -- Random shake offsets
        local offsetX = (math.random() - 0.5) * 2 * currentMagnitude
        local offsetY = (math.random() - 0.5) * 2 * currentMagnitude
        
        Camera.CFrame = Camera.CFrame * CFrame.new(offsetX, offsetY, 0)
    end)
end

-- Directional shake (towards a direction)
function CameraUtility.DirectionalShake(direction, magnitude, duration)
    if isShaking then return end
    
    isShaking = true
    local startTime = tick()
    local normalizedDir = direction.Unit
    
    if shakeConnection then
        shakeConnection:Disconnect()
    end
    
    shakeConnection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        
        if elapsed >= duration then
            shakeConnection:Disconnect()
            shakeConnection = nil
            isShaking = false
            return
        end
        
        local progress = elapsed / duration
        local currentMagnitude = magnitude * (1 - progress)
        
        -- Shake mostly in the direction with some random perpendicular movement
        local mainOffset = normalizedDir * math.sin(elapsed * 50) * currentMagnitude
        local randomOffset = Vector3.new(
            (math.random() - 0.5) * currentMagnitude * 0.3,
            (math.random() - 0.5) * currentMagnitude * 0.3,
            0
        )
        
        Camera.CFrame = Camera.CFrame * CFrame.new(mainOffset + randomOffset)
    end)
end

-- Impact shake (single hit effect)
function CameraUtility.ImpactShake(intensity)
    intensity = intensity or 1
    
    local magnitude = 0.5 * intensity
    local duration = 0.15 + (0.1 * intensity)
    
    CameraUtility.Shake(magnitude, 30, duration)
end

-- Block shake (softer than hit)
function CameraUtility.BlockShake()
    CameraUtility.Shake(0.15, 25, 0.1)
end

-- Heavy hit shake
function CameraUtility.HeavyHitShake()
    CameraUtility.Shake(0.6, 35, 0.3)
end

-- Stop any active shake
function CameraUtility.StopShake()
    if shakeConnection then
        shakeConnection:Disconnect()
        shakeConnection = nil
    end
    isShaking = false
end

-- ============================================
-- FIGHT CAMERA MODE
-- ============================================

local fightCameraActive = false
local fightCameraConnection = nil
local originalCameraSettings = {}

function CameraUtility.StartFightCamera(config)
    if fightCameraActive then return end
    
    config = config or {}
    local offset = config.Offset or Vector3.new(-3, 2, 8)
    local distance = config.Distance or 30
    local lerpSpeed = config.LerpSpeed or 0.15
    local targetGetter = config.GetTarget -- Function that returns target position
    
    fightCameraActive = true
    
    -- Save original settings
    originalCameraSettings = {
        CameraType = Camera.CameraType,
        CameraSubject = Camera.CameraSubject,
        MinZoom = Player.CameraMinZoomDistance,
        MaxZoom = Player.CameraMaxZoomDistance,
        CFrame = Camera.CFrame,
    }
    
    -- Lock zoom
    Player.CameraMinZoomDistance = distance
    Player.CameraMaxZoomDistance = distance
    Camera.CameraType = Enum.CameraType.Scriptable
    
    local character = Player.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    fightCameraConnection = RunService.RenderStepped:Connect(function()
        if not fightCameraActive then return end
        if not humanoidRootPart or not humanoidRootPart.Parent then return end
        
        -- Calculate camera position (offset from player)
        local cameraPos = humanoidRootPart.Position + humanoidRootPart.CFrame:VectorToWorldSpace(offset)
        
        -- Get look target
        local lookTarget
        if targetGetter then
            lookTarget = targetGetter()
        end
        
        if not lookTarget then
            lookTarget = humanoidRootPart.Position + humanoidRootPart.CFrame.LookVector * 10
        end
        
        -- Smooth camera
        local targetCFrame = CFrame.new(cameraPos, lookTarget)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, lerpSpeed)
    end)
end

function CameraUtility.StopFightCamera(transitionDuration)
    if not fightCameraActive then return end
    
    fightCameraActive = false
    transitionDuration = transitionDuration or 1
    
    if fightCameraConnection then
        fightCameraConnection:Disconnect()
        fightCameraConnection = nil
    end
    
    -- Restore zoom
    Player.CameraMinZoomDistance = originalCameraSettings.MinZoom or 0.5
    Player.CameraMaxZoomDistance = originalCameraSettings.MaxZoom or 400
    
    -- Smooth transition back
    local startCFrame = Camera.CFrame
    local targetCFrame = originalCameraSettings.CFrame
    local startTime = tick()
    
    local transitionConnection
    transitionConnection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        local alpha = math.min(elapsed / transitionDuration, 1)
        
        -- Ease out
        local easedAlpha = 1 - (1 - alpha) * (1 - alpha)
        
        if targetCFrame then
            Camera.CFrame = startCFrame:Lerp(targetCFrame, easedAlpha)
        end
        
        if alpha >= 1 then
            transitionConnection:Disconnect()
            
            Camera.CameraType = originalCameraSettings.CameraType or Enum.CameraType.Custom
            Camera.CameraSubject = originalCameraSettings.CameraSubject
        end
    end)
end

function CameraUtility.IsFightCameraActive()
    return fightCameraActive
end

-- ============================================
-- CINEMATIC EFFECTS
-- ============================================

-- Slow motion zoom
function CameraUtility.SlowMoZoom(zoomAmount, duration)
    local startFOV = Camera.FieldOfView
    local targetFOV = startFOV - zoomAmount
    
    local tweenIn = TweenService:Create(Camera, TweenInfo.new(duration / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        FieldOfView = targetFOV
    })
    
    local tweenOut = TweenService:Create(Camera, TweenInfo.new(duration / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        FieldOfView = startFOV
    })
    
    tweenIn:Play()
    tweenIn.Completed:Connect(function()
        tweenOut:Play()
    end)
end

-- Focus on target (moves camera to look at target)
function CameraUtility.FocusOn(targetPosition, duration)
    duration = duration or 0.5
    
    local currentCFrame = Camera.CFrame
    local targetCFrame = CFrame.new(currentCFrame.Position, targetPosition)
    
    local tween = TweenService:Create(Camera, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = targetCFrame
    })
    
    Camera.CameraType = Enum.CameraType.Scriptable
    tween:Play()
    
    return tween
end

return CameraUtility
