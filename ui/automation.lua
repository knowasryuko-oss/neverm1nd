return function(ctx, modules, tab)
    local AutoTotem = modules.auto_totem

    local sec = tab:Section({ Side = "Left", Collapsed = false })
    sec:Header({ Text = "9X Totem" })

    -- Dropdown totem name
    local totemList = {}
    local totemNameToData = {}
    do
        local list = {}
        local folder = game:GetService("ReplicatedStorage"):FindFirstChild("Totems")
        if folder then
            for _, mod in ipairs(folder:GetChildren()) do
                if mod:IsA("ModuleScript") then
                    local ok, data = pcall(function() return require(mod) end)
                    if ok and type(data) == "table" and data.Data and data.Data.Name then
                        list[#list+1] = data.Data.Name
                        totemNameToData[data.Data.Name] = data
                    end
                end
            end
        end
        table.sort(list)
        totemList = list
    end

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
            -- Only act if user really toggles
            if v then
                if AutoTotem and AutoTotem.Start and not AutoTotem._running then
                    AutoTotem.Start(ctx, selectedTotemName, distance)
                    ctx.Notify("info", "9X Totem", "Auto spawn totem aktif.", 3)
                end
            else
                if AutoTotem and AutoTotem.Stop and AutoTotem._running then
                    AutoTotem.Stop(ctx)
                    ctx.Notify("info", "9X Totem", "Auto spawn totem dimatikan.", 3)
                end
            end
        end
    }, "AutoTotemToggle")
end
