--[[
	// FileName: BubbleChat.lua
	// Written by: jeditkacheff
	// Description: Code for rendering bubble chat
]]

local useNewBubbleChatSuccess, useNewBubbleChatEnabled = pcall(function() return settings():GetFFlag("CorescriptNewBubbleChatEnabled") end)
useNewBubbleChatEnabled = useNewBubbleChatEnabled and useNewBubbleChatSuccess
if useNewBubbleChatEnabled then
	-- We need to check if the BubbleChat script exists before we can disable this bubble chat.
	-- This is for during the transition period when CorescriptNewBubbleChatEnabled could be true on the client, but not the server.
	if not game:IsLoaded() then
		game.Loaded:wait()
	end
	local ChatService = game:GetService("Chat")
	local BubbleChat = ChatService:WaitForChild("BubbleChat", 3)
	if BubbleChat then
		return --Don't enable this file if the new Bubble chat is enabled
	end
end

--[[ SERVICES ]]
local RunService = game:GetService('RunService')
local CoreGuiService = game:GetService('CoreGui')
local PlayersService = game:GetService('Players')
local ChatService = game:GetService("Chat")
local TextService = game:GetService("TextService")
local GameOptions = settings()["Game Options"]
--[[ END OF SERVICES ]]


while PlayersService.LocalPlayer == nil do PlayersService.ChildAdded:wait() end
local GuiRoot = CoreGuiService:WaitForChild('RobloxGui')
local playerDropDownModule = require(GuiRoot.Modules:WaitForChild("PlayerDropDown"))
local blockingUtility = playerDropDownModule:CreateBlockingUtility()


--[[ SCRIPT VARIABLES ]]
local CHAT_BUBBLE_FONT = Enum.Font.SourceSans
local CHAT_BUBBLE_FONT_SIZE = Enum.FontSize.Size24 -- if you change CHAT_BUBBLE_FONT_SIZE_INT please change this to match
local CHAT_BUBBLE_FONT_SIZE_INT = 24 -- if you change CHAT_BUBBLE_FONT_SIZE please change this to match
local CHAT_BUBBLE_LINE_HEIGHT = CHAT_BUBBLE_FONT_SIZE_INT + 10
local CHAT_BUBBLE_TAIL_HEIGHT = 14
local CHAT_BUBBLE_WIDTH_PADDING = 30
local CHAT_BUBBLE_FADE_SPEED = 1.5

local BILLBOARD_MAX_WIDTH = 400
local BILLBOARD_MAX_HEIGHT = 250	--This limits the number of bubble chats that you see above characters

local ELIPSES = "..."
local CchMaxChatMessageLength = 128 -- max chat message length, including null terminator and elipses.
local CchMaxChatMessageLengthExclusive = CchMaxChatMessageLength - string.len(ELIPSES) - 1

local NEAR_BUBBLE_DISTANCE = 65	--previously 45
local MAX_BUBBLE_DISTANCE = 100	--previously 80

--[[ END OF SCRIPT VARIABLES ]]


-- [[ SCRIPT ENUMS ]]
local ChatType = {	PLAYER_CHAT = "pChat",
					PLAYER_TEAM_CHAT = "pChatTeam",
					PLAYER_WHISPER_CHAT = "pChatWhisper",
					GAME_MESSAGE= "gMessage",
					PLAYER_GAME_CHAT = "pGame",
					BOT_CHAT = "bChat" }

local BubbleColor = {	WHITE = "dub",
					BLUE = "blu",
					GREEN = "gre",
					RED = "red" }

--[[ END OF SCRIPT ENUMS ]]



--[[ FUNCTIONS ]]

local function lerpLength(msg, min, max)
	return min + (max-min) * math.min(string.len(msg)/75.0, 1.0)
end

