--[[
		// FileName: PlayerlistModule.lua
		// Version 1.3
		// Written by: jmargh
		// Description: Implementation of in game player list and leaderboard
]]
local CoreGui = game:GetService'CoreGui'
local GuiService = game:GetService('GuiService')	-- NOTE: Can only use in core scripts
local UserInputService = game:GetService('UserInputService')
local HttpService = game:GetService('HttpService')
local HttpRbxApiService = game:GetService('HttpRbxApiService')
local Players = game:GetService('Players')
local TeamsService = game:FindService('Teams')
local ContextActionService = game:GetService('ContextActionService')
local RobloxReplicatedStorage = nil	-- NOTE: Can only use in core scripts

local RbxGuiLibrary = nil
if LoadLibrary then
	RbxGuiLibrary = LoadLibrary("RbxGui")
end

while not Players.LocalPlayer do
	wait()
end
local Player = Players.LocalPlayer
local RobloxGui = CoreGui:WaitForChild('RobloxGui')

--[[ Fast Flags ]]--
local newSettingsSuccess, newSettingsEnabled = pcall(function() return settings():GetFFlag("NewMenuSettingsScript") end)
local serverCoreScriptsSuccess, serverCoreScriptsEnabled = pcall(function() return settings():GetFFlag("UseServerCoreScripts") end)
local gamepadSupportSuccess, gamepadSupportFlagValue = pcall(function() return settings():GetFFlag("TopbarGamepadSupport") end)
--
local IsNewSettings = newSettingsSuccess and newSettingsEnabled
local IsServerCoreScripts = serverCoreScriptsSuccess and serverCoreScriptsEnabled
local IsGamepadSupported = gamepadSupportSuccess and gamepadSupportFlagValue

--[[ Start Module ]]--
local Playerlist = {}

--[[ Public Event API ]]--
-- Parameters: Sorted Array - see GameStats below
Playerlist.OnLeaderstatsChanged = Instance.new('BindableEvent')
-- Parameters: nameOfStat(string), formatedStringOfStat(string)
Playerlist.OnStatChanged = Instance.new('BindableEvent')

--[[ Client Stat Table ]]--
-- Sorted Array of tables
local GameStats = {}
-- Fields
	-- Name: String the developer has given the stat
	-- Text: Formated string of the stat value
	-- AddId: Child add order id
	-- IsPrimary: Is this the primary stat
	-- Priority: Sorting priority
-- NOTE: IsPrimary and Priority are unofficially supported. They are left over legacy from the old player list.
-- They can be un-supported at anytime. You should prefer using child add order to order your stats in the leader board.

--[[ Script Variables ]]--
local MyPlayerEntry = nil
local PlayerEntries = {}
local StatAddId = 0
local TeamEntries = {}
local TeamAddId = 0
local NeutralTeam = nil
local IsShowingNeutralFrame = false
local LastSelectedFrame = nil
local LastSelectedPlayer = nil
local MinContainerSize = UDim2.new(0, 165, 0.5, 0)
local PlayerEntrySizeY = 24
local TeamEntrySizeY = 18
local NameEntrySizeX = 170
local StatEntrySizeX = 75
local IsSmallScreenDevice = UserInputService.TouchEnabled and GuiService:GetScreenResolution().Y <= 500

--[[ Bindables ]]--
local BinbableFunction_SendNotification = RobloxGui:FindFirstChild('SendNotification')

--[[ Remotes ]]--
local RemoteEvent_OnNewFollower = nil 	-- we get this later in the script

local IsPersonalServer = false
local PersonalServerService = nil
if workspace:FindFirstChild('PSVariable') then
	IsPersonalServer = true
	PersonalServerService = game:GetService('PersonalServerService')
end
workspace.ChildAdded:connect(function(child)
	if child.Name == 'PSVariable' and child:IsA('BoolValue') then
		IsPersonalServer = true
		PersonalServerService = game:GetService('PersonalServerService')
	end
end)

--Report Abuse
local AbusingPlayer = nil
local AbuseReason = nil

--[[ Constants ]]--
local ENTRY_PAD = 2
local BG_TRANSPARENCY = 0.5
local BG_COLOR = Color3.new(31/255, 31/255, 31/255)
local TEXT_STROKE_TRANSPARENCY = 0.75
local TEXT_COLOR = Color3.new(1, 1, 243/255)
local TEXT_STROKE_COLOR = Color3.new(34/255, 34/255, 34/255)
local TWEEN_TIME = 0.15
local MAX_LEADERSTATS = 4
local MAX_STR_LEN = 12
local MAX_FRIEND_COUNT = 200

local ADMINS = {	-- Admins with special icons
    ['7210880'] = 'http://www.roblox.com/asset/?id=134032333', -- Jeditkacheff
    ['13268404'] = 'http://www.roblox.com/asset/?id=113059239', -- Sorcus
    ['261'] = 'http://www.roblox.com/asset/?id=105897927', -- shedlestky
    ['20396599'] = 'http://www.roblox.com/asset/?id=161078086', -- Robloxsai
}

local ABUSES = {
	"Swearing",
	"Bullying",
	"Scamming",
	"Dating",
	"Cheating/Exploiting",
	"Personal Questions",
	"Offsite Links",
	"Bad Username",
}

local FOLLOWER_STATUS = {
	FOLLOWER = 0,
	FOLLOWING = 1,
	MUTUAL = 2,
}

local PRIVILEGE_LEVEL = {
	OWNER = 255,
	ADMIN = 240,
	MEMBER = 128,
	VISITOR = 10,
	BANNED = 0,
}

--[[ Images ]]--
local CHAT_ICON = 'rbxasset://textures/ui/chat_teamButton.png'
local ADMIN_ICON = 'rbxasset://textures/ui/icon_admin-16.png'
local PLACE_OWNER_ICON = 'rbxasset://textures/ui/icon_placeowner.png'
local BC_ICON = 'rbxasset://textures/ui/icon_BC-16.png'
local TBC_ICON = 'rbxasset://textures/ui/icon_TBC-16.png'
local OBC_ICON = 'rbxasset://textures/ui/icon_OBC-16.png'
local FRIEND_ICON = 'rbxasset://textures/ui/icon_friends_16.png'
local FRIEND_REQUEST_ICON = 'rbxasset://textures/ui/icon_friendrequestsent_16.png'
local FRIEND_RECEIVED_ICON = 'rbxasset://textures/ui/icon_friendrequestrecieved-16.png'

local FOLLOWER_ICON = 'rbxasset://textures/ui/icon_follower-16.png'
local FOLLOWING_ICON = 'rbxasset://textures/ui/icon_following-16.png'
local MUTUAL_FOLLOWING_ICON = 'rbxasset://textures/ui/icon_mutualfollowing-16.png'

local FRIEND_IMAGE = 'http://www.roblox.com/thumbs/avatar.ashx?userId='

--[[ Helper Functions ]]--
local function clamp(value, min, max)
	if value < min then
		value = min
	elseif value > max then
		value = max
	end

	return value
end

local function getFriendStatus(selectedPlayer)
	if selectedPlayer == Player then
		return Enum.FriendStatus.NotFriend
	else
		local success, result = pcall(function()
			-- NOTE: Core script only
			return Player:GetFriendStatus(selectedPlayer)
		end)
		if success then
			return result
		else
			return Enum.FriendStatus.NotFriend
		end
	end
end

-- Returns whether followerUserId is following userId
local function isFollowing(userId, followerUserId)
	local apiPath = "user/following-exists?userId="
	local params = userId.."&followerUserId="..followerUserId
	local success, result = pcall(function()
		return HttpRbxApiService:GetAsync(apiPath..params, true)
	end)
	if not success then
		print("isFollowing() failed because", result)
		return false
	end

	-- can now parse web response
	result = HttpService:JSONDecode(result)
	return result["success"] and result["isFollowing"]
end

local function getFollowerStatus(selectedPlayer)
	if selectedPlayer == Player then
		return nil
	end

	-- ignore guest
	if selectedPlayer.userId <= 0 or Player.userId <= 0 then
		return
	end

	local myUserId = tostring(Player.userId)
	local theirUserId = tostring(selectedPlayer.userId)

	local isFollowingMe = isFollowing(myUserId, theirUserId)
	local isFollowingThem = isFollowing(theirUserId, myUserId)

	if isFollowingMe and isFollowingThem then 	-- mutual
		return FOLLOWER_STATUS.MUTUAL
	elseif isFollowingMe then
		return FOLLOWER_STATUS.FOLLOWER
	elseif isFollowingThem then
		return FOLLOWER_STATUS.FOLLOWING
	else
		return nil
	end
end

local function getFriendStatusIcon(friendStatus)
	if friendStatus == Enum.FriendStatus.Unknown or friendStatus == Enum.FriendStatus.NotFriend then
		return nil
	elseif friendStatus == Enum.FriendStatus.Friend then
		return FRIEND_ICON
	elseif friendStatus == Enum.FriendStatus.FriendRequestSent then
		return FRIEND_REQUEST_ICON
	elseif friendStatus == Enum.FriendStatus.FriendRequestReceived then
		return FRIEND_RECEIVED_ICON
	else
		error("PlayerList: Unknown value for friendStatus: "..tostring(friendStatus))
	end
end

