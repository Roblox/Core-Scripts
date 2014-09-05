--[[
	//FileName: ChatScript.LUA 
	//Written by: Sorcus 
	//Description: Code for lua side chat on ROBLOX. Supports Scrolling.
	//NOTE: If you find any bugs or inaccuracies PM Sorcus on ROBLOX or @Canavus on Twitter 
]]

local forceChatGUI = false

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
								'Rbadam', 'Adamintygum', 'androidtest', 'RobloxFrenchie', 'JacksSmirkingRevenge', 'LindaPepita', 'vaiobot', 'Goddessnoob', 'effward', 'Blockhaak', 'Drewbda', '659223', 'Tone', 'fasterbuilder19', 'Zeuxcg', 'concol2', 
								'ReeseMcBlox', 'Jeditkacheff', 'whkm1980', 'ChiefJustus', 'Ellissar', 'Arbolito', 'Noob007', 'Limon', 'cmed', 'hawkington', 'Tabemono', 'autoconfig', 'BrightEyes', 'Monsterinc3D', 'MrDoomBringer', 'IsolatedEvent', 
								'CountOnConnor', 'Scubasomething', 'OnlyTwentyCharacters', 'LordRugdumph', 'bellavour', 'david.baszucki', 'ibanez2189', 'Sorcus', 'DeeAna00', 'TheLorekt', 'NiqueMonster', 'Thorasaur', 'MSE6', 'CorgiParade', 'Varia', 
								'4runningwolves', 'pulmoesflor', 'Olive71', 'groundcontroll2', 'GuruKrish', 'Countvelcro', 'IltaLumi', 'juanjuan23', 'OstrichSized', 'jackintheblox', 'SlingshotJunkie', 'gordonrox24', 'sharpnine', 'Motornerve', 'Motornerve', 
								'watchmedogood', 'jmargh', 'JayKorean', 'Foyle', 'MajorTom4321', 'Shedletsky', 'supernovacaine', 'FFJosh', 'Sickenedmonkey', 'Doughtless', 'KBUX', 'totallynothere', 'ErzaStar', 'Keith', 'Chro', 'SolarCrane', 'GloriousSalt', 
								'UristMcSparks', 'ITOlaurEN', 'Malcomso', 'Stickmasterluke', 'windlight13', 'yumyumcheerios', 'Stravant', 'ByteMe', 'imaginationsensation', 'Matt.Dusek', 'Mcrtest', 'Seranok', 'maxvee', 'Coatp0cketninja', 'Screenme', 
								'b1tsh1ft', 'Totbl', 'Aquabot8', 'grossinger', 'Merely', 'CDakkar', 'Siekiera', 'Robloxkidsaccount', 'flotsamthespork', 'Soggoth', 'Phil', 'OrcaSparkles', 'skullgoblin', 'RickROSStheB0SS', 'ArgonPirate', 'NobleDragon', 
								'Squidcod', 'Raeglyn', 'RobloxSai', 'Briarroze', 'hawkeyebandit', 'DapperBuffalo', 'Vukota', 'swiftstone', 'Gemlocker', 'Loopylens', 'Tarabyte', 'Timobius', 'Tobotrobot', 'Foster008', 'Twberg', 'DarthVaden', 'Khanovich', 
								'CodeWriter', 'VladTheFirst', 'Phaedre', 'gorroth', 'SphinxShen', 'jynj1984', 'RoboYZ', 'ZodiacZak', 'superman205', 'ConvexRumbler', 'mpliner476', 'geekndestroy', 'glewis17', 'BuckerooB',
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
				Spawn(function()
					wait(5.0)
					if not Chat.GotFocus then 						
						Chat.Frame.Background.Visible = false 
					end 
				end)		
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
