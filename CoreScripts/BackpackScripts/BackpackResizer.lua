if game.CoreGui.Version < 3 then return end -- peace out if we aren't using the right client

-- A couple of necessary functions
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

waitForChild(game,"Players")
waitForProperty(game.Players,"LocalPlayer")
local player = game.Players.LocalPlayer

local RbxGui,msg = LoadLibrary("RbxGui")
if not RbxGui then print("could not find RbxGui!") return end

--- Begin Locals
waitForChild(game,"Players")

-- don't do anything if we are in an empty game
if #game.Players:GetChildren() < 1 then
	game.Players.ChildAdded:wait()
end

local tilde = "~"
local backquote = "`"
game:GetService("GuiService"):AddKey(tilde) -- register our keys
game:GetService("GuiService"):AddKey(backquote)

local player = game.Players.LocalPlayer

local backpack = script.Parent
local screen = script.Parent.Parent
local closeButton = backpack.Tabs.CloseButton

local openCloseDebounce = false

local backpackItems = {}

local buttons = {}

local debounce = false

local guiTweenSpeed = 1

local backpackOldStateVisible = false
local browsingMenu = false

local mouseEnterCons = {}
local mouseClickCons = {}

local characterChildAddedCon = nil
local characterChildRemovedCon = nil
local backpackAddCon = nil
local humanoidDiedCon = nil
local backpackButtonClickCon = nil
local guiServiceKeyPressCon = nil

waitForChild(player,"Backpack")
local playerBackpack = player.Backpack

waitForChild(backpack,"Gear")
waitForChild(backpack.Gear,"GearPreview")
local gearPreview = backpack.Gear.GearPreview

waitForChild(backpack.Gear,"GearGridScrollingArea")
local scroller = backpack.Gear.GearGridScrollingArea

waitForChild(backpack.Parent,"CurrentLoadout")
local currentLoadout = backpack.Parent.CurrentLoadout

waitForChild(backpack.Parent,"ControlFrame")
waitForChild(backpack.Parent.ControlFrame,"BackpackButton")
local backpackButton = backpack.Parent.ControlFrame.BackpackButton

waitForChild(backpack.Gear,"GearGrid")
waitForChild(backpack.Gear.GearGrid,"GearButton")
local gearButton = backpack.Gear.GearGrid.GearButton
local grid = backpack.Gear.GearGrid

waitForChild(backpack.Gear.GearGrid,"SearchFrame")
waitForChild(backpack.Gear.GearGrid.SearchFrame,"SearchBoxFrame")
waitForChild(backpack.Gear.GearGrid.SearchFrame.SearchBoxFrame,"SearchBox")
local searchBox = backpack.Gear.GearGrid.SearchFrame.SearchBoxFrame.SearchBox

waitForChild(backpack.Gear.GearGrid.SearchFrame,"SearchButton")
local searchButton = backpack.Gear.GearGrid.SearchFrame.SearchButton

waitForChild(backpack.Gear.GearGrid,"ResetFrame")
local resetFrame = backpack.Gear.GearGrid.ResetFrame

waitForChild(backpack.Gear.GearGrid.ResetFrame,"ResetButtonBorder")
local resetButton = backpack.Gear.GearGrid.ResetFrame.ResetButtonBorder

waitForChild(script.Parent,"SwapSlot")
local swapSlot = script.Parent.SwapSlot


-- creating scroll bar early as to make sure items get placed correctly
local scrollFrame, scrollUp, scrollDown, recalculateScroll = RbxGui.CreateScrollingFrame(nil, "grid", Vector2.new(4, 4))

scrollFrame.Position = UDim2.new(0,0,0,30)
scrollFrame.Size = UDim2.new(1,0,1,-30)
scrollFrame.Parent = backpack.Gear.GearGrid

local scrollBar = Instance.new("Frame")
scrollBar.Name = "ScrollBar"
scrollBar.BackgroundTransparency = 0.9
scrollBar.BackgroundColor3 = Color3.new(1,1,1)
scrollBar.BorderSizePixel = 0
scrollBar.Size = UDim2.new(0, 17, 1, -36)
scrollBar.Position = UDim2.new(0,0,0,18)
scrollBar.Parent = scroller

