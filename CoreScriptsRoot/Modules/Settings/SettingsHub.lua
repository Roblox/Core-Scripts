--[[
		Filename: SettingsHub.lua
		Written by: jeditkacheff
		Version 1.0
		Description: Controls the settings menu navigation and contains the settings pages
--]]

--[[ CONSTANTS ]]

local SETTINGS_SHIELD_COLOR = Color3.new(41/255,41/255,41/255)
local SETTINGS_SHIELD_TRANSPARENCY = 0.2
local SETTINGS_SHIELD_SIZE = UDim2.new(1, 0, 1, -2)
local SETTINGS_SHIELD_INACTIVE_POSITION = UDim2.new(0,0,-1,-36)
local SETTINGS_SHIELD_ACTIVE_POSITION = UDim2.new(0, 0, 0, 2)
local SETTINGS_BASE_ZINDEX = 2
local DEV_CONSOLE_ACTION_NAME = "Open Dev Console"

--[[ SERVICES ]]
local CoreGui = game:GetService("CoreGui")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

--[[ VARIABLES ]]
local isTouchDevice = UserInputService.TouchEnabled
local platform = UserInputService:GetPlatform()
-- TODO: Change dev console script to parent this to somewhere other than an engine created gui
local ControlFrame = RobloxGui:WaitForChild('ControlFrame')
local ToggleDevConsoleBindableFunc = ControlFrame:WaitForChild('ToggleDevConsole')

--[[ UTILITIES ]]
local utility = require(RobloxGui.Modules.Utility)

--[[ CORE MODULES ]]
local playerList = require(RobloxGui.Modules.PlayerlistModule)
local chat = require(RobloxGui.Modules.Chat)
local backpack = require(RobloxGui.Modules.BackpackScript)

