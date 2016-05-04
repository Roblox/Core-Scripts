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

local defeatableTopbarSuccess, defeatableTopbarFlagValue = pcall(function() return settings():GetFFlag("EnableSetCoreTopbarEnabled") end)
local defeatableTopbar = (defeatableTopbarSuccess and defeatableTopbarFlagValue == true)

--[[ END OF FFLAG VALUES ]]


--[[ SERVICES ]]

local CoreGuiService = game:GetService('CoreGui')
local PlayersService = game:GetService('Players')
local GuiService = game:GetService('GuiService')
local InputService = game:GetService('UserInputService')
local StarterGui = game:GetService('StarterGui')
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService('RunService')

--[[ END OF SERVICES ]]


local topbarEnabled = true
local topbarEnabledChangedEvent = Instance.new('BindableEvent')

local settingsActive = false

local GameSettings = UserSettings().GameSettings
local Player = PlayersService.LocalPlayer
while Player == nil do
	wait()
	Player = PlayersService.LocalPlayer
end

local GuiRoot = CoreGuiService:WaitForChild('RobloxGui')
local TenFootInterface = require(GuiRoot.Modules.TenFootInterface)
local isTenFootInterface = TenFootInterface:IsEnabled()

local Panel3D = require(GuiRoot.Modules.Panel3D)

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
		if GuiRoot:FindFirstChild("GuiInsetChanged") then
			GuiRoot.GuiInsetChanged:Fire(x1, y1, x2, y2)
		end
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

	local function ComputeTransparency()
		if not topbarEnabled then
			return 1
		end

		local playerGui = Player:FindFirstChild('PlayerGui')
		if playerGui then
			return playerGui:GetTopbarTransparency()
		end

		return TOPBAR_TRANSLUCENT_TRANSPARENCY
	end

	function this:UpdateBackgroundTransparency()
		if settingsActive and not VREnabled then
			topbarContainer.BackgroundTransparency = TOPBAR_OPAQUE_TRANSPARENCY
			topbarShadow.Visible = false
		else
			topbarContainer.BackgroundTransparency = ComputeTransparency()
			topbarShadow.Visible = (topbarContainer.BackgroundTransparency == 0)
		end
	end

	function this:GetInstance()
		return topbarContainer
	end

	spawn(function()
		local playerGui = Player:WaitForChild('PlayerGui')
		playerGuiChangedConn = Util.DisconnectEvent(playerGuiChangedConn)
		pcall(function()
			playerGuiChangedConn = playerGui.TopbarTransparencyChangedSignal:connect(this.UpdateBackgroundTransparency)
		end)
		this:UpdateBackgroundTransparency()
	end)

	return this
end


local BarAlignmentEnum = 
{
	Right = 0;
	Left = 1;
	Middle = 2;
}

local function CreateMenuBar(barAlignment)
	local this = {}
	local thickness = TOPBAR_THICKNESS
	local alignment = barAlignment or BarAlignmentEnum.Right
	local items = {}
	local propertyChangedConnections = {}
	local dock = nil

	function this:ArrangeItems()
		local totalWidth = 0

		for _, item in pairs(items) do
			local width = item:GetWidth()

			if alignment == BarAlignmentEnum.Left then
				item.Position = UDim2.new(0, totalWidth, 0, 0)
			elseif alignment == BarAlignmentEnum.Right then
				item.Position = UDim2.new(1, -totalWidth - width, 0, 0)
			end

			totalWidth = totalWidth + width
		end

		if alignment == BarAlignmentEnum.Middle then
			local currentX = -totalWidth / 2
			for _, item in pairs(items) do
				item.Position = UDim2.new(0, currentX, 0, 0)

				currentX = currentX + item:GetWidth()
			end
		end

		return totalWidth
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

	function this:GetItems()
		return items
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
				self:ArrangeItems()
			end
		end)
		self:ArrangeItems()

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

			self:ArrangeItems()
			return removedItem, index
		end
	end


	return this
end

