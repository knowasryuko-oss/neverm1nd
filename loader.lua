-- =========================================================
-- SUPER INSTANT AUTOFISH V2 + NEVERM1ND FLOATING BUTTON
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
    AutoFish    = false,  -- Super Instant toggle
    PerfectCast = true,
    FishDelay   = 1.5,    -- Slow Reel Threshold (detik)
    CatchDelay  = 1.0,    -- Super Instant Delay (detik)
}

-----------------------
-- ANTI AFK
-----------------------
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-----------------------
-- LOGIC AUTOFISH V2
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

                -- charge pertama (pakai waktu server)
                Events.charge:InvokeServer(workspace:GetServerTimeNow())
                task.wait(0.5)

                -- charge kedua (release) dengan timestamp
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
    if data.TextData.EffectType ~= "Exclaim" then return end  -- tanda '!'

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
-- WINDUI WINDOW
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

WindUI:SetNotificationLower(true)
WindUI:Notify({
    Title   = "Loaded",
    Content = "Super Instant AutoFish V2 siap.",
    Duration= 5,
    Icon    = "circle-check"
})

-----------------------
-- FUNGSI CARI & TOGGLE MAIN GUI WINDUI
-----------------------
local mainGui
local uiVisible = true

local function findMainGui()
    local parents = {}

    -- CoreGui (umum di executor)
    table.insert(parents, CoreGui)

    -- PlayerGui (kalau lib parent ke PlayerGui)
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        table.insert(parents, playerGui)
    end

    -- gethui() (beberapa executor pakai ini)
    pcall(function()
        if typeof(gethui) == "function" then
            local hui = gethui()
            if typeof(hui) == "Instance" then
                table.insert(parents, hui)
            end
        end
    end)

    for _, root in ipairs(parents) do
        for _, inst in ipairs(root:GetDescendants()) do
            if inst:IsA("TextLabel") and tostring(inst.Text):find("Super Instant AutoFish V2") then
                local sg = inst:FindFirstAncestorOfClass("ScreenGui")
                if sg then
                    return sg
                end
            end
        end
    end
end

local function setMainVisible(state)
    uiVisible = state

    -- kalau belum ketemu / sudah ke-Destroy, coba cari lagi
    if (not mainGui) or (not mainGui.Parent) then
        mainGui = findMainGui()
    end

    if mainGui then
        mainGui.Enabled = state
    else
        warn("[UI] mainGui belum ketemu, tidak bisa toggle.")
    end
end

-- opsional: pastikan awalnya ON
task.spawn(function()
    task.wait(1)
    mainGui = findMainGui()
    if mainGui then
        mainGui.Enabled = true
        uiVisible = true
    else
        warn("[UI] Belum menemukan ScreenGui WindUI (akan dicari lagi saat klik tombol Neverm1nd).")
    end
end)

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

-- =========================================================
-- NEVERM1ND FLOATING BUTTON (MODEL AJO-MOK)
-- =========================================================
local function createNeverm1ndGui(parent)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Neverm1nd"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 999999
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = parent

    -- Frame utama
    local Frame1 = Instance.new("Frame")
    Frame1.AnchorPoint = Vector2.new(0, 0.5)
    Frame1.Name = "main"
    Frame1.Position = UDim2.new(0, 5, 0.5, 0)
    Frame1.Size = UDim2.new(0, 55, 0, 55)
    Frame1.BackgroundColor3 = Color3.new(1, 1, 1)
    Frame1.BorderSizePixel = 0
    Frame1.Active = true
    Frame1.Draggable = false
    Frame1.Parent = screenGui

    -- Sistem drag (PC + Mobile)
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        Frame1.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    Frame1.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Frame1.Position

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if connection then
                        connection:Disconnect()
                    end
                end
            end)
        end
    end)

    Frame1.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    -- UIGradient background
    local UIGradient2 = Instance.new("UIGradient", Frame1)
    UIGradient2.Rotation = 50
    UIGradient2.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.643137,0.615686,1)),
        ColorSequenceKeypoint.new(0.515913, Color3.new(0.117647,0.105882,0.14902)),
        ColorSequenceKeypoint.new(1, Color3.new(0.643137,0.615686,1))
    }

    -- UICorner
    local UICorner3 = Instance.new("UICorner", Frame1)
    UICorner3.CornerRadius = UDim.new(0, 15)

    -- UIStroke
    local UIStroke4 = Instance.new("UIStroke", Frame1)
    UIStroke4.Color = Color3.new(1, 1, 1)
    UIStroke4.Thickness = 2

    local UIGradient5 = Instance.new("UIGradient", UIStroke4)
    UIGradient5.Rotation = 90
    UIGradient5.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.286275,0.415686,1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.137255,0.137255,0.137255))
    }

    -- Icon
    local ImageLabel6 = Instance.new("ImageLabel", Frame1)
    ImageLabel6.Size = UDim2.new(0, 35, 0, 35)
    ImageLabel6.Image = "rbxassetid://104695336294005" -- ganti kalau mau icon lain
    ImageLabel6.BackgroundTransparency = 1
    ImageLabel6.Position = UDim2.new(0.181818187, 0, 0.181818187, 0)
    ImageLabel6.BorderColor3 = Color3.new(0, 0, 0)
    ImageLabel6.Name = "imege"
    ImageLabel6.BorderSizePixel = 0
    ImageLabel6.BackgroundColor3 = Color3.new(1, 1, 1)

    -- Tombol transparan untuk klik/toggle
    local TextButton7 = Instance.new("TextButton", Frame1)
    TextButton7.TextColor3 = Color3.new(0, 0, 0)
    TextButton7.BorderColor3 = Color3.new(0, 0, 0)
    TextButton7.TextTransparency = 1
    TextButton7.Font = Enum.Font.SourceSans
    TextButton7.Name = "togl"
    TextButton7.TextSize = 14
    TextButton7.Size = UDim2.new(0, 55, 0, 50)
    TextButton7.BackgroundTransparency = 1
    TextButton7.BorderSizePixel = 0
    TextButton7.BackgroundColor3 = Color3.new(1, 1, 1)
    TextButton7.ZIndex = 9999999

    -- Drag juga bisa lewat tombol
    TextButton7.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Frame1.Position

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if connection then
                        connection:Disconnect()
                    end
                end
            end)
        end
    end)

    TextButton7.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    return screenGui
end

-- Hapus instance lama Neverm1nd kalau ada
local function destroyOldNeverm1nd()
    for _, gui in ipairs(CoreGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name == "Neverm1nd" then
            gui:Destroy()
        end
    end
    pcall(function()
        if typeof(gethui) == "function" then
            local hui = gethui()
            if typeof(hui) == "Instance" then
                local old = hui:FindFirstChild("Neverm1nd")
                if old then old:Destroy() end
            end
        end
    end)
end

destroyOldNeverm1nd()

-- Tentukan parent yang cocok (gethui atau CoreGui)
local parentForNeverm1nd = CoreGui
pcall(function()
    if typeof(gethui) == "function" then
        local hui = gethui()
        if typeof(hui) == "Instance" then
            parentForNeverm1nd = hui
        end
    end
end)

local neverGui = createNeverm1ndGui(parentForNeverm1nd)

-- Klik tombol Neverm1nd = toggle UI WindUI
local toggleButton = neverGui:WaitForChild("main"):WaitForChild("togl")
toggleButton.MouseButton1Click:Connect(function()
    setMainVisible(not uiVisible)
end)

print("[SuperInstant] Script + Neverm1nd floating button loaded.")
