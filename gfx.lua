function initGFX()
    astronautImage = love.graphics.newImage("media/images/survivor.png")
    headlightImage = love.graphics.newImage("media/images/headlight.png")
    backgrounds = {
        love.graphics.newImage("media/images/Background1.png"),
        love.graphics.newImage("media/images/Background2.png"),
        love.graphics.newImage("media/images/Background3.png"),
    }
    bgSize = {backgrounds[1]:getWidth(), backgrounds[1]:getHeight()}
    bgCountX, bgCountY = math.ceil(love.window.getWidth()/bgSize[1]), math.ceil(love.window.getHeight()/bgSize[2])

    lightMapScale = 2
    shadowMesh = love.graphics.newMesh(500, nil, "triangles")

    blurShader = love.graphics.newShader([[
    uniform float bloomStrength = 1.0;
    extern bool horizontal = true;
    //const int radius = 5;
    //const float gaussKernel[11] = float[11](0.0402,0.0623,0.0877,0.1120,0.1297,0.1362,0.1297,0.1120,0.0877,0.0623,0.0402);

    const int radius = 7;
    const float gaussKernel[15] = float[15](0.034619, 0.044859, 0.055857, 0.066833, 0.076841, 0.084894, 0.090126, 0.09194, 0.090126, 0.084894, 0.076841, 0.066833, 0.055857, 0.044859, 0.034619);

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    	vec2 delta;
    	if(horizontal) {
    		delta = vec2(1.0/love_ScreenSize.x, 0.0);
    	} else {
    		delta = vec2(0.0, 1.0/love_ScreenSize.y);
    	}

    	vec2 coord = texture_coords - radius * delta;
    	vec3 col = vec3(0.0);
    	for(int i = 0; i < radius*2 + 1; ++i) {
    		col += gaussKernel[i] * Texel(texture, coord).rgb;
    		coord += delta;
    	}

    	return vec4(col, bloomStrength);
    }]])

    tileSetImage = love.graphics.newImage("media/images/tiles.png")
    tilesX, tilesY = math.floor(tileSetImage:getWidth() / TILESIZE), math.floor(tileSetImage:getHeight() / TILESIZE)
    tileMap = {}
    for y = 0, tilesY - 1 do
        for x = 0, tilesX - 1 do
            tileMap[y*tilesX+x+1] = love.graphics.newQuad(x*(TILESIZE+2)+1, y*(TILESIZE+2)+1, TILESIZE, TILESIZE, tileSetImage:getWidth(), tileSetImage:getHeight())
        end
    end

    reinitGFX()
end

function reinitGFX()
    lightMap = love.graphics.newCanvas(love.window.getWidth()/lightMapScale, love.window.getHeight()/lightMapScale)
    lightMapPong = love.graphics.newCanvas(love.window.getWidth()/lightMapScale, love.window.getHeight()/lightMapScale)
end

function drawMap(map)
    local drawRange = {
        {screenToTiles(map, 0, 0)},
        {screenToTiles(map, love.window.getWidth(), love.window.getHeight())}
    }

    for y = drawRange[1][2], drawRange[2][2] do
        for x = drawRange[1][1], drawRange[2][1] do
            local tile = map[y][x]
            if tile > 0 then
                if map[y][x] == TILE_INDICES.WALL and map.mapMeta then
                    tile = map.mapMeta[y][x].tile
                    local col = map.mapMeta[y][x].color
                    love.graphics.setColor(col, col, col, 255)
                else
                    love.graphics.setColor(255, 255, 255, 255)
                end
                love.graphics.draw(tileSetImage, tileMap[tile], tileToWorld(x, y))
            end
        end
    end
end

