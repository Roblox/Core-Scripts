local PURPOSE_DATA = {
	[Enum.DialogPurpose.Quest] = {"rbxasset://textures/ui/dialog_purpose_quest.png", Vector2.new(6, 22)},
	[Enum.DialogPurpose.Help] = {"rbxasset://textures/ui/dialog_purpose_help.png", Vector2.new(12, 22)},
	[Enum.DialogPurpose.Shop] = {"rbxasset://textures/ui/dialog_purpose_shop.png", Vector2.new(14, 27)},
}
local TEXT_HEIGHT = 24 -- Pixel height of one row
local BAR_THICKNESS = 6
local STYLE_PADDING = 17
local CHOICE_PADDING = 6 * 2 -- (Added to vertical height)
local PROMPT_SIZE = Vector2.new(80, 90)

local WIDTH_BONUS = (STYLE_PADDING * 2) - BAR_THICKNESS
local XPOS_OFFSET = -(STYLE_PADDING - BAR_THICKNESS)
local YPOS_OFFSET = -math.floor(STYLE_PADDING / 2)


function waitForProperty(instance, name)
	while not instance[name] do
		instance.Changed:wait()
	end
end

function waitForChild(instance, name)
	while not instance:FindFirstChild(name) do
		instance.ChildAdded:wait()
	end
end

local gamepadDialogFlagSuccess, gamepadDialogFlagValue = pcall(function() return settings():GetFFlag("GamepadDialogSupport") end)
local gamepadDialogSupportEnabled = (gamepadDialogFlagSuccess and gamepadDialogFlagValue == true)

local mainFrame
local choices = {}
local lastChoice
local choiceMap = {}
local currentConversationDialog
local currentConversationPartner
local currentAbortDialogScript

local tooFarAwayMessage =           "You are too far away to chat!"
local tooFarAwaySize = 300
local characterWanderedOffMessage = "Chat ended because you walked away"
local characterWanderedOffSize = 350
local conversationTimedOut =        "Chat ended because you didn't reply"
local conversationTimedOutSize = 350

local player
local screenGui
local chatNotificationGui
local messageDialog
local timeoutScript
local reenableDialogScript
local dialogMap = {}
local dialogConnections = {}

local gui = nil
waitForChild(game,"CoreGui")
waitForChild(game:GetService("CoreGui"),"RobloxGui")
if game:GetService("CoreGui").RobloxGui:FindFirstChild("ControlFrame") then
	gui = game:GetService("CoreGui").RobloxGui.ControlFrame
else
	gui = game:GetService("CoreGui").RobloxGui
end
local touchEnabled = game:GetService("UserInputService").TouchEnabled

function currentTone()
	if currentConversationDialog then
		return currentConversationDialog.Tone
	else
		return Enum.DialogTone.Neutral
	end
end


function createChatNotificationGui()
	chatNotificationGui = Instance.new("BillboardGui")
	if gamepadDialogSupportEnabled then
		chatNotificationGui.Name = "RBXChatNotificationGui"
	else
		chatNotificationGui.Name = "ChatNotificationGui"
	end

	chatNotificationGui.ExtentsOffset = Vector3.new(0,1,0)
	chatNotificationGui.Size = UDim2.new(PROMPT_SIZE.X / 31.5, 0, PROMPT_SIZE.Y / 31.5, 0)
	chatNotificationGui.SizeOffset = Vector2.new(0,0)
	chatNotificationGui.StudsOffset = Vector3.new(0, 3.7, 0)
	chatNotificationGui.Enabled = true
	chatNotificationGui.RobloxLocked = true
	chatNotificationGui.Active = true

	local button = Instance.new("ImageButton")
	button.Name = "Background"
	button.Active = false
	button.BackgroundTransparency = 1
	button.Position = UDim2.new(0, 0, 0, 0)
	button.Size = UDim2.new(1, 0, 1, 0)
	button.Image = ""
	button.RobloxLocked = true
	button.Parent = chatNotificationGui

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Position = UDim2.new(0, 0, 0, 0)
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.Image = ""
	icon.BackgroundTransparency = 1
	icon.RobloxLocked = true
	icon.Parent = button
