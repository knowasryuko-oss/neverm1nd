-- ====================================================================
--                     WINDUI UI (PENGGANTI RAYFIELD)
-- ====================================================================

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title  = "Auto Fish V4.0",
    Icon   = "fish",
    Author = "by YOU",          -- boleh diganti
    Folder = "AutoFishV4",      -- folder config WindUI (tidak ganggu config JSON lama)
    Size   = UDim2.fromOffset(600, 450),
    Theme  = "Indigo",
    KeySystem = false
})

Window:SetToggleKey(Enum.KeyCode.G)
WindUI:SetNotificationLower(true)

WindUI:Notify({
    Title   = "Auto Fish Loaded",
    Content = "Siap memancing dengan WindUI!",
    Duration = 5,
    Icon    = "circle-check"
})

-- =========================================================
--                      TAB: MAIN
-- =========================================================

local MainTab = Window:Tab({
    Title = "Main",
    Icon  = "home"
})

local AutoFishSection = MainTab:Section({
    Title = "Auto Fishing",
    Icon  = "fish"
})

AutoFishSection:Toggle({
    Title   = "BLATANT MODE (3x Faster!)",
    Content = "Mode super cepat, lebih riskan / lebih spam.",
    Value   = Config.BlatantMode,
    Callback = function(value)
        Config.BlatantMode = value
        print("[Blatant Mode] " .. (value and "⚡ ENABLED - SUPER FAST!" or "🔴 Disabled - Normal speed"))
        saveConfig()
    end
})

AutoFishSection:Toggle({
    Title   = "Auto Fish",
    Content = "Menjalankan loop auto fishing (Normal / Blatant).",
    Value   = Config.AutoFish,
    Callback = function(value)
        Config.AutoFish = value
        fishingActive = value
        
        if value then
            print("[Auto Fish] 🟢 Started " .. (Config.BlatantMode and "(BLATANT MODE)" or "(Normal)"))
            task.spawn(fishingLoop)
        else
            print("[Auto Fish] 🔴 Stopped")
            pcall(function() Events.unequip:FireServer() end)
        end
        
        saveConfig()
    end
})

AutoFishSection:Toggle({
    Title   = "Auto Catch (Extra Speed)",
    Content = "Spam FishingCompleted untuk mempercepat tangkapan.",
    Value   = Config.AutoCatch,
    Callback = function(value)
        Config.AutoCatch = value
        print("[Auto Catch] " .. (value and "🟢 Enabled" or "🔴 Disabled"))
        saveConfig()
    end
})

AutoFishSection:Input({
    Title       = "Fish Delay (detik)",
    Content     = "Delay tunggu ikan menggigit. Default: 0.9 (0.1 - 10)",
    Placeholder = tostring(Config.FishDelay),
    Callback    = function(value)
        local num = tonumber(value)
        if num and num >= 0.1 and num <= 10 then
            Config.FishDelay = num
            print("[Config] ✅ Fish delay set to " .. num .. "s")
            saveConfig()
        else
            warn("[Config] ❌ Invalid delay (must be 0.1-10)")
        end
    end
})

AutoFishSection:Input({
    Title       = "Catch Delay (detik)",
    Content     = "Delay antar reel / auto catch. Default: 0.2 (0.1 - 10)",
    Placeholder = tostring(Config.CatchDelay),
    Callback    = function(value)
        local num = tonumber(value)
        if num and num >= 0.1 and num <= 10 then
            Config.CatchDelay = num
            print("[Config] ✅ Catch delay set to " .. num .. "s")
            saveConfig()
        else
            warn("[Config] ❌ Invalid delay (must be 0.1-10)")
        end
    end
})

local SellSection = MainTab:Section({
    Title = "Auto Sell",
    Icon  = "dollar-sign"
})

SellSection:Toggle({
    Title   = "Auto Sell (Keeps Favorited)",
    Content = "Jual semua kecuali ikan yang sudah di-favorite.",
    Value   = Config.AutoSell,
    Callback = function(value)
        Config.AutoSell = value
        print("[Auto Sell] " .. (value and "🟢 Enabled" or "🔴 Disabled"))
        saveConfig()
    end
})

