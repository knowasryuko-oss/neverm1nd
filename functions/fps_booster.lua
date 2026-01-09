-- /functions/fps_booster.lua
-- One-toggle FPS booster (world-only). Keeps UI normal.

local FpsBooster = {}

function FpsBooster.Init(ctx)
    FpsBooster._enabled = false
    FpsBooster._conn = nil

    FpsBooster._cache = {
        Lighting = {},
        PostFx = {},
        Parts = {},
        Decals = {},
        FX = {},
        HeadScale = nil,
    }
end

local function grayscaleColor(c3)
    local y = (0.299*c3.R) + (0.587*c3.G) + (0.114*c3.B)
    return Color3.new(y, y, y)
end

local function cacheLightingOnce(ctx)
    if FpsBooster._cache.Lighting._cached then return end
    FpsBooster._cache.Lighting._cached = true

    local L = ctx.Services.Lighting
    FpsBooster._cache.Lighting.GlobalShadows = L.GlobalShadows
    FpsBooster._cache.Lighting.FogStart = L.FogStart
    FpsBooster._cache.Lighting.FogEnd = L.FogEnd
    pcall(function() FpsBooster._cache.Lighting.EnvironmentDiffuseScale = L.EnvironmentDiffuseScale end)
    pcall(function() FpsBooster._cache.Lighting.EnvironmentSpecularScale = L.EnvironmentSpecularScale end)
end

local function applyLighting(ctx)
    cacheLightingOnce(ctx)
    local L = ctx.Services.Lighting

    pcall(function() L.GlobalShadows = false end)
    pcall(function() L.FogStart = 0 end)
    pcall(function() L.FogEnd = 9e9 end)
    pcall(function() L.EnvironmentDiffuseScale = 0 end)
    pcall(function() L.EnvironmentSpecularScale = 0 end)

    for _, inst in ipairs(L:GetDescendants()) do
        if inst:IsA("BloomEffect")
        or inst:IsA("DepthOfFieldEffect")
        or inst:IsA("SunRaysEffect")
        or inst:IsA("ColorCorrectionEffect")
        or inst:IsA("Atmosphere") then
            if FpsBooster._cache.PostFx[inst] == nil then
                FpsBooster._cache.PostFx[inst] = { Enabled = inst.Enabled }
            end
            pcall(function() inst.Enabled = false end)
        end
    end
end

local function restoreLighting(ctx)
    local L = ctx.Services.Lighting
    if not FpsBooster._cache.Lighting._cached then return end

    pcall(function() L.GlobalShadows = FpsBooster._cache.Lighting.GlobalShadows end)
    pcall(function() L.FogStart = FpsBooster._cache.Lighting.FogStart end)
    pcall(function() L.FogEnd = FpsBooster._cache.Lighting.FogEnd end)
    pcall(function() L.EnvironmentDiffuseScale = FpsBooster._cache.Lighting.EnvironmentDiffuseScale end)
    pcall(function() L.EnvironmentSpecularScale = FpsBooster._cache.Lighting.EnvironmentSpecularScale end)

    for inst, data in pairs(FpsBooster._cache.PostFx) do
        if typeof(inst) == "Instance" and inst.Parent then
            pcall(function() inst.Enabled = data.Enabled end)
        end
    end
end

local function applySmallHead(ctx, state)
    local char = ctx.LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local headScale = hum:FindFirstChild("HeadScale")
    if not headScale then return end

    if FpsBooster._cache.HeadScale == nil then
        FpsBooster._cache.HeadScale = headScale.Value
    end

    if state then
        headScale.Value = 0.5
    else
        if type(FpsBooster._cache.HeadScale) == "number" then
            headScale.Value = FpsBooster._cache.HeadScale
        end
    end
end

local function applyToInstance(inst)
    -- VFX off
    if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam")
    or inst:IsA("PointLight") or inst:IsA("SpotLight") or inst:IsA("SurfaceLight") then
        if FpsBooster._cache.FX[inst] == nil then
            FpsBooster._cache.FX[inst] = { Enabled = inst.Enabled }
        end
        pcall(function() inst.Enabled = false end)
        return
    end

    -- hide decals/textures
    if inst:IsA("Decal") or inst:IsA("Texture") then
        if FpsBooster._cache.Decals[inst] == nil then
            FpsBooster._cache.Decals[inst] = { Transparency = inst.Transparency }
        end
        pcall(function() inst.Transparency = 1 end)
        return
    end

    -- parts -> plastic + no shadow + grayscale
    if inst:IsA("BasePart") then
        if FpsBooster._cache.Parts[inst] == nil then
            FpsBooster._cache.Parts[inst] = {
                Material = inst.Material,
                CastShadow = inst.CastShadow,
                Reflectance = inst.Reflectance,
                Color = inst.Color,
            }
        end
        pcall(function()
            inst.Material = Enum.Material.Plastic
            inst.CastShadow = false
            inst.Reflectance = 0
            inst.Color = grayscaleColor(inst.Color)
        end)
    end
end

local function applyAll(ctx)
    applyLighting(ctx)

    for _, inst in ipairs(workspace:GetDescendants()) do
        applyToInstance(inst)
    end

    if FpsBooster._conn then
        FpsBooster._conn:Disconnect()
        FpsBooster._conn = nil
    end

    FpsBooster._conn = workspace.DescendantAdded:Connect(function(inst)
        if not FpsBooster._enabled then return end
        applyToInstance(inst)
    end)

    applySmallHead(ctx, true)
end

local function restoreAll(ctx)
    if FpsBooster._conn then
        FpsBooster._conn:Disconnect()
        FpsBooster._conn = nil
    end

    applySmallHead(ctx, false)
    restoreLighting(ctx)

    for inst, data in pairs(FpsBooster._cache.FX) do
        if typeof(inst) == "Instance" and inst.Parent and inst.Enabled ~= nil then
            pcall(function() inst.Enabled = data.Enabled end)
        end
    end

    for inst, data in pairs(FpsBooster._cache.Decals) do
        if typeof(inst) == "Instance" and inst.Parent then
            pcall(function() inst.Transparency = data.Transparency end)
        end
    end

    for inst, data in pairs(FpsBooster._cache.Parts) do
        if typeof(inst) == "Instance" and inst.Parent and inst:IsA("BasePart") then
            pcall(function()
                inst.Material = data.Material
                inst.CastShadow = data.CastShadow
                inst.Reflectance = data.Reflectance
                inst.Color = data.Color
            end)
        end
    end
end

function FpsBooster.SetEnabled(ctx, enabled)
    enabled = enabled and true or false
    ctx.Config.FpsBooster = enabled
    FpsBooster._enabled = enabled

    if enabled then
        applyAll(ctx)
        ctx.Notify("success", "Fps Booster", "Enabled (world only).", 4)
    else
        restoreAll(ctx)
        ctx.Notify("info", "Fps Booster", "Disabled (restored cached).", 4)
    end
end

return FpsBooster
