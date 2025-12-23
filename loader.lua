-- =========================================================
-- AUTO FISHING MODE • SUPER INSTANT (FLOW ATOMIC, V3)
-- =========================================================

-----------------------
-- SERVICES
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
    cancelInputs   = net:WaitForChild("RF/CancelFishingInputs"),
    charge         = net:WaitForChild("RF/ChargeFishingRod"),
    minigame       = net:WaitForChild("RF/RequestFishingMinigameStarted"),
    finish         = net:WaitForChild("RE/FishingCompleted"),
    textEffect     = net:WaitForChild("RE/ReplicateTextEffect"),
    updateAuto     = net:WaitForChild("RF/UpdateAutoFishingState"),

    equipHotbar    = net:WaitForChild("RE/EquipToolFromHotbar"),
    unequipOxy     = net:WaitForChild("RF/UnequipOxygenTank"),
    updateRadar    = net:WaitForChild("RF/UpdateFishingRadar"),
}

-----------------------
-- CONFIG
-----------------------
local Config = {
    AutoFishing      = false, -- toggle utama
    RandomizeResults = false, -- ON: posisi minigame acak; OFF: dekat perfect
    SlowReel         = 1.7,   -- jeda antar cast (detik)
    SuperInstant     = 1.0,   -- jeda setelah '!' (detik)
    RandomizeDelay   = false, -- acak sedikit SlowReel & SuperInstant
    BurstCount       = 3,     -- FishingCompleted per '!'-event
    BurstGap         = 0.03,  -- jeda antar FishingCompleted di burst
}

-----------------------
-- ANTI AFK
-----------------------
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-----------------------
-- DELAY HELPERS
-----------------------
local function getSlowReel()
    local base = tonumber(Config.SlowReel) or 1.7
    if base < 0.1 then base = 0.1 end
    if base > 10  then base = 10  end

    if Config.RandomizeDelay then
        local delta = base * 0.3  -- ±30%
        base = base + (math.random() * 2 - 1) * delta
        if base < 0.1 then base = 0.1 end
    end
    return base
end

local function getSuperInstant()
    local base = tonumber(Config.SuperInstant) or 1.0
    if base < 0.001 then base = 0.001 end
    if base > 10    then base = 10    end

    if Config.RandomizeDelay then
        local delta = base * 0.3
        base = base + (math.random() * 2 - 1) * delta
        if base < 0.001 then base = 0.001 end
    end
    return base
end

-----------------------
-- HIDE MINIGAME UI (SELALU AKTIF)
-----------------------
local function hardHideMinigameGui()
    local roots = {}

    table.insert(roots, CoreGui)

    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if pg then table.insert(roots, pg) end

    pcall(function()
        if typeof(gethui) == "function" then
            local hui = gethui()
            if typeof(hui) == "Instance" then
                table.insert(roots, hui)
            end
        end
    end)

    for _, root in ipairs(roots) do
        for _, inst in ipairs(root:GetDescendants()) do
            if inst:IsA("TextLabel") or inst:IsA("TextButton") then
                local txt = tostring(inst.Text or "")
                if txt ~= "" and (
                    txt:find("Klik Cepat") or
                    txt:find("Click Fast") or
                    txt:find("Klik untuk Lempar")
                ) then
                    -- matikan semua Frame ancestor
                    local frame = inst:FindFirstAncestorOfClass("Frame")
                    while frame do
                        frame.Visible = false
                        if frame.Parent and frame.Parent:IsA("Frame") then
                            frame = frame.Parent
                        else
                            frame = nil
                        end
                    end

                    -- matikan ScreenGui minigame
                    local sg = inst:FindFirstAncestorOfClass("ScreenGui")
                    if sg then
                        sg.Enabled = false
                    end
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        pcall(hardHideMinigameGui)
        task.wait(0.03)
    end
end)

-----------------------
-- INIT ala Atomic (sekali saat script load)
-----------------------
task.spawn(function()
    -- Equip rod di hotbar slot 1
    pcall(function()
        Events.equipHotbar:FireServer(1)
    end)

    -- Cancel input lama
    pcall(function()
        Events.cancelInputs:InvokeServer()
    end)

    -- Unequip oxygen tank (kalau ada)
    pcall(function()
        Events.unequipOxy:InvokeServer()
    end)

    -- Matikan radar fishing
    pcall(function()
        Events.updateRadar:InvokeServer(false)
    end)
end)

-----------------------
-- AUTO FISHING LOOP (TERIKAT '!')
-----------------------
local Auto = { running = false }

local function waitForExclaimOnce()
    while Auto.running do
        local ok, data = pcall(function()
            return Events.textEffect.OnClientEvent:Wait()
        end)
        if not ok or not Auto.running then return end

        if data and data.TextData and data.TextData.EffectType == "Exclaim" then
            local char = LocalPlayer.Character
            if not char then
                continue
            end
            local head = char:FindFirstChild("Head")
            if head and data.Container == head then
                return
            end
        end
    end
end

