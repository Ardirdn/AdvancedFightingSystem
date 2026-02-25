--[[
	MUSIC PLAYER CLIENT - FULLY LOCAL + FULLY SCALED UI
	Place in StarterPlayerScripts
	- All sizes/positions are scale-based (adaptive to any screen)
	- UIAspectRatioConstraint on root wrapper
	- UITextSizeConstraint on every text element
	- Clear named elements
	- Fight music integration (_G.StartFightMusic / _G.StopFightMusic)
]]

local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local SoundService    = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui      = game:GetService("StarterGui")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Icon      = require(ReplicatedStorage:WaitForChild("Icon"))
local MusicConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MusicConfig"))

-- ============================================================
-- COLORS & CONSTANTS
-- ============================================================
local C = {
	Bg         = Color3.fromRGB(20,  20,  23),
	Panel      = Color3.fromRGB(25,  25,  28),
	Btn        = Color3.fromRGB(35,  35,  38),
	Accent     = Color3.fromRGB(70,  130, 255),
	Text       = Color3.fromRGB(255, 255, 255),
	TextSub    = Color3.fromRGB(180, 180, 185),
	Border     = Color3.fromRGB(50,  50,  55),
	Success    = Color3.fromRGB(67,  181, 129),
	Danger     = Color3.fromRGB(237, 66,  69),
	Loop       = Color3.fromRGB(255, 200, 50),
}

local FIGHT_ID      = "rbxassetid://9038254260"
local FADE_DUR      = 1.5
local VOL_DEFAULT   = 0.5

-- ============================================================
-- HELPERS
-- ============================================================
local function notify(msg)
	StarterGui:SetCore("SendNotification", {Title="Music Player", Text=msg, Duration=3})
end

-- UICorner with scale-based radius
local function corner(scl)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(scl or 0.1, 0)
	return c
end

-- UIStroke
local function stroke(col, thick)
	local s = Instance.new("UIStroke")
	s.Color = col; s.Thickness = thick
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return s
end

-- UITextSizeConstraint
local function textConstraint(parent, minS, maxS)
	local t = Instance.new("UITextSizeConstraint")
	t.MinTextSize = minS or 6
	t.MaxTextSize = maxS or 18
	t.Parent = parent
end

-- UIAspectRatioConstraint
local function aspect(parent, ratio)
	local a = Instance.new("UIAspectRatioConstraint")
	a.AspectRatio     = ratio
	a.AspectType      = Enum.AspectType.ScaleWithParentSize
	a.DominantAxis    = Enum.DominantAxis.Width
	a.Parent          = parent
end

-- Create a basic Frame
local function mkFrame(name, bg, parent)
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = bg or C.Bg
	f.BorderSizePixel  = 0
	f.Parent = parent
	return f
end

-- Create a TextLabel (fully scaled)
local function mkLabel(name, text, font, minS, maxS, parent)
	local l = Instance.new("TextLabel")
	l.Name               = name
	l.Text               = text
	l.Font               = font or Enum.Font.Gotham
	l.TextColor3         = C.Text
	l.BackgroundTransparency = 1
	l.BorderSizePixel    = 0
	l.TextScaled         = true
	l.TextXAlignment     = Enum.TextXAlignment.Left
	l.Parent             = parent
	textConstraint(l, minS or 6, maxS or 18)
	return l
end

-- Create a TextButton (fully scaled)
local function mkBtn(name, text, font, bg, parent)
	local b = Instance.new("TextButton")
	b.Name               = name
	b.Text               = text
	b.Font               = font or Enum.Font.GothamBold
	b.BackgroundColor3   = bg or C.Btn
	b.TextColor3         = C.Text
	b.BorderSizePixel    = 0
	b.TextScaled         = true
	b.AutoButtonColor    = false
	b.Parent             = parent
	textConstraint(b, 6, 18)
	return b
end

-- Create ScrollingFrame
local function mkScroll(name, parent)
	local s = Instance.new("ScrollingFrame")
	s.Name                   = name
	s.BackgroundTransparency = 1
	s.BorderSizePixel        = 0
	s.ScrollBarThickness     = 4
	s.ScrollBarImageColor3   = C.Border
	s.CanvasSize             = UDim2.new(0,0,0,0)
	s.AutomaticCanvasSize    = Enum.AutomaticSize.Y
	s.Parent                 = parent
	return s
end

local function mkListLayout(parent, gap)
	local l = Instance.new("UIListLayout")
	l.Padding     = UDim.new(0, gap or 6)
	l.SortOrder   = Enum.SortOrder.LayoutOrder
	l.FillDirection = Enum.FillDirection.Vertical
	l.HorizontalAlignment = Enum.HorizontalAlignment.Center
	l.Parent      = parent
	return l
end

local function fmtTime(s)
	return string.format("%d:%02d", math.floor(s/60), math.floor(s%60))
end

-- ============================================================
-- SOUNDS
-- ============================================================
local ambientSound = Instance.new("Sound")
ambientSound.Name   = "MusicPlayer_AmbientSound"
ambientSound.Volume = VOL_DEFAULT
ambientSound.Looped = false
ambientSound.Parent = SoundService

local fightSound = Instance.new("Sound")
fightSound.Name    = "MusicPlayer_FightSound"
fightSound.SoundId = FIGHT_ID
fightSound.Volume  = 0
fightSound.Looped  = true
fightSound.Parent  = SoundService

-- ============================================================
-- SCREEN GUI
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "MusicPlayerGUI"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled        = false
screenGui.Parent         = playerGui

-- ============================================================
-- ROOT WRAPPER  (scale-based, aspect-ratio constrained)
-- Reference: 900 × 470  (380 main + 10 gap + 80 controls)
-- ============================================================
local Wrapper = mkFrame("MusicPlayer_Wrapper", nil, screenGui)
Wrapper.BackgroundTransparency = 1
Wrapper.Size         = UDim2.new(0.72, 0, 0, 0)
Wrapper.Position     = UDim2.new(0.5,  0, 0.5, 0)
Wrapper.AnchorPoint  = Vector2.new(0.5, 0.5)
Wrapper.ClipsDescendants = false
Wrapper.Visible      = false
aspect(Wrapper, 900/470)  -- ~1.9149

