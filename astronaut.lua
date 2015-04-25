do
    astronaut = {} -- (server)

    function astronaut.enter()
        astronaut.host = enet.host_create("localhost:" .. PORT)
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
                    event.peer:send("HELLO") -- send necessary data
                elseif type == "INITD" then -- initialization done
                    -- start game?
                    astronaut.initialized = true
                    astronaut.velocity = {0, 0}
                    astronaut.position = {0, 0}
                end
            end
            event = astronaut.host:service()
        end

        if astronaut.spaceshipPeer and astronaut.initialized then
            local accell = 12.0 * TILESIZE
            local friction = 0.075 * TILESIZE
            local move = {(love.keyboard.isDown("d") and 1 or 0) - (love.keyboard.isDown("a") and 1 or 0), 0}
            astronaut.velocity = vadd(astronaut.velocity, vmul(move, accell * simulationDt))
            astronaut.velocity = vsub(astronaut.velocity, vmul(astronaut.velocity, friction * simulationDt))
            astronaut.position = vadd(astronaut.position, vmul(astronaut.velocity, simulationDt))

            astronaut.spaceshipPeer:send("PLPOS:" .. tostring(astronaut.position[1]) .. ":" .. tostring(astronaut.position[2]))
        end
    end

    function astronaut.draw()
        if astronaut.spaceshipPeer then
            love.graphics.print("GAME", 0, 0)

            if astronaut.initialized then
                love.graphics.draw(astronautImage, unpack(astronaut.position))
            end
        else
            love.graphics.print("Waiting for spaceship", 0, 0)
        end
    end
end