local function createFifo()
	local this = {}
	this.data = {}

	local emptyEvent = Instance.new("BindableEvent")
	this.Emptied = emptyEvent.Event

	function this:Size()
		return #this.data
	end

	function this:Empty()
		return this:Size() <= 0
	end

	function this:PopFront()
		table.remove(this.data, 1)
		if this:Empty() then emptyEvent:Fire() end
	end

	function this:Front()
		return this.data[1]
	end

	function this:Get(index)
		return this.data[index]
	end

	function this:PushBack(value)
		table.insert(this.data, value)
	end

	function this:GetData()
		return this.data
	end

	return this
end

local function createCharacterChats()
	local this = {}

	this.Fifo = createFifo()
	this.BillboardGui = nil

	return this
end

local function createMap()
	local this = {}
	this.data = {}
	local count = 0

	function this:Size()
		return count
	end

	function this:Erase(key)
		if this.data[key] then count = count - 1 end
		this.data[key] = nil
	end

	function this:Set(key, value)
		this.data[key] = value
		if value then count = count + 1 end
	end

	function this:Get(key)
		if not key then return end
		if not this.data[key] then
			this.data[key] = createCharacterChats()
			local emptiedCon = nil
			emptiedCon = this.data[key].Fifo.Emptied:connect(function()
				emptiedCon:disconnect()
				this:Erase(key)
			end)
		end
		return this.data[key]
	end

	function this:GetData()
		return this.data
	end

	return this
end

local function createChatLine(chatType, message, bubbleColor, isLocalPlayer)
	local this = {}

	function this:ComputeBubbleLifetime(msg, isSelf)
		if isSelf then
			return lerpLength(msg,8,15)
		else
			return lerpLength(msg,12,20)
		end
	end

	function this:IsPlayerChat()
		if not this.ChatType then return false end

		if this.ChatType == ChatType.PLAYER_CHAT or
			this.ChatType == ChatType.PLAYER_WHISPER_CHAT or
			this.ChatType == ChatType.PLAYER_TEAM_CHAT then
				return true
		end

		return false
	end

	this.ChatType = chatType
	this.Origin = nil
	this.RenderBubble = nil
	this.Message = message
	this.BubbleDieDelay = this:ComputeBubbleLifetime(message, isLocalPlayer)
	this.BubbleColor = bubbleColor
	this.IsLocalPlayer = isLocalPlayer

	return this
end

local function createPlayerChatLine(chatType, player, message, isLocalPlayer)
	local this = createChatLine(chatType, message, BubbleColor.WHITE, isLocalPlayer)

	if player then
		this.User = player.Name
		this.Origin = player.Character
	end

	return this
end

local function createGameChatLine(origin, message, isLocalPlayer, bubbleColor)
	local this = createChatLine(origin and ChatType.PLAYER_GAME_CHAT or ChatType.BOT_CHAT, message, bubbleColor, isLocalPlayer)
	this.Origin = origin

	return this
end

function createChatBubbleMain(filePrefix, sliceRect)
	local chatBubbleMain = Instance.new("ImageLabel")
	chatBubbleMain.Name = "ChatBubble"
	chatBubbleMain.ScaleType = Enum.ScaleType.Slice
	chatBubbleMain.SliceCenter = sliceRect
	chatBubbleMain.Image = "rbxasset://textures/" .. tostring(filePrefix) .. ".png"
	chatBubbleMain.BackgroundTransparency = 1
	chatBubbleMain.BorderSizePixel = 0
	chatBubbleMain.Size = UDim2.new(1.0, 0, 1.0, 0)
	chatBubbleMain.Position = UDim2.new(0,0,0,0)

	return chatBubbleMain
end

function createChatBubbleTail(position, size)
	local chatBubbleTail = Instance.new("ImageLabel")
	chatBubbleTail.Name = "ChatBubbleTail"
	chatBubbleTail.Image = "rbxasset://textures/ui/dialog_tail.png"
	chatBubbleTail.BackgroundTransparency = 1
	chatBubbleTail.BorderSizePixel = 0
	chatBubbleTail.Position = position
	chatBubbleTail.Size = size

	return chatBubbleTail
