local GUI_NAME = "Neverm1ndToggle"
local ICON_ID  = "rbxassetid://140314000349135"

local function resolveParent()
    -- 1) kalau MacLib sudah ada, pakai parent yang sama persis
    local cg = game:GetService("CoreGui")
    local mac = cg:FindFirstChild("MacLib")
    if mac and mac.Parent then
        return mac.Parent
    end

    -- 2) fallback: CoreGui
    return cg
end

local function createGui(parent)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = GUI_NAME
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = true
    screenGui.DisplayOrder = 1000000 -- lebih tinggi dari MacLib (100)
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = parent

    local UserInputService = game:GetService("UserInputService")

    local frame = Instance.new("Frame")
    frame.Name = "main"
    frame.AnchorPoint = Vector2.new(0, 0.5)
    frame.Position = UDim2.new(0, 10, 0.5, 0)
    frame.Size = UDim2.fromOffset(55, 55)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = screenGui

    local icon = Instance.new("ImageLabel")
    icon.Name = "icon"
    icon.BackgroundTransparency = 1
    icon.BorderSizePixel = 0
    icon.Size = UDim2.fromScale(1, 1)
    icon.Image = ICON_ID
    icon.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Name = "togl"
    btn.Text = ""
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Size = UDim2.fromScale(1, 1)
    btn.ZIndex = 9999999
    btn.Parent = frame

    -- Drag (mouse+touch)
    local dragging = false
    local dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if conn then conn:Disconnect() end
                end
            end)
        end
    end)

    btn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    return screenGui
end

local interface = {}

function interface:is_already_executed()
    local parent = resolveParent()
    local existing = parent:FindFirstChild(GUI_NAME)
    if existing then existing:Destroy() end
end

function interface:toggle_position()
    local parent = resolveParent()
    return parent:FindFirstChild(GUI_NAME)
end

function interface:initial_interface(callback)
    local parent = resolveParent()

    local existing = parent:FindFirstChild(GUI_NAME)
    if existing then existing:Destroy() end

    local ui = createGui(parent)
    if callback then
        ui.main.togl.MouseButton1Click:Connect(function()
            pcall(callback)
        end)
    end
end

return interface
