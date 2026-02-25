--[[
	DANCE SYSTEM CLIENT - FULLY LOCAL + FULLY SCALED UI
	Place in StarterPlayerScripts
	- All sizes/positions are scale-based
	- UIAspectRatioConstraint on wrapper
	- UITextSizeConstraint on all text elements
]]

local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local RunService      = game:GetService("RunService")

local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui")
local character  = player.Character or player.CharacterAdded:Wait()

local Icon       = require(ReplicatedStorage:WaitForChild("Icon"))
local DanceConfig= require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DanceConfig"))

-- Remotes
local danceComm         = ReplicatedStorage:WaitForChild("DanceComm")
local StartDanceEvent   = danceComm:WaitForChild("StartDance")
local StopDanceEvent    = danceComm:WaitForChild("StopDance")
local SetSpeedEvent     = danceComm:WaitForChild("SetSpeed")

local remoteFolder      = ReplicatedStorage:WaitForChild("DanceRemotes")
local saveFavoriteEvent = remoteFolder:WaitForChild("SaveFavorite")
local getFavoritesFunc  = remoteFolder:WaitForChild("GetFavorites")

-- ==================== COLORS ====================
local C = {
	Bg      = Color3.fromRGB(20, 20, 23),
	Panel   = Color3.fromRGB(26, 26, 30),
	Btn     = Color3.fromRGB(40, 40, 46),
	Accent  = Color3.fromRGB(80, 130, 255),
	Text    = Color3.fromRGB(255, 255, 255),
	TextSub = Color3.fromRGB(160, 160, 165),
	Border  = Color3.fromRGB(50, 50, 56),
	Danger  = Color3.fromRGB(230, 60, 60),
	Success = Color3.fromRGB(60, 200, 100),
}

-- ==================== STATE VARIABLES ====================
local favorites        = {}
local searchQuery      = ""
local currentAnimation = nil
local animationSpeed   = 1
local currentTab       = "All"

-- Playback specific
local Tracks         = {}
local Animators      = {}
local Speeds         = {}
local AnimationDatas = {}

-- ==================== UI HELPERS ====================
local function corner(rad) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(rad, 0); return c end
local function aspect(obj, ratio) local a = Instance.new("UIAspectRatioConstraint"); a.AspectRatio = ratio; a.Parent = obj; return a end
local function stroke(col, thick) local s = Instance.new("UIStroke"); s.Color=col; s.Thickness=thick; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; return s end

local function textConstraint(obj, min, max)
	local t = Instance.new("UITextSizeConstraint")
	t.MinTextSize, t.MaxTextSize = min, max
	t.Parent = obj; return t
end

local function mkFrame(name, col, parent)
	local f = Instance.new("Frame")
	f.Name = name; f.BorderSizePixel = 0
	if col then f.BackgroundColor3 = col else f.BackgroundTransparency = 1 end
	f.Parent = parent; return f
end

local function mkLabel(name, text, font, minSz, maxSz, parent)
	local l = Instance.new("TextLabel")
	l.Name = name; l.BackgroundTransparency = 1; l.BorderSizePixel = 0
	l.Font = font; l.Text = text; l.TextColor3 = C.Text
	l.TextScaled = true; l.Parent = parent
	textConstraint(l, minSz, maxSz)
	return l
end

local function mkBtn(name, text, font, col, parent)
	local b = Instance.new("TextButton")
	b.Name = name; b.BorderSizePixel = 0; b.AutoButtonColor = false
	if col then b.BackgroundColor3 = col else b.BackgroundTransparency = 1 end
	b.Font = font; b.Text = text; b.TextColor3 = C.Text
	b.TextScaled = true; b.Parent = parent
	return b
end

local function mkScroll(name, parent)
	local s = Instance.new("ScrollingFrame")
	s.Name = name; s.BackgroundTransparency = 1; s.BorderSizePixel = 0
	s.ScrollBarThickness = 4; s.ScrollBarImageColor3 = C.Border
	s.CanvasSize = UDim2.new(0,0,0,0)
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.Parent = parent; return s
end

local function mkListLayout(parent, gap)
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, gap or 6)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.FillDirection = Enum.FillDirection.Vertical
	l.HorizontalAlignment = Enum.HorizontalAlignment.Center
	l.Parent = parent; return l
end

-- ============================================================
-- SCREEN GUI
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DancePlayerGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = false
screenGui.Parent = playerGui

