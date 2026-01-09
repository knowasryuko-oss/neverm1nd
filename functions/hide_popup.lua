-- /functions/hide_popup.lua
-- Hide "Small Notification" fish popup (UI only).

local HidePopup = {}

function HidePopup.Init(ctx)
    -- nothing
end

local function getPopup(ctx)
    local pg = ctx.LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end
    local sn = pg:FindFirstChild("Small Notification")
    if not sn then return nil end
    local display = sn:FindFirstChild("Display")
    if not display then return nil end
    return display
end

local function apply(ctx, hide)
    local display = getPopup(ctx)
    if not display then return end

    local container   = display:FindFirstChild("Container")
    local vectorFrame = display:FindFirstChild("VectorFrame")
    local newFrame    = display:FindFirstChild("NewFrame")
    local rarityLabel = container and container:FindFirstChild("Rarity")
    local itemNameLabel = container and container:FindFirstChild("ItemName")

    if vectorFrame   then vectorFrame.Visible   = not hide end
    if newFrame      then newFrame.Visible      = not hide end
    if rarityLabel   then rarityLabel.Visible   = not hide end
    if itemNameLabel then itemNameLabel.Visible = not hide end
end

function HidePopup.SetEnabled(ctx, enabled)
    enabled = enabled and true or false
    ctx.Config.HideFishPopup = enabled
    apply(ctx, enabled)
end

return HidePopup
