-- /shared/http.lua
-- FIXED + improved: clean module (no stray return), adds GET JSON helper.

local Http = {}

function Http.getRequestFunction()
    if typeof(request) == "function" then return request end
    if typeof(http_request) == "function" then return http_request end
    if typeof(syn) == "table" and typeof(syn.request) == "function" then return syn.request end
    if typeof(fluxus) == "table" and typeof(fluxus.request) == "function" then return fluxus.request end
    if typeof(krnl) == "table" and typeof(krnl.request) == "function" then return krnl.request end
    return nil
end

Http.request = Http.getRequestFunction()

function Http.jsonDecode(httpService, s)
    local ok, res = pcall(function()
        return httpService:JSONDecode(s)
    end)
    if ok then return res end
    return nil
end

function Http.jsonEncode(httpService, t)
    local ok, res = pcall(function()
        return httpService:JSONEncode(t)
    end)
    if ok then return res end
    return nil
end

function Http.postJson(httpService, url, luaTable)
    if type(url) ~= "string" or url == "" then
        return false, "no_url"
    end
    if not Http.request then
        return false, "no_request_function"
    end

    local body = Http.jsonEncode(httpService, luaTable)
    if not body then
        return false, "json_encode_failed"
    end

    local ok, res = pcall(function()
        return Http.request({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
    end)

    if not ok then
        return false, "request_failed"
    end
    return true, res
end

function Http.getBody(url)
    if type(url) ~= "string" or url == "" then
        return false, "no_url"
    end
    if not Http.request then
        return false, "no_request_function"
    end

    local ok, res = pcall(function()
        return Http.request({
            Url = url,
            Method = "GET",
        })
    end)
    if not ok then
        return false, "request_failed"
    end

    local body = res and (res.Body or res.body)
    if type(body) ~= "string" then
        return false, "no_body"
    end
    return true, body
end

function Http.getJson(httpService, url)
    local ok, bodyOrErr = Http.getBody(url)
    if not ok then
        return false, bodyOrErr
    end
    local decoded = Http.jsonDecode(httpService, bodyOrErr)
    if not decoded then
        return false, "json_decode_failed"
    end
    return true, decoded
end

return Http
