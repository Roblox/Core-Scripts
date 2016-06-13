-- Backpack Version 4.21
-- OnlyTwentyCharacters

-------------------
--| Exposed API |--
-------------------

local BackpackScript = {}
BackpackScript.OpenClose = nil -- Function to toggle open/close
BackpackScript.IsOpen = false
BackpackScript.StateChanged = Instance.new('BindableEvent') -- Fires after any open/close, passes IsNowOpen

---------------------
--| Configurables |--
---------------------

local ICON_SIZE = 60
local FONT_SIZE = Enum.FontSize.Size14
local ICON_BUFFER = 5

local BACKGROUND_FADE = 0.50
local BACKGROUND_COLOR = Color3.new(31/255, 31/255, 31/255)

local SLOT_DRAGGABLE_COLOR = Color3.new(49/255, 49/255, 49/255)
local SLOT_EQUIP_COLOR = Color3.new(90/255, 142/255, 233/255)
local SLOT_EQUIP_THICKNESS = 0.1 -- Relative
local SLOT_FADE_LOCKED = 0.50 -- Locked means undraggable
local SLOT_BORDER_COLOR = Color3.new(1, 1, 1) -- Appears when dragging

local TOOLTIP_BUFFER = 6
local TOOLTIP_HEIGHT = 16
local TOOLTIP_OFFSET = -25 -- From top

local ARROW_IMAGE_OPEN = 'rbxasset://textures/ui/Backpack_Open.png'
local ARROW_IMAGE_CLOSE = 'rbxasset://textures/ui/Backpack_Close.png'
local ARROW_SIZE = UDim2.new(0, 14, 0, 9)
local ARROW_HOTKEY = Enum.KeyCode.Backquote.Value --TODO: Hookup '~' too?
local ARROW_HOTKEY_STRING = '`'

local HOTBAR_SLOTS_FULL = 10
local HOTBAR_SLOTS_MINI = 3
local HOTBAR_SLOTS_WIDTH_CUTOFF = 1024 -- Anything smaller is MINI
local HOTBAR_OFFSET_FROMBOTTOM = -30 -- Offset to make room for the Health GUI

local INVENTORY_ROWS_FULL = 4
local INVENTORY_ROWS_MINI = 2
local INVENTORY_HEADER_SIZE = 40

--local TITLE_OFFSET = 20 -- From left side
--local TITLE_TEXT = "Backpack"

local SEARCH_BUFFER = 5
local SEARCH_WIDTH = 200
local SEARCH_TEXT = "   Search"
local SEARCH_TEXT_OFFSET_FROMLEFT = 0
local SEARCH_BACKGROUND_COLOR = Color3.new(0.37, 0.37, 0.37)
local SEARCH_BACKGROUND_FADE = 0.15

local DOUBLE_CLICK_TIME = 0.5

-----------------
--| Variables |--
-----------------
local PlayersService = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local StarterGui = game:GetService('StarterGui')
local GuiService = game:GetService('GuiService')
local CoreGui = game:GetService('CoreGui')
local ContextActionService = game:GetService('ContextActionService')
local RobloxGui = CoreGui:WaitForChild('RobloxGui')
RobloxGui:WaitForChild("Modules"):WaitForChild("TenFootInterface")
local isTenFootInterface = require(RobloxGui.Modules.TenFootInterface):IsEnabled()
local utility = require(RobloxGui.Modules.Settings.Utility)
local topbarEnabled = true

if isTenFootInterface then
	ICON_SIZE = 100
	FONT_SIZE = Enum.FontSize.Size24
end

local gamepadActionsBound = false

local IS_PHONE = UserInputService.TouchEnabled and GuiService:GetScreenResolution().X < HOTBAR_SLOTS_WIDTH_CUTOFF

local HOTBAR_SLOTS = (IS_PHONE) and HOTBAR_SLOTS_MINI or HOTBAR_SLOTS_FULL
local HOTBAR_SIZE = UDim2.new(0, ICON_BUFFER + (HOTBAR_SLOTS * (ICON_SIZE + ICON_BUFFER)), 0, ICON_BUFFER + ICON_SIZE + ICON_BUFFER)
local ZERO_KEY_VALUE = Enum.KeyCode.Zero.Value
local DROP_HOTKEY_VALUE = Enum.KeyCode.Backspace.Value
local INVENTORY_ROWS = (IS_PHONE) and INVENTORY_ROWS_MINI or INVENTORY_ROWS_FULL

local Player = PlayersService.LocalPlayer

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
local ActiveHopper = nil --NOTE: HopperBin
local StarterToolFound = false -- Special handling is required for the gear currently equipped on the site
local WholeThingEnabled = false
local TextBoxFocused = false -- ANY TextBox, not just the search box
local ResultsIndices = nil -- Results of a search, or nil
local HotkeyStrings = {} -- Used for eating/releasing hotkeys
local CharConns = {} -- Holds character connections to be cleared later
local GamepadEnabled = false -- determines if our gui needs to be gamepad friendly

local lastEquippedSlot = nil

-----------------
--| Functions |--
-----------------

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
		newGui.FontSize = FONT_SIZE
		newGui.TextWrapped = true
		if className == 'TextButton' then
			newGui.Font = Enum.Font.SourceSansBold
			newGui.BorderSizePixel = 1
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
	local inventoryOpen = InventoryFrame.Visible -- (Show all)
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
	ActiveHopper:ToggleSelect()
	SlotsByTool[ActiveHopper]:UpdateEquipView()
	ActiveHopper = nil
end

local function UnequipAllTools() --NOTE: HopperBin
	if Humanoid then
		Humanoid:UnequipTools()
		if ActiveHopper then
			DisableActiveHopper()
		end
	end
end

local function EquipNewTool(tool) --NOTE: HopperBin
	UnequipAllTools()
	if tool:IsA('HopperBin') then
		tool:ToggleSelect()
		SlotsByTool[tool]:UpdateEquipView()
		ActiveHopper = tool
	else
		--Humanoid:EquipTool(tool) --NOTE: This would also unequip current Tool
		tool.Parent = Character --TODO: Switch back to above line after EquipTool is fixed!
	end
end

local function IsEquipped(tool)
	return tool and ((tool:IsA('HopperBin') and tool.Active) or tool.Parent == Character) --NOTE: HopperBin
end