local function StartAutoFishing()
    if Auto.running then return end
    Auto.running = true

    -- Flag auto di server (sekali saat ON)
    pcall(function()
        Events.updateAuto:InvokeServer(true)
    end)

    task.spawn(function()
        while Auto.running do
            pcall(function()
                -- 1) CancelFishingInputs (pastikan state bersih)
                pcall(function()
                    Events.cancelInputs:InvokeServer()
                end)

                -- 2) ChargeFishingRod x2 (hold & release)
                local t1 = workspace:GetServerTimeNow()
                Events.charge:InvokeServer(nil, nil, nil, t1)
                task.wait(0.25) -- durasi hold (boleh di-tweak)

                local t2 = workspace:GetServerTimeNow()
                Events.charge:InvokeServer(nil, nil, nil, t2)

                -- 3) RequestFishingMinigameStarted
                local x, y
                if Config.RandomizeResults then
                    x = math.random(-1000, 1000) / 1000
                    y = math.random(0, 1000) / 1000
                else
                    local baseX, baseY = -0.7499996423721313, 1
                    x = baseX + (math.random(-500, 500) / 1e7)
                    y = baseY + (math.random(-500, 500) / 1e7)
                end

                local t3 = workspace:GetServerTimeNow()
                Events.minigame:InvokeServer(x, y, t3)

                -- 4) Tunggu '!' dari server (Exclaim di Head kita)
                waitForExclaimOnce()
                if not Auto.running then return end

                -- 5) Super Instant Delay
                local delay = getSuperInstant()
                if delay > 0 then
                    task.wait(delay)
                end

                -- 6) Burst FishingCompleted (tarik ikan)
                for i = 1, (Config.BurstCount or 3) do
                    pcall(function()
                        Events.finish:FireServer()
                    end)
                    task.wait(Config.BurstGap or 0.03)
                end

                -- 7) SlowReel sebelum siklus berikut
                task.wait(getSlowReel())
            end)

            task.wait(0.02)
        end
    end)
end

local function StopAutoFishing()
    Auto.running = false

    pcall(function()
        Events.updateAuto:InvokeServer(false)
    end)

    pcall(function()
        Events.cancelInputs:InvokeServer()
    end)
end

-----------------------
-- WINDUI WINDOW
-----------------------
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title  = "Auto Fishing Mode • Super Instant",
    Icon   = "fish",
    Author = "by YOU",
    Folder = "AtomicRebuild_FinalV3",
    Size   = UDim2.fromOffset(500, 340),
    Theme  = "Indigo",
    KeySystem = false
})

WindUI:SetNotificationLower(true)
WindUI:Notify({
    Title   = "Loaded",
    Content = "Rebuild Atomic-Style Auto Fishing V3 siap.\nEquip pancing dulu manual.",
    Duration= 6,
    Icon    = "circle-check"
})

-----------------------
-- FIND MAIN UI UNTUK TOGGLE
-----------------------
local mainGui
local mainRootFrame
local uiVisible = true

local function findMainUi()
    local roots = {}

    table.insert(roots, CoreGui)
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if pg then table.insert(roots, pg) end

    pcall(function()
        if typeof(gethui) == "function" then
            local hui = gethui()
            if typeof(hui) == "Instance" then
                table.insert(roots, hui)
            end
        end
    end)

    for _, root in ipairs(roots) do
        for _, inst in ipairs(root:GetDescendants()) do
            if inst:IsA("TextLabel") and tostring(inst.Text):find("Auto Fishing Mode • Super Instant") then
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
-- UI CONTENT
-----------------------
local MainTab = Window:Tab({
    Title = "Main",
    Icon  = "home"
})

local AutoSection = MainTab:Section({
    Title = "Blatant Auto Fishing",
    Icon  = "fish"
})

AutoSection:Toggle({
    Title   = "Auto Fishing",
    Content = "ON: Cancel + Charge x2 + RequestMinigame + tunggu '!' + Super Instant finish.\nOFF: UpdateAutoFishingState(false).",
    Value   = Config.AutoFishing,
    Callback = function(v)
        Config.AutoFishing = v
        if v then
            StartAutoFishing()
        else
            StopAutoFishing()
        end
        print("[AutoFishing] =", v)
    end
})

AutoSection:Toggle({
    Title   = "Randomize Results",
    Content = "ON: posisi minigame acak; OFF: dekat perfect.",
    Value   = Config.RandomizeResults,
    Callback = function(v)
        Config.RandomizeResults = v
    end
})

AutoSection:Input({
    Title       = "Slow Reel Threshold (detik)",
    Content     = "Jeda antar cast (0.1 - 10).",
    Placeholder = tostring(Config.SlowReel),
    Callback    = function(v)
        local n = tonumber(v)
        if n and n >= 0.1 and n <= 10 then
            Config.SlowReel = n
            print("[Config] SlowReel =", n)
        else
            warn("[Config] Invalid SlowReel (0.1-10)")
        end
    end
})

AutoSection:Input({
    Title       = "Super Instant Delay (detik)",
    Content     = "Jeda setelah tanda '!' sebelum FishingCompleted burst (0.001 - 10).",
    Placeholder = tostring(Config.SuperInstant),
    Callback    = function(v)
        local n = tonumber(v)
        if n and n >= 0.001 and n <= 10 then
            Config.SuperInstant = n
            print("[Config] SuperInstant =", n)
        else
            warn("[Config] Invalid SuperInstant (0.001-10)")
        end
    end
})

AutoSection:Toggle({
    Title   = "Randomize Delay",
    Content = "Acak sedikit SlowReel & SuperInstant (±30%).",
    Value   = Config.RandomizeDelay,
    Callback = function(v)
        Config.RandomizeDelay = v
    end
})

-----------------------
-- NEVERM1ND FLOATING BUTTON
-----------------------
local function createNeverm1ndGui(parent)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Neverm1nd"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 999999
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = parent

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

    local TextButton7 = Instance.new("TextButton", Frame1)
    TextButton7.Name = "togl"
    TextButton7.Size = UDim2.new(0, 55, 0, 55)
    TextButton7.BackgroundTransparency = 1
    TextButton7.BorderSizePixel = 0
    TextButton7.TextTransparency = 1
    TextButton7.ZIndex = 9999999

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

print("[AtomicRebuild_FinalV3] Script loaded.")
