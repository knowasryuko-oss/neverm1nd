-- /functions/auto_fishing.lua
-- Blatant fishing loop (as in your script).

local AutoFishing = {}

function AutoFishing.Init(ctx)
    -- nothing required
end

function AutoFishing.SetEnabled(ctx, enabled)
    ctx.Config.BlatantMode = enabled and true or false
    ctx.State.fishingActive = ctx.Config.BlatantMode

    if ctx.Config.BlatantMode then
        task.spawn(function()
            AutoFishing._loop(ctx)
        end)
    end
end

function AutoFishing._loop(ctx)
    while ctx.State.fishingActive and ctx.Config.BlatantMode do
        if not ctx.State.isFishing then
            ctx.State.isFishing = true

            pcall(function()
                task.spawn(function()
                    local t1 = workspace:GetServerTimeNow()
                    ctx.Events.charge:InvokeServer(nil, nil, nil, t1)
                    task.wait(0.005)
                    local t2 = workspace:GetServerTimeNow()
                    ctx.Events.minigame:InvokeServer(1, 0, t2)
                end)
            end)

            task.wait(ctx.Config.CompleteDelay)

            pcall(function()
                for _ = 1, ctx.Config.SpamCompleted do
                    ctx.Events.fishing:FireServer()
                    task.wait(0.01)
                end
            end)

            if ctx.Config.UseCancel then
                task.wait(ctx.Config.CancelDelay)
                pcall(function()
                    ctx.Events.cancel:InvokeServer()
                end)
            end

            ctx.State.isFishing = false
        else
            task.wait(0.01)
        end
    end
end

return AutoFishing
