-- Global Status Buff Script -- 
-- This will be a part of a humanoid
-- Everytime a humanoid gets hit, this script will be invoked
-- If the damage is from a previous older gear we just query the takeDamage C++ function
-- If its from some of the newer ones with status buffs, we look them up in our table and use that to determine what we need to do 


-- [[ The status debuffs currently are

		-- OVER TIME EFFECTS
					
						-- Poison
						-- Fire
						-- Ice, also slows
						-- Heal		
						-- Plague
					

		-- For fire, ice etc we could apply the texture to nearby parts to showcase as if its spreading

		-- INSTANT EFFECTS
					
					-- Stun, 10-20% chance to stun
					-- Confusion
					-- Invisibilty, there will be fading in and fading out
					-- Silence, can't use gears
					-- Blind/Miss
				

		-- TODO, AOE EFFECTS (these will propagate from the wielder) ]]

-- Return this table for accessing the library
local t = {}

-- Wait for a particular child to show up
function waitForChild(instance, name)
	while not instance:FindFirstChild(name) do
		instance.ChildAdded:wait()
	end
end

local damageGuiWidth =  5.0
local damageGuiHeight = 5.0

local myPlayer = script.Parent
local myName = script.Parent.Name
local myHumanoid = myPlayer:FindFirstChild("Humanoid")


local charConfig = nil

-- gear effects
local poison = 0
local physical = 0
local heal = 0
local regen = 0
local piercing = 0
local poisonTime = 10   -- duration of a poisoning  (default 10)
local corruption = 0   -- amount poison worsens

local iceDOT = 0
local iceDuration = 0
local iceSlow = 0

local stunDuration = 0

-- armor/character effects [will be reloaded upon characters config folder changing]

local existingIceDuration = 0

local fireDOT = 0
local fireDuration = 0
local existingFireDuration = 0

local armor = 0
local poisonArmor = 0
local existingPoison = 0
local existingCorruption = 0

local existingStunDuration = 0


-- Create Lookup Tables
local charPropType = {
	["Armor"] = function(x)
		print("ARMOR ", x)
		armor = x
	end,
	["Poison Resistance"] = function(x)
		print("POISON RESISTANCE ", x)
		poisonArmor = x
	end,
	["Poison"] = function(x)
		existingPoison = x.X
		existingCorruption = x.Z
	end,
	["Ice"] = function(x)
		existingIceDuration = x.Y
	end,
	["Fire"] = function(x)
		existingFireDuration = x.Y
	end,
	["Stun"] = function(x)
		-- Tentative value, usually we should allow to override stun duration and have a long cool down or a chance effect
		existingStunDuration = x
	end
}


-- Damage Type Table
local damageType = {
	["Damage"] = function(x) 
		--print("DAMAGE ", x) 
		physical = x 
	end,
	["Poison"] = function(x)
		print("POISONED", x) 
		poison = x
		--poisonTime = x.Y
		--corruption = x.Z
	end,
	["Heal"] = function(x)
		print("HEALED", x) 
		heal = x 
	end,
	["Regen"] = function(x)
		print("REGEN", x)
		regen = x 
	end,
	["Piercing"] = function(x) 
		print("PIERCING", x) 
		piercing = x 
	end,
	["Poison Time"] = function(x)
		print("POISON TIME", x)
		poisonTime = x
	end,
	["Corruption"] = function(x)
		print("CORRUPTION", x)
		corruption = x
	end,
	-- Code Change Feb 25th
	["Ice"] = function(x)
		--print("Ice")	
		iceDOT = x.X
		iceDuration = x.Y
		iceSlow = x.Z
	end,
	["Fire"] = function(x)
		fireDOT = x.X
		fireDuration = x.Y
	end,
	["Stun"] = function(x)
		stunDuration = x
	end
	--
}

function updateCharProperties()
	-- reset all char properties first to 0
	armor = 0
	poisonArmor = 0
	existingPoison = 0
	existingCorruption = 0
	--iceDOT = 0
	--iceDuration = 0
	--iceSlow = 0

	--print("Updating Char Properties")
	charProperties = charConfig:GetChildren()
	--print(iceDOT," ", iceDuration," ", iceSlow)
	for i = 1, #charProperties do
		if charPropType[charProperties[i].Name] then  -- can get rid of this check to improve speed at cost of safety
			charPropType[charProperties[i].Name](charProperties[i].Value)			
		end
	end
end


function applyRandomizationTo(property)
	if (math.random() > property.Y) then
		return property.X
	else
		return property.Z
	end
end

function eval(property)
	if type(property) == "number" then return property
	else return applyRandomizationTo(property) end
end


