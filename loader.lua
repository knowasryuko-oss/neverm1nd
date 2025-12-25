repeat task.wait() until game:IsLoaded()

-- Load WindUI (ZiaanHub style)
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
if not WindUI then error("WindUI failed to load") end

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Net remotes
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

-- Window: 1 fitur saja (Blatant Tester)
local Window = WindUI:CreateWindow({
Title = "ZiaanHub - Blatant Tester (Lynxx)",
Icon = "fish",
Author = "debug build",
Folder = "ZiaanHub_BlatantTester",
Size = UDim2.fromOffset(600, 360),
Theme = "Indigo",
KeySystem = false
})
Window:SetToggleKey(Enum.KeyCode.G)
WindUI:SetNotificationLower(true)

local Tab = Window:Tab({ Title = "Blatant Tester", Icon = "zap" })
local Section = Tab:Section({ Title = "Fishing Blatant (Pure Lynxx)", Icon = "fish" })

-- Config (ala Lynxx)
local cfg = {
hotbarSlot = 1, -- slot rod
chargeWait = 0.05, -- jeda kecil setelah charge sebelum minigame
recastDelay = 0.18, -- jeda antar siklus

text

completeDelay = 0.00,     -- delay sebelum RE/FishingCompleted
cancelDelay   = 0.00,     -- delay sebelum RF/CancelFishingInputs

castMode      = "Cobalt", -- "Cobalt", "Perfect", "Random"
jitterRange   = 0.00005,  -- untuk Perfect
verbose       = false     -- log detail F9
}

-- Helpers
local function clamp(n, lo, hi)
if n < lo then return lo end
if n > hi then return hi end
return n
end

local function jitter(range)
return (math.random() * 2 - 1) * range
end

local function computeCastXY()
if cfg.castMode == "Cobalt" then
-- persis sample Cobalt
return 1, 0
elseif cfg.castMode == "Perfect" then
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

-- Support charge number/table + minigame 3/2 args
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

-- Core loop
local running = false
local cycleId = 0

local function oneCycle()
cycleId += 1
local tag = "[BT][" .. cycleId .. "]"

text

-- Equip
pcall(function() Remotes.equip:FireServer(cfg.hotbarSlot) end)
task.wait(0.08)

-- Charge (server time)
local tCharge = workspace:GetServerTimeNow()
invokeCharge(tCharge)
if cfg.chargeWait > 0 then task.wait(cfg.chargeWait) end

-- Minigame (x,y,[ts])
local x, y = computeCastXY()
local tMini = workspace:GetServerTimeNow()
invokeMinigame(x, y, tMini)

-- Log ala Lynxx
local delta = tMini - tCharge
if cfg.verbose then
    print(tag, string.format("ChargeΔ=%.3fs | XY=(%.6f, %.6f) | complete=%.3f | cancel=%.3f",
        delta, x, y, cfg.completeDelay, cfg.cancelDelay))
else
    print(string.format("%s Charge Δ: %.3fs", tag, delta))
end

-- Complete → Cancel
if cfg.completeDelay > 0 then task.wait(cfg.completeDelay) end
pcall(function() Remotes.finish:FireServer() end)

if cfg.cancelDelay > 0 then task.wait(cfg.cancelDelay) end
pcall(function() Remotes.cancel:InvokeServer() end)
end

local function startLoop()
if running then return end
running = true
cycleId = 0
WindUI:Notify({ Title = "Blatant Tester", Content = "Started (pure Lynxx flow)", Duration = 3, Icon = "circle-check" })
task.spawn(function()
while running do
oneCycle()
task.wait(cfg.recastDelay)
end
end)
end

local function stopLoop()
if not running then return end
running = false
pcall(function() if Remotes.unequip then Remotes.unequip:FireServer() end end)
WindUI:Notify({ Title = "Blatant Tester", Content = "Stopped", Duration = 2, Icon = "square" })
end

-- UI controls (cuma 1 fitur)
Section:Toggle({
Title = "Start Blatant Tester",
Content = "Charge → Minigame → Complete → Cancel (timer-only)",
Callback = function(v)
if v then startLoop() else stopLoop() end
end
})

Section:Input({
Title = "Complete Delay (s)",
Content = "Default 0.00 (UI Lynxx)",
Placeholder = "0.00",
Callback = function(value)
local n = tonumber(value)
if n then
cfg.completeDelay = math.max(0, n)
WindUI:Notify({ Title = "Set", Content = ("Complete Delay = %.3f"):format(cfg.completeDelay), Duration = 2, Icon = "circle-check" })
else
WindUI:Notify({ Title = "Error", Content = "Invalid number", Duration = 2, Icon = "ban" })
end
end
})

Section:Input({
Title = "Cancel Delay (s)",
Content = "Default 0.00 (UI Lynxx)",
Placeholder = "0.00",
Callback = function(value)
local n = tonumber(value)
if n then
cfg.cancelDelay = math.max(0, n)
WindUI:Notify({ Title = "Set", Content = ("Cancel Delay = %.3f"):format(cfg.cancelDelay), Duration = 2, Icon = "circle-check" })
else
WindUI:Notify({ Title = "Error", Content = "Invalid number", Duration = 2, Icon = "ban" })
end
end
})

Section:Input({
Title = "Recast Delay (s)",
Content = "Default 0.18",
Placeholder = "0.18",
Callback = function(value)
local n = tonumber(value)
if n then
cfg.recastDelay = math.max(0, n)
WindUI:Notify({ Title = "Set", Content = ("Recast Delay = %.3f"):format(cfg.recastDelay), Duration = 2, Icon = "circle-check" })
else
WindUI:Notify({ Title = "Error", Content = "Invalid number", Duration = 2, Icon = "ban" })
end
end
})

Section:Input({
Title = "Charge Wait (s)",
Content = "Default 0.05",
Placeholder = "0.05",
Callback = function(value)
local n = tonumber(value)
if n then
cfg.chargeWait = math.max(0, n)
WindUI:Notify({ Title = "Set", Content = ("Charge Wait = %.3f"):format(cfg.chargeWait), Duration = 2, Icon = "circle-check" })
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

Section:Dropdown({
Title = "Cast Mode",
Content = "Koordinat minigame",
Values = { "Cobalt", "Perfect", "Random" },
Callback = function(v)
cfg.castMode = v
WindUI:Notify({ Title = "Cast Mode", Content = "Mode: " .. v, Duration = 2, Icon = "info" })
end
})

Section:Toggle({
Title = "Verbose Logs",
Content = "Print detail ke F9",
Value = false,
Callback = function(v)
cfg.verbose = v
WindUI:Notify({ Title = "Verbose", Content = v and "ON" or "OFF", Duration = 2, Icon = "info" })
end
})

WindUI:Notify({
Title = "ZiaanHub - Blatant Tester",
Content = "Loaded. Isi Complete/Cancel Delay (UI Lynxx), pilih Cast Mode, lalu Start.",
Duration = 4,
Icon = "circle-check"
})
