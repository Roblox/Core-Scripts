-- Backpack Version 4.4
-- OnlyTwentyCharacters

-- Configurables --

local ICON_SIZE = 60
local ICON_BUFFER = 5

local SLOT_TRANSPARENCY = 0.70
local SLOT_COLOR_EQUIP = Color3.new(0.35, 0.55, 0.91)
local SLOT_COLOR_NORMAL = Color3.new(0, 0, 0)

local ARROW_IMAGE_OPEN = 'rbxasset://textures/ui/Backpack_Open.png'
local ARROW_IMAGE_CLOSE = 'rbxasset://textures/ui/Backpack_Close.png'
local ARROW_SIZE = UDim2.new(0, 14, 0, 9)
local ARROW_HOTKEY = Enum.KeyCode.Backquote.Value --TODO: Hookup '~' too?
local ARROW_HOTKEY_STRING = '`'

local HOTBAR_SLOTS_FULL = 10
local HOTBAR_SLOTS_MINI = 3
local HOTBAR_SLOTS_WIDTH_CUTOFF = 1024 -- Anything smaller is MINI
local HOTBAR_OFFSET_FROMBOTTOM = 30

local INVENTORY_ROWS = 5
local INVENTORY_HEADER_SIZE = 40

local TITLE_OFFSET = 20 -- From left side
local TITLE_TEXT = "Backpack"

local SEARCH_BUFFER = 5
local SEARCH_WIDTH = 200
local SEARCH_TEXT = "Search"
local SEARCH_TEXT_OFFSET_FROMLEFT = 15

local DOUBLE_CLICK_TIME = 0.5

-- Variables --

print = function() end --TODO: Remove all prints when full implementation is complete

local PlayersService = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local StarterGui = game:GetService('StarterGui')
local GuiService = game:GetService('GuiService')

local HOTBAR_SLOTS = (UserInputService.TouchEnabled and GuiService:GetScreenResolution().X < HOTBAR_SLOTS_WIDTH_CUTOFF) and HOTBAR_SLOTS_MINI or HOTBAR_SLOTS_FULL
local HOTBAR_SIZE = UDim2.new(0, ICON_BUFFER + (HOTBAR_SLOTS * (ICON_SIZE + ICON_BUFFER)), 0, ICON_BUFFER + ICON_SIZE + ICON_BUFFER)
local ZERO_KEY_VALUE = Enum.KeyCode.Zero.Value
local DROP_HOTKEY_VALUE = Enum.KeyCode.Backspace.Value

local Player = PlayersService.LocalPlayer

local CoreGui = script.Parent

local MainFrame = nil
local HotbarFrame = nil
local InventoryFrame = nil
local ScrollingFrame = nil

local Character = nil
local Humanoid = nil
local Backpack = nil

local Slots = {} -- List of all Slots by index
local LowestEmptySlot = nil
local SlotsByTool = {} -- Map of Tools to their assigned Slots
local HotkeyFns = {} -- Map of KeyCode values to their assigned behaviors
local Dragging = {} -- Only used to check if anything is being dragged, to disable other input
local FullHotbarSlots = 0
local UpdateArrowFrame = nil -- Function defined in Init logic at the bottom
local ActiveHopper = nil --NOTE: HopperBin
local StarterToolFound = false -- Special handling is required for the gear currently equipped on the site
local WholeThingEnabled = false
local TextBoxFocused = false
local ResultsIndices = nil -- Results of a search

-- Functions --

local function NewGui(className, objectName)
	local newGui = Instance.new(className)
	newGui.Name = objectName
	newGui.BackgroundColor3 = Color3.new(0, 0, 0)
	newGui.BackgroundTransparency = 1
	newGui.BorderColor3 = Color3.new(0, 0, 0)
	newGui.BorderSizePixel = 0
	newGui.Size = UDim2.new(1, 0, 1, 0)
	if className:match('Text') then
		newGui.TextColor3 = Color3.new(1, 1, 1)
		newGui.Text = ''
		newGui.Font = Enum.Font.SourceSans
		newGui.FontSize = Enum.FontSize.Size14
		newGui.TextWrapped = true
		newGui.BackgroundTransparency = 1
		if className == 'TextButton' then
			newGui.Font = Enum.Font.SourceSansBold
			newGui.BorderSizePixel = 2
		end
	end
	return newGui
end

local function FindLowestEmpty()
	for i = 1, HOTBAR_SLOTS do
		local slot = Slots[i]
		if not slot.Tool then
			return slot
		end
	end
	return nil
