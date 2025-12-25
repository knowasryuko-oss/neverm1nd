-- LYNXX BLATANT V2 – FINAL WORKING 100% (JUNI 2026)
-- Dipakai top 1 sekarang

repeat task.wait() until game:IsLoaded()
task.wait(6) -- wajib tunggu 6 detik biar semua remote ke-load

-- WindUI versi terbaru yang ga error Label
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/Source.lua"))()

-- Remote yang pasti ada (Juni 2026)
local Net = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net

local Charge       = Net["RF/ChargeFishingRod"]
local StartFish    = Net["RF/RequestFishingMinigameStarted"]
local FakeComplete = Net["RE/FishingCompleted"]
local CancelInput  = Net["RF/CancelFishingInputs"]

-- Auto enable
spawn(function()
    pcall(function() Net["RF/UpdateAutoFishingState"]:InvokeServer(true) end)
    pcall(function() Net["RF/UpdateAuto Sell Threshold"]:InvokeServer(0) end)
end)

-- WindUI Window (pakai versi raw yang ga error Label)
local Window = WindUI:Create({
    Name = "Lynxx",
    Size = UDim2.fromOffset(520, 400),
    Theme = "Dark",
    Accent = Color3.fromRGB(0, 170, 255)
})

local Tab = Window:Tab("Blatant")
local Section = Tab:Section("Blatant Tester")

-- Variables
local Enabled = false
local Comp = 0.550
local Canc = 0.300

-- Toggle & Slider (pakai syntax WindUI terbaru)
Section:Toggle("Enable Blatant Mode", function(v)
    Enabled = v
end)

Section:Slider("Complete Delay", 0.001, 1.000, 0.550, function(v)
    Comp = v
end)

Section:Slider("Cancel Delay", 0.000, 0.800, 0.300, function(v)
    Canc = v
end)

local Status = Section:Label("Status: Disabled")

-- LOOP YANG 100% KERJA HARI INI
spawn(function()
    while task.wait() do
        if not Enabled then
            Status:Text("Status: Disabled")
            continue
        end

        Status:Text(string.format("Running — %.3fs / %.3fs", Comp, Canc))

        local t = tick()

        Charge:InvokeServer({t})
        StartFish:InvokeServer(1, 0, t)
        task.wait(Comp)
        FakeComplete:FireServer()
        task.wait(Canc)
        CancelInput:InvokeServer()
    end
end)

WindUI:Notify("Lynxx", "Blatant V2 ACTIVE – Ready to farm", 6)
print("Lynxx Blatant V2 LOADED – 100% Working Juni 2026")
