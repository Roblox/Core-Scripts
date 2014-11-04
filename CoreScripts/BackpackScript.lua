print("Running NEW Backpack!")

-- Configurables --

local ICON_SIZE = 50
local ICON_BUFFER = 5

local SLOT_TRANSPARENCY = 0.75
local SLOT_COLOR_NORMAL = Color3.new(0, 0, 0)
local SLOT_COLOR_EQUIP = Color3.new(0.35, 0.55, 0.91)

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

local Character = nil
local Humanoid = nil
local Backpack = nil

local Slots = {} -- List of all Slots by index, static
local LowestEmptySlot = nil
local SlotsByTool = {} -- Map of Tools to their assigned Slots, dynamic
local HotkeyFns = {} -- Map of KeyCode values to their assigned behaviors, static

local InventoryFrame = nil

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
		newGui.FontSize = Enum.FontSize.Size24
		newGui.TextWrapped = true
		newGui.BackgroundColor3 = Color3.new(1, 1, 1)
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
		if slot.Tool then
			table.insert(fullSlots, slot)
		end
	end
	local fullSlotCount = #fullSlots
	--print("   Adjusting the hotbar frames because now there are", fullSlotCount)
	for i, slot in ipairs(fullSlots) do
		slot:Readjust(i, fullSlotCount)
	end
end

