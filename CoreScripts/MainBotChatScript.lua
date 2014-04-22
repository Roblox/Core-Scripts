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
waitForChild(game.CoreGui,"RobloxGui")
if game.CoreGui.RobloxGui:FindFirstChild("ControlFrame") then
	gui = game.CoreGui.RobloxGui.ControlFrame
else
	gui = game.CoreGui.RobloxGui
end

function currentTone()
	if currentConversationDialog then
		return currentConversationDialog.Tone
	else
		return Enum.DialogTone.Neutral
	end
end
	

function createChatNotificationGui()
	chatNotificationGui = Instance.new("BillboardGui")
	chatNotificationGui.Name = "ChatNotificationGui"
	chatNotificationGui.ExtentsOffset = Vector3.new(0,1,0)
	chatNotificationGui.Size = UDim2.new(4, 0, 5.42857122, 0)
	chatNotificationGui.SizeOffset = Vector2.new(0,0)
	chatNotificationGui.StudsOffset = Vector3.new(0.4, 4.3, 0)
	chatNotificationGui.Enabled = true
   chatNotificationGui.RobloxLocked = true
	chatNotificationGui.Active = true

	local image = Instance.new("ImageLabel")
	image.Name = "Image"
	image.Active = false
	image.BackgroundTransparency = 1
	image.Position = UDim2.new(0,0,0,0)
	image.Size = UDim2.new(1.0,0,1.0,0)
	image.Image = ""
   image.RobloxLocked = true
	image.Parent = chatNotificationGui
   

	local button = Instance.new("ImageButton")
	button.Name = "Button"
	button.AutoButtonColor = false
	button.Position = UDim2.new(0.0879999995, 0, 0.0529999994, 0)
	button.Size = UDim2.new(0.829999983, 0, 0.460000008, 0)
	button.Image = ""
	button.BackgroundTransparency = 1
   button.RobloxLocked = true
	button.Parent = image
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

function styleChoices(tone)
	for i, obj in pairs(choices) do
		resetColor(obj, tone)
	end
	resetColor(lastChoice, tone)
end

function styleMainFrame(tone)
	if tone == Enum.DialogTone.Neutral then
		mainFrame.Style = Enum.FrameStyle.ChatBlue
		mainFrame.Tail.Image = "rbxasset://textures/chatBubble_botBlue_tailRight.png"
	elseif tone == Enum.DialogTone.Friendly then
		mainFrame.Style = Enum.FrameStyle.ChatGreen
		mainFrame.Tail.Image = "rbxasset://textures/chatBubble_botGreen_tailRight.png"
	elseif tone == Enum.DialogTone.Enemy then
		mainFrame.Style = Enum.FrameStyle.ChatRed
		mainFrame.Tail.Image = "rbxasset://textures/chatBubble_botRed_tailRight.png"
	end
	
	styleChoices(tone)
end
function setChatNotificationTone(gui, purpose, tone)
	if tone == Enum.DialogTone.Neutral then
		gui.Image.Image = "rbxasset://textures/chatBubble_botBlue_notify_bkg.png"
	elseif tone == Enum.DialogTone.Friendly then
		gui.Image.Image = "rbxasset://textures/chatBubble_botGreen_notify_bkg.png"
	elseif tone == Enum.DialogTone.Enemy then
		gui.Image.Image = "rbxasset://textures/chatBubble_botRed_notify_bkg.png"
	end
	if purpose == Enum.DialogPurpose.Quest then
		gui.Image.Button.Image = "rbxasset://textures/chatBubble_bot_notify_bang.png"
	elseif purpose == Enum.DialogPurpose.Help then
		gui.Image.Button.Image = "rbxasset://textures/chatBubble_bot_notify_question.png"
	elseif purpose == Enum.DialogPurpose.Shop then
		gui.Image.Button.Image = "rbxasset://textures/chatBubble_bot_notify_money.png"
	end
end

function createMessageDialog()
	messageDialog = Instance.new("Frame");
	messageDialog.Name = "DialogScriptMessage"
	messageDialog.Style = Enum.FrameStyle.RobloxRound
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

function resetColor(frame, tone)
	if tone == Enum.DialogTone.Neutral then
		frame.BackgroundColor3 = Color3.new(0/255, 0/255,   179/255) 
		frame.Number.TextColor3 = Color3.new(45/255, 142/255, 245/255) 
	elseif tone == Enum.DialogTone.Friendly then
		frame.BackgroundColor3 = Color3.new(0/255, 77/255,   0/255) 
		frame.Number.TextColor3 = Color3.new(0/255, 190/255, 0/255) 
	elseif tone == Enum.DialogTone.Enemy then
		frame.BackgroundColor3 = Color3.new(140/255, 0/255, 0/255) 
		frame.Number.TextColor3 = Color3.new(255/255,88/255, 79/255) 
	end
end

function highlightColor(frame, tone)
	if tone == Enum.DialogTone.Neutral then
		frame.BackgroundColor3 = Color3.new(2/255, 108/255,   255/255) 
		frame.Number.TextColor3 = Color3.new(1, 1, 1) 
	elseif tone == Enum.DialogTone.Friendly then
		frame.BackgroundColor3 = Color3.new(0/255, 128/255,   0/255) 
		frame.Number.TextColor3 = Color3.new(1, 1, 1) 
	elseif tone == Enum.DialogTone.Enemy then
		frame.BackgroundColor3 = Color3.new(204/255, 0/255, 0/255) 
		frame.Number.TextColor3 = Color3.new(1, 1, 1) 
	end
end

function wanderDialog()
	print("Wander")
	mainFrame.Visible = false
	endDialog()
	showMessage(characterWanderedOffMessage, characterWanderedOffSize)
