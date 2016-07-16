local source = [[
local function CreateGui()
	local ChatWindow = Instance.new("Frame")
	ChatWindow.BackgroundTransparency = 1
	ChatWindow.Size = UDim2.new(1, 0, 1, 0)
	ChatWindow.Visible = false

	local Scroller = Instance.new("ScrollingFrame", ChatWindow)
	Scroller.Name = "Scroller"
	Scroller.BackgroundTransparency = 1
	Scroller.Position = UDim2.new(0, 0, 0, 0)
	Scroller.Size = UDim2.new(1, -4, 1, -6)
	Scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
	Scroller.ScrollBarThickness = 4

	return ChatWindow
end

local module = {}
module.MaximumMesageLength = 140

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

function module.new(ChatWindow, channelName)
	local obj = {}
	obj.ChatWindow = ChatWindow
	
	obj.Frame = CreateGui()
	obj.Scroller = obj.Frame.Scroller

	obj.Name = channelName
	obj.Muted = false
	
	obj.FontSize = Enum.FontSize.Size18
	
	obj.ChatHistory = {}
	
	function obj:AddLabelToLog(label)
		label.FontSize = self.FontSize
		for i, v in pairs(label:GetChildren()) do
			v.FontSize = label.FontSize
		end
		
		local chatMessageSizeY = tonumber(self.FontSize.Name:match("%d+"))
		
		local Scroller = self.Scroller
			
		label.Parent = Scroller
		label.Position = UDim2.new(0, 4, 0, Scroller.CanvasSize.Y.Offset)
		
		local lines = 0
		while (not label.TextFits) do
			lines = lines + 1
			label.Size = label.Size + UDim2.new(0, 0, 0, chatMessageSizeY)
			if (lines > 3) then break end
		end
		
		local scrollBarBottomPosition = (Scroller.CanvasSize.Y.Offset - Scroller.AbsoluteSize.Y)
		local reposition = (Scroller.CanvasPosition.Y >= scrollBarBottomPosition)
		
		local add = UDim2.new(0, 0, 0, label.Size.Y.Offset)
		Scroller.CanvasSize = Scroller.CanvasSize + add
		if (reposition) then
			Scroller.CanvasPosition = Vector2.new(0, math.max(0, Scroller.CanvasSize.Y.Offset - Scroller.AbsoluteSize.Y))
		end
		
		table.insert(self.ChatHistory, label)
		
		if (#self.ChatHistory > self.ChatWindow.ChatSettings.MaximumMessageLog) then
			self:RemoveMessageFromLog()
		end
	end
	
	function obj:Destroy()
		self.Frame:Destroy()
		self.Frame = nil
	end
	
	function obj:ReorderChatMessages()
		local labels = self.ChatHistory
		self.ChatHistory = {}
		
		for i, label in pairs(labels) do
			label.Position = UDim2.new(0, 8, 0, 0)
			label.Size = UDim2.new(1, -16, 0, 0)
		end
		
		self.Scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
		self.Scroller.CanvasPosition = Vector2.new(0, 0)
		
		for i, label in pairs(labels) do
			self:AddLabelToLog(label)
		end
		
	end
	
	function obj:SetFontSize(fontSize)
		self.FontSize = fontSize
		self:ReorderChatMessages()
	end
	
	function obj:RemoveMessageFromLog()
		local messages = self.ChatHistory
		local lastIndex = #messages
		
		local removing = table.remove(messages, 1)
		local offset = removing.AbsoluteSize.Y
		removing:Destroy()
		
		for i, message in pairs(messages) do
			message.Position = message.Position - UDim2.new(0, 0, 0, offset)
		end
		
		self.Scroller.CanvasSize = self.Scroller.CanvasSize - UDim2.new(0, 0, 0, offset)
		
	end
	
	
	
	local deb = false
	local queued = false
	obj.Scroller.Changed:connect(function(prop)
		if (prop ~= "AbsoluteSize") then return end
		if deb then queued = true return end
		deb = true
		obj:ReorderChatMessages()
		wait(0.4)
		if (queued) then
			obj:ReorderChatMessages()
			queued = false
			wait(0.4)
		end
		deb = false
	end)
	
	
	return setmetatable(obj, metatable)
end

return module

]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script