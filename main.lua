function love.load()

end

function love.update()

end

function love.draw()

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
            simulationTime = simulationTime + timeStepDt

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

		--lush.update()

		if love.window and love.graphics and love.window.isCreated() then
			love.graphics.clear()
			love.graphics.origin()
			if love.draw then love.draw() end
			love.graphics.present()
		end

		if love.timer then love.timer.sleep(0.001) end
	end
end
