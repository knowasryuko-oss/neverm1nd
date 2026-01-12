-- /functions/hide_vfx.lua
-- Hide all rod VFX (ParticleEmitter) from ReplicatedStorage.VFX clones in workspace.

local HideVFX = {}

HideVFX._enabled = false
HideVFX._conn = nil
HideVFX._cache = {}

local function isVFXClone(inst)
    -- VFX rod biasanya parent = workspace, name sama dengan template di ReplicatedStorage.VFX
    local vfxFolder = game:GetService("ReplicatedStorage"):FindFirstChild("VFX")
    if not vfxFolder then return false end
    if not inst or not inst.Name then return false end
    return vfxFolder:FindFirstChild(inst.Name) ~= nil
end

local function disableVFX(inst)
    if not inst then return end
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("ParticleEmitter") then
            if HideVFX._cache[d] == nil then
                HideVFX._cache[d] = d.Enabled
            end
            d.Enabled = false
        end
    end
end

local function restoreVFX()
    for d, enabled in pairs(HideVFX._cache) do
        if typeof(d) == "Instance" and d.Parent and d:IsA("ParticleEmitter") then
            d.Enabled = enabled
        end
    end
    HideVFX._cache = {}
end

function HideVFX.SetEnabled(ctx, enabled)
    enabled = enabled and true or false
    HideVFX._enabled = enabled

    if HideVFX._conn then
        HideVFX._conn:Disconnect()
        HideVFX._conn = nil
    end

    if not enabled then
        restoreVFX()
        return
    end

    -- Hide all existing VFX clones in workspace
    for _, inst in ipairs(workspace:GetDescendants()) do
        if isVFXClone(inst) then
            disableVFX(inst)
        end
    end

    -- Hide future VFX clones
    HideVFX._conn = workspace.DescendantAdded:Connect(function(inst)
        if not HideVFX._enabled then return end
        if isVFXClone(inst) then
            disableVFX(inst)
        end
    end)
end

return HideVFX
