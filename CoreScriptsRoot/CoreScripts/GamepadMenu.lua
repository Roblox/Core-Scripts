--[[ SERVICES ]]
local GuiService = game:GetService('GuiService')
local CoreGuiService = game:GetService('CoreGui')
local InputService = game:GetService('UserInputService')
local ContextActionService = game:GetService('ContextActionService')
local StarterGui = game:GetService('StarterGui')
--[[ END OF SERVICES ]]

local GuiRoot = CoreGuiService:WaitForChild('RobloxGui')
local Util = {}
do
	function Util.Create(instanceType)
		return function(data)
			local obj = Instance.new(instanceType)
			for k, v in pairs(data) do
				if type(k) == 'number' then
					v.Parent = obj
				else
					obj[k] = v
				end
			end
			return obj
		end
	end
end

local gamepadSettingsFrame = nil

local function createGamepadMenuGui()
	gamepadSettingsFrame = Util.Create'Frame'{
		Name = "GamepadSettingsFrame";
		BorderSizePixel = 2;
		Position = UDim2.new(0.5,0,0.5,0);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Size = UDim2.new(0,1,0,1);
		Visible = false;
		Parent = GuiRoot;
	}

	local backpackGamepad = Util.Create'TextButton'{
		Name = "Backpack";
		Position = UDim2.new(0,100,0,-50);
		Size = UDim2.new(0,100,0,100);
		Font = Enum.Font.SourceSansBold;
		FontSize = Enum.FontSize.Size24;
		BackgroundColor3 = Color3.new(1,1,1);
		Text = "Backpack";
		Parent = gamepadSettingsFrame;
	}
	local settingsGamepad = Util.Create'TextButton'{
		Name = "Settings";
		Position = UDim2.new(0,-50,0,-200);
		Size = UDim2.new(0,100,0,100);
		Font = Enum.Font.SourceSansBold;
		FontSize = Enum.FontSize.Size24;
		BackgroundColor3 = Color3.new(1,1,1);
		Text = "Settings";
		Parent = gamepadSettingsFrame;
	}
	local playerListGamepad = Util.Create'TextButton'{
		Name = "PlayerList";
		Position = UDim2.new(0,-200,0,-50);
		Size = UDim2.new(0,100,0,100);
		Font = Enum.Font.SourceSansBold;
		FontSize = Enum.FontSize.Size24;
		BackgroundColor3 = Color3.new(1,1,1);
		Text = "Player List";
		Parent = gamepadSettingsFrame;
	}
	local chatGamepad = Util.Create'TextButton'{
		Name = "Chat";
		Position = UDim2.new(0,-50,0,100);
		Size = UDim2.new(0,100,0,100);
		Font = Enum.Font.SourceSansBold;
		FontSize = Enum.FontSize.Size24;
		BackgroundColor3 = Color3.new(1,1,1);
		Text = "Chat";
		Parent = gamepadSettingsFrame;
	}
	--todo: notications!
	
	local closeHintImage = Util.Create'ImageLabel'{
		Name = "CloseHint";
		Position = UDim2.new(0,200,0,200);
		Size = UDim2.new(0,40,0,40);
		BackgroundTransparency = 1;
		Image = "http://www.roblox.com/asset?id=238273272";
		Parent = gamepadSettingsFrame;
	}
	local closeHintText = Util.Create'TextLabel'{
		Name = "closeHintText";
		Position = UDim2.new(1,0,0,0);
		Size = UDim2.new(0,80,0,40);
		Font = Enum.Font.SourceSans;
		FontSize = Enum.FontSize.Size18;
		BackgroundTransparency = 1;
		Text = "   Close";
		TextColor3 = Color3.new(1,1,1);
		TextStrokeTransparency = 0;
		TextXAlignment = Enum.TextXAlignment.Left;
		Parent = closeHintImage;
	}

	GuiService:AddSelectionParent("CoreUIMainGroup", gamepadSettingsFrame)

	settingsGamepad.MouseButton1Click:connect(function()
		unbindAllRadialActions()
		gamepadSettingsFrame.Visible = false
		local MenuModule = require(GuiRoot.Modules.Settings2)
		MenuModule:ToggleVisibility(true)
	end)
	backpackGamepad.MouseButton1Click:connect(function()
		unbindAllRadialActions()
		gamepadSettingsFrame.Visible = false
		local BackpackModule = require(GuiRoot.Modules.BackpackScript)
		BackpackModule:OpenClose()
	end)
	playerListGamepad.MouseButton1Click:connect(function()
		unbindAllRadialActions()
		gamepadSettingsFrame.Visible = false
		local PlayerlistModule = require(GuiRoot.Modules.PlayerlistModule)
		PlayerlistModule.ToggleVisibility()
	end)
	chatGamepad.MouseButton1Click:connect(function()
		unbindAllRadialActions()
		gamepadSettingsFrame.Visible = false
		local ChatModule = require(GuiRoot.Modules.Chat)
		ChatModule:ToggleVisibility()
	end)

	gamepadSettingsFrame.Changed:connect(function(prop)
		if prop == "Visible" then
			if not gamepadSettingsFrame.Visible then
				unbindAllRadialActions()
			end
		end
	end)
