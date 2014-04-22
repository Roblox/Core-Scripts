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
local function StringTrim(str)
	-- %S is whitespaces
	-- When we find the first non space character defined by ^%s 
	-- we yank out anything in between that and the end of the string 
	-- Everything else is replaced with %1 which is essentially nothing  	
	return (str:gsub("^%s*(.-)%s*$", "%1"))
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
								FontSize = Enum.FontSize.Size12, -- 10 is good 				
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
							},

			-- This could be redone by just using the previous and next fields of the Queue
			-- But the iterators cause issues, will be optimized later 
			SlotPositions_List = {},	
			-- To precompute and store all player null strings since its an expensive process 
			CachedSpaceStrings_List = {},	
			MouseOnFrame = false,
			GotFocus = false,

			Messages_List = {},
			MessageThread = nil,

			Admins_List = {'Sorcus', 'Shedletsky', 'Telamon', 'Tarabyte', 'StickMasterLuke', 'OnlyTwentyCharacters', 'FusRoblox', 'SolarCrane', 
								'HotThoth', 'JediTkacheff', 'Builderman', 'Brighteyes', 'ReeseMcblox', 'GemLocker', 'GongfuTiger', 'Erik.Cassel', 'Matt Dusek', 'Keith',
								'Totbl', 'LordRugDump', 'David.Baszucki', 'Dbapostle', 'DaveYorkRBX', 'nJay', 'OstrichSized', 'TobotRobot', 'twberg', 'ROBLOX', 'RBAdam', 'Doughtless',
								'Anaminus', 'Stravant', 'Cr3470r', 'CodeWriter', 'Games', 'AcesWayUpHigh', 'Phil', 'effward', 'mleask'
								},

			SafeChat_List = {
								['Use the Chat menu to talk to me.'] = {'/sc 0', true},
								['I can only see menu chats.'] = {'/sc 1', true},
								['Hello'] = {	
												['Hi'] = {'/sc 2_0', true, ['Hi there!'] = true, ['Hi everyone'] = true}, 
												['Howdy'] = {'/sc 2_1', true, ['Howdy partner!'] = true},
												['Greetings'] = {'/sc 2_2', true, ['Greetings everyone'] = true, ['Greetings Robloxians!'] = true, ['Seasons greetings!'] = true},
												['Welcome'] = {'/sc 2_3', true, ['Welcome to my place'] = true, ['Welcome to my barbeque'] = true, ['Welcome to our base'] = true},
												['Hey there!'] = {'/sc 2_4', true},
												['What\'s up?'] = {'/sc 2_5', true, ['How are you doing?'] = true, ['How\'s it going?'] = true, ['What\'s new?'] = true},
												['Good day'] = {'/sc 2_6', true, ['Good morning'] = true, ['Good evening'] = true, ['Good afternoon'] = true, ['Good night'] = true},
												['Silly'] = {'/sc 2_7', true, ['Waaaaaaaz up?!'] = true, ['Hullo!'] = true, ['Behold greatness, mortals!'] = true, ['Pardon me, is this Sparta?'] = true, ['THIS IS SPARTAAAA!'] = true},
												['Happy Holidays!'] = {'/sc 2_8', true, ['Happy New Year!'] = true, 
																	      ['Happy Valentine\'s Day!'] = true, 
																	      ['Beware the Ides of March!'] = true, 
																	      ['Happy St. Patrick\'s Day!'] = true, 
																	      ['Happy Easter!'] = true, 
																	      ['Happy Earth Day!'] = true, 
																	      ['Happy 4th of July!'] = true, 
																	      ['Happy Thanksgiving!'] = true, 
																	      ['Happy Halloween!'] = true, 
																	      ['Happy Hanukkah!'] = true, 
																	      ['Merry Christmas!'] = true, 
																	      ['Happy Halloween!'] = true, 
																	      ['Happy Earth Day!'] = true, 
																	      ['Happy May Day!'] = true, 
																	      ['Happy Towel Day!'] = true, 
																	      ['Happy ROBLOX Day!'] = true, 
																	      ['Happy LOL Day!'] = true },

												[1] = '/sc 2'
											},
								['Goodbye'] = {
												['Good Night']= {'/sc 3_0', true, 
																  ['Sweet dreams'] = true, 
															      ['Go to sleep!'] = true, 
															      ['Lights out!'] = true, 
															      ['Bedtime'] = true, 
															      ['Going to bed now'] = true},

												['Later']= {'/sc 3_1', true,
												 			  ['See ya later'] = true, 
														      ['Later gator!'] = true, 
														      ['See you tomorrow'] = true},

												['Bye'] = {'/sc 3_2', true, ['Hasta la bye bye!'] = true},
												['I\'ll be right back'] = {'/sc 3_3', true},
												['I have to go'] = {'/sc 3_4', true},
												['Farewell'] = {'/sc 3_5', true, ['Take care'] = true, ['Have a nice day'] = true, ['Goodluck!'] = true, ['Ta-ta for now!'] = true},
												['Peace'] = {'/sc 3_6', true, ['Peace out!'] = true, ['Peace dudes!'] = true, ['Rest in pieces!'] = true},
												['Silly'] = {'/sc 3_7', true, 
												  ['To the batcave!'] = true, 
											      ['Over and out!'] = true, 
											      ['Happy trails!'] = true, 
											      ['I\'ve got to book it!'] = true, 
											      ['Tootles!'] = true, 
											      ['Smell you later!'] = true, 
											      ['GG!'] = true, 
											      ['My house is on fire! gtg.'] = true},
												[1] = '/sc 3'
											},
								['Friend'] ={
												['Wanna be friends?'] = {'/sc 4_0', true},
												['Follow me'] = {'/sc 4_1', true,  ['Come to my place!'] = true, ['Come to my base!'] = true, ['Follow me, team!'] = true, ['Follow me'] = true},
												['Your place is cool'] = {'/sc 4_2', true,  ['Your place is fun'] = true, ['Your place is awesome'] = true, ['Your place looks good'] = true, ['This place is awesome!'] = true},
												['Thank you'] = {'/sc 4_3', true,  ['Thanks for playing'] = true, ['Thanks for visiting'] = true, ['Thanks for everything'] = true, ['No, thank you'] = true, ['Thanx'] = true},
												['No problem'] = {'/sc 4_4', true,  ['Don\'t worry'] = true, ['That\'s ok'] = true, ['np'] = true},
												['You are ...'] = {'/sc 4_5', true,  
																	['You are great!'] = true, 
																      ['You are good!'] = true, 
																      ['You are cool!'] = true, 
																      ['You are funny!'] = true, 
																      ['You are silly!'] = true, 
																      ['You are awesome!'] = true, 
																      ['You are doing something I don\'t like, please stop'] = true
																   },
												['I like ...'] = {'/sc 4_6', true, ['I like your name'] = true, ['I like your shirt'] = true, ['I like your place'] = true, ['I like your style'] = true, 
      																['I like you'] = true, ['I like items'] = true, ['I like money'] = true},
												['Sorry'] = {'/sc 4_7', true, ['My bad!'] = true, ['I\'m sorry'] = true, ['Whoops!'] = true, ['Please forgive me.'] = true, ['I forgive you.'] = true, 
      														['I didn\'t mean to do that.'] = true, ['Sorry, I\'ll stop now.'] = true},
												[1] = '/sc 4'
											},
								['Questions'] = {
													['Who?'] = {'/sc 5_0', true,  ['Who wants to be my friend?'] = true, ['Who wants to be on my team?'] = true, ['Who made this brilliant game?'] = true},
													['What?'] = {'/sc 5_1', true,  ['What is your favorite animal?'] = true, ['What is your favorite game?'] = true, ['What is your favorite movie?'] = true, 
															      ['What is your favorite TV show?'] = true, ['What is your favorite music?'] = true, ['What are your hobbies?'] = true, ['LOLWUT?'] = true},
													['When?'] = {'/sc 5_2', true, ['When are you online?'] = true, ['When is the new version coming out?'] = true, ['When can we play again?'] = true, ['When will your place be done?'] = true},
													['Where?'] = {'/sc 5_3', true, ['Where do you want to go?'] = true, ['Where are you going?'] = true, ['Where am I?!'] = true, ['Where did you go?'] = true},
													['How?'] = {'/sc 5_4', true, ['How are you today?'] = true, ['How did you make this cool place?'] = true, ['LOLHOW?'] = true},
													['Can I...'] = {'/sc 5_5', true, ['Can I have a tour?'] = true, ['Can I be on your team?'] = true, ['Can I be your friend?'] = true, ['Can I try something?'] = true, 
																	['Can I have that please?'] = true, ['Can I have that back please?'] = true, ['Can I have borrow your hat?'] = true, ['Can I have borrow your gear?'] = true},
													[1] = '/sc 5'
												},
								['Answers'] = {
												['You need help?'] = {'/sc 6_0', true, ['Check out the news section'] = true, ['Check out the help section'] = true, ['Read the wiki!'] = true, 
																		['All the answers are in the wiki!'] = true, ['I will help you with this.'] = true},
												['Some people ...'] = {'/sc 6_1', true, ['Me'] = true, ['Not me'] = true, ['You'] = true, ['All of us'] = true, ['Everyone but you'] = true, ['Builderman!'] = true, 
      																	['Telamon!'] = true, ['My team'] = true, ['My group'] = true, ['Mom'] = true, ['Dad'] = true, ['Sister'] = true, ['Brother'] = true, ['Cousin'] = true, 
      																	['Grandparent'] = true, ['Friend'] = true},
												['Time ...'] = {'/sc 6_2', true,  ['In the morning'] = true, ['In the afternoon'] = true, ['At night'] = true, ['Tomorrow'] = true, ['This week'] = true, ['This month'] = true, 
      															['Sometime'] = true, ['Sometimes'] = true, ['Whenever you want'] = true, ['Never'] = true, ['After this'] = true, ['In 10 minutes'] = true, ['In a couple hours'] = true, 
      															['In a couple days'] = true},
												['Animals'] = {'/sc 6_3', true, 
																['Cats'] = {['Lion'] = true, ['Tiger'] = true, ['Leopard'] = true, ['Cheetah'] = true},
																['Dogs'] = {['Wolves'] = true, ['Beagle'] = true, ['Collie'] = true, ['Dalmatian'] = true, ['Poodle'] = true, ['Spaniel'] = true, 
        																		['Shepherd'] = true, ['Terrier'] = true, ['Retriever'] = true},
        														['Horses'] = {['Ponies'] = true, ['Stallions'] = true, ['Pwnyz'] = true},
        														['Reptiles'] = {['Dinosaurs'] = true, ['Lizards'] = true, ['Snakes'] = true, ['Turtles!'] = true},
        														['Hamster'] = true, 
      															['Monkey'] = true, 
      															['Bears'] = true,
      															['Fish'] = {['Goldfish'] = true, ['Sharks'] = true, ['Sea Bass'] = true, ['Halibut'] = true, ['Tropical Fish'] = true},
      															['Birds'] = {['Eagles'] = true, ['Penguins'] = true, ['Parakeets'] = true, ['Owls'] = true, ['Hawks'] = true, ['Pidgeons'] = true},
      															['Elephants'] = true, 
      															['Mythical Beasts'] = {['Dragons'] = true, ['Unicorns'] = true, ['Sea Serpents'] = true, ['Sphinx'] = true, ['Cyclops'] = true, 
        																				['Minotaurs'] = true, ['Goblins'] = true, ['Honest Politicians'] = true, ['Ghosts'] = true, ['Scylla and Charybdis'] = true}
															},
												['Games'] = {'/sc 6_4', true,
																['Action'] = true, ['Puzzle'] = true, ['Strategy'] = true, ['Racing'] = true, ['RPG'] = true, ['Obstacle Course'] = true, ['Tycoon'] = true, 
																['Roblox'] = { ['BrickBattle'] = true, ['Community Building'] = true, ['Roblox Minigames'] = true, ['Contest Place'] = true},
																['Board games'] = { ['Chess'] = true, ['Checkers'] = true, ['Settlers of Catan'] = true, ['Tigris and Euphrates'] = true, ['El Grande'] = true, 
        																			['Stratego'] = true, ['Carcassonne'] = true}
															},
												['Sports'] = {'/sc 6_5', true, ['Hockey'] = true, ['Soccer'] = true, ['Football'] = true, ['Baseball'] = true, ['Basketball'] = true, 
																 ['Volleyball'] = true, ['Tennis'] = true, ['Sports team practice'] = true,
																 ['Watersports'] = { ['Surfing'] = true,['Swimming'] = true, ['Water Polo'] = true},
																 ['Winter sports'] = { ['Skiing'] = true, ['Snowboarding'] = true, ['Sledding'] = true, ['Skating'] = true},
																 ['Adventure'] = {['Rock climbing'] = true, ['Hiking'] = true, ['Fishing'] = true, ['Horseback riding'] = true},
																 ['Wacky'] = {['Foosball'] = true, ['Calvinball'] = true, ['Croquet'] = true, ['Cricket'] = true, ['Dodgeball'] = true, 
        																		['Squash'] = true, 	['Trampoline'] = true}
															 },
												['Movies/TV'] = {'/sc 6_6', true, ['Science Fiction'] = true, ['Animated'] = {['Anime'] = true}, ['Comedy'] = true, ['Romantic'] = true, 
      																['Action'] = true, ['Fantasy'] = true},
												['Music'] = {'/sc 6_7', true, ['Country'] = true, ['Jazz'] = true, ['Rap'] = true, ['Hip-hop'] = true, ['Techno'] = true, ['Classical'] = true, 
      														['Pop'] = true, ['Rock'] = true},
												['Hobbies'] = {'/sc 6_8', true,
																['Computers'] = { ['Building computers'] = true, ['Videogames'] = true, ['Coding'] = true, ['Hacking'] = true},
																['The Internet'] = { ['lol. teh internets!'] = true, ['Watching vids'] = true},
																 ['Dance'] = true, ['Gymnastics'] = true, ['Listening to music'] = true, ['Arts and crafts'] = true,
																 ['Martial Arts'] = {['Karate'] = true, ['Judo'] = true, ['Taikwon Do'] = true, ['Wushu'] = true, ['Street fighting'] = true},
																 ['Music lessons'] = {['Playing in my band'] = true, ['Playing piano'] = true, ['Playing guitar'] = true, 
        																				['Playing violin'] = true, ['Playing drums'] = true, ['Playing a weird instrument'] = true}
																},
												['Location'] = {'/sc 6_9', true,
																	['USA'] = {
																					['West'] = { ['Alaska'] = true, ['Arizona'] = true, ['California'] = true, ['Colorado'] = true, ['Hawaii'] = true, 
          																						['Idaho'] = true, ['Montana'] = true, ['Nevada'] = true, ['New Mexico'] = true, ['Oregon'] = true, 
          																						['Utah'] = true, ['Washington'] = true, ['Wyoming'] = true
          																						},
          																			['South'] = { ['Alabama'] = true, ['Arkansas'] = true, ['Florida'] = true, ['Georgia'] = true, ['Kentucky'] = true, 
          																							['Louisiana'] = true, ['Mississippi'] = true, ['North Carolina'] = true, ['Oklahoma'] = true, 
          																							['South Carolina'] = true, ['Tennessee'] = true, ['Texas'] = true, ['Virginia'] = true, ['West Virginia'] = true
          																						},
          																			['Northeast'] = {['Connecticut'] = true, ['Delaware'] = true, ['Maine'] = true, ['Maryland'] = true, ['Massachusetts'] = true, 
          																							['New Hampshire'] = true, ['New Jersey'] = true, ['New York'] = true,  ['Pennsylvania'] = true, ['Rhode Island'] = true, 
          																							['Vermont'] = true
          																						},
          																			['Midwest'] = {['Illinois'] = true, ['Indiana'] = true, ['Iowa'] = true, ['Kansas'] = true, ['Michigan'] = true, ['Minnesota'] = true, 
          																							['Missouri'] = true, ['Nebraska'] = true, ['North Dakota'] = true, ['Ohio'] = true, ['South Dakota'] = true,  ['Wisconsin'] = true}
																				},
																	['Canada'] = {['Alberta'] = true, ['British Columbia'] = true, ['Manitoba'] = true, ['New Brunswick'] = true, ['Newfoundland'] = true, 
        																			['Northwest Territories'] = true, ['Nova Scotia'] = true, ['Nunavut'] = true, ['Ontario'] = true, ['Prince Edward Island'] = true, 
        																			['Quebec'] = true, ['Saskatchewan'] = true, ['Yukon'] = true},
        															['Mexico'] = true,
        															['Central America'] = true,
        															['Europe'] = {['France'] = true, ['Germany'] = true, ['Spain'] = true, ['Italy'] = true, ['Poland'] = true, ['Switzerland'] = true, 
        																			['Greece'] = true, ['Romania'] = true, ['Netherlands'] = true,
        																			['Great Britain'] = {['England'] = true, ['Scotland'] = true, ['Wales'] = true, ['Northern Ireland'] = true}
        																		},
        															['Asia'] = { ['China'] = true, ['India'] = true, ['Japan'] = true, ['Korea'] = true, ['Russia'] = true, ['Vietnam'] = true},
        															['South America'] = { ['Argentina'] = true, ['Brazil'] = true},
        															['Africa'] = { ['Eygpt'] = true, ['Swaziland'] = true},
        															['Australia'] = true, ['Middle East'] = true, ['Antarctica'] = true, ['New Zealand'] = true
																},
												['Age'] = {'/sc 6_10', true, ['Rugrat'] = true, ['Kid'] = true, ['Tween'] = true, ['Teen'] = true, ['Twenties'] = true, 
      														['Old'] = true, ['Ancient'] = true, ['Mesozoic'] = true, ['I don\'t want to say my age. Don\'t ask.'] = true},
												['Mood'] = {'/sc 6_11', true,  ['Good'] = true, ['Great!'] = true, ['Not bad'] = true, ['Sad'] = true, ['Hyper'] = true, 
      														['Chill'] = true, ['Happy'] = true, ['Kind of mad'] = true},
												['Boy'] = {'/sc 6_12', true},
												['Girl'] = {'/sc 6_13', true},
												['I don\'t want to say boy or girl. Don\'t ask.'] = {'/sc 6_14', true},
												[1] = '/sc 6'
											}, 
								['Game'] = {
												['Let\'s build'] = {'/sc 7_0', true},
												['Let\'s battle'] = {'/sc 7_1', true},
												['Nice one!'] = {'/sc 7_2', true},
												['So far so good'] = {'/sc 7_3', true},
												['Lucky shot!'] = {'/sc 7_4', true},
												['Oh man!'] = {'/sc 7_5', true},
												['I challenge you to a fight!'] = {'/sc 7_6', true},
												['Help me with this'] = {'/sc 7_7', true},
												['Let\'s go to your game'] = {'/sc 7_8', true},
												['Can you show me how do to that?'] = {'/sc 7_9', true},
												['Backflip!'] = {'/sc 7_10', true},
												['Frontflip!'] = {'/sc 7_11', true},							
												['Dance!'] = {'/sc 7_12', true},
												['I\'m on your side!'] = {'/sc 7_13', true},
												['Game Commands'] = {'/sc 7_14', true, ['regen'] = true, ['reset'] = true, ['go'] = true, ['fix'] = true, ['respawn'] = true},
												[1] = '/sc 7'
											};
								['Silly'] = {
												['Muahahahaha!'] = true,
												['all your base are belong to me!'] = true,
												['GET OFF MAH LAWN'] = true,
												['TEH EPIK DUCK IS COMING!!!'] = true,
												['ROFL'] = true,
												['1337'] = {true, ['i r teh pwnz0r!'] = true, ['w00t!'] = true, ['z0mg h4x!'] = true, ['ub3rR0xXorzage!'] = true}
											},
								['Yes'] = {
											['Absolutely!'] = true,
											['Rock on!'] = true,
											['Totally!'] = true,
											['Juice!'] = true,
											['Yay!'] = true,
											['Yesh'] = true
										},
								['No'] = {
											['Ummm. No.'] = true,
											['...'] = true,
											['Stop!'] = true,
											['Go away!'] = true,
											['Don\'t do that'] = true,
											['Stop breaking the rules'] = true,
											['I don\'t want to'] = true
										},
								['Ok'] = {
											['Well... ok'] = true,
											['Sure'] = true
										},
								['Uncertain'] = {
													['Maybe'] = true,
													['I don\'t know'] = true,
													['idk'] = true,
													['I can\'t decide'] = true,
													['Hmm...'] = true
												},
								[':-)'] = {
											[':-('] = true, 
										    [':D'] = true, 
										    [':-O'] = true, 
										    ['lol'] = true, 
										    ['=D'] = true, 
										    ['D='] = true, 
										    ['XD'] = true, 
										    [';D'] = true, 
										    [';)'] = true, 
										    ['O_O'] = true, 
										    ['=)'] = true, 
										    ['@_@'] = true, 
										    ['&gt;_&lt;'] = true, 
										    ['T_T'] = true, 
										    ['^_^'] = true,
											['<(0_0<) <(0_0)> (>0_0)> KIRBY DANCE'] = true,
											[')\';'] = true, 
											[':3'] = true
										},
								['Ratings'] = {
												['Rate it!'] = true,
												['I give it a 1 out of 10'] = true,
												['I give it a 2 out of 10'] = true,
												['I give it a 3 out of 10'] = true,
												['I give it a 4 out of 10'] = true,
												['I give it a 5 out of 10'] = true,
												['I give it a 6 out of 10'] = true,
												['I give it a 7 out of 10'] = true,
												['I give it a 8 out of 10'] = true,
												['I give it a 9 out of 10'] = true,
												['I give it a 10 out of 10!'] = true,
											}
							},			
			CreateEnum('SafeChat'){'Level1', 'Level2', 'Level3'},
			SafeChatTree = {},
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
	pcall(function() touchEnabled = Game:GetService('UserInputService').TouchEnabled end)	
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
					if label:IsA('TextLabel') or label:IsA('TextButton') then 	
						if diff then 
							label.Position = label.Position - UDim2.new(0, 0, diff, 0) 
						else											
							if field == self.MessageQueue[i] then 						
								label.Position = UDim2.new(self.Configuration.XScale, 0, label.Position.Y.Scale - field['Message'].Size.Y.Scale , 0)
								-- Just to show up popping effect for the latest message in chat 
								Spawn(function()
									wait(0.05)							
									while label.TextTransparency >= 0 do 
										label.TextTransparency = label.TextTransparency - 0.2
										wait(0.03) 
									end 	
									if label == field['Message'] then 
										label.TextStrokeTransparency = 0.8
									else 
										label.TextStrokeTransparency = 1.0
									end 		
								end)
							else 							
								label.Position = UDim2.new(self.Configuration.XScale, 0, label.Position.Y.Scale - field['Message'].Size.Y.Scale, 0)							
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
	message = StringTrim(message)		
	local pLabel
	local mLabel 
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
		pLabel = Gui.Create'TextLabel' 
					{
						Name = pName;
						Text = pName .. ":";
						TextColor3 = pColor;
						FontSize = Chat.Configuration.FontSize;
						TextXAlignment = Enum.TextXAlignment.Left;
						TextYAlignment = Enum.TextYAlignment.Top;
						Parent = self.RenderFrame;
						TextWrapped = false;
						Size = UDim2.new(1, 0, 0.1, 0);
						BackgroundTransparency = 1.0;
						TextTransparency = 1.0;	
						Position = UDim2.new(0, 0, 1, 0);
						BorderSizePixel = 0.0; 
						TextStrokeColor3 = Color3.new(0.5, 0.5, 0.5);
						TextStrokeTransparency = 0.75;
						--Active = false;
					};					
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

		mLabel = Gui.Create'TextLabel' 
						{
							Name = pName .. ' - message';
							-- Max is 3 lines
							Size = UDim2.new(1, 0, 0.5, 0);							
							TextColor3 = Chat.Configuration.MessageColor;
							FontSize = Chat.Configuration.FontSize;
							TextXAlignment = Enum.TextXAlignment.Left;	
							TextYAlignment = Enum.TextYAlignment.Top;						
							Text = ""; -- this is to stop when the engine reverts the swear words to default, which is button, ugh
							Parent = self.RenderFrame;			
							TextWrapped = true;			
							BackgroundTransparency = 1.0;						
							TextTransparency = 1.0;
							Position = UDim2.new(0, 0, 1, 0);
							BorderSizePixel = 0.0;
							TextStrokeColor3 = Color3.new(0, 0, 0);
							--TextStrokeTransparency = 0.8;
							--Active = false;
						};
		mLabel.Text = nString .. message;

		if not pName then 
			pLabel.Text = '' 
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
	pLabel.Size = mLabel.Size

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


