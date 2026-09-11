local AppleCheats = {}
AppleCheats.Version = "1.0.0"

local Themes = {
	TitleBg = Color3.fromRGB(0, 0, 0),
	TitleText = Color3.fromRGB(255, 255, 255),
	TabActive = Color3.fromRGB(130, 130, 130),
	TabInactive = Color3.fromRGB(205, 205, 205),
	ContentBg = Color3.fromRGB(240, 240, 240),
	Text = Color3.fromRGB(0, 0, 0),
	Border = Color3.fromRGB(0, 0, 0),
	CheckBg = Color3.fromRGB(175, 175, 175),
	CheckFill = Color3.fromRGB(0, 0, 0),
	SliderTrack = Color3.fromRGB(0, 0, 0),
	SliderHandle = Color3.fromRGB(0, 0, 0),
}

local Services = {
	Players = game:GetService("Players"),
	UserInputService = game:GetService("UserInputService"),
	RunService = game:GetService("RunService"),
	CoreGui = game:GetService("CoreGui"),
	HttpService = game:GetService("HttpService"),
}

local function GetGuiParent()
	local parent = gethui and gethui() or Services.CoreGui
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("ScreenGui") and child.Name == "AppleCheats" then
			child:Destroy()
		end
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "AppleCheats"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 999
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	if syn and syn.protect_gui then
		syn.protect_gui(gui)
	end
	gui.Parent = parent
	return gui
end

local function FormatTimestamp()
	return os.date("%b %d %Y %H:%M:%S")
end

local function FormatValue(value, decimals)
	decimals = decimals or 2
	local mult = 10 ^ decimals
	return string.format("%." .. decimals .. "f", math.floor(value * mult + 0.5) / mult)
end

local function KeyToString(key)
	if typeof(key) == "EnumItem" then
		return key.Name
	end
	return tostring(key)
end

local function New(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

local function AddStroke(parent, thickness, color)
	New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = color or Themes.Border,
		Thickness = thickness or 1,
		Parent = parent,
	})
end

local function MakeText(props)
	return New("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.Arial,
		TextColor3 = Themes.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextSize = 13,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		RichText = false,
		Parent = props.Parent,
		Text = props.Text or "",
		Name = props.Name or "Label",
	})
end

local function BindClick(gui, callback)
	local fired = false
	local function Fire()
		if fired then
			return
		end
		fired = true
		task.defer(function()
			fired = false
		end)
		callback()
	end
	if gui.MouseButton1Click then
		gui.MouseButton1Click:Connect(Fire)
	end
	if gui.Activated then
		gui.Activated:Connect(Fire)
	end
	gui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Fire()
		end
	end)
end

local Library = {
	Windows = {},
	Theme = Themes,
}

function AppleCheats:SetTheme(themeTable)
	for k, v in pairs(themeTable) do
		Library.Theme[k] = v
	end
end

