-- Eclipse Yield UI Library

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.Icon = "rbxthumb://type=Asset&id=109540638276525&w=420&h=420"
Library.Texture = "rbxthumb://type=Asset&id=109540638276525&w=420&h=420"
Library.IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local Theme = {
	Edge = Color3.fromRGB(0, 140, 160),
	Panel = Color3.fromRGB(0, 0, 0),
	Red = Color3.fromRGB(200, 15, 25),
	RedBright = Color3.fromRGB(255, 60, 60),
	Button = Color3.fromRGB(170, 170, 170),
	ButtonHover = Color3.fromRGB(195, 195, 195),
	ButtonActive = Color3.fromRGB(225, 225, 225),
	ButtonText = Color3.fromRGB(20, 20, 20),
	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(175, 175, 180),
	Element = Color3.fromRGB(16, 16, 19),
	ElementHover = Color3.fromRGB(26, 26, 31),
	ElementStroke = Color3.fromRGB(38, 38, 44),
	Off = Color3.fromRGB(48, 48, 54),
}

local Font = Enum.Font.GothamBold

-- Text (English only)

local Strings = {
	Confirm = "Confirm",
	Cancel = "Cancel",
	CloseTitle = "Close",
	CloseMessage = "Are you sure you want to close?",
}

-- Helpers ---------------------------------------------------------------

local function new(class, props, parent)
	local inst = Instance.new(class)
	for key, value in pairs(props or {}) do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

