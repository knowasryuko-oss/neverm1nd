-- /ui/automation.lua
-- Automation tab UI (9X Totem, dropdown string: Shiny, Luck, Mutation).

return function(ctx, modules, tab)
    local AutoTotem = modules.auto_totem

    local sec = tab:Section({ Side = "Left", Collapsed = false })
    sec:Header({ Text = "9X Totem" })

    -- Dropdown totem name (list string)
    local totemList = AutoTotem.GetTotemNameList()
    local selectedTotemName = totemList[1] or ""
    local distance = 100

    sec:Dropdown({
        Name = "Totem Name",
        Search = true,
        Multi = false,
        Required = true,
        Options = totemList,
        Default = selectedTotemName,
        Callback = function(name)
            selectedTotemName = name
        end
    })

    sec:Input({
        Name = "Jarak antar Totem (studs)",
        Placeholder = "100",
        Default = tostring(distance),
        AcceptedCharacters = "Numeric",
        Callback = function(text)
            local n = tonumber(text)
            if n and n > 0 then distance = n end
        end
    })

    sec:Toggle({
        Name = "Enable 9X Totem",
        Default = false,
        Callback = function(v)
            if v then
                if AutoTotem and AutoTotem.Start and selectedTotemName then
                    AutoTotem.Start(ctx, selectedTotemName, distance)
                    ctx.Notify("info", "9X Totem", "Auto spawn totem aktif.", 3)
                end
            else
                if AutoTotem and AutoTotem.Stop then
                    AutoTotem.Stop(ctx)
                    ctx.Notify("info", "9X Totem", "Auto spawn totem dimatikan.", 3)
                end
            end
        end
    }, "AutoTotemToggle")
end
