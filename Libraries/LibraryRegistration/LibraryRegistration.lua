-- Library Registration Script
-- This script is used to register RbxLua libraries on game servers, so game scripts have
-- access to all of the libraries (otherwise only local scripts do)
local sc = game:GetService("ScriptContext")
local tries = 0
 
while not sc and tries < 3 do
	tries = tries + 1
	sc = game:GetService("ScriptContext")
	wait(0.2)
end
 
if sc then
	sc:RegisterLibrary("Libraries/RbxGui", "45284430")
	sc:RegisterLibrary("Libraries/RbxUtility", "60595411")
	sc:RegisterLibrary("Libraries/RbxStamper", "73157242")
	sc:LibraryRegistrationComplete()
else
	print("failed to find script context, libraries did not load")
end
