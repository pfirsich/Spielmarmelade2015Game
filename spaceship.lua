do
    spaceship = {} -- (client)

    spaceship.buttonScale = 1.0
    spaceship.buttons = {}
    spaceship.hovered = 0 -- which button is being hovered by the mouse
    spaceship.tooltip = ""
    spaceship.hudTop = 0
    spaceship.selected = 0

    function spaceship.enter(fromState, ip)
        spaceship.host = enet.host_create()
        spaceship.server = spaceship.host:connect(ip .. ":" .. PORT)

        -- Abilities
        spaceship.abilities = 13

        spaceship.updateResolution()
    end





    function spaceship.updateResolution()

        -- Field Positions
        local dif = 14
        local size = (love.window.getWidth()-dif)/12
        local width = size - dif
        local scale = width/spaceship.hudImage:getWidth()
        local x = dif
        local y = love.window.getHeight() - dif - spaceship.hudImage:getHeight()*scale
        for i = 1, 24 do
            -- Apply Positions
            local temp = abilities.getRandom(true, 3)
            spaceship.buttons[i] = {{x, y}, {x+width, y+scale*spaceship.hudImage:getHeight()}}
            spaceship.buttons[i].ability = temp
            -- Proceed
            x = x + size
            if i == 12 then
                x = dif
                y = y - dif - spaceship.hudImage:getHeight()*scale
            end
        end
        spaceship.buttonScale = scale
        spaceship.hudTop = spaceship.buttons[24][1][2] - 8
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
                    astronaut.position = {tileToWorld(unpack(spaceship.map.spawn))}
                    astronaut.aimDirection = {0, 0}
                    camera.targetX, camera.targetY = unpack(astronaut.position)

                    event.peer:send("INITD") -- initialization done
                elseif type == "PLPOS" then
                    local vals = split(event.data, ":")
                    astronaut.position = {tonumber(vals[2]), tonumber(vals[3])}
                    astronaut.aimDirection = {tonumber(vals[4]), tonumber(vals[5])}
                end
            end
            event = spaceship.host:service()
        end



        if spaceship.astronautPeer and spaceship.initialized then -- game
            local mouseX, mouseY = love.mouse.getPosition()
            local mouseL = mouseLeftInput().pressed
            local mouseR = mouseRightInput().pressed
            -- Button Interaction
            spaceship.handleButtons(mouseX, mouseY, mouseL)
            -- Scrolling
            local moveBorder = love.window.getHeight()*0.15
            if mouseY >= spaceship.hudTop then
                moveBorder = 12
            else
                -- not on HUD -> place tile?
                if mouseL then
                    if spaceship.selected > 0 then 
                        -- place trap
                        local mtx, mty = worldToTiles(spaceship.map, mouseX, mouseY)
                        abilities.placeTrap(spaceship.buttons[spaceship.selected].ability, mtx, mty)
                        -- remove from hand 
                        spaceship.abilitites = spaceship.abilities - 1
                        for i = spaceship.selected, spaceship.abilities do
                            spaceship.buttons[i].ability = spaceship.buttons[i+1].ability
                        end
                        spaceship.selected = 0
                    end
                end
            end
            -- Deselect
            if mouseR then spaceship.selected = 0 end
            -- TODO: mouse wheel zoom?
            local camMoveSpeed = 1.8 * simulationDt * TILESIZE
            if mouseX <= moveBorder then camera.targetX = camera.targetX - camMoveSpeed end
            if mouseX >= love.window.getWidth() - moveBorder then camera.targetX = camera.targetX + camMoveSpeed end
            if mouseY <= moveBorder then camera.targetY = camera.targetY - camMoveSpeed end
            if mouseY >= love.window.getHeight() - moveBorder then camera.targetY = camera.targetY + camMoveSpeed end
            
            traps.update()

            camera.update(1/simulationDt) -- move instantly
        end
    end

    function spaceship.handleButtons(mx, my, mL)
        -- Reset
        spaceship.tooltip = ""
        spaceship.hovered = 0
        -- Cycle all buttons
        for i = 1, spaceship.abilities do
            -- Check Mouse
            if mx >= spaceship.buttons[i][1][1] and mx <= spaceship.buttons[i][2][1] and my >= spaceship.buttons[i][1][2] and my <= spaceship.buttons[i][2][2] then
                -- Hover
                spaceship.tooltip = spaceship.buttons[i].ability.tooltip
                spaceship.hovered = i
                -- Click
                if mL then
                    spaceship.selected = i
                end
            end
        end
    end

    function spaceship.draw()
        if spaceship.astronautPeer and spaceship.initialized then
            drawGame()
            spaceship.drawHUD()

            love.graphics.print("Spaceship", 0, 0)
        else
            love.graphics.print("Connecting...", 0, 0)
        end
    end

    function spaceship.keypressed(key)
        if key == " " then
            camera.targetX, camera.targetY = unpack(astronaut.position)
        end
    end


    function spaceship.drawHUD()
        -- Cycle through abilities
        local yoff = 0
        for i = 1, spaceship.abilities do
            -- Draw
            if spaceship.selected == i then
                love.graphics.setColor(128,128,255,128)
                yoff = 0
            elseif spaceship.hovered == i then
                love.graphics.setColor(255,255,255,255)
                yoff = -4
            else
                love.graphics.setColor(255,255,255,180)
                yoff = 0
            end
            love.graphics.draw( spaceship.buttons[i].ability.image, spaceship.buttons[i][1][1], spaceship.buttons[i][1][2]+yoff, 0, spaceship.buttonScale, spaceship.buttonScale, 0, 0)
        end
        love.graphics.setColor(255,255,255,255)
        -- Tooltip
        if spaceship.tooltip ~= "" then
            love.graphics.print(spaceship.tooltip, love.window.getWidth()*0.5, 20)
        end
    end
end
