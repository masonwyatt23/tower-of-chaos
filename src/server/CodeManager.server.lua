--[[
	CodeManager — Promo code redemption for Tower Obby
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared:WaitForChild("ObbyConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local RedeemCodeRemote = Instance.new("RemoteEvent")
RedeemCodeRemote.Name = "RedeemCode"
RedeemCodeRemote.Parent = Remotes

local CodeResultRemote = Instance.new("RemoteEvent")
CodeResultRemote.Name = "CodeResult"
CodeResultRemote.Parent = Remotes

local lastCodeTime = {}

RedeemCodeRemote.OnServerEvent:Connect(function(player, codeInput)
	if type(codeInput) ~= "string" then return end

	local now = tick()
	if lastCodeTime[player] and (now - lastCodeTime[player]) < 1 then
		CodeResultRemote:FireClient(player, false, "Too fast!")
		return
	end
	lastCodeTime[player] = now

	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data then return end

	local code = string.upper(string.gsub(codeInput, "%s+", ""))
	local reward = ObbyConfig.Codes[code]
	if not reward then
		CodeResultRemote:FireClient(player, false, "Invalid code!")
		return
	end

	if not data.redeemedCodes then data.redeemedCodes = {} end
	if data.redeemedCodes[code] then
		CodeResultRemote:FireClient(player, false, "Already redeemed!")
		return
	end

	data.redeemedCodes[code] = true
	if _G.AddCoins then
		_G.AddCoins(player, reward)
	end

	CodeResultRemote:FireClient(player, true, "Redeemed! +" .. tostring(reward) .. " coins!")
end)

Players.PlayerRemoving:Connect(function(player)
	lastCodeTime[player] = nil
end)

print("[CodeManager] Initialized")
