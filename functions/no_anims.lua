-- /functions/no_anims.lua
-- Disables fishing-related animations in AnimationsModule (non-destructive, reversible).

local NoAnims = {}

function NoAnims.Init(ctx)
    NoAnims._cached = {} -- [name] = originalDisabledBool
end

local function shouldDisableAnim(name)
    if type(name) ~= "string" then return false end
    -- same idea as your old script: disable fish caught/failure and common fishing anim keys
    if name:find("FishCaught", 1, true) then return true end
    if name:find("FishingFailure", 1, true) then return true end
    if name:find("RodThrow", 1, true) then return true end
    if name:find("Reeling", 1, true) then return true end
    if name:find("ReelStart", 1, true) then return true end
    if name:find("ReelIntermission", 1, true) then return true end
    if name:find("StartRodCharge", 1, true) then return true end
    if name:find("LoopedRodCharge", 1, true) then return true end
    return false
end

function NoAnims.SetEnabled(ctx, enabled)
    enabled = enabled and true or false
    ctx.Config.NoFishingAnimations = enabled

    local anims = ctx.AnimationsModule
    if type(anims) ~= "table" then return end

    for name, data in pairs(anims) do
        if type(data) == "table" and shouldDisableAnim(name) then
            if NoAnims._cached[name] == nil then
                NoAnims._cached[name] = (data.Disabled == true)
            end
            if enabled then
                data.Disabled = true
            else
                data.Disabled = NoAnims._cached[name]
            end
        end
    end
end

return NoAnims