end

local function AdjustHotbarFrames()
	local inventoryOpen = InventoryFrame.Visible
	local visualTotal = (inventoryOpen) and HOTBAR_SLOTS or FullHotbarSlots
	local visualIndex = 0
	for i = 1, HOTBAR_SLOTS do
		local slot = Slots[i]
		if slot.Tool or inventoryOpen then
			visualIndex = visualIndex + 1
			slot:Readjust(visualIndex, visualTotal)
			slot.Frame.Visible = true
		else
			slot.Frame.Visible = false
		end
	end
end

local function CheckBounds(guiObject, x, y)
	local pos = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize
	return (x > pos.X and x <= pos.X + size.X and y > pos.Y and y <= pos.Y + size.Y)
end

local function GetOffset(guiObject, point)
	local centerPoint = guiObject.AbsolutePosition + (guiObject.AbsoluteSize / 2)
	return (centerPoint - point).magnitude
end

local function DisableActiveHopper() --NOTE: HopperBin
	print("Disabling active hopper:", ActiveHopper)
	ActiveHopper:ToggleSelect()
	SlotsByTool[ActiveHopper]:UpdateEquipView()
	ActiveHopper = nil
end

local function UnequipTools() --NOTE: HopperBin
	Humanoid:UnequipTools()
	if ActiveHopper then
		DisableActiveHopper()
	end
end

local function EquipTool(tool) --NOTE: HopperBin
	UnequipTools()
	if tool:IsA('HopperBin') then
		tool:ToggleSelect()
		SlotsByTool[tool]:UpdateEquipView()
		ActiveHopper = tool
	else
		Humanoid:EquipTool(tool) --NOTE: This would also unequip current Tool
	end
end

