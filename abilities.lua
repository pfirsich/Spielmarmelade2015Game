
do

    abilityCount = 0
    abilities = {}
    
    trapCount = 0
    traps = {}
    sensors = {}
    actors = {}
    
    trapID = 0
    
    
    local ability_dirs = {{0,1}, {-1,0}, {0,-1}, {1,0}}
    
    function abilities.load() 
        -- Load all abilities
        -- Sensors
        abilities.add("Weight Sensor", "weight.png", "Triggers when weight stands on the sensor", 1, true, sensors.checkWeight, false, nil)
        abilities.add("Movement Sensor", "move.png", "Triggers when something moves in its line of sight", 1, true, sensors.checkMovement, false, nil)
        -- Actors
        abilities.add("Stomp", "stomp.png", "Crushes whatever is underneath when triggered", 3, true, false, false, actors.stomp)
        abilities.add("Vanishing Block", "vanish.png", "Vanishes when triggered", 2, true, false, false, actors.vanish)
        -- abilities.add("Timer", "timer.png", "Waits for 3 seconds after being triggered before triggering itself", 1, true, false, false, actors.timer)
        abilities.add("Fake", "fake.png", "Pretends to be a sensor/trap, but doesn't do anything", 1, true, false, false, nil)
        abilities.add("Spikes", "spikes.png", "Deathly Spikes coming out of the ground", 2, true, false, false, actors.spikes)
        -- Buffs
        abilities.add("Camouflage", "camouflage.png", "Hides a trap from being seen", 2, true, false, true, nil)
        -- Survival
        abilities.add("Teleport", "teleport.png", "Teleports you to a nearby position", 1, false, false, false, nil)
    end
    
    function abilities.add(name, image, tooltip, cost, forAI, sensorFunc, isBuff)
        abilityCount = abilityCount + 1
        abilities[abilityCount] = {name = name, 
            image = love.graphics.newImage("media/images/ability/" .. image), 
            ingameImage = nil, 
            tooltip = tooltip, 
            cost = cost, 
            forAI = forAI, 
            isSensor = (sensorFunc ~= false), 
            sensorFunc = sensorFunc, 
            isBuff = isBuff, 
            triggerFunc = triggerFunc,
            isSource = (sensorFunc ~= false)
        }
        local ingameFile = "media/images/ability/ingame_" .. image
        if love.filesystem.isFile(ingameFile) then abilities[abilityCount].ingameImage = love.graphics.newImage(ingameFile) end
    end
    
    function abilities.getRandom(forAI, maxCost) 
        if maxCost < 1 then return nil end
        repeat
            i = math.random(1,abilityCount)
        until abilities[i].forAI == forAI and abilities[i].cost <= maxCost
        return abilities[i]
    end 
    
    function abilities.getTrapByName(name)
        for i = 1, abilityCount do
            if abilities[i].name == name then return abilities[i] end
        end
        return nil
    end 
    
    function abilities.placeTrap(ability, tx, ty, id) 
        trapCount = trapCount + 1
        traps[trapCount] = {tp = ability, id = id, tx = tx, ty = ty, active = true, hidden = false, trgx = tx, trgy = ty, param = 0}
        print("Trap " .. ability.name .. " created at tile " .. tx .. "," .. ty)
    end
    
    function traps.getFromID(findID)
        id = tonumber(findID)
        for i = 1, trapCount do
            print("Trap " .. i .. " has id " .. traps[i].id .. ".")
            if traps[i].id == id then return traps[i] end
        end
        return nil        
    end
    
    function traps.getTrapAtPoint(tx, ty)
        for i = 1, trapCount do
            if traps[i].tx == tx and traps[i].ty == ty then return traps[i] end
        end
        return nil        
    end
    
    function traps.getSourceTrapAtPoint(tx, ty)
        for i = 1, trapCount do
            if traps[i].tp.isSource and traps[i].tx == tx and traps[i].ty == ty then return traps[i] end
        end
        return nil       
    end
    
    function traps.update()
        -- astronaut.onTileX, astronaut.onTileY = worldToTiles(astronaut.map, astronaut.position[1], astronaut.position[2])
        for t = 1, trapCount do
            if traps[t].active and traps[t].tp.isSensor then
                -- Update Sensor
                traps[t].tp.sensorFunc(traps[t])
            end
        end
    end
    
        function traps.trigger(tx,ty) 
            for t = 1, trapCount do
                if traps[t].tx == tx and traps[t].ty == ty then
                    if traps[t].active and traps[t].isSensor == false then
                        traps.actuallyTrigger(traps[t])
                    end
                end
            end
        end
    
        function traps.actuallyTrigger(trap)
            -- Deactivate after use
            trap.active = false
            -- send over network
            if astronaut.spaceshipPeer then astronaut.spaceshipPeer:send("TRTRG:" .. tostring(trap.id)) end
            -- Activate
            trap.tp.triggerFunc(trap)
        end
    
        function sensors.checkWeight(sensor)
            -- print("Checking sensor at " .. tostring(sensor.tx) .. "," .. tostring(sensor.ty) .. " while astronaut is on " .. tostring(astronaut.onTileX) .. "," .. tostring(astronaut.onTileY))
            if astronaut.onTileX == sensor.tx and astronaut.onTileY == sensor.ty then
                if astronaut.onGround then
                    sensors.trigger(sensor)
                end
            end
        end
        
        function sensors.checkMovement(sensor)
            local dir = ability_dirs[sensor.param+1]
            local tx, ty = sensor.tx, sensor.ty
            while astronaut.map[ty][tx] ~= TILE_INDICES.WALL do
                -- check for trigger
                if astronaut.onTileX == tx and astronaut.onTileY == ty then
                    sensors.trigger(sensor)
                end
                -- proceed
                tx = tx + dir[1]
                ty = ty + dir[2]
            end
        end
        
        function sensors.trigger(sensor)
            traps.trigger(sensor.trgx, sensor.trgy)
            print("Triggering sensor of type " .. sensor.tp.name)
        end

        
        function actors.stomp(trap)
            -- ...
        end
        
        function actors.vanish(trap)
            astronaut.map[trap.ty][trap.tx] = TILE_INDICES.FREE
        end
        
        function actors.timer(trap)
            if getState() == astronaut then delay(function() traps.trigger(trap.trgx, trap.trgy) end, 3) end
        end
        
        function actors.spikes(trap)
            -- ...
        end
        
        function actors.camouflage(trap)
            
        end

end