local function getFollowerStatusIcon(followerStatus)
	if followerStatus == FOLLOWER_STATUS.MUTUAL then
		return MUTUAL_FOLLOWING_ICON
	elseif followerStatus == FOLLOWER_STATUS.FOLLOWING then
		return FOLLOWING_ICON
	elseif followerStatus == FOLLOWER_STATUS.FOLLOWER then
		return FOLLOWER_ICON
	else
		return nil
	end
end

local function getAdminIcon(player)
	local userIdStr = tostring(player.userId)
	if ADMINS[userIdStr] then return nil end
	--
	local success, result = pcall(function()
		return player:IsInGroup(1200769)	-- yields
	end)
	if not success then
		print("PlayerListScript2: getAdminIcon() failed because", result)
		return nil
	end
	--
	if result then
		return ADMIN_ICON
	end
end

local function getMembershipIcon(player)
	local userIdStr = tostring(player.userId)
	local membershipType = player.MembershipType
	if ADMINS[userIdStr] then
		return ADMINS[userIdStr]
	elseif player.userId == game.CreatorId and game.CreatorType == Enum.CreatorType.User then
		return PLACE_OWNER_ICON
	elseif membershipType == Enum.MembershipType.None then
		return nil
	elseif membershipType == Enum.MembershipType.BuildersClub then
		return BC_ICON
	elseif membershipType == Enum.MembershipType.TurboBuildersClub then
		return TBC_ICON
	elseif membershipType == Enum.MembershipType.OutrageousBuildersClub then
		return OBC_ICON
	else
		error("PlayerList: Unknown value for membershipType"..tostring(membershipType))
	end
end

local function isValidStat(obj)
	return obj:IsA('StringValue') or obj:IsA('IntValue') or obj:IsA('BoolValue') or obj:IsA('NumberValue') or
		obj:IsA('DoubleConstrainedValue') or obj:IsA('IntConstrainedValue')
end

local function sortPlayerEntries(a, b)
	if a.PrimaryStat == b.PrimaryStat then
		return a.Player.Name:upper() < b.Player.Name:upper()
	end
	if not a.PrimaryStat then return false end
	if not b.PrimaryStat then return true end
	return a.PrimaryStat > b.PrimaryStat
end

local function sortLeaderStats(a, b)
	if a.IsPrimary ~= b.IsPrimary then
		return a.IsPrimary
	end
	if a.Priority == b.Priority then
		return a.AddId < b.AddId
	end
	return a.Priority < b.Priority
end

local function sortTeams(a, b)
	if a.TeamScore == b.TeamScore then
		return a.Id < b.Id
	end
	if not a.TeamScore then return false end
	if not b.TeamScore then return true end
	return a.TeamScore < b.TeamScore
end

local function sendNotification(title, text, image, duration, callback)
	if BinbableFunction_SendNotification then
		BinbableFunction_SendNotification:Invoke(title, text, image, duration, callback)
	end
end

-- Start of Gui Creation
local Container = Instance.new('Frame')
Container.Name = "PlayerListContainer"
Container.Position = UDim2.new(1, -167, 0, 2)
Container.Size = MinContainerSize
Container.BackgroundTransparency = 1
Container.Visible = false
Container.Parent = RobloxGui

-- Scrolling Frame
local ScrollList = Instance.new('ScrollingFrame')
ScrollList.Name = "ScrollList"
ScrollList.Size = UDim2.new(1, -1, 0, 0)
ScrollList.BackgroundTransparency = 1
ScrollList.BackgroundColor3 = Color3.new()
ScrollList.BorderSizePixel = 0
ScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)	-- NOTE: Look into if x needs to be set to anything
ScrollList.ScrollBarThickness = 6
ScrollList.BottomImage = 'rbxasset://textures/ui/scroll-bottom.png'
ScrollList.MidImage = 'rbxasset://textures/ui/scroll-middle.png'
ScrollList.TopImage = 'rbxasset://textures/ui/scroll-top.png'
ScrollList.Parent = Container

-- Friend/Report Popup
local PopupFrame = nil
local PopupClipFrame = Instance.new('Frame')
PopupClipFrame.Name = "PopupClipFrame"
PopupClipFrame.Size = UDim2.new(0, 150, 1.5, 0)
PopupClipFrame.Position = UDim2.new(0, -150 - ENTRY_PAD, 0, 0)
PopupClipFrame.BackgroundTransparency = 1
PopupClipFrame.ClipsDescendants = true
PopupClipFrame.Parent = Container