function AppleCheats:CreateWindow(options)
	options = options or {}
	local title = options.Title or "APPLE CHEATS"
	local subtitle = options.Subtitle or "menu is only usable in game"
	local keybind = options.Keybind or Enum.KeyCode.Insert
	local size = options.Size or Vector2.new(620, 420)
	local position = options.Position or UDim2.new(0.5, -size.X / 2, 0.5, -size.Y / 2)

	local gui = GetGuiParent()
	local window = {
		Gui = gui,
		Keybind = keybind,
		Visible = true,
		Tabs = {},
		ActiveTab = nil,
		Destroyed = false,
	}

	local main = New("Frame", {
		Name = "Main",
		BackgroundColor3 = Themes.ContentBg,
		BorderSizePixel = 1,
		BorderColor3 = Themes.Border,
		Position = position,
		Size = UDim2.fromOffset(size.X, size.Y),
		Active = false,
		Parent = gui,
	})

	local titleBar = New("Frame", {
		Name = "TitleBar",
		BackgroundColor3 = Themes.TitleBg,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 22),
		Active = true,
		Parent = main,
	})

	local titleLabel = New("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Font = Enum.Font.Arial,
		TextColor3 = Themes.TitleText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextSize = 12,
		Position = UDim2.fromOffset(6, 0),
		Size = UDim2.new(1, -12, 1, 0),
		Text = title .. " @ " .. FormatTimestamp() .. " (" .. KeyToString(keybind) .. ") (" .. subtitle .. ")",
		Parent = titleBar,
	})

	local tabBar = New("Frame", {
		Name = "TabBar",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 22),
		Size = UDim2.new(1, 0, 0, 26),
		Parent = main,
	})

	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabBar,
	})

	local content = New("Frame", {
		Name = "Content",
		BackgroundColor3 = Themes.ContentBg,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 1, -48),
		Parent = main,
	})

	local dragging = false
	local dragStart, startPos

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)

	titleBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	Services.UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	local function SetVisible(state)
		window.Visible = state
		main.Visible = state
	end

	Services.UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == keybind then
			SetVisible(not window.Visible)
		end
	end)

	function window:Destroy()
		if self.Destroyed then
			return
		end
		self.Destroyed = true
		gui:Destroy()
	end

	function window:SetTitle(newTitle)
		titleLabel.Text = newTitle .. " @ " .. FormatTimestamp() .. " (" .. KeyToString(keybind) .. ") (" .. subtitle .. ")"
	end

	function window:AddTab(name)
		local tab = {
			Name = name,
			Columns = {},
			Window = window,
		}

		local tabButton = New("TextButton", {
			Name = name,
			BackgroundColor3 = Themes.TabInactive,
			BorderSizePixel = 1,
			BorderColor3 = Themes.Border,
			Font = Enum.Font.Arial,
			TextSize = 13,
			TextColor3 = Themes.Text,
			Text = name,
			AutoButtonColor = false,
			Size = UDim2.new(0, 0, 1, 0),
			Parent = tabBar,
		})

		local tabContent = New("Frame", {
			Name = name .. "Content",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
			Parent = content,
		})

		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 0),
			Parent = tabContent,
		})

		local function Select()
			for _, t in ipairs(window.Tabs) do
				local active = t == tab
				t.Button.BackgroundColor3 = active and Themes.TabActive or Themes.TabInactive
				t.Button.Text = active and ("+" .. t.Name) or t.Name
				t.Content.Visible = active
			end
			window.ActiveTab = tab
		end

		tab.Button = tabButton
		tab.Content = tabContent
		tab.Select = Select

		tabButton.MouseButton1Click:Connect(Select)

		table.insert(window.Tabs, tab)

		for i, t in ipairs(window.Tabs) do
			t.Button.Size = UDim2.new(1 / #window.Tabs, 0, 1, 0)
			t.Button.LayoutOrder = i
		end

		if #window.Tabs == 1 then
			Select()
		end

		function tab:AddColumn(header)
			local column = {
				Tab = tab,
				Elements = {},
			}

			local colFrame = New("Frame", {
				Name = header or "Column",
				BackgroundTransparency = 1,
				Size = UDim2.new(1 / 3, 0, 1, 0),
				Parent = tabContent,
			})

			local scroll = New("ScrollingFrame", {
				Name = "Scroll",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
				CanvasSize = UDim2.fromOffset(0, 0),
				ScrollBarThickness = 4,
				ScrollBarImageColor3 = Themes.Border,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				Active = false,
				ScrollingEnabled = true,
				Parent = colFrame,
			})

			local list = New("Frame", {
				Name = "List",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -8, 0, 0),
				Position = UDim2.fromOffset(4, 4),
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = scroll,
			})

			New("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 3),
				Parent = list,
			})

			if header then
				local headerLabel = MakeText({
					Text = header,
					Parent = list,
					Name = "Header",
				})
				headerLabel.TextSize = 13
				headerLabel.Font = Enum.Font.ArialBold
				headerLabel.LayoutOrder = 0
			end

			column.Frame = colFrame
			column.List = list

			function column:AddCheckbox(label, default, callback)
				default = default == true
				callback = callback or function() end

				local row = New("TextButton", {
					Name = "Checkbox",
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = false,
					Selectable = true,
					Active = true,
					Size = UDim2.new(1, 0, 0, 18),
					LayoutOrder = #column.Elements + 1,
					Parent = list,
				})

				local box = New("Frame", {
					Name = "Box",
					BackgroundColor3 = Themes.CheckBg,
					BorderSizePixel = 1,
					BorderColor3 = Themes.Border,
					Size = UDim2.fromOffset(11, 11),
					Position = UDim2.fromOffset(0, 3),
					ZIndex = 2,
					Active = false,
					Parent = row,
				})

				local fill = New("Frame", {
					Name = "Fill",
					BackgroundColor3 = Themes.CheckFill,
					BorderSizePixel = 0,
					Size = UDim2.fromOffset(7, 7),
					Position = UDim2.fromOffset(2, 2),
					Visible = default,
					ZIndex = 3,
					Active = false,
					Parent = box,
				})

				local text = MakeText({
					Text = label,
					Parent = row,
					Name = "Label",
				})
				text.Position = UDim2.fromOffset(16, 0)
				text.Size = UDim2.new(1, -16, 1, 0)
				text.ZIndex = 2
				text.Active = false

				local element = {
					Type = "Checkbox",
					Value = default,
					Set = function(_, value)
						element.Value = value == true
						fill.Visible = element.Value
					end,
					Get = function()
						return element.Value
					end,
				}

				local function Toggle()
					element:Set(not element.Value)
					callback(element.Value)
				end

				BindClick(row, Toggle)

				table.insert(column.Elements, element)
				return element
			end

			function column:AddSlider(label, min, max, default, callback, decimals)
				min = min or 0
				max = max or 100
				default = default or min
				callback = callback or function() end
				decimals = decimals or 2

				local row = New("Frame", {
					Name = "Slider",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 36),
					LayoutOrder = #column.Elements + 1,
					Parent = list,
				})

				local valueLabel = MakeText({
					Text = label .. ": " .. FormatValue(default, decimals),
					Parent = row,
					Name = "Value",
				})
				valueLabel.Size = UDim2.new(1, 0, 0, 16)

				local track = New("Frame", {
					Name = "Track",
					BackgroundColor3 = Themes.SliderTrack,
					BorderSizePixel = 0,
					Position = UDim2.fromOffset(0, 20),
					Size = UDim2.new(1, 0, 0, 1),
					Parent = row,
				})

				local handle = New("Frame", {
					Name = "Handle",
					BackgroundColor3 = Themes.SliderHandle,
					BorderSizePixel = 0,
					Size = UDim2.fromOffset(3, 12),
					Position = UDim2.fromOffset(0, 14),
					Parent = row,
				})

				local minLabel = MakeText({
					Text = FormatValue(min, decimals),
					Parent = row,
					Name = "Min",
				})
				minLabel.Position = UDim2.fromOffset(0, 28)
				minLabel.Size = UDim2.fromOffset(60, 12)
				minLabel.TextSize = 11

				local maxLabel = MakeText({
					Text = FormatValue(max, decimals),
					Parent = row,
					Name = "Max",
				})
				maxLabel.Position = UDim2.new(1, -60, 0, 28)
				maxLabel.Size = UDim2.fromOffset(60, 12)
				maxLabel.TextSize = 11
				maxLabel.TextXAlignment = Enum.TextXAlignment.Right

				local element = {
					Type = "Slider",
					Min = min,
					Max = max,
					Value = default,
					Decimals = decimals,
				}

				local draggingSlider = false

				local function SetValue(value, fire)
					value = math.clamp(value, min, max)
					element.Value = value
					local alpha = (value - min) / (max - min)
					handle.Position = UDim2.new(alpha, -1, 0, 14)
					valueLabel.Text = label .. ": " .. FormatValue(value, decimals)
					if fire then
						callback(value)
					end
				end

				element.Set = function(_, value, fire)
					SetValue(value, fire ~= false)
				end

				element.Get = function()
					return element.Value
				end

				SetValue(default, false)

				local function UpdateFromInput(input)
					local trackPos = track.AbsolutePosition.X
					local trackSize = track.AbsoluteSize.X
					local rel = math.clamp((input.Position.X - trackPos) / trackSize, 0, 1)
					SetValue(min + (max - min) * rel, true)
				end

				handle.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						draggingSlider = true
					end
				end)

				track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						draggingSlider = true
						UpdateFromInput(input)
					end
				end)

				Services.UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						draggingSlider = false
					end
				end)

				Services.UserInputService.InputChanged:Connect(function(input)
					if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
						UpdateFromInput(input)
					end
				end)

				table.insert(column.Elements, element)
				return element
			end

			function column:AddLabel(text)
				local label = MakeText({
					Text = text,
					Parent = list,
					Name = "SectionLabel",
				})
				label.LayoutOrder = #column.Elements + 1
				label.TextSize = 13
				return label
			end

			function column:AddButton(text, callback)
				callback = callback or function() end

				local btn = New("TextButton", {
					Name = "Button",
					BackgroundColor3 = Themes.TabInactive,
					BorderSizePixel = 1,
					BorderColor3 = Themes.Border,
					Font = Enum.Font.Arial,
					TextSize = 13,
					TextColor3 = Themes.Text,
					Text = text,
					AutoButtonColor = false,
					Size = UDim2.new(1, 0, 0, 22),
					LayoutOrder = #column.Elements + 1,
					Parent = list,
				})

				btn.MouseButton1Click:Connect(callback)
				table.insert(column.Elements, btn)
				return btn
			end

			function column:AddSpacing(height)
				New("Frame", {
					Name = "Spacer",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, height or 6),
					LayoutOrder = #column.Elements + 1,
					Parent = list,
				})
			end

			table.insert(tab.Columns, column)
			return column
		end

		return tab
	end

	table.insert(Library.Windows, window)
	return window
end

function AppleCheats:Notify(text, duration)
	duration = duration or 3
	local gui = GetGuiParent()
	local frame = New("Frame", {
		Name = "Notification",
		BackgroundColor3 = Themes.TitleBg,
		BorderSizePixel = 1,
		BorderColor3 = Themes.Border,
		Position = UDim2.new(0.5, -150, 0, 20),
		Size = UDim2.fromOffset(300, 28),
		Parent = gui,
	})

	local label = New("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.Arial,
		TextColor3 = Themes.TitleText,
		TextSize = 12,
		Text = text,
		Size = UDim2.fromScale(1, 1),
		Parent = frame,
	})

	task.delay(duration, function()
		if frame.Parent then
			frame:Destroy()
		end
	end)

	return frame
end

return AppleCheats