local function MakeSlot(parent, index)
	index = index or (#Slots + 1)

	-- Slot Definition --

	local slot = {}
	slot.Tool = nil
	slot.Index = index
	slot.Frame = nil

	local SlotFrame = nil
	local ToolIcon = nil
	local ToolName = nil
	local ToolChangeConn = nil
	local HighlightFrame = nil

	--NOTE: The following are only defined for Hotbar Slots
	local ToolTip = nil
	local SlotNumber = nil

	-- Slot Functions --

	local function UpdateSlotFading()
		SlotFrame.BackgroundTransparency = (SlotFrame.Draggable) and 0 or SLOT_FADE_LOCKED
		SlotFrame.BackgroundColor3 = (SlotFrame.Draggable) and SLOT_DRAGGABLE_COLOR or BACKGROUND_COLOR
	end

	function slot:Reposition()
		-- Slots are positioned into rows
		local index = (ResultsIndices and ResultsIndices[self]) or self.Index
		local sizePlus = ICON_BUFFER + ICON_SIZE

		local modSlots = 0
		modSlots = ((index - 1) % HOTBAR_SLOTS) + 1

		local row = 0
		row = (index > HOTBAR_SLOTS) and (math.floor((index - 1) / HOTBAR_SLOTS)) - 1 or 0

		SlotFrame.Position = UDim2.new(0, ICON_BUFFER + ((modSlots - 1) * sizePlus), 0, ICON_BUFFER + (sizePlus * row))
	end

	function slot:Readjust(visualIndex, visualTotal) --NOTE: Only used for Hotbar slots
		local centered = HOTBAR_SIZE.X.Offset / 2
		local sizePlus = ICON_BUFFER + ICON_SIZE
		local midpointish = (visualTotal / 2) + 0.5
		local factor = visualIndex - midpointish
		SlotFrame.Position = UDim2.new(0, centered - (ICON_SIZE / 2) + (sizePlus * factor), 0, ICON_BUFFER)
	end

	function slot:Fill(tool)
		if not tool then
			return self:Clear()
		end

		self.Tool = tool

		local function assignToolData()
			local icon = tool.TextureId
			ToolIcon.Image = icon
			ToolName.Text = (icon == '') and tool.Name or '' -- (Only show name if no icon)
			if ToolTip and tool:IsA('Tool') then --NOTE: HopperBin
				ToolTip.Text = tool.ToolTip
				local width = ToolTip.TextBounds.X + TOOLTIP_BUFFER
				ToolTip.Size = UDim2.new(0, width, 0, TOOLTIP_HEIGHT)
				ToolTip.Position = UDim2.new(0.5, -width / 2, 0, TOOLTIP_OFFSET)
			end
		end
		assignToolData()

		if ToolChangeConn then
			ToolChangeConn:disconnect()
			ToolChangeConn = nil
		end

		ToolChangeConn = tool.Changed:connect(function(property)
			if property == 'TextureId' or property == 'Name' or property == 'ToolTip' then
				assignToolData()
			end
		end)

		local hotbarSlot = (self.Index <= HOTBAR_SLOTS)
		local inventoryOpen = InventoryFrame.Visible

		if not hotbarSlot or inventoryOpen then
			SlotFrame.Draggable = true
		end

		self:UpdateEquipView()

		if hotbarSlot then
			FullHotbarSlots = FullHotbarSlots + 1
		end

		SlotsByTool[tool] = self
		LowestEmptySlot = FindLowestEmpty()
	end

	function slot:Clear()
		if not self.Tool then return end

		if ToolChangeConn then
			ToolChangeConn:disconnect()
			ToolChangeConn = nil
		end

		ToolIcon.Image = ''
		ToolName.Text = ''
		if ToolTip then
			ToolTip.Text = ''
			ToolTip.Visible = false
		end
		SlotFrame.Draggable = false

		self:UpdateEquipView(true) -- Show as unequipped

		if self.Index <= HOTBAR_SLOTS then
			FullHotbarSlots = FullHotbarSlots - 1
		end

		SlotsByTool[self.Tool] = nil
		self.Tool = nil
		LowestEmptySlot = FindLowestEmpty()
	end

	function slot:UpdateEquipView(unequippedOverride)
		if not unequippedOverride and IsEquipped(self.Tool) then -- Equipped
			lastEquippedSlot = slot
			if not HighlightFrame then
				HighlightFrame = NewGui('Frame', 'Equipped')
				HighlightFrame.ZIndex = SlotFrame.ZIndex
				local t = SLOT_EQUIP_THICKNESS
				local dataTable = { -- Relative sizes and positions
					{t, 1, 0, 0},
					{1, t, 0, 0},
					{t, 1, 1 - t, 0},
					{1, t, 0, 1 - t},
				}
				for _, data in pairs(dataTable) do
					local edgeFrame = NewGui('Frame', 'Edge')
					edgeFrame.BackgroundTransparency = 0
					edgeFrame.BackgroundColor3 = SLOT_EQUIP_COLOR
					edgeFrame.Size = UDim2.new(data[1], 0, data[2], 0)
					edgeFrame.Position = UDim2.new(data[3], 0, data[4], 0)
					edgeFrame.ZIndex = HighlightFrame.ZIndex
					edgeFrame.Parent = HighlightFrame
				end
			end
			HighlightFrame.Parent = SlotFrame
		else -- In the Backpack
			if HighlightFrame then
				HighlightFrame.Parent = nil
			end
		end
		UpdateSlotFading()
	end

	function slot:IsEquipped()
		return IsEquipped(self.Tool)
	end

	function slot:Delete()
		SlotFrame:Destroy() --NOTE: Also clears connections
		table.remove(Slots, self.Index)
		local newSize = #Slots

		-- Now adjust the rest (both visually and representationally)
		for i = self.Index, newSize do
			Slots[i]:SlideBack()
		end

		if newSize % HOTBAR_SLOTS == 0 then -- We lost a row at the bottom! Adjust the CanvasSize
			local lastSlot = Slots[newSize]
			local lowestPoint = lastSlot.Frame.Position.Y.Offset + lastSlot.Frame.Size.Y.Offset
			ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, lowestPoint + ICON_BUFFER)
		end
	end

	function slot:Swap(targetSlot) --NOTE: This slot (self) must not be empty!
		local myTool, otherTool = self.Tool, targetSlot.Tool
		self:Clear()
		if otherTool then -- (Target slot might be empty)
			targetSlot:Clear()
			self:Fill(otherTool)
		end
		if myTool then
			targetSlot:Fill(myTool)
		else
			targetSlot:Clear()
		end
	end

	function slot:SlideBack() -- For inventory slot shifting
		self.Index = self.Index - 1
		SlotFrame.Name = self.Index
		self:Reposition()
	end

	function slot:TurnNumber(on)
		if SlotNumber then
			SlotNumber.Visible = on
		end
	end

	function slot:SetClickability(on) -- (Happens on open/close arrow)
		if self.Tool then
			SlotFrame.Draggable = not on
			UpdateSlotFading()
		end
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

	-- Slot select logic, activated by clicking or pressing hotkey
		function slot:Select()
			local tool = slot.Tool
			if tool then
				if IsEquipped(tool) then --NOTE: HopperBin
					UnequipAllTools()
				elseif tool.Parent == Backpack then
					EquipNewTool(tool)
				end
			end
		end

	-- Slot Init Logic --

	SlotFrame = NewGui('TextButton', index)
	SlotFrame.BackgroundColor3 = BACKGROUND_COLOR
	SlotFrame.BorderColor3 = SLOT_BORDER_COLOR
	SlotFrame.Text = ""
	SlotFrame.AutoButtonColor = false
	SlotFrame.BorderSizePixel = 0
	SlotFrame.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
	SlotFrame.Active = true
	SlotFrame.Draggable = false
	SlotFrame.BackgroundTransparency = SLOT_FADE_LOCKED
	SlotFrame.MouseButton1Click:connect(function() changeSlot(slot) end)
	slot.Frame = SlotFrame

	ToolIcon = NewGui('ImageLabel', 'Icon')
	ToolIcon.Size = UDim2.new(0.8, 0, 0.8, 0)
	ToolIcon.Position = UDim2.new(0.1, 0, 0.1, 0)
	ToolIcon.Parent = SlotFrame

	ToolName = NewGui('TextLabel', 'ToolName')
	ToolName.Size = UDim2.new(1, -2, 1, -2)
	ToolName.Position = UDim2.new(0, 1, 0, 1)
	ToolName.Parent = SlotFrame

	slot:Reposition()

	if index <= HOTBAR_SLOTS then -- Hotbar-Specific Slot Stuff
		-- ToolTip stuff
		ToolTip = NewGui('TextLabel', 'ToolTip')
		ToolTip.TextWrapped = false
		ToolTip.TextYAlignment = Enum.TextYAlignment.Top
		ToolTip.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
		ToolTip.BackgroundTransparency = 0
		ToolTip.Visible = false
		ToolTip.Parent = SlotFrame
		SlotFrame.MouseEnter:connect(function()
			if ToolTip.Text ~= '' then
				ToolTip.Visible = true
			end
		end)
		SlotFrame.MouseLeave:connect(function() ToolTip.Visible = false end)

		function slot:MoveToInventory()
			if slot.Index <= HOTBAR_SLOTS then -- From a Hotbar slot
				local tool = slot.Tool
				self:Clear() --NOTE: Order matters here
				local newSlot = MakeSlot(ScrollingFrame)
				newSlot:Fill(tool)
				if IsEquipped(tool) then -- Also unequip it --NOTE: HopperBin
					UnequipAllTools()
				end
				-- Also hide the inventory slot if we're showing results right now
				if ResultsIndices then
					newSlot.Frame.Visible = false
				end
			end
		end

		-- Show label and assign hotkeys for 1-9 and 0 (zero is always last slot when > 10 total)
		if index < 10 or index == HOTBAR_SLOTS then -- NOTE: Hardcoded on purpose!
			local slotNum = (index < 10) and index or 0
			SlotNumber = NewGui('TextLabel', 'Number')
			SlotNumber.Text = slotNum
			SlotNumber.Size = UDim2.new(0.15, 0, 0.15, 0)
			SlotNumber.Visible = false
			SlotNumber.Parent = SlotFrame
			HotkeyFns[ZERO_KEY_VALUE + slotNum] = slot.Select
		end
	else -- Inventory-Specific Slot Stuff

		local newRow = false
		newRow = (index % HOTBAR_SLOTS == 1)

		if newRow then -- We are the first slot of a new row! Adjust the CanvasSize
			local lowestPoint = SlotFrame.Position.Y.Offset + SlotFrame.Size.Y.Offset
			ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, lowestPoint + ICON_BUFFER)
		end

		-- Scroll to new inventory slot, if we're open and not viewing search results
		if InventoryFrame.Visible and not ResultsIndices then
			local offset = ScrollingFrame.CanvasSize.Y.Offset - ScrollingFrame.AbsoluteSize.Y
			ScrollingFrame.CanvasPosition = Vector2.new(0, math.max(0, offset))
		end
	end

	do -- Dragging Logic
		local startPoint = SlotFrame.Position
		local lastUpTime = 0
		local startParent = nil

		SlotFrame.DragBegin:connect(function(dragPoint)
			Dragging[SlotFrame] = true
			startPoint = dragPoint

			SlotFrame.BorderSizePixel = 2

			-- Raise above other slots
			SlotFrame.ZIndex = 2
			ToolIcon.ZIndex = 2
			ToolName.ZIndex = 2
			if SlotNumber then
				SlotNumber.ZIndex = 2
			end
			if HighlightFrame then
				HighlightFrame.ZIndex = 2
				for _, child in pairs(HighlightFrame:GetChildren()) do
					child.ZIndex = 2
				end
			end

			-- Circumvent the ScrollingFrame's ClipsDescendants property
			startParent = SlotFrame.Parent
			if startParent == ScrollingFrame then
				SlotFrame.Parent = InventoryFrame
				local pos = ScrollingFrame.Position
				local offset = ScrollingFrame.CanvasPosition - Vector2.new(pos.X.Offset, pos.Y.Offset)
				SlotFrame.Position = SlotFrame.Position - UDim2.new(0, offset.X, 0, offset.Y)
			end
		end)

		SlotFrame.DragStopped:connect(function(x, y)
			local now = tick()
			SlotFrame.Position = startPoint
			SlotFrame.Parent = startParent

			SlotFrame.BorderSizePixel = 0

			-- Restore height
			SlotFrame.ZIndex = 1
			ToolIcon.ZIndex = 1
			ToolName.ZIndex = 1
			if SlotNumber then
				SlotNumber.ZIndex = 1
			end
			if HighlightFrame then
				HighlightFrame.ZIndex = 1
				for _, child in pairs(HighlightFrame:GetChildren()) do
					child.ZIndex = 1
				end
			end

			Dragging[SlotFrame] = nil

			-- Make sure the tool wasn't dropped
			if not slot.Tool then
				return
			end

			-- Check where we were dropped
			if CheckBounds(InventoryFrame, x, y) then
				if slot.Index <= HOTBAR_SLOTS then
					slot:MoveToInventory()
				end
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
				local closest = {math.huge, nil}
				for i = 1, HOTBAR_SLOTS do
					local otherSlot = Slots[i]
					local offset = GetOffset(otherSlot.Frame, Vector2.new(x, y))
					if offset < closest[1] then
						closest = {offset, otherSlot}
					end
				end
				local closestSlot = closest[2]
				if closestSlot ~= slot then
					slot:Swap(closestSlot)
					if slot.Index > HOTBAR_SLOTS then
						local tool = slot.Tool
						if not tool then -- Clean up after ourselves if we're an inventory slot that's now empty
							slot:Delete()
						else -- Moved inventory slot to hotbar slot, and gained a tool that needs to be unequipped
							if IsEquipped(tool) then --NOTE: HopperBin
								UnequipAllTools()
							end
							-- Also hide the inventory slot if we're showing results right now
							if ResultsIndices then
								slot.Frame.Visible = false
							end
						end
					end
				end
			else
				-- local tool = slot.Tool
				-- if tool.CanBeDropped then --TODO: HopperBins
					-- tool.Parent = workspace
					-- --TODO: Move away from character
				-- end
				if slot.Index <= HOTBAR_SLOTS then
					slot:MoveToInventory() --NOTE: Temporary
				end
			end

			lastUpTime = now
		end)
	end

	-- All ready!
	SlotFrame.Parent = parent
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

	if ActiveHopper and tool.Parent == Character then --NOTE: HopperBin
		DisableActiveHopper()
	end

	--TODO: Optimize / refactor / do something else
	if not StarterToolFound and tool.Parent == Character and not SlotsByTool[tool] then
		local starterGear = Player:FindFirstChild('StarterGear')
		if starterGear then
			if starterGear:FindFirstChild(tool.Name) then
				StarterToolFound = true
				local slot = LowestEmptySlot or MakeSlot(ScrollingFrame)
				for i = slot.Index, 1, -1 do
					local curr = Slots[i] -- An empty slot, because above
					local pIndex = i - 1
					if pIndex > 0 then
						local prev = Slots[pIndex] -- Guaranteed to be full, because above
						prev:Swap(curr)
					else
						curr:Fill(tool)
					end
				end
				-- Have to manually unequip a possibly equipped tool
				for _, child in pairs(Character:GetChildren()) do
					if child:IsA('Tool') and child ~= tool then
						child.Parent = Backpack
					end
				end
				AdjustHotbarFrames()
				return -- We're done here
			end
		end
	end

	-- The tool is either moving or new
	local slot = SlotsByTool[tool]
	if slot then
		slot:UpdateEquipView()
	else -- New! Put into lowest hotbar slot or new inventory slot
		slot = LowestEmptySlot or MakeSlot(ScrollingFrame)
		slot:Fill(tool)
		if slot.Index <= HOTBAR_SLOTS and not InventoryFrame.Visible then
			AdjustHotbarFrames()
		end
		if tool:IsA('HopperBin') then --NOTE: HopperBin
			if tool.Active then
				UnequipAllTools()
				ActiveHopper = tool
			end
		end
	end
