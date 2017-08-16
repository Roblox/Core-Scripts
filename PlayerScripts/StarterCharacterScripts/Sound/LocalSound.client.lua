--[[
	Filename: LocalSound.client.lua
	Author: @spotco, adapted by boynedmaster/Kampfkarren
	Description: Locally plays all sounds for the player's humanoid. 
]]

local PlayersService = game:GetService("Players")
local SoundUtil = require(script.Parent:WaitForChild("SoundUtil"))

--All sounds are referenced by this ID
local SFX = {
	Died = 0,
	Running = 1,
	Swimming = 2,
	Climbing = 3,
	Jumping = 4,
	GettingUp = 5,
	FreeFalling = 6,
	FallingDown = 7,
	Landing = 8,
	Splash = 9
}

--Verify and set that "sound" is in "playingLoopedSounds".
local function setSoundInPlayingLoopedSounds(playingLoopedSounds, sound)
	for i=1,#playingLoopedSounds do
		if playingLoopedSounds[i] == sound then
			return
		end
	end

	table.insert(playingLoopedSounds, sound)
end

--Stop all active looped sounds except parameter "expect". If "expect is not passed, all looped sounds will be stopped.
local function stopPlayingLoopedSoundsExcept(playingLoopedSounds, except)
	for i=#playingLoopedSounds,1,-1 do
		if playingLoopedSounds[i] ~= except then
			SoundUtil.Pause(playingLoopedSounds[i])
			table.remove(playingLoopedSounds, i)
		end
	end
end

