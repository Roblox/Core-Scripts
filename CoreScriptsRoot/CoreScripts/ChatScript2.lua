--[[
	// FileName: ChatScript.lua
	// Written by: SolarCrane
	// Description: Code for lua side chat on ROBLOX.
]]

--[[ CONSTANTS ]]

-- NOTE: IF YOU WANT TO USE THIS CHAT SCRIPT IN YOUR OWN GAME:
-- 1) COPY THE CONTENTS OF THIS FILE INTO A LOCALSCRIPT THAT YOU MADE IN STARTERGUI
-- 2) SET THE FOLLOWING TWO VARIABLES TO TRUE
-- 3) CONFIGURE YOUR PLACE ON THE WEBSITE TO USE BUBBLE-CHAT
local FORCE_CHAT_GUI = false
local NON_CORESCRIPT_MODE = false
-- 4) (OPTIONAL) PUT THE FOLLOWING LINE IN A SERVER SCRIPT TO MAKE CHAT PERSIST THROUGH RESPAWNING
--  game:GetService('StarterGui').ResetPlayerGuiOnSpawn = false
---------------------------------

local MESSAGES_FADE_OUT_TIME = 30
local MAX_BLOCKLIST_SIZE = 50
local MAX_UDIM_SIZE = 2^15 - 1

local CHAT_COLORS =
{
	Color3.new(253/255, 41/255, 67/255), -- BrickColor.new("Bright red").Color,
	Color3.new(1/255, 162/255, 255/255), -- BrickColor.new("Bright blue").Color,
	Color3.new(2/255, 184/255, 87/255), -- BrickColor.new("Earth green").Color,
	BrickColor.new("Bright violet").Color,
	BrickColor.new("Bright orange").Color,
	BrickColor.new("Bright yellow").Color,
	BrickColor.new("Light reddish violet").Color,
	BrickColor.new("Brick yellow").Color,
}

local ADMIN_LIST = {
    ['68465808'] = true, -- IMightBeLying
    ['32345429'] = true, -- Rbadam
    ['48453004'] = true, -- Adamintygum
    ['57705391'] = true, -- androidtest
    ['58491921'] = true, -- RobloxFrenchie
    ['29341155'] = true, -- JacksSmirkingRevenge
    ['60629145'] = true, -- Mandaari
    ['6729993'] = true, -- vaiobot
    ['9804369'] = true, -- Goddessnoob
    ['67906358'] = true, -- Thr33pakShak3r
    ['41101356'] = true, -- effward
    ['29667843'] = true, -- Blockhaak
    ['26076267'] = true, -- Drewbda
    ['65171466'] = true, -- triptych999
    ['264635'] = true, -- Tone
    ['59257875'] = true, -- fasterbuilder19
    ['30068452'] = true, -- Zeuxcg
    ['53627251'] = true, -- concol2
    ['56449'] = true, -- ReeseMcBlox
    ['7210880'] = true, -- Jeditkacheff
    ['35187797'] = true, -- ChiefJustus
    ['21964644'] = true, -- Ellissar
    ['63971416'] = true, -- geekndestroy
    ['111627'] = true, -- Noob007
    ['482238'] = true, -- Limon
    ['39861325'] = true, -- hawkington
    ['32580099'] = true, -- Tabemono
    ['504316'] = true, -- BrightEyes
    ['35825637'] = true, -- Monsterinc3D
    ['55311255'] = true, -- IsolatedEvent
    ['48988254'] = true, -- CountOnConnor
    ['357346'] = true, -- Scubasomething
    ['28969907'] = true, -- OnlyTwentyCharacters
    ['17707636'] = true, -- LordRugdumph
    ['26714811'] = true, -- bellavour
    ['24941'] = true, -- david.baszucki
    ['13057592'] = true, -- ibanez2189
    ['66766775'] = true, -- ConvexHero
    ['13268404'] = true, -- Sorcus
    ['26065068'] = true, -- DeeAna00
    ['4108667'] = true, -- TheLorekt
    ['605367'] = true, -- MSE6
    ['28350010'] = true, -- CorgiParade
    ['1636196'] = true, -- Varia
    ['27861308'] = true, -- 4runningwolves
    ['26699190'] = true, -- pulmoesflor
    ['9733258'] = true, -- Olive71
    ['2284059'] = true, -- groundcontroll2
    ['28080592'] = true, -- GuruKrish
    ['28137935'] = true, -- Countvelcro
    ['25964666'] = true, -- IltaLumi
    ['31221099'] = true, -- juanjuan23
    ['13965343'] = true, -- OstrichSized
    ['541489'] = true, -- jackintheblox
    ['38324232'] = true, -- SlingshotJunkie
    ['146569'] = true, -- gordonrox24
    ['61666252'] = true, -- sharpnine
    ['25540124'] = true, -- Motornerve
    ['29044576'] = true, -- watchmedogood
    ['49626068'] = true, -- jmargh
    ['57352126'] = true, -- JayKorean
    ['25682044'] = true, -- Foyle
    ['1113299'] = true, -- MajorTom4321
    ['30598693'] = true, -- supernovacaine
    ['1311'] = true, -- FFJosh
    ['23603273'] = true, -- Sickenedmonkey
    ['28568151'] = true, -- Doughtless
    ['8298697'] = true, -- KBUX
    ['39871898'] = true, -- totallynothere
    ['57708043'] = true, -- ErzaStar
    ['22'] = true, -- Keith
    ['2430782'] = true, -- Chro
    ['29373363'] = true, -- SolarCrane
    ['29116915'] = true, -- GloriousSalt
    ['6783205'] = true, -- UristMcSparks
    ['62155769'] = true, -- ITOlaurEN
    ['24162607'] = true, -- Malcomso
    ['66692187'] = true, -- HeySeptember
    ['80254'] = true, -- Stickmasterluke
    ['66093461'] = true, -- chefdeletat
    ['62968051'] = true, -- windlight13
    ['80119'] = true, -- Stravant
    ['61890000'] = true, -- imaginationsensation
    ['916'] = true, -- Matt Dusek
    ['4550725'] = true, -- CrimmsonGhost
    ['59737068'] = true, -- Mcrtest
    ['5600283'] = true, -- Seranok
    ['48656806'] = true, -- maxvee
    ['48656806'] = true, -- Coatp0cketninja
    ['35231885'] = true, -- Screenme
    ['55958416'] = true, -- b1tsh1ft
    ['51763936'] = true, -- ConvexRumbler
    ['59638684'] = true, -- mpliner476
    ['44231609'] = true, -- Totbl
    ['16906083'] = true, -- Aquabot8
    ['23984372'] = true, -- grossinger
    ['13416513'] = true, -- Merely
    ['27416429'] = true, -- CDakkar
    ['46526337'] = true, -- logitek00
    ['21969613'] = true, -- Siekiera
    ['39488230'] = true, -- Robloxkidsaccount
    ['60425210'] = true, -- flotsamthespork
    ['16732061'] = true, -- Soggoth
    ['33904052'] = true, -- Phil
    ['39882028'] = true, -- OrcaSparkles
    ['62060462'] = true, -- skullgoblin
    ['29044708'] = true, -- RickROSStheB0SS
    ['15782010'] = true, -- ArgonPirate
    ['6949935'] = true, -- NobleDragon
    ['41256555'] = true, -- Squidcod
    ['16150324'] = true, -- Raeglyn
    ['24419770'] = true, -- Xerolayne
    ['20396599'] = true, -- Robloxsai
    ['55579189'] = true, -- Briarroze
    ['21641566'] = true, -- hawkeyebandit
    ['39871292'] = true, -- DapperBuffalo
    ['48725400'] = true, -- Vukota
    ['60880618'] = true, -- swiftstone
    ['8736269'] = true, -- Gemlocker
    ['17199995'] = true, -- Tarabyte
    ['6983145'] = true, -- Timobius
    ['20048521'] = true, -- Tobotrobot
    ['1644345'] = true, -- Foster008
    ['33067469'] = true, -- Twberg
    ['57741156'] = true, -- DarthVaden
    ['51164101'] = true, -- Khanovich
    ['61380399'] = true, -- oLEFTo
    ['39876101'] = true, -- CodeWriter
    ['23598967'] = true, -- VladTheFirst
    ['39299049'] = true, -- Phaedre
    ['39855185'] = true, -- gorroth
    ['61004766'] = true, -- jynj1984
    ['10261020'] = true, -- RoboYZ
    ['44564747'] = true, -- ZodiacZak
}
--[[ END OF CONSTANTS ]]

--[[ SERVICES ]]
local RunService = game:GetService('RunService')
local CoreGuiService = game:GetService('CoreGui')
local PlayersService = game:GetService('Players')
local DebrisService = game:GetService('Debris')
local GuiService = game:GetService('GuiService')
local InputService = game:GetService('UserInputService')
local StarterGui = game:GetService('StarterGui')
--[[ END OF SERVICES ]]

--[[ SCRIPT VARIABLES ]]

-- I am not fond of waiting at the top of the script here...
while PlayersService.LocalPlayer == nil do PlayersService.ChildAdded:wait() end
local Player = PlayersService.LocalPlayer
-- GuiRoot will act as the top-node for parenting GUIs
local GuiRoot = nil
if NON_CORESCRIPT_MODE then
	GuiRoot = Instance.new("ScreenGui")
	GuiRoot.Name = "RobloxGui"
	GuiRoot.Parent = Player:WaitForChild('PlayerGui')
else
	GuiRoot = CoreGuiService:WaitForChild('RobloxGui')
end
--[[ END OF SCRIPT VARIABLES ]]

local function GetBlockedUsersFlag()
	local blockUserFlagSuccess, blockUserFlagFlagValue = pcall(function() return settings():GetFFlag("BlockUsersInLuaChat") end)
	return blockUserFlagSuccess and blockUserFlagFlagValue == true
end

local function GetUsePlayerInGroupFlag()
	local flagSuccess, flagValue = pcall(function() return settings():GetFFlag("UsePlayerInGroupLuaChat") end)
	return flagSuccess and flagValue == true
end

