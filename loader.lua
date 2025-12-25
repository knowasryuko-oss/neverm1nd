-- Pure Blatant Tester (Lynxx flow) + minimal WindUI
-- No Exclaim / no extra modules, just charge -> minigame -> complete -> cancel

-- load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- net remotes
local function getNet()
local pkg = ReplicatedStorage:WaitForChild("Packages")
:WaitForChild("_Index")
:WaitForChild("sleitnick_net@0.2.0")
return pkg:WaitForChild("net")
end

local net = getNet()
local Remotes = {
equip = net:WaitForChild("RE/EquipToolFromHotbar"),
unequip = net:FindFirstChild("RE/UnequipToolFromHotbar"),
charge = net:WaitForChild("RF/ChargeFishingRod"),
minigame = net:WaitForChild("RF/RequestFishingMinigameStarted"),
finish = net:WaitForChild("RE/FishingCompleted"),
cancel = net:WaitForChild("RF/CancelFishingInputs"),
}

-- helpers
local function clamp(n, lo, hi)
if n < lo then return lo end
if n > hi then return hi end
return n
end

local function jitter(range)
return (math.random() * 2 - 1) * range
end

-- config (lynxx-style)
local cfg = {
hotbarSlot = 1,
perfectCast = true, -- true = near-perfect coords; false = random
jitterRange = 0.00005, -- kecil biar gak kaku kaku amat
chargeWait = 0.05, -- jeda kecil setelah charge sebelum minigame
recastDelay = 0.18, -- jeda antar siklus

text

completeDelay = 0.00,      -- UI: delay sebelum FishingCompleted
cancelDelay   = 0.00,      -- UI: delay sebelum CancelFishingInputs
}

local running = false

local function computeCastVector()
if cfg.perfectCast then
local baseX, baseY = -0.7499996423721313, 1
local x = clamp(baseX + jitter(cfg.jitterRange), -1, 1)
local y = clamp(baseY + jitter(cfg.jitterRange), 0, 1)
return x, y
else
local x = math.random(-1000, 1000) / 1000
local y = math.random(0, 1000) / 1000
return clamp(x, -1, 1), clamp(y, 0, 1)
end
end

-- support charge number/table + minigame 3/2 args (sesuai cobalt/lynxx)
local function invokeCharge(ts)
local ok = pcall(function() Remotes.charge:InvokeServer(ts) end)
if ok then return true end
return pcall(function() Remotes.charge:InvokeServer({ ts }) end)
end

local function invokeMinigame(x, y, ts)
local ok = pcall(function() Remotes.minigame:InvokeServer(x, y, ts) end)
if ok then return true end
return pcall(function() Remotes.minigame:InvokeServer(x, y) end)
end

local function oneCycle()
-- equip
pcall(function()
Remotes.equip:FireServer(cfg.hotbarSlot)
end)
task.wait(0.08)

text

-- charge (pakai server time)
local ts = workspace:GetServerTimeNow()
invokeCharge(ts)
if cfg.chargeWait > 0 then task.wait(cfg.chargeWait) end

-- minigame (x,y,[ts])
local x, y = computeCastVector()
invokeMinigame(x, y, ts)

-- complete -> cancel (lynxx delays)
if cfg.completeDelay > 0 then task.wait(cfg.completeDelay) end
pcall(function()
    Remotes.finish:FireServer()
end)

if cfg.cancelDelay > 0 then task.wait(cfg.cancelDelay) end
pcall(function()
    Remotes.cancel:InvokeServer()
end)
end

local function startLoop()
if running then return end
running = true
task.spawn(function()
WindUI:Notify({ Title = "Blatant Tester", Content = "Started (pure Lynxx flow)", Duration = 3, Icon = "circle-check" })
while running do
oneCycle()
task.wait(cfg.recastDelay)
end
end)
end

local function stopLoop()
running = false
pcall(function()
if Remotes.unequip then Remotes.unequip:FireServer() end
end)
WindUI:Notify({ Title = "Blatant Tester", Content = "Stopped", Duration = 2, Icon = "square" })
end

