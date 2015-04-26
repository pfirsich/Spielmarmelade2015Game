do
    astronaut = {} -- (server)

    function astronaut.setupAnimations()
        astronaut.currentAnimation = "idle"
        astronaut.animations = {
            idle = animNew(astroIdle, 30, 1, 30),
            fall = animNew(astroFall, 30, 1, 30),
            jump = animNew(astroJump, 30, 1, 30),
            walk = animNew(astroWalk, 50, 1, 50),
        }

        astronaut.animations.idle.speed = 14.0
        astronaut.animations.idle.headOffsetY = function(t) return math.cos(t*2.0*math.pi + math.pi*0.0) * 5.0 end

        astronaut.animations.walk.speed = 45.0
        astronaut.animations.walk.headOffsetX = function(t) return 15.0 end
        astronaut.animations.walk.headOffsetY = function(t) return math.abs(math.cos(t*2.0*math.pi)) * 10.0 - 14.0 end

        astronaut.animations.fall.speed = 100.0
        astronaut.animations.jump.speed = 200.0

        astronaut.animations.idle_light = copyTable(astronaut.animations.idle)
        astronaut.animations.fall_light = copyTable(astronaut.animations.fall)
        astronaut.animations.jump_light = copyTable(astronaut.animations.jump)
        astronaut.animations.walk_light = copyTable(astronaut.animations.walk)

        astronaut.animations.idle_light.image = astroIdleLight
        astronaut.animations.fall_light.image = astroFallLight
        astronaut.animations.jump_light.image = astroJumpLight
        astronaut.animations.walk_light.image = astroWalkLight
    end

    function astronaut.enter()
        astronaut.host = enet.host_create("localhost:" .. PORT)
        if astronaut.host == nil then error("Host is nil.") end
        astronaut.map = generateLevel(love.math.random(1, 10000000))
        print("Seed:", astronaut.map.seed)
        astronaut.velocity = {0, 0}
        astronaut.position = vadd({tileToWorld(unpack(astronaut.map.spawn))}, vmul({1,1}, TILESIZE/2))
        spaceInput = watchBinaryInput(keyboardCallback(" "))
        astronaut.onLadder = false
        astronaut.alive = true
        astronaut.setupAnimations()
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
                elseif type == "PLTRP" then
                    local vals = split(event.data, ":")
                    abilities.placeTrap(abilities.getTrapByName(vals[3]), tonumber(vals[4]), tonumber(vals[5]), tonumber(vals[2]), tonumber(vals[6]))
                elseif type == "CNTRP" then
                    local vals = split(event.data, ":")
                    print("Connecting traps with id " .. vals[2] .. " and " .. vals[3])
                    local src = traps.getFromID(vals[2])
                    local trg = traps.getFromID(vals[3])
                    src.trgx = trg.tx
                    src.trgy = trg.ty
                    print("Traps connected: " .. src.tp.name .. " to " .. trg.tp.name)
                    print("Positions " .. src.tx .. "," .. src.ty .. " -> " .. trg.tx .. "," .. trg.ty)
                end
            end
            event = astronaut.host:service()
        end

        if astronaut.spaceshipPeer and astronaut.initialized then -- game
            if astronaut.alive then
                local accell = 55.0 * TILESIZE
                local frictionX = 0.075 * TILESIZE
                local frictionY = 0.01 * TILESIZE
                local gravity = 15.0 * TILESIZE
                local ladderSpeed = 4.0 * TILESIZE

                local tilex, tiley = worldToTiles(astronaut.map, astronaut.position[1], astronaut.position[2])
                local isOnLadder = (astronaut.map[tiley][tilex] == TILE_INDICES.LADDER)
                if isOnLadder == false then astronaut.onLadder = false end

                astronaut.currentAnimation = "idle"

                local move = (love.keyboard.isDown("d") and 1 or 0) - (love.keyboard.isDown("a") and 1 or 0)
                if move ~= 0 then astronaut.currentAnimation = "walk" end
                astronaut.velocity[1] = astronaut.velocity[1] + move * accell * simulationDt -- side movement
                if astronaut.onLadder == false then
                    astronaut.velocity[2] = astronaut.velocity[2] + gravity * simulationDt -- vertical gravity
                    if isOnLadder and love.keyboard.isDown("w") then astronaut.onLadder = true end
                else
                    local moveUp = (love.keyboard.isDown("s") and 1 or 0) - (love.keyboard.isDown("w") and 1 or 0) -- move up/down
                    local tempx, tempy = worldToTiles(astronaut.map, astronaut.position[1], astronaut.position[2]-20) -- check if on top of ladder
                    if moveUp < 0 and (astronaut.map[tempy][tempx] ~= TILE_INDICES.LADDER) then moveUp = 0.0 end -- if so, don't move up
                    astronaut.velocity[2] = ladderSpeed * moveUp
                end
                astronaut.velocity[1] = astronaut.velocity[1] - astronaut.velocity[1] * frictionX * simulationDt -- x friction
                astronaut.velocity[2] = astronaut.velocity[2] - astronaut.velocity[2] * frictionY * simulationDt -- y friction

                astronaut.onTileX, astronaut.onTileY = worldToTiles(astronaut.map, astronaut.position[1], astronaut.position[2])

                if (astronaut.onGround or astronaut.onLadder) and spaceInput().pressed then
                    local jumpStrength = 12.0 * TILESIZE
                    astronaut.velocity[2] = -jumpStrength
                    astronaut.onLadder = false
                end

                if astronaut.velocity[2] > 1 and not astronaut.onLadder and not astronaut.onGround then
                    astronaut.currentAnimation = "fall"
                end

                if astronaut.velocity[2] < -1 and not astronaut.onLadder and not astronaut.onGround then
                    astronaut.currentAnimation = "jump"
                end

                -- collision resolution
                local function checkCollision()
                    local colCheckRange = {{worldToTiles(astronaut.map, unpack(astronaut.position))}, {0, 0}}
                    -- on gutdünkenl
                    colCheckRange[1] = {colCheckRange[1][1] - 1, colCheckRange[1][2] - 1}
                    colCheckRange[2] = {colCheckRange[1][1] + 2, colCheckRange[1][2] + 2}

                    local relBox = {vmul({-62, -112}, astronautScale / 0.75), vmul({136, 236}, astronautScale / 0.7)}
                    astronaut.collisionBox = {
                        vadd(astronaut.position, relBox[1]),
                        relBox[2]
                    }

                    for y = colCheckRange[1][2], colCheckRange[2][2] do
                        for x = colCheckRange[1][1], colCheckRange[2][1] do
                            if astronaut.map[y][x] == TILE_INDICES.WALL then
                                local mtv = aabbCollision(astronaut.collisionBox, {{tileToWorld(x, y)}, {TILESIZE, TILESIZE}})
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

                local mouseX, mouseY = camera.screenToWorld(love.mouse.getPosition())
                local camAimDist = TILESIZE * 1.5
                astronaut.aimDirection = vMaxLen(vsub({mouseX, mouseY}, astronaut.position), camAimDist)

                astronaut.flipped = astronaut.aimDirection[1] < 0.0
                local timeDir = 1.0
                if astronaut.currentAnimation == "walk" and astronaut.velocity[1] * astronaut.aimDirection[1] < 0.0 then timeDir = -1.0 end
                astronaut.animations[astronaut.currentAnimation].time = astronaut.animations[astronaut.currentAnimation].time + simulationDt * timeDir

                if love.keyboard.isDown("k") then astronaut.kill() end

                traps.update()
                bodies.update()
            else
                astronaut.currentAnimation = "fall"
                astronaut.animations.fall.time = 0.0

                if love.keyboard.isDown(" ") then
                    astronaut.position = vadd({tileToWorld(unpack(astronaut.map.spawn))}, vmul({1,1}, TILESIZE/2))
                    astronaut.spaceshipPeer:send("SPAWN:" .. tostring(astronaut.position[1]) .. ":" .. tostring(astronaut.position[2]))
                    astronaut.alive = true
                end
            end

            -- send updates
            astronaut.spaceshipPeer:send(   "PLPOS:" .. tostring(astronaut.position[1]) .. ":" .. tostring(astronaut.position[2]) .. ":" ..
                                            tostring(astronaut.aimDirection[1]) .. ":" .. tostring(astronaut.aimDirection[2]) .. ":" ..
                                            astronaut.currentAnimation .. ":" .. tostring(astronaut.animations[astronaut.currentAnimation].time) .. ":" ..
                                            tostring(astronaut.flipped), 0, "unsequenced")

            -- update camera
            camera.targetX, camera.targetY = unpack(vadd(astronaut.position, astronaut.aimDirection))
            camera.update()
        end
    end

    function astronaut.kill()
        astronaut.spaceshipPeer:send("PLDIE")
        astronaut.lives = astronaut.lives - 1
        astronaut.alive = false
    end

    function astronaut.draw()
        if astronaut.spaceshipPeer and astronaut.initialized then
            drawGame()
            love.graphics.print("Lives: " .. tostring(astronaut.lives), 0, 0)
            if not astronaut.alive then
                local deadText = "You're dead. Press <space> to respawn!"
                love.graphics.print(deadText, (love.window.getWidth() - love.graphics.getFont():getWidth(deadText))/2, love.window.getHeight()/2)
            end
        else
            love.graphics.print("Waiting for spaceship", 0, 0)
        end
    end
end
