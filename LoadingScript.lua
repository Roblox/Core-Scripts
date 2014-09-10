-- Creates the generic "ROBLOX" loading screen on startup
-- Written by ArceusInator & Ben Tkacheff, 2014
--

-- Constants

local PLACEID = Game.PlaceId

local MPS = Game:GetService 'MarketplaceService'
local CP = Game:GetService 'ContentProvider'



local COLORS = {
	BLACK = Color3.new(0, 0, 0),
	WHITE = Color3.new(1, 1, 1),
	ERROR = Color3.new(253/255,68/255,72/255)
}

--
-- Variables
local GameAssetInfo -- loaded by InfoProvider:LoadAssets()
local currScreenGui = nil
local renderSteppedConnection = nil

--
-- Utility functions
local create = function(className, defaultParent)
	return function(propertyList)
		local object = Instance.new(className)

		for index, value in next, propertyList do
			if type(index) == 'string' then
				object[index] = value
			else
				if type(value) == 'function' then
					value(object)
				elseif type(value) == 'userdata' then
					value.Parent = object
				end
			end
		end

		if object.Parent == nil then
			object.Parent = defaultParent
		end

		return object
	end
end

--
-- Create objects

local MainGui = {}
local InfoProvider = {}


function InfoProvider:GetGameName()
	if GameAssetInfo ~= nil then
		return GameAssetInfo.Name
	else
		return ''
	end
end


function InfoProvider:GetCreatorName()
	if GameAssetInfo ~= nil then
		return GameAssetInfo.Creator.Name
	else
		return ''
	end
end


function InfoProvider:LoadAssets()
	Spawn(function() 
		if PLACEID <= 0 then
			while Game.PlaceId <= 0 do
				wait()
			end
			PLACEID = Game.PlaceId
		end

		-- load game asset info
		coroutine.resume(coroutine.create(function() GameAssetInfo = MPS:GetProductInfo(PLACEID) end))
	end)
end

