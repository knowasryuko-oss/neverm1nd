-- =========================================================
-- ATOMIC-STYLE AUTO FISHING + SUPER INSTANT AUTOCATCH
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
-- NET / REMOTE (COBALT STYLE)
-----------------------
local net = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

local Events = {
    charge        = net:WaitForChild("RF/ChargeFishingRod"),
    minigame      = net:WaitForChild("RF/RequestFishingMinigameStarted"),
    finish        = net:WaitForChild("RE/FishingCompleted"),
    equip         = net:WaitForChild("RE/EquipToolFromHotbar"),
    textEffect    = net:WaitForChild("RE/ReplicateTextEffect"),
    cancelInputs  = net:WaitForChild("RF/CancelFishingInputs"),
    updateAuto    = net:WaitForChild("RF/UpdateAutoFishingState"),
}

-----------------------
-- CONFIG
-----------------------
local Config = {
    AutoFish    = false,   -- lempar otomatis (blatant)
    AutoCatch   = true,    -- tarik otomatis saat '!'
    PerfectCast = true,    -- posisi minigame mendekati perfect
    FishDelay   = 0.55,    -- jeda antar cast / slow reel threshold (detik)
    CatchDelay  = 0.001,   -- super instant delay setelah '!' (detik)
}

-----------------------
-- ANTI AFK
-----------------------
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-----------------------
-- HELPER DELAY
-----------------------
local function getSlowReelDelay()
    local d = tonumber(Config.FishDelay) or 0.55
    if d < 0.05 then d = 0.05 end
    if d > 10   then d = 10   end
    return d
end

local function getSuperInstantDelay()
    local d = tonumber(Config.CatchDelay) or 0.001
    if d < 0.001 then d = 0.001 end
    if d > 10    then d = 10    end
    return d
end

-----------------------
-- AUTO FISH (MENIRU POLA ATOMIC)
-----------------------
local AutoState = {
    running = false,
}

local AutoCatchEnabled = false  -- dikontrol dari toggle AutoCatch

local function StartAutoFishAtomic()
    if AutoState.running then return end
    AutoState.running = true

    -- optional: nyalakan flag auto di server (seperti Atomic)
    pcall(function()
        Events.updateAuto:InvokeServer(true)
    end)

    task.spawn(function()
        while AutoState.running do
            pcall(function()
                -- 1. Cancel input sebelumnya (RF/CancelFishingInputs)
                pcall(function()
                    Events.cancelInputs:InvokeServer()
                end)

                -- 2. Equip pancing di slot 1 (kalau mau beda slot, ganti angka)
                Events.equip:FireServer(1)
                task.wait(0.05)

                -- 3. ChargeFishingRod – kirim timestamp server (cocok dengan Cobalt)
                local tsCharge = workspace:GetServerTimeNow()
                Events.charge:InvokeServer(tsCharge)
                -- Atomic biasanya pakai delay sangat kecil; kita kasih sedikit jeda
                task.wait(0.05)

                -- 4. RequestFishingMinigameStarted(x, y, serverTime)
                local x, y
                if Config.PerfectCast then
                    -- Nilai base diambil dari script lamamu, terbukti stabil
                    local baseX, baseY = -0.7499996423721313, 1
                    x = baseX + (math.random(-500, 500) / 1e7)
                    y = baseY + (math.random(-500, 500) / 1e7)
                else
                    -- random bebas
                    x = math.random(-1000, 1000) / 1000
                    y = math.random(0, 1000) / 1000
                end

                local tsMini = workspace:GetServerTimeNow()
                -- tambahkan timestamp sebagai argumen ke‑3 (seperti log Cobalt)
                Events.minigame:InvokeServer(x, y, tsMini)

                -- 5. Tunggu sampai ikan nyangkut (Slow Reel Threshold)
                task.wait(getSlowReelDelay())
            end)

            task.wait(0.01) -- jeda kecil antar loop
        end
    end)
end

