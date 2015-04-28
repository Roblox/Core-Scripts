local function waitForChild(instance, name)
	while not instance:FindFirstChild(name) do
		instance.ChildAdded:wait()
	end
end

local function waitForProperty(instance, property)
	while not instance[property] do
		instance.Changed:wait()
	end
end

--Include
local Create = assert(LoadLibrary("RbxUtility")).Create


-- A Few Script Globals
local gui
if script.Parent:FindFirstChild("ControlFrame") then
	gui = script.Parent:FindFirstChild("ControlFrame")
else
	gui = script.Parent
end

local helpButton = nil
local updateCameraDropDownSelection = nil
local updateVideoCaptureDropDownSelection = nil
local updateSmartCameraDropDownSelection = nil
local updateMovementDropDownSelection = nil
local syncVideoCaptureSetting = nil
local tweenTime = 0.2

local mouseLockLookScreenUrl = "http://www.roblox.com/asset?id=54071825"
local classicLookScreenUrl = "http://www.roblox.com/Asset?id=45915798"

local hasGraphicsSlider = true
local GraphicsQualityLevels = 10 -- how many levels we allow on graphics slider
local recordingVideo = false

local currentMenuSelection = nil
local lastMenuSelection = {}

local defaultPosition = UDim2.new(0,0,0,0)

local centerDialogs = {}
local mainShield = nil

local settingsChoices = {}

local testReport = false

local inStudioMode = UserSettings().GameSettings:InStudioMode()
-- REMOVE WHEN NOT TESTING
-- inStudioMode = false

local macClient = false
local success, isMac = pcall(function() return not game:GetService("GuiService").IsWindows end)
macClient = success and isMac
-- REMOVE WHEN NOT TESTING
--macClient = true

local customCameraDefaultType = "Default (Classic)"
local touchClient = false
pcall(function() touchClient = game:GetService("UserInputService").TouchEnabled end)

-- REMOVE WHEN NOT TESTING
-- touchClient = true

if touchClient then
	hasGraphicsSlider = false
	customCameraDefaultType = "Default (Follow)"
end


local newMovementScripts = false
local successFlagRead, luaFlagValue = pcall(function() return settings():GetFFlag("UseLuaCameraAndControl") end)
if successFlagRead and luaFlagValue == true then
	newMovementScripts = true
end

local function Color3I(r,g,b)
  return Color3.new(r/255,g/255,b/255)
end

local function robloxLock(instance)
  instance.RobloxLocked = true
  children = instance:GetChildren()
  if children then
	 for i, child in ipairs(children) do
		robloxLock(child)
	 end
  end
end