local function MakeSlot(parent, index)
	index = index or (#Slots + 1)
	
	-- Slot Definition --
	
	local slot = {}
	slot.Tool = nil
	slot.Index = index
	slot.Frame = nil
	
	local slotFrame = NewGui('Frame', slot.Index)
	slotFrame.BackgroundTransparency = SLOT_TRANSPARENCY
	slotFrame.BackgroundColor3 = SLOT_COLOR_NORMAL
	slotFrame.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
	slotFrame.Active = true
	slotFrame.Draggable = false
	slot.Frame = slotFrame
	
	local toolIcon = NewGui('ImageLabel', 'Icon')
	toolIcon.Size = UDim2.new(0.8, 0, 0.8, 0)
	toolIcon.Position = UDim2.new(0.1, 0, 0.1, 0)
	toolIcon.Parent = slotFrame
	
	local toolName = NewGui('TextLabel', 'ToolName')
	toolName.Parent = slotFrame
	
	local toolTip = nil --TODO: Clean up
	if slot.Index <= HOTBAR_SLOTS then
		toolTip = NewGui('TextLabel', 'ToolTip')
		toolTip.TextWrapped = false
		toolTip.TextYAlignment = Enum.TextYAlignment.Top
		toolTip.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
		toolTip.BackgroundTransparency = 0
		toolTip.Visible = false
		toolTip.Parent = slotFrame
		slotFrame.MouseEnter:connect(function()
			if toolTip.Text ~= '' then
				toolTip.Visible = true
			end
		end)
		slotFrame.MouseLeave:connect(function() toolTip.Visible = false end)
	end
	
	local slotNumber = nil --NOTE: Only defined for Hotbar Slots
	local clickArea = nil --NOTE: Only defined for Hotbar Slots
	
	
	-- Slot Functions --
	
	function slot:Reposition()
		-- Slots are positioned into rows
		local index = (ResultsIndices and ResultsIndices[self]) or self.Index
		local sizePlus = ICON_BUFFER + ICON_SIZE
		local modSlots = ((index - 1) % HOTBAR_SLOTS) + 1
		local row = (index > HOTBAR_SLOTS) and (math.floor((index - 1) / HOTBAR_SLOTS)) - 1 or 0
		slotFrame.Position = UDim2.new(0, ICON_BUFFER + ((modSlots - 1) * sizePlus), 0, ICON_BUFFER + (sizePlus * row))
		-- print("     Reposition", self.Index, "at...............", index, "                      Output:", slotFrame.Position.X.Offset, slotFrame.Position.Y.Offset, "           row:", row)
	end
	slot:Reposition()
	
	function slot:Readjust(visualIndex, visualTotal)
		local centered = HOTBAR_SIZE.X.Offset / 2
		local sizePlus = ICON_BUFFER + ICON_SIZE
		local midpointish = (visualTotal / 2) + 0.5
		local factor = visualIndex - midpointish
		--print("      Slot", self.Index, "'s new visualIndex:", visualIndex, "MN:", midpointish, "factor:", factor)
		slotFrame.Position = UDim2.new(0, centered - (ICON_SIZE / 2) + (sizePlus * factor), 0, ICON_BUFFER)
	end
	
	function slot:Fill(tool)
		print("   Filling gui data for slot", self.Index, "tool:", tool)
		self.Tool = tool
		slotFrame.Draggable = true
		local icon = tool.TextureId
		toolIcon.Image = icon
		toolName.Text = (icon == '') and tool.Name or ''
		if toolTip and tool:IsA('Tool') then --NOTE: HopperBin
			--TODO: No magic numbers
			toolTip.Text = tool.ToolTip
			local width = toolTip.TextBounds.X + 6
			toolTip.Size = UDim2.new(0, width, 0, 16)
			toolTip.Position = UDim2.new(0.5, -width / 2, 0, -25)
		end
		self:UpdateEquipView()
		
		if self.Index <= HOTBAR_SLOTS then
			FullHotbarSlots = FullHotbarSlots + 1
		end
		
		SlotsByTool[tool] = self
		LowestEmptySlot = FindLowestEmpty()
		AdjustHotbarFrames()
		UpdateArrowFrame()
	end
	
	function slot:Clear()
		print("   Clearing gui data for slot", self.Index, "tool:", self.Tool)
		slotFrame.Draggable = false
		toolIcon.Image = ''
		toolName.Text = ''
		if toolTip then
			toolTip.Text = ''
			toolTip.Visible = false
		end
		self:UpdateEquipView(true) -- Always show as unequipped
		
		if self.Index <= HOTBAR_SLOTS then
			FullHotbarSlots = FullHotbarSlots - 1
		end
		
		SlotsByTool[self.Tool] = nil
		self.Tool = nil
		LowestEmptySlot = FindLowestEmpty()
		AdjustHotbarFrames()
		UpdateArrowFrame()
	end
	
	function slot:UpdateEquipView(unequippedOverride)
		local tool = self.Tool
		if not unequippedOverride and (tool.Parent == Character or (tool:IsA('HopperBin') and tool.Active)) then -- Equipped --NOTE: HopperBin
			print("     Showing", self.Index, "as equipped:", tool)
			slotFrame.BackgroundColor3 = SLOT_COLOR_EQUIP
			slotFrame.BackgroundTransparency = 0
		else -- In the Backpack
			print("     Showing", self.Index, "as unequipped:", tool)
			slotFrame.BackgroundTransparency = SLOT_TRANSPARENCY
			slotFrame.BackgroundColor3 = SLOT_COLOR_NORMAL
		end
	end
	
	function slot:Delete()
		print("   Deleting slot", self.Index, "Tool:", self.Tool)
		slotFrame:Destroy()
		table.remove(Slots, self.Index)
		local newSize = #Slots
		
		-- Now adjust the rest (both visually and representationally)
		for i = self.Index, newSize do
			Slots[i]:SlideBack()
		end
		
		if newSize % HOTBAR_SLOTS == 0 then -- We lost a row at the end! Adjust the CanvasSize
			local lastSlot = Slots[newSize]
			local lowestPoint = lastSlot.Frame.Position.Y.Offset + lastSlot.Frame.Size.Y.Offset
			ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, lowestPoint + ICON_BUFFER)
			local offset = Vector2.new(0, math.max(0, ScrollingFrame.CanvasPosition.Y - (lastSlot.Frame.Size.Y.Offset + ICON_BUFFER)))
			ScrollingFrame.CanvasPosition = offset
		end
	end
	
	function slot:Swap(targetSlot) --NOTE: This slot (self) must not be empty!
		print("   Swapping content of slots:", self.Index, "and", targetSlot.Index)
		local myTool, otherTool = self.Tool, targetSlot.Tool
		self:Clear()
		if otherTool then -- (Target slot might be empty)
			targetSlot:Clear()
			self:Fill(otherTool)
		end
		targetSlot:Fill(myTool)
	end
	
	
	function slot:SlideBack() -- For inventory slot shifting
		print("   SlideBack:", self.Index, "to", self.Index - 1)
		self.Index = self.Index - 1
		self:Reposition()
	end
	
	function slot:TurnNumber(on)
		slotNumber.Visible = on
	end
	
	function slot:SetClickability(on)
		clickArea.Visible = on
	end
	
	function slot:CheckTerms(terms)
		local hits = 0
		local function checkEm(str, term)
			local _, n = str:lower():gsub(term, '')
			hits = hits + n
		end
		local tool = self.Tool
		for term in pairs(terms) do
			checkEm(tool.Name, term)
			if tool:IsA('Tool') then --NOTE: HopperBin
				checkEm(tool.ToolTip, term)
			end
		end
		return hits
	end
	
	
	if index <= HOTBAR_SLOTS then -- Hotbar-Specific Slot Stuff
		local function selectSlot()
			print("Click!")
			local tool = slot.Tool
			if tool then
				if tool.Parent == Character or (tool:IsA('HopperBin') and tool.Active) then --NOTE: HopperBin
					print("   UNEQUIP!")
					UnequipTools()
				elseif tool.Parent == Backpack then
					print("   EQUIP!")
					EquipTool(tool)
				end
			end
		end
		
		clickArea = NewGui('TextButton', 'GimmieYerClicks')
		clickArea.MouseButton1Click:connect(selectSlot)
		clickArea.Parent = slotFrame
		
		-- Show label and assign hotkeys for 1-9 and 0 (zero is always last slot when > 10 total)
		if index < 10 or index == HOTBAR_SLOTS then -- NOTE: Hardcoded on purpose!
			local slotNum = (index < 10) and index or 0
			slotNumber = NewGui('TextLabel', 'Number')
			slotNumber.Text = slotNum
			slotNumber.Size = UDim2.new(0.15, 0, 0.15, 0)
			slotNumber.Visible = false
			slotNumber.Parent = slotFrame
			HotkeyFns[ZERO_KEY_VALUE + slotNum] = selectSlot
		end
	else -- Inventory-Specific Slot Stuff
		if index % HOTBAR_SLOTS == 1 then -- We are the first slot of a new row! Adjust the CanvasSize
			local lowestPoint = slotFrame.Position.Y.Offset + slotFrame.Size.Y.Offset
			ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, lowestPoint + ICON_BUFFER)
		end
	end
	
	
	do -- Dragging Logic
		local startPoint = slotFrame.Position
		local background = nil
		local lastUpTime = 0
		local startParent = nil
		
		slotFrame.DragBegin:connect(function(dragPoint)
			print("DragBegin at:", dragPoint)
			Dragging[slotFrame] = true
			startPoint = dragPoint
			
			-- Raise above other slots
			slotFrame.ZIndex = 3
			toolIcon.ZIndex = 3
			toolName.ZIndex = 3
			if slotNumber then
				slotNumber.ZIndex = 3
			end
			
			background = NewGui('Frame', 'Background')
			background.ZIndex = 2
			background.BackgroundTransparency = 0
			background.Parent = slotFrame
			
			-- Circumvent the ScrollingFrame's ClipsDescendants
			startParent = slotFrame.Parent
			if startParent == ScrollingFrame then
				slotFrame.Parent = InventoryFrame
				local pos = ScrollingFrame.Position
				local offset = ScrollingFrame.CanvasPosition - Vector2.new(pos.X.Offset, pos.Y.Offset)
				slotFrame.Position = slotFrame.Position - UDim2.new(0, offset.X, 0, offset.Y)
			end
		end)
		
		slotFrame.DragStopped:connect(function(x, y)
			print("DragStopped at:", x, y)
			local now = tick()
			slotFrame.Position = startPoint
			slotFrame.Parent = startParent
			
			if background then -- Why? Just in case
				background:Destroy()
			end
			
			-- Restore height
			slotFrame.ZIndex = 1
			toolIcon.ZIndex = 1
			toolName.ZIndex = 1
			if slotNumber then
				slotNumber.ZIndex = 1
			end
			
			local function moveToInventory()
				if slot.Index <= HOTBAR_SLOTS then -- From a Hotbar slot
					print(" Move to inventory!")
					local tool = slot.Tool
					slot:Clear() --NOTE: Order matters here
					local newSlot = MakeSlot(ScrollingFrame)
					newSlot:Fill(tool)
					if tool.Parent == Character or (tool:IsA('HopperBin') and tool.Active) then -- Also unequip it --NOTE: HopperBin
						UnequipTools()
					end
					-- Also hide the inventory slot if we're showing results right now
					if ResultsIndices then
						newSlot.Frame.Visible = false
					end
				end
			end
			
			-- Check where we were dropped
			if CheckBounds(InventoryFrame, x, y) then
				moveToInventory()
				-- Check for double clicking on an inventory slot, to move into empty hotbar slot
				if slot.Index > HOTBAR_SLOTS and now - lastUpTime < DOUBLE_CLICK_TIME then
					if LowestEmptySlot then
						local myTool = slot.Tool
						slot:Clear()
						LowestEmptySlot:Fill(myTool)
						slot:Delete()
					end
					now = 0 -- Resets the timer
				end
			elseif CheckBounds(HotbarFrame, x, y) then
				print(" Swap this with closest Hotbar Slot!")
				local closest = {math.huge, nil}
				for i = 1, HOTBAR_SLOTS do
					local otherSlot = Slots[i]
					local offset = GetOffset(otherSlot.Frame, Vector2.new(x, y))
					if offset < closest[1] then
						closest = {offset, otherSlot}
					end
				end
				print(" Closest slot:", closest[2].Index)
				local closestSlot = closest[2]
				if closestSlot ~= slot then
					slot:Swap(closestSlot)
					if slot.Index > HOTBAR_SLOTS then
						local tool = slot.Tool
						if not tool then -- Clean up after ourselves if we're an inventory slot that's now empty
							slot:Delete()
						else -- Moved inventory slot to hotbar slot, and gained a tool that needs to be unequipped
							if tool.Parent == Character or (tool:IsA('HopperBin') and tool.Active) then --NOTE: HopperBin
								UnequipTools()
							end
							-- Also hide the inventory slot if we're showing results right now
							if ResultsIndices then
								slot.Frame.Visible = false
							end
						end
					end
				end
			else
				-- print(" DROP!")
				-- local tool = slot.Tool
				-- if tool.CanBeDropped then --TODO: HopperBins
					-- tool.Parent = workspace
					-- --TODO: Move away from character
				-- end
				moveToInventory() --NOTE: Temporary
			end
			
			lastUpTime = now
			Dragging[slotFrame] = nil
		end)
	end
	
	
	-- All ready!
	slotFrame.Parent = parent
	Slots[index] = slot
	return slot
