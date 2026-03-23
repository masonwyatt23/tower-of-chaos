--[[
	EventManager — Scheduled admin events system
	Drives player spikes at predictable times (boosts algorithm ranking).
	Gives away free items that normally cost Robux → creates FOMO + habit.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared:WaitForChild("ObbyConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local EventInfoRemote = Instance.new("RemoteEvent")
EventInfoRemote.Name = "EventInfo"
EventInfoRemote.Parent = Remotes

-- Active event state
local activeEvent = nil
local activeEventEndTime = 0

-- Check if a specific event type is active
function _G.EventActive(rewardType)
	if activeEvent and os.time() < activeEventEndTime then
		return activeEvent.reward == rewardType
	end
	return false
end

-- Get current UTC day of week (1=Sunday, 7=Saturday) and hour
local function getUTCTimeInfo()
	local utcTime = os.time()
	local utcDate = os.date("!*t", utcTime)
	return utcDate.wday, utcDate.hour, utcTime
end

-- Find the next upcoming event
local function getNextEvent()
	local wday, hour, now = getUTCTimeInfo()

	local bestEvent = nil
	local bestTimeUntil = math.huge

	for _, event in ipairs(ObbyConfig.Events) do
		-- Calculate time until this event
		local daysUntil = (event.dayOfWeek - wday) % 7
		if daysUntil == 0 and hour >= event.hour then
			-- Check if event is currently active
			local eventStartToday = now - (hour - event.hour) * 3600 - (os.date("!*t", now).min * 60) - os.date("!*t", now).sec
			if now < eventStartToday + event.duration then
				-- Event is active RIGHT NOW
				return event, 0, eventStartToday + event.duration - now
			end
			daysUntil = 7 -- next week
		end

		local hoursUntil = daysUntil * 24 + (event.hour - hour)
		if hoursUntil < 0 then hoursUntil = hoursUntil + 168 end -- 7 days in hours
		local secondsUntil = hoursUntil * 3600

		if secondsUntil < bestTimeUntil then
			bestTimeUntil = secondsUntil
			bestEvent = event
		end
	end

	return bestEvent, bestTimeUntil, 0
end

-- Send event info to all clients
local function broadcastEventInfo()
	local event, timeUntil, timeRemaining = getNextEvent()

	if timeUntil == 0 and event then
		-- Event is active
		activeEvent = event
		activeEventEndTime = os.time() + timeRemaining

		EventInfoRemote:FireAllClients({
			active = true,
			name = event.name,
			reward = event.reward,
			timeRemaining = timeRemaining,
		})
	else
		activeEvent = nil

		EventInfoRemote:FireAllClients({
			active = false,
			nextEventName = event and event.name or "None",
			timeUntilNext = timeUntil,
		})
	end
end

-- Send to individual player on join
local function sendEventInfo(player)
	local event, timeUntil, timeRemaining = getNextEvent()

	if timeUntil == 0 and event then
		EventInfoRemote:FireClient(player, {
			active = true,
			name = event.name,
			reward = event.reward,
			timeRemaining = timeRemaining,
		})
	else
		EventInfoRemote:FireClient(player, {
			active = false,
			nextEventName = event and event.name or "None",
			timeUntilNext = timeUntil,
		})
	end
end

-- Check events every 30 seconds
task.spawn(function()
	while true do
		broadcastEventInfo()
		task.wait(30)
	end
end)

-- Send event info to new players
Players.PlayerAdded:Connect(function(player)
	task.wait(3)
	sendEventInfo(player)
end)

-- Handle existing players
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		task.wait(3)
		sendEventInfo(player)
	end)
end

print("[EventManager] Initialized — checking events every 30s")
