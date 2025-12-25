-- Pure Blatant Tester (Lynxx flow) + WindUI (Ziaan style) + Verbose logs + Zero Jitter option
repeat task.wait() until game:IsLoaded()

-- Load WindUI persis gaya ZiaanHub
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
if not WindUI then error("WindUI failed to load") end

-- Services & player
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

-- Window (UI ZiaanHub vibe)
local Window = WindUI:CreateWindow({
Title = "ZiaanHub - Blatant Tester (Lynxx)",
Icon = "fish",
Author = "debug build",
Folder = "ZiaanHub_BlatantTester",
Size = UDim2.fromOffset(600, 420),
Theme = "Indigo",
KeySystem = false
})
Window:SetToggleKey(Enum.KeyCode.G)
WindUI:SetNotificationLower(true)

local Tab = Window:Tab({ Title = "Blatant Tester", Icon = "zap" })
local Section = Tab:Section({ Title = "Fishing Blatant (Pure Lynxx)", Icon = "fish" })

-- Config
local cfg = {
hotbarSlot = 1,
recastDelay = 0.18, -- jeda antar siklus
chargeWait = 0.05, -- delay kecil setelah charge sebelum minigame

text

completeDelay = 0.00,     -- delay sebelum FishingCompleted
cancelDelay   = 0.00,     -- delay sebelum CancelFishingInputs

castMode      = "Cobalt", -- "Cobalt", "Perfect", "Random"
jitterRange   = 0.00005,  -- untuk Perfect mode
zeroJitter    = false,    -- kalau true + Perfect: x=-0.75,y=1 tanpa jitter

verbose       = false     -- print log detail ke F9
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
return 1, 0
elseif cfg.castMode == "Perfect" then
local baseX, baseY = -0.7499996423721313, 1
if cfg.zeroJitter then
return baseX, baseY
else
local x = clamp(baseX + jitter(cfg.jitterRange), -1, 1)
local y = clamp(baseY + jitter(cfg.jitterRange), 0, 1)
return x, y
end
else
local x = math.random(-1000, 1000) / 1000
local y = math.random(0, 1000) / 1000
return clamp(x, -1, 1), clamp(y, 0, 1)
end
end

-- Support charge number/table + minigame 3/2 args (cocok cobalt/lynxx)
local function invokeCharge(ts)
local ok, err = pcall(function() Remotes.charge:InvokeServer(ts) end)
if ok then return true end
local okTbl = pcall(function() Remotes.charge:InvokeServer({ ts }) end)
return okTbl
end

local function invokeMinigame(x, y, ts)
local ok3 = pcall(function() Remotes.minigame:InvokeServer(x, y, ts) end)
if ok3 then return true end
local ok2 = pcall(function() Remotes.minigame:InvokeServer(x, y) end)
return ok2
end

-- Core
local running = false
local cycleCount = 0

local function oneCycle()
cycleCount += 1
local label = string.format("[BT][%d]", cycleCount)

text

-- Equip
local okEquip = pcall(function() Remotes.equip:FireServer(cfg.hotbarSlot) end)
if cfg.verbose then
    print(label, "Equip slot:", cfg.hotbarSlot, okEquip and "OK" or "ERR")
end
task.wait(0.08)

-- Charge (server time)
local tCharge = workspace:GetServerTimeNow()
local okCharge = invokeCharge(tCharge)
if cfg.verbose then
    print(label, "Charge ts:", string.format("%.3f", tCharge), okCharge and "OK" or "ERR")
end
if cfg.chargeWait > 0 then task.wait(cfg.chargeWait) end

-- Minigame
local x, y = computeCastXY()
local tMini = workspace:GetServerTimeNow()
local okMini = invokeMinigame(x, y, tMini)
if cfg.verbose then
    print(label, "Minigame ts:", string.format("%.3f", tMini), okMini and "OK" or "ERR")
    print(label, "XY:", string.format("%.6f", x), string.format("%.6f", y))
    print(label, "Charge Δ:", string.format("%.3fs", (tMini - tCharge)))
    print(label, "Delays: complete=", cfg.completeDelay, " cancel=", cfg.cancelDelay)
else
    -- minimal log ala lynxx charge delta
    print(string.format("%s Charge Δ: %.3fs", label, (tMini - tCharge)))
end

-- Complete
if cfg.completeDelay > 0 then task.wait(cfg.completeDelay) end
local okFinish = pcall(function() Remotes.finish:FireServer() end)
if cfg.verbose then
    print(label, "Finish:", okFinish and "OK" or "ERR")
end

-- Cancel
if cfg.cancelDelay > 0 then task.wait(cfg.cancelDelay) end
local okCancel = pcall(function() Remotes.cancel:InvokeServer() end)
if cfg.verbose then
    print(label, "Cancel:", okCancel and "OK" or "ERR")
end
end

local function startLoop()
if running then return end
running = true
cycleCount = 0
WindUI:Notify({ Title = "Blatant Tester", Content = "Started (pure Lynxx flow)", Duration = 3, Icon = "circle-check" })

text

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
pcall(function()
if Remotes.unequip then Remotes.unequip:FireServer() end
end)
WindUI:Notify({ Title = "Blatant Tester", Content = "Stopped", Duration = 2, Icon = "square" })
end

-- UI controls
Section:Toggle({
Title = "Start Blatant Tester",
Content = "Charge → Minigame → Complete → Cancel (timer-only)",
Callback = function(v)
if v then startLoop() else stopLoop() end
end
})

Section:Dropdown({
Title = "Cast Mode",
Content = "Pilih koordinat cast",
Values = { "Cobalt", "Perfect", "Random" },
Callback = function(v)
cfg.castMode = v
WindUI:Notify({ Title = "Cast Mode", Content = "Mode: " .. v, Duration = 2, Icon = "info" })
end
})

Section:Toggle({
Title = "Zero Jitter (Perfect only)",
Content = "x=-0.75, y=1 tanpa jitter",
Value = false,
Callback = function(v)
cfg.zeroJitter = v
WindUI:Notify({ Title = "Perfect jitter", Content = v and "OFF jitter" or "ON jitter", Duration = 2, Icon = "info" })
end
})

Section:Toggle({
Title = "Verbose Logs",
Content = "Print log detail ke F9",
Value = false,
Callback = function(v)
cfg.verbose = v
WindUI:Notify({ Title = "Verbose", Content = v and "ON" or "OFF", Duration = 2, Icon = "info" })
end
})

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

Section:Button({
Title = "Run One Cycle",
Content = "Jalankan 1 siklus (untuk debug)",
Callback = function()
if running then
WindUI:Notify({ Title = "Busy", Content = "Stop dulu sebelum single cycle", Duration = 2, Icon = "ban" })
return
end
WindUI:Notify({ Title = "Single Cycle", Content = "Running...", Duration = 2, Icon = "info" })
oneCycle()
WindUI:Notify({ Title = "Single Cycle", Content = "Done", Duration = 2, Icon = "circle-check" })
end
})

WindUI:Notify({
Title = "ZiaanHub - Blatant Tester",
Content = "Loaded. Set delays, pilih Cast Mode (Cobalt = sample), lalu Start.",
Duration = 4,
Icon = "circle-check"
})
