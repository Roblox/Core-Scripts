--[[
		// Filename: VehicleHud.lua
		// Version 1.0
		// Written by: jmargh
		// Description: Implementation of the VehicleSeat HUD

		// TODO:
			Once this is live and stable, move to PlayerScripts as module
]]
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
while not Players.LocalPlayer do
	wait()
end
local LocalPlayer = Players.LocalPlayer
local RobloxGui = script.Parent
local CurrentVehicleSeat = nil
local VehicleSeatRenderCn = nil
local VehicleSeatHUDChangedCn = nil

--[[ Images ]]--
local VEHICLE_HUD_BG = 'rbxasset://textures/ui/Vehicle/SpeedBarBKG.png'
local SPEED_BAR_EMPTY = 'rbxasset://textures/ui/Vehicle/SpeedBarEmpty.png'
local SPEED_BAR = 'rbxasset://textures/ui/Vehicle/SpeedBar.png'

--[[ Constants ]]--
local BOTTOM_OFFSET = 84
local MAX_SIZE = 142

--[[ Gui Creation ]]--
local function createImageLabel(name, size, position, image, parent)
	local imageLabel = Instance.new('ImageLabel')
	imageLabel.Name = name
	imageLabel.Size = size
	imageLabel.Position = position
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = image
	imageLabel.Parent = parent

	return imageLabel
end

local function createTextLabel(name, alignment, text, parent)
	local textLabel = Instance.new('TextLabel')
	textLabel.Name = name
	textLabel.Size = UDim2.new(1, -4, 0, 20)
	textLabel.Position = UDim2.new(0, 2, 0, -20)
	textLabel.BackgroundTransparency = 1
	textLabel.TextXAlignment = alignment
	textLabel.Font = Enum.Font.SourceSans
	textLabel.FontSize = Enum.FontSize.Size18
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.5
	textLabel.TextStrokeColor3 = Color3.new(49/255, 49/255, 49/255)
	textLabel.Text = text
	textLabel.Parent = parent

	return textLabel
end

local VehicleHudFrame = Instance.new('Frame')
VehicleHudFrame.Name = "VehicleHudFrame"
VehicleHudFrame.Size = UDim2.new(0, 158, 0, 14)
VehicleHudFrame.Position = UDim2.new(0.5, -79, 1, -BOTTOM_OFFSET)
VehicleHudFrame.BackgroundTransparency = 1
VehicleHudFrame.Visible = false
VehicleHudFrame.Parent = RobloxGui

local HudBG = createImageLabel("HudBG", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 1), VEHICLE_HUD_BG, VehicleHudFrame)
local SpeedBG = createImageLabel("SpeedBG", UDim2.new(0, 142, 0, 4), UDim2.new(0.5, -71, 0.5, -2), SPEED_BAR_EMPTY, VehicleHudFrame)
local SpeedBarImage = createImageLabel("SpeedBarImage", UDim2.new(0, 0, 0, 4), UDim2.new(0.5, -71, 0.5, -2), SPEED_BAR, VehicleHudFrame)
SpeedBarImage.ZIndex = 2

local SpeedLabel = createTextLabel("SpeedLabel", Enum.TextXAlignment.Left, "Speed", VehicleHudFrame)
local SpeedText = createTextLabel("SpeedText", Enum.TextXAlignment.Right, "0", VehicleHudFrame)

--[[ Local Functions ]]--
local function getHumanoid()
	local character = LocalPlayer and LocalPlayer.Character
	if character then
		for _,child in pairs(character:GetChildren()) do
			if child:IsA('Humanoid') then
				return child
			end
		end
	end
end

local function onRenderStepped()
	if CurrentVehicleSeat then
		local speed = CurrentVehicleSeat.Velocity.magnitude
		SpeedText.Text = tostring(math.min(math.floor(speed), 9999))
		local drawSize = math.floor((speed / CurrentVehicleSeat.MaxSpeed) * MAX_SIZE)
		drawSize = math.min(drawSize, MAX_SIZE)
		SpeedBarImage.Size = UDim2.new(0, drawSize, 0, 4)
		SpeedBarImage.ImageRectSize = Vector2.new(drawSize, 0)
	end
end

local function onVehicleSeatChanged(property)
	if property == "HeadsUpDisplay" then
		VehicleHudFrame.Visible = not VehicleHudFrame.Visible
	end
end

local function onSeated(active, currentSeatPart)
	if active then
		-- TODO: Clean up when new API is live for a while
		if currentSeatPart and currentSeatPart:IsA('VehicleSeat') then
			CurrentVehicleSeat = currentSeatPart
		else
			local camSubject = workspace.CurrentCamera.CameraSubject
			if camSubject and camSubject:IsA('VehicleSeat') then
				CurrentVehicleSeat = camSubject
			end
		end
		if CurrentVehicleSeat then
			VehicleHudFrame.Visible = CurrentVehicleSeat.HeadsUpDisplay
			VehicleSeatRenderCn = RunService.RenderStepped:connect(onRenderStepped)
			VehicleSeatHUDChangedCn = CurrentVehicleSeat.Changed:connect(onVehicleSeatChanged)
		end
	else
		if CurrentVehicleSeat then
			VehicleHudFrame.Visible = false
			CurrentVehicleSeat = nil
			if VehicleSeatRenderCn then
				VehicleSeatRenderCn:disconnect()
				VehicleSeatRenderCn = nil
			end
			if VehicleSeatHUDChangedCn then
				VehicleSeatHUDChangedCn:disconnect()
				VehicleSeatHUDChangedCn = nil
			end
		end
	end
end

local function connectSeated()
	local humanoid = getHumanoid()
	while not humanoid do
		wait()
		humanoid = getHumanoid()
	end
	humanoid.Seated:connect(onSeated)
end
connectSeated()
LocalPlayer.CharacterAdded:connect(function(character)
	connectSeated()
end)
