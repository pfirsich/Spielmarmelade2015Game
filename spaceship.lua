do
    spaceship = {} -- (client)

    function spaceship.enter(fromState, ip)
        spaceship.host = enet.host_create()
        spaceship.server = spaceship.host:connect(ip .. ":" .. PORT)
    end

    function spaceship.update()
        local event = spaceship.host:service()
        while event do
            if event.type == "connect" then
                spaceship.astronautPeer = event.peer
                event.peer:send("HELLO")
            elseif event.type == "disconnect" then
                error("Connection lost :(")
            elseif event.type == "receive" then
                local type = event.data:sub(1, 5)
                if type == "HELLO" then
                    local vals = split(event.data, ":")
                    spaceship.map = generateLevel(tonumber(vals[2]))

                    spaceship.initialized = true
                    spaceship.astronaut = {
                        position = {0, 0}
                    }

                    event.peer:send("INITD") -- initialization done
                elseif type == "PLPOS" then
                    local vals = split(event.data, ":")
                    spaceship.astronaut.position = {tonumber(vals[2]), tonumber(vals[3])}
                end
            end
            event = spaceship.host:service()
        end

        if spaceship.astronautPeer and spaceship.initialized then -- game
            local mouseX, mouseY = love.mouse.getPosition()
            local moveBorder = 12
            -- TODO: mouse wheel zoom?
            local camMoveSpeed = 1.8 * simulationDt * TILESIZE
            if mouseX <= moveBorder then camera.targetX = camera.targetX - camMoveSpeed end
            if mouseX >= love.window.getWidth() - moveBorder then camera.targetX = camera.targetX + camMoveSpeed end
            if mouseY <= moveBorder then camera.targetY = camera.targetY - camMoveSpeed end
            if mouseY >= love.window.getHeight() - moveBorder then camera.targetY = camera.targetY + camMoveSpeed end

            camera.update(1/simulationDt) -- move instantly
        end
    end

    function spaceship.draw()
        if spaceship.astronautPeer and spaceship.initialized then
            camera.push()
                drawMap(spaceship.map)

                if spaceship.initialized then
                    love.graphics.draw( astronautImage, spaceship.astronaut.position[1], spaceship.astronaut.position[2], 0, 1.0, 1.0,
                                        astronautImage:getWidth()/2, astronautImage:getHeight()/2)
                end

            camera.pop()
            love.graphics.print("Spaceship", 0, 0)
        else
            love.graphics.print("Connecting...", 0, 0)
        end
    end
end