-- Report Abuse Gui
local ReportAbuseShield = Instance.new('TextButton')
ReportAbuseShield.Name = "ReportAbuseShield"
ReportAbuseShield.Size = UDim2.new(1, 0, 1, 36)
ReportAbuseShield.Position = UDim2.new(0, 0, 0, -36)
ReportAbuseShield.BackgroundColor3 = Color3.new(51/255, 51/255, 51/255)
ReportAbuseShield.BackgroundTransparency = 0.4
ReportAbuseShield.ZIndex = 1
ReportAbuseShield.Text = ""
ReportAbuseShield.AutoButtonColor = false

	local ReportAbuseFrame = Instance.new('Frame')
	ReportAbuseFrame.Name = "ReportAbuseFrame"
	ReportAbuseFrame.Size = UDim2.new(0, 525, 0, 390)
	ReportAbuseFrame.Position = UDim2.new(0.5, -262, 0.5, -195)
	ReportAbuseFrame.BackgroundTransparency = 0.7
	ReportAbuseFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	ReportAbuseFrame.Style = Enum.FrameStyle.DropShadow
	ReportAbuseFrame.Parent = ReportAbuseShield

		local reportYOffset = 24
		local ReportAbuseTitle = Instance.new('TextLabel')
		ReportAbuseTitle.Name = "ReportAbuseTitle"
		ReportAbuseTitle.Text = "Report Abuse"
		ReportAbuseTitle.Size = UDim2.new(0, 0, 0, 0)
		ReportAbuseTitle.Position = UDim2.new(0.5, 0, 0, reportYOffset)
		ReportAbuseTitle.BackgroundTransparency = 1
		ReportAbuseTitle.Font = Enum.Font.SourceSansBold
		ReportAbuseTitle.FontSize = Enum.FontSize.Size36
		ReportAbuseTitle.TextColor3 = Color3.new(1, 1, 1)
		ReportAbuseTitle.Parent = ReportAbuseFrame
		reportYOffset = reportYOffset + 32

		local ReportAbuseDescription = Instance.new('TextLabel')
		ReportAbuseDescription.Name = "ReportAbuseDescription"
		ReportAbuseDescription.Text = "This will send a complete report to a moderator.  The moderator will review the chat log and take appropriate action."
		ReportAbuseDescription.Size = UDim2.new(1, -40, 0, 40)
		ReportAbuseDescription.Position = UDim2.new(0, 35, 0, reportYOffset)
		ReportAbuseDescription.BackgroundTransparency = 1
		ReportAbuseDescription.Font = Enum.Font.SourceSans
		ReportAbuseDescription.FontSize = Enum.FontSize.Size18
		ReportAbuseDescription.TextColor3 = Color3.new(1, 1, 1)
		ReportAbuseDescription.TextWrap = true
		ReportAbuseDescription.TextXAlignment = Enum.TextXAlignment.Left
		ReportAbuseDescription.TextYAlignment = Enum.TextYAlignment.Top
		ReportAbuseDescription.Parent = ReportAbuseFrame
		reportYOffset = reportYOffset + 70

		local ReportPlayerLabel = Instance.new('TextLabel')
		ReportPlayerLabel.Name = "ReportPlayerLabel"
		ReportPlayerLabel.Text = "Player Reporting:"
		ReportPlayerLabel.Size = UDim2.new(0, 0, 0, 0)
		ReportPlayerLabel.Position = UDim2.new(0.5, -6, 0, reportYOffset)
		ReportPlayerLabel.BackgroundTransparency = 1
		ReportPlayerLabel.Font = Enum.Font.SourceSans
		ReportPlayerLabel.FontSize = Enum.FontSize.Size18
		ReportPlayerLabel.TextColor3 = Color3.new(1, 1, 1)
		ReportPlayerLabel.TextXAlignment = Enum.TextXAlignment.Right
		ReportPlayerLabel.Parent = ReportAbuseFrame

		local ReportPlayerName = Instance.new('TextLabel')
		ReportPlayerName.Name = "ReportPlayerName"
		ReportPlayerName.Text = ""
		ReportPlayerName.Size = UDim2.new(0, 0, 0, 0)
		ReportPlayerName.Position = UDim2.new(0.5, 18, 0, reportYOffset)
		ReportPlayerName.BackgroundTransparency = 1
		ReportPlayerName.Font = Enum.Font.SourceSans
		ReportPlayerName.FontSize = Enum.FontSize.Size18
		ReportPlayerName.TextColor3 = Color3.new(1, 1, 1)
		ReportPlayerName.TextXAlignment = Enum.TextXAlignment.Left
		ReportPlayerName.Parent = ReportAbuseFrame
		reportYOffset = reportYOffset + 40

		local ReportReasonLabel = Instance.new('TextLabel')
		ReportReasonLabel.Name = "ReportReasonLabel"
		ReportReasonLabel.Text = "Type of Abuse:"
		ReportReasonLabel.Size = UDim2.new(0, 0, 0, 0)
		ReportReasonLabel.Position = UDim2.new(0.5, -6, 0, reportYOffset)
		ReportReasonLabel.BackgroundTransparency = 1
		ReportReasonLabel.Font = Enum.Font.SourceSans
		ReportReasonLabel.FontSize = Enum.FontSize.Size18
		ReportReasonLabel.TextColor3 = Color3.new(1, 1, 1)
		ReportReasonLabel.TextXAlignment = Enum.TextXAlignment.Right
		ReportReasonLabel.Parent = ReportAbuseFrame
		reportYOffset = reportYOffset + 40

		local ReportDescriptionLabel = ReportAbuseDescription:Clone()
		ReportDescriptionLabel.Name = "ReportDescriptionLabel"
		ReportDescriptionLabel.Text = "Short Description: (optional)"
		ReportDescriptionLabel.Position = UDim2.new(0, 35, 0, reportYOffset)
		ReportDescriptionLabel.Parent = ReportAbuseFrame
		reportYOffset = reportYOffset + 28

		local ReportDescriptionBox = Instance.new('TextBox')
		ReportDescriptionBox.Name = "ReportDescriptionBox"
		ReportDescriptionBox.Text = ""
		ReportDescriptionBox.Size = UDim2.new(1, -70, 1, -reportYOffset - 80)
		ReportDescriptionBox.Position = UDim2.new(0, 35, 0, reportYOffset)
		ReportDescriptionBox.BackgroundTransparency = 1
		ReportDescriptionBox.Font = Enum.Font.SourceSans
		ReportDescriptionBox.FontSize = Enum.FontSize.Size18
		ReportDescriptionBox.TextColor3 = Color3.new(0, 0, 0)
		ReportDescriptionBox.TextXAlignment = Enum.TextXAlignment.Left
		ReportDescriptionBox.TextYAlignment = Enum.TextYAlignment.Top
		ReportDescriptionBox.TextWrap = true
		ReportDescriptionBox.ClearTextOnFocus = false
		ReportDescriptionBox.Parent = ReportAbuseFrame

		local ReportDescriptionBg = Instance.new('TextButton')
		ReportDescriptionBg.Name = "ReportDescriptionBg"
		ReportDescriptionBg.Size = UDim2.new(1, 16, 1, 16)
		ReportDescriptionBg.Position = UDim2.new(0, -8, 0, -8)
		ReportDescriptionBg.Text = ""
		ReportDescriptionBg.Active = false
		ReportDescriptionBg.AutoButtonColor = false
		ReportDescriptionBg.Style = Enum.ButtonStyle.RobloxRoundDropdownButton
		ReportDescriptionBg.Parent = ReportDescriptionBox
		reportYOffset = reportYOffset + ReportDescriptionBox.AbsoluteSize.y + 20

		local ReportSubmitButton = Instance.new('TextButton')
		ReportSubmitButton.Name = "ReportSubmitButton"
		ReportSubmitButton.Text = "Submit"
		ReportSubmitButton.Size = UDim2.new(0, 168, 0, 50)
		ReportSubmitButton.Position = UDim2.new(0.5, 2, 0, reportYOffset)
		ReportSubmitButton.Font = Enum.Font.SourceSansBold
		ReportSubmitButton.FontSize = Enum.FontSize.Size24
		ReportSubmitButton.TextColor3 = Color3.new(163/255, 162/255, 165/255)
		ReportSubmitButton.Active = false
		ReportSubmitButton.AutoButtonColor = true
		ReportSubmitButton.Modal = true
		ReportSubmitButton.Style = Enum.ButtonStyle.RobloxRoundDefaultButton
		ReportSubmitButton.Parent = ReportAbuseFrame

		local ReportCanelButton = Instance.new('TextButton')
		ReportCanelButton.Name = "ReportCanelButton"
		ReportCanelButton.Text = "Cancel"
		ReportCanelButton.Size = UDim2.new(0, 168, 0, 50)
		ReportCanelButton.Position = UDim2.new(0.5, -170, 0, reportYOffset)
		ReportCanelButton.Font = Enum.Font.SourceSansBold
		ReportCanelButton.FontSize = Enum.FontSize.Size24
		ReportCanelButton.TextColor3 = Color3.new(1, 1, 1)
		ReportCanelButton.Style = Enum.ButtonStyle.RobloxRoundButton
		ReportCanelButton.Parent = ReportAbuseFrame

		local AbuseDropDown, updateAbuseSelection = nil, nil
		if IsNewSettings then
			AbuseDropDown = RbxGuiLibrary.CreateScrollingDropDownMenu(
				function(text)
					AbuseReason = text
					if AbuseReason and AbusingPlayer then
						ReportSubmitButton.Active = true
						ReportSubmitButton.TextColor3 = Color3.new(1, 1, 1)
					end
				end, UDim2.new(0, 200, 0, 32), UDim2.new(0.5, 6, 0, ReportReasonLabel.Position.Y.Offset - 16), 1)
			AbuseDropDown.CreateList(ABUSES)
			AbuseDropDown.Frame.Parent = ReportAbuseFrame
		else
			AbuseDropDown, updateAbuseSelection = RbxGuiLibrary.CreateDropDownMenu(ABUSES,
				function(abuseText)
					AbuseReason = abuseText
					if AbuseReason and AbusingPlayer then
						ReportSubmitButton.Active = true
						ReportSubmitButton.TextColor3 = Color3.new(1, 1, 1)
					end
				end, true, true, 1)
			AbuseDropDown.Name = "AbuseDropDown"
			AbuseDropDown.Size = UDim2.new(0, 200, 0, 32)
			AbuseDropDown.Position = UDim2.new(0.5, 6, 0, ReportReasonLabel.Position.Y.Offset - 16)
			AbuseDropDown.Parent = ReportAbuseFrame
		end

-- Report Confirm Gui
local ReportConfirmFrame = Instance.new('Frame')
ReportConfirmFrame.Name = "ReportConfirmFrame"
ReportConfirmFrame.Size = UDim2.new(0, 400, 0, 170)
ReportConfirmFrame.Position = UDim2.new(0.5, -200, 0.5, -80)
ReportConfirmFrame.BackgroundTransparency = 0.7
ReportConfirmFrame.BackgroundColor3 = Color3.new(0, 0, 0)
ReportConfirmFrame.Style = Enum.FrameStyle.DropShadow

	local ReportConfirmHeader = Instance.new('TextLabel')
	ReportConfirmHeader.Name = "ReportConfirmHeader"
	ReportConfirmHeader.Size = UDim2.new(0, 0, 0, 0)
	ReportConfirmHeader.Position = UDim2.new(0.5, 0, 0, 14)
	ReportConfirmHeader.BackgroundTransparency = 1
	ReportConfirmHeader.Text = "Thank you for your Report"
	ReportConfirmHeader.Font = Enum.Font.SourceSans
	ReportConfirmHeader.FontSize = Enum.FontSize.Size36
	ReportConfirmHeader.TextColor3 = Color3.new(1, 1, 1)
	ReportConfirmHeader.Parent = ReportConfirmFrame

	local ReportConfirmText = Instance.new('TextLabel')
	ReportConfirmText.Name = "ReportConfirmText"
	ReportConfirmText.Text = "Our moderators will review your report and the chat log to determine what happened."
	ReportConfirmText.Size = UDim2.new(1, -20, 0, 40)
	ReportConfirmText.Position = UDim2.new(0, 10, 0, 46)
	ReportConfirmText.BackgroundTransparency = 1
	ReportConfirmText.Font = Enum.Font.SourceSans
	ReportConfirmText.FontSize = Enum.FontSize.Size18
	ReportConfirmText.TextColor3 = Color3.new(1, 1, 1)
	ReportConfirmText.TextWrap = true
	ReportConfirmText.TextXAlignment = Enum.TextXAlignment.Left
	ReportConfirmText.TextYAlignment = Enum.TextYAlignment.Top
	ReportConfirmText.Parent = ReportConfirmFrame

	local ReportConfirmButton = Instance.new('TextButton')
	ReportConfirmButton.Name = "ReportConfirmButton"
	ReportConfirmButton.Text = "OK"
	ReportConfirmButton.Size = UDim2.new(0, 168, 0, 50)
	ReportConfirmButton.Position = UDim2.new(0.5, -81, 1, -60)
	ReportConfirmButton.Font = Enum.Font.SourceSans
	ReportConfirmButton.FontSize = Enum.FontSize.Size24
	ReportConfirmButton.TextColor3 = Color3.new(1, 1, 1)
	ReportConfirmButton.Style = Enum.ButtonStyle.RobloxRoundDefaultButton
	ReportConfirmButton.Parent = ReportConfirmFrame

	local function onReportConfirmPressed()
		ReportConfirmFrame.Parent = nil
		ReportAbuseShield.Parent = nil
		ReportAbuseFrame.Parent = ReportAbuseShield
	end
	ReportConfirmButton.MouseButton1Click:connect(onReportConfirmPressed)

