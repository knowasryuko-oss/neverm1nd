-- /ui/init.lua
-- Builds MacLib window + tabs, then calls per-tab UI builders.

return function(ctx, modules)
    -- load MacLib UI lib
    local MacLib = loadstring(game:HttpGet(ctx.BaseUrl .. "MacUi/main.lua"))()

    -- create window
    ctx.State.MainWindow = MacLib:Window({
        Title = "FishIt MacLib",
        Subtitle = "Blatant + Auto",
        Size = UDim2.fromOffset(520, 370),
        DragStyle = 2,
        DisabledWindowControls = {},
        ShowUserInfo = false,
        Keybind = Enum.KeyCode.RightControl,
    })

    -- build tabs
    local tabGroup = ctx.State.MainWindow:TabGroup()

    local tabs = {
        auto     = tabGroup:Tab({ Name = "Auto Fishing", Image = "fish" }),
        shop     = tabGroup:Tab({ Name = "Shopping",     Image = "shopping-cart" }),
        teleport = tabGroup:Tab({ Name = "Teleport",     Image = "map-pin" }),
        backpack = tabGroup:Tab({ Name = "Backpack",     Image = "backpack" }),
        webhook  = tabGroup:Tab({ Name = "Webhook",      Image = "bell" }),
        misc     = tabGroup:Tab({ Name = "Misc.",        Image = "settings" }),
    }

    -- store on ctx for other ui files if needed
    ctx.State.Tabs = tabs

    -- init AJOMOK toggle button (optional)
    local okToggle, toggleInit = pcall(function()
        return ctx.RequireHttp("ui/toggle_button.lua")
    end)
    if okToggle and type(toggleInit) == "function" then
        pcall(function() toggleInit(ctx) end)
    end

    -- init per-tab UI
    ctx.RequireHttp("ui/auto.lua")(ctx, modules, tabs.auto)
    ctx.RequireHttp("ui/shopping.lua")(ctx, modules, tabs.shop)
    ctx.RequireHttp("ui/teleport.lua")(ctx, modules, tabs.teleport)
    ctx.RequireHttp("ui/backpack.lua")(ctx, modules, tabs.backpack)
    ctx.RequireHttp("ui/webhook.lua")(ctx, modules, tabs.webhook)
    ctx.RequireHttp("ui/misc.lua")(ctx, modules, tabs.misc)

    -- enable anti-afk by default
    if modules and modules.auto_fishing and modules.auto_fishing.Init then
        -- nothing
    end

    tabs.auto:Select()
end