end

local function isCoreGuiDisabled()
	for _, enumItem in pairs(Enum.CoreGuiType:GetEnumItems()) do
		if StarterGui:GetCoreGuiEnabled(enumItem) then
			return false
		end
	end

	return true
end

local function setupGamepadControls()
	local freezeControllerActionName = "doNothingAction"
	local radialSelectActionName = "RadialSelectAction"
	local radialCancelActionName = "RadialSelectCancel"

	local noOpFunc = function() end

	function unbindAllRadialActions()
		pcall(function() GuiService.GamepadNavigationEnabled = true end)
		ContextActionService:UnbindCoreAction(radialSelectActionName)
		ContextActionService:UnbindCoreAction(radialCancelActionName)
		ContextActionService:UnbindCoreAction(freezeControllerActionName)
	end

	local radialSelect = function(name, state, input)
		local inputVector = Vector2.new(0,0)

		if input.KeyCode == Enum.KeyCode.Thumbstick1 then
			inputVector = Vector2.new(input.Position.x, -input.Position.y)
		elseif state == Enum.UserInputState.Begin then
			if input.KeyCode == Enum.KeyCode.DPadLeft then
				inputVector = Vector2.new(-1,0)
			elseif input.KeyCode == Enum.KeyCode.DPadRight then
				inputVector = Vector2.new(1,0)
			elseif input.KeyCode == Enum.KeyCode.DPadUp then
				inputVector = Vector2.new(0,-1)
			elseif input.KeyCode == Enum.KeyCode.DPadDown then
				inputVector = Vector2.new(0,1)
			end
		end

		local selectedObject = nil

		-- get input direction gui
		if inputVector.magnitude > 0.5 then
			if math.abs(inputVector.x) > math.abs(inputVector.y) then
				if inputVector.x < 0 then
					selectedObject = gamepadSettingsFrame.PlayerList
				else
					selectedObject = gamepadSettingsFrame.Backpack
				end
			else
				if inputVector.y < 0 then
					selectedObject = gamepadSettingsFrame.Settings
				else
					selectedObject = gamepadSettingsFrame.Chat
				end
			end

			pcall(function() GuiService.SelectedCoreObject = selectedObject end)
		end
	end

	local radialSelectCancel = function(name, state, input)
		if state == Enum.UserInputState.Begin then
			if gamepadSettingsFrame.Visible then
				toggleCoreGuiRadial()
			end
		end
	end

	function toggleSettings()
	end

	function toggleCoreGuiRadial()
		gamepadSettingsFrame.Visible = not gamepadSettingsFrame.Visible

		if gamepadSettingsFrame.Visible then
			pcall(function() GuiService.GamepadNavigationEnabled = false end)

			ContextActionService:BindCoreAction(freezeControllerActionName, noOpFunc, false, Enum.UserInputType.Gamepad1)
			ContextActionService:BindCoreAction(radialCancelActionName, radialSelectCancel, false, Enum.KeyCode.ButtonB)
			ContextActionService:BindCoreAction(radialSelectActionName, radialSelect, false, Enum.KeyCode.Thumbstick1, 
				Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight, Enum.KeyCode.DPadUp, Enum.KeyCode.DPadDown)
		else
			pcall(function() GuiService.SelectedCoreObject = nil end)
			unbindAllRadialActions()
		end

		return gamepadSettingsFrame.Visible
	end


	local doGamepadMenuButton = function(name, state, input)
		if input.UserInputType ~= Enum.UserInputType.Gamepad1 then return end
		if state ~= Enum.UserInputState.Begin then return end

		ContextActionService:BindCoreAction(freezeControllerActionName, noOpFunc, false, Enum.UserInputType.Gamepad1)

		if isCoreGuiDisabled() then
			local shouldKillGamepadInput = toggleSettings()
			if not shouldKillGamepadInput then
				unbindAllRadialActions()
			end
		else
			local radialIsShown = toggleCoreGuiRadial()
			if not radialIsShown then
				unbindAllRadialActions()
			end
		end
	end

	if InputService:GetGamepadConnected(Enum.UserInputType.Gamepad1) then
		createGamepadMenuGui()
	else
		InputService.GamepadConnected:connect(function(gamepadEnum) 
			if gamepadEnum == Enum.UserInputType.Gamepad1 then
				createGamepadMenuGui()
			end
		end)
	end

	ContextActionService:BindCoreAction("RBXToggleMenuAction", doGamepadMenuButton, false, Enum.KeyCode.ButtonStart)
end

-- hook up gamepad stuff
setupGamepadControls()