--[[ Creation Helper Functions ]]--
local function createEntryFrame(name, sizeYOffset)
	local containerFrame = Instance.new('Frame')
	containerFrame.Name = name
	containerFrame.Position = UDim2.new(0, 0, 0, 0)
	containerFrame.Size = UDim2.new(1, 0, 0, sizeYOffset)
	containerFrame.BackgroundTransparency = 1

	local nameFrame = Instance.new('TextButton')
	nameFrame.Name = "BGFrame"
	nameFrame.Position = UDim2.new(0, 0, 0, 0)
	nameFrame.Size = UDim2.new(0, NameEntrySizeX, 0, sizeYOffset)
	nameFrame.BackgroundTransparency = BG_TRANSPARENCY
	nameFrame.BackgroundColor3 = BG_COLOR
	nameFrame.BorderSizePixel = 0
	nameFrame.ClipsDescendants = true
	nameFrame.AutoButtonColor = false
	nameFrame.Text = ""
	nameFrame.Parent = containerFrame

	return containerFrame, nameFrame
end

local function createEntryNameText(name, text, sizeXOffset, posXOffset)
	local nameLabel = Instance.new('TextLabel')
	nameLabel.Name = name
	nameLabel.Size = UDim2.new(-0.01, sizeXOffset, 0.5, 0)
	nameLabel.Position = UDim2.new(0.01, posXOffset, 0.245, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.SourceSans
	nameLabel.FontSize = Enum.FontSize.Size14
	nameLabel.TextColor3 = TEXT_COLOR
	nameLabel.TextStrokeTransparency = TEXT_STROKE_TRANSPARENCY
	nameLabel.TextStrokeColor3 = TEXT_STROKE_COLOR
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = text

	return nameLabel
end

local function createStatFrame(offset, parent, name)
	local statFrame = Instance.new('Frame')
	statFrame.Name = name
	statFrame.Size = UDim2.new(0, StatEntrySizeX, 1, 0)
	statFrame.Position = UDim2.new(0, offset + 2, 0, 0)
	statFrame.BackgroundTransparency = BG_TRANSPARENCY
	statFrame.BackgroundColor3 = BG_COLOR
	statFrame.BorderSizePixel = 0
	statFrame.Parent = parent

	return statFrame
end

local function createStatText(parent, text)
	local statText = Instance.new('TextLabel')
	statText.Name = "StatText"
	statText.Size = UDim2.new(1, 0, 1, 0)
	statText.Position = UDim2.new(0, 0, 0, 0)
	statText.BackgroundTransparency = 1
	statText.Font = Enum.Font.SourceSans
	statText.FontSize = Enum.FontSize.Size14
	statText.TextColor3 = TEXT_COLOR
	statText.TextStrokeColor3 = TEXT_STROKE_COLOR
	statText.TextStrokeTransparency = TEXT_STROKE_TRANSPARENCY
	statText.Text = text
	statText.Active = true
	statText.Parent = parent

	return statText
end

local function createImageIcon(image, name, xOffset, parent)
	local imageLabel = Instance.new('ImageLabel')
	imageLabel.Name = name
	imageLabel.Size = UDim2.new(0, 16, 0, 16)
	imageLabel.Position = UDim2.new(0.01, xOffset, 0.5, -imageLabel.Size.Y.Offset/2)
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = image
	imageLabel.BorderSizePixel = 0
	imageLabel.Parent = parent

	return imageLabel
end

local function getScoreValue(statObject)
	if statObject:IsA('DoubleConstrainedValue') or statObject:IsA('IntConstrainedValue') then
		return statObject.ConstrainedValue
	elseif statObject:IsA('BoolValue') then
		if statObject.Value then return 1 else return 0 end
	else
		return statObject.Value
	end
end

local THIN_CHARS = "[^%[iIl\%.,']"
local function strWidth(str)
	return string.len(str) - math.floor(string.len(string.gsub(str, THIN_CHARS, "")) / 2)
end

local function formatNumber(value)
	local _,_,minusSign, int, fraction = tostring(value):find('([-]?)(%d+)([.]?%d*)')
	int = int:reverse():gsub("%d%d%d", "%1,")
	return minusSign..int:reverse():gsub("^,", "")..fraction
end

local function formatStatString(text)
	local numberValue = tonumber(text)
	if numberValue then
		text = formatNumber(numberValue)
	end

	if strWidth(text) <= MAX_STR_LEN then
		return text
	else
		return string.sub(text, 1, MAX_STR_LEN - 3).."..."
	end
end

--[[ Resize Functions ]]--
local LastMaxScrollSize = 0
local function setScrollListSize()
	local teamSize = #TeamEntries * TeamEntrySizeY
	local playerSize = #PlayerEntries * PlayerEntrySizeY
	local spacing = #PlayerEntries * ENTRY_PAD + #TeamEntries * ENTRY_PAD
	local canvasSize = teamSize + playerSize + spacing
	if #TeamEntries > 0 and NeutralTeam and IsShowingNeutralFrame then
		canvasSize = canvasSize + TeamEntrySizeY + ENTRY_PAD
	end
	ScrollList.CanvasSize = UDim2.new(0, 0, 0, canvasSize)
	local newScrollListSize = math.min(canvasSize, Container.AbsoluteSize.y)
	if ScrollList.Size.Y.Offset == LastMaxScrollSize then
		ScrollList.Size = UDim2.new(1, 0, 0, newScrollListSize)
	end
	LastMaxScrollSize = newScrollListSize
end

--[[ Re-position Functions ]]--
local function setPlayerEntryPositions()
	local position = 0
	for i = 1, #PlayerEntries do
		PlayerEntries[i].Frame.Position = UDim2.new(0, 0, 0, position)
		position = position + PlayerEntrySizeY + 2
	end
end

local function setTeamEntryPositions()
	local teams = {}
	for _,teamEntry in ipairs(TeamEntries) do
		local team = teamEntry.Team
		teams[tostring(team.TeamColor)] = {}
	end
	if NeutralTeam then
		teams.Neutral = {}
	end

	for _,playerEntry in ipairs(PlayerEntries) do
		local player = playerEntry.Player
		if player.Neutral then
			table.insert(teams.Neutral, playerEntry)
		elseif teams[tostring(player.TeamColor)] then
			table.insert(teams[tostring(player.TeamColor)], playerEntry)
		else
			table.insert(teams.Neutral, playerEntry)
		end
	end

	local position = 0
	for _,teamEntry in ipairs(TeamEntries) do
		local team = teamEntry.Team
		teamEntry.Frame.Position = UDim2.new(0, 0, 0, position)
		position = position + TeamEntrySizeY + 2
		local players = teams[tostring(team.TeamColor)]
		for _,playerEntry in ipairs(players) do
			playerEntry.Frame.Position = UDim2.new(0, 0, 0, position)
			position = position + PlayerEntrySizeY + 2
		end
	end
	if NeutralTeam then
		NeutralTeam.Frame.Position = UDim2.new(0, 0, 0, position)
		position = position + TeamEntrySizeY + 2
		if #teams.Neutral > 0 then
			IsShowingNeutralFrame = true
			local players = teams.Neutral
			for _,playerEntry in ipairs(players) do
				playerEntry.Frame.Position = UDim2.new(0, 0, 0, position)
				position = position + PlayerEntrySizeY + 2
			end
		else
			IsShowingNeutralFrame = false
		end
	end
end

local function setEntryPositions()
	table.sort(PlayerEntries, sortPlayerEntries)
	if #TeamEntries > 0 then
		setTeamEntryPositions()
	else
		setPlayerEntryPositions()
	end
end

--[[ Friend/Report Functions ]]--
local selectedEntryMovedCn = nil
local function createPopupFrame(buttons)
	local frame = Instance.new('Frame')
	frame.Name = "PopupFrame"
	frame.Size = UDim2.new(1, 0, 0, (PlayerEntrySizeY * #buttons) + (#buttons - ENTRY_PAD))
	frame.Position = UDim2.new(1, 1, 0, 0)
	frame.BackgroundTransparency = 1
	frame.Parent = PopupClipFrame

	for i,button in ipairs(buttons) do
		local btn = Instance.new('TextButton')
		btn.Name = button.Name
		btn.Size = UDim2.new(1, 0, 0, PlayerEntrySizeY)
		btn.Position = UDim2.new(0, 0, 0, PlayerEntrySizeY * (i - 1) + ((i - 1) * ENTRY_PAD))
		btn.BackgroundTransparency = BG_TRANSPARENCY
		btn.BackgroundColor3 = BG_COLOR
		btn.BorderSizePixel = 0
		btn.Text = button.Text
		btn.Font = Enum.Font.SourceSans
		btn.FontSize = Enum.FontSize.Size14
		btn.TextColor3 = TEXT_COLOR
		btn.TextStrokeTransparency = TEXT_STROKE_TRANSPARENCY
		btn.TextStrokeColor3 = TEXT_STROKE_COLOR
		btn.AutoButtonColor = true
		btn.Parent = frame

		btn.MouseButton1Click:connect(button.OnPress)
	end

	return frame
end

-- if userId = nil, then it will get count for local player
local function getFriendCountAsync(userId)
	local friendCount = nil
	local wasSuccess, result = pcall(function()
		local str = 'user/get-friendship-count'
		if userId then
			str = str..'?userId='..tostring(userId)
		end
		return HttpRbxApiService:GetAsync(str, true)
	end)
	if not wasSuccess then
		print("getFriendCountAsync() failed because", result)
		return nil
	end
	result = HttpService:JSONDecode(result)

	if result["success"] and result["count"] then
		friendCount = result["count"]
	end

	return friendCount
end

-- checks if we can send a friend request. Right now the only way we
-- can't is if one of the players is at the max friend limit
local function canSendFriendRequestAsync(otherPlayer)
	local theirFriendCount = getFriendCountAsync(otherPlayer.userId)
	local myFriendCount = getFriendCountAsync()

	-- assume max friends if web call fails
	if not myFriendCount or not theirFriendCount then
		return false
	end
	if myFriendCount < MAX_FRIEND_COUNT and theirFriendCount < MAX_FRIEND_COUNT then
		return true
	elseif myFriendCount >= MAX_FRIEND_COUNT then
		sendNotification("Cannot send friend request", "You are at the max friends limit.", "", 5, function() end)
		return false
	elseif theirFriendCount >= MAX_FRIEND_COUNT then
		sendNotification("Cannot send friend request", otherPlayer.Name.." is at the max friends limit.", "", 5, function() end)
		return false
	end
end

local function hideFriendReportPopup()
	if PopupFrame then
		PopupFrame:TweenPosition(UDim2.new(1, 1, 0, PopupFrame.Position.Y.Offset), Enum.EasingDirection.InOut,
			Enum.EasingStyle.Quad, TWEEN_TIME, true, function()
				PopupFrame:Destroy()
				PopupFrame = nil
				if selectedEntryMovedCn then
					selectedEntryMovedCn:disconnect()
					selectedEntryMovedCn = nil
				end
			end)
	end
	if LastSelectedFrame then
		for _,childFrame in pairs(LastSelectedFrame:GetChildren()) do
			if childFrame:IsA('TextButton') or childFrame:IsA('Frame') then
				childFrame.BackgroundColor3 = BG_COLOR
			end
		end
	end
	ScrollList.ScrollingEnabled = true
	LastSelectedFrame = nil
	LastSelectedPlayer = nil
end

local function updateSocialIcon(newIcon, bgFrame)
	local socialIcon = bgFrame:FindFirstChild('SocialIcon')
	local nameFrame = bgFrame:FindFirstChild('PlayerName')
	local offset = 19
	if socialIcon then
		if newIcon then
			socialIcon.Image = newIcon
		else
			if nameFrame then
				newSize = nameFrame.Size.X.Offset + socialIcon.Size.X.Offset + 2
				nameFrame.Size = UDim2.new(-0.01, newSize, 0.5, 0)
				nameFrame.Position = UDim2.new(0.01, offset, 0.245, 0)
			end
			socialIcon:Destroy()
		end
	elseif newIcon and bgFrame then
		socialIcon = createImageIcon(newIcon, "SocialIcon", offset, bgFrame)
		offset = offset + socialIcon.Size.X.Offset + 2
		if nameFrame then
			local newSize = bgFrame.Size.X.Offset - offset
			nameFrame.Size = UDim2.new(-0.01, newSize, 0.5, 0)
			nameFrame.Position = UDim2.new(0.01, offset, 0.245, 0)
		end
	end
end

local function onFollowerStatusChanged()
	if not LastSelectedFrame or not LastSelectedPlayer then
		return
	end

	-- don't update icon if already friends
	local friendStatus = getFriendStatus(LastSelectedPlayer)
	if friendStatus == Enum.FriendStatus.Friend then
		return
	end

	local bgFrame = LastSelectedFrame:FindFirstChild('BGFrame')
	local followerStatus = getFollowerStatus(LastSelectedPlayer)
	local newIcon = getFollowerStatusIcon(followerStatus)
	if bgFrame then
		updateSocialIcon(newIcon, bgFrame)
	end
end

-- Client follows followedUserId
local function onFollowButtonPressed()
	if not LastSelectedPlayer then return end
	--
	local followedUserId = tostring(LastSelectedPlayer.userId)
	local apiPath = "user/follow"
	local params = "followedUserId="..followedUserId
	local success, result = pcall(function()
		return HttpRbxApiService:PostAsync(apiPath, params, true, Enum.ThrottlingPriority.Default, Enum.HttpContentType.ApplicationUrlEncoded)
	end)
	if not success then
		print("followPlayer() failed because", result)
		hideFriendReportPopup()
		return
	end

	result = HttpService:JSONDecode(result)
	if result["success"] then
		sendNotification("You are", "now following "..LastSelectedPlayer.Name, FRIEND_IMAGE..followedUserId.."&x=48&y=48", 5, function() end)
		if RemoteEvent_OnNewFollower then
			RemoteEvent_OnNewFollower:FireServer(LastSelectedPlayer)
		end
		-- now update the social icon
		onFollowerStatusChanged()
	end

	hideFriendReportPopup()
end

-- TODO: Move this to the notifications script. For now I want to keep it here until the
-- new notifications system goes live
if IsServerCoreScripts then
	-- don't block the rest of the core gui
	spawn(function()
		RobloxReplicatedStorage = game:GetService('RobloxReplicatedStorage')
		RemoteEvent_OnNewFollower = RobloxReplicatedStorage:WaitForChild('OnNewFollower')
		--
		RemoteEvent_OnNewFollower.OnClientEvent:connect(function(followerRbxPlayer)
			sendNotification("New Follower", followerRbxPlayer.Name.."is now following you!",
				FRIEND_IMAGE..followerRbxPlayer.userId.."&x=48&y=48", 5, function() end)
		end)
	end)
end

-- Client unfollows followedUserId
local function onUnfollowButtonPressed()
	if not LastSelectedPlayer then return end
	--
	local apiPath = "user/unfollow"
	local params = "followedUserId="..tostring(LastSelectedPlayer.userId)
	local success, result = pcall(function()
		return HttpRbxApiService:PostAsync(apiPath, params, true, Enum.ThrottlingPriority.Default, Enum.HttpContentType.ApplicationUrlEncoded)
	end)
	if not success then
		print("unfollowPlayer() failed because", result)
		hideFriendReportPopup()
		return
	end

	result = HttpService:JSONDecode(result)
	if result["success"] then
		onFollowerStatusChanged()
	end

	hideFriendReportPopup()
	-- no need to send notification when someone unfollows
end

local function onFriendButtonPressed()
	if LastSelectedPlayer then
		local status = getFriendStatus(LastSelectedPlayer)
		if status == Enum.FriendStatus.Friend then
			Player:RevokeFriendship(LastSelectedPlayer)
		elseif status == Enum.FriendStatus.Unknown or status == Enum.FriendStatus.NotFriend then
			-- cache and spawn
			local cachedLastSelectedPlayer = LastSelectedPlayer
			spawn(function()
				-- check for max friends before letting them send the request
				if canSendFriendRequestAsync(cachedLastSelectedPlayer) then 	-- Yields
					if cachedLastSelectedPlayer and cachedLastSelectedPlayer.Parent == Players then
						Player:RequestFriendship(cachedLastSelectedPlayer)
					end
				end
			end)
		elseif status == Enum.FriendStatus.FriendRequestSent then
			Player:RevokeFriendship(LastSelectedPlayer)
		elseif status == Enum.FriendStatus.FriendRequestReceived then
			Player:RequestFriendship(LastSelectedPlayer)
		end

		hideFriendReportPopup()
	end
end

local function onReportButtonPressed()
	if LastSelectedPlayer then
		AbusingPlayer = LastSelectedPlayer
		ReportPlayerName.Text = AbusingPlayer.Name
		ReportAbuseShield.Parent = RobloxGui
		hideFriendReportPopup()
	end
end

local function resetReportDialog()
	AbuseReason = nil
	AbusingPlayer = nil
	if IsNewSettings and AbuseDropDown then 	-- FFlag
		AbuseDropDown.SetSelectionText("Choose One")
		if AbuseDropDown.IsOpen() then
			AbuseDropDown.Reset()
		end
	else
		updateAbuseSelection(nil)
	end
	ReportPlayerName.Text = ""
	ReportDescriptionBox.Text = ""
	ReportSubmitButton.Active = false
	ReportSubmitButton.TextColor3 = Color3.new(163/255, 162/255, 165/255)
end

local function onAbuseDialogCanceled()
	resetReportDialog()
	ReportAbuseShield.Parent = nil
end
ReportCanelButton.MouseButton1Click:connect(onAbuseDialogCanceled)

local function onAbuseDialogSubmit()
	if ReportSubmitButton.Active then
		if AbuseReason and AbusingPlayer then
			local success, errorMsg = pcall(function()
				Players:ReportAbuse(AbusingPlayer, AbuseReason, ReportDescriptionBox.Text)
			end)
			if not success then
				print("PlayerlistModule: Players:ReportAbuse() failed because", errorMsg)
			end
			resetReportDialog()
			ReportAbuseFrame.Parent = nil
			ReportConfirmFrame.Parent = ReportAbuseShield
		end
	end
end
ReportSubmitButton.MouseButton1Click:connect(onAbuseDialogSubmit)

local function onDeclineFriendButonPressed()
	if LastSelectedPlayer then
		Player:RevokeFriendship(LastSelectedPlayer)
		hideFriendReportPopup()
	end
end

local function onPrivilegeLevelSelect(player, rank)
	while player.PersonalServerRank < rank do
		PersonalServerService:Promote(player)
	end
	while player.PersonalServerRank > rank do
		PersonalServerService:Demote(player)
	end
end

local function createPersonalServerDialog(buttons, selectedPlayer)
	local showPersonalServerRanks = IsPersonalServer and Player.PersonalServerRank >= PRIVILEGE_LEVEL.ADMIN and
		Player.PersonalServerRank > selectedPlayer.PersonalServerRank
	if showPersonalServerRanks then
		table.insert(buttons, {
			Name = "BanButton",
			Text = "Ban",
			OnPress = function()
				hideFriendReportPopup()
				onPrivilegeLevelSelect(selectedPlayer, PRIVILEGE_LEVEL.BANNED)
			end,
			})
		table.insert(buttons, {
			Name = "VistorButton",
			Text = "Visitor",
			OnPress = function()
				onPrivilegeLevelSelect(selectedPlayer, PRIVILEGE_LEVEL.VISITOR)
			end,
			})
		table.insert(buttons, {
			Name = "MemberButton",
			Text = "Member",
			OnPress = function()
				onPrivilegeLevelSelect(selectedPlayer, PRIVILEGE_LEVEL.MEMBER)
			end,
			})
		table.insert(buttons, {
			Name = "AdminButton",
			Text = "Admin",
			OnPress = function()
				onPrivilegeLevelSelect(selectedPlayer, PRIVILEGE_LEVEL.ADMIN)
			end,
			})
	end
end

local function showFriendReportPopup(selectedFrame, selectedPlayer)
	local buttons = {}

	local status = getFriendStatus(selectedPlayer)
	local friendText = ""
	local canDeclineFriend = false
	if status == Enum.FriendStatus.Friend then
		friendText = "Unfriend Player"
	elseif status == Enum.FriendStatus.Unknown or status == Enum.FriendStatus.NotFriend then
		friendText = "Send Friend Request"
	elseif status == Enum.FriendStatus.FriendRequestSent then
		friendText = "Revoke Friend Request"
	elseif status == Enum.FriendStatus.FriendRequestReceived then
		friendText = "Accept Friend Request"
		canDeclineFriend = true
	end

	table.insert(buttons, {
		Name = "FriendButton",
		Text = friendText,
		OnPress = onFriendButtonPressed,
		})
	if canDeclineFriend then
		table.insert(buttons, {
			Name = "DeclineFriend",
			Text = "Decline Friend Request",
			OnPress = onDeclineFriendButonPressed,
			})
	end
	-- following status
	local following = isFollowing(selectedPlayer.userId, Player.userId)
	local followerText = following and "Unfollow Player" or "Follow Player"
	table.insert(buttons, {
		Name = "FollowerButton",
		Text = followerText,
		OnPress = following and onUnfollowButtonPressed or onFollowButtonPressed,
		})
	table.insert(buttons, {
		Name = "ReportButton",
		Text = "Report Abuse",
		OnPress = onReportButtonPressed,
		})

	createPersonalServerDialog(buttons, selectedPlayer)
	if PopupFrame then
		PopupFrame:Destroy()
		if selectedEntryMovedCn then
			selectedEntryMovedCn:disconnect()
			selectedEntryMovedCn = nil
		end
	end
	PopupFrame = createPopupFrame(buttons)
	PopupFrame.Position = UDim2.new(1, 1, 0, selectedFrame.Position.Y.Offset - ScrollList.CanvasPosition.y)
	PopupFrame:TweenPosition(UDim2.new(0, 0, 0, selectedFrame.Position.Y.Offset - ScrollList.CanvasPosition.y), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, TWEEN_TIME, true)
	selectedEntryMovedCn = selectedFrame.Changed:connect(function(property)
		if property == "Position" then
			PopupFrame.Position = UDim2.new(0, 0, 0, selectedFrame.Position.Y.Offset - ScrollList.CanvasPosition.y)
		end
	end)
end

local function onEntryFrameSelected(selectedFrame, selectedPlayer)
	if selectedPlayer ~= Player and selectedPlayer.userId > 1 and Player.userId > 1 then
		if LastSelectedFrame ~= selectedFrame then
			if LastSelectedFrame then
				for _,childFrame in pairs(LastSelectedFrame:GetChildren()) do
					if childFrame:IsA('TextButton') or childFrame:IsA('Frame') then
						childFrame.BackgroundColor3 = BG_COLOR
					end
				end
			end
			LastSelectedFrame = selectedFrame
			LastSelectedPlayer = selectedPlayer
			for _,childFrame in pairs(selectedFrame:GetChildren()) do
				if childFrame:IsA('TextButton') or childFrame:IsA('Frame') then
					childFrame.BackgroundColor3 = Color3.new(0, 1, 1)
				end
			end
			-- NOTE: Core script only
			ScrollList.ScrollingEnabled = false
			showFriendReportPopup(selectedFrame, selectedPlayer)
		else
			hideFriendReportPopup()
			LastSelectedFrame = nil
			LastSelectedPlayer = nil
		end
	end
end

local function onFriendshipChanged(otherPlayer, newFriendStatus)
	local entryToUpdate = nil
	for _,entry in ipairs(PlayerEntries) do
		if entry.Player == otherPlayer then
			entryToUpdate = entry
			break
		end
	end
	if not entryToUpdate then
		return
	end
	local newIcon = getFriendStatusIcon(newFriendStatus)
	local frame = entryToUpdate.Frame
	local bgFrame = frame:FindFirstChild('BGFrame')
	if bgFrame then
		-- no longer friends, but might still be following
		if not newIcon then
			local followerStatus = getFollowerStatus(otherPlayer)
			newIcon = getFollowerStatusIcon(followerStatus)
		end

		updateSocialIcon(newIcon, bgFrame)
	end
end

-- NOTE: Core script only. This fires when a layer joins the game.
Player.FriendStatusChanged:connect(onFriendshipChanged)

local function updateAllTeamScores()
	local teamScores = {}
	for _,playerEntry in ipairs(PlayerEntries) do
		local player = playerEntry.Player
		local leaderstats = player:FindFirstChild('leaderstats')
		local team = player.Neutral and 'Neutral' or tostring(player.TeamColor)
		local isInValidColor = true
		if team ~= 'Neutral' then
			for _,teamEntry in ipairs(TeamEntries) do
				local color = teamEntry.Team.TeamColor
				if team == tostring(color) then
					isInValidColor = false
					break
				end
			end
		end
		if isInValidColor then
			team = 'Neutral'
		end
		if not teamScores[team] then
			teamScores[team] = {}
		end
		if leaderstats then
			for _,stat in ipairs(GameStats) do
				local statObject = leaderstats:FindFirstChild(stat.Name)
				if statObject and not statObject:IsA('StringValue') then
					if not teamScores[team][stat.Name] then
						teamScores[team][stat.Name] = 0
					end
					teamScores[team][stat.Name] = teamScores[team][stat.Name] + getScoreValue(statObject)
				end
			end
		end
	end

	for _,teamEntry in ipairs(TeamEntries) do
		local team = teamEntry.Team
		local frame = teamEntry.Frame
		local color = tostring(team.TeamColor)
		local stats = teamScores[color]
		if stats then
			for statName,statValue in pairs(stats) do
				local statFrame = frame:FindFirstChild(statName)
				if statFrame then
					local statText = statFrame:FindFirstChild('StatText')
					if statText then
						statText.Text = formatStatString(tostring(statValue))
					end
				end
			end
		else
			for _,childFrame in pairs(frame:GetChildren()) do
				local statText = childFrame:FindFirstChild('StatText')
				if statText then
					statText.Text = ''
				end
			end
		end
	end
	if NeutralTeam then
		local frame = NeutralTeam.Frame
		local stats = teamScores['Neutral']
		if stats then
			for statName,statValue in pairs(stats) do
				local statFrame = frame:FindFirstChild(statName)
				if statFrame then
					local statText = statFrame:FindFirstChild('StatText')
					if statText then
						statText.Text = formatStatString(tostring(statValue))
					end
				end
			end
		end
	end
end

local function updateTeamEntry(entry)
	local frame = entry.Frame
	local team = entry.Team
	local color = team.TeamColor.Color
	local offset = NameEntrySizeX
	for _,stat in ipairs(GameStats) do
		local statFrame = frame:FindFirstChild(stat.Name)
		if not statFrame then
			statFrame = createStatFrame(offset, frame, stat.Name)
			statFrame.BackgroundColor3 = color
			createStatText(statFrame, "")
		end
		statFrame.Position = UDim2.new(0, offset + 2, 0, 0)
		offset = offset + statFrame.Size.X.Offset + 2
	end
end

local function updatePrimaryStats(statName)
	for _,entry in ipairs(PlayerEntries) do
		local player = entry.Player
		local leaderstats = player:FindFirstChild('leaderstats')
		entry.PrimaryStat = nil
		if leaderstats then
			local statObject = leaderstats:FindFirstChild(statName)
			if statObject then
				local scoreValue = getScoreValue(statObject)
				entry.PrimaryStat = scoreValue
			end
		end
	end
end

local updateLeaderstatFrames = nil
-- TODO: fire event to top bar?
local function initializeStatText(stat, statObject, entry, statFrame, index)
	local player = entry.Player
	local statValue = getScoreValue(statObject)
	if statObject.Name == GameStats[1].Name then
		entry.PrimaryStat = statValue
	end
	local statText = createStatText(statFrame, formatStatString(tostring(statValue)))
	-- Top Bar insertion
	if player == Player then
		stat.Text = statText.Text
	end

	statObject.Changed:connect(function(newValue)
		local scoreValue = getScoreValue(statObject)
		statText.Text = formatStatString(tostring(scoreValue))
		if statObject.Name == GameStats[1].Name then
			entry.PrimaryStat = scoreValue
		end
		-- Top bar changed event
		if player == Player then
			stat.Text = statText.Text
			Playerlist.OnStatChanged:Fire(stat.Name, stat.Text)
		end
		updateAllTeamScores()
		setEntryPositions()
	end)
	statObject.ChildAdded:connect(function(child)
		if child.Name == "IsPrimary" then
			GameStats[1].IsPrimary = false
			stat.IsPrimary = true
			updatePrimaryStats(stat.Name)
			if updateLeaderstatFrames then updateLeaderstatFrames() end
			Playerlist.OnLeaderstatsChanged:Fire(GameStats)
		end
	end)
end

updateLeaderstatFrames = function()
	table.sort(GameStats, sortLeaderStats)
	if #TeamEntries > 0 then
		for _,entry in ipairs(TeamEntries) do
			updateTeamEntry(entry)
		end
		if NeutralTeam then
			updateTeamEntry(NeutralTeam)
		end
	end

	for _,entry in ipairs(PlayerEntries) do
		local player = entry.Player
		local mainFrame = entry.Frame
		local offset = NameEntrySizeX
		local leaderstats = player:FindFirstChild('leaderstats')

		if leaderstats then
			for _,stat in ipairs(GameStats) do
				local statObject = leaderstats:FindFirstChild(stat.Name)
				local statFrame = mainFrame:FindFirstChild(stat.Name)

				if not statFrame then
					statFrame = createStatFrame(offset, mainFrame, stat.Name)
					if statObject then
						initializeStatText(stat, statObject, entry, statFrame, _)
					end
				elseif statObject then
					local statText = statFrame:FindFirstChild('StatText')
					if not statText then
						initializeStatText(stat, statObject, entry, statFrame, _)
					end
				end
				statFrame.Position = UDim2.new(0, offset + 2, 0, 0)
				offset = offset + statFrame.Size.X.Offset + 2
			end
		else
			for _,stat in ipairs(GameStats) do
				local statFrame = mainFrame:FindFirstChild(stat.Name)
				if not statFrame then
					statFrame = createStatFrame(offset, mainFrame, stat.Name)
				end
				offset = offset + statFrame.Size.X.Offset + 2
			end
		end
		Container.Position = UDim2.new(1, -offset, 0, 2)
		Container.Size = UDim2.new(0, offset, 0.5, 0)
		local newMinContainerOffset = offset
		MinContainerSize = UDim2.new(0, newMinContainerOffset, 0.5, 0)
	end
	updateAllTeamScores()
	setEntryPositions()
	Playerlist.OnLeaderstatsChanged:Fire(GameStats)
end

local function addNewStats(leaderstats)
	for i,stat in ipairs(leaderstats:GetChildren()) do
		if isValidStat(stat) and #GameStats < MAX_LEADERSTATS then
			local gameHasStat = false
			for _,gStat in ipairs(GameStats) do
				if stat.Name == gStat.Name then
					gameHasStat = true
					break
				end
			end

			if not gameHasStat then
				local newStat = {}
				newStat.Name = stat.Name
				newStat.Text = "-"
				newStat.Priority = 0
				local priority = stat:FindFirstChild('Priority')
				if priority then newStat.Priority = priority end
				newStat.IsPrimary = false
				local isPrimary = stat:FindFirstChild('IsPrimary')
				if isPrimary then
					newStat.IsPrimary = true
				end
				newStat.AddId = StatAddId
				StatAddId = StatAddId + 1
				table.insert(GameStats, newStat)
				table.sort(GameStats, sortLeaderStats)
				if #GameStats == 1 then
					setScrollListSize()
					setEntryPositions()
				end
			end
		end
	end
end

local function removeStatFrameFromEntry(stat, frame)
	local statFrame = frame:FindFirstChild(stat.Name)
	if statFrame then
		statFrame:Destroy()
	end
end

local function doesStatExists(stat)
	local doesExists = false
	for _,entry in ipairs(PlayerEntries) do
		local player = entry.Player
		if player then
			local leaderstats = player:FindFirstChild('leaderstats')
			if leaderstats and leaderstats:FindFirstChild(stat.Name) then
				doesExists = true
				break
			end
		end
	end

	return doesExists
end

local function onStatRemoved(oldStat, entry)
	if isValidStat(oldStat) then
		removeStatFrameFromEntry(oldStat, entry.Frame)
		local statExists = doesStatExists(oldStat)
		--
		local toRemove = nil
		for i, stat in ipairs(GameStats) do
			if stat.Name == oldStat.Name then
				toRemove = i
				break
			end
		end
		-- removed from player but not from game; another player still has this stat
		if statExists then
			if toRemove and entry.Player == Player then
				GameStats[toRemove].Text = "-"
				Playerlist.OnStatChanged:Fire(GameStats[toRemove].Name, GameStats[toRemove].Text)
			end
		-- removed from game
		else
			for _,playerEntry in ipairs(PlayerEntries) do
				removeStatFrameFromEntry(oldStat, playerEntry.Frame)
			end
			for _,teamEntry in ipairs(TeamEntries) do
				removeStatFrameFromEntry(oldStat, teamEntry.Frame)
			end
			if toRemove then
				table.remove(GameStats, toRemove)
				table.sort(GameStats, sortLeaderStats)
			end
		end
		if GameStats[1] then
			updatePrimaryStats(GameStats[1].Name)
		end
		updateLeaderstatFrames()
	end
end

local function onStatAdded(leaderstats, entry)
	leaderstats.ChildAdded:connect(function(newStat)
		if isValidStat(newStat) then
			addNewStats(newStat.Parent)
			updateLeaderstatFrames()
		end
	end)
	leaderstats.ChildRemoved:connect(function(child)
		onStatRemoved(child, entry)
	end)
	addNewStats(leaderstats)
	updateLeaderstatFrames()
end

local function setLeaderStats(entry)
	local player = entry.Player
	local leaderstats = player:FindFirstChild('leaderstats')

	if leaderstats then
		onStatAdded(leaderstats, entry)
	end

	local function onPlayerChildChanged(property, child)
		if property == 'Name' and child.Name == 'leaderstats' then
			onStatAdded(child, entry)
		end
	end

	player.ChildAdded:connect(function(child)
		if child.Name == 'leaderstats' then
			onStatAdded(child, entry)
		end
		child.Changed:connect(function(property) onPlayerChildChanged(property, child) end)
	end)
	for _,child in pairs(player:GetChildren()) do
		child.Changed:connect(function(property) onPlayerChildChanged(property, child) end)
	end

	player.ChildRemoved:connect(function(child)
		if child.Name == 'leaderstats' then
			for i,stat in ipairs(child:GetChildren()) do
				onStatRemoved(stat, entry)
			end
			updateLeaderstatFrames()
		end
	end)
end
local function createPlayerEntry(player)
	local playerEntry = {}
	local name = player.Name

	local containerFrame, entryFrame = createEntryFrame(name, PlayerEntrySizeY)
	entryFrame.Active = true
	local function localEntrySelected()
		onEntryFrameSelected(containerFrame, player)
	end
	entryFrame.MouseButton1Click:connect(localEntrySelected)

	local currentXOffset = 1

	-- check membership
	local membershipIconImage = getMembershipIcon(player)
	local membershipIcon = nil
	if membershipIconImage then
		membershipIcon = createImageIcon(membershipIconImage, "MembershipIcon", currentXOffset, entryFrame)
		currentXOffset = currentXOffset + membershipIcon.Size.X.Offset + 2
	else
		currentXOffset = currentXOffset + 18
	end

	-- Some functions yield, so we need to spawn off in order to not cause a race condition with other events like Players.ChildRemoved
	spawn(function()
		local success, result = pcall(function()
			return player:GetRankInGroup(game.CreatorId) == 255
		end)
		if success then
			if game.CreatorType == Enum.CreatorType.Group and result then
				membershipIconImage = PLACE_OWNER_ICON
				if not membershipIcon then
					membershipIcon = createImageIcon(membershipIconImage, "MembershipIcon", 1, entryFrame)
				else
					membershipIcon.Image = membershipIconImage
				end
			end
		else
			print("PlayerList: GetRankInGroup failed because", result)
		end
		local adminIconImage = getAdminIcon(player)
		if adminIconImage then
			if not membershipIcon then
				membershipIcon = createImageIcon(adminIconImage, "MembershipIcon", 1, entryFrame)
			else
				membershipIcon.Image = adminIconImage
			end
		end
		-- Friendship and Follower status is checked by onFriendshipChanged, which is called by the FriendStatusChanged
		-- event. This event is fired when any player joins the game. onFriendshipChanged will check Follower status in
		-- the case that we are not friends with the new player who is joining.
	end)

	local playerNameXSize = entryFrame.Size.X.Offset - currentXOffset
	local playerName = createEntryNameText("PlayerName", name, playerNameXSize, currentXOffset)
	playerName.Parent = entryFrame
	playerEntry.Player = player
	playerEntry.Frame = containerFrame

	return playerEntry
end

local function createTeamEntry(team)
	local teamEntry = {}
	teamEntry.Team = team
	teamEntry.TeamScore = 0

	local containerFrame, entryFrame = createEntryFrame(team.Name, TeamEntrySizeY)
	entryFrame.BackgroundColor3 = team.TeamColor.Color

	local teamName = createEntryNameText("TeamName", team.Name, entryFrame.AbsoluteSize.x, 1)
	teamName.Parent = entryFrame

	teamEntry.Frame = containerFrame

	-- connections
	team.Changed:connect(function(property)
		if property == 'Name' then
			teamName.Text = team.Name
		elseif property == 'TeamColor' then
			for _,childFrame in pairs(containerFrame:GetChildren()) do
				if childFrame:IsA('Frame') then
					childFrame.BackgroundColor3 = team.TeamColor.Color
				end
			end
		end
	end)

	return teamEntry
end

local function createNeutralTeam()
	if not NeutralTeam then
		local team = Instance.new('Team')
		team.Name = 'Neutral'
		team.TeamColor = BrickColor.new('White')
		NeutralTeam = createTeamEntry(team)
		NeutralTeam.Frame.Parent = ScrollList
	end
end

--[[ Insert/Remove Player Functions ]]--
local function insertPlayerEntry(player)
	local entry = createPlayerEntry(player)
	if player == Player then
		MyPlayerEntry = entry.Frame
	end
	setLeaderStats(entry)
	table.insert(PlayerEntries, entry)
	setScrollListSize()
	updateLeaderstatFrames()
	entry.Frame.Parent = ScrollList

	player.Changed:connect(function(property)
		if #TeamEntries > 0 and (property == 'Neutral' or property == 'TeamColor') then
			setTeamEntryPositions()
			updateAllTeamScores()
			setEntryPositions()
			setScrollListSize()
		end
	end)
end

local function removePlayerEntry(player)
	for i = 1, #PlayerEntries do
		if PlayerEntries[i].Player == player then
			PlayerEntries[i].Frame:Destroy()
			table.remove(PlayerEntries, i)
			break
		end
	end
	setEntryPositions()
	setScrollListSize()
end

--[[ Team Functions ]]--
local function onTeamAdded(team)
	for i = 1, #TeamEntries do
		if TeamEntries[i].Team.TeamColor == team.TeamColor then
			TeamEntries[i].Frame:Destroy()
			table.remove(TeamEntries, i)
			break
		end
	end
	local entry = createTeamEntry(team)
	entry.Id = TeamAddId
	TeamAddId = TeamAddId + 1
	if not NeutralTeam then
		createNeutralTeam()
	end
	table.insert(TeamEntries, entry)
	table.sort(TeamEntries, sortTeams)
	setTeamEntryPositions()
	updateLeaderstatFrames()
	setScrollListSize()
	entry.Frame.Parent = ScrollList
end

local function onTeamRemoved(removedTeam)
	for i = 1, #TeamEntries do
		local team = TeamEntries[i].Team
		if team.Name == removedTeam.Name then
			TeamEntries[i].Frame:Destroy()
			table.remove(TeamEntries, i)
			break
		end
	end
	if #TeamEntries == 0 then
		if NeutralTeam then
			NeutralTeam.Frame:Destroy()
			NeutralTeam.Team:Destroy()
			NeutralTeam = nil
			IsShowingNeutralFrame = false
		end
	end
	setEntryPositions()
	updateLeaderstatFrames()
	setScrollListSize()
end

--[[ Resize/Position Functions ]]--
local function clampCanvasPosition()
	local maxCanvasPosition = ScrollList.CanvasSize.Y.Offset - ScrollList.Size.Y.Offset
	if maxCanvasPosition >= 0 and ScrollList.CanvasPosition.y > maxCanvasPosition then
		ScrollList.CanvasPosition = Vector2.new(0, maxCanvasPosition)
	end
end

local function resizePlayerList()
	setScrollListSize()
	clampCanvasPosition()
end

RobloxGui.Changed:connect(function(property)
	if property == 'AbsoluteSize' then
		spawn(function()	-- must spawn because F11 delays when abs size is set
			resizePlayerList()
		end)
	end
end)

--[[ Input Connections ]]--
UserInputService.InputEnded:connect(function(inputObject)
	if ReportAbuseShield.Parent == RobloxGui then
		if inputObject.KeyCode == Enum.KeyCode.Escape then
			onAbuseDialogCanceled()
		end
	end
end)

UserInputService.InputBegan:connect(function(inputObject, isProcessed)
	if isProcessed then return end
	local inputType = inputObject.UserInputType
	if (inputType == Enum.UserInputType.Touch and  inputObject.UserInputState == Enum.UserInputState.Begin) or
		inputType == Enum.UserInputType.MouseButton1 then
		if LastSelectedFrame then
			hideFriendReportPopup()
		end
	end
end)

ReportAbuseShield.InputBegan:connect(function(inputObject)
	if not IsNewSettings then return end 	-- FFlag
	--
	local inputType = inputObject.UserInputType
	if inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch then
		if AbuseDropDown and AbuseDropDown.IsOpen() then
			AbuseDropDown.Close()
		end
	end
end)

-- NOTE: Core script only

--[[ Player Add/Remove Connections ]]--
Players.ChildAdded:connect(function(child)
	if child:IsA('Player') then
		insertPlayerEntry(child)
	end
end)
for _,player in pairs(Players:GetPlayers()) do
	insertPlayerEntry(player)
end

Players.ChildRemoved:connect(function(child)
	if child:IsA('Player') then
		if LastSelectedPlayer and child == LastSelectedPlayer then
			hideFriendReportPopup()
		end
		removePlayerEntry(child)
	end
end)

--[[ Teams ]]--
local function initializeTeams(teams)
	for _,team in pairs(teams:GetTeams()) do
		onTeamAdded(team)
	end

	teams.ChildAdded:connect(function(team)
		if team:IsA('Team') then
			onTeamAdded(team)
		end
	end)

	teams.ChildRemoved:connect(function(team)
		if team:IsA('Team') then
			onTeamRemoved(team)
		end
	end)
end

TeamsService = game:FindService('Teams')
if TeamsService then
	initializeTeams(TeamsService)
end

game.ChildAdded:connect(function(child)
	if child:IsA('Teams') then
		initializeTeams(child)
	end
end)

--[[ Core Gui Changed events ]]--
-- NOTE: Core script only
local isOpen = true
local function onCoreGuiChanged(coreGuiType, enabled)
	if coreGuiType == Enum.CoreGuiType.All or coreGuiType == Enum.CoreGuiType.PlayerList then
		-- not visible on small screen devices
		if IsSmallScreenDevice then
			Container.Visible = false
			return
		end
		Container.Visible = enabled and isOpen
		GuiService[enabled and "AddKey" or "RemoveKey"](GuiService, "\t")
	end
end
pcall(function()
	onCoreGuiChanged(Enum.CoreGuiType.PlayerList, game:GetService("StarterGui"):GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList))
	game:GetService("StarterGui").CoreGuiChangedSignal:connect(onCoreGuiChanged)
end)

resizePlayerList()

--[[ Public API ]]--
Playerlist.GetStats = function()
	return GameStats
end

local noOpFunc = function ( )
end

local closeListFunc = function(name, state, input)
	if state ~= Enum.UserInputState.Begin then return end

	ContextActionService:UnbindCoreAction("CloseList")
	ContextActionService:UnbindCoreAction("StopAction")
	GuiService.SelectedObject = nil
end

Playerlist.ToggleVisibility = function()
	if IsSmallScreenDevice then return end
	if not game:GetService("StarterGui"):GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList) then return end
	isOpen = not isOpen
	Container.Visible = isOpen

	if IsGamepadSupported and UserInputService:GetGamepadConnected(Enum.UserInputType.Gamepad1) then
		if isOpen then
			local children = ScrollList:GetChildren()
			if children and #children > 0 then
				local frame = children[1]
				local frameChildren = frame:GetChildren()
				for i = 1, #frameChildren do
					if frameChildren[i]:IsA("TextButton") then
						GuiService.SelectedObject = frameChildren[i]
						ContextActionService:BindCoreAction("StopAction", noOpFunc, false, Enum.UserInputType.Gamepad1)
						ContextActionService:BindCoreAction("CloseList", closeListFunc, false, Enum.KeyCode.ButtonB, Enum.KeyCode.ButtonStart)
						break
					end
				end
			end
		else
			ContextActionService:UnbindCoreAction("CloseList")
			ContextActionService:UnbindCoreAction("StopAction")
			GuiService.SelectedObject = nil
		end
	end
end

Playerlist.IsOpen = function()
	return isOpen
end

-- NOTE: Core script only
if GuiService then
	GuiService.KeyPressed:connect(function(key)
		if key == "\t" then
			Playerlist.ToggleVisibility()
		end
	end)

	GuiService:AddSelectionParent("PlayerListSelection", Container)
end



return Playerlist
