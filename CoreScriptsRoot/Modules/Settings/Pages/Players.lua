 --[[
		Filename: Players.lua
		Written by: Stickmasterluke
		Version 1.0
		Description: Player list inside escape menu, with friend adding functionality.
--]]
-------------- SERVICES --------------
local CoreGui = game:GetService("CoreGui")
local CorePackages = game:GetService("CorePackages")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local GuiService = game:GetService("GuiService")
local PlayersService = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local AnalyticsService = game:GetService("AnalyticsService")
local RunService = game:GetService("RunService")

----------- UTILITIES --------------
RobloxGui:WaitForChild("Modules"):WaitForChild("TenFootInterface")
local utility = require(RobloxGui.Modules.Settings.Utility)
local reportAbuseMenu = require(RobloxGui.Modules.Settings.Pages.ReportAbuseMenu)
local SocialUtil = require(RobloxGui.Modules:WaitForChild("SocialUtil"))
local EventStream = require(CorePackages.AppTempCommon.Temp.EventStream)
local FlagSettings = require(CoreGui.RobloxGui.Modules.Settings.Pages.ShareGame.FlagSettings)
local ShareGameIcons = require(CoreGui.RobloxGui.Modules.Settings.Pages.ShareGame.Spritesheets.ShareGameIcons)
local isTenFootInterface = require(RobloxGui.Modules.TenFootInterface):IsEnabled()
local RobloxTranslator = require(RobloxGui.Modules.RobloxTranslator)

local preventFriendingRemovedPlayers = settings():GetFFlag("PreventFriendingRemovedPlayers2")

------------ Constants -------------------
local FRAME_DEFAULT_TRANSPARENCY = .85
local FRAME_SELECTED_TRANSPARENCY = .65
local REPORT_PLAYER_IMAGE = isTenFootInterface and "rbxasset://textures/ui/Settings/Players/ReportFlagIcon@2x.png" or "rbxasset://textures/ui/Settings/Players/ReportFlagIcon.png"
local ADD_FRIEND_IMAGE = isTenFootInterface and "rbxasset://textures/ui/Settings/Players/AddFriendIcon@2x.png" or "rbxasset://textures/ui/Settings/Players/AddFriendIcon.png"
local FRIEND_IMAGE = isTenFootInterface and "rbxasset://textures/ui/Settings/Players/FriendIcon@2x.png" or "rbxasset://textures/ui/Settings/Players/FriendIcon.png"

local PLAYER_ROW_HEIGHT = 62
local PLAYER_ROW_SPACING = 80

------------ Variables -------------------
local platform = UserInputService:GetPlatform()
local PageInstance = nil
local localPlayer = PlayersService.LocalPlayer
while not localPlayer do
	PlayersService.ChildAdded:wait()
	localPlayer = PlayersService.LocalPlayer
end


------------ FAST FLAGS -------------------
local success, result = pcall(function() return settings():GetFFlag('UseNotificationsLocalization') end)
local FFlagUseNotificationsLocalization = success and result

local IsShareGamePageEnabledByPlatform = FlagSettings.IsShareGamePageEnabledByPlatform(platform)
local FFlagSettingsHubInviteToGameInStudio = settings():GetFFlag('SettingsHubInviteToGameInStudio4')
local FFlagSettingsHubBarsRefactor = settings():GetFFlag('SettingsHubBarsRefactor4')

