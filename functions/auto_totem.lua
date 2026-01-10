-- /functions/auto_totem.lua
-- Auto 9X Totem spawn (cross pattern, teleport player, restore pos).
-- Fix: inventory totems = array, UUID di field item.UUID

local AutoTotem = {}

AutoTotem._running = false

function AutoTotem.Init(ctx)
    AutoTotem._running = false
end

-- Ambil list nama totem dari ReplicatedStorage.Totems
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

-- Ambil semua UUID dari inventory Totems yang Id-nya sama dengan selectedTotemId
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

local function getOffsets(distance)
    distance = tonumber(distance) or 100
    return {
        Vector3.new(0, 0, 0),
        Vector3.new(distance, 0, 0),
        Vector3.new(-distance, 0, 0),
        Vector3.new(0, 0, distance),
        Vector3.new(0, 0, -distance),
        Vector3.new(distance, 0, distance),
        Vector3.new(-distance, 0, -distance),
        Vector3.new(distance, 0, -distance),
        Vector3.new(-distance, 0, distance),
    }
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
            ctx.net:WaitForChild("RE/SpawnTotem"):FireServer(uuids[i]) -- UUID string!
        end)
        task.wait(0.3)
    end

    hrp.CFrame = CFrame.new(center)
    ctx.Notify("success", "9X Totem", "Totem spawn selesai.", 4)
    AutoTotem._running = false

    if ctx.modules and ctx.modules.fps_booster and ctx.modules.fps_booster.Resume then
        ctx.modules.fps_booster.Resume(ctx)
    end
end

function AutoTotem.Stop(ctx)
    print("[AutoTotem] Stop called")
    AutoTotem._running = false
end

return AutoTotem
