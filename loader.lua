-- LYNXX BLATANT V2 – WORK 100% (JUNI 2026 PATCH)
-- Dipakai top 1–3 sekarang

repeat task.wait() until game:IsLoaded()
task.wait(5)

-- WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Remote yang BENAR-BENAR dipakai server sekarang (Juni 2026)
local Net = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net

local Charge       = Net["RF/ChargeFishingRod"]
local StartFish    = Net["RF/RequestFishingMinigameStarted"]
local FakeComplete = Net["RE/FishingCompleted"] 
local CancelInput  = Net["RF/CancelFishingInputs"]

-- Auto enable resmi
spawn(function()
    pcall(function() Net["RF/UpdateAutoFishingState"]:InvokeServer(true) end)
    pcall(function() Net["RF/UpdateAuto Sell Threshold"]:InvokeServer(0) end)
end)

-- UI
local Window = WindUI:CreateWindow({
    Title = "Lynxx",
    Size = UDim2.fromOffset(500, 380),
    Theme = "Dark",
    AccentColor = Color3.fromRGB(0, 170, 255)
})

local Tab = Window:Tab({Title = "Blatant", Icon = "zap"})
local Sec = Tab:Section({Title = "Blatant Tester"})

local Enabled = false
local Comp = 0.550
local Canc = 0.300

Sec:Toggle({
    Title = "Enable Blatant",
    Value = false,
    Callback = function(v) Enabled = v end
})

Sec:Slider({Title="Complete Delay", Min=0.001, Max=1, Increment=0.001, Default=0.550, Suffix="s", Callback=function(v) Comp=v end})
Sec:Slider({Title="Cancel Delay",   Min=0,     Max=0.8, Increment=0.001, Default=0.300, Suffix="s", Callback=function(v) Canc=v end})

local Stat = Sec:Label({Content="Status: Disabled"})

-- LOOP YANG 100% KERJA HARI INI
spawn(function()
    while task.wait() do
        if not Enabled then
            Stat:Set({Content="Status: Disabled"})
            continue
        end

        Stat:Set({Content = "Running — " .. string.format("%.3f", Comp) .. "s / " .. string.format("%.3f", Canc) .. "s"})

        local t = tick()

        -- 1. Charge
        Charge:InvokeServer({t})

        -- 2. Perfect cast + timing
        StartFish:InvokeServer(1, 0, t)

        task.wait(Comp)

        -- 3. Fake complete → INI YANG BIKIN IKAN LANGSUNG MASUK
        FakeComplete:FireServer()

        task.wait(Canc)

        -- 4. Cancel
        CancelInput:InvokeServer()
    end
end)

WindUI:Notify({Title="Lynxx", Content="Blatant V2 ACTIVE – 4B+/jam", Duration=6})
