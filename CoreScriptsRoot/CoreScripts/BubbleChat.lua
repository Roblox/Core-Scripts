--[[
	// FileName: BubbleChat.lua
	// Written by: jeditkacheff
	// Description: Code for rendering bubble chat
]]

--[[ SERVICES ]]
local RunService = game:GetService('RunService')
local CoreGuiService = game:GetService('CoreGui')
local PlayersService = game:GetService('Players')
local DebrisService = game:GetService('Debris')
local GuiService = game:GetService('GuiService')
local StarterGui = game:GetService('StarterGui')
local ChatService = game:GetService("Chat")
local Settings = settings()
local GameOptions = Settings["Game Options"]
--[[ END OF SERVICES ]]

--[[ SCRIPT VARIABLES ]]
local ROBLOXNAME = "(ROBLOX)"
local ELIPSES = "..."
local CchMaxChatMessageLength = 128 -- max chat message length, including null terminator and elipses.
local CchMaxChatMessageLengthExclusive = CchMaxChatMessageLength - string.len(ELIPSES) - 1
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

	function this:Size()
		return #this.data
	end

	function this:Empty()
		return this:Size() <= 0
	end

	function this:PopFront()
		table.remove(this.data)
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
		if not this.data[key] then
			this.data[key] = createCharacterChats()
		end
		return this.data[key]
	end

	function this:GetData()
		return this.data
	end

	return this
end

local function createChatLine(chatType, message, startTime, bubbleColor, isLocalPlayer)
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
	this.Message = message
	this.StartTime = startTime
	this.BubbleDieDelay = this:ComputeBubbleLifetime(message, isLocalPlayer)
	this.BubbleColor = bubbleColor
	this.IsLocalPlayer = isLocalPlayer

	return this
end

local function createPlayerChatLine(chatType, player, message, startTime, isLocalPlayer)
	local this = createChatLine(chatType, message, startTime, BubbleColor.WHITE, isLocalPlayer)

	if player then
		this.User = player.Name
		this.Origin = player.Character
	end

	this.HistoryDieDelay = 60

	return this
end

local function createGameChatLine(origin, message, startTime, isLocalPlayer, bubbleColor)
	local this = createChatLine(origin and ChatType.PLAYER_GAME_CHAT or ChatType.BOT_CHAT, message, startTime, bubbleColor, isLocalPlayer)
	this.Origin = origin

	return this
end

function CreateChatBubbleMain(filePrefix)
	local chatBubbleMain = Instance.new("ImageLabel")
	chatBubbleMain.Name = "ChatBubble"
	chatBubbleMain.ScaleType = Enum.ScaleType.Slice
	chatBubbleMain.SliceCenter = Rect.new(5,5,15,15)
	chatBubbleMain.Image = "rbxasset://textures/" .. tostring(filePrefix) .. ".png"
	chatBubbleMain.BackgroundTransparency = 1
	chatBubbleMain.BorderSizePixel = 0
	chatBubbleMain.Size = UDim2.new(1.0, 0, 1.0, 0)
	chatBubbleMain.Position = UDim2.new(0,0,0,-30)

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

function createChatBubbleWithTail(filePrefix, position, size)
	local chatBubbleMain = CreateChatBubbleMain(filePrefix)
	
	local chatBubbleTail = createChatBubbleTail(position, size)
	chatBubbleTail.Parent = chatBubbleMain

	return chatBubbleMain
end

function createScaledChatBubbleWithTail(filePrefix, frameScaleSize, position)
	local chatBubbleMain = CreateChatBubbleMain(filePrefix)
	
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

function createCharacterChats()
	local this = {}
	this.IsVisible = false
	this.IsMoving = false

	this.Fifo = createFifo()
	this.BillboardGui = nil

	return this
end