end

local function OnChildRemoved(child) -- From Character or Backpack
	if not child:IsA('Tool') and not child:IsA('HopperBin') then --NOTE: HopperBin
		return
	end
	local tool = child

	-- Ignore this event if we're just moving between the two
	local newParent = tool.Parent
	if newParent == Character or newParent == Backpack then
		return
	end

	local slot = SlotsByTool[tool]
	if slot then
		slot:Clear()
		if slot.Index > HOTBAR_SLOTS then -- Inventory slot
			slot:Delete()
		elseif not InventoryFrame.Visible then
			AdjustHotbarFrames()
		end
	end

	if tool == ActiveHopper then --NOTE: HopperBin
		ActiveHopper = nil
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
	ActiveHopper = nil --NOTE: HopperBin

	-- And any old connections
	for _, conn in pairs(CharConns) do
		conn:disconnect()
	end
	CharConns = {}

	-- Hook up the new character
	Character = character
	table.insert(CharConns, character.ChildRemoved:connect(OnChildRemoved))
	table.insert(CharConns, character.ChildAdded:connect(OnChildAdded))
	for _, child in pairs(character:GetChildren()) do
		OnChildAdded(child)
	end
	--NOTE: Humanoid is set inside OnChildAdded

	-- And the new backpack, when it gets here
	Backpack = Player:WaitForChild('Backpack')
	table.insert(CharConns, Backpack.ChildRemoved:connect(OnChildRemoved))
	table.insert(CharConns, Backpack.ChildAdded:connect(OnChildAdded))
	for _, child in pairs(Backpack:GetChildren()) do
		OnChildAdded(child)
	end

	AdjustHotbarFrames()