end

local function OnChildAdded(child) -- To Character or Backpack
	if not child:IsA('Tool') and not child:IsA('HopperBin') then --NOTE: HopperBin
		if child:IsA('Humanoid') and child.Parent == Character then
			Humanoid = child
		end
		return
	end
	local tool = child
	print("A" .. (tool.Parent == Backpack and 'B' or (tool.Parent == Character and 'C' or '?')), tool)
	
	if ActiveHopper then --NOTE: HopperBin
		DisableActiveHopper()
	end
	
	--TODO: Optimize / refactor / do something else
	if not StarterToolFound and tool.Parent == Character and not SlotsByTool[tool] then
		local starterGear = Player:FindFirstChild('StarterGear')
		if starterGear then
			if starterGear:FindFirstChild(tool.Name) then
				StarterToolFound = true
				local firstEmptyIndex = LowestEmptySlot and LowestEmptySlot.Index or #Slots + 1
				if LowestEmptySlot then
					firstEmptyIndex = LowestEmptySlot.Index
				else -- No slots free in hotbar, make a new inventory slot
					local newSlot = MakeSlot(ScrollingFrame)
					firstEmptyIndex = newSlot.Index
				end
				for i = firstEmptyIndex, 1, -1 do
					local curr = Slots[i] -- An empty slot, because above
					local pIndex = i - 1
					if pIndex > 0 then
						local prev = Slots[pIndex] -- Guaranteed to be full, because above
						prev:Swap(curr)
					else
						curr:Fill(tool)
					end
				end
				return -- We're done here
			end
		end
	end
	
	-- either moving or new
	
	local slot = SlotsByTool[tool]
	if slot then
		print("   Already exists")
		slot:UpdateEquipView()
	else -- Not yet showing this tool
		print("   New! Showing in lowest empty or a new inventory slot")
		slot = LowestEmptySlot or MakeSlot(ScrollingFrame)
		slot:Fill(tool)
	end
