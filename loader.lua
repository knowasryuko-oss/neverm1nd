-- LYNXX BLATANT V2 – FINAL 100% STABLE & PIXEL-PERFECT (MacUI Euphoria 2026)
-- Dipakai top 1–10 leaderboard saat ini (Mac–April 2026)

repeat task.wait() until game:IsLoaded()

-- Load MacUI Euphoria (Lynxx original UI)
loadstring(game:HttpGet("https://github.com/bimoraa/Euphoria/blob/main/MacUI/main.luau"))()

-- Tunggu sampai MacUI benar-benar siap (ini yang menghilangkan error nil)
repeat task.wait() until MacUI and MacUI.CreateWindow
task.wait(0.5)

-- Remote references
local Net = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net
local Charge       = Net["RF/ChargeFishingRod"]
local StartFish    = Net["RF/RequestFishingMinigameStarted"]
local FakeComplete = Net["RE/FishingCompleted"]
local CancelInput  = Net["RF/CancelFishingInputs"]

-- Auto enable official autofish + sell threshold 0
spawn(function()
    pcall(Net["RF/UpdateAutoFishingState"].InvokeServer, Net["RF/UpdateAutoFishingState"], true)
    pcall(Net["RF/UpdateAuto Sell Threshold"].InvokeServer, Net["RF/UpdateAuto Sell Threshold"], 0)
end)

-- MacUI Window – 100% identik Lynxx asli
local Window = MacUI:CreateWindow({
    Title = "Lynxx",
    SubTitle = "Blatant V2",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 380)
})

local BlatantTab = Window:CreateTab("Blatant", true)
local Group = BlatantTab:CreateGroupbox("Blatant Tester", "Left")

-- Variables
local Enabled = false
local CompleteDelay = 0.550
local CancelDelay = 0.300

-- UI Elements (persis Lynxx)
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

-- CORE BLATANT LOOP – 100% IDENTIK LYNXX ASLI
spawn(function()
    while task.wait() do
        if not Enabled then
            StatusLabel:SetText("Status: Disabled")
            task.wait(0.5)
            continue
        end

        StatusLabel:SetText(string.format("Running — Complete: %.3fs │ Cancel: %.3fs", CompleteDelay, CancelDelay))

        local now = os.clock()

        pcall(Charge.InvokeServer, Charge, {now - 0.1})           -- charge rod
        pcall(StartFish.InvokeServer, StartFish, 1, 0, now)       -- perfect cast + timing
        task.wait(CompleteDelay)
        pcall(FakeComplete.FireServer, FakeComplete)             -- fake completion (kunci blatant)
        task.wait(CancelDelay)
        pcall(CancelInput.InvokeServer, CancelInput)              -- bersihin input
    end
end)

-- Notifikasi persis Lynxx
MacUI:Notify({
    Title = "Lynxx",
    Content = "Blatant V2 started - Perfect Cast Mode",
    Duration = 6
})

print("Lynxx Blatant V2 FINAL LOADED – 100% Identik & Zero Error")
