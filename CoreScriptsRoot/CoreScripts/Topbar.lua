--[[
	// FileName: Topbar.lua
	// Written by: SolarCrane
	// Description: Code for lua side Top Menu items in ROBLOX.
]]


--[[ CONSTANTS ]]

local TOPBAR_THICKNESS = 36
local USERNAME_CONTAINER_WIDTH = 170
local COLUMN_WIDTH = 75
local NAME_LEADERBOARD_SEP_WIDTH = 2

local FONT_COLOR = Color3.new(1,1,1)
local TOPBAR_BACKGROUND_COLOR = Color3.new(31/255,31/255,31/255)
local TOPBAR_OPAQUE_TRANSPARENCY = 0
local TOPBAR_TRANSLUCENT_TRANSPARENCY = 0.5

local HEALTH_BACKGROUND_COLOR = Color3.new(228/255, 236/255, 246/255)
local HEALTH_RED_COLOR = Color3.new(255/255, 28/255, 0/255)
local HEALTH_YELLOW_COLOR = Color3.new(250/255, 235/255, 0)
local HEALTH_GREEN_COLOR = Color3.new(27/255, 252/255, 107/255)

local HEALTH_PERCANTAGE_FOR_OVERLAY = 5 / 100

local HURT_OVERLAY_IMAGE = "http://www.roblox.com/asset/?id=34854607"

local DEBOUNCE_TIME = 0.25

--[[ END OF CONSTANTS ]]

--[[ FFLAG VALUES ]]
local newSettingsSuccess, newSettingsFlagValue = pcall(function() return settings():GetFFlag("NewMenuSettingsScript") end)
local useNewSettings = newSettingsSuccess and newSettingsFlagValue

local backPackSuccess, backpackFlagValue = pcall(function() return settings():GetFFlag("NewBackpackScript") end)
local useNewBackpack = (backPackSuccess and backpackFlagValue)

local playerListSuccess, playerListFlagValue = pcall(function() return settings():GetFFlag("NewPlayerListScript") end)
local useNewPlayerlist = (playerListSuccess and playerListFlagValue)

local function GetBubbleChatbarFlag()
	local bubbleChatbarSuccess, bubbleChatbarFlagValue = pcall(function() return settings():GetFFlag("BubbleChatbarDocksAtTop") end)
	return bubbleChatbarSuccess and bubbleChatbarFlagValue == true
end

local function GetChatVisibleIconFlag()
	local chatVisibleIconSuccess, chatVisibleIconFlagValue = pcall(function() return settings():GetFFlag("MobileToggleChatVisibleIcon") end)
	return chatVisibleIconSuccess and chatVisibleIconFlagValue == true
end
--[[ END OF FFLAG VALUES ]]


--[[ SERVICES ]]

local CoreGuiService = game:GetService('CoreGui')
local PlayersService = game:GetService('Players')
local GuiService = game:GetService('GuiService')
local InputService = game:GetService('UserInputService')
local StarterGui = game:GetService('StarterGui')

--[[ END OF SERVICES ]]


local GameSettings = UserSettings().GameSettings
local Player = PlayersService.LocalPlayer
while Player == nil do
	wait()
	Player = PlayersService.LocalPlayer
end

local GuiRoot = CoreGuiService:WaitForChild('RobloxGui')

local Util = {}
do
	-- Check if we are running on a touch device
	function Util.IsTouchDevice()
		return InputService.TouchEnabled
	end

	function Util.Create(instanceType)
		return function(data)
			local obj = Instance.new(instanceType)
			for k, v in pairs(data) do
				if type(k) == 'number' then
					v.Parent = obj
				else
					obj[k] = v
				end
			end
			return obj
		end
	end

	function Util.Clamp(low, high, input)
		return math.max(low, math.min(high, input))
	end

	function Util.DisconnectEvent(conn)
		if conn then
			conn:disconnect()
		end
		return nil
	end

	function Util.SetGUIInsetBounds(x1, y1, x2, y2)
		GuiService:SetGlobalGuiInset(x1, y1, x2, y2)
	end

	local humanoidCache = {}
	function Util.FindPlayerHumanoid(player)
		local character = player and player.Character
		if character then
			local resultHumanoid = humanoidCache[player]
			if resultHumanoid and resultHumanoid.Parent == character then
				return resultHumanoid
			else
				humanoidCache[player] = nil -- Bust Old Cache
				for _, child in pairs(character:GetChildren()) do
					if child:IsA('Humanoid') then
						humanoidCache[player] = child
						return child
					end
				end
			end
		end
	end
end