t.ComputeStatusEffects = function (gearConfig, charConfig, vChar)
	-- all gear effects need to be set to 0 initially
	poison = 0  
	physical = 0
	heal = 0	
	--iceDOT = 0
	iceDuration = 0
	--iceSlow = 0
	regen = 0
	piercing = 0
	poisonTime = 10 -- default is to poison someone for 10 seconds

	gearProperties = gearConfig:GetChildren()
	for i = 1, #gearProperties do
		if not (gearProperties[i].Name == "Damage") then		
			damageType[gearProperties[i].Name](gearProperties[i].Value)
			print(gearProperties[i].Name)
		else
			damageType[gearProperties[i].Name](eval(gearProperties[i].Value))
		end
	end
	
	-- apply randomization to armors that need it
	--  (doing this here [with eval] allows us to change armor variables only when necessary)	
	--poi = math.max(existingPoison, math.max(poison - eval(poisonArmor), 0))
	dmg = math.max(physical - math.max(eval(armor) - piercing, 0), 0) - heal	
	poi = math.max(poison - eval(poisonArmor), 0)
	cor = math.max(existingCorruption, corruption)

	-- Feb 25th Change
	iceDamage = iceDOT
	--

 -- Populate the tags in the Players Config!
myHumanoid:takeDamage(dmg)
print(myHumanoid.Health)
if charConfig ~= nil then
	--if poi > 0 then -- if poison damage taken, make sure we give 'em a poisoned status
	if poi > 0 and poi >= existingPoison then -- must at least tie previous poison strength to change the poison tag		
		poisonTag = charConfig:FindFirstChild("Poison")
		if poisonTag == nil then
			poisonTag = Instance.new("Vector3Value")
			poisonTag.Name = "Poison"
			poisonTag.Parent = charConfig
		end
		poisonTag.Value = Vector3.new(poi, poisonTime, cor)		
	end

	-- Feb 25th Change
		if iceDuration > 0 and existingIceDuration <= 0 then
			iceTag = charConfig:FindFirstChild("Ice")
			if iceTag == nil then 
				iceTag = Instance.new("Vector3Value")
				iceTag.Name = "Ice"
				iceTag.Parent = charConfig
			end
			iceTag.Value = Vector3.new(iceDOT, iceDuration, iceSlow)					
		end
		print(fireDuration, existingFireDuration)
		if fireDuration > 0 and existingFireDuration <= 0 then 
			fireTag = charConfig:FindFirstChild("Fire")
			if fireTag == nil then 
				fireTag = Instance.new("Vector3Value")
				fireTag.Name = "Fire"
				fireTag.Parent = charConfig
			end
			fireTag.Value = Vector3.new(fireDOT, fireDuration, 0.0)
		end

		if stunDuration > 0 and existingStunDuration <= 0 then 
			stunTag = charConfig:FindFirstChild("Stun")
			if stunTag == nil then 
				stunTag = Instance.new("NumberValue")
				stunTag.Name = "Stun"
				stunTag.Parent = charConfig
			end
			stunTag.Value = stunDuration
		end
	end
	vPlayer = game.Players:GetPlayerFromCharacter(script.Parent)
	if vPlayer then	
		dmgGui = vPlayer.PlayerGui:FindFirstChild("DamageGui")
		if dmgGui ~= nil then
			dmgChildren = dmgGui:GetChildren()
			for i = 1, #dmgChildren do
				if dmgChildren[i].TextTransparency < .35 then
					dmgChildren[i].Text = tostring(tonumber(dmgChildren[i].Text) + dmg)
					return
				end
			end
		end
		local guiCoRoutine = coroutine.create(statusGui)
		coroutine.resume(guiCoRoutine, vPlayer, dmg, poi)
		print("CREATING GUI")
	end
end

-- GUI STUFF -- 

function statusGui(vPlayer, guiDmg, guiPoi)			
	local damageGui = vPlayer.PlayerGui:FindFirstChild("DamageGui")
	if damageGui == nil then
		damageGui = Instance.new("BillboardGui")		
		damageGui.Name = "DamageGui"
		print("BB GUI CREATED")
		damageGui.Parent = vPlayer.PlayerGui
		damageGui.Adornee = script.Parent:FindFirstChild("Head")
		damageGui.Active = true
		damageGui.size = UDim2.new(damageGuiWidth, 0.0, damageGuiHeight, 0.0)	
		damageGui.StudsOffset = Vector3.new(0.0, 2.0, 0.0)
	end
	local textLabel = Instance.new("TextLabel")
	print("TEXT LABEL CREATED")
	textLabel.Text = tostring(guiDmg)
	textLabel.size = UDim2.new(1.0, 0.0, 1.0, 0.0)
	textLabel.Active = true
	textLabel.FontSize = 6
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(1, 0, 0)
	textLabel.Parent = damageGui

	for t = 1, 10 do
		wait(.1)
		textLabel.TextTransparency = t/10
		textLabel.Position = UDim2.new(0, 0, 0, -t*5)
		textLabel.FontSize = 6-t*.6
	end
	textLabel:remove()		
end

return t



-- Hook-up stuff to listeners here and do any other initialization
--[[while true do
	waitForChild(script.Parent, "PlayerStats")
	charConfig = script.Parent:FindFirstChild("PlayerStats")

	if charConfig then
		updateCharProperties()
		charConfig.Changed:connect(updateCharProperties)
		charConfig.ChildAdded:connect(function (newChild) newChild.Changed:connect(updateCharProperties) updateCharProperties() end)
		--charConfig.Desc
		break
	end
end]]

