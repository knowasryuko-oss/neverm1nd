-- /functions/weather.lua
-- Auto Weather purchase + loop.

local Weather = {}

function Weather.Init(ctx)
    Weather.SelectedIds = {} -- map id->true
    Weather.LoopEnabled = false
    Weather._running = false
end

function Weather.SetSelected(ctx, selectedIdMap)
    Weather.SelectedIds = selectedIdMap or {}
end

local function getActiveList()
    local list = {}
    for id, on in pairs(Weather.SelectedIds) do
        if on then list[#list+1] = id end
    end
    table.sort(list)
    return list
end

function Weather.PurchaseOnce(ctx)
    local actives = getActiveList()
    if #actives == 0 then
        ctx.Notify("warning", "Auto Weather", "Tidak ada weather dipilih.", 4)
        return
    end
    for _, id in ipairs(actives) do
        pcall(function()
            ctx.Events.buyWeather:InvokeServer(id)
        end)
        task.wait(0.25)
    end
end

function Weather.SetEnabled(ctx, enabled, weatherInfoList)
    Weather.LoopEnabled = enabled and true or false
    if not Weather.LoopEnabled then
        return
    end
    if Weather._running then
        return
    end
    Weather._running = true

    task.spawn(function()
        while Weather.LoopEnabled do
            local actives = getActiveList()
            if #actives == 0 then
                Weather.LoopEnabled = false
                break
            end

            Weather.PurchaseOnce(ctx)

            -- compute minDuration using provided weatherInfoList (list of {Id,Duration})
            local minDuration = math.huge
            if type(weatherInfoList) == "table" then
                for _, id in ipairs(actives) do
                    for _, info in ipairs(weatherInfoList) do
                        if info.Id == id and type(info.Duration) == "number" and info.Duration > 0 then
                            if info.Duration < minDuration then
                                minDuration = info.Duration
                            end
                        end
                    end
                end
            end

            if minDuration == math.huge then
                Weather.LoopEnabled = false
                break
            end

            local t0 = os.time()
            while Weather.LoopEnabled and (os.time() - t0) < minDuration do
                task.wait(1)
            end
        end
        Weather._running = false
    end)
end

return Weather
