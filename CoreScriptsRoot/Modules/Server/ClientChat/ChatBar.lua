--	// FileName: ChatBar.lua
--	// Written by: Xsitsu
--	// Description: Manages text typing and typing state.

local module = {}

local UserInputService = game:GetService("UserInputService")

--////////////////////////////// Include
--//////////////////////////////////////
local Chat = game:GetService("Chat")
local clientChatModules = Chat:WaitForChild("ClientChatModules")
local modulesFolder = script.Parent
local ChatSettings = require(clientChatModules:WaitForChild("ChatSettings"))
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))
local CurveUtil = require(modulesFolder:WaitForChild("CurveUtil"))

local MessageSender = require(modulesFolder:WaitForChild("MessageSender"))

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}

function methods:CreateGuiObjects(targetParent)
	rawset(self, "ChatBarParentFrame", targetParent)

	local backgroundImagePixelOffset = 7
	local textBoxPixelOffset = 5

	local BaseFrame = Instance.new("Frame")
	BaseFrame.Selectable = false
	BaseFrame.Size = UDim2.new(1, 0, 1, 0)
	BaseFrame.BackgroundTransparency = 0.6
	BaseFrame.BorderSizePixel = 0
	BaseFrame.BackgroundColor3 = ChatSettings.ChatBarBackGroundColor
	BaseFrame.Parent = targetParent

	local BoxFrame = Instance.new("Frame")
	BoxFrame.Selectable = false
	BoxFrame.Name = "BoxFrame"
	BoxFrame.BackgroundTransparency = 0.6
	BoxFrame.BorderSizePixel = 0
	BoxFrame.BackgroundColor3 = ChatSettings.ChatBarBoxColor
	BoxFrame.Size = UDim2.new(1, -backgroundImagePixelOffset * 2, 1, -backgroundImagePixelOffset * 2)
	BoxFrame.Position = UDim2.new(0, backgroundImagePixelOffset, 0, backgroundImagePixelOffset)
	BoxFrame.Parent = BaseFrame

	local TextBoxHolderFrame = Instance.new("Frame")
	TextBoxHolderFrame.BackgroundTransparency = 1
	TextBoxHolderFrame.Size = UDim2.new(1, -textBoxPixelOffset * 2, 1, -textBoxPixelOffset * 2)
	TextBoxHolderFrame.Position = UDim2.new(0, textBoxPixelOffset, 0, textBoxPixelOffset)
	TextBoxHolderFrame.Parent = BoxFrame

	local TextBox = Instance.new("TextBox")
	TextBox.Selectable = ChatSettings.GamepadNavigationEnabled
	TextBox.Name = "ChatBar"
	TextBox.BackgroundTransparency = 1
	TextBox.Size = UDim2.new(1, 0, 1, 0)
	TextBox.Position = UDim2.new(0, 0, 0, 0)
	TextBox.TextSize = ChatSettings.ChatBarTextSize
	TextBox.Font = ChatSettings.ChatBarFont
	TextBox.TextColor3 = ChatSettings.ChatBarTextColor
	TextBox.TextTransparency = 0.4
	TextBox.TextStrokeTransparency = 1
	TextBox.ClearTextOnFocus = false
	TextBox.TextXAlignment = Enum.TextXAlignment.Left
	TextBox.TextYAlignment = Enum.TextYAlignment.Top
	TextBox.TextWrapped = true
	TextBox.Text = ""
	TextBox.Parent = TextBoxHolderFrame

	local MessageModeTextLabel = Instance.new("TextLabel")
	MessageModeTextLabel.Name = "MessageMode"
	MessageModeTextLabel.BackgroundTransparency = 1
	MessageModeTextLabel.Position = UDim2.new(0, 0, 0, 0)
	MessageModeTextLabel.TextSize = ChatSettings.ChatBarTextSize
	MessageModeTextLabel.Font = ChatSettings.ChatBarFont
	MessageModeTextLabel.TextXAlignment = Enum.TextXAlignment.Left
	MessageModeTextLabel.TextWrapped = true
	MessageModeTextLabel.Text = ""
	MessageModeTextLabel.Size = UDim2.new(0.3, 0, 1, 0)
	MessageModeTextLabel.TextYAlignment = Enum.TextYAlignment.Center
	MessageModeTextLabel.TextColor3 = Color3.fromRGB(77, 139, 255)
	MessageModeTextLabel.Visible = false
	MessageModeTextLabel.Parent = TextBoxHolderFrame

	local TextLabel = Instance.new("TextLabel")
	TextLabel.Selectable = false
	TextLabel.TextWrapped = true
	TextLabel.BackgroundTransparency = 1
	TextLabel.Size = TextBox.Size
	TextLabel.Position = TextBox.Position
	TextLabel.TextSize = TextBox.TextSize
	TextLabel.Font = TextBox.Font
	TextLabel.TextColor3 = TextBox.TextColor3
	TextLabel.TextTransparency = TextBox.TextTransparency
	TextLabel.TextStrokeTransparency = TextBox.TextStrokeTransparency
	TextLabel.TextXAlignment = TextBox.TextXAlignment
	TextLabel.TextYAlignment = TextBox.TextYAlignment
	TextLabel.Text = "This value needs to be set with :SetTextLabelText()"
	TextLabel.Parent = TextBoxHolderFrame

	rawset(self, "GuiObject", BaseFrame)
	rawset(self, "TextBox", TextBox)
	rawset(self, "TextLabel", TextLabel)

	self.GuiObjects.BaseFrame = BaseFrame
	self.GuiObjects.TextBoxFrame = BoxFrame
	self.GuiObjects.TextBox = TextBox
	self.GuiObjects.TextLabel = TextLabel
	self.GuiObjects.MessageModeTextLabel = MessageModeTextLabel

	self:AnimGuiObjects()
	self:SetUpTextBoxEvents(TextBox, TextLabel, MessageModeTextLabel)
	self.eGuiObjectsChanged:Fire()
