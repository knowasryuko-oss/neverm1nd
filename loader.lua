-- LYNXX BLATANT V2 FINAL – 100% IDENTIK REAL LYNXX MAC 2026
-- NO SMART SELL, DELAY RANGE NYATA, PER-PULAU SUPPORT

local Net = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net

local Charge       = Net["RF/ChargeFishingRod"]
local StartFish    = Net["RF/RequestFishingMinigameStarted"]
local FakeComplete = Net["RE/FishingCompleted"]
local CancelInput  = Net["RF/CancelFishingInputs"]

-- Auto enable official features (tetap ada, Lynxx juga lakukan ini)
spawn(function()
    pcall(Net["RF/UpdateAutoFishingState"].InvokeServer, Net["RF/UpdateAutoFishingState"], true)
    pcall(Net["RF/UpdateAuto Sell Threshold"].InvokeServer, Net["RF/UpdateAuto Sell Threshold"], 0)
end)

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local Window = Library:CreateWindow({ Title = "Lynxx Blatant V2", Center = true, AutoShow = true })
local Tab = Window:AddTab("Blatant")
local Group = Tab:AddLeftGroupbox("Blatant Tester")

local Enabled = false
local CompleteDelay = 0.55
local CancelDelay = 0.30

Group:AddToggle("enable", {Text = "Enable Blatant Mode", Default = false, Callback = function(v) Enabled = v end})

Group:AddSlider("complete", {
    Text = "Complete Delay",
    Min = 0.001,
    Max = 1.000,          -- Lynxx real range sampai 1 detik
    Default = 0.55,
    Rounding = 3,
    Suffix = "s",
    Callback = function(v) CompleteDelay = v end
})

Group:AddSlider("cancel", {
    Text = "Cancel Delay",
    Min = 0.000,
    Max = 0.800,          -- Lynxx real range
    Default = 0.30,
    Rounding = 3,
    Suffix = "s",
    Callback = function(v) CancelDelay = v end
})

local Status = Group:AddLabel("Status: Disabled")

spawn(function()
    while task.wait() do
        if not Enabled then
            Status:Text("Status: Disabled")
            task.wait(0.5)
            continue
        end

        Status:Text(string.format("Running │ %.3fs / %.3fs", CompleteDelay, CancelDelay))

        local now = os.clock()

        pcall(Charge.InvokeServer, Charge, {now - 0.1})
        pcall(StartFish.InvokeServer, StartFish, 1, 0, now)

        task.wait(CompleteDelay)

        pcall(FakeComplete.FireServer, FakeComplete)
        task.wait(CancelDelay)

        pcall(CancelInput.InvokeServer, CancelInput)
    end
end)

Library:Notify("Lynxx Blatant V2 Real Remake – Ready", 6)
