-- /functions/webhook.lua
-- Mutation policy: ONLY official variants via FishCaught VariantId (string).
-- Special flags (e.g., Shiny=true) are ignored => shown as None.

local Webhook = {}

local THUMB_TTL = 60 * 10
local thumbCache = {}
local thumbCacheTime = {}

local function tierNameMap()
    return {
        [1] = "Common",
        [2] = "Uncommon",
        [3] = "Rare",
        [4] = "Epic",
        [5] = "Legendary",
        [6] = "Mythic",
        [7] = "Secret",
    }
end

local function parseAssetId(icon)
    if type(icon) == "number" then return icon end
    if type(icon) ~= "string" then return nil end
    local n = icon:match("rbxassetid://(%d+)")
    if n then return tonumber(n) end
    local n2 = icon:match("^(%d+)$")
    if n2 then return tonumber(n2) end
    return nil
end

local function getThumbUrl(ctx, assetId)
    if not assetId then return nil end

    local t = thumbCacheTime[assetId]
    if t and (os.clock() - t) < THUMB_TTL then
        local v = thumbCache[assetId]
        return (v == false) and nil or v
    end

    thumbCacheTime[assetId] = os.clock()
    thumbCache[assetId] = false

    if not ctx.Http.request then
        return nil
    end

    local url = ("https://thumbnails.roblox.com/v1/assets?assetIds=%d&size=420x420&format=Png&isCircular=false"):format(assetId)
    local ok, decodedOrErr = ctx.Http.getJson(ctx.Services.HttpService, url)
    if not ok or type(decodedOrErr) ~= "table" then
        return nil
    end

    local data = decodedOrErr.data
    local first = type(data) == "table" and data[1] or nil
    local imageUrl = first and first.imageUrl
    if type(imageUrl) == "string" and imageUrl ~= "" then
        thumbCache[assetId] = imageUrl
        return imageUrl
    end

    return nil
end

function Webhook.Init(ctx)
    Webhook._lastSendAt = 0
    Webhook._lastKey = nil
    Webhook._tierNumToName = tierNameMap()

    if Webhook._connected then return end
    Webhook._connected = true

    -- Prefer FishCaught because it contains VariantId (official)
    ctx.Events.fishCaught.OnClientEvent:Connect(function(fishName, data)
        local weight = (type(data) == "table" and data.Weight) or nil
        local variantId = (type(data) == "table" and type(data.VariantId) == "string" and data.VariantId) or nil
        Webhook.HandleFish(ctx, nil, fishName, weight, variantId)
    end)

    -- Still listen to obtained notif for fishId/weight, but ignore Shiny flags by policy
    ctx.Events.obtainedNewFishNotif.OnClientEvent:Connect(function(itemId, meta, payload)
        local id = tonumber(itemId) or (type(payload) == "table" and tonumber(payload.ItemId)) or nil

        local usedMeta = nil
        if type(payload) == "table" and type(payload.InventoryItem) == "table" and type(payload.InventoryItem.Metadata) == "table" then
            usedMeta = payload.InventoryItem.Metadata
        elseif type(meta) == "table" then
            usedMeta = meta
        end

        local weight = usedMeta and usedMeta.Weight or nil

        -- No official VariantId here (usually), so pass nil => "None"
        Webhook.HandleFish(ctx, id, nil, weight, nil)
    end)
end

local function passesTierFilter(ctx, tierNum)
    tierNum = tonumber(tierNum)
    if not tierNum then return false end
    local map = ctx.State.WebhookTierNumberMap or {}
    if not ctx.Utils.anySelected(map) then return false end
    return map[tierNum] == true
end