end

function getChatColor(tone)
	if tone == Enum.DialogTone.Neutral then
		return Enum.ChatColor.Blue
	elseif tone == Enum.DialogTone.Friendly then
		return Enum.ChatColor.Green
	elseif tone == Enum.DialogTone.Enemy then
		return Enum.ChatColor.Red
	end
end

function styleChoices()
	for _, obj in pairs(choices) do
		obj.BackgroundTransparency = 1
	end
	lastChoice.BackgroundTransparency = 1
end

function styleMainFrame(tone)
	if tone == Enum.DialogTone.Neutral then
		mainFrame.Style = Enum.FrameStyle.ChatBlue
	elseif tone == Enum.DialogTone.Friendly then
		mainFrame.Style = Enum.FrameStyle.ChatGreen
	elseif tone == Enum.DialogTone.Enemy then
		mainFrame.Style = Enum.FrameStyle.ChatRed
	end

	styleChoices()
end
function setChatNotificationTone(gui, purpose, tone)
	if tone == Enum.DialogTone.Neutral then
		gui.Background.Image = "rbxasset://textures/ui/chatBubble_blue_notify_bkg.png"
	elseif tone == Enum.DialogTone.Friendly then
		gui.Background.Image = "rbxasset://textures/ui/chatBubble_green_notify_bkg.png"
	elseif tone == Enum.DialogTone.Enemy then
		gui.Background.Image = "rbxasset://textures/ui/chatBubble_red_notify_bkg.png"
	end

	local newIcon, size = unpack(PURPOSE_DATA[purpose])
	local relativeSize = size / PROMPT_SIZE
	gui.Background.Icon.Size = UDim2.new(relativeSize.X, 0, relativeSize.Y, 0)
	gui.Background.Icon.Position = UDim2.new(0.5 - (relativeSize.X / 2), 0, 0.4 - (relativeSize.Y / 2), 0)
	gui.Background.Icon.Image = newIcon
end

function createMessageDialog()
	messageDialog = Instance.new("Frame");
	messageDialog.Name = "DialogScriptMessage"
	messageDialog.Style = Enum.FrameStyle.Custom
	messageDialog.BackgroundTransparency = 0.5
	messageDialog.BackgroundColor3 = Color3.new(31/255, 31/255, 31/255)
	messageDialog.Visible = false

	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Position = UDim2.new(0,0,0,-1)
	text.Size = UDim2.new(1,0,1,0)
	text.FontSize = Enum.FontSize.Size14
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1,1,1)
	text.RobloxLocked = true
	text.Parent = messageDialog
end

function showMessage(msg, size)
	messageDialog.Text.Text = msg
	messageDialog.Size = UDim2.new(0,size,0,40)
	messageDialog.Position = UDim2.new(0.5, -size/2, 0.5, -40)
	messageDialog.Visible = true
	wait(2)
	messageDialog.Visible = false
end

function variableDelay(str)
	local length = math.min(string.len(str), 100)
	wait(0.75 + ((length/75) * 1.5))
end

function resetColor(frame)
	frame.BackgroundTransparency = 1
end

function wanderDialog()
	mainFrame.Visible = false
	endDialog()
	showMessage(characterWanderedOffMessage, characterWanderedOffSize)
end

function timeoutDialog()
	mainFrame.Visible = false
	endDialog()
	showMessage(conversationTimedOut, conversationTimedOutSize)
end
function normalEndDialog()
	endDialog()
end

function endDialog()
   if currentAbortDialogScript then
		currentAbortDialogScript:Remove()
		currentAbortDialogScript = nil
	end

	local dialog = currentConversationDialog
	currentConversationDialog = nil
	if dialog and dialog.InUse then
		local reenableScript = reenableDialogScript:Clone()
		reenableScript.archivable = false
		reenableScript.Disabled = false
		reenableScript.Parent = dialog
	end

	for dialog, gui in pairs(dialogMap) do
		if dialog and gui then
			gui.Enabled = not dialog.InUse
		end
	end

	currentConversationPartner = nil