local function MakeSlot(index)
	index = index or (#Slots + 1)
	
	local slot = {}
	slot.Tool = nil
	slot.Index = index
	
	local slotFrame = NewGui('Frame', index)
	slotFrame.BackgroundTransparency = SLOT_TRANSPARENCY
	slotFrame.BackgroundColor3 = SLOT_COLOR_NORMAL
	slotFrame.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
	local sizePlus = ICON_BUFFER + ICON_SIZE
	local modSlots = ((index - 1) % HOTBAR_SLOTS) + 1
	local row = (index > HOTBAR_SLOTS) and (math.floor((index - 1) / HOTBAR_SLOTS)) - 1 or 0
	slotFrame.Position = UDim2.new(0, ICON_BUFFER + ((modSlots - 1) * sizePlus), 0, ICON_BUFFER + (sizePlus * row))
	slotFrame.Visible = false
	
	local toolIcon = NewGui('ImageLabel', 'Icon')
	toolIcon.Size = UDim2.new(0.8, 0, 0.8, 0)
	toolIcon.Position = UDim2.new(0.1, 0, 0.1, 0)
	toolIcon.Parent = slotFrame
	
	local toolName = NewGui('TextLabel', 'ToolName')
	toolName.FontSize = Enum.FontSize.Size14
	toolName.Parent = slotFrame
	
	--TODO: Tool tip thingy
	
	function slot:Show(tool)
		print("   Setting gui data for this tool:", tool)
		slot.Tool = tool
		local icon = tool.TextureId
		toolIcon.Image = icon
		toolName.Text = (icon == '') and tool.Name or ''
		
		SlotsByTool[tool] = slot
		slotFrame.Visible = true
		LowestEmptySlot = FindLowestEmpty()
		AdjustHotbarFrames()
	end
	
	function slot:Hide()
		print("   Hiding gui data for this tool:", tool)
		slotFrame.Visible = false
		
		SlotsByTool[self.Tool] = nil
		self.Tool = nil
		LowestEmptySlot = FindLowestEmpty()
		AdjustHotbarFrames()
	end
	
	function slot:ShowEquip()
		print("   Show as equipped:", slot.Tool)
		slotFrame.BackgroundColor3 = SLOT_COLOR_EQUIP
		slotFrame.BackgroundTransparency = 0
	end
	
	function slot:ShowUnequip()
		print("   Show as unequipped:", slot.Tool)
		slotFrame.BackgroundTransparency = SLOT_TRANSPARENCY
		slotFrame.BackgroundColor3 = SLOT_COLOR_NORMAL
	end
	
	function slot:Destroy()
		print("   Destroying slot", index, "Tool:", slot.Tool)
		self:Hide()
		slotFrame:Destroy()
		table.remove(Slots, index)
	end
	
	function slot:Readjust(visualIndex, total)
		local centered = HOTBAR_SIZE.X.Offset / 2
		local unit = ICON_BUFFER + ICON_SIZE
		local midpointish = (total / 2) + 0.5
		local factor = visualIndex - midpointish
		--print("      Slot", self.Index, "'s new visualIndex:", visualIndex, "MN:", midpointish, "factor:", factor)
		slotFrame.Position = UDim2.new(0, centered - (ICON_SIZE / 2) + (unit * factor), 0, ICON_BUFFER)
	end
	
	Slots[index] = slot
	return slot, slotFrame
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
		-- slot:Show(tool)
	-- end
	
	
	local slot = SlotsByTool[tool]
	if slot then
		-- just equipping/unequipping btwn char&backpack
		--TODO: what if equipping but in backpack? different from 10-swap case below? yes, by script.
		-- should still do the swap in that case. that case: slot already exists, but now equipped
		print("   DoNothing")
	else -- Not yet showing this tool
		if LowestEmptySlot then -- There's a free slot in the Hotbar!
			slot = LowestEmptySlot
			slot:Show(tool)
		else
			print("   Out of room, adding to inventory")
			local slotFrame = nil
			slot, slotFrame = MakeSlot()
			slot:Show(tool)
			slotFrame.Parent = InventoryFrame
		end
	end
	
	-- then check if want to show as equipped
	
	--TODO: what if new, but no slots left, but equipped? IsPossible? YES! Swap out w/ slot 10.
	
	if tool.Parent == Character then -- Equipped --TODO: Check for right arm weld?
		slot:ShowEquip()
	else -- Added to Backpack
		slot:ShowUnequip()
	end
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
		local index = slot.Index
		if index <= HOTBAR_SLOTS then
			slot:Hide()
		else -- Inventory slot
			slot:Destroy()
			--TODO: Reposition slot frames after index
		end
	end
end

local function OnCharacterAdded(character)
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

local hotbarFrame = NewGui('Frame', 'Hotbar')
hotbarFrame.Size = HOTBAR_SIZE
hotbarFrame.Position = UDim2.new(0.5, -hotbarFrame.Size.X.Offset / 2, 1, -hotbarFrame.Size.Y.Offset - HOTBAR_OFFSET_FROMBOTTOM)
hotbarFrame.Parent = mainFrame

for i = 1, HOTBAR_SLOTS do
	local slot, slotFrame = MakeSlot(i)
	
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
	if i < 10 or i == HOTBAR_SLOTS then -- NOTE: Hardcoded on purpose!
		local slotNum = (i < 10) and i or 0
		local number = NewGui('TextLabel', 'Number')
		number.Text = slotNum
		number.FontSize = Enum.FontSize.Size14
		number.Size = UDim2.new(0.15, 0, 0.15, 0)
		number.Parent = slotFrame
		HotkeyFns[KEY_VALUE_ZERO + slotNum] = selectSlot
	end
	
	slotFrame.Parent = hotbarFrame
	
	if not LowestEmptySlot then
		LowestEmptySlot = slot
	end
end

local inventoryFrame = NewGui('Frame', 'Inventory')
inventoryFrame.BackgroundTransparency = SLOT_TRANSPARENCY
inventoryFrame.Active = true
inventoryFrame.Size = UDim2.new(0, hotbarFrame.Size.X.Offset, 0, hotbarFrame.Size.Y.Offset * 5)
inventoryFrame.Position = UDim2.new(0.5, -inventoryFrame.Size.X.Offset / 2, 1, hotbarFrame.Position.Y.Offset - inventoryFrame.Size.Y.Offset)
inventoryFrame.Visible = false
inventoryFrame.Parent = mainFrame
InventoryFrame = inventoryFrame --TODO

do -- Inventory expand/collapse arrow
	local arrowFrame = NewGui('Frame', 'Arrow')
	arrowFrame.BackgroundTransparency = SLOT_TRANSPARENCY
	arrowFrame.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE / 2)
	arrowFrame.Position = UDim2.new(0.5, -arrowFrame.Size.X.Offset / 2, 1, hotbarFrame.Position.Y.Offset - arrowFrame.Size.Y.Offset)
	
	local arrowIcon = NewGui('ImageLabel', 'Icon')
	arrowIcon.Image = ARROW_IMAGE_OPEN
	arrowIcon.Size = ARROW_SIZE
	arrowIcon.Position = UDim2.new(0.5, -arrowIcon.Size.X.Offset / 2, 0.5, -arrowIcon.Size.Y.Offset / 2)
	arrowIcon.Parent = arrowFrame
	
	local closedPosition = arrowFrame.Position
	local openedPosition = closedPosition + UDim2.new(0, 0, 0, -inventoryFrame.Size.Y.Offset)
	
	local function openClose()
		inventoryFrame.Visible = not inventoryFrame.Visible
		arrowFrame.Position = (inventoryFrame.Visible) and openedPosition or closedPosition
		arrowIcon.Image = (inventoryFrame.Visible) and ARROW_IMAGE_CLOSE or ARROW_IMAGE_OPEN
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





