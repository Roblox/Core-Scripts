local controlFrame = script.Parent:FindFirstChild("ControlFrame")

if not controlFrame then return end

local topLeftControl = controlFrame:FindFirstChild("TopLeftControl")
local bottomLeftControl = controlFrame:FindFirstChild("BottomLeftControl")
local bottomRightControl = controlFrame:FindFirstChild("BottomRightControl")


local frameTip = Instance.new("TextLabel")
frameTip.Name = "ToolTip"
frameTip.Text = ""
frameTip.Font = Enum.Font.ArialBold
frameTip.FontSize = Enum.FontSize.Size12
frameTip.TextColor3 = Color3.new(1,1,1)
frameTip.BorderSizePixel = 0
frameTip.ZIndex = 10
frameTip.Size = UDim2.new(2,0,1,0)
frameTip.Position = UDim2.new(1,0,0,0)
frameTip.BackgroundColor3 = Color3.new(0,0,0)
frameTip.BackgroundTransparency = 1
frameTip.TextTransparency = 1
frameTip.TextWrap = true

local inside = Instance.new("BoolValue")
inside.Name = "inside"
inside.Value = false
inside.Parent = frameTip

function setUpListeners(frameToListen)
	local fadeSpeed = 0.1
	frameToListen.Parent.MouseEnter:connect(function()
		if frameToListen:FindFirstChild("inside") then
			frameToListen.inside.Value = true
			wait(1.2)
			if frameToListen.inside.Value then
				while frameToListen.inside.Value and frameToListen.BackgroundTransparency > 0 do
					frameToListen.BackgroundTransparency = frameToListen.BackgroundTransparency - fadeSpeed
					frameToListen.TextTransparency = frameToListen.TextTransparency - fadeSpeed
					wait()
				end
			end
		end
	end)
	function killTip(killFrame)
		killFrame.inside.Value = false
		killFrame.BackgroundTransparency = 1
		killFrame.TextTransparency = 1
	end
	frameToListen.Parent.MouseLeave:connect(function() killTip(frameToListen) end)
	frameToListen.Parent.MouseButton1Click:connect(function()  killTip(frameToListen) end)
end

function createSettingsButtonTip(parent)
	if parent == nil then
		parent = bottomLeftControl:FindFirstChild("SettingsButton")
	end
	
	local toolTip = frameTip:clone()
    toolTip.RobloxLocked = true
    toolTip.Text = "Settings/Leave Game"
    toolTip.Position = UDim2.new(0,0,0,-18)
    toolTip.Size = UDim2.new(0,120,0,20)
    toolTip.Parent = parent
    setUpListeners(toolTip)
end

wait(5) -- make sure we are loaded in, won't need tool tips for first 5 seconds anyway

---------------- set up Bottom Left Tool Tips -------------------------

local bottomLeftChildren = bottomLeftControl:GetChildren()
local hasSettingsTip = false

for i = 1, #bottomLeftChildren do

	if bottomLeftChildren[i].Name == "Exit" then
	    local exitTip = frameTip:clone()
	    exitTip.RobloxLocked = true
	    exitTip.Text = "Leave Place"
	    exitTip.Position = UDim2.new(0,0,-1,0)
	    exitTip.Size = UDim2.new(1,0,1,0)
	    exitTip.Parent = bottomLeftChildren[i]
	    setUpListeners(exitTip)
	elseif bottomLeftChildren[i].Name == "SettingsButton" then
		hasSettingsTip = true
		createSettingsButtonTip(bottomLeftChildren[i])
	end
end

---------------- set up Bottom Right Tool Tips -------------------------

local bottomRightChildren = bottomRightControl:GetChildren()

for i = 1, #bottomRightChildren do
	if bottomRightChildren[i].Name:find("Camera") ~= nil then
		local cameraTip = frameTip:clone()
		cameraTip.RobloxLocked = true
		cameraTip.Text = "Camera View"
		if bottomRightChildren[i].Name:find("Zoom") then
			cameraTip.Position = UDim2.new(-1,0,-1.5)
		else
			cameraTip.Position = UDim2.new(0,0,-1.5,0)
		end
		cameraTip.Size = UDim2.new(2,0,1.25,0)
		cameraTip.Parent = bottomRightChildren[i]
		setUpListeners(cameraTip)
	end
end