-- ============================================================
-- MAIN PANEL  (top 380/470 = 0.809 of wrapper)
-- ============================================================
local MainPanel = mkFrame("MusicPlayer_MainPanel", C.Bg, Wrapper)
MainPanel.Size     = UDim2.new(1, 0, 380/470, 0)
MainPanel.Position = UDim2.new(0, 0, 0,       0)
MainPanel.ClipsDescendants = false
corner(0.02).Parent = MainPanel
stroke(C.Border, 2).Parent = MainPanel

-- ---- HEADER (50/380 = 0.1316 of MainPanel) ----
local Frame_Header = mkFrame("Frame_Header", C.Panel, MainPanel)
Frame_Header.Size     = UDim2.new(1, 0, 50/380, 0)
Frame_Header.Position = UDim2.new(0, 0, 0, 0)
corner(0.12).Parent = Frame_Header

-- Square off header bottom corners
local Frame_HeaderBottomFill = mkFrame("Frame_HeaderBottomFill", C.Panel, Frame_Header)
Frame_HeaderBottomFill.Size     = UDim2.new(1, 0, 0.32, 0)
Frame_HeaderBottomFill.Position = UDim2.new(0, 0, 0.68, 0)

local Lbl_Title = mkLabel("Lbl_Title", "MUSIC PLAYER", Enum.Font.GothamBold, 8, 22, Frame_Header)
Lbl_Title.Size     = UDim2.new(0.35, 0, 0.9, 0)
Lbl_Title.Position = UDim2.new(0.02, 0, 0.05, 0)

local Btn_Close = mkBtn("Btn_Close", "✕", Enum.Font.GothamBold, C.Btn, Frame_Header)
Btn_Close.Size        = UDim2.new(0, 0, 0.78, 0)
Btn_Close.AnchorPoint = Vector2.new(1, 0.5)
Btn_Close.Position    = UDim2.new(0.965, 0, 0.5, 0)
aspect(Btn_Close, 1)
corner(0.2).Parent = Btn_Close

-- ============================================================
-- BODY PANELS (Y starts at 60/380 = 0.158, height 305/380 = 0.803)
-- ============================================================

-- ---- PLAYLIST PANEL (left, 220/900 = 0.244 wide) ----
local Panel_Playlists = mkFrame("Panel_Playlists", nil, MainPanel)
Panel_Playlists.BackgroundTransparency = 1
Panel_Playlists.Size     = UDim2.new(220/900, 0, 305/380, 0)
Panel_Playlists.Position = UDim2.new(15/900,  0, 60/380,  0)

local Lbl_PlaylistsTitle = mkLabel("Lbl_PlaylistsTitle", "PLAYLISTS", Enum.Font.GothamBold, 7, 15, Panel_Playlists)
Lbl_PlaylistsTitle.Size     = UDim2.new(1, 0, 25/305, 0)
Lbl_PlaylistsTitle.Position = UDim2.new(0, 0, 0, 0)

local Scroll_Playlists = mkScroll("Scroll_Playlists", Panel_Playlists)
Scroll_Playlists.Size     = UDim2.new(1, 0, 275/305, 0)
Scroll_Playlists.Position = UDim2.new(0, 0, 30/305,  0)
mkListLayout(Scroll_Playlists, 8)

-- ---- MUSIC LIST PANEL (center, 400/900 = 0.444 wide) ----
local Panel_MusicList = mkFrame("Panel_MusicList", nil, MainPanel)
Panel_MusicList.BackgroundTransparency = 1
Panel_MusicList.Size     = UDim2.new(400/900, 0, 305/380, 0)
Panel_MusicList.Position = UDim2.new(245/900, 0, 60/380,  0)

-- Search bar
local Frame_Search = mkFrame("Frame_Search", C.Panel, Panel_MusicList)
Frame_Search.Size     = UDim2.new(1, 0, 35/305, 0)
Frame_Search.Position = UDim2.new(0, 0, 0, 0)
corner(0.12).Parent = Frame_Search

local Lbl_SearchIcon = mkLabel("Lbl_SearchIcon", "🔍", Enum.Font.GothamBold, 6, 16, Frame_Search)
Lbl_SearchIcon.Size              = UDim2.new(0.075, 0, 1, 0)
Lbl_SearchIcon.Position          = UDim2.new(0, 0, 0, 0)
Lbl_SearchIcon.TextXAlignment    = Enum.TextXAlignment.Center
Lbl_SearchIcon.TextColor3        = C.TextSub

local Txt_SearchInput = Instance.new("TextBox")
Txt_SearchInput.Name             = "Txt_SearchInput"
Txt_SearchInput.Size             = UDim2.new(0.85, 0, 1, 0)
Txt_SearchInput.Position         = UDim2.new(0.075, 0, 0, 0)
Txt_SearchInput.BackgroundTransparency = 1
Txt_SearchInput.Font             = Enum.Font.Gotham
Txt_SearchInput.PlaceholderText  = "Search by name or ID..."
Txt_SearchInput.Text             = ""
Txt_SearchInput.TextColor3       = C.Text
Txt_SearchInput.TextScaled       = true
Txt_SearchInput.TextXAlignment   = Enum.TextXAlignment.Left
Txt_SearchInput.ClearTextOnFocus = false
Txt_SearchInput.Parent           = Frame_Search
textConstraint(Txt_SearchInput, 6, 14)

