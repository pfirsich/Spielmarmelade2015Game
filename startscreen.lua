do
    startscreen = {}

    function startscreen.enter()
        startscreen.ip = "127.0.0.1"
    end

    function startscreen.update()

    end

    function startscreen.draw()
        love.graphics.print("--- Choose mode ---\nPress 'H' to host a game (be the astronaut) or 'C' to connect to a game.", 0, 0)
        love.graphics.print("IP (X.X.X.X): " .. startscreen.ip, 0, 40)
        if startscreen.message then love.graphics.print(startscreen.message, 0, 55) end
    end

    function startscreen.keypressed(key)
        if key == "f11" then
            autoFullscreen()
        end

        if key == "h" then
            setState(astronaut)
        end

        if key == "c" then
            if string.match(startscreen.ip, "^%d+.%d+.%d+.%d+$") ~= nil then
                setState(spaceship, startscreen.ip)
            else
                startscreen.message = "IP invalid! Please make sure it matches the suggested format!"
            end
        end

        if key == "backspace" then
            startscreen.ip = startscreen.ip:sub(1, -2)
        end
    end

    function startscreen.textinput(text)
        if tonumber(text) or text == "." or text == ":" then
            startscreen.ip = startscreen.ip .. text
        end
    end
end
