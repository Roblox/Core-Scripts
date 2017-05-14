--[[ 
	This script controls the gui the player sees in regards to his or her health.
	Copyright ROBLOX 2014. Written by Ben Tkacheff.
--]]

---------------------------------------------------------------------
-- Initialize/Variables
---------------------------------------------------------------------

repeat wait() until game
repeat wait() until game:GetService("Players").LocalPlayer

local Player = game:GetService("Players").LocalPlayer

-- NOTE: If you want to use this health script in your own game:
-- 1) Copy the contents of this file into a module.
-- 2) Create a localscript and parent it to StarterGui.
-- 3) In the localscript require() the chat module you made in step 1.
-- 4) Set the following variable to true.

local useDefault = false

local currentHumanoid = nil

local HealthGui = nil
local lastHealth = 100
local HealthPercentageForOverlay = 5
local maxBarTweenTime = 0.3
local greenColor = Color3.new(0.2, 1, 0.2)
local redColor = Color3.new(1, 0.2, 0.2)
local yellowColor = Color3.new(1, 1, 0.2)

local guiEnabled = false
local healthChangedConnection = nil
local humanoidDiedConnection = nil
local characterAddedConnection = nil

local greenBarImage = "rbxasset://textures/ui/Health-BKG-Center.png"
local greenBarImageLeft = "rbxasset://textures/ui/Health-BKG-Left-Cap.png"
local greenBarImageRight = "rbxasset://textures/ui/Health-BKG-Right-Cap.png"
local hurtOverlayImage = "https://www.roblox.com/asset/?id=34854607"

local capHeight = 15
local capWidth = 4

game:GetService("ContentProvider"):Preload(greenBarImage)
game:GetService("ContentProvider"):Preload(hurtOverlayImage)

---------------------------------------------------------------------
-- Services
---------------------------------------------------------------------

local Players = game:GetService("Players")
local CoreGui = game:GetService('CoreGui')
local StarterGui = game:GetService('StarterGui')

---------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------

function CreateGui()

	local hurtOverlay = Instance.new("ImageLabel")
	hurtOverlay.Name = "HurtOverlay"
	hurtOverlay.BackgroundTransparency = 1
	hurtOverlay.Image = hurtOverlayImage
	hurtOverlay.Position = UDim2.new(-10,0,-10,0)
	hurtOverlay.Size = UDim2.new(20,0,20,0)
	hurtOverlay.Visible = false
	hurtOverlay.Parent = HealthGui
	
	local healthFrame = Instance.new("Frame")
	healthFrame.Name = "HealthFrame"
	healthFrame.BackgroundTransparency = 1
	healthFrame.BackgroundColor3 = Color3.new(1,1,1)
	healthFrame.BorderColor3 = Color3.new(0,0,0)
	healthFrame.BorderSizePixel = 0
	healthFrame.Position = UDim2.new(0.5,-85,1,-20)
	healthFrame.Size = UDim2.new(0,170,0,capHeight)
	healthFrame.Parent = HealthGui

	local healthBarBackCenter = Instance.new("ImageLabel")
	healthBarBackCenter.Name = "healthBarBackCenter"
	healthBarBackCenter.BackgroundTransparency = 1
	healthBarBackCenter.Image = greenBarImage
	healthBarBackCenter.Size = UDim2.new(1,-capWidth*2,1,0)
	healthBarBackCenter.Position = UDim2.new(0,capWidth,0,0)
	healthBarBackCenter.Parent = healthFrame
	healthBarBackCenter.ImageColor3 = Color3.new(1,1,1)

	local healthBarBackLeft = Instance.new("ImageLabel")
	healthBarBackLeft.Name = "healthBarBackLeft"
	healthBarBackLeft.BackgroundTransparency = 1
	healthBarBackLeft.Image = greenBarImageLeft
	healthBarBackLeft.Size = UDim2.new(0,capWidth,1,0)
	healthBarBackLeft.Position = UDim2.new(0,0,0,0)
	healthBarBackLeft.Parent = healthFrame
	healthBarBackLeft.ImageColor3 = Color3.new(1,1,1)

	local healthBarBackRight = Instance.new("ImageLabel")
	healthBarBackRight.Name = "healthBarBackRight"
	healthBarBackRight.BackgroundTransparency = 1
	healthBarBackRight.Image = greenBarImageRight
	healthBarBackRight.Size = UDim2.new(0,capWidth,1,0)
	healthBarBackRight.Position = UDim2.new(1,-capWidth,0,0)
	healthBarBackRight.Parent = healthFrame
	healthBarBackRight.ImageColor3 = Color3.new(1,1,1)

	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.BackgroundTransparency = 1
	healthBar.BackgroundColor3 = Color3.new(1,1,1)
	healthBar.BorderColor3 = Color3.new(0,0,0)
	healthBar.BorderSizePixel = 0
	healthBar.ClipsDescendants = true
	healthBar.Position = UDim2.new(0, 0, 0, 0)
	healthBar.Size = UDim2.new(1,0,1,0)
	healthBar.Parent = healthFrame

	local healthBarCenter = Instance.new("ImageLabel")
	healthBarCenter.Name = "healthBarCenter"
	healthBarCenter.BackgroundTransparency = 1
	healthBarCenter.Image = greenBarImage
	healthBarCenter.Size = UDim2.new(1,-capWidth*2,1,0)
	healthBarCenter.Position = UDim2.new(0,capWidth,0,0)
	healthBarCenter.Parent = healthBar
	healthBarCenter.ImageColor3 = greenColor

	local healthBarLeft = Instance.new("ImageLabel")
	healthBarLeft.Name = "healthBarLeft"
	healthBarLeft.BackgroundTransparency = 1
	healthBarLeft.Image = greenBarImageLeft
	healthBarLeft.Size = UDim2.new(0,capWidth,1,0)
	healthBarLeft.Position = UDim2.new(0,0,0,0)
	healthBarLeft.Parent = healthBar
	healthBarLeft.ImageColor3 = greenColor

	local healthBarRight = Instance.new("ImageLabel")
	healthBarRight.Name = "healthBarRight"
	healthBarRight.BackgroundTransparency = 1
	healthBarRight.Image = greenBarImageRight
	healthBarRight.Size = UDim2.new(0,capWidth,1,0)
	healthBarRight.Position = UDim2.new(1,-capWidth,0,0)
	healthBarRight.Parent = healthBar
	healthBarRight.ImageColor3 = greenColor

