--[[
	DataManager — Player data persistence for Tower Obby
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utils = require(Shared:WaitForChild("Utils"))

local PlayerStore = DataStoreService:GetDataStore("TowerObby_v1")

local MAX_RETRIES = 3
local AUTOSAVE_INTERVAL = 60

local DEFAULT_DATA = {
	coins = 0,
	totalCoins = 0,
	wins = 0,
	gamesPlayed = 0,
	bestTime = 0,
	ownedTrails = {},
	equippedTrail = "",
	redeemedCodes = {},
}

local function deepCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

local function retryAsync(func, ...)
	local args = {...}
	for attempt = 1, MAX_RETRIES do
		local success, result = pcall(function()
			return func(unpack(args))
		end)
		if success then return true, result end
		if attempt < MAX_RETRIES then task.wait(1) end
	end
	return false, nil
end

local function loadPlayerData(player)
	local key = "Player_" .. player.UserId
	local success, data = retryAsync(function()
		return PlayerStore:GetAsync(key)
	end)

	if success and data then
		for field, default in pairs(DEFAULT_DATA) do
			if data[field] == nil then
				data[field] = default
			end
		end
		return data
	end
	return deepCopy(DEFAULT_DATA)
end

local function savePlayerData(player)
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data then return end
	local key = "Player_" .. player.UserId
	retryAsync(function()
		return PlayerStore:UpdateAsync(key, function() return data end)
	end)
end

Players.PlayerAdded:Connect(function(player)
	local data = loadPlayerData(player)
	while not _G.InitializePlayerData do task.wait(0.1) end
	_G.InitializePlayerData(player, data)
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(function() savePlayerData(player) end)
		end
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		local data = loadPlayerData(player)
		while not _G.InitializePlayerData do task.wait(0.1) end
		_G.InitializePlayerData(player, data)
	end)
end

print("[DataManager] Initialized")
