--[[
	CosmeticManager — Trail system for Tower Obby
	Players buy trails with coins, equip them, trails render as particles.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared:WaitForChild("ObbyConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local BuyTrailRemote = Instance.new("RemoteEvent")
BuyTrailRemote.Name = "BuyTrail"
BuyTrailRemote.Parent = Remotes

local EquipTrailRemote = Instance.new("RemoteEvent")
EquipTrailRemote.Name = "EquipTrail"
EquipTrailRemote.Parent = Remotes

local TrailUpdateRemote = Instance.new("RemoteEvent")
TrailUpdateRemote.Name = "TrailUpdate"
TrailUpdateRemote.Parent = Remotes

-- Active trail attachments per player
local activeTrails = {}

local function applyTrail(player, trailId)
	-- Remove existing trail
	if activeTrails[player] then
		activeTrails[player]:Destroy()
		activeTrails[player] = nil
	end

	if trailId == "" then return end

	-- Find trail config
	local trailConfig = nil
	for _, t in ipairs(ObbyConfig.Trails) do
		if t.id == trailId then
			trailConfig = t
			break
		end
	end
	if not trailConfig then return end

	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Create trail using Attachment + Trail instance
	local attachment0 = Instance.new("Attachment")
	attachment0.Name = "TrailStart"
	attachment0.Position = Vector3.new(0, 1, 0)
	attachment0.Parent = hrp

	local attachment1 = Instance.new("Attachment")
	attachment1.Name = "TrailEnd"
	attachment1.Position = Vector3.new(0, -1, 0)
	attachment1.Parent = hrp

	local trail = Instance.new("Trail")
	trail.Name = "PlayerTrail"
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Color = ColorSequence.new(trailConfig.color)
	trail.Lifetime = 0.5
	trail.MinLength = 0.1
	trail.LightEmission = 0.5
	trail.FaceCamera = true
	trail.Parent = hrp

	-- Store reference for cleanup
	local folder = Instance.new("Folder")
	folder.Name = "TrailFolder"
	folder.Parent = character
	attachment0.Parent = folder
	attachment1.Parent = folder
	trail.Parent = folder

	-- Fix: re-parent to HRP
	attachment0.Parent = hrp
	attachment1.Parent = hrp
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Parent = hrp

	activeTrails[player] = folder
end

-- Buy trail
BuyTrailRemote.OnServerEvent:Connect(function(player, trailId)
	if type(trailId) ~= "string" then return end

	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data then return end

	-- Find trail
	local trailConfig = nil
	for _, t in ipairs(ObbyConfig.Trails) do
		if t.id == trailId then
			trailConfig = t
			break
		end
	end
	if not trailConfig then return end

	-- Check VIP
	if trailConfig.vip then
		if not (_G.HasGamePass and _G.HasGamePass(player, "VIPTrail")) then
			return
		end
	end

	-- Check already owned
	if not data.ownedTrails then data.ownedTrails = {} end
	for _, owned in ipairs(data.ownedTrails) do
		if owned == trailId then return end -- already owned
	end

	-- Check coins
	if trailConfig.price > 0 and data.coins < trailConfig.price then return end

	-- Purchase
	if trailConfig.price > 0 then
		data.coins = data.coins - trailConfig.price
		local UpdateCoins = Remotes:FindFirstChild("UpdateCoins")
		if UpdateCoins then UpdateCoins:FireClient(player, data.coins) end
	end

	table.insert(data.ownedTrails, trailId)
	TrailUpdateRemote:FireClient(player, data.ownedTrails, data.equippedTrail)
end)

-- Equip trail
EquipTrailRemote.OnServerEvent:Connect(function(player, trailId)
	if type(trailId) ~= "string" then return end

	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data then return end

	-- Verify ownership (or unequip with "")
	if trailId ~= "" then
		local owned = false
		for _, t in ipairs(data.ownedTrails or {}) do
			if t == trailId then owned = true break end
		end
		if not owned then return end
	end

	data.equippedTrail = trailId
	applyTrail(player, trailId)
	TrailUpdateRemote:FireClient(player, data.ownedTrails, data.equippedTrail)
end)

-- Apply trail on character spawn
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		local data = _G.GetPlayerData and _G.GetPlayerData(player)
		if data and data.equippedTrail and data.equippedTrail ~= "" then
			applyTrail(player, data.equippedTrail)
		end
	end)

	-- Send trail info once data is ready
	task.spawn(function()
		local elapsed = 0
		while not (_G.GetPlayerData and _G.GetPlayerData(player)) and elapsed < 15 do
			task.wait(0.5)
			elapsed = elapsed + 0.5
		end
		local data = _G.GetPlayerData(player)
		if data then
			TrailUpdateRemote:FireClient(player, data.ownedTrails or {}, data.equippedTrail or "")
		end
	end)
end)

-- Cleanup
Players.PlayerRemoving:Connect(function(player)
	if activeTrails[player] then
		activeTrails[player]:Destroy()
		activeTrails[player] = nil
	end
end)

print("[CosmeticManager] Initialized")
