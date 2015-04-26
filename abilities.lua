
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
        abilities.add("Weight Sensor", "weight.png", "Triggers when weight stands on the sensor", 1, true, sensors.checkWeight, false, nil, placement_freeWall)
        abilities.add("Movement Sensor", "move.png", "Triggers when something moves in its line of sight", 1, true, sensors.checkMovement, false, nil, placement_freeWall)
        -- Actors
        abilities.add("Stomp", "stomp.png", "Crushes whatever is underneath when triggered", 3, true, false, false, actors.stomp, placement_wall)
        abilities.add("Vanishing Block", "vanish.png", "Vanishes when triggered", 2, true, false, false, actors.vanish, placement_wall)
        -- abilities.add("Timer", "timer.png", "Waits for 3 seconds after being triggered before triggering itself", 1, true, false, false, actors.timer)
        abilities.add("Fake", "fake.png", "Pretends to be a sensor/trap, but doesn't do anything", 1, true, false, false, nil, placement_free)
        abilities.add("Spikes", "spikes.png", "Deathly Spikes coming out of the ground", 2, true, false, false, actors.spikes, placement_freeWall)
        -- Buffs
        abilities.add("Camouflage", "camouflage.png", "Hides a trap from being seen", 2, true, false, actors.camouflage, nil, placement_trap)
        -- Survival
        abilities.add("Teleport", "teleport.png", "Teleports you to a nearby position", 1, false, false, false, nil, nil)
    end
    
    function abilities.add(name, image, tooltip, cost, forAI, sensorFunc, buffFunc, triggerFunc, placementFunc)
        abilityCount = abilityCount + 1
        abilities[abilityCount] = {name = name, 
            image = love.graphics.newImage("media/images/ability/" .. image), 
            ingameImage = nil, 
            tooltip = tooltip, 
            cost = cost, 
            forAI = forAI, 
            isSensor = (sensorFunc ~= false), 
            sensorFunc = sensorFunc, 
            isBuff = (buffFunc ~= false), 
            buffFunc = buffFunc,
            triggerFunc = triggerFunc,
            isSource = (sensorFunc ~= false),
            placementFunction = placementFunc
        }
        local ingameFile = "media/images/ability/ingame_" .. image
        if love.filesystem.isFile(ingameFile) then abilities[abilityCount].ingameImage = love.graphics.newImage(ingameFile) end
    end
    
        function placement_free(tx,ty) 
            return spaceship.map[ty][tx] == TILE_INDICES.FREE 
        end
        
        function placement_freeWallBelow(tx,ty) 
            return spaceship.map[ty][tx] == TILE_INDICES.FREE and spaceship.map[ty+1][tx] == TILE_INDICES.WALL 
        end
        
        function placement_freeWall(tx,ty)             
            if placement_free(tx,ty) then
                if spaceship.map[ty][tx-1] == TILE_INDICES.WALL or spaceship.map[ty][tx+1] == TILE_INDICES.WALL or spaceship.map[ty-1][tx] == TILE_INDICES.WALL or spaceship.map[ty+1][tx] == TILE_INDICES.WALL then
                    return true
                end
            end
            return false 
        end
        
        function placement_wall(tx,ty) 
            return spaceship.map[ty][tx] == TILE_INDICES.WALL 
        end
        
        function placement_trap(tx,ty) 
            return (traps.getTrapAtPoint(tx,ty) ~= nil)
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
        if not ability.isBuff then
            trapCount = trapCount + 1
            traps[trapCount] = {tp = ability, id = id, tx = tx, ty = ty, active = true, hidden = false, trgx = tx, trgy = ty, param = 0}
            print("Trap " .. ability.name .. " created at tile " .. tx .. "," .. ty)
        else
            -- Buff
            print("Creating Buff " .. ability.name .. " at " .. tx .. "," .. ty)
            ability.buffFunc(ability, tx, ty)
        end
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
        
        function actors.camouflage(ability, tx, ty)
            local trg = traps.getTrapAtPoint(tx, ty)
            if trg then
                trg.hidden = true
                print("Applying camouflage on " .. trg.tp.name)
            end
        end

end
