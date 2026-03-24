--[[
	MutatorManager — Round mutator voting and application for Tower of Chaos
	Picks 3 random mutators for players to vote on, applies 2 per round
	(1 voted winner + 1 random), and reverses all effects at round end.
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared:WaitForChild("ObbyConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Create remotes
local function createRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = Remotes
	return remote
end

local MutatorCandidatesRemote = createRemote("MutatorCandidates")
local MutatorVoteRemote = createRemote("MutatorVote")
local MutatorResultRemote = createRemote("MutatorResult")
local ActiveMutatorsRemote = createRemote("ActiveMutators")

-- State
local currentCandidates = {}   -- {mutatorDef, mutatorDef, mutatorDef}
local votes = {}               -- {[mutatorId] = count}
local playerVoted = {}         -- {[player] = true}
local activeMutators = {}      -- {mutatorDef, mutatorDef}
local voteOpen = false
local iceParts = {}            -- track ice parts for cleanup

-- Saved defaults for restoration
local defaultGravity = 196.2
local defaultBrightness = 1.5
local defaultAmbient = Color3.fromRGB(100, 100, 120)
local defaultFogEnd = 100000

-- Helper: pick N unique random mutators from config
local function pickRandomMutators(count)
	local pool = {}
	for _, m in ipairs(ObbyConfig.Mutators) do
		table.insert(pool, m)
	end
	-- Shuffle
	for i = #pool, 2, -1 do
		local j = math.random(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local result = {}
	for i = 1, math.min(count, #pool) do
		table.insert(result, pool[i])
	end
	return result
end

-- Helper: find mutator def by id
local function getMutatorById(id)
	for _, m in ipairs(ObbyConfig.Mutators) do
		if m.id == id then return m end
	end
	return nil
end

-- Helper: check if mutator is active by id
local function isMutatorActive(id)
	for _, m in ipairs(activeMutators) do
		if m.id == id then return true end
	end
	return false
end

-- Apply player-specific mutator effects (speed, scale)
local function applyPlayerEffects(player)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	-- Speed
	if isMutatorActive("double_speed") then
		humanoid.WalkSpeed = 32
	end

	-- Jump power (bouncy)
	if isMutatorActive("bouncy") then
		humanoid.JumpPower = 100
	end

	-- Giant mode (2x scale)
	if isMutatorActive("giant") then
		local bodyDepth = humanoid:FindFirstChild("BodyDepthScale")
		local bodyHeight = humanoid:FindFirstChild("BodyHeightScale")
		local bodyWidth = humanoid:FindFirstChild("BodyWidthScale")
		local headScale = humanoid:FindFirstChild("HeadScale")
		if bodyDepth then bodyDepth.Value = 2 end
		if bodyHeight then bodyHeight.Value = 2 end
		if bodyWidth then bodyWidth.Value = 2 end
		if headScale then headScale.Value = 2 end
	end

	-- Tiny mode (0.5x scale)
	if isMutatorActive("tiny") then
		local bodyDepth = humanoid:FindFirstChild("BodyDepthScale")
		local bodyHeight = humanoid:FindFirstChild("BodyHeightScale")
		local bodyWidth = humanoid:FindFirstChild("BodyWidthScale")
		local headScale = humanoid:FindFirstChild("HeadScale")
		if bodyDepth then bodyDepth.Value = 0.5 end
		if bodyHeight then bodyHeight.Value = 0.5 end
		if bodyWidth then bodyWidth.Value = 0.5 end
		if headScale then headScale.Value = 0.5 end
	end
end

-- Restore player-specific effects
local function removePlayerEffects(player)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	humanoid.WalkSpeed = 16
	humanoid.JumpPower = 50

	-- Restore scale
	local bodyDepth = humanoid:FindFirstChild("BodyDepthScale")
	local bodyHeight = humanoid:FindFirstChild("BodyHeightScale")
	local bodyWidth = humanoid:FindFirstChild("BodyWidthScale")
	local headScale = humanoid:FindFirstChild("HeadScale")
	if bodyDepth then bodyDepth.Value = 1 end
	if bodyHeight then bodyHeight.Value = 1 end
	if bodyWidth then bodyWidth.Value = 1 end
	if headScale then headScale.Value = 1 end
end

-- _G.StartMutatorVote: pick 3 candidates and open voting
function _G.StartMutatorVote()
	-- Pick 3 random unique candidates
	currentCandidates = pickRandomMutators(3)
	votes = {}
	playerVoted = {}
	voteOpen = true

	for _, m in ipairs(currentCandidates) do
		votes[m.id] = 0
	end

	-- Build candidate list for client
	local candidateData = {}
	for _, m in ipairs(currentCandidates) do
		table.insert(candidateData, {id = m.id, name = m.name, description = m.description})
	end

	-- Fire to all clients
	MutatorCandidatesRemote:FireAllClients(candidateData, ObbyConfig.MutatorVoteDuration)

	-- Close voting after duration
	task.delay(ObbyConfig.MutatorVoteDuration, function()
		voteOpen = false
		tallyVotes()
	end)
end

function _G.GetMutatorCandidates()
	return currentCandidates
end

-- Tally votes and pick winners
function tallyVotes()
	-- Find winner (highest votes, random on tie)
	local maxVotes = -1
	local winners = {}

	for _, m in ipairs(currentCandidates) do
		local v = votes[m.id] or 0
		if v > maxVotes then
			maxVotes = v
			winners = {m}
		elseif v == maxVotes then
			table.insert(winners, m)
		end
	end

	-- Random from tied winners
	local winner = winners[math.random(1, #winners)]

	-- Pick second mutator randomly (not the winner)
	local pool = {}
	for _, m in ipairs(ObbyConfig.Mutators) do
		if m.id ~= winner.id then
			table.insert(pool, m)
		end
	end
	local second = pool[math.random(1, #pool)]

	activeMutators = {winner, second}

	-- Build result data for client
	local resultData = {}
	for _, m in ipairs(activeMutators) do
		table.insert(resultData, {id = m.id, name = m.name, description = m.description})
	end

	-- Fire result to all clients (includes all candidate names for wheel animation)
	local allNames = {}
	for _, m in ipairs(ObbyConfig.Mutators) do
		table.insert(allNames, m.name)
	end

	MutatorResultRemote:FireAllClients(resultData, allNames)

	-- Track rounds with mutators for all players
	for _, player in ipairs(Players:GetPlayers()) do
		local data = _G.GetPlayerData and _G.GetPlayerData(player)
		if data then
			data.roundsWithMutators = (data.roundsWithMutators or 0) + 1
		end
	end
end

-- _G.ApplyMutators: apply all active mutator effects
function _G.ApplyMutators()
	if #activeMutators == 0 then return end

	for _, m in ipairs(activeMutators) do
		if m.id == "low_gravity" then
			workspace.Gravity = 60
		elseif m.id == "bouncy" then
			workspace.Gravity = 120
		elseif m.id == "fog" then
			Lighting.FogEnd = 50
		elseif m.id == "darkness" then
			Lighting.Brightness = 0.1
			Lighting.Ambient = Color3.new(0.05, 0.05, 0.08)
		elseif m.id == "ice" then
			-- Add invisible slippery parts on each checkpoint
			local tower = workspace:FindFirstChild("Tower")
			if tower then
				for _, child in ipairs(tower:GetChildren()) do
					if child.Name:match("^Checkpoint_") then
						local icePart = Instance.new("Part")
						icePart.Name = "IceOverlay"
						icePart.Size = Vector3.new(child.Size.X, 0.1, child.Size.Z)
						icePart.Position = child.Position + Vector3.new(0, 0.55, 0)
						icePart.Anchored = true
						icePart.Transparency = 1
						icePart.CanCollide = true
						icePart.CustomPhysicalProperties = PhysicalProperties.new(
							0.5, -- density
							0,   -- friction
							0,   -- elasticity
							0,   -- frictionWeight
							0    -- elasticityWeight
						)
						icePart.Parent = tower
						table.insert(iceParts, icePart)
					end
				end
			end
		end
	end

	-- Apply player-specific effects to all current players
	for _, player in ipairs(Players:GetPlayers()) do
		applyPlayerEffects(player)
	end

	-- Fire active mutators to all clients
	local activeData = {}
	for _, m in ipairs(activeMutators) do
		table.insert(activeData, {id = m.id, name = m.name})
	end
	ActiveMutatorsRemote:FireAllClients(activeData)
end

-- _G.RemoveMutators: reverse all mutator effects
function _G.RemoveMutators()
	-- Restore global effects
	workspace.Gravity = defaultGravity
	Lighting.Brightness = defaultBrightness
	Lighting.Ambient = defaultAmbient
	Lighting.FogEnd = defaultFogEnd

	-- Remove ice parts
	for _, part in ipairs(iceParts) do
		if part and part.Parent then
			part:Destroy()
		end
	end
	iceParts = {}

	-- Restore player-specific effects
	for _, player in ipairs(Players:GetPlayers()) do
		removePlayerEffects(player)
	end

	activeMutators = {}

	-- Notify clients mutators cleared
	ActiveMutatorsRemote:FireAllClients({})
end

-- Vote handler
MutatorVoteRemote.OnServerEvent:Connect(function(player, mutatorId)
	if not voteOpen then return end
	if playerVoted[player] then return end

	-- Validate mutator is a candidate
	local isCandidate = false
	for _, m in ipairs(currentCandidates) do
		if m.id == mutatorId then
			isCandidate = true
			break
		end
	end
	if not isCandidate then return end

	-- Record vote
	playerVoted[player] = true
	votes[mutatorId] = (votes[mutatorId] or 0) + 1

	-- Track mutator votes for the player
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if data then
		data.mutatorVotes = (data.mutatorVotes or 0) + 1
	end

	-- Broadcast updated vote counts to all clients
	local voteCounts = {}
	for _, m in ipairs(currentCandidates) do
		voteCounts[m.id] = votes[m.id] or 0
	end
	MutatorCandidatesRemote:FireAllClients(nil, nil, voteCounts)
end)

-- Reapply player effects on respawn/join during active round
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		if #activeMutators > 0 then
			applyPlayerEffects(player)
		end
	end)
end)

-- Also handle existing players' respawns
for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		if #activeMutators > 0 then
			applyPlayerEffects(player)
		end
	end)
end

-- Send active mutators to late-joining players
Players.PlayerAdded:Connect(function(player)
	task.wait(2)
	if #activeMutators > 0 then
		local activeData = {}
		for _, m in ipairs(activeMutators) do
			table.insert(activeData, {id = m.id, name = m.name})
		end
		ActiveMutatorsRemote:FireClient(player, activeData)
	end
end)

-- Cleanup on player leaving
Players.PlayerRemoving:Connect(function(player)
	playerVoted[player] = nil
end)

print("[MutatorManager] Initialized")
