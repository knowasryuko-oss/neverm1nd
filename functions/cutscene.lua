-- /functions/cutscene.lua
-- Disable cutscenes (spams RE/StopCutscene while enabled)

local Cutscene = {}

function Cutscene.Init(ctx)
    Cutscene._running = false
end

function Cutscene.SetEnabled(ctx, enabled)
    enabled = enabled and true or false
    ctx.Config.DisableCutscenes = enabled

    if enabled then
        Cutscene.Start(ctx)
    end
end

function Cutscene.Start(ctx)
    if Cutscene._running then return end
    Cutscene._running = true

    task.spawn(function()
        while ctx.Config.DisableCutscenes do
            pcall(function()
                ctx.Events.stopScene:FireServer()
            end)
            task.wait(0.3)
        end
        Cutscene._running = false
    end)
end

return Cutscene