-- ============================================================
-- WRAPPER (Aspect Ratio constrained: 320x460 -> ~0.69)
-- ============================================================
local Wrapper = mkFrame("Dance_Wrapper", nil, screenGui)
Wrapper.Size             = UDim2.new(0.25, 0, 0.8, 0)
Wrapper.Position         = UDim2.new(0.05, 0, 0.5, 0)
Wrapper.AnchorPoint      = Vector2.new(0, 0.5)
Wrapper.Visible          = false
Wrapper.ClipsDescendants = false

local MainPanel = mkFrame("Dance_MainPanel", C.Bg, Wrapper)
MainPanel.Size = UDim2.new(1, 0, 1, 0)
corner(0.03).Parent = MainPanel
stroke(C.Border, 2).Parent = MainPanel

-- ---- HEADER ---- (50/460 = 0.108)
local Frame_Header = mkFrame("Frame_Header", C.Panel, MainPanel)
Frame_Header.Size = UDim2.new(1, 0, 50/460, 0)
corner(0.08).Parent = Frame_Header

-- Tutupi siku bawahnya agar gabung
local HeaderPatch = mkFrame("HeaderPatch", C.Panel, Frame_Header)
HeaderPatch.Size = UDim2.new(1, 0, 0.3, 0)
HeaderPatch.Position = UDim2.new(0, 0, 0.7, 0)

local Lbl_Title = mkLabel("Lbl_Title", "DANCE PLAYER", Enum.Font.GothamBlack, 9, 18, Frame_Header)
Lbl_Title.Size = UDim2.new(0.7, 0, 0.45, 0)
Lbl_Title.Position = UDim2.new(0.05, 0, 0.27, 0)
Lbl_Title.TextXAlignment = Enum.TextXAlignment.Left

local Btn_Close = mkBtn("Btn_Close", "✕", Enum.Font.GothamBold, C.Btn, Frame_Header)
Btn_Close.Size = UDim2.new(0, 0, 0.65, 0)
Btn_Close.AnchorPoint = Vector2.new(1, 0.5)
Btn_Close.Position = UDim2.new(0.96, 0, 0.5, 0)
Btn_Close.TextColor3 = C.Danger
aspect(Btn_Close, 1); corner(0.2).Parent = Btn_Close

local scBtnClose = Instance.new("UISizeConstraint")
scBtnClose.MinSize = Vector2.new(28, 28)
scBtnClose.MaxSize = Vector2.new(34, 34)
scBtnClose.Parent = Btn_Close

-- ---- TAB BAR ---- (35/460 = 0.076)
local Frame_Tabs = mkFrame("Frame_Tabs", nil, MainPanel)
Frame_Tabs.Size = UDim2.new(0.9, 0, 35/460, 0)
Frame_Tabs.Position = UDim2.new(0.05, 0, 60/460, 0)

local Btn_TabAll = mkBtn("Btn_TabAll", "All", Enum.Font.GothamBold, C.Accent, Frame_Tabs)
Btn_TabAll.Size = UDim2.new(0.48, 0, 1, 0)
corner(0.15).Parent = Btn_TabAll

local Btn_TabFav = mkBtn("Btn_TabFav", "Favorites", Enum.Font.GothamMedium, C.Btn, Frame_Tabs)
Btn_TabFav.Size = UDim2.new(0.48, 0, 1, 0)
Btn_TabFav.Position = UDim2.new(0.52, 0, 0, 0)
Btn_TabFav.TextColor3 = C.TextSub
corner(0.15).Parent = Btn_TabFav

-- ---- SEARCH BAR ---- (35/460 = 0.076)
local Frame_Search = mkFrame("Frame_Search", C.Panel, MainPanel)
Frame_Search.Size = UDim2.new(0.9, 0, 35/460, 0)
Frame_Search.Position = UDim2.new(0.05, 0, 105/460, 0)
corner(0.15).Parent = Frame_Search

local Lbl_SearchIcon = mkLabel("Lbl_SearchIcon", "🔍", Enum.Font.GothamBold, 8, 16, Frame_Search)
Lbl_SearchIcon.Size = UDim2.new(0.1, 0, 0.6, 0)
Lbl_SearchIcon.Position = UDim2.new(0.02, 0, 0.2, 0)
Lbl_SearchIcon.TextColor3 = C.TextSub

