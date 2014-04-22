-- This script manages context switches in the backpack (Gear to Wardrobe, etc.) and player state changes.  Also manages global functions across different tabs (currently only search)
if game.CoreGui.Version < 7 then return end -- peace out if we aren't using the right client

-- basic functions
local function waitForChild(instance, name)
	while not instance:FindFirstChild(name) do
		instance.ChildAdded:wait()
	end
	return instance:FindFirstChild(name)
end
local function waitForProperty(instance, property)
	while not instance[property] do
		instance.Changed:wait()
	end
end

-- don't do anything if we are in an empty game
waitForChild(game,"Players")
if #game.Players:GetChildren() < 1 then
	game.Players.ChildAdded:wait()
end
-- make sure everything is loaded in before we do anything
-- get our local player
waitForProperty(game.Players,"LocalPlayer")
local player = game.Players.LocalPlayer



------------------------ Locals ------------------------------
local backpack = script.Parent
waitForChild(backpack,"Gear")

local screen = script.Parent.Parent
assert(screen:IsA("ScreenGui"))

waitForChild(backpack, "Tabs")
waitForChild(backpack.Tabs, "CloseButton")
local closeButton = backpack.Tabs.CloseButton

waitForChild(backpack.Tabs, "InventoryButton")
local inventoryButton = backpack.Tabs.InventoryButton
if game.CoreGui.Version >= 8 then
	waitForChild(backpack.Tabs, "WardrobeButton")
	local wardrobeButton = backpack.Tabs.WardrobeButton
end
waitForChild(backpack.Parent,"ControlFrame")
local backpackButton = waitForChild(backpack.Parent.ControlFrame,"BackpackButton")
local currentTab = "gear"

local searchFrame = waitForChild(backpack,"SearchFrame")
waitForChild(backpack.SearchFrame,"SearchBoxFrame")
local searchBox = waitForChild(backpack.SearchFrame.SearchBoxFrame,"SearchBox")
local searchButton = waitForChild(backpack.SearchFrame,"SearchButton")
local resetButton = waitForChild(backpack.SearchFrame,"ResetButton")

local robloxGui = waitForChild(Game.CoreGui, 'RobloxGui')
local currentLoadout = waitForChild(robloxGui, 'CurrentLoadout')
local loadoutBackground = waitForChild(currentLoadout, 'Background')

local canToggle = true
local readyForNextEvent = true
local backpackIsOpen = false
local active = true
local disabledByDeveloper = false

local humanoidDiedCon = nil

local backpackButtonPos 

local guiTweenSpeed = 0.25 -- how quickly we open/close the backpack

local searchDefaultText = "Search..."
local tilde = "~"
local backquote = "`"

local backpackSize = UDim2.new(0, 600, 0, 400)

if robloxGui.AbsoluteSize.Y <= 320 then 
	backpackSize = UDim2.new(0, 200, 0, 140)
end 


------------------------ End Locals ---------------------------


---------------------------------------- Public Event Setup ----------------------------------------

function createPublicEvent(eventName)
	assert(eventName, "eventName is nil")
	assert(tostring(eventName),"eventName is not a string")
	
	local newEvent = Instance.new("BindableEvent")
	newEvent.Name = tostring(eventName)
	newEvent.Parent = script

	return newEvent
end

function createPublicFunction(funcName, invokeFunc)
	assert(funcName, "funcName is nil")
	assert(tostring(funcName), "funcName is not a string")
	assert(invokeFunc, "invokeFunc is nil")
	assert(type(invokeFunc) == "function", "invokeFunc should be of type 'function'")
	
	local newFunction = Instance.new("BindableFunction")
	newFunction.Name = tostring(funcName)
	newFunction.OnInvoke = invokeFunc
	newFunction.Parent = script

	return newFunction
end

-- Events 
local resizeEvent = createPublicEvent("ResizeEvent")
local backpackOpenEvent = createPublicEvent("BackpackOpenEvent")
local backpackCloseEvent = createPublicEvent("BackpackCloseEvent")
local tabClickedEvent = createPublicEvent("TabClickedEvent")
local searchRequestedEvent = createPublicEvent("SearchRequestedEvent")
---------------------------------------- End Public Event Setup ----------------------------------------



--------------------------- Internal Functions ----------------------------------------

function deactivateBackpack()
	backpack.Visible = false
	active = false
end

function activateBackpack()
	initHumanoidDiedConnections()		
	active = true
	backpack.Visible = backpackIsOpen
	if backpackIsOpen then 
		toggleBackpack() 
	end 
end

function initHumanoidDiedConnections()			
	if humanoidDiedCon then 
		humanoidDiedCon:disconnect()
	end
	waitForProperty(game.Players.LocalPlayer,"Character")
	waitForChild(game.Players.LocalPlayer.Character,"Humanoid")
	humanoidDiedCon = game.Players.LocalPlayer.Character.Humanoid.Died:connect(deactivateBackpack)
