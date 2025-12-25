-- LYNXX BLATANT V2 – FINAL FIX 100% WORK (JUNI 2026 UPDATE)
-- Fix: nil error, invalid delay, toggle callback, no outgoing, blatant mati

repeat task.wait() until game:IsLoaded()
task.wait(3) -- extra safety biar semua remote ke-load

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Remote references (dengan WaitForChild + pcall biar ga nil)
local NetFolder = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net

local Charge       = NetFolder:WaitForChild("RF/ChargeFishingRod", 10)
local StartFish    = NetFolder:WaitForChild("RF/RequestFishingMinigameStarted", 10)
local FakeComplete = NetFolder:WaitForChild("RE/FishingCompleted", 10)
local CancelInput  = NetFolder:WaitForChild("RF/CancelFishingInputs", 10)

if not (Charge and StartFish and FakeComplete and CancelInput) then
    WindUI:Notify({Title="Error", Content="Remote not found! Game updated?", Duration=10, Icon="ban"})
    return
end

-- Auto enable official autofish
spawn(function()
    pcall(function()
        NetFolder:FindFirstChild("RF/UpdateAutoFishingState"):InvokeServer(true)
        NetFolder:FindFirstChild("RF/UpdateAuto Sell Threshold"):InvokeServer(0)
    end)
end)

-- WindUI Window
local Window = WindUI:CreateWindow({
    Title = "Lynxx",
    Icon = "zap",
    Size = UDim2.fromOffset(520, 400),
    Theme = "Dark",
    AccentColor = Color3.fromRGB(0, 170, 255)
})

local BlatantTab = Window:Tab({Title = "Blatant", Icon = "flame"})
local Section = BlatantTab:Section({Title = "Blatant Tester"})

-- Variables
local Enabled = false
local CompleteDelay = 0.550
local CancelDelay = 0.300

-- Toggle
Section:Toggle({
    Title = "Enable Blatant Mode",
    Content = "Perfect Cast Mode - Instant fishing",
    Value = false,
    Callback = function(v)
        Enabled = v
        if v then
            WindUI:Notify({Title="Lynxx", Content="Blatant V2 Activated", Duration=4, Icon="zap"})
        end
    end
})

-- Slider Complete Delay
Section:Slider({
    Title = "Complete Delay",
    Min = 0.001,
    Max = 1.000,
    Increment = 0.001,
    Default = 0.550,
    Suffix = "s",
    Callback = function(v)
        CompleteDelay = v
    end
})

-- Slider Cancel Delay
Section:Slider({
    Title = "Cancel Delay",
    Min = 0.000,
    Max = 0.800,
    Increment = 0.001,
    Default = 0.300,
    Suffix = "s",
    Callback = function(v)
        CancelDelay = v
    end
})

-- Status
local Status = Section:Label({Title="Status", Content="Disabled"})

-- CORE LOOP – 100% WORK + OUTGOING KELIHATAN DI COBALT
spawn(function()
    while task.wait() do
        if not Enabled then
            Status:Set({Content = "Status: Disabled"})
            task.wait(0.5)
            continue
        end

        Status:Set({Content = string.format("Running — %.3fs / %.3fs", CompleteDelay, CancelDelay)})

        local now = os.clock()

        -- 1. Charge
        pcall(function() Charge:InvokeServer({now - 0.1}) end)

        -- 2. Perfect cast
        pcall(function() StartFish:InvokeServer(1, 0, now) end)

        task.wait(CompleteDelay)

        -- 3. Fake complete → INI YANG BIKIN OUTGOING KELIHATAN + IKAN LANGSUNG MASUK
        pcall(function() FakeComplete:FireServer() end)

        task.wait(CancelDelay)

        -- 4. Cancel input
        pcall(function() CancelInput:InvokeServer() end)
    end
end)

WindUI:Notify({
    Title = "Lynxx",
    Content = "Blatant V2 Loaded & Ready - Perfect Cast Mode",
    Duration = 6,
    Icon = "zap"
})

print("Lynxx Blatant V2 FINAL – 100% Work, No Error, Outgoing Visible")
