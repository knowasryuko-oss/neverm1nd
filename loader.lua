-- ====================================================================
--                 AUTO FISH V4.0 - WINDUI EDITION
--          Based on Working test.lua Fishing Method
-- ====================================================================

-- ====== CRITICAL DEPENDENCY VALIDATION ======
local success, errorMsg = pcall(function()
    local services = {
        game = game,
        workspace = workspace,
        Players = game:GetService("Players"),
        RunService = game:GetService("RunService"),
        ReplicatedStorage = game:GetService("ReplicatedStorage"),
        HttpService = game:GetService("HttpService")
    }
    
    for serviceName, service in pairs(services) do
        if not service then
            error("Critical service missing: " .. serviceName)
        end
    end
    
    local LocalPlayer = game:GetService("Players").LocalPlayer
    if not LocalPlayer then
        error("LocalPlayer not available")
    end
    
    return true
end)

if not success then
    error("❌ [Auto Fish] Critical dependency check failed: " .. tostring(errorMsg))
    return
end

-- ====================================================================
--                        CORE SERVICES
-- ====================================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local HttpService      = game:GetService("HttpService")
local VirtualUser      = game:GetService("VirtualUser")
local LocalPlayer      = Players.LocalPlayer

-- RbxNet package (untuk semua remote)
local NetPackage = ReplicatedStorage
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
    AutoFish       = false,
    AutoSell       = false,
    AutoCatch      = false,
    GPUSaver       = false,
    BlatantMode    = false,
    FishDelay      = 0.9,
    CatchDelay     = 0.2,
    SellDelay      = 30,
    TeleportLocation = "Sisyphus Statue",
    AutoFavorite   = true,
    FavoriteRarity = "Mythic"
}

local Config = {}
for k, v in pairs(DefaultConfig) do Config[k] = v end