end

function UpdateGui(health)
	if not HealthGui then return nil end
	
	local healthFrame = HealthGui:FindFirstChild("HealthFrame")
	if not healthFrame then return nil end
	
	local healthBar = healthFrame:FindFirstChild("HealthBar")
	if not healthBar then return nil end
	
	-- If more than 1/4 health, bar = green.  Else, bar = red.
	local percentHealth = (health/currentHumanoid.MaxHealth)
	if percentHealth ~= percentHealth then
		percentHealth = 1
		healthBar.healthBarCenter.ImageColor3 = yellowColor
		healthBar.healthBarRight.ImageColor3 = yellowColor
		healthBar.healthBarLeft.ImageColor3 = yellowColor
	elseif percentHealth > 0.25  then		
		healthBar.healthBarCenter.ImageColor3 = greenColor
		healthBar.healthBarRight.ImageColor3 = greenColor
		healthBar.healthBarLeft.ImageColor3 = greenColor
	else
		healthBar.healthBarCenter.ImageColor3 = redColor
		healthBar.healthBarRight.ImageColor3 = redColor
		healthBar.healthBarLeft.ImageColor3 = redColor
	end
		
	local width = (health / currentHumanoid.MaxHealth)
 	width = math.max(math.min(width,1),0) -- make sure width is between 0 and 1
 	if width ~= width then width = 1 end

	local healthDelta = lastHealth - health
	lastHealth = health
	
	local percentOfTotalHealth = math.abs(healthDelta/currentHumanoid.MaxHealth)
	percentOfTotalHealth = math.max(math.min(percentOfTotalHealth,1),0) -- make sure percentOfTotalHealth is between 0 and 1
	if percentOfTotalHealth ~= percentOfTotalHealth then percentOfTotalHealth = 1 end

	local newHealthSize = UDim2.new(width,0,1,0)
	
	healthBar.Size = newHealthSize

	local sizeX = healthBar.AbsoluteSize.X
	if sizeX < capWidth then
		healthBar.healthBarCenter.Visible = false
		healthBar.healthBarRight.Visible = false
	elseif sizeX < (2*capWidth + 1) then
		healthBar.healthBarCenter.Visible = true
		healthBar.healthBarCenter.Size = UDim2.new(0,sizeX - capWidth,1,0)
		healthBar.healthBarRight.Visible = false
	else
		healthBar.healthBarCenter.Visible = true
		healthBar.healthBarCenter.Size = UDim2.new(1,-capWidth*2,1,0)
		healthBar.healthBarRight.Visible = true
	end

	local thresholdForHurtOverlay = currentHumanoid.MaxHealth * (HealthPercentageForOverlay/100)
	
	if healthDelta >= thresholdForHurtOverlay and guiEnabled then
		AnimateHurtOverlay()
	end

