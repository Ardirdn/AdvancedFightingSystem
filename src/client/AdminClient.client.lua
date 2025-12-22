--[[
    AdminClient.client.lua
    Client script to receive private admin command responses
    
    Features:
    - Receives private messages from server (AdminPrivateMessage)
    - Displays responses in a private notification UI
    - Only visible to the admin who sent the command
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================
-- CREATE ADMIN MESSAGE UI
-- ============================================

local function createAdminUI()
    -- Check if already exists
    if playerGui:FindFirstChild("AdminMessageUI") then
        return playerGui.AdminMessageUI
    end
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AdminMessageUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 100
    screenGui.Parent = playerGui
    
    -- Container for messages (bottom-left corner)
    local container = Instance.new("Frame")
    container.Name = "MessageContainer"
    container.Size = UDim2.new(0, 450, 0, 300)
    container.Position = UDim2.new(0, 20, 1, -320)
    container.BackgroundTransparency = 1
    container.Parent = screenGui
    
    -- UIListLayout for stacking messages
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = container
    
    return screenGui
end

-- ============================================
-- MESSAGE DISPLAY
-- ============================================

local messageOrder = 0

local function showAdminMessage(message)
    local screenGui = createAdminUI()
    local container = screenGui:FindFirstChild("MessageContainer")
    if not container then return end
    
    messageOrder = messageOrder + 1
    
    -- Create message frame
    local msgFrame = Instance.new("Frame")
    msgFrame.Name = "Message_" .. messageOrder
    msgFrame.Size = UDim2.new(1, 0, 0, 0)
    msgFrame.AutomaticSize = Enum.AutomaticSize.Y
    msgFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    msgFrame.BackgroundTransparency = 0.2
    msgFrame.BorderSizePixel = 0
    msgFrame.LayoutOrder = -messageOrder -- Newest at bottom
    msgFrame.Parent = container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = msgFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 150, 255)
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = msgFrame
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = msgFrame
    
    -- Label with fixed header
    local headerLabel = Instance.new("TextLabel")
    headerLabel.Name = "Header"
    headerLabel.Size = UDim2.new(1, 0, 0, 16)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Font = Enum.Font.GothamBold
    headerLabel.TextSize = 12
    headerLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.Text = "🔧 ADMIN COMMAND"
    headerLabel.Parent = msgFrame
    
    -- Message text
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Name = "Message"
    msgLabel.Size = UDim2.new(1, 0, 0, 0)
    msgLabel.Position = UDim2.new(0, 0, 0, 18)
    msgLabel.AutomaticSize = Enum.AutomaticSize.Y
    msgLabel.BackgroundTransparency = 1
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 14
    msgLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    msgLabel.Text = message
    msgLabel.Parent = msgFrame
    
    -- Animate in
    msgFrame.BackgroundTransparency = 1
    stroke.Transparency = 1
    headerLabel.TextTransparency = 1
    msgLabel.TextTransparency = 1
    
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    
    TweenService:Create(msgFrame, tweenInfo, {BackgroundTransparency = 0.2}):Play()
    TweenService:Create(stroke, tweenInfo, {Transparency = 0.5}):Play()
    TweenService:Create(headerLabel, tweenInfo, {TextTransparency = 0}):Play()
    TweenService:Create(msgLabel, tweenInfo, {TextTransparency = 0}):Play()
    
    -- Auto-remove after 8 seconds
    task.delay(8, function()
        if msgFrame and msgFrame.Parent then
            local fadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            
            TweenService:Create(msgFrame, fadeInfo, {BackgroundTransparency = 1}):Play()
            TweenService:Create(stroke, fadeInfo, {Transparency = 1}):Play()
            TweenService:Create(headerLabel, fadeInfo, {TextTransparency = 1}):Play()
            TweenService:Create(msgLabel, fadeInfo, {TextTransparency = 1}):Play()
            
            task.delay(0.5, function()
                if msgFrame and msgFrame.Parent then
                    msgFrame:Destroy()
                end
            end)
        end
    end)
    
    -- Limit visible messages (keep last 10)
    local children = container:GetChildren()
    local frames = {}
    for _, child in ipairs(children) do
        if child:IsA("Frame") then
            table.insert(frames, child)
        end
    end
    
    if #frames > 10 then
        -- Sort by LayoutOrder (oldest first)
        table.sort(frames, function(a, b) 
            return a.LayoutOrder > b.LayoutOrder
        end)
        
        -- Remove oldest
        for i = 11, #frames do
            frames[i]:Destroy()
        end
    end
end

-- ============================================
-- REMOTE CONNECTION
-- ============================================

local adminRemote = ReplicatedStorage:WaitForChild("AdminPrivateMessage", 30)
if adminRemote then
    adminRemote.OnClientEvent:Connect(function(message)
        showAdminMessage(message)
    end)
    print("✅ [AdminClient] Private message receiver ready")
else
    warn("⚠️ [AdminClient] AdminPrivateMessage remote not found")
end
