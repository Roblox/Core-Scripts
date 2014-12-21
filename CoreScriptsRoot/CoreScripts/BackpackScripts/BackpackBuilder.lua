-- This script creates almost all gui elements found in the backpack (warning: there are a lot!)
-- TODO: automate this process

local ICON_SIZE = 46

local gui = script.Parent

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

local function IsTouchDevice()	
	return Game:GetService('UserInputService').TouchEnabled
end 

local function IsPhone()	 	
	if Game:GetService("GuiService"):GetScreenResolution().Y <= 500 and IsTouchDevice() then 	 	
		return true	 	
	end 	 	
	return false 	 	
end

waitForChild(game,"Players")
waitForProperty(game:GetService("Players"),"LocalPlayer")
local player = game:GetService("Players").LocalPlayer

-- First up is the current loadout
local CurrentLoadout = Instance.new("Frame")
CurrentLoadout.Name = "CurrentLoadout"
CurrentLoadout.Position = UDim2.new(0.5, -300, 1, -85)
CurrentLoadout.Size = UDim2.new(0, 600, 0, ICON_SIZE)
CurrentLoadout.BackgroundTransparency = 1
CurrentLoadout.RobloxLocked = true
CurrentLoadout.Parent = gui

local CLBackground = Instance.new('ImageLabel')						
CLBackground.Name = 'Background';
CLBackground.Size = UDim2.new(1.2, 0, 1.2, 0);
CLBackground.Image = "http://www.roblox.com/asset/?id=96536002"
CLBackground.BackgroundTransparency = 1.0;
CLBackground.Position = UDim2.new(-0.1, 0, -0.1, 0);
CLBackground.ZIndex = 0.0;	
CLBackground.Parent = CurrentLoadout
CLBackground.Visible = false 

local Debounce = Instance.new("BoolValue")
Debounce.Name = "Debounce"
Debounce.RobloxLocked = true
Debounce.Parent = CurrentLoadout

local BackpackButton = Instance.new("ImageButton")
BackpackButton.RobloxLocked = true
BackpackButton.Visible = false
BackpackButton.Name = "BackpackButton"
BackpackButton.BackgroundTransparency = 1
BackpackButton.Image = "rbxasset://textures/ui/Backpack_Open.png"
BackpackButton.Position = UDim2.new(0.5, -7, 1, -55)
BackpackButton.Size = UDim2.new(0, 14, 0, 9)
waitForChild(gui,"ControlFrame")
BackpackButton.Parent = gui.ControlFrame

local NumSlots = 9

if IsPhone() then
	NumSlots = 3
	CurrentLoadout.Size = UDim2.new(0,180,0,ICON_SIZE)
	CurrentLoadout.Position = UDim2.new(0.5,-90,1,-85)
end

for i = 0, NumSlots do	
	local slotFrame = Instance.new("Frame")
	slotFrame.RobloxLocked = true
	slotFrame.BackgroundColor3 = Color3.new(0,0,0)
	slotFrame.BackgroundTransparency = 1
	slotFrame.BorderColor3 = Color3.new(1, 1, 1)
	slotFrame.BorderSizePixel = 0
	slotFrame.Name = "Slot" .. tostring(i)
	slotFrame.ZIndex = 4.0
	if i == 0 then
		slotFrame.Position = UDim2.new(0.9, 48, 0, 0)
	else
		slotFrame.Position = UDim2.new((i - 1) * 0.1, (i-1)* 6,0,0)
	end	


	slotFrame.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
	slotFrame.Parent = CurrentLoadout	

	if gui.AbsoluteSize.Y <= 320 then 
		slotFrame.Position = UDim2.new(0, (i-1)* 60, 0, -50)
	end 
	if gui.AbsoluteSize.Y <= 320 and i == 0 then 
		slotFrame:Destroy() 
	end 
end