end

function AnimateHurtOverlay()
	if not HealthGui then return nil end
	
	local overlay = HealthGui:FindFirstChild("HurtOverlay")
	if not overlay then return nil end
	
	local newSize = UDim2.new(20, 0, 20, 0)
	local newPos = UDim2.new(-10, 0, -10, 0)

	if overlay:IsDescendantOf(game) then
		-- stop any tweens on overlay
		overlay:TweenSizeAndPosition(newSize,newPos,Enum.EasingDirection.Out,Enum.EasingStyle.Linear,0,true,function()
			
			-- show the gui
			overlay.Size = UDim2.new(1,0,1,0)
			overlay.Position = UDim2.new(0,0,0,0)
			overlay.Visible = true
			
			-- now tween the hide
			if overlay:IsDescendantOf(game) then
				overlay:TweenSizeAndPosition(newSize,newPos,Enum.EasingDirection.Out,Enum.EasingStyle.Quad,10,false,function()
					overlay.Visible = false
				end)
			else
				overlay.Size = newSize
				overlay.Position = newPos
			end
		end)
	else
		overlay.Size = newSize
		overlay.Position = newPos
	end

end

function humanoidDied()
	 UpdateGui(0)
end

function disconnectPlayerConnections()
	if characterAddedConnection then characterAddedConnection:disconnect() end
	if humanoidDiedConnection then humanoidDiedConnection:disconnect() end
	if healthChangedConnection then healthChangedConnection:disconnect() end
end

function newPlayerCharacter()
	disconnectPlayerConnections()
	startGui()
end

function startGui()
	characterAddedConnection = Players.LocalPlayer.CharacterAdded:connect(newPlayerCharacter)

	local character = Players.LocalPlayer.Character
	if not character then
		return nil
	end

	currentHumanoid = character:WaitForChild("Humanoid")
	if not currentHumanoid then
		return nil
	end

	if not StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health) then
		if useDefault == false then
			return nil
		end		
	end
	
	healthChangedConnection = currentHumanoid.HealthChanged:connect(UpdateGui)
	humanoidDiedConnection = currentHumanoid.Died:connect(humanoidDied)
	UpdateGui(currentHumanoid.Health)
	CreateGui()
end

---------------------------------------------------------------------
-- Start Script
---------------------------------------------------------------------

function begin()
	if StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health) == true or StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health) == true then
		if useDefault == false then
			guiEnabled = true
			HealthGui = Instance.new("ScreenGui")
			HealthGui.Name = "HealthGui"
			HealthGui.Parent = Player.PlayerGui
			startGui()
		else
			guiEnabled = true
			HealthGui = Instance.new("ScreenGui")
			HealthGui.Name = "HealthGui"
			HealthGui.Parent = CoreGui.RobloxGui
			startGui()
		end
	elseif StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health) == false or StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health) == false then
		if useDefault == false then
			guiEnabled = true
			HealthGui = Instance.new("ScreenGui")
			HealthGui.Name = "HealthGui"
			HealthGui.Parent = Player.PlayerGui
			startGui()
		end
	end
end

pcall(function()StarterGui.CoreGuiChangedSignal:connect(function(coreGuiType,enabled)
	if coreGuiType == Enum.CoreGuiType.Health or coreGuiType == Enum.CoreGuiType.All then
		if game:GetService("StarterGui"):GetCoreGuiEnabled(Enum.CoreGuiType.Health) == true then
			begin()
		elseif game:GetService("StarterGui"):GetCoreGuiEnabled(Enum.CoreGuiType.Health) == false then
			begin()
		end
	end
end)
end)

begin()

return true
