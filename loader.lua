-- ====================================================================
--  AUTO FISH V4.0 - WINDUI + AUTO FISH V2 (SUPER INSTANT 1 TOGGLE)
-- ====================================================================

-- ====== CRITICAL DEPENDENCY VALIDATION ======
local ok, err = pcall(function()
    local s = {
        game = game,
        workspace = workspace,
        Players = game:GetService("Players"),
        RunService = game:GetService("RunService"),
        ReplicatedStorage = game:GetService("ReplicatedStorage"),
        HttpService = game:GetService("HttpService")
    }
    for name, svc in pairs(s) do
        if not svc then error("Missing service: "..name) end
    end
    if not game:GetService("Players").LocalPlayer then
        error("LocalPlayer not available")
    end
end)

if not ok then
    error("❌ [Auto Fish] Critical dependency check failed: " .. tostring(err))
    return
end

-- ====================================================================
--                        CORE SERVICES
-- ====================================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local VirtualUser       = game:GetService("VirtualUser")
local LocalPlayer       = Players.LocalPlayer

local net = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

-- ====================================================================
--                    CONFIGURATION
-- ====================================================================
local CONFIG_FOLDER = "OptimizedAutoFish"
local CONFIG_FILE   = CONFIG_FOLDER .. "/config_" .. LocalPlayer.UserId .. ".json"

local DefaultConfig = {
    -- AUTO FISH V2
    AutoFish    = false,  -- dipakai juga sebagai SuperInstant toggle
    AutoCatch   = false,  -- akan otomatis ikut AutoFish
    PerfectCast = true,
    FishDelay   = 1.5,    -- Slow Reel Threshold (detik) - bebas kamu atur
    CatchDelay  = 1.0,    -- Super Instant Delay (detik) - bebas kamu atur

    -- FITUR LAIN
    AutoSell         = false,
    GPUSaver         = false,
    SellDelay        = 30,
    TeleportLocation = "Sisyphus Statue",
    AutoFavorite     = true,
    FavoriteRarity   = "Mythic"
}

local Config = {}
for k,v in pairs(DefaultConfig) do Config[k] = v end

-- ====================================================================
--                    TELEPORT LOCATIONS
-- ====================================================================
local LOCATIONS = {
    ["Spawn"]            = CFrame.new(45.2788, 252.5629, 2987.1091),
    ["Sisyphus Statue"]  = CFrame.new(-3728.2161, -135.0744, -1012.1274),
    ["Coral Reefs"]      = CFrame.new(-3114.7820, 1.3207, 2237.5230),
    ["Esoteric Depths"]  = CFrame.new(3248.3711, -1301.5303, 1403.8273),
    ["Crater Island"]    = CFrame.new(1016.4907, 20.0919, 5069.2730),
    ["Lost Isle"]        = CFrame.new(-3618.1570, 240.8367, -1317.4580),
    ["Weather Machine"]  = CFrame.new(-1488.5120, 83.1733, 1876.3030),
    ["Tropical Grove"]   = CFrame.new(-2095.3411, 197.2000, 3718.0801),
    ["Mount Hallow"]     = CFrame.new(2136.6230, 78.9164, 3272.5044),
    ["Treasure Room"]    = CFrame.new(-3606.3499, -266.5737, -1580.9734),
    ["Kohana"]           = CFrame.new(-663.9042, 3.0458, 718.7969),
    ["Underground Cellar"]=CFrame.new(2109.5215, -94.1875, -708.6091),
    ["Ancient Jungle"]   = CFrame.new(1831.7136, 6.6250, -299.2792),
    ["Sacred Temple"]    = CFrame.new(1466.9215, -21.8751, -622.8357)
}

-- ====================================================================
--                     CONFIG FUNCTIONS
-- ====================================================================
local function ensureFolder()
    if not isfolder or not makefolder then return false end
    if not isfolder(CONFIG_FOLDER) then
        pcall(function() makefolder(CONFIG_FOLDER) end)
    end
    return isfolder(CONFIG_FOLDER)
end

local function saveConfig()
    if not writefile or not ensureFolder() then return end
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
    end)
end

local function loadConfig()
    if not readfile or not isfile or not isfile(CONFIG_FILE) then return end
    pcall(function()
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        for k,v in pairs(data) do
            if DefaultConfig[k] ~= nil then Config[k] = v end
        end
    end)
end
loadConfig()