end

function methods:DisconnectConnections()
	for i = 1, #self.Connections do
		self.Connections[i]:Disconnect()
	end
	self.Connections = {}
end

function methods:SetUpTextBoxEvents(TextBox, TextLabel, MessageModeTextLabel)
	self:DisconnectConnections()

	--// Code for getting back into general channel from other target channel when pressing backspace.
	local inputBeganConnection = UserInputService.InputBegan:connect(function(inputObj, gpe)
		if (inputObj.KeyCode == Enum.KeyCode.Backspace) then
			if (TextBox:IsFocused() and TextBox.Text == "") then
				self:SetChannelTarget(ChatSettings.GeneralChannelName)
			end
		end
	end)
	table.insert(self.Connections, inputBeganConnection)

	local textboxChangedConnection = TextBox.Changed:connect(function(prop)
		if prop ~= "Text" then
			return
		end

		self:CalculateSize()

		if (string.len(TextBox.Text) > ChatSettings.MaximumMessageLength) then
			TextBox.Text = string.sub(TextBox.Text, 1, ChatSettings.MaximumMessageLength)
			return
		end

		if not self.InCustomState then
			local customState = self.CommandProcessor:ProcessInProgressChatMessage(TextBox.Text, self.ChatWindow, self)
			if customState then
				self.InCustomState = true
				rawset(self, "CustomState", customState)
			end
		else
			self.CustomState:TextUpdated()
		end
	end)
	table.insert(self.Connections, textboxChangedConnection)

	local function UpdateOnFocusStatusChanged(isFocused)
		if (isFocused) then
			TextLabel.Visible = false
			MessageModeTextLabel.Visible = true
		else
			local setVis = (TextBox.Text == "")
			TextLabel.Visible = setVis
			MessageModeTextLabel.Visible = not setVis
		end
	end

	local textboxfocusedConnection = TextBox.Focused:connect(function()
		self:CalculateSize()
		UpdateOnFocusStatusChanged(true)
	end)
	table.insert(self.Connections, textboxfocusedConnection)

	local textboxFocusLostConnection = TextBox.FocusLost:connect(function(enterPressed, inputObject)
		self:ResetSize()
		if (inputObject and inputObject.KeyCode == Enum.KeyCode.Escape) then
			TextBox.Text = ""
		end
		UpdateOnFocusStatusChanged(false)
	end)
	table.insert(self.Connections, textboxFocusLostConnection)
end

function methods:GetTextBox()
	return self.TextBox
end

function methods:GetMessageModeTextLabel()
	return self.GuiObjects.MessageModeTextLabel
end

