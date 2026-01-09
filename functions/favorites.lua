-- /functions/favorites.lua
-- Auto favorite by Tier and by Mutation (VariantPool).

local Favorites = {}

function Favorites.Init(ctx)
    Favorites._tierRunning = false
    Favorites._mutRunning = false
    Favorites._favoritedMutationUUID = {}
end

-- Tier favorites
function Favorites.SetTierEnabled(ctx, enabled)
    ctx.Config.AutoFavourite = enabled and true or false
    if ctx.Config.AutoFavourite then
        Favorites.StartTier(ctx)
    end
end

function Favorites.SetTierMap(ctx, tierNumberMap)
    ctx.State.FavoriteTierNumberMap = tierNumberMap or {}
end

function Favorites.StartTier(ctx)
    if Favorites._tierRunning then return end
    Favorites._tierRunning = true

    task.spawn(function()
        while ctx.Config.AutoFavourite do
            pcall(function()
                local dataRep = ctx.Replion.Client:WaitReplion("Data")
                local items = dataRep and dataRep:Get({"Inventory","Items"})
                if type(items) ~= "table" then return end

                local tierMap = ctx.State.FavoriteTierNumberMap
                if type(tierMap) ~= "table" then tierMap = {} end

                for _, item in ipairs(items) do
                    if not item.Favorited then
                        local base = ctx.ItemUtility:GetItemData(item.Id)
                        local tier = base and base.Data and base.Data.Tier
                        if tier and tierMap[tier] then
                            item.Favorited = true
                        end
                    end
                end
            end)
            task.wait(5)
        end

        Favorites._tierRunning = false
    end)
end

-- Mutation favorites
function Favorites.SetMutationEnabled(ctx, enabled)
    ctx.Config.AutoFavouriteMutation = enabled and true or false
    if ctx.Config.AutoFavouriteMutation then
        Favorites.StartMutation(ctx)
    end
end

function Favorites.SetMutationMap(ctx, mutationMap)
    ctx.State.FavoriteMutationMap = mutationMap or {}
end

local function getItemVariantName(item)
    return ctx and ctx.Utils and ctx.Utils.getItemVariantName and ctx.Utils.getItemVariantName(item)
end

function Favorites.StartMutation(ctx)
    if Favorites._mutRunning then return end
    Favorites._mutRunning = true

    task.spawn(function()
        while ctx.Config.AutoFavouriteMutation do
            pcall(function()
                local dataRep = ctx.Replion.Client:WaitReplion("Data")
                local items = dataRep and dataRep:Get({"Inventory","Items"})
                if type(items) ~= "table" then return end

                local mutMap = ctx.State.FavoriteMutationMap
                if type(mutMap) ~= "table" then mutMap = {} end

                for _, item in ipairs(items) do
                    if type(item) == "table" then
                        local uuid = item.UUID
                        if uuid and not Favorites._favoritedMutationUUID[uuid] then
                            if item.Favorited ~= true then
                                local variant = ctx.Utils.getItemVariantName(item)
                                if type(variant) == "string" and mutMap[variant] then
                                    ctx.Events.Favorited:FireServer(uuid)
                                    Favorites._favoritedMutationUUID[uuid] = true
                                    task.wait(0.25)
                                end
                            end
                        end
                    end
                end
            end)

            task.wait(5)
        end

        Favorites._mutRunning = false
    end)
end

return Favorites
