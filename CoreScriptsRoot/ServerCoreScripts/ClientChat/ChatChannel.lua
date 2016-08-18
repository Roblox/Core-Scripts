local source = [[
local module = {}
--////////////////////////////// Include
--//////////////////////////////////////
local modulesFolder = script.Parent
local moduleTransparencyTweener = require(modulesFolder:WaitForChild("TransparencyTweener"))
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}

local function CreateGuiObject()
	local BaseFrame = Instance.new("Frame")
	BaseFrame.Size = UDim2.new(1, 0, 1, 0)
	BaseFrame.BackgroundTransparency = 1

	local Scroller = Instance.new("ScrollingFrame", BaseFrame)
	Scroller.Name = "Scroller"
	Scroller.BackgroundTransparency = 1
	Scroller.BorderSizePixel = 0
	Scroller.Position = UDim2.new(0, 0, 0, 3)
	Scroller.Size = UDim2.new(1, -4, 1, -6)
	Scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
	Scroller.ScrollBarThickness = module.ScrollBarThickness
	Scroller.Active = false

	return BaseFrame, Scroller
end

function methods:Destroy()
	self.GuiObject:Destroy()
end

function methods:SetActive(active)
	self.GuiObject.Visible = active
end

function methods:AddMessageLabelToLog(messageObject)
	self.TextTweener:RegisterTweenObjectProperty(messageObject.Tweener, "Transparency")

	table.insert(self.MessageObjectLog, messageObject)
	self:PositionMessageLabelInWindow(messageObject)

	if (#self.MessageObjectLog > 50) then
		self:RemoveLastMessageLabelFromLog()
	end
end

function methods:RemoveLastMessageLabelFromLog()
	local lastMessage = self.MessageObjectLog[1]
	local posOffset = UDim2.new(0, 0, 0, lastMessage.BaseFrame.AbsoluteSize.Y)

	lastMessage:Destroy()
	table.remove(self.MessageObjectLog, 1)

	for i, messageObject in pairs(self.MessageObjectLog) do
		messageObject.BaseFrame.Position = messageObject.BaseFrame.Position - posOffset
	end

	self.Scroller.CanvasSize = self.Scroller.CanvasSize - posOffset
end

function methods:PositionMessageLabelInWindow(messageObject)
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

function methods:ReorderAllMessages()
	self.Scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
	for i, messageObject in pairs(self.MessageObjectLog) do
		self:PositionMessageLabelInWindow(messageObject)
	end
end

function methods:ClearMessageLog()
	for i, v in pairs(self.MessageObjectLog) do
		v:Destroy()
	end
	rawset(self, "MessageObjectLog", {})

	self.Scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
end

function methods:RegisterChannelTab(tab)
	rawset(self, "ChannelTab", tab)
end

function methods:FadeOutBackground(duration)
	--// Do nothing
end

function methods:FadeInBackground(duration)
	--// Do nothing
end

function methods:FadeOutText(duration)
	self.TextTweener:Tween(duration, 1)
end

function methods:FadeInText(duration)
	self.TextTweener:Tween(duration, 0)
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("ChatChannel", methods)

module.ScrollBarThickness = 4

function module.new(channelName)
	local obj = {}

	local BaseFrame, Scroller = CreateGuiObject()
	obj.GuiObject = BaseFrame
	obj.Scroller = Scroller

	obj.MessageObjectLog = {}
	obj.ChannelTab = nil

	obj.TextTweener = moduleTransparencyTweener.new()

	obj.Name = channelName
	obj.GuiObject.Name = "Frame_" .. obj.Name

	ClassMaker.MakeClass("ChatChannel", obj)

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