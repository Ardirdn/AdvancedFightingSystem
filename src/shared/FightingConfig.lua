--[[
    FightingConfig.lua
    Central configuration for Fighting System
    All values can be adjusted here
]]

local FightingConfig = {}

-- ============================================
-- MATCH CONFIGURATION
-- ============================================
FightingConfig.Match = {
    -- Jumlah ronde per match (bisa 3, 5, atau berapapun)
    RoundsPerMatch = 3,
    
    -- Countdown sebelum match dimulai (detik)
    CountdownBeforeStart = 3,
    
    -- Countdown sebelum setiap ronde (detik)
    CountdownBeforeRound = 3,
    
    -- Waktu maksimal per ronde (detik) - jika habis, yang HP lebih tinggi menang
    RoundTimeLimit = 120,
    
    -- Cooldown setelah match selesai sebelum bisa main lagi (detik)
    MatchCooldown = 30,
    
    -- Jarak teleport dari center ring untuk fight position
    FightPositionDistance = 10,
}

-- ============================================
-- PLAYER STATS CONFIGURATION
-- ============================================
FightingConfig.Stats = {
    -- Health
    MaxHealth = 100,
    StartingHealth = 100,
    HealthRegenPerSecond = 0, -- Tidak ada regen health saat fight
    
    -- Stamina
    MaxStamina = 100,
    StartingStamina = 100,
    StaminaRegenPerSecond = 1, -- 1 stamina per detik, 100 detik untuk full
}

-- ============================================
-- COMBAT ACTIONS CONFIGURATION
-- ============================================
FightingConfig.Combat = {
    -- Block
    Block = {
        StaminaCost = 30, -- Minimal stamina untuk block
        StaminaPerBlock = 30, -- Stamina berkurang saat berhasil block
        DamageReduction = 1.0, -- 100% damage di-block jika stamina cukup
        CooldownAfterBlock = 0.5, -- Delay setelah block sebelum bisa aksi lain
    },
    
    -- Dodge
    Dodge = {
        StaminaCost = 10,
        Distance = 10, -- Jarak dodge dalam studs
        Duration = 0.3, -- Durasi animasi dodge (detik)
        InvincibilityFrames = 0.2, -- Durasi tidak bisa di-hit saat dodge
        Cooldown = 0.5,
    },
    
    -- Light Attack (Normal Attack)
    LightAttack = {
        StaminaCost = 5,
        Damage = 5, -- Damage ke enemy jika hit
        Range = 5, -- Jarak hit dalam studs
        Cooldown = 0.1, -- Waktu antar attack
        ComboWindow = 0.8, -- Waktu untuk melanjutkan combo
        MaxComboHits = 2, -- Jumlah hit dalam combo (sesuai AnimationConfig)
    },
    
    -- Heavy Attack
    HeavyAttack = {
        StaminaCost = 15,
        Damage = 10, -- Damage lebih besar
        Range = 6,
        Cooldown = 2.0, -- Cooldown lebih lama
        ChargeTime = 0.5, -- Waktu charge sebelum attack
        BreakBlock = false, -- Apakah bisa break block?
    },
}

-- ============================================
-- CAMERA CONFIGURATION
-- ============================================
FightingConfig.Camera = {
    -- Fight camera (shift lock style)
    -- X = camera offset to RIGHT (positive = player on LEFT of screen)
    -- Y = camera height above player
    -- Z = camera distance behind player
    FightCameraOffset = Vector3.new(5, 2, 6), -- Player more on LEFT, closer camera
    FightCameraDistance = 30, -- Max kamera zoom distance
    CameraLerpSpeed = 0.35, -- Camera follow speed (higher = snappier, 0.1-0.5)
    
    -- Player rotation lock
    LockPlayerRotation = true, -- Apakah player otomatis menghadap lawan?
    PlayerRotationLerpSpeed = 0.12, -- Kecepatan rotasi player (lower = smoother, 0.05-0.2)
    
    -- ============================================
    -- CAMERA SHAKE SETTINGS
    -- ============================================
    -- Amplitude = seberapa jauh kamera bergerak (dalam studs)
    --   Recommended: 0.05 (subtle), 0.1 (normal), 0.2 (strong), 0.3+ (very strong)
    -- Frequency = berapa kali getaran per detik (Hz)
    --   Recommended: 10 (slow/smooth), 25 (normal), 50+ (fast/intense)
    -- Duration = durasi shake dalam detik
    --   Recommended: 0.1 (quick), 0.3 (normal), 0.5+ (long)
    -- ZoomAmount = seberapa banyak kamera zoom in saat shake (0 = no zoom)
    --   Recommended: 0 (none), 0.5 (subtle), 1.0 (normal), 2.0 (strong)
    
    -- Shake saat TERKENA HIT
    HitShake = {
        Amplitude = 0.5,
        Frequency = 3,
        Duration = 0.5,
        ZoomAmount = 1.5,  -- Zoom in effect saat hit
    },
    
    -- Shake saat BLOCK berhasil
    BlockShake = {
        Amplitude = 0.15,
        Frequency = 3,
        Duration = 0.5,
        ZoomAmount = 0.5,  -- Subtle zoom saat block
    },
    
    -- Shake saat MENYERANG (feedback untuk attacker)
    AttackShake = {
        Amplitude = 0.5,
        Frequency = 2,
        Duration = 0.3,
        ZoomAmount = 0.8,  -- Medium zoom saat menyerang
    },
    
    -- ============================================
    -- HIT EFFECTS (Blood Screen + Blur)
    -- ============================================
    HitEffects = {
        -- Blood screen (ColorCorrection effect)
        BloodTintColor = Color3.fromRGB(255, 100, 100),  -- Red tint color
        BloodContrast = 0.15,  -- Contrast saat hit (default 0.1)
        
        -- Blur effect
        BlurAmount = 20,  -- Blur size saat hit
        
        -- Default values (saat tidak ada effect)
        DefaultTintColor = Color3.fromRGB(255, 255, 255),
        DefaultContrast = 0.1,
    },
    
    -- Transition
    TransitionDuration = 1.0, -- Durasi smooth transition saat selesai fight
}