local TempSlot = Instance.new("ImageButton")
TempSlot.Name = "TempSlot"
TempSlot.Active = true
TempSlot.Size = UDim2.new(1,0,1,0)
TempSlot.BackgroundTransparency = 1.0
TempSlot.Style = 'Custom'
TempSlot.Visible = false
TempSlot.RobloxLocked = true
TempSlot.Parent = CurrentLoadout
TempSlot.ZIndex = 3.0

	local slotBackground = Instance.new('Frame')
	slotBackground.Name = 'Background'
	slotBackground.BackgroundTransparency = 1.0
	slotBackground.Style = "DropShadow"
	slotBackground.Position = UDim2.new(0, -10, 0, -10)	
	slotBackground.Size = UDim2.new(1, 20, 1, 20)	
	slotBackground.Parent = TempSlot

	local HighLight = Instance.new('ImageLabel')
	HighLight.Name = 'Highlight'
	HighLight.BackgroundTransparency = 1.0
	HighLight.Image = 'http://www.roblox.com/asset/?id=97643886'
	HighLight.Size = UDim2.new(1, 0, 1, 0)	
	--HighLight.Parent = TempSlot
	HighLight.Visible = false 

	-- TempSlot Children
	local GearReference = Instance.new("ObjectValue")
	GearReference.Name = "GearReference"
	GearReference.RobloxLocked = true
	GearReference.Parent = TempSlot
	

	local ToolTipLabel = Instance.new("TextLabel")
	ToolTipLabel.Name = "ToolTipLabel"
	ToolTipLabel.RobloxLocked = true
	ToolTipLabel.Text = ""
	ToolTipLabel.BackgroundTransparency = 0.5
	ToolTipLabel.BorderSizePixel = 0
	ToolTipLabel.Visible = false
	ToolTipLabel.TextColor3 = Color3.new(1,1,1)
	ToolTipLabel.BackgroundColor3 = Color3.new(0,0,0)
	ToolTipLabel.TextStrokeTransparency = 0
	ToolTipLabel.Font = Enum.Font.ArialBold
	ToolTipLabel.FontSize = Enum.FontSize.Size14
	--ToolTipLabel.TextWrap = true
	ToolTipLabel.Size = UDim2.new(1,60,0,20)
	ToolTipLabel.Position = UDim2.new(0,-30,0,-30)
	ToolTipLabel.Parent = TempSlot
	

	local Kill = Instance.new("BoolValue")
	Kill.Name = "Kill"
	Kill.RobloxLocked = true
	Kill.Parent = TempSlot

	local GearImage = Instance.new("ImageLabel")
	GearImage.Name = "GearImage"
	GearImage.BackgroundTransparency = 1
	GearImage.Position = UDim2.new(0, 0, 0, 0)
	GearImage.Size = UDim2.new(1, 0, 1, 0)
	GearImage.ZIndex = 5.0
	GearImage.RobloxLocked = true
	GearImage.Parent = TempSlot

	local SlotNumber = Instance.new("TextLabel")
	SlotNumber.Name = "SlotNumber"
	SlotNumber.BackgroundTransparency = 1
	SlotNumber.BorderSizePixel = 0
	SlotNumber.Font = Enum.Font.ArialBold
	SlotNumber.FontSize = Enum.FontSize.Size18
	SlotNumber.Position = UDim2.new(0, 0, 0, 0)
	SlotNumber.Size = UDim2.new(0,10,0,15)
	SlotNumber.TextColor3 = Color3.new(1,1,1)
	SlotNumber.TextTransparency = 0
	SlotNumber.TextXAlignment = Enum.TextXAlignment.Left
	SlotNumber.TextYAlignment = Enum.TextYAlignment.Bottom	
	SlotNumber.RobloxLocked = true
	SlotNumber.Parent = TempSlot
	SlotNumber.ZIndex = 5

	if IsTouchDevice() then 
		SlotNumber.Visible = false 
	end
	
	local SlotNumberDownShadow = SlotNumber:Clone()
	SlotNumberDownShadow.Name = "SlotNumberDownShadow"
	SlotNumberDownShadow.TextColor3 = Color3.new(0,0,0)	
	SlotNumberDownShadow.Position = UDim2.new(0, 1, 0, -1)
	SlotNumberDownShadow.Parent = TempSlot
	SlotNumberDownShadow.ZIndex = 2
	
	local SlotNumberUpShadow = SlotNumberDownShadow:Clone()
	SlotNumberUpShadow.Name = "SlotNumberUpShadow"
	SlotNumberUpShadow.Position = UDim2.new(0, -1, 0, -1)
	SlotNumberUpShadow.Parent = TempSlot

	local GearText = Instance.new("TextLabel")
	GearText.RobloxLocked = true
	GearText.Name = "GearText"
	GearText.BackgroundTransparency = 1
	GearText.Font = Enum.Font.Arial
	GearText.FontSize = Enum.FontSize.Size14
	GearText.Position = UDim2.new(0,0,0,0)
	GearText.Size = UDim2.new(1,0,1,0)
	GearText.Text = ""
	GearText.TextColor3 = Color3.new(1,1,1)
	GearText.TextWrap = true
	GearText.Parent = TempSlot
	GearText.ZIndex = 5.0

