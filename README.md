# 🥊 Advanced Fighting System for Roblox

Sistem fighting minigame lengkap untuk map hangout Roblox dengan fitur:
- Sistem match 2 player dengan round-based combat
- Block, Dodge, Light Attack (combo), Heavy Attack
- Camera shift-lock style dengan lock on enemy
- Health & Stamina system
- Leaderboard untuk Match Wins dan Playtime
- Support PC & Mobile

---

## 📁 Struktur File

```
src/
├── client/
│   ├── FightingClient.client.lua   -- Input & combat handling
│   └── FightingUI.client.lua       -- UI system
├── server/
│   ├── FightingServer.server.lua   -- Main server logic
│   ├── DataHandler.lua             -- Player data persistence
│   └── LeaderboardServer.server.lua -- Leaderboard display
└── shared/
    ├── FightingConfig.lua          -- All configurations
    └── AnimationConfig.lua         -- Animation IDs
```

---

## 🎮 Setup Guide

### 1. Setup di Roblox Studio

#### A. Build dengan Rojo

```bash
# Install Rojo jika belum
aftman install

# Build dan sync ke Roblox Studio
rojo build -o game.rbxl

# Atau serve untuk live sync
rojo serve
```

#### B. Setup Arena (Fighting Ring)

Buat folder struktur berikut di **Workspace**:

```
Workspace/
└── FightingArena/
    └── FightingArena1/           -- Nama bebas: FightingArena1, FightingArena2, dst
        ├── RingArea              -- Part: Area ring (CanCollide = false untuk non-fighters)
        ├── StartPositionA        -- Part: Posisi awal player A
        ├── StartPositionB        -- Part: Posisi awal player B
        ├── FightPosition_A       -- Part: Posisi saat fight player A
        ├── FightPosition_B       -- Part: Posisi saat fight player B
        ├── OutPosition           -- Part: Posisi teleport setelah match
        └── InfoGui               -- Part dengan BillboardGui
            └── InfoGui           -- BillboardGui
                └── Frame
                    └── TextLabel -- Text untuk info (Waiting for players, Starting Fight, etc)
```

**Properties untuk setiap Part:**

| Part Name | Anchored | CanCollide | Size (contoh) | Notes |
|-----------|----------|------------|---------------|-------|
| RingArea | ✅ | ❌ | 30x1x30 | Boundary ring, transparan |
| StartPositionA | ✅ | ✅ | 5x0.5x5 | Jarak sekitar 2 stud dari edge |
| StartPositionB | ✅ | ✅ | 5x0.5x5 | Berlawanan dengan A |
| FightPosition_A | ✅ | ❌ | 3x0.5x3 | Di dalam ring, jarak ~10 stud dari center |
| FightPosition_B | ✅ | ❌ | 3x0.5x3 | Di dalam ring, opposite A |
| OutPosition | ✅ | ❌ | 5x0.5x5 | Di luar ring, tempat exit |
| InfoGui | ✅ | ❌ | 3x2x0.1 | Di atas ring, floating |

**BillboardGui Properties:**
```
InfoGui (Part)/
└── InfoGui (BillboardGui)
    - Size: {4, 0}, {1.5, 0}
    - StudsOffset: 0, 3, 0
    - AlwaysOnTop: true
    └── Frame
        - Size: {1, 0}, {1, 0}
        - BackgroundTransparency: 0.5
        - BackgroundColor3: 25, 25, 35
        └── TextLabel
            - Size: {1, 0}, {1, 0}
            - BackgroundTransparency: 1
            - Font: GothamBold
            - TextColor3: 255, 255, 255
            - TextSize: 18
            - Text: "Waiting for players..."
```

---

### 2. Setup Leaderboard

Buat struktur berikut di **Workspace**:

```
Workspace/
└── Leaderboard/
    ├── MatchWinsBoard     -- Part dengan SurfaceGui
    ├── RoundsWinsBoard    -- Part dengan SurfaceGui
    └── PlaytimeBoard      -- Part dengan SurfaceGui
```

**Contoh setup Part:**
```
MatchWinsBoard (Part)
- Size: 8, 6, 0.5
- Position: sesuai kebutuhan
- Anchored: true
└── LeaderboardGui (SurfaceGui)
    - Face: Front
    - SizingMode: PixelsPerStud
    - PixelsPerStud: 50
```

Script akan otomatis mengisi SurfaceGui dengan leaderboard entries.

---

## ⚙️ Configuration

Edit `src/shared/FightingConfig.lua` untuk mengubah:

### Match Settings
```lua
FightingConfig.Match = {
    RoundsPerMatch = 3,              -- Jumlah ronde (3, 5, dll)
    CountdownBeforeStart = 3,        -- Countdown sebelum match
    RoundTimeLimit = 120,            -- Batas waktu per ronde (detik)
    MatchCooldown = 30,              -- Cooldown setelah match
}
```

