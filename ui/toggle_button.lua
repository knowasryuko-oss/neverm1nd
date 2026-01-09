-- /ui/toggle_button.lua
-- AJOMOK draggable toggle button for showing/hiding the main window.

return function(ctx)
    local CoreGui = ctx.Services.CoreGui
    local ContentProvider = ctx.Services.ContentProvider
    local UserInputService = ctx.Services.UserInputService

    local MainWindow = ctx.State.MainWindow
    if not MainWindow then return end

    local macGui = CoreGui:WaitForChild("MacLib", 5)
    if not macGui then return end

    local GUI_NAME = "Neverm1ndToggle"
    local ICON_ID  = "rbxassetid://100651748260650"

    local old = macGui:FindFirstChild(GUI_NAME)
    if old then old:Destroy() end

    pcall(function()
        ContentProvider:PreloadAsync({ ICON_ID })
    end)

    local Frame1 = Instance.new("Frame")
    Frame1.Name = GUI_NAME
    Frame1.AnchorPoint = Vector2.new(0, 0.5)
    Frame1.Position = UDim2.new(0, 5, 0.5, 0)
    Frame1.Size = UDim2.new(0, 55, 0, 55)
    Frame1.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    Frame1.BackgroundTransparency = 0.15
    Frame1.BorderSizePixel = 0
    Frame1.Active = true
    Frame1.ClipsDescendants = true
    Frame1.Parent = macGui
    Frame1.ZIndex = 9999999

    local UICorner3 = Instance.new("UICorner", Frame1)
    UICorner3.CornerRadius = UDim.new(0, 15)

    local UIStroke4 = Instance.new("UIStroke", Frame1)
    UIStroke4.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke4.Color = Color3.fromRGB(255, 255, 255)
    UIStroke4.Thickness = 2
    UIStroke4.Transparency = 0.65

    local ImageLabel6 = Instance.new("ImageLabel", Frame1)
    ImageLabel6.Name = "imege"
    ImageLabel6.BackgroundTransparency = 1
    ImageLabel6.BorderSizePixel = 0
    ImageLabel6.Image = ICON_ID
    ImageLabel6.AnchorPoint = Vector2.new(0.5, 0.5)
    ImageLabel6.Position = UDim2.new(0.5, 0, 0.5, 0)
    ImageLabel6.Size = UDim2.new(0, 52, 0, 52)
    ImageLabel6.ScaleType = Enum.ScaleType.Fit
    ImageLabel6.ZIndex = Frame1.ZIndex + 1

    local iconCorner = Instance.new("UICorner", ImageLabel6)
    iconCorner.CornerRadius = UDim.new(0, 12)

    local TextButton7 = Instance.new("TextButton", Frame1)
    TextButton7.Name = "togl"
    TextButton7.Text = ""
    TextButton7.TextTransparency = 1
    TextButton7.BackgroundTransparency = 1
    TextButton7.BorderSizePixel = 0
    TextButton7.Size = UDim2.new(1, 0, 1, 0)
    TextButton7.ZIndex = Frame1.ZIndex + 2

    local dragging = false
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        Frame1.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    local function beginDrag(input)
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

    Frame1.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            beginDrag(input)
        end
    end)

    TextButton7.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            beginDrag(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    TextButton7.MouseButton1Click:Connect(function()
        MainWindow:SetState(not MainWindow:GetState())
    end)
end