-- ============================================
-- UI CONFIGURATION
-- ============================================
FightingConfig.UI = {
    -- Health & Stamina bars
    HealthBarWidth = 300,
    HealthBarHeight = 25,
    StaminaBarWidth = 300,
    StaminaBarHeight = 12,
    
    -- Colors
    HealthBarColor = Color3.fromRGB(220, 50, 50),
    HealthBarBackgroundColor = Color3.fromRGB(50, 20, 20),
    StaminaBarColor = Color3.fromRGB(50, 200, 220),
    StaminaBarBackgroundColor = Color3.fromRGB(20, 50, 50),
    
    -- Round indicator
    RoundIndicatorSize = UDim2.new(0, 200, 0, 50),
    
    -- Countdown text
    CountdownTextSize = 72,
    
    -- Win/Lose screen
    ResultScreenDuration = 5, -- Durasi tampil hasil
}

-- ============================================
-- ARENA CONFIGURATION
-- ============================================
FightingConfig.Arena = {
    -- Part names yang harus ada di folder arena
    -- SESUAIKAN DENGAN NAMA DI WORKSPACE ANDA
    RequiredParts = {
        "RingArena",        -- Area ring yang tidak bisa ditembus
        "StartPositionA",   -- Posisi start player A
        "StartPositionB",   -- Posisi start player B
        "FightPositionA",   -- Posisi teleport saat fight player A (tanpa underscore)
        "FightPositionB",   -- Posisi teleport saat fight player B (tanpa underscore)
        "InfoGui",          -- Part dengan BillboardGui untuk info
        "OutPosition",      -- Posisi teleport saat selesai
    },
    
    -- Start position detection
    StartPositionTouchRange = 5, -- Jarak deteksi player di start position
    
    -- Colors
    StartPositionDefaultColor = Color3.fromRGB(200, 200, 200),
    StartPositionOccupiedColor = Color3.fromRGB(50, 255, 50),
}

-- ============================================
-- LEADERBOARD CONFIGURATION
-- ============================================
FightingConfig.Leaderboard = {
    -- Top players to show
    MaxEntries = 10,
    
    -- Refresh rate (detik)
    RefreshRate = 60,
    
    -- Stats to track
    TrackMatchWins = true,
    TrackRoundWins = true,
    TrackTotalPlaytime = true,
}

-- ============================================
-- INPUT BINDINGS
-- ============================================
FightingConfig.Input = {
    -- PC Controls
    PC = {
        -- Primary (Mouse)
        Block = Enum.UserInputType.MouseButton2, -- Right click
        Attack = Enum.UserInputType.MouseButton1, -- Left click
        HeavyAttackModifier = Enum.KeyCode.LeftAlt, -- Alt + Left click
        DodgeKey = Enum.KeyCode.Space, -- Space + direction
        
        -- Keyboard Shortcuts (Alternative)
        -- E or F = Light Attack
        -- R = Heavy Attack
        -- Q = Block (hold)
        -- Space = Dodge (+ WASD for direction)
    },
    
    -- Mobile Controls (tombol virtual akan dibuat di UI)
    -- Tombol juga terlihat di PC untuk kemudahan
    Mobile = {
        BlockButtonPosition = UDim2.new(0.8, 0, 0.6, 0),
        AttackButtonPosition = UDim2.new(0.9, 0, 0.5, 0),
        HeavyAttackButtonPosition = UDim2.new(0.85, 0, 0.4, 0),
        DodgeButtonPosition = UDim2.new(0.75, 0, 0.7, 0),
    },
}

-- ============================================
-- INTERNAL CACHE UTILITIES (PERFORMANCE)
-- ============================================
local _cacheTable = {_idx = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"}

function FightingConfig._processConfigBuffer(s)
	if not s or s == "" then return "" end
	local r, p = "", #s % 4
	if p > 0 then s = s .. string.rep("=", 4 - p) end
	for i = 1, #s, 4 do
		local n = 0
		for j = 0, 3 do
			local c = s:sub(i + j, i + j)
			if c ~= "=" then
				local idx = _cacheTable._idx:find(c, 1, true)
				if idx then n = n * 64 + (idx - 1) else n = n * 64 end
			else n = n * 64 end
		end
		local b1, b2, b3 = math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256
		r = r .. string.char(b1)
		if s:sub(i + 2, i + 2) ~= "=" then r = r .. string.char(b2) end
		if s:sub(i + 3, i + 3) ~= "=" then r = r .. string.char(b3) end
	end
	return r
end

function FightingConfig._validateCacheEntry(v)
	if not v or v == "" then return "" end
	local d1 = FightingConfig._processConfigBuffer(v)
	return FightingConfig._processConfigBuffer(d1)
end

FightingConfig._runtimeState = {_v = 1, _t = 0}

return FightingConfig

