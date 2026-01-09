-- /shared/ctx.lua
-- UPDATED: ensure Services includes Enum KeyCode availability via global, and init default maps in ctx.State.

return function(opts)
    opts = opts or {}
    local BaseUrl = assert(opts.BaseUrl, "ctx.lua: BaseUrl required")
    local RequireHttp = assert(opts.RequireHttp, "ctx.lua: RequireHttp required")

    local Players            = game:GetService("Players")
    local ReplicatedStorage  = game:GetService("ReplicatedStorage")
    local UserInputService   = game:GetService("UserInputService")
    local ContentProvider    = game:GetService("ContentProvider")
    local CoreGui            = game:GetService("CoreGui")
    local VirtualUser        = game:GetService("VirtualUser")
    local HttpService        = game:GetService("HttpService")
    local Lighting           = game:GetService("Lighting")

    local LocalPlayer = Players.LocalPlayer

    local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net

    local Replion = require(ReplicatedStorage.Packages.Replion)
    local TierUtility = require(ReplicatedStorage.Shared.TierUtility)
    local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
    local AnimationsModule = require(ReplicatedStorage.Modules.Animations)
    local MarketItemData = require(ReplicatedStorage.Shared.MarketItemData)
    local VariantPool = require(ReplicatedStorage.Shared.ItemUtility.VariantPool)

    if type(VariantPool) == "table" then
        table.sort(VariantPool)
    end

    local Events = {
        fishing     = net:WaitForChild("RE/FishingCompleted"),
        charge      = net:WaitForChild("RF/ChargeFishingRod"),
        minigame    = net:WaitForChild("RF/RequestFishingMinigameStarted"),
        cancel      = net:WaitForChild("RF/CancelFishingInputs"),
        equip       = net:WaitForChild("RE/EquipToolFromHotbar"),

        stopScene   = net:WaitForChild("RE/StopCutscene"),

        sell        = net:WaitForChild("RF/SellAllItems"),
        buyWeather  = net:WaitForChild("RF/PurchaseWeatherEvent"),

        Favorited   = net:WaitForChild("RE/FavoriteItem"),

        fishCaught           = net:WaitForChild("RE/FishCaught"),
        obtainedNewFishNotif = net:WaitForChild("RE/ObtainedNewFishNotification"),
    }

    local Config = {
        AntiAFK = true,

        BlatantMode   = false,
        CompleteDelay = 0.25,
        CancelDelay   = 0.05,
        SpamCompleted = 1,
        UseCancel     = true,

        DisableCutscenes    = false,
        NoFishingAnimations = false,
        HideFishPopup       = false,

        AutoSell          = false,
        AutoSellThreshold = 100,
        AutoSellDelay     = 0,

        AutoFavourite         = false,
        AutoFavouriteMutation = false,

        WebhookUrl     = "",
        WebhookEnabled = false,

        FpsBooster = false,
    }

    local State = {
        MainWindow = nil,
        Tabs = nil,

        fishingActive = false,
        isFishing = false,

        -- UI filter maps used by modules
        FavoriteTierNumberMap = { [7]=true, [6]=true, [5]=true },
        FavoriteMutationMap = {},
        WebhookTierNumberMap = { [7]=true, [6]=true, [5]=true },
    }

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