-- UI (WindUI) — 1 tab, 1 fitur
local Window = WindUI:CreateWindow({
Title = "Blatant Tester (Lynxx)",
Icon = "fish",
Author = "debug build",
Folder = "BlatantTesterLynxx",
Size = UDim2.fromOffset(520, 360),
Theme = "Indigo",
KeySystem = false
})

Window:SetToggleKey(Enum.KeyCode.G)
WindUI:SetNotificationLower(true)

local Tab = Window:Tab({
Title = "Blatant",
Icon = "zap"
})

local Section = Tab:Section({
Title = "Core",
Icon = "settings"
})

Section:Toggle({
Title = "Start Blatant Tester",
Content = "Pure timer: Charge → Minigame → Complete → Cancel",
Callback = function(v)
if v then startLoop() else stopLoop() end
end
})

-- Delays ala UI Lynxx (0.00 default)
Section:Input({
Title = "Complete Delay (s)",
Content = "Default 0.00",
Placeholder = "0.00",
Callback = function(value)
local n = tonumber(value)
if n then
cfg.completeDelay = math.max(0, n)
WindUI:Notify({ Title = "Set", Content = "Complete Delay = " .. string.format("%.3f", cfg.completeDelay), Duration = 2, Icon = "circle-check" })
else
WindUI:Notify({ Title = "Error", Content = "Invalid number", Duration = 2, Icon = "ban" })
end
end
})

Section:Input({
Title = "Cancel Delay (s)",
Content = "Default 0.00",
Placeholder = "0.00",
Callback = function(value)
local n = tonumber(value)
if n then
cfg.cancelDelay = math.max(0, n)
WindUI:Notify({ Title = "Set", Content = "Cancel Delay = " .. string.format("%.3f", cfg.cancelDelay), Duration = 2, Icon = "circle-check" })
else
WindUI:Notify({ Title = "Error", Content = "Invalid number", Duration = 2, Icon = "ban" })
end
end
})

-- Opsional util minim buat debug siklus
Section:Input({
Title = "Recast Delay (s)",
Content = "Default 0.18",
Placeholder = "0.18",
Callback = function(value)
local n = tonumber(value)
if n then
cfg.recastDelay = math.max(0, n)
WindUI:Notify({ Title = "Set", Content = "Recast Delay = " .. string.format("%.3f", cfg.recastDelay), Duration = 2, Icon = "circle-check" })
else
WindUI:Notify({ Title = "Error", Content = "Invalid number", Duration = 2, Icon = "ban" })
end
end
})

Section:Input({
Title = "Hotbar Slot",
Content = "Default 1",
Placeholder = "1",
Callback = function(value)
local n = tonumber(value)
if n and n >= 1 then
cfg.hotbarSlot = math.floor(n)
WindUI:Notify({ Title = "Set", Content = "Hotbar Slot = " .. cfg.hotbarSlot, Duration = 2, Icon = "circle-check" })
else
WindUI:Notify({ Title = "Error", Content = "Invalid slot", Duration = 2, Icon = "ban" })
end
end
})

Section:Toggle({
Title = "Perfect Cast",
Content = "Gunakan koordinat near-perfect (x≈-0.75, y=1)",
Value = true,
Callback = function(v)
cfg.perfectCast = v
WindUI:Notify({ Title = "Cast Mode", Content = v and "Perfect" or "Random", Duration = 2, Icon = "info" })
end
})

-- (Opsional) charge wait kecil supaya konsisten
Section:Input({
Title = "Charge Wait (s)",
Content = "Delay kecil setelah charge (default 0.05)",
Placeholder = "0.05",
Callback = function(value)
local n = tonumber(value)
if n then
cfg.chargeWait = math.max(0, n)
WindUI:Notify({ Title = "Set", Content = "Charge Wait = " .. string.format("%.3f", cfg.chargeWait), Duration = 2, Icon = "circle-check" })
else
WindUI:Notify({ Title = "Error", Content = "Invalid number", Duration = 2, Icon = "ban" })
end
end
})

WindUI:Notify({
Title = "Blatant Tester",
Content = "Loaded. Set delay, lalu Start.",
Duration = 4,
Icon = "circle-check"
})
