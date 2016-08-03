local source = [[
local module = {}
--////////////////////////////// Include
--//////////////////////////////////////
local modulesFolder = script.Parent
local moduleTransparencyTweener = require(modulesFolder:WaitForChild("TransparencyTweener"))

--////////////////////////////// Details
--//////////////////////////////////////
local metatable = {}
metatable.__ClassName = "ChatChannel"

metatable.__tostring = function(tbl)
	return tbl.__ClassName .. ": " .. tbl.MemoryLocation
end

metatable.__metatable = "The metatable is locked"
metatable.__index = function(tbl, index, value)
	if rawget(tbl, index) then return rawget(tbl, index) end
	if rawget(metatable, index) then return rawget(metatable, index) end
	error(index .. " is not a valid member of " .. tbl.__ClassName)
end
metatable.__newindex = function(tbl, index, value)
	error(index .. " is not a valid member of " .. tbl.__ClassName)
end


--////////////////////////////// Methods
--//////////////////////////////////////
local function CreateGuiObject()
	local BaseFrame = Instance.new("Frame")
	BaseFrame.Size = UDim2.new(1, 0, 1, 0)
	BaseFrame.BackgroundTransparency = 1

	local Scroller = Instance.new("ScrollingFrame", BaseFrame)
	Scroller.Name = "Scroller"
	Scroller.BackgroundTransparency = 1
	Scroller.Position = UDim2.new(0, 0, 0, 3)
	Scroller.Size = UDim2.new(1, -4, 1, -6)
	Scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
	Scroller.ScrollBarThickness = module.ScrollBarThickness

	return BaseFrame, Scroller
end

function metatable:Dump()
	return tostring(self) .. "; " .. self.Name
end

function metatable:Destroy()
	self.GuiObject:Destroy()
end

function metatable:SetActive(active)
	self.GuiObject.Visible = active
end

function metatable:AddMessageLabelToLog(messageObject)
	self.TextTweener:RegisterTweenObjectProperty(messageObject.Tweener, "Transparency")

	table.insert(self.MessageObjectLog, messageObject)
	self:PositionMessageLabelInWindow(messageObject)

end

function metatable:PositionMessageLabelInWindow(messageObject)
	local baseFrame = messageObject.BaseFrame
	local baseMessage = messageObject.BaseMessage

	baseFrame.Parent = self.Scroller
	baseFrame.Position = UDim2.new(0, 0, 0, self.Scroller.CanvasSize.Y.Offset)
	
	--// This looks stupid, but it's actually necessary.
	--// TextBounds wont be calculated correctly unless it has enough space.
	baseFrame.Size = UDim2.new(1, 0, 0, 1000)
	baseFrame.Size = UDim2.new(1, 0, 0, baseMessage.TextBounds.Y)

	local scrollBarBottomPosition = (self.Scroller.CanvasSize.Y.Offset - self.Scroller.AbsoluteSize.Y)
	local reposition = (self.Scroller.CanvasPosition.Y >= scrollBarBottomPosition)

	local add = UDim2.new(0, 0, 0, baseFrame.Size.Y.Offset)
	self.Scroller.CanvasSize = self.Scroller.CanvasSize + add

	if (reposition) then
		self.Scroller.CanvasPosition = Vector2.new(0, math.max(0, self.Scroller.CanvasSize.Y.Offset - self.Scroller.AbsoluteSize.Y))
	else
		local displayNewMessagesIfNotFullyScrolledDown = false
		self.ChannelTab:UpdateMessagePostedInChannel(displayNewMessagesIfNotFullyScrolledDown)
	end
end

function metatable:ReorderAllMessages()
	self.Scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
	for i, messageObject in pairs(self.MessageObjectLog) do
		self:PositionMessageLabelInWindow(messageObject)
	end
end

function metatable:RegisterChannelTab(tab)
	rawset(self, "ChannelTab", tab)
end

function metatable:FadeOutBackground(duration)
	--// Do nothing
end

function metatable:FadeInBackground(duration)
	--// Do nothing
end

function metatable:FadeOutText(duration)
	self.TextTweener:Tween(duration, 1)
end

function metatable:FadeInText(duration)
	self.TextTweener:Tween(duration, 0)
end

--///////////////////////// Constructors
--//////////////////////////////////////
module.ScrollBarThickness = 4

function module.new(channelName)
	local obj = {}
	obj.MemoryLocation = tostring(obj):match("[0123456789ABCDEF]+")
	
	local BaseFrame, Scroller = CreateGuiObject()
	obj.GuiObject = BaseFrame
	obj.Scroller = Scroller

	obj.MessageObjectLog = {}
	obj.ChannelTab = nil

	obj.TextTweener = moduleTransparencyTweener.new()

	obj.Name = channelName
	obj.GuiObject.Name = "Frame_" .. obj.Name

	obj = setmetatable(obj, metatable)

	obj.GuiObject.Changed:connect(function(prop)
		if (prop == "AbsoluteSize") then
			spawn(function() obj:ReorderAllMessages() end)
		end
	end)

	return obj
end

return module
]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script