function resumeGameFunction(shield)
	shield.Settings:TweenPosition(UDim2.new(0.5, -262,-0.5, -200),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
	delay(tweenTime,function()
		shield.Visible = false
		for i = 1, #centerDialogs do
			centerDialogs[i].Visible = false
			game:GetService("GuiService"):RemoveCenterDialog(centerDialogs[i])
		end
		game:GetService("GuiService"):RemoveCenterDialog(shield)
		settingsButton.Active = true
		currentMenuSelection = nil
		lastMenuSelection = {}
		pcall(function() game:GetService("UserInputService").OverrideMouseIconEnabled = false end)
	end)
end

function goToMenu(container,menuName, moveDirection,size,position)
	if type(menuName) ~= "string" then return end
	
	table.insert(lastMenuSelection,currentMenuSelection)
	if menuName == "GameMainMenu" then
		lastMenuSelection = {}
	end

	local containerChildren = container:GetChildren()
	local selectedMenu = false
	for i = 1, #containerChildren do
		if containerChildren[i].Name == menuName then
			containerChildren[i].Visible = true
			currentMenuSelection = {container = container,name = menuName, direction = moveDirection, lastSize = size}
			selectedMenu = true
			if size and position then
				containerChildren[i]:TweenSizeAndPosition(size,position,Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
			elseif size then
				containerChildren[i]:TweenSizeAndPosition(size,UDim2.new(0.5,-size.X.Offset/2,0.5,-size.Y.Offset/2),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
			else
				containerChildren[i]:TweenPosition(UDim2.new(0,0,0,0),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
			end
		else
			if moveDirection == "left" then
				containerChildren[i]:TweenPosition(UDim2.new(-1,-525,0,0),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
			elseif moveDirection == "right" then
				containerChildren[i]:TweenPosition(UDim2.new(1,525,0,0),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
			elseif moveDirection == "up" then
				containerChildren[i]:TweenPosition(UDim2.new(0,0,-1,-400),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
			elseif moveDirection == "down" then
				containerChildren[i]:TweenPosition(UDim2.new(0,0,1,400),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
			end
			delay(tweenTime,function()
				containerChildren[i].Visible = false
			end)
		end
	end	
end

function resetLocalCharacter()
	local player = game:GetService("Players").LocalPlayer
	if player then
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.Health = 0
		end
	end
end

local function createTextButton(text,style,fontSize,buttonSize,buttonPosition)
	local newTextButton = Instance.new("TextButton")
	newTextButton.Font = Enum.Font.SourceSansBold
	newTextButton.FontSize = fontSize
	newTextButton.Size = buttonSize
	newTextButton.Position = buttonPosition
	newTextButton.Style = style
	newTextButton.TextColor3 = Color3.new(1,1,1)
	newTextButton.Text = text
	return newTextButton
end

local function CreateTextButtons(frame, buttons, yPos, ySize)
	if #buttons < 1 then
		error("Must have more than one button")
	end

	local buttonNum = 1
	local buttonObjs = {}

	local function toggleSelection(button)
		for i, obj in ipairs(buttonObjs) do
			if obj == button then
				obj.Style = Enum.ButtonStyle.RobloxRoundDefaultButton
			else
				obj.Style = Enum.ButtonStyle.RobloxRoundButton
			end
		end
	end

	for i, obj in ipairs(buttons) do 
		local button = Instance.new("TextButton")
		button.Name = "Button" .. buttonNum
		button.Font = Enum.Font.SourceSansBold
		button.FontSize = Enum.FontSize.Size18
		button.AutoButtonColor = true
		button.Style = Enum.ButtonStyle.RobloxRoundButton
		button.Text = obj.Text
		button.TextColor3 = Color3.new(1,1,1)
		button.MouseButton1Click:connect(function() toggleSelection(button) obj.Function() end)
		button.Parent = frame
		button.ZIndex = 8
		buttonObjs[buttonNum] = button

		buttonNum = buttonNum + 1
	end
	
	toggleSelection(buttonObjs[1])

	local numButtons = buttonNum-1

	if numButtons == 1 then
		frame.Button1.Position = UDim2.new(0.35, 0, yPos.Scale, yPos.Offset)
		frame.Button1.Size = UDim2.new(.4,0,ySize.Scale, ySize.Offset)
	elseif numButtons == 2 then
		frame.Button1.Position = UDim2.new(0.1, 0, yPos.Scale, yPos.Offset)
		frame.Button1.Size = UDim2.new(.35,0, ySize.Scale, ySize.Offset)

		frame.Button2.Position = UDim2.new(0.55, 0, yPos.Scale, yPos.Offset)
		frame.Button2.Size = UDim2.new(.35,0, ySize.Scale, ySize.Offset)
	elseif numButtons >= 3 then
		local spacing = .1 / numButtons
		local buttonSize = .9 / numButtons

		buttonNum = 1
		while buttonNum <= numButtons do
			buttonObjs[buttonNum].Position = UDim2.new(spacing*buttonNum + (buttonNum-1) * buttonSize, 0, yPos.Scale, yPos.Offset)
			buttonObjs[buttonNum].Size = UDim2.new(buttonSize, 0, ySize.Scale, ySize.Offset)
			buttonNum = buttonNum + 1
		end
	end
end

function setRecordGui(recording, stopRecordButton, recordVideoButton)
	if recording then 
		stopRecordButton.Visible = true
		recordVideoButton.Text = "Stop Recording"
	else
		stopRecordButton.Visible = false
		recordVideoButton.Text = "Record Video"
	end
end

function recordVideoClick(recordVideoButton, stopRecordButton)
	recordingVideo = not recordingVideo
	setRecordGui(recordingVideo, stopRecordButton, recordVideoButton)
end

local currentlyToggling = false;
local DevConsoleToggle = nil;

delay(0, function()
	DevConsoleToggle = gui:WaitForChild("ToggleDevConsole")
end)

function toggleDeveloperConsole()
	if not DevConsoleToggle then
		return
	end

	DevConsoleToggle:Invoke()
end

function backToGame(buttonClicked, shield, settingsButton)
	buttonClicked.Parent.Parent.Parent.Parent.Visible = false
	shield.Visible = false
	for i = 1, #centerDialogs do
		game:GetService("GuiService"):RemoveCenterDialog(centerDialogs[i])
		centerDialogs[i].Visible = false
	end
	centerDialogs = {}
	game:GetService("GuiService"):RemoveCenterDialog(shield)
	settingsButton.Active = true
end

function setDisabledState(guiObject)
	if not guiObject then return end
	
	if guiObject:IsA("TextLabel") then
		guiObject.TextTransparency = 0.9
	elseif guiObject:IsA("TextButton") then
		guiObject.TextTransparency = 0.9
		guiObject.Active = false
	else
		if guiObject["ClassName"] then
			print("setDisabledState() got object of unsupported type.  object type is ",guiObject.ClassName)
		end
	end
end

local function createHelpDialog(baseZIndex)
	local shield = Instance.new("Frame")
	shield.Name = "HelpDialogShield"
	shield.Active = true
	shield.Visible = false
	shield.Size = UDim2.new(1,0,1,0)
	shield.BackgroundColor3 = Color3I(51,51,51)
	shield.BorderColor3 = Color3I(27,42,53)
	shield.BackgroundTransparency = 0.4
	shield.ZIndex = baseZIndex + 2

	local helpDialog = Instance.new("Frame")
	helpDialog.Name = "HelpDialog"
	helpDialog.Style = Enum.FrameStyle.DropShadow
	helpDialog.Position = UDim2.new(.2, 0, .2, 0)
	helpDialog.Size = UDim2.new(0.6, 0, 0.6, 0)
	helpDialog.Active = true
	helpDialog.Parent = shield
	helpDialog.ZIndex = baseZIndex + 2

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Text = "Keyboard & Mouse Controls"
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.FontSize = Enum.FontSize.Size36
	titleLabel.Position = UDim2.new(0, 0, 0.025, 0)
	titleLabel.Size = UDim2.new(1, 0, 0, 40)
	titleLabel.TextColor3 = Color3.new(1,1,1)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Parent = helpDialog
	titleLabel.ZIndex = baseZIndex + 2

	local buttonRow = Instance.new("Frame")
	buttonRow.Name = "Buttons"
	buttonRow.Position = UDim2.new(0.1, 0, .07, 40)
	buttonRow.Size = UDim2.new(0.8, 0, 0, 45)
	buttonRow.BackgroundTransparency = 1
	buttonRow.Parent = helpDialog
	buttonRow.ZIndex = baseZIndex + 2

	local imageFrame = Instance.new("Frame")
	imageFrame.Name = "ImageFrame"
	imageFrame.Position = UDim2.new(0.05, 0, 0.075, 80)
	imageFrame.Size = UDim2.new(0.9, 0, .9, -120)
	imageFrame.BackgroundTransparency = 1
	imageFrame.Parent = helpDialog
	imageFrame.ZIndex = baseZIndex + 2

	local layoutFrame = Instance.new("Frame")
	layoutFrame.Name = "LayoutFrame"
	layoutFrame.Position = UDim2.new(0.5, 0, 0, 0)
	layoutFrame.Size = UDim2.new(1.5, 0, 1, 0)
	layoutFrame.BackgroundTransparency = 1
	layoutFrame.SizeConstraint = Enum.SizeConstraint.RelativeYY
	layoutFrame.Parent = imageFrame
	layoutFrame.ZIndex = baseZIndex + 2

	local image = Instance.new("ImageLabel")
	image.Name = "Image"
	if UserSettings().GameSettings.ControlMode == Enum.ControlMode["Mouse Lock Switch"] then
		image.Image = mouseLockLookScreenUrl
	else
		image.Image = classicLookScreenUrl
	end
	image.Position = UDim2.new(-0.5, 0, 0, 0)
	image.Size = UDim2.new(1, 0, 1, 0)
	image.BackgroundTransparency = 1
	image.Parent = layoutFrame
	image.ZIndex = baseZIndex + 2
	
	local buttons = {}
	buttons[1] = {}
	buttons[1].Text = "Look"
	buttons[1].Function = function()
		if UserSettings().GameSettings.ControlMode == Enum.ControlMode["Mouse Lock Switch"] then
			image.Image = mouseLockLookScreenUrl
		else
			image.Image = classicLookScreenUrl
		end
	end 
	buttons[2] = {}
	buttons[2].Text = "Move"
	buttons[2].Function = function() 
		image.Image = "http://www.roblox.com/Asset?id=45915811"
	end 
	buttons[3] = {}
	buttons[3].Text = "Gear"
	buttons[3].Function = function() 
		image.Image = "http://www.roblox.com/Asset?id=45917596"
	end
	buttons[4] = {}
	buttons[4].Text = "Zoom"
	buttons[4].Function = function() 	
		image.Image = "http://www.roblox.com/Asset?id=45915825"
	end 

	CreateTextButtons(buttonRow, buttons, UDim.new(0, 0), UDim.new(1,0))
	
	local devConsoleButton = Create'TextButton'{
		Name = "DeveloperConsoleButton";
		Text = "Log";
		Size = UDim2.new(0,60,0,30);
		Style = Enum.ButtonStyle.RobloxRoundButton;
		Position = UDim2.new(1,-65,1,-35);
		Font = Enum.Font.SourceSansBold;
		FontSize = Enum.FontSize.Size18;
		TextColor3 = Color3.new(1,1,1);
		ZIndex = baseZIndex + 4;
		BackgroundTransparency = 1;
		Parent = helpDialog;
	}
	
	Create'TextLabel'{
		Name = "DeveloperConsoleButton";
		Text = "F9";
		Size = UDim2.new(0,14,0,14);
		Position = UDim2.new(1,-6,0, -2);
		Font = Enum.Font.SourceSansBold;
		FontSize = Enum.FontSize.Size12;
		TextColor3 = Color3.new(0,1,0);
		ZIndex = baseZIndex + 4;
		BackgroundTransparency = 1;
		Parent = devConsoleButton;
	}
	
	waitForProperty(game:GetService("Players"), "LocalPlayer")
	game:GetService("Players").LocalPlayer:GetMouse().KeyDown:connect(function(key)
		if string.byte(key) == 34 then --F9
			toggleDeveloperConsole()
		end
	end)

	devConsoleButton.MouseButton1Click:connect(function()
		toggleDeveloperConsole()
		shield.Visible = false
		game:GetService("GuiService"):RemoveCenterDialog(shield)
	end)
			
	-- set up listeners for type of mouse mode, but keep constructing gui at same time
	delay(0, function()
		waitForChild(gui,"UserSettingsShield")
		waitForChild(gui.UserSettingsShield,"Settings")
		waitForChild(gui.UserSettingsShield.Settings,"SettingsStyle")
		waitForChild(gui.UserSettingsShield.Settings.SettingsStyle, "GameSettingsMenu")
		waitForChild(gui.UserSettingsShield.Settings.SettingsStyle.GameSettingsMenu, "CameraField")
		waitForChild(gui.UserSettingsShield.Settings.SettingsStyle.GameSettingsMenu.CameraField, "DropDownMenuButton")
		gui.UserSettingsShield.Settings.SettingsStyle.GameSettingsMenu.CameraField.DropDownMenuButton.Changed:connect(function(prop)
			if prop ~= "Text" then return end
			if buttonRow.Button1.Style == Enum.ButtonStyle.RobloxRoundDefaultButton then -- only change if this is the currently selected panel
				if gui.UserSettingsShield.Settings.SettingsStyle.GameSettingsMenu.CameraField.DropDownMenuButton.Text == "Classic" then
					image.Image = classicLookScreenUrl
				else
					image.Image = mouseLockLookScreenUrl
				end
			end
		end)
	end)


	local okBtn = Instance.new("TextButton")
	okBtn.Name = "OkBtn"
	okBtn.Text = "OK"
	okBtn.Modal = true
	okBtn.Size = UDim2.new(0.3, 0, 0, 45)
	okBtn.Position = UDim2.new(0.35, 0, .975, -50)
	okBtn.Font = Enum.Font.SourceSansBold
	okBtn.FontSize = Enum.FontSize.Size18
	okBtn.BackgroundTransparency = 1
	okBtn.TextColor3 = Color3.new(1,1,1)
	okBtn.Style = Enum.ButtonStyle.RobloxRoundDefaultButton
	okBtn.ZIndex = baseZIndex + 2
	okBtn.MouseButton1Click:connect(
		function()
			shield.Visible = false
			game:GetService("GuiService"):RemoveCenterDialog(shield)
		end)
	okBtn.Parent = helpDialog

	robloxLock(shield)
	return shield
end

local function createLeaveConfirmationMenu(baseZIndex,shield)
	local frame = Instance.new("Frame")
	frame.Name = "LeaveConfirmationMenu"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1,0,1,0)
	frame.Position = UDim2.new(0,0,2,400)
	frame.ZIndex = baseZIndex + 4
	
	local yesButton = createTextButton("Leave",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size24,UDim2.new(0,128,0,50),UDim2.new(0,313,0.8,0))
	yesButton.Name = "YesButton"
	yesButton.ZIndex = baseZIndex + 4
	yesButton.Parent = frame
	yesButton.Modal = true
	yesButton:SetVerb("Exit")
	
	local noButton = createTextButton("Stay",Enum.ButtonStyle.RobloxRoundDefaultButton,Enum.FontSize.Size24,UDim2.new(0,128,0,50),UDim2.new(0,90,0.8,0))
	noButton.Name = "NoButton"
	noButton.Parent = frame
	noButton.ZIndex = baseZIndex + 4
	noButton.MouseButton1Click:connect(function()
		goToMenu(shield.Settings.SettingsStyle,"GameMainMenu","down",UDim2.new(0,525,0,430))
		shield.Settings:TweenSize(UDim2.new(0,525,0,430),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
	end)
	
	local leaveText = Instance.new("TextLabel")
	leaveText.Name = "LeaveText"
	leaveText.Text = "Leave this game?"
	leaveText.Size = UDim2.new(1,0,0.8,0)
	leaveText.TextWrap = true
	leaveText.TextColor3 = Color3.new(1,1,1)
	leaveText.Font = Enum.Font.SourceSansBold
	leaveText.FontSize = Enum.FontSize.Size36
	leaveText.BackgroundTransparency = 1
	leaveText.ZIndex = baseZIndex + 4
	leaveText.Parent = frame
	
	return frame
end

local function createResetConfirmationMenu(baseZIndex,shield)
	local frame = Instance.new("Frame")
	frame.Name = "ResetConfirmationMenu"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1,0,1,0)
	frame.Position = UDim2.new(0,0,2,400)
	frame.ZIndex = baseZIndex + 4
	
	local yesButton = createTextButton("Reset",Enum.ButtonStyle.RobloxRoundDefaultButton,Enum.FontSize.Size24,UDim2.new(0,128,0,50),UDim2.new(0,313,0,280))
	yesButton.Name = "YesButton"
	yesButton.ZIndex = baseZIndex + 4
	yesButton.Parent = frame
	yesButton.Modal  = true
	yesButton.MouseButton1Click:connect(function()
		resumeGameFunction(shield)
		resetLocalCharacter()
	end)
	
	local noButton = createTextButton("Cancel",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size24,UDim2.new(0,128,0,50),UDim2.new(0,90,0,280))
	noButton.Name = "NoButton"
	noButton.Parent = frame
	noButton.ZIndex = baseZIndex + 4
	noButton.MouseButton1Click:connect(function()
		goToMenu(shield.Settings.SettingsStyle,"GameMainMenu","down",UDim2.new(0,525,0,430))
		shield.Settings:TweenSize(UDim2.new(0,525,0,430),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
	end)
	
	local resetCharacterText = Instance.new("TextLabel")
	resetCharacterText.Name = "ResetCharacterText"
	resetCharacterText.Text = "Are you sure you want to reset your character?"
	resetCharacterText.Size = UDim2.new(1,0,0.8,0)
	resetCharacterText.TextWrap = true
	resetCharacterText.TextColor3 = Color3.new(1,1,1)
	resetCharacterText.Font = Enum.Font.SourceSansBold
	resetCharacterText.FontSize = Enum.FontSize.Size36
	resetCharacterText.BackgroundTransparency = 1
	resetCharacterText.ZIndex = baseZIndex + 4
	resetCharacterText.Parent = frame
	
	local fineResetCharacterText = resetCharacterText:Clone()
	fineResetCharacterText.Name = "FineResetCharacterText"
	fineResetCharacterText.Text = "You will be put back on a spawn point"
	fineResetCharacterText.Size = UDim2.new(0,303,0,18)
	fineResetCharacterText.Position = UDim2.new(0, 109, 0, 215)
	fineResetCharacterText.FontSize = Enum.FontSize.Size18
	fineResetCharacterText.Parent = frame
	
	return frame
end

local function createGameMainMenu(baseZIndex, shield)

	local buttonTop = 54

	local gameMainMenuFrame = Instance.new("Frame")
	gameMainMenuFrame.Name = "GameMainMenu"
	gameMainMenuFrame.BackgroundTransparency = 1
	gameMainMenuFrame.Size = UDim2.new(1,0,1,0)
	gameMainMenuFrame.ZIndex = baseZIndex + 4
	gameMainMenuFrame.Parent = settingsFrame

	-- GameMainMenu Children

	-- RESUME GAME
	local resumeGameButton = createTextButton("Resume Game",Enum.ButtonStyle.RobloxRoundDefaultButton,Enum.FontSize.Size24,UDim2.new(0,340,0,50),UDim2.new(0.5,-170,0,buttonTop))
	resumeGameButton.Name = "resumeGameButton"
	resumeGameButton.ZIndex = baseZIndex + 4
	resumeGameButton.Parent = gameMainMenuFrame
	resumeGameButton.Modal = true
	resumeGameButton.MouseButton1Click:connect(function() resumeGameFunction(shield) end)
	buttonTop = buttonTop + 51

	-- RESET CHARACTER
	local resetButton = createTextButton("Reset Character",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size24,UDim2.new(0,340,0,50),UDim2.new(0.5,-170,0,buttonTop))
	resetButton.Name = "ResetButton"
	resetButton.ZIndex = baseZIndex + 4
	resetButton.Parent = gameMainMenuFrame
	buttonTop = buttonTop + 51

	-- GAME SETTINGS
	local gameSettingsButton = createTextButton("Game Settings",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size24,UDim2.new(0,340,0,50),UDim2.new(0.5,-170,0,buttonTop))
	gameSettingsButton.Name = "SettingsButton"
	gameSettingsButton.ZIndex = baseZIndex + 4
	gameSettingsButton.Parent = gameMainMenuFrame
	buttonTop = buttonTop + 51

	-- HELP BUTTON
	local robloxHelpButton = createTextButton("Help",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size18,UDim2.new(0,164,0,50),UDim2.new(0,92,0,buttonTop))
	robloxHelpButton.Name = "HelpButton"
	robloxHelpButton.ZIndex = baseZIndex + 4
	robloxHelpButton.Parent = gameMainMenuFrame
	robloxHelpButton.Visible =  not touchClient
	if macClient or touchClient then
		robloxHelpButton.Size = UDim2.new(0,340,0,50)
		robloxHelpButton.FontSize = Enum.FontSize.Size24
	end

	helpButton = robloxHelpButton
			
	local helpDialog = createHelpDialog(baseZIndex)
	helpDialog.Parent = gui
		
	helpButton.MouseButton1Click:connect(
		function() 
			table.insert(centerDialogs,helpDialog)
			game:GetService("GuiService"):AddCenterDialog(helpDialog, Enum.CenterDialogType.ModalDialog,
				--ShowFunction
				function()
					helpDialog.Visible = true
					mainShield.Visible = false
				end,
				--HideFunction
				function()
					helpDialog.Visible = false
				end)
		end)
	helpButton.Active = true
	
	-- SCREEN SHOT
	local screenshotButton = createTextButton("Screenshot",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size18,UDim2.new(0,168,0,50),UDim2.new(0,264,0,buttonTop))
	screenshotButton.Name = "ScreenshotButton"
	screenshotButton.ZIndex = baseZIndex + 4
	screenshotButton.Parent = gameMainMenuFrame
	screenshotButton.Visible = not macClient and not touchClient
	screenshotButton:SetVerb("Screenshot")
	
	if not touchClient then
		buttonTop = buttonTop + 51
	end

	-- REPORT ABUSE
	local reportAbuseButton = createTextButton("Report Abuse",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size18,UDim2.new(0,164,0,50),UDim2.new(0,92,0,buttonTop))
	reportAbuseButton.Name = "ReportAbuseButton"
	reportAbuseButton.ZIndex = baseZIndex + 4
	reportAbuseButton.Parent = gameMainMenuFrame
	if macClient or touchClient then
		reportAbuseButton.Size = UDim2.new(0,340,0,50)
		reportAbuseButton.FontSize = Enum.FontSize.Size24
	end

	-- RECORD VIDEO
	local recordVideoButton = createTextButton("Record Video",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size18,UDim2.new(0,168,0,50),UDim2.new(0,264,0,buttonTop))
	recordVideoButton.Name = "RecordVideoButton"
	recordVideoButton.ZIndex = baseZIndex + 4
	recordVideoButton.Parent = gameMainMenuFrame
	recordVideoButton.Visible = not macClient and not touchClient
	recordVideoButton:SetVerb("RecordToggle")
	
	local stopRecordButton = Instance.new("ImageButton")
	stopRecordButton.Name = "StopRecordButton"
	stopRecordButton.BackgroundTransparency = 1
	stopRecordButton.Image = "rbxasset://textures/ui/RecordStop.png"
	stopRecordButton.Size = UDim2.new(0,59,0,27)
	stopRecordButton:SetVerb("RecordToggle")
	
	stopRecordButton.MouseButton1Click:connect(function() recordVideoClick(recordVideoButton, stopRecordButton) end)
	stopRecordButton.Visible = false
	stopRecordButton.Parent = gui
	buttonTop = buttonTop + 51

	-- LEAVE GAME	
	local leaveGameButton = createTextButton("Leave Game",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size24,UDim2.new(0,340,0,50),UDim2.new(0.5,-170,0,buttonTop))
	leaveGameButton.Name = "LeaveGameButton"
	leaveGameButton.ZIndex = baseZIndex + 4
	leaveGameButton.Parent = gameMainMenuFrame

	return gameMainMenuFrame
end

local function createGameSettingsMenu(baseZIndex, shield)
	local gameSettingsMenuFrame = Instance.new("Frame")
	gameSettingsMenuFrame.Name = "GameSettingsMenu"
	gameSettingsMenuFrame.BackgroundTransparency = 1
	gameSettingsMenuFrame.Size = UDim2.new(1,0,1,0)
	gameSettingsMenuFrame.ZIndex = baseZIndex + 4

	local itemTop = 0
	if game:GetService("GuiService"):GetScreenResolution().y <= 500 then
		itemTop = 50
	end
	----------------------------------------------------------------------------------------------------
	--  C A M E R A    C O N T R O L S
	----------------------------------------------------------------------------------------------------

	if not touchClient then
		local cameraLabel = Instance.new("TextLabel")
		cameraLabel.Name = "CameraLabel"
		if (newMovementScripts) then
			cameraLabel.Text = "Enable Mouse Lock Switch"
		else
			cameraLabel.Text = "Character & Camera Controls"
		end
		cameraLabel.Font = Enum.Font.SourceSansBold
		cameraLabel.FontSize = Enum.FontSize.Size18
		cameraLabel.Position = UDim2.new(0,31,0,itemTop + 6)
		cameraLabel.Size = UDim2.new(0,224,0,18)
		cameraLabel.TextColor3 = Color3I(255,255,255)
		cameraLabel.TextXAlignment = Enum.TextXAlignment.Left
		cameraLabel.BackgroundTransparency = 1
		cameraLabel.ZIndex = baseZIndex + 4
		cameraLabel.Parent = gameSettingsMenuFrame

		if (newMovementScripts) then
			local mouseLockDisabled = Instance.new("TextLabel")
			mouseLockDisabled.Name = "mouseLockDisabled"
			mouseLockDisabled.Text = "Set by Game"
			mouseLockDisabled.Font = Enum.Font.SourceSansBold
			mouseLockDisabled.FontSize = Enum.FontSize.Size18
			mouseLockDisabled.Position = UDim2.new(0,275,0,itemTop + 6)
			mouseLockDisabled.Size = UDim2.new(0,200,0,18)
			mouseLockDisabled.TextColor3 = Color3I(180,180,180)
			mouseLockDisabled.TextXAlignment = Enum.TextXAlignment.Left
			mouseLockDisabled.BackgroundTransparency = 1
			mouseLockDisabled.ZIndex = baseZIndex + 4
			mouseLockDisabled.Parent = gameSettingsMenuFrame

			settingsChoices["MouseLockDisabled"] = mouseLockDisabled
		end

		local mouseLockLabel = game:GetService("CoreGui").RobloxGui:FindFirstChild("MouseLockLabel",true)
		if (newMovementScripts) then
			local mouseLockCheckbox = createTextButton("",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size18,UDim2.new(0,32,0,32),UDim2.new(0, 270, 0, itemTop- 4))
			mouseLockCheckbox.Name = "mouseLockCheckbox"
			mouseLockCheckbox.ZIndex = baseZIndex + 4
			mouseLockCheckbox.Parent = gameSettingsMenuFrame
			if UserSettings().GameSettings.ControlMode.Name == "MouseLockSwitch" then 
				mouseLockCheckbox.Text = "X" 
			end
			mouseLockCheckbox.MouseButton1Click:connect(function()
				if mouseLockCheckbox.Text == "" then
					mouseLockCheckbox.Text = "X"
					UserSettings().GameSettings.ControlMode =  "MouseLockSwitch"
				else
					mouseLockCheckbox.Text = ""
					UserSettings().GameSettings.ControlMode =  "Classic"
				end

				pcall(function()
					if mouseLockLabel and UserSettings().GameSettings.ControlMode == Enum.ControlMode["Mouse Lock Switch"] then
						mouseLockLabel.Visible = true
					elseif mouseLockLabel then
						mouseLockLabel.Visible = false
					end
				end)
			end)	
			settingsChoices["MouseLockEnabled"] = mouseLockCheckbox
		else

			local enumItems = Enum.ControlMode:GetEnumItems()
			local enumNames = {}
			local enumNameToItem = {}
			for i,obj in ipairs(enumItems) do
				enumNames[i] = obj.Name
				enumNameToItem[obj.Name] = obj
			end

			local cameraDropDown
			cameraDropDown, updateCameraDropDownSelection = RbxGui.CreateDropDownMenu(enumNames, 
				function(text) 
					UserSettings().GameSettings.ControlMode = enumNameToItem[text] 
					
					pcall(function()
						if mouseLockLabel and UserSettings().GameSettings.ControlMode == Enum.ControlMode["Mouse Lock Switch"] then
							mouseLockLabel.Visible = true
						elseif mouseLockLabel then
							mouseLockLabel.Visible = false
						end
					end)
				end, false, true, baseZIndex + 1)
			cameraDropDown.Name = "CameraField"
			cameraDropDown.Position = UDim2.new(0, 270, 0, itemTop)
			cameraDropDown.Size = UDim2.new(0,200,0,32)
			cameraDropDown.Parent = gameSettingsMenuFrame
		end

		itemTop = itemTop + 35
	end

	----------------------------------------------------------------------------------------------------
	--  C U S T O M    C A M E R A    C O N T R O L S
	----------------------------------------------------------------------------------------------------

	local smartCameraLabel = Instance.new("TextLabel")
	smartCameraLabel.Name = "SmartCameraLabel"
	smartCameraLabel.Text = "Camera Mode"
	smartCameraLabel.Font = Enum.Font.SourceSansBold
	smartCameraLabel.FontSize = Enum.FontSize.Size18
	smartCameraLabel.Position = UDim2.new(0,31,0,itemTop + 6)
	smartCameraLabel.Size = UDim2.new(0,224,0,18)
	smartCameraLabel.TextColor3 = Color3I(255,255,255)
	smartCameraLabel.TextXAlignment = Enum.TextXAlignment.Left
	smartCameraLabel.BackgroundTransparency = 1
	smartCameraLabel.ZIndex = baseZIndex + 4
	smartCameraLabel.Parent = gameSettingsMenuFrame

	if (newMovementScripts) then
		local smartCameraDisabled = Instance.new("TextLabel")
		smartCameraDisabled.Name = "smartCameraDisabled"
		smartCameraDisabled.Text = "Set by Game"
		smartCameraDisabled.Font = Enum.Font.SourceSansBold
		smartCameraDisabled.FontSize = Enum.FontSize.Size18
		smartCameraDisabled.Position = UDim2.new(0,275,0,itemTop + 6)
		smartCameraDisabled.Size = UDim2.new(0,200,0,18)
		smartCameraDisabled.TextColor3 = Color3I(180,180,180)
		smartCameraDisabled.TextXAlignment = Enum.TextXAlignment.Left
		smartCameraDisabled.BackgroundTransparency = 1
		smartCameraDisabled.ZIndex = baseZIndex + 4
		smartCameraDisabled.Parent = gameSettingsMenuFrame

		settingsChoices["CameraModeDevChoice"] = smartCameraDisabled
	end

	local smartEnumItems = nil
	if (not newMovementScripts) then
		smartEnumItems = Enum.CustomCameraMode:GetEnumItems()
	elseif (touchClient) then
		smartEnumItems = Enum.TouchCameraMovementMode:GetEnumItems()
	else
		smartEnumItems = Enum.ComputerCameraMovementMode:GetEnumItems()
	end

	local smartEnumNames = {}
	local smartEnumNameToItem = {}

	for i,obj in pairs(smartEnumItems) do
		local displayName = obj.Name
		if (obj.Name == "Default") then
			displayName = customCameraDefaultType
		end
		smartEnumNames[i] = displayName
		smartEnumNameToItem[displayName] = obj.Value
	end

	local smartCameraDropDown
	smartCameraDropDown, updateSmartCameraDropDownSelection = RbxGui.CreateDropDownMenu(smartEnumNames, 
		function(text) 
			if (not newMovementScripts) then
				UserSettings().GameSettings.CameraMode = smartEnumNameToItem[text]
			elseif (touchClient) then
				UserSettings().GameSettings.TouchCameraMovementMode = smartEnumNameToItem[text] 
			else
				UserSettings().GameSettings.ComputerCameraMovementMode = smartEnumNameToItem[text] 
			end
		end, false, true, baseZIndex + 1)
	smartCameraDropDown.Name = "SmartCameraField"
	smartCameraDropDown.Position = UDim2.new(0, 270, 0, itemTop)
	smartCameraDropDown.Size = UDim2.new(0,200,0,32)
	smartCameraDropDown.Parent = gameSettingsMenuFrame

	settingsChoices["CameraModeUserChoice"] = smartCameraDropDown

	itemTop = itemTop + 35


	----------------------------------------------------------------------------------------------------
	--  T O U C H    M O V E M E N T    C O N T R O L S
	----------------------------------------------------------------------------------------------------

	if (touchClient or newMovementScripts) then
		local movementModeLabel = Instance.new("TextLabel")
		movementModeLabel.Name = "movementModeLabel"
		movementModeLabel.Text = "Movement Mode"
		movementModeLabel.Font = Enum.Font.SourceSansBold
		movementModeLabel.FontSize = Enum.FontSize.Size18
		movementModeLabel.Position = UDim2.new(0,31,0,itemTop + 6)
		movementModeLabel.Size = UDim2.new(0,224,0,18)
		movementModeLabel.TextColor3 = Color3I(255,255,255)
		movementModeLabel.TextXAlignment = Enum.TextXAlignment.Left
		movementModeLabel.BackgroundTransparency = 1
		movementModeLabel.ZIndex = baseZIndex + 4
		movementModeLabel.Parent = gameSettingsMenuFrame

		if (newMovementScripts) then
			local movementModeDisabled = Instance.new("TextLabel")
			movementModeDisabled.Name = "movementModeDisabled"
			movementModeDisabled.Text = "Set by Game"
			movementModeDisabled.Font = Enum.Font.SourceSansBold
			movementModeDisabled.FontSize = Enum.FontSize.Size18
			movementModeDisabled.Position = UDim2.new(0,275,0,itemTop + 6)
			movementModeDisabled.Size = UDim2.new(0,200,0,18)
			movementModeDisabled.TextColor3 = Color3I(180,180,180)
			movementModeDisabled.TextXAlignment = Enum.TextXAlignment.Left
			movementModeDisabled.BackgroundTransparency = 1
			movementModeDisabled.ZIndex = baseZIndex + 4
			movementModeDisabled.Parent = gameSettingsMenuFrame

			settingsChoices["MovementModeDevChoice"] = movementModeDisabled
		end

		local enumNames
		local enumNameToItem 
		if (touchClient) then
			local touchEnumItems = Enum.TouchMovementMode:GetEnumItems()
			local touchEnumNames = {}
			local touchEnumNameToItem = {}
			for i,obj in ipairs(touchEnumItems) do
				local displayName = obj.Name
				if (obj.Name == "Default") then
					displayName = "Default (Thumbstick)"
				end
				touchEnumNames[i] = displayName
				touchEnumNameToItem[displayName] = obj
			end
			enumNames = touchEnumNames
			enumNameToItem = touchEnumNameToItem
		else 
			local computerEnumItems = Enum.ComputerMovementMode:GetEnumItems()
			local computerEnumNames = {}
			local computerEnumNameToItem = {}
			for i,obj in ipairs(computerEnumItems) do
				local displayName = obj.Name
				if (obj.Name == "Default") then
					displayName = "Default (Keyboard)"
				end
				computerEnumNames[i] = displayName
				computerEnumNameToItem[displayName] = obj
			end
			enumNames = computerEnumNames
			enumNameToItem = computerEnumNameToItem
		end

		local movementModeDropDown
		movementModeDropDown,  updateMovementDropDownSelection = RbxGui.CreateDropDownMenu(enumNames, 
			function(text) 
				if (touchClient) then
					UserSettings().GameSettings.TouchMovementMode = enumNameToItem[text]
				else
					UserSettings().GameSettings.ComputerMovementMode = enumNameToItem[text]
				end
			end, false, true, baseZIndex + 1)
		movementModeDropDown.Name = "movementModeField"
		movementModeDropDown.Position = UDim2.new(0, 270, 0, itemTop)
		movementModeDropDown.Size = UDim2.new(0,200,0,32)
		movementModeDropDown.Parent = gameSettingsMenuFrame

		settingsChoices["MovementModeUserChoice"] = movementModeDropDown

		itemTop = itemTop + 35
	end

	----------------------------------------------------------------------------------------------------
	--  V I D E O   C A P T U R E   S E T T I N G S
	----------------------------------------------------------------------------------------------------
	if not macClient and not touchClient then
		local videoCaptureLabel = Instance.new("TextLabel")
		videoCaptureLabel.Name = "VideoCaptureLabel"
		videoCaptureLabel.Text = "After Capturing Video"
		videoCaptureLabel.Font = Enum.Font.SourceSansBold
		videoCaptureLabel.FontSize = Enum.FontSize.Size18
		videoCaptureLabel.Position = UDim2.new(0,32,0,itemTop + 6)
		videoCaptureLabel.Size = UDim2.new(0,164,0,18)
		videoCaptureLabel.BackgroundTransparency = 1
		videoCaptureLabel.TextColor3 = Color3I(255,255,255)
		videoCaptureLabel.TextXAlignment = Enum.TextXAlignment.Left
		videoCaptureLabel.ZIndex = baseZIndex + 4
		videoCaptureLabel.Parent = gameSettingsMenuFrame

		local videoNames = {}
		local videoNameToItem = {}
		videoNames[1] = "Just Save to Disk"
		videoNameToItem[videoNames[1]] = Enum.UploadSetting["Never"]
		videoNames[2] = "Upload to YouTube"
		videoNameToItem[videoNames[2]] = Enum.UploadSetting["Ask me first"]

		local videoCaptureDropDown = nil
		videoCaptureDropDown, updateVideoCaptureDropDownSelection = RbxGui.CreateDropDownMenu(videoNames, 
			function(text) 
				UserSettings().GameSettings.VideoUploadPromptBehavior = videoNameToItem[text]
			end, false, true, baseZIndex + 1)
		videoCaptureDropDown.Name = "VideoCaptureField"
		videoCaptureDropDown.Position = UDim2.new(0, 270, 0, itemTop)
		videoCaptureDropDown.Size = UDim2.new(0,200,0,32)
		videoCaptureDropDown.Parent = gameSettingsMenuFrame

		syncVideoCaptureSetting = function()
			if UserSettings().GameSettings.VideoUploadPromptBehavior == Enum.UploadSetting["Never"] then
				updateVideoCaptureDropDownSelection(videoNames[1])
			elseif UserSettings().GameSettings.VideoUploadPromptBehavior == Enum.UploadSetting["Ask me first"] then
				updateVideoCaptureDropDownSelection(videoNames[2])
			else
				UserSettings().GameSettings.VideoUploadPromptBehavior = Enum.UploadSetting["Ask me first"]
				updateVideoCaptureDropDownSelection(videoNames[2])
			end
		end
		itemTop = itemTop + 35
	end
	
	----------------------------------------------------------------------------------------------------
	-- F U L L  S C R E E N    M O D E
	----------------------------------------------------------------------------------------------------

	local fullscreenText = nil
	local fullscreenShortcut = nil
	local fullscreenCheckbox = nil

	if not touchClient then

		itemTop = itemTop + 15

		fullscreenText = Instance.new("TextLabel")
		fullscreenText.Name = "FullscreenText"
		fullscreenText.Text = "Fullscreen Mode"

		fullscreenText.Position = UDim2.new(0,31,0,itemTop + 6)
		fullscreenText.Size = UDim2.new(0,224,0,18)

		fullscreenText.Font = Enum.Font.SourceSansBold
		fullscreenText.FontSize = Enum.FontSize.Size18
		fullscreenText.TextXAlignment = Enum.TextXAlignment.Left
		fullscreenText.TextColor3 = Color3.new(1,1,1)
		fullscreenText.ZIndex = baseZIndex + 4
		fullscreenText.BackgroundTransparency = 1
		fullscreenText.Parent = gameSettingsMenuFrame
		
		fullscreenCheckbox = createTextButton("",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size18,UDim2.new(0,32,0,32),UDim2.new(0, 270, 0, itemTop- 4))
		fullscreenCheckbox.Name = "FullscreenCheckbox"
		fullscreenCheckbox.ZIndex = baseZIndex + 4
		fullscreenCheckbox.Parent = gameSettingsMenuFrame
		fullscreenCheckbox:SetVerb("ToggleFullScreen")
		if UserSettings().GameSettings:InFullScreen() then fullscreenCheckbox.Text = "X" end
		if hasGraphicsSlider then
			UserSettings().GameSettings.FullscreenChanged:connect(function(isFullscreen)
				if isFullscreen then
					fullscreenCheckbox.Text = "X"
				else
					fullscreenCheckbox.Text = ""
				end
			end)
		else
			fullscreenCheckbox.MouseButton1Click:connect(function()
				if fullscreenCheckbox.Text == "" then
					fullscreenCheckbox.Text = "X"
				else
					fullscreenCheckbox.Text = ""
				end
			end)	
		end
	end

	----------------------------------------------------------------------------------------------------
	-- G R A P H I C S    S L I D E R
	----------------------------------------------------------------------------------------------------
	local graphicsSlider, graphicsLevel = nil
	if hasGraphicsSlider then
		local graphicsQualityYOffset = -45

		local qualityText = Instance.new("TextLabel")
		qualityText.Name = "QualityText"
		qualityText.Text = "Graphics Quality"
		qualityText.Size = UDim2.new(0,224,0,18)
		qualityText.Position = UDim2.new(0,31,0,239 + graphicsQualityYOffset)

		qualityText.TextXAlignment = Enum.TextXAlignment.Left
		qualityText.Font = Enum.Font.SourceSansBold
		qualityText.FontSize = Enum.FontSize.Size18
		qualityText.TextColor3 = Color3.new(1,1,1)
		qualityText.ZIndex = baseZIndex + 4
		qualityText.BackgroundTransparency = 1
		qualityText.Parent = gameSettingsMenuFrame
		qualityText.Visible = not inStudioMode
		
		local autoText = qualityText:clone()
		autoText.Name = "AutoText"
		autoText.Text = "Auto"
		autoText.Position = UDim2.new(0,235,0,239 + graphicsQualityYOffset)
		autoText.TextColor3 = Color3.new(128/255,128/255,128/255)
		autoText.Size = UDim2.new(0,34,0,18)
		autoText.Parent = gameSettingsMenuFrame
		autoText.Visible = not inStudioMode
		
		local fasterText = autoText:clone()
		fasterText.Name = "FasterText"
		fasterText.Text = "Faster"
		fasterText.Position = UDim2.new(0,185,0,274 + graphicsQualityYOffset)
		fasterText.TextColor3 = Color3.new(95,95,95)
		fasterText.FontSize = Enum.FontSize.Size14
		fasterText.Parent = gameSettingsMenuFrame
		fasterText.Visible = not inStudioMode
		
		local betterQualityText = autoText:clone()
		betterQualityText.Name = "BetterQualityText"
		betterQualityText.Text = "Better Quality"
		betterQualityText.TextWrap = true
		betterQualityText.Size = UDim2.new(0,41,0,28)
		betterQualityText.Position = UDim2.new(0,390,0,269 + graphicsQualityYOffset)
		betterQualityText.TextColor3 = Color3.new(95,95,95)
		betterQualityText.FontSize = Enum.FontSize.Size14
		betterQualityText.Parent = gameSettingsMenuFrame
		betterQualityText.Visible = not inStudioMode
		
		local autoGraphicsButton = createTextButton("X",Enum.ButtonStyle.RobloxRoundButton,Enum.FontSize.Size18,UDim2.new(0,32,0,32),UDim2.new(0,270,0,232 + graphicsQualityYOffset))
		autoGraphicsButton.Name = "AutoGraphicsButton"
		autoGraphicsButton.ZIndex = baseZIndex + 4
		autoGraphicsButton.Parent = gameSettingsMenuFrame
		autoGraphicsButton.Visible = not inStudioMode
		
		graphicsSlider, graphicsLevel = RbxGui.CreateSliderNew(GraphicsQualityLevels,150,UDim2.new(0, 230, 0, 280 + graphicsQualityYOffset)) -- graphics - 1 because slider starts at 1 instead of 0
		graphicsSlider.Parent = gameSettingsMenuFrame
		graphicsSlider.Bar.ZIndex = baseZIndex + 4
		graphicsSlider.Bar.Slider.ZIndex = baseZIndex + 5
		graphicsSlider.Visible = not inStudioMode
		graphicsLevel.Value = math.floor((settings().Rendering:GetMaxQualityLevel() - 1)/2)
		
		local graphicsSetter = Instance.new("TextBox")
		graphicsSetter.Name = "GraphicsSetter"
		graphicsSetter.BackgroundColor3 = Color3.new(0,0,0)
		graphicsSetter.BorderColor3 = Color3.new(128/255,128/255,128/255)
		graphicsSetter.Size = UDim2.new(0,50,0,25)
		graphicsSetter.Position = UDim2.new(0,450,0,269 + graphicsQualityYOffset)
		graphicsSetter.TextColor3 = Color3.new(1,1,1)
		graphicsSetter.Font = Enum.Font.SourceSansBold
		graphicsSetter.FontSize = Enum.FontSize.Size18
		graphicsSetter.Text = "Auto"
		graphicsSetter.ZIndex = 1
		graphicsSetter.TextWrap = true
		graphicsSetter.Parent = gameSettingsMenuFrame
		graphicsSetter.Visible = not inStudioMode

		local isAutoGraphics = true
		if not inStudioMode then
			isAutoGraphics = (UserSettings().GameSettings.SavedQualityLevel == Enum.SavedQualitySetting.Automatic)
		else
			settings().Rendering.EnableFRM = false
		end
		
		local listenToGraphicsLevelChange = true
		
		local function setAutoGraphicsGui(active)
			isAutoGraphics = active
			if active then
				autoGraphicsButton.Text = "X"
				betterQualityText.ZIndex = 1
				fasterText.ZIndex = 1
				graphicsSlider.Bar.ZIndex = 1
				graphicsSlider.BarLeft.ZIndex = 1
				graphicsSlider.BarRight.ZIndex = 1
				graphicsSlider.Bar.Fill.ZIndex = 1
				graphicsSlider.FillLeft.ZIndex = 1
				graphicsSlider.Bar.Slider.ZIndex = 1
				graphicsSetter.ZIndex = 1
				graphicsSetter.Text = "Auto"
			else
				autoGraphicsButton.Text = ""
				graphicsSlider.Bar.ZIndex = baseZIndex + 4
				graphicsSlider.Bar.Slider.ZIndex = baseZIndex + 6
				graphicsSlider.BarLeft.ZIndex = baseZIndex + 4
				graphicsSlider.BarRight.ZIndex = baseZIndex + 4
				graphicsSlider.Bar.Fill.ZIndex = baseZIndex + 5
				graphicsSlider.FillLeft.ZIndex = baseZIndex + 5
				betterQualityText.ZIndex = baseZIndex + 4
				fasterText.ZIndex = baseZIndex + 4
				graphicsSetter.ZIndex = baseZIndex + 4
			end
		end
		
		local function goToAutoGraphics()
			setAutoGraphicsGui(true)
			
			UserSettings().GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.Automatic
			
			settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
		end
				
		local function setGraphicsQualityLevel(newLevel)
			local percentage = newLevel/GraphicsQualityLevels
			local newSetting = math.floor((settings().Rendering:GetMaxQualityLevel() - 1) * percentage)
			if newSetting == 20 then -- Level 20 is the same as level 21, except it doesn't render ambient occlusion
				newSetting = 21
			elseif newLevel == 1 then -- make sure we can go to lowest settings (for terrible computers)
				newSetting = 1
			elseif newSetting > settings().Rendering:GetMaxQualityLevel() then
				newSetting = settings().Rendering:GetMaxQualityLevel() - 1
			end
			
			UserSettings().GameSettings.SavedQualityLevel = newLevel
			settings().Rendering.QualityLevel = newSetting
		end
		
		local function goToManualGraphics(explicitLevel)
			 setAutoGraphicsGui(false)
			
			if explicitLevel then
				graphicsLevel.Value = explicitLevel
			else
				graphicsLevel.Value = math.floor((settings().Rendering.AutoFRMLevel/(settings().Rendering:GetMaxQualityLevel() - 1)) * GraphicsQualityLevels)
			end
			
			if explicitLevel == graphicsLevel.Value then -- make sure we are actually in right graphics mode
				setGraphicsQualityLevel(graphicsLevel.Value)
			end
			
			if not explicitLevel then
				UserSettings().GameSettings.SavedQualityLevel = graphicsLevel.Value
			end
			graphicsSetter.Text = tostring(graphicsLevel.Value)
		end
		
		local function showAutoGraphics()
			autoText.ZIndex = baseZIndex + 4
			autoGraphicsButton.ZIndex = baseZIndex + 4
		end
		
		local function hideAutoGraphics()
			autoText.ZIndex = 1
			autoGraphicsButton.ZIndex = 1
		end
		
		local function showManualGraphics()
			graphicsSlider.Bar.ZIndex = baseZIndex + 4
			graphicsSlider.Bar.Slider.ZIndex = baseZIndex + 5
			betterQualityText.ZIndex = baseZIndex + 4
			fasterText.ZIndex = baseZIndex + 4
			graphicsSetter.ZIndex = baseZIndex + 4
		end
		
		local function hideManualGraphics()
			betterQualityText.ZIndex = 1
			fasterText.ZIndex = 1
			graphicsSlider.Bar.ZIndex = 1
			graphicsSlider.Bar.Slider.ZIndex = 1
			graphicsSetter.ZIndex = 1
		end
		
		local function translateSavedQualityLevelToInt(savedQualityLevel)
			if savedQualityLevel == Enum.SavedQualitySetting.Automatic then
				return 0
			elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel1 then
				return 1
			elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel2 then
				return 2
			elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel3 then
				return 3
			elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel4 then
				return 4
			elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel5 then
				return 5
			elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel6 then
				return 6
			elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel7 then
				return 7
			elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel8 then
				return 8
			elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel9 then
				return 9
			elseif savedQualityLevel == Enum.SavedQualitySetting.QualityLevel10 then
				return 10
			end
		end
		
		local function enableGraphicsWidget()
			settings().Rendering.EnableFRM = true
			
			isAutoGraphics = (UserSettings().GameSettings.SavedQualityLevel == Enum.SavedQualitySetting.Automatic)
			if isAutoGraphics then
				showAutoGraphics()
				goToAutoGraphics()
			else
				showAutoGraphics()
				showManualGraphics()
				goToManualGraphics(translateSavedQualityLevelToInt(UserSettings().GameSettings.SavedQualityLevel))
			end
		end
		
		local function disableGraphicsWidget()
			hideManualGraphics()
			hideAutoGraphics()
			settings().Rendering.EnableFRM = false
		end
		
		graphicsSetter.FocusLost:connect(function()
			if isAutoGraphics then 
				graphicsSetter.Text = tostring(graphicsLevel.Value)
				return
			end
			
			local newGraphicsValue = tonumber(graphicsSetter.Text)
			if newGraphicsValue == nil then
				graphicsSetter.Text = tostring(graphicsLevel.Value)
				return
			end
			
			if newGraphicsValue < 1 then newGraphicsValue = 1
			elseif newGraphicsValue >= settings().Rendering:GetMaxQualityLevel() then
				newGraphicsValue = settings().Rendering:GetMaxQualityLevel() - 1
			end
			
			graphicsLevel.Value = newGraphicsValue
			setGraphicsQualityLevel(graphicsLevel.Value)
			graphicsSetter.Text = tostring(graphicsLevel.Value)
		end)
		
		graphicsLevel.Changed:connect(function(prop)
			if isAutoGraphics then return end
			if not listenToGraphicsLevelChange then return end
			
			graphicsSetter.Text = tostring(graphicsLevel.Value)
			setGraphicsQualityLevel(graphicsLevel.Value)
		end)
		
		-- setup our graphic mode on load
		if inStudioMode or UserSettings().GameSettings.SavedQualityLevel == Enum.SavedQualitySetting.Automatic then
			if inStudioMode then
				settings().Rendering.EnableFRM = false
				disableGraphicsWidget()
			else
				settings().Rendering.EnableFRM = true
				goToAutoGraphics()
			end
		else
			settings().Rendering.EnableFRM = true
			goToManualGraphics(translateSavedQualityLevelToInt(UserSettings().GameSettings.SavedQualityLevel))
		end
		
		autoGraphicsButton.MouseButton1Click:connect(function()
			if inStudioMode and not game:GetService("Players").LocalPlayer then return end
			
			if not isAutoGraphics then
				goToAutoGraphics()
			else
				goToManualGraphics(graphicsLevel.Value)
			end
		end)
		
		local lastUpdate = nil
		game.GraphicsQualityChangeRequest:connect(function(graphicsIncrease)
			if isAutoGraphics then return end -- only can set graphics in manual mode
			
			if graphicsIncrease then
				if (graphicsLevel.Value + 1) > GraphicsQualityLevels then return end
				graphicsLevel.Value = graphicsLevel.Value + 1
				graphicsSetter.Text = tostring(graphicsLevel.Value)
				setGraphicsQualityLevel(graphicsLevel.Value)
			else
				if (graphicsLevel.Value - 1) <= 0 then return end
				graphicsLevel.Value = graphicsLevel.Value - 1
				graphicsSetter.Text = tostring(graphicsLevel.Value)
				setGraphicsQualityLevel(graphicsLevel.Value)
			end
		end)
		
		game:GetService("Players").PlayerAdded:connect(function(player)
			if player == game:GetService("Players").LocalPlayer and inStudioMode then
				enableGraphicsWidget()
			end
		end)
		game:GetService("Players").PlayerRemoving:connect(function(player)
			if player == game:GetService("Players").LocalPlayer and inStudioMode then
				disableGraphicsWidget()
			end
		end)

		local wasManualGraphics = (settings().Rendering.QualityLevel ~= Enum.QualityLevel.Automatic)
		if inStudioMode and not game:GetService("Players").LocalPlayer then
			disableGraphicsWidget()
		elseif inStudioMode then
			enableGraphicsWidget()
		end
		if hasGraphicsSlider then
			 UserSettings().GameSettings.StudioModeChanged:connect(function(isStudioMode)
				inStudioMode = isStudioMode
				if isStudioMode then
					wasManualGraphics = (settings().Rendering.QualityLevel ~= Enum.QualityLevel.Automatic)
					goToAutoGraphics()
					autoGraphicsButton.ZIndex = 1
					autoText.ZIndex = 1
				else
					if wasManualGraphics then
						goToManualGraphics()
					end
					autoGraphicsButton.ZIndex = baseZIndex + 4
					autoText.ZIndex = baseZIndex + 4
				end
			end)
		end

		if graphicsSlider and graphicsSlider.Bar and graphicsSlider.Visible then
			itemTop = graphicsSlider.Bar.Position.Y.Offset + 20
		end
	end
	----------------------------------------------------------------------------------------------------
	-- V O L U M E    S L I D E R
	----------------------------------------------------------------------------------------------------
	local maxVolumeLevel = 256

	local volumeText = Instance.new("TextLabel")
	volumeText.Name = "VolumeText"
	volumeText.Text = "Volume"
	volumeText.Size = UDim2.new(0,224,0,18)

	local volumeTextOffset = 25
	if graphicsSlider and not graphicsSlider.Visible then
		volumeTextOffset = volumeTextOffset + 30
	end
	volumeText.Position = UDim2.new(0,31,0, itemTop + volumeTextOffset)

	volumeText.TextXAlignment = Enum.TextXAlignment.Left
	volumeText.Font = Enum.Font.SourceSansBold
	volumeText.FontSize = Enum.FontSize.Size18
	volumeText.TextColor3 = Color3.new(1,1,1)
	volumeText.ZIndex = baseZIndex + 4
	volumeText.BackgroundTransparency = 1
	volumeText.Parent = gameSettingsMenuFrame
	volumeText.Visible = true

	local volumeSliderOffset = 32
	if graphicsSlider and not graphicsSlider.Visible then
		volumeSliderOffset = volumeSliderOffset + 30
	end
	local volumeSlider, volumeLevel = RbxGui.CreateSliderNew( maxVolumeLevel,256,UDim2.new(0, 180, 0, itemTop + volumeSliderOffset) )
	volumeSlider.Parent = gameSettingsMenuFrame
	volumeSlider.Bar.ZIndex = baseZIndex + 3
	volumeSlider.Bar.Slider.ZIndex = baseZIndex + 4
	volumeSlider.BarLeft.ZIndex = baseZIndex + 3
	volumeSlider.BarRight.ZIndex = baseZIndex + 3
	volumeSlider.Bar.Fill.ZIndex = baseZIndex + 3
	volumeSlider.FillLeft.ZIndex = baseZIndex + 3
	volumeSlider.Visible = true
	volumeLevel.Value = math.min(math.max(UserSettings().GameSettings.MasterVolume * maxVolumeLevel, 1), maxVolumeLevel)

	volumeLevel.Changed:connect(function(prop)
		local volume = volumeLevel.Value - 1 -- smallest value is 1, so need to subtract one for muting
		UserSettings().GameSettings.MasterVolume = volume/maxVolumeLevel
	end)

	itemTop = itemTop + volumeSliderOffset
	

	----------------------------------------------------------------------------------------------------
	--  O K    B U T T O N
	----------------------------------------------------------------------------------------------------


	local backButton
	if hasGraphicsSlider then
		backButton = createTextButton("OK",Enum.ButtonStyle.RobloxRoundDefaultButton,Enum.FontSize.Size24,UDim2.new(0,180,0,50),UDim2.new(0,170,0,315))
		backButton.Modal = true
	else
		backButton = createTextButton("OK",Enum.ButtonStyle.RobloxRoundDefaultButton,Enum.FontSize.Size24,UDim2.new(0,180,0,50),UDim2.new(0,170,0,270))
		backButton.Modal = true
	end
	
	backButton.Name = "BackButton"
	backButton.ZIndex = baseZIndex + 4
	backButton.Parent = gameSettingsMenuFrame
	
	if (newMovementScripts) then
		updateUserSettings()
		game.Players.LocalPlayer.Changed:connect(function(prop) 
			if prop == "DevTouchMovementMode" or prop == "DevComputerMovementMode" or prop == "DevTouchCameraMode" or prop == "DevComputerCameraMode" or
				prop == "DevEnableMouseLock" then
				updateUserSettings()
			end
		end)
	end

	return gameSettingsMenuFrame
end

function updateUserSettings()	
	if not newMovementScripts then return end

	local player = game.Players.LocalPlayer
	if (touchClient) then
		if (player.DevTouchMovementMode.Name == "UserChoice") then
			settingsChoices["MovementModeDevChoice"].Visible = false
			settingsChoices["MovementModeUserChoice"].Visible = true
		else
			settingsChoices["MovementModeDevChoice"].Visible = true
			settingsChoices["MovementModeUserChoice"].Visible = false
		end
		if (player.DevTouchCameraMode.Name == "UserChoice") then
			settingsChoices["CameraModeDevChoice"].Visible = false
			settingsChoices["CameraModeUserChoice"].Visible = true
		else
			settingsChoices["CameraModeDevChoice"].Visible = true
			settingsChoices["CameraModeUserChoice"].Visible = false
		end
	else
		if (player.DevComputerMovementMode.Name == "UserChoice") then
			settingsChoices["MovementModeDevChoice"].Visible = false
			settingsChoices["MovementModeUserChoice"].Visible = true
		else
			settingsChoices["MovementModeDevChoice"].Visible = true
			settingsChoices["MovementModeUserChoice"].Visible = false
		end	
		if (player.DevComputerCameraMode.Name == "UserChoice") then
			settingsChoices["CameraModeDevChoice"].Visible = false
			settingsChoices["CameraModeUserChoice"].Visible = true
		else
			settingsChoices["CameraModeDevChoice"].Visible = true
			settingsChoices["CameraModeUserChoice"].Visible = false
		end
		settingsChoices["MouseLockEnabled"].Visible = player.DevEnableMouseLock
		settingsChoices["MouseLockDisabled"].Visible = not player.DevEnableMouseLock
	end
end

local showMainMenu = nil 

if LoadLibrary then
  RbxGui = LoadLibrary("RbxGui")
  local baseZIndex = 4
if UserSettings then

	waitForChild(gui,"TopLeftControl")
	waitForChild(gui,"BottomLeftControl")
	

	local settingButtonParent = gui:WaitForChild("TopLeftControl") 
	local createSettingsDialog = function()
		if touchClient then
			waitForChild(gui,"TopLeftControl")
		else
			settingButtonParent = gui:WaitForChild("BottomLeftControl")
		end

		settingsButton = settingButtonParent:FindFirstChild("SettingsButton")
		
		if settingsButton == nil then
			settingsButton = Instance.new("ImageButton")
			settingsButton.Name = "SettingsButton"
			settingsButton.Image = "rbxasset://textures/ui/homeButton.png"
			settingsButton.BackgroundTransparency = 1
			settingsButton.Active = false
			settingsButton.Size = UDim2.new(0,36,0,28)
			if (touchClient) then
				settingsButton.Position = UDim2.new(0,2,0,5)
			else
				settingsButton.Position = UDim2.new(0, 15, 1, -42)
			end
			settingsButton.Parent = settingButtonParent
		end

		local shield = Instance.new("TextButton")
		shield.Text = ""
		shield.Name = "UserSettingsShield"
		shield.Active = true
		shield.AutoButtonColor = false
		shield.Visible = false
		shield.Size = UDim2.new(1,0,1,0)
		shield.BackgroundColor3 = Color3I(51,51,51)
		shield.BorderColor3 = Color3I(27,42,53)
		shield.BackgroundTransparency = 0.4
		shield.ZIndex = baseZIndex + 2
		mainShield = shield

		local frame = Instance.new("Frame")
		frame.Name = "Settings"
		frame.Position = UDim2.new(0.5, -262, -0.5, -200)
		frame.Size = UDim2.new(0, 525, 0, 430)
		frame.BackgroundTransparency = 1
		frame.Active = true
		frame.Parent = shield

		local settingsFrame = Instance.new("Frame")
		settingsFrame.Name = "SettingsStyle"
		settingsFrame.Size = UDim2.new(1, 0, 1, 0)
		settingsFrame.Style = Enum.FrameStyle.DropShadow
		settingsFrame.Active = true
		settingsFrame.ZIndex = baseZIndex + 3
		settingsFrame.Parent = frame
		
		local gameMainMenu = createGameMainMenu(baseZIndex, shield)
		gameMainMenu.Parent = settingsFrame
		
		gameMainMenu.ScreenshotButton.MouseButton1Click:connect(function()
			backToGame(gameMainMenu.ScreenshotButton, shield, settingsButton)	
		end)
			
		gameMainMenu.RecordVideoButton.MouseButton1Click:connect(function()
			recordVideoClick(gameMainMenu.RecordVideoButton, gui.StopRecordButton)
			backToGame(gameMainMenu.RecordVideoButton, shield, settingsButton)
		end)
		
		if settings():FindFirstChild("Game Options") then
			pcall(function()
				settings():FindFirstChild("Game Options").VideoRecordingChangeRequest:connect(function(recording)
					recordingVideo = recording
					setRecordGui(recording, gui.StopRecordButton, gameMainMenu.RecordVideoButton)
				end)
			end)
		end
		
		game:GetService("CoreGui").RobloxGui.Changed:connect(function(prop) -- We have stopped recording when we resize
			if prop == "AbsoluteSize" and recordingVideo then
				recordVideoClick(gameMainMenu.RecordVideoButton, gui.StopRecordButton)
			end
		end)
		
		function localPlayerChange()
			gameMainMenu.ResetButton.Visible = game:GetService("Players").LocalPlayer
			if game:GetService("Players").LocalPlayer then
				settings().Rendering.EnableFRM = true
			elseif inStudioMode then
				settings().Rendering.EnableFRM = false
			end
		end
		
		gameMainMenu.ResetButton.Visible = game:GetService("Players").LocalPlayer
		if game:GetService("Players").LocalPlayer ~= nil then
			game:GetService("Players").LocalPlayer.Changed:connect(function()
				localPlayerChange()
			end)
		else
			delay(0,function()
				waitForProperty(game:GetService("Players"),"LocalPlayer")
				gameMainMenu.ResetButton.Visible = game:GetService("Players").LocalPlayer
				game:GetService("Players").LocalPlayer.Changed:connect(function()
					localPlayerChange()
				end)
			end)
		end
		
		gameMainMenu.ReportAbuseButton.Visible = game:FindService("NetworkClient")
		-- TODO: remove line below when not testing report abuse
		if (testReport) then
			gameMainMenu.ReportAbuseButton.Visible = true
		end
		if not gameMainMenu.ReportAbuseButton.Visible then
			game.ChildAdded:connect(function(child)
				if child:IsA("NetworkClient") then
					gameMainMenu.ReportAbuseButton.Visible = game:FindService("NetworkClient")
				end
			end)
		end
		
		gameMainMenu.ResetButton.MouseButton1Click:connect(function()
			goToMenu(settingsFrame,"ResetConfirmationMenu","up",UDim2.new(0,525,0,370))
		end)
		
		local leaveGameButton = gameMainMenu:FindFirstChild("LeaveGameButton")
		if (leaveGameButton) then
			gameMainMenu.LeaveGameButton.MouseButton1Click:connect(function()
				goToMenu(settingsFrame,"LeaveConfirmationMenu","down",UDim2.new(0,525,0,300))
			end)
		end

		showMainMenu = function(overrideMenu, overrideDir, overrideSize)
			if shield.Visible and overrideMenu then
				goToMenu(settingsFrame,overrideMenu,overrideDir,overrideSize)
				return
			end

			game:GetService("GuiService"):AddCenterDialog(shield, Enum.CenterDialogType.ModalDialog,
				--showFunction
				function()
					settingsButton.Active = false
					if updateCameraDropDownSelection ~= nil then
						updateCameraDropDownSelection(UserSettings().GameSettings.ControlMode.Name)
					end

					local cameraMode = "None"
					if (not newMovementScripts) then
						cameraMode = UserSettings().GameSettings.CameraMode.Name
					elseif (touchClient) then
						cameraMode = UserSettings().GameSettings.TouchCameraMovementMode.Name
					else
						cameraMode = UserSettings().GameSettings.ComputerCameraMovementMode.Name
					end

					if (cameraMode == "Default") then
						cameraMode = customCameraDefaultType
					end

					updateSmartCameraDropDownSelection(cameraMode)

					if updateMovementDropDownSelection ~= nil then
						local moveMode = "None"
						if (touchClient) then
							moveMode = UserSettings().GameSettings.TouchMovementMode.Name
							if (moveMode == "Default") then
								moveMode = "Default (Thumbstick)"
							end
						else 
							moveMode = UserSettings().GameSettings.ComputerMovementMode.Name
							if (moveMode == "Default") then
								moveMode = "Default (Keyboard)"
							end
						end
						updateMovementDropDownSelection(moveMode)
					end

					pcall(function() game:GetService("UserInputService").OverrideMouseIconEnabled = true end)
					if syncVideoCaptureSetting then
							syncVideoCaptureSetting()
					end

					local menuToGoTo = "GameMainMenu"
					local direction = "right"
					local menuSize = UDim2.new(0,525,0,430)

					if overrideMenu then
						menuToGoTo = overrideMenu
					end
					if overrideDir then
						direction = overrideDir
					end
					if overrideSize then
						menuSize = overrideSize
					end

					goToMenu(settingsFrame,menuToGoTo,direction,menuSize)
					shield.Visible = true
					shield.Active = true
					settingsFrame.Parent:TweenPosition(UDim2.new(0.5, -262,0.5, -200),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
					settingsFrame.Parent:TweenSize(UDim2.new(0,525,0,430),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
				end,
				--hideFunction
				function()
					settingsFrame.Parent:TweenPosition(UDim2.new(0.5, -262,-0.5, -200),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
					settingsFrame.Parent:TweenSize(UDim2.new(0,525,0,430),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
					shield.Visible = false
					settingsButton.Active = true
				end)
		end
		
		game:GetService("GuiService").EscapeKeyPressed:connect(function()
			if currentMenuSelection == nil then
				showMainMenu()
			elseif #lastMenuSelection > 0 then
				if #centerDialogs > 0 then
					for i = 1, #centerDialogs do
						game:GetService("GuiService"):RemoveCenterDialog(centerDialogs[i])
						centerDialogs[i].Visible = false
					end
					centerDialogs = {}
				end
				
				goToMenu(lastMenuSelection[#lastMenuSelection]["container"],lastMenuSelection[#lastMenuSelection]["name"],
					lastMenuSelection[#lastMenuSelection]["direction"],lastMenuSelection[#lastMenuSelection]["lastSize"])
					
				table.remove(lastMenuSelection,#lastMenuSelection)
				if #lastMenuSelection == 1 then -- apparently lua can't reduce count to 0... T_T
					lastMenuSelection = {}
				end
			else
				resumeGameFunction(shield)
			end
		end)
			
		local gameSettingsMenu = createGameSettingsMenu(baseZIndex, shield)
		gameSettingsMenu.Visible = false
		gameSettingsMenu.Parent = settingsFrame
		
		gameMainMenu.SettingsButton.MouseButton1Click:connect(function() 
			goToMenu(settingsFrame,"GameSettingsMenu","left",UDim2.new(0,525,0,350))
		end)

		gameSettingsMenu.BackButton.MouseButton1Click:connect(function()
			goToMenu(settingsFrame,"GameMainMenu","right",UDim2.new(0,525,0,430))
		end)
		
		local resetConfirmationWindow = createResetConfirmationMenu(baseZIndex, shield)
		resetConfirmationWindow.Visible = false
		resetConfirmationWindow.Parent = settingsFrame
		
		local leaveConfirmationWindow = createLeaveConfirmationMenu(baseZIndex,shield)
		leaveConfirmationWindow.Visible = false
		leaveConfirmationWindow.Parent = settingsFrame

		robloxLock(shield)
		
		settingsButton.MouseButton1Click:connect(
			function()
				game:GetService("GuiService"):AddCenterDialog(shield, Enum.CenterDialogType.ModalDialog,
					--showFunction
					function()
						settingsButton.Active = false
						if updateCameraDropDownSelection ~= nil then
							updateCameraDropDownSelection(UserSettings().GameSettings.ControlMode.Name)
						end
	
						local cameraMode = "None"
						if (not newMovementScripts) then
							cameraMode = UserSettings().GameSettings.CameraMode.Name
						elseif (touchClient) then
							cameraMode = UserSettings().GameSettings.TouchCameraMovementMode.Name
						else
							cameraMode = UserSettings().GameSettings.ComputerCameraMovementMode.Name
						end
						if (cameraMode == "Default") then
							cameraMode = customCameraDefaultType
						end
						updateSmartCameraDropDownSelection(cameraMode)
	
						if updateMovementDropDownSelection ~= nil then
							local moveMode = "None"
							if (touchClient) then
								moveMode = UserSettings().GameSettings.TouchMovementMode.Name
								if (moveMode == "Default") then
									moveMode = "Default (Thumbstick)"
								end
							else 
								moveMode = UserSettings().GameSettings.ComputerMovementMode.Name
								if (moveMode == "Default") then
									moveMode = "Default (Keyboard)"
								end
							end
							updateMovementDropDownSelection(moveMode)
						end
						
						if syncVideoCaptureSetting then
  							syncVideoCaptureSetting()
						end

						goToMenu(settingsFrame,"GameMainMenu","right",UDim2.new(0,525,0,430))
						shield.Visible = true
						settingsFrame.Parent:TweenPosition(UDim2.new(0.5, -262,0.5, -200),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
						settingsFrame.Parent:TweenSize(UDim2.new(0,525,0,430),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
					end,
					--hideFunction
					function()
						settingsFrame.Parent:TweenPosition(UDim2.new(0.5, -262,-0.5, -200),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
						settingsFrame.Parent:TweenSize(UDim2.new(0,525,0,430),Enum.EasingDirection.InOut,Enum.EasingStyle.Sine,tweenTime,true)
						shield.Visible = false
						settingsButton.Active = true
					end)
			end)
			
		return shield
	end

	delay(0, function()
		createSettingsDialog().Parent = gui
		
		settingButtonParent.SettingsButton.Active = true
--		settingButtonParent.SettingsButton.Position = UDim2.new(0,2,0,-2)

		if mouseLockLabel and UserSettings().GameSettings.ControlMode == Enum.ControlMode["Mouse Lock Switch"] then
			mouseLockLabel.Visible = true
		elseif mouseLockLabel then
			mouseLockLabel.Visible = false
		end
		
		-- our script has loaded, get rid of older buttons now
		local leaveGameButton = gui.BottomLeftControl:FindFirstChild("Exit")
		if leaveGameButton then leaveGameButton:Remove() end
		
		local topLeft = gui:FindFirstChild("TopLeftControl")
		if topLeft then 
			leaveGameButton = topLeft:FindFirstChild("Exit")
			if leaveGameButton then leaveGameButton:Remove() end

			if settingButtonParent ~= topLeft then
				topLeft:Remove()
			end
		end
		--]]
	end)
	
end --UserSettings call

local createSaveDialogs = function()
	local shield = Instance.new("TextButton")
	shield.Text = ""
	shield.AutoButtonColor = false
	shield.Name = "SaveDialogShield"
	shield.Active = true
	shield.Visible = false
	shield.Size = UDim2.new(1,0,1,0)
	shield.BackgroundColor3 = Color3I(51,51,51)
	shield.BorderColor3 = Color3I(27,42,53)
	shield.BackgroundTransparency = 0.4
	shield.ZIndex = baseZIndex+1

	local clearAndResetDialog
	local save
	local saveLocal
	local dontSave
	local cancel

	local messageBoxButtons = {}
	messageBoxButtons[1] = {}
	messageBoxButtons[1].Text = "Save"
	messageBoxButtons[1].Style = Enum.ButtonStyle.RobloxRoundDefaultButton
	messageBoxButtons[1].Function = function() save() end 
	messageBoxButtons[1].ZIndex =  baseZIndex+3
	messageBoxButtons[2] = {}
	messageBoxButtons[2].Text = "Cancel"
	messageBoxButtons[2].Function = function() cancel() end 
	messageBoxButtons[2].Style = Enum.ButtonStyle.RobloxRoundButton
	messageBoxButtons[2].ZIndex =  baseZIndex+3
	messageBoxButtons[3] = {}
	messageBoxButtons[3].Text = "Don't Save"
	messageBoxButtons[3].Function = function() dontSave() end 
	messageBoxButtons[3].Style = Enum.ButtonStyle.RobloxRoundButton
	messageBoxButtons[3].ZIndex =  baseZIndex+3

	local saveDialogMessageBox = RbxGui.CreateStyledMessageDialog("Unsaved Changes", "Save your changes to ROBLOX before leaving?", "Confirm", messageBoxButtons)
	saveDialogMessageBox.Visible = true
	saveDialogMessageBox.Parent = shield
	saveDialogMessageBox.ZIndex = baseZIndex+2
	saveDialogMessageBox.Style = Enum.FrameStyle.DropShadow
	saveDialogMessageBox.Title.ZIndex = baseZIndex+3
	saveDialogMessageBox.Message.ZIndex = baseZIndex+3
	saveDialogMessageBox.StyleImage.ZIndex = baseZIndex+3


	local errorBoxButtons = {}

	local buttonOffset = 1
	if game.LocalSaveEnabled then
		errorBoxButtons[buttonOffset] = {}
		errorBoxButtons[buttonOffset].Text = "Save to Disk"
		errorBoxButtons[buttonOffset].Function = function() saveLocal() end 
		buttonOffset = buttonOffset + 1
	end
	errorBoxButtons[buttonOffset] = {}
	errorBoxButtons[buttonOffset].Text = "Keep Playing"
	errorBoxButtons[buttonOffset].Function = function() cancel() end 
	errorBoxButtons[buttonOffset].Style = Enum.ButtonStyle.RobloxRoundButton
	errorBoxButtons[buttonOffset].ZIndex =  baseZIndex+3
	errorBoxButtons[buttonOffset+1] = {}
	errorBoxButtons[buttonOffset+1].Text = "Don't Save"
	errorBoxButtons[buttonOffset+1].Function = function() dontSave() end 
	errorBoxButtons[buttonOffset+1].Style = Enum.ButtonStyle.RobloxRoundButton
	errorBoxButtons[buttonOffset+1].ZIndex =  baseZIndex+3

	local errorDialogMessageBox = RbxGui.CreateStyledMessageDialog("Upload Failed", "Sorry, we could not save your changes to ROBLOX. If this problem continues to occur, please make sure your Roblox account has a verified email address.", "Error", errorBoxButtons)
	errorDialogMessageBox.Visible = false
	errorDialogMessageBox.Parent = shield
	errorDialogMessageBox.ZIndex = baseZIndex+2
	errorDialogMessageBox.Style = Enum.FrameStyle.DropShadow
	errorDialogMessageBox.Title.ZIndex = baseZIndex+3
	errorDialogMessageBox.Message.ZIndex = baseZIndex+3
	errorDialogMessageBox.StyleImage.ZIndex = baseZIndex+3

	local spinnerDialog = Instance.new("Frame")
	spinnerDialog.Name = "SpinnerDialog"
	spinnerDialog.Style = Enum.FrameStyle.DropShadow
	spinnerDialog.Size = UDim2.new(0, 350, 0, 150)
	spinnerDialog.Position = UDim2.new(.5, -175, .5, -75)
	spinnerDialog.Visible = false
	spinnerDialog.Active = true
	spinnerDialog.ZIndex = baseZIndex+1
	spinnerDialog.Parent = shield

	local waitingLabel = Instance.new("TextLabel")
	waitingLabel.Name = "WaitingLabel"
	waitingLabel.Text = "Saving to ROBLOX..."
	waitingLabel.Font = Enum.Font.SourceSansBold
	waitingLabel.FontSize = Enum.FontSize.Size18
	waitingLabel.Position = UDim2.new(0.5, 25, 0.5, 0)
	waitingLabel.TextColor3 = Color3.new(1,1,1)
	waitingLabel.ZIndex = baseZIndex+2
	waitingLabel.Parent = spinnerDialog

	local spinnerFrame = Instance.new("Frame")
	spinnerFrame.Name = "Spinner"
	spinnerFrame.Size = UDim2.new(0, 80, 0, 80)
	spinnerFrame.Position = UDim2.new(0.5, -150, 0.5, -40)
	spinnerFrame.BackgroundTransparency = 1
	spinnerFrame.ZIndex = baseZIndex+2
	spinnerFrame.Parent = spinnerDialog

	local spinnerIcons = {}
	local spinnerNum = 1
	while spinnerNum <= 8 do
		local spinnerImage = Instance.new("ImageLabel")
	    spinnerImage.Name = "Spinner"..spinnerNum
		spinnerImage.Size = UDim2.new(0, 16, 0, 16)
		spinnerImage.Position = UDim2.new(.5+.3*math.cos(math.rad(45*spinnerNum)), -8, .5+.3*math.sin(math.rad(45*spinnerNum)), -8)
		spinnerImage.BackgroundTransparency = 1
	    spinnerImage.Image = "http://www.roblox.com/Asset?id=45880710"
		spinnerImage.ZIndex = baseZIndex+3
		spinnerImage.Parent = spinnerFrame

	   spinnerIcons[spinnerNum] = spinnerImage
	   spinnerNum = spinnerNum + 1
	end

	save = function()
		saveDialogMessageBox.Visible = false
		
		--Show the spinner dialog
		spinnerDialog.Visible = true
		local spin = true
		--Make it spin
		delay(0, function()
		  local spinPos = 0
			while spin do
				local pos = 0

				while pos < 8 do
					if pos == spinPos or pos == ((spinPos+1)%8) then
						spinnerIcons[pos+1].Image = "http://www.roblox.com/Asset?id=45880668"
					else
						spinnerIcons[pos+1].Image = "http://www.roblox.com/Asset?id=45880710"
					end
					
					pos = pos + 1
				end
				spinPos = (spinPos + 1) % 8
				wait(0.2)
			end
		end)

		--Do the save while the spinner is going, function will wait
		local result = game:SaveToRoblox()
		if not result then
			--Try once more
			result = game:SaveToRoblox()
		end

		--Hide the spinner dialog
		spinnerDialog.Visible = false
		--And cause the delay thread to stop
		spin = false	

		--Now process the result
		if result then
			--Success, close
			game:FinishShutdown(false)
			clearAndResetDialog()
		else
			--Failure, show the second dialog prompt
			errorDialogMessageBox.Visible = true
		end
	end

	saveLocal = function()
		errorDialogMessageBox.Visible = false
		game:FinishShutdown(true)
		clearAndResetDialog()
	end

	dontSave = function()
		saveDialogMessageBox.Visible = false
		errorDialogMessageBox.Visible = false
		game:FinishShutdown(false)
		clearAndResetDialog()
	end
	cancel = function()
		saveDialogMessageBox.Visible = false
		errorDialogMessageBox.Visible = false
		clearAndResetDialog()
	end

	clearAndResetDialog = function()
		saveDialogMessageBox.Visible = true
		errorDialogMessageBox.Visible = false
		spinnerDialog.Visible = false
		shield.Visible = false
		game:GetService("GuiService"):RemoveCenterDialog(shield)
	end

	robloxLock(shield)
	shield.Visible = false
	return shield
end

local createReportAbuseDialog = function()
	--Only show things if we are a NetworkClient
	-- TODO: add line back in when not testing report abuse
	if not testReport then
		waitForChild(game,"NetworkClient")
	end

	waitForChild(game,"Players")
	waitForProperty(game:GetService("Players"), "LocalPlayer")
	local localPlayer = game:GetService("Players").LocalPlayer
	
	local reportAbuseButton
	waitForChild(gui,"UserSettingsShield")
	waitForChild(gui.UserSettingsShield, "Settings")
	waitForChild(gui.UserSettingsShield.Settings,"SettingsStyle")
	waitForChild(gui.UserSettingsShield.Settings.SettingsStyle,"GameMainMenu")
	waitForChild(gui.UserSettingsShield.Settings.SettingsStyle.GameMainMenu, "ReportAbuseButton")
	reportAbuseButton = gui.UserSettingsShield.Settings.SettingsStyle.GameMainMenu.ReportAbuseButton

	local shield = Instance.new("TextButton")
	shield.Name = "ReportAbuseShield"
	shield.Text = ""
	shield.AutoButtonColor = false
	shield.Active = true
	shield.Visible = false
	shield.Size = UDim2.new(1,0,1,0)
	shield.BackgroundColor3 = Color3I(51,51,51)
	shield.BorderColor3 = Color3I(27,42,53)
	shield.BackgroundTransparency = 0.4
	shield.ZIndex = baseZIndex + 1

	local closeAndResetDialgo

	local messageBoxButtons = {}
	messageBoxButtons[1] = {}
	messageBoxButtons[1].Text = "Ok"
	messageBoxButtons[1].Modal = true
	messageBoxButtons[1].Style = Enum.ButtonStyle.RobloxRoundDefaultButton
	messageBoxButtons[1].ZIndex = baseZIndex+3
	messageBoxButtons[1].Function = function() closeAndResetDialog() end 
	local calmingMessageBox = RbxGui.CreateMessageDialog("Thanks for your report!", "Our moderators will review the chat logs and determine what happened.  The other user is probably just trying to make you mad.\n\nIf anyone used swear words, inappropriate language, or threatened you in real life, please report them for Bad Words or Threats", messageBoxButtons)
	calmingMessageBox.Visible = false
	calmingMessageBox.Parent = shield
	calmingMessageBox.ZIndex = baseZIndex+2
	calmingMessageBox.Style = Enum.FrameStyle.DropShadow
	calmingMessageBox.Title.ZIndex = baseZIndex+3
	calmingMessageBox.Message.ZIndex = baseZIndex+3

	local recordedMessageBox = RbxGui.CreateMessageDialog("Thanks for your report!","We've recorded your report for evaluation.", messageBoxButtons)
	recordedMessageBox.Visible = false
	recordedMessageBox.Parent = shield
	recordedMessageBox.ZIndex = baseZIndex+2
	recordedMessageBox.Style = Enum.FrameStyle.DropShadow
	recordedMessageBox.Title.ZIndex = baseZIndex+3
	recordedMessageBox.Message.ZIndex = baseZIndex+3

	local normalMessageBox = RbxGui.CreateMessageDialog("Thanks for your report!", "Our moderators will review the chat logs and determine what happened.", messageBoxButtons)
	normalMessageBox.Visible = false
	normalMessageBox.Parent = shield
	normalMessageBox.ZIndex = baseZIndex+2
	normalMessageBox.Style = Enum.FrameStyle.DropShadow
	normalMessageBox.Title.ZIndex = baseZIndex+3
	normalMessageBox.Message.ZIndex = baseZIndex+3

	local frame = Instance.new("Frame")
	frame.Name = "Settings"
	frame.Position = UDim2.new(0.5, -240, 0.5, -160)
	frame.Size = UDim2.new(0.0, 480, 0.0, 320)
	frame.BackgroundTransparency = 1
	frame.Active = true
	frame.Parent = shield

	local settingsFrame = Instance.new("Frame")
	settingsFrame.Name = "ReportAbuseStyle"
	settingsFrame.Size = UDim2.new(1, 0, 1, 0)
	settingsFrame.Style = Enum.FrameStyle.DropShadow
	settingsFrame.Active = true
	settingsFrame.ZIndex = baseZIndex + 1
	settingsFrame.Parent = frame

	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Text = "This will send a complete report to a moderator.  The moderator will review the chat log and take appropriate action."
	description.TextColor3 = Color3I(221,221,221)
	description.Position = UDim2.new(0, 10, 0, 10)
	description.Size = UDim2.new(1, -20, 0, 40)
	description.BackgroundTransparency = 1
	description.Font = Enum.Font.SourceSans
	description.FontSize = Enum.FontSize.Size18
	description.TextWrap = true
	description.ZIndex = baseZIndex + 2
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.Parent = settingsFrame

	local playerLabel = Instance.new("TextLabel")
	playerLabel.Name = "PlayerLabel"
	playerLabel.Text = "Which player?"
	playerLabel.BackgroundTransparency = 1
	playerLabel.Font = Enum.Font.SourceSans
	playerLabel.FontSize = Enum.FontSize.Size18
	playerLabel.Position = UDim2.new(0.025,20,0,92)
	playerLabel.Size 	   = UDim2.new(0.4,0,0,36)
	playerLabel.TextColor3 = Color3I(255,255,255)
	playerLabel.TextXAlignment = Enum.TextXAlignment.Left
	playerLabel.ZIndex = baseZIndex + 2
	playerLabel.Parent = settingsFrame

	local gameOrPlayerLabel = Instance.new("TextLabel")
	gameOrPlayerLabel.Name = "TypeLabel"
	gameOrPlayerLabel.Text = "Game or Player:"
	gameOrPlayerLabel.BackgroundTransparency = 1
	gameOrPlayerLabel.Font = Enum.Font.SourceSans
	gameOrPlayerLabel.FontSize = Enum.FontSize.Size18
	gameOrPlayerLabel.Position = UDim2.new(0.025,20,0,55)
	gameOrPlayerLabel.Size 	   = UDim2.new(0.4,0,0,36)
	gameOrPlayerLabel.TextColor3 = Color3I(255,255,255)
	gameOrPlayerLabel.TextXAlignment = Enum.TextXAlignment.Left
	gameOrPlayerLabel.ZIndex = baseZIndex + 2
	gameOrPlayerLabel.Parent = settingsFrame

	local abuseLabel = Instance.new("TextLabel")
	abuseLabel.Name = "AbuseLabel"
	abuseLabel.Text = "Type of Abuse:"
	abuseLabel.Font = Enum.Font.SourceSans
	abuseLabel.BackgroundTransparency = 1
	abuseLabel.FontSize = Enum.FontSize.Size18
	abuseLabel.Position = UDim2.new(0.025,20,0,131)
	abuseLabel.Size = UDim2.new(0.4,0,0,36)
	abuseLabel.TextColor3 = Color3I(255,255,255)
	abuseLabel.TextXAlignment = Enum.TextXAlignment.Left
	abuseLabel.ZIndex = baseZIndex + 2
	abuseLabel.Parent = settingsFrame

	local abusingPlayer = nil
	local abuse = nil
	local submitReportButton = nil
	local gameOrPlayer = nil

	local updatePlayerSelection = nil
	local createPlayersDropDown = function()
		local players = game:GetService("Players")
		local playerNames = {}
		local nameToPlayer = {}
		local children = players:GetChildren()
		local pos = 1
		if children then
		   for i, player in ipairs(children) do
				if player:IsA("Player") and player ~= localPlayer then
					playerNames[pos] = player.Name
					nameToPlayer[player.Name] = player
					pos = pos + 1
				end
			end
		end
		local playerDropDown = nil
		playerDropDown, updatePlayerSelection = RbxGui.CreateDropDownMenu(playerNames, 
			function(playerName) 
				abusingPlayer = nameToPlayer[playerName] 
				if abuse and abusingPlayer then
					submitReportButton.Active = true
				end
			end, false, true, baseZIndex)
		playerDropDown.Name = "PlayersComboBox"
		playerDropDown.ZIndex = baseZIndex + 2
		playerDropDown.Position = UDim2.new(.425, 0, 0, 94)
		playerDropDown.Size = UDim2.new(.55,0,0,32)
		
		return playerDropDown
	end

	local gameOrPlayerTable = {"Game","Player"}
	local gameOrPlayerDropDown = nil
	gameOrPlayerDropDown = RbxGui.CreateDropDownMenu(gameOrPlayerTable, 
		function(gameOrPlayerText) 
			gameOrPlayer = gameOrPlayerText
			if gameOrPlayer == "Game" then
				submitReportButton.Active = true
				playerLabel.Visible = false
				local playerDropDown = gameOrPlayerDropDown.Parent:FindFirstChild("PlayersComboBox")
				if playerDropDown then
					playerDropDown.Visible = false
				end
			else
				playerLabel.Visible = true
				local playerDropDown = gameOrPlayerDropDown.Parent:FindFirstChild("PlayersComboBox")
				if playerDropDown then
					playerDropDown.Visible = true
				end
			end
		end, true, true, baseZIndex)
	gameOrPlayerDropDown.Name = "TypeComboBox"
	gameOrPlayerDropDown.ZIndex = baseZIndex + 2
	gameOrPlayerDropDown.Position = UDim2.new(0.425, 0, 0, 55)
	gameOrPlayerDropDown.Size = UDim2.new(0.55,0,0,32)
	gameOrPlayerDropDown.Parent = settingsFrame

	local abuses = {"Swearing","Bullying","Scamming","Dating","Cheating/Exploiting","Personal Questions","Offsite Links","Bad Model or Script","Bad Username"}
	local abuseDropDown, updateAbuseSelection = RbxGui.CreateDropDownMenu(abuses, 
		function(abuseText) 
			abuse = abuseText 
			if abuse and abusingPlayer then
				submitReportButton.Active = true
			end
		end, true, true, baseZIndex)
	abuseDropDown.Name = "AbuseComboBox"
	abuseDropDown.ZIndex = baseZIndex + 2
	abuseDropDown.Position = UDim2.new(0.425, 0, 0, 133)
	abuseDropDown.Size = UDim2.new(0.55,0,0,32)
	abuseDropDown.Parent = settingsFrame

	local shortDescriptionLabel = Instance.new("TextLabel")
	shortDescriptionLabel.Name = "ShortDescriptionLabel"
	shortDescriptionLabel.Text = "Short Description: (optional)"
	shortDescriptionLabel.Font = Enum.Font.SourceSans
	shortDescriptionLabel.FontSize = Enum.FontSize.Size18
	shortDescriptionLabel.Position = UDim2.new(0.025,0,0,165)
	shortDescriptionLabel.Size = UDim2.new(0.95,0,0,36)
	shortDescriptionLabel.TextColor3 = Color3I(255,255,255)
	shortDescriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
	shortDescriptionLabel.BackgroundTransparency = 1
	shortDescriptionLabel.ZIndex = baseZIndex + 2
	shortDescriptionLabel.Parent = settingsFrame

	local shortDescriptionWrapper = Instance.new("Frame")
	shortDescriptionWrapper.Name = "ShortDescriptionWrapper"
	shortDescriptionWrapper.Position = UDim2.new(0.025,0,0,195)
	shortDescriptionWrapper.Size = UDim2.new(0.95,0,1,-250)
	shortDescriptionWrapper.BackgroundColor3 = Color3I(206,206,206)
	shortDescriptionWrapper.BorderSizePixel = 0
	shortDescriptionWrapper.ZIndex = baseZIndex + 2
	shortDescriptionWrapper.Parent = settingsFrame

	local shortDescriptionBox = Instance.new("TextBox")
	shortDescriptionBox.Name = "TextBox"
	shortDescriptionBox.Text = ""
	shortDescriptionBox.ClearTextOnFocus = false
	shortDescriptionBox.Font = Enum.Font.SourceSans
	shortDescriptionBox.FontSize = Enum.FontSize.Size18
	shortDescriptionBox.Position = UDim2.new(0,3,0,3)
	shortDescriptionBox.Size = UDim2.new(1,-6,1,-6)
	shortDescriptionBox.TextColor3 = Color3I(0,0,0)
	shortDescriptionBox.TextXAlignment = Enum.TextXAlignment.Left
	shortDescriptionBox.TextYAlignment = Enum.TextYAlignment.Top
	shortDescriptionBox.TextWrap = true
	shortDescriptionBox.BackgroundColor3 = Color3I(206,206,206)
	shortDescriptionBox.BorderColor3 = Color3I(206,206,206)
	shortDescriptionBox.ZIndex = baseZIndex + 2
	shortDescriptionBox.Parent = shortDescriptionWrapper

	submitReportButton = Instance.new("TextButton")
	submitReportButton.Name = "SubmitReportBtn"
	submitReportButton.Active = false
	submitReportButton.Modal = true
	submitReportButton.Font = Enum.Font.SourceSans
	submitReportButton.FontSize = Enum.FontSize.Size18
	submitReportButton.Position = UDim2.new(0.1, 0, 1, -50)
	submitReportButton.Size = UDim2.new(0.35,0,0,40)
	submitReportButton.AutoButtonColor = true
	submitReportButton.Style = Enum.ButtonStyle.RobloxRoundDefaultButton 
	submitReportButton.Text = "Submit Report"
	submitReportButton.TextColor3 = Color3I(255,255,255)
	submitReportButton.ZIndex = baseZIndex + 2
	submitReportButton.Parent = settingsFrame

	submitReportButton.MouseButton1Click:connect(function()
		if submitReportButton.Active then
			if abuse and abusingPlayer then
				frame.Visible = false
				if gameOrPlayer == "Player" then
					game:GetService("Players"):ReportAbuse(abusingPlayer, abuse, shortDescriptionBox.Text)
				else
					game:GetService("Players"):ReportAbuse(nil, abuse, shortDescriptionBox.Text)
				end
				if abuse == "Cheating/Exploiting" then
					recordedMessageBox.Visible = true
				elseif abuse == "Bullying" or abuse == "Swearing" then
					calmingMessageBox.Visible = true
				else
					normalMessageBox.Visible = true
				end
			else
				closeAndResetDialog()
			end
		end
	end)

	local cancelButton = Instance.new("TextButton")
	cancelButton.Name = "CancelBtn"
	cancelButton.Font = Enum.Font.SourceSans
	cancelButton.FontSize = Enum.FontSize.Size18
	cancelButton.Position = UDim2.new(0.55, 0, 1, -50)
	cancelButton.Size = UDim2.new(0.35,0,0,40)
	cancelButton.AutoButtonColor = true
	cancelButton.Style = Enum.ButtonStyle.RobloxRoundDefaultButton 
	cancelButton.Text = "Cancel"
	cancelButton.TextColor3 = Color3I(255,255,255)
	cancelButton.ZIndex = baseZIndex + 2
	cancelButton.Parent = settingsFrame

	closeAndResetDialog = function()
		--Delete old player combo box
		local oldComboBox = settingsFrame:FindFirstChild("PlayersComboBox")
		if oldComboBox then
			oldComboBox.Parent = nil
		end
		
		abusingPlayer = nil updatePlayerSelection(nil)
		abuse = nil updateAbuseSelection(nil)
		submitReportButton.Active = false
		shortDescriptionBox.Text = ""
		frame.Visible = true
		calmingMessageBox.Visible = false
		recordedMessageBox.Visible = false
		normalMessageBox.Visible = false
		shield.Visible = false		
		reportAbuseButton.Active = true
		game:GetService("GuiService"):RemoveCenterDialog(shield)
	end

	cancelButton.MouseButton1Click:connect(closeAndResetDialog)
	
	reportAbuseButton.MouseButton1Click:connect(
		function() 
			createPlayersDropDown().Parent = settingsFrame
			table.insert(centerDialogs,shield)
			game:GetService("GuiService"):AddCenterDialog(shield, Enum.CenterDialogType.ModalDialog, 
				--ShowFunction
				function()
					reportAbuseButton.Active = false
					shield.Visible = true
					mainShield.Visible = false
				end,
				--HideFunction
				function()
					reportAbuseButton.Active = true
					shield.Visible = false
				end)
		end)

	robloxLock(shield)
	return shield
end

local createChatBar = function()
	--Only show a chat bar if we are a NetworkClient
	waitForChild(game, "NetworkClient")

	waitForChild(game, "Players")
	waitForProperty(game:GetService("Players"), "LocalPlayer")
	
	local chatBar = Instance.new("Frame")
	chatBar.Name = "ChatBar"
	chatBar.Size = UDim2.new(1, 0, 0, 22)
	chatBar.Position = UDim2.new(0, 0, 1, 0)
	chatBar.BackgroundColor3 = Color3.new(0,0,0)
	chatBar.BorderSizePixel = 0

	local chatBox = Instance.new("TextBox")
	chatBox.Text = ""
	chatBox.Visible = false
	chatBox.Size = UDim2.new(1,-4,1,0)
	chatBox.Position = UDim2.new(0,2,0,0)
	chatBox.TextXAlignment = Enum.TextXAlignment.Left
	chatBox.Font = Enum.Font.SourceSansBold
	chatBox.ClearTextOnFocus = false
	chatBox.FontSize = Enum.FontSize.Size14
	chatBox.TextColor3 = Color3.new(1,1,1)
	chatBox.BackgroundTransparency = 1
	--chatBox.Parent = chatBar

	local chatButton = Instance.new("TextButton")
	chatButton.Size = UDim2.new(1,-4,1,0)
	chatButton.Position = UDim2.new(0,2,0,0)
	chatButton.AutoButtonColor = false
	chatButton.Text = "To chat click here or press \"/\" key"
	chatButton.TextXAlignment = Enum.TextXAlignment.Left
	chatButton.Font = Enum.Font.SourceSansBold
	chatButton.FontSize = Enum.FontSize.Size14
	chatButton.TextColor3 = Color3.new(1,1,1)
	chatButton.BackgroundTransparency = 1
	--chatButton.Parent = chatBar

	local activateChat = function()
		if chatBox.Visible then
			return
		end
		chatButton.Visible = false
		chatBox.Text = ""
		chatBox.Visible = true
		chatBox:CaptureFocus()
	end

	chatButton.MouseButton1Click:connect(activateChat)

	local hotKeyEnabled = true
	local toggleHotKey = function(value)
		hotKeyEnabled = value
	end
	
	local guiService = game:GetService("GuiService")
	local newChatMode = pcall(function()
		--guiService:AddSpecialKey(Enum.SpecialKey.ChatHotkey)
		--guiService.SpecialKeyPressed:connect(function(key) if key == Enum.SpecialKey.ChatHotkey and hotKeyEnabled then activateChat() end end)
	end)
	if not newChatMode then
		--guiService:AddKey("/")
		--guiService.KeyPressed:connect(function(key) if key == "/" and hotKeyEnabled then activateChat() end end)
	end

	chatBox.FocusLost:connect(
		function(enterPressed)
			if enterPressed then
				if chatBox.Text ~= "" then
					local str = chatBox.Text
					if string.sub(str, 1, 1) == '%' then
						game:GetService("Players"):TeamChat(string.sub(str, 2))
					else
						game:GetService("Players"):Chat(str)
					end
				end
			end
			chatBox.Text = ""
			chatBox.Visible = false
			chatButton.Visible = true
		end)
	robloxLock(chatBar)
	return chatBar, toggleHotKey
end

--Spawn a thread for the Save dialogs
local isSaveDialogSupported = pcall(function() local var = game.LocalSaveEnabled end)
if isSaveDialogSupported then
	delay(0, 
		function()
			local saveDialogs = createSaveDialogs()
			saveDialogs.Parent = gui
		
			game.RequestShutdown = function()
				table.insert(centerDialogs,saveDialogs)
				game:GetService("GuiService"):AddCenterDialog(saveDialogs, Enum.CenterDialogType.QuitDialog,
					--ShowFunction
					function()
						saveDialogs.Visible = true 
					end,
					--HideFunction
					function()
						saveDialogs.Visible = false
					end)

				return true
			end
		end)
end

--Spawn a thread to listen to leave game prompts
Spawn(function()
	local showLeaveEvent = nil
	pcall(function() showLeaveEvent = Game:GetService("GuiService").ShowLeaveConfirmation end)
	if not showLeaveEvent then return end

	function showLeaveConfirmation()
		if showMainMenu then
			showMainMenu("LeaveConfirmationMenu","down",UDim2.new(0,525,0,300))
		end
	end

	Game:GetService("GuiService").ShowLeaveConfirmation:connect(function( )
		if currentMenuSelection == nil then
			showLeaveConfirmation()
		else
			resumeGameFunction(gui.UserSettingsShield)
		end
	end)
end)

--Spawn a thread for the Report Abuse dialogs
delay(0, 
	function()
		createReportAbuseDialog().Parent = gui
		waitForChild(gui,"UserSettingsShield")
		waitForChild(gui.UserSettingsShield, "Settings")
		waitForChild(gui.UserSettingsShield.Settings,"SettingsStyle")
		waitForChild(gui.UserSettingsShield.Settings.SettingsStyle,"GameMainMenu")
		waitForChild(gui.UserSettingsShield.Settings.SettingsStyle.GameMainMenu, "ReportAbuseButton")
		gui.UserSettingsShield.Settings.SettingsStyle.GameMainMenu.ReportAbuseButton.Active = true
	end)

end --LoadLibrary if
