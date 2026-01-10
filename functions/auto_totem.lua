-- /ui/automation.lua
-- Automation tab UI (9X Totem, offset fix 90, tidak ada input manual).

return function(ctx, modules, tab)
    local AutoTotem = modules.auto_totem

    local sec = tab:Section({ Side = "Left", Collapsed = false })
    sec:Header({ Text = "9X Totem" })

    -- Dropdown totem name (label=Name, value=Id)
    local totemList = AutoTotem.GetTotemList()
    local nameToId = {}
    local nameList = {}
    for _, v in ipairs(totemList) do
        nameToId[v.label] = v.value
        nameList[#nameList+1] = v.label
    end
    local selectedTotemName = nameList[1] or ""
    local selectedTotemId = nameToId[selectedTotemName]
    local offset = 90

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

    sec:Toggle({
        Name = "Enable 9X Totem",
        Default = false,
        Callback = function(v)
            if v then
                if AutoTotem and AutoTotem.Start and selectedTotemId then
                    AutoTotem.Start(ctx, selectedTotemId, offset)
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
