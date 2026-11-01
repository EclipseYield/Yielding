
--[[
    ECLIPSE YIELD UI LIBRARY
    Version: 2.0
    UI Library API
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Library = {}

Library.Version = "2.0"
Library.IconId = 109540638276525
Library.Notifications = true
Library.IsMobile = UserInputService.TouchEnabled
Library.Windows = {}

local Theme = {
    Background = Color3.fromRGB(5, 5, 8),
    Panel = Color3.fromRGB(10, 10, 13),
    Element = Color3.fromRGB(17, 17, 21),
    Hover = Color3.fromRGB(27, 27, 32),
    Border = Color3.fromRGB(40, 40, 46),

    Accent = Color3.fromRGB(0, 140, 160),
    Red = Color3.fromRGB(200, 15, 25),
    RedBright = Color3.fromRGB(255, 60, 60),

    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(165, 165, 175),
    Off = Color3.fromRGB(48, 48, 54),
}

Library.Theme = Theme

local function New(class, properties, parent)
    local object = Instance.new(class)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    object.Parent = parent

    return object
end

local function Corner(object, radius)
    return New("UICorner", {
        CornerRadius = UDim.new(0, radius or 6)
    }, object)
end

local function Stroke(object, color, thickness)
    return New("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1
    }, object)
end

local function Tween(object, properties, duration)
    local animation = TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.2,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        properties
    )

    animation:Play()

    return animation
end

local function CreateText(parent, text, size, position, fontSize)
    return New("TextLabel", {
        Size = size,
        Position = position,
        BackgroundTransparency = 1,
        Text = tostring(text or ""),
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = fontSize or 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    }, parent)
end

-- IMAGE SYSTEM

local function NormalizeImage(image)
    if typeof(image) == "number" then
        return "rbxassetid://" .. tostring(image)
    end

    if typeof(image) == "string" then
        if image:match("^%d+$") then
            return "rbxassetid://" .. image
        end

        return image
    end

    return ""
end

function Library:LoadImage(object, imageId, fallbackText)
    if not object then
        return false
    end

    local image = NormalizeImage(imageId or self.IconId)

    object.Image = image
    object.Visible = true

    task.spawn(function()
        local success = pcall(function()
            ContentProvider:PreloadAsync({object})
        end)

        if not object.Parent then
            return
        end

        if not success or not object.IsLoaded then
            object.Image = ""

            local fallback = New("TextLabel", {
                Name = "ImageFallback",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = fallbackText or "E",
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamBold,
                TextScaled = true
            }, object)

            object:SetAttribute("ImageFailed", true)
        else
            object:SetAttribute("ImageFailed", false)
        end
    end)

    return true
end

-- NOTIFICATIONS

local NotificationHolder

local function GetNotificationHolder()
    if NotificationHolder and NotificationHolder.Parent then
        return NotificationHolder
    end

    local gui = New("ScreenGui", {
        Name = "EclipseNotifications",
        ResetOnSpawn = false,
        DisplayOrder = 9999
    }, PlayerGui)

    NotificationHolder = New("Frame", {
        Size = UDim2.fromOffset(300, 400),
        Position = UDim2.new(1, -315, 0, 15),
        BackgroundTransparency = 1
    }, gui)

    New("UIListLayout", {
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Top
    }, NotificationHolder)

    return NotificationHolder
end

function Library:Notify(config)
    config = config or {}

    if not self.Notifications then
        return
    end

    local holder = GetNotificationHolder()

    local card = New("Frame", {
        Size = UDim2.new(1, 0, 0, 75),
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 0.05
    }, holder)

    Corner(card, 7)
    Stroke(card, Theme.Red, 1.2)

    local title = CreateText(
        card,
        config.Title or "Eclipse Yield",
        UDim2.new(1, -20, 0, 25),
        UDim2.fromOffset(12, 7),
        14
    )

    local description = CreateText(
        card,
        config.Text or "",
        UDim2.new(1, -24, 0, 35),
        UDim2.fromOffset(12, 32),
        11
    )

    description.TextColor3 = Theme.SubText
    description.TextWrapped = true

    card.Position = UDim2.new(1.2, 0, 0, 0)

    Tween(card, {
        Position = UDim2.new(0, 0, 0, 0)
    }, 0.3)

    task.delay(config.Duration or 4, function()
        if card.Parent then
            Tween(card, {
                Position = UDim2.new(1.2, 0, 0, 0)
            }, 0.25)

            task.wait(0.3)

            card:Destroy()
        end
    end)
end

-- WINDOW