end

function sanitizeMessage(msg)
  if string.len(msg) == 0 then
     return "..."
  else
     return msg
  end
end

function selectChoice(choice)
	renewKillswitch(currentConversationDialog)

	--First hide the Gui
	mainFrame.Visible = false
	if choice == lastChoice then
		game:GetService("Chat"):Chat(game:GetService("Players").LocalPlayer.Character, "Goodbye!", getChatColor(currentTone()))

		normalEndDialog()
	else
		local dialogChoice = choiceMap[choice]

		game:GetService("Chat"):Chat(game:GetService("Players").LocalPlayer.Character, sanitizeMessage(dialogChoice.UserDialog), getChatColor(currentTone()))
		wait(1)
		currentConversationDialog:SignalDialogChoiceSelected(player, dialogChoice)
		game:GetService("Chat"):Chat(currentConversationPartner, sanitizeMessage(dialogChoice.ResponseDialog), getChatColor(currentTone()))

		variableDelay(dialogChoice.ResponseDialog)
		presentDialogChoices(currentConversationPartner, dialogChoice:GetChildren())
	end
end

function newChoice()
	local frame = Instance.new("TextButton")
	frame.BackgroundColor3 = Color3.new(227/255, 227/255, 227/255)
	frame.BackgroundTransparency = 1
	frame.AutoButtonColor = false
	frame.BorderSizePixel = 0
	frame.Text = ""
	frame.MouseEnter:connect(function() frame.BackgroundTransparency = 0 end)
	frame.MouseLeave:connect(function() frame.BackgroundTransparency = 1 end)
	frame.MouseButton1Click:connect(function() selectChoice(frame) end)
	frame.RobloxLocked = true

	local prompt = Instance.new("TextLabel")
	prompt.Name = "UserPrompt"
	prompt.BackgroundTransparency = 1
	prompt.Font = Enum.Font.SourceSans
	prompt.FontSize = Enum.FontSize.Size24
	prompt.Position = UDim2.new(0, 28, 0, 0)
	prompt.Size = UDim2.new(1, -32-28, 1, 0)
	prompt.TextXAlignment = Enum.TextXAlignment.Left
	prompt.TextYAlignment = Enum.TextYAlignment.Center
	prompt.TextWrap = true
	prompt.RobloxLocked = true
	prompt.Parent = frame

	return frame
end
function initialize(parent)
	choices[1] = newChoice()
	choices[2] = newChoice()
	choices[3] = newChoice()
	choices[4] = newChoice()

	lastChoice = newChoice()
	lastChoice.UserPrompt.Text = "Goodbye!"
	lastChoice.Size = UDim2.new(1, WIDTH_BONUS, 0, TEXT_HEIGHT + CHOICE_PADDING)

	mainFrame = Instance.new("Frame")
	mainFrame.Name = "UserDialogArea"
	mainFrame.Size = UDim2.new(0, 350, 0, 200)
	mainFrame.Style = Enum.FrameStyle.ChatBlue
	mainFrame.Visible = false

	for n, obj in pairs(choices) do
      obj.RobloxLocked = true
		obj.Parent = mainFrame
	end
   lastChoice.RobloxLocked = true
	lastChoice.Parent = mainFrame

   mainFrame.RobloxLocked = true
	mainFrame.Parent = parent
end

