 do
    camera = {targetX = 0.0, targetY = 0.0, targetZoom = 0.6, x = 0.0, y = 0.0, zoom = 1.0, scale = 1.0}

    function camera.push(scale)
        scale = scale or 1.0

        love.graphics.push()
        -- Center Screen
        love.graphics.translate(love.window.getWidth()/2*scale, love.window.getHeight()/2*scale)
        -- Here I swap scale and translate, so I can scale the translation myself and floor the values, to prevent sub-pixel-flickering around the edges
        local tx = -math.floor(camera.x * camera.scale * scale)
        local ty = -math.floor(camera.y * camera.scale * scale)
        love.graphics.translate(tx, ty)
        -- FIXME: flickering on edges caused by pixel positions not being whole numbers after scaling (see math.floor in translate). ?
        love.graphics.scale(camera.scale*scale, camera.scale*scale)
    end

    function camera.screenToWorld(x, y)
        -- Relative to Center
        x = x - love.window.getWidth()/2
        y = y - love.window.getHeight()/2
        -- Scaling
        x = x/camera.scale
        y = y/camera.scale
        -- translation
        x = camera.x + x
        y = camera.y + y
        return x, y
    end

    camera.pop = love.graphics.pop

    function camera.update(speed)
        camera.resolutionZoomFactor = love.window.getHeight()/720.0

        speed = speed or 6.0
        local tfac = speed * simulationDt
        -- Interpolation
        camera.x = camera.x + (camera.targetX - camera.x) * tfac
        camera.y = camera.y + (camera.targetY - camera.y) * tfac
        -- Zoom
        camera.zoom = camera.zoom + (camera.targetZoom - camera.zoom) * tfac
        camera.scale = camera.zoom * camera.resolutionZoomFactor
    end
end
