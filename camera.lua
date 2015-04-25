 do 
    local camAheadDis = 200

    camera = {targetX = 0.0, targetY = 0.0, targetZoom = 1.0, x = 0.0, y = 0.0, zoom = 1.0, scale = 1.0, resolutionZoomFactor = 1.0, scrw = 1280, scrh = 720}



    function camera.load()
        
    end

    function camera.updateResolution()
        camera.scrw = love.window.getWidth()
        camera.scrh = love.window.getHeight()
        camera.resolutionZoomFactor = camera.scrh/720.0
    end


    function camera.push()
        love.graphics.push()
        -- Center Screen
        love.graphics.translate(camera.scrw*0.5, camera.scrh*0.5)
        -- Here I swap scale and translate, so I can scale the translation myself and floor the values, to prevent sub-pixel-flickering around the edges
        local tx = -math.floor(camera.x * camera.scale)
        local ty = -math.floor(camera.y * camera.scale)
        love.graphics.translate(tx, ty)
        -- FIXME: flickering on edges caused by pixel positions not being whole numbers after scaling (see math.floor in translate). ?
        love.graphics.scale(camera.scale, camera.scale)
    end
    
    function camera.screenToWorld(x, y)
        -- Relative to Center
        x = x - camera.scrw*0.5
        y = y - camera.scrh*0.5
        -- Scaling
        x = camera.x + x/camera.scale
        y = camera.y + y/camera.scale
        return x, y
    end

    camera.pop = love.graphics.pop

    function camera.update()    
        local tfac = 0.1 * simulationDt
        -- Interpolation
        position = p + (t-p) * speed * simulationDt
        camera.x = camera.x + (camera.targetX - camera.x) * tfac
        camera.y = camera.y + (camera.targetY - camera.y) * tfac
        -- Zoom
        camera.zoom = camera.zoom + (camera.targetZoom - camera.zoom) * tfac
        camera.scale = camera.zoom * camera.resolutionZoomFactor
    end


    function camera.set(x, y, headingDirection)
        -- Set Camera to player/position
        if getState() == astronaut then
            camera.targetX = x + headingDirection and camAheadDis or -camAheadDis
            camera.targetZoom = 2.0
        else
            camera.targetX = x
            camera.targetZoom = 1.0
        end
        camera.targetY = y
    end
end