scrollDown.Position = UDim2.new(0,0,1,-17)

scrollUp.Parent = scroller
scrollDown.Parent = scroller

local scrollFrameLoadout, scrollUpLoadout, scrollDownLoadout, recalculateScrollLoadout = RbxGui.CreateScrollingFrame()

scrollFrameLoadout.Position = UDim2.new(0,0,0,0)
scrollFrameLoadout.Size = UDim2.new(1,0,1,0)
scrollFrameLoadout.Parent = backpack.Gear.GearLoadouts.LoadoutsList

local LoadoutButton = Instance.new("TextButton")
LoadoutButton.RobloxLocked = true
LoadoutButton.Name = "LoadoutButton"
LoadoutButton.Font = Enum.Font.ArialBold
LoadoutButton.FontSize = Enum.FontSize.Size14
LoadoutButton.Position = UDim2.new(0,0,0,0)
LoadoutButton.Size = UDim2.new(1,0,0,32)
LoadoutButton.Style = Enum.ButtonStyle.RobloxButton
LoadoutButton.Text = "Loadout #1"
LoadoutButton.TextColor3 = Color3.new(1,1,1)
LoadoutButton.Parent = scrollFrameLoadout

local LoadoutButtonTwo = LoadoutButton:clone()
LoadoutButtonTwo.Text = "Loadout #2"
LoadoutButtonTwo.Parent = scrollFrameLoadout

local LoadoutButtonThree = LoadoutButton:clone()
LoadoutButtonThree.Text = "Loadout #3"
LoadoutButtonThree.Parent = scrollFrameLoadout

local LoadoutButtonFour = LoadoutButton:clone()
LoadoutButtonFour.Text = "Loadout #4"
LoadoutButtonFour.Parent = scrollFrameLoadout

local scrollBarLoadout = Instance.new("Frame")
scrollBarLoadout.Name = "ScrollBarLoadout"
scrollBarLoadout.BackgroundTransparency = 0.9
scrollBarLoadout.BackgroundColor3 = Color3.new(1,1,1)
scrollBarLoadout.BorderSizePixel = 0
scrollBarLoadout.Size = UDim2.new(0, 17, 1, -36)
scrollBarLoadout.Position = UDim2.new(0,0,0,18)
scrollBarLoadout.Parent = backpack.Gear.GearLoadouts.GearLoadoutsScrollingArea

scrollDownLoadout.Position = UDim2.new(0,0,1,-17)

scrollUpLoadout.Parent = backpack.Gear.GearLoadouts.GearLoadoutsScrollingArea
scrollDownLoadout.Parent = backpack.Gear.GearLoadouts.GearLoadoutsScrollingArea


-- Begin Functions
function removeFromMap(map,object)
	for i = 1, #map do
		if map[i] == object then
			table.remove(map,i)
			break
		end
	end
end

function robloxLock(instance)
  instance.RobloxLocked = true
  children = instance:GetChildren()
  if children then
	 for i, child in ipairs(children) do
		robloxLock(child)
	 end
  end
end

function resize()
	local size = 0
	if gearPreview.AbsoluteSize.Y > gearPreview.AbsoluteSize.X then
		size = gearPreview.AbsoluteSize.X * 0.75
	else
		size = gearPreview.AbsoluteSize.Y * 0.75
	end

	gearPreview.GearImage.Size = UDim2.new(0,size,0,size)
	gearPreview.GearImage.Position = UDim2.new(0,gearPreview.AbsoluteSize.X/2 - size/2,0.75,-size)
	
	resizeGrid()
end

