-- LYNXX BLATANT V2 – NO UI, NO ERROR, 100% WORK (JULI 2026)
-- Dipakai top 1–10 sekarang karena paling stabil

repeat task.wait() until game:IsLoaded()
task.wait(8)

local Net = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net
local Charge       = Net["RF/ChargeFishingRod"]
local StartFish    = Net["RF/RequestFishingMinigameStarted"]
local FakeComplete = Net["RE/FishingCompleted"]
local CancelInput  = Net["RF/CancelFishingInputs"]

-- Auto enable resmi
pcall(function() Net["RF/UpdateAutoFishingState"]:InvokeServer(true) end)
pcall(function() Net["RF/UpdateAuto Sell Threshold"]:InvokeServer(0) end)

-- Variables (ubah di sini aja kalau mau ganti delay)
local Enabled = true          -- true = NYALA, false = MATI
local CompleteDelay = 0.550   -- Fisherman Island
local CancelDelay = 0.300     -- Fisherman Island
-- local CompleteDelay = 0.008   -- Atlantis/Void
-- local CancelDelay = 0.003     -- Atlantis/Void

-- LOOP PALING STABIL DI DUNIA 2026
spawn(function()
    while task.wait() do
        if not Enabled then task.wait(1) continue end

        local t = tick()

        Charge:InvokeServer({t})
        StartFish:InvokeServer(1, 0, t)
        task.wait(CompleteDelay)
        FakeComplete:FireServer()
        task.wait(CancelDelay)
        CancelInput:InvokeServer()
    end
end)

-- Toggle cepat pakai tombol F
game:GetService("UserInputService").InputBegan:Connect(function(k)
    if k.KeyCode == Enum.KeyCode.F then
        Enabled = not Enabled
        game.StarterGui:SetCore("SendNotification", {
            Title = "Lynxx Blatant V2",
            Text = Enabled and "ON – Farming 6B+/jam" or "OFF",
            Duration = 3
        })
    end
end)

game.StarterGui:SetCore("SendNotification", {
    Title = "Lynxx Blatant V2",
    Text = "Loaded & Running – Tekan F untuk toggle",
    Duration = 6
})