function Chat:FindButtonTree(scButton, rootList)	
	local list = {}
	rootList = rootList or self.SafeChatTree 	
	for button, _ in pairs(rootList) do 		
		if button == scButton then 			
			list = rootList[button]
		elseif type(rootList[button]) == 'table' then 
			list = Chat:FindButtonTree(scButton, rootList[button])
		end 
	end 		
	return list 
end 

function Chat:ToggleSafeChatMenu(scButton)
	local list = Chat:FindButtonTree(scButton, self.SafeChatTree)		
	if list then 
		for button, _ in pairs(list) do 
			if button:IsA('TextButton') or button:IsA('ImageButton') then 
				button.Visible = not button.Visible 
			end 
		end 
		return true
	end 
	return false 
end

function Chat:CreateSafeChatOptions(list, rootButton)
	local text_List = {}
	level = level or 0
	local count = 0
	text_List[rootButton] = {}
	text_List[rootButton][1] = list[1]
	rootButton = rootButton or self.SafeChatButton 
	for msg, _ in pairs(list) do 
		if type(msg) == 'string' then 
			local chatText = Gui.Create'TextButton'
							{
								Name = msg;
								Text = msg;
								Size = UDim2.new(0, 100, 0, 20);
								TextXAlignment = Enum.TextXAlignment.Center;
								TextColor3 = Color3.new(0.2, 0.1, 0.1);
								BackgroundTransparency = 0.5;
								BackgroundColor3 = Color3.new(1, 1, 1);
								Parent = self.SafeChatFrame;
								Visible = false;
								Position = UDim2.new(0, rootButton.Position.X.Scale + 105, 0, rootButton.Position.Y.Scale - ((count - 3) * 100));
							};

			count = count + 1

			if type(list[msg]) == 'table' then 								
				text_List[rootButton][chatText] = Chat:CreateSafeChatOptions(list[msg], chatText)				
			else 
				--table.insert(text_List[chatText], true)
			end 
			chatText.MouseEnter:connect(function()
				Chat:ToggleSafeChatMenu(chatText)
			end)

			chatText.MouseLeave:connect(function()
				Chat:ToggleSafeChatMenu(chatText)
			end)

			chatText.MouseButton1Click:connect(function()									
				local lList = Chat:FindButtonTree(chatText)
				if lList then 					
					for i, v in pairs(lList) do 						
					end 
				else 					
				end 
				pcall(function() PlayersService:Chat(lList[1])	end)
			end)
		end 
	end 
	return text_List
