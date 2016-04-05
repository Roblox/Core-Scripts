--BackpackScript3D: VR port of backpack interface using a 3D panel
--written by 0xBAADF00D
local ICON_SIZE = 48
local ICON_SPACING = 52
local PIXELS_PER_STUD = 64

local SLOT_BORDER_SIZE = 0
local SLOT_BORDER_SELECTED_SIZE = 4
local SLOT_BORDER_COLOR = Color3.new(90/255, 142/255, 233/255)
local SLOT_BACKGROUND_COLOR = Color3.new(31/255, 31/255, 31/255)
local SLOT_HOVER_BACKGROUND_COLOR = Color3.new(90/255, 90/255, 90/255)

local HOPPERBIN_ANGLE = math.rad(-45)
local HOPPERBIN_ROTATION = CFrame.Angles(HOPPERBIN_ANGLE, 0, 0)
local HOPPERBIN_OFFSET = Vector3.new(0, 0, -5)

local HEALTHBAR_SPACE = 10
local HEALTHBAR_WIDTH = 80
local HEALTHBAR_HEIGHT = 3

local Tools = {}
local ToolsList = {}

local BackpackScript = {}
local topbarEnabled = false

local player = game.Players.LocalPlayer
local currentHumanoid = nil
local CoreGui = game:GetService('CoreGui')
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local Panel3D = require(RobloxGui.Modules.Panel3D)

local ContextActionService = game:GetService("ContextActionService")

local panel = Panel3D.Get(Panel3D.Panels.Lower)
local toolsFrame = Instance.new("TextButton", panel.gui) --prevent clicks falling through in case you have a rocket launcher and blow yourself up
toolsFrame.Text = ""
toolsFrame.Size = UDim2.new(1, 0, 0, ICON_SIZE)
toolsFrame.BackgroundTransparency = 1
local insetAdjustY = toolsFrame.AbsolutePosition.Y
toolsFrame.Position = UDim2.new(0, 0, 0, HEALTHBAR_SPACE)

--Healthbar color function stolen from Topbar.lua
local HEALTH_BACKGROUND_COLOR = Color3.new(228/255, 236/255, 246/255)
local HEALTH_RED_COLOR = Color3.new(255/255, 28/255, 0/255)
local HEALTH_YELLOW_COLOR = Color3.new(250/255, 235/255, 0)
local HEALTH_GREEN_COLOR = Color3.new(27/255, 252/255, 107/255)

local healthbarBack = Instance.new("Frame", panel.gui)
healthbarBack.BackgroundColor3 = HEALTH_BACKGROUND_COLOR
healthbarBack.BorderSizePixel = 0
healthbarBack.Name = "HealthbarContainer"
local healthbarFront = Instance.new("Frame", healthbarBack)
healthbarFront.BorderSizePixel = 0
healthbarFront.Size = UDim2.new(1, 0, 1, 0)
healthbarFront.Position = UDim2.new(0, 0, 0, 0)
healthbarFront.BackgroundColor3 = HEALTH_GREEN_COLOR
healthbarFront.Name = "HealthbarFill"

local healthColorToPosition = {
	[Vector3.new(HEALTH_RED_COLOR.r, HEALTH_RED_COLOR.g, HEALTH_RED_COLOR.b)] = 0.1;
	[Vector3.new(HEALTH_YELLOW_COLOR.r, HEALTH_YELLOW_COLOR.g, HEALTH_YELLOW_COLOR.b)] = 0.5;
	[Vector3.new(HEALTH_GREEN_COLOR.r, HEALTH_GREEN_COLOR.g, HEALTH_GREEN_COLOR.b)] = 0.8;
}
local min = 0.1
local minColor = HEALTH_RED_COLOR
local max = 0.8
local maxColor = HEALTH_GREEN_COLOR

