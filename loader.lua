-- =========================================================
-- SUPER INSTANT AUTOFISH V2 (VERSI RINGAN + WINDUI)
-- =========================================================

-- Layanan dasar
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser       = game:GetService("VirtualUser")
local LocalPlayer       = Players.LocalPlayer

-- Paket net
local net = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

-- Remote yang dipakai (sesuai script lain)
local Events = {
    charge     = net:WaitForChild("RF/ChargeFishingRod"),
    minigame   = net:WaitForChild("RF/RequestFishingMinigameStarted"),
    finish     = net:WaitForChild("RE/FishingCompleted"),
    equip      = net:WaitForChild("RE/EquipToolFromHotbar"),
    textEffect = net:WaitForChild("RE/ReplicateTextEffect"),
}
local updateAuto = net:FindFirstChild("RF/UpdateAutoFishingState")

-- Konfigurasi sederhana (hanya di RAM, tidak disimpan ke file)
local Config = {
    AutoFish    = false, -- Super Instant toggle
    PerfectCast = true,
    FishDelay   = 1.5,   -- Slow Reel Threshold (detik) -> kamu atur manual
    CatchDelay  = 1.0,   -- Super Instant Delay (detik)  -> kamu atur manual
}

-- Anti-AFK sederhana
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- =========================================================
-- ANIMASI (sama seperti script lain)
-- =========================================================
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

-- =========================================================
-- LOGIC AUTOFISH V2 + SUPPER INSTANT AUTOCATCH
-- =========================================================
local AutoV2 = {
    running     = false,
    autoCatch   = false,
    perfectCast = true
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
    AutoV2.running     = true
    AutoV2.autoCatch   = true       -- selalu ON bersama toggle
    AutoV2.perfectCast = Config.PerfectCast

    pcall(function()
        if updateAuto then updateAuto:InvokeServer(true) end
    end)

    task.spawn(function()
        while AutoV2.running do
            pcall(function()
                -- equip rod slot 1
                Events.equip:FireServer(1)
                task.wait(0.1)

                -- charge (script lain pakai server time)
                Events.charge:InvokeServer(workspace:GetServerTimeNow())
                task.wait(0.5)

                local timestamp = workspace:GetServerTimeNow()
                RodShakeAnim:Play()
                Events.charge:InvokeServer(timestamp)

                -- posisi minigame
                local baseX, baseY = -0.7499996423721313, 1
                local x, y
                if AutoV2.perfectCast then
                    x = baseX + (math.random(-500,500)/1e7)
                    y = baseY + (math.random(-500,500)/1e7)
                else
                    x = math.random(-1000,1000)/1000
                    y = math.random(0,1000)/1000
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
    AutoV2.running   = false
    AutoV2.autoCatch = false
    pcall(function()
        if updateAuto then updateAuto:InvokeServer(false) end
    end)
    RodIdleAnim:Stop()
    RodShakeAnim:Stop()
    RodReelAnim:Stop()
end

-- AUTOCATCH SUPER INSTANT (event-based)
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
            pcall(function()
                Events.finish:FireServer()
            end)
            task.wait(0.05)
        end
    end)
end)

-- =========================================================
-- WINDUI UI (SANGAT SEDERHANA)
-- =========================================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title  = "Super Instant AutoFish V2",
    Icon   = "fish",
    Author = "by YOU",
    Folder = "SimpleAutoFishV2",
    Size   = UDim2.fromOffset(500, 350),
    Theme  = "Indigo",
    KeySystem = false
})

Window:SetToggleKey(Enum.KeyCode.G)
WindUI:SetNotificationLower(true)

WindUI:Notify({
    Title   = "Loaded",
    Content = "Super Instant AutoFish V2 siap.",
    Duration= 5,
    Icon    = "circle-check"
})

local MainTab = Window:Tab({
    Title = "Main",
    Icon  = "home"
})

local AutoFishSection = MainTab:Section({
    Title = "Super Instant AutoFish",
    Icon  = "fish"
})

-- SATU TOGGLE: AutoFish V2 + AutoCatch
AutoFishSection:Toggle({
    Title   = "Super Instant Auto Fish",
    Content = "Auto Fish V2 + AutoCatch event-based (tanda '!')",
    Value   = Config.AutoFish,
    Callback = function(v)
        Config.AutoFish  = v
        if v then
            StartAutoFishV2()
            print("[SuperInstant] ON")
        else
            StopAutoFishV2()
            print("[SuperInstant] OFF")
        end
    end
})

AutoFishSection:Toggle({
    Title   = "Perfect Cast",
    Content = "ON = posisi cast mendekati perfect. OFF = random.",
    Value   = Config.PerfectCast,
    Callback = function(v)
        Config.PerfectCast = v
        AutoV2.perfectCast = v
    end
})

AutoFishSection:Input({
    Title       = "Slow Reel Threshold (detik)",
    Content     = "Jeda tunggu setelah lempar. Bebas atur (0.1 - 10).",
    Placeholder = tostring(Config.FishDelay),
    Callback    = function(v)
        local n = tonumber(v)
        if n and n >= 0.1 and n <= 10 then
            Config.FishDelay = n
            print("[Config] SlowReel =", n)
        else
            warn("[Config] Invalid SlowReel (0.1-10)")
        end
    end
})

AutoFishSection:Input({
    Title       = "Super Instant Delay (detik)",
    Content     = "Jeda setelah tanda '!' sebelum reel. Bebas atur (0.05 - 10).",
    Placeholder = tostring(Config.CatchDelay),
    Callback    = function(v)
        local n = tonumber(v)
        if n and n >= 0.05 and n <= 10 then
            Config.CatchDelay = n
            print("[Config] SuperInstantDelay =", n)
        else
            warn("[Config] Invalid SuperInstantDelay (0.05-10)")
        end
    end
})

print("[SuperInstant] Script loaded.")
