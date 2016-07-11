--A new unified Utility library for all ROBLOX CoreScripts
--When adding methods to this module, please document the API
--in the index below.

--Method Index:
-- Utility.Create(instanceType) { property=value, ... } : Instance
-- Utility.RayPlaneIntersection(ray, planeNormal, pointOnPlane) : Vector3
-- Utility.IsTouchDevice() : bool
-- Utility.Clamp(low, high, input) : number
-- Utility.FindPlayerHumanoid(player) : Humanoid
-- Utility.DisconnectEvent(conn) : nil

local Utility = {}
local UserInputService = game:GetService("UserInputService")

function Utility.Create(instanceType)
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

-- RayPlaneIntersection (shortened)
-- http://www.siggraph.org/education/materials/HyperGraph/raytrace/rayplane_intersection.htm
function Utility.RayPlaneIntersection(ray, planeNormal, pointOnPlane)
	planeNormal = planeNormal.unit
	ray = ray.Unit

	local Vd = planeNormal:Dot(ray.Direction)
	if Vd == 0 then -- parallel, no intersection
		return nil
	end

	local V0 = planeNormal:Dot(pointOnPlane - ray.Origin)
	local t = V0 / Vd
	if t < 0 then --plane is behind ray origin, and thus there is no intersection
		return nil
	end
	
	return ray.Origin + ray.Direction * t
end

-- Check if we are running on a touch device
function Utility.IsTouchDevice()
	return UserInputService.TouchEnabled
end

function Utility.Clamp(low, high, input)
	return math.max(low, math.min(high, input))
end

local humanoidCache = {}
function Utility.FindPlayerHumanoid(player)
	local character = player and player.Character
	if character then
		local resultHumanoid = humanoidCache[player]
		if resultHumanoid and resultHumanoid.Parent == character then
			return resultHumanoid
		else
			humanoidCache[player] = nil -- Bust Old Cache
			for _, child in pairs(character:GetChildren()) do
				if child:IsA('Humanoid') then
					humanoidCache[player] = child
					return child
				end
			end
		end
	end
end

function Utility.DisconnectEvent(conn)
	if conn then
		conn:disconnect()
	end
end

return Utility