end

local hideBackpack = function()
	backpackIsOpen = false
	readyForNextEvent = false
	backpackButton.Selected = false
	resetSearch()
	backpackCloseEvent:Fire(currentTab)
	backpack.Tabs.Visible = false
	searchFrame.Visible = false
	backpack:TweenSizeAndPosition(UDim2.new(0, backpackSize.X.Offset,0, 0), UDim2.new(0.5, -backpackSize.X.Offset/2, 1, -85), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, guiTweenSpeed, true,
		function()
			game.GuiService:RemoveCenterDialog(backpack)
			backpack.Visible = false
			backpackButton.Selected = false
		end)
	delay(guiTweenSpeed,function()
		game.GuiService:RemoveCenterDialog(backpack)
		backpack.Visible = false
		backpackButton.Selected = false
		readyForNextEvent = true		
		canToggle = true
	end)
end

function showBackpack()
	game.GuiService:AddCenterDialog(backpack, Enum.CenterDialogType.PlayerInitiatedDialog, 
		function()
			backpack.Visible = true
			backpackButton.Selected = true
		end,
		function()
			backpack.Visible = false
			backpackButton.Selected = false
	end)
	backpack.Visible = true
	backpackButton.Selected = true	
	backpack:TweenSizeAndPosition(backpackSize, UDim2.new(0.5, -backpackSize.X.Offset/2, 1, -backpackSize.Y.Offset - 88), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, guiTweenSpeed, true)
	delay(guiTweenSpeed,function()
		backpack.Tabs.Visible = false
		searchFrame.Visible = true
		backpackOpenEvent:Fire(currentTab)
		canToggle = true
		readyForNextEvent = true
		backpackButton.Image = 'http://www.roblox.com/asset/?id=97644093'
		backpackButton.Position = UDim2.new(0.5, -60, 1, -backpackSize.Y.Offset - 103)
	end)
end

function toggleBackpack()	
	if not game.Players.LocalPlayer then return end
	if not game.Players.LocalPlayer["Character"] then return end
	if not canToggle then return end
	if not readyForNextEvent then return end
	readyForNextEvent = false
	canToggle = false
	
	backpackIsOpen = not backpackIsOpen

	if backpackIsOpen then				
		loadoutBackground.Image = 'http://www.roblox.com/asset/?id=97623721'
		loadoutBackground.Position = UDim2.new(-0.03, 0, -0.17, 0)
		loadoutBackground.Size = UDim2.new(1.05, 0, 1.25, 0)
		loadoutBackground.ZIndex = 2.0
		loadoutBackground.Visible = true
		showBackpack()
	else		
		backpackButton.Position = UDim2.new(0.5, -60, 1, -44)
		loadoutBackground.Visible = false
		backpackButton.Selected = false		
		backpackButton.Image = "http://www.roblox.com/asset/?id=97617958"
		loadoutBackground.Image = 'http://www.roblox.com/asset/?id=96536002'
		loadoutBackground.Position = UDim2.new(-0.1, 0, -0.1, 0)
		loadoutBackground.Size = UDim2.new(1.2, 0, 1.2, 0)		
		hideBackpack()

		
		local clChildren = currentLoadout:GetChildren()
		for i = 1, #clChildren do 
			if clChildren[i] and clChildren[i]:IsA('Frame') then 
				local frame = clChildren[i] 
				if #frame:GetChildren() > 0 then 
					backpackButton.Position = UDim2.new(0.5, -60, 1, -108)
					backpackButton.Visible = true
					loadoutBackground.Visible = true
					if frame:GetChildren()[1]:IsA('ImageButton') then 
						local imgButton = frame:GetChildren()[1]
						imgButton.Active = true 
						imgButton.Draggable = false 
					end 
				end 
			end 
		end 
		
	end
end

function closeBackpack()
	if backpackIsOpen then
		toggleBackpack()
	end
end

function setSelected(tab)
	assert(tab)
	assert(tab:IsA("TextButton"))
	
	tab.BackgroundColor3 = Color3.new(1,1,1)
	tab.TextColor3 = Color3.new(0,0,0)
	tab.Selected = true
	tab.ZIndex = 3
end

function setUnselected(tab)
	assert(tab)
	assert(tab:IsA("TextButton"))
	
	tab.BackgroundColor3 = Color3.new(0,0,0)
	tab.TextColor3 = Color3.new(1,1,1)
	tab.Selected = false
	tab.ZIndex = 1
end

function updateTabGui(selectedTab)
	assert(selectedTab)
	
	if selectedTab == "gear" then
		setSelected(inventoryButton)
		setUnselected(wardrobeButton)
	elseif selectedTab == "wardrobe" then
		setSelected(wardrobeButton)
		setUnselected(inventoryButton)
	end