--
-- Declare member functions
function MainGui:GenerateMain()
	local screenGui = create 'ScreenGui' {
		Name = 'RobloxLoadingGui'
	}


	--
	-- create descendant frames
	local mainBackgroundContainer = create 'Frame' {
		Name = 'BlackFrame',
		BackgroundColor3 = COLORS.BLACK,
		Size = UDim2.new(1, 0, 1, 0),
		Active = true,

		create 'ImageButton' {
			Name = 'CloseButton',
			Image = 'rbxasset://textures/ui/CloseButton.png',
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -27, 0, 5),
			Size = UDim2.new(0, 22, 0, 22),
			Active = true,
			ZIndex = 10
		},

		create 'Frame' {
			Name = 'ErrorFrame',
			BackgroundColor3 = COLORS.ERROR,
			BorderSizePixel = 0,
			Position = UDim2.new(0.25,0,0,0),
			Size = UDim2.new(0.5, 0, 0, 80),
			ZIndex = 8,
			Visible = false,

			create 'TextLabel' {
				Name = "ErrorText",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Font = Enum.Font.SourceSansBold,
				FontSize = Enum.FontSize.Size14,
				TextWrapped = true,
				TextColor3 = COLORS.WHITE,
				Text = "",
				ZIndex = 8
			}
		},

		create 'Frame' {
			Name = 'BottomFrame',
			BackgroundColor3 = COLORS.BLACK,
			BorderSizePixel = 0,
			Position = UDim2.new(0,0,1,-120),
			Size = UDim2.new(1,0,0,120),
			ZIndex = 1
		},

		create 'Frame' {
			Name = 'PlaceFrame',
			BackgroundTransparency = 1,
			Position = UDim2.new(0.35, 0, 1, -100),
			Size = UDim2.new(0.3, 0, 0, 80),
			ZIndex = 2,

			create 'TextLabel' {
				Name = 'PlaceLabel',
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0.5, -2),
				Font = Enum.Font.SourceSansBold,
				FontSize = Enum.FontSize.Size14,
				TextWrapped = true,
				TextScaled = true,
				TextColor3 = COLORS.WHITE,
				TextStrokeTransparency = 0,
				Text = "",
				ZIndex = 2
			},

			create 'TextLabel' {
				Name = 'CreatorLabel',
				BackgroundTransparency = 1,
				Position = UDim2.new(0,0,0.5,2),
				Size = UDim2.new(1, 0, 0.5, -2),
				Font = Enum.Font.SourceSans,
				FontSize = Enum.FontSize.Size12,
				TextWrapped = true,
				TextScaled = true,
				TextColor3 = COLORS.WHITE,
				TextStrokeTransparency = 0,
				Text = "",
				ZIndex = 2
			},
		},

		create 'Frame' {
			Name = 'GraphicsFrame',
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -125, 1, -125),
			Size = UDim2.new(0, 120, 0, 120),
			ZIndex = 2,

			create 'ImageLabel' {
				Name = 'LoadingImage',
				BackgroundTransparency = 1,
				Image = 'rbxasset://textures/Roblox-loading-glow.png',
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 1, 0),
				ZIndex = 2
			},

			create 'ImageLabel' {
				Name = 'LogoImage',
				BackgroundTransparency = 1,
				Image = 'rbxasset://textures/Roblox-loading.png',
				Position = UDim2.new(0.125, 0, 0.125, 0),
				Size = UDim2.new(0.75, 0, 0.75, 0),
				ZIndex = 2
			}
		},
		
		create 'Frame' {
			Name = 'CountFrame',
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 1, -90),
			Size = UDim2.new(0.3, 0, 0, 90),
			ZIndex = 2,

			create 'TextLabel' {
				Name = 'BrickLabel',
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 5, 0, 20),
				Size = UDim2.new(0.5, -5, 0, 18),
				Font = Enum.Font.SourceSansBold,
				FontSize = Enum.FontSize.Size18,
				TextScaled = true,
				TextColor3 = COLORS.WHITE,
				TextStrokeTransparency = 0,
				Text = "Bricks:",
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 2
			},

			create 'TextLabel' {
				Name = 'ConnectorLabel',
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 5, 0, 40),
				Size = UDim2.new(0.5, -5, 0, 18),
				Font = Enum.Font.SourceSansBold,
				FontSize = Enum.FontSize.Size18,
				TextScaled = true,
				TextColor3 = COLORS.WHITE,
				TextStrokeTransparency = 0,
				Text = "Connectors:",
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 2
			},

			create 'TextLabel' {
				Name = 'InstanceLabel',
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 5, 0, 0),
				Size = UDim2.new(0.5, -5, 0, 18),
				Font = Enum.Font.SourceSansBold,
				FontSize = Enum.FontSize.Size18,
				TextScaled = true,
				TextColor3 = COLORS.WHITE,
				TextStrokeTransparency = 0,
				Text = "Instances:",
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 2
			},

			create 'TextLabel' {
				Name = 'VoxelLabel',
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 5, 0, 60),
				Size = UDim2.new(0.5, -5, 0, 18),
				Font = Enum.Font.SourceSansBold,
				FontSize = Enum.FontSize.Size18,
				TextScaled = true,
				TextColor3 = COLORS.WHITE,
				TextStrokeTransparency = 0,
				Text = "Voxels:",
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 2
			},

			create 'TextLabel' {
				Name = 'BrickCount',
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, 5, 0, 20),
				Size = UDim2.new(0.5, -5, 0, 18),
				Font = Enum.Font.SourceSans,
				FontSize = Enum.FontSize.Size18,
				TextScaled = true,
				TextColor3 = COLORS.WHITE,
				TextStrokeTransparency = 0,
				Text = "",
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 2
			},

			create 'TextLabel' {
				Name = 'ConnectorCount',
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, 5, 0, 40),
				Size = UDim2.new(0.5, -5, 0, 18),
				Font = Enum.Font.SourceSans,
				FontSize = Enum.FontSize.Size18,
				TextScaled = true,
				TextColor3 = COLORS.WHITE,
				TextStrokeTransparency = 0,
				Text = "",
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 2
			},

			create 'TextLabel' {
				Name = 'InstanceCount',
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, 5, 0, 0),
				Size = UDim2.new(0.5, -5, 0, 18),
				Font = Enum.Font.SourceSans,
				FontSize = Enum.FontSize.Size18,
				TextScaled = true,
				TextColor3 = COLORS.WHITE,
				TextStrokeTransparency = 0,
				Text = "",
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 2
			},

			create 'TextLabel' {
				Name = 'VoxelCount',
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, 5, 0, 60),
				Size = UDim2.new(0.5, -5, 0, 18),
				Font = Enum.Font.SourceSans,
				FontSize = Enum.FontSize.Size18,
				TextScaled = true,
				TextColor3 = COLORS.WHITE,
				TextStrokeTransparency = 0,
				Text = "",
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 2
			},
		},

		Parent = screenGui
	}

	while not Game:GetService("CoreGui") do
		wait()
	end
	screenGui.Parent = Game.CoreGui
	currScreenGui = screenGui
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

---------------------------------------------------------
-- Main Script (show something now + setup connections)

-- start loading assets asap
InfoProvider:LoadAssets()
MainGui:GenerateMain()

local guiService = Game:GetService("GuiService")

local removedLoadingScreen = false
local instanceCount = 0
local voxelCount = 0
local brickCount = 0
local connectorCount = 0
local setVerb = true
local fadeDown = true
local lastRenderTime = nil
local fadeCycleTime = 1.7

