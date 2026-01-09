-- /shared/utils.lua
-- Small helpers used across modules.

local Utils = {}

function Utils.formatPrice(n)
    local s = tostring(n or 0)
    local out = {}
    for i = #s, 1, -1 do
        out[#out+1] = s:sub(i,i)
        local idxFromEnd = (#s - i + 1)
        if idxFromEnd % 3 == 0 and i ~= 1 then
            out[#out+1] = "."
        end
    end
    local rev = {}
    for i = #out, 1, -1 do
        rev[#rev+1] = out[i]
    end
    return table.concat(rev)
end

function Utils.rgbToDiscordInt(c3)
    local r = math.clamp(math.floor((c3.R or 0) * 255 + 0.5), 0, 255)
    local g = math.clamp(math.floor((c3.G or 0) * 255 + 0.5), 0, 255)
    local b = math.clamp(math.floor((c3.B or 0) * 255 + 0.5), 0, 255)
    return (r * 65536) + (g * 256) + b
end

function Utils.footerTextWithTimestamp()
    return ("Neverm1nd Webhook | %s"):format(os.date("%Y-%m-%d %H:%M:%S"))
end

function Utils.anySelected(map)
    for _, v in pairs(map) do
        if v then return true end
    end
    return false
end

function Utils.tableKeysTrue(map)
    local out = {}
    for k, v in pairs(map or {}) do
        if v then out[#out+1] = k end
    end
    table.sort(out, function(a,b) return tostring(a) < tostring(b) end)
    return out
end

function Utils.getItemVariantName(item)
    if type(item) ~= "table" then return nil end
    local v = item.Variant or item.VariantName or item.Mutation or item.MutationName
    if type(v) == "string" then return v end
    if type(v) == "table" then
        if type(v.Name) == "string" then return v.Name end
        if type(v.Id) == "string" then return v.Id end
    end
    return nil
end

return Utils