local function Create3DMenuBar(barAlignment, threeDPanel)
	local this = CreateMenuBar(barAlignment)

	local superArrangeItems = this.ArrangeItems
	function this:ArrangeItems()
		local totalWidth = superArrangeItems(self)
		if threeDPanel then
			threeDPanel:ResizePixels(totalWidth, TOPBAR_THICKNESS)
		end
		return totalWidth
	end

	if threeDPanel then
		local RENDER_STEP_NAME = game:GetService("HttpService"):GenerateGUID() .. "Create3DMenuBar"
		threeDPanel:AddTransparencyCallback(function(transparency)
			for _, item in pairs(this:GetItems()) do
				item:SetTransparency(transparency)
			end
		end)

		local lastHoveredItem = nil
		local function OnRenderStep()
			local hoveredItem = Panel3D.FindHoveredGuiElement(threeDPanel, this:GetItems())
			if hoveredItem ~= lastHoveredItem then
				if lastHoveredItem then
					lastHoveredItem:OnMouseLeave()
				end
				if hoveredItem then
					hoveredItem:OnMouseEnter()
				end
				lastHoveredItem = hoveredItem
			end
		end

		threeDPanel.OnMouseEnter = function()
			RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
			RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Last.Value, OnRenderStep)
		end
		threeDPanel.OnMouseLeave = function() 
			RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
			if lastHoveredItem then
				lastHoveredItem:OnMouseLeave()
				lastHoveredItem = nil
			end
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

local function createNormalHealthBar()
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

	return container, username, healthContainer, healthFill
end

----- HEALTH -----
local function CreateUsernameHealthMenuItem()

	local container, username, healthContainer, healthFill = nil

	if isTenFootInterface then
		container, username, healthContainer, healthFill = TenFootInterface:CreateHealthBar()
	else
		container, username, healthContainer, healthFill = createNormalHealthBar()
	end

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
		if hurtOverlay and not VREnabled then
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

				if healthDelta >= thresholdForHurtOverlay and health ~= humanoid.MaxHealth and game.StarterGui:GetCoreGuiEnabled("Health") == true then
					AnimateHurtOverlay()
				end
				
				healthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
				healthFill.BackgroundColor3 = healthColor

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

	rawset(this, "SetHealthbarEnabled",
		function(self, enabled)
			healthContainer.Visible = enabled
			if enabled then
				username.Size = UDim2.new(1, -14, 0, 22);
				username.TextYAlignment = Enum.TextYAlignment.Bottom;
			else
				username.Size = UDim2.new(1, -14, 1, 0);
				username.TextYAlignment = Enum.TextYAlignment.Center;
			end
		end)

	rawset(this, "SetNameVisible",
		function(self, visible)
			username.Visible = visible
		end)

	-- Don't need to disconnect this one because we never reconnect it.
	Player.CharacterAdded:connect(OnCharacterAdded)
	if Player.Character then
		OnCharacterAdded(Player.Character)
	end

	local PlayerlistModule = require(GuiRoot.Modules.PlayerlistModule)
	container.MouseButton1Click:connect(function()
		if topbarEnabled then
			PlayerlistModule.ToggleVisibility()
		end
	end)

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

	rawset(this, "SetColumns",
		function(self, columnsList)
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
		end)

	rawset(this, "UpdateColumnValue",
		function(self, columnName, value)
			local column = columns[columnName]
			local columnValue = column and column:FindFirstChild('ColumnValue')
			if columnValue then
				columnValue.Text = tostring(value)
			end
		end)

	topbarEnabledChangedEvent.Event:connect(function()
		PlayerlistModule.TopbarEnabledChanged(topbarEnabled)
	end)

	this:SetColumns(PlayerlistModule.GetStats())
	PlayerlistModule.OnLeaderstatsChanged.Event:connect(function(newStatColumns)
		this:SetColumns(newStatColumns)
	end)

	PlayerlistModule.OnStatChanged.Event:connect(function(statName, statValueAsString)
		this:UpdateColumnValue(statName, statValueAsString)
	end)

	leaderstatsContainer.MouseButton1Click:connect(function()
		if topbarEnabled then
			PlayerlistModule.ToggleVisibility()
		end
	end)

	return this
