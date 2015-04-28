-- Creates the generic "ROBLOX" loading screen on startup
-- Written by ArceusInator & Ben Tkacheff, 2014
--

-- Constants
local PLACEID = Game.PlaceId

local MPS = Game:GetService 'MarketplaceService'
local CP = Game:GetService 'ContentProvider'

local startTime = tick()

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
local fadingBackground = false
local destroyedLoadingGui = false
local hasReplicatedFirstElements = false

-- Fast Flags
local topbarSuccess, topbarFlagValue = pcall(function() return settings():GetFFlag("UseInGameTopBar") end)
local useTopBar = (topbarSuccess and topbarFlagValue == true)
local bgFrameOffset = useTopBar and 36 or 20
local offsetPosition = useTopBar and UDim2.new(0, 0, 0, -36) or UDim2.new(0, 0, 0, 0)

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
		coroutine.resume(coroutine.create(function()
			local success, result = pcall(function()
				GameAssetInfo = MPS:GetProductInfo(PLACEID)
			end)
			if not success then
				print("LoadingScript->InfoProvider:LoadAssets:", result)
			end
		end))
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
		Size = UDim2.new(1, 0, 1, bgFrameOffset),
		Position = offsetPosition,
		Active = true,

		create 'ImageButton' {
				Name = 'CloseButton',
				Image = 'rbxasset://textures/ui/CloseButton_dn.png',
				ImageColor3=Color3.new(0.9,0.9,0.9),
				ImageTransparency = 1,
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -37, 0, 5),
				Size = UDim2.new(0, 32, 0, 32),
				Active = false,
				ZIndex = 10
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
			Name = 'UiMessageFrame',
			BackgroundTransparency = 1,
			Position = UDim2.new(0.25, 0, 1, -120),
			Size = UDim2.new(0.5, 0, 0, 80),
			ZIndex = 2,

			create 'TextLabel' {
				Name = 'UiMessage',
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Font = Enum.Font.SourceSansBold,
				FontSize = Enum.FontSize.Size18,
				TextWrapped = true,
				TextColor3 = COLORS.WHITE,
				Text = "",
				ZIndex = 2
			},
		},
		
		create 'Frame' {
			Name = 'CountFrame',
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 1, -120),
			Size = UDim2.new(0.3, 0, 0, 120),
			ZIndex = 2,

			create 'TextLabel' {
				Name = 'PlaceLabel',
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -5, 0, 18),
				Position = UDim2.new(0, 5, 0, 0),
				Font = Enum.Font.SourceSansBold,
				FontSize = Enum.FontSize.Size14,
				TextWrapped = true,
				TextScaled = true,
				TextColor3 = COLORS.WHITE,
				TextStrokeTransparency = 0,
				Text = "",
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 2
			},

			create 'TextLabel' {
				Name = 'CreatorLabel',
				BackgroundTransparency = 1,
				Position = UDim2.new(0,5,0,18),
				Size = UDim2.new(1, -5, 0, 18),
				Font = Enum.Font.SourceSans,
				FontSize = Enum.FontSize.Size12,
				TextWrapped = true,
				TextScaled = true,
				TextColor3 = COLORS.WHITE,
				TextStrokeTransparency = 0,
				Text = "",
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 2
			},

			create 'TextLabel' {
				Name = 'BrickLabel',
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 5, 0, 63),
				Size = UDim2.new(0, 85, 0, 18),
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
				Position = UDim2.new(0, 5, 0, 81),
				Size = UDim2.new(0, 85, 0, 18),
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
				Position = UDim2.new(0, 5, 0, 45),
				Size = UDim2.new(0, 85, 0, 18),
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
				Position = UDim2.new(0, 5, 0, 99),
				Size = UDim2.new(0, 85, 0, 18),
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
				Position = UDim2.new(0, 95, 0, 63),
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
				Position = UDim2.new(0, 95, 0, 81),
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
				Position = UDim2.new(0, 95, 0, 45),
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
				Position = UDim2.new(0, 95, 0, 99),
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
			},

		Parent = screenGui
	}

	while not Game:GetService("CoreGui") do
		wait()
	end
	screenGui.Parent = Game:GetService("CoreGui")
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
	if not currScreenGui:FindFirstChild("BlackFrame") then return end

	if setVerb then
		currScreenGui.BlackFrame.CloseButton:SetVerb("Exit")
		setVerb = false
	end

	if currScreenGui.BlackFrame.CountFrame.PlaceLabel.Text == "" then
		currScreenGui.BlackFrame.CountFrame.PlaceLabel.Text = InfoProvider:GetGameName()
	end

	if currScreenGui.BlackFrame.CountFrame.CreatorLabel.Text == "" then
		local creatorName = InfoProvider:GetCreatorName()
		if creatorName ~= "" then
			currScreenGui.BlackFrame.CountFrame.CreatorLabel.Text = "By " .. creatorName
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
	
	-- fade in close button after 5 seconds
	if currentTime - startTime > 5 and currScreenGui.BlackFrame.CloseButton.ImageTransparency > 0 then
		currScreenGui.BlackFrame.CloseButton.ImageTransparency = currScreenGui.BlackFrame.CloseButton.ImageTransparency - fadeAmount

		if currScreenGui.BlackFrame.CloseButton.ImageTransparency <= 0 then
			currScreenGui.BlackFrame.CloseButton.Active = true
		end
	end