local function CreateTopBar()
	local this = {}

	local playerGuiChangedConn = nil

	local topbarContainer = Util.Create'Frame'{
		Name = "TopBarContainer";
		Size = UDim2.new(1, 0, 0, TOPBAR_THICKNESS);
		Position = UDim2.new(0, 0, 0, -TOPBAR_THICKNESS);
		BackgroundTransparency = TOPBAR_OPAQUE_TRANSPARENCY;
		BackgroundColor3 = TOPBAR_BACKGROUND_COLOR;
		BorderSizePixel = 0;
		Active = true;
		Parent = GuiRoot;
	};

	local topbarShadow = Util.Create'ImageLabel'{
		Name = "TopBarShadow";
		Size = UDim2.new(1, 0, 0, 3);
		Position = UDim2.new(0, 0, 1, 0);
		Image = "rbxasset://textures/ui/TopBar/dropshadow.png";
		BackgroundTransparency = 1;
		Active = false;
		Visible = false;
		Parent = topbarContainer;
	};

	local function UpdateBackgroundTransparency()
		local playerGui = Player:FindFirstChild('PlayerGui')
		if playerGui then
			pcall(function()
				topbarContainer.BackgroundTransparency = playerGui:GetTopbarTransparency()
			end)
			topbarShadow.Visible = (topbarContainer.BackgroundTransparency == 0)
		end
	end

	function this:GetInstance()
		return topbarContainer
	end

	function this:SetTopbarDisplayMode(opaque)
		topbarContainer.BackgroundTransparency = opaque and TOPBAR_OPAQUE_TRANSPARENCY or TOPBAR_TRANSLUCENT_TRANSPARENCY
		topbarShadow.Visible = not opaque
		UpdateBackgroundTransparency()
	end

	spawn(function()
		local playerGui = Player:WaitForChild('PlayerGui')
		playerGuiChangedConn = Util.DisconnectEvent(playerGuiChangedConn)
		pcall(function()
			playerGuiChangedConn = playerGui.TopbarTransparencyChangedSignal:connect(UpdateBackgroundTransparency)
		end)
		UpdateBackgroundTransparency()
	end)

	return this
end

local function CreateMenuBar(barAlignment)
	local this = {}
	local thickness = TOPBAR_THICKNESS
	local alignment = (barAlignment == 'Right' and 'Right' or 'Left')
	local items = {}
	local propertyChangedConnections = {}
	local dock = nil

	local function ArrangeItems()
		local totalWidth = 0
		for i, item in pairs(items) do
			local width = item:GetWidth()
			if alignment == 'Left' then
				item.Position = UDim2.new(0, totalWidth, 0, 0)
			else -- Right
				item.Position = UDim2.new(1, -totalWidth - width, 0, 0)
			end

			totalWidth = totalWidth + width
		end
	end

	function this:GetThickness()
		return thickness
	end

	function this:GetNumberOfItems()
		return #items
	end

	function this:SetDock(newDock)
		dock = newDock
		for _, item in pairs(items) do
			item.Parent = dock
		end
	end

	function this:IndexOfItem(searchItem)
		for index, item in pairs(items) do
			if item == searchItem then
				return index
			end
		end
		return nil
	end

	function this:ItemAtIndex(index)
		return items[index]
	end

	function this:AddItem(item, index)
		local numItems = self:GetNumberOfItems()
		index = Util.Clamp(1, numItems + 1, (index or numItems + 1))

		local alreadyFoundIndex = self:IndexOfItem(item)
		if alreadyFoundIndex then
			return item, index
		end

		table.insert(items, index, item)
		Util.DisconnectEvent(propertyChangedConnections[item])
		propertyChangedConnections[item] = item.Changed:connect(function(property)
			if property == 'AbsoluteSize' then
				ArrangeItems()
			end
		end)
		ArrangeItems()

		if dock then
			item.Parent = dock
		end

		return item, index
	end

	function this:RemoveItem(item)
		local index = self:IndexOfItem(item)
		if index then
			local removedItem = table.remove(items, index)

			removedItem.Parent = nil
			Util.DisconnectEvent(propertyChangedConnections[removedItem])

			ArrangeItems()
			return removedItem, index
		end
	end


	return this
end

local function CreateMenuItem(origInstance)
	local this = {}
	local instance = origInstance

	function this:SetInstance(newInstance)
		if not instance then
			instance = newInstance
		else
			print("Trying to set an Instance of a Menu Item that already has an instance; doing nothing.")
		end
	end

	function this:GetWidth()
		return self.Size.X.Offset
	end

	-- We are extending a regular instance.
	do
		local mt =
		{
			__index = function (t, k)
				return instance[k]
			end;

			__newindex = function (t, k, v)
				--if instance[k] ~= nil then
					instance[k] = v
				--else
				--	rawset(t, k, v)
				--end
			end;
		}
		setmetatable(this, mt)
	end

	return this
end


