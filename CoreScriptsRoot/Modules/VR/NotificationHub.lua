local CoreGui = game:GetService("CoreGui")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local Util = require(RobloxGui.Modules.Settings.Utility)
local Panel3D = require(RobloxGui.Modules.VR.Panel3D)
local VRHub = require(RobloxGui.Modules.VR.VRHub)

local NO_TRANSITION_ANIMATIONS = false
local ANIMATE_OUT_DISTANCE = -100
local ANIMATE_OUT_DURATION = 0.25
local PIXELS_PER_STUD = 150
local WINDOW_TITLEBAR_HEIGHT = 72
local BLURRED_TITLEBAR_COLOR = Color3.new(78 / 255, 84 / 255, 96 / 255)
local FOCUSED_TITLEBAR_COLOR = Color3.new(82 / 255, 101 / 255, 141 / 255)
local WINDOW_BG_COLOR = Color3.new(20/255, 20/255, 20/255)
local WINDOW_BG_TRANSPARENCY = 0.5
local POPOUT_DISTANCE = 0.25
local POPOUT_DURATION = 0.25

local NOTIFICATION_WIDTH_SCALE = 0.85
local NOTIFICATION_HEIGHT_OFFSET = 80
local NOTIFICATION_PADDING_Y = 20
local NOTIFICATION_PADDING_X_SCALE = (1 - NOTIFICATION_WIDTH_SCALE) / 2
local NOTIFICATION_DEPTH_OFFSET = 0.25
local MAX_NOTIFICATIONS_SHOWN = 3
local MAX_DETAILS_SHOWN = 2
local DETAILS_PADDING = 20

local BUTTON_NORMAL_IMG = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuButton.png"
local BUTTON_SELECTED_IMG = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuButtonSelected.png"

local emptySelectionImage = Util:Create "ImageLabel" {
	BackgroundTransparency = 1,
	Image = ""
}


local AVATAR_IMAGE_URL = 'http://www.roblox.com/thumbs/avatar.ashx?userId=%d&x=%d&y=%d'

local TEXT_COLOR = Color3.new(1, 1, 1)

local aspectRatio = 1.62666666
local totalHeight = 3.5
local totalWidth = totalHeight * aspectRatio
local leftPanelWidth = totalWidth * 0.4
local rightPanelWidth = totalWidth * 0.6

local panelOffset = totalWidth / 2
local leftOffset = panelOffset - (leftPanelWidth * 0.5)
local rightOffset = leftOffset - (leftPanelWidth * 0.5) - (rightPanelWidth * 0.5)

local NotificationHubModule = {}
NotificationHubModule.ModuleName = "Notifications"
NotificationHubModule.KeepVRTopbarOpen = true
NotificationHubModule.VRIsExclusive = true
NotificationHubModule.VRClosesNonExclusive = true
NotificationHubModule.UnreadCountChanged = function() end
VRHub:RegisterModule(NotificationHubModule)

local notificationsPanel = Panel3D.Get("Notifications")
local notificationsWindow = nil
local detailsPanel = Panel3D.Get("NotificationDetails")
local detailsWindow = nil

