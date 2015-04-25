TILE_INDICES = {
    FREE = 0,
    WALL = 1,
    SPAWN = 2,
    GOAL = 3,
    WATER = 4,
    OIL = 5
}

local maxw = 320
local maxh = 320


function generateLevel(seed)
    
    -- Randomization
    math.randomseed(seed)
    
    -- Level Object
    local level = {seed = seed, sizex = maxw, sizey = maxh}
    -- Clear Level
    for y = 1, level.sizey do 
        level[y] = {}
        for x = 1, level.sizex do
            level[y][x] = TILE_INDICES.WALL
        end
    end
    
    local midx = level.sizex/2
    local midy = level.sizey/2
    -- Generate two random branches
    generateBranch(level, midx, midy, 1, math.random(1,math.random(1,2))) -- right
    generateBranch(level, midx, midy, 3, math.random(1,math.random(1,2))) -- left
    -- Spawn Point
    level[midy][midx] = 2
    
    
    -- Create return table
    local table = {seed = level.seed, width = level.sizex, height = level.sizey, data = {}}
    local i = 1
    for y = 1, level.sizey do
        for x = 1, level.sizex do
            table.data[i] = level[y][x]
            i = i+1
        end
    end
    return table
end


function getRandomDirection() 
    local d = 0
    if math.random(1,4) <= 1 then
        -- Horizontal
        if math.random(1,2) == 1 then d = 1 else d = 3 end
    else
        -- Vertical
        if math.random(1,2) == 1 then d = 2 else d = 4 end
    end
    return d
end

function generateBranch(level, x, y, direction, childs) 
    local dirs = {{0,1}, {-1,0}, {0,-1}, {1,0}}
    local dir = dirs[direction]
    local segments = math.random(6,18)
    local branchSegment = 0
    local containsGoal = false
    if childs > 0 then
        branchSegment = math.random(3, segments-3)
        childs = childs - 1
        if childs < 1 then containsGoal = true end
    end
    
    -- Cycle through segments
    local outPos = {}
    for seg = 1, segments do
        -- Generate Segment
        outPos = generateSegment(level, x, y, dir)
        -- Apply Position of segment's end
        x = outPos[1]
        y = outPos[2]
        -- New Random Direction (just not straight back)
        repeat
            newdir = getRandomDirection()
        until math.abs(direction - newdir) ~= 2
        direction = newdir
        dir = dirs[direction]
        -- new Branch?
        if seg == branchSegment then
            generateBranch(level, x, y, math.random(1,4), childs)
        end
    end
    
    -- Set Goal
    if containsGoal then
        level[y][x] = TILE_INDICES.GOAL
    end
end

function generateSegment(level, x, y, dir)
    local steps = 0
    local vertical = (dir[2] ~= 0)
    if vertical then
        steps = math.random(1, math.random(3,7))
    else
        steps = math.random(3, 10)
    end
    local offL = math.random(0,1)
    local offR = math.random(0,1)
    local requiresLadder = (vertical and steps > 2)
    --if dir[2] > 0 and math.random(1,3) == 1 then requiresLadder = false end
    
    -- Step loop
    for i = 1, steps do
        -- Update Position
        x = x + dir[1]
        y = y + dir[2]
        -- Carve Out
        if vertical then
            for offx = -offL, offR do
                level[y][x+offx] = TILE_INDICES.FREE
            end
        else
            for offy = -offL, offR do
                level[y+offy][x] = TILE_INDICES.FREE
            end
        end
        -- Ladder
        if requiresLadder then
            level[y][x] = TILE_INDICES.LADDER
        end
        -- Change offset
        if math.random(1,4)==1 then offL = math.random(0,1) end
        if math.random(1,4)==1 then offR = math.random(0,1) end
        -- Cave
        if math.random(1,32) == 1 then generateCave(level,x,y) end
    end
    
    -- Output new position
    return {x, y}
end



function generateCave(level, ox, oy) 
    local rects = math.random(2,3)
    local lx, ly = 0
    for i = 1, rects do
        -- rectangle bounds
        local offL = math.random(1,2)
        local offR = offL + math.random(-1,1)
        local offT = math.random(1,3)
        local offB = math.random(0,1)
        for y = -offT, offB do
            for x = -offL, offR do
                lx = ox+x
                ly = oy+y
                --if level[ly][lx] == TILE_INDICES.WALL then level[ly][lx] = TILE_INDICES.FREE end
            end
        end
    end
end



function savePBMLevel(lvl, filename)
    local imgZoom = 1
    file = io.open(filename, "w")
    file:write("P2\n" .. tostring((lvl.width)*imgZoom) .. " " .. tostring((lvl.height)*imgZoom) .. "\n 15 \n")
    local i = 1
    for y = 1, lvl.height do
            for z1 = 1, imgZoom do
                    for x = 1, lvl.width do
                            for z2 = 1, imgZoom do
                                    if lvl.data[i] == TILE_INDICES.WALL then
                                            file:write("0 ")
                                    elseif lvl.data[i] == TILE_INDICES.FREE then                                         
                                            file:write("15 ")
                                    else
                                        file:write("8 ")
                                    end
                            end
                            i = i + 1
                    end
                    file:write("\n")
            end
    end
    file:close()
end






