 do
    local camAheadDis = 200

    camera = {targetX = 0.0, targetY = 0.0, targetZoom = 1.0, x = 0.0, y = 0.0, zoom = 1.0, scale = 1.0, resolutionZoomFactor = 1.0}



    function camera.load()

    end

    function camera.updateResolution()
        camera.resolutionZoomFactor = love.window.getHeight/720.0
    end


    function camera.push()
        love.graphics.push()
        love.graphics.translate(love.window.getWidth()/2, love.window.getHeight()/2)
        -- Here I swap scale and translate, so I can scale the translation myself and floor the values, to prevent sub-pixel-flickering around the edges
        local tx = -math.floor(camera.x * camera.scale)
        local ty = -math.floor(camera.y * camera.scale)
        love.graphics.translate(tx, ty)
        -- FIXME: flickering on edges caused by pixel positions not being whole numbers after scaling (see math.floor in translate). ?
        love.graphics.scale(camera.scale, camera.scale)
    end


    camera.pop = love.graphics.pop

    function camera.update(speed)
        speed = speed or 20.0
        local tfac = speed * simulationDt
        -- Interpolation
        camera.x = camera.x + (camera.targetX - camera.x) * tfac
        camera.y = camera.y + (camera.targetY - camera.y) * tfac
        -- Zoom
        camera.zoom = camera.zoom + (camera.targetZoom - camera.zoom) * tfac
        camera.scale = camera.zoom * camera.resolutionZoomFactor
    end
end
