--[[
    DebugServer.server.lua
    Server-side handler for DEBUG_MODE dummy NPC system.

    Provides two RemoteEvents in FightingRemotes:
      • SpawnDebugDummy  – spawns a clone of the player's character 4 studs ahead
      • HitDebugDummy    – registers a hit on the dummy (visual HP counter, no real death)

    The dummy is:
      - Anchored (stays in place)
      - Immortal (HP resets at 0, Humanoid.MaxHealth = math.huge)
      - Cloned from the player's own character so it looks identical
      - Cleaned up when the player leaves
]]

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local ModularConfig    = ReplicatedStorage:WaitForChild("Modules")
local FightingConfig   = require(ModularConfig:WaitForChild("FightingConfig"))

-- ── Wait for FightingRemotes ──────────────────────────────────────────────────
local FightingRemotes = ReplicatedStorage:WaitForChild("FightingRemotes", 15)
if not FightingRemotes then
    warn("❌ [DebugServer] FightingRemotes not found – debug dummy system disabled")
    return
end

-- ── Create remote events ──────────────────────────────────────────────────────
local SpawnDebugDummy = Instance.new("RemoteEvent")
SpawnDebugDummy.Name   = "SpawnDebugDummy"
SpawnDebugDummy.Parent = FightingRemotes

local HitDebugDummy   = Instance.new("RemoteEvent")
HitDebugDummy.Name    = "HitDebugDummy"
HitDebugDummy.Parent  = FightingRemotes

-- ── Configuration ─────────────────────────────────────────────────────────────
local DUMMY_DISPLAY_HP = 100   -- cosmetic HP shown in billboard (resets on 0)
local LIGHT_HIT_DMG    = 10
local HEAVY_HIT_DMG    = 20
local SPAWN_DISTANCE   = 4     -- studs in front of player

