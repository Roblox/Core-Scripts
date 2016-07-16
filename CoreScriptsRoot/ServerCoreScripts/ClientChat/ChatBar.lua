local source = [[
local function CreateGui()
	local ChatBar = Instance.new("Frame")
	ChatBar.Name = "ChatBar"
	ChatBar.BackgroundTransparency = 0.2
	ChatBar.BackgroundColor3 = Color3.new(60/255, 60/255, 60/255)
	--ChatBar.BorderSizePixel = 0
	ChatBar.Position = UDim2.new(0, 0, 1, -30)
	ChatBar.Size = UDim2.new(1, -30, 0, 30)
	
	local EnabledFrame = Instance.new("Frame")
	EnabledFrame.BackgroundTransparency = 1
	EnabledFrame.Size = UDim2.new(1, 0, 1, 0)
	
	Instance.new("Frame", ChatBar)
	ChatBar.Frame.Position = UDim2.new(0, 6, 0, 4)
	ChatBar.Frame.Size = UDim2.new(1, -12, 1, -8)
	ChatBar.Frame.BackgroundColor3 = Color3.new(220/255, 220/255, 220/255)
	ChatBar.Frame.BorderSizePixel = 0
	
	local ChatBarBox = Instance.new("TextBox", ChatBar.Frame)
	ChatBarBox.Position = UDim2.new(0, 6, 0, 0)
	ChatBarBox.Size = UDim2.new(1, -12, 1, 0)
	ChatBarBox.Font = Enum.Font.SourceSansBold
	ChatBarBox.FontSize = Enum.FontSize.Size18
	ChatBarBox.TextColor3 = Color3.new(120/255, 120/255, 120/255)
	ChatBarBox.TextWrapped = true
	ChatBarBox.TextXAlignment = "Left"
	ChatBarBox.BackgroundTransparency = 1
	ChatBarBox.TextWrapped = true
	
	ChatBar.Parent = EnabledFrame
	
	return ChatBar
end

local module = {}

local metatable = {
	__index = function(tbl, index)
		if (index == "Visible") then
			return tbl.Frame[index]
		elseif (index == "Parent") then
			return tbl.Frame.Parent and tbl.Frame.Parent[index] or nil
		elseif (index == "Text" or index == "ClearTextOnFocus" or index == "FocusLost") then
			return tbl.TextBox[index]
		elseif (index == "Enabled") then
			return tbl.Frame.Parent and tbl.Frame.Parent.Visible or false
		else
			return rawget(tbl, index)
		end
	end,
	__newindex = function(tbl, index, value)
		if (index == "Visible") then
			tbl.Frame[index] = value
		elseif (index == "Parent") then
			tbl.Frame.Parent[index] = value
		elseif (index == "Text" or index == "ClearTextOnFocus") then
			tbl.TextBox[index] = value
			
		elseif (index == "Enabled") then
			tbl.Frame.Parent.Visible = value
			
		else
			rawset(tbl, index, value)
			
		end
	end,
}

function module.new(ChatWindow)
	local obj = {}
	obj.ChatWindow = ChatWindow
	
	obj.Frame = CreateGui()
	obj.TextBox = obj.Frame.Frame.TextBox
	obj.SwapText = ""
	
	function obj:CaptureFocus()
		self.TextBox:CaptureFocus()
	end

	function obj:ReleaseFocus(didRelease)
		self.TextBox:ReleaseFocus(didRelease)
	end

	function obj:IsFocused()
		return self.TextBox:IsFocused()
	end

	function obj:ResetText()
		self.TextBox.Text = "To chat click here or press the \"/\" key"
	end
	
	function obj:ResetSize()
		local fontSize = tonumber(self.TextBox.FontSize.Name:match("%d+"))
		local baseSize = fontSize + 8 + 4
		
		self.Frame.Size = UDim2.new(1, 0 - baseSize - 4, 0, baseSize)
		--self.SwapText = ""
	end
	
	function obj:CalculateBoxSize()
		local fontSize = tonumber(self.TextBox.FontSize.Name:match("%d+"))
		local baseSize = fontSize + 8 + 4
		local bounds = self.TextBox.TextBounds.Y
		
		self.Frame.Size = UDim2.new(1, 0 - baseSize - 4, 0, bounds + baseSize - 4)
		if (string.len(self.TextBox.Text) > 140) then
			self.TextBox.Text = string.sub(self.TextBox.Text, 1, 140)
		end
	end
	
	obj.TextBox.Changed:connect(function(prop)
		if (obj:IsFocused()) then
			obj:CalculateBoxSize()
		else
			obj:ResetSize()
		end
		
	end)
	
	obj.TextBox.FocusLost:connect(function(enterPressed, inputResponsible)
		--print("Unfocusing:\t\t", obj.SwapText, "{SW || CT}", obj.TextBox.Text)
		obj.SwapText = obj.TextBox.Text
		obj:ResetText()
		obj:ResetSize()
		obj.TextBox.Parent.BackgroundTransparency = 0.4

		if (inputResponsible and inputResponsible.KeyCode == Enum.KeyCode.Escape) then
			obj.SwapText = ""
		end

		--print("Unfocused:\t\t", obj.SwapText, "{SW || CT}", obj.TextBox.Text)
	end)
	
	obj.TextBox.Focused:connect(function()
		--print("Focusing:\t\t", obj.SwapText, "{SW || CT}", obj.TextBox.Text)
		obj:CalculateBoxSize()
		obj.TextBox.Text = obj.SwapText
		obj.TextBox.Parent.BackgroundTransparency = 0
		--print("Focused:\t\t", obj.SwapText, "{SW || CT}", obj.TextBox.Text)
	end)
	
	return setmetatable(obj, metatable)
end

return module

]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script