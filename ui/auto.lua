-- /ui/auto.lua
-- UPDATED: adds Standard toggles for AntiAFK, Disable Cutscenes, No Fishing Animations, Hide Fish Popup.
-- Requires modules: anti_afk, cutscene, hide_popup

return function(ctx, modules, tab)
    local AutoFishing = modules.auto_fishing
    local AutoSell = modules.auto_sell
    local AntiAFK = modules.anti_afk
    local Cutscene = modules.cutscene
    local HidePopup = modules.hide_popup

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

    secStd:Toggle({
        Name = "Anti AFK",
        Default = true,
        Callback = function(v)
            if AntiAFK and AntiAFK.SetEnabled then
                AntiAFK.SetEnabled(ctx, v)
            end
        end
    }, "AntiAFK")

    -- one-shot equip
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

    secStd:Toggle({
        Name = "Disable Cutscenes",
        Default = false,
        Callback = function(v)
            if Cutscene and Cutscene.SetEnabled then
                Cutscene.SetEnabled(ctx, v)
            end
        end
    }, "DisableCutscenes")

    secStd:Toggle({
        Name = "Hide Fish Popup",
        Default = false,
        Callback = function(v)
            if HidePopup and HidePopup.SetEnabled then
                HidePopup.SetEnabled(ctx, v)
            end
        end
    }, "HideFishPopup")
end
