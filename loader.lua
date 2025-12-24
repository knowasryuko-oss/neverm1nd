-- =========================================================
-- RIDE AUTO FISHING GAME + SUPER INSTANT '!'
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
-- NET / REMOTE (sleitnick_net)
-----------------------
local net = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

local Events = {
    finish     = net:WaitForChild("RE/FishingCompleted"),
    textEffect = net:WaitForChild("RE/ReplicateTextEffect"),
    updateAuto = net:WaitForChild("RF/UpdateAutoFishingState"),
    equipRod   = net:FindFirstChild("RE/EquipToolFromHotbar"), -- opsional
}

-----------------------
-- CONFIG
-----------------------
local Config = {
    RideAutoFishing = false, -- toggle utama
    SuperInstant    = 0.001, -- delay setelah '!' sebelum FishingCompleted
    BurstCount      = 3,     -- berapa kali FishingCompleted setelah '!'
    BurstGap        = 0.03,  -- jeda antar FishingCompleted di dalam burst
}

-----------------------
-- ANTI AFK
-----------------------
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-----------------------
-- STATE
-----------------------
local AutoCatchEnabled = false

local function getSuperInstant()
    local base = tonumber(Config.SuperInstant) or 0.001
    if base < 0 then base = 0 end
    return base
end

-----------------------
-- HOOK TANDA '!' DARI SERVER
-----------------------
Events.textEffect.OnClientEvent:Connect(function(data)
    if not AutoCatchEnabled then return end
    if not data or not data.TextData then return end
    if data.TextData.EffectType ~= "Exclaim" then return end -- hanya '!' 

    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head or data.Container ~= head then return end

    -- SuperInstantDelay berbasis setting
    local delay = getSuperInstant()
    local burst = tonumber(Config.BurstCount) or 1
    local gap   = tonumber(Config.BurstGap) or 0.03

    if burst < 1 then burst = 1 end

    task.spawn(function()
        if delay > 0 then
            task.wait(delay)
        end

        for i = 1, burst do
            pcall(function()
                Events.finish:FireServer()
            end)
            if gap > 0 and i < burst then
                task.wait(gap)
            end
        end
    end)
end)

-----------------------
-- RIDE AUTO FISHING (ON/OFF)
-----------------------
local function StartRide()
    AutoCatchEnabled = true

    -- ON auto fishing bawaan game (server yang urus cast/minigame)
    pcall(function()
        Events.updateAuto:InvokeServer(true)
    end)

    -- pastikan rod di-equip (opsional)
    pcall(function()
        if Events.equipRod then
            Events.equipRod:FireServer(1) -- slot 1
        end
    end)
end

local function StopRide()
    AutoCatchEnabled = false

    pcall(function()
        Events.updateAuto:InvokeServer(false)
    end)
end

-----------------------
-- WINDUI WINDOW
-----------------------
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title  = "Ride AutoFishing • Super Instant",
    Icon   = "fish",
    Author = "by YOU",
    Folder = "RideAutoFishing_SuperInstant",
    Size   = UDim2.fromOffset(500, 260),
    Theme  = "Indigo",
    KeySystem = false
})

WindUI:SetNotificationLower(true)
WindUI:Notify({
    Title   = "Loaded",
    Content = "Ride AutoFishing siap. Equip pancing, lalu ON untuk menunggangi auto bawaan game + Super Instant '!'.",
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
            if inst:IsA("TextLabel") and tostring(inst.Text):find("Ride AutoFishing") then
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

local RideSection = MainTab:Section({
    Title = "Ride AutoFishing • Super Instant",
    Icon  = "fish"
})

RideSection:Toggle({
    Title   = "Ride Auto Fishing (Game)",
    Content = "ON: UpdateAutoFishingState(true) → game yang urus lempar + minigame.\n" ..
              "Script hanya tarik ikan super cepat setelah tanda '!' muncul.\n" ..
              "OFF: UpdateAutoFishingState(false).",
    Value   = Config.RideAutoFishing,
    Callback = function(v)
        Config.RideAutoFishing = v
        if v then
            StartRide()
        else
            StopRide()
        end
        print("[RideAutoFishing] =", v)
    end
})

RideSection:Input({
    Title       = "Super Instant Delay (detik)",
    Content     = "Jeda setelah tanda '!' sebelum FishingCompleted burst. Bisa 0 / 0.001 / 0.01, dst.",
    Placeholder = tostring(Config.SuperInstant),
    Callback    = function(v)
        local n = tonumber(v)
        if n ~= nil and n >= 0 then
            Config.SuperInstant = n
            print("[Config] SuperInstant =", n)
        else
            warn("[Config] Invalid SuperInstant (angka >= 0).")
        end
    end
})

RideSection:Input({
    Title       = "Burst Count",
    Content     = "Berapa kali FishingCompleted setelah tiap '!'. (1 - 10 dianjurkan)",
    Placeholder = tostring(Config.BurstCount),
    Callback    = function(v)
        local n = tonumber(v)
        if n and n >= 1 then
            Config.BurstCount = math.floor(n)
            print("[Config] BurstCount =", Config.BurstCount)
        else
            warn("[Config] Invalid BurstCount (>=1).")
        end
    end
})

RideSection:Input({
    Title       = "Burst Gap (detik)",
    Content     = "Jeda antar FishingCompleted di dalam burst. 0 - 0.1 biasa cukup.",
    Placeholder = tostring(Config.BurstGap),
    Callback    = function(v)
        local n = tonumber(v)
        if n ~= nil and n >= 0 then
            Config.BurstGap = n
            print("[Config] BurstGap =", n)
        else
            warn("[Config] Invalid BurstGap (>=0).")
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

    local ImageLabel6 = Instance.new("ImageLabel")
    ImageLabel6.Name = "imege"
    ImageLabel6.BackgroundTransparency = 1
    ImageLabel6.BorderSizePixel = 0
    ImageLabel6.AnchorPoint = Vector2.new(0.5, 0.5)
    ImageLabel6.Position    = UDim2.new(0.5, 0, 0.5, 0)
    ImageLabel6.Size        = UDim2.new(1, -6, 1, -6)
    ImageLabel6.Image       = "rbxassetid://100651748260650"
    ImageLabel6.ScaleType   = Enum.ScaleType.Fit
    ImageLabel6.Parent      = Frame1

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

    local TextButton7 = Instance.new("TextButton")
    TextButton7.Name = "togl"
    TextButton7.Size = UDim2.new(0, 55, 0, 55)
    TextButton7.BackgroundTransparency = 1
    TextButton7.BorderSizePixel = 0
    TextButton7.TextTransparency = 1
    TextButton7.ZIndex = 9999999
    TextButton7.Parent = Frame1

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

print("[RideAutoFishing_SuperInstant] Script loaded.")