function methods:IsFocused()
	-- Temporary hack while reparenting is necessary.
	if not self.GuiObject:IsDescendantOf(game) then
		if rawget(self, "LastFocusedState") then
			return self.LastFocusedState.Focused
		end
	end
	return self:GetTextBox():IsFocused()
end

function methods:GetVisible()
	return self.GuiObject.Visible
end

function methods:CaptureFocus()
	self:GetTextBox():CaptureFocus()
end

function methods:ReleaseFocus(didRelease)
	self:GetTextBox():ReleaseFocus(didRelease)
end

function methods:ResetText()
	self:GetTextBox().Text = ""
end

function methods:SetText(text)
	self:GetTextBox().Text = text
end

function methods:GetEnabled()
	return self.GuiObject.Visible
end

function methods:SetEnabled(enabled)
	self.GuiObject.Visible = enabled
end

function methods:SetTextLabelText(text)
	self.TextLabel.Text = text
end

function methods:SetTextBoxText(text)
	self.TextBox.Text = text
end

function methods:GetTextBoxText()
	return self.TextBox.Text
end

function methods:ResetSize()
	self.TargetYSize = 0
	self:TweenToTargetYSize()
end

function methods:CalculateSize()
	local lastPos = self.GuiObject.Size
	self.GuiObject.Size = UDim2.new(1, 0, 0, 1000)

	local textSize = self.TextBox.TextSize
	local bounds = self.TextBox.TextBounds.Y

	self.GuiObject.Size = lastPos

	local newTargetYSize = bounds - textSize
	if (self.TargetYSize ~= newTargetYSize) then
		self.TargetYSize = newTargetYSize
		self:TweenToTargetYSize()
	end

end

function methods:TweenToTargetYSize()
	local endSize = UDim2.new(1, 0, 1, self.TargetYSize)
	local curSize = self.GuiObject.Size

	local curAbsoluteSizeY = self.GuiObject.AbsoluteSize.Y
	self.GuiObject.Size = endSize
	local endAbsoluteSizeY = self.GuiObject.AbsoluteSize.Y
	self.GuiObject.Size = curSize

	local pixelDistance = math.abs(endAbsoluteSizeY - curAbsoluteSizeY)
	local tweeningTime = math.min(1, (pixelDistance * (1 / self.TweenPixelsPerSecond))) -- pixelDistance * (seconds per pixels)

	local success = pcall(function() self.GuiObject:TweenSize(endSize, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, tweeningTime, true) end)
	if (not success) then
		self.GuiObject.Size = endSize
	end
end

function methods:SetTextSize(textSize)
	if not self:IsInCustomState() then
		if rawget(self, "TextBox") then
			self.TextBox.TextSize = textSize
		end
		if rawget(self, "TextLabel") then
			self.TextLabel.TextSize = textSize
		end
	end
end

function methods:SetChannelTarget(targetChannel)
	local messageModeTextLabel = self.GuiObjects.MessageModeTextLabel
	local textBox = self.TextBox

	rawset(self, "TargetChannel", targetChannel)

	if not self:IsInCustomState() then
		if (targetChannel ~= ChatSettings.GeneralChannelName) then
			messageModeTextLabel.Size = UDim2.new(0, 1000, 1, 0)
			messageModeTextLabel.Text = string.format("[%s] ", targetChannel)

			local xSize = messageModeTextLabel.TextBounds.X
			messageModeTextLabel.Size = UDim2.new(0, xSize, 1, 0)
			textBox.Size = UDim2.new(1, -xSize, 1, 0)
			textBox.Position = UDim2.new(0, xSize, 0, 0)

		else
			messageModeTextLabel.Text = ""
			textBox.Size = UDim2.new(1, 0, 1, 0)
			textBox.Position = UDim2.new(0, 0, 0, 0)

		end
	end
end

function methods:IsInCustomState()
	return self.InCustomState
end

function methods:ResetCustomState()
	if self.InCustomState then
		self.CustomState:Destroy()
		self.CustomState = nil
		self.InCustomState = false

		self.ChatBarParentFrame:ClearAllChildren()
		self:CreateGuiObjects(self.ChatBarParentFrame)
		self:SetTextLabelText('To chat click here or press "/" key')
	end
end

function methods:GetCustomMessage()
	if self.InCustomState then
		return self.CustomState:GetMessage()
	end
	return nil
end