----- HEALTH -----
local function CreateUsernameHealthMenuItem()
	local container = Util.Create'ImageButton'
	{
		Name = "NameHealthContainer";
		Size = UDim2.new(0, USERNAME_CONTAINER_WIDTH, 1, 0);
		AutoButtonColor = false;
		Image = "";
		BackgroundTransparency = 1;
	}

	local username = Util.Create'TextLabel'{
		Name = "Username";
		Text = Player.Name;
		Size = UDim2.new(1, -14, 0, 22);
		Position = UDim2.new(0, 7, 0, 0);
		Font = Enum.Font.SourceSansBold;
		FontSize = Enum.FontSize.Size14;
		BackgroundTransparency = 1;
		TextColor3 = FONT_COLOR;
		TextYAlignment = Enum.TextYAlignment.Bottom;
		TextXAlignment = Enum.TextXAlignment.Left;
		Parent = container;
	};

	local healthContainer = Util.Create'Frame'{
		Name = "HealthContainer";
		Size = UDim2.new(1, -14, 0, 3);
		Position = UDim2.new(0, 7, 1, -9);
		BorderSizePixel = 0;
		BackgroundColor3 = HEALTH_BACKGROUND_COLOR;
		Parent = container;
	};

	local healthFill = Util.Create'Frame'{
		Name = "HealthFill";
		Size = UDim2.new(1, 0, 1, 0);
		BorderSizePixel = 0;
		BackgroundColor3 = HEALTH_GREEN_COLOR;
		Parent = healthContainer;
	};

	local hurtOverlay = Util.Create'ImageLabel'
	{
		Name = "HurtOverlay";
		BackgroundTransparency = 1;
		Image = HURT_OVERLAY_IMAGE;
		Position = UDim2.new(-10,0,-10,0);
		Size = UDim2.new(20,0,20,0);
		Visible = false;
		Parent = GuiRoot;
	};

	local this = CreateMenuItem(container)

	--- EVENTS ---
	local humanoidChangedConn, childAddedConn, childRemovedConn = nil
	--------------

	local function AnimateHurtOverlay()
		if hurtOverlay then
			local newSize = UDim2.new(20, 0, 20, 0)
			local newPos = UDim2.new(-10, 0, -10, 0)

			if hurtOverlay:IsDescendantOf(game) then
				-- stop any tweens on overlay
				hurtOverlay:TweenSizeAndPosition(newSize, newPos, Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0, true, function()
					-- show the gui
					hurtOverlay.Size = UDim2.new(1,0,1,0)
					hurtOverlay.Position = UDim2.new(0,0,0,0)
					hurtOverlay.Visible = true
					-- now tween the hide
					if hurtOverlay:IsDescendantOf(game) then
						hurtOverlay:TweenSizeAndPosition(newSize, newPos, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 10, false, function()
							hurtOverlay.Visible = false
						end)
					else
						hurtOverlay.Size = newSize
						hurtOverlay.Position = newPos
					end
				end)
			else
				hurtOverlay.Size = newSize
				hurtOverlay.Position = newPos
			end
		end
	end

	local healthColorToPosition = {
		[Vector3.new(HEALTH_RED_COLOR.r, HEALTH_RED_COLOR.g, HEALTH_RED_COLOR.b)] = 0.1;
		[Vector3.new(HEALTH_YELLOW_COLOR.r, HEALTH_YELLOW_COLOR.g, HEALTH_YELLOW_COLOR.b)] = 0.5;
		[Vector3.new(HEALTH_GREEN_COLOR.r, HEALTH_GREEN_COLOR.g, HEALTH_GREEN_COLOR.b)] = 0.8;
	}
	local min = 0.1
	local minColor = HEALTH_RED_COLOR
	local max = 0.8
	local maxColor = HEALTH_GREEN_COLOR

	local function HealthbarColorTransferFunction(healthPercent)
		if healthPercent < min then
			return minColor
		elseif healthPercent > max then
			return maxColor
		end

		-- Shepard's Interpolation
		local numeratorSum = Vector3.new(0,0,0)
		local denominatorSum = 0
		for colorSampleValue, samplePoint in pairs(healthColorToPosition) do
			local distance = healthPercent - samplePoint
			if distance == 0 then
				-- If we are exactly on an existing sample value then we don't need to interpolate
				return Color3.new(colorSampleValue.x, colorSampleValue.y, colorSampleValue.z)
			else
				local wi = 1 / (distance*distance)
				numeratorSum = numeratorSum + wi * colorSampleValue
				denominatorSum = denominatorSum + wi
			end
		end
		local result = numeratorSum / denominatorSum
		return Color3.new(result.x, result.y, result.z)
	end

	local function OnHumanoidAdded(humanoid)
		local lastHealth = humanoid.Health
		local function OnHumanoidHealthChanged(health)
			if humanoid then
				local healthDelta = lastHealth - health
				local healthPercent = health / humanoid.MaxHealth
				if humanoid.MaxHealth <= 0 then
					healthPercent = 0
				end
				healthPercent = Util.Clamp(0, 1, healthPercent)
				local healthColor = HealthbarColorTransferFunction(healthPercent)
				local thresholdForHurtOverlay = humanoid.MaxHealth * HEALTH_PERCANTAGE_FOR_OVERLAY

				if healthDelta >= thresholdForHurtOverlay and health ~= humanoid.MaxHealth then
					AnimateHurtOverlay()
				end
				healthFill.BackgroundColor3 = healthColor
				healthFill.Size = UDim2.new(healthPercent, 0, 1, 0)

				lastHealth = health
			end
		end
		Util.DisconnectEvent(humanoidChangedConn)
		humanoidChangedConn = humanoid.HealthChanged:connect(OnHumanoidHealthChanged)
		OnHumanoidHealthChanged(lastHealth)
	end

	local function OnCharacterAdded(character)
		local humanoid = Util.FindPlayerHumanoid(Player)
		if humanoid then
			OnHumanoidAdded(humanoid)
		end

		local function onChildAddedOrRemoved()
			local tempHumanoid = Util.FindPlayerHumanoid(Player)
			if tempHumanoid and tempHumanoid ~= humanoid then
				humanoid = tempHumanoid
				OnHumanoidAdded(humanoid)
			end
		end
		Util.DisconnectEvent(childAddedConn)
		Util.DisconnectEvent(childRemovedConn)
		childAddedConn = character.ChildAdded:connect(onChildAddedOrRemoved)
		childRemovedConn = character.ChildRemoved:connect(onChildAddedOrRemoved)
	end

	local mtStore = getmetatable(this)
	setmetatable(this, {})
	function this:SetHealthbarEnabled(enabled)
		healthContainer.Visible = enabled
		if enabled then
			username.Size = UDim2.new(1, -14, 0, 22);
			username.TextYAlignment = Enum.TextYAlignment.Bottom;
		else
			username.Size = UDim2.new(1, -14, 1, 0);
			username.TextYAlignment = Enum.TextYAlignment.Center;
		end
	end

	function this:SetNameVisible(visible)
		username.Visible = visible
	end

	setmetatable(this, mtStore)

	-- Don't need to disconnect this one because we never reconnect it.
	Player.CharacterAdded:connect(OnCharacterAdded)
	if Player.Character then
		OnCharacterAdded(Player.Character)
	end

	if useNewPlayerlist then
		local PlayerlistModule = require(GuiRoot.Modules.PlayerlistModule)
		container.MouseButton1Click:connect(function()
			PlayerlistModule.ToggleVisibility()
		end)
	end

	return this