local Btn_ClearSearch = mkBtn("Btn_ClearSearch", "✕", Enum.Font.GothamBold, nil, Frame_Search)
Btn_ClearSearch.BackgroundTransparency = 1
Btn_ClearSearch.Size     = UDim2.new(0.075, 0, 1, 0)
Btn_ClearSearch.Position = UDim2.new(0.925, 0, 0, 0)
Btn_ClearSearch.TextColor3 = C.TextSub
Btn_ClearSearch.Visible  = false

-- Filter bar
local Frame_FilterBar = mkFrame("Frame_FilterBar", nil, Panel_MusicList)
Frame_FilterBar.BackgroundTransparency = 1
Frame_FilterBar.Size     = UDim2.new(1, 0, 30/305, 0)
Frame_FilterBar.Position = UDim2.new(0, 0, 45/305, 0)

local Btn_FavToggle = mkBtn("Btn_FavToggle", "♡ Show Favorites Only", Enum.Font.GothamMedium, C.Btn, Frame_FilterBar)
Btn_FavToggle.Size     = UDim2.new(0.48, 0, 1, 0)
Btn_FavToggle.Position = UDim2.new(0, 0, 0, 0)
corner(0.2).Parent = Btn_FavToggle

-- Music scroll
local Scroll_MusicList = mkScroll("Scroll_MusicList", Panel_MusicList)
Scroll_MusicList.Size     = UDim2.new(1, 0, 220/305, 0)
Scroll_MusicList.Position = UDim2.new(0, 0, 85/305,  0)
mkListLayout(Scroll_MusicList, 8)

local Lbl_MusicEmpty = mkLabel("Lbl_MusicEmpty", "No music found", Enum.Font.Gotham, 7, 14, Scroll_MusicList)
Lbl_MusicEmpty.Size     = UDim2.new(1, 0, 0, 60)
Lbl_MusicEmpty.TextColor3 = C.TextSub
Lbl_MusicEmpty.TextXAlignment = Enum.TextXAlignment.Center
Lbl_MusicEmpty.Visible  = false

-- ---- QUEUE PANEL (right, 220/900 = 0.244 wide) ----
local Panel_Queue = mkFrame("Panel_Queue", nil, MainPanel)
Panel_Queue.BackgroundTransparency = 1
Panel_Queue.Size     = UDim2.new(220/900, 0, 305/380, 0)
Panel_Queue.Position = UDim2.new(665/900, 0, 60/380,  0)

local Lbl_QueueTitle = mkLabel("Lbl_QueueTitle", "QUEUE", Enum.Font.GothamBold, 7, 15, Panel_Queue)
Lbl_QueueTitle.Size     = UDim2.new(1, 0, 25/305, 0)
Lbl_QueueTitle.Position = UDim2.new(0, 0, 0, 0)

local Scroll_Queue = mkScroll("Scroll_Queue", Panel_Queue)
Scroll_Queue.Size     = UDim2.new(1, 0, 240/305, 0)
Scroll_Queue.Position = UDim2.new(0, 0, 30/305,  0)
mkListLayout(Scroll_Queue, 8)

local Lbl_QueueEmpty = mkLabel("Lbl_QueueEmpty", "Queue is empty", Enum.Font.Gotham, 6, 13, Scroll_Queue)
Lbl_QueueEmpty.Size     = UDim2.new(1, 0, 0, 50)
Lbl_QueueEmpty.TextColor3 = C.TextSub
Lbl_QueueEmpty.TextXAlignment = Enum.TextXAlignment.Center
Lbl_QueueEmpty.Visible  = true

local Btn_ClearQueue = mkBtn("Btn_ClearQueue", "🗑 Clear Queue", Enum.Font.GothamMedium, C.Btn, Panel_Queue)
Btn_ClearQueue.Size       = UDim2.new(1, 0, 28/305, 0)
Btn_ClearQueue.Position   = UDim2.new(0, 0, 277/305, 0)
Btn_ClearQueue.TextColor3 = C.TextSub
corner(0.2).Parent = Btn_ClearQueue

-- ============================================================
-- CONTROLS BAR (80/470 = 0.170 of wrapper, starts at 390/470 = 0.830)
-- ============================================================
local Frame_Controls = mkFrame("Frame_Controls", C.Panel, Wrapper)
Frame_Controls.Size     = UDim2.new(1, 0, 80/470, 0)
Frame_Controls.Position = UDim2.new(0, 0, 390/470, 0)
corner(0.06).Parent = Frame_Controls
stroke(C.Border, 2).Parent = Frame_Controls

-- LEFT: Song info (220/900 wide)
local Frame_CtrlLeft = mkFrame("Frame_CtrlLeft", nil, Frame_Controls)
Frame_CtrlLeft.BackgroundTransparency = 1
Frame_CtrlLeft.Size     = UDim2.new(220/900, 0, 1, 0)
Frame_CtrlLeft.Position = UDim2.new(15/900,  0, 0, 0)

local Lbl_SongTitle = mkLabel("Lbl_SongTitle", "No Song Playing", Enum.Font.GothamBold, 7, 15, Frame_CtrlLeft)
Lbl_SongTitle.Size           = UDim2.new(0.82, 0, 0.32, 0)
Lbl_SongTitle.Position       = UDim2.new(0,    0, 0.18, 0)
Lbl_SongTitle.TextTruncate   = Enum.TextTruncate.AtEnd

local Lbl_SongPlaylist = mkLabel("Lbl_SongPlaylist", "Playlist: None", Enum.Font.Gotham, 6, 11, Frame_CtrlLeft)
Lbl_SongPlaylist.Size      = UDim2.new(0.82, 0, 0.22, 0)
Lbl_SongPlaylist.Position  = UDim2.new(0,    0, 0.52, 0)
Lbl_SongPlaylist.TextColor3 = C.TextSub

local Btn_FavCurrent = mkBtn("Btn_FavCurrent", "♡", Enum.Font.GothamBold, C.Btn, Frame_CtrlLeft)
Btn_FavCurrent.Size        = UDim2.new(0, 0, 0.44, 0)
Btn_FavCurrent.AnchorPoint = Vector2.new(1, 0.5)
Btn_FavCurrent.Position    = UDim2.new(1, 0, 0.5, 0)
Btn_FavCurrent.TextColor3  = C.TextSub
aspect(Btn_FavCurrent, 1)
corner(0.2).Parent = Btn_FavCurrent

