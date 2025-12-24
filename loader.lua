-- =========================================================
-- BLATANT TESTER (PARALLEL PERSIS FLOW YANG DITEMUKAN)
-- Charge({time}) -> Minigame(1,0,time2) -> wait CompleteDelay -> FishingCompleted() -> wait CancelDelay -> CancelInputs()
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

    equipHotbar    = net:FindFirstChild("RE/EquipToolFromHotbar"), -- opsional
    unequipOxy     = net:FindFirstChild("RF/UnequipOxygenTank"),   -- opsional
    updateRadar    = net:FindFirstChild("RF/UpdateFishingRadar"),  -- opsional
}

-----------------------
-- CONFIG
-----------------------
local Config = {
    TesterEnabled = false, -- toggle utama
    CompleteDelay = 0.45,  -- jeda dari RequestMinigame ke FishingCompleted
    CancelDelay   = 0.30,  -- jeda dari FishingCompleted ke CancelInputs
}

-----------------------
-- ANTI AFK
-----------------------
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-----------------------
-- INIT (OPSIONAL)
-----------------------
task.spawn(function()
    -- Equip rod di hotbar slot 1 (sekali di awal)
    pcall(function()
        if Events.equipHotbar then
            Events.equipHotbar:FireServer(1)
        end
    end)

    -- Unequip oxygen tank (kalau ada)
    pcall(function()
        if Events.unequipOxy then
            Events.unequipOxy:InvokeServer()
        end
    end)

    -- Matikan radar fishing (kalau ada)
    pcall(function()
        if Events.updateRadar then
            Events.updateRadar:InvokeServer(false)
        end
    end)
end)

-----------------------
-- BLATANT TESTER LOOP
-- Per cast (thread utama):
--   Charge({time}) -> RequestMinigame(1,0,time2)
-- Thread lain per cast:
--   wait CompleteDelay -> FishingCompleted()
--   wait CancelDelay   -> CancelInputs()
-----------------------
local Tester = { running = false }

local function StartBlatantTester()
    if Tester.running then return end
    Tester.running = true

    task.spawn(function()
        while Tester.running do
            pcall(function()
                -- 1) ChargeFishingRod sekali (pakai {time} seperti logmu)
                local t1 = workspace:GetServerTimeNow()
                Events.charge:InvokeServer({ t1 })

                -- 2) RequestFishingMinigameStarted di (1,0)
                local t2 = workspace:GetServerTimeNow()
                Events.minigame:InvokeServer(1, 0, t2)

                -- 3) Ambil delay dari Config (tanpa clamp/safety)
                local completeDelay = tonumber(Config.CompleteDelay) or 0
                local cancelDelay   = tonumber(Config.CancelDelay) or 0

                -- 4) Thread penyelesaian untuk cast ini
                task.spawn(function()
                    if completeDelay > 0 then
                        task.wait(completeDelay)
                    end

                    -- FishingCompleted 1x
                    pcall(function()
                        Events.finish:FireServer()
                    end)

                    if cancelDelay > 0 then
                        task.wait(cancelDelay)
                    end

                    -- CancelFishingInputs 1x
                    pcall(function()
                        Events.cancelInputs:InvokeServer()
                    end)
                end)

                -- 5) Cast berikutnya dijadwalkan di frame berikutnya
                task.wait() -- minimal yield 1 frame
            end)
        end
    end)
end

local function StopBlatantTester()
    Tester.running = false
    -- thread penyelesaian yang sudah ter-spawn akan selesai sendiri
end

-----------------------
-- WINDUI WINDOW
-----------------------
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title  = "Blatant Tester (Flow Remote Penuh)",
    Icon   = "fish",
    Author = "by YOU",
    Folder = "BlatantTester_RemoteFlow",
    Size   = UDim2.fromOffset(500, 260),
    Theme  = "Indigo",
    KeySystem = false
})

WindUI:SetNotificationLower(true)
WindUI:Notify({
    Title   = "Loaded",
    Content = "Blatant Tester (Charge+Minigame main loop, Complete+Cancel di task.spawn) siap.\nEquip pancing manual, lalu ON.",
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
            if inst:IsA("TextLabel") and tostring(inst.Text):find("Blatant Tester") then
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

local TesterSection = MainTab:Section({
    Title = "Blatant Tester",
    Icon  = "zap"
})

TesterSection:Toggle({
    Title   = "Blatant Tester",
    Content = "ON: Charge({t}) -> Minigame(1,0,t2) di main loop.\n" ..
              "Setiap cast spawn task: wait CompleteDelay -> FishingCompleted -> wait CancelDelay -> Cancel.\n" ..
              "OFF: stop spawn cast baru (task lama tetap selesai).",
    Value   = Config.TesterEnabled,
    Callback = function(v)
        Config.TesterEnabled = v
        if v then
            StartBlatantTester()
        else
            StopBlatantTester()
        end
        print("[BlatantTester] =", v)
    end
})

TesterSection:Input({
    Title       = "Complete Delay (detik)",
    Content     = "Jeda dari RequestMinigame sampai FishingCompleted (boleh 0, isi ANGKA).",
    Placeholder = tostring(Config.CompleteDelay),
    Callback    = function(v)
        local n = tonumber(v)
        if n then
            Config.CompleteDelay = n
            print("[Tester] CompleteDelay =", n)
        else
            warn("[Tester] Invalid CompleteDelay (angka saja).")
        end
    end
})

TesterSection:Input({
    Title       = "Cancel Delay (detik)",
    Content     = "Jeda dari FishingCompleted sampai CancelInputs (boleh 0, isi ANGKA).",
    Placeholder = tostring(Config.CancelDelay),
    Callback    = function(v)
        local n = tonumber(v)
        if n then
            Config.CancelDelay = n
            print("[Tester] CancelDelay =", n)
        else
            warn("[Tester] Invalid CancelDelay (angka saja).")
        end
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

neverGui = createNeverm1ndGui(parentForNeverm1nd)
toggleButton = neverGui:WaitForChild("main"):WaitForChild("togl")
toggleButton.MouseButton1Click:Connect(function()
    setMainVisible(not uiVisible)
end)

print("[BlatantTester_PureFlow] Script loaded.")