end
----- END OF HEALTH -----

----- LEADERSTATS -----
local function CreateLeaderstatsMenuItem()
	local PlayerlistModule = require(GuiRoot.Modules.PlayerlistModule)

	local leaderstatsContainer = Util.Create'ImageButton'
	{
		Name = "LeaderstatsContainer";
		Size = UDim2.new(0, 0, 1, 0);
		AutoButtonColor = false;
		Image = "";
		BackgroundTransparency = 1;
	};

	local this = CreateMenuItem(leaderstatsContainer)
	local columns = {}

	local mtStore = getmetatable(this)
	setmetatable(this, {})
	function this:SetColumns(columnsList)
		-- Should we handle is the screen dimensions change and it is no longer a small touch device after we set columns?
		local isSmallTouchDevice = Util.IsTouchDevice() and GuiService:GetScreenResolution().Y < 500
		local numColumns = #columnsList

		-- Destroy old columns
		for _, oldColumn in pairs(columns) do
			oldColumn:Destroy()
		end
		columns = {}
		-- End destroy old columns
		local count = 0
		for index, columnData in pairs(columnsList) do  -- i = 1, numColumns do
			if not isSmallTouchDevice or index <= 1 then
				local columnName = columnData.Name
				local columnValue = columnData.Text

				local columnframe = Util.Create'Frame'
				{
					Name = "Column" .. tostring(index);
					Size = UDim2.new(0, COLUMN_WIDTH + (index == numColumns and 0 or NAME_LEADERBOARD_SEP_WIDTH), 1, 0);
					Position = UDim2.new(0, NAME_LEADERBOARD_SEP_WIDTH + (COLUMN_WIDTH + NAME_LEADERBOARD_SEP_WIDTH) * (index-1), 0, 0);
					BackgroundTransparency = 1;
					Parent = leaderstatsContainer;

					Util.Create'TextLabel'
					{
						Name = "ColumnName";
						Text = columnName;
						Size = UDim2.new(1, 0, 0, 10);
						Position = UDim2.new(0, 0, 0, 4);
						Font = Enum.Font.SourceSans;
						FontSize = Enum.FontSize.Size14;
						BorderSizePixel = 0;
						BackgroundTransparency = 1;
						TextColor3 = FONT_COLOR;
						TextYAlignment = Enum.TextYAlignment.Center;
						TextXAlignment = Enum.TextXAlignment.Center;
					};

					Util.Create'TextLabel'
					{
						Name = "ColumnValue";
						Text = columnValue;
						Size = UDim2.new(1, 0, 0, 10);
						Position = UDim2.new(0, 0, 0, 19);
						Font = Enum.Font.SourceSansBold;
						FontSize = Enum.FontSize.Size14;
						BorderSizePixel = 0;
						BackgroundTransparency = 1;
						TextColor3 = FONT_COLOR;
						TextYAlignment = Enum.TextYAlignment.Center;
						TextXAlignment = Enum.TextXAlignment.Center;
					};
				};
				columns[columnName] = columnframe
				count = count + 1
			end
		end
		leaderstatsContainer.Size = UDim2.new(0, COLUMN_WIDTH * count + NAME_LEADERBOARD_SEP_WIDTH * count, 1, 0)
	end

	function this:UpdateColumnValue(columnName, value)
		local column = columns[columnName]
		local columnValue = column and column:FindFirstChild('ColumnValue')
		if columnValue then
			columnValue.Text = tostring(value)
		end
	end
	setmetatable(this, mtStore)

	this:SetColumns(PlayerlistModule.GetStats())
	PlayerlistModule.OnLeaderstatsChanged.Event:connect(function(newStatColumns)
		this:SetColumns(newStatColumns)
	end)

	PlayerlistModule.OnStatChanged.Event:connect(function(statName, statValueAsString)
		this:UpdateColumnValue(statName, statValueAsString)
	end)

	leaderstatsContainer.MouseButton1Click:connect(function()
		PlayerlistModule.ToggleVisibility()
	end)

	return this
