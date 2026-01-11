-- /functions/auto_totem.lua
-- Auto 9X Totem spawn (offset mirror script lain, idle 3 detik, NoClip+PlatformStand+Anchored ON, restore ke saved_location).

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

-- Array offset hasil konversi dari posisi absolut (tanpa pusat)
local offsets = {
    Vector3.new(-48.89, -0.01, 46.06),      -- Totem 1
    Vector3.new(51.71, -0.01, 37.78),       -- Totem 2
    Vector3.new(-9.30, 0.69, -48.07),       -- Totem 3
    Vector3.new(-48.89, 100.99, 46.06),     -- Totem 4
    Vector3.new(51.71, 100.99, 37.78),      -- Totem 5
    Vector3.new(-9.30, 101.69, -48.07),     -- Totem 6
    Vector3.new(-48.89, 94.95, 46.06),      -- Totem 7
    Vector3.new(51.71, -102.01, 37.78),     -- Totem 8
    Vector3.new(-9.30, -103.31, -48.07),    -- Totem 9
}

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

    local saved_location = hrp.Position
    local n = math.min(9, #uuids, #offsets)

    setNoClip(ctx, true)
    setPlatformStand(ctx, true)

    if ctx.modules and ctx.modules.fps_booster and ctx.modules.fps_booster.Pause then
        ctx.modules.fps_booster.Pause()
    end

    for i = 1, n do
        if not AutoTotem._running then break end
        local pos = saved_location + offsets[i]
        hrp.CFrame = CFrame.new(pos)
        setAnchored(hrp, true)
        print("[AutoTotem] SPAWN TOTEM:", uuids[i], type(uuids[i]), "at", pos)
        pcall(function()
            ctx.net:WaitForChild("RE/SpawnTotem"):FireServer(uuids[i])
        end)
        task.wait(3)
        setAnchored(hrp, false)
    end

    hrp.CFrame = CFrame.new(saved_location)
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
