-- /ui/auto.lua
-- Auto Fishing tab UI (Blatant + Auto Sell + Standard).

return function(ctx, modules, tab)
    local AutoFishing = modules.auto_fishing
    local AutoSell = modules.auto_sell

    -- Blatant
    local secBlatant = tab:Section({ Side = "Left", Collapsed = false })
    secBlatant:Header({ Text = "Blatant Tester" })

    secBlatant:Toggle({
        Name = "Blatant Tester",
        Default = false,
        Callback = function(v)
            ctx.Config.BlatantMode = v and true or false
            ctx.State.fishingActive = ctx.Config.BlatantMode
            if AutoFishing and AutoFishing.SetEnabled then
                AutoFishing.SetEnabled(ctx, v)
            end
        end
    })

    secBlatant:Input({
        Name = "Complete Delay",
        Placeholder = "0.25",
        Default = tostring(ctx.Config.CompleteDelay),
        AcceptedCharacters = "All",
        Callback = function(text)
            local num = tonumber(text)
            if num and num >= 0 then ctx.Config.CompleteDelay = num end
        end
    })

    secBlatant:Input({
        Name = "Cancel Delay",
        Placeholder = "0.05",
        Default = tostring(ctx.Config.CancelDelay),
        AcceptedCharacters = "All",
        Callback = function(text)
            local num = tonumber(text)
            if num and num >= 0 then ctx.Config.CancelDelay = num end
        end
    })

    -- Auto Sell
    local secSell = tab:Section({ Side = "Left", Collapsed = false })
    secSell:Header({ Text = "Auto Sell" })

    secSell:Toggle({
        Name = "Enable Auto Sell",
        Default = false,
        Callback = function(v)
            ctx.Config.AutoSell = v and true or false
            if AutoSell and AutoSell.SetEnabled then
                AutoSell.SetEnabled(ctx, v)
            end
        end
    })

    secSell:Input({
        Name = "Threshold Count",
        Placeholder = "100",
        Default = tostring(ctx.Config.AutoSellThreshold),
        AcceptedCharacters = "Numeric",
        Callback = function(text)
            local num = tonumber(text)
            if num and num >= 0 then ctx.Config.AutoSellThreshold = math.floor(num) end
        end
    })

    secSell:Input({
        Name = "Sell Delay (detik)",
        Placeholder = "0 (pakai threshold)",
        Default = tostring(ctx.Config.AutoSellDelay),
        AcceptedCharacters = "Numeric",
        Callback = function(text)
            local num = tonumber(text)
            if num and num >= 0 then ctx.Config.AutoSellDelay = math.floor(num) end
        end
    })

    -- Standard
    local secStd = tab:Section({ Side = "Left", Collapsed = false })
    secStd:Header({ Text = "Standard" })

    -- Anti AFK
    secStd:Toggle({
        Name = "Anti AFK",
        Default = true,
        Callback = function(v)
            ctx.Config.AntiAFK = v and true or false
            -- UI layer doesn't implement AFK; you can add a module later if you want.
        end
    }, "AntiAFK")

    -- One-shot equip rod
    local equipToggleRef
    equipToggleRef = secStd:Toggle({
        Name = "Auto Equip Rod",
        Default = false,
        Callback = function(v)
            if not v then return end
            pcall(function()
                ctx.Events.equip:FireServer(1)
            end)
            ctx.Notify("info", "Standard", "Equipped rod (slot 1).", 2)
            task.defer(function()
                pcall(function() equipToggleRef:UpdateState(false) end)
            end)
        end
    }, "AutoEquipRodOnce")
end