end

function mouseLeaveTab(button)
	assert(button)
	assert(button:IsA("TextButton"))
	
	if button.Selected then return end
	
	button.BackgroundColor3 = Color3.new(0,0,0)
end

function mouseOverTab(button)
	assert(button)
	assert(button:IsA("TextButton"))
	
	if button.Selected then return end
	
	button.BackgroundColor3 = Color3.new(39/255,39/255,39/255)
end

function newTabClicked(tabName)
	assert(tabName)
	tabName = string.lower(tabName)
	currentTab = tabName
	
	updateTabGui(tabName)
	tabClickedEvent:Fire(tabName)
	resetSearch()
end

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function splitByWhitespace(text)
	if type(text) ~= "string" then return nil end
	
	local terms = {}
	for token in string.gmatch(text, "[^%s]+") do
	   if string.len(token) > 0 then
			table.insert(terms,token)
	   end
	end
	return terms
end

function resetSearchBoxGui()
	resetButton.Visible = false
	searchBox.Text = searchDefaultText
end

function doSearch()
	local searchText = searchBox.Text
	if searchText == "" then
		resetSearch()
		return
	end
	searchText = trim(searchText)
	resetButton.Visible = true
	termTable = splitByWhitespace(searchText)
	searchRequestedEvent:Fire(searchText) -- todo: replace this with termtable when table passing is possible
end

function resetSearch()
	resetSearchBoxGui()
	searchRequestedEvent:Fire()
end

local backpackReady = function()
	readyForNextEvent = true
end

function coreGuiChanged(coreGuiType,enabled)
	if coreGuiType == Enum.CoreGuiType.Backpack or coreGuiType == Enum.CoreGuiType.All then
		active = enabled
		disabledByDeveloper = not enabled

		if disabledByDeveloper then
			game:GetService("GuiService"):RemoveKey(tilde)
			game:GetService("GuiService"):RemoveKey(backquote)
		else
			game:GetService("GuiService"):AddKey(tilde)
			game:GetService("GuiService"):AddKey(backquote)
		end

		resetSearch()
		searchFrame.Visible = enabled and backpackIsOpen

		currentLoadout.Visible = enabled
		backpack.Visible = enabled
		backpackButton.Visible = enabled
	end
end

--------------------------- End Internal Functions -------------------------------------


------------------------------ Public Functions Setup -------------------------------------
createPublicFunction("CloseBackpack", hideBackpack)
createPublicFunction("BackpackReady", backpackReady)
------------------------------ End Public Functions Setup ---------------------------------


------------------------ Connections/Script Main -------------------------------------------

coreGuiChanged(Enum.CoreGuiType.Backpack, Game.StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack))
Game.StarterGui.CoreGuiChangedSignal:connect(coreGuiChanged)

inventoryButton.MouseButton1Click:connect(function() newTabClicked("gear") end)
inventoryButton.MouseEnter:connect(function() mouseOverTab(inventoryButton) end)
inventoryButton.MouseLeave:connect(function() mouseLeaveTab(inventoryButton) end)

if game.CoreGui.Version >= 8 then
	wardrobeButton.MouseButton1Click:connect(function() newTabClicked("wardrobe") end)
	wardrobeButton.MouseEnter:connect(function() mouseOverTab(wardrobeButton) end)
	wardrobeButton.MouseLeave:connect(function() mouseLeaveTab(wardrobeButton) end)
end

closeButton.MouseButton1Click:connect(closeBackpack)

screen.Changed:connect(function(prop)
	if prop == "AbsoluteSize" then
		resizeEvent:Fire(screen.AbsoluteSize)
	end
end)

-- GuiService key setup
game:GetService("GuiService"):AddKey(tilde)
game:GetService("GuiService"):AddKey(backquote)
game:GetService("GuiService").KeyPressed:connect(function(key)
	if not active or disabledByDeveloper then return end
	if key == tilde or key == backquote then
		toggleBackpack()
	end
end)
backpackButton.MouseButton1Click:connect(function() 
	if not active or disabledByDeveloper then return end
	toggleBackpack()
end)

if game.Players.LocalPlayer["Character"] then
	activateBackpack()
end

game.Players.LocalPlayer.CharacterAdded:connect(activateBackpack)

-- search functions
searchBox.FocusLost:connect(function(enterPressed)
	if enterPressed or searchBox.Text ~= "" then
		doSearch()
	elseif searchBox.Text == "" then
		resetSearch()
	end
end)
searchButton.MouseButton1Click:connect(doSearch)
resetButton.MouseButton1Click:connect(resetSearch)

if searchFrame and robloxGui.AbsoluteSize.Y <= 320 then  
	searchFrame.RobloxLocked = false 
	searchFrame:Destroy() 
end 