local function StopAutoFishAtomic()
    AutoState.running = false

    pcall(function()
        Events.updateAuto:InvokeServer(false)
    end)

    pcall(function()
        Events.cancelInputs:InvokeServer()
    end)
end

-----------------------
-- AUTO CATCH SUPER INSTANT ('!')
-----------------------
Events.textEffect.OnClientEvent:Connect(function(data)
    if not AutoCatchEnabled then return end
    if not data or not data.TextData then return end
    if data.TextData.EffectType ~= "Exclaim" then return end  -- tanda '!'

    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head or data.Container ~= head then return end

    local delay = getSuperInstantDelay()
    task.spawn(function()
        task.wait(delay)

        -- Cobalt: RE/FishingCompleted:FireServer() tanpa argumen
        pcall(function()
            Events.finish:FireServer()
        end)
    end)
end)

-- =========================================================
-- WINDUI WINDOW
-- =========================================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title  = "Super Instant AutoFish V2 (Atomic-Style)",
    Icon   = "fish",
    Author = "by YOU",
    Folder = "AtomicLikeAutoFish",
    Size   = UDim2.fromOffset(500, 320),
    Theme  = "Indigo",
    KeySystem = false
})

WindUI:SetNotificationLower(true)
WindUI:Notify({
    Title   = "Loaded",
    Content = "Atomic-style Auto Fishing + Super Instant AutoCatch siap.",
    Duration= 5,
    Icon    = "circle-check"
})

-----------------------
-- CARI UI WINDUI UNTUK TOGGLE
-----------------------
local mainGui
local mainRootFrame
local uiVisible = true

local function findMainUi()
    local parents = {}

    table.insert(parents, CoreGui)

    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        table.insert(parents, playerGui)
    end

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
                    local frame = inst:FindFirstAncestorOfClass("Frame")
                    local top = frame
                    while top and top.Parent ~= sg and top.Parent and top.Parent:IsA("Frame") do
                        top = top.Parent
                    end
                    return sg, (top or frame)
                end
            end
        end
    end
end

local function ensureMainUi()
    if (not mainGui) or (not mainGui.Parent) or (not mainRootFrame) or (not mainRootFrame.Parent) then
        mainGui, mainRootFrame = findMainUi()
    end
end

local function setMainVisible(state)
    uiVisible = state
    ensureMainUi()

    if mainRootFrame then
        mainRootFrame.Visible = state
    elseif mainGui then
        mainGui.Enabled = state
    else
        warn("[UI] Tidak menemukan UI WindUI untuk di-toggle.")
    end
end

task.spawn(function()
    task.wait(1.5)
    ensureMainUi()
end)

-----------------------
-- ISI WINDOW
-----------------------
local MainTab = Window:Tab({
    Title = "Main",
    Icon  = "home"
})

local AutoSection = MainTab:Section({
    Title = "Atomic-Style Auto Fishing",
    Icon  = "fish"
})

AutoSection:Toggle({
    Title   = "Auto Fishing (Blatant)",
    Content = "Lempar & mulai minigame otomatis meniru pola Atomic.\nDisarankan ON juga Auto Catch.",
    Value   = Config.AutoFish,
    Callback = function(v)
        Config.AutoFish = v
        if v then
            StartAutoFishAtomic()
        else
            StopAutoFishAtomic()
        end
        print("[AutoFish] =", v)
    end
})

AutoSection:Toggle({
    Title   = "Auto Catch (tanda '!')",
    Content = "Tarik ikan otomatis begitu tanda '!' muncul di kepala.",
    Value   = Config.AutoCatch,
    Callback = function(v)
        Config.AutoCatch = v
        AutoCatchEnabled = v
        print("[AutoCatch] =", v)
    end
})

AutoSection:Toggle({
    Title   = "Perfect Cast",
    Content = "ON = posisi minigame mendekati perfect; OFF = random.",
    Value   = Config.PerfectCast,
    Callback = function(v)
        Config.PerfectCast = v
    end
})

