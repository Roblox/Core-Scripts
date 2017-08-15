--[[
		Filename: ReportPlayer.lua
		Written by: boynedmaster/Kampfkarren
		Version 1.0
		Description: Adds ReportPlayer SetCore function.
        Notes:       This basically just acts as a wrapper for Players:ReportAbuse, but in a context level normal LocalScripts can access.
                     It is a separate file rather than inside a similar script, such as ReportAbuseMenu.lua, to ensure the SetCore functionality exists on startup.
                     Why you would want to use it on startup I have no clue, but TheGamer101 said on the developer forum
                     "Currently we try to make all SetCore and GetCore methods work without requiring the developer to wait a frame before calling it."
--]]

local PlayersService = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

StarterGui:RegisterSetCore("ReportPlayer", function(arguments)
    if typeof(arguments) ~= "table" then
        warn("ReportPlayer expects a table of arguments.")
        return
    end

    if #arguments ~= 2 and #arguments ~= 3 then
        warn("ReportPlayer expects 2-3 arguments.")
        return
    end
    
    local player = arguments[1]
    local reason = arguments[2]
    local optionalMessage = arguments[3] or ""

    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        warn("Invalid argument 1 for ReportPlayer. Expected a Player.")
        return
    end

    if typeof(reason) ~= "string" then
        warn("Invalid argument 2 for ReportPlayer. Expected a string.")
        return
    end
    
    if typeof(optionalMessage) ~= "string" then
        warn("Invalid argument 3 for ReportPlayer. Expected a string.")
        return
    end

    if player == PlayersService.LocalPlayer then
        warn("ReportPlayer tried to report the LocalPlayer.")
        return
    end

    PlayersService:ReportAbuse(player, reason, optionalMessage)
end)