function Library:CreateWindow(config)
    config = config or {}

    local title = config.Title or "Eclipse Yield"
    local iconId = config.Icon or config.IconId or self.IconId

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)

    local wanted = config.Size or Vector2.new(640, 470)

    local width = math.min(wanted.X, viewport.X - 24)
    local height = math.min(wanted.Y, viewport.Y - 24)

    local Window = {
        Sections = {},
        Elements = {},
        CurrentTab = nil,
        Minimized = false,
        Visible = true,
        Destroyed = false,
        Config = {},
        IsMobile = self.IsMobile
    }

    local gui = New("ScreenGui", {
        Name = "EclipseYield",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, PlayerGui)

    Window.Gui = gui

    local main = New("Frame", {
        Name = "Main",
        Size = UDim2.fromOffset(width, height),
        Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = false
    }, gui)

    Window.Main = main

    Corner(main, 8)
    Stroke(main, Theme.Accent, 1.2)

    local topbar = New("Frame", {
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundTransparency = 1
    }, main)

    local icon = New("ImageLabel", {
        Size = UDim2.fromOffset(42, 42),
        Position = UDim2.fromOffset(12, 10),
        BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Fit
    }, topbar)

    Library:LoadImage(icon, iconId, "E")

    CreateText(
        topbar,
        title,
        UDim2.new(1, -160, 1, 0),
        UDim2.fromOffset(65, 0),
        17
    )

    local function CreateControl(text, position)
        local button = New("TextButton", {
            Size = UDim2.fromOffset(27, 27),
            Position = position,
            BackgroundColor3 = Theme.Element,
            Text = text,
            TextColor3 = Theme.Text,
            TextSize = 15,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false
        }, topbar)

        Corner(button, 5)
        Stroke(button, Theme.Red)

        button.MouseEnter:Connect(function()
            Tween(button, {
                BackgroundColor3 = Theme.Hover
            })
        end)

        button.MouseLeave:Connect(function()
            Tween(button, {
                BackgroundColor3 = Theme.Element
            })
        end)

        return button
    end

    local minimize = CreateControl(
        "-",
        UDim2.new(1, -70, 0, 16)
    )

    local close = CreateControl(
        "X",
        UDim2.new(1, -36, 0, 16)
    )

    -- DRAG

    do
        local dragging = false
        local dragStart
        local startPosition

        topbar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

                dragging = true
                dragStart = input.Position
                startPosition = main.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            ) then

                local delta = input.Position - dragStart

                main.Position = UDim2.new(
                    startPosition.X.Scale,
                    startPosition.X.Offset + delta.X,
                    startPosition.Y.Scale,
                    startPosition.Y.Offset + delta.Y
                )
            end
        end)
    end

    -- BODY

    local body = New("Frame", {
        Size = UDim2.new(1, 0, 1, -64),
        Position = UDim2.fromOffset(0, 64),
        BackgroundTransparency = 1
    }, main)

    local sidebar = New("Frame", {
        Size = UDim2.new(0, 130, 1, -10),
        Position = UDim2.fromOffset(10, 0),
        BackgroundColor3 = Theme.Panel
    }, body)

    Corner(sidebar, 5)

    local content = New("Frame", {
        Size = UDim2.new(1, -154, 1, -10),
        Position = UDim2.fromOffset(144, 0),
        BackgroundColor3 = Theme.Panel,
        ClipsDescendants = true
    }, body)

    Corner(content, 5)

    local sectionList = New("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Red,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new()
    }, sidebar)

    New("UIListLayout", {
        Padding = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder
    }, sectionList)

    New("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10)
    }, sectionList)

    -- WINDOW API

    function Window:Notify(options)
        Library:Notify(options)
    end

    function Window:Toggle()
        if self.Destroyed then return end

        self.Visible = not self.Visible
        main.Visible = self.Visible
    end

    function Window:Destroy()
        if self.Destroyed then return end

        self.Destroyed = true
        gui:Destroy()

        if config.OnClose then
            task.spawn(config.OnClose)
        end
    end

    function Window:SetToggleKey(key)
        self.ToggleKey = key
    end

    Window.ToggleKey = config.ToggleKey or Enum.KeyCode.RightControl

    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and not Window.Destroyed then
            if input.KeyCode == Window.ToggleKey then
                Window:Toggle()
            end
        end
    end)

    minimize.MouseButton1Click:Connect(function()
        Window.Minimized = not Window.Minimized

        body.Visible = not Window.Minimized

        Tween(main, {
            Size = UDim2.fromOffset(
                width,
                Window.Minimized and 64 or height
            )
        }, 0.2)
    end)

    close.MouseButton1Click:Connect(function()
        Window:Destroy()
    end)

    -- SECTION API

    function Window:AddSection(name)
        local Section = {
            Name = name,
            Tabs = {}
        }

        local sectionFrame = New("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = #Window.Sections + 1
        }, sectionList)

        New("UIListLayout", {
            Padding = UDim.new(0, 7),
            HorizontalAlignment = Enum.HorizontalAlignment.Center
        }, sectionFrame)

        CreateText(
            sectionFrame,
            "→ " .. tostring(name),
            UDim2.new(1, -15, 0, 20),
            UDim2.fromOffset(7, 0),
            11
        )

        -- TAB API

        function Section:AddTab(tabName)
            local Tab = {
                Name = tabName,
                Elements = {}
            }

            local button = New("TextButton", {
                Size = UDim2.fromOffset(110, 30),
                BackgroundColor3 = Theme.Element,
                Text = tostring(tabName),
                TextColor3 = Theme.SubText,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                AutoButtonColor = false
            }, sectionFrame)

            Corner(button, 5)

            local page = New("ScrollingFrame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = Theme.Red,
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                CanvasSize = UDim2.new(),
                Visible = false
            }, content)

            New("UIListLayout", {
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder
            }, page)

            New("UIPadding", {
                PaddingTop = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10)
            }, page)

            Tab.Button = button
            Tab.Page = page

            function Tab:Select()
                if Window.CurrentTab then
                    Window.CurrentTab.Page.Visible = false

                    Tween(
                        Window.CurrentTab.Button,
                        {BackgroundColor3 = Theme.Element}
                    )
                end

                Window.CurrentTab = self
                page.Visible = true

                Tween(button, {
                    BackgroundColor3 = Theme.Red
                })
            end

            button.MouseButton1Click:Connect(function()
                Tab:Select()
            end)

            local order = 0

            local function Row(height)
                order += 1

                local frame = New("Frame", {
                    Size = UDim2.new(1, 0, 0, height or 36),
                    BackgroundColor3 = Theme.Element,
                    BorderSizePixel = 0,
                    LayoutOrder = order
                }, page)

                Corner(frame, 5)
                Stroke(frame, Theme.Border)

                return frame
            end

            -- LABEL

            function Tab:AddLabel(text)
                local label = CreateText(
                    page,
                    text,
                    UDim2.new(1, 0, 0, 25),
                    UDim2.new(),
                    12
                )

                label.LayoutOrder = order + 1
                order += 1

                return label
            end

            -- PARAGRAPH

            function Tab:AddParagraph(title, text)
                local frame = Row(75)

                CreateText(
                    frame,
                    title,
                    UDim2.new(1, -20, 0, 22),
                    UDim2.fromOffset(10, 5),
                    13
                )

                local description = CreateText(
                    frame,
                    text,
                    UDim2.new(1, -20, 0, 38),
                    UDim2.fromOffset(10, 28),
                    11
                )

                description.TextColor3 = Theme.SubText
                description.TextWrapped = true

                return frame
            end

            -- BUTTON

            function Tab:AddButton(text, callback)
                local frame = Row(36)

                local button = New("TextButton", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = tostring(text),
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.GothamBold,
                    TextSize = 13
                }, frame)

                button.MouseEnter:Connect(function()
                    Tween(frame, {
                        BackgroundColor3 = Theme.Hover
                    })
                end)

                button.MouseLeave:Connect(function()
                    Tween(frame, {
                        BackgroundColor3 = Theme.Element
                    })
                end)

                button.MouseButton1Click:Connect(function()
                    Tween(frame, {
                        BackgroundColor3 = Theme.Red
                    }, 0.1)

                    task.spawn(function()
                        if callback then
                            callback()
                        end
                    end)

                    task.delay(0.15, function()
                        if frame.Parent then
                            Tween(frame, {
                                BackgroundColor3 = Theme.Element
                            })
                        end
                    end)
                end)

                return button
            end

            -- TOGGLE

            function Tab:AddToggle(text, default, callback)
                local state = default == true
                local frame = Row(38)

                CreateText(
                    frame,
                    text,
                    UDim2.new(1, -65, 1, 0),
                    UDim2.fromOffset(12, 0),
                    12
                )

                local track = New("Frame", {
                    Size = UDim2.fromOffset(38, 20),
                    Position = UDim2.new(1, -50, 0.5, -10),
                    BackgroundColor3 = state and Theme.Red or Theme.Off
                }, frame)

                Corner(track, 10)

                local knob = New("Frame", {
                    Size = UDim2.fromOffset(14, 14),
                    Position = UDim2.fromOffset(state and 21 or 3, 3),
                    BackgroundColor3 = Theme.Text
                }, track)

                Corner(knob, 10)

                local hit = New("TextButton", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = ""
                }, frame)

                local Toggle = {}

                function Toggle:Set(value, silent)
                    state = value == true

                    Tween(track, {
                        BackgroundColor3 = state and Theme.Red or Theme.Off
                    })

                    Tween(knob, {
                        Position = UDim2.fromOffset(
                            state and 21 or 3,
                            3
                        )
                    })

                    if callback and not silent then
                        task.spawn(callback, state)
                    end
                end

                function Toggle:Get()
                    return state
                end

                hit.MouseButton1Click:Connect(function()
                    Toggle:Set(not state)
                end)

                return Toggle
            end

            -- SLIDER

            function Tab:AddSlider(text, minimum, maximum, default, callback)
                minimum = minimum or 0
                maximum = maximum or 100

                local value = math.clamp(
                    default or minimum,
                    minimum,
                    maximum
                )

                local frame = Row(55)

                local label = CreateText(
                    frame,
                    "",
                    UDim2.new(1, -20, 0, 22),
                    UDim2.fromOffset(10, 3),
                    12
                )

                local bar = New("Frame", {
                    Size = UDim2.new(1, -24, 0, 6),
                    Position = UDim2.fromOffset(12, 38),
                    BackgroundColor3 = Theme.Off
                }, frame)

                Corner(bar, 5)

                local fill = New("Frame", {
                    Size = UDim2.fromScale(
                        (value - minimum) / (maximum - minimum),
                        1
                    ),
                    BackgroundColor3 = Theme.Red
                }, bar)

                Corner(fill, 5)

                local Slider = {}

                local function Refresh()
                    label.Text = text .. ": " .. tostring(value)
                end

                function Slider:Set(newValue, silent)
                    value = math.clamp(
                        math.floor(newValue + 0.5),
                        minimum,
                        maximum
                    )

                    local alpha = (value - minimum) / (maximum - minimum)

                    Tween(fill, {
                        Size = UDim2.fromScale(alpha, 1)
                    })

                    Refresh()

                    if callback and not silent then
                        task.spawn(callback, value)
                    end
                end

                function Slider:Get()
                    return value
                end

                local dragging = false

                local function Update(input)
                    local alpha = math.clamp(
                        (input.Position.X - bar.AbsolutePosition.X)
                        / bar.AbsoluteSize.X,
                        0,
                        1
                    )

                    Slider:Set(
                        minimum + (maximum - minimum) * alpha
                    )
                end

                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        Update(input)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (
                        input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch
                    ) then
                        Update(input)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)

                Refresh()

                return Slider
            end

            -- TEXTBOX

            function Tab:AddTextBox(text, placeholder, callback)
                local frame = Row(38)

                CreateText(
                    frame,
                    text,
                    UDim2.new(0.42, 0, 1, 0),
                    UDim2.fromOffset(10, 0),
                    12
                )

                local box = New("TextBox", {
                    Size = UDim2.new(0.52, -5, 0, 25),
                    Position = UDim2.new(0.46, 0, 0.5, -12),
                    BackgroundColor3 = Theme.Panel,
                    Text = "",
                    PlaceholderText = placeholder or "",
                    PlaceholderColor3 = Theme.SubText,
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    ClearTextOnFocus = false
                }, frame)

                Corner(box, 4)
                Stroke(box, Theme.Border)

                box.FocusLost:Connect(function(enter)
                    if callback then
                        task.spawn(callback, box.Text, enter)
                    end
                end)

                return box
            end

            -- DROPDOWN

            function Tab:AddDropdown(text, options, callback)
                options = options or {}

                local selected = options[1]
                local opened = false

                local frame = Row(38)

                local button = New("TextButton", {
                    Size = UDim2.new(1, -12, 1, -6),
                    Position = UDim2.fromOffset(6, 3),
                    BackgroundTransparency = 1,
                    Text = text .. ": " .. tostring(selected or "None"),
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12
                }, frame)

                local list = New("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    BackgroundColor3 = Theme.Panel,
                    ClipsDescendants = true,
                    Visible = false,
                    ZIndex = 10
                }, page)

                Corner(list, 5)
                Stroke(list, Theme.Red)

                local layout = New("UIListLayout", {
                    Padding = UDim.new(0, 3)
                }, list)

                local Dropdown = {}

                local function Refresh()
                    button.Text = text .. ": " .. tostring(selected or "None")
                end

                function Dropdown:SetOptions(newOptions)
                    options = newOptions or {}

                    for _, child in ipairs(list:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end

                    for _, option in ipairs(options) do
                        local optionButton = New("TextButton", {
                            Size = UDim2.new(1, 0, 0, 28),
                            BackgroundColor3 = Theme.Element,
                            Text = tostring(option),
                            TextColor3 = Theme.Text,
                            Font = Enum.Font.Gotham,
                            TextSize = 12
                        }, list)

                        optionButton.MouseButton1Click:Connect(function()
                            selected = option
                            Refresh()

                            list.Visible = false
                            opened = false

                            if callback then
                                task.spawn(callback, selected)
                            end
                        end)
                    end

                    list.Size = UDim2.new(
                        1,
                        0,
                        0,
                        math.min(#options * 31, 155)
                    )
                end

                function Dropdown:Set(value)
                    selected = value
                    Refresh()

                    if callback then
                        task.spawn(callback, value)
                    end
                end

                function Dropdown:Get()
                    return selected
                end

                button.MouseButton1Click:Connect(function()
                    opened = not opened
                    list.Visible = opened

                    if opened then
                        Dropdown:SetOptions(options)
                    end
                end)

                Dropdown:SetOptions(options)

                return Dropdown
            end

            -- KEYBIND

            function Tab:AddKeybind(text, default, callback)
                local key = default or Enum.KeyCode.RightControl

                local frame = Row(38)

                CreateText(
                    frame,
                    text,
                    UDim2.new(0.6, 0, 1, 0),
                    UDim2.fromOffset(10, 0),
                    12
                )

                local button = New("TextButton", {
                    Size = UDim2.fromOffset(90, 25),
                    Position = UDim2.new(1, -100, 0.5, -12),
                    BackgroundColor3 = Theme.Panel,
                    Text = key.Name,
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.GothamBold,
                    TextSize = 11
                }, frame)

                Corner(button, 4)

                local listening = false
                local Keybind = {}

                function Keybind:Set(newKey)
                    key = newKey
                    button.Text = key.Name
                end

                function Keybind:Get()
                    return key
                end

                button.MouseButton1Click:Connect(function()
                    listening = true
                    button.Text = "..."
                end)

                local connection

                connection = UserInputService.InputBegan:Connect(function(input, processed)
                    if input.UserInputType ~= Enum.UserInputType.Keyboard then
                        return
                    end

                    if listening then
                        key = input.KeyCode
                        listening = false
                        button.Text = key.Name
                        return
                    end

                    if not processed and input.KeyCode == key then
                        if callback then
                            task.spawn(callback, key)
                        end
                    end
                end)

                return Keybind
            end

            table.insert(Section.Tabs, Tab)

            if not Window.CurrentTab then
                Tab:Select()
            end

            return Tab
        end

        table.insert(Window.Sections, Section)

        return Section
    end

    -- DEFAULT SECTION

    if config.DefaultContent ~= false then
        local section = Window:AddSection("Settings")

        local settings = section:AddTab("Settings")

        settings:AddLabel("Eclipse Yield v" .. Library.Version)

        settings:AddToggle("Notifications", true, function(value)
            Library.Notifications = value
        end)

        settings:AddButton("Test Notification", function()
            Library:Notify({
                Title = "Eclipse Yield",
                Text = "Notification system working!",
                Duration = 3
            })
        end)

        settings:AddButton("Unload UI", function()
            Window:Destroy()
        end)
    end

    table.insert(Library.Windows, Window)

    return Window
end

-- CONFIG API

function Library:SaveConfig(name, data)
    if not writefile then
        return false, "writefile unavailable"
    end

    local success, result = pcall(function()
        writefile(
            tostring(name) .. ".json",
            HttpService:JSONEncode(data or {})
        )
    end)

    return success, result
end

function Library:LoadConfig(name)
    if not readfile or not isfile then
        return nil, "readfile unavailable"
    end

    local success, result = pcall(function()
        local path = tostring(name) .. ".json"

        if not isfile(path) then
            return {}
        end

        return HttpService:JSONDecode(readfile(path))
    end)

    if success then
        return result
    end

    return nil, result
end

function Library:DestroyAll()
    for _, window in ipairs(self.Windows) do
        window:Destroy()
    end

    table.clear(self.Windows)
end

return Library
