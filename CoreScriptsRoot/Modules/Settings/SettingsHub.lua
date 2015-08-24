--[[
		Filename: SettingsHub.lua
		Written by: jeditkacheff
		Version 1.0
		Description: Controls the settings menu navigation and contains the settings pages
--]]

--[[ CONSTANTS ]]
local SETTINGS_SHIELD_COLOR = Color3.new(41/255,41/255,41/255)
local SETTINGS_SHIELD_TRANSPARENCY = 0.2
local SETTINGS_SHIELD_SIZE = UDim2.new(1, 0, 1, 0)
local SETTINGS_SHIELD_INACTIVE_POSITION = UDim2.new(0,0,-1,-36)
local SETTINGS_SHIELD_ACTIVE_POSITION = UDim2.new(0, 0, 0, 0)
local SETTINGS_BASE_ZINDEX = 2
local DEV_CONSOLE_ACTION_NAME = "Open Dev Console"

--[[ SERVICES ]]
local CoreGui = game:GetService("CoreGui")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--[[ UTILITIES ]]
local utility = require(RobloxGui.Modules.Settings.Utility)

--[[ VARIABLES ]]
local isTouchDevice = UserInputService.TouchEnabled
RobloxGui:WaitForChild("Modules"):WaitForChild("TenFootInterface")
local isTenFootInterface = require(RobloxGui.Modules.TenFootInterface):IsEnabled()
local platform = UserInputService:GetPlatform()
-- TODO: Change dev console script to parent this to somewhere other than an engine created gui
local ControlFrame = RobloxGui:WaitForChild('ControlFrame')
local ToggleDevConsoleBindableFunc = ControlFrame:WaitForChild('ToggleDevConsole')
local lastInputChangedCon = nil

--[[ CORE MODULES ]]
local playerList = require(RobloxGui.Modules.PlayerlistModule)
local chat = require(RobloxGui.Modules.Chat)
local backpack = require(RobloxGui.Modules.BackpackScript)

if utility:IsSmallTouchScreen() or isTenFootInterface then
	SETTINGS_SHIELD_ACTIVE_POSITION = UDim2.new(0,0,0,0)
	SETTINGS_SHIELD_SIZE = UDim2.new(1,0,1,0)
end