-- ====================================================================
--                    TELEPORT LOCATIONS
-- ====================================================================
local LOCATIONS = {
    ["Spawn"] = CFrame.new(45.2788086, 252.562927, 2987.10913, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    ["Sisyphus Statue"] = CFrame.new(-3728.21606, -135.074417, -1012.12744, -0.977224171, 7.74980258e-09, -0.212209702, 1.566994e-08, 1, -3.5640408e-08, 0.212209702, -3.81539813e-08, -0.977224171),
    ["Coral Reefs"] = CFrame.new(-3114.78198, 1.32066584, 2237.52295, -0.304758579, 1.6556676e-08, -0.952429652, -8.50574935e-08, 1, 4.46003305e-08, 0.952429652, 9.46036067e-08, -0.304758579),
    ["Esoteric Depths"] = CFrame.new(3248.37109, -1301.53027, 1403.82727, -0.920208454, 7.76270355e-08, 0.391428679, 4.56261056e-08, 1, -9.10549289e-08, -0.391428679, -6.5930152e-08, -0.920208454),
    ["Crater Island"] = CFrame.new(1016.49072, 20.0919304, 5069.27295, 0.838976264, 3.30379857e-09, -0.544168055, 2.63538391e-09, 1, 1.01344115e-08, 0.544168055, -9.93662219e-09, 0.838976264),
    ["Lost Isle"] = CFrame.new(-3618.15698, 240.836655, -1317.45801, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    ["Weather Machine"] = CFrame.new(-1488.51196, 83.1732635, 1876.30298, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    ["Tropical Grove"] = CFrame.new(-2095.34106, 197.199997, 3718.08008),
    ["Mount Hallow"] = CFrame.new(2136.62305, 78.9163895, 3272.50439, -0.977613986, -1.77645827e-08, 0.210406482, -2.42338203e-08, 1, -2.81680421e-08, -0.210406482, -3.26364251e-08, -0.977613986),
    ["Treasure Room"] = CFrame.new(-3606.34985, -266.57373, -1580.97339, 0.998743415, 1.12141152e-13, -0.0501160324, -1.56847693e-13, 1, -8.88127842e-13, 0.0501160324, 8.94872392e-13, 0.998743415),
    ["Kohana"] = CFrame.new(-663.904236, 3.04580712, 718.796875, -0.100799225, -2.14183729e-08, -0.994906783, -1.12300391e-08, 1, -2.03902459e-08, 0.994906783, 9.11752096e-09, -0.100799225),
    ["Underground Cellar"] = CFrame.new(2109.52148, -94.1875076, -708.609131, 0.418592364, 3.34794485e-08, -0.908174217, -5.24141512e-08, 1, 1.27060247e-08, 0.908174217, 4.22825366e-08, 0.418592364),
    ["Ancient Jungle"] = CFrame.new(1831.71362, 6.62499952, -299.279175, 0.213522509, 1.25553285e-07, -0.976938128, -4.32026184e-08, 1, 1.19074642e-07, 0.976938128, 1.67811702e-08, 0.213522509),
    ["Sacred Temple"] = CFrame.new(1466.92151, -21.8750591, -622.835693, -0.764787138, 8.14444334e-09, 0.644283056, 2.31097452e-08, 1, 1.4791004e-08, -0.644283056, 2.6201187e-08, -0.764787138)
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
        print("[Config] Settings saved!")
    end)
end

local function loadConfig()
    if not readfile or not isfile or not isfile(CONFIG_FILE) then return end
    pcall(function()
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        for k, v in pairs(data) do
            if DefaultConfig[k] ~= nil then Config[k] = v end
        end
        print("[Config] Settings loaded!")
    end)
end

loadConfig()

-- ====================================================================
--                     NETWORK EVENTS
-- ====================================================================
local function getNetworkEvents()
    local net = NetPackage
    return {
        fishing  = net:WaitForChild("RE/FishingCompleted"),
        sell     = net:WaitForChild("RF/SellAllItems"),
        charge   = net:WaitForChild("RF/ChargeFishingRod"),
        minigame = net:WaitForChild("RF/RequestFishingMinigameStarted"),
        cancel   = net:WaitForChild("RF/CancelFishingInputs"),
        equip    = net:WaitForChild("RE/EquipToolFromHotbar"),
        unequip  = net:WaitForChild("RE/UnequipToolFromHotbar"),
        favorite = net:WaitForChild("RE/FavoriteItem")
    }
end

local Events = getNetworkEvents()

-- ====================================================================
--                     MODULES FOR AUTO FAVORITE
-- ====================================================================
local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
local Replion     = require(ReplicatedStorage.Packages.Replion)
local PlayerData  = Replion.Client:WaitReplion("Data")

-- ====================================================================
--                     RARITY SYSTEM
-- ====================================================================
local RarityTiers = {
    Common    = 1,
    Uncommon  = 2,
    Rare      = 3,
    Epic      = 4,
    Legendary = 5,
    Mythic    = 6,
    Secret    = 7
}

local function getRarityValue(rarity)
    return RarityTiers[rarity] or 0
end

local function getFishRarity(itemData)
    if not itemData or not itemData.Data then return "Common" end
    return itemData.Data.Rarity or "Common"
end

-- ====================================================================
--                     TELEPORT SYSTEM
-- ====================================================================
local Teleport = {}

function Teleport.to(locationName)
    local cframe = LOCATIONS[locationName]
    if not cframe then
        warn("❌ [Teleport] Location not found: " .. tostring(locationName))
        return false
    end
    
    local success = pcall(function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local rootPart  = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        rootPart.CFrame = cframe
        print("✅ [Teleport] Moved to " .. locationName)
    end)
    
    return success
end

-- ====================================================================
--                     GPU SAVER
-- ====================================================================
local gpuActive  = false
local whiteScreen = nil

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
    
    local frame = Instance.new("Frame")
    frame.Size              = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3  = Color3.new(0.1, 0.1, 0.1)
    frame.Parent            = whiteScreen
    
    local label = Instance.new("TextLabel")
    label.Size                 = UDim2.new(0, 400, 0, 100)
    label.Position             = UDim2.new(0.5, -200, 0.5, -50)
    label.BackgroundTransparency = 1
    label.Text                 = "🟢 GPU SAVER ACTIVE\n\nAuto Fish Running..."
    label.TextColor3           = Color3.new(0, 1, 0)
    label.TextSize             = 28
    label.Font                 = Enum.Font.GothamBold
    label.TextXAlignment       = Enum.TextXAlignment.Center
    label.Parent               = frame
    
    whiteScreen.Parent = game.CoreGui
    print("[GPU] GPU Saver enabled")
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
    
    if whiteScreen then
        whiteScreen:Destroy()
        whiteScreen = nil
    end
    print("[GPU] GPU Saver disabled")
end

-- ====================================================================
--                     ANTI-AFK
-- ====================================================================
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

print("[Anti-AFK] Protection enabled")

-- ====================================================================
--                     AUTO FAVORITE
-- ====================================================================
local favoritedItems = {}

local function isItemFavorited(uuid)
    local success, result = pcall(function()
        local items = PlayerData:GetExpect("Inventory").Items
        for _, item in ipairs(items) do
            if item.UUID == uuid then
                return item.Favorited == true
            end
        end
        return false
    end)
    return success and result or false
end

local function autoFavoriteByRarity()
    if not Config.AutoFavorite then return end
    
    local targetRarity = Config.FavoriteRarity
    local targetValue  = getRarityValue(targetRarity)
    if targetValue < 6 then
        targetValue = 6
    end
    
    local favorited = 0
    
    pcall(function()
        local items = PlayerData:GetExpect("Inventory").Items
        if not items or #items == 0 then return end
        
        for _, item in ipairs(items) do
            local data = ItemUtility:GetItemData(item.Id)
            if data and data.Data then
                local itemName   = data.Data.Name or "Unknown"
                local rarity     = getFishRarity(data)
                local rarityValue= getRarityValue(rarity)
                
                if rarityValue >= targetValue and rarityValue >= 6 then
                    if not isItemFavorited(item.UUID) and not favoritedItems[item.UUID] then
                        Events.favorite:FireServer(item.UUID)
                        favoritedItems[item.UUID] = true
                        favorited = favorited + 1
                        print("[Auto Favorite] ⭐ #" .. favorited .. " - " .. itemName .. " (" .. rarity .. ")")
                        task.wait(0.3)
                    end
                end
            end
        end
    end)
    
    if favorited > 0 then
        print("[Auto Favorite] ✅ Complete! Favorited: " .. favorited)
    end
end

task.spawn(function()
    while true do
        task.wait(10)
        if Config.AutoFavorite then
            autoFavoriteByRarity()
        end
    end
end)

-- ====================================================================
--                     FISHING LOGIC
-- ====================================================================
local isFishing     = false
local fishingActive = false

local function castRod()
    pcall(function()
        Events.equip:FireServer(1)
        task.wait(0.05)
        Events.charge:InvokeServer(1755848498.4834)
        task.wait(0.02)
        Events.minigame:InvokeServer(1.2854545116425, 1)
        print("[Fishing] 🎣 Cast")
    end)
end

local function reelIn()
    pcall(function()
        Events.fishing:FireServer()
        print("[Fishing] ✅ Reel")
    end)
end

-- BLATANT MODE
local function blatantFishingLoop()
    while fishingActive and Config.BlatantMode do
        if not isFishing then
            isFishing = true
            
            pcall(function()
                Events.equip:FireServer(1)
                task.wait(0.01)
                
                task.spawn(function()
                    Events.charge:InvokeServer(1755848498.4834)
                    task.wait(0.01)
                    Events.minigame:InvokeServer(1.2854545116425, 1)
                end)
                
                task.wait(0.05)
                
                task.spawn(function()
                    Events.charge:InvokeServer(1755848498.4834)
                    task.wait(0.01)
                    Events.minigame:InvokeServer(1.2854545116425, 1)
                end)
            end)
            
            task.wait(Config.FishDelay)
            
            for _ = 1, 5 do
                pcall(function() 
                    Events.fishing:FireServer() 
                end)
                task.wait(0.01)
            end
            
            task.wait(Config.CatchDelay * 0.5)
            isFishing = false
            print("[Blatant] ⚡ Fast cycle")
        else
            task.wait(0.01)
        end
    end
end

-- NORMAL MODE
local function normalFishingLoop()
    while fishingActive and not Config.BlatantMode do
        if not isFishing then
            isFishing = true
            
            castRod()
            task.wait(Config.FishDelay)
            reelIn()
            task.wait(Config.CatchDelay)
            
            isFishing = false
        else
            task.wait(0.1)
        end
    end
end

local function fishingLoop()
    while fishingActive do
        if Config.BlatantMode then
            blatantFishingLoop()
        else
            normalFishingLoop()
        end
        task.wait(0.1)
    end
end

-- ====================================================================
--                     AUTO CATCH (EVENT BASED)
-- ====================================================================
local RE_ReplicateTextEffect
local ok, err = pcall(function()
    RE_ReplicateTextEffect = NetPackage:WaitForChild("RE/ReplicateTextEffect")
end)

if ok and RE_ReplicateTextEffect then
    RE_ReplicateTextEffect.OnClientEvent:Connect(function(data)
        -- AutoCatch harus ON
        if not Config.AutoCatch then return end
        if not data or not data.TextData then return end
        if data.TextData.EffectType ~= "Exclaim" then return end

        local char = LocalPlayer.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end
        if data.Container ~= head then return end

        -- Ikan gigit di karakter kita → spam FishingCompleted
        task.spawn(function()
            for i = 1, 3 do
                pcall(function()
                    Events.fishing:FireServer()
                end)
                task.wait(Config.CatchDelay)
            end
        end)
    end)
else
    warn("[AutoCatch] Tidak menemukan RE/ReplicateTextEffect:", err)
end

-- ====================================================================
--                     AUTO SELL
-- ====================================================================
local function simpleSell()
    print("╔═══════════════════════════════════╗")
    print("[Auto Sell] 💰 Selling all non-favorited items...")
    
    local sellSuccess = pcall(function()
        return Events.sell:InvokeServer()
    end)
    
    if sellSuccess then
        print("[Auto Sell] ✅ SOLD! (Favorited fish kept safe)")
        print("╚═══════════════════════════════════╝")
    else
        warn("[Auto Sell] ❌ Sell failed")
        print("╚═══════════════════════════════════╝")
    end
end

task.spawn(function()
    while true do
        task.wait(Config.SellDelay)
        if Config.AutoSell then
            simpleSell()
        end
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
    Content = "Siap memancing dengan WindUI!",
    Duration = 5,
    Icon    = "circle-check"
})

-- ===== TAB MAIN =====
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
        fishingActive   = value
        
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
    Title   = "Auto Catch (Event Based)",
    Content = "Otomatis reel saat tanda '!' muncul di kepala.",
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
    Content     = "Jeda antar spam FishingCompleted. Default: 0.2 (0.1 - 10)",
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

-- ===== TAB TELEPORT =====
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

-- ===== TAB INFO =====
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
• Auto Sell (menjaga ikan yang di-favorite)
• Auto Catch berbasis event (tanda '!' di kepala)
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

→ Siklus mancing jauh lebih cepat, tapi juga lebih riskan kalau game punya anti-cheat yang ketat.
    ]]
})

print("🎣 Auto Fish V4.0 - WindUI Edition Loaded!")