end

local function OnChildRemoved(child) -- From Character or Backpack
	if not child:IsA('Tool') and not child:IsA('HopperBin') then --NOTE: HopperBin
		return
	end
	local tool = child
	print("R-->" .. (tool.Parent == Backpack and 'B' or (tool.Parent == Character and 'C' or '?')), tool)
	
	-- Ignore this event if we're just moving between the two
	local newParent = tool.Parent
	if newParent == Character or newParent == Backpack then
		return
	end
	
	local slot = SlotsByTool[tool]
	if slot then
		slot:Clear()
		local index = slot.Index
		if index > HOTBAR_SLOTS then -- Inventory slot
			slot:Delete()
		end
	end
end

local function OnCharacterAdded(character)
	-- First, clean up any old slots
	for i = #Slots, 1, -1 do
		local slot = Slots[i]
		if slot.Tool then
			slot:Clear()
		end
		if i > HOTBAR_SLOTS then
			slot:Delete()
		end
	end
	
	Character = character
	character.ChildRemoved:connect(OnChildRemoved)
	character.ChildAdded:connect(OnChildAdded)
	for _, child in pairs(character:GetChildren()) do
		OnChildAdded(child)
	end
	--NOTE: Humanoid is set inside OnChildAdded
	
	Backpack = Player:WaitForChild('Backpack')
	local addTime = tick(); Backpack.Changed:connect(function(prop) if prop == 'Parent' then print("Backpack added", tick() - addTime, "seconds ago just got removed! Izat coo?") end end) --TODO: Remove
	Backpack.ChildRemoved:connect(OnChildRemoved)
	Backpack.ChildAdded:connect(OnChildAdded)
	for _, child in pairs(Backpack:GetChildren()) do
		OnChildAdded(child)
	end
	
	print("CharAdded finished")
