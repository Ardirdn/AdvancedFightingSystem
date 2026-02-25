--[[
    DANCE SYSTEM SERVER (SIMPLIFIED & OPTIMIZED)
    Place in ServerScriptService
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ==================== CREATE REMOTEEVENTS ====================

local danceComm = ReplicatedStorage:FindFirstChild("DanceComm")
if not danceComm then
	danceComm = Instance.new("Folder")
	danceComm.Name = "DanceComm"
	danceComm.Parent = ReplicatedStorage
end

local function getRemote(name, type, parent)
	local r = parent:FindFirstChild(name)
	if not r then
		r = Instance.new(type)
		r.Name = name
		r.Parent = parent
	end
	return r
end

local StartDance = getRemote("StartDance", "RemoteEvent", danceComm)
local StopDance  = getRemote("StopDance", "RemoteEvent", danceComm)
local SetSpeed   = getRemote("SetSpeed", "RemoteEvent", danceComm)

local remoteFolder = ReplicatedStorage:FindFirstChild("DanceRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "DanceRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local saveFavoriteEvent = getRemote("SaveFavorite", "RemoteEvent", remoteFolder)
local getFavoritesFunc  = getRemote("GetFavorites", "RemoteFunction", remoteFolder)

-- Clean up unused remnant remotes just in case
for _, v in ipairs({"SyncDance", "UnsyncDance", "StartCoordinateDance", "StopCoordinateDance", "UpdateDance"}) do
	local r1 = danceComm:FindFirstChild(v)
	local r2 = remoteFolder:FindFirstChild(v)
	if r1 then r1:Destroy() end
	if r2 then r2:Destroy() end
end

print("✅ [DANCE SERVER] Remotes ready")

-- ==================== STATE TRACKING ====================
local PlayerAnims = {}
local PlayerSpeeds = {}
local lastSpeedSet = {}

-- ==================== ANIMATION SYNC FUNCTIONS ====================

StartDance.OnServerEvent:Connect(function(player, data)
	if not data then return end
	PlayerAnims[player] = data
	PlayerSpeeds[player] = PlayerSpeeds[player] or 1
	data.Speed = PlayerSpeeds[player]

	-- Broadcast ke semua orang agar client lain bisa lihat player menari
	StartDance:FireAllClients(player, data)
	print(string.format("💃 [DANCE SERVER] %s started dancing", player.Name))
end)

StopDance.OnServerEvent:Connect(function(player)
	PlayerAnims[player] = nil
	StopDance:FireAllClients(player)
	print(string.format("🛑 [DANCE SERVER] %s stopped dancing", player.Name))
end)

SetSpeed.OnServerEvent:Connect(function(player, targetSpeed)
	local currentTime = tick()
	local lastTime = lastSpeedSet[player.UserId]

	-- Debounce
	if lastTime and (currentTime - lastTime) < 0.1 then return end
	lastSpeedSet[player.UserId] = currentTime

	if PlayerSpeeds[player] == targetSpeed then return end
	PlayerSpeeds[player] = math.max(0.0001, targetSpeed)

	if PlayerAnims[player] then
		SetSpeed:FireAllClients(player, targetSpeed)
	end
end)

-- ==================== FAVORITES SYSTEM ====================

saveFavoriteEvent.OnServerEvent:Connect(function(player, action, danceTitle)
	if not player or not player.Parent then return end
	local s, DataHandler = pcall(function() return require(script.Parent:WaitForChild("DataHandler", 2)) end)
	if not s or type(DataHandler) ~= "table" then return end

	if action == "add" then
		if not DataHandler:ArrayContains(player, "FavoriteDances", danceTitle) then
			DataHandler:ArrayAdd(player, "FavoriteDances", danceTitle)
			DataHandler:SavePlayer(player)
		end
	elseif action == "remove" then
		DataHandler:ArrayRemove(player, "FavoriteDances", danceTitle)
		DataHandler:SavePlayer(player)
	end
end)

getFavoritesFunc.OnServerInvoke = function(player)
	local s, DataHandler = pcall(function() return require(script.Parent:WaitForChild("DataHandler", 2)) end)
	if s and type(DataHandler) == "table" then
		local data = DataHandler:GetData(player)
		if data then return data.FavoriteDances or {} end
	end
	return {}
end

-- ==================== CLEANUP ====================
Players.PlayerRemoving:Connect(function(player)
	PlayerAnims[player] = nil
	PlayerSpeeds[player] = nil
	lastSpeedSet[player.UserId] = nil
end)

print("✅ [DANCE SERVER] Loaded")
