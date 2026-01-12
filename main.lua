-- /main.lua
-- Entry point: loads shared ctx + functions + UI from your GitHub repo.

local BASE_URL = "https://raw.githubusercontent.com/knowasryuko-oss/neverm1nd/main/"

local function requireHttp(relPath)
    local src = game:HttpGet(BASE_URL .. relPath)
    local fn, err = loadstring(src, "@" .. relPath)
    if not fn then
        error(("Failed to load %s: %s"):format(relPath, tostring(err)))
    end
    return fn()
end

-- Shared
local buildCtx = requireHttp("shared/ctx.lua")
local ctx = buildCtx({
    BaseUrl = BASE_URL,
    RequireHttp = requireHttp,
})

-- Functions (modules)
local modules = {
    fps_booster  = requireHttp("functions/fps_booster.lua"),
    webhook      = requireHttp("functions/webhook.lua"),
    merchant     = requireHttp("functions/merchant.lua"),
    weather      = requireHttp("functions/weather.lua"),
    teleport     = requireHttp("functions/teleport.lua"),
    auto_fishing = requireHttp("functions/auto_fishing.lua"),
    auto_sell    = requireHttp("functions/auto_sell.lua"),
    favorites    = requireHttp("functions/favorites.lua"),
    anti_afk     = requireHttp("functions/anti_afk.lua"),
    cutscene     = requireHttp("functions/cutscene.lua"),
    hide_popup   = requireHttp("functions/hide_popup.lua"),
    no_anims     = requireHttp("functions/no_anims.lua"),
    -- auto_totem   = requireHttp("functions/auto_totem.lua"), -- PATCH: dinonaktifkan
}

ctx.modules = modules

-- Init modules (optional)
for name, mod in pairs(modules) do
    if type(mod) == "table" and type(mod.Init) == "function" then
        local ok, err = pcall(function()
            mod.Init(ctx)
        end)
        if not ok then
            warn(("Module Init failed (%s): %s"):format(name, tostring(err)))
        end
    end
end

-- UI init (builds window + tabs and wires callbacks)
local uiInit = requireHttp("ui/init.lua")
uiInit(ctx, modules)

-- PATCH: Jangan panggil tab Automation/9X Totem
--[[
do
    local tabGroup = ctx.State.MainWindow:TabGroup()
    local automationTab = tabGroup:Tab({ Name = "Automation", Image = "zap" })
    ctx.RequireHttp("ui/automation.lua")(ctx, modules, automationTab)
end
]]

return true
