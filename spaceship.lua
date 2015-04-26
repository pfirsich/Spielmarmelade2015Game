do
    spaceship = {} -- (client)

    spaceship.buttonScale = 1.0
    spaceship.buttons = {}
    spaceship.hovered = 0 -- which button is being hovered by the mouse
    spaceship.tooltip = ""
    spaceship.hudTop = 0
    spaceship.selected = 0

    spaceship.isDragging = false
    spaceship.dragSource = nil

    function spaceship.enter(fromState, ip)
        spaceship.host = enet.host_create()
        spaceship.server = spaceship.host:connect(ip .. ":" .. PORT)
        spaceship.notice = ""

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
                    astronaut.setupAnimations()
                    astronaut.position = {tileToWorld(unpack(spaceship.map.spawn))}
                    astronaut.aimDirection = {0, 0}
                    camera.targetX, camera.targetY = unpack(astronaut.position)

                    event.peer:send("INITD") -- initialization done
                elseif type == "PLPOS" then
                    local vals = split(event.data, ":")
                    astronaut.position = {tonumber(vals[2]), tonumber(vals[3])}
                    astronaut.aimDirection = {tonumber(vals[4]), tonumber(vals[5])}
                    astronaut.currentAnimation = vals[6]
                    astronaut.animations[astronaut.currentAnimation].time = tonumber(vals[7])
                    astronaut.flipped = vals[8] == "true"
                elseif type == "TRTRG" then
                    local vals = split(event.data, ":")
                    local trap = traps.getFromID(vals[2])
                    traps.actuallyTrigger(trap)
                elseif type == "PLDIE" then
                    astronaut.lives = astronaut.lives - 1
                elseif type == "SPAWN" then
                    local vals = split(event.data, ":")
                    astronaut.position = {tonumber(vals[2]), tonumber(vals[3])}
                    camera.targetX, camera.targetY = unpack(astronaut.position)
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
                local mtx, mty = screenToTiles(spaceship.map, mouseX, mouseY)
                if mouseL then
                    local worldMouseX, worldMouseY = camera.screenToWorld(mouseX, mouseY)
                    local rel = {worldMouseX - astronaut.position[1], worldMouseY - astronaut.position[2]}
                    if rel[1]*rel[1] + rel[2]*rel[2] > astronaut.safeRadius*astronaut.safeRadius then
                        if spaceship.selected > 0 then
                            -- place trap
                            if spaceship.buttons[spaceship.selected].ability.placementFunction(mtx, mty) then
                                local localMouseX, localMouseY = worldMouseX - (mtx - 0.5) * TILESIZE, worldMouseY - (mty - 0.5) * TILESIZE
                                local localMouseAngle = vangle({localMouseX, localMouseY})
                                if math.abs(localMouseAngle) <= math.pi / 4.0 then side = 0 end
                                if localMouseAngle >=  math.pi/4.0 and localMouseAngle <=  math.pi/4.0 + math.pi/2.0 then side = 1 end
                                if localMouseAngle <= -math.pi/4.0 and localMouseAngle >= -math.pi/4.0 - math.pi/2.0 then side = 3 end
                                if math.abs(localMouseAngle) >= math.pi/4.0 + math.pi/2.0 then side = 2 end

                                print("Placing trap because placement function returned true")
                                trapID = trapID + 1

                                abilities.placeTrap(spaceship.buttons[spaceship.selected].ability, mtx, mty, trapID, side)
                                spaceship.astronautPeer:send(   "PLTRP:" .. tostring(trapID) .. ":" ..
                                                                spaceship.buttons[spaceship.selected].ability.name .. ":" ..
                                                                tostring(mtx) .. ":" .. tostring(mty) .. ":" .. tostring(side))
                                -- remove from hand
                                spaceship.abilities = spaceship.abilities - 1

                                for i = spaceship.selected, spaceship.abilities do
                                    spaceship.buttons[i].ability = spaceship.buttons[i+1].ability
                                end
                                spaceship.selected = 0
                            end
                        else
                            -- Hovering over a placed tile?
                            print("Trying to drag at " .. mtx .. "," .. mty)
                            local trap = traps.getSourceTrapAtPoint(mtx, mty)
                            if trap ~= nil then
                                print("Starting to drag trap " .. trap.tp.name)
                                spaceship.isDragging = true
                                spaceship.dragSource = trap
                            end
                        end
                    else
                        spaceship.notice = "You cannot place a trap/sensor that close to the player."
                        delay(function() spaceship.notice = "" end, 2.0)
                    end
                else
                    if mouseLeftInput().released then
                        if spaceship.isDragging then
                            local trg = traps.getTrapAtPoint(mtx, mty)
                            if trg then
                                -- Apply
                                spaceship.dragSource.trgX = trg.tx
                                spaceship.dragSource.trgY = trg.ty
                                -- Send to Astronaut
                                spaceship.astronautPeer:send("CNTRP:" .. spaceship.dragSource.id .. ":" .. trg.id)
                                print("Traps connected: " .. spaceship.dragSource.tp.name .. " to " .. trg.tp.name)
                            end
                            -- stop dragging
                            spaceship.isDragging = false
                            spaceship.dragSource = nil
                        end
                    end
                end
            end
            -- Deselect
            if mouseR then spaceship.selected = 0 end
            -- TODO: mouse wheel zoom?
            local camMoveSpeed = 3.2 * simulationDt * TILESIZE
            local b2I = function(b) return b and 1 or 0 end
            local moveX = b2I(mouseX >= love.window.getWidth() - moveBorder) + b2I(love.keyboard.isDown("d")) - b2I(mouseX <= moveBorder) - b2I(love.keyboard.isDown("a"))
            local moveY = b2I(mouseY >= love.window.getHeight() - moveBorder) + b2I(love.keyboard.isDown("s")) - b2I(mouseY <= moveBorder) - b2I(love.keyboard.isDown("w"))
            camera.targetX = camera.targetX + camMoveSpeed * moveX
            camera.targetY = camera.targetY + camMoveSpeed * moveY

            -- Bodies
            bodies.update()

            camera.update(1/simulationDt) -- move instantly
            camera.scale = 0.4
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
            drawGame(true)
            spaceship.drawHUD()

            love.graphics.print("Lives: " .. tostring(astronaut.lives), 0, 0)
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
        -- drag'n'drop line
        if spaceship.isDragging then
            local srcx, srcy = tilesToScreen( spaceship.dragSource.tx+0.5, spaceship.dragSource.ty+0.5 )
            local trgx, trgy = love.mouse.getPosition()
            love.graphics.line(srcx, srcy, trgx, trgy)
        end
        -- Tooltip
        if spaceship.tooltip ~= "" then
            love.graphics.print(spaceship.tooltip, love.window.getWidth()/2 - love.graphics.getFont():getWidth(spaceship.tooltip)/2, 20)
        end

        love.graphics.print(spaceship.notice, (love.window.getWidth() - love.graphics.getFont():getWidth(spaceship.notice))/2, love.window.getHeight()/2)
    end
end
