-- /ui/backpack.lua
-- Backpack tab UI (Favorite Tier + Favorite Mutation).

return function(ctx, modules, tab)
    local Favorites = modules.favorites

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

    -- internal maps stored on ctx.State so functions can read them
    ctx.State.FavoriteTierNumberMap = ctx.State.FavoriteTierNumberMap or { [7]=true, [6]=true, [5]=true }
    ctx.State.FavoriteMutationMap = ctx.State.FavoriteMutationMap or {}

    -- Favorite Tier
    local favTierSec = tab:Section({ Side = "Left", Collapsed = false })
    favTierSec:Header({ Text = "Favorite Tier Fish" })

    favTierSec:Dropdown({
        Name     = "Select Favorite Tiers",
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
            ctx.State.FavoriteTierNumberMap = map
            if Favorites and Favorites.SetTierMap then
                Favorites.SetTierMap(ctx, map)
            end
        end
    }, "FavoriteTierDropdown")

    favTierSec:Toggle({
        Name = "Enable Auto Favorite Tier",
        Default = false,
        Callback = function(v)
            if Favorites and Favorites.SetTierEnabled then
                Favorites.SetTierEnabled(ctx, v)
            end
        end
    }, "EnableAutoFavouriteTier")

    -- Favorite Mutation
    local favMutSec = tab:Section({ Side = "Left", Collapsed = false })
    favMutSec:Header({ Text = "Favorite Mutation" })

    favMutSec:Dropdown({
        Name     = "Select Favorite Mutations",
        Search   = true,
        Multi    = true,
        Required = false,
        Options  = ctx.VariantPool,
        Default  = {},
        Callback = function(Value)
            local map = {}
            for name, state in pairs(Value) do
                if state then map[name] = true end
            end
            ctx.State.FavoriteMutationMap = map
            if Favorites and Favorites.SetMutationMap then
                Favorites.SetMutationMap(ctx, map)
            end
        end
    }, "FavoriteMutationDropdown")

    favMutSec:Toggle({
        Name = "Enable Auto Favorite Mutation",
        Default = false,
        Callback = function(v)
            if Favorites and Favorites.SetMutationEnabled then
                Favorites.SetMutationEnabled(ctx, v)
            end
        end
    }, "EnableAutoFavouriteMutation")
end