end
----- END OF LEADERSTATS -----

--- SETTINGS ---
local function CreateSettingsIcon()
	local MenuModule = require(game.CoreGui.RobloxGui.Modules.Settings2)

	local settingsIconButton = Util.Create'ImageButton'
	{
		Name = "Settings";
		Size = UDim2.new(0, 50, 0, TOPBAR_THICKNESS);
		Image = "";
		AutoButtonColor = false;
		BackgroundTransparency = 1;
	}

	local settingsIconImage = Util.Create'ImageLabel'
	{
		Name = "SettingsIcon";
		Size = UDim2.new(0, 32, 0, 25);
		Position = UDim2.new(0.5, -16, 0.5, -12);
		BackgroundTransparency = 1;
		Image = "rbxasset://textures/ui/Menu/Hamburger.png";
		Parent = settingsIconButton;
	};

	local settingsActive = false

	local function UpdateHamburgerIcon()
		if settingsActive then
			settingsIconImage.Image = "rbxasset://textures/ui/Menu/HamburgerDown.png";
		else
			settingsIconImage.Image = "rbxasset://textures/ui/Menu/Hamburger.png";
		end
	end

	local function toggleSettings()
		if settingsActive == false then
			settingsActive = true
		else
			settingsActive = false
		end

		MenuModule:ToggleVisibility(settingsActive)
		UpdateHamburgerIcon()

		return settingsActive
	end

	settingsIconButton.MouseButton1Click:connect(function() toggleSettings() end)

	MenuModule.SettingsShowSignal:connect(function(active)
		settingsActive = active
		UpdateHamburgerIcon()
	end)

	return CreateMenuItem(settingsIconButton)
end
------------

--- CHAT ---
local function CreateUnreadMessagesNotifier(ChatModule)
	local chatActive = false
	local lastMessageCount = 0

	local chatCounter = Util.Create'ImageLabel'
	{
		Name = "ChatCounter";
		Size = UDim2.new(0, 18, 0, 18);
		Position = UDim2.new(1, -12, 0, -4);
		BackgroundTransparency = 1;
		Image = "rbxasset://textures/ui/Chat/MessageCounter.png";
		Visible = false;
	};

	local chatCountText = Util.Create'TextLabel'
	{
		Name = "ChatCounterText";
		Text = '';
		Size = UDim2.new(0, 13, 0, 9);
		Position = UDim2.new(0.5, -7, 0.5, -7);
		Font = Enum.Font.SourceSansBold;
		FontSize = Enum.FontSize.Size14;
		BorderSizePixel = 0;
		BackgroundTransparency = 1;
		TextColor3 = FONT_COLOR;
		TextYAlignment = Enum.TextYAlignment.Center;
		TextXAlignment = Enum.TextXAlignment.Center;
		Parent = chatCounter;
	};

	local function OnUnreadMessagesChanged(count)
		if chatActive then
			lastMessageCount = count
		end
		local unreadCount = count - lastMessageCount

		if unreadCount <= 0 then
			chatCountText.Text = ""
			chatCounter.Visible = false
		else
			if unreadCount < 100 then
				chatCountText.Text = tostring(unreadCount)
			else
				chatCountText.Text = "!"
			end
			chatCounter.Visible = true
		end
	end

	local function onChatStateChanged(visible)
		chatActive = visible
		if ChatModule then
			OnUnreadMessagesChanged(ChatModule:GetMessageCount())
		end
	end


	if ChatModule then
		if ChatModule.VisibilityStateChanged then
			ChatModule.VisibilityStateChanged:connect(onChatStateChanged)
		end
		if ChatModule.MessagesChanged then
			ChatModule.MessagesChanged:connect(OnUnreadMessagesChanged)
		end

		onChatStateChanged(ChatModule:GetVisibility())
		OnUnreadMessagesChanged(ChatModule:GetMessageCount())
	end

	return chatCounter