function presentDialogChoices(talkingPart, dialogChoices)
	if not currentConversationDialog then
		return
	end

	currentConversationPartner = talkingPart
	sortedDialogChoices = {}
	for n, obj in pairs(dialogChoices) do
		if obj:IsA("DialogChoice") then
			table.insert(sortedDialogChoices, obj)
		end
	end
	table.sort(sortedDialogChoices, function(a,b) return a.Name < b.Name end)

	if #sortedDialogChoices == 0 then
		normalEndDialog()
		return
	end

	local pos = 1
	local yPosition = 0
	choiceMap = {}
	for n, obj in pairs(choices) do
		obj.Visible = false
	end

	for n, obj in pairs(sortedDialogChoices) do
		if pos <= #choices then
			--3 lines is the maximum, set it to that temporarily
			choices[pos].Size = UDim2.new(1, WIDTH_BONUS, 0, TEXT_HEIGHT * 3)
			choices[pos].UserPrompt.Text = obj.UserDialog
			local height = (math.ceil(choices[pos].UserPrompt.TextBounds.Y / TEXT_HEIGHT) * TEXT_HEIGHT) + CHOICE_PADDING

			choices[pos].Position = UDim2.new(0, XPOS_OFFSET, 0, YPOS_OFFSET + yPosition)
			choices[pos].Size = UDim2.new(1, WIDTH_BONUS, 0, height)
			choices[pos].Visible = true

			choiceMap[choices[pos]] = obj

			yPosition = yPosition + height + 1 -- The +1 makes highlights not overlap
			pos = pos + 1
		end
	end

	lastChoice.Position = UDim2.new(0, XPOS_OFFSET, 0, YPOS_OFFSET + yPosition)

	mainFrame.Size = UDim2.new(0, 350, 0, yPosition + lastChoice.AbsoluteSize.Y + (STYLE_PADDING * 2) + (YPOS_OFFSET * 2))
	mainFrame.Position = UDim2.new(0,20,1.0, -mainFrame.Size.Y.Offset-20)
	styleMainFrame(currentTone())
	mainFrame.Visible = true

	if gamepadDialogSupportEnabled then
		Game:GetService("GuiService").SelectedCoreObject = choices[1]
	end
end

function doDialog(dialog)
	while not Instance.Lock(dialog, player) do
		wait()
	end

	if dialog.InUse then
		Instance.Unlock(dialog)
		return
	else
		dialog.InUse = true
		Instance.Unlock(dialog)
	end

	currentConversationDialog = dialog
	game:GetService("Chat"):Chat(dialog.Parent, dialog.InitialPrompt, getChatColor(dialog.Tone))
	variableDelay(dialog.InitialPrompt)

	presentDialogChoices(dialog.Parent, dialog:GetChildren())
end

function renewKillswitch(dialog)
	if currentAbortDialogScript then
		currentAbortDialogScript:Remove()
		currentAbortDialogScript = nil
	end

	currentAbortDialogScript = timeoutScript:Clone()
	currentAbortDialogScript.archivable = false
	currentAbortDialogScript.Disabled = false
	currentAbortDialogScript.Parent = dialog
end

function checkForLeaveArea()
	while currentConversationDialog do
		if currentConversationDialog.Parent and (player:DistanceFromCharacter(currentConversationDialog.Parent.Position) >= currentConversationDialog.ConversationDistance) then
			wanderDialog()
		end
		wait(1)
	end
end

function startDialog(dialog)
	if dialog.Parent and dialog.Parent:IsA("BasePart") then
		if player:DistanceFromCharacter(dialog.Parent.Position) >= dialog.ConversationDistance then
			showMessage(tooFarAwayMessage, tooFarAwaySize)
			return
		end

		for dialog, gui in pairs(dialogMap) do
			if dialog and gui then
				gui.Enabled = false
			end
		end

		renewKillswitch(dialog)

		delay(1, checkForLeaveArea)
		doDialog(dialog)
	end
end

function removeDialog(dialog)
   if dialogMap[dialog] then
      dialogMap[dialog]:Remove()
      dialogMap[dialog] = nil
   end
	if dialogConnections[dialog] then
		dialogConnections[dialog]:disconnect()
		dialogConnections[dialog] = nil
	end
end

