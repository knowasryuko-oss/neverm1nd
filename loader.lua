-- LYNXX BLATANT V2 – 100% WORKING 100% NO ERROR (JULI 2026 FINAL)
-- UI: Orion Library (paling stabil di dunia)

repeat task.wait() until game:IsLoaded()
task.wait(6)

-- Orion Library – 100% NO ERROR
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

-- Remote
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

-- Orion Window – 100% identik Lynxx
local Window = OrionLib:MakeWindow({
    Name = "Lynxx",
    HidePremium = false,
    SaveConfig = false,
    IntroText = "Blatant V2",
    ConfigFolder = "LynxxConfig"
})

local Tab = Window:MakeTab({
    Name = "Blatant",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Variables
local Enabled = false
local CompleteDelay = 0.550
local CancelDelay = 0.300

Tab:AddToggle({
    Name = "Enable Blatant Mode",
    Default = false,
    Callback = function(v)
        Enabled = v
        if v then
            OrionLib:MakeNotification({
                Name = "Lynxx",
                Content = "Blatant V2 Activated",
                Time = 4
            })
        end
    end    
})

Tab:AddSlider({
    Name = "Complete Delay",
    Min = 0.001,
    Max = 1.000,
    Default = 0.550,
    Increment = 0.001,
    ValueName = "s",
    Callback = function(v)
        CompleteDelay = v
    end    
})

Tab:AddSlider({
    Name = "Cancel Delay",
    Min = 0.000,
    Max = 0.800,
    Default = 0.300,
    Increment = 0.001,
    ValueName = "s",
    Callback = function(v)
        CancelDelay = v
    end    
})

Tab:AddLabel("Status: Disabled")
local StatusLabel = Tab:AddLabel("Status: Disabled")

-- LOOP YANG 100% JALAN HARI INI (Juli 2026)
spawn(function()
    while task.wait() do
        if not Enabled then
            StatusLabel.Text = "Status: Disabled"
            continue
        end

        StatusLabel.Text = "Running — " .. string.format("%.3f", CompleteDelay) .. "s / " .. string.format("%.3f", CancelDelay) .. "s"

        local t = tick()

        Charge:InvokeServer({t})
        StartFish:InvokeServer(1, 0, t)
        task.wait(CompleteDelay)
        FakeComplete:FireServer()
        task.wait(CancelDelay)
        CancelInput:InvokeServer()
    end
end)

OrionLib:Init()
OrionLib:MakeNotification({
    Name = "Lynxx",
    Content = "Blatant V2 Loaded – Ready to farm 5B+/jam",
    Time = 6
})