local WindowFrame = {} 
do
	local windows = {}
	local WindowFrame_mt = { __index = WindowFrame }
	function WindowFrame.new(panel, parent, title)
		local instance = {}
		table.insert(windows, instance)
		instance.zeroCF = panel.localCF
		instance.zOffset = 0
		instance.isPopping = false
		instance.isAnimating = false
		instance.tweener = nil
		instance.panel = panel
		instance.panel.OnMouseEnter = function()
			for i, v in pairs(windows) do
				if v ~= instance then
					v:SetPopOut(false)
				end
			end
			instance:SetPopOut(true)
		end

		instance.titlebar = Util:Create "ImageLabel" {
			Parent = parent,

			Position = UDim2.new(0, -1, 0, -1),
			Size = UDim2.new(1, 2, 0, WINDOW_TITLEBAR_HEIGHT + 2),

			BackgroundTransparency = 1,

			Image = "rbxasset://textures/ui/VR/rectBackgroundWhite.png",
			ImageColor3 = BLURRED_TITLEBAR_COLOR,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(10, 10, 10, 10)
		}
		instance.titleText = Util:Create "TextLabel" {
			Parent = instance.titlebar,

			Position = UDim2.new(0, 1, 0, 1),
			Size = UDim2.new(1, -2, 1, -2),

			Text = title,
			TextColor3 = TEXT_COLOR,
			Font = Enum.Font.SourceSans,
			FontSize = Enum.FontSize.Size36,

			BackgroundTransparency = 1
		}

		instance.content = Util:Create "ImageLabel" {
			Parent = parent,

			Position = UDim2.new(0, -1, 0, WINDOW_TITLEBAR_HEIGHT + 2),
			Size = UDim2.new(1, 2, 1, -WINDOW_TITLEBAR_HEIGHT - 4),

			BackgroundTransparency = 1,

			Image = "rbxasset://textures/ui/VR/rectBackgroundWhite.png",
			ImageColor3 = WINDOW_BG_COLOR,
			ImageTransparency = WINDOW_BG_TRANSPARENCY,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(10, 10, 10, 10)
		}	

		return setmetatable(instance, WindowFrame_mt)
	end

	function WindowFrame:SetTitle(title)
		self.titleText.Text = title
	end

	function WindowFrame:AddCloseButton(callback)
		local closeBtnSize = 48
		local closeBtnOffset = 14
		self.closeButton = Util:Create "ImageButton" {
			Parent = self.titlebar,

			Position = UDim2.new(0, closeBtnOffset, 0, closeBtnOffset),
			Size = UDim2.new(0, closeBtnSize, 0, closeBtnSize),

			BackgroundTransparency = 1, 

			Image = "rbxasset://textures/ui/VR/closeButtonPadded.png"
		}
		self.closeButton.MouseButton1Click:connect(callback)
	end

	function WindowFrame:TweenZOffsetTo(zOffset, duration, easingFunc, callback)
		if self.tweener and not self.tweener:IsFinished() then
			self.tweener:Cancel()
		end
		self.tweener = Util:TweenProperty(self, "zOffset", self.zOffset, zOffset, duration, easingFunc, callback)
	end

	function WindowFrame:AnimateOut(callback)
		self.isAnimating = true
		self:TweenZOffsetTo(ANIMATE_OUT_DISTANCE, ANIMATE_OUT_DURATION, Util:GetEaseInOutQuad(), function()
			if callback then callback() end
			self.isAnimating = false
		end)
	end

	function WindowFrame:AnimateIn(callback)
		self.zOffset = ANIMATE_OUT_DISTANCE
		self:OnUpdate(0)
		self.isAnimating = true
		self:TweenZOffsetTo(0, ANIMATE_OUT_DURATION, Util:GetEaseInOutQuad(), function()
			if callback then callback() end
			self.isAnimating = false
		end)
	end

	function WindowFrame:SetPopOut(popOut)
		if self.isAnimating then
			return
		end

		if popOut then
			self.isPopping = true
			self:TweenZOffsetTo(POPOUT_DISTANCE, POPOUT_DURATION, Util:GetEaseInOutQuad(), function()
				self.isPopping = false
			end)
		else
			self.isPopping = true
			self:TweenZOffsetTo(0, POPOUT_DURATION, Util:GetEaseInOutQuad(), function()
				self.isPopping = false
			end)
		end
	end

	function WindowFrame:OnUpdate(dt)
		self.panel.localCF = self.zeroCF * CFrame.new(0, 0, -self.zOffset)

		if self.isPopping then
			local alpha = math.max(0, math.min(1, self.zOffset / POPOUT_DISTANCE))
			self.titlebar.ImageColor3 = BLURRED_TITLEBAR_COLOR:lerp(FOCUSED_TITLEBAR_COLOR, alpha)
		end
	end
end

--Notifications panel setup
do
	notificationsPanel:SetType(Panel3D.Type.Fixed)
	notificationsPanel:SetVisible(false)
	notificationsPanel:SetCanFade(false)
	notificationsPanel:ResizeStuds(leftPanelWidth, totalHeight, PIXELS_PER_STUD)
	local notificationsFrame = Util:Create "TextButton" {
		Parent = notificationsPanel:GetGUI(),
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -4, 1, 0),

		BackgroundTransparency = 1,
		Text = "",

		Selectable = true,
		SelectionImageObject = emptySelectionImage
	}
	notificationsWindow = WindowFrame.new(notificationsPanel, notificationsFrame, "Notifications")
	notificationsWindow:AddCloseButton(function()
		NotificationHubModule:SetVisible(false)
	end)
	function notificationsPanel:OnUpdate(dt)
		notificationsWindow:OnUpdate(dt)
	end