local function CreateSettingsHub()
	local this = {}
	this.Visible = false
	this.Active = false
	this.Pages = {CurrentPage = nil, PageTable = {}}
	this.MenuStack = {}
	this.TabHeaders = {}
	this.BottomBarButtons = {}
	this.LeaveGamePage = require(RobloxGui.Modules.Settings.Pages.LeaveGame)
	this.ResetCharacterPage = require(RobloxGui.Modules.Settings.Pages.ResetCharacter)
	this.SettingsShowSignal = utility:CreateSignal()

	local pageChangeCon = nil

	local PoppedMenuEvent = Instance.new("BindableEvent")
	PoppedMenuEvent.Name = "PoppedMenu"
	this.PoppedMenu = PoppedMenuEvent.Event

	local function setBottomBarBindings()
		for i = 1, #this.BottomBarButtons do
			local buttonTable = this.BottomBarButtons[i]
			local buttonName = buttonTable[1]
			local hotKeyTable = buttonTable[2]
			ContextActionService:BindCoreAction(buttonName, hotKeyTable[1], false, unpack(hotKeyTable[2]))
		end

		if this.BottomButtonFrame then
			this.BottomButtonFrame.Visible = true
		end
	end

	local function removeBottomBarBindings()
		for _, hotKeyTable in pairs(this.BottomBarButtons) do
			ContextActionService:UnbindCoreAction(hotKeyTable[1])
		end

		if this.BottomButtonFrame then
			this.BottomButtonFrame.Visible = false
		end
	end

	local function addBottomBarButton(name, text, gamepadImage, keyboardImage, position, clickFunc, hotkeys)
		local buttonName = name .. "Button"
		local textName = name .. "Text"

		local size = UDim2.new(0,260,0,70)
		if isTenFootInterface then
			size = UDim2.new(0,320,0,120)
		end

		this[buttonName], this[textName] = utility:MakeStyledButton(name .. "Button", text, size, clickFunc, nil, this)
		this[buttonName].Position = position
		this[buttonName].Parent = this.BottomButtonFrame
		if isTenFootInterface then
			this[buttonName].ImageTransparency = 1
		end

		this[textName].FontSize = Enum.FontSize.Size24
		local hintLabel = nil

		if not UserInputService.TouchEnabled then
			this[textName].Size = UDim2.new(1,0,1,0)
			if isTenFootInterface then
				this[textName].Position = UDim2.new(0,60,0,-4)
			else
				this[textName].Position = UDim2.new(0,10,0,-4)
			end

			local hintNameText = name .. "HintText"
			local hintName = name .. "Hint"
			local image = ""
			if UserInputService:GetGamepadConnected(Enum.UserInputType.Gamepad1) or platform == Enum.Platform.XBoxOne then
				image = gamepadImage
			else
				image = keyboardImage
			end

			hintLabel = utility:Create'ImageLabel'
			{
				Name = hintName,
				Size = UDim2.new(0,60,0,60),
				Position = UDim2.new(0,10,0,5),
				ZIndex = this.Shield.ZIndex + 2,
				BackgroundTransparency = 1,
				Image = image,
				Parent = this[buttonName]
			};
			if isTenFootInterface then
				hintLabel.Size = UDim2.new(0,90,0,90)
				hintLabel.Position = UDim2.new(0,10,0.5,-45)
			end
		end

		if isTenFootInterface then
			this[textName].FontSize = Enum.FontSize.Size36
		end

		UserInputService.InputBegan:connect(function(inputObject)
			if inputObject.UserInputType == Enum.UserInputType.Gamepad1 or inputObject.UserInputType == Enum.UserInputType.Gamepad2 or
				inputObject.UserInputType == Enum.UserInputType.Gamepad3 or inputObject.UserInputType == Enum.UserInputType.Gamepad4 then
					if hintLabel then
						hintLabel.Image = gamepadImage
						if isTenFootInterface then
							hintLabel.Size = UDim2.new(0,90,0,90)
							hintLabel.Position = UDim2.new(0,10,0.5,-45)
						else
							hintLabel.Size = UDim2.new(0,60,0,60)
							hintLabel.Position = UDim2.new(0,10,0,5)
						end
					end
			elseif inputObject.UserInputType == Enum.UserInputType.Keyboard then
				if hintLabel then
					hintLabel.Image = keyboardImage
					hintLabel.Size = UDim2.new(0,48,0,48)
					hintLabel.Position = UDim2.new(0,10,0,8)
				end
			end
		end)

		local hotKeyFunc = function(contextName, inputState, inputObject)
			if inputState == Enum.UserInputState.Begin then
				clickFunc()
			end
		end

		local hotKeyTable = {hotKeyFunc, hotkeys}
		this.BottomBarButtons[#this.BottomBarButtons + 1] = {buttonName, hotKeyTable}
	end

	local function createGui()
		local PageViewSizeReducer = 0
		if utility:IsSmallTouchScreen() then
			PageViewSizeReducer = 5
		end

		local clippingShield = utility:Create'Frame'
		{
			Name = "SettingsShield",
			Size = SETTINGS_SHIELD_SIZE,
			Position = SETTINGS_SHIELD_ACTIVE_POSITION,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			BackgroundTransparency = 1,
			Visible = true,
			ZIndex = SETTINGS_BASE_ZINDEX,
			Parent = RobloxGui
		};

		this.Shield = utility:Create'Frame'
		{
			Name = "SettingsShield",
			Size = UDim2.new(1,0,1,0),
			Position = SETTINGS_SHIELD_INACTIVE_POSITION,
			BackgroundTransparency = SETTINGS_SHIELD_TRANSPARENCY,
			BackgroundColor3 = SETTINGS_SHIELD_COLOR,
			BorderSizePixel = 0,
			Visible = false,
			Active = true,
			ZIndex = SETTINGS_BASE_ZINDEX,
			Parent = clippingShield
		};

		this.HubBar = utility:Create'ImageLabel'
		{
			Name = "HubBar",
			ZIndex = this.Shield.ZIndex + 1,
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(78/255, 84/255, 96/255),
			BackgroundTransparency = 1,
			Image = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuBackground.png",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(4,4,6,6),
			Parent = this.Shield
		};

		local barHeight = 60
		if utility:IsSmallTouchScreen() then
			barHeight = 40
			this.HubBar.Size = UDim2.new(1,-10,0,40)
			this.HubBar.Position = UDim2.new(0,5,0,6)
		elseif isTenFootInterface then
			barHeight = 100
			this.HubBar.Size = UDim2.new(0,1200,0,100)
			this.HubBar.Position = UDim2.new(0.5,-600,0.1,0)
		else
			this.HubBar.Size = UDim2.new(0,800,0,60)
			this.HubBar.Position = UDim2.new(0.5,-400,0.12,0)
		end

		this.PageViewClipper = utility:Create'Frame'
		{
			Name = 'PageViewClipper',
			BackgroundTransparency = 1,
			Size = UDim2.new(this.HubBar.Size.X.Scale,this.HubBar.Size.X.Offset,
				 				1, -this.HubBar.Size.Y.Offset - this.HubBar.Position.Y.Offset - PageViewSizeReducer),
			Position = UDim2.new(this.HubBar.Position.X.Scale, this.HubBar.Position.X.Offset,
												this.HubBar.Position.Y.Scale, this.HubBar.Position.Y.Offset + this.HubBar.Size.Y.Offset + 1),
			ClipsDescendants = true,
			Parent = this.Shield,

			utility:Create'ImageButton'{
				Name = 'InputCapture',
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Image = ''
			}
		}

		this.PageViewScrollBar = utility:Create'Frame'{
			Name = 'ScrollBar',
			Parent = this.PageViewClipper,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -12, 0, 0),
			Size = UDim2.new(0, 12, 1, 0),

			utility:Create'ImageLabel'{
				Name = 'Top',
				BackgroundTransparency = 1,
				Image = 'rbxasset://textures/ui/Scroll/scroll-top.png',
				Position = UDim2.new(0, 0, 0, -6),
				Size = UDim2.new(1, 0, 0, 12),
				ZIndex = 3
			},
			utility:Create'ImageLabel'{
				Name = 'Middle',
				BackgroundTransparency = 1,
				Image = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
				Position = UDim2.new(0, 0, 0, 6),
				Size = UDim2.new(1, 0, 1, -6*2),
				ZIndex = 3
			},
			utility:Create'ImageLabel'{
				Name = 'Bottom',
				BackgroundTransparency = 1,
				Image = 'rbxasset://textures/ui/Scroll/scroll-bottom.png',
				Position = UDim2.new(0, 0, 1, -6),
				Size = UDim2.new(1, 0, 0, 12),
				ZIndex = 3
			},
			utility:Create'ImageButton'{
				Name = 'InputCapture',
				BackgroundTransparency = 1,
				Image = '',
				Size = UDim2.new(1, 0, 1, 0)
			}
		}

		this.PageView = utility:Create'ScrollingFrame'
		{
			Name = "PageView",
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = this.Shield.ZIndex,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Selectable = false,
			Parent = this.PageViewClipper,
			ScrollingEnabled = false
		};
		if UserInputService.MouseEnabled then
			this.PageViewClipper.Size = UDim2.new(this.HubBar.Size.X.Scale,this.HubBar.Size.X.Offset,
				 							0.5, -(this.HubBar.Position.Y.Offset - this.HubBar.Size.Y.Offset))
		end

		if utility:IsSmallTouchScreen() then
			this.PageView.CanvasSize = this.PageViewClipper.Size
		else
			local bottomOffset = 0
			if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
				bottomOffset = 80
			end
			this.BottomButtonFrame = utility:Create'Frame'
			{
				Name = "BottomButtonFrame",
				Size = this.HubBar.Size,
				Position = UDim2.new(0.5, -this.HubBar.Size.X.Offset/2, 1-this.HubBar.Position.Y.Scale-this.HubBar.Size.Y.Scale, -this.HubBar.Position.Y.Offset-this.HubBar.Size.Y.Offset),
				ZIndex = this.Shield.ZIndex + 1,
				BackgroundTransparency = 1,
				Parent = this.Shield
			};

			local leaveGameFunc = function()
				this:AddToMenuStack(this.Pages.CurrentPage)
				this.HubBar.Visible = false
				removeBottomBarBindings()
				this:SwitchToPage(this.LeaveGamePage, nil, 1)
			end

			local resetCharFunc = function()
				this:AddToMenuStack(this.Pages.CurrentPage)
				this.HubBar.Visible = false
				removeBottomBarBindings()
				this:SwitchToPage(this.ResetCharacterPage, nil, 1)
			end

			local resumeFunc = function()
				setVisibilityInternal(false)
			end

			local buttonImageAppend = ""

			if isTenFootInterface then
				buttonImageAppend = "@2x"
			end

			addBottomBarButton("LeaveGame", "Leave Game", "rbxasset://textures/ui/Settings/Help/XButtonLight" .. buttonImageAppend .. ".png", 
				"rbxasset://textures/ui/Settings/Help/LeaveIcon.png", UDim2.new(0.5,isTenFootInterface and -160 or -130,0.5,-25), 
				leaveGameFunc, {Enum.KeyCode.L, Enum.KeyCode.ButtonX})
			addBottomBarButton("ResetCharacter", "    Reset Character", "rbxasset://textures/ui/Settings/Help/YButtonLight" .. buttonImageAppend .. ".png", 
				"rbxasset://textures/ui/Settings/Help/ResetIcon.png", UDim2.new(0.5,isTenFootInterface and -550 or -400,0.5,-25), 
				resetCharFunc, {Enum.KeyCode.R, Enum.KeyCode.ButtonY})
			addBottomBarButton("Resume", "Resume Game", "rbxasset://textures/ui/Settings/Help/BButtonLight" .. buttonImageAppend .. ".png",
				"rbxasset://textures/ui/Settings/Help/EscapeIcon.png", UDim2.new(0.5,isTenFootInterface and 200 or 140,0.5,-25), 
				resumeFunc, {Enum.KeyCode.ButtonB, Enum.KeyCode.ButtonStart})
		end


		local function onScreenSizeChanged()
			local largestPageSize = 405
			local fullScreenSize = RobloxGui.AbsoluteSize.y
			local bufferSize = (1-0.85) * fullScreenSize
			if isTenFootInterface then
				largestPageSize = 800
				bufferSize = 0.07 * fullScreenSize
			elseif utility:IsSmallTouchScreen() then
				bufferSize = (1-0.99) * fullScreenSize
			end
			local barSize = this.HubBar.Size.Y.Offset
			local extraSpace = bufferSize*2+barSize*2
			
			if utility:IsSmallTouchScreen() then
				extraSpace = bufferSize+barSize+4
			end

			local usableScreenHeight = fullScreenSize - extraSpace
			local minimumPageSize = 150
			local usePageSize = minimumPageSize

			if largestPageSize < usableScreenHeight then
				usePageSize = largestPageSize
				this.HubBar.Position = UDim2.new(
					this.HubBar.Position.X.Scale,
					this.HubBar.Position.X.Offset,
					0.5,
					-largestPageSize/2 - this.HubBar.Size.Y.Offset
				)
				if this.BottomButtonFrame then
					this.BottomButtonFrame.Position = UDim2.new(
						this.BottomButtonFrame.Position.X.Scale,
						this.BottomButtonFrame.Position.X.Offset,
						0.5,
						largestPageSize/2
					)
				end
			elseif usableScreenHeight < minimumPageSize then
				usePageSize = minimumPageSize
				this.HubBar.Position = UDim2.new(
					this.HubBar.Position.X.Scale,
					this.HubBar.Position.X.Offset,
					0.5,
					-minimumPageSize/2 - this.HubBar.Size.Y.Offset
				)
				if this.BottomButtonFrame then
					this.BottomButtonFrame.Position = UDim2.new(
						this.BottomButtonFrame.Position.X.Scale,
						this.BottomButtonFrame.Position.X.Offset,
						0.5,
						minimumPageSize/2
					)
				end
			else
				usePageSize = usableScreenHeight
				this.HubBar.Position = UDim2.new(
					this.HubBar.Position.X.Scale,
					this.HubBar.Position.X.Offset,
					0,
					bufferSize
				)
				if this.BottomButtonFrame then
					this.BottomButtonFrame.Position = UDim2.new(
						this.BottomButtonFrame.Position.X.Scale,
						this.BottomButtonFrame.Position.X.Offset,
						1,
						-(bufferSize + barSize)
					)
				end
			end

			this.PageViewClipper.Size = UDim2.new(
				this.PageViewClipper.Size.X.Scale,
				this.PageViewClipper.Size.X.Offset,
				0,
				usePageSize
			)
			this.PageViewClipper.Position = UDim2.new(
				this.PageViewClipper.Position.X.Scale,
				this.PageViewClipper.Position.X.Offset,
				0.5,
				-usePageSize/2
			)
		end
		screenSizeChangedCon = RobloxGui.Changed:connect(function(prop)
			if prop == "AbsoluteSize" then
				onScreenSizeChanged()
			end
		end)
		onScreenSizeChanged()

		-- Resize the scroll bar whenever content or size changes
		local function resizePageViewScrollBar()
			local space = this.PageView.AbsoluteSize.y
			local size = this.PageView.CanvasSize.Y.Offset
			local progress = this.PageView.CanvasPosition.Y

			if size > space then
				this.PageViewScrollBar.Visible = true

				this.PageViewScrollBar.Size = UDim2.new(0, 12, space/size, 0)
				this.PageViewScrollBar.Position = UDim2.new(1, -12, progress/size, 1)
			else
				this.PageViewScrollBar.Visible = false
			end
		end
		local onPageViewChangedCon = this.PageView.Changed:connect(function(prop)
			if prop == 'CanvasSize' or prop == 'CanvasPosition' or prop == 'AbsoluteSize' or prop == 'AbsolutePosition' then
				resizePageViewScrollBar()
			end
		end)

		-- Mouse wheel scrolling
		this.PageViewClipper.InputCapture.InputChanged:connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseWheel then
				local dir = input.Position.z
				local power = 20
				local pixels = -dir*power

				this:ScrollPixels(pixels)
			end
		end)

		-- Scroll bar drag scrolling
		-- Note: At the time of writing there is a bug where mouse movement position will not account for the top bar so the scroll movement will be offset by 36 pixels.  Should be fixed soon.
		local isDraggingScrollbar = false
		local scrollBarHandleOffset = 0
		this.PageViewScrollBar.InputCapture.InputBegan:connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				scrollBarHandleOffset = input.Position.y - this.PageViewScrollBar.AbsolutePosition.y
				isDraggingScrollbar = true
			end
		end)
		UserInputService.InputChanged:connect(function(input)
			if isDraggingScrollbar and input.UserInputType == Enum.UserInputType.MouseMovement then
				local mouseYRelative = input.Position.Y - scrollBarHandleOffset - this.PageViewClipper.AbsolutePosition.y
				local totalSpace = this.PageViewClipper.AbsoluteSize.y - this.PageViewScrollBar.AbsoluteSize.y
				local progress = math.max(0, math.min(mouseYRelative/totalSpace, 1))
				this:ScrollToProgress(progress)
			end
		end)
		UserInputService.InputEnded:connect(function(input)
			if isDraggingScrollbar and input.UserInputType == Enum.UserInputType.MouseButton1 then
				isDraggingScrollbar = false
			end
		end)

		-- Thumbstick scrolling
		local deadzone = 0.25
		local scrolling = false
		local scrollingPixels = 0
		UserInputService.InputChanged:connect(function(input)
			if this.Visible then
				if input.KeyCode == Enum.KeyCode.Thumbstick2 then
					if math.abs(input.Position.y) > deadzone then
						local dir = input.Position.y > 0 and 1 or -1
						local power = 3 * (math.abs(input.Position.y)-deadzone)/(1-deadzone)
						scrollingPixels = -dir*power

						this:ScrollPixels(scrollingPixels)

						if not scrolling then
							scrolling = true
							while scrolling do
								this:ScrollPixels(scrollingPixels)
								RunService.RenderStepped:wait()
							end
						end
					else
						if scrolling then
							scrolling = false
						end
					end
				end
			end
		end)

		-- touch drag scrolling
		local pcTestTouchControls = false
		if UserInputService.TouchEnabled or pcTestTouchControls then
			local isDraggingTouch = false
			local touchHandleOffset = 0
			local touchPosition = 0
			local lastPosition = 0
			local listenForActiveInput = pcTestTouchControls and Enum.UserInputType.MouseButton1 or Enum.UserInputType.Touch
			local listenForPassiveInput = pcTestTouchControls and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch
			UserInputService.InputBegan:connect(function(input)
				if input.UserInputType == listenForActiveInput then
					local ax, ay = this.PageViewClipper.InputCapture.AbsolutePosition.x, this.PageViewClipper.InputCapture.AbsolutePosition.y
					local sx, sy = this.PageViewClipper.InputCapture.AbsoluteSize.x, this.PageViewClipper.InputCapture.AbsoluteSize.y
					local bx, by = ax+sx, ay+sy
					local px, py = input.Position.x, input.Position.y

					if px > ax and px < bx and py > ay and py < by then
						touchHandleOffset = input.Position.y - this.PageViewScrollBar.AbsolutePosition.y
						touchPosition = input.Position.Y - touchHandleOffset - this.PageViewClipper.AbsolutePosition.y
						lastPosition = input.Position.Y
						isDraggingTouch = true
					end
				end
			end)
			UserInputService.InputChanged:connect(function(input)
				if isDraggingTouch and input.UserInputType == listenForPassiveInput then
					local delta = input.Position.y - lastPosition
					touchPosition = touchPosition + -delta
					lastPosition = input.Position.y
					local totalSpace = this.PageViewClipper.AbsoluteSize.y - this.PageViewScrollBar.AbsoluteSize.y
					local progress = math.max(0, math.min(touchPosition/totalSpace, 1))
					this:ScrollToProgress(progress)
				end
			end)
			UserInputService.InputEnded:connect(function(input)
				if isDraggingTouch and input.UserInputType == listenForActiveInput then
					isDraggingTouch = false
				end
			end)
		end
	end

	local function toggleDevConsole(actionName, inputState, inputObject)
		if actionName == DEV_CONSOLE_ACTION_NAME then 	-- ContextActionService->F9
			if inputState and inputState == Enum.UserInputState.Begin and ToggleDevConsoleBindableFunc then
				ToggleDevConsoleBindableFunc:Invoke()
			end
		end
	end


	local switchTabFunc = function(actionName, inputState, inputObject)
		if inputState ~= Enum.UserInputState.Begin then return end

		local direction = 0
		if inputObject.KeyCode == Enum.KeyCode.ButtonR1 or inputObject.KeyCode == Enum.KeyCode.Tab then 
			direction = 1
		elseif inputObject.KeyCode == Enum.KeyCode.ButtonL1 then 
			direction = -1
		end

		local currentTabPosition = GetHeaderPosition(this.Pages.CurrentPage)
		if currentTabPosition < 0 then return end

		local newTabPosition = currentTabPosition + direction
		local newHeader = this.TabHeaders[newTabPosition]

		if not newHeader and inputObject.KeyCode == Enum.KeyCode.Tab then
			newHeader = this.TabHeaders[1]
		end

		if newHeader then
			for pager,v in pairs(this.Pages.PageTable) do
				if pager:GetTabHeader() == newHeader then
					this:SwitchToPage(pager, true, direction)
					break
				end
			end
		end
	end

	-- need some stuff for functions below so init here
	createGui()

	function GetHeaderPosition(page)
		local header = page:GetTabHeader()
		if not header then return -1 end

		for i,v in pairs(this.TabHeaders) do
			if v == header then
				return i
			end
		end

		return -1
	end

	local setZIndex = nil
	setZIndex = function(newZIndex, object)
		if object:IsA("GuiObject") then
			object.ZIndex = newZIndex
			local children = object:GetChildren()
			for i = 1, #children do
				setZIndex(newZIndex, children[i])
			end
		end
	end

	local function AddHeader(newHeader, headerPage)
		if not newHeader then return end

		this.TabHeaders[#this.TabHeaders + 1] = newHeader
		headerPage.TabPosition = #this.TabHeaders

		local sizeOfTab = 1/#this.TabHeaders
		for i = 1, #this.TabHeaders do
			local tabMaxPos = (sizeOfTab * i)
			local tabMinPos = (sizeOfTab * (i - 1))
			local pos = ((tabMaxPos - tabMinPos)/2) + tabMinPos

			local tab = this.TabHeaders[i]
			tab.Position = UDim2.new(pos,-tab.Size.X.Offset/2,0,0)
		end

		setZIndex(SETTINGS_BASE_ZINDEX + 1, newHeader)
		newHeader.Parent = this.HubBar
	end

	local function RemoveHeader(oldHeader)
		local removedPos = nil

		for i = 1, #this.TabHeaders do 
			if this.TabHeaders[i] == oldHeader then
				removedPos = i
				table.remove(this.TabHeaders, i)
				break
			end
		end

		if removedPos then
			for i = removedPos, #this.TabHeaders do
				local currentTab = this.TabHeaders[i]
				currentTab.Position = UDim2.new(currentTab.Position.X.Scale, currentTab.Position.X.Offset - oldHeader.AbsoluteSize.X,
				 								currentTab.Position.Y.Scale, currentTab.Position.Y.Offset)
			end
		end

		oldHeader.Parent = nil
	end

	-- Page APIs
	function this:AddPage(pageToAdd)
		this.Pages.PageTable[pageToAdd] = true
		AddHeader(pageToAdd:GetTabHeader(), pageToAdd)
		pageToAdd.Page.Position = UDim2.new(pageToAdd.TabPosition - 1,0,0,0)
	end
	
	function this:RemovePage(pageToRemove)
		this.Pages.PageTable[pageToRemove] = nil
		RemoveHeader(pageToRemove:GetTabHeader())
	end

	function this:HideBar()
		this.HubBar.Visible = false
		this.PageViewClipper.Visible = false
		if this.BottomButtonFrame then
			removeBottomBarBindings()
		end
	end

	function this:ShowBar()
		this.HubBar.Visible = true
		this.PageViewClipper.Visible = true
		if this.BottomButtonFrame then
			setBottomBarBindings()
		end
	end

	function this:GetScrollProgress()
		return this.PageView.CanvasPosition.y / (this.PageView.CanvasSize.Y.Offset - this.PageViewClipper.AbsoluteSize.y)
	end

	function this:ScrollToProgress(progress)
		local pixels = (this.PageView.CanvasSize.Y.Offset - this.PageViewClipper.AbsoluteSize.y) * progress
		this.PageView.CanvasPosition = Vector2.new(0, pixels)
	end

	function this:ScrollPixels(pixels)
		-- Only Y
		local oldY = this.PageView.CanvasPosition.Y
		local maxY = this.PageView.CanvasSize.Y.Offset - this.PageViewClipper.AbsoluteSize.y
		local newY = math.max(0, math.min(oldY+pixels, maxY)) -- i.e. clamp
		this.PageView.CanvasPosition = Vector2.new(0, newY)
	end

	function this:ScrollToFrame(frame)
		local ay = frame.AbsolutePosition.y - this.Pages.CurrentPage.Page.AbsolutePosition.y
		local by = ay + frame.AbsoluteSize.y

		if ay < this.PageView.CanvasPosition.y then -- Scroll up to fit top
			this.PageView.CanvasPosition = Vector2.new(0, ay)
		elseif by - this.PageView.CanvasPosition.y > this.PageViewClipper.Size.Y.Offset then -- Scroll down to fit bottom
			this.PageView.CanvasPosition = Vector2.new(0, by - this.PageViewClipper.Size.Y.Offset)
		end
	end

	function this:SwitchToPage(pageToSwitchTo, ignoreStack, direction)
		if this.Pages.PageTable[pageToSwitchTo] == nil then return end

		-- scroll back up
		this:ScrollToProgress(0)

		-- if we have a page we need to let it know to go away
		if this.Pages.CurrentPage then
			pageChangeCon:disconnect()
			this.Pages.CurrentPage.Active = false
		end

		-- make sure all pages are in right position
		local newPagePos = pageToSwitchTo.TabPosition
		for page, _ in pairs(this.Pages.PageTable) do
			if page ~= pageToSwitchTo then
				page:Hide(-direction, newPagePos)
			end
		end

		if this.BottomButtonFrame then
			this.BottomButtonFrame.Visible = (pageToSwitchTo ~= this.ResetCharacterPage and pageToSwitchTo ~= this.LeaveGamePage)
			this.HubBar.Visible = this.BottomButtonFrame.Visible
		end

		-- make sure page is visible
		this.Pages.CurrentPage = pageToSwitchTo
		this.Pages.CurrentPage:Display(this.PageView)
		this.Pages.CurrentPage.Active = true

		local pageSize = this.Pages.CurrentPage:GetSize()
		this.PageView.CanvasSize = UDim2.new(0,pageSize.X,0,pageSize.Y)

		pageChangeCon = this.Pages.CurrentPage.Page.Changed:connect(function(prop)
			if prop == "AbsoluteSize" then
				local pageSize = this.Pages.CurrentPage:GetSize()
				this.PageView.CanvasSize = UDim2.new(0,pageSize.X,0,pageSize.Y)
			end
		end)

		if this.MenuStack[#this.MenuStack] ~= this.Pages.CurrentPage and not ignoreStack then
			this.MenuStack[#this.MenuStack + 1] = this.Pages.CurrentPage
		end
	end

	function this:SetActive(active)
		this.Active = active

		if this.Pages.CurrentPage then
			this.Pages.CurrentPage.Active = active
		end
	end

	function clearMenuStack()
		while this.MenuStack and #this.MenuStack > 0 do
			this:PopMenu()
		end
	end

	function setOverrideMouseIconBehavior()
		pcall(function()
			if UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1 then
				UserInputService.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.ForceHide
			else
				UserInputService.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.ForceShow
			end
		end)
	end

	function setVisibilityInternal(visible, noAnimation, customStartPage)
		this.Visible = visible

		this.SettingsShowSignal:fire(this.Visible)

		if this.Visible then
			this.Shield.Visible = this.Visible
			if noAnimation then
				this.Shield.Position = SETTINGS_SHIELD_ACTIVE_POSITION
			else
				this.Shield:TweenPosition(SETTINGS_SHIELD_ACTIVE_POSITION, Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, 0.5, true)
			end

			local noOpFunc = function() end
			ContextActionService:BindCoreAction("RbxSettingsHubStopCharacter", noOpFunc, false,
												 Enum.PlayerActions.CharacterForward, 
												 Enum.PlayerActions.CharacterBackward, 
												 Enum.PlayerActions.CharacterLeft,
												 Enum.PlayerActions.CharacterRight,
												 Enum.PlayerActions.CharacterJump, 
												 Enum.UserInputType.Gamepad1, Enum.UserInputType.Gamepad2, Enum.UserInputType.Gamepad3, Enum.UserInputType.Gamepad4)

			ContextActionService:BindCoreAction("RbxSettingsHubSwitchTab", switchTabFunc, false, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonL1, Enum.KeyCode.Tab)
			setBottomBarBindings()

			setOverrideMouseIconBehavior()
			pcall(function() lastInputChangedCon = UserInputService.LastInputTypeChanged:connect(setOverrideMouseIconBehavior) end)

			pcall(function() PlatformService.BlurIntensity = 10 end)

			if customStartPage then
				this:SwitchToPage(customStartPage, nil, 1)
			else
				if this.HomePage then
					this:SwitchToPage(this.HomePage, nil, 1)
				else
					this:SwitchToPage(this.GameSettingsPage, nil, 1)
				end
			end

			if playerList:IsOpen() then
				playerList:ToggleVisibility()
			end

			if chat:GetVisibility() then
				chat:ToggleVisibility()
			end

			if backpack.IsOpen then
				backpack:OpenClose()
			end
		else
			if noAnimation then
				this.Shield.Position = SETTINGS_SHIELD_INACTIVE_POSITION
				this.Shield.Visible = this.Visible
			else
				this.Shield:TweenPosition(SETTINGS_SHIELD_INACTIVE_POSITION, Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.4, true, function()
					this.Shield.Visible = this.Visible
				end)
			end

			if lastInputChangedCon then
				lastInputChangedCon:disconnect()
			end

			pcall(function() UserInputService.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.None end)
			pcall(function() PlatformService.BlurIntensity = 0 end)

			clearMenuStack()
			ContextActionService:UnbindCoreAction("RbxSettingsHubSwitchTab")
			ContextActionService:UnbindCoreAction("RbxSettingsHubStopCharacter")
			removeBottomBarBindings()

			game.GuiService.SelectedCoreObject = nil
		end

	end

	function this:SetVisibility(visible, noAnimation, customStartPage)
		if this.Visible == visible then return end

		setVisibilityInternal(visible, noAnimation, customStartPage)
	end

	function this:ToggleVisibility()
		setVisibilityInternal(not this.Visible)
	end

	function this:AddToMenuStack(newItem)
		if this.MenuStack[#this.MenuStack] ~= newItem then
			this.MenuStack[#this.MenuStack + 1] = newItem
		end
	end


	function this:PopMenu()
		if this.MenuStack and #this.MenuStack > 0 then
			local lastStackItem = this.MenuStack[#this.MenuStack]

			if type(lastStackItem) ~= "table" then
				PoppedMenuEvent:Fire(lastStackItem)
			end

			if lastStackItem == this.LeaveGamePage or lastStackItem == this.ResetCharacterPage then
				setBottomBarBindings()
			end

			table.remove(this.MenuStack, #this.MenuStack)
			this:SwitchToPage(this.MenuStack[#this.MenuStack], true, 1)
			if #this.MenuStack == 0 then
				this:SetVisibility(false)
				this.Pages.CurrentPage:Hide(0,0)
			end
		else
			this.MenuStack = {}
			PoppedMenuEvent:Fire()
			this:ToggleVisibility()
		end
	end

	function this:ShowShield()
		this.Shield.BackgroundTransparency = SETTINGS_SHIELD_TRANSPARENCY
	end
	function this:HideShield()
		this.Shield.BackgroundTransparency = 1
	end

	local closeMenuFunc = function(name, inputState, input)
		if inputState ~= Enum.UserInputState.Begin then return end
		this:PopMenu()
	end
	ContextActionService:BindCoreAction("RBXEscapeMainMenu", closeMenuFunc, false, Enum.KeyCode.Escape)
	
	this.ResetCharacterPage:SetHub(this)
	this.LeaveGamePage:SetHub(this)

	-- full page initialization
	if utility:IsSmallTouchScreen() then
		this.HomePage = require(RobloxGui.Modules.Settings.Pages.Home)
		this.HomePage:SetHub(this)
	end

	this.GameSettingsPage = require(RobloxGui.Modules.Settings.Pages.GameSettings)
	this.GameSettingsPage:SetHub(this)

	if platform ~= Enum.Platform.XBoxOne and platform ~= Enum.Platform.PS4 then
		this.ReportAbusePage = require(RobloxGui.Modules.Settings.Pages.ReportAbuseMenu)
		this.ReportAbusePage:SetHub(this)
	end

	this.HelpPage = require(RobloxGui.Modules.Settings.Pages.Help)
	this.HelpPage:SetHub(this)

	if platform == Enum.Platform.Windows then
		this.RecordPage = require(RobloxGui.Modules.Settings.Pages.Record)
		this.RecordPage:SetHub(this)
	end

	-- page registration
	this:AddPage(this.ResetCharacterPage)
	this:AddPage(this.LeaveGamePage)
	if this.HomePage then
		this:AddPage(this.HomePage)
	end
	this:AddPage(this.GameSettingsPage)
	if this.ReportAbusePage then
		this:AddPage(this.ReportAbusePage)
	end
	this:AddPage(this.HelpPage)
	if this.RecordPage then
		this:AddPage(this.RecordPage)
	end

	if this.HomePage then
		this:SwitchToPage(this.HomePage, true, 1)
	else
		this:SwitchToPage(this.GameSettingsPage, true, 1)
	end
	-- hook up to necessary signals

	-- connect back button on android
	GuiService.ShowLeaveConfirmation:connect(function()
		if #this.MenuStack == 0 then
			this:SwitchToPage(this.LeaveGamePage, nil, 1)
		else
			this:SetVisibility(false)
			this:PopMenu()
		end
	end)

	-- Dev Console Connections
	ContextActionService:BindCoreAction(DEV_CONSOLE_ACTION_NAME, toggleDevConsole, false, Enum.KeyCode.F9)

	return this
end


-- Main Entry Point

local moduleApiTable = {}

	local SettingsHubInstance = CreateSettingsHub()

	function moduleApiTable:SetVisibility(visible, noAnimation, customStartPage)
		SettingsHubInstance:SetVisibility(visible, noAnimation, customStartPage)
	end

	function moduleApiTable:ToggleVisibility()
		SettingsHubInstance:ToggleVisibility()
	end

	function moduleApiTable:SwitchToPage(pageToSwitchTo, ignoreStack)
		SettingsHubInstance:SwitchToPage(pageToSwitchTo, ignoreStack, 1)
	end

	function moduleApiTable:GetVisibility()
		return SettingsHubInstance.Visible
	end

	function moduleApiTable:ShowShield()
		SettingsHubInstance:ShowShield()
	end

	function moduleApiTable:HideShield()
		SettingsHubInstance:HideShield()
	end

	moduleApiTable.SettingsShowSignal = SettingsHubInstance.SettingsShowSignal

return moduleApiTable