function addToGrid(child)
	if not child:IsA("Tool") then
		if not child:IsA("HopperBin") then 
			return
		end
	end
	if child:FindFirstChild("RobloxBuildTool") then return end
	
	for i,v in pairs(backpackItems) do  -- check to see if we already have this gear registered
		if v == child then return end
	end

	table.insert(backpackItems,child)
	
	local changeCon = child.Changed:connect(function(prop)
		if prop == "Name" then
			if buttons[child] then
				if buttons[child].Image == "" then
					buttons[child].GearText.Text = child.Name
				end
			end
		end
	end)
	local ancestryCon = nil
	ancestryCon = child.AncestryChanged:connect(function(theChild,theParent)
		local thisObject = nil
		for k,v in pairs(backpackItems) do
			if v == child then
				thisObject = v
				break
			end
		end
		
		waitForProperty(player,"Character")
		waitForChild(player,"Backpack")
		if (child.Parent ~= player.Backpack and child.Parent ~= player.Character) then
			if ancestryCon then ancestryCon:disconnect() end
			if changeCon then changeCon:disconnect() end
			
			for k,v in pairs(backpackItems) do
				if v == thisObject then
					if mouseEnterCons[buttons[v]] then mouseEnterCons[buttons[v]]:disconnect() end
					if mouseClickCons[buttons[v]] then mouseClickCons[buttons[v]]:disconnect() end
					buttons[v].Parent = nil
					buttons[v] = nil
					break
				end
			end

			removeFromMap(backpackItems,thisObject)
			
			resizeGrid()
		else
			resizeGrid()
		end
		updateGridActive()
	end)
	resizeGrid()
end

function buttonClick(button)
	if button:FindFirstChild("UnequipContextMenu") and not button.Active then
		button.UnequipContextMenu.Visible = true
		browsingMenu = true
	end
end

function previewGear(button)
	if not browsingMenu then
		gearPreview.GearImage.Image = button.Image
		gearPreview.GearStats.GearName.Text = button.GearReference.Value.Name
	end
end

function findEmptySlot()
	local smallestNum = nil
	local loadout = currentLoadout:GetChildren()
	for i = 1, #loadout do
		if loadout[i]:IsA("Frame") and #loadout[i]:GetChildren() <= 0 then
			local frameNum = tonumber(string.sub(loadout[i].Name,5))
			if frameNum == 0 then frameNum = 10 end
			if not smallestNum or (smallestNum > frameNum) then
				smallestNum = frameNum
			end
		end
	end
	if smallestNum == 10 then smallestNum = 0 end
	return smallestNum
end

function checkForSwap(button,x,y)
	local loadoutChildren = currentLoadout:GetChildren()
	for i = 1, #loadoutChildren do
		if loadoutChildren[i]:IsA("Frame") and string.find(loadoutChildren[i].Name,"Slot") then
			if x >= loadoutChildren[i].AbsolutePosition.x and x <= (loadoutChildren[i].AbsolutePosition.x + loadoutChildren[i].AbsoluteSize.x) then
				if y >= loadoutChildren[i].AbsolutePosition.y and y <= (loadoutChildren[i].AbsolutePosition.y + loadoutChildren[i].AbsoluteSize.y) then
					local slot = tonumber(string.sub(loadoutChildren[i].Name,5))
					swapGearSlot(slot,button)
					return true
				end
			end
		end
	end
	return false
end

function resizeGrid()
	for k,v in pairs(backpackItems) do
		if not v:FindFirstChild("RobloxBuildTool") then
			if not buttons[v] then
				local buttonClone = gearButton:clone()
				buttonClone.Parent = grid.ScrollingFrame
				buttonClone.Visible = true
				buttonClone.Image = v.TextureId
				if buttonClone.Image == "" then
					buttonClone.GearText.Text = v.Name
				end

				buttonClone.GearReference.Value = v
				buttonClone.Draggable = true 
				buttons[v] = buttonClone
				
				local unequipMenu = getGearContextMenu()
				
				unequipMenu.Visible = false
				unequipMenu.Parent = buttonClone
				
				local beginPos = nil
				buttonClone.DragBegin:connect(function(value)
					buttonClone.ZIndex = 9
					beginPos = value
				end)
				buttonClone.DragStopped:connect(function(x,y)
					buttonClone.ZIndex = 1
					if beginPos ~= buttonClone.Position then
						if not checkForSwap(buttonClone,x,y) then
							buttonClone:TweenPosition(beginPos,Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)
							buttonClone.Draggable = false
							delay(0.5,function()
								buttonClone.Draggable = true
							end)
						else
							buttonClone.Position = beginPos
						end
					end	
				end)
				local clickTime = tick()
				mouseEnterCons[buttonClone] = buttonClone.MouseEnter:connect(function() previewGear(buttonClone) end)
				mouseClickCons[buttonClone] = buttonClone.MouseButton1Click:connect(function()
					local newClickTime = tick()
					if buttonClone.Active and (newClickTime - clickTime) < 0.5 then
						local slot = findEmptySlot()
						if slot then
							buttonClone.ZIndex = 1
							swapGearSlot(slot,buttonClone)
						end
					else
						buttonClick(buttonClone)
					end
					clickTime = newClickTime
				end)
			end
		end
	end
	recalculateScroll()