-- ── Per-player state ──────────────────────────────────────────────────────────
local dummyHP = {}             -- [player.Name] = current cosmetic HP

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function buildHPGui(hrp)
    local billboard = Instance.new("BillboardGui")
    billboard.Name            = "DummyHPGui"
    billboard.Size            = UDim2.new(5, 0, 1.2, 0)
    billboard.StudsOffset     = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop     = false
    billboard.ResetOnSpawn    = false
    billboard.Parent          = hrp

    -- Title
    local title = Instance.new("TextLabel")
    title.Name               = "Title"
    title.Size               = UDim2.new(1, 0, 0.45, 0)
    title.BackgroundTransparency = 1
    title.Text               = "🎯 DUMMY"
    title.TextColor3         = Color3.fromRGB(255, 200, 50)
    title.Font               = Enum.Font.GothamBold
    title.TextScaled         = true
    title.Parent             = billboard

    -- HP bar background
    local barBG = Instance.new("Frame")
    barBG.Name              = "BarBG"
    barBG.Size              = UDim2.new(1, 0, 0.3, 0)
    barBG.Position          = UDim2.new(0, 0, 0.5, 0)
    barBG.BackgroundColor3  = Color3.fromRGB(40, 10, 10)
    barBG.BorderSizePixel   = 0
    barBG.Parent            = billboard

    local barFill = Instance.new("Frame")
    barFill.Name            = "BarFill"
    barFill.Size            = UDim2.new(1, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    barFill.BorderSizePixel = 0
    barFill.Parent          = barBG

    -- HP text
    local hpLabel = Instance.new("TextLabel")
    hpLabel.Name            = "HPLabel"
    hpLabel.Size            = UDim2.new(1, 0, 0.3, 0)
    hpLabel.Position        = UDim2.new(0, 0, 0.82, 0)
    hpLabel.BackgroundTransparency = 1
    hpLabel.Text            = DUMMY_DISPLAY_HP .. " / " .. DUMMY_DISPLAY_HP
    hpLabel.TextColor3      = Color3.fromRGB(255, 255, 255)
    hpLabel.Font            = Enum.Font.Gotham
    hpLabel.TextScaled      = true
    hpLabel.Parent          = billboard

    return billboard
end

local function updateHP(dummy, playerName, newHP)
    local hrp = dummy:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local gui = hrp:FindFirstChild("DummyHPGui")
    if not gui then return end

    local label   = gui:FindFirstChild("HPLabel")
    local barFill = gui:FindFirstChild("BarBG") and gui.BarBG:FindFirstChild("BarFill")

    local pct = math.clamp(newHP / DUMMY_DISPLAY_HP, 0, 1)

    if label then
        label.Text = newHP .. " / " .. DUMMY_DISPLAY_HP
    end
    if barFill then
        TweenService:Create(barFill, TweenInfo.new(0.15), {
            Size = UDim2.new(pct, 0, 1, 0),
            BackgroundColor3 = pct > 0.5
                and Color3.fromRGB(200, 50, 50)
                or  Color3.fromRGB(255, 80, 20)
        }):Play()
    end
end

-- ── SpawnDebugDummy handler ───────────────────────────────────────────────────
SpawnDebugDummy.OnServerEvent:Connect(function(player)
    -- Remove old dummy
    local oldDummy = workspace:FindFirstChild("DebugDummy_" .. player.Name)
    if oldDummy then oldDummy:Destroy() end

    local char     = player.Character
    if not char then return end
    local playerHRP = char:FindFirstChild("HumanoidRootPart")
    if not playerHRP then return end

    -- Clone player's own character (same appearance & rig)
    -- IMPORTANT: Character.Archivable must be true, otherwise Clone() returns nil
    local wasArchivable = char.Archivable
    char.Archivable = true
    local dummy = char:Clone()
    char.Archivable = wasArchivable  -- restore original value

    if not dummy then
        warn("❌ [DebugServer] char:Clone() returned nil for", player.Name,
             "— cannot spawn dummy")
        return
    end
    dummy.Name = "DebugDummy_" .. player.Name


    -- Remove SERVER scripts and Tools from clone, but KEEP LocalScripts.
    -- The 'Animate' LocalScript drives the idle/walk animations — we want it!
    -- LocalScripts do NOT run inside workspace (only in PlayerScripts/etc),
    -- so keeping them is harmless on the server side but enables animation on clients.
    local toDestroy = {}
    for _, desc in ipairs(dummy:GetDescendants()) do
        if desc:IsA("Script") or desc:IsA("Tool") then   -- NOT LocalScript
            toDestroy[#toDestroy + 1] = desc
        end
    end
    for _, inst in ipairs(toDestroy) do
        if inst and inst.Parent then inst:Destroy() end
    end

    -- Position: N studs in front of player (along their look vector)
    local dummyHRP = dummy:FindFirstChild("HumanoidRootPart")
    if dummyHRP then
        local spawnCF = playerHRP.CFrame * CFrame.new(0, 0, -SPAWN_DISTANCE)
        -- Face TOWARD the player (flip 180°)
        dummyHRP.CFrame   = spawnCF * CFrame.Angles(0, math.pi, 0)
        dummyHRP.Anchored = true   -- freeze in place
    end

    -- Make immortal
    local humanoid = dummy:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.MaxHealth  = math.huge
        humanoid.Health     = math.huge
        humanoid.WalkSpeed  = 0
        humanoid.JumpPower  = 0
        humanoid.JumpHeight = 0
    end

    -- Add HP billboard
    dummyHP[player.Name] = DUMMY_DISPLAY_HP
    if dummyHRP then
        buildHPGui(dummyHRP)
    end
    
    -- Assign CollisionGroup so it never bumps into players globally
    for _, part in pairs(dummy:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CollisionGroup = "Fighters"
        end
    end

    dummy.Parent = workspace

    -- ── Play idle animation (server-side, replicates to all clients) ──────────
    -- Wait 1 frame so Humanoid/Animator finish initializing
    task.defer(function()
        if not dummy or not dummy.Parent then return end
        local hum = dummy:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        local anim = dummy:FindFirstChildOfClass("Animator")
                  or hum:FindFirstChildOfClass("Animator")
        if not anim then
            anim = Instance.new("Animator")
            anim.Parent = hum
        end

        -- Default Roblox R15 idle (works for any R15 rig)
        local idleInstance = Instance.new("Animation")
        idleInstance.AnimationId = "rbxassetid://507766388"  -- Roblox default idle

        local ok, track = pcall(function()
            return anim:LoadAnimation(idleInstance)
        end)
        if ok and track then
            track.Looped   = true
            track.Priority = Enum.AnimationPriority.Idle
            track:Play()
            print("🎯 [DebugServer] Idle animation started on dummy")
        else
            warn("⚠️ [DebugServer] Could not load idle animation:", track)
        end
    end)

    print("🎯 [DebugServer] Dummy spawned for", player.Name,
          "at", tostring(dummyHRP and dummyHRP.Position))
end)


-- ── HitDebugDummy handler ─────────────────────────────────────────────────────
-- Hit animation counter per player (alternates Hit1 / Hit2)
local hitCounter = {}

local HIT_ANIMS = {
    "rbxassetid://80025712607456",  -- Hit 1
    "rbxassetid://84510747822815",  -- Hit 2
}

HitDebugDummy.OnServerEvent:Connect(function(player, attackType, comboStep)
    local dummy = workspace:FindFirstChild("DebugDummy_" .. player.Name)
    if not dummy then return end

    local dummyHRP = dummy:FindFirstChild("HumanoidRootPart")

    -- ── HP damage ─────────────────────────────────────────────────────────────
    local dmg = (attackType == "Heavy") and HEAVY_HIT_DMG or LIGHT_HIT_DMG
    local hp  = math.max(0, (dummyHP[player.Name] or DUMMY_DISPLAY_HP) - dmg)
    dummyHP[player.Name] = hp
    updateHP(dummy, player.Name, hp)

    -- ── Full-body red flash via Highlight ────────────────────────────────────
    -- Highlight works on ALL descendants (hair, accessories, mesh, everything)
    task.spawn(function()
        local hl = Instance.new("Highlight")
        hl.FillColor          = Color3.fromRGB(255, 40, 40)
        hl.FillTransparency   = 0.65 -- Intensitas merah diturunkan 50%+ 
        hl.OutlineColor       = Color3.fromRGB(255, 0, 0)
        hl.OutlineTransparency = 0.7
        hl.DepthMode          = Enum.HighlightDepthMode.Occluded  -- respects depth, no X-ray
        hl.Parent             = dummy

        task.wait(0.15)
        -- Fade out
        TweenService:Create(hl, TweenInfo.new(0.1), {
            FillTransparency    = 1,
            OutlineTransparency = 1,
        }):Play()
        task.wait(0.12)
        if hl and hl.Parent then hl:Destroy() end
    end)

    -- ── Pushback (CFrame tween on anchored HRP) ───────────────────────────────
    if dummyHRP then
        task.spawn(function()
            local originalCF = dummyHRP.CFrame
            
            -- Push direction = arah dari attacker
            local playerHRP  = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local pushDir    = playerHRP and playerHRP.CFrame.LookVector or -dummyHRP.CFrame.LookVector
            pushDir          = Vector3.new(pushDir.X, 0, pushDir.Z).Unit
            
            local isFar = comboStep and comboStep % 4 == 0
            local cfg = isFar and FightingConfig.Combat.PushMechanics.DefenderFar or FightingConfig.Combat.PushMechanics.DefenderNormal
            
            local maxDist    = cfg.Distance
            local duration   = cfg.Duration
            
            if isFar then
                print("🚀 [DebugServer] Hit ke-4 terdeteksi! Pushback Dummy 2x lebih jauh.")
            end
            
            if cfg.Delay > 0 then task.wait(cfg.Delay) end

            -- Raycast to detect walls and clamp distance (dummy is Anchored so no physics)
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {dummy}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            local hit = workspace:Raycast(dummyHRP.Position, pushDir * maxDist, rayParams)
            -- Leave ~1 stud gap from wall (approx character radius)
            local safeDist = hit and math.max(0, hit.Distance - 1.0) or maxDist
            
            -- Auto-rotate dummy to face the attacker
            local facePos = playerHRP and playerHRP.Position or (originalCF.Position - pushDir)
            local targetPos = originalCF.Position + (pushDir * safeDist)
            local pushedCF = CFrame.lookAt(targetPos, Vector3.new(facePos.X, targetPos.Y, facePos.Z))

            -- Enemy speed 1.5x lebih cepat dari player agar tidak bertubrukan
            TweenService:Create(dummyHRP, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                CFrame = pushedCF
            }):Play()
            -- No return: dummy stays pushed (terdorong, bukan bounce)
        end)
    end

    -- ── Hit reaction animation (alternates Hit1 / Hit2) ───────────────────────
    task.spawn(function()
        local hum = dummy:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then return end

        -- Alternate between the two hit animations
        hitCounter[player.Name] = ((hitCounter[player.Name] or 0) % #HIT_ANIMS) + 1
        local animId = HIT_ANIMS[hitCounter[player.Name]]

        local hitAnim = Instance.new("Animation")
        hitAnim.AnimationId = animId

        local ok, track = pcall(function()
            return animator:LoadAnimation(hitAnim)
        end)
        if ok and track then
            track.Priority = Enum.AnimationPriority.Action4
            track:Play()
            task.delay(0.7, function()
                if track and track.IsPlaying then track:Stop(0.2) end
            end)
        end
    end)

    -- ── Reset HP if it hit 0 (immortal) ──────────────────────────────────────
    if hp <= 0 then
        task.wait(0.3)
        dummyHP[player.Name] = DUMMY_DISPLAY_HP
        updateHP(dummy, player.Name, DUMMY_DISPLAY_HP)
        print("🎯 [DebugServer] Dummy HP reset for", player.Name)
    end

    print(string.format("🎯 [DebugServer] %s → dummy (%s) | pushback %.1f stud | HP: %d → %d",
        player.Name, attackType,
        attackType == "Heavy" and 2.5 or 1,
        hp + dmg, math.max(0, hp)))
end)

-- ── Cleanup on player leave ───────────────────────────────────────────────────
Players.PlayerRemoving:Connect(function(player)
    local dummy = workspace:FindFirstChild("DebugDummy_" .. player.Name)
    if dummy then dummy:Destroy() end
    dummyHP[player.Name] = nil
end)

print("🎯 [DebugServer] Debug Dummy system loaded (SpawnDebugDummy + HitDebugDummy remotes ready)")
