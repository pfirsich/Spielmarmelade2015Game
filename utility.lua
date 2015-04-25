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

function split(str, sep)
    local ret = {}
    for part in string.gmatch(str, "([^" .. sep .. "]+)") do
        ret[#ret+1] = part
    end
    return ret
end

function clamp(v, lo, hi)
    return math.max(math.min(v, hi), lo)
end

function intervalsOverlap(A, B) -- interval: {left, right}
	-- they dont overlap if left_B > right_A or right_B < left_A
	-- negate: left_B <= right_A and right_B >= left_A
	return A[1] <= B[2] and B[1] <= A[2]
end

function aabbCollision(A, B) -- box: {{xleft, xright}, {yleft, yright}} (DAS WAR ES MAL. IS JETZT VORBEI)
	-- returns the MTV (minimal translation vector to resolve the collision) for the shape A if there is a collision, otherwise nil
    -- box = {{topleftx, toplefty}, {sizex, sizey}}
	if  intervalsOverlap({A[1][1], A[1][1] + A[2][1]}, {B[1][1], B[1][1] + B[2][1]})
    and intervalsOverlap({A[1][2], A[1][2] + A[2][2]}, {B[1][2], B[1][2] + B[2][2]}) then
        local xOverlap = 0
		local xMTVSign = 1
		if A[1][1] + A[2][1] - B[1][1] < B[1][1] + B[2][1] - A[1][1] then
			xOverlap = A[1][1] + A[2][1] - B[1][1]
			xMTVSign = -1
		else
			xOverlap = B[1][1] + B[2][1] - A[1][1]
			xMTVSign = 1
		end

		local yOverlap = 0
		local yMTVSign = 1
		if A[1][2] + A[2][2] - B[2][1] < B[1][2] + B[2][2] - A[2][1] then
			yOverlap = A[1][2] + A[2][2] - B[2][1]
			yMTVSign = -1
		else
			yOverlap = B[1][2] + B[2][2] - A[2][1]
			yMTVSign = 1
		end

		if xOverlap < yOverlap then
			return {xOverlap * xMTVSign, 0.0}
		else
			return {0.0, yOverlap * yMTVSign}
		end
	else
		return nil
	end
end

function worldToTiles(map, x, y)
    return clamp(math.floor(x / TILESIZE) + 1, 1, map.width), clamp(math.floor(y / TILESIZE) + 1, 1, map.height)
end

function tileToWorld(x, y)
    return (x-1)*TILESIZE, (y-1)*TILESIZE
end

function screenToTiles(map, x, y)
    return worldToTiles(map, camera.screenToWorld(x, y))
end