end

local function OnInputBegan(input, isProcessed)
	-- Pass through keyboard hotkeys when not typing into a TextBox and not disabled (except for the Drop key)
	if input.UserInputType == Enum.UserInputType.Keyboard and not TextBoxFocused and (WholeThingEnabled or input.KeyCode.Value == DROP_HOTKEY_VALUE) then
		local hotkeyBehavior = HotkeyFns[input.KeyCode.Value]
		if hotkeyBehavior then
			hotkeyBehavior(isProcessed)
		end
	end
end

local function OnUISChanged(property)
	if property == 'KeyboardEnabled' then
		local on = UserInputService.KeyboardEnabled
		for i = 1, HOTBAR_SLOTS do
			Slots[i]:TurnNumber(on)
		end
	end
end

-------------------------
--| Gamepad Functions |--
-------------------------
local lastChangeToolInputObject = nil
local lastChangeToolInputTime = nil
local maxEquipDeltaTime = 0.06
local noOpFunc = function() end
local selectDirection = Vector2.new(0,0)
local hotbarVisible = false

function unbindAllGamepadEquipActions()
	ContextActionService:UnbindCoreAction("RBXBackpackHasGamepadFocus")
	ContextActionService:UnbindCoreAction("RBXCloseInventory")
end

local function setHotbarVisibility(visible, isInventoryScreen)
	for i = 1, HOTBAR_SLOTS do
		local hotbarSlot = Slots[i]
		if hotbarSlot and hotbarSlot.Frame and (isInventoryScreen or hotbarSlot.Tool) then
			hotbarSlot.Frame.Visible = visible
		end
	end
