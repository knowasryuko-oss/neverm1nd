-- /shared/ctx.lua
-- Builds a shared context object used by all modules and UI.

return function(opts)
    opts = opts or {}
    local BaseUrl = assert(opts.BaseUrl, "ctx.lua: BaseUrl required")
    local RequireHttp = assert(opts.RequireHttp, "ctx.lua: RequireHttp required")

    -- services
    local Players            = game:GetService("Players")
    local ReplicatedStorage  = game:GetService("ReplicatedStorage")
    local UserInputService   = game:GetService("UserInputService")
    local ContentProvider    = game:GetService("ContentProvider")
    local CoreGui            = game:GetService("CoreGui")
    local VirtualUser        = game:GetService("VirtualUser")
    local HttpService        = game:GetService("HttpService")
    local Lighting           = game:GetService("Lighting")

    local LocalPlayer = Players.LocalPlayer

    -- net
    local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net

    -- shared modules
    local Replion = require(ReplicatedStorage.Packages.Replion)
    local TierUtility = require(ReplicatedStorage.Shared.TierUtility)
    local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
    local AnimationsModule = require(ReplicatedStorage.Modules.Animations)
    local MarketItemData = require(ReplicatedStorage.Shared.MarketItemData)
    local VariantPool = require(ReplicatedStorage.Shared.ItemUtility.VariantPool)

    -- sort variant pool once
    if type(VariantPool) == "table" then
        table.sort(VariantPool)
    end

    -- events used across features
    local Events = {
        -- fishing
        fishing     = net:WaitForChild("RE/FishingCompleted"),
        charge      = net:WaitForChild("RF/ChargeFishingRod"),
        minigame    = net:WaitForChild("RF/RequestFishingMinigameStarted"),
        cancel      = net:WaitForChild("RF/CancelFishingInputs"),
        equip       = net:WaitForChild("RE/EquipToolFromHotbar"),

        -- misc
        stopScene   = net:WaitForChild("RE/StopCutscene"),

        -- shop
        sell        = net:WaitForChild("RF/SellAllItems"),
        buyWeather  = net:WaitForChild("RF/PurchaseWeatherEvent"),

        -- favorites
        Favorited   = net:WaitForChild("RE/FavoriteItem"),

        -- webhook triggers
        fishCaught           = net:WaitForChild("RE/FishCaught"),
        obtainedNewFishNotif = net:WaitForChild("RE/ObtainedNewFishNotification"),
    }

    -- shared config/state
    local Config = {
        AntiAFK = true,

        -- Auto fishing
        BlatantMode   = false,
        CompleteDelay = 0.25,
        CancelDelay   = 0.05,
        SpamCompleted = 1,
        UseCancel     = true,

        -- Standard
        DisableCutscenes    = false,
        NoFishingAnimations = false,
        HideFishPopup       = false,

        -- Auto sell
        AutoSell          = false,
        AutoSellThreshold = 100,
        AutoSellDelay     = 0,

        -- Favorites
        AutoFavourite         = false,
        AutoFavouriteMutation = false,

        -- Webhook
        WebhookUrl     = "",
        WebhookEnabled = false,

        -- FPS Booster
        FpsBooster = false,
    }

    local State = {
        -- General/UI
        MainWindow = nil,

        -- Auto fishing
        fishingActive = false,
        isFishing = false,

        -- Auto loops flags
        stopSceneRunning = false,
        autoSellRunning = false,
        weatherLoopRunning = false,

        -- Anti AFK
        AFKConnection = nil,
    }

    -- Lazy-load shared utils modules
    local Utils = RequireHttp("shared/utils.lua")
    local Http = RequireHttp("shared/http.lua")
    local FishData = RequireHttp("shared/fish_data.lua")

    local ctx = {
        BaseUrl = BaseUrl,
        RequireHttp = RequireHttp,

        Services = {
            Players = Players,
            ReplicatedStorage = ReplicatedStorage,
            UserInputService = UserInputService,
            ContentProvider = ContentProvider,
            CoreGui = CoreGui,
            VirtualUser = VirtualUser,
            HttpService = HttpService,
            Lighting = Lighting,
        },

        LocalPlayer = LocalPlayer,
        net = net,
        Events = Events,

        Replion = Replion,
        TierUtility = TierUtility,
        ItemUtility = ItemUtility,
        AnimationsModule = AnimationsModule,
        MarketItemData = MarketItemData,
        VariantPool = VariantPool,

        Config = Config,
        State = State,

        Utils = Utils,
        Http = Http,
        FishData = FishData,
    }

    -- notifier helper: requires ctx.State.MainWindow to be set by UI/init.lua
    function ctx.Notify(variant, title, desc, lifetime)
        local w = ctx.State.MainWindow
        if not w then return end
        w:Notify({
            Title = title,
            Description = desc,
            Variant = variant or "default",
            Lifetime = lifetime or 3,
        })
    end

    return ctx
end
