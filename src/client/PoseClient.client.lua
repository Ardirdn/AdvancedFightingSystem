--[[
    PoseClient.client.lua
    Client script for Pose/Dance System
    
    Handles:
    - UI for pose selection (dark mode, left side)
    - Playing/stopping animations locally
    - Receiving pose updates from other players
    
    Controls:
    - Press P or click the button to toggle pose menu
    - Click a pose to play it
    - Click again to stop
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

print("🎭 [PoseClient] Loading...")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for character
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")

-- Wait for Modules
local Modules = ReplicatedStorage:WaitForChild("Modules", 10)
if not Modules then
    warn("❌ [PoseClient] Modules folder not found!")
    return
end

local PoseConfig = require(Modules:WaitForChild("PoseConfig"))

-- Wait for Remotes
local PoseRemotes = ReplicatedStorage:WaitForChild("PoseRemotes", 10)
if not PoseRemotes then
    warn("❌ [PoseClient] PoseRemotes folder not found!")
    return
end

local PlayPoseEvent = PoseRemotes:WaitForChild("PlayPose")
local StopPoseEvent = PoseRemotes:WaitForChild("StopPose")

print("✅ [PoseClient] Modules and remotes loaded")

-- ============================================
-- STATE VARIABLES
-- ============================================
local isMenuOpen = false
local currentPoseTrack = nil
local currentPoseId = nil
local poseUI = nil
local toggleButtonUI = nil
local poseButtons = {} -- Store references to pose buttons

-- Track other players' poses
local otherPlayerPoses = {} -- [Player] = AnimationTrack

-- ============================================
-- ANIMATION FUNCTIONS
-- ============================================

local function stopCurrentPose()
    if currentPoseTrack then
        currentPoseTrack:Stop(0.2)
        currentPoseTrack:Destroy()
        currentPoseTrack = nil
        currentPoseId = nil
        
        -- Notify server
        StopPoseEvent:FireServer()
        
        -- Update UI (remove selected state from all buttons)
        for _, button in pairs(poseButtons) do
            if button:FindFirstChild("UIStroke") then
                local stroke = button.UIStroke
                stroke.Color = PoseConfig.UI.StrokeColor
                stroke.Thickness = PoseConfig.UI.StrokeThickness
            end
            button.BackgroundColor3 = PoseConfig.UI.ItemBackgroundColor
        end
        
        print("🎭 [PoseClient] Pose stopped")
    end
end

local function playPose(animationId)
    -- If same pose, stop it
    if currentPoseId == animationId then
        stopCurrentPose()
        return
    end
    
    -- Stop current pose if any
    if currentPoseTrack then
        currentPoseTrack:Stop(0.2)
        currentPoseTrack:Destroy()
        currentPoseTrack = nil
    end
    
    -- Create and play new pose
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://" .. animationId
    
    local track = Animator:LoadAnimation(animation)
    track.Looped = true
    track.Priority = Enum.AnimationPriority.Action
    track:Play(0.2)
    
    currentPoseTrack = track
    currentPoseId = animationId
    
    -- Notify server
    PlayPoseEvent:FireServer(animationId)
    
    -- Update UI (highlight selected)
    for id, button in pairs(poseButtons) do
        if button:FindFirstChild("UIStroke") then
            local stroke = button.UIStroke
            if id == animationId then
                stroke.Color = PoseConfig.UI.SelectedStrokeColor
                stroke.Thickness = PoseConfig.UI.SelectedStrokeThickness
                button.BackgroundColor3 = PoseConfig.UI.ItemSelectedColor
            else
                stroke.Color = PoseConfig.UI.StrokeColor
                stroke.Thickness = PoseConfig.UI.StrokeThickness
                button.BackgroundColor3 = PoseConfig.UI.ItemBackgroundColor
            end
        end
    end
    
    print("🎭 [PoseClient] Playing pose:", animationId)
end

-- ============================================
-- OTHER PLAYER POSE HANDLING
-- ============================================

local function playPoseForPlayer(player, animationId)
    if not player or not player.Character then return end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then return end
    
    -- Stop any existing pose for this player
    if otherPlayerPoses[player] then
        otherPlayerPoses[player]:Stop(0.2)
        otherPlayerPoses[player]:Destroy()
        otherPlayerPoses[player] = nil
    end
    
    -- Play new pose
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://" .. animationId
    
    local track = animator:LoadAnimation(animation)
    track.Looped = true
    track.Priority = Enum.AnimationPriority.Action
    track:Play(0.2)
    
    otherPlayerPoses[player] = track
    
    print("🎭 [PoseClient]", player.Name, "is playing pose:", animationId)
end

local function stopPoseForPlayer(player)
    if otherPlayerPoses[player] then
        otherPlayerPoses[player]:Stop(0.2)
        otherPlayerPoses[player]:Destroy()
        otherPlayerPoses[player] = nil
        
        print("🎭 [PoseClient]", player.Name, "stopped pose")
    end
end

-- ============================================
-- TOGGLE BUTTON CREATION (Small button on left)
-- ============================================

local function createToggleButton()
    local config = PoseConfig.UI
    
    -- Main ScreenGui for toggle button
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PoseToggleButton"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 4
    screenGui.Enabled = true
    screenGui.Parent = PlayerGui
    
    -- Toggle Button Frame (small, left side, vertically centered)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = "ToggleFrame"
    toggleFrame.AnchorPoint = Vector2.new(0, 0.5) -- Anchor left-center
    toggleFrame.Position = UDim2.new(0, 10, 0.5, 0) -- Left side, vertically centered
    toggleFrame.BackgroundColor3 = config.BackgroundColor
    toggleFrame.BackgroundTransparency = config.BackgroundTransparency
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Parent = screenGui
    
    -- Aspect Ratio Constraint for toggle button
    local toggleAspect = Instance.new("UIAspectRatioConstraint")
    toggleAspect.AspectRatio = config.ToggleButtonAspectRatio
    toggleAspect.AspectType = Enum.AspectType.ScaleWithParentSize
    toggleAspect.DominantAxis = Enum.DominantAxis.Width
    toggleAspect.Parent = toggleFrame
    
    -- Size from config
    toggleFrame.Size = UDim2.new(config.ToggleButtonWidthScale, 0, 0, 0)
    
    -- Corner radius
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0.3, 0)
    toggleCorner.Parent = toggleFrame
    
    -- Stroke
    local toggleStroke = Instance.new("UIStroke")
    toggleStroke.Color = config.StrokeColor
    toggleStroke.Thickness = config.StrokeThickness
    toggleStroke.Transparency = 0.3
    toggleStroke.Parent = toggleFrame
    
    -- Clickable button overlay
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "Button"
    toggleButton.Size = UDim2.new(1, 0, 1, 0)
    toggleButton.BackgroundTransparency = 1
    toggleButton.Text = ""
    toggleButton.AutoButtonColor = false
    toggleButton.Parent = toggleFrame
    
    -- Content container (horizontal layout)
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -8, 1, -6)
    contentFrame.Position = UDim2.new(0, 4, 0, 3)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = toggleFrame
    
    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0.4, 0, 1, 0)
    iconLabel.Position = UDim2.new(0, 0, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.Text = "🎭"
    iconLabel.TextColor3 = config.TextColor
    iconLabel.TextScaled = true
    iconLabel.Parent = contentFrame
    
    -- Text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.Size = UDim2.new(0.6, 0, 1, 0)
    textLabel.Position = UDim2.new(0.4, 0, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Text = "Pose"
    textLabel.TextColor3 = config.TextColor
    textLabel.TextScaled = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.Parent = contentFrame
    
    local textConstraint = Instance.new("UITextSizeConstraint")
    textConstraint.MaxTextSize = 14
    textConstraint.MinTextSize = 6
    textConstraint.Parent = textLabel
    
    -- Hover effects
    toggleButton.MouseEnter:Connect(function()
        TweenService:Create(toggleFrame, TweenInfo.new(0.15), {
            BackgroundColor3 = config.ItemHoverColor
        }):Play()
        TweenService:Create(toggleStroke, TweenInfo.new(0.15), {
            Color = config.SelectedStrokeColor
        }):Play()
    end)
    
    toggleButton.MouseLeave:Connect(function()
        TweenService:Create(toggleFrame, TweenInfo.new(0.15), {
            BackgroundColor3 = config.BackgroundColor
        }):Play()
        TweenService:Create(toggleStroke, TweenInfo.new(0.15), {
            Color = config.StrokeColor
        }):Play()
    end)
    
    toggleButtonUI = screenGui
    
    return toggleButton
end

-- ============================================
-- UI CREATION (Pose Menu)
-- ============================================

local function createPoseUI()
    local config = PoseConfig.UI
    local poses = PoseConfig.Poses
    
    -- Main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PoseUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 5
    screenGui.Enabled = false
    screenGui.Parent = PlayerGui
    
    -- Main Frame (left side of screen)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.AnchorPoint = Vector2.new(0, 0.5)
    mainFrame.Position = UDim2.new(0, 10, 0.5, 0)
    mainFrame.BackgroundColor3 = config.BackgroundColor
    mainFrame.BackgroundTransparency = config.BackgroundTransparency
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Size: Width from config, height auto from aspect ratio
    mainFrame.Size = UDim2.new(config.FrameWidthScale, 0, 0, 0)
    
    -- Aspect Ratio Constraint (width-based) - adjust FrameAspectRatio in config to change height
    local aspectRatio = Instance.new("UIAspectRatioConstraint")
    aspectRatio.AspectRatio = config.FrameAspectRatio
    aspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize
    aspectRatio.DominantAxis = Enum.DominantAxis.Width
    aspectRatio.Parent = mainFrame
    
    -- Corner radius
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    -- Main stroke
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = config.StrokeColor
    mainStroke.Thickness = config.StrokeThickness
    mainStroke.Transparency = 0.3
    mainStroke.Parent = mainFrame
    
    -- Title Bar (scaled)
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0.12, 0) -- 12% of frame height
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = mainFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(0.6, 0, 1, 0)
    titleLabel.Position = UDim2.new(0, config.Padding, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "🎭 Poses"
    titleLabel.TextColor3 = config.TitleColor
    titleLabel.TextScaled = true
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    local titleTextConstraint = Instance.new("UITextSizeConstraint")
    titleTextConstraint.MaxTextSize = 18
    titleTextConstraint.MinTextSize = 10
    titleTextConstraint.Parent = titleLabel
    
    -- Close button (X) - scaled
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0.15, 0, 0.7, 0) -- Scaled size
    closeButton.AnchorPoint = Vector2.new(1, 0.5)
    closeButton.Position = UDim2.new(1, -4, 0.5, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    closeButton.BackgroundTransparency = 0.3
    closeButton.BorderSizePixel = 0
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.AutoButtonColor = false
    closeButton.Parent = titleBar
    
    -- Keep close button square
    local closeAspect = Instance.new("UIAspectRatioConstraint")
    closeAspect.AspectRatio = 1
    closeAspect.DominantAxis = Enum.DominantAxis.Height
    closeAspect.Parent = closeButton
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0.3, 0)
    closeCorner.Parent = closeButton
    
    local closeTextConstraint = Instance.new("UITextSizeConstraint")
    closeTextConstraint.MaxTextSize = 14
    closeTextConstraint.MinTextSize = 8
    closeTextConstraint.Parent = closeButton
    
    -- Close button hover effects
    closeButton.MouseEnter:Connect(function()
        TweenService:Create(closeButton, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(220, 70, 70),
            BackgroundTransparency = 0
        }):Play()
    end)
    
    closeButton.MouseLeave:Connect(function()
        TweenService:Create(closeButton, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(180, 60, 60),
            BackgroundTransparency = 0.3
        }):Play()
    end)
    
    -- Scrolling Frame for poses (scaled)
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "PoseList"
    scrollFrame.Size = UDim2.new(1, -config.Padding * 2, 0.86, -config.Padding) -- Below title bar
    scrollFrame.Position = UDim2.new(0, config.Padding, 0.12, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Auto-sized
    scrollFrame.Parent = mainFrame
    
    -- List Layout for pose items
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, config.Padding)
    listLayout.Parent = scrollFrame
    
    -- Create pose buttons (scaled height)
    for i, pose in ipairs(poses) do
        local poseButton = Instance.new("TextButton")
        poseButton.Name = "Pose_" .. pose.AnimationId
        poseButton.Size = UDim2.new(1, 0, config.ItemHeightScale, 0) -- Scaled height
        poseButton.LayoutOrder = i
        poseButton.BackgroundColor3 = config.ItemBackgroundColor
        poseButton.BorderSizePixel = 0
        poseButton.Text = ""
        poseButton.AutoButtonColor = false
        poseButton.Parent = scrollFrame
        
        -- Button corner
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = poseButton
        
        -- Button stroke
        local buttonStroke = Instance.new("UIStroke")
        buttonStroke.Name = "UIStroke"
        buttonStroke.Color = config.StrokeColor
        buttonStroke.Thickness = config.StrokeThickness
        buttonStroke.Transparency = 0.5
        buttonStroke.Parent = poseButton
        
        -- Icon (emoji) - scaled
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Name = "Icon"
        iconLabel.Size = UDim2.new(0.25, 0, 1, 0) -- 25% of width
        iconLabel.Position = UDim2.new(0.02, 0, 0, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.Text = pose.Icon or "🎭"
        iconLabel.TextColor3 = config.TextColor
        iconLabel.TextScaled = true
        iconLabel.Parent = poseButton
        
        -- Pose name (scaled)
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "PoseName"
        nameLabel.Size = UDim2.new(0.7, 0, 1, 0) -- 70% of width
        nameLabel.Position = UDim2.new(0.28, 0, 0, 0) -- After icon
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamMedium
        nameLabel.Text = pose.Name
        nameLabel.TextColor3 = config.TextColor
        nameLabel.TextScaled = true
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = poseButton
        
        local nameTextConstraint = Instance.new("UITextSizeConstraint")
        nameTextConstraint.MaxTextSize = 14
        nameTextConstraint.MinTextSize = 8
        nameTextConstraint.Parent = nameLabel
        
        -- Store button reference
        poseButtons[pose.AnimationId] = poseButton
        
        -- Button interactions
        poseButton.MouseEnter:Connect(function()
            if currentPoseId ~= pose.AnimationId then
                TweenService:Create(poseButton, TweenInfo.new(0.1), {
                    BackgroundColor3 = config.ItemHoverColor
                }):Play()
            end
        end)
        
        poseButton.MouseLeave:Connect(function()
            if currentPoseId ~= pose.AnimationId then
                TweenService:Create(poseButton, TweenInfo.new(0.1), {
                    BackgroundColor3 = config.ItemBackgroundColor
                }):Play()
            end
        end)
        
        poseButton.MouseButton1Click:Connect(function()
            playPose(pose.AnimationId)
        end)
    end
    
    poseUI = screenGui
    
    -- Return close button for connection
    return screenGui, closeButton
end

-- ============================================
-- MENU TOGGLE
-- ============================================

local function showToggleButton()
    if toggleButtonUI then
        local frame = toggleButtonUI:FindFirstChild("ToggleFrame")
        if frame then
            toggleButtonUI.Enabled = true
            frame.BackgroundTransparency = 1
            
            -- Fade in
            TweenService:Create(frame, TweenInfo.new(PoseConfig.UI.FadeInDuration), {
                BackgroundTransparency = PoseConfig.UI.BackgroundTransparency
            }):Play()
            
            for _, child in ipairs(frame:GetDescendants()) do
                if child:IsA("TextLabel") then
                    child.TextTransparency = 1
                    TweenService:Create(child, TweenInfo.new(PoseConfig.UI.FadeInDuration), {
                        TextTransparency = 0
                    }):Play()
                end
                if child:IsA("UIStroke") then
                    child.Transparency = 1
                    TweenService:Create(child, TweenInfo.new(PoseConfig.UI.FadeInDuration), {
                        Transparency = 0.3
                    }):Play()
                end
            end
        end
    end
end

local function hideToggleButton()
    if toggleButtonUI then
        local frame = toggleButtonUI:FindFirstChild("ToggleFrame")
        if frame then
            TweenService:Create(frame, TweenInfo.new(PoseConfig.UI.FadeOutDuration), {
                BackgroundTransparency = 1
            }):Play()
            
            for _, child in ipairs(frame:GetDescendants()) do
                if child:IsA("TextLabel") then
                    TweenService:Create(child, TweenInfo.new(PoseConfig.UI.FadeOutDuration), {
                        TextTransparency = 1
                    }):Play()
                end
                if child:IsA("UIStroke") then
                    TweenService:Create(child, TweenInfo.new(PoseConfig.UI.FadeOutDuration), {
                        Transparency = 1
                    }):Play()
                end
            end
            
            task.delay(PoseConfig.UI.FadeOutDuration, function()
                if isMenuOpen then
                    toggleButtonUI.Enabled = false
                end
            end)
        end
    end
end

local function toggleMenu()
    if not poseUI then return end
    
    local config = PoseConfig.UI
    local mainFrame = poseUI:FindFirstChild("MainFrame")
    if not mainFrame then return end
    
    isMenuOpen = not isMenuOpen
    
    if isMenuOpen then
        -- Hide toggle button
        hideToggleButton()
        
        -- Show menu with fade in
        poseUI.Enabled = true
        mainFrame.BackgroundTransparency = 1
        
        for _, child in ipairs(mainFrame:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                child.TextTransparency = 1
            end
            if child:IsA("UIStroke") then
                child.Transparency = 1
            end
            if child:IsA("Frame") or child:IsA("TextButton") then
                if child.BackgroundTransparency < 1 then
                    child:SetAttribute("OriginalBgTransparency", child.BackgroundTransparency)
                    child.BackgroundTransparency = 1
                end
            end
        end
        
        -- Animate in
        TweenService:Create(mainFrame, TweenInfo.new(config.FadeInDuration), {
            BackgroundTransparency = config.BackgroundTransparency
        }):Play()
        
        for _, child in ipairs(mainFrame:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                TweenService:Create(child, TweenInfo.new(config.FadeInDuration), {
                    TextTransparency = 0
                }):Play()
            end
            if child:IsA("UIStroke") then
                local targetTrans = 0.3
                if child.Parent and child.Parent:IsA("TextButton") then
                    targetTrans = 0.5
                end
                TweenService:Create(child, TweenInfo.new(config.FadeInDuration), {
                    Transparency = targetTrans
                }):Play()
            end
            if child:IsA("Frame") or child:IsA("TextButton") then
                local origTrans = child:GetAttribute("OriginalBgTransparency")
                if origTrans then
                    TweenService:Create(child, TweenInfo.new(config.FadeInDuration), {
                        BackgroundTransparency = origTrans
                    }):Play()
                end
            end
        end
        
        print("🎭 [PoseClient] Menu opened")
    else
        -- Hide menu with fade out
        TweenService:Create(mainFrame, TweenInfo.new(config.FadeOutDuration), {
            BackgroundTransparency = 1
        }):Play()
        
        for _, child in ipairs(mainFrame:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                TweenService:Create(child, TweenInfo.new(config.FadeOutDuration), {
                    TextTransparency = 1
                }):Play()
            end
            if child:IsA("UIStroke") then
                TweenService:Create(child, TweenInfo.new(config.FadeOutDuration), {
                    Transparency = 1
                }):Play()
            end
            if child:IsA("Frame") or child:IsA("TextButton") then
                TweenService:Create(child, TweenInfo.new(config.FadeOutDuration), {
                    BackgroundTransparency = 1
                }):Play()
            end
        end
        
        task.delay(config.FadeOutDuration, function()
            if not isMenuOpen then
                poseUI.Enabled = false
                -- Show toggle button again
                showToggleButton()
            end
        end)
        
        print("🎭 [PoseClient] Menu closed")
    end
end

-- ============================================
-- INPUT HANDLING
-- ============================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == PoseConfig.UI.ToggleKey then
        toggleMenu()
    end
end)

-- ============================================
-- EVENT HANDLERS
-- ============================================

PlayPoseEvent.OnClientEvent:Connect(function(player, animationId)
    playPoseForPlayer(player, animationId)
end)

StopPoseEvent.OnClientEvent:Connect(function(player)
    stopPoseForPlayer(player)
end)

-- ============================================
-- CHARACTER RESPAWN HANDLING
-- ============================================

Player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = newCharacter:WaitForChild("Humanoid")
    Animator = Humanoid:WaitForChild("Animator")
    
    -- Reset pose state
    currentPoseTrack = nil
    currentPoseId = nil
    
    -- Update UI
    for _, button in pairs(poseButtons) do
        if button:FindFirstChild("UIStroke") then
            local stroke = button.UIStroke
            stroke.Color = PoseConfig.UI.StrokeColor
            stroke.Thickness = PoseConfig.UI.StrokeThickness
        end
        button.BackgroundColor3 = PoseConfig.UI.ItemBackgroundColor
    end
    
    print("🔄 [PoseClient] Character respawned, pose reset")
end)

-- Cleanup when other players leave
Players.PlayerRemoving:Connect(function(player)
    if otherPlayerPoses[player] then
        otherPlayerPoses[player]:Stop()
        otherPlayerPoses[player]:Destroy()
        otherPlayerPoses[player] = nil
    end
end)

-- ============================================
-- INITIALIZATION
-- ============================================

-- Create toggle button first
local toggleButton = createToggleButton()

-- Connect toggle button click
toggleButton.MouseButton1Click:Connect(function()
    toggleMenu()
end)

-- Create pose menu
local _, closeButton = createPoseUI()

-- Connect close button
closeButton.MouseButton1Click:Connect(function()
    toggleMenu()
end)

print("========================================")
print("🎭 [PoseClient] Pose Client Loaded!")
print("   Click the 🎭 Pose button or press P")
print("   Click a pose to play it")
print("   Click again to stop")
print("========================================")