end

function showPartialGrid(subset)

	resetFrame.Visible = true

	for k,v in pairs(buttons) do
		v.Parent = nil
	end
	for k,v in pairs(subset) do
		v.Parent =  grid.ScrollingFrame
	end
	recalculateScroll()
end

function showEntireGrid()
	resetFrame.Visible = false
	
	for k,v in pairs(buttons) do
		v.Parent = grid.ScrollingFrame
	end
	recalculateScroll()
end

function inLoadout(gear)
	local children = currentLoadout:GetChildren()
	for i = 1, #children do
		if children[i]:IsA("Frame") then
			local button = children[i]:GetChildren()
			if #button > 0 then
				if button[1].GearReference.Value and button[1].GearReference.Value == gear then
					return true
				end
			end
		end
	end
	return false
end	

function updateGridActive()
	for k,v in pairs(backpackItems) do
		if buttons[v] then
			local gear = nil
			local gearRef = buttons[v]:FindFirstChild("GearReference")
			
			if gearRef then gear = gearRef.Value end
			
			if not gear then
				buttons[v].Active = false
			elseif inLoadout(gear) then
				buttons[v].Active = false
			else
				buttons[v].Active = true
			end
		end
	end
end

function centerGear(loadoutChildren)
	local gearButtons = {}
	local lastSlotAdd = nil
	for i = 1, #loadoutChildren do
		if loadoutChildren[i]:IsA("Frame") and #loadoutChildren[i]:GetChildren() > 0 then
			if loadoutChildren[i].Name == "Slot0" then 
				lastSlotAdd = loadoutChildren[i]
			else
				table.insert(gearButtons, loadoutChildren[i])
			end
		end
	end
	if lastSlotAdd then table.insert(gearButtons,lastSlotAdd) end
	
	local startPos = ( 1 - (#gearButtons * 0.1) ) / 2
	for i = 1, #gearButtons do	
		gearButtons[i]:TweenPosition(UDim2.new(startPos + ((i - 1) * 0.1),0,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
	end
end

function spreadOutGear(loadoutChildren)
	for i = 1, #loadoutChildren do
		if loadoutChildren[i]:IsA("Frame") then
			local slot = tonumber(string.sub(loadoutChildren[i].Name,5))
			if slot == 0 then slot = 10 end
			loadoutChildren[i]:TweenPosition(UDim2.new((slot - 1)/10,0,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
		end
	end
end

function openCloseBackpack(close)
	if openCloseDebounce then return end
	openCloseDebounce = true

	local visible = not backpack.Visible
	if visible and not close then
		updateGridActive()
		local centerDialogSupported, msg = pcall(function() game.GuiService:AddCenterDialog(backpack, Enum.CenterDialogType.PlayerInitiatedDialog, 
			function()
				backpack.Visible = true
				loadoutChildren = currentLoadout:GetChildren()
				for i = 1, #loadoutChildren do
					if loadoutChildren[i]:IsA("Frame") then
						loadoutChildren[i].BackgroundTransparency = 0.5
					end
				end 
				spreadOutGear(loadoutChildren)
			end,
			function()
				backpack.Visible = false
			end)
		end)
		backpackButton.Selected = true
		backpack:TweenSizeAndPosition(UDim2.new(0.55, 0, 0.6, 0),UDim2.new(0.225, 0, 0.2, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, guiTweenSpeed/2, true)
		delay(guiTweenSpeed/2 + 0.01,
			function()
				local children = backpack:GetChildren()
				for i = 1, #children do
					if children[i]:IsA("Frame") then
						children[i].Visible = true
					end
				end
				resizeGrid()
				resize()
				openCloseDebounce = false
			end)
	else
		backpackButton.Selected = false
		local children = backpack:GetChildren()
		for i = 1, #children do
			if children[i]:IsA("Frame") then
				children[i].Visible = false
			end
		end
		loadoutChildren = currentLoadout:GetChildren()
		for i = 1, #loadoutChildren do
			if loadoutChildren[i]:IsA("Frame") then
				loadoutChildren[i].BackgroundTransparency = 1
			end
		end
		centerGear(loadoutChildren)
	
		backpack:TweenSizeAndPosition(UDim2.new(0,0,0,0),UDim2.new(0.5,0,0.5,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, guiTweenSpeed/2, true)
		delay(guiTweenSpeed/2 + 0.01,
			function()
				backpack.Visible = visible
				resizeGrid()
				resize()
				pcall(function() game.GuiService:RemoveCenterDialog(backpack) end)
				openCloseDebounce = false
			end)
	end
end

function loadoutCheck(child, selectState)
	if not child:IsA("ImageButton") then return end
	for k,v in pairs(backpackItems) do
		if buttons[v] then
			if child:FindFirstChild("GearReference") and buttons[v]:FindFirstChild("GearReference") then
				if buttons[v].GearReference.Value == child.GearReference.Value then
					buttons[v].Active = selectState
					break
				end
			end
		end
	end
end

function clearPreview()
	gearPreview.GearImage.Image = ""
	gearPreview.GearStats.GearName.Text = ""
end

function removeAllEquippedGear(physGear)
	local stuff = player.Character:GetChildren()
	for i = 1, #stuff do
		if ( stuff[i]:IsA("Tool") or stuff[i]:IsA("HopperBin") ) and stuff[i] ~= physGear then
			stuff[i].Parent = playerBackpack
		end
	end
end

function equipGear(physGear)
	removeAllEquippedGear(physGear)
	physGear.Parent = player.Character
	updateGridActive()
end

function unequipGear(physGear)
	physGear.Parent = playerBackpack
	updateGridActive()
end

function highlight(button)
	button.TextColor3 = Color3.new(0,0,0)
	button.BackgroundColor3 = Color3.new(0.8,0.8,0.8)
end
function clearHighlight(button)
	button.TextColor3 = Color3.new(1,1,1)
	button.BackgroundColor3 = Color3.new(0,0,0)
end

function swapGearSlot(slot,gearButton)
	if not swapSlot.Value then -- signal loadout to swap a gear out
		swapSlot.Slot.Value = slot
		swapSlot.GearButton.Value = gearButton
		swapSlot.Value = true
		updateGridActive()
	end
end


local UnequipGearMenuClick = function(element, menu)
	if type(element.Action) ~= "number" then return end
	local num = element.Action
	if num == 1 then -- remove from loadout
		unequipGear(menu.Parent.GearReference.Value)
		local inventoryButton = menu.Parent
		local gearToUnequip = inventoryButton.GearReference.Value
		local loadoutChildren = currentLoadout:GetChildren()
		local slot = -1
		for i = 1, #loadoutChildren do
			if loadoutChildren[i]:IsA("Frame") then
				local button = loadoutChildren[i]:GetChildren()
				if button[1] and button[1].GearReference.Value == gearToUnequip then
					slot = button[1].SlotNumber.Text
					break
				end
			end
		end
		swapGearSlot(slot,nil)
	end
end

-- these next two functions are used to stop any use of backpack while the player is dead (can cause issues)
function activateBackpack()
	backpack.Visible = backpackOldStateVisible
	
	loadoutChildren = currentLoadout:GetChildren()
	for i = 1, #loadoutChildren do
		if loadoutChildren[i]:IsA("Frame") then
			loadoutChildren[i].BackgroundTransparency = 1
		end
	end

	backpackButtonClickCon = backpackButton.MouseButton1Click:connect(function() openCloseBackpack() end)
	guiServiceKeyPressCon = game:GetService("GuiService").KeyPressed:connect(function(key)
		if key == tilde or key == backquote then
			openCloseBackpack()
		end
	end)
end
function deactivateBackpack()
	if backpackButtonClickCon then backpackButtonClickCon:disconnect() end
	if guiServiceKeyPressCon then guiServiceKeyPressCon:disconnect() end

	backpackOldStateVisible = backpack.Visible
	backpack.Visible = false
	openCloseBackpack(true)
end

function setupCharacterConnections()

	if backpackAddCon then backpackAddCon:disconnect() end
	backpackAddCon = game.Players.LocalPlayer.Backpack.ChildAdded:connect(function(child) addToGrid(child) end)
	
	-- make sure we get all the children
	local backpackChildren = game.Players.LocalPlayer.Backpack:GetChildren()
	for i = 1, #backpackChildren do
		addToGrid(backpackChildren[i])
	end

	if characterChildAddedCon then characterChildAddedCon:disconnect() end
	characterChildAddedCon = 
		game.Players.LocalPlayer.Character.ChildAdded:connect(function(child)
			addToGrid(child)
			updateGridActive()
		end)
		
	if characterChildRemovedCon then characterChildRemovedCon:disconnect() end
	characterChildRemovedCon = 
		game.Players.LocalPlayer.Character.ChildRemoved:connect(function(child)
			updateGridActive()
		end)
		
			
	if humanoidDiedCon then humanoidDiedCon:disconnect() end
	local localPlayer = game.Players.LocalPlayer
	waitForProperty(localPlayer,"Character")
	waitForChild(localPlayer.Character,"Humanoid")
	humanoidDiedCon = game.Players.LocalPlayer.Character.Humanoid.Died:connect(function() deactivateBackpack() end)
	
	activateBackpack()

	wait()
	centerGear(currentLoadout:GetChildren())
end

function removeCharacterConnections()
	if characterChildAddedCon then characterChildAddedCon:disconnect() end
	if characterChildRemovedCon then characterChildRemovedCon:disconnect() end
	if backpackAddCon then backpackAddCon:disconnect() end
end

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function splitByWhiteSpace(text)
	if type(text) ~= "string" then return nil end
	
	local terms = {}
	for token in string.gmatch(text, "[^%s]+") do
	   if string.len(token) > 2 then
			table.insert(terms,token)
	   end
	end
	return terms
end

function filterGear(searchTerm)
	string.lower(searchTerm)
	searchTerm = trim(searchTerm)
	if string.len(searchTerm) < 2 then return nil end
	local terms = splitByWhiteSpace(searchTerm)
	
	local filteredGear = {}
	for k,v in pairs(backpackItems) do
		if buttons[v] then
			local gearString = string.lower(buttons[v].GearReference.Value.Name)
			gearString = trim(gearString)
			for i = 1, #terms do
				if string.match(gearString,terms[i]) then
					table.insert(filteredGear,buttons[v])
					break
				end
			end
		end
	end
	
	return filteredGear
end


function showSearchGear()
	local searchText = searchBox.Text
	searchBox.Text = "Search..."
	local filteredButtons = filterGear(searchText)
	if filteredButtons and #filteredButtons > 0 then
		showPartialGrid(filteredButtons)
	else
		showEntireGrid()
	end
end

function nukeBackpack()
	while #buttons > 0 do
		table.remove(buttons)
	end
	buttons = {}
	while #backpackItems > 0 do
		table.remove(backpackItems)
	end
	backpackItems = {}
	local scrollingFrameChildren = grid.ScrollingFrame:GetChildren()
	for i = 1, #scrollingFrameChildren do
		scrollingFrameChildren[i]:remove()
	end
end

function getGearContextMenu()
	local gearContextMenu = Instance.new("Frame")
	gearContextMenu.Active = true
	gearContextMenu.Name = "UnequipContextMenu"
	gearContextMenu.Size = UDim2.new(0,115,0,70)
	gearContextMenu.Position = UDim2.new(0,-16,0,-16)
	gearContextMenu.BackgroundTransparency = 1
	gearContextMenu.Visible = false

	local gearContextMenuButton = Instance.new("TextButton")
	gearContextMenuButton.Name = "UnequipContextMenuButton"
	gearContextMenuButton.Text = ""
	gearContextMenuButton.Style = Enum.ButtonStyle.RobloxButtonDefault
	gearContextMenuButton.ZIndex = 8
	gearContextMenuButton.Size = UDim2.new(1, 0, 1, -20)
	gearContextMenuButton.Visible = true
	gearContextMenuButton.Parent = gearContextMenu
	
	local elementHeight = 12
	
	local contextMenuElements = {}		
	local contextMenuElementsName = {"Remove Hotkey"}

	for i = 1, #contextMenuElementsName do
		local element = {}
		element.Type = "Button"
		element.Text = contextMenuElementsName[i]
		element.Action = i
		element.DoIt = UnequipGearMenuClick
		table.insert(contextMenuElements,element)
	end

	for i, contextElement in ipairs(contextMenuElements) do
		local element = contextElement
		if element.Type == "Button" then
			local button = Instance.new("TextButton")
			button.Name = "UnequipContextButton" .. i
			button.BackgroundColor3 = Color3.new(0,0,0)
			button.BorderSizePixel = 0
			button.TextXAlignment = Enum.TextXAlignment.Left
			button.Text = " " .. contextElement.Text
			button.Font = Enum.Font.Arial
			button.FontSize = Enum.FontSize.Size14
			button.Size = UDim2.new(1, 8, 0, elementHeight)
			button.Position = UDim2.new(0,0,0,elementHeight * i)
			button.TextColor3 = Color3.new(1,1,1)
			button.ZIndex = 9
			button.Parent = gearContextMenuButton

			button.MouseButton1Click:connect(function()
				if button.Active and not gearContextMenu.Parent.Active then
					local success, result = pcall(function() element.DoIt(element, gearContextMenu) end)
					browsingMenu = false
					gearContextMenu.Visible = false
					clearHighlight(button)
					clearPreview()
				end
			end)
			
			button.MouseEnter:connect(function()
				if button.Active and gearContextMenu.Parent.Active then
					highlight(button)
				end
			end)
			button.MouseLeave:connect(function()
				if button.Active and gearContextMenu.Parent.Active then
					clearHighlight(button)
				end
			end)
			
			contextElement.Button = button
			contextElement.Element = button
		elseif element.Type == "Label" then
			local frame = Instance.new("Frame")
			frame.Name = "ContextLabel" .. i
			frame.BackgroundTransparency = 1
			frame.Size = UDim2.new(1, 8, 0, elementHeight)

			local label = Instance.new("TextLabel")	
			label.Name = "Text1"
			label.BackgroundTransparency = 1
			label.BackgroundColor3 = Color3.new(1,1,1)
			label.BorderSizePixel = 0
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Font = Enum.Font.ArialBold
			label.FontSize = Enum.FontSize.Size14
			label.Position = UDim2.new(0.0, 0, 0, 0)
			label.Size = UDim2.new(0.5, 0, 1, 0)
			label.TextColor3 = Color3.new(1,1,1)
			label.ZIndex = 9
			label.Parent = frame
			element.Label1 = label
		
			if element.GetText2 then
				label = Instance.new("TextLabel")	
				label.Name = "Text2"
				label.BackgroundTransparency = 1
				label.BackgroundColor3 = Color3.new(1,1,1)
				label.BorderSizePixel = 0
				label.TextXAlignment = Enum.TextXAlignment.Right
				label.Font = Enum.Font.Arial
				label.FontSize = Enum.FontSize.Size14
				label.Position = UDim2.new(0.5, 0, 0, 0)
				label.Size = UDim2.new(0.5, 0, 1, 0)
				label.TextColor3 = Color3.new(1,1,1)
				label.ZIndex = 9
				label.Parent = frame
				element.Label2 = label
			end
			frame.Parent = gearContextMenuButton
			element.Label = frame
			element.Element =  frame
		end
	end

	gearContextMenu.ZIndex = 4
	gearContextMenu.MouseLeave:connect(function()
		browsingMenu = false
		gearContextMenu.Visible = false
		clearPreview()
	end)
	robloxLock(gearContextMenu)
	
	return gearContextMenu
end

local backpackChildren = player.Backpack:GetChildren()
for i = 1, #backpackChildren do
	addToGrid(backpackChildren[i])
end

------------------------- Start Lifelong Connections -----------------------
screen.Changed:connect(function(prop)
	if prop == "AbsoluteSize" then
		if debounce then return end
		debounce = true
		wait()
		resize()
		resizeGrid()
		debounce = false
	end
end)

currentLoadout.ChildAdded:connect(function(child) loadoutCheck(child, false) end)
currentLoadout.ChildRemoved:connect(function(child) loadoutCheck(child, true) end)

currentLoadout.DescendantAdded:connect(function(descendant)
	if not backpack.Visible and ( descendant:IsA("ImageButton") or descendant:IsA("TextButton") ) then
		centerGear(currentLoadout:GetChildren())
	end
end)
currentLoadout.DescendantRemoving:connect(function(descendant)
	if not backpack.Visible and ( descendant:IsA("ImageButton") or descendant:IsA("TextButton") ) then
		wait()
		centerGear(currentLoadout:GetChildren())
	end
end)
	
grid.MouseEnter:connect(function() clearPreview() end)
grid.MouseLeave:connect(function() clearPreview() end)

player.CharacterRemoving:connect(function()
	removeCharacterConnections()
	nukeBackpack()
end)
player.CharacterAdded:connect(function() setupCharacterConnections() end)

player.ChildAdded:connect(function(child)
	if child:IsA("Backpack") then
		playerBackpack = child
		if backpackAddCon then backpackAddCon:disconnect() end
		backpackAddCon = game.Players.LocalPlayer.Backpack.ChildAdded:connect(function(child) addToGrid(child) end)
	end
end)

swapSlot.Changed:connect(function()
	if not swapSlot.Value then
		updateGridActive()
	end
end)

searchBox.FocusLost:connect(function(enterPressed)
	if enterPressed then
		showSearchGear()
	end
end)

local loadoutChildren = currentLoadout:GetChildren()
for i = 1, #loadoutChildren do
	if loadoutChildren[i]:IsA("Frame") and string.find(loadoutChildren[i].Name,"Slot") then
		loadoutChildren[i].ChildRemoved:connect(function()
			updateGridActive()
		end)
		loadoutChildren[i].ChildAdded:connect(function()
			updateGridActive()
		end)
	end
end

closeButton.Modal = true
closeButton.MouseButton1Click:connect(function() openCloseBackpack() end)

searchButton.MouseButton1Click:connect(function() showSearchGear() end)
resetButton.MouseButton1Click:connect(function() showEntireGrid() end)
------------------------- End Lifelong Connections -----------------------

resize()
resizeGrid()

-- make sure any items in the loadout are accounted for in inventory
local loadoutChildren = currentLoadout:GetChildren()
for i = 1, #loadoutChildren do
	loadoutCheck(loadoutChildren[i], false)
end
if not backpack.Visible then centerGear(currentLoadout:GetChildren()) end

-- make sure that inventory is listening to gear reparenting
if characterChildAddedCon == nil and game.Players.LocalPlayer["Character"] then
	setupCharacterConnections()
end
if not backpackAddCon then
	backpackAddCon = game.Players.LocalPlayer.Backpack.ChildAdded:connect(function(child) addToGrid(child) end)
end

-- flip it on if we are good
if game.CoreGui.Version >= 3 then
	backpackButton.Visible = true
end

recalculateScrollLoadout()