local function getFilterActivateText(ctx)
    local map = ctx.State.WebhookTierNumberMap or {}
    local names = {}
    local tmap = tierNameMap()
    for n, enabled in pairs(map) do
        if enabled then
            names[#names+1] = tmap[n] or tostring(n)
        end
    end
    table.sort(names)
    if #names == 0 then return "None" end
    return table.concat(names, ", ")
end

local function buildEmbedFish(ctx, entry, weight, variantId)
    local tierNum = tonumber(entry.Data.Tier) or 1
    local rarityName = entry.Data.TierName or Webhook._tierNumToName[tierNum] or "Unknown"

    local embed = {
        title = "Neverm1nd | Fish Caught Notification",
        description = ("Wake Up Kid ! %s You has been obtained a new %s Fish !"):format(
            tostring(ctx.LocalPlayer.Name),
            tostring(rarityName)
        ),
        color = 0x2F7DFF,
        fields = {
            { name = "Name Fish :", value = tostring(entry.Data.Name or "Unknown"), inline = false },
            { name = "Rarity :", value = tostring(rarityName), inline = false },
            { name = "Weight :", value = ("%s Kg"):format(tostring(weight or "Unknown")), inline = false },
            { name = "Mutation :", value = tostring(variantId or "None"), inline = false },
            { name = "Sell Price :", value = ("$%s Coins"):format(ctx.Utils.formatPrice(entry.SellPrice or 0)), inline = false },
            { name = "Filter Activate :", value = getFilterActivateText(ctx), inline = false },
        },
        footer = { text = ctx.Utils.footerTextWithTimestamp() },
    }

    embed.color = (function()
        local tierObj = ctx.TierUtility:GetTier(tierNum)
        if tierObj and tierObj.TierColor then
            local tc = tierObj.TierColor
            if typeof(tc) == "Color3" then
                return ctx.Utils.rgbToDiscordInt(tc)
            elseif typeof(tc) == "ColorSequence" and tc.Keypoints and tc.Keypoints[1] then
                return ctx.Utils.rgbToDiscordInt(tc.Keypoints[1].Value)
            end
        end
        return 0x2F7DFF
    end)()

    local assetId = parseAssetId(entry.Data.Icon)
    local thumb = getThumbUrl(ctx, assetId)
    if thumb then
        embed.thumbnail = { url = thumb }
    end

    return embed
end

local function buildEmbedTest(ctx)
    return {
        title = "Neverm1nd | Webhook Test",
        description = ("✅ Webhook connected!\nPlayer: %s"):format(tostring(ctx.LocalPlayer.Name)),
        color = 0x2ECC71,
        fields = {
            { name = "Status:", value = "Success", inline = true },
            { name = "Time:", value = os.date("%Y-%m-%d %H:%M:%S"), inline = true },
            { name = "Filter Activate :", value = getFilterActivateText(ctx), inline = false },
        },
        footer = { text = ctx.Utils.footerTextWithTimestamp() },
    }
end

function Webhook.Test(ctx)
    if ctx.Config.WebhookUrl == "" then
        ctx.Notify("warning", "Webhook", "Isi Webhook URL dulu.", 4)
        return false
    end
    if not ctx.Http.request then
        ctx.Notify("danger", "Webhook", "Executor tidak support HTTP request.", 6)
        return false
    end

    local embed = buildEmbedTest(ctx)
    local payload = { username = "Neverm1nd Webhook", embeds = { embed } }
    local ok, res = ctx.Http.postJson(ctx.Services.HttpService, ctx.Config.WebhookUrl, payload)
    if ok then
        ctx.Notify("success", "Webhook", "Test webhook sent.", 3)
        return true
    end
    ctx.Notify("danger", "Webhook", ("Test failed: %s"):format(tostring(res)), 5)
    return false
end

function Webhook.HandleFish(ctx, fishId, fishName, weight, variantId)
    if not ctx.Config.WebhookEnabled or ctx.Config.WebhookUrl == "" then
        return
    end

    local now = os.clock()
    if (now - (Webhook._lastSendAt or 0)) < 0.8 then
        return
    end

    local entry = ctx.FishData.GetByIdOrName(ctx, fishId, fishName)
    if not entry or type(entry.Data) ~= "table" then
        return
    end

    local tierNum = tonumber(entry.Data.Tier) or 1
    if not passesTierFilter(ctx, tierNum) then
        return
    end

    local key = ("%s|%s|%s"):format(tostring(entry.Data.Id), tostring(weight or "nil"), tostring(variantId or "None"))
    if key == Webhook._lastKey then
        return
    end
    Webhook._lastKey = key

    local embed = buildEmbedFish(ctx, entry, weight, variantId)
    local payload = { username = "Neverm1nd Webhook", embeds = { embed } }

    local ok, _ = ctx.Http.postJson(ctx.Services.HttpService, ctx.Config.WebhookUrl, payload)
    if ok then
        Webhook._lastSendAt = now
    end
end

return Webhook