end)

guiService.ErrorMessageChanged:connect(function()
	if guiService:GetErrorMessage() ~= '' then
		currScreenGui.ErrorFrame.ErrorText.Text = guiService:GetErrorMessage()
		currScreenGui.ErrorFrame.Visible = true
		local blackFrame = currScreenGui:FindFirstChild('BlackFrame')
		if blackFrame then
			blackFrame.CloseButton.ImageTransparency = 0
			blackFrame.CloseButton.Active = true
		end
	else
		currScreenGui.ErrorFrame.Visible = false
	end
end)

guiService.UiMessageChanged:connect(function(type, newMessage)
	if type == Enum.UiMessageType.UiMessageInfo then
		local blackFrame = currScreenGui and currScreenGui:FindFirstChild('BlackFrame')
		if blackFrame then
			blackFrame.UiMessageFrame.UiMessage.Text = newMessage
			if newMessage ~= '' then
				blackFrame.UiMessageFrame.Visible = true
			else
				blackFrame.UiMessageFrame.Visible = false
			end
		end
	end
end)

if guiService:GetErrorMessage() ~= '' then
	currScreenGui.ErrorFrame.ErrorText.Text = guiService:GetErrorMessage()
	currScreenGui.ErrorFrame.Visible = true
end


function stopListeningToRenderingStep()
	if renderSteppedConnection then
		renderSteppedConnection:disconnect()
		renderSteppedConnection = nil
	end
end

function fadeBackground()
	if not currScreenGui then return end
	if fadingBackground then return end
	
	if not currScreenGui:findFirstChild("BlackFrame") then return end

	fadingBackground = true

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

function fadeAndDestroyBlackFrame(blackFrame)
	Spawn(function()
		local countFrame = blackFrame:FindFirstChild("CountFrame")
		local graphicsFrame = blackFrame:FindFirstChild("GraphicsFrame")

		local textChildren = countFrame:GetChildren()
		local transparency = 0
		local rateChange = 1.8
		local lastUpdateTime = nil

		while transparency < 1 do
			if not lastUpdateTime then
				lastUpdateTime = tick()
			else
				local newTime = tick()
				transparency = transparency + rateChange * (newTime - lastUpdateTime)
				for i =1, #textChildren do
					textChildren[i].TextTransparency = transparency
					textChildren[i].TextStrokeTransparency = transparency
				end
				graphicsFrame.LoadingImage.ImageTransparency = transparency
				graphicsFrame.LogoImage.ImageTransparency = transparency

				lastUpdateTime = newTime
			end
			wait()
		end
		blackFrame:Destroy()
	end)
end

function destroyLoadingElements()
	if not currScreenGui then return end
	if destroyedLoadingGui then return end
	destroyedLoadingGui = true
	
	local guiChildren = currScreenGui:GetChildren()
	for i=1, #guiChildren do
		-- need to keep this around in case we get a connection error later
		if guiChildren[i].Name ~= "ErrorFrame" then
			if guiChildren[i].Name == "BlackFrame" then
				fadeAndDestroyBlackFrame(guiChildren[i])
			else
				guiChildren[i]:Destroy()
			end
		end
	end
end

function handleFinishedReplicating()
	hasReplicatedFirstElements = (#Game:GetService("ReplicatedFirst"):GetChildren() > 0)
	if not hasReplicatedFirstElements then
		fadeBackground()
	else
		wait(20) -- make sure after 20 seconds we remove the default gui, even if the user doesn't
		handleRemoveDefaultLoadingGui()
	end
end

function handleRemoveDefaultLoadingGui()
	fadeBackground()
	destroyLoadingElements()
end

function handleGameLoaded()
	if not hasReplicatedFirstElements then
		destroyLoadingElements()
	end
end

Game:GetService("ReplicatedFirst").FinishedReplicating:connect(handleFinishedReplicating)
if Game:GetService("ReplicatedFirst"):IsFinishedReplicating() then
	handleFinishedReplicating()
end

Game:GetService("ReplicatedFirst").RemoveDefaultLoadingGuiSignal:connect(handleRemoveDefaultLoadingGui)
if Game:GetService("ReplicatedFirst"):IsDefaultLoadingGuiRemoved() then
	handleRemoveDefaultLoadingGui()
	return
end

Game.Loaded:connect(handleGameLoaded)
if Game:IsLoaded() then
	handleGameLoaded()
end
