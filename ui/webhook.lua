-- /ui/webhook.lua
-- Webhook tab UI.

return function(ctx, modules, tab)
    local Webhook = modules.webhook

    local TierOptions = { "Secret", "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common" }
    local TierNameToNumber = {
        Common    = 1,
        Uncommon  = 2,
        Rare      = 3,
        Epic      = 4,
        Legendary = 5,
        Mythic    = 6,
        Secret    = 7,
    }

    ctx.State.WebhookTierNumberMap = ctx.State.WebhookTierNumberMap or { [7]=true, [6]=true, [5]=true }

    local sec = tab:Section({ Side = "Left", Collapsed = false })
    sec:Header({ Text = "Webhook Setting" })

    sec:Input({
        Name = "Webhook URL",
        Placeholder = "https://discord.com/api/webhooks/...",
        Default = "",
        AcceptedCharacters = "All",
        Callback = function(text)
            text = tostring(text or "")
            ctx.Config.WebhookUrl = text
            ctx.Config.WebhookEnabled = (text ~= "")
            if ctx.Config.WebhookEnabled then
                ctx.Notify("success", "Webhook", "Webhook enabled (URL set).", 3)
            else
                ctx.Notify("warning", "Webhook", "Webhook disabled (URL empty).", 3)
            end
        end
    }, "WebhookUrlInput")

    sec:Dropdown({
        Name     = "Filter Rarity (Tier)",
        Search   = true,
        Multi    = true,
        Required = false,
        Options  = TierOptions,
        Default  = {"Secret","Mythic","Legendary"},
        Callback = function(Value)
            local map = {}
            for name, state in pairs(Value) do
                if state then
                    local n = TierNameToNumber[name]
                    if n then map[n] = true end
                end
            end
            ctx.State.WebhookTierNumberMap = map
        end
    }, "WebhookTierFilterDropdown")

    sec:Button({
        Name = "Test Webhook",
        Callback = function()
            if not Webhook then return end
            Webhook.Test(ctx)
        end
    })

    if not ctx.Http.request then
        sec:Button({
            Name = "HTTP Status: NO REQUEST (click to notify)",
            Callback = function()
                ctx.Notify("danger", "Webhook", "Executor tidak support HTTP request (request/http_request).", 6)
            end
        })
    end
end
