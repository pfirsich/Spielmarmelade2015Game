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
                    -- get necessary data, prepare map
                    spaceship.initialized = true
                    spaceship.astronaut = {
                        position = {0, 0}
                    }
                    event.peer:send("INITD")
                elseif type == "PLPOS" then
                    local vals = split(event.data, ":")
                    spaceship.astronaut.position = {tonumber(vals[2]), tonumber(vals[3])}
                end
            end
            event = spaceship.host:service()
        end
    end

    function spaceship.draw()
        if spaceship.astronautPeer then
            love.graphics.print("GAME")

            if spaceship.initialized then
                love.graphics.draw(astronautImage, unpack(spaceship.astronaut.position))
            end
        else
            love.graphics.print("Connecting...", 0, 0)
        end
    end
end