local function HealthbarColorTransferFunction(healthPercent)
	if healthPercent < min then
		return minColor
	elseif healthPercent > max then
		return maxColor
	end

	-- Shepard's Interpolation
	local numeratorSum = Vector3.new(0,0,0)
	local denominatorSum = 0
	for colorSampleValue, samplePoint in pairs(healthColorToPosition) do
		local distance = healthPercent - samplePoint
		if distance == 0 then
			-- If we are exactly on an existing sample value then we don't need to interpolate
			return Color3.new(colorSampleValue.x, colorSampleValue.y, colorSampleValue.z)
		else
			local wi = 1 / (distance*distance)
			numeratorSum = numeratorSum + wi * colorSampleValue
			denominatorSum = denominatorSum + wi
		end
	end
	local result = numeratorSum / denominatorSum
	return Color3.new(result.x, result.y, result.z)
end
---

local verticalRange = math.rad(0)
local horizontalRange = math.rad(0)

local backpackEnabled = true
local healthbarEnabled = true

local function UpdateLayout()
	local width, height = 100, 100
	local borderSize = (ICON_SPACING - ICON_SIZE) / 2	
	
	local x = borderSize
	local y = 0
	for _, tool in ipairs(ToolsList) do
		local slot = Tools[tool]
		if slot then
			slot.icon.Position = UDim2.new(0, x, 0, y)
			x = x + ICON_SPACING
		end
	end
	
	width = #ToolsList * ICON_SPACING
	height = ICON_SIZE + HEALTHBAR_SPACE
	
--	hopperbinGUI.CanvasSize = Vector2.new(width, height)
--	hopperbinPart.Size = Vector3.new(width / PIXELS_PER_STUD, height / PIXELS_PER_STUD, 1)	

	panel:ResizePixels(width, height)

	healthbarBack.Position = UDim2.new(0.5, -HEALTHBAR_WIDTH / 2, 0, (HEALTHBAR_SPACE - HEALTHBAR_HEIGHT) / 2)
	healthbarBack.Size = UDim2.new(0, HEALTHBAR_WIDTH, 0, HEALTHBAR_HEIGHT)
end

local function UpdateHealth(humanoid)
	local percentHealth = humanoid.Health / humanoid.MaxHealth
	if percentHealth ~= percentHealth then
		percentHealth = 1
	end
	healthbarFront.BackgroundColor3 = HealthbarColorTransferFunction(percentHealth)
	healthbarFront.Size = UDim2.new(percentHealth, 0, 1, 0)
end

local function SetTransparency(transparency)
	for i, v in pairs(Tools) do
		v.icon.BackgroundTransparency = transparency + 0.5
		v.icon.ImageTransparency = transparency
	end

	healthbarBack.BackgroundTransparency = transparency
	healthbarFront.BackgroundTransparency = transparency
end
panel:AddTransparencyCallback(SetTransparency)

local function OnHotbarEquipPrimary(actionName, state, obj)
	if state ~= Enum.UserInputState.Begin then
		return
	end
	for tool, slot in pairs(Tools) do
		if slot.hovered then
			slot.OnClick()
		end
	end
end