end

local function CreateChatIcon()
	local ChatModule = require(GuiRoot.Modules.Chat)

	local bubbleChatIsOn = not PlayersService.ClassicChat and PlayersService.BubbleChat
	local debounce = 0

	local chatIconButton = Util.Create'ImageButton'
	{
		Name = "Chat";
		Size = UDim2.new(0, 50, 0, TOPBAR_THICKNESS);
		Image = "";
		AutoButtonColor = false;
		BackgroundTransparency = 1;
	};

	local chatIconImage = Util.Create'ImageLabel'
	{
		Name = "ChatIcon";
		Size = UDim2.new(0, 28, 0, 27);
		Position = UDim2.new(0.5, -14, 0.5, -13);
		BackgroundTransparency = 1;
		Image = "rbxasset://textures/ui/Chat/Chat.png";
		Parent = chatIconButton;
	};
	if not Util.IsTouchDevice() or not GetChatVisibleIconFlag() then
		local chatCounter = CreateUnreadMessagesNotifier(ChatModule)
		chatCounter.Parent = chatIconImage;
	end

	local function updateIcon(down)
		if down then
			chatIconImage.Image = "rbxasset://textures/ui/Chat/ChatDown.png";
		else
			chatIconImage.Image = "rbxasset://textures/ui/Chat/Chat.png";
		end
	end

	local function onChatStateChanged(visible)
		if not Util.IsTouchDevice() then
			updateIcon(visible)
		end
	end

	local function toggleChat()
		if Util.IsTouchDevice() or (GetBubbleChatbarFlag() and bubbleChatIsOn) then
			if debounce + DEBOUNCE_TIME < tick() then
				if Util.IsTouchDevice() and not ChatModule:GetVisibility() then
					ChatModule:ToggleVisibility()
				end
				ChatModule:FocusChatBar()
			end
		else
			ChatModule:ToggleVisibility()
		end
	end

	chatIconButton.MouseButton1Click:connect(function()
		toggleChat()
	end)

	if Util.IsTouchDevice() or (GetBubbleChatbarFlag() and bubbleChatIsOn) then
		if ChatModule.ChatBarFocusChanged then
			ChatModule.ChatBarFocusChanged:connect(function(isFocused)
				updateIcon(isFocused)
				debounce = tick()
			end)
		end
		updateIcon(false)
	end

	if ChatModule.VisibilityStateChanged then
		ChatModule.VisibilityStateChanged:connect(onChatStateChanged)
	end
	onChatStateChanged(ChatModule:GetVisibility())

	if not Util.IsTouchDevice() then
		ChatModule:ToggleVisibility(true)
	end

	return CreateMenuItem(chatIconButton)
end

local function CreateMobileHideChatIcon()
	local ChatModule = require(GuiRoot.Modules.Chat)

	local chatHideIconButton = Util.Create'ImageButton'
	{
		Name = "ChatVisible";
		Size = UDim2.new(0, 50, 0, TOPBAR_THICKNESS);
		Image = "";
		AutoButtonColor = false;
		BackgroundTransparency = 1;
	};

	local chatIconImage = Util.Create'ImageLabel'
	{
		Name = "ChatVisibleIcon";
		Size = UDim2.new(0, 28, 0, 27);
		Position = UDim2.new(0.5, -14, 0.5, -13);
		BackgroundTransparency = 1;
		Image = "rbxasset://textures/ui/Chat/ToggleChat.png";
		Parent = chatHideIconButton;
	};

	local unreadMessageNotifier = CreateUnreadMessagesNotifier(ChatModule)
	unreadMessageNotifier.Parent = chatIconImage

	local function updateIcon(down)
		if down then
			chatIconImage.Image = "rbxasset://textures/ui/Chat/ToggleChatDown.png";
		else
			chatIconImage.Image = "rbxasset://textures/ui/Chat/ToggleChat.png";
		end
	end

	local function toggleChat()
		ChatModule:ToggleVisibility()
	end

	local function onChatStateChanged(visible)
		updateIcon(visible)
	end

	chatHideIconButton.MouseButton1Click:connect(function()
		toggleChat()
	end)

	if ChatModule.VisibilityStateChanged then
		ChatModule.VisibilityStateChanged:connect(onChatStateChanged)
	end
	onChatStateChanged(ChatModule:GetVisibility())

	return CreateMenuItem(chatHideIconButton)
end

-----------

