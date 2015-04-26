


bodies = { }
bodies.count = 0




function spawnBody(img, tile, tx, ty, moveAng, moveSpeed, angle, colSize)
    print("Spawning body at " .. tx .. "," .. ty .. " moving in direction " .. moveAng)
    bodies.count = bodies.count + 1
    local x, y = tileToWorld(tx,ty)
    bodies[bodies.count] = {img = img, tile = tile, x = x, y = y, angle = angle, vx = moveSpeed * math.sin(moveAng), vy = -moveSpeed * math.cos(moveAng), colSize = colSize}
    bodies[bodies.count].ox = 128
    bodies[bodies.count].oy = 128
    bodies[bodies.count].index = bodies.count
end

function bodies.update()
    for b = bodies.count, 1, -1 do
        bodies_update(bodies[b])
    end
end

    function bodies_update(body) 
        local deleteMe = false
        -- Movement
        body.x = body.x + simulationDt*body.vx 
        body.y = body.y + simulationDt*body.vy
        -- Collision 
        if getState() == astronaut then
            -- Astronaut
            if aabbCollision(astronaut.collisionBox, {{body.x-body.colSize, body.y-body.colSize}, {2*body.colSize, 2*body.colSize}}) then
                -- deleteMe = true
                astronaut.kill()
            end
            -- Level
            local tx,ty = worldToTiles(astronaut.map, body.x, body.y)
            local tp = astronaut.map[ty][tx]
            if tp == TILE_INDICES.WALL then
                deleteMe = true
            end
            -- Delete?
            if deleteMe then
                local index = body.index
                bodies[index] = bodies[bodies.count]
                bodies[index].index = index
                bodies.count = bodies.count - 1
            end
        end
    end

function bodies.draw()
    for b = 1, bodies.count do
        bodies_draw(bodies[b])
    end    
end

    function bodies_draw(body) 
        if body.tile == 0 then
            love.graphics.draw(body.img, body.x, body.y, body.angle, 1.0, 1.0, body.ox, body.oy)
        else
            love.graphics.draw(body.img, body.tile, body.x, body.y, body.angle, 1.0, 1.0, body.ox, body.oy)        
        end
    end
    
    
function bodies.drawLight()
    for b = 1, bodies.count do
        bodies_drawLight(bodies[b])
    end    
end

    function bodies_drawLight(body) 
        if body.tile == 0 then
            love.graphics.draw(body.img, body.x, body.y, body.angle, 1.0, 1.0, body.ox, body.oy)
        else
            love.graphics.draw(body.img, body.tile, body.x, body.y, body.angle, 1.0, 1.0, body.ox, body.oy)        
        end
    end