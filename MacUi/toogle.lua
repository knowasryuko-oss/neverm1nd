local GUI_NAME = "Neverm1nd"
local ICON_ID  = "rbxassetid://140314000349135"

local function createGui(parent)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = GUI_NAME
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 999999
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = parent

    local UserInputService = game:GetService("UserInputService")

    -- Frame kecil (tetap jadi container drag + tombol)
    local Frame1 = Instance.new("Frame")
    Frame1.Name = "main"
    Frame1.AnchorPoint = Vector2.new(0, 0.5)
    Frame1.Position = UDim2.new(0, 5, 0.5, 0)
    Frame1.Size = UDim2.new(0, 55, 0, 55)
    Frame1.BackgroundTransparency = 1 -- ✅ no background
    Frame1.BorderSizePixel = 0
    Frame1.Active = true
    Frame1.Parent = screenGui

    -- ✅ Dragging (PC + Mobile)
    local dragging = false
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        Frame1.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    Frame1.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Frame1.Position

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if connection then connection:Disconnect() end
                end
            end)
        end
    end)

    Frame1.InputChanged:Connect(function(input)
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

    -- ✅ Hanya gambar (tanpa border/gradient/stroke)
    local icon = Instance.new("ImageLabel")
    icon.Name = "icon"
    icon.BackgroundTransparency = 1
    icon.BorderSizePixel = 0
    icon.Size = UDim2.fromScale(1, 1)
    icon.Position = UDim2.fromScale(0, 0)
    icon.Image = ICON_ID
    icon.Parent = Frame1

    -- ✅ Tombol transparan di atas gambar (untuk toggle)
    local btn = Instance.new("TextButton")
    btn.Name = "togl"
    btn.Text = ""
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Size = UDim2.fromScale(1, 1)
    btn.ZIndex = icon.ZIndex + 1
    btn.Parent = Frame1

    -- Drag juga dari tombol (biar enak di mobile)
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Frame1.Position

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
    local cg = game:GetService("CoreGui")
    return cg:FindFirstChild(GUI_NAME)
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
