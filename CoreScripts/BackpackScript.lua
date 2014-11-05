print("Running NEW Backpack!")

-- Configurables --

local ICON_SIZE = 60
local ICON_BUFFER = 5

local SLOT_TRANSPARENCY = 0.70
local SLOT_COLOR_EQUIP = Color3.new(0.35, 0.55, 0.91)
local SLOT_COLOR_NORMAL = Color3.new(0, 0, 0)

local ARROW_IMAGE_OPEN = 'rbxasset://textures/ui/Backpack_Open.png'
local ARROW_IMAGE_CLOSE = 'rbxasset://textures/ui/Backpack_Close.png'
local ARROW_SIZE = UDim2.new(0, 14, 0, 9)
local ARROW_HOTKEY = Enum.KeyCode.Backquote.Value

local HOTBAR_SLOTS = 10 --TODO: Change this on different screen sizes
local HOTBAR_OFFSET_FROMBOTTOM = 30

-- Variables --

local PlayersService = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local GuiService = game:GetService('GuiService')

local KEY_VALUE_ZERO = Enum.KeyCode.Zero.Value
local HOTBAR_SIZE = UDim2.new(0, ICON_BUFFER + (HOTBAR_SLOTS * (ICON_SIZE + ICON_BUFFER)), 0, ICON_BUFFER + ICON_SIZE + ICON_BUFFER)

local Player = PlayersService.LocalPlayer

local CoreGui = script.Parent

local HotbarFrame = nil
local InventoryFrame = nil

local Character = nil
local Humanoid = nil
local Backpack = nil

