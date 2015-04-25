do
    astronaut = {} -- (server)

    function astronaut.enter()
        astronaut.host = enet.host_create("localhost:" .. PORT)
        if astronaut.host == nil then error("Host is nil.") end
        astronaut.map = generateLevel(love.math.random(1, 10000000))
        astronaut.velocity = {0, 0}
        astronaut.position = {tileToWorld(unpack(astronaut.map.spawn))}
    end

    function astronaut.update()
        local event = astronaut.host:service()
        while event do
            if event.type == "connect" then
                astronaut.spaceshipPeer = event.peer
            elseif event.type == "disconnect" then
                error("Spaceship disconnected :(")
            elseif event.type == "receive" then
                local type = event.data:sub(1, 5)
                if type == "HELLO" then
                    event.peer:send("HELLO:" .. tostring(astronaut.map.seed)) -- send necessary data
                elseif type == "INITD" then -- initialization done
                    astronaut.initialized = true
                end
            end
            event = astronaut.host:service()
        end

        if astronaut.spaceshipPeer and astronaut.initialized then -- game
            local accell = 55.0 * TILESIZE
            local friction = 0.075 * TILESIZE
            local gravity = 300.0 * TILESIZE

            local move = (love.keyboard.isDown("d") and 1 or 0) - (love.keyboard.isDown("a") and 1 or 0)
            astronaut.velocity[1] = astronaut.velocity[1] + move * accell * simulationDt
            --astronaut.velocity[2] = astronaut.velocity[2] + gravity * simulationDt
            astronaut.velocity[2] = astronaut.velocity[2] - ((love.keyboard.isDown("w") and 1 or 0) - (love.keyboard.isDown("s") and 1 or 0)) * 200
            astronaut.velocity = vsub(astronaut.velocity, vmul(astronaut.velocity, friction * simulationDt))
            astronaut.position = vadd(astronaut.position, vmul(astronaut.velocity, simulationDt))

            -- resolve collisions
            local colCheckRange = {{worldToTiles(astronaut.map, unpack(astronaut.position))}, {0, 0}}
            -- on gutdünken
            colCheckRange[1] = {colCheckRange[1][1] - 1, colCheckRange[1][2] - 1}
            colCheckRange[2] = {colCheckRange[1][1] + 2, colCheckRange[1][2] + 2}

            local relBox = {{-62, -112}, {136, 236}}
            local colBox = {
                vadd(astronaut.position, relBox[1]),
                relBox[2]
            }
            astronaut.wonky = false
            for y = colCheckRange[1][2], colCheckRange[2][2] do
                for x = colCheckRange[1][1], colCheckRange[2][1] do
                    if astronaut.map[y][x] == TILE_INDICES.WALL then
                        local mtv = aabbCollision(colBox, {{tileToWorld(x, y)}, {TILESIZE, TILESIZE}})
                        if mtv then
                            astronaut.wonky = true
                            astronaut.position = vadd(astronaut.position, vmul(mtv, 1.01))
                            colBox[1] = vadd(astronaut.position, relBox[1])
                        end
                    end
                end
            end

            -- send updates
            astronaut.spaceshipPeer:send("PLPOS:" .. tostring(astronaut.position[1]) .. ":" .. tostring(astronaut.position[2]))

            -- update camera
            local mouseX, mouseY = camera.screenToWorld(love.mouse.getPosition())
            local camAimDist = TILESIZE * 2.0
            astronaut.aimDirection = vMaxLen(vsub({mouseX, mouseY}, astronaut.position), camAimDist)

            camera.targetX, camera.targetY = unpack(vadd(astronaut.position, astronaut.aimDirection))
            camera.update()
        end
    end

    function astronaut.draw()
        if astronaut.spaceshipPeer then
            camera.push()
                drawMap(astronaut.map)

                love.graphics.setColor(astronaut.wonky and {255, 0, 0} or {255, 255, 255, 255})

                if astronaut.initialized then
                    love.graphics.draw(astronautImage, astronaut.position[1], astronaut.position[2], 0, 1.0, 1.0, astronautImage:getWidth()/2, astronautImage:getHeight()/2)
                end
            camera.pop()
            love.graphics.print("Astronaut", 0, 0)
        else
            love.graphics.print("Waiting for spaceship", 0, 0)
        end
    end
end