local function connectFigure(Figure)
	local Sounds = {}

	local Humanoid
	local Head = Figure:WaitForChild("Head")

	while not Humanoid do
		Humanoid = Figure:FindFirstChildWhichIsA("Humanoid")

		if Humanoid then break end

		Figure.ChildAdded:Wait()
	end

	if SoundUtil.UseNewSystem() then
		--Using the new sound system, create all the sounds on the client
		 SoundUtil.CreateSounds(Head)
	end

	Sounds[SFX.Died] = 			Head:WaitForChild("Died")
	Sounds[SFX.Running] = 		Head:WaitForChild("Running")
	Sounds[SFX.Swimming] = 		Head:WaitForChild("Swimming")
	Sounds[SFX.Climbing] = 		Head:WaitForChild("Climbing")
	Sounds[SFX.Jumping] = 		Head:WaitForChild("Jumping")
	Sounds[SFX.GettingUp] = 	Head:WaitForChild("GettingUp")
	Sounds[SFX.FreeFalling] = 	Head:WaitForChild("FreeFalling")
	Sounds[SFX.Landing] = 		Head:WaitForChild("Landing")
	Sounds[SFX.Splash] = 		Head:WaitForChild("Splash")

	--List of all active Looped sounds
	local playingLoopedSounds = {}

	--Last seen Enum.HumanoidStateType
	local activeState = nil
	
	local stateUpdated

	local stateUpdateHandler = {
		[Enum.HumanoidStateType.Dead] = function()
			stopPlayingLoopedSoundsExcept(playingLoopedSounds)

			local sound = Sounds[SFX.Died]
			SoundUtil.Play(sound)
		end,
		
		[Enum.HumanoidStateType.RunningNoPhysics] = function()
			stateUpdated(Enum.HumanoidStateType.Running)
		end,
		
		[Enum.HumanoidStateType.Running] = function()	
			local sound = Sounds[SFX.Running]

			stopPlayingLoopedSoundsExcept(playingLoopedSounds, sound)
			
			if SoundUtil.HorizontalSpeed(Head) > 0.5 then
				SoundUtil.Resume(sound)
				setSoundInPlayingLoopedSounds(playingLoopedSounds, sound)
			else
				stopPlayingLoopedSoundsExcept(playingLoopedSounds)
			end
		end,
		
		[Enum.HumanoidStateType.Swimming] = function()
			if activeState ~= Enum.HumanoidStateType.Swimming and SoundUtil.VerticalSpeed(Head) > 0.1 then
				local splashSound = Sounds[SFX.Splash]

				splashSound.Volume = SoundUtil.Clamp(
					SoundUtil.YForLineGivenXAndTwoPts(
						SoundUtil.VerticalSpeed(Head), 
						100, 0.28, 
						350, 1),
					0,1)
				SoundUtil.Play(splashSound)
			end
			
			do
				local sound = Sounds[SFX.Swimming]

				stopPlayingLoopedSoundsExcept(playingLoopedSounds, sound)
				SoundUtil.Resume(sound)
				setSoundInPlayingLoopedSounds(playingLoopedSounds, sound)
			end
		end,
		
		[Enum.HumanoidStateType.Climbing] = function()
			local sound = Sounds[SFX.Climbing]

			if SoundUtil.VerticalSpeed(Head) > 0.1 then
				SoundUtil.Resume(sound)
				stopPlayingLoopedSoundsExcept(playingLoopedSounds, sound)
			else
				stopPlayingLoopedSoundsExcept(playingLoopedSounds)
			end

			setSoundInPlayingLoopedSounds(playingLoopedSounds, sound)
		end,
		
		[Enum.HumanoidStateType.Jumping] = function()
			if activeState == Enum.HumanoidStateType.Jumping then
				return
			end

			stopPlayingLoopedSoundsExcept(playingLoopedSounds)

			local sound = Sounds[SFX.Jumping]
			SoundUtil.Play(sound)
		end,
		
		[Enum.HumanoidStateType.GettingUp] = function()
			stopPlayingLoopedSoundsExcept(playingLoopedSounds)

			local sound = Sounds[SFX.GettingUp]
			SoundUtil.Play(sound)
		end,
		
		[Enum.HumanoidStateType.Freefall] = function()
			if activeState == Enum.HumanoidStateType.Freefall then
				return
			end

			local sound = Sounds[SFX.FreeFalling]
			sound.Volume = 0
			stopPlayingLoopedSoundsExcept(playingLoopedSounds)
		end,
		
		[Enum.HumanoidStateType.FallingDown] = function()
			stopPlayingLoopedSoundsExcept(playingLoopedSounds)
		end,
		
		[Enum.HumanoidStateType.Landed] = function()
			stopPlayingLoopedSoundsExcept(playingLoopedSounds)

			if SoundUtil.VerticalSpeed(Head) > 75 then
				local landingSound = Sounds[SFX.Landing]
				landingSound.Volume = SoundUtil.Clamp(
					SoundUtil.YForLineGivenXAndTwoPts(
						SoundUtil.VerticalSpeed(Head), 
						50, 0, 
						100, 1),
					0,1)
				SoundUtil.Play(landingSound)			
			end
		end,
		
		[Enum.HumanoidStateType.Seated] = function()
			stopPlayingLoopedSoundsExcept(playingLoopedSounds)
		end
	}

	--Handle state event fired or OnChange fired
	stateUpdated = function(state)
		if stateUpdateHandler[state] ~= nil then
			stateUpdateHandler[state]()
		end
		
		activeState = state
	end

	Humanoid.Died:connect(function() stateUpdated(Enum.HumanoidStateType.Dead) end)
	Humanoid.Running:connect(function() stateUpdated(Enum.HumanoidStateType.Running) end)
	Humanoid.Swimming:connect(function() stateUpdated(Enum.HumanoidStateType.Swimming) end)
	Humanoid.Climbing:connect(function() stateUpdated(Enum.HumanoidStateType.Climbing) end)
	Humanoid.Jumping:connect(function() stateUpdated(Enum.HumanoidStateType.Jumping) end)
	Humanoid.GettingUp:connect(function() stateUpdated(Enum.HumanoidStateType.GettingUp) end)
	Humanoid.FreeFalling:connect(function() stateUpdated(Enum.HumanoidStateType.Freefall) end)
	Humanoid.FallingDown:connect(function() stateUpdated(Enum.HumanoidStateType.FallingDown) end)

	-- required for proper handling of Landed event
	Humanoid.StateChanged:connect(function(old, new)
		stateUpdated(new)
	end)

	local function onUpdate(stepDeltaSeconds, tickSpeedSeconds)
		local stepScale = stepDeltaSeconds / tickSpeedSeconds

		do
			local sound = Sounds[SFX.FreeFalling]
			
			if activeState == Enum.HumanoidStateType.Freefall then
				if Head.Velocity.Y < 0 and SoundUtil.VerticalSpeed(Head) > 75 then
					SoundUtil.Resume(sound)

					--Volume takes 1.1 seconds to go from volume 0 to 1
					local ANIMATION_LENGTH_SECONDS = 1.1

					local normalizedIncrement = tickSpeedSeconds / ANIMATION_LENGTH_SECONDS
					sound.Volume = SoundUtil.Clamp(sound.Volume + normalizedIncrement * stepScale, 0, 1)
				else
					sound.Volume = 0
				end
			else
				SoundUtil.Pause(sound)
			end
		end

		do
			local sound = Sounds[SFX.Running]

			if activeState == Enum.HumanoidStateType.Running then
				if SoundUtil.HorizontalSpeed(Head) < 0.5 then
					SoundUtil.Pause(sound)
				end
			end
		end
	end

	local lastTick = tick()
	local TICK_SPEED_SECONDS = 0.25
	
	spawn(function()
		while true do
			onUpdate(tick() - lastTick, TICK_SPEED_SECONDS)
			lastTick = tick()
			wait(TICK_SPEED_SECONDS)
		end
	end)
end

if SoundUtil.UseNewSystem() then
	local function playerAdded(player)
		player.CharacterAdded:connect(connectFigure)

		if player.Character then
			connectFigure(player.Character)
		end
	end

	PlayersService.PlayerAdded:connect(playerAdded)

	for _,player in pairs(PlayersService:GetPlayers()) do
		playerAdded(player)
	end
else
	connectFigure(script.Parent.Parent) --This is the same functionality as the old system.
end