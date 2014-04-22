local vChar = script.Parent
local vPlayer = game.Players:GetPlayerFromCharacter(vChar)
playerGui = vPlayer.PlayerGui

local config = vChar:FindFirstChild("PlayerStats")
while config == nil do
	config = vChar:FindFirstChild("PlayerStats")
	wait()
end

buffGui = Instance.new("ScreenGui")
buffGui.Parent = playerGui
buffGui.Name = "BuffGUI"

tray = Instance.new("Frame")
tray.BackgroundTransparency = 1.0
tray.Parent = buffGui
tray.Name = "Tray"
tray.Position = UDim2.new(0.40, 0.0, 0.95, 0.0)
tray.Size = UDim2.new(0.0, 300.0, 0.0, 30.0)
tray.BorderColor3 = Color3.new(0, 0, 0)
tray.Visible = true

local iceLabel = Instance.new("ImageLabel")
iceLabel.Name = "Ice"
iceLabel.Size = UDim2.new(0.1, 0.0, 0.8, 0.0)
iceLabel.BackgroundTransparency = 1.0
iceLabel.Image = "http://www.roblox.com/asset/?id=47522829"
iceLabel.Visible = true

local poisonLabel = Instance.new("ImageLabel")
poisonLabel.Name = "Poison"
poisonLabel.Size = UDim2.new(0.1, 0.0, 0.8, 0.0)
poisonLabel.BackgroundTransparency = 1.0
poisonLabel.Image = "http://www.roblox.com/asset/?id=47525343"
poisonLabel.Visible = true

local fireLabel = Instance.new("ImageLabel")
fireLabel.Name = "Fire"
fireLabel.Size = UDim2.new(0.1, 0.0, 0.8, 0.0)
fireLabel.BackgroundTransparency = 1.0
fireLabel.Image = "http://www.roblox.com/asset/?id=47522853"
fireLabel.Visible = true 

local stunLabel = Instance.new("ImageLabel")
stunLabel.Name = "Stun"
stunLabel.Size = UDim2.new(0.1, 0.0, 0.8, 0.0)
stunLabel.BackgroundTransparency = 1.0
stunLabel.Image = "http://www.roblox.com/asset/?id= 47522868"
stunLabel.Visible = true

-- The table that contains the list of all the status buff images
local labels = {poisonLabel, iceLabel, fireLabel, stunLabel}

--  Contains the list of active Labels to draw them
local activeLabels = {}

-- Copies the necessary labels 
local buffsGuiTable = {
	["Speed"] = function ()
	end,
	["MaxHealth"] = function ()
	end,
	["Poison"] = function ()
		table.insert(activeLabels, labels[1])
	end,
	["Ice"] = function()
		table.insert(activeLabels, labels[2])
	end,
	["Fire"] = function()
		table.insert(activeLabels, labels[3])
	end,
	["Stun"] = function()
		table.insert(activeLabels, labels[4])
	end
}

function statusBuffGui()
	activeLabels = {}
	for a = 1, #labels do
		labels[a].Active = false
		labels[a].Visible = false
	end
	activeBuffs = config:GetChildren()	
	print(#buffsGuiTable)
	print(#activeBuffs)
	if #activeBuffs > 2 then 
		for i = 1, #activeBuffs do 
			print(activeBuffs[i].Name)
			buffsGuiTable[activeBuffs[i].Name]()			
		end
		print(#activeLabels)
		if #activeLabels > 0 then
				count = 0
				parity = 1
				median = 0.45
				if #activeLabels%2 == 0 then median = .5 end
			for j = 1, #activeLabels do
				activeLabels[j].Position = UDim2.new(median + parity*count, 0.0, 0.0, 0.0)				
				if j%2 == 1 then count = count + .1 end
				parity = parity * -1
				activeLabels[j].Parent = tray
				activeLabels.Active = true
			end
		end
	end
end

-- Blinking Labels

function blinkGui()
	while true do
		for n = 1, #activeLabels do
			activeLabels[n].Visible = not activeLabels[n].Visible
		end
	wait(0.5)
	end
end

blink = coroutine.create(blinkGui)
coroutine.resume(blink)

-- Event Listeners
config.ChildAdded:connect(statusBuffGui)
config.ChildRemoved:connect(statusBuffGui)









