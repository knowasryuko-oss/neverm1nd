-- /functions/anti_afk.lua
-- Anti-AFK module (VirtualUser)

local AntiAFK = {}

function AntiAFK.Init(ctx)
    AntiAFK._conn = nil
end

function AntiAFK.SetEnabled(ctx, enabled)
    enabled = enabled and true or false
    ctx.Config.AntiAFK = enabled

    if AntiAFK._conn then
        AntiAFK._conn:Disconnect()
        AntiAFK._conn = nil
    end

    if not enabled then
        return
    end

    AntiAFK._conn = ctx.LocalPlayer.Idled:Connect(function()
        pcall(function()
            local cam = workspace.CurrentCamera
            if not cam then return end
            ctx.Services.VirtualUser:Button2Down(Vector2.new(0, 0), cam.CFrame)
            task.wait(1)
            ctx.Services.VirtualUser:Button2Up(Vector2.new(0, 0), cam.CFrame)
        end)
    end)
end

return AntiAFK