end

local function getInputDirection(inputObject)
	local buttonModifier = 1
	if inputObject.UserInputState == Enum.UserInputState.End then
		buttonModifier = -1
	end

	if inputObject.KeyCode == Enum.KeyCode.Thumbstick1 then

		local magnitude = inputObject.Position.magnitude

		if magnitude > 0.98 then
			local normalizedVector = Vector2.new(inputObject.Position.x / magnitude, -inputObject.Position.y / magnitude)
			selectDirection =  normalizedVector
		else
			selectDirection = Vector2.new(0,0)
		end
	elseif inputObject.KeyCode == Enum.KeyCode.DPadLeft then
		selectDirection = Vector2.new(selectDirection.x - 1 * buttonModifier, selectDirection.y)
	elseif inputObject.KeyCode == Enum.KeyCode.DPadRight then
		selectDirection = Vector2.new(selectDirection.x + 1 * buttonModifier, selectDirection.y)
	elseif inputObject.KeyCode == Enum.KeyCode.DPadUp then
		selectDirection = Vector2.new(selectDirection.x, selectDirection.y - 1 * buttonModifier)
	elseif inputObject.KeyCode == Enum.KeyCode.DPadDown then
		selectDirection = Vector2.new(selectDirection.x, selectDirection.y + 1 * buttonModifier)
	else
		selectDirection = Vector2.new(0,0)
	end

	return selectDirection
end

local selectToolExperiment = function(actionName, inputState, inputObject)

	local inputDirection = getInputDirection(inputObject)

	if inputDirection == Vector2.new(0,0) then
		return
	end

	local angle = math.atan2(inputDirection.y, inputDirection.x) - math.atan2(-1, 0)
	if angle < 0 then
		angle = angle + (math.pi * 2)
	end

	local quarterPi = (math.pi * 0.25)

	local index = (angle/quarterPi) + 1
	index = math.floor(index + 0.5) -- round index to whole number
	if index > HOTBAR_SLOTS then
		index = 1
	end

	if index > 0 then
		local selectedSlot = Slots[index]
		if selectedSlot and selectedSlot.Tool and not selectedSlot:IsEquipped() then
			selectedSlot:Select()
		end
	else
		UnequipAllTools()
	end
end

local changeToolFunc = function(actionName, inputState, inputObject)
	if inputState ~= Enum.UserInputState.Begin then return end

	if lastChangeToolInputObject then
		if (lastChangeToolInputObject.KeyCode == Enum.KeyCode.ButtonR1 and
			inputObject.KeyCode == Enum.KeyCode.ButtonL1) or
			(lastChangeToolInputObject.KeyCode == Enum.KeyCode.ButtonL1 and
			inputObject.KeyCode == Enum.KeyCode.ButtonR1) then
				if (tick() - lastChangeToolInputTime) <= maxEquipDeltaTime then
					UnequipAllTools()
					lastChangeToolInputObject = inputObject
					lastChangeToolInputTime = tick()
					return
				end
		end
	end

	lastChangeToolInputObject = inputObject
	lastChangeToolInputTime = tick()

	delay(maxEquipDeltaTime, function()
		if lastChangeToolInputObject ~= inputObject then return end

		local moveDirection = 0
		if (inputObject.KeyCode == Enum.KeyCode.ButtonL1) then
			moveDirection = -1
		else
			moveDirection = 1
		end

		for i = 1, HOTBAR_SLOTS do
			local hotbarSlot = Slots[i]
			if hotbarSlot:IsEquipped() then

				local newSlotPosition = moveDirection + i
				if newSlotPosition > HOTBAR_SLOTS then
					newSlotPosition = 1
				elseif newSlotPosition < 1 then
					newSlotPosition = HOTBAR_SLOTS
				end

				local origNewSlotPos = newSlotPosition
				while not Slots[newSlotPosition].Tool do
					newSlotPosition = newSlotPosition + moveDirection
					if newSlotPosition == origNewSlotPos then return end

					if newSlotPosition > HOTBAR_SLOTS then
						newSlotPosition = 1
					elseif newSlotPosition < 1 then
						newSlotPosition = HOTBAR_SLOTS
					end
				end

				Slots[newSlotPosition]:Select()
				return
			end
		end

		if lastEquippedSlot and lastEquippedSlot.Tool then
			lastEquippedSlot:Select()
			return
		end

		for i = 1, HOTBAR_SLOTS do
			if Slots[i].Tool then
				Slots[i]:Select()
				return
			end
		end
	end)
end

function getGamepadSwapSlot()
	for i = 1, #Slots do
		if Slots[i].Frame.BorderSizePixel > 0 then
			return Slots[i]
		end
	end
end

function changeSlot(slot)
	if slot.Frame == GuiService.SelectedCoreObject then
		local currentlySelectedSlot = getGamepadSwapSlot()

		if currentlySelectedSlot then
			currentlySelectedSlot.Frame.BorderSizePixel = 0
			if currentlySelectedSlot ~= slot then
				slot:Swap(currentlySelectedSlot)

				if slot.Index > HOTBAR_SLOTS and not slot.Tool then
					if GuiService.SelectedCoreObject == slot.Frame then
						GuiService.SelectedCoreObject = currentlySelectedSlot.Frame
					end
					slot:Delete()
				end

				if currentlySelectedSlot.Index > HOTBAR_SLOTS and not currentlySelectedSlot.Tool then
					if GuiService.SelectedCoreObject == currentlySelectedSlot.Frame then
						GuiService.SelectedCoreObject = slot.Frame
					end
					currentlySelectedSlot:Delete()
				end
			end
		else
			local startSize = slot.Frame.Size
			local startPosition = slot.Frame.Position
			slot.Frame:TweenSizeAndPosition(startSize + UDim2.new(0, 10, 0, 10), startPosition - UDim2.new(0, 5, 0, 5), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, .1, true, function() slot.Frame:TweenSizeAndPosition(startSize, startPosition, Enum.EasingDirection.In, Enum.EasingStyle.Quad, .1, true) end)
			slot.Frame.BorderSizePixel = 3
		end
	else
		slot:Select()
	end
