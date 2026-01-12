-- /functions/hide_vfx.lua
-- Hide all rod VFX (VFX clone) by Parent=nil (mirror script lain).

local HideVFX = {}

HideVFX._enabled = false
HideVFX._conn = nil

local function isVFXClone(inst)
    local vfxFolder = game:GetService("ReplicatedStorage"):FindFirstChild("VFX")
    if not vfxFolder then return false end
    if not inst or not inst.Name then return false end
    return vfxFolder:FindFirstChild(inst.Name) ~= nil
end

local function removeVFX(inst)
    if not inst then return end
    -- Parent=nil (tidak destroy, biar tidak error restore)
    pcall(function() inst.Parent = nil end)
end

function HideVFX.SetEnabled(ctx, enabled)
    enabled = enabled and true or false
    HideVFX._enabled = enabled

    if HideVFX._conn then
        HideVFX._conn:Disconnect()
        HideVFX._conn = nil
    end

    if not enabled then
        -- OFF: tidak bisa restore VFX yang sudah dihapus, VFX baru akan muncul normal
        return
    end

    -- Hapus semua VFX clone di workspace
    for _, inst in ipairs(workspace:GetDescendants()) do
        if isVFXClone(inst) then
            removeVFX(inst)
        end
    end

    -- Hapus VFX clone yang baru muncul
    HideVFX._conn = workspace.DescendantAdded:Connect(function(inst)
        if not HideVFX._enabled then return end
        if isVFXClone(inst) then
            removeVFX(inst)
        end
    end)
end

return HideVFX