local Slots = {} -- List of all Slots by index
local LowestEmptySlot = nil
local SlotsByTool = {} -- Map of Tools to their assigned Slots
local HotkeyFns = {} -- Map of KeyCode values to their assigned behaviors
local Dragging = {} -- Only used to check if anything is being dragged, to disable other input

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
	local fullSlots = {}
	for i = 1, HOTBAR_SLOTS do
		local slot = Slots[i]
		if slot.Tool or InventoryFrame.Visible then
			table.insert(fullSlots, slot)
		end
	end
	local fullSlotCount = #fullSlots
	--print("   Adjusting the hotbar frames because now there are", fullSlotCount)
	for i, slot in ipairs(fullSlots) do
		slot:Readjust(i, fullSlotCount)
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
	slotFrame.Draggable = true
	slotFrame.Visible = false
	slot.Frame = slotFrame
	
	-- Slots are positioned into rows
	local function Position()
		local sizePlus = ICON_BUFFER + ICON_SIZE
		local modSlots = ((slot.Index - 1) % HOTBAR_SLOTS) + 1
		local row = (slot.Index > HOTBAR_SLOTS) and (math.floor((slot.Index - 1) / HOTBAR_SLOTS)) - 1 or 0
		slotFrame.Position = UDim2.new(0, ICON_BUFFER + ((modSlots - 1) * sizePlus), 0, ICON_BUFFER + (sizePlus * row))
	end
	Position()
	
	local toolIcon = NewGui('ImageLabel', 'Icon')
	toolIcon.Size = UDim2.new(0.8, 0, 0.8, 0)
	toolIcon.Position = UDim2.new(0.1, 0, 0.1, 0)
	toolIcon.Parent = slotFrame
	
	local toolName = NewGui('TextLabel', 'ToolName')
	toolName.Parent = slotFrame
	
	local slotNumber = nil --NOTE: Only defined on Hotbar Slots
	
	--TODO: Tool tip
	--local toolTip = 
	--toolTip.Parent = slotFrame
	
	-- Slot Functions --
	
	function slot:Fill(tool)
		print("   Filling gui data for slot", self.Index, "tool:", tool)
		self.Tool = tool
		local icon = tool.TextureId
		toolIcon.Image = icon
		toolName.Text = (icon == '') and tool.Name or ''
		
		self:UpdateEquipView()
		
		SlotsByTool[tool] = self
		slotFrame.Visible = true
		LowestEmptySlot = FindLowestEmpty()
		AdjustHotbarFrames()
	end
	
	function slot:Clear()
		print("   Clearing gui data for slot", self.Index, "tool:", self.Tool)
		slotFrame.Visible = false
		
		SlotsByTool[self.Tool] = nil
		self.Tool = nil
		LowestEmptySlot = FindLowestEmpty()
		AdjustHotbarFrames()
	end
	
	function slot:UpdateEquipView()
		if self.Tool.Parent == Character then -- Equipped --TODO: Check for right arm weld?
			print("   Showing", self.Index, "as equipped:", self.Tool)
			slotFrame.BackgroundColor3 = SLOT_COLOR_EQUIP
			slotFrame.BackgroundTransparency = 0
		else -- Added to Backpack
			print("   Showing", self.Index, "as unequipped:", self.Tool)
			slotFrame.BackgroundTransparency = SLOT_TRANSPARENCY
			slotFrame.BackgroundColor3 = SLOT_COLOR_NORMAL
		end
	end
	
	function slot:Delete()
		print("   Deleting slot", self.Index, "Tool:", self.Tool)
		--self:Clear()
		slotFrame:Destroy()
		table.remove(Slots, self.Index)
		
		-- Now adjust the rest (both visually and representationally)
		for i = self.Index, #Slots do
			Slots[i]:SlideBack()
		end
	end
	
	function slot:Readjust(visualIndex, visualTotal)
		local centered = HOTBAR_SIZE.X.Offset / 2
		local sizePlus = ICON_BUFFER + ICON_SIZE
		local midpointish = (visualTotal / 2) + 0.5
		local factor = visualIndex - midpointish
		--print("      Slot", self.Index, "'s new visualIndex:", visualIndex, "MN:", midpointish, "factor:", factor)
		slotFrame.Position = UDim2.new(0, centered - (ICON_SIZE / 2) + (sizePlus * factor), 0, ICON_BUFFER)
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
		Position()
	end
	
	
	-- Hotbar-Specific Slot Stuff
	if index <= HOTBAR_SLOTS then
		local function selectSlot()
			print("Click!")
			local tool = slot.Tool
			if tool then
				if tool.Parent == Character then
					print("   UNEQUIP!")
					Humanoid:UnequipTools()
				elseif tool.Parent == Backpack then
					print("   EQUIP!")
					Humanoid:EquipTool(tool) --NOTE: This also unequips current Tool
				end
			end
		end
		
		local clickArea = NewGui('TextButton', 'GimmieYerClicks')
		clickArea.MouseButton1Click:connect(selectSlot)
		clickArea.Parent = slotFrame
		
		-- Show label and assign hotkeys for 1-9 and 0 (zero is always last slot when > 10 total)
		if index < 10 or index == HOTBAR_SLOTS then -- NOTE: Hardcoded on purpose!
			local slotNum = (index < 10) and index or 0
			slotNumber = NewGui('TextLabel', 'Number')
			slotNumber.Text = slotNum
			slotNumber.Size = UDim2.new(0.15, 0, 0.15, 0)
			slotNumber.Parent = slotFrame
			HotkeyFns[KEY_VALUE_ZERO + slotNum] = selectSlot
		end
		
		-- Add a function to Slot, just for Hotbar slots
		function slot:SetClickability(on)
			clickArea.Visible = on
		end
	end
	
	
	do -- Dragging Logic
		local startPoint = slotFrame.Position
		local background = nil
		
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
			
		end)
		
		slotFrame.DragStopped:connect(function(x, y)
			print("DragStopped at:", x, y)
			slotFrame.Position = startPoint
			
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
					local newSlot = MakeSlot(InventoryFrame)
					newSlot:Fill(tool)
					if tool.Parent == Character then -- Also unequip it
						Humanoid:UnequipTools()
					end
				end
			end
			
			-- Check where we were dropped
			if CheckBounds(InventoryFrame, x, y) then
				moveToInventory()
			elseif CheckBounds(HotbarFrame, x, y) then
				print(" Swap this with closest hotbar slot!")
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
					-- Then delete the inventory slot we came from, if empty
					if not slot.Tool and slot.Index > HOTBAR_SLOTS then
						slot:Delete()
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
			
			Dragging[slotFrame] = nil
		end)
	end
	
	
	-- All ready!
	slotFrame.Parent = parent
	Slots[index] = slot
	return slot
end

local function OnChildAdded(child) -- To Character or Backpack
	if not child:IsA('Tool') then --TODO: Hopper bins?
		if child:IsA('Humanoid') and child.Parent == Character then
			Humanoid = child
		end
		return
	end
	local tool = child
	print("A" .. (tool.Parent == Backpack and 'B' or (tool.Parent == Character and 'C' or '?')), tool)
	
	-- either moving or new
	
	--if set in slotTable, then just moving, only do the equip stuff after.
	--else, get lowest slot (if any left), set the gui data and slotTable data
	--if none left above, then done. Maybe return.
	
	-- local slot = SlotsByTool[tool]
	-- if not slot and LowestEmptySlot then -- Not set yet and have room for it!
		-- slot = Slots[LowestEmptySlot]
		-- slot:Fill(tool)
	-- end
	
	
	local slot = SlotsByTool[tool]
	if slot then
		-- just equipping/unequipping btwn char&backpack
		--TODO: what if equipping but in backpack? different from 10-swap case below? yes, by script.
		-- should still do the swap in that case. that case: slot already exists, but now equipped
		print("   Already exists")
		slot:UpdateEquipView()
	else -- Not yet showing this tool
		print("   New! Showing in lowest empty or a new inventory slot")
		slot = LowestEmptySlot or MakeSlot(InventoryFrame)
		slot:Fill(tool)
	end
	
	-- then check if want to show as equipped
	
	--TODO: what if new, but no slots left, but equipped? IsPossible? YES! Swap out w/ slot 10.