-- CENTER: Playback + Timeline (420/900 wide)
local Frame_CtrlCenter = mkFrame("Frame_CtrlCenter", nil, Frame_Controls)
Frame_CtrlCenter.BackgroundTransparency = 1
Frame_CtrlCenter.Size     = UDim2.new(420/900, 0, 1, 0)
Frame_CtrlCenter.Position = UDim2.new(245/900, 0, 0, 0)

-- Playback buttons row
local Frame_PlaybackRow = mkFrame("Frame_PlaybackRow", nil, Frame_CtrlCenter)
Frame_PlaybackRow.BackgroundTransparency = 1
Frame_PlaybackRow.Size     = UDim2.new(1, 0, 0.52, 0)
Frame_PlaybackRow.Position = UDim2.new(0, 0, 0.05, 0)

-- Helper for control buttons (centered in playback row)
local function mkCtrl(name, text, xPos, xSize)
	local b = mkBtn(name, text, Enum.Font.GothamBold, C.Btn, Frame_PlaybackRow)
	b.Size     = UDim2.new(xSize, 0, 0.88, 0)
	b.Position = UDim2.new(0.5 + xPos, 0, 0.06, 0)
	corner(0.2).Parent = b
	return b
end

-- Centered group: Prev(-0.215) Play(-0.053) Next(0.053+play_width) Loop(...)
local Btn_Prev = mkCtrl("Btn_Prev", "⏮", -0.215, 0.086)
local Btn_Play = mkCtrl("Btn_Play", "▶", -0.105, 0.105)
local Btn_Next = mkCtrl("Btn_Next", "⏭",  0.020, 0.086)
local Btn_Loop = mkCtrl("Btn_Loop", "↺",  0.125, 0.086)

-- Timeline row
local Frame_Timeline = mkFrame("Frame_Timeline", nil, Frame_CtrlCenter)
Frame_Timeline.BackgroundTransparency = 1
Frame_Timeline.Size     = UDim2.new(1, 0, 0.30, 0)
Frame_Timeline.Position = UDim2.new(0, 0, 0.64, 0)

local Lbl_TimeElapsed = mkLabel("Lbl_TimeElapsed", "0:00", Enum.Font.GothamBold, 5, 11, Frame_Timeline)
Lbl_TimeElapsed.Size             = UDim2.new(0.12, 0, 1, 0)
Lbl_TimeElapsed.Position         = UDim2.new(0, 0, 0, 0)
Lbl_TimeElapsed.TextXAlignment   = Enum.TextXAlignment.Left

local Frame_ProgressBg = mkFrame("Frame_ProgressBg", C.Btn, Frame_Timeline)
Frame_ProgressBg.Size        = UDim2.new(0.76, 0, 0.45, 0)
Frame_ProgressBg.Position    = UDim2.new(0.12, 0, 0.275, 0)
corner(0.35).Parent = Frame_ProgressBg

local Frame_ProgressFill = mkFrame("Frame_ProgressFill", C.Success, Frame_ProgressBg)
Frame_ProgressFill.Size = UDim2.new(0, 0, 1, 0)
corner(0.35).Parent = Frame_ProgressFill

local Lbl_TimeTotal = mkLabel("Lbl_TimeTotal", "0:00", Enum.Font.GothamBold, 5, 11, Frame_Timeline)
Lbl_TimeTotal.Size           = UDim2.new(0.12, 0, 1, 0)
Lbl_TimeTotal.Position       = UDim2.new(0.88, 0, 0, 0)
Lbl_TimeTotal.TextXAlignment = Enum.TextXAlignment.Right

-- RIGHT: Volume (220/900 wide)
local Frame_CtrlRight = mkFrame("Frame_CtrlRight", nil, Frame_Controls)
Frame_CtrlRight.BackgroundTransparency = 1
Frame_CtrlRight.Size     = UDim2.new(220/900, 0, 1, 0)
Frame_CtrlRight.Position = UDim2.new(670/900, 0, 0, 0)

local Frame_VolumeRow = mkFrame("Frame_VolumeRow", nil, Frame_CtrlRight)
Frame_VolumeRow.BackgroundTransparency = 1
Frame_VolumeRow.Size        = UDim2.new(1, 0, 0.42, 0)
Frame_VolumeRow.AnchorPoint = Vector2.new(0, 0.5)
Frame_VolumeRow.Position    = UDim2.new(0, 0, 0.5, 0)

local Lbl_VolumeLabel = mkLabel("Lbl_VolumeLabel", "Volume: 50%", Enum.Font.GothamMedium, 5, 11, Frame_VolumeRow)
Lbl_VolumeLabel.Size       = UDim2.new(0.32, 0, 1, 0)
Lbl_VolumeLabel.Position   = UDim2.new(0, 0, 0, 0)
Lbl_VolumeLabel.TextColor3 = C.TextSub

local Btn_VolDec = mkBtn("Btn_VolDec", "-", Enum.Font.GothamBold, C.Btn, Frame_VolumeRow)
Btn_VolDec.Size     = UDim2.new(0, 0, 0.82, 0)
Btn_VolDec.Position = UDim2.new(0.33, 0, 0.09, 0)
aspect(Btn_VolDec, 1)
corner(0.2).Parent = Btn_VolDec

local Frame_SliderBg = mkFrame("Frame_SliderBg", C.Btn, Frame_VolumeRow)
Frame_SliderBg.Size        = UDim2.new(0.34, 0, 0.30, 0)
Frame_SliderBg.AnchorPoint = Vector2.new(0, 0.5)
Frame_SliderBg.Position    = UDim2.new(0.47, 0, 0.5, 0)
corner(0.4).Parent = Frame_SliderBg