local Txt_SearchInput = Instance.new("TextBox")
Txt_SearchInput.Name = "Txt_SearchInput"
Txt_SearchInput.Size = UDim2.new(0.75, 0, 1, 0)
Txt_SearchInput.Position = UDim2.new(0.13, 0, 0, 0)
Txt_SearchInput.BackgroundTransparency = 1
Txt_SearchInput.Font = Enum.Font.Gotham
Txt_SearchInput.PlaceholderText = "Search dance..."
Txt_SearchInput.Text = ""
Txt_SearchInput.TextColor3 = C.Text
Txt_SearchInput.TextScaled = true
Txt_SearchInput.TextXAlignment = Enum.TextXAlignment.Left
Txt_SearchInput.ClearTextOnFocus = false
Txt_SearchInput.Parent = Frame_Search
textConstraint(Txt_SearchInput, 7, 14)

local Btn_ClearSearch = mkBtn("Btn_ClearSearch", "✕", Enum.Font.GothamBold, nil, Frame_Search)
Btn_ClearSearch.Size = UDim2.new(0.1, 0, 0.6, 0)
Btn_ClearSearch.Position = UDim2.new(0.88, 0, 0.2, 0)
Btn_ClearSearch.TextColor3 = C.TextSub
Btn_ClearSearch.Visible = false

-- ---- MAIN LIST ---- (240/460 = 0.52)
local Scroll_DanceList = mkScroll("Scroll_DanceList", MainPanel)
Scroll_DanceList.Size = UDim2.new(1, 0, 240/460, 0)
Scroll_DanceList.Position = UDim2.new(0, 0, 150/460, 0)
mkListLayout(Scroll_DanceList, 8)

local Lbl_DanceEmpty = mkLabel("Lbl_DanceEmpty", "No dances found", Enum.Font.Gotham, 7, 14, Scroll_DanceList)
Lbl_DanceEmpty.Size = UDim2.new(1, 0, 0, 60)
Lbl_DanceEmpty.TextColor3 = C.TextSub
Lbl_DanceEmpty.Visible = true

-- ---- SPEED CONTROLS ---- (55/460 = 0.12)
local Frame_Speed = mkFrame("Frame_Speed", C.Panel, MainPanel)
Frame_Speed.Size = UDim2.new(0.9, 0, 55/460, 0)
Frame_Speed.Position = UDim2.new(0.05, 0, 395/460, 0)
corner(0.1).Parent = Frame_Speed

local Lbl_Speed = mkLabel("Lbl_Speed", "Speed: 1.0x", Enum.Font.GothamBold, 6, 12, Frame_Speed)
Lbl_Speed.Size = UDim2.new(1, -20, 0.35, 0)
Lbl_Speed.Position = UDim2.new(0, 10, 0.15, 0)
Lbl_Speed.TextXAlignment = Enum.TextXAlignment.Left

local Frame_SliderBg = mkFrame("Frame_SliderBg", C.Btn, Frame_Speed)
Frame_SliderBg.Size = UDim2.new(1, -20, 0.14, 0)
Frame_SliderBg.Position = UDim2.new(0, 10, 0.65, 0)
corner(0.5).Parent = Frame_SliderBg

local Frame_SpeedFill = mkFrame("Frame_SpeedFill", C.Accent, Frame_SliderBg)
Frame_SpeedFill.Size = UDim2.new(0.5, 0, 1, 0)
corner(0.5).Parent = Frame_SpeedFill

local Frame_SpeedHandle = mkFrame("Frame_SpeedHandle", C.Text, Frame_SliderBg)
Frame_SpeedHandle.Size = UDim2.new(0, 14, 0, 14)
Frame_SpeedHandle.AnchorPoint = Vector2.new(0.5, 0.5)
Frame_SpeedHandle.Position = UDim2.new(0.5, 0, 0.5, 0)
corner(0.5).Parent = Frame_SpeedHandle
aspect(Frame_SpeedHandle, 1)


-- ==================== LOGIC FUNCTIONS: ANIMATION ====================

local function playAnim(targetPlayer, animData)
	local currentTrack = Tracks[targetPlayer]
	if currentTrack ~= nil then
		currentTrack:Stop()
		Tracks[targetPlayer] = nil
	end
	AnimationDatas[targetPlayer] = nil

	local anim = Instance.new("Animation")
	anim.AnimationId = animData.AnimationId

	local animator = Animators[targetPlayer]
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = animator
	end

	local currentAnimTrack = animator:LoadAnimation(anim)
	currentAnimTrack:Play()
	currentAnimTrack:AdjustSpeed(animData.Speed or 1)

	Tracks[targetPlayer] = currentAnimTrack
	AnimationDatas[targetPlayer] = animData
