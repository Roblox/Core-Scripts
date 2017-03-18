--[[r
		Filename: Record.lua
		Written by: jeditkacheff
		Version 1.0
		Description: Takes care of the Record Tab in Settings Menu
--]]
-------------- SERVICES --------------
local CoreGui = game:GetService("CoreGui")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local GuiService = game:GetService("GuiService")
local TextService = game:GetService("TextService")
local Settings = UserSettings()
local GameSettings = Settings.GameSettings

----------- UTILITIES --------------
RobloxGui:WaitForChild("Modules"):WaitForChild("TenFootInterface")
local utility = require(RobloxGui.Modules.Settings.Utility)
local isTenFootInterface = require(RobloxGui.Modules.TenFootInterface):IsEnabled()

------------ Variables -------------------
local PageInstance = nil

----------- CLASS DECLARATION --------------

local function Initialize()
	local settingsPageFactory = require(RobloxGui.Modules.Settings.SettingsPageFactory)
	local this = settingsPageFactory:CreateNewPage()
	local isRecordingVideo = false

	local recordingEvent = Instance.new("BindableEvent")
	recordingEvent.Name = "RecordingEvent"
	this.RecordingChanged = recordingEvent.Event
	function this:IsRecording()
		return isRecordingVideo
	end
	
	------ TAB CUSTOMIZATION -------
	this.TabHeader.Name = "RecordTab"

	this.TabHeader.Icon.Image = "rbxasset://textures/ui/Settings/MenuBarIcons/RecordTab.png"
	this.TabHeader.Icon.AspectRatioConstraint.AspectRatio = 41 / 40

	this.TabHeader.Icon.Title.Text = "Record"

	------ PAGE CUSTOMIZATION -------
	this.Page.Name = "Record"

	local function makeTextLabel(name, text, isTitle, parent, layoutOrder)
		local leftPadding, rightPadding, bottomPadding, textSize, font = 10, 0, 10, 24, Enum.Font.SourceSans

		if isTitle then
			leftPadding, rightPadding, bottomPadding, textSize, font = 10, 0, 0, 36, Enum.Font.SourceSansBold
		end

		local container = utility:Create'Frame'
		{
			Name = name .. "Container",
			BackgroundTransparency = 1,
			ZIndex = 2,
			LayoutOrder = layoutOrder,
			Parent = parent
		};
		local textLabel = utility:Create'TextLabel'
		{
			Name = name,
			BackgroundTransparency = 1,
			Text = text,
			TextWrapped = true,
			Font = font,
			TextSize = textSize,
			TextColor3 = Color3.new(1,1,1),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Position = UDim2.new(0, leftPadding, 0, 0),
			Size = UDim2.new(1, -(leftPadding + rightPadding), 1, 0),
			ZIndex = 2,
			Parent = container
		};

		local function onResized(prop)
			if prop == "AbsoluteSize" then
				local textSize = TextService:GetTextSize(text, textLabel.TextSize, textLabel.Font, Vector2.new(parent.AbsoluteSize.X - leftPadding - rightPadding, 1e4))
				container.Size = UDim2.new(1, 0, 0, textSize.Y + bottomPadding)
			end
		end
		onResized("AbsoluteSize")
		parent.Changed:connect(onResized)

		return textLabel, container
	end

	-- need to override this function from SettingsPageFactory
	-- DropDown menus require hub to to be set when they are initialized
	function this:SetHub(newHubRef)
		this.HubRef = newHubRef

		local recordEnumNames = {}
		recordEnumNames[1] = "Save To Disk"
		recordEnumNames[2] = "Upload to YouTube"

		local startSetting = 2
		if GameSettings.VideoUploadPromptBehavior == Enum.UploadSetting["Never"] then
			startSetting = 1
		end

		---------------------------------- SCREENSHOT -------------------------------------
		local screenshotTitle = makeTextLabel("ScreenshotTitle", 
												"Screenshot",
												true, this.Page, 1)

		local screenshotBody = makeTextLabel("ScreenshotBody", 
												"By clicking the 'Take Screenshot' button, the menu will close and take a screenshot and save it to your computer.",
												false, this.Page, 2)

		local closeSettingsFunc = function()
			this.HubRef:SetVisibility(false, true)
		end
		this.ScreenshotButtonRow, this.ScreenshotButton = utility:AddButtonRow(this, "ScreenshotButton", "Take Screenshot", UDim2.new(0, 300, 0, 44), closeSettingsFunc)
		this.ScreenshotButtonRow.LayoutOrder = 3


		---------------------------------- VIDEO -------------------------------------
		local videoTitle = makeTextLabel("VideoTitle", 
												"Video",
												true, this.Page, 4)

		local videoBody = makeTextLabel("VideoBody", 
												"By clicking the 'Record Video' button, the menu will close and start recording your screen.",
												false, this.Page, 5)

		this.VideoSettingsFrame, 
		this.VideoSettingsLabel,
		this.VideoSettingsMode = utility:AddNewRow(this, "Video Settings", "Selector", recordEnumNames, startSetting)
		this.VideoSettingsFrame.LayoutOrder = 5

		this.VideoSettingsMode.IndexChanged:connect(function(newIndex)
			if newIndex == 1 then
				GameSettings.VideoUploadPromptBehavior = Enum.UploadSetting.Never
			elseif newIndex == 2 then
				GameSettings.VideoUploadPromptBehavior = Enum.UploadSetting.Always
			end
		end)
		
		local recordButtonRow, recordButton = utility:AddButtonRow(this, "RecordButton", "Record Video", UDim2.new(0, 300, 0, 44), closeSettingsFunc)
		recordButtonRow.LayoutOrder = 6
		recordButton.MouseButton1Click:connect(function()
			recordingEvent:Fire(not isRecordingVideo)
		end)

		local gameOptions = settings():FindFirstChild("Game Options")
		if gameOptions then
			gameOptions.VideoRecordingChangeRequest:connect(function(recording)
				isRecordingVideo = recording
				if recording then
					recordButton.RecordButtonTextLabel.Text = "Stop Recording"
				else
					recordButton.RecordButtonTextLabel.Text = "Record Video"
				end
			end)
		end

		recordButton:SetVerb("RecordToggle")
		this.ScreenshotButton:SetVerb("Screenshot")

		this.Page.Size = UDim2.new(1,0,0,400)
	end

	return this
end


----------- Public Facing API Additions --------------
PageInstance = Initialize()

PageInstance.Displayed.Event:connect(function(switchedFromGamepadInput)
	if switchedFromGamepadInput then
		GuiService.SelectedCoreObject = PageInstance.ScreenshotButton
	end
end)


return PageInstance