local Frame_SliderFill = mkFrame("Frame_SliderFill", C.Accent, Frame_SliderBg)
Frame_SliderFill.Size = UDim2.new(VOL_DEFAULT, 0, 1, 0)
corner(0.4).Parent = Frame_SliderFill

local Frame_SliderHandle = mkFrame("Frame_SliderHandle", C.Text, Frame_SliderBg)
Frame_SliderHandle.Size        = UDim2.new(0, 0, 2, 0)
Frame_SliderHandle.AnchorPoint = Vector2.new(0.5, 0.5)
Frame_SliderHandle.Position    = UDim2.new(VOL_DEFAULT, 0, 0.5, 0)
aspect(Frame_SliderHandle, 1)
corner(0.5).Parent = Frame_SliderHandle

local Btn_VolInc = mkBtn("Btn_VolInc", "+", Enum.Font.GothamBold, C.Btn, Frame_VolumeRow)
Btn_VolInc.Size        = UDim2.new(0, 0, 0.82, 0)
Btn_VolInc.AnchorPoint = Vector2.new(1, 0)
Btn_VolInc.Position    = UDim2.new(1, 0, 0.09, 0)
aspect(Btn_VolInc, 1)
corner(0.2).Parent = Btn_VolInc

-- ============================================================
-- STATE
-- ============================================================
local currentPlaylist   = "All"
local showFavsOnly      = false
local favorites         = {}
local searchQuery       = ""
local localQueue        = {}
local allSongsFlat      = {}
local currentSongIndex  = 1
local currentSongData   = nil
local isPlaying         = false
local isLooping         = false
local isInFight         = false
local currentVolume     = VOL_DEFAULT
local lastQueueAddTime  = 0
local musicIcon

-- ============================================================
-- DATA HELPERS
-- ============================================================
local function getAllSongs()
	local list = {}
	for plName, pl in pairs(MusicConfig.Playlists) do
		for _, song in ipairs(pl.Songs) do
			table.insert(list, {Title=song.Title, SoundId=song.SoundId, Playlist=plName, Thumbnail=pl.Thumbnail})
		end
	end
	return list
end

local function isFav(title) return table.find(favorites, title) ~= nil end

local function toggleFav(title)
	if isFav(title) then
		table.remove(favorites, table.find(favorites, title))
		notify("Removed from favorites")
	else
		table.insert(favorites, title)
		notify("Added to favorites")
	end
end

-- ============================================================
-- SOUND HELPERS
-- ============================================================
local function fadeIn(snd, vol, dur)
	snd.Volume = 0; snd:Play()
	TweenService:Create(snd, TweenInfo.new(dur or FADE_DUR, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Volume=vol}):Play()
end

local function fadeOut(snd, dur, cb)
	local t = TweenService:Create(snd, TweenInfo.new(dur or FADE_DUR, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Volume=0})
	t:Play()
	t.Completed:Connect(function() snd:Stop(); if cb then cb() end end)
end

local function refreshVolume(v)
	currentVolume = math.clamp(v, 0, 1)
	Frame_SliderFill.Size   = UDim2.new(currentVolume, 0, 1, 0)
	Frame_SliderHandle.Position = UDim2.new(currentVolume, 0, 0.5, 0)
	Lbl_VolumeLabel.Text    = "Volume: " .. math.floor(currentVolume * 100) .. "%"
	if not isInFight then ambientSound.Volume = currentVolume end
end

-- ============================================================
-- UI UPDATERS (forward declared)
-- ============================================================
local updateCurrentDisplay, updatePlayBtn, updateQueue, updateMusicList, updatePlaylistButtons

-- ============================================================
-- PLAYBACK
-- ============================================================
local function playSong(songData)
	if not songData then return end
	currentSongData = songData
	if isInFight then updateCurrentDisplay(); return end
	ambientSound:Stop()
	ambientSound.SoundId = songData.SoundId
	ambientSound.Looped  = isLooping
	ambientSound.Volume  = currentVolume
	ambientSound:Play()
	isPlaying = true
	updateCurrentDisplay()
	updatePlayBtn()
end

local function getNextSong()
	if #localQueue > 0 then
		local s = table.remove(localQueue, 1)
		updateQueue(); return s
	end
	currentSongIndex = currentSongIndex + 1
	if currentSongIndex > #allSongsFlat then currentSongIndex = 1 end
	return allSongsFlat[currentSongIndex]
end

local function getPrevSong()
	if ambientSound.IsPlaying and ambientSound.TimePosition > 3 then return currentSongData end
	currentSongIndex = currentSongIndex - 1
	if currentSongIndex < 1 then currentSongIndex = #allSongsFlat end
	return allSongsFlat[currentSongIndex]
end

local function syncIndex(song)
	for i, s in ipairs(allSongsFlat) do
		if s.SoundId == song.SoundId then currentSongIndex = i; break end
	end
end

local function playNext()
	local s = getNextSong(); if s then syncIndex(s); playSong(s) end
end
local function playPrev()
	local s = getPrevSong(); if s then syncIndex(s); playSong(s) end
end

local function togglePause()
	if not currentSongData then
		if #allSongsFlat > 0 then playSong(allSongsFlat[currentSongIndex]) end; return
	end
	if isInFight then return end
	if ambientSound.IsPlaying then ambientSound:Pause(); isPlaying = false
	else ambientSound:Resume(); isPlaying = true end
	updatePlayBtn()
end

local function toggleLoop()
	isLooping = not isLooping
	ambientSound.Looped = isLooping
	Btn_Loop.BackgroundColor3 = isLooping and C.Loop or C.Btn
	Btn_Loop.TextColor3 = isLooping and C.Bg or C.Text
end

ambientSound.Ended:Connect(function()
	if isLooping or isInFight then return end
	task.wait(0.5); playNext()
end)