end

function timeoutDialog()
	print("Timeout")
	mainFrame.Visible = false
	endDialog()
	showMessage(conversationTimedOut, conversationTimedOutSize)
end
function normalEndDialog()
	print("Done")
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
		game.Chat:Chat(game.Players.LocalPlayer.Character, "Goodbye!", getChatColor(currentTone()))
		
		normalEndDialog()
	else 
		local dialogChoice = choiceMap[choice]

		game.Chat:Chat(game.Players.LocalPlayer.Character, sanitizeMessage(dialogChoice.UserDialog), getChatColor(currentTone()))
		wait(1)
		currentConversationDialog:SignalDialogChoiceSelected(player, dialogChoice)
		game.Chat:Chat(currentConversationPartner, sanitizeMessage(dialogChoice.ResponseDialog), getChatColor(currentTone()))
	
		variableDelay(dialogChoice.ResponseDialog)
		presentDialogChoices(currentConversationPartner, dialogChoice:GetChildren())
	end 
end

function newChoice(numberText)
	local frame = Instance.new("TextButton")
	frame.BackgroundColor3 = Color3.new(0/255, 0/255, 179/255)
	frame.AutoButtonColor = false
	frame.BorderSizePixel = 0
	frame.Text = ""
	frame.MouseEnter:connect(function() highlightColor(frame, currentTone()) end)
	frame.MouseLeave:connect(function() resetColor(frame, currentTone()) end)
	frame.MouseButton1Click:connect(function() selectChoice(frame) end)
   frame.RobloxLocked = true

	local number = Instance.new("TextLabel")
	number.Name = "Number"
	number.TextColor3 = Color3.new(127/255, 212/255, 255/255)
	number.Text = numberText
	number.FontSize = Enum.FontSize.Size14
	number.BackgroundTransparency = 1
	number.Position = UDim2.new(0,4,0,2)
	number.Size = UDim2.new(0,20,0,24)
	number.TextXAlignment = Enum.TextXAlignment.Left
	number.TextYAlignment = Enum.TextYAlignment.Top
   number.RobloxLocked = true
	number.Parent = frame

	local prompt = Instance.new("TextLabel")
	prompt.Name = "UserPrompt"
	prompt.BackgroundTransparency = 1
	prompt.TextColor3 = Color3.new(1,1,1)
	prompt.FontSize = Enum.FontSize.Size14
	prompt.Position = UDim2.new(0,28, 0, 2)
	prompt.Size = UDim2.new(1,-32, 1, -4)
	prompt.TextXAlignment = Enum.TextXAlignment.Left
	prompt.TextYAlignment = Enum.TextYAlignment.Top
	prompt.TextWrap = true
   prompt.RobloxLocked = true
	prompt.Parent = frame

	return frame
end
function initialize(parent)
	choices[1] = newChoice("1)")
	choices[2] = newChoice("2)")
	choices[3] = newChoice("3)")
	choices[4] = newChoice("4)")

	lastChoice = newChoice("5)")
	lastChoice.UserPrompt.Text = "Goodbye!"
	lastChoice.Size = UDim2.new(1,0,0,28)

	mainFrame = Instance.new("Frame")
	mainFrame.Name = "UserDialogArea"
	mainFrame.Size = UDim2.new(0, 350, 0, 200)
	mainFrame.Style = Enum.FrameStyle.ChatBlue
	mainFrame.Visible = false
	
	imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "Tail"
	imageLabel.Size = UDim2.new(0,62,0,53)
	imageLabel.Position = UDim2.new(1,8,0.25)
	imageLabel.Image = "rbxasset://textures/chatBubble_botBlue_tailRight.png"
	imageLabel.BackgroundTransparency = 1
   imageLabel.RobloxLocked = true
	imageLabel.Parent = mainFrame
		
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
			choices[pos].Size = UDim2.new(1, 0, 0, 24*3)
			choices[pos].UserPrompt.Text = obj.UserDialog
			local height = math.ceil(choices[pos].UserPrompt.TextBounds.Y/24)*24

			choices[pos].Position = UDim2.new(0, 0, 0, yPosition)
			choices[pos].Size = UDim2.new(1, 0, 0, height)
			choices[pos].Visible = true
		
			choiceMap[choices[pos]] = obj

			yPosition = yPosition + height
			pos = pos + 1
		end
	end

	lastChoice.Position = UDim2.new(0,0,0,yPosition)	
	lastChoice.Number.Text = pos .. ")"

	mainFrame.Size = UDim2.new(0, 350, 0, yPosition+24+32)
	mainFrame.Position = UDim2.new(0,20,0.0, -mainFrame.Size.Y.Offset-20)
	styleMainFrame(currentTone())
	mainFrame.Visible = true
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
	game.Chat:Chat(dialog.Parent, dialog.InitialPrompt, getChatColor(dialog.Tone))
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
			chatGui.Parent = game.CoreGui
			chatGui.Image.Button.MouseButton1Click:connect(function() startDialog(dialog) end)
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
  waitForProperty(game.Players, "LocalPlayer")
  player = game.Players.LocalPlayer
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
  frame.Parent = gui.BottomLeftControl
  initialize(frame)

  --print("Adding Dialogs")
  game.CollectionService.ItemAdded:connect(function(obj) if obj:IsA("Dialog") then addDialog(obj) end end)
  game.CollectionService.ItemRemoved:connect(function(obj) if obj:IsA("Dialog") then removeDialog(obj) end end)
  for i, obj in pairs(game.CollectionService:GetCollection("Dialog")) do
    if obj:IsA("Dialog") then
       addDialog(obj)
    end
  end
end

onLoad()