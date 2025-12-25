-- ========== Delta Mobile - Keyboard UIStroke compat patch ==========
do
local CoreGui = game:GetService("CoreGui")
local function ensureStroke(btn)
if not btn:FindFirstChildOfClass("UIStroke") then
local s = Instance.new("UIStroke")
s.Name = "UIStroke"
s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
s.Color = Color3.fromRGB(255, 255, 255)
s.Transparency = 0.75
s.Thickness = 1
s.Parent = btn
end
end
local function patchKeyboard(root)
for _, d in ipairs(root:GetDescendants()) do
if d:IsA("TextButton") then
ensureStroke(d)
end
end
root.DescendantAdded:Connect(function(d)
if d:IsA("TextButton") then
ensureStroke(d)
end
end)
end
task.spawn(function()
while true do
for _, gui in ipairs(CoreGui:GetChildren()) do
if gui:IsA("ScreenGui") and tostring(gui.Name):lower():find("delta") and tostring(gui.Name):lower():find("keyboard") then
patchKeyboard(gui)
return
end
end
task.wait(1)
end
end)
end

-- ========== Services/Remotes ==========
repeat task.wait() until game:IsLoaded()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local net = ReplicatedStorage:WaitForChild("Packages")
:WaitForChild("_Index")
:WaitForChild("sleitnick_net@0.2.0")
:WaitForChild("net")

local Remotes = {
equip = net:WaitForChild("RE/EquipToolFromHotbar"),
unequip = net:FindFirstChild("RE/UnequipToolFromHotbar"),
charge = net:WaitForChild("RF/ChargeFishingRod"),
minigame = net:WaitForChild("RF/RequestFishingMinigameStarted"),
finish = net:WaitForChild("RE/FishingCompleted"),
cancel = net:WaitForChild("RF/CancelFishingInputs"),
}

-- ========== Pure Lynxx Blatant tester core (timer only) ==========
local cfg = {
hotbarSlot = 1,
chargeWait = 0.05,
recastDelay = 0.18,
completeDelay = 0.00,
cancelDelay = 0.00,
}

local running = false
local cycleId = 0

local function invokeCharge(ts)
local ok = pcall(function() Remotes.charge:InvokeServer(ts) end)
if ok then return true end
return pcall(function() Remotes.charge:InvokeServer({ ts }) end)
end

local function invokeMinigame(x, y, ts)
local ok3 = pcall(function() Remotes.minigame:InvokeServer(x, y, ts) end)
if ok3 then return true end
return pcall(function() Remotes.minigame:InvokeServer(x, y) end)
end

local function oneCycle()
cycleId += 1
-- equip
pcall(function() Remotes.equip:FireServer(cfg.hotbarSlot) end)
task.wait(0.08)

text

-- charge
local tCharge = workspace:GetServerTimeNow()
invokeCharge(tCharge)
if cfg.chargeWait > 0 then task.wait(cfg.chargeWait) end

-- minigame (Cobalt sample vector 1,0)
local tMini = workspace:GetServerTimeNow()
invokeMinigame(1, 0, tMini)

-- complete -> cancel (lynxx style delays)
if cfg.completeDelay > 0 then task.wait(cfg.completeDelay) end
pcall(function() Remotes.finish:FireServer() end)

if cfg.cancelDelay > 0 then task.wait(cfg.cancelDelay) end
pcall(function() Remotes.cancel:InvokeServer() end)
end

local function startLoop(onNotify)
if running then return end
running = true
cycleId = 0
if onNotify then onNotify("Started (pure Lynxx flow)") end
task.spawn(function()
while running do
oneCycle()
task.wait(cfg.recastDelay)
end
end)
end

local function stopLoop(onNotify)
if not running then return end
running = false
pcall(function() if Remotes.unequip then Remotes.unequip:FireServer() end end)
if onNotify then onNotify("Stopped") end
end

-- ========== UI builder (Atomic MacLib first, fallback simple UI) ==========
local function safeNumber(s)
local n = tonumber(s)
if not n then return nil end
return math.max(0, n)
end

local function buildWithMacLib(MacLib)
local Window = MacLib:Window({
Title = "Atomic - Blatant Tester (Lynxx)",
Subtitle = "pure timer flow",
Size = UDim2.fromOffset(720, 480),
DragStyle = 2,
ShowUserInfo = false,
Keybind = Enum.KeyCode.RightControl,
})

text

local TG = Window:TabGroup()
local Tab = TG:Tab({ Name = "Blatant Tester", Image = "zap" })

local SecL = Tab:Section({ Side = "Left" })
SecL:Header({ Name = "Pure Lynxx Flow (Charge → Minigame → Complete → Cancel)" })

SecL:Toggle({
    Name = "Start Blatant Tester",
    Default = false,
    Callback = function(v)
        if v then
            startLoop(function(msg)
                Window:Notify({ Title = "Blatant Tester", Description = msg, Lifetime = 3 })
            end)
        else
            stopLoop(function(msg)
                Window:Notify({ Title = "Blatant Tester", Description = msg, Lifetime = 2 })
            end)
        end
    end
}, "BT_Start")

SecL:Input({
    Name = "Complete Delay (s)",
    Placeholder = "0.00",
    AcceptedCharacters = "Numeric",
    Default = "0.00",
    Callback = function(text)
        local n = safeNumber(text)
        if n then
            cfg.completeDelay = n
            Window:Notify({ Title = "Blatant Tester", Description = ("Complete Delay = %.3f"):format(cfg.completeDelay), Lifetime = 2 })
        else
            Window:Notify({ Title = "Invalid", Description = "Complete Delay harus angka", Lifetime = 2 })
        end
    end
}, "BT_CompleteDelay")