-- ====================================================================
--                     NETWORK EVENTS
-- ====================================================================
local Events = {
    charge     = net:WaitForChild("RF/ChargeFishingRod"),
    minigame   = net:WaitForChild("RF/RequestFishingMinigameStarted"),
    finish     = net:WaitForChild("RE/FishingCompleted"),
    equip      = net:WaitForChild("RE/EquipToolFromHotbar"),
    unequip    = net:FindFirstChild("RE/UnequipToolFromHotbar"),
    textEffect = net:WaitForChild("RE/ReplicateTextEffect"),
    sell       = net:WaitForChild("RF/SellAllItems"),
    favorite   = net:WaitForChild("RE/FavoriteItem"),
}
local updateAuto = net:FindFirstChild("RF/UpdateAutoFishingState")

-- ====================================================================
--                     MODULES FOR AUTO FAVORITE
-- ====================================================================
local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
local Replion     = require(ReplicatedStorage.Packages.Replion)
local PlayerData  = Replion.Client:WaitReplion("Data")

local RarityTiers = {
    Common = 1, Uncommon = 2, Rare = 3, Epic = 4,
    Legendary = 5, Mythic = 6, Secret = 7
}
local function getRarityValue(r) return RarityTiers[r] or 0 end
local function getFishRarity(d) return (d and d.Data and d.Data.Rarity) or "Common" end

-- ====================================================================
--                     TELEPORT SYSTEM
-- ====================================================================
local Teleport = {}
function Teleport.to(name)
    local cf = LOCATIONS[name]
    if not cf then
        warn("[Teleport] Unknown location:", name); return
    end
    pcall(function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp  = char:WaitForChild("HumanoidRootPart")
        hrp.CFrame = cf
    end)
end

-- ====================================================================
--                     GPU SAVER
-- ====================================================================
local gpuActive, whiteScreen = false, nil
local function enableGPU()
    if gpuActive then return end
    gpuActive = true
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        game.Lighting.GlobalShadows       = false
        game.Lighting.FogEnd              = 1
        if setfpscap then setfpscap(8) end
    end)
    whiteScreen = Instance.new("ScreenGui")
    whiteScreen.ResetOnSpawn = false
    whiteScreen.DisplayOrder = 999999
    local f = Instance.new("Frame", whiteScreen)
    f.Size = UDim2.new(1,0,1,0)
    f.BackgroundColor3 = Color3.new(0.1,0.1,0.1)
    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(0,400,0,100)
    lbl.Position = UDim2.new(0.5,-200,0.5,-50)
    lbl.BackgroundTransparency = 1
    lbl.Text = "🟢 GPU SAVER ACTIVE\n\nAuto Fish Running..."
    lbl.TextColor3 = Color3.new(0,1,0)
    lbl.TextSize   = 28
    lbl.Font       = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    whiteScreen.Parent = game.CoreGui
end

local function disableGPU()
    if not gpuActive then return end
    gpuActive = false
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        game.Lighting.GlobalShadows       = true
        game.Lighting.FogEnd              = 100000
        if setfpscap then setfpscap(0) end
    end)
    if whiteScreen then whiteScreen:Destroy() whiteScreen = nil end
end

-- ====================================================================
--                     ANTI-AFK
-- ====================================================================
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ====================================================================
--                     AUTO FAVORITE
-- ====================================================================
local favoritedItems = {}

local function isItemFavorited(uuid)
    local ok2, result = pcall(function()
        local inv = PlayerData:GetExpect("Inventory").Items
        for _,it in ipairs(inv) do
            if it.UUID == uuid then return it.Favorited == true end
        end
        return false
    end)
    return ok2 and result or false
end

local function autoFavoriteByRarity()
    if not Config.AutoFavorite then return end
    local target = getRarityValue(Config.FavoriteRarity)
    if target < 6 then target = 6 end
    pcall(function()
        local inv = PlayerData:GetExpect("Inventory").Items
        if not inv then return end
        local count = 0
        for _, item in ipairs(inv) do
            local data = ItemUtility:GetItemData(item.Id)
            if data and data.Data then
                local rarity      = getFishRarity(data)
                local rarityValue = getRarityValue(rarity)
                if rarityValue >= target and rarityValue >= 6 then
                    if not isItemFavorited(item.UUID) and not favoritedItems[item.UUID] then
                        Events.favorite:FireServer(item.UUID)
                        favoritedItems[item.UUID] = true
                        count = count + 1
                        task.wait(0.3)
                    end
                end
            end
        end
        if count > 0 then
            print("[Auto Favorite] New favorites:", count)
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(10)
        if Config.AutoFavorite then autoFavoriteByRarity() end
    end
end)

-- ====================================================================
--           AUTO FISH V2 (LOGIKA SCRIPT LAIN) + SUPER INSTANT
-- ====================================================================