--- Backpack ---
local function CreateBackpackIcon()
	local BackpackModule = require(GuiRoot.Modules.BackpackScript)

	local backpackIconButton = Util.Create'ImageButton'
	{
		Name = "Backpack";
		Size = UDim2.new(0, 50, 0, TOPBAR_THICKNESS);
		Image = "";
		AutoButtonColor = false;
		BackgroundTransparency = 1;
	};

	local backpackIconImage = Util.Create'ImageLabel'
	{
		Name = "BackpackIcon";
		Size = UDim2.new(0, 22, 0, 28);
		Position = UDim2.new(0.5, -11, 0.5, -14);
		BackgroundTransparency = 1;
		Image = "rbxasset://textures/ui/Backpack/Backpack.png";
		Parent = backpackIconButton;
	};

	local function onBackpackStateChanged(open)
		if open then
			backpackIconImage.Image = "rbxasset://textures/ui/Backpack/Backpack_Down.png";
		else
			backpackIconImage.Image = "rbxasset://textures/ui/Backpack/Backpack.png";
		end
	end

	BackpackModule.StateChanged.Event:connect(onBackpackStateChanged)

	local function toggleBackpack()
		BackpackModule:OpenClose()
	end

	backpackIconButton.MouseButton1Click:connect(function()
		BackpackModule:OpenClose()
	end)

	return CreateMenuItem(backpackIconButton)
end
--------------

----- Stop Recording --
local function CreateStopRecordIcon()
	local stopRecordIconButton = Util.Create'ImageButton'
	{
		Name = "StopRecording";
		Size = UDim2.new(0, 50, 0, TOPBAR_THICKNESS);
		Image = "";
		Visible = true;
		BackgroundTransparency = 1;
	};
	stopRecordIconButton:SetVerb("RecordToggle")

	local stopRecordIconLabel = Util.Create'ImageLabel'
	{
		Name = "StopRecordingIcon";
		Size = UDim2.new(0, 28, 0, 28);
		Position = UDim2.new(0.5, -14, 0.5, -14);
		BackgroundTransparency = 1;
		Image = "rbxasset://textures/ui/RecordDown.png";
		Parent = stopRecordIconButton;
	};

	return CreateMenuItem(stopRecordIconButton)
end
-----------------------

----- Shift Lock ------
local function CreateShiftLockIcon()
	local shiftlockIconButton = Util.Create'ImageButton'
	{
		Name = "ShiftLock";
		Size = UDim2.new(0, 50, 0, TOPBAR_THICKNESS);
		AutoButtonColor = false;
		Image = "";
		BackgroundTransparency = 1;
	};

	local shiftlockIconLabel = Util.Create'ImageLabel'
	{
		Name = "ShiftlockIcon";
		Size = UDim2.new(0, 31, 0, 31);
		Position = UDim2.new(0.5, -15, 0.5, -15);
		BackgroundTransparency = 1;
		Image = "rbxasset://textures/ui/ShiftLock/ShiftLock.png";
		Parent = shiftlockIconButton;
	};

	local shiftlockActive = false
	shiftlockIconButton.MouseButton1Click:connect(function()
		if shiftlockActive == false then
			shiftlockActive = true
			shiftlockIconLabel.Image = "rbxasset://textures/ui/ShiftLock/ShiftLockDown.png";
		else
			shiftlockActive = false
			shiftlockIconLabel.Image = "rbxasset://textures/ui/ShiftLock/ShiftLock.png";
		end
	end)

	return CreateMenuItem(shiftlockIconButton)
end
----------------------

local settingsIcon = useNewSettings and CreateSettingsIcon()
local chatIcon = CreateChatIcon()
local mobileShowChatIcon = Util.IsTouchDevice() and CreateMobileHideChatIcon()
local backpackIcon = useNewBackpack and CreateBackpackIcon()
local shiftlockIcon = nil --CreateShiftLockIcon()
local nameAndHealthMenuItem = CreateUsernameHealthMenuItem()
local leaderstatsMenuItem = useNewPlayerlist and CreateLeaderstatsMenuItem()
local stopRecordingIcon = CreateStopRecordIcon()

local LeftMenubar = CreateMenuBar('Left')
local RightMenubar = CreateMenuBar('Right')

-- Set Item Orders
local LEFT_ITEM_ORDER = {}
if settingsIcon then
	LEFT_ITEM_ORDER[settingsIcon] = 1
end
if GetChatVisibleIconFlag() then
	if mobileShowChatIcon then
		LEFT_ITEM_ORDER[mobileShowChatIcon] = 2
	end
end
if chatIcon then
	LEFT_ITEM_ORDER[chatIcon] = 3
end
if backpackIcon then
	LEFT_ITEM_ORDER[backpackIcon] = 4
end
if shiftlockIcon then
	LEFT_ITEM_ORDER[shiftlockIcon] = 5
end
LEFT_ITEM_ORDER[stopRecordingIcon] = 6

local RIGHT_ITEM_ORDER = {}
if leaderstatsMenuItem then
	RIGHT_ITEM_ORDER[leaderstatsMenuItem] = 1
end
if nameAndHealthMenuItem then
	RIGHT_ITEM_ORDER[nameAndHealthMenuItem] = 2
end
-------------------------

local TopBar = CreateTopBar()

