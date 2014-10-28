
if false then
	--[[
		//FileName: ChatScript.LUA
		//Written by: Sorcus
		//Description: Code for lua side chat on ROBLOX. Supports Scrolling.
		//NOTE: If you find any bugs or inaccuracies PM Sorcus on ROBLOX or @Canavus on Twitter
	]]

	local forceChatGUI = true

	-- Utility functions + Globals
	local function WaitForChild(parent, childName)
		while parent:FindFirstChild(childName) == nil do
			parent.ChildAdded:wait(0.03)
		end
		return parent[childName]
	end

	local function typedef(obj)
		return obj
	end

	local function IsPhone()
		local cGui = Game:GetService('CoreGui')
		local rGui = WaitForChild(cGui, 'RobloxGui')
		if rGui.AbsoluteSize.Y < 600 then
			return true
		end
		return false
	end

	-- Users can use enough white spaces to spoof chatting as other players
	-- This function removes trailing and leading white spaces
	-- AFAIK, there is no reason for spam white spaces
	local function StringTrim(str,nstr)
		-- %s+ stands whitespaces
		-- We yank out any whitespaces at the begin and end of the string
		-- After that, we put a tab behind newlines
		-- That way people can't fake messages on a new line
		return str:match("^%s*(.-)%s*$"):gsub("\n","\n"..nstr)
	end

	while Game.Players.LocalPlayer == nil do wait(0.03) end

	local Player = Game.Players.LocalPlayer
	while Player.Character == nil do wait(0.03) end
	local RbxUtility = LoadLibrary('RbxUtility')
	local Gui = typedef(RbxUtility)
	local Camera = Game.Workspace.CurrentCamera

	-- Services
	local CoreGuiService = Game:GetService('CoreGui')
	local PlayersService = Game:GetService('Players')
	local DebrisService=  Game:GetService('Debris')
	local GuiService = Game:GetService('GuiService')
	local inputService = game:GetService("UserInputService")

	-- Lua Enums
	local Enums do
		Enums = {}
		local EnumName = {} -- used as unique key for enum name
		local enum_mt = {
			__call = function(self,value)
				return self[value] or self[tonumber(value)]
			end;
			__index = {
				GetEnumItems = function(self)
					local t = {}
					for i,item in pairs(self) do
						if type(i) == 'number' then
							t[#t+1] = item
						end
					end
					table.sort(t,function(a,b) return a.Value < b.Value end)
					return t
				end;
			};
			__tostring = function(self)
				return "Enum." .. self[EnumName]
			end;
		}
		local item_mt = {
			__call = function(self,value)
				return value == self or value == self.Name or value == self.Value
			end;
			__tostring = function(self)
				return "Enum." .. self[EnumName] .. "." .. self.Name
			end;
		}
		function CreateEnum(enumName)
			return function(t)
				local e = {[EnumName] = enumName}
				for i,name in pairs(t) do
					local item = setmetatable({Name=name,Value=i,Enum=e,[EnumName]=enumName},item_mt)
					e[i] = item
					e[name] = item
					e[item] = item
				end
				Enums[enumName] = e
				return setmetatable(e, enum_mt)
			end
		end
	end
	---------------------------------------------------
	------------------ Input class --------------------
	local Input = {
							Mouse = Player:GetMouse(),
							Speed = 0,
							Simulating = false,

							Configuration = {
												DefaultSpeed = 1
											},
							UserIsScrolling = false
						}

	---------------------------------------------------
	------------------ Chat class --------------------
	local Chat = {

				ChatColors = {
								BrickColor.new("Bright red"),
								BrickColor.new("Bright blue"),
								BrickColor.new("Earth green"),
								BrickColor.new("Bright violet"),
								BrickColor.new("Bright orange"),
								BrickColor.new("Bright yellow"),
								BrickColor.new("Light reddish violet"),
								BrickColor.new("Brick yellow"),
							},

				Gui = nil,
				Frame = nil,
				RenderFrame = nil,
				TapToChatLabel = nil,
				ClickToChatButton = nil,

				ScrollingLock = false,
				EventListener = nil,

				-- This is actually a ring buffer
				-- Meaning at hitting the historyLength it wraps around
				-- Reuses the text objects, so chat atmost uses 100 text objects
				MessageQueue = {},

				-- Stores all the values for configuring chat
				Configuration = {
									FontSize = Enum.FontSize.Size18, -- 10 is good
									-- Also change this when you are changing the above, this is suboptimal but so is our interface to find FontSize
									NumFontSize = 12,
									HistoryLength = 20, -- stores up to 50 of the last chat messages for you to scroll through,
									Size = UDim2.new(0.38, 0, 0.20, 0),
									MessageColor = Color3.new(1, 1, 1),
									AdminMessageColor = Color3.new(1, 215/255, 0),
									XScale = 0.025,
									LifeTime = 45,
									Position = UDim2.new(0, 2, 0.05, 0),
									DefaultTweenSpeed = 0.15,
									HaltTime = 1/15, -- Why would people need to be chatting faster than every 1/15th of a second?
								},

				PreviousMessage = tick(), -- Timestamp of previous message

				-- This could be redone by just using the previous and next fields of the Queue
				-- But the iterators cause issues, will be optimized later
				SlotPositions_List = {},
				-- To precompute and store all player null strings since its an expensive process
				CachedSpaceStrings_List = {},
				MouseOnFrame = false,
				GotFocus = false,

				Messages_List = {},
				MessageThread = nil,

				Admins_List = {
									'Rbadam', 'Adamintygum', 'androidtest', 'RobloxFrenchie', 'JacksSmirkingRevenge', 'Mandaari', 'vaiobot', 'Goddessnoob', 'Thr33pakShak3r', 'effward',
									'Blockhaak', 'Drewbda', 'triptych999', 'Tone', 'fasterbuilder19', 'Zeuxcg', 'concol2',
									'ReeseMcBlox', 'Jeditkacheff', 'ChiefJustus', 'Ellissar', 'geekndestroy', 'Noob007', 'Limon', 'hawkington', 'Tabemono', 'autoconfig', 'BrightEyes', 'Monsterinc3D', 'IsolatedEvent', 'CountOnConnor', 'Scubasomething', 'OnlyTwentyCharacters', 'LordRugdumph', 'bellavour', 'david.baszucki', 'ibanez2189', 'ConvexHero', 'Sorcus', 'DeeAna00', 'TheLorekt', 'MSE6', 'CorgiParade', 'Varia',
									'4runningwolves', 'pulmoesflor', 'Olive71', 'groundcontroll2', 'GuruKrish', 'Countvelcro', 'IltaLumi', 'juanjuan23', 'OstrichSized', 'jackintheblox', 'SlingshotJunkie', 'gordonrox24', 'sharpnine', 'Motornerve', 'watchmedogood', 'jmargh', 'JayKorean', 'Foyle', 'MajorTom4321', 'Shedletsky', 'supernovacaine', 'FFJosh', 'Sickenedmonkey', 'Doughtless', 'KBUX', 'totallynothere', 'ErzaStar', 'Keith', 'Chro', 'SolarCrane', 'GloriousSalt',
									'IMightBeLying', 'UristMcSparks', 'ITOlaurEN', 'Malcomso', 'HeySeptember', 'Stickmasterluke', 'windlight13', 'Stravant', 'imaginationsensation', 'Matt.Dusek', 'CrimmsonGhost', 'Mcrtest', 'Seranok', 'maxvee', 'Coatp0cketninja', 'Screenme',
									'b1tsh1ft', 'ConvexRumbler', 'mpliner476', 'Totbl', 'Aquabot8', 'grossinger', 'Merely', 'CDakkar', 'Siekiera', 'Robloxkidsaccount', 'flotsamthespork', 'Soggoth', 'Phil', 'OrcaSparkles', 'skullgoblin', 'RickROSStheB0SS', 'ArgonPirate', 'NobleDragon',
									'Squidcod', 'Raeglyn', 'Xerolayne', 'RobloxSai', 'Briarroze', 'hawkeyebandit', 'DapperBuffalo', 'Vukota', 'swiftstone', 'Gemlocker', 'Tarabyte', 'Timobius', 'Tobotrobot', 'Foster008', 'Twberg', 'DarthVaden', 'Khanovich',
									'CodeWriter', 'oLEFTo', 'VladTheFirst', 'Phaedre', 'gorroth', 'jynj1984', 'RoboYZ', 'ZodiacZak',
								},
				TempSpaceLabel = nil
			}
	---------------------------------------------------

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
		return value%8
	end

	function Chat:ComputeChatColor(pName)
		return self.ChatColors[GetNameValue(pName) + 1].Color
	end

	-- This is context based scrolling
	function Chat:EnableScrolling(toggle)
		-- Genius idea gone to fail, if we switch the camera type we can effectively lock the
		-- camera and do no click scrolling
		self.MouseOnFrame = false
		if self.RenderFrame then
			self.RenderFrame.MouseEnter:connect(function()
				local character = Player.Character
				local torso = WaitForChild(character, 'Torso')
				local humanoid = WaitForChild(character, 'Humanoid')
				local head = WaitForChild(character, 'Head')
				if toggle then
					self.MouseOnFrame = true
					Camera.CameraType = 'Scriptable'
					-- Get relative position of camera and keep to it
					Spawn(function()
						local currentRelativePos = Camera.CoordinateFrame.p - torso.Position
						while Chat.MouseOnFrame do
							Camera.CoordinateFrame = CFrame.new(torso.Position + currentRelativePos, head.Position)
							wait(0.015)
						end
					end)
				end
			end)

			self.RenderFrame.MouseLeave:connect(function()
				Camera.CameraType = 'Custom'
				self.MouseOnFrame = false
			end)
		end
	end

	-- TODO: Scrolling using Mouse wheel
	function Chat:OnScroll(speed)
		if self.MouseOnFrame then
			--
		end
	end

	-- Check if we are running on a touch device
	function Chat:IsTouchDevice()
		local touchEnabled = false
		pcall(function() touchEnabled = inputService.TouchEnabled end)
		return touchEnabled
	end

	-- Scrolling
	function Chat:ScrollQueue(value)
		--[[for i = 1, #self.MessageQueue do
			if self.MessageQueue[i] then
				for _, label in pairs(self.MessageQueue[i]) do
					local next = self.MessageQueue[i].Next
					local previous = self.MessageQueue[i].Previous
					if label and label:IsA('TextLabel') or label:IsA('TextButton') then
						if value > 0 and previous and previous['Message'] then
							label.Position = previous['Message'].Position
						elseif value < 1 and next['Message'] then
							label.Position = previous['Message'].Position
						end
					end
				end
			end
		end ]]
	end

	-- Handles the rendering of the text objects in their appropriate places
	function Chat:UpdateQueue(field, diff)
		-- Have to do some sort of correction here
		for i = #self.MessageQueue, 1, -1 do
			if self.MessageQueue[i] then
				for _, label in pairs(self.MessageQueue[i]) do
					if label and type(label) ~= 'table' and type(label) ~= 'number' then
						if label:IsA('TextLabel') or label:IsA('TextButton') or label:IsA('ImageLabel') then
							if diff then
								label.Position = label.Position - UDim2.new(0, 0, diff, 0)
							else
								local yOffset = 0
								local xOffset = 20
								if label:IsA('ImageLabel') then
									yOffset = 4
									xOffset = 0
								end
								if field == self.MessageQueue[i] then
									label.Position = UDim2.new(self.Configuration.XScale, xOffset, label.Position.Y.Scale - field['Message'].Size.Y.Scale , yOffset)
									-- Just to show up popping effect for the latest message in chat
									if label:IsA('TextLabel') or label:IsA('TextButton') then
										Spawn(function()
											wait(0.05)
											while label.TextTransparency > 0 do
												label.TextTransparency = label.TextTransparency - 0.2
												wait(0.03)
											end
											if label == field['Message'] then
												label.TextStrokeTransparency = 0.6
											else
												label.TextStrokeTransparency = 1.0
											end
										end)
									else
										Spawn(function()
											wait(0.05)
											while label.ImageTransparency > 0 do
												label.ImageTransparency = label.ImageTransparency - 0.2
												wait(0.03)
											end
										end)

									end
								else
									label.Position = UDim2.new(self.Configuration.XScale, xOffset, label.Position.Y.Scale - field['Message'].Size.Y.Scale, yOffset)
								end
								if label.Position.Y.Scale < -0.01 then
									-- NOTE: Remove this fix when Textbounds is fixed
									label.Visible = false
									label:Destroy()
								end
							end
						end
					end
				end
			end
		end
	end

	function Chat:CreateScrollBar()
		-- Code for scrolling is in here, partially, but scroll bar drawing isn't drawn
		-- TODO: Implement
	end

	-- For scrolling, to see if we hit the bounds so that we can stop it from scrolling anymore
	function Chat:CheckIfInBounds(value)
		if #Chat.MessageQueue < 3 then
			return true
		end

		if value > 0 and Chat.MessageQueue[1] and Chat.MessageQueue[1]['Player'] and Chat.MessageQueue[1]['Player'].Position.Y.Scale == 0 then
			return true
		elseif value < 0  and Chat.MessageQueue[1] and Chat.MessageQueue[1]['Player'] and Chat.MessageQueue[1]['Player'].Position.Y.Scale < 0 then
			return true
		else
			return false
		end
		return false
	end

	-- This is to precompute all playerName space strings
	-- This is used to offset the message by exactly this + 2 spacestrings
	function Chat:ComputeSpaceString(pLabel)
		local nString = " "
		if not self.TempSpaceLabel then
			self.TempSpaceLabel  = Gui.Create'TextButton'
									{
										Size = UDim2.new(0, pLabel.AbsoluteSize.X, 0, pLabel.AbsoluteSize.Y);
										FontSize = self.Configuration.FontSize;
										Parent = self.RenderFrame;
										BackgroundTransparency = 1.0;
										Text = nString;
										Name = 'SpaceButton'
									};
		else
			self.TempSpaceLabel.Text = nString
		end

		while self.TempSpaceLabel.TextBounds.X < pLabel.TextBounds.X do
			nString = nString .. " "
			self.TempSpaceLabel.Text = nString
		end
		nString = nString .. " "
		self.CachedSpaceStrings_List[pLabel.Text] = nString
		self.TempSpaceLabel.Text = ""
		return nString
	end

	-- When the playerChatted event fires
	-- The message is what the player chatted
	function Chat:UpdateChat(cPlayer, message)
		local messageField = {
								['Player'] = cPlayer,
								['Message'] = message
							}
		if coroutine.status(Chat.MessageThread) == 'dead' then
			--Chat.Messages_List = {}
			table.insert(Chat.Messages_List, messageField)
			Chat.MessageThread = coroutine.create(function()
										for i = 1, #Chat.Messages_List do
											local field = Chat.Messages_List[i]
											Chat:CreateMessage(field['Player'], field['Message'])
										end
										Chat.Messages_List = {}
									end)
			coroutine.resume(Chat.MessageThread)
		else
			table.insert(Chat.Messages_List, messageField)
		end
	end

	function Chat:RecalculateSpacing()
		--[[for i = 1, #self.MessageQueue do
			local pLabel = self.MessageQueue[i]['Player']
			local mLabel = self.MessageQueue[i]['Message']

			local prevYScale = mLabel.Size.Y.Scale
			local prevText = mLabel.Text
			mLabel.Text = prevText

			local heightField = mLabel.TextBounds.Y

			mLabel.Size = UDim2.new(1, 0, heightField/self.RenderFrame.AbsoluteSize.Y, 0)
			pLabel.Size = mLabel.Size

			local diff = mLabel.Size.Y.Scale - prevYScale

			Chat:UpdateQueue(self.MessageQueue[i], diff)
		end ]]
	end

	function Chat:ApplyFilter(str)
		--[[for _, word in pair(self.Filter_List) do
			if string.find(str, word) then
				str:gsub(word, '@#$^')
			end
		end ]]
	end

	-- NOTE: Temporarily disabled ring buffer to allow for chat to always wrap around
	function Chat:CreateMessage(cPlayer, message)
		local pName
		if not cPlayer then
			pName = ''
		else
			pName = cPlayer.Name
		end
		local pLabel,mLabel
		-- Our history stores upto 50 messages that is 100 textlabels
		-- If we ever hit the mark, which would be in every popular game btw
		-- we wrap around and reuse the labels
		if #self.MessageQueue > self.Configuration.HistoryLength then
			--[[pLabel = self.MessageQueue[#self.MessageQueue]['Player']
			mLabel = self.MessageQueue[#self.MessageQueue]['Message']

			pLabel.Text = pName .. ':'
			pLabel.Name = pName

			local pColor
			if cPlayer.Neutral then
				pLabel.TextColor3 = Chat:ComputeChatColor(pName)
			else
				pLabel.TextColor3 = cPlayer.TeamColor.Color
			end

			local nString

			if not self.CachedSpaceStrings_List[pName] then
				nString = Chat:ComputeSpaceString(pLabel)
			else
				nString = self.CachedSpaceStrings_List[pName]
			end

			mLabel.Text = ""
			mLabel.Name = pName .. " - message"
			mLabel.Text = nString .. message;

			mLabel.Parent = nil
			mLabel.Parent = self.RenderFrame

			mLabel.Position = UDim2.new(0, 0, 1, 0);
			pLabel.Position = UDim2.new(0, 0, 1, 0);]]

			-- Reinserted at the beginning, ring buffer
			self.MessageQueue[#self.MessageQueue] = nil
		end
		--else
			-- Haven't hit the mark yet, so keep creating

		local nString = ""


			pLabel = Gui.Create'ImageLabel'
						{
							Name = pName;
							Parent = self.RenderFrame;
							Size = UDim2.new(0, 14, 0, 14);
							BackgroundTransparency = 1.0;
							Position = UDim2.new(0, 0, 1, -10);
							BorderSizePixel = 0.0;
							Image = "rbxasset://textures/ui/chat_teamButton.png";
							ImageTransparency = 1.0;
						};

			local pColor
			if cPlayer.Neutral then
				pLabel.ImageColor3 = Chat:ComputeChatColor(pName)
			else
				pLabel.ImageColor3 = cPlayer.TeamColor.Color
			end

			mLabel = Gui.Create'TextLabel'
							{
								Name = pName .. ' - message';
								-- Max is 3 lines
								Size = UDim2.new(1, 0, 0.5, 0);
								TextColor3 = Chat.Configuration.MessageColor;
								Font = Enum.Font.SourceSans;
								FontSize = Chat.Configuration.FontSize;
								TextXAlignment = Enum.TextXAlignment.Left;
								TextYAlignment = Enum.TextYAlignment.Top;
								Text = ""; -- this is to stop when the engine reverts the swear words to default, which is button, ugh
								Parent = self.RenderFrame;
								TextWrapped = true;
								BackgroundTransparency = 1.0;
								TextTransparency = 1.0;
								Position = UDim2.new(0, 40, 1, 0);
								BorderSizePixel = 0.0;
								TextStrokeColor3 = Color3.new(0, 0, 0);
								TextStrokeTransparency = 0.6;
								--Active = false;
							};
			mLabel.Text = nString .. pName .. ": " .. message;

			if not pName then
				mLabel.TextColor3 = Color3.new(0, 0.4, 1.0)
			end
		--end

		for _, adminName in pairs(self.Admins_List) do
			if string.lower(adminName) == string.lower(pName) then
				mLabel.TextColor3 = self.Configuration.AdminMessageColor
			end
		end

		pLabel.Visible = true
		mLabel.Visible = true

		-- This will give beautiful multilines as well
		local heightField = mLabel.TextBounds.Y

		mLabel.Size = UDim2.new(1, 0, heightField/self.RenderFrame.AbsoluteSize.Y, 0)

		local yPixels = self.RenderFrame.AbsoluteSize.Y
		local yFieldSize = mLabel.TextBounds.Y

		local queueField = {}
		queueField['Player'] = pLabel
		queueField['Message'] = mLabel
		queueField['SpawnTime'] = tick() -- Used for identifying when to make the message invisible

		table.insert(self.MessageQueue, 1, queueField)
		Chat:UpdateQueue(queueField)
	end

	function Chat:ScreenSizeChanged()
		wait()
		while self.Frame.AbsoluteSize.Y > 120 do
			self.Frame.Size = self.Frame.Size - UDim2.new(0, 0, 0.005, 0)
		end
		Chat:RecalculateSpacing()
	end



	function Chat:FocusOnChatBar()
		if self.ClickToChatButton then
			self.ClickToChatButton.Visible = false
		end

		self.GotFocus = true
		if self.Frame['Background'] then
			self.Frame.Background.Visible = false
		end
		self.ChatBar:CaptureFocus()
	end

	-- For touch devices we create a button instead
	function Chat:CreateTouchButton()
		self.ChatTouchFrame = Gui.Create'Frame'
							{
								Name = 'ChatTouchFrame';
								Size = UDim2.new(0, 128, 0, 32);
								Position = UDim2.new(0, 88, 0, 0);
								BackgroundTransparency = 1.0;
								Parent = self.Gui;

								Gui.Create'ImageButton'
								{
									Name = 'ChatLabel';
									Size = UDim2.new(0, 74, 0, 28);
									Position = UDim2.new(0, 0, 0, 0);
									BackgroundTransparency = 1.0;
									ZIndex = 2.0;
								};
								Gui.Create'ImageLabel'
								{
									Name = 'Background';
									Size = UDim2.new(1, 0, 1, 0);
									Position = UDim2.new(0, 0, 0, 0);
									BackgroundTransparency = 1.0;
									Image = 'http://www.roblox.com/asset/?id=97078724'
								};

							}
		self.TapToChatLabel = self.ChatTouchFrame.ChatLabel
		self.TouchLabelBackground = self.ChatTouchFrame.Background

		self.ChatBar = Gui.Create'TextBox'
						{
							Name = 'ChatBar';
							Size = UDim2.new(1, 0, 0.2, 0);
							Position = UDim2.new(0, 0, 0.8, 800);
							Text = "";
							ZIndex = 1.0;
							BackgroundTransparency = 1.0;
							Parent = self.Frame;
							TextXAlignment = Enum.TextXAlignment.Left;
							TextColor3 = Color3.new(1, 1, 1);
							ClearTextOnFocus = false;
						};

		self.TapToChatLabel.MouseButton1Click:connect(function()
			self.TapToChatLabel.Visible = false
			--self.ChatBar.Visible = true
			--self.Frame.Background.Visible = true
			self.ChatBar:CaptureFocus()
			self.GotFocus = true
			if self.TouchLabelBackground then
				self.TouchLabelBackground.Visible = false
			end
		end)
	end

	-- Non touch devices, create the bottom chat bar
	function Chat:CreateChatBar()
		-- okay now we do
		local status, result = pcall(function() return GuiService.UseLuaChat end)
		if forceChatGUI or (status and result) then
			self.ClickToChatButton = Gui.Create'TextButton'
									{
										Name = 'ClickToChat';
										Size = UDim2.new(1, 0, 0, 20);
										BackgroundTransparency = 1.0;
										ZIndex = 2.0;
										Parent = self.Gui;
										Text = "To chat click here or press \"/\" key";
										TextColor3 = Color3.new(1, 1, 0.9);
										Position = UDim2.new(0, 0, 1, 0);
										TextXAlignment = Enum.TextXAlignment.Left;
										FontSize = Enum.FontSize.Size12;
									}

			self.ChatBar = Gui.Create'TextBox'
								{
									Name = 'ChatBar';
									Size = UDim2.new(1, 0, 0, 20);
									Position = UDim2.new(0, 0, 1, 0);
									Text = "";
									ZIndex = 1.0;
									BackgroundColor3 = Color3.new(0, 0, 0);
									BackgroundTransparency = 0.25;
									Parent = self.Gui;
									TextXAlignment = Enum.TextXAlignment.Left;
									TextColor3 = Color3.new(1, 1, 1);
									FontSize = Enum.FontSize.Size12;
									ClearTextOnFocus = false;
									Text = '';
								};

			-- Engine has code to offset the entire world, so if we do it by -20 pixels nothing gets in our chat's way
			--GuiService:SetGlobalSizeOffsetPixel(0, -20)
			local success, error = pcall(function() GuiService:SetGlobalGuiInset(0, 0, 0, 20) end)
			if not success then
				pcall(function() GuiService:SetGlobalSizeOffsetPixel(0, -20) end) -- Doesn't hurt to throw a non-existent function into a pcall
			end
			-- ChatHotKey is '/'
			GuiService:AddSpecialKey(Enum.SpecialKey.ChatHotkey)
			GuiService.SpecialKeyPressed:connect(function(key)
				if key == Enum.SpecialKey.ChatHotkey then
					Chat:FocusOnChatBar()
				end
			end)

			self.ClickToChatButton.MouseButton1Click:connect(function()
				Chat:FocusOnChatBar()
			end)
		end
	end

	-- Create the initial Chat stuff
	-- Done only once
	function Chat:CreateGui()
		self.Gui = WaitForChild(CoreGuiService, 'RobloxGui')
		local GuiRoot = Instance.new("ScreenGui")
		GuiRoot.Name = "RobloxGui"
		GuiRoot.Parent = Player:WaitForChild('PlayerGui')
		self.Gui = GuiRoot
		self.Frame = Gui.Create'Frame'
					{
						Name = 'ChatFrame';
						--Size = self.Configuration.Size;
						Size = UDim2.new(0, 500, 0, 120);
						Position = UDim2.new(0, 0, 0, 5);
						BackgroundTransparency = 1.0;
						--ClipsDescendants = true;
						ZIndex = 0.0;
						Parent = self.Gui;
						Active = false;

						Gui.Create'ImageLabel'
						{
							Name = 'Background';
							Image = 'http://www.roblox.com/asset/?id=97120937'; --96551212';
							Size = UDim2.new(1.3, 0, 1.64, 0);
							Position = UDim2.new(0, 0, 0, 0);
							BackgroundTransparency = 1.0;
							ZIndex = 0.0;
							Visible = false
						};

						Gui.Create'Frame'
						{
							Name = 'Border';
							Size = UDim2.new(1, 0, 0, 1);
							Position = UDim2.new(0, 0, 0.8, 0);
							BackgroundTransparency = 0.0;
							BackgroundColor3 = Color3.new(236/255, 236/255, 236/255);
							BorderSizePixel = 0.0;
							Visible = false;
						};

						Gui.Create'Frame'
						{
							Name = 'ChatRenderFrame';
							Size = UDim2.new(1.02, 0, 1.01, 0);
							Position = UDim2.new(0, 0, 0, 0);
							BackgroundTransparency = 1.0;
							--ClipsDescendants = true;
							ZIndex = 0.0;
							Active = false;

						};
					};

		Spawn(function()
			wait(0.5)
			if IsPhone() then
				self.Frame.Size = UDim2.new(0, 280, 0, 120)
			end
			-- leave space for the settings button on touch devices
			-- better use the exact same test it uses for its position
			if game:GetService("UserInputService").TouchEnabled then
				self.Frame.Position = UDim2.new(0, 0, 0, 55)
			end
		end)

		self.RenderFrame = self.Frame.ChatRenderFrame
		if Chat:IsTouchDevice() then
			self.Frame.Position = self.Configuration.Position;
			self.RenderFrame.Size = UDim2.new(1, 0, 1, 0)
		elseif self.Frame.AbsoluteSize.Y > 120 then
			Chat:ScreenSizeChanged()
			self.Gui.Changed:connect(function(property)
				if property == 'AbsoluteSize' then
					Chat:ScreenSizeChanged()
				end
			end)
		end

		if forceChatGUI or Player.ChatMode == Enum.ChatMode.TextAndMenu then
			if Chat:IsTouchDevice() then
				Chat:CreateTouchButton()
			else
				Chat:CreateChatBar()
			end

			if self.ChatBar then
				self.ChatBar.FocusLost:connect(function(enterPressed)
					Chat.GotFocus = false
					if Chat:IsTouchDevice() then
	 					self.ChatBar.Visible = false
						self.TapToChatLabel.Visible = true

						if self.TouchLabelBackground then
							self.TouchLabelBackground.Visible = true
						end
					end
					if enterPressed and self.ChatBar.Text ~= "" then

						if tick() - Chat.PreviousMessage > Chat.Configuration.HaltTime then -- Make sure that the user isn't deliberately spamming the chat
							Chat.PreviousMessage = tick()
							local cText = self.ChatBar.Text
							if string.sub(self.ChatBar.Text, 1, 1)  == '%' then
								cText = '(TEAM) ' .. string.sub(cText, 2, #cText)
								pcall(function() PlayersService:TeamChat(cText) end)
							else
								pcall(function() PlayersService:Chat(cText) end)
							end

							if self.ClickToChatButton then
								self.ClickToChatButton.Visible = true
							end
							self.ChatBar.Text = ""
						end
					end
					--[[
					Spawn(function()
						wait(5.0)
						if not Chat.GotFocus then
							Chat.Frame.Background.Visible = false
						end
					end)
]]
				end)

				-- Make the escape key clear the chat box (like it used to)
				inputService.InputBegan:connect(function(input)
					if (input.KeyCode == Enum.KeyCode.Escape) then
						if self.ClickToChatButton then
							self.ClickToChatButton.Visible = true
						end

						self.ChatBar.Text = ""
					end
				end)
			end
		end
	end

	-- Scrolling function
	-- Applies a speed(velocity) to have nice scrolling effect
	function Input:OnMouseScroll()
		Spawn(function()
			-- How long should the speed last?
			while Input.Speed ~=0 do
				if Input.Speed > 1 then
					while Input.Speed > 0 do
						Input.Speed = Input.Speed - 1
						wait(0.25)
					end
				elseif Input.Speed < 0 then
					while Input.Speed < 0 do
						Input.Speed = Input.Speed + 1
						wait(0.25)
					end
				end
				wait(0.03)
			end
		end)
		if Chat:CheckIfInBounds(Input.Speed) then
			return
		end
		Chat:ScrollQueue()
	end

	function Input:ApplySpeed(value)
		Input.Speed = Input.Speed + value
		if not self.Simulating then
			Input:OnMouseScroll()
		end
	end

	function Input:Initialize()
		self.Mouse.WheelBackward:connect(function()
			Input:ApplySpeed(self.Configuration.DefaultSpeed)
		end)

		self.Mouse.WheelForward:connect(function()
			Input:ApplySpeed(self.Configuration.DefaultSpeed)
		end)
	end

	-- Just a wrapper around our PlayerChatted event
	function Chat:PlayerChatted(...)
		local args = {...}
		local argCount = select('#', ...)
		local player
		local message
		-- This doesn't look very good, but what else to do?
		if args[2] then
			player = args[2]
		end
		if args[3] then
			message = args[3]
			if string.sub(message, 1, 1) == '%' then
				message = '(TEAM) ' .. string.sub(message, 2, #message)
			end
		end

		if PlayersService.ClassicChat then
			if string.sub(message, 1, 3) == '/e ' or string.sub(message, 1, 7) == '/emote ' then
				-- don't do anything right now
			elseif forceChatGUI or Player.ChatMode == Enum.ChatMode.TextAndMenu then
				Chat:UpdateChat(player, message)
			elseif Player.ChatMode == Enum.ChatMode.Menu and string.sub(message, 1, 3) == '/sc' then
				Chat:UpdateChat(player, message)
			end
		end
	end

	-- After Chat.Configuration.Lifetime seconds of existence, the labels become invisible
	-- Runs only every 5 seconds and has to loop through 50 values
	-- Shouldn't be too expensive
	function Chat:CullThread()
		while true do
			if #self.MessageQueue > 0 then
				for _, field in pairs(self.MessageQueue) do
					if field['SpawnTime'] and field['Player'] and field['Message'] and tick() - field['SpawnTime'] > self.Configuration.LifeTime then
						field['Player'].Visible = false
						field['Message'].Visible = false
					end
				end
			end
			wait(5.0)
		end
	end

	-- RobloxLock everything so users can't delete them(?)
	function Chat:LockAllFields(gui)
		local children = gui:GetChildren()
		for i = 1, #children do
			children[i].RobloxLocked = true
			if #children[i]:GetChildren() > 0 then
				Chat:LockAllFields(children[i])
			end
		end
	end

	function Chat:CoreGuiChanged(coreGuiType,enabled)
		if coreGuiType == Enum.CoreGuiType.Chat or coreGuiType == Enum.CoreGuiType.All then
			if self.Frame then self.Frame.Visible = enabled end
			if self.TapToChatLabel then self.TapToChatLabel.Visible = enabled end

			if not Chat:IsTouchDevice() and self.ChatBar then
				self.ChatBar.Visible = enabled
				if enabled then
					GuiService:SetGlobalGuiInset(0, 0, 0, 20)
				else
					GuiService:SetGlobalGuiInset(0, 0, 0, 0)
				end
			end
		end
	end

	-- Constructor
	-- This function initializes everything
	function Chat:Initialize()

		Chat:CreateGui()

		pcall(function()
			Chat:CoreGuiChanged(Enum.CoreGuiType.Chat, Game.StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat))
			Game.StarterGui.CoreGuiChangedSignal:connect(function(coreGuiType,enabled) Chat:CoreGuiChanged(coreGuiType,enabled) end)
		end)

		self.EventListener = PlayersService.PlayerChatted:connect(function(...)
			-- This event has 4 callback arguments
			-- Enum.PlayerChatType.All, chatPlayer, message, targetPlayer
			Chat:PlayerChatted(...)

		end)

		self.MessageThread = coroutine.create(function() end)
		coroutine.resume(self.MessageThread)

		-- Initialize input for us
		Input:Initialize()
		-- Eww, everytime a player is added, you have to redo the connection
		-- Seems this is not automatic
		-- NOTE: PlayerAdded only fires on the server, hence ChildAdded is used here
		PlayersService.ChildAdded:connect(function()
			Chat.EventListener:disconnect()
			self.EventListener = PlayersService.PlayerChatted:connect(function(...)
				-- This event has 4 callback arguments
				-- Enum.PlayerChatType.All, chatPlayer, message, targetPlayer
				Chat:PlayerChatted(...)
			end)
		end)

		Spawn(function()
			Chat:CullThread()
		end)

		self.Frame.RobloxLocked = true
		Chat:LockAllFields(self.Frame)
		self.Frame.DescendantAdded:connect(function(descendant)
			Chat:LockAllFields(descendant)
		end)
	end

	Chat:Initialize()


	wait(11000000)
end







--[[
	// FileName: ChatScript.LUA
	// Written by: SolarCrane
	// Description: Code for lua side chat on ROBLOX.
]]

--[[ CONSTANTS ]]
local FORCE_CHAT_GUI = true
local USE_PLAYER_GUI_TESTING = true
local ADMIN_LIST =
{
	'Rbadam', 'Adamintygum', 'androidtest', 'RobloxFrenchie', 'JacsksSmirkingRevenge', 'LindaPepita', 'vaiobot', 'Goddessnoob', 'effward', 'Blockhaak', 'Drewbda', '659223', 'Tone', 'fasterbuilder19', 'Zeuxcg', 'concol2',
	'ReeseMcBlox', 'Jeditkacheff', 'whkm1980', 'ChiefJustus', 'Ellissar', 'Arbolito', 'Noob007', 'Limon', 'cmed', 'hawkington', 'Tabemono', 'autoconfig', 'BrightEyes', 'Monsterinc3D', 'MrDoomBringer', 'IsolatedEvent',
	'CountOnConnor', 'Scubasomething', 'OnlyTwentyCharacters', 'LordRugdumph', 'bellavour', 'david.baszucki', 'ibanez2189', 'Sorcus', 'DeeAna00', 'TheLorekt', 'NiqueMonster', 'Thorasaur', 'MSE6', 'CorgiParade', 'Varia',
	'4runningwolves', 'pulmoesflor', 'Olive71', 'groundcontroll2', 'GuruKrish', 'Countvelcro', 'IltaLumi', 'juanjuan23', 'OstrichSized', 'jackintheblox', 'SlingshotJunkie', 'gordonrox24', 'sharpnine', 'Motornerve', 'Motornerve',
	'watchmedogood', 'jmargh', 'JayKorean', 'Foyle', 'MajorTom4321', 'Shedletsky', 'supernovacaine', 'FFJosh', 'Sickenedmonkey', 'Doughtless', 'KBUX', 'totallynothere', 'ErzaStar', 'Keith', 'Chro', 'SolarCrane', 'GloriousSalt',
	'UristMcSparks', 'ITOlaurEN', 'Malcomso', 'Stickmasterluke', 'windlight13', 'yumyumcheerios', 'Stravant', 'ByteMe', 'imaginationsensation', 'Matt.Dusek', 'Mcrtest', 'Seranok', 'maxvee', 'Coatp0cketninja', 'Screenme',
	'b1tsh1ft', 'Totbl', 'Aquabot8', 'grossinger', 'Merely', 'CDakkar', 'Siekiera', 'Robloxkidsaccount', 'flotsamthespork', 'Soggoth', 'Phil', 'OrcaSparkles', 'skullgoblin', 'RickROSStheB0SS', 'ArgonPirate', 'NobleDragon',
	'Squidcod', 'Raeglyn', 'RobloxSai', 'Briarroze', 'hawkeyebandit', 'DapperBuffalo', 'Vukota', 'swiftstone', 'Gemlocker', 'Loopylens', 'Tarabyte', 'Timobius', 'Tobotrobot', 'Foster008', 'Twberg', 'DarthVaden', 'Khanovich',
	'CodeWriter', 'VladTheFirst', 'Phaedre', 'gorroth', 'SphinxShen', 'jynj1984', 'RoboYZ', 'ZodiacZak', 'superman205', 'ConvexRumbler', 'mpliner476', 'geekndestroy', 'glewis17', 'BuckerooB',
}
local CHAT_COLORS =
{
	BrickColor.new("Bright red"),
	BrickColor.new("Bright blue"),
	BrickColor.new("Earth green"),
	BrickColor.new("Bright violet"),
	BrickColor.new("Bright orange"),
	BrickColor.new("Bright yellow"),
	BrickColor.new("Light reddish violet"),
	BrickColor.new("Brick yellow"),
}
-- These emotes are copy-pastad from the humanoidLocalAnimateKeyframe script
local EMOTE_NAMES = {wave = true, point = true, dance = true, dance2 = true, dance3 = true, laugh = true, cheer = true}
local MESSAGES_FADE_OUT_TIME = 30
--[[ END OF CONSTANTS ]]

--[[ SERVICES ]]
local RunService = Game:GetService('RunService')
local CoreGuiService = Game:GetService('CoreGui')
local PlayersService = Game:GetService('Players')
local DebrisService = Game:GetService('Debris')
local GuiService = Game:GetService('GuiService')
local InputService = Game:GetService('UserInputService')
local StarterGui = Game:GetService('StarterGui')
local RobloxGui = CoreGuiService:WaitForChild('RobloxGui')
--[[ END OF SERVICES ]]

--[[ SCRIPT VARIABLES ]]

-- I am not fond of waiting at the top of the script here...
while PlayersService.LocalPlayer == nil do PlayersService.ChildAdded:wait() end
local Player = PlayersService.LocalPlayer
-- GuiRoot will act as the top-node for parenting GUIs
local GuiRoot = RobloxGui
if USE_PLAYER_GUI_TESTING then
	GuiRoot = Instance.new("ScreenGui")
	GuiRoot.Name = "RobloxGui"
	GuiRoot.Parent = Player:WaitForChild('PlayerGui')
	GuiRoot.RobloxLocked = true
end
--[[ END OF SCRIPT VARIABLES ]]

local Util = {}
do
	-- Check if we are running on a touch device
	function Util.IsTouchDevice()
		local touchEnabled = false
		pcall(function() touchEnabled = InputService.TouchEnabled end)
		return touchEnabled
	end

	function Util.IsPhone()
		if RobloxGui.AbsoluteSize.Y < 600 then
			return true
		end
		return false
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
		Spawn(function()
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
		return value%8
	end

	function Util.ComputeChatColor(pName)
		return CHAT_COLORS[GetNameValue(pName) + 1].Color
	end

	-- This is a memo-izing function
	local testLabel = Instance.new('TextLabel')
	testLabel.TextWrapped = true;
	testLabel.Position = UDim2.new(1,0,1,0)
	testLabel.RobloxLocked = true
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

	this.Settings =
	{
		Font = Enum.Font.SourceSansBold;
		FontSize = Enum.FontSize.Size14;
	}

	function this:FadeIn()
		local gui = this:GetGui()
		if gui then
			--Util.PropertyTweener(this.ChatContainer, 'BackgroundTransparency', this.ChatContainer.BackgroundTransparency, 1, duration, Util.Linear)
			gui.Visible = true
		end
	end

	function this:FadeOut()
		local gui = this:GetGui()
		if gui then
			--Util.PropertyTweener(this.ChatContainer, 'BackgroundTransparency', this.ChatContainer.BackgroundTransparency, 1, duration, Util.Linear)
			gui.Visible = false
		end
	end

	function this:GetGui()
		return this.Container
	end

	function this:IsVisible()
		return true
	end

	function this:Destroy()
		if this.Container ~= nil then
			this.Container:Destroy()
			this.Container = nil
		end
	end

	return this
end

local function CreateSystemChatMessage(chattedMessage)
	local this = CreateChatMessage()

	this.chatMessage = chattedMessage

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
			RobloxLocked = true;
		};

			local chatMessage = Util.Create'TextLabel'
			{
				Name = 'SystemChatMessage';
				Position = UDim2.new(0, xOffset, 0, 0);
				Size = UDim2.new(1, 0, 0, systemMessageSize.Y);
				Text = systemMesasgeDisplayText;
				ZIndex = 1;
				BackgroundColor3 = Color3.new(0, 0, 0);
				BackgroundTransparency = 1;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Top;
				TextWrapped = true;
				TextColor3 = Color3.new(1, 1, 1);
				FontSize = this.Settings.FontSize;
				Font = this.Settings.Font;
				RobloxLocked = true;
				Parent = container;
			};

		container.Size = UDim2.new(1, 0, 0, chatMessage.Size.Y.Offset);
		this.Container = container
	end

	CreateMessageGuiElement()

	return this
end

local function CreatePlayerChatMessage(playerChatType, sendingPlayer, chattedMessage, receivingPlayer)
	local this = CreateChatMessage()

	this.PlayerChatType = playerChatType
	this.SendingPlayer = sendingPlayer
	this.RawMessageContent = chattedMessage
	this.ReceivingPlayer = receivingPlayer
	this.ReceivedTime = tick()

	this.Neutral = this.SendingPlayer and this.SendingPlayer.Neutral or true
	this.TeamColor = this.SendingPlayer and this.SendingPlayer.TeamColor or BrickColor.new("White")

	function this:FormatMessage()
		local result = ""
		if this.RawMessageContent then
			local message = this.RawMessageContent
			--[[
			if string.sub(message, 1, 1) == '%' then
				result = '(TEAM) ' .. string.sub(message, 2, #message)
			elseif string.sub(message, 1, 6) == '(TEAM)' then
				result = '(TEAM) ' .. string.sub(message, 7, #message)
			end
			]]
			if PlayersService.ClassicChat then
				if string.sub(message, 1, 3) == '/e ' or string.sub(message, 1, 7) == '/emote ' then
					if this.SendingPlayer then
						result = this.SendingPlayer.Name .. " emotes."
					end
				elseif FORCE_CHAT_GUI or Player.ChatMode == Enum.ChatMode.TextAndMenu then
					result = message--Chat:UpdateChat(player, message)
				elseif Player.ChatMode == Enum.ChatMode.Menu and string.sub(message, 1, 3) == '/sc' then
					result = "SafeChat Response"
					--Chat:UpdateChat(player, message)
				end
			end
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
		return "[" .. (this.SendingPlayer and this.SendingPlayer.Name or "") .. "]"
	end

	function this:IsVisible()
		if this.PlayerChatType == Enum.PlayerChatType.All or
				this.PlayerChatType == Enum.PlayerChatType.Team or
				(this.PlayerChatType == Enum.PlayerChatType.Whisper and this.ReceivingPlayer == Player) then
			return true
		end
		return false
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
		local toMesasgeDisplayText = "To: "
		local toMessageSize = Util.GetStringTextBounds(toMesasgeDisplayText, this.Settings.Font, this.Settings.FontSize)
		local chatTypeDisplayText = this:FormatChatType()
		local chatTypeSize = chatTypeDisplayText and Util.GetStringTextBounds(chatTypeDisplayText, this.Settings.Font, this.Settings.FontSize) or Vector2.new(0,0)
		local playerNameDisplayText = this:FormatPlayerNameText()
		local playerNameSize = Util.GetStringTextBounds(playerNameDisplayText, this.Settings.Font, this.Settings.FontSize)

		local singleSpaceSize = Util.GetStringTextBounds(" ", this.Settings.Font, this.Settings.FontSize)
		local numNeededSpaces = math.ceil(playerNameSize.X / singleSpaceSize.X) + 1
		local chatMessageDisplayText = string.rep(" ", numNeededSpaces) .. this:FormatMessage()
		local chatMessageSize = Util.GetStringTextBounds(chatMessageDisplayText, this.Settings.Font, this.Settings.FontSize, UDim2.new(0, 400 - 5 - playerNameSize.X, 0, 1000))



		local playerColor = Color3.new(1,1,1)
		if this.SendingPlayer then
			if this.SendingPlayer.Neutral then
				playerColor = Util.ComputeChatColor(this.SendingPlayer.Name)
			else
				playerColor = this.SendingPlayer.TeamColor.Color
			end
		end

		local container = Util.Create'Frame'
		{
			Name = 'MessageContainer';
			Position = UDim2.new(0, 0, 0, 0);
			ZIndex = 1;
			BackgroundColor3 = Color3.new(0, 0, 0);
			BackgroundTransparency = 1;
			RobloxLocked = true;
		};
			local xOffset = 0

			local whisperToText = nil
			if this.SendingPlayer and this.SendingPlayer == Player and this.PlayerChatType == Enum.PlayerChatType.Whisper then
				whisperToText = Util.Create'TextLabel'
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
					TextColor3 = Color3.new(1, 1, 1);
					FontSize = this.Settings.FontSize;
					Font = this.Settings.Font;
					RobloxLocked = true;
					Parent = container;
				};
				xOffset = xOffset + toMessageSize.X
			else
				local userNameDot = Util.Create'ImageLabel'
				{
					Name = "UserNameDot";
					Size = UDim2.new(0, 14, 0, 14);
					BackgroundTransparency = 1;
					Position = UDim2.new(0, 0, 0, 2);
					BorderSizePixel = 0;
					Image = "rbxasset://textures/ui/chat_teamButton.png";
					ImageColor3 = playerColor;
					RobloxLocked = true;
					Parent = container;
				}
				xOffset = xOffset + 14 + 3
			end
		if chatTypeDisplayText then
			local chatModeButton = Util.Create'TextButton'
			{
				Name = 'ChatMode';
				BackgroundTransparency = 1;
				ZIndex = 2;
				Text = chatTypeDisplayText;
				TextColor3 = Color3.new(255/255, 255/255, 243/255);
				Position = UDim2.new(0, xOffset, 0, 0);
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Top;
				FontSize = this.Settings.FontSize;
				Font = this.Settings.Font;
				Size = UDim2.new(0, chatTypeSize.X, 0, chatTypeSize.Y);
				RobloxLocked = true;
				Parent = container
			}
			this.ClickedOnModeConn = chatModeButton.MouseButton1Click:connect(function()
				SelectChatModeEvent:fire(this.PlayerChatType)
			end)
			if this.PlayerChatType == Enum.PlayerChatType.Team then
				chatModeButton.TextColor3 = playerColor
			end
			xOffset = xOffset + chatTypeSize.X + 1
		end
			local userNameButton = Util.Create'TextButton'
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
				RobloxLocked = true;
				Parent = container
			}
			this.ClickedOnPlayerConn = userNameButton.MouseButton1Click:connect(function()
				SelectPlayerEvent:fire(this.SendingPlayer)
			end)
			--xOffset = xOffset + playerNameSize.X

			--xOffset = xOffset + 5
			local chatMessage = Util.Create'TextLabel'
			{
				Name = 'ChatMessage';
				Position = UDim2.new(0, xOffset, 0, 0);
				Size = UDim2.new(1, -xOffset, 0, chatMessageSize.Y);
				Text = chatMessageDisplayText;
				ZIndex = 1;
				BackgroundColor3 = Color3.new(0, 0, 0);
				BackgroundTransparency = 1;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Top;
				TextWrapped = true;
				TextColor3 = Color3.new(255/255, 255/255, 243/255);
				FontSize = this.Settings.FontSize;
				Font = this.Settings.Font;
				RobloxLocked = true;
				Parent = container;
			};
			chatMessage.Size = chatMessage.Size + UDim2.new(0, 0, 0, chatMessage.TextBounds.Y);

		container.Size = UDim2.new(1, 0, 0, math.max(chatMessage.Size.Y.Offset, userNameButton.Size.Y.Offset));
		this.Container = container
	end

	CreateMessageGuiElement()

	return this
end

local function CreateChatBarWidget(settings)
	local this = {}

	-- MessageModes: {All, Team, Whisper}
	this.MessageMode = "All"
	this.TargetWhisperPlayer = nil
	this.Settings = settings

	this.ChatBarGainedFocusEvent = Util.Signal()
	this.ChatBarLostFocusEvent = Util.Signal()
	this.ChatCommandEvent = Util.Signal() -- success, actionType, captures

	this.ChatMatchingRegex =
	{
		[function(chatBarText) return string.find(string.lower(chatBarText), "^/w (%w+)") end] = "Whisper";
		[function(chatBarText) return string.find(string.lower(chatBarText), "^/whisper (%w+)") end] = "Whisper";

		[function(chatBarText) return string.find(chatBarText, "^%%") end] = "Team";
		[function(chatBarText) return string.find(chatBarText, "^(TEAM)") end] = "Team";
		[function(chatBarText) return string.find(string.lower(chatBarText), "^/t") end] = "Team";
		[function(chatBarText) return string.find(string.lower(chatBarText), "^/team") end] = "Team";

		[function(chatBarText) return string.find(string.lower(chatBarText), "^/a") end] = "All";
		[function(chatBarText) return string.find(string.lower(chatBarText), "^/all") end] = "All";
		[function(chatBarText) return string.find(string.lower(chatBarText), "^/s") end] = "All";
		[function(chatBarText) return string.find(string.lower(chatBarText), "^/say") end] = "All";

		[function(chatBarText) return string.find(string.lower(chatBarText), "^/e") end] = "Emote";
		[function(chatBarText) return string.find(string.lower(chatBarText), "^/emote") end] = "Emote";

		[function(chatBarText) return string.find(string.lower(chatBarText), "^/%?") end] = "Help";
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

	function this:CoreGuiChanged(coreGuiType, enabled)
		if coreGuiType == Enum.CoreGuiType.Chat or coreGuiType == Enum.CoreGuiType.All then
			if this.ChatBarContainer then
				this.ChatBarContainer.Visible = enabled
			end
		end
	end

	function this:IsAChatMode(mode)
		return ChatModesDict[mode] ~= nil
	end

	function this:IsAnEmoteMode(mode)
		return mode == "Emote"
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
									this:SetChatBarText("")
									this.ChatCommandEvent:fire(false, actionType, capture)
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
				-- TODO: Flash Max Characters Feedback
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
		if this.MessageMode ~= newMessageMode then
			this.MessageMode = newMessageMode
			if this.ChatModeText then
				if newMessageMode == 'Whisper' then
					-- TODO: also update this when they change players to whisper to
					local chatRecipientText = "[" .. (this.TargetWhisperPlayer and this.TargetWhisperPlayer.Name or "") .. "]"
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
				this.ChatBar.Visible = true
				this:SetMessageMode('All') -- Don't remember message mode on mobile devices
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
			if Util.IsTouchDevice() then
				self.ChatBar.Visible = false
			end
			if enterPressed then
				local didMatchSlashCommand = this:ProcessChatBarModes(false)
				local cText = this:SanitizeInput(this:GetChatBarText())
				if cText ~= "" then
					if not didMatchSlashCommand and string.sub(cText,1,1) == "/" then
						this.ChatCommandEvent:fire(false, "Unknown", cText)
					else
						local currentMessageMode = this:GetMessageMode()
						-- {All, Team, Whisper}
						if currentMessageMode == 'Team' then
							pcall(function() PlayersService:TeamChat(cText) end)
						elseif currentMessageMode == 'Whisper' then
							if this.TargetWhisperPlayer then
								pcall(function() PlayersService:WhisperChat(cText, this.TargetWhisperPlayer) end)
							else
								print("Somehow we are trying to whisper to a player not in the game anymore:" , this.TargetWhisperPlayer)
							end
						elseif currentMessageMode == 'All' then
							pcall(function() PlayersService:Chat(cText) end)
						else
							Spawn(function() error("ChatScript: Unknown Message Mode of " .. tostring(currentMessageMode)) end)
						end
					end
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
			RobloxLocked = true;
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
				RobloxLocked = true;
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
				BackgroundTransparency = 1;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Top;
				TextColor3 = this.Settings.GlobalTextColor;
				Font = Enum.Font.SourceSansBold;
				FontSize = Enum.FontSize.Size18;
				ClearTextOnFocus = false;
				Visible = not Util.IsTouchDevice();
				RobloxLocked = true;
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
				RobloxLocked = true;
				Parent = chatBarContainer;
			}
		this.ChatBarContainer = chatBarContainer
		this.ClickToChatButton = clickToChatButton
		this.ChatBar = chatBar
		this.ChatModeText = chatModeText
		this.ChatBarContainer.Parent = GuiRoot


		--------- EVENTS ---------
		-- ChatHotKey is '/'
		GuiService:AddSpecialKey(Enum.SpecialKey.ChatHotkey)
		GuiService.SpecialKeyPressed:connect(function(key)
			if key == Enum.SpecialKey.ChatHotkey then
				this:FocusChatBar()
			end
		end)

		this.ClickToChatButton.MouseButton1Click:connect(function() this:FocusChatBar() end)
		this.ChatBar.FocusLost:connect(function(...) this.ChatBarLostFocusEvent:fire(...) end)

		-- TODO: disconnect these events
		this.ChatBarLostFocusEvent:connect(function(...) this:OnChatBarFocusLost(...) end)

		SelectChatModeEvent:connect(function(chatType)
			this:SetMessageMode(chatType)
			this:FocusChatBar()
		end)
		SelectPlayerEvent:connect(function(chatPlayer)
			this.TargetWhisperPlayer = chatPlayer
			this:SetMessageMode("Whisper")
			this:FocusChatBar()
		end)
		--------- END OF EVENTS ---------

	end

	CreateChatBar()
	return this
end

local function CreateChatWindowWidget(settings)
	local this = {}
	this.Settings = settings
	this.Chats = {}
	this.BackgroundVisible = false

	this.ChatWindowPagingConn = nil

	local lastMoveTime = tick()
	local lastEnterTime = tick()
	local lastLeaveTime = tick()

	local lastFadeOutTime = 0
	local lastFadeInTime = 0

	local FadeLock = false

	local function PointInChatWindow(pt)
		local point0 = this.ChatContainer.AbsolutePosition
		local point1 = point0 + this.ChatContainer.AbsoluteSize
		return point0.X <= pt.X and point1.X >= pt.X and
		       point0.Y <= pt.Y and point1.Y >= pt.Y
	end

	function this:IsHovering()
		--return lastEnterTime > lastLeaveTime
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

	function this:FadeIn(duration, lockFade)
		if not FadeLock then
			duration = duration or 0.75
			-- fade in
			if this.BackgroundTweener then
				this.BackgroundTweener:Cancel()
			end
			lastFadeInTime = tick()
			this.ScrollingFrame.ScrollingEnabled = true
			this.BackgroundTweener = Util.PropertyTweener(this.ChatContainer, 'BackgroundTransparency', this.ChatContainer.BackgroundTransparency, 0.7, duration, Util.Linear)
			this.BackgroundVisible = true
			this:FadeInChats()

			this.ChatWindowPagingConn = Util.DisconnectEvent(this.ChatWindowPagingConn)
			this.ChatWindowPagingConn = InputService.InputBegan:connect(function(inputObject)
				local key = inputObject.KeyCode
				if key == Enum.KeyCode.PageUp then
					this.ScrollingFrame.CanvasPosition = Vector2.new(0, math.max(0, this.ScrollingFrame.CanvasPosition.Y - this.ScrollingFrame.AbsoluteSize.Y))
				elseif key == Enum.KeyCode.PageDown then
					this.ScrollingFrame.CanvasPosition =
						Vector2.new(0, Util.Clamp(0, --min
						               this.ScrollingFrame.CanvasSize.Y.Offset - this.ScrollingFrame.AbsoluteSize.Y, --max
						               this.ScrollingFrame.CanvasPosition.Y + this.ScrollingFrame.AbsoluteSize.Y))
				elseif key == Enum.KeyCode.Home then
					this.ScrollingFrame.CanvasPosition = Vector2.new(0, 0)
				elseif key == Enum.KeyCode.End then
					this.ScrollingFrame.CanvasPosition = Vector2.new(0, this.ScrollingFrame.CanvasSize.Y.Offset - this.ScrollingFrame.AbsoluteSize.Y)
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
			this.ScrollingFrame.ScrollingEnabled = false
			this.BackgroundTweener = Util.PropertyTweener(this.ChatContainer, 'BackgroundTransparency', this.ChatContainer.BackgroundTransparency, 1, duration, Util.Linear)
			this.BackgroundVisible = false

			this.ChatWindowPagingConn = Util.DisconnectEvent(this.ChatWindowPagingConn)

			local now = lastFadeOutTime
			delay(MESSAGES_FADE_OUT_TIME, function()
				if lastFadeOutTime > lastFadeInTime and now == lastFadeOutTime then
					this:FadeOutChats()
				end
			end)
		end
	end

	function this:FadeInChats()
		-- TODO: only bother with this loop if we know chats have been faded out, could be quicker than this
		for index, message in pairs(this.Chats) do
			message:FadeIn()
		end
	end

	function this:FadeOutChats()
		for index, message in pairs(this.Chats) do
			message:FadeOut()
		end
	end

	function this:PushMessageIntoQueue(chatMessage)
		table.insert(this.Chats, chatMessage)

		local isScrolledDown = this:IsScrolledDown()

		local ySize = this.MessageContainer.Size.Y.Offset
		local chatMessageElement = chatMessage:GetGui()
		local chatMessageElementYSize = UDim2.new(0, 0, 0, chatMessageElement.Size.Y.Offset)

		chatMessageElement.Position = chatMessageElement.Position + UDim2.new(0, 0, 0, ySize)
		chatMessageElement.Parent = this.MessageContainer
		this.MessageContainer.Size = this.MessageContainer.Size + chatMessageElementYSize
		this.ScrollingFrame.CanvasSize = this.ScrollingFrame.CanvasSize + chatMessageElementYSize

		if this.Settings.MaxWindowChatMessages < #this.Chats then
			this:RemoveOldestMessage()
		end
		if isScrolledDown then
			this.ScrollingFrame.CanvasPosition = Vector2.new(0, math.max(0, this.ScrollingFrame.CanvasSize.Y.Offset - this.ScrollingFrame.AbsoluteSize.Y))
		else
			-- Raise unread message alert!
		end
		this:FadeInChats()
	end

	function this:AddSystemChatMessage(chattedMessage)
		local chatMessage = CreateSystemChatMessage(chattedMessage)
		this:PushMessageIntoQueue(chatMessage)
	end

	function this:AddChatMessage(playerChatType, sendingPlayer, chattedMessage, receivingPlayer)
		local chatMessage = CreatePlayerChatMessage(playerChatType, sendingPlayer, chattedMessage, receivingPlayer)
		--print("New Message:" , playerChatType, sendingPlayer, chattedMessage, receivingPlayer)
		this:PushMessageIntoQueue(chatMessage)
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
						guiObj.Parent = nil
					end
					message:Destroy()
					return table.remove(this.Chats, index)
				end
			end
		end
	end

	function this:IsScrolledDown()
		local yCanvasSize = this.ScrollingFrame.CanvasSize.Y.Offset
		local yContainerSize = this.ScrollingFrame.AbsoluteSize.Y
		local yScrolledPosition = this.ScrollingFrame.CanvasPosition.Y
		-- Check if the messages are at the bottom
		return yCanvasSize < yContainerSize or
		       yCanvasSize - yScrolledPosition >= yContainerSize - 2 -- Fuzzy equals here
	end

	function this:CoreGuiChanged(coreGuiType, enabled)
		if coreGuiType == Enum.CoreGuiType.Chat or coreGuiType == Enum.CoreGuiType.All then
			if this.ChatContainer then
				this.ChatContainer.Visible = enabled
			end
		end
	end

	local function CreateChatWindow()
		local container = Util.Create'Frame'
		{
			Name = 'ChatWindowContainer';
			 -- Height is a multiple of chat message height, maybe keep this value at 150 and move that padding into the messageContainer
			Size = UDim2.new(0, 400, 0, 140);
			Position = UDim2.new(0, 20, 0, 50);
			ZIndex = 1;
			BackgroundColor3 = Color3.new(0, 0, 0);
			BackgroundTransparency = 1;
			RobloxLocked = true;
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
				RobloxLocked = true;
				Parent = container;
			};
				local messageContainer = Util.Create'Frame'
				{
					Name = 'MessageContainer';
					Size = UDim2.new(1, 0, 0, 0);
					Position = UDim2.new(0, 0, 1, 0);
					ZIndex = 1;
					BackgroundColor3 = Color3.new(0, 0, 0);
					BackgroundTransparency = 1;
					RobloxLocked = true;
					Parent = scrollingFrame
				};

		-- This is some trickery we are doing to make the first chat messages appear at the bottom and go towards the top.
		local function OnChatWindowResize(prop)
			if prop == 'AbsoluteSize' then
				messageContainer.Position = UDim2.new(0, 0, 1, -messageContainer.Size.Y.Offset)
			elseif prop == 'ScrollBarThickness' then
				messageContainer.Size = UDim2.new(
					messageContainer.Size.X.Scale,
					scrollingFrame.Size.X.Offset - scrollingFrame.ScrollBarThickness - scrollingFrame.Position.X.Offset,
					messageContainer.Size.Y.Scale,
					messageContainer.Size.Y.Offset)
			end
		end

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

			Spawn(function()
				while true do
					wait()
					if this.BackgroundVisible then
						if not dontFadeOutOnMouseLeave then
							this:FadeOut(0.25)
						end
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
					wait(2)
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

			Spawn(function()
				while true do
					wait()
					if this:IsHovering() then
						if tick() - lastMoveTime > 2 and not this.BackgroundVisible then
							this:FadeIn()
						end
					else -- not this:IsHovering()
						if this.BackgroundVisible then
							if not dontFadeOutOnMouseLeave then
								this:FadeOut(0.25)
							end
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
		MaxWindowChatMessages = 100;
		MaxCharactersInMessage = 140; -- Same as a tweet :D
	}


	function this:CoreGuiChanged(coreGuiType, enabled)
		if coreGuiType == Enum.CoreGuiType.Chat or coreGuiType == Enum.CoreGuiType.All then
			if Util:IsTouchDevice() then
				Util.SetGUIInsetBounds(0, 0)
			else
				if enabled then
					-- Reserve bottom 20 pixels for our chat bar
					Util.SetGUIInsetBounds(0, 20)
				else
					Util.SetGUIInsetBounds(0, 0)
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
			if playerChatType == Enum.PlayerChatType.Team and sendingPlayer and sendingPlayer.Neutral == true then
				this.ChatWindowWidget:AddSystemChatMessage("You are not in any team.")
			else
				this.ChatWindowWidget:AddChatMessage(playerChatType, sendingPlayer, chattedMessage, receivingPlayer)
			end
		end
	end

	function this:OnPlayerAdded()
		this.PlayerChattedConn = Util.DisconnectEvent(this.PlayerChattedConn)
		this.PlayerChattedConn = PlayersService.PlayerChatted:connect(function(...)
			this:OnPlayerChatted(...)
		end)
	end

	function this:GetBlockedPlayersAsync()
		local secureBaseUrl = Util.GetSecureApiBaseUrl()
		local url = secureBaseUrl .. "userblock/getblockedusers" .. "?" .. "userId=" .. tostring(Player.userId) .. "&" .. "page=" .. "1"
		local blockList = nil
		local success, msg = ypcall(function()
			local request = game:HttpGetAsync(url)
			blockList = request and game:GetService('HttpService'):DecodeJSON(request)
		end)
		if blockList and blockList['success'] == true then
			return blockList['userList']
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
			RobloxLocked = true;
		};
	end

	function this:PrintWelcome()
		this.ChatWindowWidget:AddSystemChatMessage("Welcome to Roblox")
		this.ChatWindowWidget:AddSystemChatMessage("Please type /? for a list of commands")
	end

	function this:PrintHelp()
		this.ChatWindowWidget:AddSystemChatMessage("Help Menu")
		this.ChatWindowWidget:AddSystemChatMessage("Chat Commands:")
		this.ChatWindowWidget:AddSystemChatMessage("/w [PlayerName] or /whisper [PlayerName] - Whisper Chat")
		this.ChatWindowWidget:AddSystemChatMessage("/t or /team - Team Chat")
		this.ChatWindowWidget:AddSystemChatMessage("/a or /all - All Chat")
	end

	function this:CreateGUI()
		local success, useLuaChat = pcall(function() return GuiService.UseLuaChat end)
		if (success and useLuaChat) or FORCE_CHAT_GUI then
			-- TODO: eventually we will make multiple chat window frames
			-- Settings is a table, which makes it a pointing and is kosher to pass by reference
			this.ChatWindowWidget = CreateChatWindowWidget(this.Settings)
			this.ChatBarWidget = CreateChatBarWidget(this.Settings)

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

			this.ChatBarWidget.ChatCommandEvent:connect(function(success, actionType, capture)
				if actionType == "Help" then
					this:PrintHelp()
				elseif actionType == "Whisper" then
					if success == false then
						local playerName = capture and tostring(capture) or "Unknown"
						this.ChatWindowWidget:AddSystemChatMessage("Unable to Whisper Player: " .. playerName)
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
				mobileChatButton.Parent = GuiRoot

				mobileChatButton.TouchTap:connect(function()
					mobileChatButton.Visible = false
					if this.ChatBarWidget then
						this.ChatBarWidget:FocusChatBar()
					end
				end)

				this.ChatBarWidget.ChatBarLostFocusEvent:connect(function()
					mobileChatButton.Visible = true
				end)
			end
		end
	end

	function this:Initialize()
		pcall(function()
			this:CoreGuiChanged(Enum.CoreGuiType.Chat, StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat))
			this.CoreGuiChangedConn = Util.DisconnectEvent(this.CoreGuiChangedConn)
			this.CoreGuiChangedConn = StarterGui.CoreGuiChangedSignal:connect(
				function(coreGuiType,enabled)
					this:CoreGuiChanged(coreGuiType,enabled)
				end)
		end)

		--spawn(function()
		--	this:GetBlockedPlayersAsync()
		--end)

		this:OnPlayerAdded()
		-- Upsettingly, it seems everytime a player is added, you have to redo the connection
		-- NOTE: PlayerAdded only fires on the server, hence ChildAdded is used here
		PlayersService.ChildAdded:connect(function()
			this:OnPlayerAdded()
		end)

		this:CreateGUI()

		this:PrintWelcome()
	end

	return this
end


-- Run the script
do
	local ChatInstance = CreateChat()
	ChatInstance:Initialize()
end
