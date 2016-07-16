local source = [[
local function CreateGui()
	local ChannelFrame = Instance.new("ScrollingFrame")
	ChannelFrame.Name = "ChannelFrame"
	ChannelFrame.BackgroundTransparency = 0.2
	ChannelFrame.BackgroundColor3 = Color3.new(60/255, 60/255, 60/255)
	--ChannelFrame.BorderSizePixel = 0
	ChannelFrame.Position = UDim2.new(0, 0, 0, 1)
	ChannelFrame.Size = UDim2.new(1, 0, 0, 30)
	ChannelFrame.ScrollBarThickness = 2
	
	local PlacementFrame = Instance.new("Frame", ChannelFrame)
	PlacementFrame.Name = "PlacementFrame"
	PlacementFrame.BackgroundTransparency = 1
	PlacementFrame.Size = UDim2.new(0, 0, 0.4, 0 - ChannelFrame.ScrollBarThickness - 2)
	PlacementFrame.Position = UDim2.new(0, 0, 0.6, 0)
	
	return ChannelFrame
end

local function CreateChannelTab()
	local Frame = Instance.new("ImageButton")
	Frame.BackgroundTransparency = 1
	Frame.Size = UDim2.new(0, 1000, 2.5, 0)
	Frame.Position = UDim2.new(0, 0, -1.5, 0)
	Frame.ClipsDescendants = true

	local Button = Instance.new("TextLabel", Frame)
	Button.Name = "ButtonObj"
	Button.BackgroundTransparency = 0
	Button.Position = UDim2.new(0, 0, 0.3, 0)
	Button.Size = UDim2.new(1, 0, 0.7, 0)
	Button.Font = Enum.Font.SourceSansBold
	Button.FontSize = Enum.FontSize.Size18
	Button.TextStrokeTransparency = 0.7
	Button.TextColor3 = Color3.new(1, 1, 1)
	Button.Text = ""
	
	return Frame
end

local module = {}

local metatable = {
	__index = function(tbl, index)
		if (index == "Parent" or index == "Visible") then
			return tbl.Frame[index]
			
		else
			return rawget(tbl, index)
		end
	end,
	__newindex = function(tbl, index, value)
		if (index == "Visible" or index == "Parent") then
			tbl.Frame[index] = value
			
		else
			rawset(tbl, index, value)
			
		end
	end,
}

function module.new(ChatWindow)
	local obj = {}
	obj.ChatWindow = ChatWindow
	
	obj.Frame = CreateGui()
	obj.BaseChannelTab = CreateChannelTab()

	obj.ChannelTabs = {}
	obj.CurrentChannelTab = nil

	obj.eOnChannelTabChanged = Instance.new("BindableEvent")
	obj.OnChannelTabChanged = obj.eOnChannelTabChanged.Event
	
	obj.FontSize = Enum.FontSize.Size18
	
	function obj:GetChannelTab(channelName)
		return self.ChannelTabs[channelName:lower()]
	end
	
	function obj:AddChannelTab(channelName)
		if (self:GetChannelTab(channelName)) then return end
		
		local tab = self.BaseChannelTab:Clone()
		tab.ButtonObj.Text = channelName
		tab.Parent = self.Frame.PlacementFrame
		
		local minWidth = 78
		local width = math.max(minWidth, tab.ButtonObj.TextBounds.X + 8)
		tab.Size = UDim2.new(0, width + (1 * 2), 1, 0)
		
		tab.MouseButton1Click:connect(function()
			if (self.CurrentChannelTab ~= nil and self.CurrentChannelTab.ButtonObj.Text:lower() == channelName:lower()) then
				self:SetActiveChannelTab(nil)				
			else
				self:SetActiveChannelTab(channelName)
			end
		end)
		
		tab.InputBegan:connect(function(input)
			if (input.UserInputType == Enum.UserInputType.MouseButton2) then
				print("close tab")
			end
		end)

		self.ChannelTabs[channelName:lower()] = tab
		self:UpdateTabSizes()
	end

	function obj:RemoveChannelTab(channelName)
		if (self.CurrentChannelTab and self.CurrentChannelTab.Name:lower() == channelName:lower()) then
			self:SetActiveChannelTab("")
		end

		self.ChannelTabs[channelName:lower()]:Destroy()
		self.ChannelTabs[channelName:lower()] = nil

		self:OrganizeChannelTabs()
	end

	function obj:SetActiveChannelTab(channelName)
		if (self.CurrentChannelTab) then
			self.CurrentChannelTab.ButtonObj.Position = self.BaseChannelTab.ButtonObj.Position
			self.CurrentChannelTab.ButtonObj.Size = self.BaseChannelTab.ButtonObj.Size
		end
		
		if (channelName) then
			self.CurrentChannelTab = self.ChannelTabs[channelName:lower()]
		else
			self.CurrentChannelTab = nil
		end
		
		if (self.CurrentChannelTab) then
			self.CurrentChannelTab.ButtonObj.Position = UDim2.new(0, 0, 0, 0)
			self.CurrentChannelTab.ButtonObj.Size = UDim2.new(1, 0, 1, 0)
			
			self.CurrentChannelTab.ButtonObj.TextColor3 = Color3.new(1, 1, 1)
		end

		self:OrganizeChannelTabs()
		self.eOnChannelTabChanged:Fire(channelName)
	end

	function obj:OrganizeChannelTabs()
		local tabOrder = {}
		
		for channelName, tab in pairs(self.ChannelTabs) do
			local i = 1
			while (i <= #tabOrder and tabOrder[i] < channelName) do
				i = i + 1
			end
			table.insert(tabOrder, i, channelName)
		end
		
		local posOffsetY = (self.Frame.PlacementFrame.AbsoluteSize.Y - self.Frame.AbsoluteSize.Y)
		local currentPosition = 1
		for i, channelName in pairs(tabOrder) do
			local tab = self.ChannelTabs[channelName]
			tab.Position = UDim2.new(0, currentPosition, 0, posOffsetY)
			
			currentPosition = currentPosition + tab.Size.X.Offset + (tab.BorderSizePixel * 2) + 1
		end
		
		self.Frame.CanvasSize = UDim2.new(0, currentPosition, 0, 0)
		
		self:UpdateScrollingBar()
	end

	function obj:OnMessagePostedInChannel(channelName)
		local tab = self:GetChannelTab(channelName)
		if (tab) then
			if (tab.ButtonObj.Size.Y.Scale ~= 1) then
				tab.ButtonObj.TextColor3 = self.ChatWindow.ChatSettings.ChannelTabNotificationColor
			end
		end
	end
	
	function obj:UpdateTabSizes()
		local height = self.Frame.AbsoluteSize.Y
		local minWidth = height * 2
		
		for channelName, tab in pairs(self.ChannelTabs) do
			--tab.Size = UDim2.new(0, 100000, 1, 0)
			local width = math.max(minWidth, tab.ButtonObj.TextBounds.X + 8)
			tab.Size = UDim2.new(0, width + (1 * 2), 0, self.Frame.AbsoluteSize.Y)
			tab.ButtonObj.FontSize = self.FontSize
		end
		
		self:OrganizeChannelTabs()
	end
	
	function obj:UpdateScrollingBar()
		if (self.Frame.CanvasSize.X.Offset > self.Frame.AbsoluteSize.X) then
			self.Frame.PlacementFrame.Size = UDim2.new(0, 0, 0.5, 0 - self.Frame.ScrollBarThickness - 2)
		else
			self.Frame.PlacementFrame.Size = UDim2.new(0, 0, 0.5, 0)
		end
		
		self.Frame.PlacementFrame.Position = UDim2.new(0, 0, 0.5, 0)
	end
	
	obj.Frame.Changed:connect(function(prop)
		if (prop == "AbsoluteSize") then
			obj:UpdateScrollingBar()
		end
	end)
	
	obj:UpdateScrollingBar()
	
	return setmetatable(obj, metatable)
end

return module

]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script