SecL:Input({
    Name = "Cancel Delay (s)",
    Placeholder = "0.00",
    AcceptedCharacters = "Numeric",
    Default = "0.00",
    Callback = function(text)
        local n = safeNumber(text)
        if n then
            cfg.cancelDelay = n
            Window:Notify({ Title = "Blatant Tester", Description = ("Cancel Delay = %.3f"):format(cfg.cancelDelay), Lifetime = 2 })
        else
            Window:Notify({ Title = "Invalid", Description = "Cancel Delay harus angka", Lifetime = 2 })
        end
    end
}, "BT_CancelDelay")

local SecR = Tab:Section({ Side = "Right" })
SecR:Header({ Name = "Advanced (opsional)" })

SecR:Input({
    Name = "Recast Delay (s) [default 0.18]",
    Placeholder = "0.18",
    AcceptedCharacters = "Numeric",
    Default = "0.18",
    Callback = function(text)
        local n = safeNumber(text)
        if n then
            cfg.recastDelay = n
            Window:Notify({ Title = "Blatant Tester", Description = ("Recast Delay = %.3f"):format(cfg.recastDelay), Lifetime = 2 })
        end
    end
}, "BT_RecastDelay")

SecR:Input({
    Name = "Charge Wait (s) [default 0.05]",
    Placeholder = "0.05",
    AcceptedCharacters = "Numeric",
    Default = "0.05",
    Callback = function(text)
        local n = safeNumber(text)
        if n then
            cfg.chargeWait = n
            Window:Notify({ Title = "Blatant Tester", Description = ("Charge Wait = %.3f"):format(cfg.chargeWait), Lifetime = 2 })
        end
    end
}, "BT_ChargeWait")

Tab:Select()
Window:Notify({
    Title = "Atomic - Blatant Tester",
    Description = "Set Complete/Cancel Delay seperti UI Lynxx, lalu Start.",
    Lifetime = 4
})
end

local function buildSimpleFallback()
local CoreGui = game:GetService("CoreGui")
local sg = Instance.new("ScreenGui")
sg.Name = "BlatantTesterFallback"
sg.IgnoreGuiInset = true
sg.ResetOnSpawn = false
sg.Parent = CoreGui

text

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(300, 180)
frame.Position = UDim2.fromOffset(20, 220)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
frame.Parent = sg

local uic = Instance.new("UICorner", frame); uic.CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -10, 0, 26)
title.Position = UDim2.fromOffset(10, 8)
title.BackgroundTransparency = 1
title.Text = "Blatant Tester (Fallback)"
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local function makeInput(lbl, y, default, onSet)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.fromOffset(140, 24)
    l.Position = UDim2.fromOffset(10, y)
    l.BackgroundTransparency = 1
    l.Text = lbl
    l.TextColor3 = Color3.new(1,1,1)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.fromOffset(120, 24)
    box.Position = UDim2.fromOffset(170, y)
    box.BackgroundColor3 = Color3.fromRGB(55,55,65)
    box.Text = default
    box.TextColor3 = Color3.new(1,1,1)
    box.Parent = frame
    local c = Instance.new("UICorner", box); c.CornerRadius = UDim.new(0,6)

    box.FocusLost:Connect(function()
        onSet(box.Text)
    end)
end

makeInput("Complete Delay (s)", 40, "0.00", function(text)
    local n = safeNumber(text)
    if n then cfg.completeDelay = n end
end)
makeInput("Cancel Delay (s)", 70, "0.00", function(text)
    local n = safeNumber(text)
    if n then cfg.cancelDelay = n end
end)
makeInput("Recast Delay (s)", 100, "0.18", function(text)
    local n = safeNumber(text)
    if n then cfg.recastDelay = n end
end)
makeInput("Charge Wait (s)", 130, "0.05", function(text)
    local n = safeNumber(text)
    if n then cfg.chargeWait = n end
end)

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.fromOffset(130, 26)
startBtn.Position = UDim2.fromOffset(10, 155)
startBtn.BackgroundColor3 = Color3.fromRGB(90, 160, 90)
startBtn.Text = "Start"
startBtn.TextColor3 = Color3.new(1,1,1)
startBtn.Parent = frame
local c1 = Instance.new("UICorner", startBtn); c1.CornerRadius = UDim.new(0,6)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.fromOffset(130, 26)
stopBtn.Position = UDim2.fromOffset(160, 155)
stopBtn.BackgroundColor3 = Color3.fromRGB(160, 90, 90)
stopBtn.Text = "Stop"
stopBtn.TextColor3 = Color3.new(1,1,1)
stopBtn.Parent = frame
local c2 = Instance.new("UICorner", stopBtn); c2.CornerRadius = UDim.new(0,6)

startBtn.MouseButton1Click:Connect(function()
    startLoop(function(msg) print("[Blatant Tester]", msg) end)
end)
stopBtn.MouseButton1Click:Connect(function()
    stopLoop(function(msg) print("[Blatant Tester]", msg) end)
end)
end

-- ========== Decide which UI to use ==========
local MacLib = rawget(getfenv(), "MacLib") or _G.MacLib or shared.MacLib
-- Catatan: kalau kamu paste file MacLib yang kamu kirim barusan lalu langsung return MacLib,
-- jalankan script ini SETELAH MacLib dieksekusi, atau gabungkan jadi satu file dan set MacLib ke _G.MacLib = MacLib

if typeof(MacLib) == "table" and MacLib.Window then
buildWithMacLib(MacLib)
else
warn("[Blatant Tester] MacLib tidak terdeteksi. Menggunakan UI fallback sederhana.")
buildSimpleFallback()
end

-- Selesai.