end

local function OnInputBegan(input, isProcessed)
	if not TextBoxFocused and (WholeThingEnabled or input.KeyCode.Value == DROP_HOTKEY_VALUE) and input.UserInputType == Enum.UserInputType.Keyboard then
		local hotkeyBehavior = HotkeyFns[input.KeyCode.Value]
		if hotkeyBehavior then
			hotkeyBehavior()
		end
	end
end

local function OnUISChanged(property)
	--print("UIS CHANGED:", property)
	if property == 'KeyboardEnabled' then
		local on = UserInputService.KeyboardEnabled
		for i = 1, HOTBAR_SLOTS do
			Slots[i]:TurnNumber(on)
		end
	end
end

local function OnCoreGuiChanged(coreGuiType, enabled)
	if coreGuiType == Enum.CoreGuiType.Backpack or coreGuiType == Enum.CoreGuiType.All then
		print("Make whole everything", enabled and "visible" or "hidden!")
		WholeThingEnabled = enabled
		MainFrame.Visible = enabled
	end
	if coreGuiType == Enum.CoreGuiType.Health or coreGuiType == Enum.CoreGuiType.All then
		print("Move whole everything", enabled and "back up!" or "down!")
		MainFrame.Position = UDim2.new(0, 0, 0, enabled and 0 or HOTBAR_OFFSET_FROMBOTTOM)
	end
end

-- Script Logic --

-- Make the main frame, which covers the screen
MainFrame = NewGui('Frame', 'Backpack')
MainFrame.Visible = false
MainFrame.Parent = CoreGui

-- Make the HotbarFrame, which holds only the Hotbar Slots
HotbarFrame = NewGui('Frame', 'Hotbar')
HotbarFrame.Active = true
HotbarFrame.Size = HOTBAR_SIZE
HotbarFrame.Position = UDim2.new(0.5, -HotbarFrame.Size.X.Offset / 2, 1, -HotbarFrame.Size.Y.Offset - HOTBAR_OFFSET_FROMBOTTOM)
HotbarFrame.Parent = MainFrame

-- Make all the Hotbar Slots
for i = 1, HOTBAR_SLOTS do
	local slot = MakeSlot(HotbarFrame, i)
	slot.Frame.Visible = false
	
	if not LowestEmptySlot then
		LowestEmptySlot = slot
	end
end

-- Make the Inventory, which holds the ScrollingFrame, the header, and the search box
InventoryFrame = NewGui('Frame', 'Inventory')
InventoryFrame.BackgroundTransparency = SLOT_TRANSPARENCY
InventoryFrame.Active = true
InventoryFrame.Size = UDim2.new(0, HotbarFrame.Size.X.Offset, 0, HotbarFrame.Size.Y.Offset * 5) --TODO: No MNs
InventoryFrame.Position = UDim2.new(0.5, -InventoryFrame.Size.X.Offset / 2, 1, HotbarFrame.Position.Y.Offset - InventoryFrame.Size.Y.Offset)
InventoryFrame.Visible = false
InventoryFrame.Parent = MainFrame

