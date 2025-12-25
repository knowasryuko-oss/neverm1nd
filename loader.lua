-- LYNXX BLATANT V2 WINDUI EDITION
-- 100% FUNCTION + VISUAL LYNXX ASLI PAKAI WindUI (dipakai top 1–3 sekarang)

local Net = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net
local Charge       = Net["RF/ChargeFishingRod"]
local StartFish    = Net["RF/RequestFishingMinigameStarted"]
local FakeComplete = Net["RE/FishingCompleted"]
local CancelInput  = Net["RF/CancelFishingInputs"]

-- Auto enable official autofish + threshold 0
spawn(function()
    pcall(Net["RF/UpdateAutoFishingState"].InvokeServer, Net["RF/UpdateAutoFishingState"], true)
    pcall(Net["RF/UpdateAuto Sell Threshold"].InvokeServer, Net["RF/UpdateAuto Sell Threshold"], 0)
end)

-- WindUI Load
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/Source.lua"))()

local Window = WindUI:CreateWindow({
    Name = "Lynxx",
    LoadingTitle = "Lynxx Blatant V2",
    LoadingSubtitle = "Perfect Cast Mode",
    Theme = "Dark",
    AccentColor = Color3.fromRGB(0, 170, 255) -- biru muda khas Lynxx
})

local BlatantTab = Window:CreateTab("Blatant", "blatant")

local BlatantGroup = BlatantTab:CreateGroupbox("Blatant Tester", "Left")

local Enabled = false
local CompleteDelay = 0.550
local CancelDelay = 0.300

BlatantGroup:AddToggle({
    Name = "Enable Blatant Mode",
    CurrentValue = false,
    Flag = "blatant_toggle",
    Callback = function(val) Enabled = val end
})

BlatantGroup:AddSlider({
    Name = "Complete Delay",
    Min = 0.001,
    Max = 1.000,
    Default = 0.550,
    Increment = 0.001,
    Suffix = "s",
    Callback = function(val) CompleteDelay = val end
})

BlatantGroup:AddSlider({
    Name = "Cancel Delay",
    Min = 0.000,
    Max = 0.800,
    Default = 0.300,
    Increment = 0.001,
    Suffix = "s",
    Callback = function(val) CancelDelay = val end
})

local StatusLabel = BlatantGroup:AddLabel("Status: Disabled")

-- Core blatant loop (100% Lynxx)
spawn(function()
    while task.wait() do
        if not Enabled then
            StatusLabel:Set("Status: Disabled")
            task.wait(0.5)
            continue
        end

        StatusLabel:Set(string.format("Running │ %.3fs / %.3fs", CompleteDelay, CancelDelay))

        local now = os.clock()

        pcall(Charge.InvokeServer, Charge, {now - 0.1})
        pcall(StartFish.InvokeServer, StartFish, 1, 0, now)
        task.wait(CompleteDelay)
        pcall(FakeComplete.FireServer, FakeComplete)
        task.wait(CancelDelay)
        pcall(CancelInput.InvokeServer, CancelInput)
    end
end)

WindUI:Notify({
    Title = "Lynxx",
    Content = "Blatant V2 started - Perfect Cast Mode",
    Duration = 6
})

print("Lynxx Blatant V2 WindUI Edition Loaded – 100% Lynxx asli")
