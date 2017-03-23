 --[[
		Filename: Players.lua
		Written by: Stickmasterluke
		Version 1.0
		Description: Player list inside escape menu, with friend adding functionality.
--]]
-------------- SERVICES --------------
local CoreGui = game:GetService("CoreGui")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local GuiService = game:GetService("GuiService")
local PlayersService = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')

----------- UTILITIES --------------
RobloxGui:WaitForChild("Modules"):WaitForChild("TenFootInterface")
local utility = require(RobloxGui.Modules.Settings.Utility)
local isTenFootInterface = require(RobloxGui.Modules.TenFootInterface):IsEnabled()

local enablePortraitModeSuccess, enablePortraitModeValue = pcall(function() return settings():GetFFlag("EnablePortraitMode") end)
local enablePortraitMode = enablePortraitModeSuccess and enablePortraitModeValue

------------ Constants -------------------
local frameDefaultTransparency = .85
local frameSelectedTransparency = .65

------------ Variables -------------------
local PageInstance = nil
local localPlayer = PlayersService.LocalPlayer
while not localPlayer do
	PlayersService.ChildAdded:wait()
	localPlayer = PlayersService.LocalPlayer
end

----------- CLASS DECLARATION --------------
local function Initialize()
	local settingsPageFactory = require(RobloxGui.Modules.Settings.SettingsPageFactory)
	local this = settingsPageFactory:CreateNewPage()

	local playerLabelFakeSelection = Instance.new('ImageLabel')
	playerLabelFakeSelection.BackgroundTransparency = 1
	--[[playerLabelFakeSelection.Image = 'rbxasset://textures/ui/SelectionBox.png'
	playerLabelFakeSelection.ScaleType = 'Slice'
	playerLabelFakeSelection.SliceCenter = Rect.new(31,31,31,31)]]
	playerLabelFakeSelection.Image = ''
	playerLabelFakeSelection.Size = UDim2.new(0,0,0,0)

	------ TAB CUSTOMIZATION -------
	this.TabHeader.Name = "PlayersTab"
	this.TabHeader.Icon.Image = isTenFootInterface and "rbxasset://textures/ui/Settings/MenuBarIcons/PlayersTabIcon@2x.png" or "rbxasset://textures/ui/Settings/MenuBarIcons/PlayersTabIcon.png"

	this.TabHeader.Icon.Title.Text = "Players"

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

	local selectionFound = nil
	local function friendStatusCreate(playerLabel, player)
		if playerLabel then
			-- remove any previous friend status labels
			for _, item in pairs(playerLabel:GetChildren()) do
				if item and item.Name == 'FriendStatus' then
					if GuiService.SelectedCoreObject == item then
						selectionFound = nil
						GuiService.SelectedCoreObject = nil
					end
					item:Destroy()
				end
			end

			-- create new friend status label
			local status = nil
			if player and player ~= localPlayer and player.UserId > 1 and localPlayer.UserId > 1 then
				status = getFriendStatus(player)
			end

			local friendLabel, friendLabelText = nil, nil
			if not status then
				friendLabel = Instance.new('TextButton')
				friendLabel.Text = ''
				friendLabel.BackgroundTransparency = 1
				friendLabel.Position = UDim2.new(1,-198,0,7)
			elseif status == Enum.FriendStatus.Friend then 
				friendLabel = Instance.new('TextButton')
				friendLabel.Text = 'Friend'
				friendLabel.BackgroundTransparency = 1
				friendLabel.FontSize = 'Size24'
				friendLabel.Font = 'SourceSans'
				friendLabel.TextColor3 = Color3.new(1,1,1)
				friendLabel.Position = UDim2.new(1,-198,0,7)
			elseif status == Enum.FriendStatus.Unknown or status == Enum.FriendStatus.NotFriend or status == Enum.FriendStatus.FriendRequestReceived then
				local addFriendFunc = function()
					if friendLabel and friendLabelText and friendLabelText.Text ~= '' then
						friendLabel.ImageTransparency = 1
						friendLabelText.Text = ''
						if localPlayer and player then
							localPlayer:RequestFriendship(player)
						end
					end
				end
				local friendLabel2, friendLabelText2 = utility:MakeStyledButton("FriendStatus", "Add Friend", UDim2.new(0, 182, 0, 46), addFriendFunc)
				friendLabel = friendLabel2
				friendLabelText = friendLabelText2
				friendLabelText.ZIndex = 3
				friendLabelText.Position = friendLabelText.Position + UDim2.new(0,0,0,1)
				friendLabel.Position = UDim2.new(1,-198,0,7)
			elseif status == Enum.FriendStatus.FriendRequestSent then
				friendLabel = Instance.new('TextButton')
				friendLabel.Text = 'Request Sent'
				friendLabel.BackgroundTransparency = 1
				friendLabel.FontSize = 'Size24'
				friendLabel.Font = 'SourceSans'
				friendLabel.TextColor3 = Color3.new(1,1,1)
				friendLabel.Position = UDim2.new(1,-198,0,7)
			end

			if friendLabel then
				friendLabel.Name = 'FriendStatus'
				friendLabel.Size = UDim2.new(0,182,0,46)
				friendLabel.ZIndex = 3
				friendLabel.Parent = playerLabel
				friendLabel.SelectionImageObject = playerLabelFakeSelection

				local updateHighlight = function()
					if playerLabel then
						playerLabel.ImageTransparency = friendLabel and GuiService.SelectedCoreObject == friendLabel and frameSelectedTransparency or frameDefaultTransparency
					end
				end
				friendLabel.SelectionGained:connect(updateHighlight)
				friendLabel.SelectionLost:connect(updateHighlight)

				if UserInputService.GamepadEnabled and not selectionFound then
					selectionFound = true
					local fakeSize = 20
					playerLabelFakeSelection.Size = UDim2.new(0,playerLabel.AbsoluteSize.X+fakeSize,0,playerLabel.AbsoluteSize.Y+fakeSize)
					playerLabelFakeSelection.Position = UDim2.new(0, -(playerLabel.AbsoluteSize.X-198)-fakeSize*.5, 0, -8-fakeSize*.5)
					GuiService.SelectedCoreObject = friendLabel
				end
			end

		end
	end

	localPlayer.FriendStatusChanged:connect(function(player, friendStatus)
		if player then
			local playerLabel = this.Page:FindFirstChild('PlayerLabel'..player.Name)
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

	if enablePortraitMode then
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
	else
		if not utility:IsSmallTouchScreen() then
			buttonsContainer.Visible = false
			buttonsContainer.Size = UDim2.new(1, 0, 0, 0)
		else
			buttonsContainer.Visible = true
		end
	end

	local existingPlayerLabels = {}
	this.Displayed.Event:connect(function(switchedFromGamepadInput)
		local sortedPlayers = PlayersService:GetPlayers()
		table.sort(sortedPlayers,function(item1,item2)
			return item1.Name:lower() < item2.Name:lower()
		end)

		local extraOffset = 20
		if utility:IsSmallTouchScreen() then
			extraOffset = 85
		end

		selectionFound = nil

		-- iterate through players to reuse or create labels for players
		for index=1, #sortedPlayers do
			local player = sortedPlayers[index]
			local frame = existingPlayerLabels[index]
			if player then
				-- create label (frame) for this player index if one does not exist
				if not frame or not frame.Parent then
					frame = Instance.new('ImageLabel')
					frame.Image = "rbxasset://textures/ui/dialog_white.png"
					frame.ScaleType = 'Slice'
					frame.SliceCenter = Rect.new(10,10,10,10)
					frame.Size = UDim2.new(1,0,0,60)
					frame.Position = UDim2.new(0,0,0,(index-1)*80 + extraOffset)
					frame.BackgroundTransparency = 1
					frame.ZIndex = 2

					local icon = Instance.new('ImageLabel')
					icon.Name = 'Icon'
					icon.BackgroundTransparency = 1
					icon.Size = UDim2.new(0,36,0,36)
					icon.Position = UDim2.new(0,12,0,12)
					icon.ZIndex = 3
					icon.Parent = frame

					local nameLabel = Instance.new('TextLabel')
					nameLabel.Name = 'NameLabel'
					nameLabel.TextXAlignment = Enum.TextXAlignment.Left
					nameLabel.Font = 'SourceSans'
					nameLabel.FontSize = 'Size24'
					nameLabel.TextColor3 = Color3.new(1,1,1)
					nameLabel.BackgroundTransparency = 1
					nameLabel.Position = UDim2.new(0,60,.5,0)
					nameLabel.Size = UDim2.new(0,0,0,0)
					nameLabel.ZIndex = 3
					nameLabel.Parent = frame

					frame.MouseEnter:connect(function()
						frame.ImageTransparency = frameSelectedTransparency
					end)
					frame.MouseLeave:connect(function()
						frame.ImageTransparency = frameDefaultTransparency
					end)

					frame.Parent = this.Page
					table.insert(existingPlayerLabels, index, frame)
				end
				frame.Name = 'PlayerLabel'..player.Name
				frame.Icon.Image = 'https://www.roblox.com/Thumbs/Avatar.ashx?x=100&y=100&userId='..math.max(1, player.UserId)
				frame.NameLabel.Text = player.Name
				frame.ImageTransparency = frameDefaultTransparency

				friendStatusCreate(frame, player)
			end
		end

		-- iterate through existing labels in reverse to destroy and remove unused labels
		for index=#existingPlayerLabels, 1, -1 do
			local player = sortedPlayers[index]
			local frame = existingPlayerLabels[index]
			if frame and not player then
				table.remove(existingPlayerLabels, i)
				frame:Destroy()
			end
		end

		this.Page.Size = UDim2.new(1,0,0, extraOffset + 80 * #sortedPlayers - 5)
	end)

	return this
end

----------- Public Facing API Additions --------------
PageInstance = Initialize()

return PageInstance
