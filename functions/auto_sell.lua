-- /functions/auto_sell.lua
-- Auto-sell unfavorited items using Replion Data and RF/SellAllItems.

local AutoSell = {}

function AutoSell.Init(ctx)
    AutoSell._running = false
    AutoSell._lastSellTime = 0
end

function AutoSell.SetEnabled(ctx, enabled)
    ctx.Config.AutoSell = enabled and true or false
    if ctx.Config.AutoSell then
        AutoSell.Start(ctx)
    end
end

function AutoSell.Start(ctx)
    if AutoSell._running then return end
    AutoSell._running = true

    task.spawn(function()
        while ctx.Config.AutoSell do
            pcall(function()
                local dataRep = ctx.Replion.Client:WaitReplion("Data")
                if not dataRep then return end

                local items = dataRep:Get({"Inventory","Items"})
                if type(items) ~= "table" then return end

                local unfavoritedCount = 0
                for _, item in ipairs(items) do
                    if not item.Favorited then
                        unfavoritedCount = unfavoritedCount + (item.Count or 1)
                    end
                end

                local threshold = ctx.Config.AutoSellThreshold or 0
                local delay     = ctx.Config.AutoSellDelay or 0
                local now       = os.time()
                local shouldSell = false

                if threshold > 0 then
                    shouldSell = unfavoritedCount >= threshold
                elseif delay > 0 then
                    shouldSell = (unfavoritedCount > 0) and ((now - AutoSell._lastSellTime) >= delay)
                end

                if shouldSell then
                    ctx.Events.sell:InvokeServer()
                    AutoSell._lastSellTime = now
                    ctx.Notify("success", "Auto Sell", ("Sell non-favorit (count=%d)"):format(unfavoritedCount), 4)
                end
            end)

            task.wait(10)
        end

        AutoSell._running = false
    end)
end

return AutoSell
