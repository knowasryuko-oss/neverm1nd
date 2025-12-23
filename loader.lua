-- =========================================================
-- BLATANT AUTO FISHING • MIRIP ATOMIC (2 REMOTE SAJA)
-- Remote Outgoing dari script ini:
--   RF/UpdateAutoFishingState (x1 ON, x1 OFF)
--   RE/FishingCompleted (burst x3 berkali-kali)
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

local RF_UpdateAutoFishingState = net:WaitForChild("RF/UpdateAutoFishingState")
local RE_FishingCompleted       = net:WaitForChild("RE/FishingCompleted")
local RE_ReplicateTextEffect    = net:WaitForChild("RE/ReplicateTextEffect") -- incoming, tidak ke server

-----------------------
-- CONFIG
-----------------------
local Config = {
    AutoFishing    = false, -- toggle utama
    SlowReel       = 1.7,   -- dipakai untuk throttle antar burst (mirip "Slow Reel Threshold")
    SuperInstant   = 1.0,   -- delay setelah '!' sebelum burst FishingCompleted
    RandomizeDelay = false, -- acak sedikit SlowReel & SuperInstant
    BurstCount     = 3,     -- berapa kali FishingCompleted per burst (Atomic terlihat x3)
    BurstGap       = 0.03,  -- jeda antar FishingCompleted di dalam burst
    HideMinigameUI = true,  -- sembunyikan bar hijau tap-tap
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
    if base < 0.05 then base = 0.05 end
    if base > 10   then base = 10   end

    if Config.RandomizeDelay then
        local delta = base * 0.3
        base = base + (math.random() * 2 - 1) * delta
        if base < 0.05 then base = 0.05 end
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

task.spawn(function()
    while true do
        pcall(scanAndHideMinigameGui)
        task.wait(0.1)
    end
end)

-----------------------
-- HOOK METAMETHOD: BLOCK REMOTE AUTO FISHING GAME
-----------------------
local BlatantState = { running = false }
local hookEnabled  = false

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if hookEnabled
        and method == "InvokeServer"
        and typeof(self) == "Instance"
        and self:IsA("RemoteFunction")
    then
        local name = self.Name
        -- block remote bawaan auto fishing game
        if name == "RF/ChargeFishingRod"
        or name == "RF/RequestFishingMinigameStarted"
        or name == "RF/CancelFishingInputs" then
            -- jangan diteruskan ke server
            return nil
        end
    end

    return oldNamecall(self, ...)
end)

-----------------------
-- BLATANT CORE (HANYA 2 REMOTE KELUAR)
-----------------------
local lastBurstTime = 0

local function doBurst()
    lastBurstTime = os.clock()
    for i = 1, (Config.BurstCount or 3) do
        pcall(function()
            RE_FishingCompleted:FireServer()
        end)
        task.wait(Config.BurstGap or 0.03)
    end
end

-- Selalu pakai tanda '!' sebagai trigger (tanpa opsi mode lain)
RE_ReplicateTextEffect.OnClientEvent:Connect(function(data)
    if not BlatantState.running then return end
    if not data or not data.TextData then return end
    if data.TextData.EffectType ~= "Exclaim" then return end -- tanda '!'

    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head or data.Container ~= head then return end

    -- throttle pakai SlowReel, supaya tidak nabrak kalau ada spam efek
    local now = os.clock()
    if now - lastBurstTime < getSlowReel() then
        return
    end

    local delay = getSuperInstant()
    task.spawn(function()
        task.wait(delay)
        doBurst()
    end)
end)

local function StartBlatant()
    if BlatantState.running then return end
    BlatantState.running = true
    hookEnabled = true

    -- persis Atomic: UpdateAutoFishingState(true) sekali
    pcall(function()
        RF_UpdateAutoFishingState:InvokeServer(true)
    end)
end

local function StopBlatant()
    BlatantState.running = false
    hookEnabled = false

    pcall(function()
        RF_UpdateAutoFishingState:InvokeServer(false)
    end)
end

-- =========================================================
-- WINDUI WINDOW
-- =========================================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title  = "Auto Fishing Mode • Blatant",
    Icon   = "fish",
    Author = "by YOU",
    Folder = "AtomicBlatantPure",
    Size   = UDim2.fromOffset(500, 320),
    Theme  = "Indigo",
    KeySystem = false
})

WindUI:SetNotificationLower(true)
WindUI:Notify({
    Title   = "Loaded",
    Content = "Blatant Auto Fishing (2 remote, pakai tanda '!') siap.",
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
            if inst:IsA("TextLabel") and tostring(inst.Text):find("Blatant") then
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
-- UI CONTENT (tanpa opsi mode)
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
    Content = "ON: RF/UpdateAutoFishingState(true) + burst RE/FishingCompleted saat '!' muncul.\nOFF: RF/UpdateAutoFishingState(false).",
    Value   = Config.AutoFishing,
    Callback = function(v)
        Config.AutoFishing = v
        if v then
            StartBlatant()
        else
            StopBlatant()
        end
        print("[AutoFishing] =", v)
    end
})

AutoSection:Input({
    Title       = "Slow Reel Threshold (detik)",
    Content     = "Throttle antar burst (0.05 - 10). Semakin kecil, semakin sering ikan.",
    Placeholder = tostring(Config.SlowReel),
    Callback    = function(v)
        local n = tonumber(v)
        if n and n >= 0.05 and n <= 10 then
            Config.SlowReel = n
            print("[Config] SlowReel =", n)
        else
            warn("[Config] Invalid SlowReel (0.05-10)")
        end
    end
})

AutoSection:Input({
    Title       = "Super Instant Delay (detik)",
    Content     = "Jeda setelah '!' sebelum burst FishingCompleted (0.001 - 10).",
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

AutoSection:Input({
    Title       = "Burst Count",
    Content     = "Jumlah RE/FishingCompleted per burst (1 - 10). Atomic biasanya 3.",
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
    Title       = "Burst Gap (detik)",
    Content     = "Jeda antar FishingCompleted di dalam burst (0 - 0.2).",
    Placeholder = tostring(Config.BurstGap),
    Callback    = function(v)
        local n = tonumber(v)
        if n and n >= 0 and n <= 0.2 then
            Config.BurstGap = n
            print("[Config] BurstGap =", Config.BurstGap)
        else
            warn("[Config] Invalid BurstGap (0-0.2)")
        end
    end
})

AutoSection:Toggle({
    Title   = "Hide Minigame UI",
    Content = "Sembunyikan bar 'Klik Cepat!' di layar (visual saja).",
    Value   = Config.HideMinigameUI,
    Callback = function(v)
        Config.HideMinigameUI = v
    end
})

-- =========================================================
-- NEVERM1ND FLOATING BUTTON (sama seperti sebelumnya)
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

print("[Blatant2Remote+Hook+ExclaimOnly] Script loaded.")
