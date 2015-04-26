do
    TILE_INDICES = {
        FREE = 0,
        WALL = 1,
        SPAWN = 4,
        GOAL = 4,
        WATER = 5,
        OIL = 6,
        LADDER = 3,
    }

    local maxw = 320
    local maxh = 320

    local rand = love.math.random
    local setSeed = love.math.setRandomSeed

    function generateLevel(seed)
        -- Randomization
        setSeed(seed)

        -- Level Object
        local level = {seed = seed, width = maxw, height = maxh}
        -- Clear Level
        for y = 1, level.height do
            level[y] = {}
            for x = 1, level.width do
                level[y][x] = TILE_INDICES.FREE
            end
        end
        for y = 3, level.height-2 do
            level[y] = {}
            for x = 3, level.width-2 do
                level[y][x] = TILE_INDICES.WALL
            end
        end

        local midx = level.width/2
        local midy = level.height/2
        -- Generate two random branches
        generateBranch(level, midx, midy, 2, rand(1,rand(4,6))) -- right
        generateBranch(level, midx, midy, 4, rand(1,rand(4,6))) -- left

        -- Spawn Point
        generateCave(level, midx, midy)
        level.spawn = {midx, midy}

        refineLevel(level)

        level.mapMeta = {}
        for y = 1, level.height do
            level.mapMeta[y] = {}
            for x = 1, level.width do
                level.mapMeta[y][x] = {
                    tile = love.math.random(1, 2) + (love.math.random() < 0.5 and 1 or 0) * 4,
                    color = love.math.random(190, 255),
                }

                if y < level.height and level[y][x] == TILE_INDICES.WALL and level[y+1][x] ~= TILE_INDICES.WALL and math.random() < 0.2 then
                    level.mapMeta[y][x].light = true
                    local cur = y+1
                    while cur < level.height and level[cur][x] ~= TILE_INDICES.WALL do cur = cur + 1 end
                    level.mapMeta[y][x].lightHeight = (cur - y) / 10.0
                end
            end
        end

        savePBMLevel(level, "out.pgm")
        return level
    end


    function getRandomDirection(x, y)
        local d = 0
        if rand(1,100) <= 48 then
            -- Vertical
            if rand(1,2) == 1 then d = 1 else d = 3 end
            if rand(1,4) > 3 then
                -- Away from center
                if 2*y ~= maxh then if 2*y > maxh then d = 1 else d = 3 end end
            end
        else
            -- Horizontal
            if rand(1,2) == 1 then d = 2 else d = 4 end
            if rand(1,4) > 3 then
                -- Away from center
                if 2*x > maxw then d = 4 else d = 2 end
            end
        end
        return d
    end

    function generateBranch(level, x, y, direction, childs)
        local dirs = {{0,1}, {-1,0}, {0,-1}, {1,0}}
        local dir = dirs[direction]
        local segments = rand(8,20)
        local branchSegment = 0
        local containsGoal = false
        if childs > 0 then
            branchSegment = rand(3, segments-3)
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
                newdir = getRandomDirection(x, y)
            until math.abs(direction - newdir) ~= 2
            direction = newdir
            dir = dirs[direction]
            -- new Branch?
            if seg == branchSegment then
                generateBranch(level, x, y, rand(1,4), childs)
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
            steps = rand(1, rand(3,7))
        else
            steps = rand(6, 14)
        end
        local offL = 1 --rand(1,2)
        local offR = 0 --rand(0,1)
        local requiresLadder = (vertical and steps >= 2)
        local x2, y2 = 0
        --if dir[2] > 0 and rand(1,3) == 1 then requiresLadder = false end
        -- start at actual point
        x = x - dir[1]
        y = y - dir[2]

        -- Step loop
        for i = 1, steps do
            -- Update Position
            x = x + dir[1]
            y = y + dir[2]
            -- Check if it intervenes with another branch
            if i > 5 then
                x2 = x + dir[1]
                y2 = y + dir[2]
                if vertical then
                    for offx = -offL-1, offR+1 do
                        if level[y][x+offx] == TILE_INDICES.FREE then return {x - dir[1], y - dir[2]} end
                    end
                else
                    for offy = -offL-1, offR+1 do
                        if level[y+offy][x] == TILE_INDICES.FREE then return {x - dir[1], y - dir[2]} end
                    end
                end
            end
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
            if rand(1,8)==1 then offL = rand(1,2) end
            if rand(1,8)==1 then offR = rand(0,1) end
            -- Cave
            if rand(1,32) == 1 then generateCave(level,x,y) end
        end

        -- Output new position
        return {x, y}
    end



    function generateCave(level, ox, oy)
        local rects = rand(1,2)
        local lx, ly = 0
        for i = 1, rects do
            -- rectangle bounds
            local offL = rand(1,2)
            local offR = offL + rand(-1,1)
            local offT = rand(1,2)
            local offB = rand(0,1)
            for y = -offT, offB do
                for x = -offL, offR do
                    lx = ox+x
                    ly = oy+y
                    if level[ly][lx] == TILE_INDICES.WALL then level[ly][lx] = TILE_INDICES.FREE end
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
                                        if lvl[y][x] == TILE_INDICES.WALL then
                                                file:write("0 ")
                                        elseif lvl[y][x] == TILE_INDICES.FREE then
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


    function refineLevel(level)
        -- Step 1: Remove inner blocks for better looks
        local lvl = copyTable(level)
        for y = 2, level.height-1 do
            for x = 2, level.width-1 do
                if lvl[y][x] == TILE_INDICES.WALL then
                    if lvl[y-1][x] == TILE_INDICES.WALL and lvl[y+1][x] == TILE_INDICES.WALL and lvl[y][x+1] == TILE_INDICES.WALL and lvl[y][x-1] == TILE_INDICES.WALL then
                        if lvl[y-1][x-1] == TILE_INDICES.WALL and lvl[y-1][x+1] == TILE_INDICES.WALL and lvl[y+1][x-1] == TILE_INDICES.WALL and lvl[y+1][x+1] == TILE_INDICES.WALL then
                            level[y][x] = TILE_INDICES.FREE
                        end
                    end
                end
            end
        end
    end
end