----------- CLASS DECLARATION --------------
local function Initialize()
	local settingsPageFactory = require(RobloxGui.Modules.Settings.SettingsPageFactory)
	local this = settingsPageFactory:CreateNewPage()

	this.PageListLayout.Padding = UDim.new(0, PLAYER_ROW_SPACING - PLAYER_ROW_HEIGHT)

	------ TAB CUSTOMIZATION -------
	this.TabHeader.Name = "PlayersTab"
	this.TabHeader.Icon.Image = isTenFootInterface and "rbxasset://textures/ui/Settings/MenuBarIcons/PlayersTabIcon@2x.png" or "rbxasset://textures/ui/Settings/MenuBarIcons/PlayersTabIcon.png"

	if FFlagUseNotificationsLocalization then
		this.TabHeader.Title.Text = "Players"
	else
		this.TabHeader.Icon.Title.Text = "Players"
	end

	----- FRIENDSHIP FUNCTIONS ------
	local function getFriendStatus(selectedPlayer)
		local success, result = pcall(function()
			-- NOTE: Core script only
			return localPlayer:GetFriendStatus(selectedPlayer)
		end)
		if success then
			return result
		else
			return Enum.FriendStatus.NotFriend
		end
	end

	------ PAGE CUSTOMIZATION -------
	this.Page.Name = "Players"

	local function showRightSideButtons(player)
		return player and player ~= localPlayer and player.UserId > 0 and localPlayer.UserId > 0
	end

	local function createFriendStatusTextLabel(status, player)
		if status == nil then
			return nil
		end

		local fakeSelection = Instance.new("Frame")
		fakeSelection.BackgroundTransparency = 1

		local friendLabel = nil
		local friendLabelText = nil
		if status == Enum.FriendStatus.Friend or status == Enum.FriendStatus.FriendRequestSent then
			friendLabel = Instance.new("TextButton")
			friendLabel.BackgroundTransparency = 1
			friendLabel.FontSize = Enum.FontSize.Size24
			friendLabel.Font = Enum.Font.SourceSans
			friendLabel.TextColor3 = Color3.new(1,1,1)
			friendLabel.SelectionImageObject = fakeSelection
			if status == Enum.FriendStatus.Friend then
				friendLabel.Text = "Friend"
			else
				friendLabel.Text = "Request Sent"
			end
		elseif status == Enum.FriendStatus.Unknown or status == Enum.FriendStatus.NotFriend or status == Enum.FriendStatus.FriendRequestReceived then
			local addFriendFunc = function()
				if friendLabel and friendLabelText and friendLabelText.Text ~= "" then
					friendLabel.ImageTransparency = 1
					friendLabelText.Text = ""
					if localPlayer and player then
                        AnalyticsService:ReportCounter("PlayersMenu-RequestFriendship")
                        AnalyticsService:TrackEvent("Game", "RequestFriendship", "PlayersMenu")

						localPlayer:RequestFriendship(player)
					end
				end
			end
			friendLabel, friendLabelText = utility:MakeStyledButton("FriendStatus", "Add Friend", UDim2.new(0, 182, 0, 46), addFriendFunc)
			friendLabelText.ZIndex = 3
			friendLabelText.Position = friendLabelText.Position + UDim2.new(0,0,0,1)
		end

		if friendLabel then
			friendLabel.Name = "FriendStatus"
			friendLabel.Size = UDim2.new(0,182,0,46)
			friendLabel.Position = UDim2.new(1,-198,0,7)
			friendLabel.ZIndex = 3
		end
		return friendLabel
	end

	local function createFriendStatusImageLabel(status, player)
		if status == Enum.FriendStatus.Friend or status == Enum.FriendStatus.FriendRequestSent then
			local friendLabel = Instance.new("ImageButton")
			friendLabel.Name = "FriendStatus"
			friendLabel.Size = UDim2.new(0, 46, 0, 46)
			friendLabel.Image = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuButton.png"
			friendLabel.ScaleType = Enum.ScaleType.Slice
			friendLabel.SliceCenter = Rect.new(8,6,46,44)
			friendLabel.AutoButtonColor = false
			friendLabel.BackgroundTransparency = 1
			friendLabel.ZIndex = 2
			local friendImage = Instance.new("ImageLabel")
			friendImage.BackgroundTransparency = 1
			friendImage.Position = UDim2.new(0.5, 0, 0.5, 0)
			friendImage.Size = UDim2.new(0, 28, 0, 28)
			friendImage.AnchorPoint = Vector2.new(0.5, 0.5)
			friendImage.ZIndex = 3
			friendImage.Image = FRIEND_IMAGE
			if status == Enum.FriendStatus.Friend then
				friendImage.ImageTransparency = 0
			else
				friendImage.Image = ADD_FRIEND_IMAGE
				friendImage.ImageTransparency = 0.5
			end
			friendImage.Parent = friendLabel
			return friendLabel
		elseif status == Enum.FriendStatus.Unknown or status == Enum.FriendStatus.NotFriend or status == Enum.FriendStatus.FriendRequestReceived then
			local addFriendButton, addFriendImage = nil
			local addFriendFunc = function()
				if addFriendButton and addFriendImage and addFriendButton.ImageTransparency ~= 1 then
					addFriendButton.ImageTransparency = 1
					addFriendImage.ImageTransparency = 1
					if localPlayer and player then
                        AnalyticsService:ReportCounter("PlayersMenu-RequestFriendship")
                        AnalyticsService:TrackEvent("Game", "RequestFriendship", "PlayersMenu")

						localPlayer:RequestFriendship(player)
					end
				end
			end
			addFriendButton, addFriendImage = utility:MakeStyledImageButton("FriendStatus", ADD_FRIEND_IMAGE,
					UDim2.new(0, 46, 0, 46), UDim2.new(0, 28, 0, 28), addFriendFunc)
			addFriendButton.Name = "FriendStatus"
			addFriendButton.Selectable = true
			return addFriendButton
		end
		return nil
	end

	--- Ideally we want to select the first add friend button, but select the first report button instead if none are available.
	local reportSelectionFound = nil
	local friendSelectionFound = nil
	local function friendStatusCreate(playerLabel, player)
		local friendLabelParent = nil
		if playerLabel then
			friendLabelParent = playerLabel:FindFirstChild("RightSideButtons")
		end

		if friendLabelParent then
			-- remove any previous friend status labels
			for _, item in pairs(friendLabelParent:GetChildren()) do
				if item and item.Name == "FriendStatus" then
					if GuiService.SelectedCoreObject == item then
						friendSelectionFound = nil
						GuiService.SelectedCoreObject = nil
					end
					item:Destroy()
				end
			end

			-- create new friend status label
			local status = nil
			if showRightSideButtons(player) then
				status = getFriendStatus(player)
			end

			local friendLabel = nil
			local wasIsPortrait = nil
			utility:OnResized(playerLabel, function(newSize, isPortrait)
				if friendLabel and isPortrait == wasIsPortrait then
					return
				end
				wasIsPortrait = isPortrait
				if friendLabel then
					friendLabel:Destroy()
				end
				if isPortrait then
					friendLabel = createFriendStatusImageLabel(status, player)
				else
					friendLabel = createFriendStatusTextLabel(status, player)
				end

				if friendLabel then
					friendLabel.Name = "FriendStatus"
					friendLabel.LayoutOrder = 2
					friendLabel.Selectable = true
					friendLabel.Parent = friendLabelParent

					if UserInputService.GamepadEnabled and not friendSelectionFound then
						friendSelectionFound = true
						GuiService.SelectedCoreObject = friendLabel
					end
				end
			end)
		end
	end

	localPlayer.FriendStatusChanged:connect(function(player, friendStatus)
		if player then
			local playerLabel = this.Page:FindFirstChild("PlayerLabel"..player.Name)
			if playerLabel then
				friendStatusCreate(playerLabel, player)
			end
		end
	end)

	local buttonsContainer = utility:Create("Frame") {
		Name = "ButtonsContainer",
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundTransparency = 1,
		Parent = this.Page,

		Visible = false
	}

	local leaveGameFunc = function()
		this.HubRef:SwitchToPage(this.HubRef.LeaveGamePage, false, 1)
	end
	local leaveButton, leaveLabel = utility:MakeStyledButton("LeaveButton", "Leave Game", UDim2.new(1 / 3, -5, 1, 0), leaveGameFunc)
	leaveButton.AnchorPoint = Vector2.new(0, 0)
	leaveButton.Position = UDim2.new(0, 0, 0, 0)
	leaveLabel.Size = UDim2.new(1, 0, 1, -6)
	leaveButton.Parent = buttonsContainer

	local resetFunc = function()
		this.HubRef:SwitchToPage(this.HubRef.ResetCharacterPage, false, 1)
	end
	local resetButton, resetLabel = utility:MakeStyledButton("ResetButton", "Reset Character", UDim2.new(1 / 3, -5, 1, 0), resetFunc)
	resetButton.AnchorPoint = Vector2.new(0.5, 0)
	resetButton.Position = UDim2.new(0.5, 0, 0, 0)
	resetLabel.Size = UDim2.new(1, 0, 1, -6)
	resetButton.Parent = buttonsContainer

	local resumeGameFunc = function()
		this.HubRef:SetVisibility(false)
	end
	local resumeButton, resumeLabel = utility:MakeStyledButton("ResumeButton", "Resume Game", UDim2.new(1 / 3, -5, 1, 0), resumeGameFunc)
	resumeButton.AnchorPoint = Vector2.new(1, 0)
	resumeButton.Position = UDim2.new(1, 0, 0, 0)
	resumeLabel.Size = UDim2.new(1, 0, 1, -6)
	resumeButton.Parent = buttonsContainer

	utility:OnResized(buttonsContainer, function(newSize, isPortrait)
		if isPortrait or utility:IsSmallTouchScreen() then
			local buttonsFontSize = isPortrait and 18 or 24
			buttonsContainer.Visible = true
			buttonsContainer.Size = UDim2.new(1, 0, 0, isPortrait and 50 or 62)
			resetLabel.TextSize = buttonsFontSize
			leaveLabel.TextSize = buttonsFontSize
			resumeLabel.TextSize = buttonsFontSize
		else
			buttonsContainer.Visible = false
			buttonsContainer.Size = UDim2.new(1, 0, 0, 0)
		end
	end)


	if FFlagUseNotificationsLocalization then
		local function ApplyLocalizeTextSettingsToLabel(label)
			label.AnchorPoint = Vector2.new(0.5,0.5)
			label.Position = UDim2.new(0.5, 0, 0.5, -3)
			label.Size = UDim2.new(0.75, 0, 0.5, 0)
		end
		ApplyLocalizeTextSettingsToLabel(leaveLabel)
		ApplyLocalizeTextSettingsToLabel(resetLabel)
		ApplyLocalizeTextSettingsToLabel(resetLabel)
	end

	local function reportAbuseButtonCreate(playerLabel, player)
		local rightSideButtons = playerLabel:FindFirstChild("RightSideButtons")
		if rightSideButtons then
			local oldReportButton = rightSideButtons:FindFirstChild("ReportPlayer")
			if oldReportButton then
				if oldReportButton == GuiService.SelectedCoreObject then
					reportSelectionFound = nil
				end
				oldReportButton:Destroy()
			end

			if showRightSideButtons(player) then
				local reportPlayerFunction = function()
					reportAbuseMenu:ReportPlayer(player)
				end

				local reportButton = utility:MakeStyledImageButton("ReportPlayer", REPORT_PLAYER_IMAGE,
						UDim2.new(0, 46, 0, 46), UDim2.new(0, 28, 0, 28), reportPlayerFunction)
				reportButton.Name = "ReportPlayer"
				reportButton.Position = UDim2.new(1, -260, 0, 7)
				reportButton.LayoutOrder = 1
				reportButton.Selectable = true
				reportButton.Parent = rightSideButtons

				if not reportSelectionFound and not friendSelectionFound and UserInputService.GamepadEnabled then
					reportSelectionFound = true
					GuiService.SelectedCoreObject = reportButton
				end
			end
		end
	end

	local createShareGameButton = nil
	local createPlayerRow = nil
	if FFlagSettingsHubBarsRefactor then
		local function createRow(frameClassName)
			local frame = Instance.new(frameClassName)
			frame.Image = "rbxasset://textures/ui/dialog_white.png"
			frame.ScaleType = "Slice"
			frame.SliceCenter = Rect.new(10, 10, 10, 10)
			frame.Size = UDim2.new(1, 0, 0, PLAYER_ROW_HEIGHT)
			frame.Position = UDim2.new(0, 0, 0, 0)
			frame.BackgroundTransparency = 1
			frame.ZIndex = 2
			frame.ImageTransparency = FRAME_DEFAULT_TRANSPARENCY

			local icon = Instance.new("ImageLabel")
			icon.Name = "Icon"
			icon.BackgroundTransparency = 1
			icon.Size = UDim2.new(0, 36, 0, 36)
			icon.Position = UDim2.new(0, 12, 0, 12)
			icon.ZIndex = 3
			icon.Parent = frame

			local textLabel = Instance.new("TextLabel")
			textLabel.TextXAlignment = Enum.TextXAlignment.Left
			textLabel.Font = Enum.Font.SourceSans
			textLabel.FontSize = Enum.FontSize.Size24
			textLabel.TextColor3 = Color3.new(1, 1, 1)
			textLabel.BackgroundTransparency = 1
			textLabel.Position = UDim2.new(0, 60, .5, 0)
			textLabel.Size = UDim2.new(0, 0, 0, 0)
			textLabel.ZIndex = 3
			textLabel.Parent = frame

			return frame
		end

		createShareGameButton = function()
			local frame = createRow("ImageButton")
			local textLabel = frame.TextLabel
			local icon = frame.Icon

			textLabel.Font = Enum.Font.SourceSansSemibold
			textLabel.Text = RobloxTranslator:FormatByKey("Feature.SettingsHub.Action.InviteFriendsToPlay")

			icon.Size = UDim2.new(0, 24, 0, 24)
			icon.Position = UDim2.new(0, 18, 0, 18)
			ShareGameIcons:ApplyImage(icon, "invite")

			local function onHover(isHovering)
				if isHovering then
					frame.ImageTransparency = FRAME_SELECTED_TRANSPARENCY
				else
					frame.ImageTransparency = FRAME_DEFAULT_TRANSPARENCY
				end
			end

			frame.InputBegan:Connect(function() onHover(true) end)
			frame.InputEnded:Connect(function() onHover(false) end)
			frame.Activated:Connect(function() onHover(false) end)
			frame.TouchPan:Connect(function(_, totalTranslation)
				local TAP_ACCURACY_THREASHOLD = 20
				if math.abs(totalTranslation.Y) > TAP_ACCURACY_THREASHOLD then
					onHover(false)
				end
			 end)

			return frame
		end

		createPlayerRow = function()
			local frame = createRow("ImageLabel")
			frame.TextLabel.Name = "NameLabel"

			local rightSideButtons = Instance.new("Frame")
			rightSideButtons.Name = "RightSideButtons"
			rightSideButtons.BackgroundTransparency = 1
			rightSideButtons.ZIndex = 2
			rightSideButtons.Position = UDim2.new(0, 0, 0, 0)
			rightSideButtons.Size = UDim2.new(1, -10, 1, 0)
			rightSideButtons.Parent = frame

			-- Selection Highlighting logic:
			local updateHighlight = function(lostSelectionObject)
				if frame then
					if GuiService.SelectedCoreObject and GuiService.SelectedCoreObject ~= lostSelectionObject and GuiService.SelectedCoreObject.Parent == rightSideButtons then
						frame.ImageTransparency = FRAME_SELECTED_TRANSPARENCY
					else
						frame.ImageTransparency = FRAME_DEFAULT_TRANSPARENCY
					end
				end
			end

			local fakeSelectionObject = nil
			rightSideButtons.ChildAdded:connect(function(child)
				if child:IsA("GuiObject") then
					if fakeSelectionObject and child ~= fakeSelectionObject then
						fakeSelectionObject:Destroy()
						fakeSelectionObject = nil
					end
					child.SelectionGained:connect(function() updateHighlight(nil) end)
					child.SelectionLost:connect(function() updateHighlight(child) end)
				end
			end)

			fakeSelectionObject = Instance.new("Frame")
			fakeSelectionObject.Selectable = true
			fakeSelectionObject.Size = UDim2.new(0, 100, 0, 100)
			fakeSelectionObject.BackgroundTransparency = 1
			fakeSelectionObject.SelectionImageObject = fakeSelectionObject:Clone()
			fakeSelectionObject.Parent = rightSideButtons

			local rightSideListLayout = Instance.new("UIListLayout")
			rightSideListLayout.Name = "RightSideListLayout"
			rightSideListLayout.FillDirection = Enum.FillDirection.Horizontal
			rightSideListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			rightSideListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			rightSideListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			rightSideListLayout.Padding = UDim.new(0, 20)
			rightSideListLayout.Parent = rightSideButtons

			pcall(function()
				frame.NameLabel.Localize = false
			end)

			return frame
		end
	else
		createPlayerRow = function(yPosition)
			local frame = Instance.new("ImageLabel")
			frame.Image = "rbxasset://textures/ui/dialog_white.png"
			frame.ScaleType = "Slice"
			frame.SliceCenter = Rect.new(10, 10, 10, 10)
			frame.Size = UDim2.new(1, 0, 0, PLAYER_ROW_HEIGHT)
			frame.Position = UDim2.new(0, 0, 0, yPosition)
			frame.BackgroundTransparency = 1
			frame.ZIndex = 2

			local rightSideButtons = Instance.new("Frame")
			rightSideButtons.Name = "RightSideButtons"
			rightSideButtons.BackgroundTransparency = 1
			rightSideButtons.ZIndex = 2
			rightSideButtons.Position = UDim2.new(0, 0, 0, 0)
			rightSideButtons.Size = UDim2.new(1, -10, 1, 0)
			rightSideButtons.Parent = frame

			-- Selection Highlighting logic:
			local updateHighlight = function(lostSelectionObject)
				if frame then
					if GuiService.SelectedCoreObject and GuiService.SelectedCoreObject ~= lostSelectionObject and GuiService.SelectedCoreObject.Parent == rightSideButtons then
						frame.ImageTransparency = FRAME_SELECTED_TRANSPARENCY
					else
						frame.ImageTransparency = FRAME_DEFAULT_TRANSPARENCY
					end
				end
			end

			 local fakeSelectionObject = nil
			rightSideButtons.ChildAdded:connect(function(child)
				if child:IsA("GuiObject") then
					if fakeSelectionObject and child ~= fakeSelectionObject then
						fakeSelectionObject:Destroy()
						fakeSelectionObject = nil
					end
					child.SelectionGained:connect(function() updateHighlight(nil) end)
					child.SelectionLost:connect(function() updateHighlight(child) end)
				end
			end)

			fakeSelectionObject = Instance.new("Frame")
			fakeSelectionObject.Selectable = true
			fakeSelectionObject.Size = UDim2.new(0, 100, 0, 100)
			fakeSelectionObject.BackgroundTransparency = 1
			fakeSelectionObject.SelectionImageObject = fakeSelectionObject:Clone()
			fakeSelectionObject.Parent = rightSideButtons

			local rightSideListLayout = Instance.new("UIListLayout")
			rightSideListLayout.Name = "RightSideListLayout"
			rightSideListLayout.FillDirection = Enum.FillDirection.Horizontal
			rightSideListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			rightSideListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			rightSideListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			rightSideListLayout.Padding = UDim.new(0, 20)
			rightSideListLayout.Parent = rightSideButtons

			local icon = Instance.new("ImageLabel")
			icon.Name = "Icon"
			icon.BackgroundTransparency = 1
			icon.Size = UDim2.new(0, 36, 0, 36)
			icon.Position = UDim2.new(0, 12, 0, 12)
			icon.ZIndex = 3
			icon.Parent = frame

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "NameLabel"
			pcall(function()
				nameLabel.Localize = false
			end)
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Font = Enum.Font.SourceSans
			nameLabel.FontSize = Enum.FontSize.Size24
			nameLabel.TextColor3 = Color3.new(1, 1, 1)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Position = UDim2.new(0, 60, .5, 0)
			nameLabel.Size = UDim2.new(0, 0, 0, 0)
			nameLabel.ZIndex = 3
			nameLabel.Parent = frame
			pcall(function()
				nameLabel.Localize = false
			end)

			return frame
		end
	end

	-- Manage cutting off a players name if it is too long when switching into portrait mode.
	local function managePlayerNameCutoff(frame, player)
		local wasIsPortrait = nil
		local reportFlagAddedConnection = nil
		local reportFlagChangedConnection = nil
		local function reportFlagChanged(reportFlag, prop)
			if prop == "AbsolutePosition" and wasIsPortrait then
				local maxPlayerNameSize = reportFlag.AbsolutePosition.X - 20 - frame.NameLabel.AbsolutePosition.X
				frame.NameLabel.Text = player.Name
				local newNameLength = string.len(player.Name)
				while frame.NameLabel.TextBounds.X > maxPlayerNameSize and newNameLength > 0 do
					frame.NameLabel.Text = string.sub(player.Name, 1, newNameLength) .. "..."
					newNameLength = newNameLength - 1
				end
			end
		end
		utility:OnResized(frame.NameLabel, function(newSize, isPortrait)
			if wasIsPortrait ~= nil and wasIsPortrait == isPortrait then
				return
			end
			wasIsPortrait = isPortrait
			if isPortrait then
				if reportFlagAddedConnection == nil then
					reportFlagAddedConnection = frame.RightSideButtons.ChildAdded:connect(function(child)
						if child.Name == "ReportPlayer" then
							reportFlagChangedConnection = child.Changed:connect(function(prop) reportFlagChanged(child, prop) end)
							reportFlagChanged(child, "AbsolutePosition")
						end
					end)
				end
				local reportFlag = frame.RightSideButtons:FindFirstChild("ReportPlayer")
				if reportFlag then
					reportFlagChangedConnection = reportFlag.Changed:connect(function(prop) reportFlagChanged(reportFlag, prop) end)
					reportFlagChanged(reportFlag, "AbsolutePosition")
				end
			else
				frame.NameLabel.Text = player.Name
			end
		end)
	end

	local function canShareCurrentGame()
		return this.HubRef.ShareGamePage ~= nil and localPlayer.UserId > 0
	end

	local shareGameButton
	local sortedPlayers
	local existingPlayerLabels = {}
	local livePlayers = {}

	this.Displayed.Event:connect(function(switchedFromGamepadInput)
		sortedPlayers = PlayersService:GetPlayers()
		table.sort(sortedPlayers, function(item1,item2)
			return item1.Name:lower() < item2.Name:lower()
		end)

		local extraOffset = 20
		if utility:IsSmallTouchScreen() or utility:IsPortrait() then
			extraOffset = 85
		end

		if IsShareGamePageEnabledByPlatform then
			-- Create "invite friends" button if it doesn't exist yet
			-- We shouldn't create this button if we're not in a live game
			if canShareCurrentGame() and not shareGameButton
				and (not RunService:IsStudio() or FFlagSettingsHubInviteToGameInStudio) then
				local eventStream = EventStream.new()
				shareGameButton = createShareGameButton()
				shareGameButton.Activated:connect(function()
					local eventContext = "inGame"
					local eventName = "inputShareGameEntryPoint"
					local additionalArgs = {
						buttonName = "settingsHub",
					}
					eventStream:setRBXEventStream(eventContext, eventName, additionalArgs)

					this.HubRef:AddToMenuStack(this.HubRef.Pages.CurrentPage)
					this.HubRef:SwitchToPage(this.HubRef.ShareGamePage, nil, 1, true)
				end)

				-- Ensure the button is always at the top of the list
				shareGameButton.LayoutOrder = 1
				shareGameButton.Parent = this.Page
			end
		end

		friendSelectionFound = nil
		reportSelectionFound = nil

		-- iterate through players to reuse or create labels for players
		for index=1, #sortedPlayers do
			local player = sortedPlayers[index]
			local frame
			frame = existingPlayerLabels[player.Name]

			if player then
				livePlayers[player.Name] = true
				-- create label (frame) for this player index if one does not exist
				if not frame or not frame.Parent then
					frame = createPlayerRow((index - 1)*PLAYER_ROW_SPACING + extraOffset)
					frame.Parent = this.Page
					existingPlayerLabels[player.Name] = frame
				end
				frame.Name = "PlayerLabel" ..player.Name

                -- Immediately assign the image to an image that isn't guaranteed to be generated
                frame.Icon.Image = SocialUtil.GetFallbackPlayerImageUrl(math.max(1, player.UserId), Enum.ThumbnailSize.Size100x100, Enum.ThumbnailType.AvatarThumbnail)
                -- Spawn a function to get the generated image
                spawn(function()
                    local imageUrl = SocialUtil.GetPlayerImage(math.max(1, player.UserId), Enum.ThumbnailSize.Size100x100, Enum.ThumbnailType.AvatarThumbnail)
                    if frame and frame.Parent and frame.Parent == this.Page then
                        frame.Icon.Image = imageUrl
                    end
                end)

				frame.NameLabel.Text = player.Name
				frame.ImageTransparency = FRAME_DEFAULT_TRANSPARENCY
				if IsShareGamePageEnabledByPlatform then
					-- extra index room for shareGameButton
					frame.LayoutOrder = index + 1
				else
					frame.LayoutOrder = index
				end

				managePlayerNameCutoff(frame, player)

				friendStatusCreate(frame, player)
				if platform ~= Enum.Platform.XBoxOne and platform ~= Enum.Platform.PS4 then
					reportAbuseButtonCreate(frame, player)
				end
			end
		end

		for playerName, frame in pairs(existingPlayerLabels) do
			if not livePlayers[playerName] then
				frame:Destroy()
				existingPlayerLabels[playerName] = nil
			end
		end

		utility:OnResized("MenuPlayerListExtraPageSize", function(newSize, isPortrait)
			local extraOffset = 20
			if utility:IsSmallTouchScreen() or utility:IsPortrait() then
				extraOffset = 85
			end

			if IsShareGamePageEnabledByPlatform then
				local inviteToGameRow = 1
				local playerListRowsCount = #sortedPlayers + inviteToGameRow

				this.Page.Size = UDim2.new(1,0,0, extraOffset + PLAYER_ROW_SPACING * playerListRowsCount - 5)
			else
				this.Page.Size = UDim2.new(1,0,0, extraOffset + PLAYER_ROW_SPACING * #sortedPlayers - 5)
			end

		end)
	end)

	if preventFriendingRemovedPlayers then
		PlayersService.PlayerRemoving:Connect(function (player)
			livePlayers[player.Name] = nil

			local playerLabel = existingPlayerLabels[player.Name]

			if not playerLabel then
				return
			end

			local buttons = playerLabel:FindFirstChild("RightSideButtons")
			if not buttons then
				return
			end

			local friendStatus = buttons:FindFirstChild("FriendStatus")
			if friendStatus then
				if GuiService.SelectedCoreObject == friendStatus then
					friendSelectionFound = nil
					GuiService.SelectedCoreObject = nil
				end
				friendStatus:Destroy()
			end

			local reportPlayer = buttons:FindFirstChild("ReportPlayer")
			if reportPlayer then
				if GuiService.SelectedCoreObject == reportPlayer then
					reportSelectionFound = nil
					GuiService.SelectedCoreObject = nil
				end
				reportPlayer:Destroy()
			end
		end)
	end

	return this
end

----------- Public Facing API Additions --------------
PageInstance = Initialize()

return PageInstance
