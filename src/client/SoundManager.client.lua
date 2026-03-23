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

createSound("Checkpoint", 138677306, 0.4)
createSound("Win",        138677306, 0.7)
createSound("RoundStart", 138677306, 0.5)
createSound("Death",      138677306, 0.3)

local function playSound(name)
	local sound = Sounds[name]
	if sound then
		local clone = sound:Clone()
		clone.Parent = SoundService
		clone:Play()
		clone.Ended:Connect(function() clone:Destroy() end)
	end
end

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