--- Great, now lets make the inventory!

local Backpack = Instance.new("Frame")
Backpack.RobloxLocked = true
Backpack.Visible = false
Backpack.Name = "Backpack"
Backpack.Position = UDim2.new(0.5, 0, 0.5, 0)
Backpack.BackgroundColor3 = Color3.new(32/255, 32/255, 32/255)
Backpack.BackgroundTransparency = 0.5
Backpack.BorderSizePixel = 0
Backpack.Parent = gui
Backpack.Active = true

	-- Backpack Children
	local SwapSlot = Instance.new("BoolValue")
	SwapSlot.RobloxLocked = true
	SwapSlot.Name = "SwapSlot"
	SwapSlot.Parent = Backpack
		
		-- SwapSlot Children
		local Slot = Instance.new("IntValue")
		Slot.RobloxLocked = true
		Slot.Name = "Slot"
		Slot.Parent = SwapSlot
		
		local GearButton = Instance.new("ObjectValue")
		GearButton.RobloxLocked = true
		GearButton.Name = "GearButton"
		GearButton.Parent = SwapSlot
	
	local Tabs = Instance.new("Frame")
	Tabs.Name = "Tabs"
	Tabs.Visible = false
	Tabs.Active = false
	Tabs.RobloxLocked = true
	Tabs.BackgroundColor3 = Color3.new(0,0,0)
	Tabs.BackgroundTransparency = 0.08
	Tabs.BorderSizePixel = 0
	Tabs.Position = UDim2.new(0,0,-0.1,-4)
	Tabs.Size = UDim2.new(1,0,0.1,4)
	Tabs.Parent = Backpack
	
		-- Tabs Children
		
		local tabLine = Instance.new("Frame")
		tabLine.RobloxLocked = true
		tabLine.Name = "TabLine"
		tabLine.BackgroundColor3 = Color3.new(53/255, 53/255, 53/255)
		tabLine.BorderSizePixel = 0
		tabLine.Position = UDim2.new(0,5,1,-4)
		tabLine.Size = UDim2.new(1,-10,0,4)
		tabLine.ZIndex = 2
		tabLine.Parent = Tabs
		
		local InventoryButton = Instance.new("TextButton")
		InventoryButton.RobloxLocked = true
		InventoryButton.Name = "InventoryButton"
		InventoryButton.Size = UDim2.new(0,60,0,30)
		InventoryButton.Position = UDim2.new(0,7,1,-31)
		InventoryButton.BackgroundColor3 = Color3.new(1,1,1)
		InventoryButton.BorderColor3 = Color3.new(1,1,1)
		InventoryButton.Font = Enum.Font.ArialBold
		InventoryButton.FontSize = Enum.FontSize.Size18
		InventoryButton.Text = "Gear"
		InventoryButton.AutoButtonColor = false
		InventoryButton.TextColor3 = Color3.new(0,0,0)
		InventoryButton.Selected = true
		InventoryButton.Active = true
		InventoryButton.ZIndex = 3
		InventoryButton.Parent = Tabs
			
		local closeButton = Instance.new("TextButton")
		closeButton.RobloxLocked = true
		closeButton.Name = "CloseButton"
		closeButton.Font = Enum.Font.ArialBold
		closeButton.FontSize = Enum.FontSize.Size24
		closeButton.Position = UDim2.new(1,-33,0,4)
		closeButton.Size = UDim2.new(0,30,0,30)
		closeButton.Style = Enum.ButtonStyle.RobloxButton
		closeButton.Text = ""
		closeButton.TextColor3 = Color3.new(1,1,1)
		closeButton.Parent = Tabs
		closeButton.Modal = true
		
			--closeButton child
			local XImage = Instance.new("ImageLabel")
			XImage.RobloxLocked = true
			XImage.Name = "XImage"
			game:GetService("ContentProvider"):Preload("http://www.roblox.com/asset/?id=75547445")
			XImage.Image = "http://www.roblox.com/asset/?id=75547445"  --TODO: move to rbxasset
			XImage.BackgroundTransparency = 1
			XImage.Position = UDim2.new(-.25,-1,-.25,-1)
			XImage.Size = UDim2.new(1.5,2,1.5,2)
			XImage.ZIndex = 2
			XImage.Parent = closeButton
			
		-- Generic Search gui used across backpack	
		local SearchFrame = Instance.new("Frame")
		SearchFrame.RobloxLocked = true
		SearchFrame.Name = "SearchFrame"
		SearchFrame.BackgroundTransparency = 1
		SearchFrame.Position = UDim2.new(1,-220,0,2)
		SearchFrame.Size = UDim2.new(0,220,0,24)
		SearchFrame.Parent = Backpack
		
			-- SearchFrame Children
			local SearchButton = Instance.new("ImageButton")
			SearchButton.RobloxLocked = true
			SearchButton.Name = "SearchButton"
			SearchButton.Size = UDim2.new(0,25,0,25)
			SearchButton.BackgroundTransparency = 1
			SearchButton.Image = "rbxasset://textures/ui/SearchIcon.png"
			SearchButton.Parent = SearchFrame
			
			local SearchBoxFrame = Instance.new("TextButton")
			SearchBoxFrame.RobloxLocked = true
			SearchBoxFrame.Position = UDim2.new(0,25,0,-2)
			SearchBoxFrame.Size = UDim2.new(1,-28,0,30)
			SearchBoxFrame.Name = "SearchBoxFrame"
			SearchBoxFrame.Text = ""
			SearchBoxFrame.Style = Enum.ButtonStyle.RobloxRoundButton
			SearchBoxFrame.Parent = SearchFrame
			
				-- SearchBoxFrame Children
				local SearchBox = Instance.new("TextBox")
				SearchBox.RobloxLocked = true
				SearchBox.Name = "SearchBox"
				SearchBox.BackgroundTransparency = 1
				SearchBox.Font = Enum.Font.ArialBold
				SearchBox.FontSize = Enum.FontSize.Size12
				SearchBox.Position = UDim2.new(0,-5,0,-5)
				SearchBox.Size = UDim2.new(1,10,1,10)
				SearchBox.TextColor3 = Color3.new(1,1,1)
				SearchBox.TextXAlignment = Enum.TextXAlignment.Left
				SearchBox.ZIndex = 2
				SearchBox.TextWrap = true
				SearchBox.Text = "Search..."
				SearchBox.Parent = SearchBoxFrame
				
			
			local ResetButton = Instance.new("TextButton")
			ResetButton.RobloxLocked = true
			ResetButton.Visible = false
			ResetButton.Name = "ResetButton"
			ResetButton.Position = UDim2.new(1,-26,0,3)
			ResetButton.Size = UDim2.new(0,20,0,20)
			ResetButton.Style = Enum.ButtonStyle.RobloxButtonDefault
			ResetButton.Text = "X"
			ResetButton.TextColor3 = Color3.new(1,1,1)
			ResetButton.Font = Enum.Font.ArialBold
			ResetButton.FontSize = Enum.FontSize.Size18
			ResetButton.ZIndex = 3
			ResetButton.Parent = SearchFrame
		
