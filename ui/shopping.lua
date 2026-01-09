-- /ui/shopping.lua
-- Shopping tab UI (Auto Weather + Traveling Merchant).

return function(ctx, modules, tab)
    local Weather = modules.weather
    local Merchant = modules.merchant

    -- Weather config list matches your script
    local WeatherEvents = {
        {Id = "Cloudy",     Price = 20000,  Duration = 900},
        {Id = "Radiant",    Price = 50000,  Duration = 900},
        {Id = "Snow",       Price = 15000,  Duration = 900},
        {Id = "Storm",      Price = 35000,  Duration = 900},
        {Id = "Wind",       Price = 10000,  Duration = 900},
        {Id = "Shark Hunt", Price = 300000, Duration = 1800},
    }

    -- Auto Weather (Left)
    local sec = tab:Section({ Side = "Left", Collapsed = false })
    sec:Header({ Text = "Auto Weather" })

    local weatherLabels = {}
    local labelToId = {}
    for _, info in ipairs(WeatherEvents) do
        local label = ("%s ($%s)"):format(info.Id, ctx.Utils.formatPrice(info.Price))
        weatherLabels[#weatherLabels+1] = label
        labelToId[label] = info.Id
    end
    table.sort(weatherLabels)

    sec:Dropdown({
        Name     = "Select Weathers...",
        Search   = true,
        Multi    = true,
        Required = false,
        Options  = weatherLabels,
        Default  = {},
        Callback = function(Value)
            local map = {}
            for label, state in pairs(Value) do
                if state then
                    local id = labelToId[label]
                    if id then map[id] = true end
                end
            end
            if Weather and Weather.SetSelected then
                Weather.SetSelected(ctx, map)
            end
        end
    }, "WeatherMultiDropdown")

    sec:Toggle({
        Name = "Auto Buy and Active Weather",
        Default = false,
        Callback = function(v)
            if not Weather then return end
            if v then
                Weather.PurchaseOnce(ctx)
                Weather.SetEnabled(ctx, true, WeatherEvents)
            else
                Weather.SetEnabled(ctx, false, WeatherEvents)
            end
        end
    })

    -- Traveling Merchant (Right)
    local tmSec = tab:Section({ Side = "Right", Collapsed = false })
    tmSec:Header({ Text = "Traveling Merchant" })

    local SelectedTMId = nil
    local tmLabelToId = {}

    local tmDropdown
    do
        local opts, map = Merchant.BuildOptions(ctx)
        tmLabelToId = map
        tmDropdown = tmSec:Dropdown({
            Name     = "Select Item",
            Search   = true,
            Multi    = false,
            Required = false,
            Options  = opts,
            Default  = nil,
            Callback = function(label)
                SelectedTMId = label and tmLabelToId[label] or nil
            end
        }, "TravelingMerchantDropdown")
    end

    tmSec:Button({
        Name = "Refresh List",
        Callback = function()
            if not (tmDropdown and tmDropdown.ClearOptions and tmDropdown.InsertOptions) then
                ctx.Notify("warning", "Traveling Merchant", "Dropdown refresh tidak didukung.", 4)
                return
            end
            local opts, map = Merchant.BuildOptions(ctx)
            tmLabelToId = map
            SelectedTMId = nil
            tmDropdown:ClearOptions()
            tmDropdown:InsertOptions(opts)
        end
    })

    tmSec:Button({
        Name = "Buy (1x)",
        Callback = function()
            if not SelectedTMId then
                ctx.Notify("warning", "Traveling Merchant", "Pilih item dulu.", 3)
                return
            end
            Merchant.BuyById(ctx, SelectedTMId)
        end
    })
end
