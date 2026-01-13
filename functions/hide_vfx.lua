-- /functions/hide_vfx.lua
-- Hide all rod VFX (VFX clone + skin rod in !!!EQUIPPED_TOOL!!!) by disabling ParticleEmitter, Trail, Beam, Light.

local HideVFX = {}

HideVFX._enabled = false
HideVFX._conn = nil
HideVFX._toolConn = nil
HideVFX._cache = {}

local function isVFXClone(inst)
    local vfxFolder = game:GetService("ReplicatedStorage"):FindFirstChild("VFX")
    if not vfxFolder then return false end
    if not inst or not inst.Name then return false end
    return vfxFolder:FindFirstChild(inst.Name) ~= nil
end

local function disableVFX(inst)
    if not inst then return end
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam")
        or d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
            if HideVFX._cache[d] == nil then
                HideVFX._cache[d] = d.Enabled
            end
            d.Enabled = false
        end
    end
end

local function restoreVFX()
    for d, enabled in pairs(HideVFX._cache) do
        if typeof(d) == "Instance" and d.Parent and d.Enabled ~= nil then
            d.Enabled = enabled
        end
    end
    HideVFX._cache = {}
end

local function getEquippedTool()
    local charFolder = workspace:FindFirstChild("Characters")
    local char = charFolder and charFolder:FindFirstChild(game.Players.LocalPlayer.Name)
    if not char then char = game.Players.LocalPlayer.Character end
    if not char then return nil end
    return char:FindFirstChild("!!!EQUIPPED_TOOL!!!")
end

function HideVFX.SetEnabled(ctx, enabled)
    enabled = enabled and true or false
    HideVFX._enabled = enabled

    if HideVFX._conn then
        HideVFX._conn:Disconnect()
        HideVFX._conn = nil
    end
    if HideVFX._toolConn then
        HideVFX._toolConn:Disconnect()
        HideVFX._toolConn = nil
    end

    if not enabled then
        restoreVFX()
        return
    end

    -- Hide all VFX clone in workspace
    for _, inst in ipairs(workspace:GetDescendants()) do
        if isVFXClone(inst) then
            disableVFX(inst)
        end
    end

    -- Hide all VFX in equipped tool
    local tool = getEquippedTool()
    if tool then
        disableVFX(tool)
        HideVFX._toolConn = tool.DescendantAdded:Connect(function(inst)
            if not HideVFX._enabled then return end
            if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam")
            or inst:IsA("PointLight") or inst:IsA("SpotLight") or inst:IsA("SurfaceLight") then
                if HideVFX._cache[inst] == nil then
                    HideVFX._cache[inst] = inst.Enabled
                end
                inst.Enabled = false
            end
        end)
    end

    -- Hide future VFX clones in workspace
    HideVFX._conn = workspace.DescendantAdded:Connect(function(inst)
        if not HideVFX._enabled then return end
        if isVFXClone(inst) then
            disableVFX(inst)
        end
    end)
end

return HideVFX
