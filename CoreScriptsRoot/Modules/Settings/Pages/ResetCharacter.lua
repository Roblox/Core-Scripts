--[[
		Filename: ResetCharacter.lua
		Written by: jeditkacheff
		Version 1.0
		Description: Takes care of the reseting the character in Settings Menu
--]]

-------------- CONSTANTS -------------
local RESET_CHARACTER_GAME_ACTION = "ResetCharacterAction"
local RESET_ENABLED_TEXT = "Are you sure you want to reset your character?"
local RESET_DISABLED_TEXT = "The game doesn't allow you to reset!"

-------------- SERVICES --------------
local CoreGui = game:GetService("CoreGui")
local ContextActionService = game:GetService("ContextActionService")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players)

----------- UTILITIES --------------
local utility = require(RobloxGui.Modules.Settings.Utility)

local function canResetChar()
	local character = Player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			return humanoid:GetStateEnabled(Enum.HumanoidStateType.Dead)
		end
	end return false	
end

------------ Variables -------------------
local PageInstance = nil
RobloxGui:WaitForChild("Modules"):WaitForChild("TenFootInterface")
local isTenFootInterface = require(RobloxGui.Modules.TenFootInterface):IsEnabled()
local Player = Players.LocalPlayer

----------- CLASS DECLARATION --------------
local function Initialize()
	local settingsPageFactory = require(RobloxGui.Modules.Settings.SettingsPageFactory)
	local this = settingsPageFactory:CreateNewPage()

	this.DontResetCharFunc = function(isUsingGamepad)
		if this.HubRef then
			this.HubRef:PopMenu(isUsingGamepad, true)
		end
	end
	this.DontResetCharFromHotkey = function(name, state, input)
		if state == Enum.UserInputState.Begin then
			local isUsingGamepad = input.UserInputType == Enum.UserInputType.Gamepad1 or input.UserInputType == Enum.UserInputType.Gamepad2
				or input.UserInputType == Enum.UserInputType.Gamepad3 or input.UserInputType == Enum.UserInputType.Gamepad4

			this.DontResetCharFunc(isUsingGamepad)
		end
	end
	this.DontResetCharFromButton = function(isUsingGamepad)
		this.DontResetCharFunc(isUsingGamepad)
	end
	
	------ TAB CUSTOMIZATION -------
	this.TabHeader = nil -- no tab for this page

	------ PAGE CUSTOMIZATION -------
	this.Page.Name = "ResetCharacter"

	local resetCharacterText =  utility:Create'TextLabel'
	{
		Name = "ResetCharacterText",
		Text = RESET_ENABLED_TEXT,
		Font = Enum.Font.SourceSansBold,
		FontSize = Enum.FontSize.Size36,
		TextColor3 = Color3.new(1,1,1),
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0,200),
		TextWrapped = true,
		ZIndex = 2,
		Parent = this.Page
	};
	this.resetCharacterText = resetCharacterText
	if utility:IsSmallTouchScreen() then
		resetCharacterText.FontSize = Enum.FontSize.Size24
		resetCharacterText.Size = UDim2.new(1,0,0,100)
	elseif isTenFootInterface then
		resetCharacterText.FontSize = Enum.FontSize.Size48
	end

	------ Init -------
	local function resetCharFuncn()
		local character = Player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				if humanoid:GetStateEnabled(Enum.HumanoidStateType.Dead) then
					humanoid.Health = 0
				end
			end
		end

		if this.HubRef then
			this.HubRef:SetVisibility(false, true)
		end
	end

	local buttonSpacing = 20
	local buttonSize = UDim2.new(0, 200, 0, 50)
	if isTenFootInterface then
		resetCharacterText.Position = UDim2.new(0,0,0,100)
		buttonSize = UDim2.new(0, 300, 0, 80)
	end

	local ResetCharacterButton = utility:MakeStyledButton("ResetCharacter", "Reset", buttonSize, resetCharFunc)
	this.ResetCharacterButton = ResetCharacterButton
	ResetCharacterButton.NextSelectionRight = nil
	if utility:IsSmallTouchScreen() then
		ResetCharacterButton.Position = UDim2.new(0.5, -buttonSize.X.Offset - buttonSpacing, 1, 0)
	else
		ResetCharacterButton.Position = UDim2.new(0.5, -buttonSize.X.Offset - buttonSpacing, 1, -30)
	end
	ResetCharacterButton.Parent = resetCharacterText


	local dontResetCharacterButton = utility:MakeStyledButton("DontResetCharacter", "Don't Reset", buttonSize, this.DontResetCharFromButton)
	this.dontResetCharacterButton = dontResetCharacterButton
	dontResetCharacterButton.NextSelectionLeft = nil
	if utility:IsSmallTouchScreen() then
		dontResetCharacterButton.Position = UDim2.new(0.5, buttonSpacing, 1, 0)
	else
		dontResetCharacterButton.Position = UDim2.new(0.5, buttonSpacing, 1, -30)
	end
	dontResetCharacterButton.Parent = resetCharacterText

	this.Page.Size = UDim2.new(1,0,0,dontResetCharacterButton.AbsolutePosition.Y + dontResetCharacterButton.AbsoluteSize.Y)
	
	return this
end


----------- Public Facing API Additions --------------
PageInstance = Initialize()

PageInstance.Displayed.Event:connect(function()
	local canReset = canResetChar()
	PageInstance.ResetCharacterButton.Visible = canReset
	PageInstance.resetCharacterText.Text = canReset and RESET_ENABLED_TEXT or RESET_DISABLED_TEXT
	GuiService.SelectedCoreObject = PageInstance[canReset and "ResetCharacterButton" or "dontResetCharacterButton"]
	ContextActionService:BindCoreAction(RESET_CHARACTER_GAME_ACTION, PageInstance.DontResetCharFromHotkey, false, Enum.KeyCode.ButtonB)
end)

PageInstance.Hidden.Event:connect(function()
	ContextActionService:UnbindCoreAction(RESET_CHARACTER_GAME_ACTION)
end)


return PageInstance