renderSteppedConnection = Game:GetService("RunService").RenderStepped:connect(function()
	if not currScreenGui then return end
	if setVerb then
		currScreenGui.BlackFrame.CloseButton:SetVerb("Exit")
		setVerb = false
	end

	if currScreenGui.BlackFrame.PlaceFrame.PlaceLabel.Text == "" then
		currScreenGui.BlackFrame.PlaceFrame.PlaceLabel.Text = InfoProvider:GetGameName()
	end

	if currScreenGui.BlackFrame.PlaceFrame.CreatorLabel.Text == "" then
		local creatorName = InfoProvider:GetCreatorName()
		if creatorName ~= "" then
			currScreenGui.BlackFrame.PlaceFrame.CreatorLabel.Text = "By " .. creatorName
		end
	end

	instanceCount = guiService:GetInstanceCount()
	voxelCount = guiService:GetVoxelCount()
	brickCount = guiService:GetBrickCount()
	connectorCount = guiService:GetConnectorCount()

	currScreenGui.BlackFrame.CountFrame.InstanceCount.Text = tostring(instanceCount)
	currScreenGui.BlackFrame.CountFrame.BrickCount.Text = tostring(brickCount)
	currScreenGui.BlackFrame.CountFrame.ConnectorCount.Text = tostring(connectorCount)

	if voxelCount <= 0 then
		currScreenGui.BlackFrame.CountFrame.VoxelCount.Text = "0"
	else
		currScreenGui.BlackFrame.CountFrame.VoxelCount.Text = tostring(round(voxelCount,4)) .." million"
	end

	if not lastRenderTime then
		lastRenderTime = tick()
		return
	end

	local currentTime = tick()
	local fadeAmount = (currentTime - lastRenderTime) * fadeCycleTime
	lastRenderTime = currentTime

	if fadeDown then
		currScreenGui.BlackFrame.GraphicsFrame.LoadingImage.ImageTransparency = currScreenGui.BlackFrame.GraphicsFrame.LoadingImage.ImageTransparency - fadeAmount
		if currScreenGui.BlackFrame.GraphicsFrame.LoadingImage.ImageTransparency <= 0 then
			fadeDown = false
		end
	else
		currScreenGui.BlackFrame.GraphicsFrame.LoadingImage.ImageTransparency = currScreenGui.BlackFrame.GraphicsFrame.LoadingImage.ImageTransparency + fadeAmount
		if currScreenGui.BlackFrame.GraphicsFrame.LoadingImage.ImageTransparency >= 1 then
			fadeDown = true
		end
	end
end)

guiService.ErrorMessageChanged:connect(function()
	if guiService:GetErrorMessage() ~= '' then
		currScreenGui.MainBackgroundContainer.ErrorFrame.ErrorText.Text = guiService:GetErrorMessage()
		currScreenGui.MainBackgroundContainer.ErrorFrame.Visible = true
	else
		currScreenGui.MainBackgroundContainer.ErrorFrame.Visible = false
	end
end)

if guiService:GetErrorMessage() ~= '' then
	currScreenGui.MainBackgroundContainer.ErrorFrame.ErrorText.Text = guiService:GetErrorMessage()
	currScreenGui.MainBackgroundContainer.ErrorFrame.Visible = true
end


function stopListeningToRenderingStep()
	if renderSteppedConnection then
		renderSteppedConnection:disconnect()
		renderSteppedConnection = nil
	end
end

function fadeBackground()
	if not currScreenGui then return end

	local lastTime = nil
	local backgroundRemovalTime = 3.2

	while currScreenGui and currScreenGui.BlackFrame and currScreenGui.BlackFrame.BackgroundTransparency < 1 do
		if lastTime == nil then
			currScreenGui.BlackFrame.Active = false
			lastTime = tick()
		else
			local currentTime = tick()
			local fadeAmount = (currentTime - lastTime) * backgroundRemovalTime
			lastTime = currentTime

			currScreenGui.BlackFrame.BackgroundTransparency = currScreenGui.BlackFrame.BackgroundTransparency + fadeAmount
		end

		wait()
	end
end

function destroyLoadingElements()
	if not currScreenGui then return end
	
	local guiChildren = currScreenGui:GetChildren()
	for i=1, #guiChildren do
		-- need to keep this around in case we get a connection error later
		if guiChildren[i].Name ~= "ErrorFrame" then
			guiChildren[i]:Destroy()
		end
	end
end

function removeLoadingScreen()
	if removedLoadingScreen then return end
	removedLoadingScreen = true

	stopListeningToRenderingStep()
	destroyLoadingElements()
end


function gameIsLoaded()
	removeLoadingScreen()
end

Game.ReplicatedFirst.RemoveDefaultLoadingGuiSignal:connect(removeLoadingScreen)
if Game.ReplicatedFirst:IsDefaultLoadingGuiRemoved() then
	removeLoadingScreen()
	return
end

Game.Loaded:connect(gameIsLoaded)
if Game:IsLoaded() then
	gameIsLoaded()
end

-- quickly fade background to show 3D, any user loading scripts should of started by now
wait(1.5)
fadeBackground()