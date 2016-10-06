--	// FileName: ChatBar.lua
--	// Written by: Xsitsu
--	// Description: Manages text typing and typing state.

local module = {}

local UserInputService = game:GetService("UserInputService")

--////////////////////////////// Include
--//////////////////////////////////////
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local clientChatModules = ReplicatedStorage:WaitForChild("ClientChatModules")
local modulesFolder = script.Parent
local ChatSettings = require(clientChatModules:WaitForChild("ChatSettings"))
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))
local CurveUtil = require(modulesFolder:WaitForChild("CurveUtil"))

local MessageSender = require(modulesFolder:WaitForChild("MessageSender"))

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}

function methods:CreateGuiObjects(targetParent)
	local backgroundImagePixelOffset = 7
	local textBoxPixelOffset = 5

	local BaseFrame = Instance.new("Frame", targetParent)
	BaseFrame.Selectable = false
	BaseFrame.Size = UDim2.new(1, 0, 1, 0)
	BaseFrame.BackgroundTransparency = 0.6
	BaseFrame.BorderSizePixel = 0
	BaseFrame.BackgroundColor3 = Color3.new(0, 0, 0)

	local BoxFrame = Instance.new("Frame", BaseFrame)
	BoxFrame.Selectable = false
	BoxFrame.Name = "BoxFrame"
	BoxFrame.BackgroundTransparency = 0.6
	BoxFrame.BorderSizePixel = 0
	BoxFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	BoxFrame.Size = UDim2.new(1, -backgroundImagePixelOffset * 2, 1, -backgroundImagePixelOffset * 2)
	BoxFrame.Position = UDim2.new(0, backgroundImagePixelOffset, 0, backgroundImagePixelOffset)

	local TextBoxHolderFrame = Instance.new("Frame", BoxFrame)
	TextBoxHolderFrame.BackgroundTransparency = 1
	TextBoxHolderFrame.Size = UDim2.new(1, -textBoxPixelOffset * 2, 1, -textBoxPixelOffset * 2)
	TextBoxHolderFrame.Position = UDim2.new(0, textBoxPixelOffset, 0, textBoxPixelOffset)

	local TextBox = Instance.new("TextBox", TextBoxHolderFrame)
	TextBox.Selectable = ChatSettings.GamepadNavigationEnabled
	TextBox.Name = "ChatBar"
	TextBox.BackgroundTransparency = 1
	TextBox.Size = UDim2.new(1, 0, 1, 0)
	TextBox.Position = UDim2.new(0, 0, 0, 0)
	TextBox.FontSize = ChatSettings.ChatBarTextSize
	TextBox.Font = Enum.Font.SourceSansBold
	TextBox.TextColor3 = Color3.new(1, 1, 1)
	--TextBox.TextStrokeTransparency = 0.75
	TextBox.ClearTextOnFocus = false
	TextBox.TextXAlignment = Enum.TextXAlignment.Left
	TextBox.TextYAlignment = Enum.TextYAlignment.Top
	TextBox.TextWrapped = true
	TextBox.Text = ""

	local MessageModeTextLabel = Instance.new("TextLabel", TextBoxHolderFrame)
	MessageModeTextLabel.Name = "MessageMode"
	MessageModeTextLabel.BackgroundTransparency = 1
	MessageModeTextLabel.Position = UDim2.new(0, 0, 0, 0)
	MessageModeTextLabel.FontSize = ChatSettings.ChatBarTextSize
	MessageModeTextLabel.Font = Enum.Font.SourceSansBold
	MessageModeTextLabel.TextXAlignment = Enum.TextXAlignment.Left
	MessageModeTextLabel.TextWrapped = true
	MessageModeTextLabel.Text = ""
	MessageModeTextLabel.Size = UDim2.new(0.3, 0, 1, 0)
	MessageModeTextLabel.TextYAlignment = Enum.TextYAlignment.Center
	MessageModeTextLabel.TextColor3 = Color3.fromRGB(77, 139, 255)

	local TextLabel = Instance.new("TextLabel", TextBoxHolderFrame)
	TextLabel.Selectable = false
	TextLabel.TextWrapped = true
	TextLabel.BackgroundTransparency = 1
	TextLabel.Size = TextBox.Size
	TextLabel.Position = TextBox.Position
	TextLabel.FontSize = TextBox.FontSize
	TextLabel.Font = TextBox.Font
	TextLabel.TextColor3 = TextBox.TextColor3
	TextLabel.TextStrokeTransparency = TextBox.TextStrokeTransparency
	TextLabel.TextXAlignment = TextBox.TextXAlignment
	TextLabel.TextYAlignment = TextBox.TextYAlignment
	TextLabel.Text = "This value needs to be set with :SetTextLabelText()"

	TextLabel.TextColor3 = Color3.new(0, 0, 0)
	TextLabel.TextStrokeTransparency = 1
	TextLabel.TextTransparency = 0.4

	TextBox.TextColor3 = TextLabel.TextColor3
	TextBox.TextStrokeTransparency = TextLabel.TextStrokeTransparency
	TextBox.TextTransparency = TextLabel.TextTransparency

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

	TextBox.Focused:connect(function() UpdateOnFocusStatusChanged(true) end)
	TextBox.FocusLost:connect(function() UpdateOnFocusStatusChanged(false) end)

	--// Code for getting back into general channel from other target channel when pressing backspace.
	UserInputService.InputBegan:connect(function(inputObj, gpe)
		if (inputObj.KeyCode == Enum.KeyCode.Backspace) then
			if (TextBox:IsFocused() and TextBox.Text == "") then
				self:SetChannelTarget(ChatSettings.GeneralChannelName)
			end
		end
	end)

	TextBox.Changed:connect(function(prop)
		if (prop == "Text")  then
			if (string.len(TextBox.Text) > ChatSettings.MaximumMessageLength) then
				TextBox.Text = string.sub(TextBox.Text, 1, ChatSettings.MaximumMessageLength)
				return
			end
		end

		if (prop == "Text" and not ChatSettings.ShowChannelsBar and TextBox.Text:match("%s$")) then
			local text = TextBox.Text
			local doProcess = true
			if (string.sub(TextBox.Text, 1, 3):lower() == "/w ") then
				text = string.sub(text, 4)

			elseif (string.sub(TextBox.Text, 1, 9):lower() == "/whisper ") then
				text = string.sub(text,  10)

			else
				doProcess = false

			end

			if (doProcess) then
				local match = nil
				if (string.sub(text, 1, 1) == "\"") then
					match = string.match(text, "\".+\"%s")
					if (match) then
						local len = string.len(match)
						match = string.sub(match, 2, len - 1)
					end
				else
					match = string.match(text, "%S+%s")
				end

				if (match) then
					local len = string.len(match)
					match = string.sub(match, 1, len - 1)
					TextBox.Text = ""

					local targ = ChatSettings.GeneralChannelName or rawget(self, "TargetChannel")
					MessageSender:SendMessage(string.format("/w %s", match), targ)
				end
			end
		end
	end)

	rawset(self, "GuiObject", BaseFrame)
	rawset(self, "TextBox", TextBox)
	rawset(self, "TextLabel", TextLabel)

	self.GuiObjects.BaseFrame = BaseFrame
	self.GuiObjects.TextBoxFrame = BoxFrame
	self.GuiObjects.TextBox = TextBox
	self.GuiObjects.TextLabel = TextLabel
	self.GuiObjects.MessageModeTextLabel = MessageModeTextLabel

	self:AnimGuiObjects()

	local changedLock = false
	self.TextBox.Changed:connect(function(prop)
		if (prop == "Text") then
			if (changedLock) then return end
			changedLock = true

			self:CalculateSize()

			changedLock = false
		end
	end)

	self.TextBox.Focused:connect(function()
		self:CalculateSize()
	end)

	self.TextBox.FocusLost:connect(function(enterPressed, inputObject)
		self:ResetSize()
		if (inputObject and inputObject.KeyCode == Enum.KeyCode.Escape) then
			self.TextBox.Text = ""
		end

	end)