end

--Details panel setup
do
	detailsPanel:SetType(Panel3D.Type.Fixed)
	detailsPanel:SetVisible(false)
	detailsPanel:SetCanFade(false)
	detailsPanel:ResizeStuds(rightPanelWidth, totalHeight, PIXELS_PER_STUD)
	local detailsFrame = Util:Create "TextButton" {
		Parent = detailsPanel:GetGUI(),
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		
		BackgroundTransparency = 1,
		Text = "",

		Selectable = true,
		SelectionImageObject = emptySelectionImage
	}
	detailsWindow = WindowFrame.new(detailsPanel, detailsFrame, "Friend Requests")
	function detailsPanel:OnUpdate(dt)
		detailsWindow:OnUpdate(dt)
	end
end

local notificationsGroups = {}
local notificationsGroupsList = {}
local function groupSort(a, b)
	return a.order < b.order
end
local activeGroup = nil

local function layoutNotificationsGroups()
	local y = NOTIFICATION_PADDING_Y
	for _, group in ipairs(notificationsGroupsList) do
		if #group.notifications > 0 then
			local height = NOTIFICATION_HEIGHT_OFFSET + (NOTIFICATION_PADDING_Y * (math.min(MAX_NOTIFICATIONS_SHOWN, #group.notifications) - 1))
			local widthOffset = -((MAX_NOTIFICATIONS_SHOWN - 1) * NOTIFICATION_PADDING_Y)
			group.frame.Position = UDim2.new(NOTIFICATION_PADDING_X_SCALE, 0, 0, y)
			group.frame.Size = UDim2.new(NOTIFICATION_WIDTH_SCALE, widthOffset, 0, height)
			y = y + height + NOTIFICATION_PADDING_Y

			if group.notificationsDirty then
				group.notificationsDirty = false

				local notificationOffset = 0
				local notificationDepth = 0

				local notificationsEnd = #group.notifications
				if notificationsEnd > 0 then
					local notificationsStart = math.max(1, notificationsEnd - MAX_NOTIFICATIONS_SHOWN + 1)
					for i = 1, notificationsEnd do
						local notification = group.notifications[i]
						if i >= notificationsStart then
							notification.frame.Visible = true
							notification.frame.Position = UDim2.new(0, notificationOffset, 0, notificationOffset)
							notificationOffset = notificationOffset + NOTIFICATION_PADDING_Y

							local subpanel = notificationsPanel:SetSubpanelDepth(notification.frame, notificationDepth)
							notificationDepth = notificationDepth + NOTIFICATION_DEPTH_OFFSET
						else
							notification.frame.Visible = false
						end
					end

					if activeGroup == group then
						notificationsStart = math.max(1, notificationsEnd - MAX_DETAILS_SHOWN + 1)
						local detailY = 0
						local fraction = 1 / MAX_DETAILS_SHOWN
						for i = 1, notificationsEnd do
							local notification = group.notifications[i]
							if i >= notificationsStart then
								notification.detailsFrame.Visible = true
								notification.detailsFrame.Position = UDim2.new(0, DETAILS_PADDING, detailY, DETAILS_PADDING)
								notification.detailsFrame.Size = UDim2.new(1, -DETAILS_PADDING * 2, fraction, -DETAILS_PADDING * 2)

								detailY = detailY + fraction
							else
								notification.detailsFrame.Visible = false
							end
						end
					end
				end
			end
		end
	end
end

local NotificationGroup = {} 
do
	local NotificationGroup_mt = { __index = NotificationGroup }
	function NotificationGroup.new(key, title, order) 
		local self = setmetatable({}, NotificationGroup_mt)

		self.key = key
		self.title = title
		self.order = order
		self.notifications = {}
		self.notificationsDirty = false
		self.frame = Util:Create "Frame" {
			Parent = notificationsWindow.content,
			BackgroundTransparency = 1
		}
		self.detailsFrame = Util:Create "Frame" {
			Parent = nil,
			BackgroundTransparency = 1,

			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0)
		}

		notificationsGroups[key] = self
		table.insert(notificationsGroupsList, self)

		return self
	end

	function NotificationGroup:Deactivate()
		self.detailsFrame.Parent = nil
		for i, v in pairs(self.detailsFrame:GetChildren()) do
			detailsPanel:RemoveSubpanel(v)
		end
	end

	function NotificationGroup:SwitchTo()
		detailsWindow:SetTitle(self.title)
		for i, v in pairs(notificationsGroups) do
			if v ~= self then
				v:Deactivate()
			end
		end
		self.detailsFrame.Parent = detailsWindow.content

		activeGroup = self
		self.notificationsDirty = true
	end

	function NotificationGroup:BringNotificationToFront(notification)
		if activeGroup ~= self then
			self:SwitchTo()
		end

		for i, v in ipairs(self.notifications) do
			if v == notification then
				if i == #self.notifications then
					layoutNotificationsGroups()
					return --already on top, no point
				end
				--take it out
				table.remove(self.notifications, i)
				break
			end
		end
		--put it back on top
		table.insert(self.notifications, notification)
		self.notificationsDirty = true
		layoutNotificationsGroups()
	end

	function NotificationGroup:RemoveNotification(notification)
		for i, v in ipairs(self.notifications) do
			if v == notification then
				table.remove(self.notifications, i)
				notificationsPanel:RemoveSubpanel(notification.frame)
				detailsPanel:RemoveSubpanel(notification.detailsFrame)
				notification.detailsFrame:Destroy()
				notification.frame:Destroy()

				self.notificationsDirty = true
				layoutNotificationsGroups()
				return
			end
		end
	end

	function NotificationGroup:GetTopNotification()
		local numNotifications = #self.notifications
		if numNotifications <= 0 then
			return nil
		end
		return self.notifications[numNotifications]
	end
end

NotificationGroup.new("Friends", 		"Friends",	1)
NotificationGroup.new("BadgeAwards", 	"Badges", 	2)
NotificationGroup.new("PlayerPoints",	"Points", 	3)
NotificationGroup.new("Developer", 		"Other", 	4)
table.sort(notificationsGroupsList, groupSort)

local function doCallback(callback, ...)
	if not callback then
		return
	end

	if type(callback) == "function" then
		callback(...)
		return
	end
	if callback:IsA("BindableEvent") then
		callback:Fire(...)
		return
	end
	if callback:IsA("BindableFunction") then
		callback:Invoke(...)
		return
	end
end

local Notification = {} 
do
	local Notification_mt = { __index = Notification }
	function Notification.new(group, notificationInfo)
		local self = setmetatable({}, Notification_mt)
		self.group = group
		self.frame = Util:Create "ImageButton" {
			Parent = group.frame,
			Size = UDim2.new(1, 0, 0, NOTIFICATION_HEIGHT_OFFSET),

			SelectionImageObject = emptySelectionImage,

			BackgroundTransparency = 1 --when we have proper frame rendering with AA, we can change this and remove the stand-in background
		}
		self.frame.MouseButton1Click:connect(function()
			self:OnClicked()
		end)
		self.background = Util:Create "ImageLabel" { --this is the stand-in background for that smoooooooth edge rendering
			Parent = self.frame,
			Position = UDim2.new(0, -1, 0, -1),
			Size = UDim2.new(1, 2, 1, 2),

			BackgroundTransparency = 1,
			Image = "rbxasset://textures/ui/vr/rectBackgroundWhite.png",
			ImageColor3 = Color3.new(0.2, 0.2, 0.2), --constant me
			ImageTransparency = 0.1, --constant me

			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(10, 10, 10, 10)
		}
		self.imageBackground = Util:Create "ImageLabel" {
			Parent = self.frame,
			Position = UDim2.new(0, 5, 0, 5),
			Size = UDim2.new(0, 70, 0, 70),

			BackgroundTransparency = 1,

			Image = "rbxasset://textures/ui/VR/circleWhite.png",
			ImageColor3 = notificationInfo.imgBackgroundColor or Color3.new(1, 1, 1)
		}
		self.image = Util:Create "ImageLabel" {
			Parent = self.imageBackground,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),

			BackgroundTransparency = 1,

			Image = notificationInfo.Image
		}

		local text = notificationInfo.Text
		if notificationInfo.Title and notificationInfo.Text then
			text = notificationInfo.Title .. "\n" .. notificationInfo.Text
		end
		self.text = Util:Create "TextLabel" {
			Parent = self.frame,

			Position = UDim2.new(0, NOTIFICATION_HEIGHT_OFFSET, 0, 0),
			Size = UDim2.new(1, -NOTIFICATION_HEIGHT_OFFSET, 1, 0),

			BackgroundTransparency = 1,

			TextXAlignment = Enum.TextXAlignment.Left,
			Text = text,
			Font = Enum.Font.SourceSans,
			FontSize = Enum.FontSize.Size18,
			TextColor3 = TEXT_COLOR
		}

		self.detailsFrame = Util:Create "Frame" {
			Parent = group.detailsFrame,
			BackgroundTransparency = 1
		}
		self.detailsFrame.MouseEnter:connect(function()
			detailsPanel:SetSubpanelDepth(self.detailsFrame, 0.25)
		end)
		self.detailsFrame.MouseLeave:connect(function()
			detailsPanel:SetSubpanelDepth(self.detailsFrame, 0)
		end)
		self.detailsBackground = Util:Create "ImageLabel" {
			Parent = self.detailsFrame,
			Position = UDim2.new(0, -1, 0, -1),
			Size = UDim2.new(1, 2, 1, 2),

			BackgroundTransparency = 1,

			Image = "rbxasset://textures/ui/VR/rectBackgroundWhite.png",
			ImageColor3 = Color3.new(0.2, 0.2, 0.2),
			ImageTransparency = 0.1,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(10,10,10,10)
		}

		self.detailsIconBackground = Util:Create "ImageLabel" {
			Parent = self.detailsFrame,
			Position = UDim2.new(0, 20, 0, 10),
			Size = UDim2.new(0, 80, 0, 80),

			BackgroundTransparency = 1,

			Image = "rbxasset://textures/ui/VR/circleWhite.png",
			ImageColor3 = notificationInfo.imgBackgroundColor or Color3.new(1, 1, 1)
		}
		self.detailsIcon = Util:Create "ImageLabel" {
			Parent = self.detailsIconBackground,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),

			BackgroundTransparency = 1,

			Image = notificationInfo.Image
		}

		local detailText = notificationInfo.DetailText or notificationInfo.Title
		self.detailsText = Util:Create "TextLabel" {
			Parent = self.detailsFrame,
			Position = UDim2.new(0, 110, 0, 10),
			Size = UDim2.new(1, -120, 0, 90),

			BackgroundTransparency = 1,

			Text = detailText, 
			TextColor3 = TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.SourceSansBold,
			FontSize = Enum.FontSize.Size36
		}

		local function createButton(xPosScale, xSizeScale, text)
			local button, text = Util:Create "ImageButton" {
				Parent = self.detailsFrame,
				Position = UDim2.new(xPosScale, 0, 0.55, 0),
				Size = UDim2.new(xSizeScale, 0, 0.29, 0),

				BackgroundTransparency = 1,

				Image = BUTTON_NORMAL_IMG,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(8,6,46,44),

				SelectionImageObject = emptySelectionImage
			}, Util:Create "TextLabel" {
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 1, -6),

				BackgroundTransparency = 1,

				Text = text,
				TextColor3 = TEXT_COLOR,
				Font = Enum.Font.SourceSansBold,
				FontSize = Enum.FontSize.Size24
			}
			text.Parent = button

			button.SelectionGained:connect(function()
				button.Image = BUTTON_SELECTED_IMG
			end)
			button.SelectionLost:connect(function()
				button.Image = BUTTON_NORMAL_IMG
			end)
			return button, text
		end

		if notificationInfo.Button1Text and notificationInfo.Button2Text then
			self.detailsButton1, self.detailsButton1Text = createButton(0.07, 0.415, notificationInfo.Button1Text)
			self.detailsButton2, self.detailsButton2Text = createButton(0.511, 0.415, notificationInfo.Button2Text)

			self.detailsButton1.MouseButton1Click:connect(function() 
				doCallback(notificationInfo.Callback, notificationInfo.Button1Text)
				self:Dismiss() 
			end)
			self.detailsButton2.MouseButton1Click:connect(function() 
				doCallback(notificationInfo.Callback, notificationInfo.Button2Text)
				self:Dismiss() 
			end)
		elseif not notificationInfo.button2Text then
			local text = notificationInfo.Button1Text or "Dismiss"
			self.detailsButton1, self.detailsButton1Text = createButton(0.07, 0.86, text)
			self.detailsButton1.MouseButton1Click:connect(function() 
				doCallback(notificationInfo.Callback, notificationInfo.Button1Text)
				self:Dismiss() 
			end)
		end

		table.insert(group.notifications, self)
		group.notificationsDirty = true
		layoutNotificationsGroups()

		return self
	end

	function Notification:OnClicked()
		self.group:BringNotificationToFront(self)
	end

	function Notification:Dismiss()
		self.group:RemoveNotification(self)
	end