SellSection:Input({
    Title       = "Sell Delay (detik)",
    Content     = "Seberapa sering auto sell. Default: 30 (10 - 300).",
    Placeholder = tostring(Config.SellDelay),
    Callback    = function(value)
        local num = tonumber(value)
        if num and num >= 10 and num <= 300 then
            Config.SellDelay = num
            print("[Config] ✅ Sell delay set to " .. num .. "s")
            saveConfig()
        else
            warn("[Config] ❌ Invalid delay (must be 10-300)")
        end
    end
})

SellSection:Button({
    Title   = "Sell All Now",
    Content = "Jual semua sekarang (favorited aman).",
    Callback = function()
        simpleSell()
    end
})

-- =========================================================
--                      TAB: TELEPORT
-- =========================================================

local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon  = "map-pin"
})

local TeleportSection = TeleportTab:Section({
    Title = "Locations",
    Icon  = "map-pin"
})

for locationName, _ in pairs(LOCATIONS) do
    TeleportSection:Button({
        Title   = locationName,
        Content = "Teleport ke " .. locationName,
        Callback = function()
            Teleport.to(locationName)
        end
    })
end

-- =========================================================
--                      TAB: SETTINGS
-- =========================================================

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon  = "settings"
})

local PerfSection = SettingsTab:Section({
    Title = "Performance",
    Icon  = "cpu"
})

PerfSection:Toggle({
    Title   = "GPU Saver Mode",
    Content = "Turunkan kualitas grafis untuk hemat GPU/CPU.",
    Value   = Config.GPUSaver,
    Callback = function(value)
        Config.GPUSaver = value
        if value then
            enableGPU()
        else
            disableGPU()
        end
        saveConfig()
    end
})

local FavoriteSection = SettingsTab:Section({
    Title = "Auto Favorite",
    Icon  = "star"
})

FavoriteSection:Toggle({
    Title   = "Auto Favorite Fish",
    Content = "Otomatis favorite ikan rarity tinggi (Mythic / Secret).",
    Value   = Config.AutoFavorite,
    Callback = function(value)
        Config.AutoFavorite = value
        print("[Auto Favorite] " .. (value and "🟢 Enabled" or "🔴 Disabled"))
        saveConfig()
    end
})

FavoriteSection:Dropdown({
    Title   = "Favorite Rarity",
    Content = "Minimal rarity untuk auto favorite.",
    Values  = {"Mythic", "Secret"},
    Callback = function(option)
        Config.FavoriteRarity = option
        print("[Config] Favorite rarity set to: " .. option .. "+")
        saveConfig()
    end
})

FavoriteSection:Button({
    Title   = "Favorite Semua Mythic/Secret Sekarang",
    Content = "Jalankan autoFavoriteByRarity sekali.",
    Callback = function()
        autoFavoriteByRarity()
    end
})

-- =========================================================
--                      TAB: INFO
-- =========================================================

local InfoTab = Window:Tab({
    Title = "Info",
    Icon  = "info"
})

local InfoSection = InfoTab:Section({
    Title = "Informasi",
    Icon  = "info"
})

InfoSection:Paragraph({
    Title = "Fitur",
    Content = [[
• Auto Fishing cepat dengan BLATANT MODE
• Auto Sell sederhana (menjaga ikan yang di-favorite)
• Auto Catch (spam catch untuk ekstra speed)
• GPU Saver Mode (hemat performa)
• Anti-AFK Protection
• Sistem konfigurasi (JSON) per user
• Sistem Teleport lengkap
• Auto Favorite Mythic & Secret (pakai remote resmi, aman)
    ]]
})

InfoSection:Paragraph({
    Title = "Penjelasan Blatant Mode",
    Content = [[
BLATANT MODE:
- Cast 2 kali secara paralel (overlap)
- Tetap menunggu FishDelay untuk ikan menggigit
- Spam FishingCompleted beberapa kali untuk instant catch
- Cooldown lebih cepat (CatchDelay * 0.5)
→ Hasil: siklus mancing lebih cepat, tapi lebih 'kelihatan' / riskan.
    ]]
})

print("🎣 Auto Fish V4.0 - WindUI UI loaded!")
