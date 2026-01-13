-- /functions/hide_vfx.lua
-- Hide all rod VFX (ParticleEmitter, Trail, Beam, Light, MeshPart/Part Transparency)
-- and disable all rod animations in AnimationsModule.

local HideVFX = {}

HideVFX._enabled = false
HideVFX._conns = {}
HideVFX._cache = {}
HideVFX._animCache = {}

local function disableVFX(inst)
    if not inst then return end
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam")
        or d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
            if HideVFX._cache[d] == nil then
                HideVFX._cache[d] = d.Enabled
            end
            d.Enabled = false
        elseif d:IsA("MeshPart") or d:IsA("Part") or d:IsA("UnionOperation") then
            if HideVFX._cache[d] == nil then
                HideVFX._cache[d] = d.Transparency
            end
            d.Transparency = 1
        end
    end
end

local function restoreVFX()
    for d, v in pairs(HideVFX._cache) do
        if typeof(d) == "Instance" and d.Parent then
            if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam")
            or d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
                d.Enabled = v
            elseif d:IsA("MeshPart") or d:IsA("Part") or d:IsA("UnionOperation") then
                d.Transparency = v
            end
        end
    end
    HideVFX._cache = {}
end

local function getAllVFXFolders()
    local folders = {}
    -- Tool
    local charFolder = workspace:FindFirstChild("Characters")
    local char = charFolder and charFolder:FindFirstChild(game.Players.LocalPlayer.Name)
    if not char then char = game.Players.LocalPlayer.Character end
    if char then
        local tool = char:FindFirstChild("!!!EQUIPPED_TOOL!!!")
        if tool then
            folders[#folders+1] = tool
        end
    end
    -- Workspace VFX/Effect folders
    for _, obj in ipairs(workspace:GetChildren()) do
        local name = obj.Name:lower()
        if name:find("vfx") or name:find("effect") then
            folders[#folders+1] = obj
        end
    end
    return folders
end

-- Disable all rod animations in AnimationsModule
local function disableRodAnims(ctx, state)
    local anims = ctx.AnimationsModule
    if type(anims) ~= "table" then return end
    for name, data in pairs(anims) do
        if type(data) == "table" and (
            name:find("RodThrow") or name:find("FishCaught") or name:find("ReelingIdle")
            or name:find("ReelStart") or name:find("ReelIntermission") or name:find("StartRodCharge")
            or name:find("LoopedRodCharge") or name:find("EquipIdle") or name:find("Failure")
        ) then
            if HideVFX._animCache[name] == nil then
                HideVFX._animCache[name] = data.Disabled or false
            end
            data.Disabled = state and true or HideVFX._animCache[name]
        end
    end
end

function HideVFX.SetEnabled(ctx, enabled)
    enabled = enabled and true or false
    HideVFX._enabled = enabled

    -- Disconnect all listeners
    for _, conn in ipairs(HideVFX._conns) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    HideVFX._conns = {}

    if not enabled then
        restoreVFX()
        disableRodAnims(ctx, false)
        return
    end

    -- Hide all VFX in all folders
    local folders = getAllVFXFolders()
    for _, folder in ipairs(folders) do
        disableVFX(folder)
        -- Listen for new VFX in each folder
        table.insert(HideVFX._conns, folder.DescendantAdded:Connect(function(inst)
            if not HideVFX._enabled then return end
            disableVFX(inst)
        end))
    end

    -- Hide future VFX/Effect folders in workspace
    table.insert(HideVFX._conns, workspace.ChildAdded:Connect(function(obj)
        if not HideVFX._enabled then return end
        local name = obj.Name:lower()
        if name:find("vfx") or name:find("effect") then
            disableVFX(obj)
            table.insert(HideVFX._conns, obj.DescendantAdded:Connect(function(inst)
                if not HideVFX._enabled then return end
                disableVFX(inst)
            end))
        end
    end))

    -- Disable all rod animations
    disableRodAnims(ctx, true)
end

return HideVFX
