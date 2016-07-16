local source = [[
local modulesFolder = script.Parent


local ChatBar = require(modulesFolder:WaitForChild("ChatBar"))
local ChannelsBar = require(modulesFolder:WaitForChild("ChannelsBar"))
local ChatChannel = require(modulesFolder:WaitForChild("ChatChannel"))

local function CreateGui()
	local Frame = Instance.new("Frame")
	Frame.Name = "Chat"
	Frame.BackgroundTransparency = 1
	Frame.Size = UDim2.new(1, 0, 1, 0)
	Frame.Visible = false
	
	local Dragger = Instance.new("ImageButton", Frame)
	Dragger.Name = "Dragger"
	Dragger.BackgroundTransparency = 1
	Dragger.Position = UDim2.new(0, 0, 0, 2)
	Dragger.Size = UDim2.new(0.3, 0, 0.35, 0)
	Dragger.Draggable = true
	
	local CoreGuiEnabledFrame = Instance.new("Frame")
	CoreGuiEnabledFrame.Name = "CoreGuiEnabledFrame"
	CoreGuiEnabledFrame.BackgroundTransparency = 1
	CoreGuiEnabledFrame.Size = UDim2.new(1, 0, 1, 0)
	
	Frame.Parent = CoreGuiEnabledFrame
	
	local ChatWindow = Instance.new("Frame", Dragger)
	ChatWindow.Name = "ChatWindow"
	ChatWindow.BackgroundColor3 = Color3.new(60/255, 60/255, 60/255)
	ChatWindow.BackgroundTransparency = 0.2
	ChatWindow.Size = UDim2.new(1, 0, 1, 0 - 30 - 4 - 30 - 4)
	ChatWindow.Position = UDim2.new(0, 0, 0, 34)
	
	local Resizer = Instance.new("ImageButton", Frame)
	Resizer.Name = "Resizer"
	Resizer.BackgroundColor3 = Color3.new(60/255, 60/255, 60/255)
	Resizer.BackgroundTransparency = 0.2
	Resizer.Size = UDim2.new(0, 30, 0, 30)
	
	
	Dragger.Draggable = true
	Dragger.Changed:connect(function(prop)
		if (prop ~= "AbsolutePosition") then return end
		
		local buttonTopLeftCorner = Dragger.AbsolutePosition
		local buttonBottomRightCorner = buttonTopLeftCorner + Dragger.AbsoluteSize
		
		local screenTopLeftCorner = Frame.AbsolutePosition
		local screenBottomRightCorner = screenTopLeftCorner + Frame.AbsoluteSize
		
		if (buttonTopLeftCorner.X < screenTopLeftCorner.X or buttonTopLeftCorner.Y < screenTopLeftCorner.Y or 
			buttonBottomRightCorner.X > screenBottomRightCorner.X or buttonBottomRightCorner.Y > screenBottomRightCorner.Y) then
			local reposX = math.max(screenTopLeftCorner.X, math.min(screenBottomRightCorner.X - Dragger.AbsoluteSize.X, buttonTopLeftCorner.X))
			local reposY = math.max(screenTopLeftCorner.Y, math.min(screenBottomRightCorner.Y - Dragger.AbsoluteSize.Y, buttonTopLeftCorner.Y))
			
			Dragger.Position = UDim2.new(0, reposX, 0, reposY)
		end
		
		local rtp = Dragger.AbsolutePosition + Dragger.AbsoluteSize - Resizer.AbsoluteSize
		Resizer.Position = UDim2.new(0, rtp.X, 0, rtp.Y)
		
	end)
	
	Resizer.Draggable = true
	spawn(function()
		wait()
		wait()
		
		Resizer.Changed:connect(function(prop)
			if (prop ~= "AbsolutePosition") then return end
			
			local bottomRightCorner = Resizer.AbsolutePosition + Resizer.AbsoluteSize
			local bottomRightCornerScreen = Frame.AbsolutePosition + Frame.AbsoluteSize
			
			local limitPosition = Vector2.new(math.min(bottomRightCorner.X, bottomRightCornerScreen.X), math.min(bottomRightCorner.Y, bottomRightCornerScreen.Y))			
			if (limitPosition ~= bottomRightCorner) then
				local pos = limitPosition - Resizer.AbsoluteSize
				Resizer.Position = UDim2.new(0, pos.X, 0, pos.Y)
				return
			end
			
			local size = Resizer.AbsolutePosition - Dragger.AbsolutePosition + Resizer.AbsoluteSize
			local sX = math.max(360, math.min(80000, size.X))
			local sY = math.max(180, math.min(40000, size.Y))
			Dragger.Size = UDim2.new(0, sX, 0, sY)
			
			if (Vector2.new(sX, sY) ~= size) then
				local rtp = Dragger.AbsolutePosition + Dragger.AbsoluteSize - Resizer.AbsoluteSize
				Resizer.Position = UDim2.new(0, rtp.X, 0, rtp.Y)
			end
		end)
		
		Resizer.Position = UDim2.new(0, Dragger.AbsoluteSize.X + Dragger.AbsolutePosition.X, 0, Dragger.AbsoluteSize.Y + Dragger.AbsolutePosition.Y) - Resizer.Size
		
	end)
	
	return Frame
end

local module = {}

local metatable = {
	__index = function(tbl, index)
		if (index == "Visible") then
			return tbl.Frame[index]
			
		elseif (index == "Parent") then
			return tbl.Frame.Parent and tbl.Frame.Parent[index] or nil
			
		elseif (index == "CoreGuiEnabled") then
			return tbl.Frame.Parent and tbl.Frame.Parent.Visible or false
			
		elseif (index == "ChatWindow") then
			return tbl.Frame.Dragger.ChatWindow
			
		else
			return rawget(tbl, index)
		end
	end,
	__newindex = function(tbl, index, value)
		if (index == "Visible") then
			tbl.Frame[index] = value
			
		elseif (index == "Parent") then
			tbl.Frame.Parent[index] = value
			
		else
			rawset(tbl, index, value)
		end
	end,
}

function module.new()
	local obj = {}
	obj.Frame = CreateGui()
	obj.ChatBar = nil
	obj.ChannelsBar = nil
	
	obj.ChatChannels = {}
	obj.CurrentChatChannel = nil
	
	obj.ChatSettings = require(modulesFolder:WaitForChild("ChatSettings"))
	
	function obj:AddChatChannel(channelName)
		local proxy = newproxy(true)
		getmetatable(proxy).__index = self
		
		local channelObj = ChatChannel.new(proxy, channelName)
		self.ChatChannels[channelName:lower()] = channelObj
		channelObj.Parent = self.Frame.Dragger.ChatWindow
		
		return channelObj
	end

	function obj:RemoveChatChannel(channelName)
		self.ChatChannels[channelName:lower()]:Destroy()
		self.ChatChannels[channelName:lower()] = nil
	end

	function obj:GetChatChannel(channelName)
		return self.ChatChannels[channelName:lower()]
	end

	function obj:SetCurrentChatChannel(channelName)
		if (self.CurrentChatChannel) then
			self.CurrentChatChannel.Visible = false
		end
		
		if (channelName) then	
			self.CurrentChatChannel = self:GetChatChannel(channelName)
		else
			self.CurrentChatChannel = nil
		end
		
		if (self.CurrentChatChannel) then
			self.CurrentChatChannel.Visible = true
			self.CurrentChatChannel:ReorderChatMessages()
		end
	end
	
	function obj:SetCoreGuiEnabled(enabled)
		self.Frame.Parent.Visible = enabled
	end
	
	function obj:ReorganizeGuiElements()
		self.ChannelsBar.FontSize = self.ChatSettings.ChannelTabFontSize
		self.ChatBar.TextBox.FontSize = self.ChatSettings.ChatMessageFontSize
		
		self.ChannelsBar:UpdateTabSizes()
		self.ChatBar:ResetSize()
		
		local channelsBarSizeY = tonumber(self.ChannelsBar.FontSize.Name:match("%d+")) + 8 + 4
		local chatBarSizeY = tonumber(self.ChatBar.TextBox.FontSize.Name:match("%d+")) + 8 + 4
		local borderGapSizeY = 4
				
		self.ChannelsBar.Frame.Size = UDim2.new(1, 0, 0, channelsBarSizeY)
		self.ChannelsBar.Frame.Position = UDim2.new(0, 0, 0, 1)
		
		self.Frame.Dragger.ChatWindow.Size = UDim2.new(1, 0, 1, 0 - channelsBarSizeY - borderGapSizeY - chatBarSizeY - borderGapSizeY)
		self.Frame.Dragger.ChatWindow.Position = UDim2.new(0, 0, 0, channelsBarSizeY + borderGapSizeY)
		
		self.ChatBar.Frame.Size = UDim2.new(1, 0, 0, chatBarSizeY)
		self.ChatBar.Frame.Position = UDim2.new(0, 0, 1, -chatBarSizeY)
		
		self.Frame.Resizer.Size = UDim2.new(0, chatBarSizeY, 0, chatBarSizeY)
		
		for channelName, channel in pairs(self.ChatChannels) do
			channel:SetFontSize(self.ChatSettings.ChatMessageFontSize)
		end
	end
	
	obj = setmetatable(obj, metatable)
	
	local proxy = newproxy(true)
	getmetatable(proxy).__index = obj
	
	rawset(obj, "ChatBar", ChatBar.new(proxy))
	rawset(obj, "ChannelsBar", ChannelsBar.new(proxy))
	
	obj.ChatBar.Parent = obj.Frame.Dragger
	obj.ChannelsBar.Parent =  obj.Frame.Dragger
	
	obj:ReorganizeGuiElements()
	
	return obj
end

return module

]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script