-- ============================================================
-- FIGHT MUSIC
-- ============================================================
local function startFightMusic()
	if isInFight then return end; isInFight = true
	if ambientSound.IsPlaying then fadeOut(ambientSound, FADE_DUR * 0.5) end
	task.delay(FADE_DUR * 0.3, function()
		if isInFight then fadeIn(fightSound, currentVolume) end
	end)
end

local function stopFightMusic()
	if not isInFight then return end; isInFight = false
	fadeOut(fightSound, FADE_DUR)
	task.delay(FADE_DUR + 0.5, function()
		if not isInFight and currentSongData then
			ambientSound.SoundId = currentSongData.SoundId
			ambientSound.Looped  = isLooping
			fadeIn(ambientSound, currentVolume)
			isPlaying = true; updatePlayBtn()
		end
	end)
end

_G.StartFightMusic = function() startFightMusic() end
_G.StopFightMusic  = function() stopFightMusic()  end

task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("FightingRemotes", 10)
	if not remotes then return end
	local sm = remotes:FindFirstChild("StartMatch")
	if sm then sm.OnClientEvent:Connect(function() startFightMusic() end) end
end)

-- ============================================================
-- UI UPDATE FUNCTIONS
-- ============================================================
function updatePlayBtn()
	Btn_Play.Text = (ambientSound.IsPlaying or isInFight) and "⏸" or "▶"
end

function updateCurrentDisplay()
	if currentSongData then
		Lbl_SongTitle.Text    = currentSongData.Title
		Lbl_SongPlaylist.Text = "Playlist: " .. (currentSongData.Playlist or "Unknown")
		Btn_FavCurrent.Text      = isFav(currentSongData.Title) and "♥" or "♡"
		Btn_FavCurrent.TextColor3 = isFav(currentSongData.Title) and Color3.fromRGB(255,100,100) or C.TextSub
	else
		Lbl_SongTitle.Text    = "No Song Playing"
		Lbl_SongPlaylist.Text = "Playlist: None"
		Btn_FavCurrent.Text      = "♡"; Btn_FavCurrent.TextColor3 = C.TextSub
		Frame_ProgressFill.Size  = UDim2.new(0, 0, 1, 0)
		Lbl_TimeElapsed.Text  = "0:00"; Lbl_TimeTotal.Text = "0:00"
	end
end

