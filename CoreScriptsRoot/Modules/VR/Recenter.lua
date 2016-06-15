local InputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local Panel3D = require(RobloxGui.Modules.VR.Panel3D)
local VRHub = require(RobloxGui.Modules.VR.VRHub)
local Util = require(RobloxGui.Modules.Settings.Utility)

local RecenterModule = {}
RecenterModule.ModuleName = "Recenter"
RecenterModule.KeepVRTopbarOpen = true
VRHub:RegisterModule(RecenterModule)

local countdownPanel = Panel3D.Get("RecenterCountdown")
countdownPanel:SetType(Panel3D.Type.HorizontalFollow)
countdownPanel:ResizeStuds(1, 1, 128)
countdownPanel:SetCanFade(false)

local countdown = Util:Create "TextLabel" {
	Parent = countdownPanel:GetGUI(),

	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(1, 0, 1, 0),

	BackgroundTransparency = 0.9,
	BackgroundColor3 = Color3.new(0.2, 0.2, 0.2),

	TextColor3 = Color3.new(1, 1, 1),
	Text = "",
	TextScaled = true,
	Font = Enum.Font.SourceSansBold,

	Visible = true
}

countdownPanel:SetVisible(false)

local isCountingDown = false

VRHub.ModuleOpened.Event:connect(function(moduleName, isExclusive)
	if moduleName ~= RecenterModule.ModuleName and isExclusive then
		isCountingDown = false
	end
end)

function RecenterModule:SetVisible(visible)
	if visible then
		if isCountingDown then
			isCountingDown = false
			VRHub:FireModuleClosed(RecenterModule.ModuleName)
			return
		else
			VRHub:FireModuleOpened(RecenterModule.ModuleName, true, true)
		end

		spawn(function()
			isCountingDown = true
			countdownPanel:SetVisible(true)

			for i = 3, 1, -1 do
				if isCountingDown then
					countdown.Text = tostring(i)
					wait(1)
				end
			end

			if isCountingDown then
				InputService:RecenterUserHeadCFrame() 
			end

			countdownPanel:SetVisible(false)
			isCountingDown = false

			VRHub:FireModuleClosed(RecenterModule.ModuleName)
		end)
	else
		VRHub:FireModuleClosed(RecenterModule.ModuleName)
	end
end


return RecenterModule