-- creates the in-game gui sub menus for property tools
-- written 9/27/2010 by Ben (jeditkacheff)

local gui = script.Parent
if gui:FindFirstChild("ControlFrame") then
	gui = gui:FindFirstChild("ControlFrame")
end

local currentlySelectedButton = nil

local localAssetBase = "rbxasset://textures/ui/"

local selectedButton = Instance.new("ObjectValue")
selectedButton.RobloxLocked = true
selectedButton.Name = "SelectedButton"
selectedButton.Parent = gui.BuildTools

local closeButton = Instance.new("ImageButton")
closeButton.Name = "CloseButton"
closeButton.RobloxLocked = true
closeButton.BackgroundTransparency = 1
closeButton.Image = localAssetBase .. "CloseButton.png"
closeButton.ZIndex = 2
closeButton.Size = UDim2.new(0.2,0,0.05,0)
closeButton.AutoButtonColor = false
closeButton.Position = UDim2.new(0.75,0,0.01,0)



function setUpCloseButtonState(button)

	button.MouseEnter:connect(function()
		button.Image = localAssetBase .. "CloseButton_dn.png"
	end)
	button.MouseLeave:connect(function()
		button.Image = localAssetBase .. "CloseButton.png"
	end)
	button.MouseButton1Click:connect(function()
		button.ClosedState.Value = true
		button.Image = localAssetBase .. "CloseButton.png"
	end)

end

-- nice selection animation
function fadeInButton(button)

	if currentlySelectedButton ~= nil then
		currentlySelectedButton.Selected = false
		currentlySelectedButton.ZIndex = 2
		currentlySelectedButton.Frame.BackgroundTransparency = 1
	end

	local speed = 0.1
	button.ZIndex = 3
	while button.Frame.BackgroundTransparency > 0 do
		button.Frame.BackgroundTransparency = button.Frame.BackgroundTransparency - speed
		wait()
	end
	button.Selected = true

	currentlySelectedButton = button
	selectedButton.Value = currentlySelectedButton
end

------------------------------- create the color selection sub menu -----------------------------------

local paintMenu = Instance.new("ImageLabel")
local paintTool = gui.BuildTools.Frame.PropertyTools.PaintTool
paintMenu.Name = "PaintMenu"
paintMenu.RobloxLocked = true
paintMenu.Parent = paintTool
paintMenu.Position = UDim2.new(-2.7,0,-3,0)
paintMenu.Size = UDim2.new(2.5,0,10,0)
paintMenu.BackgroundTransparency = 1
paintMenu.ZIndex = 2
paintMenu.Image = localAssetBase .. "PaintMenu.png"

local paintColorButton = Instance.new("ImageButton")
paintColorButton.RobloxLocked = true
paintColorButton.BorderSizePixel = 0
paintColorButton.ZIndex = 2
paintColorButton.Size = UDim2.new(0.200000003, 0,0.0500000007, 0)

local selection = Instance.new("Frame")
selection.RobloxLocked = true
selection.BorderSizePixel = 0
selection.BackgroundColor3 = Color3.new(1,1,1)
selection.BackgroundTransparency = 1
selection.ZIndex = 2
selection.Size = UDim2.new(1.1,0,1.1,0)
selection.Position = UDim2.new(-0.05,0,-0.05,0)
selection.Parent = paintColorButton

local header =  0.08
local spacing = 18

local count = 1

function findNextColor()
	colorName = tostring(BrickColor.new(count))
	while colorName == "Medium stone grey" do
		count = count + 1
		colorName = tostring(BrickColor.new(count))
	end
	return count
end

for i = 0,15 do
	for j = 1, 4 do
		newButton = paintColorButton:clone()
		newButton.RobloxLocked = true
		newButton.BackgroundColor3 = BrickColor.new(findNextColor()).Color
		newButton.Name = tostring(BrickColor.new(count))
		count = count + 1
		if j == 1 then newButton.Position = UDim2.new(0.08,0,i/spacing + header,0)
		elseif j == 2 then newButton.Position = UDim2.new(0.29,0,i/spacing + header,0)
		elseif j == 3 then newButton.Position = UDim2.new(0.5,0,i/spacing + header,0)
		elseif j == 4 then newButton.Position = UDim2.new(0.71,0,i/spacing + header,0) end
		newButton.Parent = paintMenu
	end
end

local paintButtons = paintMenu:GetChildren()
for i = 1, #paintButtons do
	paintButtons[i].MouseButton1Click:connect(function()
		fadeInButton(paintButtons[i])
	end)
end

local paintCloseButton = closeButton:clone()
paintCloseButton.RobloxLocked = true
paintCloseButton.Parent = paintMenu

local closedState = Instance.new("BoolValue")
closedState.RobloxLocked = true
closedState.Name = "ClosedState"
closedState.Parent = paintCloseButton

setUpCloseButtonState(paintCloseButton)

------------------------------- create the material selection sub menu -----------------------------------

