-- /ui/automation.lua
-- Automation tab UI (9X Totem, dropdown value=Id, label=Name).

return function(ctx, modules, tab)
    local AutoTotem = modules.auto_totem

    local sec = tab:Section({ Side = "Left", Collapsed = false })
    sec:Header({ Text = "9X Totem" })

    -- Dropdown totem name (label=Name, value=Id)
    local totemList = AutoTotem.GetTotemList()
    local selectedTotemId = totemList[1] and totemList[1].value or nil
    local distance = 100

    -- Build list of just names for UI, but keep value=Id
    local nameToId = {}
    local nameList = {}
    for _, v in ipairs(totemList) do
        nameToId[v.label] = v.value
        nameList[#nameList+1] = v.label
    end
    local selectedTotemName = nameList[1] or ""

    sec:Dropdown({
        Name = "Totem Name",
        Search = true,
        Multi = false,
        Required = true,
        Options = nameList,
        Default = selectedTotemName,
        Callback = function(name)
            selectedTotemName = name
            selectedTotemId = nameToId[name]
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
                if AutoTotem and AutoTotem.Start and selectedTotemId then
                    AutoTotem.Start(ctx, selectedTotemId, distance)
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