### Combat Settings
```lua
FightingConfig.Combat = {
    Block = {
        StaminaCost = 30,            -- Minimal stamina untuk block
        StaminaPerBlock = 30,        -- Stamina berkurang per block
    },
    Dodge = {
        StaminaCost = 10,
        Distance = 15,               -- Jarak dodge (studs)
    },
    LightAttack = {
        StaminaCost = 5,
        Damage = 15,                 -- Damage per hit
        MaxComboHits = 3,            -- Jumlah combo
    },
    HeavyAttack = {
        StaminaCost = 15,
        Damage = 30,                 -- Damage lebih besar
        Cooldown = 2.0,              -- Cooldown (detik)
    },
}
```

### Stamina Regen
```lua
FightingConfig.Stats = {
    MaxStamina = 100,
    StaminaRegenPerSecond = 1,       -- 1 per detik = 100 detik untuk full
}
```

---

## 🎬 Animation Setup

Edit `src/shared/AnimationConfig.lua` untuk mengubah animation IDs:

```lua
-- Block animation (looping)
AnimationConfig.Block = {
    BlockHold = "rbxassetid://121918883757512",
}

-- Attack combo (3 hit)
AnimationConfig.Attack = {
    Combo = {
        [1] = "rbxassetid://81442291322583",
        [2] = "rbxassetid://129043976512982",
        [3] = "rbxassetid://87048626485725",
    },
    -- Hit reactions (paired dengan combo)
    Hit = {
        [1] = "rbxassetid://133411118324472",
        [2] = "rbxassetid://133411118324472",
        [3] = "rbxassetid://133411118324472",
    },
}

-- Heavy attack
AnimationConfig.HeavyAttack = {
    Attack = "rbxassetid://121358890086382",
    Hit = "rbxassetid://133411118324472",
}

-- Dodge (set nil jika belum ada)
AnimationConfig.Dodge = {
    Universal = nil,  -- Akan di-skip tanpa error
}
```

---

## 🎮 Controls

### PC
| Action | Input |
|--------|-------|
| Light Attack | Left Click |
| Heavy Attack | Alt + Left Click |
| Block | Hold Right Click |
| Dodge | Direction (WASD) + Space |

### Mobile
Tombol virtual akan muncul saat match:
- **PUNCH** - Light attack
- **HEAVY** - Heavy attack
- **BLOCK** - Hold untuk block
- **DODGE** - Dodge ke belakang (atau arah joystick)

---

## 📊 Data yang Disimpan

Data player disimpan menggunakan DataStore:

```lua
-- Per player
{
    RoundsWin = 0,          -- Total rounds dimenangkan
    MatchWin = 0,           -- Total matches dimenangkan
    TotalPlaytime = 0,      -- Total playtime (detik)
    TotalHits = 0,          -- Total hits landed
    TotalBlocks = 0,        -- Total blocks successful
    TotalDodges = 0,        -- Total dodges performed
    TotalDamageDealt = 0,   -- Total damage dealt
    TotalDamageTaken = 0,   -- Total damage received
}
```

---

## 🔧 Troubleshooting

### Arena tidak terdeteksi
- Pastikan folder `FightingArena` ada di Workspace
- Pastikan semua required parts ada dengan nama yang tepat
- Check Output window untuk warning messages

### Animasi tidak jalan
- Pastikan animation ID valid dan dipublish
- Cek apakah animasi sudah di-owned oleh game/group
- Set animation ID ke `nil` untuk skip (tidak akan error)

### Leaderboard tidak muncul
- Pastikan folder `Leaderboard` ada di Workspace
- Pastikan Part dengan nama yang benar ada
- Script akan otomatis membuat SurfaceGui jika tidak ada

### Start Position tidak detect player
- Pastikan player berdiri tepat di atas Part
- Check `StartPositionTouchRange` di config (default: 5 studs)
- Pastikan player tidak dalam cooldown

---

## 📝 Notes

- Match hanya bisa dimulai jika kedua player ada di start positions
- Player dalam cooldown tidak bisa join match baru
- Jika player disconnect saat match, opponent menang otomatis
- Data auto-save setiap 5 menit dan saat player leave

---

## 🚀 Quick Start Checklist

- [ ] Build project dengan Rojo
- [ ] Buat folder `FightingArena` di Workspace
- [ ] Buat minimal 1 arena dengan semua required parts
- [ ] Buat folder `Leaderboard` (optional)
- [ ] Test dengan 2 player (atau 2 Roblox instances)
- [ ] Customize values di FightingConfig.lua
- [ ] Update animation IDs di AnimationConfig.lua

---

Made with ❤️ for Roblox developers