-- Animations
local AnimFolder  = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations")
local RodIdle     = AnimFolder:WaitForChild("FishingRodReelIdle")
local RodReel     = AnimFolder:WaitForChild("EasyFishReelStart")
local RodShake    = AnimFolder:WaitForChild("CastFromFullChargePosition1Hand")

local function getAnimator()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum  = char:WaitForChild("Humanoid")
    local anim = hum:FindFirstChildOfClass("Animator")
    if not anim then anim = Instance.new("Animator", hum) end
    return anim
end

local animator     = getAnimator()
local RodShakeAnim = animator:LoadAnimation(RodShake)
local RodIdleAnim  = animator:LoadAnimation(RodIdle)
local RodReelAnim  = animator:LoadAnimation(RodReel)

local AutoV2 = {
    running     = false,
    autoCatch   = Config.AutoCatch,
    perfectCast = Config.PerfectCast
}

local function getSlowReelDelay()
    local d = tonumber(Config.FishDelay) or 1.5
    if d < 0.1 then d = 0.1 end
    return d
end

local function getSuperInstantDelay()
    local d = tonumber(Config.CatchDelay) or 1.0
    if d < 0.05 then d = 0.05 end
    return d
end

local function StartAutoFishV2()
    if AutoV2.running then return end
    AutoV2.running = true

    pcall(function()
        if updateAuto then updateAuto:InvokeServer(true) end
    end)

    task.spawn(function()
        while AutoV2.running do
            pcall(function()
                -- equip rod di slot 1
                Events.equip:FireServer(1)
                task.wait(0.1)

                -- charge pakai server time (logika script lain)
                Events.charge:InvokeServer(workspace:GetServerTimeNow())
                task.wait(0.5)

                local timestamp = workspace:GetServerTimeNow()
                RodShakeAnim:Play()
                Events.charge:InvokeServer(timestamp)

                -- posisi minigame
                local baseX, baseY = -0.7499996423721313, 1
                local x, y
                if AutoV2.perfectCast then
                    x = baseX + (math.random(-500, 500) / 1e7)
                    y = baseY + (math.random(-500, 500) / 1e7)
                else
                    x = math.random(-1000,1000) / 1000
                    y = math.random(0,1000)     / 1000
                end

                RodIdleAnim:Play()
                Events.minigame:InvokeServer(x, y)

                task.wait(getSlowReelDelay())
            end)
            task.wait(0.02)
        end
    end)
end

local function StopAutoFishV2()
    AutoV2.running = false
    pcall(function()
        if updateAuto then updateAuto:InvokeServer(false) end
    end)
    RodIdleAnim:Stop()
    RodShakeAnim:Stop()
    RodReelAnim:Stop()
end

-- AutoCatch: Super Instant
Events.textEffect.OnClientEvent:Connect(function(data)
    if not AutoV2.autoCatch then return end
    if not data or not data.TextData then return end
    if data.TextData.EffectType ~= "Exclaim" then return end

    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head or data.Container ~= head then return end

    local delay = getSuperInstantDelay()
    task.spawn(function()
        task.wait(delay)
        for i = 1,3 do
            pcall(function() Events.finish:FireServer() end)
            task.wait(0.05)
        end
    end)
end)

-- ====================================================================
--                     AUTO SELL
-- ====================================================================
local function simpleSell()
    print("[Auto Sell] Selling all non-favorited items...")
    local ok3 = pcall(function() Events.sell:InvokeServer() end)
    if ok3 then
        print("[Auto Sell] Done.")
    else
        warn("[Auto Sell] Failed.")
    end
end

task.spawn(function()
    while true do
        task.wait(Config.SellDelay)
        if Config.AutoSell then simpleSell() end
    end
end)

-- ====================================================================
--                     WINDUI UI
-- ====================================================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title  = "Auto Fish V4.0",
    Icon   = "fish",
    Author = "by YOU",
    Folder = "AutoFishV4",
    Size   = UDim2.fromOffset(600, 450),
    Theme  = "Indigo",
    KeySystem = false
})

Window:SetToggleKey(Enum.KeyCode.G)
WindUI:SetNotificationLower(true)

WindUI:Notify({
    Title   = "Auto Fish Loaded",
    Content = "Super Instant Auto Fish siap digunakan.",
    Duration = 5,
    Icon    = "circle-check"
})

-- ===== TAB MAIN =====
local MainTab = Window:Tab({
    Title = "Main",
    Icon  = "home"
})

local AutoFishSection = MainTab:Section({
    Title = "Auto Fishing V2",
    Icon  = "fish"
})