end


function enableGamepadInventoryControl()
	local goBackOneLevel = function(actionName, inputState, inputObject)
		if inputState ~= Enum.UserInputState.Begin then return end

		local selectedSlot = getGamepadSwapSlot()
		if selectedSlot then
			local selectedSlot = getGamepadSwapSlot()
			if selectedSlot then
				selectedSlot.Frame.BorderSizePixel = 0
				return
			end
		elseif InventoryFrame.Visible then
			BackpackScript.OpenClose()
			spawn(function() GuiService:SetMenuIsOpen(false) end)
		end
	end

	ContextActionService:BindCoreAction("RBXBackpackHasGamepadFocus", noOpFunc, false, Enum.UserInputType.Gamepad1)
	ContextActionService:BindCoreAction("RBXCloseInventory", goBackOneLevel, false, Enum.KeyCode.ButtonB, Enum.KeyCode.ButtonStart)

	GuiService.SelectedCoreObject = HotbarFrame:FindFirstChild("1")
end

function disableGamepadInventoryControl()
	unbindAllGamepadEquipActions()

	for i = 1, HOTBAR_SLOTS do
		local hotbarSlot = Slots[i]
		if hotbarSlot and hotbarSlot.Frame then
			hotbarSlot.Frame.BorderSizePixel = 0
		end
	end

	if GuiService.SelectedCoreObject and GuiService.SelectedCoreObject:IsDescendantOf(MainFrame) then
		GuiService.SelectedCoreObject = nil
	end
end

function gamepadDisconnected()
	GamepadEnabled = false
	disableGamepadInventoryControl()
end

function gamepadConnected()
	GamepadEnabled = true
	GuiService:AddSelectionParent("RBXBackpackSelection", MainFrame)

	if not gamepadActionsBound then
		gamepadActionsBound = true
		ContextActionService:BindCoreAction("RBXHotbarEquip", changeToolFunc, false, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1)
	end

	if InventoryFrame.Visible then
		enableGamepadInventoryControl()
	end
end
-----------------------------
--| End Gamepad Functions |--
-----------------------------



