local source = [[
--	// FileName: ChatBar.lua
--	// Written by: Xsitsu
--	// Description: Manages text typing and typing state.

local module = {}
--////////////////////////////// Include
--//////////////////////////////////////
local modulesFolder = script.Parent
local moduleTransparencyTweener = require(modulesFolder:WaitForChild("TransparencyTweener"))
local ChatSettings = require(modulesFolder:WaitForChild("ChatSettings"))
local ClassMaker = require(modulesFolder:WaitForChild("ClassMaker"))

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}

function methods:CreateGuiObjects(targetParent)
	local backgroundImagePixelOffset = 8
	local textBoxPixelOffset = 8

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

	local TextBox = Instance.new("TextBox", BoxFrame)
	TextBox.Selectable = ChatSettings.GamepadNavigationEnabled
	TextBox.Name = "ChatBar"
	TextBox.BackgroundTransparency = 1
	TextBox.Size = UDim2.new(1, -textBoxPixelOffset * 2, 1, -textBoxPixelOffset * 2)
	TextBox.Position = UDim2.new(0, textBoxPixelOffset, 0, textBoxPixelOffset)
	TextBox.FontSize = ChatSettings.ChatBarTextSize
	TextBox.Font = Enum.Font.SourceSansBold
	TextBox.TextColor3 = Color3.new(1, 1, 1)
	TextBox.TextStrokeTransparency = 0.75
	TextBox.ClearTextOnFocus = false
	TextBox.TextXAlignment = Enum.TextXAlignment.Left
	TextBox.TextYAlignment = Enum.TextYAlignment.Top
	TextBox.TextWrapped = true
	TextBox.Text = ""

	local TextLabel = Instance.new("TextLabel", BoxFrame)
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

	TextBox.Focused:connect(function() TextLabel.Visible = false end)
	TextBox.FocusLost:connect(function() TextLabel.Visible = (TextBox.Text == "") end)

	rawset(self, "GuiObject", BaseFrame)
	rawset(self, "TextBox", TextBox)
	rawset(self, "TextLabel", TextLabel)

	self.GuiObjects.BaseFrame = BaseFrame
	self.GuiObjects.TextBoxFrame = BoxFrame
	self.GuiObjects.TextBox = TextBox
	self.GuiObjects.TextLabel = TextLabel

	self:CreateTweeners()

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

function methods:FadeOutBackground(duration)
	self.BackgroundTweener:Tween(duration, 1)
	--self:FadeOutText(duration)
end

function methods:FadeInBackground(duration)
	self.BackgroundTweener:Tween(duration, 0)
	--self:FadeInText(duration)
end

function methods:FadeOutText(duration)
	self.TextTweener:Tween(duration, 1)
end

function methods:FadeInText(duration)
	self.TextTweener:Tween(duration, 0)
end

function methods:CreateTweeners()
	self.BackgroundTweener:CancelTween()
	self.TextTweener:CancelTween()

	self.BackgroundTweener = moduleTransparencyTweener.new()
	self.TextTweener = moduleTransparencyTweener.new()

	--// Register BackgroundTweener objects and properties
	self.BackgroundTweener:RegisterTweenObjectProperty(self.GuiObject, "BackgroundTransparency")
	self.BackgroundTweener:RegisterTweenObjectProperty(self.GuiObjects.TextBoxFrame, "BackgroundTransparency")

	--// Register TextTweener objects and properties
	local registerAsText = false
	if (registerAsText) then
		self.TextTweener:RegisterTweenObjectProperty(self.GuiObjects.TextLabel, "TextTransparency")
		self.TextTweener:RegisterTweenObjectProperty(self.GuiObjects.TextLabel, "TextStrokeTransparency")
		self.TextTweener:RegisterTweenObjectProperty(self.GuiObjects.TextBox, "TextTransparency")
		self.TextTweener:RegisterTweenObjectProperty(self.GuiObjects.TextBox, "TextStrokeTransparency")
	else
		self.BackgroundTweener:RegisterTweenObjectProperty(self.GuiObjects.TextLabel, "TextTransparency")
		self.BackgroundTweener:RegisterTweenObjectProperty(self.GuiObjects.TextLabel, "TextStrokeTransparency")
		self.BackgroundTweener:RegisterTweenObjectProperty(self.GuiObjects.TextBox, "TextTransparency")
		self.BackgroundTweener:RegisterTweenObjectProperty(self.GuiObjects.TextBox, "TextStrokeTransparency")
	end

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

	obj.TweenPixelsPerSecond = 500
	obj.TargetYSize = 0

	obj.BackgroundTweener = moduleTransparencyTweener.new()
	obj.TextTweener = moduleTransparencyTweener.new()

	ClassMaker.MakeClass("ChatBar", obj)

	ChatSettings.SettingsChanged:connect(function(setting, value)
		if (setting == "ChatBarTextSize") then
			obj:SetFontSize(value)
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