-- SATU TOGGLE: Super Instant (Auto Fish + Auto Catch)
AutoFishSection:Toggle({
    Title   = "Super Instant Auto Fish",
    Content = "Auto Fish V2 + Auto Catch event-based dalam satu toggle.",
    Value   = Config.AutoFish,
    Callback = function(v)
        Config.AutoFish  = v
        Config.AutoCatch = v
        AutoV2.autoCatch = v

        if v then
            StartAutoFishV2()
            print("[SuperInstant] ON")
        else
            StopAutoFishV2()
            print("[SuperInstant] OFF")
            pcall(function()
                if Events.unequip then Events.unequip:FireServer() end
            end)
        end

        saveConfig()
    end
})

-- Perfect cast tetap bisa ON/OFF
AutoFishSection:Toggle({
    Title   = "Perfect Cast",
    Content = "Kalau ON: posisi cast mendekati perfect. OFF: lebih random.",
    Value   = Config.PerfectCast,
    Callback = function(v)
        Config.PerfectCast = v
        AutoV2.perfectCast = v
        saveConfig()
    end
})

AutoFishSection:Input({
    Title       = "Slow Reel Threshold (detik)",
    Content     = "Jeda tunggu setelah lempar sebelum script mulai narik. Semakin kecil = lebih cepat.",
    Placeholder = tostring(Config.FishDelay),
    Callback    = function(v)
        local n = tonumber(v)
        if n and n >= 0.1 and n <= 10 then
            Config.FishDelay = n
            saveConfig()
        else
            warn("[Config] Invalid Slow Reel (0.1-10)")
        end
    end
})

AutoFishSection:Input({
    Title       = "Super Instant Delay (detik)",
    Content     = "Jeda setelah tanda '!' sebelum script mengirim FishingCompleted. Semakin kecil = lebih instant.",
    Placeholder = tostring(Config.CatchDelay),
    Callback    = function(v)
        local n = tonumber(v)
        if n and n >= 0.05 and n <= 10 then
            Config.CatchDelay = n
            saveConfig()
        else
            warn("[Config] Invalid Super Instant Delay (0.05-10)")
        end
    end
})

-- ===== AUTO SELL =====
local SellSection = MainTab:Section({
    Title = "Auto Sell",
    Icon  = "dollar-sign"
})

SellSection:Toggle({
    Title   = "Auto Sell (Keep Favorites)",
    Content = "Jual semua kecuali ikan yang sudah di-favorite.",
    Value   = Config.AutoSell,
    Callback = function(v)
        Config.AutoSell = v
        saveConfig()
    end
})

SellSection:Input({
    Title       = "Sell Delay (detik)",
    Content     = "Seberapa sering auto sell (default 30, min 10).",
    Placeholder = tostring(Config.SellDelay),
    Callback    = function(v)
        local n = tonumber(v)
        if n and n >= 10 and n <= 300 then
            Config.SellDelay = n
            saveConfig()
        else
            warn("[Config] Invalid Sell Delay (10-300)")
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

-- ===== TAB TELEPORT =====
local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon  = "map-pin"
})

local TeleportSection = TeleportTab:Section({
    Title = "Locations",
    Icon  = "map-pin"
})

for name,_ in pairs(LOCATIONS) do
    TeleportSection:Button({
        Title   = name,
        Content = "Teleport ke "..name,
        Callback = function() Teleport.to(name) end
    })
end

-- ===== TAB SETTINGS =====
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
    Content = "Turunkan kualitas grafis untuk hemat resource.",
    Value   = Config.GPUSaver,
    Callback = function(v)
        Config.GPUSaver = v
        if v then enableGPU() else disableGPU() end
        saveConfig()
    end
})

local FavSection = SettingsTab:Section({
    Title = "Auto Favorite",
    Icon  = "star"
})

FavSection:Toggle({
    Title   = "Auto Favorite Fish",
    Content = "Favorite otomatis ikan Mythic/Secret.",
    Value   = Config.AutoFavorite,
    Callback = function(v)
        Config.AutoFavorite = v
        saveConfig()
    end
})

FavSection:Dropdown({
    Title   = "Favorite Rarity",
    Content = "Minimal rarity untuk auto favorite.",
    Values  = {"Mythic","Secret"},
    Callback = function(opt)
        Config.FavoriteRarity = opt
        saveConfig()
    end
})

FavSection:Button({
    Title   = "Favorite Semua Mythic/Secret Sekarang",
    Content = "Jalankan autoFavoriteByRarity sekali.",
    Callback = function()
        autoFavoriteByRarity()
    end
})

print("🎣 Auto Fish V4.0 - WindUI + SuperInstant V2 Loaded!")
