-- /functions/merchant.lua
-- Traveling Merchant list builder + purchase.

local Merchant = {}

function Merchant.Init(ctx)
    -- nothing required now
end

local function getActiveIdMap(ctx)
    local rep = ctx.Replion.Client:WaitReplion("Merchant")
    if not rep then return {} end

    local ids
    pcall(function() ids = rep:GetExpect("Items") end)
    if type(ids) ~= "table" then
        pcall(function() ids = rep:Get({"Items"}) end)
    end
    if type(ids) ~= "table" then return {} end

    local map = {}
    for _, id in ipairs(ids) do
        id = tonumber(id)
        if id then map[id] = true end
    end
    return map
end

function Merchant.BuildOptions(ctx)
    local opts, labelToId = {}, {}
    local active = getActiveIdMap(ctx)

    for _, it in ipairs(ctx.MarketItemData) do
        if active[it.Id] then
            if not it.SkinCrate and it.Currency ~= "Robux" and not it.ProductId and it.Price then
                local name = it.DisplayName or it.Identifier or ("Item #" .. tostring(it.Id))
                local label = ("%s ($%s) | id=%d"):format(name, ctx.Utils.formatPrice(it.Price), it.Id)
                opts[#opts+1] = label
                labelToId[label] = it.Id
            end
        end
    end

    table.sort(opts)
    return opts, labelToId
end

local function getPurchaseMarketItemRF(ctx)
    local rf
    pcall(function()
        rf = ctx.net:WaitForChild("RF/PurchaseMarketItem")
    end)
    if rf then return rf end

    local ok, NetModule = pcall(function()
        return require(ctx.Services.ReplicatedStorage.Packages.Net)
    end)
    if ok and NetModule and NetModule.RemoteFunction then
        local ok2, remote = pcall(function()
            return NetModule:RemoteFunction("PurchaseMarketItem")
        end)
        if ok2 then return remote end
    end
    return nil
end

function Merchant.BuyById(ctx, id)
    id = tonumber(id)
    if not id then
        ctx.Notify("warning", "Traveling Merchant", "Item id tidak valid.", 3)
        return false
    end

    -- validate data
    local itFound
    for _, it in ipairs(ctx.MarketItemData) do
        if it.Id == id then itFound = it break end
    end
    if not itFound then
        ctx.Notify("danger", "Traveling Merchant", ("Item id %d tidak ditemukan."):format(id), 4)
        return false
    end
    if itFound.SkinCrate or itFound.Currency == "Robux" or itFound.ProductId then
        ctx.Notify("warning", "Traveling Merchant", "Item Robux/Crate/DevProduct (tidak support).", 4)
        return false
    end

    local rf = getPurchaseMarketItemRF(ctx)
    if not rf then
        ctx.Notify("danger", "Traveling Merchant", "RF PurchaseMarketItem tidak ditemukan.", 4)
        return false
    end

    local ok, res = pcall(function()
        return rf:InvokeServer(id)
    end)
    if not ok then
        ctx.Notify("danger", "Traveling Merchant", "InvokeServer error.", 4)
        return false
    end

    if res then
        ctx.Notify("success", "Traveling Merchant", "Completed purchase!", 3)
        return true
    else
        ctx.Notify("warning", "Traveling Merchant", "Purchase gagal/ditolak.", 4)
        return false
    end
end

return Merchant
