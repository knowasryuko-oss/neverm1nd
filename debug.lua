-- FIX UI + BLATANT TESTER

-- [Shared UI]
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local function NotifySuccess(title, msg, dur)
    WindUI:Notify({Title=title, Content=msg, Duration=dur or 3, Icon="circle-check"})
end

-- [Network]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
local Events = {
    fishing  = net:WaitForChild("RE/FishingCompleted"),
    sell     = net:WaitForChild("RF/SellAllItems"),
    charge   = net:WaitForChild("RF/ChargeFishingRod"),
    minigame = net:WaitForChild("RF/RequestFishingMinigameStarted"),
    cancel   = net:WaitForChild("RF/CancelFishingInputs"),
    equip    = net:WaitForChild("RE/EquipToolFromHotbar"),
    unequip  = net:WaitForChild("RE/UnequipToolFromHotbar"),
    favorite = net:WaitForChild("RE/FavoriteItem"),
}

-- [Blatant Auto Fish]
local Config = {
    BlatantMode = false,
    FishDelay   = 0.55,
    CatchDelay  = 0.01,
}
local fishingActive = false
local isFishing = false

local function blatantFishingLoop()
    while fishingActive and Config.BlatantMode do
        if not isFishing then
            isFishing = true

            -- STEP 1: Equip & 2x cast tumpuk secepat mungkin
            pcall(function()
                -- Equip rod di slot 1

                -- Cast 1
                task.spawn(function()
                    -- Hardcoded / semi-hardcoded, sangat blatant
                    local t = workspace:GetServerTimeNow()
                    Events.charge:InvokeServer(t)
                    task.wait(0.01)
                    -- X/Y pakai nilai "perfect" + sedikit random noise
                    local x = 1.2854545 + (math.random(-100, 100) / 1e6)
                    local y = 1 + (math.random(-100, 100) / 1e6)
                    Events.minigame:InvokeServer(x, y)
                end)

                task.wait(0.01) -- jeda super tipis

            end)

            -- STEP 2: Tunggu ikan gigit (agresif, tapi jangan terlalu kecil)
            task.wait(Config.FishDelay)  -- misal 1.5 detik, bisa coba 1.2 / 1.0

            -- STEP 3: Spam FishingCompleted brutal
            task.spawn(function()
                for i = 1, 1 do        -- 8x spam
                    pcall(function()
                        Events.fishing:FireServer()
                    end)
                    task.wait(0.01)     -- 0.01 detik antar panggilan
                end
            end)

            -- STEP 4: Cooldown super singkat sebelum siklus berikutnya
            task.wait(Config.CatchDelay) -- misal 0.5 detik

            isFishing = false
            -- print("[Blatant] Extreme fast cycle")
        else
            task.wait(0.01) -- cek status lebih sering
        end
    end
end

local Window = WindUI:CreateWindow({
    Title   = "Blatant FishIt",
    Icon    = "fish",
    Author  = "by you",
    Folder  = "BlatantFishIt",
    Size    = UDim2.fromOffset(450, 300),
    Theme   = "Indigo",
    KeySystem = false
})

local Tab = Window:Tab({Title="Auto Fishing", Icon="fish"})
local section = Tab:Section({Title="Blatant", Icon="fish"})

section:Toggle({
    Title   = "Blatant Auto Fish",
    Content = "Super cepat, super riskan",
    Callback = function(v)
        Config.BlatantMode = v
        fishingActive = v
        if v then
            task.spawn(blatantFishingLoop)
            NotifySuccess("Blatant", "Blatant Auto Fish ON")
        end
    end
})