end

local function OnChildRemoved(child) -- From Character or Backpack
	if not child:IsA('Tool') then --TODO: Hopper bins?
		return
	end
	local tool = child
	print("R-->" .. (tool.Parent == Backpack and 'B' or (tool.Parent == Character and 'C' or '?')), tool)
	
	-- Ignore this event if we're just moving between the two
	if tool.Parent == Character or tool.Parent == Backpack then
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
	if input.UserInputType == Enum.UserInputType.Keyboard then
		local hotkeyBehavior = HotkeyFns[input.KeyCode.Value]
		if hotkeyBehavior then
			hotkeyBehavior()
		end
	end
end

-- Script Logic --

local mainFrame = NewGui('Frame', 'Backpack')
mainFrame.Visible = false
mainFrame.Parent = CoreGui

HotbarFrame = NewGui('Frame', 'Hotbar')
HotbarFrame.Size = HOTBAR_SIZE
HotbarFrame.Position = UDim2.new(0.5, -HotbarFrame.Size.X.Offset / 2, 1, -HotbarFrame.Size.Y.Offset - HOTBAR_OFFSET_FROMBOTTOM)
--HotbarFrame.BackgroundTransparency = 0.9 --TODO?
HotbarFrame.Parent = mainFrame

for i = 1, HOTBAR_SLOTS do
	local slot = MakeSlot(HotbarFrame, i)
	
	if not LowestEmptySlot then
		LowestEmptySlot = slot
	end
end

InventoryFrame = NewGui('Frame', 'Inventory')
InventoryFrame.BackgroundTransparency = SLOT_TRANSPARENCY
InventoryFrame.Active = true
InventoryFrame.Size = UDim2.new(0, HotbarFrame.Size.X.Offset, 0, HotbarFrame.Size.Y.Offset * 5)
InventoryFrame.Position = UDim2.new(0.5, -InventoryFrame.Size.X.Offset / 2, 1, HotbarFrame.Position.Y.Offset - InventoryFrame.Size.Y.Offset)
InventoryFrame.Visible = false
InventoryFrame.Parent = mainFrame

do -- Inventory expand/collapse arrow
	local arrowFrame = NewGui('Frame', 'Arrow')
	arrowFrame.BackgroundTransparency = SLOT_TRANSPARENCY
	arrowFrame.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE / 2)
	arrowFrame.Position = UDim2.new(0.5, -arrowFrame.Size.X.Offset / 2, 1, HotbarFrame.Position.Y.Offset - arrowFrame.Size.Y.Offset)
	
	local arrowIcon = NewGui('ImageLabel', 'Icon')
	arrowIcon.Image = ARROW_IMAGE_OPEN
	arrowIcon.Size = ARROW_SIZE
	arrowIcon.Position = UDim2.new(0.5, -arrowIcon.Size.X.Offset / 2, 0.5, -arrowIcon.Size.Y.Offset / 2)
	arrowIcon.Parent = arrowFrame
	
	local closedPosition = arrowFrame.Position
	local openedPosition = closedPosition + UDim2.new(0, 0, 0, -InventoryFrame.Size.Y.Offset)
	
	local function openClose()
		if not next(Dragging) then -- Only continue if nothing is being dragged
			InventoryFrame.Visible = not InventoryFrame.Visible
			local nowOpen = InventoryFrame.Visible
			arrowFrame.Position = (nowOpen) and openedPosition or closedPosition
			arrowIcon.Image = (nowOpen) and ARROW_IMAGE_CLOSE or ARROW_IMAGE_OPEN
			AdjustHotbarFrames()
			for i = 1, HOTBAR_SLOTS do
				Slots[i]:SetClickability(not nowOpen)
			end
		end
	end
	local clickArea = NewGui('TextButton', 'GimmieYerClicks')
	clickArea.MouseButton1Click:connect(openClose)
	clickArea.Parent = arrowFrame
	HotkeyFns[ARROW_HOTKEY] = openClose
	
	arrowFrame.Parent = mainFrame
end

-- Connect events

while not Player do --TODO: Only necessary in RunSolo? -- Still a valid case though.
	wait()
	Player = PlayersService.LocalPlayer
end

mainFrame.Visible = true

Player.CharacterAdded:connect(OnCharacterAdded)
if Player.Character then
	OnCharacterAdded(Player.Character)
end

if UserInputService.KeyboardEnabled then
	UserInputService.InputBegan:connect(OnInputBegan)
end





