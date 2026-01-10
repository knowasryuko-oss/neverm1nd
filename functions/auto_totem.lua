-- /functions/auto_totem.lua
-- Auto 9X Totem spawn (cross pattern, teleport player, restore pos).
-- Dropdown hanya: "Shiny", "Luck", "Mutation"

local AutoTotem = {}

AutoTotem._running = false

function AutoTotem.Init(ctx)
    AutoTotem._running = false
end

-- List string, sesuai script lain
function AutoTotem.GetTotemNameList()
    return { "Shiny", "Luck", "Mutation" }
end

-- Ambil semua UUID dari inventory Totems yang Name/Identifier cocok dengan dropdown
local function getTotemUUIDs(ctx, totemName)
    local dataRep = ctx.Replion.Client:WaitReplion("Data")
    if not dataRep then return {} end
    local inv = dataRep:Get("Inventory")
    local totems = inv and inv["Totems"]
    if type(totems) ~= "table" then return {} end
    local uuids = {}
    for uuid, item in pairs(totems) do
        -- Cek field mana yang cocok dengan dropdown
        if item then
            -- Cek Name, Identifier, Type, dsb
            if (item.Name == totemName)
            or (item.Identifier == totemName)
            or (item.Type == totemName)
            then
                uuids[#uuids+1] = uuid
            end
        end
    end
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

function AutoTotem.Start(ctx, totemName, distance)
    print("[AutoTotem] Start called", totemName, distance)
    if AutoTotem._running then return end
    AutoTotem._running = true

    local uuids = getTotemUUIDs(ctx, totemName)
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
        pcall(function()
            ctx.net:WaitForChild("RE/SpawnTotem"):FireServer(uuids[i])
        end)
        task.wait(0.3)
    end

    hrp.CFrame = CFrame.new(center)
    ctx.Notify("success", "9X Totem", "Totem spawn selesai.", 4)
    AutoTotem._running = false

    -- Resume FPS Booster
    if ctx.modules and ctx.modules.fps_booster and ctx.modules.fps_booster.Resume then
        ctx.modules.fps_booster.Resume(ctx)
    end
end

function AutoTotem.Stop(ctx)
    print("[AutoTotem] Stop called")
    AutoTotem._running = false
end

return AutoTotem
