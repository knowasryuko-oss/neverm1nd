-- =========================================================
-- SUPER INSTANT AUTOFISH V2 + FLOATING BUTTON (TANPA ANIMASI)
-- =========================================================

-----------------------
-- LAYANAN DASAR
-----------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser       = game:GetService("VirtualUser")
local CoreGui           = game:GetService("CoreGui")
local UIS               = game:GetService("UserInputService")

local LocalPlayer       = Players.LocalPlayer

-----------------------
-- NET / REMOTE
-----------------------
local net = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

local Events = {
    charge     = net:WaitForChild("RF/ChargeFishingRod"),
    minigame   = net:WaitForChild("RF/RequestFishingMinigameStarted"),
    finish     = net:WaitForChild("RE/FishingCompleted"),
    equip      = net:WaitForChild("RE/EquipToolFromHotbar"),
    textEffect = net:WaitForChild("RE/ReplicateTextEffect"),
}
local updateAuto = net:FindFirstChild("RF/UpdateAutoFishingState")

-----------------------
-- CONFIG SEDERHANA (DI RAM)
-----------------------
local Config = {
    AutoFish    = false, -- Super Instant toggle
    PerfectCast = true,
    FishDelay   = 1.5,   -- Slow Reel Threshold (detik) - bebas kamu atur
    CatchDelay  = 1.0,   -- Super Instant Delay (detik)  - bebas kamu atur
}

-----------------------
-- ANTI AFK
-----------------------
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-----------------------
-- AUTO FISH V2 LOGIC
-----------------------
local AutoV2 = {
    running   = false,
    autoCatch = false,
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
    AutoV2.running   = true
    AutoV2.autoCatch = true

    pcall(function()
        if updateAuto then updateAuto:InvokeServer(true) end
    end)

    task.spawn(function()
        while AutoV2.running do
            pcall(function()
                -- equip rod di hotbar slot 1
                Events.equip:FireServer(1)
                task.wait(0.1)

                -- charge 1 (pakai waktu server)
                Events.charge:InvokeServer(workspace:GetServerTimeNow())
                task.wait(0.5)

                -- charge 2 (release) dengan timestamp
                local timestamp = workspace:GetServerTimeNow()
                Events.charge:InvokeServer(timestamp)

                -- posisi minigame
                local baseX, baseY = -0.7499996423721313, 1
                local x, y
                if Config.PerfectCast then
                    x = baseX + (math.random(-500,500)/1e7)
                    y = baseY + (math.random(-500,500)/1e7)
                else
                    x = math.random(-1000,1000)/1000
                    y = math.random(0,1000)/1000
                end

                Events.minigame:InvokeServer(x, y)

                -- tunggu SlowReelThreshold
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
end

-----------------------
-- AUTOCATCH SUPER INSTANT (EVENT)
-----------------------
Events.textEffect.OnClientEvent:Connect(function(data)
    if not AutoV2.autoCatch then return end
    if not data or not data.TextData then return end
    if data.TextData.EffectType ~= "Exclaim" then return end -- tanda '!'

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
-- WINDUI WINDOW + GET ScreenGui UTAMA
-- =========================================================
local existing = {}
for _,g in ipairs(CoreGui:GetChildren()) do
    existing[g] = true
end

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

-- JANGAN pakai toggle key keyboard (biarkan kosong)
-- Window:SetToggleKey(Enum.KeyCode.G)

WindUI:SetNotificationLower(true)
WindUI:Notify({
    Title   = "Loaded",
    Content = "Super Instant AutoFish V2 siap.",
    Duration= 5,
    Icon    = "circle-check"
})

-- Cari ScreenGui baru yang dibuat WindUI
local mainGui
for _,g in ipairs(CoreGui:GetChildren()) do
    if not existing[g] and g:IsA("ScreenGui") then
        mainGui = g
        break
    end
end

local uiVisible = true
local function setMainVisible(state)
    uiVisible = state
    if mainGui then mainGui.Enabled = state end
end

-----------------------
-- ISI WINDOW (TAB MAIN)
-----------------------
local MainTab = Window:Tab({
    Title = "Main",
    Icon  = "home"
})

local AutoFishSection = MainTab:Section({
    Title = "Super Instant AutoFish",
    Icon  = "fish"
})

AutoFishSection:Toggle({
    Title   = "Super Instant Auto Fish",
    Content = "Auto Fish V2 + AutoCatch event-based (tanda '!')",
    Value   = Config.AutoFish,
    Callback = function(v)
        Config.AutoFish = v
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
    Content = "ON = cast mendekati perfect; OFF = random.",
    Value   = Config.PerfectCast,
    Callback = function(v)
        Config.PerfectCast = v
    end
})

AutoFishSection:Input({
    Title       = "Slow Reel Threshold (detik)",
    Content     = "Jeda tunggu setelah lempar. Isi bebas (0.1 - 10).",
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
    Content     = "Jeda setelah tanda '!' sebelum reel. Isi bebas (0.05 - 10).",
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

-- Pastikan UI utama kelihatan saat awal
setMainVisible(true)

-- =========================================================
-- FLOATING BUTTON DRAGGABLE (UNTUK SHOW/HIDE WINDOW)
-- =========================================================
local floatGui = Instance.new("ScreenGui")
floatGui.Name = "SuperInstant_Floating"
floatGui.ResetOnSpawn = false
floatGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
floatGui.Parent = CoreGui

local floatButton = Instance.new("ImageButton")
floatButton.Name = "ToggleButton"
floatButton.Parent = floatGui
floatButton.Size = UDim2.new(0, 60, 0, 60)
floatButton.Position = UDim2.new(0, 20, 0.5, -30)  -- posisi awal di kiri
floatButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
floatButton.BackgroundTransparency = 0.2
floatButton.BorderSizePixel = 0
floatButton.AutoButtonColor = true
floatButton.Image = "rbxassetid://6031091002" -- ikon fish bundar, bisa diganti
floatButton.ImageColor3 = Color3.fromRGB(255,255,255)

local uicorner = Instance.new("UICorner", floatButton)
uicorner.CornerRadius = UDim.new(1,0)

-- klik = toggle main UI
floatButton.MouseButton1Click:Connect(function()
    setMainVisible(not uiVisible)
end)

-- DRAG LOGIC
local dragging = false
local dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    floatButton.Position = UDim2.new(
        0, startPos.X.Offset + delta.X,
        0, startPos.Y.Offset + delta.Y
    )
end

floatButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos  = floatButton.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

floatButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

print("[SuperInstant] Script + floating button loaded.")
