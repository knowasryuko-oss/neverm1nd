-- /ui/misc.lua
-- Misc tab UI (FPS Booster one-toggle).

return function(ctx, modules, tab)
    local FpsBooster = modules.fps_booster

    local sec = tab:Section({ Side = "Left", Collapsed = false })
    sec:Header({ Text = "Fps Booster" })

    sec:Toggle({
        Name = "Enable FPS Booster",
        Default = false,
        Callback = function(v)
            if FpsBooster and FpsBooster.SetEnabled then
                FpsBooster.SetEnabled(ctx, v)
            end
        end
    }, "FpsBoosterToggle")
end
