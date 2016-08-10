local source = [[
local module = {}
--////////////////////////////// Include
--//////////////////////////////////////
local modulesFolder = script.Parent
local moduleTransparencyTweener = require(modulesFolder:WaitForChild("TransparencyTweener"))

--////////////////////////////// Details
--//////////////////////////////////////
local metatable = {}
metatable.__ClassName = "ChatBar"

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
	local backgroundImagePixelOffset = 8
	local textBoxPixelOffset = 8

	local BaseFrame = Instance.new("Frame")
	BaseFrame.Size = UDim2.new(1, 0, 1, 0)
	BaseFrame.BackgroundTransparency = 0.6
	BaseFrame.BorderSizePixel = 0
	BaseFrame.BackgroundColor3 = Color3.new(0, 0, 0)

	local BoxFrame = Instance.new("Frame", BaseFrame)
	BoxFrame.Name = "BoxFrame"
	BoxFrame.BackgroundTransparency = 0.6
	BoxFrame.BorderSizePixel = 0
	BoxFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	BoxFrame.Size = UDim2.new(1, -backgroundImagePixelOffset * 2, 1, -backgroundImagePixelOffset * 2)
	BoxFrame.Position = UDim2.new(0, backgroundImagePixelOffset, 0, backgroundImagePixelOffset)

	local TextBox = Instance.new("TextBox", BoxFrame)
	TextBox.Name = "ChatBar"
	TextBox.BackgroundTransparency = 1
	TextBox.Size = UDim2.new(1, -textBoxPixelOffset * 2, 1, -textBoxPixelOffset * 2)
	TextBox.Position = UDim2.new(0, textBoxPixelOffset, 0, textBoxPixelOffset)
	TextBox.FontSize = Enum.FontSize.Size18
	TextBox.Font = Enum.Font.SourceSansBold
	TextBox.TextColor3 = Color3.new(1, 1, 1)
	TextBox.TextStrokeTransparency = 0.75
	TextBox.ClearTextOnFocus = false
	TextBox.TextXAlignment = Enum.TextXAlignment.Left
	TextBox.TextYAlignment = Enum.TextYAlignment.Top
	TextBox.TextWrapped = true
	TextBox.Text = ""

	local TextLabel = Instance.new("TextLabel", BoxFrame)
	TextLabel.BackgroundTransparency = 1
	TextLabel.Size = TextBox.Size
	TextLabel.Position = TextBox.Position
	TextLabel.FontSize = TextBox.FontSize
	TextLabel.Font = TextBox.Font
	TextLabel.TextColor3 = TextBox.TextColor3
	TextLabel.TextStrokeTransparency = TextBox.TextStrokeTransparency
	TextLabel.TextXAlignment = TextBox.TextXAlignment
	TextLabel.TextYAlignment = TextBox.TextYAlignment
	TextLabel.Text = "This value was un-initialized lololololololololol"

	TextLabel.TextColor3 = Color3.new(0, 0, 0)
	TextLabel.TextStrokeTransparency = 1
	TextLabel.TextTransparency = 0.4

	TextBox.Focused:connect(function() TextLabel.Visible = false end)
	TextBox.FocusLost:connect(function() TextLabel.Visible = (TextBox.Text == "") end)

	return BaseFrame, BoxFrame, TextBox, TextLabel
end

function metatable:Dump()
	return tostring(self)
end

function metatable:GetTextBox()
	return self.TextBox
end

function metatable:IsFocused()
	return self:GetTextBox():IsFocused()
end

function metatable:GetVisible()
	return self.GuiObject.Visible
end

function metatable:CaptureFocus()
	self:GetTextBox():CaptureFocus()
end

function metatable:ReleaseFocus(didRelease)
	self:GetTextBox():ReleaseFocus(didRelease)
end

function metatable:ResetText()
	self:GetTextBox().Text = ""
end

function metatable:GetEnabled()
	return self.GuiObject.Visible
end

function metatable:SetEnabled(enabled)
	self.GuiObject.Visible = false
end

function metatable:SetTextLabelText(text)
	self.TextLabel.Text = text
end

function metatable:ResetSize()
	self.TargetYSize = 0
	self:TweenToTargetYSize()
end

function metatable:CalculateSize()
	local lastPos = self.GuiObject.Size
	self.GuiObject.Size = UDim2.new(1, 0, 0, 1000)

	local fontSize = tonumber(self.TextBox.FontSize.Name:match("%d+"))
	local bounds = self.TextBox.TextBounds.Y

	self.GuiObject.Size = lastPos

	local newTargetYSize = bounds - fontSize --+ 4
	if (self.TargetYSize ~= newTargetYSize) then
		self.TargetYSize = newTargetYSize
		self:TweenToTargetYSize()
	end

end

function metatable:TweenToTargetYSize()
	local endSize = UDim2.new(1, 0, 1, self.TargetYSize)
	local curSize = self.GuiObject.Size

	local curAbsoluteSizeY = self.GuiObject.AbsoluteSize.Y
	self.GuiObject.Size = endSize
	local endAbsoluteSizeY = self.GuiObject.AbsoluteSize.Y
	self.GuiObject.Size = curSize

	local pixelDistance = math.abs(endAbsoluteSizeY - curAbsoluteSizeY)
	local tweeningTime = math.min(1, (pixelDistance * (1 / self.TweenPixelsPerSecond))) -- pixelDistance * (seconds per pixels)

	self.GuiObject:TweenSize(endSize, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, tweeningTime, true)
end

function metatable:FadeOutBackground(duration)
	self.BackgroundTweener:Tween(duration, 1)
	--self:FadeOutText(duration)
end

function metatable:FadeInBackground(duration)
	self.BackgroundTweener:Tween(duration, 0)
	--self:FadeInText(duration)
end

function metatable:FadeOutText(duration)
	self.TextTweener:Tween(duration, 1)
end

function metatable:FadeInText(duration)
	self.TextTweener:Tween(duration, 0)
end

function metatable:CreateTweeners()
	self.BackgroundTweener:CancelTween()
	self.TextTweener:CancelTween()

	self.BackgroundTweener = moduleTransparencyTweener.new()
	self.TextTweener = moduleTransparencyTweener.new()

	--// Register BackgroundTweener objects and properties
	self.BackgroundTweener:RegisterTweenObjectProperty(self.GuiObject, "BackgroundTransparency")
	self.BackgroundTweener:RegisterTweenObjectProperty(self.TextBoxFrame, "BackgroundTransparency")

	--// Register TextTweener objects and properties
	local registerAsText = false
	if (registerAsText) then
		self.TextTweener:RegisterTweenObjectProperty(self.TextLabel, "TextTransparency")
		self.TextTweener:RegisterTweenObjectProperty(self.TextLabel, "TextStrokeTransparency")
		self.TextTweener:RegisterTweenObjectProperty(self.TextBox, "TextTransparency")
		self.TextTweener:RegisterTweenObjectProperty(self.TextBox, "TextStrokeTransparency")
	else
		self.BackgroundTweener:RegisterTweenObjectProperty(self.TextLabel, "TextTransparency")
		self.BackgroundTweener:RegisterTweenObjectProperty(self.TextLabel, "TextStrokeTransparency")
		self.BackgroundTweener:RegisterTweenObjectProperty(self.TextBox, "TextTransparency")
		self.BackgroundTweener:RegisterTweenObjectProperty(self.TextBox, "TextStrokeTransparency")
	end

end

--///////////////////////// Constructors
--//////////////////////////////////////
function module.new()
	local obj = {}
	obj.MemoryLocation = tostring(obj):match("[0123456789ABCDEF]+")

	local BaseFrame, TextBoxFrame, TextBox, TextLabel = CreateGuiObject()
	obj.GuiObject = BaseFrame
	obj.TextBoxFrame = TextBoxFrame
	obj.TextBox = TextBox
	obj.TextLabel = TextLabel

	obj.TweenPixelsPerSecond = 300 + 200
	obj.TargetYSize = 0

	obj.BackgroundTweener = moduleTransparencyTweener.new()
	obj.TextTweener = moduleTransparencyTweener.new()

	obj = setmetatable(obj, metatable)

	obj:SetTextLabelText("To chat click here or press \"/\" key")

	obj:CreateTweeners()

	local changedLock = false
	obj.TextBox.Changed:connect(function(prop)
		if (prop == "Text") then
			if (changedLock) then return end
			changedLock = true

			obj:CalculateSize()

			changedLock = false
		end
	end)

	obj.TextBox.Focused:connect(function()
		obj:CalculateSize()
	end)

	obj.TextBox.FocusLost:connect(function(enterPressed, inputObject)
		obj:ResetSize()
		if (inputObject.KeyCode == Enum.KeyCode.Escape) then
			obj.TextBox.Text = ""
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