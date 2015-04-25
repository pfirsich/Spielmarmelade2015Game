-- filters a list
-- func takes an element from list as an argument and returns a boolean, which determines if it should be kept
function filter(list, func)
	local ret = {}
	for i = 1, #list do
		if func(list[i]) then ret[#ret+1] = list[i] end
	end
	return ret
end

function setResolution(w, h, flags) -- this is encapsulated, so if canvases are used later, they can be updated here!
	if love.window.setMode(w, h, flags) then
        -- update canvases and stuff here!
    else
		error(string.format("Resolution %dx%d could not be set successfully.", w, h))
	end
end

function autoFullscreen()
	local supported = love.window.getFullscreenModes()
	table.sort(supported, function(a, b) return a.width*a.height < b.width*b.height end)

	local scrWidth, scrHeight = love.window.getDesktopDimensions()
	supported = filter(supported, function(mode) return mode.width*scrHeight == scrWidth*mode.height end)

	local max = supported[#supported]
	local flags = {fullscreen = true}
	setResolution(max.width, max.height, flags)
end

-- returns deep recursive copy
function copyTable(from)
	local to = {}
	for k, v in pairs(from) do
		if type(v) == "table" then
			to[k] = copyTable(v)
		else
			to[k] = v
		end
	end
	return to
end
