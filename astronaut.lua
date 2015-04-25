do
    astronaut = {} -- (server)

    function astronaut.enter()
        astronaut.host = enet.host_create("localhost:" .. PORT)
        if astronaut.host == nil then error("Host is nil.") end
        astronaut.map = generateLevel(love.math.random(1, 10000000))
        print("Seed:", astronaut.map.seed)
        astronaut.velocity = {0, 0}
        astronaut.position = vadd({tileToWorld(unpack(astronaut.map.spawn))}, vmul({1,1}, TILESIZE/2))
        spaceInput = watchBinaryInput(keyboardCallback(" "))
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
            local accell = 75.0 * TILESIZE
            local frictionX = 0.075 * TILESIZE
            local frictionY = 0.01 * TILESIZE
            local gravity = 45.0 * TILESIZE

            local move = (love.keyboard.isDown("d") and 1 or 0) - (love.keyboard.isDown("a") and 1 or 0)
            astronaut.velocity[1] = astronaut.velocity[1] + move * accell * simulationDt
            astronaut.velocity[2] = astronaut.velocity[2] + gravity * simulationDt
            astronaut.velocity[1] = astronaut.velocity[1] - astronaut.velocity[1] * frictionX * simulationDt
            astronaut.velocity[2] = astronaut.velocity[2] - astronaut.velocity[2] * frictionY * simulationDt

            if astronaut.onGround and spaceInput().pressed then
                local jumpStrength = 18 * TILESIZE
                astronaut.velocity[2] = -jumpStrength
            end

            -- collision resolution
            local function checkCollision()
                local colCheckRange = {{worldToTiles(astronaut.map, unpack(astronaut.position))}, {0, 0}}
                -- on gutdünkenl
                colCheckRange[1] = {colCheckRange[1][1] - 1, colCheckRange[1][2] - 1}
                colCheckRange[2] = {colCheckRange[1][1] + 2, colCheckRange[1][2] + 2}

                local relBox = {{-62, -112}, {136, 236}}
                local colBox = {
                    vadd(astronaut.position, relBox[1]),
                    relBox[2]
                }

                for y = colCheckRange[1][2], colCheckRange[2][2] do
                    for x = colCheckRange[1][1], colCheckRange[2][1] do
                        if astronaut.map[y][x] == TILE_INDICES.WALL then
                            local mtv = aabbCollision(colBox, {{tileToWorld(x, y)}, {TILESIZE, TILESIZE}})
                            if mtv then return mtv end
                        end
                    end
                end

                return nil
            end

            astronaut.onGround = false
            local delta = vmul(astronaut.velocity, simulationDt)
            astronaut.position[1] = astronaut.position[1] + delta[1]
            if checkCollision() then astronaut.position[1] = astronaut.position[1] - delta[1] end
            astronaut.position[2] = astronaut.position[2] + delta[2]
            local mtv = checkCollision()
            if mtv then
                astronaut.velocity[2] = 0
                astronaut.position = vadd(astronaut.position, vmul(mtv, 1.01))
                if delta[2] > 0.0 then
                    astronaut.onGround = true
                end
            end

            -- send updates
            astronaut.spaceshipPeer:send("PLPOS:" .. tostring(astronaut.position[1]) .. ":" .. tostring(astronaut.position[2]))

            -- update camera
            local mouseX, mouseY = camera.screenToWorld(love.mouse.getPosition())
            local camAimDist = TILESIZE * 1.5
            astronaut.aimDirection = vMaxLen(vsub({mouseX, mouseY}, astronaut.position), camAimDist)

            camera.targetX, camera.targetY = unpack(vadd(astronaut.position, astronaut.aimDirection))
            camera.update()
        end
    end

    function astronaut.draw()
        if astronaut.spaceshipPeer then
            camera.push()
                drawMap(astronaut.map)

                if astronaut.initialized then
                    love.graphics.setColor(255, 255, 255, 255)
                    love.graphics.draw(astronautImage, astronaut.position[1], astronaut.position[2], 0, 1.0, 1.0, astronautImage:getWidth()/2, astronautImage:getHeight()/2)
                end
            camera.pop()
            love.graphics.print("Astronaut", 0, 0)
        else
            love.graphics.print("Waiting for spaceship", 0, 0)
        end
    end
end