local function OnCoreGuiChanged(coreGuiType, enabled)
	-- Check for enabling/disabling the whole thing
	if coreGuiType == Enum.CoreGuiType.Backpack or coreGuiType == Enum.CoreGuiType.All then
		enabled = enabled and topbarEnabled and not UserInputService.VREnabled
		WholeThingEnabled = enabled
		MainFrame.Visible = enabled

		-- Eat/Release hotkeys (Doesn't affect UserInputService)
		for _, keyString in pairs(HotkeyStrings) do
			if enabled then
				GuiService:AddKey(keyString)
			else
				GuiService:RemoveKey(keyString)
			end
		end

		if GamepadEnabled then
			if enabled then
				gamepadActionsBound = true
				ContextActionService:BindCoreAction("RBXHotbarEquip", changeToolFunc, false, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1)
			else
				disableGamepadInventoryControl()
				gamepadActionsBound = false
				ContextActionService:UnbindCoreAction("RBXHotbarEquip")
			end
		end
	end
end



--------------------
--| Script Logic |--
--------------------

-- Make the main frame, which (mostly) covers the screen
MainFrame = NewGui('Frame', 'Backpack')
MainFrame.Visible = false
MainFrame.Parent = RobloxGui

-- Make the HotbarFrame, which holds only the Hotbar Slots
HotbarFrame = NewGui('Frame', 'Hotbar')
HotbarFrame.Size = HOTBAR_SIZE
HotbarFrame.Position = UDim2.new(0.5, -HotbarFrame.Size.X.Offset / 2, 1, -HotbarFrame.Size.Y.Offset)
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
InventoryFrame.BackgroundTransparency = BACKGROUND_FADE
InventoryFrame.BackgroundColor3 = BACKGROUND_COLOR
InventoryFrame.Active = true
InventoryFrame.Size = UDim2.new(0, HotbarFrame.Size.X.Offset, 0, (HotbarFrame.Size.Y.Offset * INVENTORY_ROWS) + INVENTORY_HEADER_SIZE)
InventoryFrame.Position = UDim2.new(0.5, -InventoryFrame.Size.X.Offset / 2, 1, HotbarFrame.Position.Y.Offset - InventoryFrame.Size.Y.Offset)
InventoryFrame.Visible = false
InventoryFrame.Parent = MainFrame

-- Make the ScrollingFrame, which holds the rest of the Slots (however many)
ScrollingFrame = NewGui('ScrollingFrame', 'ScrollingFrame')
ScrollingFrame.Selectable = false
ScrollingFrame.Size = UDim2.new(1, ScrollingFrame.ScrollBarThickness + 1, 1, -INVENTORY_HEADER_SIZE)

ScrollingFrame.Position = UDim2.new(0, 0, 0, INVENTORY_HEADER_SIZE)
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingFrame.Parent = InventoryFrame

-- Make the header title, in the Inventory
--local headerText = NewGui('TextLabel', 'Header')
--headerText.Text = TITLE_TEXT
--headerText.TextXAlignment = Enum.TextXAlignment.Left
--headerText.Font = Enum.Font.SourceSansBold
--headerText.FontSize = Enum.FontSize.Size48
--headerText.TextStrokeColor3 = SLOT_EQUIP_COLOR
--headerText.TextStrokeTransparency = BACKGROUND_FADE
--headerText.Size = UDim2.new(0, (InventoryFrame.Size.X.Offset / 2) - TITLE_OFFSET, 0, INVENTORY_HEADER_SIZE)
--headerText.Position = UDim2.new(0, TITLE_OFFSET, 0, 0)
--headerText.Parent = InventoryFrame

--Make the gamepad hint frame
local gamepadHintsFrame = utility:Create'Frame'
{
	Name = "GamepadHintsFrame",
	Size = UDim2.new(0, HotbarFrame.Size.X.Offset, 0, (isTenFootInterface and 95 or 60)),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = MainFrame
}

local function addGamepadHint(hintImage, hintImageLarge, hintText)
	local hintFrame = utility:Create'Frame'
	{
		Name = "HintFrame",
		Size = UDim2.new(1, 0, 1, -5),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Parent = gamepadHintsFrame
	}

	local hintImage = utility:Create'ImageLabel'
	{
		Name = "HintImage",
		Size = (isTenFootInterface and UDim2.new(0,90,0,90) or UDim2.new(0,60,0,60)),
		BackgroundTransparency = 1,
		Image = (isTenFootInterface and hintImageLarge or hintImage),
		Parent = hintFrame
	}

	local hintText = utility:Create'TextLabel'
	{
		Name = "HintText",
		Position = UDim2.new(0, (isTenFootInterface and 100 or 70), 0, 0),
		Size = UDim2.new(1, -(isTenFootInterface and 100 or 70), 1, 0),
		Font = Enum.Font.SourceSansBold,
		FontSize = (isTenFootInterface and Enum.FontSize.Size36 or Enum.FontSize.Size24),
		BackgroundTransparency = 1,
		Text = hintText,
		TextColor3 = Color3.new(1,1,1),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = hintFrame
	}
end

local function resizeGamepadHintsFrame()
	gamepadHintsFrame.Size = UDim2.new(HotbarFrame.Size.X.Scale, HotbarFrame.Size.X.Offset, 0, (isTenFootInterface and 95 or 60))
	gamepadHintsFrame.Position = UDim2.new(HotbarFrame.Position.X.Scale, HotbarFrame.Position.X.Offset, InventoryFrame.Position.Y.Scale, InventoryFrame.Position.Y.Offset - gamepadHintsFrame.Size.Y.Offset)

	local spaceTaken = 0

	local gamepadHints = gamepadHintsFrame:GetChildren()
	--First get the total space taken by all the hints
	for i = 1, #gamepadHints do
		gamepadHints[i].Size = UDim2.new(1, 0, 1, -5)
		gamepadHints[i].Position = UDim2.new(0, 0, 0, 0)
		spaceTaken = spaceTaken + (gamepadHints[i].HintText.Position.X.Offset + gamepadHints[i].HintText.TextBounds.X)
	end

	--The space between all the frames should be equal
	local spaceBetweenElements = (gamepadHintsFrame.AbsoluteSize.X - spaceTaken)/(#gamepadHints - 1)
	for i = 1, #gamepadHints do
		gamepadHints[i].Position = (i == 1 and UDim2.new(0, 0, 0, 0) or UDim2.new(0, gamepadHints[i-1].Position.X.Offset + gamepadHints[i-1].Size.X.Offset + spaceBetweenElements, 0, 0))
		gamepadHints[i].Size = UDim2.new(0, (gamepadHints[i].HintText.Position.X.Offset + gamepadHints[i].HintText.TextBounds.X), 1, -5)
	end
end

addGamepadHint("rbxasset://textures/ui/Settings/Help/XButtonDark.png", "rbxasset://textures/ui/Settings/Help/XButtonDark@2x.png", "Remove From Hotbar")
addGamepadHint("rbxasset://textures/ui/Settings/Help/AButtonDark.png", "rbxasset://textures/ui/Settings/Help/AButtonDark@2x.png", "Select/Swap")
addGamepadHint("rbxasset://textures/ui/Settings/Help/BButtonDark.png", "rbxasset://textures/ui/Settings/Help/BButtonDark@2x.png", "Close Backpack")

do -- Search stuff
	local searchFrame = NewGui('Frame', 'Search')
	searchFrame.BackgroundColor3 = SEARCH_BACKGROUND_COLOR
	searchFrame.BackgroundTransparency = SEARCH_BACKGROUND_FADE
	searchFrame.Size = UDim2.new(0, SEARCH_WIDTH - (SEARCH_BUFFER * 2), 0, INVENTORY_HEADER_SIZE - (SEARCH_BUFFER * 2))
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
	xButton.TextColor3 = SLOT_EQUIP_COLOR
	xButton.FontSize = Enum.FontSize.Size24
	xButton.TextYAlignment = Enum.TextYAlignment.Bottom
	xButton.BackgroundColor3 = SEARCH_BACKGROUND_COLOR
	xButton.BackgroundTransparency = 0
	xButton.Size = UDim2.new(0, searchFrame.Size.Y.Offset - (SEARCH_BUFFER * 2), 0, searchFrame.Size.Y.Offset - (SEARCH_BUFFER * 2))
	xButton.Position = UDim2.new(1, -xButton.Size.X.Offset - (SEARCH_BUFFER * 2), 0.5, -xButton.Size.Y.Offset / 2)
	xButton.ZIndex = 0
	xButton.Visible = true
	xButton.BorderSizePixel = 0
	xButton.Parent = searchFrame

	local function search()
		local terms = {}
		for word in searchBox.Text:gmatch('%S+') do
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
				slot:Reposition()
				slot.Frame.Visible = true
			end
		end

		ScrollingFrame.CanvasPosition = Vector2.new(0, 0)

		xButton.ZIndex = 3
	end

	local function clearResults()
		if xButton.ZIndex > 0 then
			ResultsIndices = nil
			for i = HOTBAR_SLOTS + 1, #Slots do
				local slot = Slots[i]
				slot:Reposition()
				slot.Frame.Visible = true
			end
			xButton.ZIndex = 0
		end
	end

	local function reset()
		clearResults()
		searchBox.Text = SEARCH_TEXT
	end

	local function onChanged(property)
		if property == 'Text' then
			local text = searchBox.Text
			if text == '' then
				clearResults()
			elseif text ~= SEARCH_TEXT then
				search()
			end
		end
	end

	local function onFocused()
		if searchBox.Text == SEARCH_TEXT then
			searchBox.Text = ''
		end
	end

	local function focusLost(enterPressed)
		if enterPressed then
			--TODO: Could optimize
			search()
		elseif searchBox.Text == '' then
			searchBox.Text = SEARCH_TEXT
		end
	end

	searchBox.Focused:connect(onFocused)
	xButton.MouseButton1Click:connect(reset)
	searchBox.Changed:connect(onChanged)
	searchBox.FocusLost:connect(focusLost)

	BackpackScript.StateChanged.Event:connect(function(isNowOpen)
		xButton.Modal = isNowOpen -- Allows free mouse movement even in first person
		if not isNowOpen then
			reset()
		end
	end)

	HotkeyFns[Enum.KeyCode.Escape.Value] = function(isProcessed)
		if isProcessed then -- Pressed from within a TextBox
			reset()
		elseif InventoryFrame.Visible then
			BackpackScript.OpenClose()
		end
	end

	local function detectGamepad(input, processed)
		if input.UserInputType == Enum.UserInputType.Gamepad1 then
			searchFrame.Visible = false
		else
			searchFrame.Visible = true
		end
	end
	local uis = game:GetService("UserInputService")
	uis.InputBegan:connect(detectGamepad)
	uis.InputChanged:connect(detectGamepad)
end

do -- Make the Inventory expand/collapse arrow (unless TopBar)
	local removeHotBarSlot = function(name, state, input)
		if state ~= Enum.UserInputState.Begin then return end
		if not GuiService.SelectedCoreObject then return end

		for i = 1, HOTBAR_SLOTS do
			if Slots[i].Frame == GuiService.SelectedCoreObject and Slots[i].Tool then
				Slots[i]:MoveToInventory()
				return
			end
		end
	end

	local function openClose()
		if not next(Dragging) then -- Only continue if nothing is being dragged
			InventoryFrame.Visible = not InventoryFrame.Visible
			local nowOpen = InventoryFrame.Visible
			AdjustHotbarFrames()
			HotbarFrame.Active = not HotbarFrame.Active
			for i = 1, HOTBAR_SLOTS do
				Slots[i]:SetClickability(not nowOpen)
			end
		end

		if GamepadEnabled then
			if InventoryFrame.Visible then
				local lastInputType = UserInputService:GetLastInputType()
            			local currentlyUsingGamepad = (lastInputType == Enum.UserInputType.Gamepad1 or lastInputType == Enum.UserInputType.Gamepad2 or
                                                lastInputType == Enum.UserInputType.Gamepad3 or lastInputType == Enum.UserInputType.Gamepad4)
    				if currentlyUsingGamepad then
					resizeGamepadHintsFrame()
					gamepadHintsFrame.Visible = true
				end
				enableGamepadInventoryControl()
			else
				gamepadHintsFrame.Visible = false
				disableGamepadInventoryControl()
			end
		end

		if InventoryFrame.Visible and GamepadEnabled then
			ContextActionService:BindCoreAction("RBXRemoveSlot", removeHotBarSlot, false, Enum.KeyCode.ButtonX)
		elseif GamepadEnabled then
			ContextActionService:UnbindCoreAction("RBXRemoveSlot")
		end

		BackpackScript.IsOpen = InventoryFrame.Visible
		BackpackScript.StateChanged:Fire(InventoryFrame.Visible)
	end
	HotkeyFns[ARROW_HOTKEY] = openClose
	BackpackScript.OpenClose = openClose -- Exposed
end

-- Now that we're done building the GUI, we connect to all the major events

-- Wait for the player if LocalPlayer wasn't ready earlier
while not Player do
	wait()
	Player = PlayersService.LocalPlayer
end

-- Listen to current and all future characters of our player
Player.CharacterAdded:connect(OnCharacterAdded)
if Player.Character then
	OnCharacterAdded(Player.Character)
end

do -- Hotkey stuff
	-- Init HotkeyStrings, used for eating hotkeys
	for i = 0, 9 do
		table.insert(HotkeyStrings, tostring(i))
	end
	table.insert(HotkeyStrings, ARROW_HOTKEY_STRING)

	-- Listen to key down
	UserInputService.InputBegan:connect(OnInputBegan)

	-- Listen to ANY TextBox gaining or losing focus, for disabling all hotkeys
	UserInputService.TextBoxFocused:connect(function() TextBoxFocused = true end)
	UserInputService.TextBoxFocusReleased:connect(function() TextBoxFocused = false end)

	-- Manual unequip for HopperBins on drop button pressed
	HotkeyFns[DROP_HOTKEY_VALUE] = function() --NOTE: HopperBin
		if ActiveHopper then
			UnequipAllTools()
		end
	end

	-- Listen to keyboard status, for showing/hiding hotkey labels
	UserInputService.Changed:connect(OnUISChanged)
	OnUISChanged('KeyboardEnabled')

	-- Listen to gamepad status, for allowing gamepad style selection/equip
	if UserInputService:GetGamepadConnected(Enum.UserInputType.Gamepad1) then
		gamepadConnected()
	end
	UserInputService.GamepadConnected:connect(function(gamepadEnum)
		if gamepadEnum == Enum.UserInputType.Gamepad1 then
			gamepadConnected()
		end
	end)
	UserInputService.GamepadDisconnected:connect(function(gamepadEnum)
		if gamepadEnum == Enum.UserInputType.Gamepad1 then
			gamepadDisconnected()
		end
	end)
end

function BackpackScript:TopbarEnabledChanged(enabled)
	topbarEnabled = enabled
	-- Update coregui to reflect new topbar status
	OnCoreGuiChanged(Enum.CoreGuiType.Backpack, StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack))
end

-- Listen to enable/disable signals from the StarterGui
StarterGui.CoreGuiChangedSignal:connect(OnCoreGuiChanged)
local backpackType, healthType = Enum.CoreGuiType.Backpack, Enum.CoreGuiType.Health
OnCoreGuiChanged(backpackType, StarterGui:GetCoreGuiEnabled(backpackType))
OnCoreGuiChanged(healthType, StarterGui:GetCoreGuiEnabled(healthType))

local UISChanged
local function OnVREnabled(prop)
	if prop == "VREnabled" and UserInputService.VREnabled then
		OnCoreGuiChanged(backpackType, StarterGui:GetCoreGuiEnabled(backpackType))
		OnCoreGuiChanged(healthType, StarterGui:GetCoreGuiEnabled(healthType))
		spawn(function() require(RobloxGui.Modules.BackpackScript3D) end)
		UISChanged:disconnect()
		UISChanged = nil
	end
end
UISChanged = UserInputService.Changed:connect(OnVREnabled)
OnVREnabled("VREnabled")

return BackpackScript
