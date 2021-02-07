local intro_finish

function intro_load()
	gamestate = "intro"
	
	introduration = 2.5
	blackafterintro = 0.3
	introfadetime = 0.5
	introprogress = 0.5
	
	screenwidth = width*16*scale
	screenheight = 224*scale
	allowskip = false
end

function intro_update(dt)
	allowskip = true
	if introprogress < introduration+blackafterintro then
		introprogress = introprogress + dt
		if introprogress > introduration+blackafterintro then
			introprogress = introduration+blackafterintro
		end
		
		if introprogress > 0.5 and playedwilhelm == nil then
			if math.random(300) == 1 then
				playsound(babysound)
			elseif math.random(300) == 1 then
				playsound(checkpointsound)
			else
				playsound(stabsound)
			end
			
			playedwilhelm = true
		end
		
		if introprogress == introduration + blackafterintro then
			intro_finish()
		end
	end
end

function intro_draw()
	local logoscale = scale / 3
	if introprogress >= 0 and introprogress < introduration then
		local a = 255
		if introprogress < introfadetime then
			a = introprogress/introfadetime * 255
		elseif introprogress >= introduration-introfadetime then
			a = (1-(introprogress-(introduration-introfadetime))/introfadetime) * 255
		end

		local img = logoblood
		if loadingtext[3] == "oil" then
			img = logooil
		elseif loadingtext[3] == "smithley" then
			img = logosmithley
		end
		
		love.graphics.setColor(255, 255, 255, a)
		
		if FamilyFriendly then
			--"If you create a minor update that's in game options make you remove the stabyourself logo?????"
			--"Stabyourself logo is not rated for everyone"
			--"If make a really free for everyone version for mari0 AE many kids will like this news"
			--"The stick man dies in the screen"
			
			if introprogress > introfadetime+0.3 and introprogress < introduration - introfadetime then
				local y = (introprogress-0.2-introfadetime) / (introduration-2*introfadetime) * 206 * 5
				properprint("stys.eu", ((width*16)*scale)/2-string.len("stys.eu")*4*scale, 110*scale)
				love.graphics.setScissor(0, screenheight/2+150*logoscale - y, screenwidth, y)
				love.graphics.setColor(100, 100, 100, a)
				properprint("stys.eu", ((width*16)*scale)/2-string.len("stys.eu")*4*scale, 110*scale)
				love.graphics.setColor(255, 255, 255, a)
				properprint("stys.eu", ((width*16)*scale)/2-string.len("stys.eu")*4*scale, 109*scale)
				love.graphics.setScissor()
			elseif introprogress >= introduration - introfadetime then
				love.graphics.setColor(100, 100, 100, a)
				properprint("stys.eu", ((width*16)*scale)/2-string.len("stys.eu")*4*scale, 110*scale)
				love.graphics.setColor(255, 255, 255, a)
				properprint("stys.eu", ((width*16)*scale)/2-string.len("stys.eu")*4*scale, 109*scale)
			else
				properprint("stys.eu", ((width*16)*scale)/2-string.len("stys.eu")*4*scale, 110*scale)
			end
		else
			if introprogress > introfadetime+0.3 and introprogress < introduration - introfadetime then
				local y = (introprogress-0.2-introfadetime) / (introduration-2*introfadetime) * 206 * 5
				love.graphics.draw(logo, screenwidth/2, screenheight/2, 0, logoscale, logoscale, 142, 150)
				love.graphics.setScissor(0, screenheight/2+150*logoscale - y, screenwidth, y)
				love.graphics.draw(img, screenwidth/2, screenheight/2, 0, logoscale, logoscale, 142, 150)
				love.graphics.setScissor()
			elseif introprogress >= introduration - introfadetime then
				love.graphics.draw(img, screenwidth/2, screenheight/2, 0, logoscale, logoscale, 142, 150)
			else
				love.graphics.draw(logo, screenwidth/2, screenheight/2, 0, logoscale, logoscale, 142, 150)
			end
		end
		
		local a2 = math.max(0, (1-(introprogress-.5)/0.3)*255)
		love.graphics.setColor(20, 20, 20, a2)
		love.graphics.rectangle("fill", 0, 4*scale, 400*scale, 20*scale)
		love.graphics.rectangle("fill", 0, 201*scale, 400*scale, 20*scale)
		love.graphics.setColor(150, 150, 150, a2)
		properprint("loading aece...", 10*scale, 10*scale)
		if loadingtext[3] == "red" then
			love.graphics.setColor(100, 50, 50, a2)
		else
			love.graphics.setColor(50, 50, 50, a2)
		end
		properprint(loadingtext[1], ((width*16)*scale)/2-string.len(loadingtext[1])*4*scale, ((height*16)*scale)/2+160)
		properprint(loadingtext[2], ((width*16)*scale)/2-string.len(loadingtext[2])*4*scale, ((height*16)*scale)/2+190)
		if loadingtext[3] == "abode" then
			local offset = 0
			for i = 1, 5 do
				offset = offset + 30
				properprint(loadingtext[1], ((width*16)*scale)/2-string.len(loadingtext[1])*4*scale, ((height*16)*scale)/2+190+offset)
			end
		end

		love.graphics.setColor(255,255,255, a2)
		for i = 1, 8 do
			love.graphics.rectangle("fill", ((i*10)-5)*scale, ((height*16)-15)*scale, 5*scale, 5*scale)
		end
	end
end

function intro_mousepressed()
	if not allowskip then
		return
	end
	stabsound:stop()
	intro_finish()
end

function intro_keypressed()
	if not allowskip then
		return
	end
	stabsound:stop()
	intro_finish()
end

function intro_finish()
	menu_load()
	logo = nil
	img = nil
end