function updateQueue()
	for _, ch in ipairs(Scroll_Queue:GetChildren()) do
		if ch:IsA("Frame") then ch:Destroy() end
	end
	Lbl_QueueEmpty.Visible = (#localQueue == 0)

	for i, song in ipairs(localQueue) do
		-- ARC-based height: 220px ref width / 48px ref height = 4.58
		-- UISizeConstraint guarantees min 44px touch target on mobile
		local item = mkFrame("QueueItem_" .. i, C.Panel, Scroll_Queue)
		item.Size        = UDim2.new(0.94, 0, 0, 0)  -- height from ARC, 94% width = padded
		item.LayoutOrder = i
		aspect(item, 4.58)
		local sc = Instance.new("UISizeConstraint")
		sc.MinSize = Vector2.new(0, 44); sc.Parent = item
		corner(0.12).Parent = item

		local lIdx = mkLabel("Lbl_QueueIndex", tostring(i), Enum.Font.GothamBold, 6, 12, item)
		lIdx.Size = UDim2.new(0.12, 0, 1, 0); lIdx.Position = UDim2.new(0.02, 0, 0, 0)
		lIdx.TextXAlignment = Enum.TextXAlignment.Center; lIdx.TextColor3 = C.TextSub

		local lTitle = mkLabel("Lbl_QueueSongTitle", song.Title, Enum.Font.GothamMedium, 7, 13, item)
		lTitle.Size = UDim2.new(0.72, 0, 0.46, 0); lTitle.Position = UDim2.new(0.15, 0, 0.08, 0)
		lTitle.TextTruncate = Enum.TextTruncate.AtEnd

		local lPl = mkLabel("Lbl_QueuePlaylist", song.Playlist or "Unknown", Enum.Font.Gotham, 6, 11, item)
		lPl.Size = UDim2.new(0.72, 0, 0.36, 0); lPl.Position = UDim2.new(0.15, 0, 0.58, 0)
		lPl.TextColor3 = C.TextSub

		local bRem = mkBtn("Btn_QueueRemove_" .. i, "✕", Enum.Font.GothamBold, C.Danger, item)
		bRem.Size = UDim2.new(0, 0, 0.52, 0); bRem.AnchorPoint = Vector2.new(1, 0.5)
		bRem.Position = UDim2.new(1, -10, 0.5, 0) -- jarak fixed 10px dari kanan edge
		aspect(bRem, 1)
		local scBtn = Instance.new("UISizeConstraint")
		scBtn.MinSize = Vector2.new(26, 26)
		scBtn.MaxSize = Vector2.new(34, 34) -- Mencegah kebesaran
		scBtn.Parent = bRem
		corner(0.2).Parent = bRem

		local ci = i
		bRem.MouseButton1Click:Connect(function()
			table.remove(localQueue, ci); updateQueue()
		end)
	end
end

function updatePlaylistButtons()
	for _, ch in ipairs(Scroll_Playlists:GetChildren()) do
		if ch:IsA("TextButton") or ch:IsA("Frame") then ch:Destroy() end
	end
	allSongsFlat = getAllSongs()

	local function mkPlaylistBtn(plName, count)
		local isSelected = (currentPlaylist == plName)
		local btn = Instance.new("TextButton")
		btn.Name = "PlaylistBtn_" .. plName
		-- ARC: 220px ref / 48px ref = 4.58; MinSize ensures touch target
		btn.Size = UDim2.new(0.94, 0, 0, 0)  -- height from ARC, 94% width = padded
		btn.BackgroundColor3 = isSelected and C.Accent or C.Panel
		btn.BorderSizePixel = 0; btn.Text = ""
		btn.AutoButtonColor = false; btn.Parent = Scroll_Playlists
		aspect(btn, 4.58)
		local sc = Instance.new("UISizeConstraint")
		sc.MinSize = Vector2.new(0, 44); sc.Parent = btn
		corner(0.14).Parent = btn

		-- Playlist name: bold, centered, truncates if too long
		local lName = mkLabel("Lbl_PlaylistName", plName, Enum.Font.GothamBold, 7, 14, btn)
		lName.Size     = UDim2.new(0.9, 0, 0.5, 0)
		lName.Position = UDim2.new(0.05, 0, 0.05, 0)
		lName.TextXAlignment = Enum.TextXAlignment.Center
		lName.TextTruncate   = Enum.TextTruncate.AtEnd

		-- Song count: secondary, smaller
		local lCount = mkLabel("Lbl_PlaylistCount", count .. " songs", Enum.Font.Gotham, 6, 11, btn)
		lCount.Size     = UDim2.new(0.9, 0, 0.36, 0)
		lCount.Position = UDim2.new(0.05, 0, 0.60, 0)
		lCount.TextXAlignment = Enum.TextXAlignment.Center
		lCount.TextColor3     = isSelected and C.Text or C.TextSub

		btn.MouseButton1Click:Connect(function()
			currentPlaylist = plName; searchQuery = ""
			Txt_SearchInput.Text = ""; Btn_ClearSearch.Visible = false
			updateMusicList(); updatePlaylistButtons()
		end)
	end

	mkPlaylistBtn("All", #allSongsFlat)
	for plName, pl in pairs(MusicConfig.Playlists) do
		mkPlaylistBtn(plName, #pl.Songs)
	end
end

function updateMusicList()
	for _, ch in ipairs(Scroll_MusicList:GetChildren()) do
		if ch:IsA("Frame") then ch:Destroy() end
	end

	local list = {}
	if currentPlaylist == "All" then
		list = getAllSongs()
	else
		local pl = MusicConfig.Playlists[currentPlaylist]
		if pl then
			for _, s in ipairs(pl.Songs) do
				table.insert(list, {Title=s.Title, SoundId=s.SoundId, Playlist=currentPlaylist, Thumbnail=pl.Thumbnail})
			end
		end
	end

	if searchQuery ~= "" then
		local filtered, lq = {}, string.lower(searchQuery)
		for _, s in ipairs(list) do
			if string.find(string.lower(s.Title), lq, 1, true) or string.find(s.SoundId, searchQuery, 1, true) then
				table.insert(filtered, s)
			end
		end
		list = filtered
	end

	if showFavsOnly then
		local filtered = {}
		for _, s in ipairs(list) do if isFav(s.Title) then table.insert(filtered, s) end end
		list = filtered
	end

	Lbl_MusicEmpty.Visible = (#list == 0)
	if #list == 0 then
		Lbl_MusicEmpty.Text = searchQuery ~= "" and "Musik tidak ditemukan" or "No music found"; return
	end

	for _, songData in ipairs(list) do
		-- ARC: 400px ref width / 52px ref height = 7.69
		-- UISizeConstraint: min 44px ensures tappable on phone
		local item = mkFrame("MusicItem_" .. songData.Title, C.Panel, Scroll_MusicList)
		item.Size = UDim2.new(0.96, 0, 0, 0)  -- height driven by ARC, 96% width = padded
		aspect(item, 7.69)
		local sc = Instance.new("UISizeConstraint")
		sc.MinSize = Vector2.new(0, 44); sc.Parent = item
		corner(0.1).Parent = item

		if currentSongData and currentSongData.SoundId == songData.SoundId then
			stroke(C.Accent, 1).Parent = item
		end

		-- Primary: song title
		local lTitle = mkLabel("Lbl_MusicTitle", songData.Title, Enum.Font.GothamBold, 7, 14, item)
		lTitle.Size = UDim2.new(0.74, 0, 0.46, 0); lTitle.Position = UDim2.new(0.03, 0, 0.08, 0)
		lTitle.TextTruncate = Enum.TextTruncate.AtEnd

		-- Secondary: playlist name
		local lPl = mkLabel("Lbl_MusicPlaylist", songData.Playlist, Enum.Font.Gotham, 6, 11, item)
		lPl.Size = UDim2.new(0.74, 0, 0.34, 0); lPl.Position = UDim2.new(0.03, 0, 0.58, 0)
		lPl.TextColor3 = C.TextSub

		-- Fav button: posisinya dipatok dari kanan edge, dengan MaxSize
		local bFav = mkBtn("Btn_MusicFav", isFav(songData.Title) and "♥" or "♡", Enum.Font.GothamBold, C.Btn, item)
		bFav.Size = UDim2.new(0, 0, 0.60, 0); bFav.AnchorPoint = Vector2.new(1, 0.5)
		bFav.Position = UDim2.new(1, -48, 0.5, 0) -- jarak 48px dari edge (sebelah plus)
		bFav.TextColor3 = isFav(songData.Title) and Color3.fromRGB(255,100,100) or C.TextSub
		aspect(bFav, 1)
		local scFav = Instance.new("UISizeConstraint")
		scFav.MinSize = Vector2.new(28, 28)
		scFav.MaxSize = Vector2.new(35, 35) -- Max target agar ga raksasa
		scFav.Parent = bFav
		corner(0.2).Parent = bFav

		-- Queue button: sama posisinya patokan kanan
		local bQueue = mkBtn("Btn_MusicQueue", "+", Enum.Font.GothamBold, C.Accent, item)
		bQueue.Size = UDim2.new(0, 0, 0.60, 0); bQueue.AnchorPoint = Vector2.new(1, 0.5)
		bQueue.Position = UDim2.new(1, -8, 0.5, 0) -- jarak 8px dari edge
		aspect(bQueue, 1)
		local scQ = Instance.new("UISizeConstraint")
		scQ.MinSize = Vector2.new(28, 28)
		scQ.MaxSize = Vector2.new(35, 35)
		scQ.Parent = bQueue
		corner(0.2).Parent = bQueue

		bFav.MouseButton1Click:Connect(function()
			toggleFav(songData.Title)
			bFav.Text = isFav(songData.Title) and "♥" or "♡"
			bFav.TextColor3 = isFav(songData.Title) and Color3.fromRGB(255,100,100) or C.TextSub
			if showFavsOnly then updateMusicList() end
		end)

		item.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				syncIndex(songData); playSong(songData); updateMusicList()
			end
		end)

		bQueue.MouseButton1Click:Connect(function()
			table.insert(localQueue, songData); updateQueue()
			notify("Queued: " .. songData.Title)
			bQueue.BackgroundColor3 = C.Success
			task.wait(0.4); bQueue.BackgroundColor3 = C.Accent
		end)
	end
end

-- ============================================================
-- PROGRESS BAR UPDATE
-- ============================================================
RunService.Heartbeat:Connect(function()
	if ambientSound.IsPlaying and ambientSound.TimeLength > 0 then
		local p = ambientSound.TimePosition / ambientSound.TimeLength
		Frame_ProgressFill.Size = UDim2.new(p, 0, 1, 0)
		Lbl_TimeElapsed.Text    = fmtTime(ambientSound.TimePosition)
		Lbl_TimeTotal.Text      = fmtTime(ambientSound.TimeLength)
	end
end)

-- ============================================================
-- EVENT CONNECTIONS
-- ============================================================
Btn_Close.MouseButton1Click:Connect(function()
	Wrapper.Visible = false; screenGui.Enabled = false; musicIcon:deselect()
end)

Txt_SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
	searchQuery = Txt_SearchInput.Text
	Btn_ClearSearch.Visible = searchQuery ~= ""; updateMusicList()
end)

Btn_ClearSearch.MouseButton1Click:Connect(function()
	Txt_SearchInput.Text = ""; searchQuery = ""
	Btn_ClearSearch.Visible = false; updateMusicList()
end)

local favFilterOn = false
Btn_FavToggle.MouseButton1Click:Connect(function()
	favFilterOn = not favFilterOn; showFavsOnly = favFilterOn
	Btn_FavToggle.Text = favFilterOn and "♥ Showing Favorites" or "♡ Show Favorites Only"
	Btn_FavToggle.BackgroundColor3 = favFilterOn and C.Accent or C.Btn
	updateMusicList()
end)

Btn_FavCurrent.MouseButton1Click:Connect(function()
	if currentSongData then
		toggleFav(currentSongData.Title)
		Btn_FavCurrent.Text = isFav(currentSongData.Title) and "♥" or "♡"
		Btn_FavCurrent.TextColor3 = isFav(currentSongData.Title) and Color3.fromRGB(255,100,100) or C.TextSub
	end
end)

Btn_Prev.MouseButton1Click:Connect(playPrev)
Btn_Play.MouseButton1Click:Connect(function()
	if not currentSongData and #allSongsFlat > 0 then playSong(allSongsFlat[currentSongIndex])
	else togglePause() end
end)
Btn_Next.MouseButton1Click:Connect(playNext)
Btn_Loop.MouseButton1Click:Connect(toggleLoop)
Btn_ClearQueue.MouseButton1Click:Connect(function()
	localQueue = {}; updateQueue(); notify("Queue cleared")
end)

Btn_VolDec.MouseButton1Click:Connect(function() refreshVolume(currentVolume - 0.1) end)
Btn_VolInc.MouseButton1Click:Connect(function() refreshVolume(currentVolume + 0.1) end)

local draggingVol = false
Frame_SliderBg.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingVol = true
		local mp = UserInputService:GetMouseLocation().X
		refreshVolume(math.clamp((mp - Frame_SliderBg.AbsolutePosition.X) / Frame_SliderBg.AbsoluteSize.X, 0, 1))
	end
end)
Frame_SliderHandle.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then draggingVol = true end
end)
UserInputService.InputEnded:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then draggingVol = false end
end)
UserInputService.InputChanged:Connect(function(inp)
	if draggingVol and inp.UserInputType == Enum.UserInputType.MouseMovement then
		local mp = UserInputService:GetMouseLocation().X
		refreshVolume(math.clamp((mp - Frame_SliderBg.AbsolutePosition.X) / Frame_SliderBg.AbsoluteSize.X, 0, 1))
	end
end)

