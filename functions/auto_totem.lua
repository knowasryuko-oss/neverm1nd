-- /functions/auto_totem.lua
-- Auto 9X Totem spawn (offset mirror script lain, NoClip+PlatformStand+BodyPosition+BodyGyro, idle 3 detik).

local AutoTotem = {}

AutoTotem._running = false

function AutoTotem.Init(ctx)
    AutoTotem._running = false
end

function AutoTotem.GetTotemList()
    local totemFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Totems")
    local list = {}
    if totemFolder then
        for _, mod in ipairs(totemFolder:GetChildren()) do
            if mod:IsA("ModuleScript") then
                local ok, data = pcall(function() return require(mod) end)
                if ok and type(data) == "table" and data.Data and data.Data.Name and data.Data.Id then
                    list[#list+1] = { label = data.Data.Name, value = data.Data.Id }
                end
            end
        end
    end
    table.sort(list, function(a, b) return tostring(a.label) < tostring(b.label) end)
    return list
end

local function getTotemUUIDs(ctx, totemId)
    local dataRep = ctx.Replion.Client:WaitReplion("Data")
    if not dataRep then return {} end
    local inv = dataRep:Get("Inventory")
    local totems = inv and inv["Totems"]
    if type(totems) ~= "table" then return {} end
    local uuids = {}
    for _, item in ipairs(totems) do
        if item and tonumber(item.Id) == tonumber(totemId) and type(item.UUID) == "string" then
            uuids[#uuids+1] = item.UUID
        end
    end
    print("[AutoTotem] getTotemUUIDs for Id", totemId, "->", #uuids, "found:", table.concat(uuids, ", "))
    return uuids
end

-- Offset mirror dari script lain (relatif terhadap pusat)
local function getOffsets()
    return {
        Vector3.new(0, 0, 0),
        Vector3.new(100.6, 0, -8.29),
        Vector3.new(39.59, 0.69, -94.14),
        Vector3.new(0, 101, 0),
        Vector3.new(100.6, 101, -8.29),
        Vector3.new(39.59, 101.69, -94.14),
        Vector3.new(0, -101, 0),
        Vector3.new(100.6, -101, -8.29),
        Vector3.new(39.59, -101.3, -94.14),
    }
end

local function setPlatformStand(ctx, state)
    local char = ctx.LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.PlatformStand = state and true or false
end

local function setNoClip(ctx, state)
    local char = ctx.LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
        end
    end
end

local function setBodyPositionAndGyro(hrp, pos)
    local bp = Instance.new("BodyPosition")
    bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bp.Position = pos
    bp.P = 1e5
    bp.D = 1e3
    bp.Parent = hrp

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bg.CFrame = CFrame.new(pos)
    bg.P = 1e5
    bg.D = 1e3
    bg.Parent = hrp

    return bp, bg
end

function AutoTotem.Start(ctx, totemId, _distance)
    print("[AutoTotem] Start called", totemId)
    if AutoTotem._running then return end
    AutoTotem._running = true

    local uuids = getTotemUUIDs(ctx, totemId)
    if #uuids == 0 then
        ctx.Notify("warning", "9X Totem", "Tidak ada UUID totem di inventory.", 4)
        AutoTotem._running = false
        return
    end

    local hrp = ctx.LocalPlayer.Character and ctx.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        ctx.Notify("warning", "9X Totem", "Tidak bisa ambil posisi player.", 4)
        AutoTotem._running = false
        return
    end

    local center = hrp.Position
    local offsets = getOffsets()
    local n = math.min(9, #uuids, #offsets)

    setNoClip(ctx, true)
    setPlatformStand(ctx, true)

    if ctx.modules and ctx.modules.fps_booster and ctx.modules.fps_booster.Pause then
        ctx.modules.fps_booster.Pause()
    end

    for i = 1, n do
        if not AutoTotem._running then break end
        local pos = center + offsets[i]
        local bp, bg = setBodyPositionAndGyro(hrp, pos)
        task.wait(0.2)
        print("[AutoTotem] SPAWN TOTEM:", uuids[i], type(uuids[i]))
        pcall(function()
            ctx.net:WaitForChild("RE/SpawnTotem"):FireServer(uuids[i])
        end)
        task.wait(3)
        bp:Destroy()
        bg:Destroy()
    end

    hrp.CFrame = CFrame.new(center)
    setNoClip(ctx, false)
    setPlatformStand(ctx, false)
    ctx.Notify("success", "9X Totem", "Totem spawn selesai.", 4)
    AutoTotem._running = false

    if ctx.modules and ctx.modules.fps_booster and ctx.modules.fps_booster.Resume then
        ctx.modules.fps_booster.Resume(ctx)
    end
end

function AutoTotem.Stop(ctx)
    print("[AutoTotem] Stop called")
    AutoTotem._running = false
    setNoClip(ctx, false)
    setPlatformStand(ctx, false)
end

return AutoTotem
