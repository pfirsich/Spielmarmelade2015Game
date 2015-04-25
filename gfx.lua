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
    lightMap = love.graphics.newCanvas()
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

function drawGame()
    -- light map
    camera.push()
        love.graphics.setCanvas(lightMap)
        local col = 40
        lightMap:clear(col, col, col, 255)
        love.graphics.setBlendMode("additive")
        local headLightScale = 0.75
        love.graphics.draw( headlightImage, astronaut.position[1], astronaut.position[2] - astronautImage:getHeight()*0.3,
                            vangle(astronaut.aimDirection or {0, 0}), headLightScale, headLightScale, 0.0, headlightImage:getHeight()*0.5)
    camera.pop()

    love.graphics.setCanvas()
    love.graphics.setBlendMode("alpha")

    -- background (all this is sooo bad)
    local middle = vmul({getState().map.width, getState().map.height}, 0.5 * TILESIZE)
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
        drawMap(getState().map)

        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.draw(astronautImage, astronaut.position[1], astronaut.position[2], 0, 1.0, 1.0, astronautImage:getWidth()/2, astronautImage:getHeight()/2)
    camera.pop()

    love.graphics.setBlendMode("multiplicative")
    love.graphics.draw(lightMap)

    love.graphics.setBlendMode("alpha")
end
