-- /functions/webhook.lua
-- Discord webhook sender + event listeners for fish caught.

local Webhook = {}

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

function Webhook.Init(ctx)
    Webhook._lastSendAt = 0
    Webhook._lastKey = nil
    Webhook._tierNumToName = tierNameMap()

    -- connect triggers once
    if Webhook._connected then return end
    Webhook._connected = true

    ctx.Events.fishCaught.OnClientEvent:Connect(function(fishName, data)
        local weight = (type(data) == "table" and data.Weight) or nil
        Webhook.HandleFish(ctx, nil, fishName, weight, data)
    end)

    ctx.Events.obtainedNewFishNotif.OnClientEvent:Connect(function(itemId, meta, payload)
        local id = tonumber(itemId) or (type(payload) == "table" and tonumber(payload.ItemId)) or nil
        local invMeta = nil
        if type(payload) == "table" and type(payload.InventoryItem) == "table" and type(payload.InventoryItem.Metadata) == "table" then
            invMeta = payload.InventoryItem.Metadata
        end
        local usedMeta = (type(invMeta) == "table" and invMeta) or (type(meta) == "table" and meta) or nil
        local weight = usedMeta and usedMeta.Weight or nil
        Webhook.HandleFish(ctx, id, nil, weight, usedMeta)
    end)
end

local function passesTierFilter(ctx, tierNum)
    tierNum = tonumber(tierNum)
    if not tierNum then return false end
    if not ctx.Utils.anySelected(ctx.State.WebhookTierNumberMap or {}) then
        -- if UI hasn't set it yet, default allow
        return true
    end
    return (ctx.State.WebhookTierNumberMap[tierNum] == true)
end

local function mutationFromMetadata(meta)
    if type(meta) ~= "table" then return "None" end
    local muts = {}
    for k, v in pairs(meta) do
        if k ~= "Weight" and type(k) == "string" and v == true then
            muts[#muts+1] = k
        end
    end
    table.sort(muts)
    if #muts > 0 then
        return table.concat(muts, ", ")
    end
    return "None"
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

local function buildEmbedFish(ctx, entry, weight, mutationName)
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
            { name = "Mutation :", value = tostring(mutationName or "None"), inline = false },
            { name = "Sell Price :", value = ("$%s Coins"):format(ctx.Utils.formatPrice(entry.SellPrice or 0)), inline = false },
            { name = "Filter Activate :", value = getFilterActivateText(ctx), inline = false },
        },
        footer = { text = ctx.Utils.footerTextWithTimestamp() },
    }

    -- color per tier
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

    -- Thumbnail: simplest fallback (roblox asset delivery is not always previewable)
    -- Keeping it simple for now; you can upgrade to thumbnails API later.
    local icon = entry.Data.Icon
    if type(icon) == "string" or type(icon) == "number" then
        local url = ("https://www.roblox.com/asset/?id=%s"):format(tostring(icon):gsub("rbxassetid://",""))
        embed.thumbnail = { url = url }
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

function Webhook.HandleFish(ctx, fishId, fishName, weight, meta)
    if not ctx.Config.WebhookEnabled or ctx.Config.WebhookUrl == "" then
        return
    end

    -- rate limit
    local now = os.clock()
    if (now - (Webhook._lastSendAt or 0)) < 0.8 then
        return
    end

    -- find fish entry
    local entry = ctx.FishData.GetByIdOrName(ctx, fishId, fishName)
    if not entry or type(entry.Data) ~= "table" then
        return
    end

    local tierNum = tonumber(entry.Data.Tier) or 1
    if not passesTierFilter(ctx, tierNum) then
        return
    end

    local mutationName = mutationFromMetadata(meta)
    local key = ("%s|%s|%s"):format(tostring(entry.Data.Id), tostring(weight or "nil"), mutationName)
    if key == Webhook._lastKey then
        return
    end
    Webhook._lastKey = key

    local embed = buildEmbedFish(ctx, entry, weight, mutationName)
    local payload = { username = "Neverm1nd Webhook", embeds = { embed } }

    local ok, _ = ctx.Http.postJson(ctx.Services.HttpService, ctx.Config.WebhookUrl, payload)
    if ok then
        Webhook._lastSendAt = now
    end
end

return Webhook