function methods:CustomStateProcessCompletedMessage(message)
	if self.InCustomState then
		return self.CustomState:ProcessCompletedMessage()
	end
	return false
end

-- Temporary hack until ScreenGui.DisplayOrder is released.
function methods:GetFocusedState()
	local focusedState = {
		Focused = self.TextBox:IsFocused(),
		Text = self.TextBox.Text
	}
	rawset(self, "LastFocusedState", focusedState)
	return focusedState
end

function methods:RestoreFocusedState(focusedState)
	self.TextBox.Text = focusedState.Text
	if focusedState.Focused then
		self.TextBox:CaptureFocus()
	end
end

function methods:FadeOutBackground(duration)
	self.AnimParams.Background_TargetTransparency = 1
	self.AnimParams.Background_NormalizedExptValue = CurveUtil:NormalizedDefaultExptValueInSeconds(duration)
	self:FadeOutText(duration)
end

function methods:FadeInBackground(duration)
	self.AnimParams.Background_TargetTransparency = 0.6
	self.AnimParams.Background_NormalizedExptValue = CurveUtil:NormalizedDefaultExptValueInSeconds(duration)
	self:FadeInText(duration)
end

function methods:FadeOutText(duration)
	self.AnimParams.Text_TargetTransparency = 1
	self.AnimParams.Text_NormalizedExptValue = CurveUtil:NormalizedDefaultExptValueInSeconds(duration)
end

function methods:FadeInText(duration)
	self.AnimParams.Text_TargetTransparency = 0.4
	self.AnimParams.Text_NormalizedExptValue = CurveUtil:NormalizedDefaultExptValueInSeconds(duration)
end

function methods:AnimGuiObjects()
	self.GuiObject.BackgroundTransparency = self.AnimParams.Background_CurrentTransparency
	self.GuiObjects.TextBoxFrame.BackgroundTransparency = self.AnimParams.Background_CurrentTransparency

	self.GuiObjects.TextLabel.TextTransparency = self.AnimParams.Text_CurrentTransparency
	self.GuiObjects.TextBox.TextTransparency = self.AnimParams.Text_CurrentTransparency
	self.GuiObjects.MessageModeTextLabel.TextTransparency = self.AnimParams.Text_CurrentTransparency
end

function methods:InitializeAnimParams()
	self.AnimParams.Text_TargetTransparency = 0.4
	self.AnimParams.Text_CurrentTransparency = 0.4
	self.AnimParams.Text_NormalizedExptValue = 1

	self.AnimParams.Background_TargetTransparency = 0.6
	self.AnimParams.Background_CurrentTransparency = 0.6
	self.AnimParams.Background_NormalizedExptValue = 1
end

function methods:Update(dtScale)
	self.AnimParams.Text_CurrentTransparency = CurveUtil:Expt(
			self.AnimParams.Text_CurrentTransparency,
			self.AnimParams.Text_TargetTransparency,
			self.AnimParams.Text_NormalizedExptValue,
			dtScale
	)
	self.AnimParams.Background_CurrentTransparency = CurveUtil:Expt(
			self.AnimParams.Background_CurrentTransparency,
			self.AnimParams.Background_TargetTransparency,
			self.AnimParams.Background_NormalizedExptValue,
			dtScale
	)

	self:AnimGuiObjects()
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("ChatBar", methods)

function module.new(CommandProcessor, ChatWindow)
	local obj = {}

	obj.GuiObject = nil
	obj.ChatBarParentFrame = nil
	obj.TextBox = nil
	obj.TextLabel = nil
	obj.GuiObjects = {}
	obj.eGuiObjectsChanged = Instance.new("BindableEvent")
	obj.GuiObjectsChanged = obj.eGuiObjectsChanged.Event

	obj.Connections = {}
	obj.InCustomState = false
	obj.CustomState = nil

	obj.TargetChannel = nil
	obj.CommandProcessor = CommandProcessor
	obj.ChatWindow = ChatWindow

	obj.TweenPixelsPerSecond = 500
	obj.TargetYSize = 0

	obj.AnimParams = {}
	obj.LastFocusedState = nil

	ClassMaker.MakeClass("ChatBar", obj)

	obj:InitializeAnimParams()

	ChatSettings.SettingsChanged:connect(function(setting, value)
		if (setting == "ChatBarTextSize") then
			obj:SetTextSize(value)
		end
	end)


	return obj
end

return module
