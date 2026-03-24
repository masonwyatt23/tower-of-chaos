--[[
	SoundManager — Audio feedback for Tower Obby
]]

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local StageReached = Remotes:WaitForChild("StageReached", 15)
local PlayerWin = Remotes:WaitForChild("PlayerWin", 15)
local RoundStart = Remotes:WaitForChild("RoundStart", 15)

local player = Players.LocalPlayer
local Sounds = {}

local function createSound(name, assetId, volume)
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = "rbxassetid://" .. assetId
	sound.Volume = volume or 0.5
	sound.Parent = SoundService
	Sounds[name] = sound
end

-- Varied sound effects
createSound("Checkpoint", 9125402735, 0.4)     -- Cha-ching checkpoint
createSound("Win",        9125836726, 0.7)     -- Victory fanfare
createSound("RoundStart", 9125786610, 0.5)     -- Whoosh start
createSound("Death",      6895079853, 0.3)     -- Thud
createSound("Vote",       6895079853, 0.2)     -- Click
createSound("MutatorSpin",9125786610, 0.4)     -- Spinning wheel

-- Background music (energetic action loop)
local bgMusic = Instance.new("Sound")
bgMusic.Name = "BackgroundMusic"
bgMusic.SoundId = "rbxassetid://1837849285"
bgMusic.Volume = 0.1
bgMusic.Looped = true
bgMusic.Parent = SoundService

task.spawn(function()
	task.wait(3)
	bgMusic:Play()
end)

_G.SetMusicVolume = function(vol)
	bgMusic.Volume = math.clamp(vol, 0, 1)
end

local function playSound(name)
	local sound = Sounds[name]
	if sound then
		local clone = sound:Clone()
		clone.Parent = SoundService
		clone:Play()
		clone.Ended:Connect(function() clone:Destroy() end)
	end
end

_G.PlaySound = playSound

StageReached.OnClientEvent:Connect(function()
	playSound("Checkpoint")
end)

PlayerWin.OnClientEvent:Connect(function(playerName)
	if playerName == player.Name then
		playSound("Win")
	end
end)

RoundStart.OnClientEvent:Connect(function()
	playSound("RoundStart")
end)

-- Death detection
player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		playSound("Death")
	end)
end)

print("[SoundManager] Initialized")