end

local function stopAnim(targetPlayer)
	local currentTrack = Tracks[targetPlayer]
	if currentTrack ~= nil then
		currentTrack:Stop()
		Tracks[targetPlayer] = nil
	end
	AnimationDatas[targetPlayer] = nil
end

local function setSpeed(targetPlayer, targetSpeed)
	Speeds[targetPlayer] = targetSpeed
	local animTrack = Tracks[targetPlayer]
	if animTrack then animTrack:AdjustSpeed(targetSpeed) end
end

local function OnCharacterAdded(targetPlayer, char)
	local targetHumanoid = char:WaitForChild("Humanoid")
	local animator = targetHumanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = targetHumanoid
	end
	Animators[targetPlayer] = animator

	if AnimationDatas[targetPlayer] ~= nil then
		playAnim(targetPlayer, AnimationDatas[targetPlayer])
	end
end

for _, p in ipairs(Players:GetPlayers()) do
	if p.Character then OnCharacterAdded(p, p.Character) end
	p.CharacterAdded:Connect(function(c) OnCharacterAdded(p, c) end)
end

Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function(c) OnCharacterAdded(p, c) end)
end)

StartDanceEvent.OnClientEvent:Connect(playAnim)
StopDanceEvent.OnClientEvent:Connect(stopAnim)
SetSpeedEvent.OnClientEvent:Connect(setSpeed)

-- ==================== UI UPDATE ====================

local function isFav(title)
	return table.find(favorites, title) ~= nil
end

local function toggleFav(title)
	if isFav(title) then
		table.remove(favorites, table.find(favorites, title))
		saveFavoriteEvent:FireServer("remove", title)
	else
		table.insert(favorites, title)
		saveFavoriteEvent:FireServer("add", title)
	end
end

local function playDance(animData)
	currentAnimation = animData
	StartDanceEvent:FireServer(animData)
end

local function stopDance()
	currentAnimation = nil
	StopDanceEvent:FireServer()
end

local function updateSpeedUI(relX)
	Frame_SpeedFill.Size = UDim2.new(relX, 0, 1, 0)
	Frame_SpeedHandle.Position = UDim2.new(relX, 0, 0.5, 0)
	animationSpeed = 0.1 + (relX * 3.9)
	Lbl_Speed.Text = string.format("Speed: %.1fx", animationSpeed)
	SetSpeedEvent:FireServer(animationSpeed)
end

local function renderDances()
	for _, ch in ipairs(Scroll_DanceList:GetChildren()) do
		if ch:IsA("Frame") then ch:Destroy() end
	end

	local list = {}
	if currentTab == "All" then
		list = DanceConfig.Animations
	else
		for _, v in ipairs(DanceConfig.Animations) do
			if isFav(v.Title) then table.insert(list, v) end
		end
	end

	if searchQuery ~= "" then
		local filtered = {}
		local q = string.lower(searchQuery)
		for _, v in ipairs(list) do
			if string.find(string.lower(v.Title), q, 1, true) or string.find(v.AnimationId, q, 1, true) then
				table.insert(filtered, v)
			end
		end
		list = filtered
	end

	Lbl_DanceEmpty.Visible = (#list == 0)

	for i, anim in ipairs(list) do
		local isPlaying = (currentAnimation and currentAnimation.Title == anim.Title)

		-- Item size 92% width (memberikan padding natural), height menyesuaikan arc
		local item = mkFrame("DanceItem_"..i, isPlaying and C.Accent or C.Panel, Scroll_DanceList)
		item.Size = UDim2.new(0.92, 0, 0, 0)
		aspect(item, 5.5)  -- Creates dynamic height
		local itemSc = Instance.new("UISizeConstraint")
		itemSc.MinSize = Vector2.new(0, 40) -- Diperkcil touch point minimalnya 40
		itemSc.Parent = item
		corner(0.15).Parent = item

		local lTitle = mkLabel("LblItem_Title", anim.Title, Enum.Font.GothamBold, 6, 14, item)
		lTitle.Size = UDim2.new(0.75, 0, 0.45, 0)
		lTitle.Position = UDim2.new(0.04, 0, 0.27, 0)
		lTitle.TextXAlignment = Enum.TextXAlignment.Left

		local btnFav = mkBtn("BtnItem_Fav", isFav(anim.Title) and "♥" or "♡", Enum.Font.GothamBold, C.Btn, item)
		btnFav.Size = UDim2.new(0, 0, 0.7, 0)
		btnFav.AnchorPoint = Vector2.new(1, 0.5)
		btnFav.Position = UDim2.new(1, -8, 0.5, 0)
		btnFav.TextColor3 = isFav(anim.Title) and Color3.fromRGB(255, 100, 100) or C.TextSub
		aspect(btnFav, 1)
		corner(0.2).Parent = btnFav
		
		local scFavBtn = Instance.new("UISizeConstraint")
		scFavBtn.MinSize = Vector2.new(28, 28)
		scFavBtn.MaxSize = Vector2.new(35, 35)
		scFavBtn.Parent = btnFav

		btnFav.MouseButton1Click:Connect(function()
			toggleFav(anim.Title)
			renderDances()
		end)

		item.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if isPlaying then stopDance() else playDance(anim) end
				renderDances()
			end
		end)
	end