local materialMenu = Instance.new("ImageLabel")
local materialTool = gui.BuildTools.Frame.PropertyTools.MaterialSelector
materialMenu.RobloxLocked = true
materialMenu.Name = "MaterialMenu"
materialMenu.Position = UDim2.new(-4,0,-3,0)
materialMenu.Size = UDim2.new(2.5,0,6.5,0)
materialMenu.BackgroundTransparency = 1
materialMenu.ZIndex = 2
materialMenu.Image = localAssetBase .. "MaterialMenu.png"
materialMenu.Parent = materialTool

local textures = {"Plastic","Wood","Slate","CorrodedMetal","Ice","Grass","Foil","DiamondPlate","Concrete"}

local materialButtons = {}

local materialButton = Instance.new("ImageButton")
materialButton.RobloxLocked = true
materialButton.BackgroundTransparency = 1
materialButton.Size = UDim2.new(0.400000003, 0,0.16, 0)
materialButton.ZIndex = 2

selection.Parent = materialButton

local current = 1
function getTextureAndName(button)

	if current > #textures then
		button:remove()
		return false
	end
	button.Image = localAssetBase .. textures[current] .. ".png"
	button.Name = textures[current]
	current = current + 1
	return true

end

local ySpacing = 0.10
local xSpacing  = 0.07
for i = 1,5 do
	for j = 1,2 do
		local button = materialButton:clone()
		button.RobloxLocked = true
		button.Position = UDim2.new((j -1)/2.2 + xSpacing,0,ySpacing + (i - 1)/5.5,0)
		if getTextureAndName(button) then button.Parent = materialMenu else button:remove() end
		table.insert(materialButtons,button)
	end
end


for i = 1, #materialButtons do
	materialButtons[i].MouseButton1Click:connect(function()
		fadeInButton(materialButtons[i])
	end)
end

local materialCloseButton = closeButton:clone()
materialCloseButton.RobloxLocked = true
materialCloseButton.Size = UDim2.new(0.2,0,0.08,0)
materialCloseButton.Parent = materialMenu

local closedState = Instance.new("BoolValue")
closedState.RobloxLocked = true
closedState.Name = "ClosedState"
closedState.Parent = materialCloseButton

setUpCloseButtonState(materialCloseButton)


------------------------------- create the surface selection sub menu -----------------------------------

local surfaceMenu = Instance.new("ImageLabel")
local surfaceTool = gui.BuildTools.Frame.PropertyTools.InputSelector
surfaceMenu.RobloxLocked = true
surfaceMenu.Name = "SurfaceMenu"
surfaceMenu.Position = UDim2.new(-2.6,0,-4,0)
surfaceMenu.Size = UDim2.new(2.5,0,5.5,0)
surfaceMenu.BackgroundTransparency = 1
surfaceMenu.ZIndex = 2
surfaceMenu.Image = localAssetBase .. "SurfaceMenu.png"
surfaceMenu.Parent = surfaceTool

textures = {"Smooth", "Studs", "Inlets", "Universal", "Glue", "Weld", "Hinge", "Motor"}
current = 1

local surfaceButtons = {}

local surfaceButton = Instance.new("ImageButton")
surfaceButton.RobloxLocked = true
surfaceButton.BackgroundTransparency = 1
surfaceButton.Size = UDim2.new(0.400000003, 0,0.19, 0)
surfaceButton.ZIndex = 2

selection.Parent = surfaceButton

local ySpacing = 0.14
local xSpacing  = 0.07
for i = 1,4 do
	for j = 1,2 do
		local button = surfaceButton:clone()
		button.RobloxLocked = true
		button.Position = UDim2.new((j -1)/2.2 + xSpacing,0,ySpacing + (i - 1)/4.6,0)
		getTextureAndName(button)
		button.Parent = surfaceMenu
		table.insert(surfaceButtons,button)
	end
end

for i = 1, #surfaceButtons do
	surfaceButtons[i].MouseButton1Click:connect(function()
		fadeInButton(surfaceButtons[i])
	end)
end

local surfaceMenuCloseButton = closeButton:clone()
surfaceMenuCloseButton.RobloxLocked = true
surfaceMenuCloseButton.Size = UDim2.new(0.2,0,0.09,0)
surfaceMenuCloseButton.Parent = surfaceMenu

local closedState = Instance.new("BoolValue")
closedState.RobloxLocked = true
closedState.Name = "ClosedState"
closedState.Parent = surfaceMenuCloseButton

setUpCloseButtonState(surfaceMenuCloseButton)

if game.CoreGui.Version >= 2 then
	local function setupTweenTransition(button, menu, outXScale, inXScale)
		button.Changed:connect(
		function(property)
			if property ~= "Selected" then 
				return 
			end
			if button.Selected then
				menu:TweenPosition(UDim2.new(inXScale, menu.Position.X.Offset, menu.Position.Y.Scale, menu.Position.Y.Offset),
					Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 1, true)
			else
				menu:TweenPosition(UDim2.new(outXScale, menu.Position.X.Offset, menu.Position.Y.Scale, menu.Position.Y.Offset),
					Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.5, true)
			end
		end)
	end
	
	setupTweenTransition(paintTool, paintMenu, -2.7, 2.6)
	setupTweenTransition(surfaceTool, surfaceMenu, -2.6, 2.6)
	setupTweenTransition(materialTool, materialMenu, -4, 1.4)
end
