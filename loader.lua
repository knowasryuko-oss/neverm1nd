-- LYNXX BLATANT V2 – WINDUI EDITION (100% CLEAN FROM ZIAANHUB BASE)
-- UI diambil langsung dari script open source kamu, semua fitur lain dihapus total

repeat task.wait() until game:IsLoaded()

-- Load WindUI (exact dari script ZiaanHub kamu)
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Remote references
local Net = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net
local Charge       = Net["RF/ChargeFishingRod"]
local StartFish    = Net["RF/RequestFishingMinigameStarted"]
local FakeComplete = Net["RE/FishingCompleted"]
local CancelInput  = Net["RF/CancelFishingInputs"]

-- Auto enable official autofish + threshold 0 (Lynxx selalu lakukan ini)
spawn(function()
    pcall(Net["RF/UpdateAutoFishingState"].InvokeServer, Net["RF/UpdateAutoFishingState"], true)
    pcall(Net["RF/UpdateAuto Sell Threshold"].InvokeServer, Net["RF/UpdateAuto Sell Threshold"], 0)
end)

-- WindUI Window – 100% identik Lynxx asli pakai WindUI
local Window = WindUI:CreateWindow({
    Title = "Lynxx",
    Icon = "fish",
    Author = "Blatant V2",
    Size = UDim2.fromOffset(500, 380),
    Theme = "Dark",
    AccentColor = Color3.fromRGB(0, 170, 255) -- biru muda khas Lynxx
})

Window:SetToggleKey(Enum.KeyCode.RightControl)

-- Tab Blatant
local BlatantTab = Window:Tab({
    Title = "Blatant",
    Icon = "zap"
})

local BlatantSection = BlatantTab:Section({
    Title = "Blatant Tester",
    Icon = "flame"
})

-- Variables
local Enabled = false
local CompleteDelay = 0.550
local CancelDelay = 0.300

-- Toggle Enable
BlatantSection:Toggle({
    Title = "Enable Blatant Mode",
    Content = "Perfect Cast Mode - Instant fishing",
    Value = false,
    Callback = function(value)
        Enabled = value
    end
})

-- Slider Complete Delay
BlatantSection:Slider({
    Title = "Complete Delay",
    Content = "Delay after perfect cast (higher = safer)",
    Min = 0.001,
    Max = 1.000,
    Increment = 0.001,
    Default = 0.550,
    Suffix = "s",
    Callback = function(value)
        CompleteDelay = value
    end
})

-- Slider Cancel Delay
BlatantSection:Slider({
    Title = "Cancel Delay",
    Content = "Delay after fake completion",
    Min = 0.000,
    Max = 0.800,
    Increment = 0.001,
    Default = 0.300,
    Suffix = "s",
    Callback = function(value)
        CancelDelay = value
    end
})

-- Status Label
local StatusLabel = BlatantSection:Label({
    Title = "Status",
    Content = "Disabled"
})

-- CORE BLATANT LOOP – 100% IDENTIK LYNXX ASLI
spawn(function()
    while task.wait() do
        if not Enabled then
            StatusLabel:Set({ Content = "Status: Disabled" })
            task.wait(0.5)
            continue
        end

        StatusLabel:Set({ Content = string.format("Running — Complete: %.3fs │ Cancel: %.3fs", CompleteDelay, CancelDelay) })

        local now = os.clock()

        pcall(Charge.InvokeServer, Charge, {now - 0.1})
        pcall(StartFish.InvokeServer, StartFish, 1, 0, now)
        task.wait(CompleteDelay)
        pcall(FakeComplete.FireServer, FakeComplete)
        task.wait(CancelDelay)
        pcall(CancelInput.InvokeServer, CancelInput)
    end
end)

-- Notifikasi load persis Lynxx
WindUI:Notify({
    Title = "Lynxx",
    Content = "Blatant V2 started - Perfect Cast Mode",
    Duration = 6,
    Icon = "zap"
})

print("Lynxx Blatant V2 WindUI Edition – 100% Clean & Working")
