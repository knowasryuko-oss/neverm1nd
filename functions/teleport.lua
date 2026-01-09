-- /functions/teleport.lua
-- Teleport helpers (island + player)

local Teleport = {}

function Teleport.Init(ctx)
    -- nothing required
end

local function getHRP(ctx)
    local charFolder = workspace:FindFirstChild("Characters")
    local char = charFolder and charFolder:FindFirstChild(ctx.LocalPlayer.Name)
    if not char then char = ctx.LocalPlayer.Character end
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 2)
end

local function getCharacterFromServerPlayer(plr)
    local charFolder = workspace:FindFirstChild("Characters")
    local char = charFolder and charFolder:FindFirstChild(plr.Name)
    if char then return char end
    return plr.Character
end

function Teleport.ToIsland(ctx, islandCoords, name)
    if not name then
        return false, "Belum pilih island."
    end

    local targetPos
    for _, data in pairs(islandCoords) do
        if data.name == name then
            targetPos = data.position
            break
        end
    end
    if not targetPos then
        return false, "Island tidak ditemukan."
    end

    local hrp = getHRP(ctx)
    if not hrp then
        return false, "HumanoidRootPart tidak ditemukan."
    end
    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))
    return true
end

function Teleport.ToPlayer(ctx, playerName)
    if not playerName or playerName == "" then
        return false, "Belum pilih player."
    end

    local plr = ctx.Services.Players:FindFirstChild(playerName)
    if not plr then
        return false, "Player tidak ditemukan."
    end
    if plr == ctx.LocalPlayer then
        return false, "Tidak bisa ke diri sendiri."
    end

    local myHrp = getHRP(ctx)
    if not myHrp then
        return false, "HRP kamu tidak ditemukan."
    end

    local char = getCharacterFromServerPlayer(plr)
    if not char then
        return false, "Character target tidak ditemukan."
    end

    local targetHrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 2)
    if not targetHrp then
        return false, "HRP target tidak ditemukan."
    end

    myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 4)
    return true
end

return Teleport
