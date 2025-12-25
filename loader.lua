repeat task.wait() until game:IsLoaded()

-- pastikan MacLib sudah loaded (dari file yang kamu kirim)
assert(MacLib and typeof(MacLib) == "table" and MacLib.Window, "MacLib belum di-load/return")

-- services + remotes
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

-- config (UI Lynxx style)
local cfg = {
hotbarSlot = 1,
chargeWait = 0.05,
recastDelay = 0.18,
completeDelay = 0.00,
cancelDelay = 0.00,
}

-- helpers (compat args)
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

-- core loop (pure Lynxx; cast = (1,0))
local running = false
local cycleId = 0

local function oneCycle()
cycleId += 1
-- equip
pcall(function() Remotes.equip:FireServer(cfg.hotbarSlot) end)
task.wait(0.08)

text

-- charge (server time)
local tCharge = workspace:GetServerTimeNow()
invokeCharge(tCharge)
if cfg.chargeWait > 0 then task.wait(cfg.chargeWait) end

-- minigame (Cobalt sample: 1,0)
local tMini = workspace:GetServerTimeNow()
invokeMinigame(1, 0, tMini)

-- lengkapkan ala Lynxx: Complete → Cancel dengan delay bebas
if cfg.completeDelay > 0 then task.wait(cfg.completeDelay) end
pcall(function() Remotes.finish:FireServer() end)

if cfg.cancelDelay > 0 then task.wait(cfg.cancelDelay) end
pcall(function() Remotes.cancel:InvokeServer() end)
end

local function startLoop(window)
if running then return end
running = true
cycleId = 0
if window and window.Notify then
window:Notify({
Title = "Blatant Tester",
Description = "Started (pure Lynxx flow)",
Lifetime = 3
})
end
task.spawn(function()
while running do
oneCycle()
task.wait(cfg.recastDelay)
end
end)
end

local function stopLoop(window)
if not running then return end
running = false
pcall(function() if Remotes.unequip then Remotes.unequip:FireServer() end end)
if window and window.Notify then
window:Notify({
Title = "Blatant Tester",
Description = "Stopped",
Lifetime = 2
})
end
end

-- build UI (Atomic MacLib)
local Window = MacLib:Window({
Title = "Atomic - Blatant Tester (Lynxx)",
Subtitle = "pure timer flow",
Size = UDim2.fromOffset(720, 480),
DragStyle = 2,
ShowUserInfo = false,
Keybind = Enum.KeyCode.RightControl,
})

local TG = Window:TabGroup()
local Tab = TG:Tab({ Name = "Blatant Tester", Image = "zap" })
local Sec = Tab:Section({ Side = "Left" })
Sec:Header({ Name = "Pure Lynxx Flow (Charge → Minigame → Complete → Cancel)" })

-- start/stop toggle
Sec:Toggle({
Name = "Start Blatant Tester",
Default = false,
Callback = function(v)
if v then startLoop(Window) else stopLoop(Window) end
end
}, "BT_Start")

-- complete delay input (0.00 default)
Sec:Input({
Name = "Complete Delay (s)",
Placeholder = "0.00",
AcceptedCharacters = "Numeric",
Callback = function(text)
local n = tonumber(text)
if n then
cfg.completeDelay = math.max(0, n)
Window:Notify({
Title = "Blatant Tester",
Description = ("Complete Delay = %.3f"):format(cfg.completeDelay),
Lifetime = 2
})
else
Window:Notify({
Title = "Invalid",
Description = "Complete Delay harus angka",
Lifetime = 2
})
end
end,
}, "BT_CompleteDelay")

-- cancel delay input (0.00 default)
Sec:Input({
Name = "Cancel Delay (s)",
Placeholder = "0.00",
AcceptedCharacters = "Numeric",
Callback = function(text)
local n = tonumber(text)
if n then
cfg.cancelDelay = math.max(0, n)
Window:Notify({
Title = "Blatant Tester",
Description = ("Cancel Delay = %.3f"):format(cfg.cancelDelay),
Lifetime = 2
})
else
Window:Notify({
Title = "Invalid",
Description = "Cancel Delay harus angka",
Lifetime = 2
})
end
end,
}, "BT_CancelDelay")

-- optional: recast & charge wait (kalau mau sentuh)
local Adv = Tab:Section({ Side = "Right" })
Adv:Header({ Name = "Advanced (opsional)" })
Adv:Input({
Name = "Recast Delay (s) [default 0.18]",
Placeholder = "0.18",
AcceptedCharacters = "Numeric",
Callback = function(text)
local n = tonumber(text)
if n then
cfg.recastDelay = math.max(0, n)
Window:Notify({
Title = "Blatant Tester",
Description = ("Recast Delay = %.3f"):format(cfg.recastDelay),
Lifetime = 2
})
end
end,
}, "BT_RecastDelay")
Adv:Input({
Name = "Charge Wait (s) [default 0.05]",
Placeholder = "0.05",
AcceptedCharacters = "Numeric",
Callback = function(text)
local n = tonumber(text)
if n then
cfg.chargeWait = math.max(0, n)
Window:Notify({
Title = "Blatant Tester",
Description = ("Charge Wait = %.3f"):format(cfg.chargeWait),
Lifetime = 2
})
end
end,
}, "BT_ChargeWait")

-- pilih tab & ready
Tab:Select()
Window:Notify({
Title = "Atomic - Blatant Tester",
Description = "Set Complete/Cancel Delay seperti UI Lynxx, lalu Start.",
Lifetime = 4
})

-- OPTIONAL: hook tombol toggle kecil Ajomok (kalau kamu load modulnya ke variabel AjToggle)
-- if AjToggle and AjToggle.initial_interface then
-- AjToggle:initial_interface(function()
-- if running then
-- stopLoop(Window)
-- local opt = MacLib.Options["BT_Start"]
-- if opt and opt.UpdateState then opt:UpdateState(false) end
-- else
-- startLoop(Window)
-- local opt = MacLib.Options["BT_Start"]
-- if opt and opt.UpdateState then opt:UpdateState(true) end
-- end
-- end)
-- end