end

function createChatBubbleWithTail(filePrefix, position, size, sliceRect)
	local chatBubbleMain = createChatBubbleMain(filePrefix, sliceRect)

	local chatBubbleTail = createChatBubbleTail(position, size)
	chatBubbleTail.Parent = chatBubbleMain

	return chatBubbleMain
end

function createScaledChatBubbleWithTail(filePrefix, frameScaleSize, position, sliceRect)
	local chatBubbleMain = createChatBubbleMain(filePrefix, sliceRect)

	local frame = Instance.new("Frame")
	frame.Name = "ChatBubbleTailFrame"
	frame.BackgroundTransparency = 1
	frame.SizeConstraint = Enum.SizeConstraint.RelativeXX
	frame.Position = UDim2.new(0.5, 0, 1, 0)
	frame.Size = UDim2.new(frameScaleSize, 0, frameScaleSize, 0)
	frame.Parent = chatBubbleMain

	local chatBubbleTail = createChatBubbleTail(position, UDim2.new(1,0,0.5,0))
	chatBubbleTail.Parent = frame

	return chatBubbleMain
end

function createChatImposter(filePrefix, dotDotDot, yOffset)
	local result = Instance.new("ImageLabel")
	result.Name = "DialogPlaceholder"
	result.Image = "rbxasset://textures/" .. tostring(filePrefix) .. ".png"
	result.BackgroundTransparency = 1
	result.BorderSizePixel = 0
	result.Position = UDim2.new(0, 0, -1.25, 0)
	result.Size = UDim2.new(1, 0, 1, 0)

	local image = Instance.new("ImageLabel")
	image.Name = "DotDotDot"
	image.Image = "rbxasset://textures/" .. tostring(dotDotDot) .. ".png"
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.Position = UDim2.new(0.001, 0, yOffset, 0)
	image.Size = UDim2.new(1, 0, 0.7, 0)
	image.Parent = result

	return result
end


