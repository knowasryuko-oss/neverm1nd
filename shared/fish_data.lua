-- /shared/fish_data.lua
-- Loads fish.luau from GitHub and builds lookup tables.

local FISH_DATA_URL = "https://raw.githubusercontent.com/knowasryuko-oss/neverm1nd/main/data/fish.luau"

local function buildIndex(tbl)
    local byId = {}
    local byName = {}

    if type(tbl) ~= "table" then
        return byId, byName
    end

    for _, entry in pairs(tbl) do
        if type(entry) == "table" and type(entry.Data) == "table" then
            local id = entry.Data.Id
            local name = entry.Data.Name
            if id ~= nil then
                byId[tonumber(id)] = entry
            end
            if type(name) == "string" then
                byName[name] = entry
            end
        end
    end

    return byId, byName
end

local FishData = {}

function FishData.Load(ctx)
    if FishData._loaded then
        return FishData
    end
    FishData._loaded = true

    local ok, src = pcall(function()
        return game:HttpGet(FISH_DATA_URL)
    end)
    if not ok or type(src) ~= "string" then
        FishData.Raw = nil
        FishData.ById, FishData.ByName = {}, {}
        return FishData
    end

    local ok2, tbl = pcall(function()
        return loadstring(src, "@fish.luau")()
    end)

    if not ok2 or type(tbl) ~= "table" then
        FishData.Raw = nil
        FishData.ById, FishData.ByName = {}, {}
        return FishData
    end

    FishData.Raw = tbl
    FishData.ById, FishData.ByName = buildIndex(tbl)
    return FishData
end

function FishData.GetById(ctx, id)
    FishData.Load(ctx)
    return FishData.ById[tonumber(id)]
end

function FishData.GetByName(ctx, name)
    FishData.Load(ctx)
    return FishData.ByName[name]
end

function FishData.GetByIdOrName(ctx, id, name)
    FishData.Load(ctx)
    if id ~= nil then
        local e = FishData.ById[tonumber(id)]
        if e then return e end
    end
    if type(name) == "string" then
        return FishData.ByName[name]
    end
    return nil
end

return FishData
