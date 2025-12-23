-- =========================================================
-- BLATANT AUTO FISHING ala ATOMIC
-- HANYA: RF/UpdateAutoFishingState + RE/FishingCompleted SPAM
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
    updateAuto = net:WaitForChild("RF/UpdateAutoFishingState"),
    finish     = net:WaitForChild("RE/FishingCompleted"),
    textEffect = net:WaitForChild("RE/ReplicateTextEffect"), -- kalau mau pakai '!' sebagai trigger
}

-----------------------
-- CONFIG
-----------------------
local Config = {
    BlatantAuto = false,   -- master toggle gaya Atomic
    UseExclaim  = false,   -- kalau true: cuma spam saat ada tanda '!'
    BurstCount  = 3,       -- berapa kali FishingCompleted per burst (Atomic kelihatan x3)
    BurstDelay  = 0.03,    -- jeda antar FishingCompleted di dalam 1 burst
    CycleDelay  = 0.10,    -- jeda antar burst kalau TIDAK pakai '!'
    HideMinigameUI = true, -- sembunyikan bar tap-tap di layar (client-only)
}

-----------------------
-- ANTI AFK
-----------------------
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-----------------------
-- HIDE MINIGAME UI (CLIENT-SIDE)
-----------------------
local function scanAndHideMinigameGui()
    if not Config.HideMinigameUI then return end

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
                    local frame = inst:FindFirstAncestorOfClass("Frame")
                    if frame then frame.Visible = false end
                    local sg = inst:FindFirstAncestorOfClass("ScreenGui")
                    if sg then sg.Enabled = false end
                end
            end
        end
    end
end

-- loop ringan supaya minigame bar selalu ketutup
task.spawn(function()
    while true do
        pcall(scanAndHideMinigameGui)
        task.wait(0.1)
    end
end)

-----------------------
-- BLATANT AUTO FISH CORE
-----------------------
local BlatantState = {
    running = false,
}

-- burst x3 FishingCompleted seperti pola Atomic
local function doBurst()
    for i = 1, Config.BurstCount do
        pcall(function()
            Events.finish:FireServer()
        end)
        task.wait(Config.BurstDelay)
    end
end

-- MODE 1: SPAM BERKALA (TANPA LIHAT '!')
local function spamLoopNoExclaim()
    while BlatantState.running and not Config.UseExclaim do
        doBurst()
        task.wait(Config.CycleDelay)
    end
end

-- MODE 2: HANYA SAAT ADA TANDA '!' (lebih aman)
Events.textEffect.OnClientEvent:Connect(function(data)
    if not BlatantState.running then return end
    if not Config.UseExclaim then return end
    if not data or not data.TextData then return end
    if data.TextData.EffectType ~= "Exclaim" then return end -- tanda '!'

    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head or data.Container ~= head then return end

    task.spawn(doBurst)
end)

local function StartBlatant()
    if BlatantState.running then return end
    BlatantState.running = true

    -- Aktifkan auto fishing di server (persis seperti Cobalt: invokeServer(true))
    pcall(function()
        Events.updateAuto:InvokeServer(true)
    end)

    -- Kalau tidak pakai trigger '!' → spam terus
    if not Config.UseExclaim then
        task.spawn(spamLoopNoExclaim)
    end
end

local function StopBlatant()
    BlatantState.running = false

    pcall(function()
        Events.updateAuto:InvokeServer(false)
    end)
end

-- =========================================================
-- WINDUI WINDOW
-- =========================================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title  = "V2 (Atomic-Style)",
    Icon   = "fish",
    Author = "by YOU",
    Folder = "AtomicBlatant",
    Size   = UDim2.fromOffset(500, 320),
    Theme  = "Indigo",
    KeySystem = false
})

WindUI:SetNotificationLower(true)
WindUI:Notify({
    Title   = "Loaded",
    Content = "Blatant Auto Fishing ala Atomic siap.",
    Duration= 5,
    Icon    = "circle-check"
})

-----------------------
-- FIND MAIN UI FOR FLOATING BUTTON
-----------------------
local mainGui
local mainRootFrame
local uiVisible = true

local function findMainUi()
    local parents = {}

    table.insert(parents, CoreGui)
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then table.insert(parents, playerGui) end

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
            if inst:IsA("TextLabel") and tostring(inst.Text):find("Atomic-Style") then
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
    Title = "Blatant Auto Fishing (Atomic-like)",
    Icon  = "fish"
})

AutoSection:Toggle({
    Title   = "Blatant Auto Fishing",
    Content = "ON: RF/UpdateAutoFishingState(true) + spam RE/FishingCompleted.\nOFF: UpdateAutoFishingState(false).",
    Value   = Config.BlatantAuto,
    Callback = function(v)
        Config.BlatantAuto = v
        if v then
            StartBlatant()
        else
            StopBlatant()
        end
        print("[BlatantAuto] =", v)
    end
})

AutoSection:Toggle({
    Title   = "Gunakan tanda '!' sebagai trigger",
    Content = "ON: burst FishingCompleted hanya saat efek '!' muncul (lebih aman).\nOFF: spam terus dengan interval CycleDelay (lebih mirip Atomic murni).",
    Value   = Config.UseExclaim,
    Callback = function(v)
        Config.UseExclaim = v
        -- kalau diubah ke OFF saat sedang jalan → mulai loop spam
        if BlatantState.running and not v then
            task.spawn(spamLoopNoExclaim)
        end
    end
})

AutoSection:Input({
    Title       = "Burst Count (xFishingCompleted)",
    Content     = "Berapa kali FishingCompleted per burst. Atomic kelihatan pakai 3.",
    Placeholder = tostring(Config.BurstCount),
    Callback    = function(v)
        local n = tonumber(v)
        if n and n >= 1 and n <= 10 then
            Config.BurstCount = math.floor(n)
            print("[Config] BurstCount =", Config.BurstCount)
        else
            warn("[Config] Invalid BurstCount (1-10)")
        end
    end
})

AutoSection:Input({
    Title       = "Burst Delay (detik)",
    Content     = "Jeda antar FishingCompleted di dalam 1 burst (0.0 - 0.2).",
    Placeholder = tostring(Config.BurstDelay),
    Callback    = function(v)
        local n = tonumber(v)
        if n and n >= 0 and n <= 0.2 then
            Config.BurstDelay = n
            print("[Config] BurstDelay =", n)
        else
            warn("[Config] Invalid BurstDelay (0 - 0.2)")
        end
    end
})

AutoSection:Input({
    Title       = "Cycle Delay (detik)",
    Content     = "Jeda antar burst kalau UseExclaim = OFF. 0.05 - 1.0",
    Placeholder = tostring(Config.CycleDelay),
    Callback    = function(v)
        local n = tonumber(v)
        if n and n >= 0.05 and n <= 1 then
            Config.CycleDelay = n
            print("[Config] CycleDelay =", n)
        else
            warn("[Config] Invalid CycleDelay (0.05-1)")
        end
    end
})

AutoSection:Toggle({
    Title   = "Hide Minigame UI",
    Content = "Sembunyikan bar 'Klik Cepat!' di layar (client-only).",
    Value   = Config.HideMinigameUI,
    Callback = function(v)
        Config.HideMinigameUI = v
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

print("[AtomicBlatant] Script loaded.")