local function CreateSettingsHub()
	local this = {}
	this.Visible = false
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
	end

	local function removeBottomBarBindings()
		for _, hotKeyTable in pairs(this.BottomBarButtons) do
			ContextActionService:UnbindCoreAction(hotKeyTable[1])
		end
	end
			

	local function addBottomBarButton(name, text, gamepadImage, keyboardString, position, clickFunc, hotkeys)
		local buttonName = name .. "Button"
		local textName = name .. "Text"

		this[buttonName], this[textName] = utility:MakeStyledButton(name .. "Button", text, UDim2.new(0,260,0,70), clickFunc)
		this[buttonName].Position = position
		this[buttonName].Parent = this.BottomButtonFrame
		if platform == Enum.Platform.XBoxOne or  UserInputService:GetPlatform() == Enum.Platform.AndroidTV then
			this[buttonName].ImageTransparency = 1
		end

		this[textName].FontSize = Enum.FontSize.Size24
		local hintLabel = nil
		local hintLabelText = nil

		if not UserInputService.TouchEnabled then
			this[textName].Size = UDim2.new(1,0,1,0)
			this[textName].Position = UDim2.new(0,10,0,-4)

			local hintNameText = name .. "HintText"
			local hintName = name .. "Hint"
			local image = ""
			if UserInputService:GetGamepadConnected(Enum.UserInputType.Gamepad1) then
				image = gamepadImage
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

			hintLabelText= utility:Create'TextLabel'
			{
				Name = hintName .. "Text",
				Text = keyboardString,
				Font = Enum.Font.SourceSans,
				FontSize = Enum.FontSize.Size36,
				TextColor3 = Color3.new(0.9,0.9,0.9),
				TextWrapped = true,
				Size = UDim2.new(0,60,0,60),
				Position = UDim2.new(0,10,0,0),
				ZIndex = this.Shield.ZIndex + 2,
				BackgroundTransparency = 1,
				Visible = (image == ""),
				Parent = this[buttonName]
			};
		end

		UserInputService.InputBegan:connect(function(inputObject)
			if inputObject.UserInputType == Enum.UserInputType.Gamepad1 or inputObject.UserInputType == Enum.UserInputType.Gamepad2 or
				inputObject.UserInputType == Enum.UserInputType.Gamepad3 or inputObject.UserInputType == Enum.UserInputType.Gamepad4 then
					if hintLabel then
						hintLabel.Image = gamepadImage
						hintLabelText.Visible = false
					end
			elseif inputObject.UserInputType == Enum.UserInputType.Keyboard then
				if hintLabel then
					hintLabel.Image = ""
					hintLabelText.Visible = true
				end
			end
		end)

		local hotKeyFunc = function(contextName, inputState, inputObject)
			if inputState ~= Enum.UserInputState.Begin then return end
			clickFunc()
		end

		local hotKeyTable = {hotKeyFunc, hotkeys}
		this.BottomBarButtons[#this.BottomBarButtons + 1] = {buttonName, hotKeyTable}
	end

	local function createGui()
		local PageViewSizeReducer = 140
		if utility:IsSmallTouchScreen() then
			PageViewSizeReducer = 5
		end

		this.Shield = utility:Create'Frame'
		{
			Name = "SettingsShield",
			Size = SETTINGS_SHIELD_SIZE,
			Position = SETTINGS_SHIELD_INACTIVE_POSITION,
			BackgroundTransparency = SETTINGS_SHIELD_TRANSPARENCY,
			BackgroundColor3 = SETTINGS_SHIELD_COLOR,
			BorderSizePixel = 0,
			Visible = false,
			Active = true,
			ZIndex = SETTINGS_BASE_ZINDEX,
			Parent = RobloxGui
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
		
		if utility:IsSmallTouchScreen() then
			this.HubBar.Size = UDim2.new(1,-10,0,36)
			this.HubBar.Position = UDim2.new(0,5,0,6)
		else
			this.HubBar.Size = UDim2.new(0,800,0,60)
			this.HubBar.Position = UDim2.new(0.5,-400,0.05,0)
		end

		this.PageView = utility:Create'ScrollingFrame'
		{
			Name = "PageView",
			Size = UDim2.new(this.HubBar.Size.X.Scale,this.HubBar.Size.X.Offset,
				 				1, -this.HubBar.Size.Y.Offset - this.HubBar.Position.Y.Offset - PageViewSizeReducer),
			Position = UDim2.new(this.HubBar.Position.X.Scale, this.HubBar.Position.X.Offset,
												this.HubBar.Position.Y.Scale, this.HubBar.Position.Y.Offset + this.HubBar.Size.Y.Offset + 1),
			ZIndex = this.Shield.ZIndex,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Selectable = false,
			Parent = this.Shield
		};
		if utility:IsSmallTouchScreen() then
			this.PageView.CanvasSize = this.PageView.Size
		else
			local bottomOffset = 20
			if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
				bottomOffset = 80
			end
			this.BottomButtonFrame = utility:Create'Frame'
			{
				Name = "BottomButtonFrame",
				Size = this.HubBar.Size,
				Position = UDim2.new(0.5, -this.HubBar.Size.X.Offset/2, 1, -this.HubBar.Size.Y.Offset - bottomOffset),
				ZIndex = this.Shield.ZIndex + 1,
				BackgroundTransparency = 1,
				Parent = this.Shield
			};

			local leaveGameFunc = function()
				this:AddToMenuStack(this.Pages.CurrentPage)
				this.BottomButtonFrame.Visible = false
				this.HubBar.Visible = false
				this:SwitchToPage(this.LeaveGamePage, nil, 1)
			end

			local resetCharFunc = function()
				this:AddToMenuStack(this.Pages.CurrentPage)
				this.BottomButtonFrame.Visible = false
				this.HubBar.Visible = false
				this:SwitchToPage(this.ResetCharacterPage, nil, 1)
			end

			local resumeFunc = function()
				this:SetVisibility(false)
			end

			addBottomBarButton("LeaveGame", "Leave Game", "rbxasset://textures/ui/Settings/Help/XButtonLight.png", 
				"L", UDim2.new(0.5,-130,0.5,-25), 
				leaveGameFunc, {Enum.KeyCode.L, Enum.KeyCode.ButtonX})
			addBottomBarButton("ResetCharacter", "Reset Character", "rbxasset://textures/ui/Settings/Help/YButtonLight.png", 
				"R", UDim2.new(0.5,-400,0.5,-25), 
				resetCharFunc, {Enum.KeyCode.R, Enum.KeyCode.ButtonY})
			addBottomBarButton("Resume", "Resume", "rbxasset://textures/ui/Settings/Help/BButtonLight.png",
				"Esc", UDim2.new(0.5,140,0.5,-25), 
				resumeFunc, {Enum.KeyCode.ButtonB, Enum.KeyCode.ButtonStart})
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
		if inputObject.KeyCode == Enum.KeyCode.ButtonR1 or inputObject.KeyCode == Enum.KeyCode.E then 
			direction = 1
		elseif inputObject.KeyCode == Enum.KeyCode.ButtonL1 or inputObject.KeyCode == Enum.KeyCode.Q then 
			direction = -1
		end

		local currentTabPosition = GetHeaderPosition(this.Pages.CurrentPage)
		if currentTabPosition < 0 then return end

		local newTabPosition = currentTabPosition + direction
		local newHeader = this.TabHeaders[newTabPosition]

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

	function this:SwitchToPage(pageToSwitchTo, ignoreStack, direction)
		if this.Pages.PageTable[pageToSwitchTo] == nil then return end

		-- if we have a page we need to let it know to go away
		if this.Pages.CurrentPage then
			pageChangeCon:disconnect()
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

	function setVisibilityInternal(visible, noAnimation)
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
												 Enum.UserInputType.Keyboard, Enum.UserInputType.Gamepad1,
												 Enum.UserInputType.Gamepad2, Enum.UserInputType.Gamepad3, Enum.UserInputType.Gamepad4)

			ContextActionService:BindCoreAction("RbxSettingsHubSwitchTab", switchTabFunc, false, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonL1, Enum.KeyCode.Q, Enum.KeyCode.E)
			setBottomBarBindings()

			if this.HomePage then
				this:SwitchToPage(this.HomePage, nil, 1)
			else
				this:SwitchToPage(this.GameSettingsPage, nil, 1)
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

			this.MenuStack = {}
			game.GuiService.SelectedCoreObject = nil
			ContextActionService:UnbindCoreAction("RbxSettingsHubSwitchTab")
			ContextActionService:UnbindCoreAction("RbxSettingsHubStopCharacter")
			removeBottomBarBindings()
		end

	end

	function this:SetVisibility(visible, noAnimation)
		if this.Visible == visible then return end

		setVisibilityInternal(visible, noAnimation)
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

			table.remove(this.MenuStack, #this.MenuStack)
			this:SwitchToPage(this.MenuStack[#this.MenuStack], true, 1)
			if #this.MenuStack == 0 then
				this:ToggleVisibility()
			end
		else
			this.MenuStack = {}
			PoppedMenuEvent:Fire()
			this:ToggleVisibility()
		end
	end

	function this:ShowShield()
		this.PageView.ClipsDescendants = true
		this.Shield.BackgroundTransparency = SETTINGS_SHIELD_TRANSPARENCY
	end
	function this:HideShield()
		--this.PageView.ClipsDescendants = false
		this.Shield.BackgroundTransparency = 1
	end

	GuiService.EscapeKeyPressed:connect(function()
		this:PopMenu()
	end)

	this.ResetCharacterPage:SetHub(this)
	this.LeaveGamePage:SetHub(this)

	-- full page initialization
	if utility:IsSmallTouchScreen() then
		this.HomePage = require(RobloxGui.Modules.Settings.Pages.Home)
		this.HomePage:SetHub(this)
	end

	this.GameSettingsPage = require(RobloxGui.Modules.Settings.Pages.GameSettings)
	this.GameSettingsPage:SetHub(this)

	this.ReportAbusePage = require(RobloxGui.Modules.Settings.Pages.ReportAbuseMenu)
	this.ReportAbusePage:SetHub(this)

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
	this:AddPage(this.ReportAbusePage)
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

	function moduleApiTable:SetVisibility(visible, noAnimation)
		SettingsHubInstance:SetVisibility(visible, noAnimation)
	end

	function moduleApiTable:ToggleVisibility()
		SettingsHubInstance:ToggleVisibility()
	end

	function moduleApiTable:SwitchToPage(pageToSwitchTo)
		SettingsHubInstance:SwitchToPage(pageToSwitchTo, nil, 1)
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