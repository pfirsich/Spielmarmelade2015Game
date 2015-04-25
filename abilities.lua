
do

    abilityCount = 0
    abilities = {}
    
    function abilities.load() 
        -- Load all abilities
        -- Sensors
        abilities.add("Weight Sensor", 0, "Triggers when weight stands on the sensor", true, true)
        abilities.add("Movement Sensor", 0, "Triggers when something moves in its line of sight", true, true)
        -- Actors
        abilities.add("Stomp", 0, "Crushes whatever is underneath when triggered", true, false)
        abilities.add("Vanishing Block", 0, "Vanishes when triggered", true, false)
        -- Buffs
        -- Survival
    end
    
    function abilities.add(name, image, tooltip, forAI, isSensor)
        abilityCount = abilityCount + 1
        abilities{abilityCount} = {name = name, image = image, tooltip = tooltip, forAI = forAI, isSensor = isSensor}
    end
    



end