end
----- END OF LEADERSTATS -----

--- SETTINGS ---
local function CreateSettingsIcon(topBarInstance)
	local MenuModule = nil
	game.CoreGui.RobloxGui.Modules:WaitForChild("Settings")
	game.CoreGui.RobloxGui.Modules.Settings:WaitForChild("SettingsHub")
	MenuModule = require(game.CoreGui.RobloxGui.Modules.Settings.SettingsHub)

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
		topBarInstance:UpdateBackgroundTransparency()
		UpdateHamburgerIcon()
	end)

	local menuItem = CreateMenuItem(settingsIconButton)

	rawset(menuItem, "SetTransparency", function(self, transparency)
		settingsIconImage.ImageTransparency = transparency
	end)
	rawset(menuItem, "SetImage", function(self, image)
		settingsIconImage.Image = image
	end)
	rawset(menuItem, "SetSettingsActive", function(self, active)
		settingsActive = active
		MenuModule:ToggleVisibility(settingsActive)
		UpdateHamburgerIcon()

		return settingsActive
	end)

	return menuItem
end

local function Create3DSettingsIcon(topBarInstance, panel)
	local menuItem = CreateSettingsIcon(topBarInstance)

	rawset(menuItem, "Hover", function(self, hovering)
		if hovering then
			self:SetImage("rbxasset://textures/ui/Menu/HamburgerDown.png")
		else
			self:SetImage("rbxasset://textures/ui/Menu/Hamburger.png")
		end
	end)


	local function OnHamburger3DInput(actionName, state, inputObj)
		if state ~= Enum.UserInputState.Begin then
			return
		end
		menuItem:SetSettingsActive(true) --this button is only ever shown if the settings menu isn't already open, so it can only be true.
	end

	local eaterAction = game:GetService("HttpService"):GenerateGUID()
	local function EnableHamburger3DInput(enable)
		if enable then
			ContextActionService:BindCoreAction("Hamburger3DInput", OnHamburger3DInput, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
			ContextActionService:BindAction(eaterAction, function() end, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
		else
			ContextActionService:UnbindCoreAction("Hamburger3DInput")
			ContextActionService:UnbindAction(eaterAction)
		end
	end

	rawset(menuItem, "OnMouseEnter",
		function(self)
			EnableHamburger3DInput(true) 
			menuItem:Hover(true)
		end)

	rawset(menuItem, "OnMouseLeave",
		function(self)
			EnableHamburger3DInput(false) 
			menuItem:Hover(false)
		end)

	return menuItem
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
	local chatEnabled = game:GetService("UserInputService"):GetPlatform() ~= Enum.Platform.XBoxOne
	if not chatEnabled then return end
	
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
	if not Util.IsTouchDevice() then
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
		if InputService.VREnabled then
			ChatModule:ToggleVisibility()
		elseif Util.IsTouchDevice() or bubbleChatIsOn then
			if debounce + DEBOUNCE_TIME < tick() then
				if Util.IsTouchDevice() and ChatModule:GetVisibility() then
					ChatModule:ToggleVisibility()
				end
				ChatModule:FocusChatBar()
			end
		else
			ChatModule:ToggleVisibility()
		end
	end

	topbarEnabledChangedEvent.Event:connect(function()
		ChatModule:TopbarEnabledChanged(topbarEnabled)
	end)

	chatIconButton.MouseButton1Click:connect(function()
		toggleChat()
	end)

	if Util.IsTouchDevice() or bubbleChatIsOn then
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

	local menuItem = CreateMenuItem(chatIconButton)

	rawset(menuItem, "ToggleChat", function(self)
		toggleChat()
	end)
	rawset(menuItem, "SetTransparency", function(self, transparency)
		chatIconImage.ImageTransparency = transparency
	end)
	rawset(menuItem, "SetImage", function(self, newImage)
		chatIconImage.Image = newImage
	end)

	return menuItem
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


local function Create3DChatIcon(topBarInstance, panel)
	local menuItem = CreateChatIcon(topBarInstance)


	rawset(menuItem, "Hover", function(self, hovering)
		if hovering then
			self:SetImage("rbxasset://textures/ui/Chat/ChatDown.png")
		else
			self:SetImage("rbxasset://textures/ui/Chat/Chat.png")
		end
	end)

	local function On3DInput(actionName, state, inputObj)
		if state == Enum.UserInputState.Begin then
			menuItem:ToggleChat()
		end
	end

	local eaterAction = game:GetService("HttpService"):GenerateGUID()
	local function EnableChat3DInput(enable)
		if enable then
			ContextActionService:BindCoreAction("ChatIcon3DInput", On3DInput, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
			ContextActionService:BindAction(eaterAction, function() end, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
		else
			ContextActionService:UnbindCoreAction("ChatIcon3DInput")
			ContextActionService:UnbindAction(eaterAction)
		end
	end

	rawset(menuItem, "OnMouseEnter",
		function(self)
			EnableChat3DInput(true) 
			menuItem:Hover(true)
		end)

	rawset(menuItem, "OnMouseLeave",
		function(self)
			EnableChat3DInput(false) 
			menuItem:Hover(false)
		end)

	return menuItem
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

	topbarEnabledChangedEvent.Event:connect(function()
		BackpackModule:TopbarEnabledChanged(topbarEnabled)
	end)

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

local Hamburger3DPanel = Panel3D.Get(Panel3D.Panels.Hamburger)

local TopBar = CreateTopBar()
local LeftMenubar = CreateMenuBar(BarAlignmentEnum.Left)
local RightMenubar = CreateMenuBar(BarAlignmentEnum.Right)
local ThreeDMenubar = Create3DMenuBar(BarAlignmentEnum.Left, Hamburger3DPanel)

local settingsIcon = CreateSettingsIcon(TopBar)
local mobileShowChatIcon = Util.IsTouchDevice() and CreateMobileHideChatIcon() or nil
local chatIcon = CreateChatIcon()
local backpackIcon = CreateBackpackIcon()
local stopRecordingIcon = CreateStopRecordIcon()

local leaderstatsMenuItem = CreateLeaderstatsMenuItem()
local nameAndHealthMenuItem = CreateUsernameHealthMenuItem()

local settingsIcon3D = Create3DSettingsIcon(TopBar, Hamburger3DPanel)
local chatIcon3D = Create3DChatIcon(TopBar, Hamburger3DPanel)

local LEFT_ITEM_ORDER = {}
local RIGHT_ITEM_ORDER = {}
local THREE_D_ITEM_ORDER = {}


-- Set Item Orders
if settingsIcon then
	LEFT_ITEM_ORDER[settingsIcon] = 1
end
if mobileShowChatIcon then
	LEFT_ITEM_ORDER[mobileShowChatIcon] = 2
end
if chatIcon then
	LEFT_ITEM_ORDER[chatIcon] = 3
end
if backpackIcon then
	LEFT_ITEM_ORDER[backpackIcon] = 4
end
if stopRecordingIcon then
	LEFT_ITEM_ORDER[stopRecordingIcon] = 5
end

if leaderstatsMenuItem then
	RIGHT_ITEM_ORDER[leaderstatsMenuItem] = 1
end
if nameAndHealthMenuItem and not isTenFootInterface then
	RIGHT_ITEM_ORDER[nameAndHealthMenuItem] = 2
end

if settingsIcon3D then
	THREE_D_ITEM_ORDER[settingsIcon3D] = 1
end
if chatIcon3D then
	THREE_D_ITEM_ORDER[chatIcon3D] = 2
end

-------------------------


local function AddItemInOrder(Bar, Item, ItemOrder)
	local index = 1
	while ItemOrder[Bar:ItemAtIndex(index)] and ItemOrder[Bar:ItemAtIndex(index)] < ItemOrder[Item] do
		index = index + 1
	end
	Bar:AddItem(Item, index)
end

local function OnCoreGuiChanged(coreGuiType, coreGuiEnabled)
	local enabled = coreGuiEnabled and topbarEnabled
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
		local showTopbarChatIcon = enabled and Player.ChatMode == Enum.ChatMode.TextAndMenu
		local showThree3DChatIcon = coreGuiEnabled and InputService.VREnabled and Player.ChatMode == Enum.ChatMode.TextAndMenu

		if showThree3DChatIcon then
			if chatIcon3D then
				AddItemInOrder(ThreeDMenubar, chatIcon3D, THREE_D_ITEM_ORDER)
			end
		else
			if chatIcon3D then
				ThreeDMenubar:RemoveItem(chatIcon3D)
			end
		end
		if showTopbarChatIcon then
			if chatIcon then
				AddItemInOrder(LeftMenubar, chatIcon, LEFT_ITEM_ORDER)
			end
			if mobileShowChatIcon and PlayersService.ClassicChat then
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
		nameAndHealthMenuItem:SetNameVisible((playerListOn or healthbarOn) and topbarEnabled)
	end
end


TopBar:UpdateBackgroundTransparency()

LeftMenubar:SetDock(TopBar:GetInstance())
RightMenubar:SetDock(TopBar:GetInstance())
ThreeDMenubar:SetDock(Hamburger3DPanel.gui)


if not isTenFootInterface then
	Util.SetGUIInsetBounds(0, TOPBAR_THICKNESS, 0, 0)
end

if settingsIcon then
	AddItemInOrder(LeftMenubar, settingsIcon, LEFT_ITEM_ORDER)
end
if nameAndHealthMenuItem and topbarEnabled and not isTenFootInterface then
	AddItemInOrder(RightMenubar, nameAndHealthMenuItem, RIGHT_ITEM_ORDER)
end



local function MoveHamburgerTo3D()
	LeftMenubar:RemoveItem(settingsIcon)
	AddItemInOrder(ThreeDMenubar, settingsIcon3D, THREE_D_ITEM_ORDER)
end

local gameOptions = settings():FindFirstChild("Game Options")
if gameOptions and not isTenFootInterface then
	local success, result = pcall(function()
		gameOptions.VideoRecordingChangeRequest:connect(function(recording)
			if recording and topbarEnabled then
				AddItemInOrder(LeftMenubar, stopRecordingIcon, LEFT_ITEM_ORDER)
			else
				LeftMenubar:RemoveItem(stopRecordingIcon)
			end
		end)
	end)
end

function topBarEnabledChanged()
	topbarEnabledChangedEvent:Fire(topbarEnabled)
	TopBar:UpdateBackgroundTransparency()
	for _, enumItem in pairs(Enum.CoreGuiType:GetEnumItems()) do
		-- The All enum will be false if any of the coreguis are false
		-- therefore by force updating it we are clobbering the previous sets
		if enumItem ~= Enum.CoreGuiType.All then
			OnCoreGuiChanged(enumItem, StarterGui:GetCoreGuiEnabled(enumItem))
		end
	end
end

local UISChanged;
local function OnVREnabled(prop)
	if prop == "VREnabled" and InputService.VREnabled then
		VREnabled = true
		topbarEnabled = false
		MoveHamburgerTo3D()
		topBarEnabledChanged()
		if UISChanged then
			UISChanged:disconnect()
			UISChanged = nil
		end
	end
end
UISChanged = InputService.Changed:connect(OnVREnabled)
OnVREnabled("VREnabled")

if defeatableTopbar then
	StarterGui:RegisterSetCore("TopbarEnabled", function(enabled)
		if type(enabled) == "boolean" then 
			topbarEnabled = enabled
			topBarEnabledChanged()
		end
	end)
end

-- Hook-up coregui changing
StarterGui.CoreGuiChangedSignal:connect(OnCoreGuiChanged)
topBarEnabledChanged()