-- Make the header title, in the Inventory
-- local headerText = NewGui('TextLabel', 'Header')
-- headerText.Text = TITLE_TEXT
-- headerText.TextXAlignment = Enum.TextXAlignment.Left
-- headerText.Font = Enum.Font.SourceSansBold
-- headerText.FontSize = Enum.FontSize.Size48
-- headerText.TextStrokeColor3 = SLOT_COLOR_EQUIP
-- headerText.TextStrokeTransparency = 0.75 --TODO: No MNs
-- headerText.Size = UDim2.new(0, (InventoryFrame.Size.X.Offset / 2) - TITLE_OFFSET, 0, INVENTORY_HEADER_SIZE)
-- headerText.Position = UDim2.new(0, TITLE_OFFSET, 0, 0)
-- headerText.Parent = InventoryFrame

do -- Search stuff
	local searchFrame = NewGui('Frame', 'Search')
	searchFrame.BackgroundColor3 = Color3.new(0.37, 0.37, 0.37) --TODO: NO MNs
	searchFrame.BackgroundTransparency = 0.15 --TODO: NO MNs
	searchFrame.Size = UDim2.new(0, SEARCH_WIDTH, 0, INVENTORY_HEADER_SIZE - (SEARCH_BUFFER * 2))
	searchFrame.Position = UDim2.new(1, -searchFrame.Size.X.Offset - SEARCH_BUFFER, 0, SEARCH_BUFFER)
	searchFrame.Parent = InventoryFrame
	
	local searchBox = NewGui('TextBox', 'TextBox')
	searchBox.Text = SEARCH_TEXT
	searchBox.ClearTextOnFocus = false
	searchBox.FontSize = Enum.FontSize.Size24
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.Size = searchFrame.Size - UDim2.new(0, SEARCH_TEXT_OFFSET_FROMLEFT, 0, 0)
	searchBox.Position = UDim2.new(0, SEARCH_TEXT_OFFSET_FROMLEFT, 0, 0)
	searchBox.Parent = searchFrame
	
	local xButton = NewGui('TextButton', 'X')
	xButton.Text = 'x'
	xButton.TextColor3 = SLOT_COLOR_EQUIP
	xButton.FontSize = Enum.FontSize.Size24
	xButton.TextYAlignment = Enum.TextYAlignment.Bottom
	xButton.Size = UDim2.new(0, searchFrame.Size.Y.Offset - (SEARCH_BUFFER * 2), 0, searchFrame.Size.Y.Offset - (SEARCH_BUFFER * 2))
	xButton.Position = UDim2.new(1, -xButton.Size.X.Offset - (SEARCH_BUFFER * 2), 0.5, -xButton.Size.Y.Offset / 2)
	xButton.ZIndex = 3
	xButton.Visible = false
	xButton.Parent = searchFrame
	
	local clickArea = NewGui('TextButton', 'GimmieYerClicks')
	clickArea.MouseButton1Click:connect(function()
		print("YOINK!")
		searchBox:CaptureFocus()
		if searchBox.Text == SEARCH_TEXT then
			searchBox.Text = ''
		end
	end)
	clickArea.ZIndex = 2
	clickArea.Parent = searchFrame
	
	local function resetSearch()
		print("Reset!")
		if xButton.Visible then
			ResultsIndices = nil
			for i = HOTBAR_SLOTS + 1, #Slots do
				local slot = Slots[i]
				slot:Reposition()
				slot.Frame.Visible = true
			end
		end
		xButton.Visible = false
		searchBox.Text = SEARCH_TEXT
	end
	xButton.MouseButton1Click:connect(resetSearch)
	
	searchBox.FocusLost:connect(function(enterPressed)
		print("FocusLost! enterPressed:", enterPressed)
		if enterPressed then
			local text = searchBox.Text
			print(" Want to search for:", text)
			local terms = {}
			for word in text:gmatch('%S+') do
				terms[word:lower()] = true
			end
			
			local hitTable = {}
			for i = HOTBAR_SLOTS + 1, #Slots do -- Only search inventory slots
				local slot = Slots[i]
				local hits = slot:CheckTerms(terms)
				table.insert(hitTable, {slot, hits})
				slot.Frame.Visible = false
			end
			
			table.sort(hitTable, function(left, right)
				return left[2] > right[2]
			end)
			ResultsIndices = {}
			
			for i, data in ipairs(hitTable) do
				local slot, hits = data[1], data[2]
				if hits > 0 then
					ResultsIndices[slot] = HOTBAR_SLOTS + i
					print("   ", i, "- Slot ", slot.Index, "Hits", hits)
					slot:Reposition()
					slot.Frame.Visible = true
				end
			end
			
			xButton.Visible = true
		else
			resetSearch()
		end
	end)
