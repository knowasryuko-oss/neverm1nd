-- /ui/teleport.lua
-- Teleport tab UI (Island + Player).

return function(ctx, modules, tab)
    local Teleport = modules.teleport

    -- Island coords (same as your script)
    local islandCoords = {
        ["01"] = { name = "Weather Machine", position = Vector3.new(-1471, -3, 1929) },
        ["02"] = { name = "Esoteric Depths", position = Vector3.new(3157, -1303, 1439) },
        ["03"] = { name = "Tropical Grove", position = Vector3.new(-2038, 3, 3650) },
        ["04"] = { name = "Stingray Shores", position = Vector3.new(-32, 4, 2773) },
        ["05"] = { name = "Kohana Volcano", position = Vector3.new(-519, 24, 189) },
        ["06"] = { name = "Coral Reefs", position = Vector3.new(-3095, 1, 2177) },
        ["07"] = { name = "Crater Island", position = Vector3.new(968, 1, 4854) },
        ["08"] = { name = "Kohana", position = Vector3.new(-658, 3, 719) },
        ["09"] = { name = "Winter Fest", position = Vector3.new(1611, 4, 3280) },
        ["10"] = { name = "Isoteric Island", position = Vector3.new(1987, 4, 1400) },
        ["11"] = { name = "Treasure Hall", position = Vector3.new(-3600, -267, -1558) },
        ["12"] = { name = "Lost Shore", position = Vector3.new(-3663, 38, -989 ) },
        ["13"] = { name = "Sishypus Statue", position = Vector3.new(-3792, -135, -986) }
    }

    local SelectedIslandName = nil
    local SelectedPlayerName = nil

    -- Island
    local tpSec = tab:Section({ Side = "Left", Collapsed = false })
    tpSec:Header({ Text = "Teleport Island" })

    local islandNames = {}
    for _, data in pairs(islandCoords) do
        islandNames[#islandNames+1] = data.name
    end
    table.sort(islandNames)

    tpSec:Dropdown({
        Name     = "Island Teleport",
        Search   = true,
        Multi    = false,
        Required = false,
        Options  = islandNames,
        Default  = nil,
        Callback = function(selectedName)
            SelectedIslandName = selectedName
        end
    }, "IslandTeleportDropdown")

    local tpToggleRef
    tpToggleRef = tpSec:Toggle({
        Name = "Teleport to Island",
        Default = false,
        Callback = function(v)
            if not v then return end
            local ok, msg = Teleport.ToIsland(ctx, islandCoords, SelectedIslandName)
            if not ok then
                ctx.Notify("warning", "Teleport", msg or "Gagal teleport.", 4)
            end
            task.defer(function()
                pcall(function() tpToggleRef:UpdateState(false) end)
            end)
        end
    }, "TeleportToIslandToggle")

    -- Player
    local plSec = tab:Section({ Side = "Left", Collapsed = false })
    plSec:Header({ Text = "Teleport Player" })

    local function buildPlayerList()
        local list = {}
        for _, plr in ipairs(ctx.Services.Players:GetPlayers()) do
            if plr ~= ctx.LocalPlayer then
                list[#list+1] = plr.Name
            end
        end
        table.sort(list)
        return list
    end

    local playerDropdown
    playerDropdown = plSec:Dropdown({
        Name     = "Select Player",
        Search   = true,
        Multi    = false,
        Required = false,
        Options  = buildPlayerList(),
        Default  = nil,
        Callback = function(name)
            SelectedPlayerName = name
        end
    }, "TeleportPlayerDropdown")

    plSec:Button({
        Name = "Refresh Player List",
        Callback = function()
            if playerDropdown and playerDropdown.ClearOptions and playerDropdown.InsertOptions then
                playerDropdown:ClearOptions()
                playerDropdown:InsertOptions(buildPlayerList())
            end
        end
    })

    local tpPlToggle
    tpPlToggle = plSec:Toggle({
        Name = "Teleport to Player",
        Default = false,
        Callback = function(v)
            if not v then return end
            local ok, msg = Teleport.ToPlayer(ctx, SelectedPlayerName)
            if not ok then
                ctx.Notify("warning", "Teleport", msg or "Gagal teleport.", 4)
            end
            task.defer(function()
                pcall(function() tpPlToggle:UpdateState(false) end)
            end)
        end
    }, "TeleportToPlayerToggle")
end