------------------------------- GEAR -------------------------------------------------------
	local Gear = Instance.new("Frame")
	Gear.Name = "Gear"
	Gear.RobloxLocked = true
	Gear.BackgroundTransparency = 1
	Gear.Size  = UDim2.new(1,0,1,0)
	Gear.ClipsDescendants = true
	Gear.Parent = Backpack

		-- Gear Children
		local AssetsList = Instance.new("Frame")
		AssetsList.RobloxLocked = true
		AssetsList.Name = "AssetsList"
		AssetsList.BackgroundTransparency = 1
		AssetsList.Size = UDim2.new(0.2,0,1,0)
		AssetsList.Style = Enum.FrameStyle.RobloxSquare
		AssetsList.Visible = false
		AssetsList.Parent = Gear
			
		local GearGrid = Instance.new("Frame")
		GearGrid.RobloxLocked = true
		GearGrid.Name = "GearGrid"
		GearGrid.Size = UDim2.new(0.95, 0, 1, 0)
		GearGrid.BackgroundTransparency = 1
		GearGrid.Parent = Gear	
				
			
			local GearButton = Instance.new("ImageButton")
			GearButton.RobloxLocked = true
			GearButton.Visible = false
			GearButton.Name = "GearButton"
			GearButton.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
			GearButton.Style = 'Custom'
			GearButton.Parent = GearGrid
			GearButton.BackgroundTransparency = 1.0

					local slotBackground = Instance.new('Frame')
					slotBackground.Name = 'Background'
					slotBackground.BackgroundTransparency = 1.0
					slotBackground.Size = UDim2.new(1, 16,  1, 16)
					slotBackground.Position = UDim2.new(0, -8,  0, -8)
					slotBackground.Parent = GearButton
					slotBackground.Style = "DropShadow"


				-- GearButton Children
				local GearReference = Instance.new("ObjectValue")
				GearReference.RobloxLocked = true
				GearReference.Name = "GearReference"
				GearReference.Parent = GearButton
				
				local GreyOutButton = Instance.new("Frame")
				GreyOutButton.RobloxLocked = true
				GreyOutButton.Name = "GreyOutButton"
				GreyOutButton.BackgroundTransparency = 0.5
				GreyOutButton.Size = UDim2.new(1,0,1,0)
				GreyOutButton.Active = true
				GreyOutButton.Visible = false
				GreyOutButton.ZIndex = 3
				GreyOutButton.Parent = GearButton
				
				local GearText = Instance.new("TextLabel")
				GearText.RobloxLocked = true
				GearText.Name = "GearText"
				GearText.BackgroundTransparency = 1
				GearText.Font = Enum.Font.Arial
				GearText.FontSize = Enum.FontSize.Size14
				GearText.Position = UDim2.new(0,-8,0,-8)
				GearText.Size = UDim2.new(1,16,1,16)
				GearText.Text = ""
				GearText.ZIndex = 2
				GearText.TextColor3 = Color3.new(1,1,1)
				GearText.TextWrap = true
				GearText.Parent = GearButton

		local GearGridScrollingArea = Instance.new("Frame")
		GearGridScrollingArea.RobloxLocked = true
		GearGridScrollingArea.Name = "GearGridScrollingArea"
		GearGridScrollingArea.Position = UDim2.new(1, -19, 0, 35)
		GearGridScrollingArea.Size = UDim2.new(0, 17, 1, -45)
		GearGridScrollingArea.BackgroundTransparency = 1
		GearGridScrollingArea.Parent = Gear

		local GearLoadouts = Instance.new("Frame")
		GearLoadouts.RobloxLocked = true
		GearLoadouts.Name = "GearLoadouts"
		GearLoadouts.BackgroundTransparency = 1
		GearLoadouts.Position = UDim2.new(0.7,23,0.5,1)
		GearLoadouts.Size = UDim2.new(0.3,-23,0.5,-1)
		GearLoadouts.Parent = Gear
		GearLoadouts.Visible = false
		
			-- GearLoadouts Children
			local GearLoadoutsHeader = Instance.new("Frame")
			GearLoadoutsHeader.RobloxLocked = true
			GearLoadoutsHeader.Name = "GearLoadoutsHeader"
			GearLoadoutsHeader.BackgroundColor3 = Color3.new(0,0,0)
			GearLoadoutsHeader.BackgroundTransparency = 0.2
			GearLoadoutsHeader.BorderColor3 = Color3.new(1,0,0)
			GearLoadoutsHeader.Size = UDim2.new(1,2,0.15,-1)
			GearLoadoutsHeader.Parent = GearLoadouts

				-- GearLoadoutsHeader Children
				local LoadoutsHeaderText = Instance.new("TextLabel")
				LoadoutsHeaderText.RobloxLocked = true
				LoadoutsHeaderText.Name = "LoadoutsHeaderText"
				LoadoutsHeaderText.BackgroundTransparency = 1
				LoadoutsHeaderText.Font = Enum.Font.ArialBold
				LoadoutsHeaderText.FontSize = Enum.FontSize.Size18
				LoadoutsHeaderText.Size = UDim2.new(1,0,1,0)
				LoadoutsHeaderText.Text = "Loadouts"
				LoadoutsHeaderText.TextColor3 = Color3.new(1,1,1)
				LoadoutsHeaderText.Parent = GearLoadoutsHeader
	
				local GearLoadoutsScrollingArea = GearGridScrollingArea:clone()
				GearLoadoutsScrollingArea.RobloxLocked = true
				GearLoadoutsScrollingArea.Name = "GearLoadoutsScrollingArea"
				GearLoadoutsScrollingArea.Position = UDim2.new(1,-15,0.15,2)
				GearLoadoutsScrollingArea.Size = UDim2.new(0,17,0.85,-2)
				GearLoadoutsScrollingArea.Parent = GearLoadouts

				local LoadoutsList = Instance.new("Frame")
				LoadoutsList.RobloxLocked = true
				LoadoutsList.Name = "LoadoutsList"
				LoadoutsList.Position = UDim2.new(0,0,0.15,2)
				LoadoutsList.Size = UDim2.new(1,-17,0.85,-2)
				LoadoutsList.Style = Enum.FrameStyle.RobloxSquare
				LoadoutsList.Parent = GearLoadouts
							
		local GearPreview = Instance.new("Frame")
		GearPreview.RobloxLocked = true
		GearPreview.Name = "GearPreview"
		GearPreview.Position = UDim2.new(0.7,23,0,0)
		GearPreview.Size = UDim2.new(0.3,-28,0.5,-1)
		GearPreview.BackgroundTransparency = 1
		GearPreview.ZIndex = 7
		GearPreview.Parent = Gear
		
			-- GearPreview Children
			local GearStats = Instance.new("Frame")
			GearStats.RobloxLocked = true
			GearStats.Name = "GearStats"
			GearStats.BackgroundTransparency = 1
			GearStats.Position = UDim2.new(0,0,0.75,0)
			GearStats.Size = UDim2.new(1,0,0.25,0)
			GearStats.ZIndex = 8
			GearStats.Parent = GearPreview
				
				-- GearStats Children
				local GearName = Instance.new("TextLabel")
				GearName.RobloxLocked = true
				GearName.Name = "GearName"
				GearName.BackgroundTransparency = 1
				GearName.Font = Enum.Font.ArialBold
				GearName.FontSize = Enum.FontSize.Size18
				GearName.Position = UDim2.new(0,-3,0,0)
				GearName.Size = UDim2.new(1,6,1,5)
				GearName.Text = ""
				GearName.TextColor3 = Color3.new(1,1,1)
				GearName.TextWrap = true
				GearName.ZIndex = 9
				GearName.Parent = GearStats
				
			local GearImage = Instance.new("ImageLabel")
			GearImage.RobloxLocked = true
			GearImage.Name = "GearImage"
			GearImage.Image = ""
			GearImage.BackgroundTransparency = 1
			GearImage.Position = UDim2.new(0.125,0,0,0)
			GearImage.Size = UDim2.new(0.75,0,0.75,0)
			GearImage.ZIndex = 8
			GearImage.Parent = GearPreview
			
				--GearImage Children
				local GearIcons = Instance.new("Frame")
				GearIcons.BackgroundColor3 = Color3.new(0,0,0)
				GearIcons.BackgroundTransparency = 0.5
				GearIcons.BorderSizePixel = 0
				GearIcons.RobloxLocked = true
				GearIcons.Name = "GearIcons"
				GearIcons.Position = UDim2.new(0.4,2,0.85,-2)
				GearIcons.Size = UDim2.new(0.6,0,0.15,0)
				GearIcons.Visible = false
				GearIcons.ZIndex = 9
				GearIcons.Parent = GearImage
				
					-- GearIcons Children
					local GenreImage = Instance.new("ImageLabel")
					GenreImage.RobloxLocked = true
					GenreImage.Name = "GenreImage"
					GenreImage.BackgroundColor3 = Color3.new(102/255,153/255,1)
					GenreImage.BackgroundTransparency = 0.5
					GenreImage.BorderSizePixel = 0
					GenreImage.Size = UDim2.new(0.25,0,1,0)
					GenreImage.Parent = GearIcons
					
					local AttributeOneImage = GenreImage:clone()
					AttributeOneImage.RobloxLocked = true
					AttributeOneImage.Name = "AttributeOneImage"
					AttributeOneImage.BackgroundColor3 = Color3.new(1,51/255,0)
					AttributeOneImage.Position = UDim2.new(0.25,0,0,0)
					AttributeOneImage.Parent = GearIcons
					
					local AttributeTwoImage = GenreImage:clone()
					AttributeTwoImage.RobloxLocked = true
					AttributeTwoImage.Name = "AttributeTwoImage"
					AttributeTwoImage.BackgroundColor3 = Color3.new(153/255,1,153/255)
					AttributeTwoImage.Position = UDim2.new(0.5,0,0,0)
					AttributeTwoImage.Parent = GearIcons
					
					local AttributeThreeImage = GenreImage:clone()
					AttributeThreeImage.RobloxLocked = true
					AttributeThreeImage.Name = "AttributeThreeImage"
					AttributeThreeImage.BackgroundColor3 = Color3.new(0,0.5,0.5)
					AttributeThreeImage.Position = UDim2.new(0.75,0,0,0)
					AttributeThreeImage.Parent = GearIcons

script:Destroy()