local eaterAction = game:GetService("HttpService"):GenerateGUID()
local function EnableHotbarInput(enable)
	if not backpackEnabled then
		enable = false
	end
	if not currentHumanoid then
		return
	end
	if enable then
		ContextActionService:BindCoreAction("HotbarEquipPrimary", OnHotbarEquipPrimary, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
		ContextActionService:BindAction(eaterAction, function() end, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
	else
		ContextActionService:UnbindCoreAction("HotbarEquipPrimary")
		ContextActionService:UnbindAction(eaterAction)
	end
end

local function AddTool(tool)
	if Tools[tool] then
		return
	end

	local slot = {}
	Tools[tool] = slot
	table.insert(ToolsList, tool)

	slot.hovered = false
	slot.tool = tool
	slot.icon = Instance.new("ImageButton", toolsFrame)
	slot.icon.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
	slot.icon.BackgroundColor3 = Color3.new(0, 0, 0)
	slot.icon.BorderSizePixel = SLOT_BORDER_SIZE
	slot.icon.BorderColor3 = SLOT_BORDER_COLOR
	slot.icon.Image = tool.TextureId

	slot.OnClick = function()
		if not player.Character then return end
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if not humanoid then return end
		
		local in_backpack = tool.Parent == player.Backpack
		humanoid:UnequipTools()
		if in_backpack then
			humanoid:EquipTool(tool)
		end
	end
	
	slot.icon.MouseButton1Click:connect(slot.OnClick)
	slot.OnEnter = function()
		slot.icon.BackgroundColor3 = SLOT_HOVER_BACKGROUND_COLOR
		slot.hovered = true
		EnableHotbarInput(true)
	end
	slot.OnLeave = function()
		slot.icon.BackgroundColor3 = SLOT_BACKGROUND_COLOR
		slot.hovered = false
		EnableHotbarInput(false)
	end
--	slot.icon.MouseEnter:connect(slot.OnEnter)
--	slot.icon.MouseLeave:connect(slot.OnLeave)

	tool.Changed:connect(function(prop)
		if tool.Parent == player:FindFirstChild("Backpack") then
			slot.icon.BorderSizePixel = SLOT_BORDER_SIZE
		elseif tool.Parent == player.Character then
			slot.icon.BorderSizePixel = SLOT_BORDER_SELECTED_SIZE
		end
	end)
	
	UpdateLayout()
end

local humanoidChangedEvent = nil
local humanoidAncestryChangedEvent = nil
local function RegisterHumanoid(humanoid)
	currentHumanoid = humanoid
	if humanoidChangedEvent then
		humanoidChangedEvent:disconnect()
		humanoidChangedEvent = nil
	end
	if humanoidAncestryChangedEvent then
		humanoidAncestryChangedEvent:disconnect()
		humanoidAncestryChangedEvent = nil
	end
	if humanoid then
		humanoidChangedEvent = humanoid.HealthChanged:connect(function() UpdateHealth(humanoid) end)
		humanoidAncestryChangedEvent = humanoid.AncestryChanged:connect(function(child, parent) 
			if child == humanoid and parent ~= player.Character then
				RegisterHumanoid(nil)
			end
		end)
		UpdateHealth(humanoid)
	end
end

local function OnChildAdded(child)
	if child:IsA("Tool") or child:IsA("HopperBin") then
		AddTool(child)
	end
	if child:IsA("Humanoid") and child.Parent == player.Character then
		RegisterHumanoid(child)
	end
end

local function RemoveTool(tool)
	if not Tools[tool] then
		return
	end
	Tools[tool].icon:Destroy()
	for i, v in ipairs(ToolsList) do
		if v == tool then
			table.remove(ToolsList, i)
			break
		end
	end
	Tools[tool] = nil
	UpdateLayout()
end

local function OnChildRemoved(child)
	if child:IsA("Tool") or child:IsA("HopperBin") then
		if Tools[child] then
			if child.Parent ~= player:FindFirstChild("Backpack") and child.Parent ~= player.Character then
				RemoveTool(child)
			end
		end
	end
end

local function OnCharacterAdded(character)
	local backpack = player:WaitForChild("Backpack")

	for i, v in ipairs(character:GetChildren()) do
		if v:IsA("Humanoid") then
			RegisterHumanoid(v)
			break
		end
	end

	for tool, v in pairs(Tools) do
		RemoveTool(tool)
	end
	Tools = {}
	ToolsList = {}
	
	character.ChildAdded:connect(OnChildAdded)
	character.ChildRemoved:connect(OnChildRemoved)
	
	for i, v in ipairs(backpack:GetChildren()) do
		OnChildAdded(v)
	end
	
	backpack.ChildAdded:connect(OnChildAdded)
	backpack.ChildRemoved:connect(OnChildRemoved)
end

player.CharacterAdded:connect(OnCharacterAdded)
if player.Character then
	spawn(function() OnCharacterAdded(player.Character) end)
end

game:GetService("RunService"):BindToRenderStep("Cursor3D", Enum.RenderPriority.Last.Value, function()
	if not backpackEnabled then
		return
	end
	if not player.Character then
		return
	end

	local cframe = workspace.CurrentCamera:GetRenderCFrame()
	local ray = Ray.new(cframe.p, cframe.lookVector * 999)
	local ignoreList = { player.Character }
	local part, endpoint = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)

	if part ~= panel.part then
		for i, v in pairs(Tools) do
			if v.hovered then
				v.OnLeave()
			end
		end
		return
	end
	
	local localEndpoint = part:GetRenderCFrame():pointToObjectSpace(endpoint)
	local x = 1 - ((localEndpoint.X / part.Size.X) + 0.5)
	local y = 1 - ((localEndpoint.Y / part.Size.Y) + 0.5)
	
	--REMOVE THIS WHEN GUI MOUSELEAVE/MOUSEENTER ARE FIXED
	local px = x * panel.gui.AbsoluteSize.X
	local py = y * panel.gui.AbsoluteSize.Y + insetAdjustY --this can go once AbsolutePosition is fixed for sure
	for i, v in pairs(Tools) do
		local ix = px - v.icon.AbsolutePosition.X
		local iy = py - v.icon.AbsolutePosition.Y
		if ix > 0 and ix < v.icon.AbsoluteSize.X and iy > 0 and iy < v.icon.AbsoluteSize.Y then
			if not v.hovered then
				v.OnEnter()
			end
		else
			if v.hovered then
				v.OnLeave()
			end
		end
	end
	------------------------------------------------------
end)

local function OnHotbarEquip(actionName, state, obj)
	if not backpackEnabled then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	if not currentHumanoid then
		return
	end
	if state ~= Enum.UserInputState.Begin then
		return
	end
	if #ToolsList == 0 then
		return
	end
	local current = 0
	for i, v in pairs(ToolsList) do
		if v.Parent == character then
			current = i
		end
	end
	currentHumanoid:UnequipTools()
	if obj.KeyCode == Enum.KeyCode.ButtonR1 then
		current = current + 1
		if current > #ToolsList then
			current = 1
		end
	else
		current = current - 1
		if current < 1 then
			current = #ToolsList
		end
	end
	currentHumanoid:EquipTool(ToolsList[current])
end

local function OnCoreGuiChanged(coreGuiType, enabled)
	-- Check for enabling/disabling the whole thing
	if coreGuiType == Enum.CoreGuiType.Backpack or coreGuiType == Enum.CoreGuiType.All then
		backpackEnabled = enabled
		if enabled then
			ContextActionService:BindCoreAction("HotbarEquip2", OnHotbarEquip, false, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1)
			toolsFrame.Parent = panel.gui
		else
			ContextActionService:UnbindCoreAction("HotbarEquip2")
			toolsFrame.Parent = nil
		end
	end

	if coreGuiType == Enum.CoreGuiType.Health or coreGuiType == Enum.CoreGuiType.All then
		healthbarEnabled = enabled
		if enabled then
			healthbarBack.Parent = panel.gui
		else
			healthbarBack.Parent = nil
		end
	end
end

local StarterGui = game:GetService("StarterGui")
StarterGui.CoreGuiChangedSignal:connect(OnCoreGuiChanged)
OnCoreGuiChanged(Enum.CoreGuiType.Backpack, StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack))
OnCoreGuiChanged(Enum.CoreGuiType.Backpack, StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.All))

OnCoreGuiChanged(Enum.CoreGuiType.Health, StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health))
OnCoreGuiChanged(Enum.CoreGuiType.Health, StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.All))

return BackpackScript