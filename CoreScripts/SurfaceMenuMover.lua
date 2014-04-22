-- this script is responsible for moving the surface menu in and out when selected/deselected

local button = script.Parent
local activated = false

function waitForChild(instance, name)
	while not instance:FindFirstChild(name) do
		instance.ChildAdded:wait()
	end
end

waitForChild(script.Parent,"SurfaceMenu")
local menu = script.Parent:FindFirstChild("SurfaceMenu")

local speed = 0.35
local moving = false

button.Changed:connect(function(property)

	if property ~= "Selected" then return end
	if moving then return end
	moving = true
	activated = button.Selected
	if activated then
		while menu.Position.X.Scale < 2.6 do
			menu.Position = UDim2.new(menu.Position.X.Scale + speed,menu.Position.X.Offset,menu.Position.Y.Scale,menu.Position.Y.Offset)
			wait()
		end
	else
		while menu.Position.X.Scale > -2.6 do
			menu.Position = UDim2.new(menu.Position.X.Scale - speed,menu.Position.X.Offset,menu.Position.Y.Scale,menu.Position.Y.Offset)
			wait()
		end
	end

moving = false end)