local function createChatOutput()
	local kMaxTextSize = 16
	local kMaxCharsInline  = 20
	local MaxChatBubblesPerPlayer = 10
	local MaxChatLinesPerBubble = 5

	local this = {}
	this.Time = 0
	this.Players = nil
	this.ChatBubble = {}
	this.ChatBubbleWithTail = {}
	this.ScalingChatBubbleWithTail = {}
	this.ChatPlaceholder = {}
	this.CharacterSortedMsg = createMap()
	this.Fifo = createFifo()

	-- init chat bubble tables
	local function initChatBubbleType(chatBubbleType, fileName, imposterFileName, isInset)
		this.ChatBubble[chatBubbleType] = CreateChatBubbleMain(fileName)
		this.ChatBubbleWithTail[chatBubbleType] = createChatBubbleWithTail(fileName, UDim2.new(0.5, -14, 1, isInset and -1 or 0), UDim2.new(0, 30, 0, 14))
		this.ScalingChatBubbleWithTail[chatBubbleType] = createScaledChatBubbleWithTail(fileName, 0.5, UDim2.new(-0.5, 0, 0, isInset and -1 or 0))

		this.ChatPlaceholder[chatBubbleType] = createChatImposter(imposterFileName, "chatBubble_bot_notifyGray_dotDotDot", isInset and -0.12 or -0.05)
	end

	initChatBubbleType(BubbleColor.WHITE,	"ui/dialog_white",	"ui/chatBubble_white_notify_bkg", 	false)
	initChatBubbleType(BubbleColor.BLUE,	"ui/dialog_blue",	"ui/chatBubble_blue_notify_bkg",	true)
	initChatBubbleType(BubbleColor.RED,		"ui/dialog_red",	"ui/chatBubble_red_notify_bkg",		true)
	initChatBubbleType(BubbleColor.GREEN,	"ui/dialog_green",	"ui/chatBubble_green_notify_bkg",	true)

	function this:AcceleratedBubbleDecay(chatLine, wallStep, isMoving, isVisible)
		if chatLine.IsLocalPlayer and isMoving then
			chatLine.BubbleDieDelay = chatLine.BubbleDieDelay - (3 * wallStep) -- effectively quarters delay time.
		elseif isVisible then
			chatLine.BubbleDieDelay = chatLine.BubbleDieDelay - wallStep -- effectively halves delay time.
		end
	end

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
		billboardGui.Size = UDim2.new(3,0,3.6,0)
		billboardGui.Parent = CoreGuiService

		return billboardGui
	end

	function this:CreateBillboardGuiHelper(instance, onlyCharacter)
		if not this.CharacterSortedMsg:Get(instance)["BillboardGui"] then
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

	function this:RemoveOldest()
		this.Fifo:PopFront()
	end

	function this:RemoveExpired()
		local bRemovedSomething = false
		local settingChildren = Settings:GetChildren()
		local maxBubblesPerPlayer = math.min(GameOptions.BubbleChatMaxBubbles, MaxChatBubblesPerPlayer)

		if not this.Fifo:Empty() then
			-- fifo contains only PlayerChatLine objects, its only using generic ChatLine for use in helper functions
			local playerChatLine = this.Fifo:Front()
			if (playerChatLine.HistoryDieDelay + playerChatLine.StartTime) < this.Time then
				this.Fifo:PopFront()
				bRemovedSomething = true
			end
		end

		for index, value in pairs(this.CharacterSortedMsg:GetData()) do
			local playerFifo = value.Fifo

			if not playerFifo:Empty() then
				local chatLine = playerFifo:Front()
				if ((chatLine.BubbleDieDelay + chatLine.StartTime) < self.Time) or (playerFifo:Size() > maxBubblesPerPlayer) then
					playerFifo:PopFront()
					bRemovedSomething = true
				end
			end

			-- remove if empty
			if playerFifo:Empty() then
				local billboardGui = value["BillboardGui"]
				if billboardGui then
					billboardGui.Parent = nil
					billboardGui:Destroy() -- todo: I think this is right, not sure
				end

				this.CharacterSortedMsg:Erase(index)
			end
		end

		return bRemovedSomething
	end

	function this:OnHeartbeat(step)
		this.Time = this.Time + step

		--[[for index, value in pairs(this.CharacterSortedMsg:GetData()) do
			local playerFifo = value.Fifo
			for i = 1, playerFifo:Size() do
				this:AcceleratedBubbleDecay(playerFifo:Get(i), step, value.IsMoving, value.IsVisible)
			end
		end

		local isRemoving = false
		repeat
			isRemoving = this:RemoveExpired()
		until(isRemoving == false)]]
	end

	function this:CreateChatLineRender(instance, line, onlyCharacter)
		if not this.CharacterSortedMsg:Get(instance)["BillboardGui"] then
			this:CreateBillboardGuiHelper(instance, onlyCharacter)
		end

		local billboardGui = this.CharacterSortedMsg:Get(instance)["BillboardGui"]

		print("line.ChatType is", line.ChatType)
		if line.ChatType == Enum.PlayerChatType.All then
			local chatBubbleRender = this.ChatBubbleWithTail[BubbleColor.WHITE]:Clone()
			chatBubbleRender.Size = UDim2.new(22, 25, 3, 0)
			chatBubbleRender.Position = UDim2.new()
			chatBubbleRender.Parent = billboardGui
		end

	end

	function this:OnPlayerChatMessage(chatType, sourcePlayer, message, targetPlayer)
		if not this:BubbleChatEnabled() then return end

		-- eliminate display of emotes
		if string.find(message, "/e ") == 1 or string.find(message, "/emote ") == 1 then return end

		while this.Fifo:Size() > GameOptions.ChatScrollLength do
			this:RemoveOldest()
		end

		local localPlayer = PlayersService.LocalPlayer
		local fromOthers = localPlayer ~= nil and sourcePlayer ~= localPlayer

		local luaChatType = ChatType.PLAYER_CHAT
		if chatType == Enum.PlayerChatType.Team then
			luaChatType = ChatType.PLAYER_TEAM_CHAT 
		elseif chatType == Enum.PlayerChatType.All then
			luaChatType = ChatType.PLAYER_GAME_CHAT
		elseif chatType == Enum.PlayerChatType.Whisper then
			luaChatType = ChatType.PLAYER_WHISPER_CHAT
		end

		local safeMessage = this:SanitizeChatLine(message)

		local line = createPlayerChatLine(chatType, sourcePlayer, safeMessage, self.Time, not fromOthers)
		this.Fifo:PushBack(line)

		this.CharacterSortedMsg:Get(line.Origin).Fifo:PushBack(line)

		if sourcePlayer then
			--Game chat (badges) won't show up here
			this:CreateChatLineRender(sourcePlayer.Character, line, true)
		end
	end

	function this:OnGameChatMessage(origin, message, color)
		if not this:BubbleChatEnabled() then return end

		local localPlayer = PlayersService.LocalPlayer
		local fromOthers = localPlayer ~= nil and (localPlayer.Character ~= origin)

		message = ChatService:FilterStringForPlayerAsync(message, localPlayer)

		local bubbleColor = BubbleColor.WHITE

		if color == Enum.ChatColor.Blue then bubbleColor = BubbleColor.BLUE
		elseif color == Enum.ChatColor.Green then bubbleColor = BubbleColor.GREEN
		elseif color == Enum.ChatColor.Red then bubbleColor = BubbleColor.RED end

		local safeMessage = this:SanitizeChatLine(message)
		local line = createGameChatLine(origin, safeMessage, time, not fromOthers, bubbleColor)
	
		this.CharacterSortedMsg:Get(line.Origin).Fifo:PushBack(line)
		this:CreateChatLineRender(origin, line, false)
	end

	function this:BubbleChatEnabled()
		return true
		--return PlayersService.BubbleChat
	end

	-- setup to datamodel connections

	RunService.Heartbeat:connect(function(step) this:OnHeartbeat(step) end)
	PlayersService.PlayerChatted:connect(function(chatType, player, message, targetPlayer) this:OnPlayerChatMessage(chatType, player, message, targetPlayer) end)
	ChatService.Chatted:connect(function(origin, message, color) this:OnGameChatMessage(origin, message, color) end)

	-- todo: return modified api table
	return this
end

local test = createChatOutput()