end

function methods:GetTextBox()
	return self.TextBox
end

function methods:IsFocused()
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

	local fontSize = tonumber(self.TextBox.FontSize.Name:match("%d+"))
	local bounds = self.TextBox.TextBounds.Y

	self.GuiObject.Size = lastPos

	local newTargetYSize = bounds - fontSize
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

function methods:SetFontSize(fontSize)
	self.TextBox.FontSize = fontSize
	self.TextLabel.FontSize = fontSize
end

function methods:SetChannelTarget(targetChannel)
	local messageModeTextLabel = self.GuiObjects.MessageModeTextLabel
	local textBox = self.TextBox

	rawset(self, "TargetChannel", targetChannel)

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

function methods:FadeOutBackground(duration)
	self.AnimParams.Background_TargetTransparency = 1
	self:FadeOutText(duration)
end

function methods:FadeInBackground(duration)
	self.AnimParams.Background_TargetTransparency = 0.6
	self:FadeInText(duration)
end

function methods:FadeOutText(duration)
	self.AnimParams.Text_TargetTransparency = 1
end

function methods:FadeInText(duration)
	self.AnimParams.Text_TargetTransparency = 0.4
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

	self.AnimParams.Background_TargetTransparency = 0.6
	self.AnimParams.Background_CurrentTransparency = 0.6
end

function methods:Update(dtScale)
	self.AnimParams.Text_CurrentTransparency = CurveUtil:Expt(self.AnimParams.Text_CurrentTransparency, self.AnimParams.Text_TargetTransparency, 0.1, dtScale)
	self.AnimParams.Background_CurrentTransparency = CurveUtil:Expt(self.AnimParams.Background_CurrentTransparency, self.AnimParams.Background_TargetTransparency, 0.1, dtScale)

	self:AnimGuiObjects()
end

--///////////////////////// Constructors
--//////////////////////////////////////
ClassMaker.RegisterClassType("ChatBar", methods)

function module.new()
	local obj = {}

	obj.GuiObject = nil
	obj.TextBox = nil
	obj.TextLabel = nil
	obj.GuiObjects = {}

	obj.TargetChannel = nil

	obj.TweenPixelsPerSecond = 500
	obj.TargetYSize = 0

	obj.AnimParams = {}

	ClassMaker.MakeClass("ChatBar", obj)

	obj:InitializeAnimParams()

	ChatSettings.SettingsChanged:connect(function(setting, value)
		if (setting == "ChatBarTextSize") then
			obj:SetFontSize(value)
		end
	end)


	return obj
end

return module