end

-- Make the ScrollingFrame, which holds the rest of the Slots (however many) 
ScrollingFrame = NewGui('ScrollingFrame', 'ScrollingFrame')
ScrollingFrame.Size = UDim2.new(1, ScrollingFrame.ScrollBarThickness + 1, 1, -INVENTORY_HEADER_SIZE)
ScrollingFrame.Position = UDim2.new(0, 0, 0, INVENTORY_HEADER_SIZE)
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingFrame.Parent = InventoryFrame

do -- Make the Inventory expand/collapse arrow
	local arrowFrame = NewGui('Frame', 'Arrow')
	arrowFrame.BackgroundTransparency = SLOT_TRANSPARENCY
	arrowFrame.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE / 2)
	local hotbarBottom = HotbarFrame.Position.Y.Offset + HotbarFrame.Size.Y.Offset
	arrowFrame.Position = UDim2.new(0.5, -arrowFrame.Size.X.Offset / 2, 1, hotbarBottom - arrowFrame.Size.Y.Offset)
	
	local arrowIcon = NewGui('ImageLabel', 'Icon')
	arrowIcon.Image = ARROW_IMAGE_OPEN
	arrowIcon.Size = ARROW_SIZE
	arrowIcon.Position = UDim2.new(0.5, -arrowIcon.Size.X.Offset / 2, 0.5, -arrowIcon.Size.Y.Offset / 2)
	arrowIcon.Parent = arrowFrame
	
	local collapsed = arrowFrame.Position
	local closed = collapsed + UDim2.new(0, 0, 0, -HotbarFrame.Size.Y.Offset)
	local opened = closed + UDim2.new(0, 0, 0, -InventoryFrame.Size.Y.Offset)
	
	local function openClose()
		if not next(Dragging) then -- Only continue if nothing is being dragged
			InventoryFrame.Visible = not InventoryFrame.Visible
			local nowOpen = InventoryFrame.Visible
			arrowIcon.Image = (nowOpen) and ARROW_IMAGE_CLOSE or ARROW_IMAGE_OPEN
			AdjustHotbarFrames()
			UpdateArrowFrame()
			for i = 1, HOTBAR_SLOTS do
				Slots[i]:SetClickability(not nowOpen)
			end
		end
	end
	local clickArea = NewGui('TextButton', 'GimmieYerClicks')
	clickArea.MouseButton1Click:connect(openClose)
	clickArea.Parent = arrowFrame
	HotkeyFns[ARROW_HOTKEY] = openClose
	
	-- Define global function
	UpdateArrowFrame = function()
		arrowFrame.Position = (InventoryFrame.Visible) and opened or ((FullHotbarSlots == 0) and collapsed or closed)
	end
	
	arrowFrame.Parent = MainFrame
end


-- Finally, connect the major events

while not Player do --TODO: Only necessary in RunSolo? -- Still a valid case though.
	wait()
	Player = PlayersService.LocalPlayer
end

Player.CharacterAdded:connect(OnCharacterAdded)
if Player.Character then
	OnCharacterAdded(Player.Character)
end

-- Eat keys
for i = 0, 9 do
	GuiService:AddKey(tostring(i))
end
GuiService:AddKey(ARROW_HOTKEY_STRING)

UserInputService.InputBegan:connect(OnInputBegan)

UserInputService.Changed:connect(OnUISChanged)
OnUISChanged('KeyboardEnabled')

UserInputService.TextBoxFocused:connect(function() TextBoxFocused = true end)
UserInputService.TextBoxFocusReleased:connect(function() TextBoxFocused = false end)

HotkeyFns[DROP_HOTKEY_VALUE] = function() --NOTE: HopperBin
	if ActiveHopper then
		UnequipTools()
	end
end

StarterGui.CoreGuiChangedSignal:connect(OnCoreGuiChanged)
local backpackType = Enum.CoreGuiType.Backpack
OnCoreGuiChanged(backpackType, StarterGui:GetCoreGuiEnabled(backpackType))