-- ============================================================
-- DRAGGABLE (drag Wrapper by header)
-- ============================================================
do
	local dragging, dragInput, mousePos, wrapPos
	Frame_Header.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true; mousePos = inp.Position; wrapPos = Wrapper.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	Frame_Header.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement then dragInput = inp end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if inp == dragInput and dragging then
			local delta = inp.Position - mousePos
			Wrapper.Position = UDim2.new(wrapPos.X.Scale, wrapPos.X.Offset + delta.X, wrapPos.Y.Scale, wrapPos.Y.Offset + delta.Y)
		end
	end)
end

-- ============================================================
-- INITIALIZATION
-- ============================================================
task.wait(2)
allSongsFlat = getAllSongs()
updatePlaylistButtons()
updateMusicList()
updateQueue()
updateCurrentDisplay()

if #allSongsFlat > 0 then playSong(allSongsFlat[currentSongIndex]) end

musicIcon = Icon.new()
	:setName("Music")
	:setImage("rbxassetid://7733964640")
	:setLabel("Music")
_G.MusicIcon = musicIcon

musicIcon:bindEvent("selected", function()
		screenGui.Enabled = true; Wrapper.Visible = true
		updatePlaylistButtons(); updateMusicList(); updateQueue()
	end)
	:bindEvent("deselected", function()
		screenGui.Enabled = false; Wrapper.Visible = false
	end)

print("✓ MusicPlayer (Local, Scaled) loaded — " .. #allSongsFlat .. " songs")