function initGFX()
    astronautImage = love.graphics.newImage("media/images/survivor.png")

    tileSetImage = love.graphics.newImage("media/images/tiles.png")
    tilesX, tilesY = math.floor(tileSetImage:getWidth() / TILESIZE), math.floor(tileSetImage:getHeight() / TILESIZE)
    tileMap = {}
    for y = 0, tilesY - 1 do
        for x = 0, tilesX - 1 do
            tileMap[y*tilesX+x+1] = love.graphics.newQuad(x*(TILESIZE+2)+1, y*(TILESIZE+2)+1, TILESIZE, TILESIZE, tileSetImage:getWidth(), tileSetImage:getHeight())
        end
    end
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
