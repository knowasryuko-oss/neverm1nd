-- /functions/auto_totem.lua
-- Auto 9X Totem spawn (cross pattern, teleport player, restore pos).

local AutoTotem = {}

AutoTotem._running = false

function AutoTotem.Init(ctx)
    AutoTotem._running = false
end

local function getTotemDataList()
    local totemFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Totems")
    local list = {}
    if totemFolder then
        for _, mod in ipairs(totemFolder:GetChildren()) do
            if mod:IsA("ModuleScript") then
                local ok, data = pcall(function() return require(mod) end)
                if ok and type(data) == "table" and data.Data and data.Data.Name then
                    list[#list+1] = {
                        Name = data.Data.Name,
                        Id = data.Data.Id,
                        Icon = data.Data.Icon,
                        Range = data.Range or 100,
                        Module = mod,
                    }
                end
            end
        end
    end
    table.sort(list, function(a, b) return tostring(a.Name) < tostring(b.Name) end)
    return list
end

local function getTotemUUIDs(ctx, totemName)
    local dataRep = ctx.Replion.Client:WaitReplion("Data")
    if not dataRep then return {} end
    local items = dataRep:Get({"Inventory","Items"})
    if type(items) ~= "table" then return {} end
    local uuids = {}
    for _, item in ipairs(items) do
        if item and item.ItemType == "Totems" and item.Name == totemName and item.UUID then
            uuids[#uuids+1] = item.UUID
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

    -- Optional: pause FPS Booster to avoid re-entrancy
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
