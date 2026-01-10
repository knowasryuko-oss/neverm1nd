-- /functions/auto_totem.lua
-- Auto 9X Totem spawn (cross pattern, teleport player, restore pos).
-- Offset 90, auto fly/walk on water ON/OFF.

local AutoTotem = {}

AutoTotem._running = false
AutoTotem._flyConn = nil
AutoTotem._oldPlatform = nil

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

-- Pola offset: pusat, kanan, kiri, depan, belakang, atas, bawah, kanan-depan, kiri-belakang
local function getOffsets(distance)
    distance = tonumber(distance) or 90
    return {
        Vector3.new(0, 0, 0),
        Vector3.new(distance, 0, 0),
        Vector3.new(-distance, 0, 0),
        Vector3.new(0, 0, distance),
        Vector3.new(0, 0, -distance),
        Vector3.new(0, distance, 0),
        Vector3.new(0, -distance, 0),
        Vector3.new(distance, 0, distance),
        Vector3.new(-distance, 0, -distance),
    }
end

-- Simple fly/walk on water: set PlatformStand true, restore after
local function enableFly(ctx)
    local char = ctx.LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    AutoTotem._oldPlatform = hum.PlatformStand
    hum.PlatformStand = true
end

local function disableFly(ctx)
    local char = ctx.LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if AutoTotem._oldPlatform ~= nil then
        hum.PlatformStand = AutoTotem._oldPlatform
    else
        hum.PlatformStand = false
    end
end

function AutoTotem.Start(ctx, totemId, distance)
    print("[AutoTotem] Start called", totemId, distance)
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
    local offsets = getOffsets(distance)
    local n = math.min(9, #uuids, #offsets)

    -- Aktifkan fly/walk on water
    enableFly(ctx)

    -- Pause FPS Booster to avoid re-entrancy
    if ctx.modules and ctx.modules.fps_booster and ctx.modules.fps_booster.Pause then
        ctx.modules.fps_booster.Pause()
    end

    for i = 1, n do
        if not AutoTotem._running then break end
        local pos = center + offsets[i]
        hrp.CFrame = CFrame.new(pos)
        print("[AutoTotem] SPAWN TOTEM:", uuids[i], type(uuids[i]))
        pcall(function()
            ctx.net:WaitForChild("RE/SpawnTotem"):FireServer(uuids[i])
        end)
        task.wait(2.5) -- delay 2 detik antar spawn
    end

    hrp.CFrame = CFrame.new(center)
    disableFly(ctx)
    ctx.Notify("success", "9X Totem", "Totem spawn selesai.", 4)
    AutoTotem._running = false

    if ctx.modules and ctx.modules.fps_booster and ctx.modules.fps_booster.Resume then
        ctx.modules.fps_booster.Resume(ctx)
    end
end

function AutoTotem.Stop(ctx)
    print("[AutoTotem] Stop called")
    AutoTotem._running = false
    disableFly(ctx)
end

return AutoTotem