local Util = {}
do
	-- Check if we are running on a touch device
	function Util.IsTouchDevice()
		local touchEnabled = false
		pcall(function() touchEnabled = InputService.TouchEnabled end)
		return touchEnabled
	end

	function Util.Create(instanceType)
		return function(data)
			local obj = Instance.new(instanceType)
			for k, v in pairs(data) do
				if type(k) == 'number' then
					v.Parent = obj
				else
					obj[k] = v
				end
			end
			return obj
		end
	end

	function Util.Clamp(low, high, input)
		return math.max(low, math.min(high, input))
	end

	function Util.Linear(t, b, c, d)
		if t >= d then return b + c end

		return c*t/d + b
	end

	function Util.EaseOutQuad(t, b, c, d)
		if t >= d then return b + c end

		t = t/d;
		return -c * t*(t-2) + b
	end

	function Util.EaseInOutQuad(t, b, c, d)
		if t >= d then return b + c end

		t = t / (d/2);
		if (t < 1) then return c/2*t*t + b end;
		t = t - 1;
		return -c/2 * (t*(t-2) - 1) + b;
	end

	function Util.PropertyTweener(instance, prop, start, final, duration, easingFunc, cbFunc)
		local this = {}
		this.StartTime = tick()
		this.EndTime = this.StartTime + duration
		this.Cancelled = false

		local finished = false
		local percentComplete = 0
		spawn(function()
			local now = tick()
			while now < this.EndTime and instance do
				if this.Cancelled then
					return
				end
				instance[prop] = easingFunc(now - this.StartTime, start, final - start, duration)
				percentComplete = Util.Clamp(0, 1, (now - this.StartTime) / duration)
				RunService.RenderStepped:wait()
				now = tick()
			end
			if this.Cancelled == false and instance then
				instance[prop] = final
				finished = true
				percentComplete = 1
				if cbFunc then
					cbFunc()
				end
			end
		end)

		function this:GetPercentComplete()
			return percentComplete
		end

		function this:IsFinished()
			return finished
		end

		function this:Cancel()
			this.Cancelled = true
		end

		return this
	end

	function Util.Signal()
		local sig = {}

		local mSignaler = Instance.new('BindableEvent')

		local mArgData = nil
		local mArgDataCount = nil

		function sig:fire(...)
			mArgData = {...}
			mArgDataCount = select('#', ...)
			mSignaler:Fire()
		end

		function sig:connect(f)
			if not f then error("connect(nil)", 2) end
			return mSignaler.Event:connect(function()
				f(unpack(mArgData, 1, mArgDataCount))
			end)
		end

		function sig:wait()
			mSignaler.Event:wait()
			assert(mArgData, "Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.")
			return unpack(mArgData, 1, mArgDataCount)
		end

		return sig
	end

	function Util.DisconnectEvent(conn)
		if conn then
			conn:disconnect()
		end
		return nil
	end

	function Util.SetGUIInsetBounds(x, y)
		local success, _ = pcall(function() GuiService:SetGlobalGuiInset(0, x, 0, y) end)
		if not success then
			pcall(function() GuiService:SetGlobalSizeOffsetPixel(-x, -y) end) -- Legacy GUI-offset function
		end
	end

	local baseUrl = game:GetService("ContentProvider").BaseUrl:lower()
	baseUrl = string.gsub(baseUrl,"/m.","/www.") --mobile site does not work for this stuff!
	function Util.GetSecureApiBaseUrl()
		local secureApiUrl = baseUrl
		secureApiUrl = string.gsub(secureApiUrl,"http","https")
		secureApiUrl = string.gsub(secureApiUrl,"www","api")
		return secureApiUrl
	end

	function Util.GetPlayerByName(playerName)
		-- O(n), may be faster if I store a reverse hash from the players list; can't trust FindFirstChild in PlayersService because anything can be parented to there.
		local lowerName = string.lower(playerName)
		for _, player in pairs(PlayersService:GetPlayers()) do
			if string.lower(player.Name) == lowerName then
				return player
			end
		end
		return nil -- Found no player
	end

	local adminCache = {}
	function Util.IsPlayerAdminAsync(player)
		local userId = player and player.userId
		if userId then
			if GetUsePlayerInGroupFlag() then
				if adminCache[userId] == nil then
					local isAdmin = false
					-- Many things can error is the IsInGroup check
					pcall(function()
						isAdmin = player:IsInGroup(1200769)
					end)
					adminCache[userId] = isAdmin
				end
				return adminCache[userId]
			end
			return ADMIN_LIST[tostring(userId)]
		end
		return false
	end

	local function GetNameValue(pName)
		local value = 0
		for index = 1, #pName do
			local cValue = string.byte(string.sub(pName, index, index))
			local reverseIndex = #pName - index + 1
			if #pName%2 == 1 then
				reverseIndex = reverseIndex - 1
			end
			if reverseIndex%4 >= 2 then
				cValue = -cValue
			end
			value = value + cValue
		end
		return value
	end

	function Util.ComputeChatColor(pName)
		return CHAT_COLORS[(GetNameValue(pName) % #CHAT_COLORS) + 1]
	end

	-- This is a memo-izing function
	local testLabel = Instance.new('TextLabel')
	testLabel.TextWrapped = true;
	testLabel.Position = UDim2.new(1,0,1,0)
	testLabel.Parent = GuiRoot -- Note: We have to parent it to check TextBounds
	-- The TextSizeCache table looks like this Text->Font->sizeBounds->FontSize
	local TextSizeCache = {}
	function Util.GetStringTextBounds(text, font, fontSize, sizeBounds)
		-- If no sizeBounds are specified use some huge number
		sizeBounds = sizeBounds or false
		if not TextSizeCache[text] then
			TextSizeCache[text] = {}
		end
		if not TextSizeCache[text][font] then
			TextSizeCache[text][font] = {}
		end
		if not TextSizeCache[text][font][sizeBounds] then
			TextSizeCache[text][font][sizeBounds] = {}
		end
		if not TextSizeCache[text][font][sizeBounds][fontSize] then
			testLabel.Text = text
			testLabel.Font = font
			testLabel.FontSize = fontSize
			if sizeBounds then
				testLabel.TextWrapped = true;
				testLabel.Size = sizeBounds
			else
				testLabel.TextWrapped = false;
			end
			TextSizeCache[text][font][sizeBounds][fontSize] = testLabel.TextBounds
		end
		return TextSizeCache[text][font][sizeBounds][fontSize]
	end
end

local SelectChatModeEvent = Util.Signal()
local SelectPlayerEvent = Util.Signal()

local function CreateChatMessage()
	local this = {}
	this.FadeRoutines = {}

	function this:OnResize()
		-- Nothing!
	end

	function this:FadeIn()
		local gui = this:GetGui()
		if gui then
			gui.Visible = true
		end
	end

	function this:FadeOut()
		local gui = this:GetGui()
		if gui then
			gui.Visible = false
		end
	end

	function this:GetGui()
		return this.Container
	end

	function this:Destroy()
		if this.Container ~= nil then
			this.Container:Destroy()
			this.Container = nil
		end
		if this.FadeRoutines then
			for _, routine in pairs(this.FadeRoutines) do
				routine:Cancel()
			end
			this.FadeRoutines = {}
		end
	end

	return this
end

local function CreateSystemChatMessage(settings, chattedMessage)
	local this = CreateChatMessage()

	this.Settings = settings
	this.chatMessage = chattedMessage

	function this:OnResize(containerSize)
		if this.Container and this.ChatMessage then
			this.Container.Size = UDim2.new(1,0,0,1000)
			local textHeight = this.ChatMessage.TextBounds.Y
			this.Container.Size = UDim2.new(1,0,0,textHeight + 1)
			return textHeight
		end
	end

	function this:FadeIn()
		local gui = this:GetGui()
		if gui then
			gui.Visible = true
			for _, routine in pairs(this.FadeRoutines) do
				routine:Cancel()
			end
			this.FadeRoutines = {}
			local tweenableObjects = {
				this.ChatMessage;
			}
			for _, object in pairs(tweenableObjects) do
				object.TextTransparency = 0;
				object.TextStrokeTransparency = this.Settings.TextStrokeTransparency;
			end
		end
	end

	function this:FadeOut(instant)
		local gui = this:GetGui()
		if gui then
			if instant then
				gui.Visible = false
			else
				local tweenableObjects = {
					this.ChatMessage;
				}
				for _, object in pairs(tweenableObjects) do
					table.insert(this.FadeRoutines, Util.PropertyTweener(object, 'TextTransparency', object.TextTransparency, 1, 1, Util.Linear))
					table.insert(this.FadeRoutines, Util.PropertyTweener(object, 'TextStrokeTransparency', object.TextStrokeTransparency, 1, 0.85, Util.Linear))
				end
			end
		end
	end

	local function CreateMessageGuiElement()
		local systemMesasgeDisplayText = this.chatMessage or ""
		local systemMessageSize = Util.GetStringTextBounds(systemMesasgeDisplayText, this.Settings.Font, this.Settings.FontSize, UDim2.new(0, 400, 0, 1000))

		local container = Util.Create'Frame'
		{
			Name = 'MessageContainer';
			Position = UDim2.new(0, 0, 0, 0);
			ZIndex = 1;
			BackgroundColor3 = Color3.new(0, 0, 0);
			BackgroundTransparency = 1;
		};

			local chatMessage = Util.Create'TextLabel'
			{
				Name = 'SystemChatMessage';
				Position = UDim2.new(0, 0, 0, 0);
				Size = UDim2.new(1, 0, 1, 0);
				Text = systemMesasgeDisplayText;
				ZIndex = 1;
				BackgroundColor3 = Color3.new(0, 0, 0);
				BackgroundTransparency = 1;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Top;
				TextWrapped = true;
				TextColor3 = this.Settings.DefaultMessageTextColor;
				FontSize = this.Settings.FontSize;
				Font = this.Settings.Font;
				TextStrokeColor3 = this.Settings.TextStrokeColor;
				TextStrokeTransparency = this.Settings.TextStrokeTransparency;
				Parent = container;
			};

		container.Size = UDim2.new(1, 0, 0, systemMessageSize.Y + 1);
		this.Container = container
		this.ChatMessage = chatMessage
	end

	CreateMessageGuiElement()

	return this
end

local function CreatePlayerChatMessage(settings, playerChatType, sendingPlayer, chattedMessage, receivingPlayer)
	local this = CreateChatMessage()

	this.Settings = settings
	this.PlayerChatType = playerChatType
	this.SendingPlayer = sendingPlayer
	this.RawMessageContent = chattedMessage
	this.ReceivingPlayer = receivingPlayer
	this.ReceivedTime = tick()

	this.Neutral = this.SendingPlayer and this.SendingPlayer.Neutral or true
	this.TeamColor = this.SendingPlayer and this.SendingPlayer.TeamColor or BrickColor.new("White")

	function this:OnResize(containerSize)
		if this.Container and this.ChatMessage then
			this.Container.Size = UDim2.new(1,0,0,1000)
			local textHeight = this.ChatMessage.TextBounds.Y
			this.Container.Size = UDim2.new(1,0,0,textHeight + 1)
			return textHeight
		end
	end

	function this:FormatMessage()
		local result = ""
		if this.RawMessageContent then
			local message = this.RawMessageContent
			result = message
		end
		return result
	end

	function this:FormatChatType()
		if this.PlayerChatType then
			if this.PlayerChatType == Enum.PlayerChatType.All then
				--return "[All]"
			elseif this.PlayerChatType == Enum.PlayerChatType.Team then
				return "[Team]"
			elseif this.PlayerChatType == Enum.PlayerChatType.Whisper then
				-- nothing!
			end
		end
	end

	function this:FormatPlayerNameText()
		local playerName = ""
		-- If we are sending a whisper to someone, then we should show their name
		if this.PlayerChatType == Enum.PlayerChatType.Whisper and this.SendingPlayer and this.SendingPlayer == Player then
			playerName = (this.ReceivingPlayer and this.ReceivingPlayer.Name or "")
		else
			playerName = (this.SendingPlayer and this.SendingPlayer.Name or "")
		end
		return "[" ..  playerName .. "]:"
	end

	function this:FadeIn()
		local gui = this:GetGui()
		if gui then
			gui.Visible = true
			for _, routine in pairs(this.FadeRoutines) do
				routine:Cancel()
			end
			this.FadeRoutines = {}
			local tweenableObjects = {
					this.WhisperToText;
					this.WhisperFromText;
					this.ChatModeButton;
					this.UserNameButton;
					this.ChatMessage;
				}
			for _, object in pairs(tweenableObjects) do
				object.TextTransparency = 0;
				object.TextStrokeTransparency = this.Settings.TextStrokeTransparency;
				object.Active = true
			end
			if this.UserNameDot then
				this.UserNameDot.ImageTransparency = 0
			end
		end
	end

	function this:FadeOut(instant)
		local gui = this:GetGui()
		if gui then
			if instant then
				gui.Visible = false
			else
				local tweenableObjects = {
					this.WhisperToText;
					this.WhisperFromText;
					this.ChatModeButton;
					this.UserNameButton;
					this.ChatMessage;
				}
				for _, object in pairs(tweenableObjects) do
					table.insert(this.FadeRoutines, Util.PropertyTweener(object, 'TextTransparency', object.TextTransparency, 1, 1, Util.Linear))
					table.insert(this.FadeRoutines, Util.PropertyTweener(object, 'TextStrokeTransparency', object.TextStrokeTransparency, 1, 0.85, Util.Linear))
					object.Active = false
				end
				if this.UserNameDot then
					table.insert(this.FadeRoutines, Util.PropertyTweener(this.UserNameDot, 'ImageTransparency', this.UserNameDot.ImageTransparency, 1, 1, Util.Linear))
				end
			end
		end
	end

	function this:Destroy()
		if this.Container ~= nil then
			this.Container:Destroy()
			this.Container = nil
		end
		this.ClickedOnModeConn = Util.DisconnectEvent(this.ClickedOnModeConn)
		this.ClickedOnPlayerConn = Util.DisconnectEvent(this.ClickedOnPlayerConn)
	end

	local function CreateMessageGuiElement()
		local toMesasgeDisplayText = "To "
		local toMessageSize = Util.GetStringTextBounds(toMesasgeDisplayText, this.Settings.Font, this.Settings.FontSize)
		local fromMesasgeDisplayText = "From "
		local fromMessageSize = Util.GetStringTextBounds(fromMesasgeDisplayText, this.Settings.Font, this.Settings.FontSize)
		local chatTypeDisplayText = this:FormatChatType()
		local chatTypeSize = chatTypeDisplayText and Util.GetStringTextBounds(chatTypeDisplayText, this.Settings.Font, this.Settings.FontSize) or Vector2.new(0,0)
		local playerNameDisplayText = this:FormatPlayerNameText()
		local playerNameSize = Util.GetStringTextBounds(playerNameDisplayText, this.Settings.Font, this.Settings.FontSize)

		local singleSpaceSize = Util.GetStringTextBounds(" ", this.Settings.Font, this.Settings.FontSize)
		local numNeededSpaces = math.ceil(playerNameSize.X / singleSpaceSize.X) + 1
		local chatMessageDisplayText = string.rep(" ", numNeededSpaces) .. this:FormatMessage()
		local chatMessageSize = Util.GetStringTextBounds(chatMessageDisplayText, this.Settings.Font, this.Settings.FontSize, UDim2.new(0, 400 - 5 - playerNameSize.X, 0, 1000))


		local playerColor = this.Settings.DefaultMessageTextColor
		if this.SendingPlayer then
			if this.PlayerChatType == Enum.PlayerChatType.Whisper then
				if this.SendingPlayer == Player and this.ReceivingPlayer then
					playerColor = Util.ComputeChatColor(this.ReceivingPlayer.Name)
				else
					playerColor = Util.ComputeChatColor(this.SendingPlayer.Name)
				end
			else
				if this.SendingPlayer.Neutral then
					playerColor = Util.ComputeChatColor(this.SendingPlayer.Name)
				else
					playerColor = this.SendingPlayer.TeamColor.Color
				end
			end
		end

		local container = Util.Create'Frame'
		{
			Name = 'MessageContainer';
			Position = UDim2.new(0, 0, 0, 0);
			ZIndex = 1;
			BackgroundColor3 = Color3.new(0, 0, 0);
			BackgroundTransparency = 1;
		};
			local xOffset = 0

			if this.SendingPlayer and this.SendingPlayer == Player and this.PlayerChatType == Enum.PlayerChatType.Whisper then
				local whisperToText = Util.Create'TextLabel'
				{
					Name = 'WhisperTo';
					Position = UDim2.new(0, 0, 0, 0);
					Size = UDim2.new(0, toMessageSize.X, 0, toMessageSize.Y);
					Text = toMesasgeDisplayText;
					ZIndex = 1;
					BackgroundColor3 = Color3.new(0, 0, 0);
					BackgroundTransparency = 1;
					TextXAlignment = Enum.TextXAlignment.Left;
					TextYAlignment = Enum.TextYAlignment.Top;
					TextWrapped = true;
					TextColor3 = this.Settings.DefaultMessageTextColor;
					FontSize = this.Settings.FontSize;
					Font = this.Settings.Font;
					TextStrokeColor3 = this.Settings.TextStrokeColor;
					TextStrokeTransparency = this.Settings.TextStrokeTransparency;
					Parent = container;
				};
				xOffset = xOffset + toMessageSize.X
				this.WhisperToText = whisperToText
			elseif this.SendingPlayer and this.SendingPlayer ~= Player and this.PlayerChatType == Enum.PlayerChatType.Whisper then
				local whisperFromText = Util.Create'TextLabel'
				{
					Name = 'WhisperFromText';
					Position = UDim2.new(0, 0, 0, 0);
					Size = UDim2.new(0, fromMessageSize.X, 0, fromMessageSize.Y);
					Text = fromMesasgeDisplayText;
					ZIndex = 1;
					BackgroundColor3 = Color3.new(0, 0, 0);
					BackgroundTransparency = 1;
					TextXAlignment = Enum.TextXAlignment.Left;
					TextYAlignment = Enum.TextYAlignment.Top;
					TextWrapped = true;
					TextColor3 = this.Settings.DefaultMessageTextColor;
					FontSize = this.Settings.FontSize;
					Font = this.Settings.Font;
					TextStrokeColor3 = this.Settings.TextStrokeColor;
					TextStrokeTransparency = this.Settings.TextStrokeTransparency;
					Parent = container;
				};
				xOffset = xOffset + fromMessageSize.X
				this.WhisperFromText = whisperFromText
			else
				local userNameDot = Util.Create'ImageLabel'
				{
					Name = "UserNameDot";
					Size = UDim2.new(0, 14, 0, 14);
					BackgroundTransparency = 1;
					Position = UDim2.new(0, 0, 0, math.max(0, ((playerNameSize and playerNameSize.Y or 0) - 14)/2) + 2);
					BorderSizePixel = 0;
					Image = "rbxasset://textures/ui/chat_teamButton.png";
					ImageColor3 = playerColor;
					Parent = container;
				}
				xOffset = xOffset + 14 + 3
				this.UserNameDot = userNameDot
			end
		if chatTypeDisplayText then
			local chatModeButton = Util.Create(Util.IsTouchDevice() and 'TextLabel' or 'TextButton')
			{
				Name = 'ChatMode';
				BackgroundTransparency = 1;
				ZIndex = 2;
				Text = chatTypeDisplayText;
				TextColor3 = this.Settings.DefaultMessageTextColor;
				Position = UDim2.new(0, xOffset, 0, 0);
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Top;
				FontSize = this.Settings.FontSize;
				Font = this.Settings.Font;
				Size = UDim2.new(0, chatTypeSize.X, 0, chatTypeSize.Y);
				TextStrokeColor3 = this.Settings.TextStrokeColor;
				TextStrokeTransparency = this.Settings.TextStrokeTransparency;
				Parent = container
			}
			if chatModeButton:IsA('TextButton') then
				this.ClickedOnModeConn = chatModeButton.MouseButton1Click:connect(function()
					SelectChatModeEvent:fire(this.PlayerChatType)
				end)
			end
			if this.PlayerChatType == Enum.PlayerChatType.Team then
				chatModeButton.TextColor3 = playerColor
			end
			xOffset = xOffset + chatTypeSize.X + 1
			this.ChatModeButton = chatModeButton
		end
			local userNameButton = Util.Create(Util.IsTouchDevice() and 'TextLabel' or 'TextButton')
			{
				Name = 'PlayerName';
				BackgroundTransparency = 1;
				ZIndex = 2;
				Text = playerNameDisplayText;
				TextColor3 = playerColor;
				Position = UDim2.new(0, xOffset, 0, 0);
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Top;
				FontSize = this.Settings.FontSize;
				Font = this.Settings.Font;
				Size = UDim2.new(0, playerNameSize.X, 0, playerNameSize.Y);
				TextStrokeColor3 = this.Settings.TextStrokeColor;
				TextStrokeTransparency = this.Settings.TextStrokeTransparency;
				Parent = container
			}
			if userNameButton:IsA('TextButton') then
				this.ClickedOnPlayerConn = userNameButton.MouseButton1Click:connect(function()
					if this.PlayerChatType == Enum.PlayerChatType.Whisper and this.SendingPlayer == Player and this.ReceivingPlayer then
						SelectPlayerEvent:fire(this.ReceivingPlayer)
					else
						SelectPlayerEvent:fire(this.SendingPlayer)
					end
				end)
			end

			local chatMessage = Util.Create'TextLabel'
			{
				Name = 'ChatMessage';
				Position = UDim2.new(0, xOffset, 0, 0);
				Size = UDim2.new(1, -xOffset, 1, 0);
				Text = chatMessageDisplayText;
				ZIndex = 1;
				BackgroundColor3 = Color3.new(0, 0, 0);
				BackgroundTransparency = 1;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Top;
				TextWrapped = true;
				TextColor3 = this.Settings.DefaultMessageTextColor;
				FontSize = this.Settings.FontSize;
				Font = this.Settings.Font;
				TextStrokeColor3 = this.Settings.TextStrokeColor;
				TextStrokeTransparency = this.Settings.TextStrokeTransparency;
				Parent = container;
			};
			-- Check if they got moderated and put up a real message instead of Label
			if chatMessage.Text == 'Label' and chatMessageDisplayText ~= 'Label' then
				chatMessage.Text = string.rep(" ", numNeededSpaces) .. '[Content Deleted]'
			end
			if this.SendingPlayer and Util.IsPlayerAdminAsync(this.SendingPlayer) then
				chatMessage.TextColor3 = this.Settings.AdminTextColor
			end
			chatMessage.Size = chatMessage.Size + UDim2.new(0, 0, 0, chatMessage.TextBounds.Y);

		container.Size = UDim2.new(1, 0, 0, math.max(chatMessageSize.Y + 1, userNameButton.Size.Y.Offset + 1));
		this.Container = container
		this.ChatMessage = chatMessage
		this.UserNameButton = userNameButton
	end

	CreateMessageGuiElement()

	return this
end

local function CreateChatBarWidget(settings)
	local this = {}

	-- MessageModes: {All, Team, Whisper}
	this.MessageMode = 'All'
	this.TargetWhisperPlayer = nil
	this.Settings = settings

	this.ChatBarGainedFocusEvent = Util.Signal()
	this.ChatBarLostFocusEvent = Util.Signal()
	this.ChatCommandEvent = Util.Signal() -- Signal Signatue: success, actionType, [captures]
	this.ChatErrorEvent = Util.Signal() -- Signal Signatue: success, actionType, [captures]

	-- This function while lets string.find work case-insensitively without clobbering the case of the captures
	local function nocase(s)
      s = string.gsub(s, "%a", function (c)
            return string.format("[%s%s]", string.lower(c),
                                           string.upper(c))
          end)
      return s
    end

	this.ChatMatchingRegex =
	{
		[function(chatBarText) return string.find(chatBarText, nocase("^/w ") .. "(%w+)") end] = "Whisper";
		[function(chatBarText) return string.find(chatBarText, nocase("^/whisper ") .. "(%w+)") end] = "Whisper";

		[function(chatBarText) return string.find(chatBarText, "^%%") end] = "Team";
		[function(chatBarText) return string.find(chatBarText, "^%(TEAM%)") end] = "Team";
		[function(chatBarText) return string.find(chatBarText, nocase("^/t")) end] = "Team";
		[function(chatBarText) return string.find(chatBarText, nocase("^/team")) end] = "Team";

		[function(chatBarText) return string.find(chatBarText, nocase("^/a")) end] = "All";
		[function(chatBarText) return string.find(chatBarText, nocase("^/all")) end] = "All";
		[function(chatBarText) return string.find(chatBarText, nocase("^/s")) end] = "All";
		[function(chatBarText) return string.find(chatBarText, nocase("^/say")) end] = "All";

		[function(chatBarText) return string.find(chatBarText, nocase("^/e")) end] = "Emote";
		[function(chatBarText) return string.find(chatBarText, nocase("^/emote")) end] = "Emote";

		[function(chatBarText) return string.find(chatBarText, "^/%?") end] = "Help";
		[function(chatBarText) return string.find(chatBarText, nocase("^/help")) end] = "Help";

		[function(chatBarText) return string.find(chatBarText, nocase("^/ignore ") .. "(%w+)") end] = "Block";
		[function(chatBarText) return string.find(chatBarText, nocase("^/block ") .. "(%w+)") end] = "Block";

		[function(chatBarText) return string.find(chatBarText, nocase("^/unignore ") .. "(%w+)") end] = "Unblock";
		[function(chatBarText) return string.find(chatBarText, nocase("^/unblock ") .. "(%w+)") end] = "Unblock";
	}

	local ChatModesDict =
	{
		['Whisper'] = 'Whisper';
		['Team'] = 'Team';
		['All'] = 'All';
		[Enum.PlayerChatType.Whisper] = 'Whisper';
		[Enum.PlayerChatType.Team] = 'Team';
		[Enum.PlayerChatType.All] = 'All';
	}

	local function TearDownEvents()
		-- Note: This is a new api so we need to pcall it
		pcall(function() GuiService:RemoveSpecialKey(Enum.SpecialKey.ChatHotkey) end)
		this.SpecialKeyPressedConn = Util.DisconnectEvent(this.SpecialKeyPressedConn)
		this.ClickToChatButtonConn = Util.DisconnectEvent(this.ClickToChatButtonConn)
		this.ChatBarFocusLostConn = Util.DisconnectEvent(this.ChatBarFocusLostConn)
		this.ChatBarLostFocusConn = Util.DisconnectEvent(this.ChatBarLostFocusConn)
		this.SelectChatModeConn = Util.DisconnectEvent(this.SelectChatModeConn)
		this.SelectPlayerConn = Util.DisconnectEvent(this.SelectPlayerConn)
		this.FocusChatBarInputBeganConn = Util.DisconnectEvent(this.FocusChatBarInputBeganConn)
		this.InputBeganConn = Util.DisconnectEvent(this.InputBeganConn)
	end

	local function HookUpEvents()
		TearDownEvents() -- Cleanup old events

		pcall(function()
			-- ChatHotKey is '/'
			GuiService:AddSpecialKey(Enum.SpecialKey.ChatHotkey)
			this.SpecialKeyPressedConn = GuiService.SpecialKeyPressed:connect(function(key)
				if key == Enum.SpecialKey.ChatHotkey then
					this:FocusChatBar()
				end
			end)
		end)

		if this.ClickToChatButton then this.ClickToChatButtonConn = this.ClickToChatButton.MouseButton1Click:connect(function() this:FocusChatBar() end) end

		if this.ChatBar then this.ChatBarFocusLostConn = this.ChatBar.FocusLost:connect(function(...) this.ChatBarLostFocusEvent:fire(...) end) end

		if this.ChatBarLostFocusEvent then this.ChatBarLostFocusConn = this.ChatBarLostFocusEvent:connect(function(...) this:OnChatBarFocusLost(...) end) end

		this.SelectChatModeConn = SelectChatModeEvent:connect(function(chatType)
			this:SetMessageMode(chatType)
			this:FocusChatBar()
		end)

		this.SelectPlayerConn = SelectPlayerEvent:connect(function(chatPlayer)
			this.TargetWhisperPlayer = chatPlayer
			this:SetMessageMode("Whisper")
			this:FocusChatBar()
		end)

		this.InputBeganConn = InputService.InputBegan:connect(function(inputObject)
			if inputObject.KeyCode == Enum.KeyCode.Escape then
				-- Clear text when they press escape
				this:SetChatBarText("")
			end
		end)
	end

	function this:CoreGuiChanged(coreGuiType, enabled)
		if coreGuiType == Enum.CoreGuiType.Chat or coreGuiType == Enum.CoreGuiType.All then
			if enabled then
				HookUpEvents()
			else
				TearDownEvents()
			end
			if this.ChatBarContainer then
				this.ChatBarContainer.Visible = enabled
			end
		end
		if NON_CORESCRIPT_MODE then
			this.ChatBarContainer.Visible = false
		end
	end

	function this:IsAChatMode(mode)
		return ChatModesDict[mode] ~= nil
	end

	function this:ProcessChatBarModes(requireWhitespaceAfterChatMode)
		local matchedAChatCommand = false
		if this.ChatBar then
			local chatBarText = this:SanitizeInput(this:GetChatBarText())
			for regexFunc, actionType in pairs(this.ChatMatchingRegex) do
				local start, finish, capture = regexFunc(chatBarText)
				if start and finish then
					-- The following line is for whether or not to try setting the chatmode as-you-type
					-- versus when you press enter.
					local whitespaceAfterSlashCommand = string.find(string.sub(chatBarText, finish+1, finish+1), "%s")
					if (not requireWhitespaceAfterChatMode and finish == #chatBarText) or whitespaceAfterSlashCommand then
						if this:IsAChatMode(actionType) then
							if actionType == "Whisper" then
								local targetPlayer = capture and Util.GetPlayerByName(capture)
								if targetPlayer then --and targetPlayer ~= Player then
									this.TargetWhisperPlayer = targetPlayer
									-- start from two over to eat the space or tab character after the slash command
									this:SetChatBarText(string.sub(chatBarText, finish + 2))
									this:SetMessageMode(actionType)
									this.ChatCommandEvent:fire(true, actionType, capture)
								else
									-- This is an indirect way of detecting if they used enter to close submit this chat
									if not requireWhitespaceAfterChatMode then
										this:SetChatBarText("")
										this.ChatCommandEvent:fire(false, actionType, capture)
									end
								end
							else
								-- start from two over to eat the space or tab character after the slash command
								this:SetChatBarText(string.sub(chatBarText, finish + 2))
								this:SetMessageMode(actionType)
								this.ChatCommandEvent:fire(true, actionType, capture)
							end
						elseif actionType == "Emote" then
							-- You can only emote to everyone.
							this:SetMessageMode('All')
						elseif not requireWhitespaceAfterChatMode then -- Some non-chat related command
							if actionType == "Help" then
								this:SetChatBarText("") -- Clear the chat so we don't send /? to everyone
							end
							this.ChatCommandEvent:fire(true, actionType, capture)
						end
						-- should we break here since we already matched a slash command or keep going?
						matchedAChatCommand = true
					end
				end
			end
		end
		return matchedAChatCommand
	end

	local previousText = ""
	function this:OnChatBarTextChanged()
		if not Util.IsTouchDevice() then
			this:ProcessChatBarModes(true)
			local newText = this:GetChatBarText()
			if #newText > this.Settings.MaxCharactersInMessage then
				local fixedText = ""
				-- This is a hack to deal with the bug that holding down a key for repeated input doesn't trigger the textChanged event
				if #newText == #previousText + 1 then
					fixedText = string.sub(previousText, 1, this.Settings.MaxCharactersInMessage)
				else
					fixedText = string.sub(newText, 1, this.Settings.MaxCharactersInMessage)
				end
				this:SetChatBarText(fixedText)
				previousText = fixedText
			else
				previousText = newText
			end
		end
	end

	function this:GetChatBarText()
		return this.ChatBar and this.ChatBar.Text or ""
	end

	function this:SetChatBarText(newText)
		if this.ChatBar then
			this.ChatBar.Text = newText
		end
	end

	function this:GetMessageMode()
		return this.MessageMode
	end

	function this:SetMessageMode(newMessageMode)
		newMessageMode = ChatModesDict[newMessageMode]

		local chatRecipientText = "[" .. (this.TargetWhisperPlayer and this.TargetWhisperPlayer.Name or "") .. "]"
		if this.MessageMode ~= newMessageMode or (newMessageMode == 'Whisper' and this.ChatModeText and chatRecipientText ~= this.ChatModeText.Text) then
			if this.ChatModeText then
				this.MessageMode = newMessageMode
				if newMessageMode == 'Whisper' then
					local chatRecipientTextBounds = Util.GetStringTextBounds(chatRecipientText, this.ChatModeText.Font, this.ChatModeText.FontSize)

					this.ChatModeText.TextColor3 = this.Settings.WhisperTextColor
					this.ChatModeText.Text = chatRecipientText
					this.ChatModeText.Size = UDim2.new(0, chatRecipientTextBounds.X, 1, 0)
				elseif newMessageMode == 'Team' then
					local chatTeamText = '[Team]'
					local chatTeamTextBounds = Util.GetStringTextBounds(chatTeamText, this.ChatModeText.Font, this.ChatModeText.FontSize)

					this.ChatModeText.TextColor3 = this.Settings.TeamTextColor
					this.ChatModeText.Text = "[Team]"
					this.ChatModeText.Size = UDim2.new(0, chatTeamTextBounds.X, 1, 0)
				else
					this.ChatModeText.Text = ""
					this.ChatModeText.Size = UDim2.new(0, 0, 1, 0)
				end
				if this.ChatBar then
					local offset = this.ChatModeText.Size.X.Offset + this.ChatModeText.Position.X.Offset
					this.ChatBar.Size = UDim2.new(1, -offset - 5, 1, 0)
					this.ChatBar.Position = UDim2.new(0, offset + 5, 0, 0)
				end
			end
		end
	end

	function this:FocusChatBar()
		if this.ChatBar then
			this.ChatBar.Visible = true
			this.ChatBar:CaptureFocus()
			if self.ClickToChatButton then
				self.ClickToChatButton.Visible = false
			end
			if this.ChatModeText then
				this.ChatModeText.Visible = true
			end
			this.ChatBarChangedConn = Util.DisconnectEvent(this.ChatBarChangedConn)
			this.ChatBarChangedConn = this.ChatBar.Changed:connect(function(prop)
				if prop == "Text" then
					this:OnChatBarTextChanged()
				end
			end)
			if Util.IsTouchDevice() then
				this:SetMessageMode('All') -- Don't remember message mode on mobile devices
			else
				-- Use a count to check for double backspace out of a chatmode
				local count = 0
				this.FocusChatBarInputBeganConn = Util.DisconnectEvent(this.FocusChatBarInputBeganConn)
				this.FocusChatBarInputBeganConn = InputService.InputBegan:connect(function(inputObj)
					if inputObj.KeyCode == Enum.KeyCode.Backspace and this:GetChatBarText() == "" then
						if count == 0 then
							count = count + 1
						else
							this:SetMessageMode('All')
						end
					else
						count = 0
					end
				end)
			end
			this.ChatBarGainedFocusEvent:fire()
		end
	end

	function this:SanitizeInput(input)
		local sanitizedInput = input
		-- Chomp the whitespace at the front and end of the string
		-- TODO: maybe only chop off the front space if there are more than a few?
		local _, _, capture = string.find(sanitizedInput, "^%s*(.*)%s*$")
		sanitizedInput = capture or ""

		return sanitizedInput
	end

	function this:OnChatBarFocusLost(enterPressed)
		if self.ChatBar then
			self.ChatBar.Visible = false
			if enterPressed then
				local didMatchSlashCommand = this:ProcessChatBarModes(false)
				local cText = this:SanitizeInput(this:GetChatBarText())
				if cText ~= "" then
					-- For now we will let any slash command go through, NOTE: these will show up in bubble-chat
					--if not didMatchSlashCommand and string.sub(cText,1,1) == "/" then
					--	this.ChatCommandEvent:fire(false, "Unknown", cText)
					--else
						local currentMessageMode = this:GetMessageMode()
						-- {All, Team, Whisper}
						if currentMessageMode == 'Team' then
							if Player and Player.Neutral == true then
								this.ChatErrorEvent:fire("You are not in any team.")
							else
								pcall(function() PlayersService:TeamChat(cText) end)
							end
						elseif currentMessageMode == 'Whisper' then
							if this.TargetWhisperPlayer then
								if this.TargetWhisperPlayer == Player then
									this.ChatErrorEvent:fire("You cannot send a whisper to yourself.")
								else
									pcall(function() PlayersService:WhisperChat(cText, this.TargetWhisperPlayer) end)
								end
							else
								this.ChatErrorEvent:fire("Invalid whisper target.")
							end
						elseif currentMessageMode == 'All' then
							pcall(function() PlayersService:Chat(cText) end)
						else
							spawn(function() error("ChatScript: Unknown Message Mode of " .. tostring(currentMessageMode)) end)
						end
					--end
				end
				this:SetChatBarText("")
			end
		end
		if self.ClickToChatButton then
			self.ClickToChatButton.Visible = true
		end
		if this.ChatModeText then
			this.ChatModeText.Visible = false
		end
		this.ChatBarChangedConn = Util.DisconnectEvent(this.ChatBarChangedConn)
		this.FocusChatBarInputBeganConn = Util.DisconnectEvent(this.FocusChatBarInputBeganConn)
	end

	local function CreateChatBar()
		local chatBarContainer = Util.Create'Frame'
		{
			Name = 'ChatBarContainer';
			Position = UDim2.new(0, 0, 1, 0);
			Size = UDim2.new(1, 0, 0, 20);
			ZIndex = 1;
			BackgroundColor3 = Color3.new(0, 0, 0);
			BackgroundTransparency = 0.25;
		};
			local clickToChatButton = Util.Create'TextButton'
			{
				Name = 'ClickToChat';
				Position = UDim2.new(0,9,0,0);
				Size = UDim2.new(1, -9, 1, 0);
				BackgroundTransparency = 1;
				ZIndex = 3;
				Text = 'To chat click here or press "/" key';
				TextColor3 = this.Settings.GlobalTextColor;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Top;
				Font = Enum.Font.SourceSansBold;
				FontSize = Enum.FontSize.Size18;
				Parent = chatBarContainer;
			}
			local chatBar = Util.Create'TextBox'
			{
				Name = 'ChatBar';
				Position = UDim2.new(0, 9, 0, 0);
				Size = UDim2.new(1, -9, 1, 0);
				Text = "";
				ZIndex = 1;
				BackgroundColor3 = Color3.new(0, 0, 0);
				Active = false;
				BackgroundTransparency = 1;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Top;
				TextColor3 = this.Settings.GlobalTextColor;
				Font = Enum.Font.SourceSansBold;
				FontSize = Enum.FontSize.Size18;
				ClearTextOnFocus = false;
				Visible = not Util.IsTouchDevice();
				Parent = chatBarContainer;
			}
			local chatModeText = Util.Create'TextButton'
			{
				Name = 'ChatModeText';
				Position = UDim2.new(0, 9, 0, 0);
				Size = UDim2.new(1, -9, 1, 0);
				BackgroundTransparency = 1;
				ZIndex = 2;
				Text = '';
				TextColor3 = this.Settings.WhisperTextColor;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Top;
				Font = Enum.Font.SourceSansBold;
				FontSize = Enum.FontSize.Size18;
				Parent = chatBarContainer;
			}

		this.ChatBarContainer = chatBarContainer
		this.ClickToChatButton = clickToChatButton
		this.ChatBar = chatBar
		this.ChatModeText = chatModeText
		this.ChatBarContainer.Parent = GuiRoot
	end

	CreateChatBar()
	return this
end

local function CreateChatWindowWidget(settings)
	local this = {}
	this.Settings = settings
	this.Chats = {}
	this.BackgroundVisible = false
	this.ChatsVisible = false

	this.ChatWindowPagingConn = nil

	local lastMoveTime = tick()
	local lastEnterTime = tick()
	local lastLeaveTime = tick()

	local lastFadeOutTime = 0
	local lastFadeInTime = 0
	local lastChatActivity = 0

	local FadeLock = false

	local function PointInChatWindow(pt)
		local point0 = this.ChatContainer.AbsolutePosition
		local point1 = point0 + this.ChatContainer.AbsoluteSize
		return point0.X <= pt.X and point1.X >= pt.X and
		       point0.Y <= pt.Y and point1.Y >= pt.Y
	end

	function this:IsHovering()
		if this.ChatContainer and this.LastMousePosition then
			return PointInChatWindow(this.LastMousePosition)
		end
		return false
	end

	function this:SetFadeLock(lock)
		FadeLock = lock
	end

	function this:GetFadeLock()
		return FadeLock
	end

	function this:SetCanvasPosition(newCanvasPosition)
		if this.ScrollingFrame then
			local maxSize = Vector2.new(math.max(0, this.ScrollingFrame.CanvasSize.X.Offset - this.ScrollingFrame.AbsoluteWindowSize.X),
			                            math.max(0, this.ScrollingFrame.CanvasSize.Y.Offset - this.ScrollingFrame.AbsoluteWindowSize.Y))
			this.ScrollingFrame.CanvasPosition = Vector2.new(Util.Clamp(0, maxSize.X, newCanvasPosition.X),
			                                                 Util.Clamp(0, maxSize.Y, newCanvasPosition.Y))
		end
	end

	function this:ScrollToBottom()
		if this.ScrollingFrame then
			this:SetCanvasPosition(Vector2.new(this.ScrollingFrame.CanvasPosition.X, this.ScrollingFrame.CanvasSize.Y.Offset))
		end
	end

	function this:FadeIn(duration, lockFade)
		if not FadeLock then
			duration = duration or 0.75
			-- fade in
			if this.BackgroundTweener then
				this.BackgroundTweener:Cancel()
			end
			lastFadeInTime = tick()
			lastChatActivity = tick()
			this.ScrollingFrame.ScrollingEnabled = true
			this.BackgroundTweener = Util.PropertyTweener(this.ChatContainer, 'BackgroundTransparency', this.ChatContainer.BackgroundTransparency, 0.7, duration, Util.Linear)
			this.BackgroundVisible = true
			this:FadeInChats()

			this.ChatWindowPagingConn = Util.DisconnectEvent(this.ChatWindowPagingConn)
			this.ChatWindowPagingConn = InputService.InputBegan:connect(function(inputObject)
				local key = inputObject.KeyCode
				if key == Enum.KeyCode.PageUp then
					this:SetCanvasPosition(this.ScrollingFrame.CanvasPosition - Vector2.new(0, this.ScrollingFrame.AbsoluteWindowSize.Y))
				elseif key == Enum.KeyCode.PageDown then
					this:SetCanvasPosition(this.ScrollingFrame.CanvasPosition + Vector2.new(0, this.ScrollingFrame.AbsoluteWindowSize.Y))
				elseif key == Enum.KeyCode.Home then
					this:SetCanvasPosition(Vector2.new(0, 0))
				elseif key == Enum.KeyCode.End then
					this:ScrollToBottom()
				end
			end)
		end
	end
	function this:FadeOut(duration, unlockFade)
		if not FadeLock then
			duration = duration or 0.75
			-- fade out
			if this.BackgroundTweener then
				this.BackgroundTweener:Cancel()
			end
			lastFadeOutTime = tick()
			lastChatActivity = tick()
			this.ScrollingFrame.ScrollingEnabled = false
			this.BackgroundTweener = Util.PropertyTweener(this.ChatContainer, 'BackgroundTransparency', this.ChatContainer.BackgroundTransparency, 1, duration, Util.Linear)
			this.BackgroundVisible = false

			this.ChatWindowPagingConn = Util.DisconnectEvent(this.ChatWindowPagingConn)
		end
	end

	function this:FadeInChats()
		if this.ChatsVisible == true then return end
		this.ChatsVisible = true
		for index, message in pairs(this.Chats) do
			message:FadeIn()
		end
	end

	function this:FadeOutChats()
		if this.ChatsVisible == false then return end
		this.ChatsVisible = false
		for index, message in pairs(this.Chats) do
			local messageGui = message:GetGui()
			local instant = false
			if messageGui and this.ScrollingFrame then
				-- If the chat is not in the visible frame then don't waste cpu cycles fading it out
				if messageGui.AbsolutePosition.Y > (this.ScrollingFrame.AbsolutePosition + this.ScrollingFrame.AbsoluteWindowSize).Y or
						messageGui.AbsolutePosition.Y + messageGui.AbsoluteSize.Y < this.ScrollingFrame.AbsolutePosition.Y then
					instant = true
				end
			end
			message:FadeOut(instant)
		end
	end

	local ResizeCount = 0
	function this:OnResize()
		ResizeCount = ResizeCount + 1
		local currentResizeCount = ResizeCount
		local isScrolledDown = this:IsScrolledDown()
		-- Unfortunately there is a race condition so we need this wait here.
		wait()
		if this.ScrollingFrame then
			if currentResizeCount ~= ResizeCount then return end
			local scrollingFrameAbsoluteSize = this.ScrollingFrame.AbsoluteWindowSize
			if scrollingFrameAbsoluteSize ~= nil and scrollingFrameAbsoluteSize.X > 0 and scrollingFrameAbsoluteSize.Y > 0 then
				local ySize = 0

				if this.ScrollingFrame then
					for index, message in pairs(this.Chats) do
						local newHeight = message:OnResize(scrollingFrameAbsoluteSize)
						if newHeight then
							local chatMessageElement = message:GetGui()
							if chatMessageElement then
								local chatMessageElementYSize = chatMessageElement.Size.Y.Offset
								chatMessageElement.Position = UDim2.new(0, 0, 0, ySize)
								ySize = ySize + chatMessageElementYSize
							end
						end
					end
				end
				if this.MessageContainer and this.ScrollingFrame then
					this.MessageContainer.Size = UDim2.new(
							this.MessageContainer.Size.X.Scale,
							this.MessageContainer.Size.X.Offset,
							0,
							ySize)
					this.MessageContainer.Position = UDim2.new(0, 0, 1, -this.MessageContainer.Size.Y.Offset)
					this.ScrollingFrame.CanvasSize = UDim2.new(this.ScrollingFrame.CanvasSize.X.Scale, this.ScrollingFrame.CanvasSize.X.Offset, this.ScrollingFrame.CanvasSize.Y.Scale, ySize)
				end
			end
			this:ScrollToBottom()
		end
	end

	function this:FilterMessage(playerChatType, sendingPlayer, chattedMessage, receivingPlayer)
		if chattedMessage and string.sub(chattedMessage, 1, 1) ~= '/' then
			return true
		end
		return false
	end

	function this:PushMessageIntoQueue(chatMessage, silently)
		table.insert(this.Chats, chatMessage)

		local isScrolledDown = this:IsScrolledDown()

		local chatMessageElement = chatMessage:GetGui()

		chatMessageElement.Parent = this.MessageContainer
		chatMessage:OnResize()
		local ySize = this.MessageContainer.Size.Y.Offset
		local chatMessageElementYSize = UDim2.new(0, 0, 0, chatMessageElement.Size.Y.Offset)

		chatMessageElement.Position = chatMessageElement.Position + UDim2.new(0, 0, 0, ySize)
		this.MessageContainer.Size = this.MessageContainer.Size + chatMessageElementYSize
		this.ScrollingFrame.CanvasSize = this.ScrollingFrame.CanvasSize + chatMessageElementYSize

		if this.Settings.MaxWindowChatMessages < #this.Chats then
			this:RemoveOldestMessage()
		end
		if isScrolledDown then
			this:ScrollToBottom()
		elseif not silently then
			-- Raise unread message alert!
		end

		if silently then
			chatMessage:FadeOut(true)
		else
			this:FadeInChats()
			lastChatActivity = tick()
		end

		-- NOTE: Sort of hacky, but if we are approaching the max 16 bit size
		-- we need to rebase y back to 0 which can be done with the resize function
		if ySize > (MAX_UDIM_SIZE / 2) then
			self:OnResize()
		end
	end

	function this:AddSystemChatMessage(chattedMessage, silently)
		local chatMessage = CreateSystemChatMessage(this.Settings, chattedMessage)
		this:PushMessageIntoQueue(chatMessage, silently)
	end

	function this:AddChatMessage(playerChatType, sendingPlayer, chattedMessage, receivingPlayer, silently)
		if this:FilterMessage(playerChatType, sendingPlayer, chattedMessage, receivingPlayer) then
			local chatMessage = CreatePlayerChatMessage(this.Settings, playerChatType, sendingPlayer, chattedMessage, receivingPlayer)
			this:PushMessageIntoQueue(chatMessage, silently)
		end
	end

	function this:RemoveOldestMessage()
		local oldestChat = this.Chats[1]
		if oldestChat then
			return this:RemoveChatMessage(oldestChat)
		end
	end

	function this:RemoveChatMessage(chatMessage)
		if chatMessage then
			for index, message in pairs(this.Chats) do
				if chatMessage == message then
					local guiObj = chatMessage:GetGui()
					if guiObj then
						local ySize = guiObj.Size.Y.Offset
						this.ScrollingFrame.CanvasSize = this.ScrollingFrame.CanvasSize - UDim2.new(0,0,0,ySize)
						-- Clamp the canvasposition
						this:SetCanvasPosition(this.ScrollingFrame.CanvasPosition)
						guiObj.Parent = nil
					end
					message:Destroy()
					return table.remove(this.Chats, index)
				end
			end
		end
	end

	function this:IsScrolledDown()
		if this.ScrollingFrame then
			local yCanvasSize = this.ScrollingFrame.CanvasSize.Y.Offset
			local yContainerSize = this.ScrollingFrame.AbsoluteWindowSize.Y
			local yScrolledPosition = this.ScrollingFrame.CanvasPosition.Y
			-- Check if the messages are at the bottom
			return yCanvasSize < yContainerSize or
			       yCanvasSize - yScrolledPosition <= yContainerSize + 5 -- a little wiggle room
		end
		return false
	end

	function this:CoreGuiChanged(coreGuiType, enabled)
		if coreGuiType == Enum.CoreGuiType.Chat or coreGuiType == Enum.CoreGuiType.All then
			if this.ChatContainer then
				this.ChatContainer.Visible = enabled
			end
		end
		-- If we are using bubble-chat then do not show chat window
		if this.ChatContainer and not PlayersService.ClassicChat then
			this.ChatContainer.Visible = false
		end
		if NON_CORESCRIPT_MODE then
			this.ChatContainer.Visible = true
		end
	end

	local function CreateChatWindow()
		local container = Util.Create'Frame'
		{
			Name = 'ChatWindowContainer';
			Size = UDim2.new(0.3, 0, 0.25, 0);
			Position = UDim2.new(0, 8, 0, 37);
			ZIndex = 1;
			BackgroundColor3 = Color3.new(0, 0, 0);
			BackgroundTransparency = 1;
		};
			local scrollingFrame = Util.Create'ScrollingFrame'
			{
				Name = 'ChatWindow';
				Size = UDim2.new(1, -4 - 10, 1, -20);
				CanvasSize = UDim2.new(1, -4 - 10, 0, 0);
				Position = UDim2.new(0, 10, 0, 10);
				ZIndex = 1;
				BackgroundColor3 = Color3.new(0, 0, 0);
				BackgroundTransparency = 1;
				BottomImage = "rbxasset://textures/ui/scroll-bottom.png";
				MidImage = "rbxasset://textures/ui/scroll-middle.png";
				TopImage = "rbxasset://textures/ui/scroll-top.png";
				ScrollBarThickness = 7;
				BorderSizePixel = 0;
				ScrollingEnabled = false;
				Parent = container;
			};
				local messageContainer = Util.Create'Frame'
				{
					Name = 'MessageContainer';
					Size = UDim2.new(1, -scrollingFrame.ScrollBarThickness - 1, 0, 0);
					Position = UDim2.new(0, 0, 1, 0);
					ZIndex = 1;
					BackgroundColor3 = Color3.new(0, 0, 0);
					BackgroundTransparency = 1;
					Parent = scrollingFrame
				};

		-- This is some trickery we are doing to make the first chat messages appear at the bottom and go towards the top.
		local function OnChatWindowResize(prop)
			if prop == 'AbsoluteSize' then
				messageContainer.Position = UDim2.new(0, 0, 1, -messageContainer.Size.Y.Offset)
			end
		end
		container.Changed:connect(function(prop) if prop == 'AbsoluteSize' then this:OnResize() end end)

		local function RobloxClientScreenSizeChanged(newSize)
			if container then
				-- Phone
				if newSize.X <= 640 then
					container.Size = UDim2.new(0.5,0,0.5,0) - container.Position
				-- Tablet
				elseif newSize.X <= 1024 then
					container.Size = UDim2.new(0.4,0,0.3,0) - container.Position
				-- Desktop
				else
					container.Size = UDim2.new(0.3,0,0.25,0) - container.Position
				end
			end
		end

		GuiRoot.Changed:connect(function(prop) if prop == "AbsoluteSize" then RobloxClientScreenSizeChanged(GuiRoot.AbsoluteSize) end end)
		RobloxClientScreenSizeChanged(GuiRoot.AbsoluteSize)

		messageContainer.Changed:connect(OnChatWindowResize)
		scrollingFrame.Changed:connect(OnChatWindowResize)

		this.ChatContainer = container
		this.ScrollingFrame = scrollingFrame
		this.MessageContainer = messageContainer
		this.ChatContainer.Parent = GuiRoot

		--- BACKGROUND FADING CODE ---
		-- This is so we don't accidentally fade out when we are scrolling and mess with the scrollbar.
		local dontFadeOutOnMouseLeave = false

		if Util:IsTouchDevice() then
			local touchCount = 0
			this.InputBeganConn = InputService.InputBegan:connect(function(inputObject)
				if inputObject.UserInputType == Enum.UserInputType.Touch and inputObject.UserInputState == Enum.UserInputState.Begin then
					if PointInChatWindow(Vector2.new(inputObject.Position.X, inputObject.Position.Y)) then
						touchCount = touchCount + 1
						dontFadeOutOnMouseLeave = true
					end
				end
			end)

			this.InputEndedConn = InputService.InputEnded:connect(function(inputObject)
				if inputObject.UserInputType == Enum.UserInputType.Touch and inputObject.UserInputState == Enum.UserInputState.End then
					local endedCount = touchCount
					wait(2)
					if touchCount == endedCount then
						dontFadeOutOnMouseLeave = false
					end
				end
			end)

			spawn(function()
				local now = tick()
				while true do
					wait()
					now = tick()
					if this.BackgroundVisible then
						if not dontFadeOutOnMouseLeave then
							this:FadeOut(0.25)
						end
					-- If background is not visible/in-focus
					elseif this.ChatsVisible and now > lastChatActivity + MESSAGES_FADE_OUT_TIME then
						this:FadeOutChats()
					end
				end
			end)
		else
			this.LastMousePosition = Vector2.new()

			this.MouseEnterFrameConn = this.ChatContainer.MouseEnter:connect(function()
				lastEnterTime = tick()
				if this.BackgroundTweener and not this.BackgroundTweener:IsFinished() and not this.BackgroundVisible then
					this:FadeIn()
				end
			end)

			this.MouseMoveConn = InputService.InputChanged:connect(function(inputObject)
				if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
					lastMoveTime = tick()
					this.LastMousePosition = Vector2.new(inputObject.Position.X, inputObject.Position.Y)
					if this.BackgroundTweener and this.BackgroundTweener:GetPercentComplete() < 0.5 and this.BackgroundVisible then
						if not dontFadeOutOnMouseLeave then
							this:FadeOut()
						end
					end
				end
			end)

			local clickCount = 0
			this.InputBeganConn = InputService.InputBegan:connect(function(inputObject)
				if inputObject.UserInputType == Enum.UserInputType.MouseButton1 and inputObject.UserInputState == Enum.UserInputState.Begin then
					if PointInChatWindow(Vector2.new(inputObject.Position.X, inputObject.Position.Y)) then
						clickCount = clickCount + 1
						dontFadeOutOnMouseLeave = true
					end
				end
			end)

			this.InputEndedConn = InputService.InputEnded:connect(function(inputObject)
				if inputObject.UserInputType == Enum.UserInputType.MouseButton1 and inputObject.UserInputState == Enum.UserInputState.End then
					local nowCount = clickCount
					wait(1.3)
					if nowCount == clickCount then
						dontFadeOutOnMouseLeave = false
					end
				end
			end)

			this.MouseLeaveFrameConn = this.ChatContainer.MouseLeave:connect(function()
				lastLeaveTime = tick()
				if this.BackgroundTweener and not this.BackgroundTweener:IsFinished() and this.BackgroundVisible then
					if not dontFadeOutOnMouseLeave then
						this:FadeOut()
					end
				end
			end)

			spawn(function()
				while true do
					wait()
					local now = tick()
					if this:IsHovering() then
						if now - lastMoveTime > 1.3 and not this.BackgroundVisible then
							this:FadeIn()
						end
					else -- not this:IsHovering()
						if this.BackgroundVisible then
							if not dontFadeOutOnMouseLeave then
								this:FadeOut(0.25)
							end
						-- If background is not visible/in-focus
						elseif this.ChatsVisible and now > lastChatActivity + MESSAGES_FADE_OUT_TIME then
							this:FadeOutChats()
						end
					end
				end
			end)
		end
		--- END OF BACKGROUND FADING CODE ---
	end

	CreateChatWindow()

	return this
end


local function CreateChat()
	local this = {}

	this.Settings =
	{
		GlobalTextColor = Color3.new(255/255, 255/255, 243/255);
		WhisperTextColor = Color3.new(77/255, 139/255, 255/255);
		TeamTextColor = Color3.new(230/255, 207/255, 0);
		DefaultMessageTextColor = Color3.new(255/255, 255/255, 243/255);
		AdminTextColor = Color3.new(1, 215/255, 0);
		TextStrokeTransparency = 0.75;
		TextStrokeColor = Color3.new(34/255,34/255,34/255);
		Font = Enum.Font.SourceSansBold;
		--Font = Enum.Font.ArialBold;
		FontSize = Enum.FontSize.Size18;
		MaxWindowChatMessages = 50;
		MaxCharactersInMessage = 140;
	}

	this.BlockList = {}

	function this:CoreGuiChanged(coreGuiType, enabled)
		if coreGuiType == Enum.CoreGuiType.Chat or coreGuiType == Enum.CoreGuiType.All then
			if Util:IsTouchDevice() then
				Util.SetGUIInsetBounds(0, 0)
			else
				if enabled and this.ChatBarWidget then
					-- Reserve bottom 20 pixels for our chat bar
					Util.SetGUIInsetBounds(0, 20)
				else
					Util.SetGUIInsetBounds(0, 0)
				end
			end
			if this.MobileChatButton then
				if enabled == true then
					this.MobileChatButton.Parent = GuiRoot
					-- we need to set it to be visible in-case we missed a lost focus event while chat was turned off.
					this.MobileChatButton.Visible = true
				else
					this.MobileChatButton.Parent = nil
				end
			end
		end
		if this.ChatWindowWidget then
			this.ChatWindowWidget:CoreGuiChanged(coreGuiType, enabled)
		end
		if this.ChatBarWidget then
			this.ChatBarWidget:CoreGuiChanged(coreGuiType, enabled)
		end
	end

	-- This event has 4 callback arguments
	-- Enum.PlayerChatType.{All|Team|Whisper}, chatPlayer, message, targetPlayer
	function this:OnPlayerChatted(playerChatType, sendingPlayer, chattedMessage, receivingPlayer)
		if this.ChatWindowWidget then
			-- Don't add messages from blocked players
			if not this:IsPlayerBlocked(sendingPlayer) then
				this.ChatWindowWidget:AddChatMessage(playerChatType, sendingPlayer, chattedMessage, receivingPlayer)
			end
		end
	end

	function this:OnPlayerAdded(newPlayer)
		if newPlayer then
			spawn(function() Util.IsPlayerAdminAsync(newPlayer) end)
		end
		if NON_CORESCRIPT_MODE then
			newPlayer.Chatted:connect(function(msg, recipient)
				this:OnPlayerChatted(Enum.PlayerChatType.All, newPlayer, msg, recipient)
			end)
		else
			this.PlayerChattedConn = Util.DisconnectEvent(this.PlayerChattedConn)
			this.PlayerChattedConn = PlayersService.PlayerChatted:connect(function(...)
				this:OnPlayerChatted(...)
			end)
		end
	end

	function this:IsPlayerBlockedByUserId(userId)
		for _, currentBlockedUserId in pairs(this.BlockList) do
			if currentBlockedUserId == userId then
				return true
			end
		end
		return false
	end

	function this:IsPlayerBlocked(player)
		return player and this:IsPlayerBlockedByUserId(player.userId)
	end

	function this:GetBlockedPlayersAsync()
		local userId = Player.userId
		local secureBaseUrl = Util.GetSecureApiBaseUrl()
		local url = secureBaseUrl .. "userblock/getblockedusers" .. "?" .. "userId=" .. tostring(userId) .. "&" .. "page=" .. "1"
		if userId > 0 then
			local blockList = nil
			local success, msg = ypcall(function()
				local request = game:HttpGetAsync(url)
				blockList = request and game:GetService('HttpService'):JSONDecode(request)
			end)
			if blockList and blockList['success'] == true and blockList['userList'] then
				return blockList['userList']
			end
		end
		return {}
	end

	function this:BlockPlayerAsync(playerToBlock)
		if playerToBlock and Player ~= playerToBlock then
			local blockUserId = playerToBlock.userId
			local playerToBlockName = playerToBlock.Name
			if blockUserId > 0 then
				if not this:IsPlayerBlockedByUserId(blockUserId) then
					-- TODO: We may want to use a more dynamic way of changing the blockList size.
					--if #this.BlockList < MAX_BLOCKLIST_SIZE then
						table.insert(this.BlockList, blockUserId)
						this.ChatWindowWidget:AddSystemChatMessage(playerToBlockName .. " is now blocked.")
						-- Make Block call
						pcall(function()
							local success = PlayersService:BlockUser(Player.userId, blockUserId)
						end)
					--else
					--	this.ChatWindowWidget:AddSystemChatMessage("You cannot block " .. playerToBlockName .. " because your list is full.")
					--end
				else
					this.ChatWindowWidget:AddSystemChatMessage(playerToBlockName .. " is already blocked.")
				end
			else
				this.ChatWindowWidget:AddSystemChatMessage("You cannot block guests.")
			end
		else
			this.ChatWindowWidget:AddSystemChatMessage("You cannot block yourself.")
		end
	end

	function this:UnblockPlayerAsync(playerToUnblock)
		if playerToUnblock then
			local unblockUserId = playerToUnblock.userId
			local playerToUnblockName = playerToUnblock.Name

			if this:IsPlayerBlockedByUserId(unblockUserId) then
				local blockedUserIndex = nil
				for index, blockedUserId in pairs(this.BlockList) do
					if blockedUserId == unblockUserId then
						blockedUserIndex = index
					end
				end
				if blockedUserIndex then
					table.remove(this.BlockList, blockedUserIndex)
				end
				this.ChatWindowWidget:AddSystemChatMessage(playerToUnblockName .. " is no longer blocked.")
				-- Make Unblock call
				pcall(function()
					local success = PlayersService:UnblockUser(Player.userId, unblockUserId)
				end)
			else
				this.ChatWindowWidget:AddSystemChatMessage(playerToUnblockName .. " is not blocked.")
			end
		end
	end

	function this:CreateTouchDeviceChatButton()
		return Util.Create'ImageButton'
		{
			Name = 'TouchDeviceChatButton';
			Size = UDim2.new(0, 128, 0, 32);
			Position = UDim2.new(0, 88, 0, 0);
			BackgroundTransparency = 1.0;
			Image = 'http://www.roblox.com/asset/?id=97078724';
		};
	end

	function this:PrintWelcome()
		if this.ChatWindowWidget then
			this.ChatWindowWidget:AddSystemChatMessage("Please type /? for a list of commands", true)
		end
	end

	function this:PrintHelp()
		if this.ChatWindowWidget then
			this.ChatWindowWidget:AddSystemChatMessage("Help Menu")
			this.ChatWindowWidget:AddSystemChatMessage("Chat Commands:")
			this.ChatWindowWidget:AddSystemChatMessage("/w [PlayerName] or /whisper [PlayerName] - Whisper Chat")
			this.ChatWindowWidget:AddSystemChatMessage("/t or /team - Team Chat")
			this.ChatWindowWidget:AddSystemChatMessage("/a or /all - All Chat")
			if GetBlockedUsersFlag() then
				this.ChatWindowWidget:AddSystemChatMessage("/block [PlayerName] or /ignore [PlayerName] - Block communications from Target Player")
				this.ChatWindowWidget:AddSystemChatMessage("/unblock [PlayerName] or /unignore [PlayerName] - Restore communications with Target Player")
			end
		end
	end

	function this:CreateGUI()
		if FORCE_CHAT_GUI or Player.ChatMode == Enum.ChatMode.TextAndMenu then
			-- NOTE: eventually we will make multiple chat window frames
			this.ChatWindowWidget = CreateChatWindowWidget(this.Settings)
			this.ChatBarWidget = CreateChatBarWidget(this.Settings)
			this.ChatWindowWidget:FadeOut(0)
			local focusCount = 0
			this.ChatBarWidget.ChatBarGainedFocusEvent:connect(function()
				focusCount = focusCount + 1
				this.ChatWindowWidget:FadeIn(0.25)
				this.ChatWindowWidget:SetFadeLock(true)
			end)
			this.ChatBarWidget.ChatBarLostFocusEvent:connect(function()
				local focusNow = focusCount
				if Util:IsTouchDevice() then
					wait(2)
					if focusNow == focusCount then
						this.ChatWindowWidget:SetFadeLock(false)
					end
				else
					this.ChatWindowWidget:SetFadeLock(false)
				end
			end)

			this.ChatBarWidget.ChatErrorEvent:connect(function(msg)
				if msg then
					this.ChatWindowWidget:AddSystemChatMessage(msg)
				end
			end)

			this.ChatBarWidget.ChatCommandEvent:connect(function(success, actionType, capture)
				if actionType == "Help" then
					this:PrintHelp()
				elseif actionType == "Block" then
					if GetBlockedUsersFlag() then
						local blockPlayerName = capture and tostring(capture) or ""
						local playerToBlock = Util.GetPlayerByName(blockPlayerName)
						if playerToBlock then
							spawn(function() this:BlockPlayerAsync(playerToBlock) end)
						else
							this.ChatWindowWidget:AddSystemChatMessage("Cannot block " .. blockPlayerName .. " because they are not in the game.")
						end
					end
				elseif actionType == "Unblock" then
					if GetBlockedUsersFlag() then
						local unblockPlayerName = capture and tostring(capture) or ""
						local playerToBlock = Util.GetPlayerByName(unblockPlayerName)
						if playerToBlock then
							spawn(function() this:UnblockPlayerAsync(playerToBlock) end)
						else
							this.ChatWindowWidget:AddSystemChatMessage("Cannot unblock " .. unblockPlayerName .. " because they are not in the game.")
						end
					end
				elseif actionType == "Whisper" then
					if success == false then
						local playerName = capture and tostring(capture) or "Unknown"
						this.ChatWindowWidget:AddSystemChatMessage("Unable to Send a Whisper to Player: " .. playerName)
					end
				elseif actionType == "Unknown" then
					if success == false then
						local commandText = capture and tostring(capture) or "Unknown"
						this.ChatWindowWidget:AddSystemChatMessage("Invalid Slash Command: " .. commandText)
					end
				end
			end)

			if Util.IsTouchDevice() then
				local mobileChatButton = this:CreateTouchDeviceChatButton()
				if StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat) then
					mobileChatButton.Parent = GuiRoot
				end

				mobileChatButton.TouchTap:connect(function()
					mobileChatButton.Visible = false
					if this.ChatBarWidget then
						this.ChatBarWidget:FocusChatBar()
					end
				end)

				this.ChatBarWidget.ChatBarLostFocusEvent:connect(function()
					mobileChatButton.Visible = true
				end)

				this.MobileChatButton = mobileChatButton
			end
		end
	end

	function this:Initialize()
		if GetBlockedUsersFlag() then
			spawn(function()
				this.BlockList = this:GetBlockedPlayersAsync()
			end)
		end

		this:OnPlayerAdded(Player)
		-- Upsettingly, it seems everytime a player is added, you have to redo the connection
		-- NOTE: PlayerAdded only fires on the server, hence ChildAdded is used here
		PlayersService.ChildAdded:connect(function(child)
			if child:IsA('Player') then
				this:OnPlayerAdded(child)
			end
		end)

		this:CreateGUI()


		this:CoreGuiChanged(Enum.CoreGuiType.Chat, StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat))
		this.CoreGuiChangedConn = Util.DisconnectEvent(this.CoreGuiChangedConn)
		pcall(function()
			this.CoreGuiChangedConn = StarterGui.CoreGuiChangedSignal:connect(
				function(coreGuiType,enabled)
					this:CoreGuiChanged(coreGuiType, enabled)
				end)
		end)

		if not NON_CORESCRIPT_MODE then
			this:PrintWelcome()
		end
	end

	return this
end

-- Main Entry Point
do
	local ChatInstance = CreateChat()
	ChatInstance:Initialize()
end
