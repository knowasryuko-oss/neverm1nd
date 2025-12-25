-- LYNXX BLATANT V2 – 100% IDENTIK DENGAN LYNXX ASLI (MacUI EUPHORIA)
-- UI EXACTLY SAMA, WARNA, FONT, ANIMASI, LAYOUT – GA BISA DIBEDAIN

loadstring(game:HttpGet("https://github.com/bimoraa/Euphoria/blob/main/MacUI/main.luau"))()

local Net = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net
local Charge       = Net["RF/ChargeFishingRod"]
local StartFish    = Net["RF/RequestFishingMinigameStarted"]
local FakeComplete = Net["RE/FishingCompleted"]
local CancelInput  = Net["RF/CancelFishingInputs"]

-- Auto enable official
spawn(function()
    pcall(Net["RF/UpdateAutoFishingState"].InvokeServer, Net["RF/UpdateAutoFishingState"], true)
    pcall(Net["RF/UpdateAuto Sell Threshold"].InvokeServer, Net["RF/UpdateAuto Sell Threshold"], 0)
end)

wait(2) -- tunggu MacUI fully load

local Window = MacUI:CreateWindow({
    Title = "Lynxx",
    SubTitle = "Blatant V2",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 380)
})

local BlatantTab = Window:CreateTab("Blatant", true)

local Group = BlatantTab:CreateGroupbox("Blatant Tester", "Left")

local Enabled = false
local CompleteDelay = 0.550
local CancelDelay = 0.300

Group:AddToggle("Enable Blatant Mode", false, function(state)
    Enabled = state
end)

Group:AddSlider("Complete Delay", 0.550, 0.001, 1.000, 0.001, "s", function(val)
    CompleteDelay = val
end)

Group:AddSlider("Cancel Delay", 0.300, 0.000, 0.800, 0.001, "s", function(val)
    CancelDelay = val
end)

local StatusLabel = Group:AddLabel("Status: Disabled")

-- CORE LOOP 100% LYNXX ASLI
spawn(function()
    while task.wait() do
        if not Enabled then
            StatusLabel:SetText("Status: Disabled")
            task.wait(0.5)
            continue
        end

        StatusLabel:SetText(string.format("Running ━ Complete: %.3fs │ Cancel: %.3fs", CompleteDelay, CancelDelay))

        local now = os.clock()

        pcall(Charge.InvokeServer, Charge, {now - 0.1})
        pcall(StartFish.InvokeServer, StartFish, 1, 0, now)
        task.wait(CompleteDelay)
        pcall(FakeComplete.FireServer, FakeComplete)
        task.wait(CancelDelay)
        pcall(CancelInput.InvokeServer, CancelInput)
    end
end)

MacUI:Notify({
    Title = "Lynxx",
    Content = "Blatant V2 started - Perfect Cast Mode",
    Duration = 5
})

print("Lynxx Blatant V2 MacUI 100% Clone Loaded – Indistinguishable")
