
do

    abilityCount = 0
    abilities = {}
    
    trapCount = 0
    traps = {}
    sensors = {}
    
    function abilities.load() 
        -- Load all abilities
        -- Sensors
        abilities.add("Weight Sensor", "weight.png", "Triggers when weight stands on the sensor", 1, true, sensors.checkWeight, false)
        abilities.add("Movement Sensor", "move.png", "Triggers when something moves in its line of sight", 1, true, sensors.checkMovement, false)
        -- Actors
        abilities.add("Stomp", "stomp.png", "Crushes whatever is underneath when triggered", 3, true, false, false)
        abilities.add("Vanishing Block", "vanish.png", "Vanishes when triggered", 2, true, false, false)
        abilities.add("Timer", "timer.png", "Waits for 3 seconds after being triggered before triggering itself", 1, true, false, false)
        abilities.add("Fake", "fake.png", "Pretends to be a sensor/trap, but doesn't do anything", 1, true, false, false)
        abilities.add("Spikes", "spikes.png", "Deathly Spikes coming out of the ground", 2, true, false, false)
        -- Buffs
        abilities.add("Camouflage", "camouflage.png", "Hides a trap from being seen", 2, true, false, true)
        -- Survival
        abilities.add("Teleport", "teleport.png", "Teleports you to a nearby position", 1, false, false, false)
    end
    
    function abilities.add(name, image, tooltip, cost, forAI, sensorFunc, isBuff)
        abilityCount = abilityCount + 1
        abilities[abilityCount] = {name = name, image = love.graphics.newImage("media/images/ability/" .. image), tooltip = tooltip, cost = cost, forAI = forAI, isSensor = (sensorFunc ~= false), sensorFunc = sensorFunc, isBuff = isBuff}
    end
    
    function abilities.getRandom(forAI, maxCost) 
        if maxCost < 1 then return nil end
        repeat
            i = math.random(1,abilityCount)
        until abilities[i].forAI == forAI and abilities[i].cost <= maxCost
        return abilities[i]
    end 
    
    function abilities.placeTrap(ability, tx, ty) 
        trapCount = trapCount + 1
        traps[trapCount] = {tp = ability, tx = tx, ty = ty, active = true, hidden = false, trgx = tx, trgy = ty, param = 0}
    end
    
    function traps.update()
        for t = 1, trapCount do
            if traps[t].active and traps[t].tp.isSensor then
                -- Update Sensor
                traps[t].tp.sensorFunc(traps[t])
            end
        end
    end
    
        function traps.trigger(tx,ty) 
            for t = 1, trapCount do
                if trap[t].tx == tx and trap[t].ty == ty then
                    if trap[t].active then
                        traps.actuallyTrigger(trap[t])
                    end
                end
            end
        end
    
        function traps.actuallyTrigger(trap)
            -- Deactivate after use
            trap[t].active = false
            -- 
        end
    
        function sensors.checkWeight(sensor)
            if astronaut.onTileX == sensor.tx and astronaut.onTileY == sensor.ty then
                if astronaut.onGround then
                    sensors.trigger(sensor)
                end
            end
        end
        
        function sensors.checkMovement(sensor)
            if sensor.param == 0 then
            end
        end
        
        function sensors.trigger(sensor)
            traps.trigger(sensor.trgx, sensor.trgy)
            print("Triggering sensor of type " .. sensor.tp.name)
        end


end