local function createChatOutput()

	local this = {}
	this.ChatBubble = {}
	this.ChatBubbleWithTail = {}
	this.ScalingChatBubbleWithTail = {}
	this.CharacterSortedMsg = createMap()

	-- init chat bubble tables
	local function initChatBubbleType(chatBubbleType, fileName, imposterFileName, isInset, sliceRect)
		this.ChatBubble[chatBubbleType] = createChatBubbleMain(fileName, sliceRect)
		this.ChatBubbleWithTail[chatBubbleType] = createChatBubbleWithTail(fileName, UDim2.new(0.5, -CHAT_BUBBLE_TAIL_HEIGHT, 1, isInset and -1 or 0), UDim2.new(0, 30, 0, CHAT_BUBBLE_TAIL_HEIGHT), sliceRect)
		this.ScalingChatBubbleWithTail[chatBubbleType] = createScaledChatBubbleWithTail(fileName, 0.5, UDim2.new(-0.5, 0, 0, isInset and -1 or 0), sliceRect)
	end

	initChatBubbleType(BubbleColor.WHITE,	"ui/dialog_white",	"ui/chatBubble_white_notify_bkg", 	false,	Rect.new(5,5,15,15))
	initChatBubbleType(BubbleColor.BLUE,	"ui/dialog_blue",	"ui/chatBubble_blue_notify_bkg",	true, 	Rect.new(7,7,33,33))
	initChatBubbleType(BubbleColor.RED,		"ui/dialog_red",	"ui/chatBubble_red_notify_bkg",		true,	Rect.new(7,7,33,33))
	initChatBubbleType(BubbleColor.GREEN,	"ui/dialog_green",	"ui/chatBubble_green_notify_bkg",	true,	Rect.new(7,7,33,33))

	function this:SanitizeChatLine(msg)
		if string.len(msg) > CchMaxChatMessageLengthExclusive then
			return string.sub(msg, 1, CchMaxChatMessageLengthExclusive + string.len(ELIPSES))
		else
			return msg
		end
	end

	local function createBillboardInstance(adornee)
		local billboardGui = Instance.new("BillboardGui")
		billboardGui.Adornee = adornee
		billboardGui.RobloxLocked = true
		billboardGui.Size = UDim2.new(0,BILLBOARD_MAX_WIDTH,0,BILLBOARD_MAX_HEIGHT)
		billboardGui.StudsOffset = Vector3.new(0, 1.5, 2)
		billboardGui.Parent = CoreGuiService

		local billboardFrame = Instance.new("Frame")
		billboardFrame.Name = "BillboardFrame"
		billboardFrame.Size = UDim2.new(1,0,1,0)
		billboardFrame.Position = UDim2.new(0,0,-0.5,0)
		billboardFrame.BackgroundTransparency = 1
		billboardFrame.Parent = billboardGui

		local billboardChildRemovedCon = nil
		billboardChildRemovedCon = billboardFrame.ChildRemoved:connect(function()
			if #billboardFrame:GetChildren() <= 1 then
				billboardChildRemovedCon:disconnect()
				billboardGui:Destroy()
			end
		end)

		this:CreateSmallTalkBubble(BubbleColor.WHITE).Parent = billboardFrame

		return billboardGui
	end

	function this:CreateBillboardGuiHelper(instance, onlyCharacter)
		if instance and not this.CharacterSortedMsg:Get(instance)["BillboardGui"] then
			if not onlyCharacter then
				if instance:IsA("Part") then
					-- Create a new billboardGui object attached to this player
					local billboardGui = createBillboardInstance(instance)
					this.CharacterSortedMsg:Get(instance)["BillboardGui"] = billboardGui
					return
				end
			end

			if instance:IsA("Model") then
				local head = instance:FindFirstChild("Head")
				if head and head:IsA("Part") then
					-- Create a new billboardGui object attached to this player
					local billboardGui = createBillboardInstance(head)
					this.CharacterSortedMsg:Get(instance)["BillboardGui"] = billboardGui
				end
			end
		end
	end

	local function distanceToBubbleOrigin(origin)
		if not origin then return 100000 end

		return (origin.Position - game.Workspace.CurrentCamera.CoordinateFrame.p).magnitude
	end

	local function isPartOfLocalPlayer(adornee)
		if adornee and PlayersService.LocalPlayer.Character then
			return adornee:IsDescendantOf(PlayersService.LocalPlayer.Character)
		end
	end

	function this:SetBillboardLODNear(billboardGui)
		local isLocalPlayer = isPartOfLocalPlayer(billboardGui.Adornee)
		billboardGui.Size = UDim2.new(0, BILLBOARD_MAX_WIDTH, 0, BILLBOARD_MAX_HEIGHT)
		billboardGui.StudsOffset = Vector3.new(0, isLocalPlayer and 1.5 or 2.5, isLocalPlayer and 2 or 0)
		billboardGui.Enabled = true
		local billChildren = billboardGui.BillboardFrame:GetChildren()
		for i = 1, #billChildren do
			billChildren[i].Visible = true
		end
		billboardGui.BillboardFrame.SmallTalkBubble.Visible = false
	end

	function this:SetBillboardLODDistant(billboardGui)
		local isLocalPlayer = isPartOfLocalPlayer(billboardGui.Adornee)
		billboardGui.Size = UDim2.new(4,0,3,0)
		billboardGui.StudsOffset = Vector3.new(0, 3, isLocalPlayer and 2 or 0)
		billboardGui.Enabled = true
		local billChildren = billboardGui.BillboardFrame:GetChildren()
		for i = 1, #billChildren do
			billChildren[i].Visible = false
		end
		billboardGui.BillboardFrame.SmallTalkBubble.Visible = true
	end

	function this:SetBillboardLODVeryFar(billboardGui)
		billboardGui.Enabled = false
	end

	function this:SetBillboardGuiLOD(billboardGui, origin)
		if not origin then return end

		if origin:IsA("Model") then
			local head = origin:FindFirstChild("Head")
			if not head then origin = origin.PrimaryPart
			else origin = head end
		end

		local bubbleDistance = distanceToBubbleOrigin(origin)

		if bubbleDistance < NEAR_BUBBLE_DISTANCE then
			this:SetBillboardLODNear(billboardGui)
		elseif bubbleDistance >= NEAR_BUBBLE_DISTANCE and bubbleDistance < MAX_BUBBLE_DISTANCE then
			this:SetBillboardLODDistant(billboardGui)
		else
			this:SetBillboardLODVeryFar(billboardGui)
		end
	end

	function this:CameraCFrameChanged()
		for index, value in pairs(this.CharacterSortedMsg:GetData()) do
			local playerBillboardGui = value["BillboardGui"]
			if playerBillboardGui then this:SetBillboardGuiLOD(playerBillboardGui, index) end
		end
	end

	function this:CreateBubbleText(message)
		local bubbleText = Instance.new("TextLabel")
		bubbleText.Name = "BubbleText"
		bubbleText.BackgroundTransparency = 1
		bubbleText.Position = UDim2.new(0,CHAT_BUBBLE_WIDTH_PADDING/2,0,0)
		bubbleText.Size = UDim2.new(1,-CHAT_BUBBLE_WIDTH_PADDING,1,0)
		bubbleText.Font = CHAT_BUBBLE_FONT
		bubbleText.TextWrapped = true
		bubbleText.FontSize = CHAT_BUBBLE_FONT_SIZE
		bubbleText.Text = message
		bubbleText.Visible = false

		return bubbleText
	end

	function this:CreateSmallTalkBubble(chatBubbleType)
		local smallTalkBubble = this.ScalingChatBubbleWithTail[chatBubbleType]:Clone()
		smallTalkBubble.Name = "SmallTalkBubble"
		smallTalkBubble.Position = UDim2.new(0,0,1,-40)
		smallTalkBubble.Visible = false
		local text = this:CreateBubbleText("...")
		text.TextScaled = true
		text.TextWrapped = false
		text.Visible = true
		text.Parent = smallTalkBubble

		return smallTalkBubble
	end

	function this:UpdateChatLinesForOrigin(origin, currentBubbleYPos)
		local bubbleQueue = this.CharacterSortedMsg:Get(origin).Fifo
		local bubbleQueueSize = bubbleQueue:Size()
		local bubbleQueueData = bubbleQueue:GetData()
		if #bubbleQueueData <= 1 then return end

		for index = (#bubbleQueueData - 1), 1, -1 do
			local value = bubbleQueueData[index]
			local bubble = value.RenderBubble
			if not bubble then return end
			local bubblePos = bubbleQueueSize - index + 1

			if bubblePos > 1 then
				local tail = bubble:FindFirstChild("ChatBubbleTail")
				if tail then tail:Destroy() end
				local bubbleText = bubble:FindFirstChild("BubbleText")
				if bubbleText then bubbleText.TextTransparency = 0.5 end
			end

			local udimValue = UDim2.new( bubble.Position.X.Scale, bubble.Position.X.Offset,
										1, currentBubbleYPos - bubble.Size.Y.Offset - CHAT_BUBBLE_TAIL_HEIGHT )
			bubble:TweenPosition(udimValue, Enum.EasingDirection.Out, Enum.EasingStyle.Bounce, 0.1, true)
			currentBubbleYPos = currentBubbleYPos - bubble.Size.Y.Offset - CHAT_BUBBLE_TAIL_HEIGHT
		end
	end

	function this:DestroyBubble(bubbleQueue, bubbleToDestroy)
		if not bubbleQueue then return end
		if bubbleQueue:Empty() then return end

		local bubble = bubbleQueue:Front().RenderBubble
		if not bubble then
			bubbleQueue:PopFront()
		 	return
		end

		spawn(function()
			while bubbleQueue:Front().RenderBubble ~= bubbleToDestroy do
				wait()
			end

			bubble = bubbleQueue:Front().RenderBubble

			local timeBetween = 0
			local bubbleText = bubble:FindFirstChild("BubbleText")
			local bubbleTail = bubble:FindFirstChild("ChatBubbleTail")

			while bubble and bubble.ImageTransparency < 1 do
				timeBetween = wait()
				if bubble then
					local fadeAmount = timeBetween * CHAT_BUBBLE_FADE_SPEED
					bubble.ImageTransparency = bubble.ImageTransparency + fadeAmount
					if bubbleText then bubbleText.TextTransparency = bubbleText.TextTransparency + fadeAmount end
					if bubbleTail then bubbleTail.ImageTransparency = bubbleTail.ImageTransparency + fadeAmount end
				end
			end

			if bubble then
				bubble:Destroy()
				bubbleQueue:PopFront()
			end
		end)
	end

	function this:CreateChatLineRender(instance, line, onlyCharacter, fifo)
		if not instance then return end

		if not this.CharacterSortedMsg:Get(instance)["BillboardGui"] then
			this:CreateBillboardGuiHelper(instance, onlyCharacter)
		end

		local billboardGui = this.CharacterSortedMsg:Get(instance)["BillboardGui"]
		if billboardGui then
			local chatBubbleRender = this.ChatBubbleWithTail[line.BubbleColor]:Clone()
			chatBubbleRender.Visible = false
			local bubbleText = this:CreateBubbleText(line.Message)

			bubbleText.Parent = chatBubbleRender
			chatBubbleRender.Parent = billboardGui.BillboardFrame

			line.RenderBubble = chatBubbleRender

			local currentTextBounds = TextService:GetTextSize(bubbleText.Text, CHAT_BUBBLE_FONT_SIZE_INT, CHAT_BUBBLE_FONT,
																Vector2.new(BILLBOARD_MAX_WIDTH, BILLBOARD_MAX_HEIGHT))
			local bubbleWidthScale = math.max((currentTextBounds.x + CHAT_BUBBLE_WIDTH_PADDING)/BILLBOARD_MAX_WIDTH, 0.1)
			local numOflines = (currentTextBounds.y/CHAT_BUBBLE_FONT_SIZE_INT)

			-- prep chat bubble for tween
			chatBubbleRender.Size = UDim2.new(0,0,0,0)
			chatBubbleRender.Position = UDim2.new(0.5,0,1,0)

			local newChatBubbleOffsetSizeY = numOflines * CHAT_BUBBLE_LINE_HEIGHT

			chatBubbleRender:TweenSizeAndPosition(UDim2.new(bubbleWidthScale, 0, 0, newChatBubbleOffsetSizeY),
												 	UDim2.new( (1-bubbleWidthScale)/2, 0, 1, -newChatBubbleOffsetSizeY),
												 	Enum.EasingDirection.Out, Enum.EasingStyle.Elastic, 0.1, true,
												 	function() bubbleText.Visible = true end)

			-- todo: remove when over max bubbles
			this:SetBillboardGuiLOD(billboardGui, line.Origin)
			this:UpdateChatLinesForOrigin(line.Origin, -newChatBubbleOffsetSizeY)

			delay(line.BubbleDieDelay, function()
				this:DestroyBubble(fifo, chatBubbleRender)
			end)
		end
	end

	local testLabel = Instance.new('TextLabel')
	function isLabelTextAllowed(message)
		--There exists an internal filter that filters out some profanity. It does this silently if you try to set text of an object.
		--Here we check if the message is going to be filtered by applying it and comparing it.
		testLabel.Text = message
		return (testLabel.Text == message)
	end

	function this:OnPlayerChatMessage(chatType, sourcePlayer, message, targetPlayer)
		if not this:BubbleChatEnabled() then return end

		-- eliminate display of commands
		if string.sub(message, 1, 1) == '/' then return end

		local localPlayer = PlayersService.LocalPlayer
		local fromOthers = localPlayer ~= nil and sourcePlayer ~= localPlayer

		-- annihilate chats made by blocked or muted players
		if blockingUtility:IsPlayerBlockedByUserId(sourcePlayer.UserId) or blockingUtility:IsPlayerMutedByUserId(sourcePlayer.UserId) then return end

		-- remove messages that are filtered from the default gui text filter
		if not isLabelTextAllowed(message) then return end

		local luaChatType = ChatType.PLAYER_CHAT
		if chatType == Enum.PlayerChatType.Team then
			luaChatType = ChatType.PLAYER_TEAM_CHAT
		elseif chatType == Enum.PlayerChatType.All then
			luaChatType = ChatType.PLAYER_GAME_CHAT
		elseif chatType == Enum.PlayerChatType.Whisper then
			luaChatType = ChatType.PLAYER_WHISPER_CHAT
		end

		local safeMessage = this:SanitizeChatLine(message)

		local line = createPlayerChatLine(chatType, sourcePlayer, safeMessage, not fromOthers)

		if sourcePlayer and line.Origin then
			local fifo = this.CharacterSortedMsg:Get(line.Origin).Fifo
			fifo:PushBack(line)
			--Game chat (badges) won't show up here
			this:CreateChatLineRender(sourcePlayer.Character, line, true, fifo)
		end
	end

	function this:OnGameChatMessage(origin, message, color)
		local localPlayer = PlayersService.LocalPlayer
		local fromOthers = localPlayer ~= nil and (localPlayer.Character ~= origin)

		local bubbleColor = BubbleColor.WHITE

		if color == Enum.ChatColor.Blue then bubbleColor = BubbleColor.BLUE
		elseif color == Enum.ChatColor.Green then bubbleColor = BubbleColor.GREEN
		elseif color == Enum.ChatColor.Red then bubbleColor = BubbleColor.RED end

		local safeMessage = this:SanitizeChatLine(message)
		local line = createGameChatLine(origin, safeMessage, not fromOthers, bubbleColor)

		this.CharacterSortedMsg:Get(line.Origin).Fifo:PushBack(line)
		this:CreateChatLineRender(origin, line, false, this.CharacterSortedMsg:Get(line.Origin).Fifo)
	end

	function this:BubbleChatEnabled()
		return PlayersService.BubbleChat
	end

	function this:CameraChanged(prop)
		if prop == "CoordinateFrame" then
			this:CameraCFrameChanged()
		end
	end

	-- setup to datamodel connections
	PlayersService.PlayerChatted:connect(function(chatType, player, message, targetPlayer) this:OnPlayerChatMessage(chatType, player, message, targetPlayer) end)
	ChatService.Chatted:connect(function(origin, message, color) this:OnGameChatMessage(origin, message, color) end)

	local cameraChangedCon = nil
	if game.Workspace.CurrentCamera then
		cameraChangedCon = game.Workspace.CurrentCamera.Changed:connect(function(prop) this:CameraChanged(prop) end)
	end
	game.Workspace.Changed:connect(function(prop)
		if prop == "CurrentCamera" then
			if cameraChangedCon then cameraChangedCon:disconnect() end
			if game.Workspace.CurrentCamera then
				cameraChangedCon = game.Workspace.CurrentCamera.Changed:connect(function(prop) this:CameraChanged(prop) end)
			end
		end
	end)
end


local isClient = false
local success = pcall(function() isClient = game:GetService("RunService"):IsClient()end)

-- init only if we have a simulation going
if isClient or not success then
	createChatOutput()
end