end

function Chat:CreateSafeChatGui()
	self.SafeChatFrame = Gui.Create'Frame' 
						{
							Name = 'SafeChatFrame';
							Size = UDim2.new(1, 0, 1, 0);
							Parent = self.Gui;
							BackgroundTransparency = 1.0;

							Gui.Create'ImageButton'
							{
								Name = 'SafeChatButton';
								Size = UDim2.new(0, 44, 0, 31);
								Position = UDim2.new(0, 1, 0.35, 0);
								BackgroundTransparency = 1.0;
								Image = 'http://www.roblox.com/asset/?id=97080365';
							};
						}

	self.SafeChatButton = self.SafeChatFrame.SafeChatButton
	-- safe chat button is the root of this tree 
	self.SafeChatTree[self.SafeChatButton] = Chat:CreateSafeChatOptions(self.SafeChat_List, self.SafeChatButton)

	self.SafeChatButton.MouseButton1Click:connect(function()		
		Chat:ToggleSafeChatMenu(self.SafeChatButton)
	end)
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
			GuiService:SetGlobalSizeOffsetPixel(0, -20)
		end
		-- CHatHotKey is '/'
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
			--Chat:CreateSafeChatGui()
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
				Spawn(function()
					wait(5.0)
					if not Chat.GotFocus then 						
						Chat.Frame.Background.Visible = false 
					end 
				end)		
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

function Chat:FindMessageInSafeChat(message, list)
	local foundMessage =  false 
	for msg, _ in pairs(list) do 		
		if msg == message then 			
			return true
		end 
		if type(list[msg]) == 'table' then 
			foundMessage = Chat:FindMessageInSafeChat(message, list[msg])
			if foundMessage then 
				return true 
			end 
		end 
	end 
	return foundMessage
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
		else 
			if Chat:FindMessageInSafeChat(message, self.SafeChat_List) then 
				Chat:UpdateChat(player, message)
			end 
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
