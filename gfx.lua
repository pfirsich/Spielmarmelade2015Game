function initGFX()
    astronautImage = love.graphics.newImage("media/images/survivor.png")

    tileSetImage = love.graphics.newImage("media/images/tiles.png")
    tilesX, tilesY = tileSetImage:getWidth() / TILESIZE, tileSetImage:getHeight() / TILESIZE
    tileMap = {}
    for y = 0, tilesY - 1 do
        for x = 0, tilesX - 1 do
            -- TODO properly PADD TILEMAPS
            -- tileMap[y*tilesX+x] = love.graphics.newQuad(x*TILESIZE+1, y*TILESIZE+1, TILESIZE-2, TILESIZE-2, TILESIZE, TILESIZE)
            tileMap[y*tilesX+x+1] = love.graphics.newQuad(x*TILESIZE, y*TILESIZE, TILESIZE, TILESIZE, tileSetImage:getWidth(), tileSetImage:getHeight())
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
            if map[y][x] > 0 then
                love.graphics.draw(tileSetImage, tileMap[map[y][x]], tileToWorld(x, y))
            end
        end
    end
end