function extrudeShadowEdge(vertices, edgeFrom, edgeTo, from)
    local shadowLength = love.window.getWidth()

    local vertex = function(point, len)
        local relX, relY = point[1] - from[1], point[2] - from[2]
        local relLen = math.sqrt(relX*relX + relY*relY)
        relX, relY = relX/relLen, relY/relLen
        return {point[1] + relX * len, point[2] + relY * len, 0, 0}
    end

    local f = {edgeFrom[1], edgeFrom[2], 0, 0}
    local t = {edgeTo[1], edgeTo[2], 0, 0}
    local ef = vertex(edgeFrom, shadowLength)
    local et = vertex(edgeTo, shadowLength)

    vertices[#vertices+1] = f
    vertices[#vertices+1] = t
    vertices[#vertices+1] = et

    vertices[#vertices+1] = f
    vertices[#vertices+1] = et
    vertices[#vertices+1] = ef
end

function drawGame()
    local map = getState().map

    -- light map
    camera.push(1.0/lightMapScale)
        love.graphics.setCanvas(lightMap)
        local ambient = 20
        lightMap:clear(ambient, ambient, ambient, 255)
        love.graphics.setBlendMode("additive")
        local headLightScale = 0.9
        love.graphics.draw( headlightImage, astronaut.position[1], astronaut.position[2] - astronautImage:getHeight()*0.3,
                            vangle(astronaut.aimDirection), headLightScale, headLightScale, 0.0, headlightImage:getHeight()*0.5)

        -- draw shadow volumes
        local vertices = {}

        local drawRange = {
            {screenToTiles(map, 0, 0)},
            {screenToTiles(map, love.window.getWidth(), love.window.getHeight())}
        }

        local aimDir = vnormed(astronaut.aimDirection)

        local checkEdge = function(x, y, from, to)
            if y < 1 or x < 1 or y > map.height or x > map.width then return end

            if map[y][x] ~= TILE_INDICES.WALL then
                local normal = vsub(to, from)
                normal = vnormed({normal[2], -normal[1]})
                if vdot(normal, aimDir) < 0.0 then
                end
                    extrudeShadowEdge(vertices, from, to, astronaut.position)
            end
        end

        for y = drawRange[1][2], drawRange[2][2] do
            for x = drawRange[1][1], drawRange[2][1] do
                local tile = map[y][x]
                if map[y][x] == TILE_INDICES.WALL then
                    local topLeftX, topLeftY = tileToWorld(x, y)
                    checkEdge(x  , y+1, {topLeftX, topLeftY + TILESIZE}, {topLeftX + TILESIZE, topLeftY + TILESIZE})
                    checkEdge(x+1, y  , {topLeftX + TILESIZE, topLeftY + TILESIZE}, {topLeftX + TILESIZE, topLeftY})
                    checkEdge(x  , y-1, {topLeftX + TILESIZE, topLeftY}, {topLeftX, topLeftY})
                    checkEdge(x-1, y  , {topLeftX, topLeftY}, {topLeftX, topLeftY + TILESIZE})
                end
            end
        end

        if #vertices > 0 then
            love.graphics.setBlendMode("alpha")
            love.graphics.setColor(ambient, ambient, ambient, 255)

            shadowMesh:setVertices(vertices)
            love.graphics.draw(shadowMesh)
        end
    camera.pop()

    -- blur the light map
    love.graphics.setBlendMode("replace")
    love.graphics.setShader(blurShader)

    love.graphics.setCanvas(lightMapPong)
    blurShader:send("horizontal", false)
    love.graphics.draw(lightMap)

    love.graphics.setCanvas(lightMap)
    blurShader:send("horizontal", true)
    love.graphics.draw(lightMapPong)

    -- draw scene and combine
    love.graphics.setCanvas()
    love.graphics.setShader()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(255, 255, 255, 255)

    -- background (all this is sooo bad)
    local middle = vmul({map.width, map.height}, 0.5 * TILESIZE)
    local dx, dy = unpack(vmul(vsub({camera.x, camera.y}, middle), camera.scale * 0.9))

    local xindex, yindex = math.floor(dx/bgSize[1]), math.floor(dy/bgSize[2])
    dx = dx - xindex * bgSize[1]
    dy = dy - yindex * bgSize[2]

    local noise2D = function(x, y)
        return (x + y) % 3 + 1
    end

    for y = -1, bgCountY do
        for x = -1, bgCountX do
            local index = noise2D(x + xindex, y + yindex)
            love.graphics.draw(backgrounds[index], -dx + x * bgSize[1], -dy + y * bgSize[2])
        end
    end

    -- map and players
    camera.push()
        drawMap(map)

        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.draw(astronautImage, astronaut.position[1], astronaut.position[2], 0, 1.0, 1.0, astronautImage:getWidth()/2, astronautImage:getHeight()/2)
    camera.pop()

    love.graphics.setBlendMode("multiplicative")
    love.graphics.draw(lightMap, 0, 0, 0, lightMapScale, lightMapScale)

    love.graphics.setBlendMode("alpha")
end
