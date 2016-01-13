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
local HttpService = game:GetService('HttpService')
local HttpRbxApiService = game:GetService('HttpRbxApiService')
local Settings = UserSettings()
local GameSettings = Settings.GameSettings

----------- UTILITIES --------------
RobloxGui:WaitForChild("Modules"):WaitForChild("TenFootInterface")
local utility = require(RobloxGui.Modules.Settings.Utility)
local isTenFootInterface = require(RobloxGui.Modules.TenFootInterface):IsEnabled()

------------ Variables -------------------
local PageInstance = nil
local localPlayer = PlayersService.LocalPlayer

----------- CLASS DECLARATION --------------

local function Initialize()
	local settingsPageFactory = require(RobloxGui.Modules.Settings.SettingsPageFactory)
	local this = settingsPageFactory:CreateNewPage()

	local BinbableFunction_SendNotification = nil
	spawn(function()
		BinbableFunction_SendNotification = RobloxGui:WaitForChild("SendNotification")
	end)

	--[[ Follower Notifications ]]--
	local function sendNotification(title, text, image, duration, callback)
		if BinbableFunction_SendNotification then
			BinbableFunction_SendNotification:Invoke(title, text, image, duration, callback)
		end
	end

	------ TAB CUSTOMIZATION -------
	this.TabHeader.Name = "PlayersTab"

	this.TabHeader.Icon.Image = "rbxasset://textures/ui/Settings/MenuBarIcons/PlayersTabIcon.png"
	if utility:IsSmallTouchScreen() then
		this.TabHeader.Icon.Size = UDim2.new(0,34,0,28)
		this.TabHeader.Icon.Position = UDim2.new(this.TabHeader.Icon.Position.X.Scale,this.TabHeader.Icon.Position.X.Offset,0.5,-14)
		this.TabHeader.Size = UDim2.new(0,115,1,0)
	elseif isTenFootInterface then
		this.TabHeader.Icon.Image = "rbxasset://textures/ui/Settings/MenuBarIcons/PlayersTabIcon@2x.png"
		this.TabHeader.Icon.Size = UDim2.new(0,88,0,74)
		this.TabHeader.Icon.Position = UDim2.new(0,0,0.5,-43)
		this.TabHeader.Size = UDim2.new(0,280,1,0)
	else
		this.TabHeader.Icon.Size = UDim2.new(0,44,0,37)
		this.TabHeader.Icon.Position = UDim2.new(0,15,0.5,-18)	-- -22
		this.TabHeader.Size = UDim2.new(0,150,1,0)
	end

	this.TabHeader.Icon.Title.Text = "Players"


	----- FRIENDSHIP FUNCTIONS ------
	local function getFriendStatus(selectedPlayer)
		if selectedPlayer == localPlayer then
			return Enum.FriendStatus.NotFriend
		else
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
	end

	------ PAGE CUSTOMIZATION -------
	this.Page.Name = "Players"

	local function friendStatusCreate(playerLabel, player)
		if playerLabel then
			-- remove any previous friend status labels
			for _, item in pairs(playerLabel:GetChildren()) do
				if item and item.Name == 'FriendStatus' then
					item:Destroy()
				end
			end

			-- create new friend status label
			if player and player ~= localPlayer and player.userId > 1 then
				local status = getFriendStatus(player)
				if status == Enum.FriendStatus.Friend then 
					local friendLabel = Instance.new('TextLabel')
					friendLabel.Name = 'FriendStatus'
					friendLabel.Text = 'Friend'
					friendLabel.BackgroundTransparency = 1
					friendLabel.Font = 'SourceSans'
					friendLabel.FontSize = 'Size24'
					friendLabel.TextColor3 = Color3.new(1,1,1)
					friendLabel.Size = UDim2.new(0,182,0,46)
					friendLabel.Position = UDim2.new(1,-198,0,7)
					friendLabel.ZIndex = 3
					friendLabel.Parent = playerLabel
				elseif status == Enum.FriendStatus.Unknown or status == Enum.FriendStatus.NotFriend or status == Enum.FriendStatus.FriendRequestReceived then
					local addButton = Instance.new('TextButton')
					addButton.Name = 'FriendStatus'
					addButton.Text = 'Add Friend'
					addButton.Style = 'RobloxRoundButton'
					addButton.Font = 'SourceSansBold'
					addButton.FontSize = 'Size24'
					addButton.TextColor3 = Color3.new(1,1,1)
					addButton.Size = UDim2.new(0,182,0,46)
					addButton.Position = UDim2.new(1,-198,0,7)
					addButton.ZIndex = 3
					addButton.MouseButton1Down:connect(function()
						localPlayer:RequestFriendship(player)
						if addButton then
							addButton:Destroy()
						end
					end)
					addButton.Parent = playerLabel
				elseif status == Enum.FriendStatus.FriendRequestSent then
					local friendLabel = Instance.new('TextLabel')
					friendLabel.Name = 'FriendStatus'
					friendLabel.Text = 'Request Sent'
					friendLabel.BackgroundTransparency = 1
					friendLabel.Font = 'SourceSans'
					friendLabel.FontSize = 'Size24'
					friendLabel.TextColor3 = Color3.new(1,1,1)
					friendLabel.Size = UDim2.new(0,182,0,46)
					friendLabel.Position = UDim2.new(1,-198,0,7)
					friendLabel.ZIndex = 3
					friendLabel.Parent = playerLabel
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

	if utility:IsSmallTouchScreen() then
		local spaceFor3Buttons = RobloxGui.AbsoluteSize.x >= 720	-- else there is only space for 2

		local resetFunc = function()
			this.HubRef:SwitchToPage(this.HubRef.ResetCharacterPage, false, 1)
		end
		local resetButton, resetLabel = utility:MakeStyledButton("ResetButton", "Reset Character", UDim2.new(0, 200, 0, 62), resetFunc)
		resetLabel.Size = UDim2.new(1, 0, 1, -6)
		resetLabel.FontSize = Enum.FontSize.Size24
		resetButton.Position = UDim2.new(0.5,spaceFor3Buttons and -340 or -220,0,14)
		resetButton.Parent = this.Page

		local leaveGameFunc = function()
			this.HubRef:SwitchToPage(this.HubRef.LeaveGamePage, false, 1)
		end
		local leaveButton, leaveLabel = utility:MakeStyledButton("LeaveButton", "Leave Game", UDim2.new(0, 200, 0, 62), leaveGameFunc)
		leaveLabel.Size = UDim2.new(1, 0, 1, -6)
		leaveLabel.FontSize = Enum.FontSize.Size24
		leaveButton.Position = UDim2.new(0.5,spaceFor3Buttons and -100 or 20,0,14)
		leaveButton.Parent = this.Page

		if spaceFor3Buttons then
			local resumeGameFunc = function()
				this.HubRef:SetVisibility(false)
			end
			resumeButton, resumeLabel = utility:MakeStyledButton("ResumeButton", "Resume Game", UDim2.new(0, 200, 0, 62), resumeGameFunc)
			resumeLabel.Size = UDim2.new(1, 0, 1, -6)
			resumeLabel.FontSize = Enum.FontSize.Size24
			resumeButton.Position = UDim2.new(0.5,140,0,14)
			resumeButton.Parent = this.Page
		end
	end

	local existingPlayerLabels = {}
	local Opening = function()
		local sortedPlayers = game.Players:GetPlayers()
		table.sort(sortedPlayers,function(item1,item2)
			return item1.Name < item2.Name
		end)

		local extraOffset = 20
		if utility:IsSmallTouchScreen() then
			extraOffset = 85
		end

		local framesToDestroy = {}
		for index=1, math.max(#sortedPlayers,#existingPlayerLabels) do
			local player = sortedPlayers[index]
			local frame = existingPlayerLabels[index]
			if player then
				if not frame then
					frame = Instance.new('ImageLabel')
					frame.Image = "rbxasset://textures/ui/dialog_white.png"
					frame.ScaleType = 'Slice'
					frame.SliceCenter = Rect.new(10,10,10,10)
					frame.Size = UDim2.new(1,0,0,60)
					frame.Position = UDim2.new(0,0,0,(index-1)*80 + extraOffset)
					frame.BackgroundTransparency = 1
					frame.ImageTransparency = .85
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

					frame.Parent = this.Page
					table.insert(existingPlayerLabels, index, frame)
				end
				frame.Name = 'PlayerLabel'..player.Name
				frame.Icon.Image = 'http://www.roblox.com/Thumbs/Avatar.ashx?x=100&y=100&userId='..math.max(1, player.userId)
				frame.NameLabel.Text = player.Name

				friendStatusCreate(frame, player)
			elseif frame then
				table.insert(framesToDestroy,frame)
			end
		end
		for i=#framesToDestroy, 1, -1 do
			local frame = framesToDestroy[i]
			if frame then
				frame:Destroy()
			end
		end

		this.Page.Size = UDim2.new(1,0,0, extraOffset + 80 * #sortedPlayers - 5)
	end
	this.Opening = Opening

	return this
end


----------- Public Facing API Additions --------------
PageInstance = Initialize()


return PageInstance



