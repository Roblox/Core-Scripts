-- Library Registration Script
-- This script is used to register RbxLua libraries on game servers, so game scripts have
-- access to all of the libraries (otherwise only local scripts do)

local deepakTestingPlace = 3569749
local sc = game:GetService("ScriptContext")
local tries = 0
 
while not sc and tries < 3 do
	tries = tries + 1
	sc = game:GetService("ScriptContext")
	wait(0.2)
end
 
if sc then
	sc:RegisterLibrary("RbxGui", "45284430")
	sc:RegisterLibrary("RbxGear", "45374389")
	if game.PlaceId == deepakTestingPlace then
		sc:RegisterLibrary("RbxStatus", "52177566")
	end
	sc:RegisterLibrary("RbxUtility", "60595411")
	sc:RegisterLibrary("RbxStamper","129667429")
	sc:LibraryRegistrationComplete()
else
	print("failed to find libraries")
end