local function corner(parent, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function stroke(parent, color, thickness)
	return new("UIStroke", { Color = color, Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent)
end

local function tween(inst, props, time)
	local t = TweenService:Create(inst, TweenInfo.new(time or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function guiParent()
	local ok, hui = pcall(function() return gethui and gethui() end)
	if ok and hui then
		return hui
	end
	local probe = Instance.new("ScreenGui")
	local canUseCore = pcall(function() probe.Parent = game:GetService("CoreGui") end)
	probe:Destroy()
	if canUseCore then
		return game:GetService("CoreGui")
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function isTap(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

-- Notifications ----------------------------------------------------------

local notifyGui, notifyHolder
local notifyCount = 0

local function getHolder()
	if notifyHolder and notifyHolder.Parent then
		return notifyHolder
	end

	notifyGui = new("ScreenGui", {
		Name = "EclipseYieldNotifications",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 1000,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, guiParent())

	notifyHolder = new("Frame", {
		Size = UDim2.new(0, 300, 1, -24),
		Position = UDim2.new(1, -312, 0, 12),
		BackgroundTransparency = 1,
	}, notifyGui)

	new("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		-- on mobile the bottom corner is taken by the Roblox controls
		VerticalAlignment = Library.IsMobile and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom,
	}, notifyHolder)

	return notifyHolder
end

-- Library:Notify({ Title = "...", Text = "...", Duration = 4 })
-- Tapping a notification dismisses it immediately.
function Library:Notify(opts)
	opts = opts or {}
	local holder = getHolder()
	notifyCount += 1

	local slot = new("Frame", {
		Size = UDim2.new(1, 0, 0, 68),
		BackgroundTransparency = 1,
		LayoutOrder = Library.IsMobile and -notifyCount or notifyCount,
	}, holder)

	local card = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.new(1.15, 0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(10, 12, 15),
		BorderSizePixel = 0,
	}, slot)
	corner(card, 8)
	stroke(card, Theme.Red, 1.2)

	new("ImageLabel", {
		Size = UDim2.fromOffset(42, 42),
		Position = UDim2.fromOffset(12, 13),
		BackgroundTransparency = 1,
		Image = opts.Icon or Library.Icon,
	}, card)

	new("TextLabel", {
		Size = UDim2.new(1, -76, 0, 18),
		Position = UDim2.fromOffset(64, 10),
		BackgroundTransparency = 1,
		Text = opts.Title or "Eclipse Yield",
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = Font,
		TextSize = 14,
	}, card)

	new("TextLabel", {
		Size = UDim2.new(1, -76, 0, 30),
		Position = UDim2.fromOffset(64, 29),
		BackgroundTransparency = 1,
		Text = opts.Text or "",
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Font = Enum.Font.Gotham,
		TextSize = 12,
	}, card)

	local click = new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
	}, card)

	local closed = false
	local function dismiss(slideOut)
		if closed then return end
		closed = true
		if slideOut then
			local t = tween(card, { Position = UDim2.new(1.15, 0, 0, 0) }, 0.2)
			t.Completed:Connect(function() slot:Destroy() end)
		else
			slot:Destroy()
		end
	end

	click.MouseButton1Click:Connect(function() dismiss(false) end)

	tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.25)
	task.delay(opts.Duration or 4, dismiss, true)
end

-- Window ----------------------------------------------------------------

function Library:CreateWindow(config)
	config = config or {}
	local title = config.Title or "Eclipse Yield"

	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local wanted = config.Size or Vector2.new(640, 470)
	local width = math.min(wanted.X, viewport.X - 24)
	local height = math.min(wanted.Y, viewport.Y - 24)

	local Window = {
		Sections = {},
		Minimized = false,
		IsMobile = Library.IsMobile,
	}

	local function tr(key)
		return Strings[key] or key
	end

	local function bindText(fn)
		fn()
	end

	local gui = new("ScreenGui", {
		Name = "EclipseYield",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, nil)
	pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(gui) end
	end)
	gui.Parent = guiParent()
	Window.Gui = gui

	local main = new("Frame", {
		Name = "Main",
		Size = UDim2.fromOffset(width, height),
		Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	}, gui)
	corner(main, 8)
	stroke(main, Theme.Edge, 1)
	new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 30, 38)),
			ColorSequenceKeypoint.new(0.3, Color3.fromRGB(5, 9, 12)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
		}),
	}, main)

	-- Top bar ---------------------------------------------------------

	local topbar = new("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundTransparency = 1,
	}, main)

	new("ImageLabel", {
		Size = UDim2.fromOffset(46, 46),
		Position = UDim2.fromOffset(10, 9),
		BackgroundTransparency = 1,
		Image = Library.Icon,
	}, topbar)

	new("TextLabel", {
		Size = UDim2.new(1, -170, 1, 0),
		Position = UDim2.fromOffset(66, 4),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Font,
		TextSize = 18,
	}, topbar)

	local function controlButton(xOffset, kind)
		local btn = new("TextButton", {
			Size = UDim2.fromOffset(26, 26),
			Position = UDim2.new(1, xOffset, 0, 8),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.35,
			Text = "",
			AutoButtonColor = false,
		}, topbar)
		corner(btn, 7)
		local outline = stroke(btn, Theme.Red, 1.5)

		local function bar(rotation, length)
			new("Frame", {
				Size = UDim2.fromOffset(length, 2),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Rotation = rotation,
				BackgroundColor3 = Theme.Text,
				BorderSizePixel = 0,
			}, btn)
		end
		if kind == "close" then
			bar(45, 13)
			bar(-45, 13)
		else
			bar(0, 11)
		end

		btn.MouseEnter:Connect(function()
			tween(btn, { BackgroundTransparency = 0.05 })
			tween(outline, { Color = Theme.RedBright })
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, { BackgroundTransparency = 0.35 })
			tween(outline, { Color = Theme.Red })
		end)
		return btn
	end

	local minimizeBtn = controlButton(-68, "minimize")
	local closeBtn = controlButton(-36, "close")

	-- drag by the top bar
	do
		local dragging, dragStart, startPos
		topbar.InputBegan:Connect(function(input)
			if isTap(input) then
				dragging = true
				dragStart = input.Position
				startPos = main.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and isMove(input) then
				local delta = input.Position - dragStart
				main.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end)
	end

	-- Body -----------------------------------------------------------------

	local body = new("Frame", {
		Name = "Body",
		Size = UDim2.new(1, 0, 1, -64),
		Position = UDim2.fromOffset(0, 64),
		BackgroundTransparency = 1,
	}, main)

	local sidebar = new("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 124, 1, -10),
		Position = UDim2.fromOffset(10, 0),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
	}, body)
	corner(sidebar, 3)

	local content = new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -154, 1, -10),
		Position = UDim2.fromOffset(144, 0),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, body)
	corner(content, 3)

	local sectionList = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Red,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, sidebar)
	new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, sectionList)
	new("UIPadding", { PaddingTop = UDim.new(0, 8) }, sectionList)

	-- Minimize / close ----------------------------------------------------

	local fullHeight = height
	minimizeBtn.MouseButton1Click:Connect(function()
		Window.Minimized = not Window.Minimized
		body.Visible = not Window.Minimized
		main.Size = UDim2.fromOffset(width, Window.Minimized and 64 or fullHeight)
	end)

	local overlay = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Active = true,
		Visible = false,
		ZIndex = 50,
	}, main)
	corner(overlay, 8)

	local dialog = new("Frame", {
		Size = UDim2.fromOffset(310, 146),
		Position = UDim2.new(0.5, -155, 0.5, -73),
		BackgroundColor3 = Color3.fromRGB(10, 12, 15),
		BorderSizePixel = 0,
		ZIndex = 51,
	}, overlay)
	corner(dialog, 8)
	stroke(dialog, Theme.Red, 1.2)

	local dialogTitle = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		TextColor3 = Theme.Text,
		Font = Font,
		TextSize = 16,
		ZIndex = 52,
	}, dialog)
	local dialogMessage = new("TextLabel", {
		Size = UDim2.new(1, -30, 0, 42),
		Position = UDim2.fromOffset(15, 38),
		BackgroundTransparency = 1,
		TextColor3 = Theme.SubText,
		TextWrapped = true,
		Font = Enum.Font.Gotham,
		TextSize = 14,
		ZIndex = 52,
	}, dialog)
	bindText(function()
		dialogTitle.Text = tr("CloseTitle")
		dialogMessage.Text = tr("CloseMessage")
	end)

	local function dialogButton(key, xScale, xOffset)
		local btn = new("TextButton", {
			Size = UDim2.new(0.5, -22, 0, 32),
			Position = UDim2.new(xScale, xOffset, 1, -46),
			BackgroundColor3 = Theme.Button,
			BorderSizePixel = 0,
			TextColor3 = Theme.ButtonText,
			Font = Font,
			TextSize = 14,
			AutoButtonColor = false,
			ZIndex = 52,
		}, dialog)
		corner(btn, 4)
		bindText(function() btn.Text = tr(key) end)
		btn.MouseEnter:Connect(function() tween(btn, { BackgroundColor3 = Theme.ButtonHover }) end)
		btn.MouseLeave:Connect(function() tween(btn, { BackgroundColor3 = Theme.Button }) end)
		return btn
	end

	local confirmBtn = dialogButton("Confirm", 0, 15)
	local cancelBtn = dialogButton("Cancel", 0.5, 7)

	closeBtn.MouseButton1Click:Connect(function() overlay.Visible = true end)
	cancelBtn.MouseButton1Click:Connect(function() overlay.Visible = false end)
	confirmBtn.MouseButton1Click:Connect(function()
		if Window.OnClose then pcall(Window.OnClose) end
		gui:Destroy()
	end)

	-- Show / hide: key on PC, side button on mobile ---------------

	local function toggleVisible()
		main.Visible = not main.Visible
	end
	Window.Toggle = toggleVisible

	local toggleKeys = {}
	local function setKeys(keys)
		toggleKeys = {}
		if typeof(keys) == "EnumItem" then
			keys = { keys }
		end
		for _, key in ipairs(keys or {}) do
			toggleKeys[key] = true
		end
	end
	setKeys(config.ToggleKey or Enum.KeyCode.RightControl)

	function Window:SetToggleKey(keys)
		setKeys(keys)
	end

	if not Library.IsMobile then
		UserInputService.InputBegan:Connect(function(input, processed)
			if not processed and toggleKeys[input.KeyCode] then
				toggleVisible()
			end
		end)
	else
		local fab = new("ImageButton", {
			Name = "MobileToggle",
			Size = UDim2.fromOffset(46, 46),
			Position = UDim2.new(0, 8, 0.5, -23),
			BackgroundColor3 = Color3.fromRGB(8, 10, 13),
			Image = Library.Texture,
			AutoButtonColor = false,
		}, gui)
		corner(fab, 23)
		stroke(fab, Theme.Red, 1.5)

		local dragging, moved, dragStart, startPos = false, false, nil, nil
		fab.InputBegan:Connect(function(input)
			if isTap(input) then
				dragging, moved = true, false
				dragStart = input.Position
				startPos = fab.AbsolutePosition
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						if not moved then
							toggleVisible()
						end
					end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and isMove(input) then
				local delta = input.Position - dragStart
				if delta.Magnitude > 8 then
					moved = true
				end
				if moved then
					local screen = gui.AbsoluteSize
					fab.Position = UDim2.fromOffset(
						math.clamp(startPos.X + delta.X, 0, screen.X - 46),
						math.clamp(startPos.Y + delta.Y, 0, screen.Y - 46)
					)
				end
			end
		end)
	end

	-- Window API ---------------------------------------------------------

	function Window:Notify(opts)
		Library:Notify(opts)
	end

	function Window:Destroy()
		gui:Destroy()
	end

	function Window:AddSection(name)
		local Section = { Tabs = {} }

		local frame = new("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = #Window.Sections + 1,
		}, sectionList)
		new("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, frame)

		local label = new("TextLabel", {
			Size = UDim2.new(1, -14, 0, 16),
			BackgroundTransparency = 1,
			TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Font,
			TextSize = 11,
			LayoutOrder = 0,
		}, frame)
		bindText(function() label.Text = "→ " .. tr(name) end)

		function Section:AddTab(tabName)
			local Tab = {}

			local btn = new("TextButton", {
				Size = UDim2.fromOffset(94, 26),
				BackgroundColor3 = Theme.Button,
				BorderSizePixel = 0,
				TextColor3 = Theme.ButtonText,
				Font = Font,
				TextSize = 14,
				AutoButtonColor = false,
				LayoutOrder = #Section.Tabs + 1,
			}, frame)
			corner(btn, 4)
			bindText(function() btn.Text = tr(tabName) end)

			local page = new("ScrollingFrame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = Theme.Red,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(),
				Visible = false,
			}, content)
			new("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, page)
			new("UIPadding", {
				PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12),
			}, page)

			Tab.Button = btn
			Tab.Page = page

			btn.MouseEnter:Connect(function()
				if Window.CurrentTab ~= Tab then tween(btn, { BackgroundColor3 = Theme.ButtonHover }) end
			end)
			btn.MouseLeave:Connect(function()
				if Window.CurrentTab ~= Tab then tween(btn, { BackgroundColor3 = Theme.Button }) end
			end)

			function Tab:Select()
				local current = Window.CurrentTab
				if current then
					current.Page.Visible = false
					tween(current.Button, { BackgroundColor3 = Theme.Button })
				end
				Window.CurrentTab = Tab
				page.Visible = true
				tween(btn, { BackgroundColor3 = Theme.ButtonActive })
			end
			btn.MouseButton1Click:Connect(function() Tab:Select() end)

			-- elements ------------------------------------------------------

			local order = 0
			local function row(rowHeight)
				order += 1
				local frame = new("Frame", {
					Size = UDim2.new(1, 0, 0, rowHeight or 34),
					BackgroundColor3 = Theme.Element,
					BorderSizePixel = 0,
					LayoutOrder = order,
				}, page)
				corner(frame, 5)
				stroke(frame, Theme.ElementStroke, 1)
				return frame
			end

			local function hoverable(frame, target)
				target.MouseEnter:Connect(function() tween(frame, { BackgroundColor3 = Theme.ElementHover }) end)
				target.MouseLeave:Connect(function() tween(frame, { BackgroundColor3 = Theme.Element }) end)
			end

			function Tab:AddLabel(text)
				order += 1
				local l = new("TextLabel", {
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundTransparency = 1,
					TextColor3 = Theme.SubText,
					TextXAlignment = Enum.TextXAlignment.Left,
					Font = Font,
					TextSize = 12,
					LayoutOrder = order,
				}, page)
				bindText(function() l.Text = tr(text) end)
				return l
			end

			function Tab:AddButton(text, callback)
				local frame = row(34)
				local b = new("TextButton", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					TextColor3 = Theme.Text,
					Font = Font,
					TextSize = 13,
					AutoButtonColor = false,
				}, frame)
				bindText(function() b.Text = tr(text) end)
				hoverable(frame, b)
				b.MouseButton1Click:Connect(function()
					frame.BackgroundColor3 = Theme.Red
					tween(frame, { BackgroundColor3 = Theme.ElementHover }, 0.25)
					if callback then task.spawn(callback) end
				end)
				return b
			end

			function Tab:AddToggle(text, default, callback)
				local state = default and true or false
				local frame = row(34)

				local l = new("TextLabel", {
					Size = UDim2.new(1, -70, 1, 0),
					Position = UDim2.fromOffset(12, 0),
					BackgroundTransparency = 1,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Font = Font,
					TextSize = 13,
				}, frame)
				bindText(function() l.Text = tr(text) end)

				local track = new("Frame", {
					Size = UDim2.fromOffset(38, 20),
					Position = UDim2.new(1, -50, 0.5, -10),
					BackgroundColor3 = state and Theme.Red or Theme.Off,
					BorderSizePixel = 0,
				}, frame)
				corner(track, 10)
				local knob = new("Frame", {
					Size = UDim2.fromOffset(14, 14),
					Position = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3),
					BackgroundColor3 = Theme.Text,
					BorderSizePixel = 0,
				}, track)
				corner(knob, 7)

				local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, frame)
				hoverable(frame, hit)

				local Toggle = {}
				function Toggle:Set(value, silent)
					state = value and true or false
					tween(track, { BackgroundColor3 = state and Theme.Red or Theme.Off })
					tween(knob, { Position = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3) })
					if callback and not silent then task.spawn(callback, state) end
				end
				function Toggle:Get() return state end
				hit.MouseButton1Click:Connect(function() Toggle:Set(not state) end)
				return Toggle
			end

			function Tab:AddSlider(text, min, max, default, callback)
				local value = math.clamp(default or min, min, max)
				local frame = row(50)

				local l = new("TextLabel", {
					Size = UDim2.new(1, -24, 0, 22),
					Position = UDim2.fromOffset(12, 4),
					BackgroundTransparency = 1,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Font = Font,
					TextSize = 13,
				}, frame)
				local function refresh() l.Text = tr(text) .. ": " .. tostring(value) end
				bindText(refresh)

				local bar = new("Frame", {
					Size = UDim2.new(1, -24, 0, 6),
					Position = UDim2.new(0, 12, 1, -15),
					BackgroundColor3 = Theme.Off,
					BorderSizePixel = 0,
				}, frame)
				corner(bar, 3)
				local fill = new("Frame", {
					Size = UDim2.fromScale((value - min) / (max - min), 1),
					BackgroundColor3 = Theme.Red,
					BorderSizePixel = 0,
				}, bar)
				corner(fill, 3)

				local Slider = {}
				function Slider:Set(v, silent)
					value = math.clamp(math.floor(v + 0.5), min, max)
					tween(fill, { Size = UDim2.fromScale((value - min) / (max - min), 1) }, 0.08)
					refresh()
					if callback and not silent then task.spawn(callback, value) end
				end
				function Slider:Get() return value end

				local dragging = false
				local function update(input)
					local alpha = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
					Slider:Set(min + (max - min) * alpha)
				end
				bar.InputBegan:Connect(function(input)
					if isTap(input) then
						dragging = true
						update(input)
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
					if isTap(input) then dragging = false end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if dragging and isMove(input) then update(input) end
				end)
				return Slider
			end

			function Tab:AddTextBox(text, placeholder, callback)
				local frame = row(34)
				local l = new("TextLabel", {
					Size = UDim2.new(0.45, 0, 1, 0),
					Position = UDim2.fromOffset(12, 0),
					BackgroundTransparency = 1,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Font = Font,
					TextSize = 13,
				}, frame)
				bindText(function() l.Text = tr(text) end)

				local field = new("Frame", {
					Size = UDim2.new(0.5, -18, 0, 24),
					Position = UDim2.new(0.5, 6, 0.5, -12),
					BackgroundColor3 = Theme.Panel,
					BorderSizePixel = 0,
				}, frame)
				corner(field, 4)
				stroke(field, Theme.ElementStroke, 1)

				local box = new("TextBox", {
					Size = UDim2.new(1, -12, 1, 0),
					Position = UDim2.fromOffset(6, 0),
					BackgroundTransparency = 1,
					Text = "",
					PlaceholderText = placeholder or "",
					PlaceholderColor3 = Color3.fromRGB(110, 110, 118),
					TextColor3 = Theme.Text,
					Font = Font,
					TextSize = 12,
					ClearTextOnFocus = false,
				}, field)
				box.FocusLost:Connect(function(enter)
					if callback then task.spawn(callback, box.Text, enter) end
				end)
				return box
			end

			table.insert(Section.Tabs, Tab)
			return Tab
		end

		table.insert(Window.Sections, Section)
		return Section
	end

	-- Built-in tabs: Settings and Config
	local defaultSection = Window:AddSection("Settings & Config")
	Window.Settings = defaultSection:AddTab("Settings")
	Window.Config = defaultSection:AddTab("Config")

	return Window
end

return Library
