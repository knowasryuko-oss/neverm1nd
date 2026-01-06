local GUI_NAME = "Neverm1nd UI"
local ICON_ID  = "rbxassetid://140314000349135"

local function createGui(parent)
    -- IMPORTANT: parent langsung di constructor (seperti Atomic)
    local screenGui = Instance.new("ScreenGui", parent)
    screenGui.Name = GUI_NAME
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 999999
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Enabled = true

    local UserInputService = game:GetService("UserInputService")

    local frame = Instance.new("Frame", screenGui)
    frame.AnchorPoint = Vector2.new(0, 0.5)
    frame.Name = "main"
    frame.Position = UDim2.new(0, 5, 0.5, 0)
    frame.Size = UDim2.new(0, 55, 0, 55)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Active = true

    -- icon only
    local icon = Instance.new("ImageLabel", frame)
    icon.Name = "icon"
    icon.Size = UDim2.fromScale(1, 1)
    icon.BackgroundTransparency = 1
    icon.BorderSizePixel = 0
    icon.Image = ICON_ID

    -- click overlay
    local btn = Instance.new("TextButton", frame)
    btn.Name = "togl"
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.ZIndex = 9999999

    -- drag system (Atomic-like)
    local dragging = false
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if connection then connection:Disconnect() end
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
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

    -- drag from button too
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if connection then connection:Disconnect() end
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

    return screenGui
end

local interface = {}

function interface:is_already_executed()
    local cg = game:GetService("CoreGui")
    local existing = cg:FindFirstChild(GUI_NAME)
    if existing then existing:Destroy() end
end

function interface:toggle_position()
    return game:GetService("CoreGui"):FindFirstChild(GUI_NAME)
end

function interface:initial_interface(callback)
    local cg = game:GetService("CoreGui")

    local existing = cg:FindFirstChild(GUI_NAME)
    if existing then existing:Destroy() end

    local ui = createGui(cg)
    if callback then
        ui.main.togl.MouseButton1Click:Connect(function()
            pcall(callback)
        end)
    end
end

return interface
