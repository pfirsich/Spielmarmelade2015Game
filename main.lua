PORT = "3092"
TILESIZE = 256

require "math_vec"
require "states"
require "spaceship"
require "astronaut"
require "startscreen"
require "utility"
require "inputs"
require "enet"
require "camera"
require "mapgen"
require "gfx"
require "abilities"
lush = require "lush"

function love.load()
    spaceship.hudImage = love.graphics.newImage("media/images/ability_back.png")
    mouseLeftInput = watchBinaryInput(mouseButtonCallback("l"))
    mouseRightInput = watchBinaryInput(mouseButtonCallback("r"))
    initGFX()
    abilities.load()
    astronaut.lives = 8
    setState(startscreen)
end

function love.update()
    updateDelayedCalls()
    updateWatchedInputs()

    local state = getState()
    state.time = (state.time or 0) + simulationDt
    if state.update then state.update() end
end

function love.textinput(text)
    if getState().textinput then getState().textinput(text) end
end

function love.draw()
    love.graphics.setColor(255, 255, 255, 255)
    if getState().draw then getState().draw() end
end

function love.keypressed(key, isrepeat)
    if getState().keypressed then getState().keypressed(key, isrepeat) end
end

function love.keyreleased(key)
    if getState().keyreleased then getState().keyreleased(key) end
end

function love.run()
    if love.math then
        love.math.setRandomSeed(os.time())
        for i=1,3 do love.math.random() end
    end

    if love.event then
        love.event.pump()
    end

    simulationTime = love.timer.getTime()
    simulationDt = 1.0/40.0

    if love.load then love.load(arg) end

    -- Main loop
    while true do
        while simulationTime < love.timer.getTime() do
            simulationTime = simulationTime + simulationDt

            -- Process events.
            if love.event then
                love.event.pump()
                for e,a,b,c,d in love.event.poll() do
                    if e == "quit" then
                        if not love.quit or not love.quit() then
                            if love.audio then
                                love.audio.stop()
                            end
                            return
                        end
                    end
                    love.handlers[e](a,b,c,d)
                end
            end

            love.update()
        end

        lush.update()

        if love.window and love.graphics and love.window.isCreated() then
            love.graphics.clear()
            love.graphics.origin()
            if love.draw then love.draw() end
            love.graphics.present()
        end

        if love.timer then love.timer.sleep(0.001) end
    end
end