function addDialog(dialog)
	if dialog.Parent then
		if dialog.Parent:IsA("BasePart") then
			local chatGui = chatNotificationGui:clone()
			chatGui.Enabled = not dialog.InUse
			chatGui.Adornee = dialog.Parent
			chatGui.RobloxLocked = true

			if gamepadDialogSupportEnabled then
				waitForProperty(game:GetService("Players"), "LocalPlayer")
	 			game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
				chatGui.Parent = game:GetService("Players").LocalPlayer.PlayerGui
			else
				chatGui.Parent = game:GetService("CoreGui")
			end

			chatGui.Background.MouseButton1Click:connect(function() startDialog(dialog) end)
			setChatNotificationTone(chatGui, dialog.Purpose, dialog.Tone)

			dialogMap[dialog] = chatGui

			dialogConnections[dialog] = dialog.Changed:connect(function(prop)
				if prop == "Parent" and dialog.Parent then
					--This handles the reparenting case, seperate from removal case
					removeDialog(dialog)
					addDialog(dialog)
				elseif prop == "InUse" then
					chatGui.Enabled = not currentConversationDialog and not dialog.InUse
					if dialog == currentConversationDialog then
						timeoutDialog()
					end
				elseif prop == "Tone" or prop == "Purpose" then
					setChatNotificationTone(chatGui, dialog.Purpose, dialog.Tone)
				end
			end)
		else -- still need to listen to parent changes even if current parent is not a BasePart
			dialogConnections[dialog] = dialog.Changed:connect(function(prop)
				if prop == "Parent" and dialog.Parent then
					--This handles the reparenting case, seperate from removal case
					removeDialog(dialog)
					addDialog(dialog)
				end
			end)
		end
	end
end

function fetchScripts()
	local model = game:GetService("InsertService"):LoadAsset(39226062)
    if type(model) == "string" then -- load failed, lets try again
		wait(0.1)
		model = game:GetService("InsertService"):LoadAsset(39226062)
	end
	if type(model) == "string" then -- not going to work, lets bail
		return
	end

	waitForChild(model,"TimeoutScript")
	timeoutScript = model.TimeoutScript
	waitForChild(model,"ReenableDialogScript")
	reenableDialogScript = model.ReenableDialogScript
end

function onLoad()
  waitForProperty(game:GetService("Players"), "LocalPlayer")
  player = game:GetService("Players").LocalPlayer
  waitForProperty(player, "Character")

  --print("Fetching Scripts")
  fetchScripts()

  --print("Creating Guis")
  createChatNotificationGui()

  --print("Creating MessageDialog")
  createMessageDialog()
  messageDialog.RobloxLocked = true
  messageDialog.Parent = gui

  --print("Waiting for BottomLeftControl")
  waitForChild(gui, "BottomLeftControl")

  --print("Initializing Frame")
  local frame = Instance.new("Frame")
  frame.Name = "DialogFrame"
  frame.Position = UDim2.new(0,0,0,0)
  frame.Size = UDim2.new(0,0,0,0)
  frame.BackgroundTransparency = 1
  frame.RobloxLocked = true
  if gamepadDialogSupportEnabled then
  		game:GetService("GuiService"):AddSelectionParent("RBXDialogGroup", frame)
  end

  if (touchEnabled) then
	frame.Position = UDim2.new(0,20,0.5,0)
	frame.Size = UDim2.new(0.25,0,0.1,0)
	frame.Parent = gui
  else
	frame.Parent = gui.BottomLeftControl
  end
  initialize(frame)

  --print("Adding Dialogs")
  game:GetService("CollectionService").ItemAdded:connect(function(obj) if obj:IsA("Dialog") then addDialog(obj) end end)
  game:GetService("CollectionService").ItemRemoved:connect(function(obj) if obj:IsA("Dialog") then removeDialog(obj) end end)
  for i, obj in pairs(game:GetService("CollectionService"):GetCollection("Dialog")) do
    if obj:IsA("Dialog") then
       addDialog(obj)
    end
  end
end

onLoad()