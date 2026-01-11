-- /functions/auto_totem.lua
-- Auto 9X Totem spawn (array posisi absolut, idle 4 detik, NoClip+PlatformStand+Anchored ON).

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

-- Array posisi absolut (mirror script lain)
local function getPositions()
    return {
        Vector3.new(-2188.89, 53.49, 3671.06),
        Vector3.new(95.35161590576172, 53.49, 2850.99560546875),
        Vector3.new(34.34161376953125, 10.573726654052734, 2765.1455078125),
        Vector3.new(-2188.89, 154.49, 3671.06),
        Vector3.new(95.35161590576172, 154.49, 2850.99560546875),
        Vector3.new(34.34161376953125, 111.57373046875, 2765.1455078125),
        Vector3.new(-2188.89, -47.51, 3671.06),
        Vector3.new(95.35161590576172, -91.11627197265625, 2850.99560546875),
        Vector3.new(34.34161376953125, -91.41627502441406, 2765.1455078125),
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

local function setAnchored(hrp, state)
    if hrp then
        hrp.Anchored = state and true or false
    end
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

    local posOn = hrp.Position
    local positions = getPositions()
    local n = math.min(9, #uuids, #positions)

    setNoClip(ctx, true)
    setPlatformStand(ctx, true)

    if ctx.modules and ctx.modules.fps_booster and ctx.modules.fps_booster.Pause then
        ctx.modules.fps_booster.Pause()
    end

    for i = 1, n do
        if not AutoTotem._running then break end
        local pos = positions[i]
        hrp.CFrame = CFrame.new(pos)
        setAnchored(hrp, true)
        print("[AutoTotem] SPAWN TOTEM:", uuids[i], type(uuids[i]), "at", pos)
        pcall(function()
            ctx.net:WaitForChild("RE/SpawnTotem"):FireServer(uuids[i])
        end)
        task.wait(4)
        setAnchored(hrp, false)
    end

    hrp.CFrame = CFrame.new(posOn)
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
    local hrp = ctx.LocalPlayer.Character and ctx.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    setNoClip(ctx, false)
    setPlatformStand(ctx, false)
    setAnchored(hrp, false)
end

return AutoTotem