end

-- ==================== EVENTS & DRAGGING ====================

Btn_Close.MouseButton1Click:Connect(function() screenGui.Enabled = false; Wrapper.Visible = false end)

Btn_TabAll.MouseButton1Click:Connect(function()
	currentTab = "All"
	Btn_TabAll.BackgroundColor3 = C.Accent; Btn_TabAll.Font = Enum.Font.GothamBold; Btn_TabAll.TextColor3 = C.Text
	Btn_TabFav.BackgroundColor3 = C.Btn; Btn_TabFav.Font = Enum.Font.GothamMedium; Btn_TabFav.TextColor3 = C.TextSub
	renderDances()
end)

Btn_TabFav.MouseButton1Click:Connect(function()
	currentTab = "Fav"
	Btn_TabFav.BackgroundColor3 = C.Accent; Btn_TabFav.Font = Enum.Font.GothamBold; Btn_TabFav.TextColor3 = C.Text
	Btn_TabAll.BackgroundColor3 = C.Btn; Btn_TabAll.Font = Enum.Font.GothamMedium; Btn_TabAll.TextColor3 = C.TextSub
	renderDances()
end)

Txt_SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
	searchQuery = Txt_SearchInput.Text
	Btn_ClearSearch.Visible = (searchQuery ~= "")
	renderDances()
end)

Btn_ClearSearch.MouseButton1Click:Connect(function()
	Txt_SearchInput.Text = ""; searchQuery = ""
	Btn_ClearSearch.Visible = false
	renderDances()
end)

local draggingSpeed = false
Frame_SliderBg.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSpeed = true
		updateSpeedUI(math.clamp((UserInputService:GetMouseLocation().X - Frame_SliderBg.AbsolutePosition.X) / Frame_SliderBg.AbsoluteSize.X, 0, 1))
	end
end)
Frame_SpeedHandle.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then draggingSpeed = true end
end)
UserInputService.InputEnded:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then draggingSpeed = false end
end)
UserInputService.InputChanged:Connect(function(inp)
	if draggingSpeed and inp.UserInputType == Enum.UserInputType.MouseMovement then
		updateSpeedUI(math.clamp((UserInputService:GetMouseLocation().X - Frame_SliderBg.AbsolutePosition.X) / Frame_SliderBg.AbsoluteSize.X, 0, 1))
	end
end)

-- Draggable Wrapper
local drg, dInp, mPos, wPos
Frame_Header.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		drg = true; mPos = i.Position; wPos = Wrapper.Position
		i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then drg=false end end)
	end
end)
Frame_Header.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then dInp = i end end)
UserInputService.InputChanged:Connect(function(i)
	if i == dInp and drg then
		local d = i.Position - mPos
		Wrapper.Position = UDim2.new(wPos.X.Scale, wPos.X.Offset + d.X, wPos.Y.Scale, wPos.Y.Offset + d.Y)
	end
end)

-- ==================== INIT ====================

local danceIcon = Icon.new()
	:setName("Dance")
	:setImage("rbxassetid://7733764811")
	:setLabel("Dance")
_G.DanceIcon = danceIcon

danceIcon:bindEvent("selected", function()
		screenGui.Enabled = true; Wrapper.Visible = true
		task.spawn(function()
			task.wait(2)
			local s, res = pcall(function() return getFavoritesFunc:InvokeServer() end)
			if s and res then favorites = res; renderDances() end
		end)
		renderDances()
	end)
	:bindEvent("deselected", function()
		screenGui.Enabled = false; Wrapper.Visible = false
	end)

print("✅ [DANCE CLIENT] Scaled Loaded")