local function AddItemInOrder(Bar, Item, ItemOrder)
	local index = 1
	while ItemOrder[Bar:ItemAtIndex(index)] and ItemOrder[Bar:ItemAtIndex(index)] < ItemOrder[Item] do
		index = index + 1
	end
	Bar:AddItem(Item, index)
end

local function OnCoreGuiChanged(coreGuiType, enabled)
	if coreGuiType == Enum.CoreGuiType.PlayerList or coreGuiType == Enum.CoreGuiType.All then
		if leaderstatsMenuItem then
			if enabled then
				AddItemInOrder(RightMenubar, leaderstatsMenuItem, RIGHT_ITEM_ORDER)
			else
				RightMenubar:RemoveItem(leaderstatsMenuItem)
			end
		end
	end
	if coreGuiType == Enum.CoreGuiType.Health or coreGuiType == Enum.CoreGuiType.All then
		if nameAndHealthMenuItem then
			nameAndHealthMenuItem:SetHealthbarEnabled(enabled)
		end
	end
	if coreGuiType == Enum.CoreGuiType.Backpack or coreGuiType == Enum.CoreGuiType.All then
		if backpackIcon then
			if enabled then
				AddItemInOrder(LeftMenubar, backpackIcon, LEFT_ITEM_ORDER)
			else
				LeftMenubar:RemoveItem(backpackIcon)
			end
		end
	end
	if coreGuiType == Enum.CoreGuiType.Chat or coreGuiType == Enum.CoreGuiType.All then
		if enabled and Player.ChatMode == Enum.ChatMode.TextAndMenu then
			if chatIcon then
				AddItemInOrder(LeftMenubar, chatIcon, LEFT_ITEM_ORDER)
			end
			if mobileShowChatIcon then
				AddItemInOrder(LeftMenubar, mobileShowChatIcon, LEFT_ITEM_ORDER)
			end
		else
			if chatIcon then
				LeftMenubar:RemoveItem(chatIcon)
			end
			if mobileShowChatIcon then
				LeftMenubar:RemoveItem(mobileShowChatIcon)
			end
		end
	end

	if nameAndHealthMenuItem then
		local playerListOn = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
		local healthbarOn = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health)
		-- Left-align the player's name if either playerlist or healthbar is shown
		nameAndHealthMenuItem:SetNameVisible(playerListOn or healthbarOn)
	end
end

local function IsShiftLockModeEnabled()
	return GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch and
	       GameSettings.ComputerMovementMode ~= Enum.ComputerMovementMode.ClickToMove and
	       Player.DevEnableMouseLock and
	       Player.DevComputerMovementMode ~= Enum.DevComputerMovementMode.Scriptable and
	       Player.DevComputerMovementMode ~= Enum.DevComputerMovementMode.ClickToMove and
	       Util.IsTouchDevice() == false
end

local function CheckShiftLockMode()
	if shiftlockIcon then
		if IsShiftLockModeEnabled() then
			AddItemInOrder(LeftMenubar, shiftlockIcon, LEFT_ITEM_ORDER)
		else
			LeftMenubar:RemoveItem(shiftlockIcon)
		end
	end
end



local function OnGameSettingsChanged(property)
	if property == 'ControlMode' or property == 'ComputerMovementMode' then
		CheckShiftLockMode()
	end
end

local function OnPlayerChanged(property)
	if property == 'DevEnableMouseLock' or property == 'DevComputerMovementMode' then
		CheckShiftLockMode()
	end
end


TopBar:SetTopbarDisplayMode(false)

LeftMenubar:SetDock(TopBar:GetInstance())
RightMenubar:SetDock(TopBar:GetInstance())
Util.SetGUIInsetBounds(0, TOPBAR_THICKNESS, 0, 0)

if settingsIcon then
	AddItemInOrder(LeftMenubar, settingsIcon, LEFT_ITEM_ORDER)
end
if nameAndHealthMenuItem then
	AddItemInOrder(RightMenubar, nameAndHealthMenuItem, RIGHT_ITEM_ORDER)
end

local gameOptions = settings():FindFirstChild("Game Options")
if gameOptions then
	local success, result = pcall(function()
		gameOptions.VideoRecordingChangeRequest:connect(function(recording)
			if recording then
				AddItemInOrder(LeftMenubar, stopRecordingIcon, LEFT_ITEM_ORDER)
			else
				LeftMenubar:RemoveItem(stopRecordingIcon)
			end
		end)
	end)
end

-- Hook-up coregui changing
StarterGui.CoreGuiChangedSignal:connect(OnCoreGuiChanged)
for _, enumItem in pairs(Enum.CoreGuiType:GetEnumItems()) do
	OnCoreGuiChanged(enumItem, StarterGui:GetCoreGuiEnabled(enumItem))
end
-- Hook up Shiftlock detection
GameSettings.Changed:connect(OnGameSettingsChanged)
Player.Changed:connect(OnPlayerChanged)
CheckShiftLockMode()