end

--NotificationHubModule API and state management
do
	local pendingNotifications = {}
	local isVisible = false
	local unreadCount = 0

	local SendNotificationInfoEvent = RobloxGui:WaitForChild("SendNotificationInfo")
	SendNotificationInfoEvent.Event:connect(function(notificationInfo)
		local group = notificationsGroups[notificationInfo.GroupName or "Developer"]
		if not group then
			group = notificationsGroups.Developer
		end

		Notification.new(group, notificationInfo)

		if not isVisible then
			unreadCount = unreadCount + 1
			NotificationHubModule.UnreadCountChanged(unreadCount)
		end
	end)

	NotificationHubModule.VisibilityStateChanged = Util:Create "BindableEvent" {
		Name = "VisibilityStateChanged"
	}

	function NotificationHubModule:GetNumberOfPendingNotifications()
		return #pendingNotifications
	end

	function NotificationHubModule:IsVisible()
		return isVisible
	end

	function NotificationHubModule:SetVisible(visible)
		if isVisible == visible then
			return
		end
		isVisible = visible

		local topbarPanel = Panel3D.Get("Topbar3D")
		topbarPanel:SetCanFade(not visible)
		if visible then
			unreadCount = 0
			NotificationHubModule.UnreadCountChanged(unreadCount)

			local hubSpace = topbarPanel.localCF * CFrame.Angles(math.rad(-5), 0, 0) * CFrame.new(0, 4, 0) * CFrame.Angles(math.rad(-15), 0, 0)

			notificationsPanel.localCF = hubSpace * CFrame.new(leftOffset, 0, 0)
			notificationsWindow.zeroCF = notificationsPanel.localCF
			if not NO_TRANSITION_ANIMATIONS then
				notificationsWindow:AnimateIn(nil)
			end

			detailsPanel.localCF = hubSpace * CFrame.new(rightOffset, 0, 0)
			detailsWindow.zeroCF = detailsPanel.localCF
			if not NO_TRANSITION_ANIMATIONS then
				detailsWindow:AnimateIn(nil)
			end
			
			notificationsPanel:SetVisible(true)
			detailsPanel:SetVisible(true)

			VRHub:FireModuleOpened(NotificationHubModule.ModuleName)
		else
			if not NO_TRANSITION_ANIMATIONS then
				spawn(function()
					cancelAnimation = false
					notificationsWindow:AnimateOut(function()
						notificationsPanel:SetVisible(false)
					end)
					detailsWindow:AnimateOut(function()
						detailsPanel:SetVisible(false)
					end)
				end)
			else
				notificationsPanel:SetVisible(false)
				detailsPanel:SetVisible(false)
			end

			VRHub:FireModuleClosed(NotificationHubModule.ModuleName)
		end

		NotificationHubModule.VisibilityStateChanged:Fire(visible)
	end

	
	VRHub.ModuleOpened.Event:connect(function(moduleName, isExclusive, shouldCloseNonExclusive, shouldKeepTopbarOpen)
		if moduleName ~= NotificationHubModule.ModuleName then
			NotificationHubModule:SetVisible(false)
		end
	end)
end

return NotificationHubModule