local Utils = {}

function Utils.formatNumber(amount)
	if amount >= 1e6 then
		return string.format("%.1fM", amount / 1e6)
	elseif amount >= 1e3 then
		return string.format("%.1fK", amount / 1e3)
	else
		return tostring(math.floor(amount))
	end
end

function Utils.formatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%d:%02d", mins, secs)
end

function Utils.deepCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = Utils.deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

return Utils