AutoSection:Input({
    Title       = "Slow Reel Threshold (detik)",
    Content     = "Jeda setelah mulai minigame sebelum cast berikutnya. (0.05 - 10)",
    Placeholder = tostring(Config.FishDelay),
    Callback    = function(v)
        local n = tonumber(v)
        if n and n >= 0.05 and n <= 10 then
            Config.FishDelay = n
            print("[Config] SlowReel =", n)
        else
            warn("[Config] Invalid SlowReel (0.05-10)")
        end
    end
})

AutoSection:Input({
    Title       = "Super Instant Delay (detik)",
    Content     = "Jeda setelah '!' sebelum RE/FishingCompleted. Contoh: 0.001",
    Placeholder = tostring(Config.CatchDelay),
    Callback    = function(v)
        local n = tonumber(v)
        if n and n >= 0.001 and n <= 10 then
            Config.CatchDelay = n
            print("[Config] SuperInstantDelay =", n)
        else
            warn("[Config] Invalid SuperInstantDelay (0.001-10)")
        end
    end
})

-- =========================================================
-- NEVERM1ND FLOATING BUTTON
-- =========================================================
local function createNeverm1ndGui(parent)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Neverm1nd"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 999999
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = parent

    -- Frame utama (border ungu)
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

    local UICorner3 = Instance.new("UICorner", Frame1)
    UICorner3.CornerRadius = UDim.new(0, 15)

    local UIGradient2 = Instance.new("UIGradient", Frame1)
    UIGradient2.Rotation = 50
    UIGradient2.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.643137,0.615686,1)),
        ColorSequenceKeypoint.new(0.515913, Color3.new(0.117647,0.105882,0.14902)),
        ColorSequenceKeypoint.new(1, Color3.new(0.643137,0.615686,1))
    }

    local UIStroke4 = Instance.new("UIStroke", Frame1)
    UIStroke4.Color = Color3.new(1, 1, 1)
    UIStroke4.Thickness = 2

    local UIGradient5 = Instance.new("UIGradient", UIStroke4)
    UIGradient5.Rotation = 90
    UIGradient5.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.286275,0.415686,1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.137255,0.137255,0.137255))
    }

    -- Icon Neverm1nd
    local ImageLabel6 = Instance.new("ImageLabel", Frame1)
    ImageLabel6.Name = "imege"
    ImageLabel6.BackgroundTransparency = 1
    ImageLabel6.BorderSizePixel = 0
    ImageLabel6.AnchorPoint = Vector2.new(0.5, 0.5)
    ImageLabel6.Position    = UDim2.new(0.5, 0, 0.5, 0)
    ImageLabel6.Size        = UDim2.new(1, -6, 1, -6)
    ImageLabel6.Image       = "rbxassetid://100651748260650"
    ImageLabel6.ScaleType   = Enum.ScaleType.Fit

    local ImageCorner = Instance.new("UICorner", ImageLabel6)
    ImageCorner.CornerRadius = UDim.new(0, 13)

    -- Drag (PC + Mobile)
    local dragging = false
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
                    if connection then connection:Disconnect() end
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

    -- Tombol transparan untuk klik/toggle UI
    local TextButton7 = Instance.new("TextButton", Frame1)
    TextButton7.Name = "togl"
    TextButton7.Size = UDim2.new(0, 55, 0, 55)
    TextButton7.BackgroundTransparency = 1
    TextButton7.BorderSizePixel = 0
    TextButton7.TextTransparency = 1
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
                    if connection then connection:Disconnect() end
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

-- Hapus Neverm1nd lama
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

-- Pilih parent (gethui/CoreGui)
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
local toggleButton = neverGui:WaitForChild("main"):WaitForChild("togl")

toggleButton.MouseButton1Click:Connect(function()
    setMainVisible(not uiVisible)
end)

print("[SuperInstant] Atomic-style AutoFish + Neverm1nd button loaded.")
