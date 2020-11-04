function menu_load()
	love.audio.stop()
	menu_music()
	editormode = false
	guielements = {}
	gamestate = "menu"

	selection = 1
	oldmouse = {love.mouse.getPosition()}
	oldjoystick = {}
	mouseonselect = false
	mouseonselecthold = false
	coinanimation = 1
	coinframe = 1
	love.graphics.setBackgroundColor(92, 148, 252)
	scrollsmoothrate = 4
	optionstab = 2
	optionsselection = 1
	skinningplayer = 1
	--cheatspage = 1
	rgbselection = 1
	colorsetedit = 1
	mappackselection = 1
	onlinemappackselection = 1
	opendlcbutton = guielement:new("button", 241, 190, "open dlc folder", opendlcfolder, nil, 0, 2.5, 147, true)
	opendlcbutton.active = false

	downloadedmappacks = {}
	mappackhorscroll = 0
	mappackhorscrollsmooth = 0
	checkpointx = false
	mariocoincount = 0
	objects = nil
	updateplayerproperties("reset")
	love.graphics.setBackgroundColor(backgroundcolor[1])
	
	controlstable = {"left", "right", "up", "down", "run", "jump", "reload", "use", "aimx", "aimy", "portal1", "portal2"}
	
	portalanimation = 1
	portalanimationtimer = 0
	portalanimationdelay = 0.08
	
	infmarioY = 0
	infmarioR = 0
	
	infmarioYspeed = 200
	infmarioRspeed = 4
	
	RGBchangespeed = 200
	huechangespeed = 0.5
	spriteset = 1
	
	portalcolors = {}
	for i = 1, players do
		portalcolors[i] = {}
	end
	
	continueavailable = false
	if love.filesystem.exists("suspend") then
		continueavailable = true
	end
	
	mariolevel = 1
	marioworld = 1
	mariosublevel = 0
	actualsublevel = 0

	loadbackground("1-1.txt")
	
	--tips
	currentmenutip = menutips[math.random(#menutips)]
	menutipoffset = -1280--(-width*16)
	
	--blinking fore the daily challenge tab
	blinktimer = 0
	
	--player select
	currentcustomplayer = false
	
	skipupdate = true
end

function menu_music()
	menumusic = false
	if love.filesystem.exists(mappackfolder .. "/" .. mappack .. "/menumusic.ogg") then
		menumusic = love.audio.newSource(mappackfolder .. "/" .. mappack .. "/menumusic.ogg")
	elseif love.filesystem.exists(mappackfolder .. "/" .. mappack .. "/menumusic.mp3") then
		menumusic = love.audio.newSource(mappackfolder .. "/" .. mappack .. "/menumusic.mp3")
	else
		menumusic = false
	end
	
	if menumusic then
		love.audio.stop()
		love.audio.play(menumusic)
	else
		love.audio.stop()
	end
end

function menu_update(dt)
	--coinanimation
	coinanimation = coinanimation + dt*6.75
	while coinanimation >= 6 do
		coinanimation = coinanimation - 5
	end	
	
	coinframe = math.max(1, math.floor(coinanimation))

	--animate animated tiles because I say so
	for i = 1, #animatedtiles do
		animatedtiles[i]:update(dt)
	end

	updatecustombackgrounds(dt)
	
	if mappackscroll then
		--smooth the scroll
		if mappackscrollsmooth > mappackscroll then
			mappackscrollsmooth = mappackscrollsmooth - (mappackscrollsmooth-mappackscroll)*dt*5-0.1*dt
			if mappackscrollsmooth < mappackscroll then
				mappackscrollsmooth = mappackscroll
			end
		elseif mappackscrollsmooth < mappackscroll then
			mappackscrollsmooth = mappackscrollsmooth - (mappackscrollsmooth-mappackscroll)*dt*5+0.1*dt
			if mappackscrollsmooth > mappackscroll then
				mappackscrollsmooth = mappackscroll
			end
		end
	end
	
	if onlinemappackscroll then
		--smooth the scroll
		if onlinemappackscrollsmooth > onlinemappackscroll then
			onlinemappackscrollsmooth = onlinemappackscrollsmooth - (onlinemappackscrollsmooth-onlinemappackscroll)*dt*5-0.1*dt
			if onlinemappackscrollsmooth < onlinemappackscroll then
				onlinemappackscrollsmooth = onlinemappackscroll
			end
		elseif onlinemappackscrollsmooth < onlinemappackscroll then
			onlinemappackscrollsmooth = onlinemappackscrollsmooth - (onlinemappackscrollsmooth-onlinemappackscroll)*dt*5+0.1*dt
			if onlinemappackscrollsmooth > onlinemappackscroll then
				onlinemappackscrollsmooth = onlinemappackscroll
			end
		end
	end
	
	if onlinemappackiconthread and onlinemappackiconthread:isRunning() then
		local v = onlinemappackiconchannel2:pop()
		if v then
			if v[1] == "error" then
				onlinemappackiconchannel:push("stop")
			elseif v[1] == "img" then
				onlinemappackiconimage = love.graphics.newImage(v[2])
				onlinemappackiconchannel:push("stop")
				onlinemappackiconquad = {}
				local w, h = onlinemappackiconimage:getWidth(), onlinemappackiconimage:getHeight()
				for y = 1, math.floor(h/50) do
					for x = 1, math.floor(w/50) do
						table.insert(onlinemappackiconquad, love.graphics.newQuad((x-1)*50, (y-1)*50, 50, 50, w, h))
					end
				end
			end
		end
	end
	if mappacklistthread then
		if mappacklistthread:isRunning() then
			local v = mappacklistthreadchannelout:pop()
			local error = mappacklistthread:getError()
			if v then
				if v[1] == "error" then
					mappacklistthreadchannelin:push({"stop"})
				elseif v[1] == "mappack" then
					if v[6] then
						mappackicon[mappacklistthreadn] = love.graphics.newImage(v[6])
					end
		
					--get info
					mappackname[mappacklistthreadn] = v[2]
					mappackauthor[mappacklistthreadn] = v[3]
					mappackdescription[mappacklistthreadn] = v[4]
					mappackbackground[mappacklistthreadn] = v[5]
					mappackdropshadow[mappacklistthreadn] = v[7]

					mappacklistthreadn = mappacklistthreadn + 1
					if mappacklistthreadn <= #mappacklist-1 then
						mappacklistthreadchannelin:push({mappackfolder .. "/" .. mappacklist[mappacklistthreadn]})
					else
						mappacklistthreadchannelin:push({"stop"})
					end
				end
			end
		else
			local error = mappacklistthread:getError()
			--print(error)
		end
	end
	
	if mappackhorscroll then
		if mappackhorscrollsmooth > mappackhorscroll then
			mappackhorscrollsmooth = mappackhorscrollsmooth - (mappackhorscrollsmooth-mappackhorscroll)*dt*5-0.03*dt
			if mappackhorscrollsmooth < mappackhorscroll then
				mappackhorscrollsmooth = mappackhorscroll
			end
		elseif mappackhorscrollsmooth < mappackhorscroll then
			mappackhorscrollsmooth = mappackhorscrollsmooth - (mappackhorscrollsmooth-mappackhorscroll)*dt*5+0.03*dt
			if mappackhorscrollsmooth > mappackhorscroll then
				mappackhorscrollsmooth = mappackhorscroll
			end
		end
	end
	
	if gamestate == "options" and optionstab == 2 then
		portalanimationtimer = portalanimationtimer + dt
		while portalanimationtimer > portalanimationdelay do
			portalanimation = portalanimation + 1
			if portalanimation > 6 then
				portalanimation = 1
			end
			portalanimationtimer = portalanimationtimer - portalanimationdelay
		end
		
		infmarioY = infmarioY + infmarioYspeed*dt
		while infmarioY > 64 do
			infmarioY = infmarioY - 64
		end
		
		infmarioR = infmarioR + infmarioRspeed*dt
		while infmarioR > math.pi*2 do
			infmarioR = infmarioR - math.pi*2
		end
	
		if characters.data[mariocharacter[skinningplayer]].colorables and optionsselection > 5 and optionsselection < 9 then
			local colorRGB = optionsselection-5
			
			if (love.keyboard.isDown("right") or love.keyboard.isDown("d")) and mariocolors[skinningplayer][colorsetedit][colorRGB] < 255 then
				mariocolors[skinningplayer][colorsetedit][colorRGB] = mariocolors[skinningplayer][colorsetedit][colorRGB] + RGBchangespeed*dt
				if mariocolors[skinningplayer][colorsetedit][colorRGB] > 255 then
					mariocolors[skinningplayer][colorsetedit][colorRGB] = 255
				end
			elseif (love.keyboard.isDown("left") or love.keyboard.isDown("a")) and mariocolors[skinningplayer][colorsetedit][colorRGB] > 0 then
				mariocolors[skinningplayer][colorsetedit][colorRGB] = mariocolors[skinningplayer][colorsetedit][colorRGB] - RGBchangespeed*dt
				if mariocolors[skinningplayer][colorsetedit][colorRGB] < 0 then
					mariocolors[skinningplayer][colorsetedit][colorRGB] = 0
				end
			end
			
		elseif (characters.data[mariocharacter[skinningplayer]].colorables and optionsselection == 9) or (not characters.data[mariocharacter[skinningplayer]].colorables and optionsselection == 5) then
			if (love.keyboard.isDown("right") or love.keyboard.isDown("d")) and portalhues[skinningplayer][1] < 1 then
				portalhues[skinningplayer][1] = portalhues[skinningplayer][1] + huechangespeed*dt
				if portalhues[skinningplayer][1] > 1 then
					portalhues[skinningplayer][1] = 1
				end
				portalcolor[skinningplayer][1] = getrainbowcolor(portalhues[skinningplayer][1])
				
			elseif (love.keyboard.isDown("left") or love.keyboard.isDown("a")) and portalhues[skinningplayer][1] > 0 then
				portalhues[skinningplayer][1] = portalhues[skinningplayer][1] - huechangespeed*dt
				if portalhues[skinningplayer][1] < 0 then
					portalhues[skinningplayer][1] = 0
				end
				portalcolor[skinningplayer][1] = getrainbowcolor(portalhues[skinningplayer][1])
			end
			
		elseif (characters.data[mariocharacter[skinningplayer]].colorables and optionsselection == 10) or (not characters.data[mariocharacter[skinningplayer]].colorables and optionsselection == 6) then
			if (love.keyboard.isDown("right") or love.keyboard.isDown("d")) and portalhues[skinningplayer][2] < 1 then
				portalhues[skinningplayer][2] = portalhues[skinningplayer][2] + huechangespeed*dt
				if portalhues[skinningplayer][2] > 1 then
					portalhues[skinningplayer][2] = 1
				end
				portalcolor[skinningplayer][2] = getrainbowcolor(portalhues[skinningplayer][2])
				
			elseif (love.keyboard.isDown("left") or love.keyboard.isDown("a")) and portalhues[skinningplayer][2] > 0 then
				portalhues[skinningplayer][2] = portalhues[skinningplayer][2] - huechangespeed*dt
				if portalhues[skinningplayer][2] < 0 then
					portalhues[skinningplayer][2] = 0
				end
				portalcolor[skinningplayer][2] = getrainbowcolor(portalhues[skinningplayer][2])
			end
		end
	elseif gamestate == "onlinemenu" then
		onlinemenu_update(dt)
	elseif gamestate == "lobby" then
		lobby_update(dt)
	end
	
	if titleframes > 1 and gamestate == "menu" and titledelay ~= nil then
		titletimer = titletimer + dt
		while titletimer >= titledelay do
			titleframe = titleframe + 1
			if titleframe > titleframes then
				titleframe = 1
			end
			titletimer = titletimer - titledelay
		end
	end
	
	--use mouse to select
	local x, y = love.mouse.getPosition()
	if (x ~= oldmouse[1] or y ~= oldmouse[2]) and gamestate == "menu" and (not DisableMouseInMainMenu) then
		if selectworldopen then
			local x, y = x/scale, y/scale
			local sc = selectworldcursor
			local v = math.ceil(sc/8)*8-7
			
			local i2 = 1
			for i = v, v+7 do
				local world = i
				if hudworldletter and i > 9 and i <= 9+#alphabet then
					world = alphabet:sub(i-9, i-9)
				end
				if reachedworlds[mappack][i] and x > (54+(i2-1)*20) and x < (54+(i2-1)*20)+12 and y > 128 and y < 140 then
					selectworldcursor = i
					break
				end
				i2 = i2 + 1
			end
		else
			mouseonselect = false
			local x, y = x/scale, y/scale
			--continue game
			if continueavailable then
				if x > 87 and y > 122 and x < 87+(string.len("continue game")*8) and y < 122+8 then
					selection = 0
					mouseonselect = 0
				end
			end
			--player game
			if x > 103 and y > 138 and x < 103+(string.len("player game")*8) and y < 138+8 then
				selection = 1
				mouseonselect = 1
			end
			--level editor
			if x > 95 and y > 154 and x < 95+(string.len("level editor")*8) and y < 154+8 then
				selection = 2
				mouseonselect = 2
			end
			--select mappack
			if x > 87 and y > 170 and x < 87+(string.len("select mappack")*8) and y < 170+8 then
				selection = 3
				mouseonselect = 3
			end
			--options
			if x > 111 and y > 186 and x < 111+(string.len("options")*8) and y < 186+8 then
				selection = 4
				mouseonselect = 4
			end
		end
	end
	oldmouse = {x, y}
	
	--joystick navigation
	if not keyprompt then
		local s1 = controls[1]["right"]
		local s2 = controls[1]["left"]
		local s3 = controls[1]["down"]
		local s4 = controls[1]["up"]
		if s1[1] == "joy" then
			if checkkey(s1) then
				if not oldjoystick[1] then
					menu_keypressed("right")
					oldjoystick[1] = true
				end
			else
				oldjoystick[1] = false
			end
		end
		if s2[1] == "joy" then
			if checkkey(s2) then
				if not oldjoystick[2] then
					menu_keypressed("left")
					oldjoystick[2] = true
				end
			else
				oldjoystick[2] = false
			end
		end
		if s3[1] == "joy" then
			if checkkey(s3) then
				if not oldjoystick[3] then
					menu_keypressed("down")
					oldjoystick[3] = true
				end
			else
				oldjoystick[3] = false
			end
		end
		if s4[1] == "joy" then
			if checkkey(s4) then
				if not oldjoystick[4] then
					menu_keypressed("up")
					oldjoystick[4] = true
				end
			else
				oldjoystick[4] = false
			end
		end
	end
	
	if not disabletips then
		menutipoffset = menutipoffset + 80*dt
		while menutipoffset > currentmenutip:len()*8 do
			menutipoffset = menutipoffset - (currentmenutip:len()*8) - (width*16)*2
			currentmenutip = menutips[math.random(#menutips)]
		end
	end
	
	--blink
	blinktimer = blinktimer + dt
	while blinktimer > 1 do
		blinktimer = blinktimer - 1
	end
end

function menu_draw()
	--GUI LIBRARY?! Never heard of that.
	--I'm not proud of this at all; But I'm even lazier than not proud.

	--TILES
	love.graphics.translate(0, yoffset*scale)
	local xtodraw
	if mapwidth < width+1 then
		xtodraw = mapwidth
	else
		if mapwidth > width then
			xtodraw = width+1
		else
			xtodraw = width
		end
	end
	
	local ytodraw
	if mapheight > height-1 then
		ytodraw = height+2
	else
		ytodraw = height+1
	end
		
	--custom background
	rendercustombackground(0,0)

	--BACKGROUND TILES
	if bmap_on then
		if editormode then
			love.graphics.setColor(255,255,255,100)
		else
			love.graphics.setColor(255,255,255,255)
		end
		for y = 1, ytodraw do
			for x = 1, xtodraw do
				local backgroundtile = bmapt(x, y, 1)
				if backgroundtile then
					if not tilequads[backgroundtile] then 
						error(backgroundtile)
					end
					love.graphics.draw(tilequads[backgroundtile].image, tilequads[backgroundtile].quad, math.floor((x-1)*16*scale), ((y-1)*16-8)*scale, 0, scale, scale)
				end
			end
		end
		love.graphics.setColor(255,255,255,255)
	end

	--Drop Shadow
	if dropshadow then
		love.graphics.setColor(dropshadowcolor)
		love.graphics.push()
		love.graphics.translate(3*scale, 3*scale)
		drawmaptiles("menudropshadow", 0, 0, xtodraw, ytodraw)
		love.graphics.pop()
	end
	
	love.graphics.setColor(255, 255, 255)
	drawmaptiles("menu", 0, 0, xtodraw, ytodraw)

	--[[for y = 1, ytodraw do
		for x = 1, xtodraw do
			local t = map[x][y]
			if t then --cheap fix
				local tilenumber = tonumber(t[1])
				if tilequads[tilenumber].coinblock and tilenumber < 90000 and tilequads[tilenumber].invisible == false then --coinblock
					love.graphics.draw(coinblockimage, coinblockquads[spriteset][coinframe], math.floor((x-1)*16*scale), ((y-1)*16-8)*scale, 0, scale, scale)
				elseif (tilequads[tilenumber].coin and tilenumber < 90000) or (t[2] == "187") then --coin
					love.graphics.draw(coinimage, coinquads[spriteset][coinframe], math.floor((x-1)*16*scale), ((y-1)*16-8)*scale, 0, scale, scale)
				elseif tilenumber ~= 0 and not tilequads[tilenumber].invisible then
					love.graphics.draw(tilequads[tilenumber].image, tilequads[tilenumber].quad, math.floor((x-1)*16*scale), ((y-1)*16-8)*scale, 0, scale, scale)
				end
			end
		end
	end]]
	
	for j = 1, math.min(4, players) do
		local char = mariocharacter[j]
		local v = characters.data[char]
		if not v then
			mariocharacter[j] = "mario"
			v = characters.data[char]
			if not v then
				break
			end
		end
	
		--draw player
		love.graphics.setColor(255, 255, 255, 255)
		local idlei = 3
		if not portalgun or (playertype == "classic" or playertype == "cappy") then
			idlei = 5
		end
		for k = 1, #v.colorables do
			love.graphics.setColor(unpack(mariocolors[j][k] or {0,0,0}))
			love.graphics.draw(v["animations"][k], v["small"]["idle"][idlei], (startx*16-6+v.smalloffsetX)*scale+8*(j-1)*scale, (starty*16-12-v.smalloffsetY)*scale, 0, scale, scale, v.smallquadcenterX, v.smallquadcenterY)
		end
		
		--hat
		offsets = customplayerhatoffsets(char, "hatoffsets", "idle") or hatoffsets["idle"]
		if v.hats then
			if #mariohats[j] > 1 or mariohats[j][1] ~= 1 then
				local yadd = 0
				for i = 1, #mariohats[j] do
					love.graphics.setColor(255, 255, 255)
					love.graphics.draw(hat[mariohats[j][i]].graphic, hat[mariohats[j][i]].quad[1], (startx*16-6+v.smalloffsetX)*scale+8*(j-1)*scale, (starty*16-12-v.smalloffsetY)*scale, 0, scale, scale, v.smallquadcenterX - hat[mariohats[j][i]].x + offsets[1], v.smallquadcenterY - hat[mariohats[j][i]].y + offsets[2] + yadd)
					yadd = yadd + (hat[mariohats[j][i]].height or 0)
				end
			elseif #mariohats[j] == 1 then
				love.graphics.setColor(mariocolors[j][1])
				love.graphics.draw(hat[mariohats[j][1]].graphic, hat[mariohats[j][1]].quad[1], (startx*16-6+v.smalloffsetX)*scale+8*(j-1)*scale, (starty*16-12-v.smalloffsetY)*scale, 0, scale, scale, v.smallquadcenterX - hat[mariohats[j][1]].x + offsets[1], v.smallquadcenterY - hat[mariohats[j][1]].y + offsets[2])
			end
		end
		
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.draw(characters.data[mariocharacter[j]]["animations"][0], v["small"]["idle"][idlei], (startx*16-6+v.smalloffsetX)*scale+8*(j-1)*scale, (starty*16-12-v.smalloffsetY)*scale, 0, scale, scale, v.smallquadcenterX, v.smallquadcenterY)
	end
	
	local properprintfunc = properprint
	if hudoutline then
		properprintfunc = properprintbackground
	end
	
	--custom foreground
	rendercustomforeground(0,0)
	
	if gamestate == "menu" then
		local x = (40-8*((titlewidth-176)/24))--position of title logo
		love.graphics.draw(titleimage, titlequad[titleframe], x*scale, 24*scale, 0, scale, scale)
		
		if updatenotification then
			love.graphics.setColor(255, 0, 0)
			properprint("version outdated!|go to stabyourself.net|to download latest", 220*scale, 90*scale)
			love.graphics.setColor(255, 255, 255, 255)
		end
		
		love.graphics.setColor(255, 255, 255)
		properprint("C2012-2020 maurice", (x+titlewidth-144)*scale, 112*scale)
		love.graphics.setColor(255, 255, 255, 255)
		
		if selection == 0 then
			love.graphics.draw(menuselectimg, 73*scale, (137+(selection-1)*16)*scale, 0, scale, scale)
		elseif selection == 1 then
			love.graphics.draw(menuselectimg, 73*scale, (137+(selection-1)*16)*scale, 0, scale, scale)
		elseif selection == 2 then
			love.graphics.draw(menuselectimg, 81*scale, (137+(selection-1)*16)*scale, 0, scale, scale)
		elseif selection == 3 then
			love.graphics.draw(menuselectimg, 73*scale, (137+(selection-1)*16)*scale, 0, scale, scale)
		elseif selection == 4 then
			love.graphics.draw(menuselectimg, 98*scale, (137+(selection-1)*16)*scale, 0, scale, scale)
		end

		---UI
		if hudvisible then
			drawHUD()
		end

		local start = 9
		if (custombackground or customforeground) and not hudoutline then
			start = 1
		end
		
		for i = start, 9 do
			local tx, ty = -scale, scale
			love.graphics.setColor(0, 0, 0)
			if i == 2 then
				tx, ty = scale, scale
			elseif i == 3 then
				tx, ty = -scale, -scale
			elseif i == 4 then
				tx, ty = scale, -scale
			elseif i == 5 then
				tx, ty = 0, -scale
			elseif i == 6 then
				tx, ty = 0, scale
			elseif i == 7 then
				tx, ty = scale, 0
			elseif i == 8 then
				tx, ty = -scale, 0
			elseif i == 9 then
				tx, ty = 0, 0
				love.graphics.setColor(255, 255, 255)
			end
			
			love.graphics.translate(tx, ty)
			
			if continueavailable then
				if i == 9 then if mouseonselecthold and mouseonselect == 0 then love.graphics.setColor(188, 188, 188) else love.graphics.setColor(255, 255, 255) end end
				properprintfunc("continue game", 87*scale, 122*scale)
			end
			
			if i == 9 then if mouseonselecthold and mouseonselect == 1 then love.graphics.setColor(188, 188, 188) else love.graphics.setColor(255, 255, 255) end end
			properprintfunc("player game", 103*scale, 138*scale)
			
			properprintfunc(players, 87*scale, 138*scale)
			if i == 9 then if (mouseonselecthold and mouseonselect == 2) or nofunallowed then love.graphics.setColor(188, 188, 188) else love.graphics.setColor(255, 255, 255) end end
			properprintfunc("level editor", 95*scale, 154*scale)
			
			if i == 9 then if mouseonselecthold and mouseonselect == 3 then love.graphics.setColor(188, 188, 188) else love.graphics.setColor(255, 255, 255) end end
			properprintfunc("select mappack", 87*scale, 170*scale)
			
			if i == 9 then if mouseonselecthold and mouseonselect == 4 then love.graphics.setColor(188, 188, 188) else love.graphics.setColor(255, 255, 255) end end
			properprintfunc("options", 111*scale, 186*scale)
			
			if i == 9 then love.graphics.setColor(255, 255, 255) end
			
			--properprint("mod by|alesan99", (x+1+titlewidth)*scale, 27*scale)
			--if not (not disabletips and menutipoffset > -width*16) then
				if not (custombackground or customforeground) or hudoutline then
					love.graphics.setColor(0, 0, 0)
					properprint("ae community edition", (width*16-#("ae community edition")*8-7)*scale, 195*scale) --a little less intrusive
					properprint("original by alesan99", (width*16-#("original by alesan99")*8-7)*scale, 209*scale) --a little less intrusive
					love.graphics.setColor(255, 255, 255)
				end
				properprint("ae community edition", (width*16-#("ae community edition")*8-8)*scale, 194*scale) --a little less intrusive
				properprint("original by alesan99", (width*16-#("original by alesan99")*8-8)*scale, 208*scale) --a little less intrusive
			--end
			
			love.graphics.translate(-tx, -ty)
		end
		
		if players >= 1 then
			love.graphics.draw(playerselectarrowimg, 82*scale, 138*scale, 0, scale, scale)
		end
		
		if players < 4 then
			love.graphics.draw(playerselectarrowimg, 102*scale, 138*scale, 0, -scale, scale)
		end
		
		if selectworldopen then
			love.graphics.setColor(0, 0, 0)
			love.graphics.rectangle("fill", 30*scale, 92*scale, 200*scale, 60*scale)
			love.graphics.setColor(255, 255, 255)
			drawrectangle(31, 93, 198, 58)
			properprint("select world", 83*scale, 105*scale)
			
			local sc = selectworldcursor
			local v = math.ceil(sc/8)*8-7
			
			local i2 = 1
			for i = v, v+7 do
				if selectworldcursor == i then
					love.graphics.setColor(255, 255, 255)
				elseif reachedworlds[mappack][i] then
					love.graphics.setColor(200, 200, 200)
				elseif selectworldexists[i] then
					love.graphics.setColor(50, 50, 50)
				else
					love.graphics.setColor(0, 0, 0)
				end
				
				local world = i
				if hudworldletter and i > 9 and i <= 9+#alphabet then
					world = alphabet:sub(i-9, i-9)
				end
				properprint(world, (55+(i2-1)*20)*scale, 130*scale)
				if i == selectworldcursor then
					properprint("v", (55+(i2-1)*20)*scale, 120*scale)
				end
				i2 = i2 + 1
			end
			love.graphics.setColor(255, 255, 255)
			if v ~= 1 then
				properprint("{", 35*scale, 130*scale)
			end
			if v+7 < #mappacklevels then
				properprint("}", 215*scale, 130*scale)
			end
		end
		
		--menu tip
		if not disabletips and menutipoffset > -width*16 then
			love.graphics.setColor(0, 0, 0, 140)
			love.graphics.rectangle("fill", 0*scale, 208*scale, width*16*scale, 11*scale)
			love.graphics.setColor(255, 255, 255, 200)
			properprint(currentmenutip:sub(1, math.floor((menutipoffset+(width*16))/8)+1), -menutipoffset*scale, 210*scale)
		end
		
	elseif gamestate == "mappackmenu" then
		---UI
		if hudvisible then
			drawHUD()
		end

		--background
		love.graphics.setColor(0, 0, 0, 100)
		love.graphics.rectangle("fill", 21*scale, 16*scale, 218*scale, 200*scale)
		love.graphics.setColor(255, 255, 255, 255)
		
		--set scissor
		love.graphics.setScissor(21*scale, 16*scale, 218*scale, 200*scale)
		
		if loadingonlinemappacks then
			love.graphics.setColor(0, 0, 0, 200)
			love.graphics.rectangle("fill", 21*scale, 16*scale, 218*scale, 200*scale)
			love.graphics.setColor(255, 255, 255, 255)
			properprint("a little patience..|downloading " .. currentdownload .. " of " .. downloadcount, 50*scale, 30*scale)
			drawrectangle(50, 55, 152, 10)
			love.graphics.rectangle("fill", 50*scale, 55*scale, 152*((currentfiledownload-1)/(filecount-1))*scale, 10*scale)
		else
			love.graphics.translate(-round(mappackhorscrollsmooth*scale*mappackhorscrollrange), 0)
			
			--mappacks
			if mappackhorscrollsmooth < 1 then
				--draw each butten (even if all you do, is press ONE. BUTTEN.)
				--scrollbar offset
				love.graphics.translate(0, -round(mappackscrollsmooth*60*scale))
				
				love.graphics.setScissor(240*scale, 16*scale, 200*scale, 200*scale)
				love.graphics.setColor(0, 0, 0, 200)
				love.graphics.rectangle("fill", 240*scale, 81*scale, 115*scale, 61*scale)
				love.graphics.setColor(255, 255, 255)
				if not savefolderfailed then
					properprint("press right to|access the dlc||press m to|open your|mappack folder", 241*scale, 83*scale)
				else
					properprint("press right to|access the dlc||could not|open your|mappack folder", 241*scale, 83*scale)
				end
				love.graphics.setScissor(21*scale, 16*scale, 218*scale, 200*scale)
				
				for i = math.max(1, math.floor(mappackscrollsmooth+1)), math.min(#mappacklist, math.floor(mappackscrollsmooth+5)) do
					--back
					love.graphics.draw(mappackback, 25*scale, (20+(i-1)*60)*scale, 0, scale, scale)
					
					--icon
					if mappackicon[i] ~= nil then
						local scale2w = scale*50 / math.max(1, mappackicon[i]:getWidth())
						local scale2h = scale*50 / math.max(1, mappackicon[i]:getHeight())
						love.graphics.draw(mappackicon[i], 29*scale, (24+(i-1)*60)*scale, 0, scale2w, scale2h)
					elseif i > mappacklistthreadn and i ~= #mappacklist then
						love.graphics.setColor(0, 0, 0)
						love.graphics.rectangle("fill", 29*scale, (24+(i-1)*60)*scale, 50*scale, 50*scale)
						love.graphics.setColor(255, 255, 255)
						love.graphics.draw(mappackloadingicon, (29+25)*scale, (24+(i-1)*60+25)*scale, (coinanimation/5)*math.pi*2, scale, scale, 25, 25)
					else
						love.graphics.draw(mappacknoicon, 29*scale, (24+(i-1)*60)*scale, 0, scale, scale)
					end
					love.graphics.draw(mappackoverlay, 29*scale, (24+(i-1)*60)*scale, 0, scale, scale)
					
					--name
					love.graphics.setColor(200, 200, 200)
					if mappackselection == i then
						love.graphics.setColor(255, 255, 255)
					end
					
					properprint(string.sub(mappackname[i] or mappacklist[i]:lower(), 1, 17), 83*scale, (26+(i-1)*60)*scale)
					
					--author
					love.graphics.setColor(100, 100, 100)
					if mappackselection == i then
						love.graphics.setColor(100, 100, 100)
					end
					
					if mappackauthor[i] then
						properprint(string.sub("by " .. (mappackauthor[i] or ""), 1, 16), 91*scale, (35+(i-1)*60)*scale)
					end
					
					--description
					love.graphics.setColor(130, 130, 130)
					if mappackselection == i then
						love.graphics.setColor(180, 180, 180)
					end
					
					if mappackdescription[i] then
						properprint( string.sub(mappackdescription[i] or "", 1, 17), 83*scale, (47+(i-1)*60)*scale)
						
						if mappackdescription[i]:len() > 17 then
							properprint( string.sub(mappackdescription[i] or "", 18, 34), 83*scale, (56+(i-1)*60)*scale)
						end
						
						if mappackdescription[i]:len() > 34 then
							properprint( string.sub(mappackdescription[i] or "", 35, 51), 83*scale, (65+(i-1)*60)*scale)
						end
					end
					
					love.graphics.setColor(255, 255, 255)
					
					--highlight
					if i == mappackselection then
						love.graphics.draw(mappackhighlight, 25*scale, (20+(i-1)*60)*scale, 0, scale, scale)
					end
				end
			
				love.graphics.translate(0, round(mappackscrollsmooth*60*scale))
			
				local i = mappackscrollsmooth / (#mappacklist-3.233)
			
				love.graphics.draw(mappackscrollbar, 227*scale, (20+i*160)*scale, 0, scale, scale)
			
			end
			
			love.graphics.translate(round(mappackhorscrollsmooth*scale*mappackhorscrollrange), 0)
			----------
			--ONLINE--
			----------
			
			love.graphics.translate(round(mappackhorscrollrange*scale - mappackhorscrollsmooth*scale*mappackhorscrollrange), 0)
			
			if mappackhorscrollsmooth > 0 and mappackhorscrollsmooth < 2 and onlinemappacklist then
				if #onlinemappacklist == 0 then
					properprint("something went wrong||      sorry d:||maybe your internet|does not work right?", 40*scale, 80*scale)
				end
				
				love.graphics.setScissor()
				if mappackhorscrollsmooth <= 1.01 then
					love.graphics.setColor(0, 0, 0, 200)
					love.graphics.rectangle("fill", 241*scale, 16*scale, 150*scale, 180*scale)
					love.graphics.setColor(255, 255, 255, 255)
					properprint("download mappacks!||pick a mappack to|open the link||after you download|the mappack, put|the .zip inside|your dlc folder||||*there's enemies/ | characters too!", 244*scale, 19*scale)
					--properprint("bonus content|like enemies|and characters|are here too!", 244*scale, 140*scale)
					love.graphics.setColor(255, 255, 255, 255)
					if outdated then
						love.graphics.setColor(255, 0, 0, 255)
						properprint("version outdated!|you have an old|version of mari0!|mappacks could not|be downloaded.|go to|stabyourself.net|to download latest", 244*scale, 130*scale)
						love.graphics.setColor(255, 255, 255, 255)
					elseif onlinemappackerror then
						love.graphics.setColor(255, 0, 0, 255)
						properprint("download error!|something went|wrong while|downloading|your mappack.|try again.|sorry.", 244*scale, 130*scale)
						love.graphics.setColor(255, 255, 255, 255)
					end
					opendlcbutton:draw()
				end
					
				love.graphics.setScissor(21*scale, 16*scale, 218*scale, 200*scale)
				
				--scrollbar offset
				love.graphics.translate(0, -round(onlinemappackscrollsmooth*60*scale))
				for i = math.max(1, math.floor(onlinemappackscrollsmooth+1)), math.min(#onlinemappacklist, math.floor(onlinemappackscrollsmooth+5)) do
					local bonuscontent = (onlinemappackfilename[i] == "enemies" or onlinemappackfilename[i] == "character")

					--back
					if downloadedmappacks[i] then
						if downloadedmappacks[i] == true then
							love.graphics.setColor(0, 100, 0, 179)
						else
							love.graphics.setColor(100, 0, 0, 179)
						end
						love.graphics.rectangle("fill", 25*scale, (20+(i-1)*60)*scale, 200*scale, 58*scale)
					else
						love.graphics.draw(mappackback, 25*scale, (20+(i-1)*60)*scale, 0, scale, scale)
					end
					
					--icon
					love.graphics.setColor(255, 255, 255)
					
					if not onlinedlc then
						if onlinemappackicon[i] then
							local scale2w = scale*50 / math.max(1, onlinemappackicon[i]:getWidth())
							local scale2h = scale*50 / math.max(1, onlinemappackicon[i]:getHeight())
							love.graphics.draw(onlinemappackicon[i], 29*scale, (24+(i-1)*60)*scale, 0, scale2w, scale2h)
						end
					elseif onlinemappackiconimage and onlinemappackiconquad[i] then
						local quadi = i
						if onlinemappackiconi[i] and onlinemappackiconquad[onlinemappackiconi[i]] then
							quadi = onlinemappackiconi[i]
						end
						love.graphics.draw(onlinemappackiconimage, onlinemappackiconquad[quadi], 29*scale, (24+(i-1)*60)*scale, 0, scale, scale)
					else
						love.graphics.draw(mappackonlineicon, mappackonlineiconquad[1], 29*scale, (24+(i-1)*60)*scale, 0, scale, scale)
					end
					love.graphics.draw(mappackoverlay, 29*scale, (24+(i-1)*60)*scale, 0, scale, scale)
					if (not onlinedlc) then
						love.graphics.draw(mappackonlineicon, mappackonlineiconquad[3], 63*scale, (25+(i-1)*60)*scale, 0, scale, scale)
					elseif onlinemappackfilename[i] == "enemies" then
						love.graphics.draw(mappackonlineicon, mappackonlineiconquad[5], 63*scale, (25+(i-1)*60)*scale, 0, scale, scale)
					elseif onlinemappackfilename[i] == "character" then
						love.graphics.draw(mappackonlineicon, mappackonlineiconquad[6], 63*scale, (25+(i-1)*60)*scale, 0, scale, scale)
					elseif onlinemappackfilename[i] == "video" then
						love.graphics.draw(mappackonlineicon, mappackonlineiconquad[7], 63*scale, (25+(i-1)*60)*scale, 0, scale, scale)
					else
						love.graphics.draw(mappackonlineicon, mappackonlineiconquad[2], 63*scale, (25+(i-1)*60)*scale, 0, scale, scale)
					end
					
					--name
					love.graphics.setColor(200, 200, 200)
					if onlinemappackselection == i then
						love.graphics.setColor(255, 255, 255)
					end
					
					properprint(string.sub(onlinemappackname[i]:lower(), 1, 17), 83*scale, (26+(i-1)*60)*scale)
					
					--author
					love.graphics.setColor(100, 100, 100)
					if onlinemappackselection == i then
						love.graphics.setColor(100, 100, 100)
					end
					
					if onlinemappackauthor[i] then
						properprint(string.sub("by " .. onlinemappackauthor[i]:lower(), 1, 16), 91*scale, (35+(i-1)*60)*scale)
					end
					
					--description
					love.graphics.setColor(130, 130, 130)
					if onlinemappackselection == i then
						love.graphics.setColor(180, 180, 180)
					end
					
					if onlinemappackdescription[i] then
						properprint( string.sub(onlinemappackdescription[i]:lower(), 1, 17), 83*scale, (47+(i-1)*60)*scale)
						
						if onlinemappackdescription[i]:len() > 17 then
							properprint( string.sub(onlinemappackdescription[i]:lower(), 18, 34), 83*scale, (56+(i-1)*60)*scale)
						end
						
						if onlinemappackdescription[i]:len() > 34 then
							properprint( string.sub(onlinemappackdescription[i]:lower(), 35, 51), 83*scale, (65+(i-1)*60)*scale)
						end
					end
					
					love.graphics.setColor(255, 255, 255)
					
					--highlight
					if i == onlinemappackselection then
						love.graphics.draw(mappackhighlight, 25*scale, (20+(i-1)*60)*scale, 0, scale, scale)
					end
				end
			
				love.graphics.translate(0, round(onlinemappackscrollsmooth*60*scale))
			
				local i = onlinemappackscrollsmooth / (#onlinemappacklist-3.233)
			
				love.graphics.draw(mappackscrollbar, 227*scale, (20+i*160)*scale, 0, scale, scale)
			end
			
			love.graphics.translate(- round(mappackhorscrollrange*scale - mappackhorscrollsmooth*scale*mappackhorscrollrange), 0)
			
			-------------------
			--DAILY CHALLENGE--
			-------------------
			
			love.graphics.translate(round(((mappackhorscrollrange*scale)*2) - mappackhorscrollsmooth*scale*mappackhorscrollrange), 0)
			
			love.graphics.setScissor(21*scale, 16*scale, 218*scale, 200*scale)
			if mappackhorscrollsmooth > 1 and mappackhorscrollsmooth < 3 then
				love.graphics.setColor(255, 255, 255)
				properprint("daily challenge:" .. datet[1] .. "/" .. datet[2] .. "/" .. datet[3], 25*scale, 21*scale)
				properprint("no. " .. DCcompleted, 25*scale, 33*scale)
				love.graphics.setColor(30, 30, 30, 150)
				properprint("v." .. DCversion, (21+mappackhorscrollrange-5-(#("v." .. DCversion)*8))*scale, 33*scale)
				love.graphics.setColor(0, 0, 0, 150)
				love.graphics.rectangle("fill", 24*scale, 45*scale, 212*scale, 80*scale)
				love.graphics.rectangle("fill", 24*scale, 129*scale, 87*scale, 13*scale)
				love.graphics.rectangle("fill", 24*scale, 145*scale, 213*scale, 42*scale)
				love.graphics.setColor(160, 160, 160)
				for i = 1, #DCchalobjectivet do
					properprint(DCchalobjectivet[i], 106*scale, (75+((i-1)*10))*scale)
				end
				local high1, high2, high3 = DChigh[1], DChigh[2], DChigh[3]
				if tonumber(high1) then
					high1 = string.format("%.2f", tonumber(high1) or 0)
				end
				if tonumber(high2) then
					high2 = string.format("%.2f", tonumber(high2) or 0)
				end
				if tonumber(high3) then
					high3 = string.format("%.2f", tonumber(high3) or 0)
				end
				properprint("1. " .. high1 .. "|2. " .. high2 .. "|3. " .. high3, 30*scale, 152*scale)
				love.graphics.setColor(255, 255, 255)
				properprint("today's|challenge", 106*scale, 48*scale)
				properprint("highscores", 28*scale, 132*scale)
				if blinktimer < 0.5 then
					properprint("press start to play!", 51*scale, 199*scale)
				end
				love.graphics.setColor(calendarcolors[tonumber(datet[1]) or 1])
				love.graphics.rectangle("fill", 26*scale, 47*scale, 76*scale, 76*scale)
				love.graphics.setColor(255, 255, 255)
				love.graphics.draw(calendarimg, 26*scale, 47*scale, 0, scale, scale)
			end
			love.graphics.setScissor()
			
			love.graphics.translate(- (round(((mappackhorscrollrange*scale)*2) - mappackhorscrollsmooth*scale*mappackhorscrollrange)), 0)
		end
		
		love.graphics.setScissor()
		
		--draw tabs
		local colors = {}
		for i = 0, 2 do
			if mappackhorscroll == i then
				colors[i] = {{255, 255, 255}, {0, 0, 0}}
			else
				colors[i] = {{0, 0, 0}, {255, 255, 255}}
			end
		end
		--local
		love.graphics.setColor(0, 0, 0)
		love.graphics.rectangle("fill", 22*scale, 3*scale, 44*scale, 13*scale)
		love.graphics.setColor(colors[0][1])
		love.graphics.rectangle("fill", 23*scale, 4*scale, 42*scale, 11*scale)
		love.graphics.setColor(colors[0][2])
		properprint("local", 23*scale, 6*scale)
		--dlc
		love.graphics.setColor(0, 0, 0)
		love.graphics.rectangle("fill", 70*scale, 3*scale, 29*scale, 13*scale)
		love.graphics.setColor(colors[1][1])
		love.graphics.rectangle("fill", 71*scale, 4*scale, 27*scale, 11*scale)
		love.graphics.setColor(colors[1][2])
		properprint("dlc", 72*scale, 6*scale)
		--daily challenge
		love.graphics.setColor(0, 0, 0)
		love.graphics.rectangle("fill", 103*scale, 3*scale, 125*scale, 13*scale)
		love.graphics.setColor(colors[2][1])
		love.graphics.rectangle("fill", 104*scale, 4*scale, 123*scale, 11*scale)
		love.graphics.setColor(colors[2][2])
		properprint("daily challenge", 105*scale, 6*scale)
		
		if downloadingmappack then
			love.graphics.setColor(0, 0, 0, 100)
			love.graphics.rectangle("fill", 0, 0, width*16*scale, 224*scale)
			love.graphics.setColor(0, 0, 0, 230)
			love.graphics.rectangle("fill", ((width*16)/2-100)*scale, (224/2-15)*scale, 200*scale, 30*scale)
			love.graphics.setColor(255, 255, 255)
			if onlinedlc then
				if onlinemappacksize[onlinemappackselection] == "url" then
					properprint("opening link...", ((width*16)/2-(string.len("opening link...")*8/2))*scale, (224/2-4)*scale)
				else
					properprint("downloading mappack...", ((width*16)/2-(string.len("downloading mappack...")*8/2))*scale, (224/2-4)*scale)
				end
			else
				properprint("loading mappacks...", ((width*16)/2-(string.len("loading mappacks...")*8/2))*scale, (224/2-4)*scale)
			end
		end
		
	elseif gamestate == "onlinemenu" then
		---UI
		if hudvisible then
			drawHUD()
		end
		onlinemenu_draw()
		--[[if CLIENT == false and SERVER == false then
			properprint("press c for client", 70*scale, 100*scale)
			properprint("press s for server", 70*scale, 160*scale)
			properprint("run away to quit", 78*scale, 170*scale)
		elseif CLIENT then
			properprint("waiting for server..", 62*scale, 100*scale)
		elseif SERVER then
			properprint("press enter to start!", 62*scale, 100*scale)
		end]]
	elseif gamestate == "lobby" then
		---UI
		if hudvisible then
			drawHUD()
		end
		lobby_draw()
	elseif gamestate == "options" then
		---UI
		if hudvisible then
			drawHUD()
		end
		love.graphics.setColor(0, 0, 0, 200)
		love.graphics.rectangle("fill", 21*scale, 31*scale, 218*scale, 185*scale)

		--Controls tab head
		--new system (oh boy)
		for i = 1, 5 do
			if optionstab == i and optionsselection == 1 then
				love.graphics.setColor(100, 100, 100, 200)
			else
				love.graphics.setColor(0, 0, 0, 200)
			end
			love.graphics.rectangle("fill", (21+((i-1)*15))*scale, 18*scale, 14*scale, 13*scale)

			if optionstab == i and optionsselection == 1 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			love.graphics.draw(optionsiconsimg, optionsiconsquads[i], (22+((i-1)*15))*scale, 19*scale, 0, scale, scale)
		end
		--old ew
		--[[if optionstab == 1 and optionsselection == 1 then
			love.graphics.setColor(100, 100, 100, 200)
		else
			love.graphics.setColor(0, 0, 0, 200)
		end
		love.graphics.rectangle("fill", 23*scale, 18*scale, 14*scale, 13*scale)
		
		if optionstab == 1 and optionsselection == 1 then
			love.graphics.setColor(255, 255, 255, 255)
		else
			love.graphics.setColor(100, 100, 100, 255)
		end
		properprint("controls", 26*scale, 22*scale)
		
		--Skins tab head
		if optionstab == 2 and optionsselection == 1 then
			love.graphics.setColor(100, 100, 100, 200)
		else
			love.graphics.setColor(0, 0, 0, 200)
		end
		love.graphics.rectangle("fill", 96*scale, 20*scale, 43*scale, 11*scale)
		
		if optionstab == 2 and optionsselection == 1 then
			love.graphics.setColor(255, 255, 255, 255)
		else
			love.graphics.setColor(100, 100, 100, 255)
		end
		properprint("skins", 97*scale, 22*scale)
		
		--Miscellaneous tab head
		if optionstab == 3 and optionsselection == 1 then
			love.graphics.setColor(100, 100, 100, 200)
		else
			love.graphics.setColor(0, 0, 0, 200)
		end
		love.graphics.rectangle("fill", 145*scale, 20*scale, 39*scale, 11*scale)
		
		if optionstab == 3 and optionsselection == 1 then
			love.graphics.setColor(255, 255, 255, 255)
		else
			love.graphics.setColor(100, 100, 100, 255)
		end
		properprint("misc.", 146*scale, 22*scale)
		
		--Cheat tab head
		if optionstab == 4 and optionsselection == 1 then
			love.graphics.setColor(100, 100, 100, 200)
		else
			love.graphics.setColor(0, 0, 0, 200)
		end
		love.graphics.rectangle("fill", 190*scale, 20*scale, 43*scale, 11*scale)
		
		if optionstab == 4 and optionsselection == 1 then
			love.graphics.setColor(255, 255, 255, 255)
		else
			love.graphics.setColor(100, 100, 100, 255)
		end
		properprint("cheat", 191*scale, 22*scale)
		]]
		love.graphics.setColor(255, 255, 255, 255)
		
		if optionstab == 1 then
			--CONTROLS
			if optionsselection == 2 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("edit player:" .. skinningplayer, 74*scale, 40*scale)
			
			if optionsselection == 3 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			if mouseowner == skinningplayer then
				properprint("uses the mouse: yes", 46*scale, 52*scale)
			else
				properprint("uses the mouse: no", 46*scale, 52*scale)
			end
			
			for i = 1, #controlstable do
				if mouseowner ~= skinningplayer or i <= 8 then		
					if optionsselection == 3+i then
						love.graphics.setColor(255, 255, 255, 255)
					else
						love.graphics.setColor(100, 100, 100, 255)
					end
					
					properprint(controlstable[i], 30*scale, (70+(i-1)*12)*scale)
					
					local s = ""
					
					if controls[skinningplayer][controlstable[i]] then
						for j = 1, #controls[skinningplayer][controlstable[i]] do
							s = s .. controls[skinningplayer][controlstable[i]][j]
						end
					end
					if s == " " then
						s = "space"
					end
					properprint(s, 120*scale, (70+(i-1)*12)*scale)
				end
			end
				
			if keyprompt then
				love.graphics.setColor(0, 0, 0, 255)
				love.graphics.rectangle("fill", 30*scale, 100*scale, 200*scale, 60*scale)
				love.graphics.setColor(255, 255, 255, 255)
				drawrectangle(30, 100, 200, 60)
				if controlstable[optionsselection-3] == "aimx" then
					properprint("move stick right", 40*scale, 110*scale)
				elseif controlstable[optionsselection-3] == "aimy" then
					properprint("move stick down", 40*scale, 110*scale)
				else
					properprint("press key for '" .. controlstable[optionsselection-3] .. "'", 40*scale, 110*scale)
				end
				properprint("press 'esc' to cancel", 40*scale, 140*scale)
				
				if buttonerror then
					love.graphics.setColor(200, 0, 0)
					properprint("you can only set", 40*scale, 120*scale)
					properprint("buttons for this", 40*scale, 130*scale)
				elseif axiserror then
					love.graphics.setColor(200, 0, 0)
					properprint("you can only set", 40*scale, 120*scale)
					properprint("axes for this", 40*scale, 130*scale)
				end
			end
		elseif optionstab == 2 then
			local v = characters.data[mariocharacter[skinningplayer]]
			--SKINS
			if optionsselection == 2 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("edit player:" .. skinningplayer, 74*scale, 32*scale)
			
			--PREVIEW MARIO IN BIG. WITH BIG LETTERS
			local v = characters.data[mariocharacter[skinningplayer]]
			love.graphics.setColor(255, 255, 255, 255)
			for i = 1, #v.colorables do
				love.graphics.setColor(unpack(mariocolors[skinningplayer][i]))
				if mariocharacter[skinningplayer] then
					love.graphics.draw(characters.data[mariocharacter[skinningplayer]]["animations"][i], characters.data[mariocharacter[skinningplayer]]["small"]["idle"][3], (34+46+v.smalloffsetX*2)*scale, (32+32-v.smalloffsetY*2)*scale, 0, scale*2, scale*2, v.smallquadcenterX, v.smallquadcenterY)
				end
			end
			
			--character
			if optionsselection == 3 then
				love.graphics.setColor(0, 0, 0, 200)
				love.graphics.rectangle("fill", 240*scale, 41*scale, 95*scale, 41*scale)
				love.graphics.setColor(255, 255, 255)
				properprint("press m to|open your|characters|folder", 241*scale, 43*scale)

				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("{", 64*scale, 56*scale)
			properprint("}", 112*scale, 56*scale)
			properprint(characters.data[mariocharacter[skinningplayer]].name, (118-#characters.data[mariocharacter[skinningplayer]].name*4)*scale, 80*scale)
			
			--hat
			offsets = customplayerhatoffsets(mariocharacter[skinningplayer], "hatoffsets", "idle") or hatoffsets["idle"]
			if v.hats then
				if #mariohats[skinningplayer] > 1 or mariohats[skinningplayer][1] ~= 1 then
					local yadd = 0
					for i = 1, #mariohats[skinningplayer] do
						love.graphics.setColor(255, 255, 255)
						love.graphics.draw(hat[mariohats[skinningplayer][i]].graphic, hat[mariohats[skinningplayer][i]].quad[1], (80+v.smalloffsetX*2)*scale, (64-v.smalloffsetY*2)*scale, 0, scale*2, scale*2, v.smallquadcenterX - hat[mariohats[skinningplayer][i]].x + offsets[1], v.smallquadcenterY - hat[mariohats[skinningplayer][i]].y + offsets[2] + yadd)
						yadd = yadd + hat[mariohats[skinningplayer][i]].height
					end
				elseif #mariohats[skinningplayer] == 1 then
					love.graphics.setColor(mariocolors[skinningplayer][1])
					love.graphics.draw(hat[mariohats[skinningplayer][1]].graphic, hat[mariohats[skinningplayer][1]].quad[1], (80+v.smalloffsetX*2)*scale, (64-v.smalloffsetY*2)*scale, 0, scale*2, scale*2, v.smallquadcenterX - hat[mariohats[skinningplayer][1]].x + offsets[1], v.smallquadcenterY - hat[mariohats[skinningplayer][1]].y + offsets[2])
				end
			end
			
			love.graphics.setColor(255, 255, 255, 255)
			love.graphics.draw(characters.data[mariocharacter[skinningplayer]]["animations"][0], characters.data[mariocharacter[skinningplayer]]["small"]["idle"][3], (34+46+v.smalloffsetX*2)*scale, (32+32-v.smalloffsetY*2)*scale, 0, scale*2, scale*2, v.smallquadcenterX, v.smallquadcenterY)
			
			--PREVIEW PORTALS WITH FALLING MARIO BECAUSE I CAN AND IT LOOKS RAD
			love.graphics.setScissor(142*scale, 42*scale, 32*scale, 32*scale)
			
			for j = 1, #v.colorables do
				for i = 1, #v.colorables do
					love.graphics.setColor(unpack(mariocolors[skinningplayer][i]))
					love.graphics.draw(characters.data[mariocharacter[skinningplayer]]["animations"][i], characters.data[mariocharacter[skinningplayer]]["small"]["jump"][3], (152+v.smalloffsetX)*scale, (2+((j-1)*32)+infmarioY-v.smalloffsetY)*scale, infmarioR, scale, scale, v.smallquadcenterX, v.smallquadcenterY)
				end
				love.graphics.setColor(255, 255, 255, 255)
				love.graphics.draw(characters.data[mariocharacter[skinningplayer]]["animations"][0], characters.data[mariocharacter[skinningplayer]]["small"]["jump"][3], (152+v.smalloffsetX)*scale, (2+((j-1)*32)+infmarioY-v.smalloffsetY)*scale, infmarioR, scale, scale, v.smallquadcenterX, v.smallquadcenterY)
			end
			
			local portalframe = portalanimation
			
			love.graphics.setColor(255, 255, 255, 80 - math.abs(portalframe-3)*10)
			love.graphics.draw(portalglowimg, 174*scale, 59*scale, math.pi, scale, scale)
			love.graphics.draw(portalglowimg, 142*scale, 57*scale, 0, scale, scale)
			
			love.graphics.setColor(unpack(portalcolor[skinningplayer][1]))
			love.graphics.draw(portalimg, portalquad[portalframe], 174*scale, 46*scale, math.pi, scale, scale)
			love.graphics.setColor(unpack(portalcolor[skinningplayer][2]))
			love.graphics.draw(portalimg, portalquad[portalframe], 142*scale, 70*scale, 0, scale, scale)
			
			love.graphics.setScissor()
			
			--HAT
			if optionsselection == 4 then
				if mariocharacter[skinningplayer] and not characters.data[mariocharacter[skinningplayer]].hats then
					love.graphics.setColor(150, 150, 150, 255)
				else
					love.graphics.setColor(255, 255, 255, 255)
				end
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			if mariocharacter[skinningplayer] and not characters.data[mariocharacter[skinningplayer]].hats then
				properprint("hat: disabled", (66)*scale, 90*scale)
			elseif mariohats[skinningplayer][1] == nil then
				properprint("hat: none", (83)*scale, 90*scale)
			else
				properprint("hat: " .. mariohats[skinningplayer][1], (99-string.len(mariohats[skinningplayer][1])*4)*scale, 90*scale)
			end

			if v.colorables then
				if optionsselection == 5 then
					love.graphics.setColor(255, 255, 255, 255)
				else
					love.graphics.setColor(100, 100, 100, 255)
				end
				
				--NEW SKIN CUSTOMIZATION
				local v = characters.data[mariocharacter[skinningplayer]]
				properprint("{ " .. v.colorables[colorsetedit] .. " }", 120*scale-string.len("{ " .. v.colorables[colorsetedit] .. " }")*4*scale, 105*scale)
				
				if optionsselection > 5 and optionsselection < 9 then
					love.graphics.setColor(255, 255, 255, 255)
					love.graphics.rectangle("fill", 39*scale, 114*scale + (optionsselection-6)*10*scale, 142*scale, 10*scale)
				end
			
				love.graphics.setColor(100, 0, 0)
				properprint("r", 40*scale, (116)*scale)
				love.graphics.setColor(255, 0, 0)	
				properprint("r", 39*scale, (115)*scale)
				
				love.graphics.setColor(0, 100, 0)
				properprint("g", 40*scale, (126)*scale)
				love.graphics.setColor(0, 255, 0)	
				properprint("g", 39*scale, (125)*scale)
				
				love.graphics.setColor(0, 0, 100)
				properprint("b", 40*scale, (136)*scale)
				love.graphics.setColor(0, 0, 255)	
				properprint("b", 39*scale, (135)*scale)
				
				love.graphics.setColor(100, 0, 0)
				love.graphics.rectangle("fill", 51*scale, (116)*scale, math.floor(129*scale * (mariocolors[skinningplayer][colorsetedit][1]/255)), 7*scale)
				love.graphics.setColor(255, 0, 0)
				love.graphics.rectangle("fill", 50*scale, (115)*scale, math.floor(129*scale * (mariocolors[skinningplayer][colorsetedit][1]/255)), 7*scale)
				
				love.graphics.setColor(100, 100, 100)
				local s = math.floor(mariocolors[skinningplayer][colorsetedit][1])
				properprint(s, 200*scale-string.len(s)*4*scale, 116*scale)
				
				love.graphics.setColor(0, 100, 0)
				love.graphics.rectangle("fill", 51*scale, (126)*scale, math.floor(129*scale * (mariocolors[skinningplayer][colorsetedit][2]/255)), 7*scale)
				love.graphics.setColor(0, 255, 0)
				love.graphics.rectangle("fill", 50*scale, (125)*scale, math.floor(129*scale * (mariocolors[skinningplayer][colorsetedit][2]/255)), 7*scale)
				
				love.graphics.setColor(100, 100, 100)
				local s = math.floor(mariocolors[skinningplayer][colorsetedit][2])
				properprint(s, 200*scale-string.len(s)*4*scale, 126*scale)
				
				love.graphics.setColor(0, 0, 100)
				love.graphics.rectangle("fill", 51*scale, (136)*scale, math.floor(129*scale * (mariocolors[skinningplayer][colorsetedit][3]/255)), 7*scale)
				love.graphics.setColor(0, 0, 255)
				love.graphics.rectangle("fill", 50*scale, (135)*scale, math.floor(129*scale * (mariocolors[skinningplayer][colorsetedit][3]/255)), 7*scale)
				
				love.graphics.setColor(100, 100, 100)
				local s = math.floor(mariocolors[skinningplayer][colorsetedit][3])
				properprint(s, 200*scale-string.len(s)*4*scale, 136*scale)
			end
			
			--[[love.graphics.setColor(255, 255, 255, 255)
			--WHITE BACKGROUND FOR RGB BARS
			
			if optionsselection > 4 and optionsselection < 14 then
				love.graphics.rectangle("fill", 69*scale, 89*scale + math.mod(optionsselection-5, 3)*10*scale + math.floor((optionsselection-5)/3)*14*scale, 142*scale, 10*scale)
			end
			
			if math.floor((optionsselection-2)/3) == 1 then
				love.graphics.setColor(255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100)
			end
			
			properprint("hat", 35*scale, 90*scale)
			
			if math.floor((optionsselection-2)/3) == 2 then
				love.graphics.setColor(255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100)
			end
			
			properprint("hair", 31*scale, 114*scale)
			
			if math.floor((optionsselection-2)/3) == 3 then
				love.graphics.setColor(255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100)
			end
			
			properprint("skin", 31*scale, 138*scale)
			for i = 1, 3 do
				if math.floor((optionsselection-2)/3) == i then
					love.graphics.setColor(100, 0, 0)
					properprint("r", 70*scale, (91+(i-1)*14)*scale)
					love.graphics.setColor(255, 0, 0)	
					properprint("r", 69*scale, (90+(i-1)*14)*scale)
					
					love.graphics.setColor(0, 100, 0)
					properprint("g", 70*scale, (101+(i-1)*14)*scale)
					love.graphics.setColor(0, 255, 0)	
					properprint("g", 69*scale, (100+(i-1)*14)*scale)
					
					love.graphics.setColor(0, 0, 100)
					properprint("b", 70*scale, (111+(i-1)*14)*scale)
					love.graphics.setColor(0, 0, 255)	
					properprint("b", 69*scale, (110+(i-1)*14)*scale)
				end
			end
			
			for j = 1, 3 do
				if math.floor((optionsselection-2)/3) == j then
					love.graphics.setColor(100, 0, 0)
					love.graphics.rectangle("fill", 81*scale, (91+(j-1)*14)*scale, math.floor(129*scale * (mariocolors[skinningplayer][j][1]/255)), 7*scale)
					love.graphics.setColor(255, 0, 0)
					love.graphics.rectangle("fill", 80*scale, (90+(j-1)*14)*scale, math.floor(129*scale * (mariocolors[skinningplayer][j][1]/255)), 7*scale)
					
					love.graphics.setColor(0, 100, 0)
					love.graphics.rectangle("fill", 81*scale, (101+(j-1)*14)*scale, math.floor(129*scale * (mariocolors[skinningplayer][j][2]/255)), 7*scale)
					love.graphics.setColor(0, 255, 0)
					love.graphics.rectangle("fill", 80*scale, (100+(j-1)*14)*scale, math.floor(129*scale * (mariocolors[skinningplayer][j][2]/255)), 7*scale)
					
					love.graphics.setColor(0, 0, 100)
					love.graphics.rectangle("fill", 81*scale, (111+(j-1)*14)*scale, math.floor(129*scale * (mariocolors[skinningplayer][j][3]/255)), 7*scale)
					love.graphics.setColor(0, 0, 255)
					love.graphics.rectangle("fill", 80*scale, (110+(j-1)*14)*scale, math.floor(129*scale * (mariocolors[skinningplayer][j][3]/255)), 7*scale)
				end
			end]]
			
			--Portalhues
			--hue
			local alpha = 100
			
			if characters.data[mariocharacter[skinningplayer]].colorables then
				if optionsselection == 9 then
					alpha = 255
				end
			else
				if optionsselection == 5 then
					alpha = 255
				end
			end
			
			love.graphics.setColor(255, 255, 255, alpha)
			
			properprint("portal 1 color:", 31*scale, 150*scale)
			
			love.graphics.draw(huebarimg, 32*scale, 170*scale, 0, scale, scale)
			
			--marker
			love.graphics.setColor(unpack(portalcolor[skinningplayer][1]))
			love.graphics.rectangle("fill", math.floor(29 + (portalhues[skinningplayer][1])*178)*scale, 161*scale, 7*scale, 6*scale)
			love.graphics.setColor(alpha, alpha, alpha)
			love.graphics.draw(huebarmarkerimg, math.floor(28 + (portalhues[skinningplayer][1])*178)*scale, 160*scale, 0, scale, scale)
			
			alpha = 100
			if characters.data[mariocharacter[skinningplayer]].colorables then
				if optionsselection == 10 then
					alpha = 255
				end
			else
				if optionsselection == 6 then
					alpha = 255
				end
			end
			
			love.graphics.setColor(255, 255, 255, alpha)
			
			properprint("portal 2 color:", 31*scale, 180*scale)
			
			love.graphics.draw(huebarimg, 32*scale, 200*scale, 0, scale, scale)
			
			--marker
			love.graphics.setColor(unpack(portalcolor[skinningplayer][2]))
			love.graphics.rectangle("fill", math.floor(29 + (portalhues[skinningplayer][2])*178)*scale, 191*scale, 7*scale, 6*scale)
			love.graphics.setColor(alpha, alpha, alpha)
			love.graphics.draw(huebarmarkerimg, math.floor(28 + (portalhues[skinningplayer][2])*178)*scale, 190*scale, 0, scale, scale)
		elseif optionstab == 3 then
			if optionsselection == 2 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			properprint("scale:", 30*scale, 40*scale)
			if not resizable then
				properprint("*" .. tostring(scale), (180-(string.len(scale)+1)*8)*scale, 40*scale)
			else
				properprint("resizable", (180-string.len("resizable")*8)*scale, 40*scale)
			end

			if optionsselection == 3 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			properprint("letterbox:", 30*scale, 50*scale)
			if letterboxfullscreen then
				properprint("on", (180-string.len("on")*8)*scale, 50*scale)
			else
				properprint("off", (180-string.len("off")*8)*scale, 50*scale)
			end
			
			if optionsselection == 4 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("shader1:", 30*scale, 65*scale)
			if shaderssupported == false then
				properprint("unsupported", (180-string.len("unsupported")*8)*scale, 65*scale)
			else
				properprint(string.lower(shaderlist[currentshaderi1]), (180-string.len(shaderlist[currentshaderi1])*8)*scale, 65*scale)
			end
			
			if optionsselection == 5 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			properprint("shader2:", 30*scale, 75*scale)
			if shaderssupported == false then
				properprint("unsupported", (180-string.len("unsupported")*8)*scale, 75*scale)
			else
				properprint(string.lower(shaderlist[currentshaderi2]), (180-string.len(shaderlist[currentshaderi2])*8)*scale, 75*scale)
			end
			
			love.graphics.setColor(100, 100, 100, 255)
			properprint("shaders will really", 30*scale, 90*scale)
			properprint("reduce performance!", 30*scale, 100*scale)
			
			if optionsselection == 6 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			properprint("volume:", 30*scale, 115*scale)
			drawrectangle(90, 118, 90, 1)
			drawrectangle(90, 115, 1, 7)
			drawrectangle(179, 115, 1, 7)
			love.graphics.draw(volumesliderimg, math.floor((89+89*volume)*scale), 115*scale, 0, scale, scale)
			
			if optionsselection == 7 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("reset default maps", 30*scale, 130*scale)
			
			if optionsselection == 8 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("reset all settings", 30*scale, 145*scale)
			
			if optionsselection == 9 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("vsync:", 30*scale, 160*scale)
			if vsync then
				properprint("on", (180-16)*scale, 160*scale)
			else
				properprint("off", (180-24)*scale, 160*scale)
			end
			
			if optionsselection == 10 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("mappack folder:", 30*scale, 175*scale)
			if mappackfolder == "mappacks" then
				properprint("mappacks", (180-24)*scale, 175*scale)
			else
				properprint("alesans_e..", (180-28)*scale, 175*scale)
			end
			
			if optionsselection == 11 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end


			love.graphics.setColor(255, 255, 255, 255)
			properprint("a99e : ace" .. VERSIONSTRING, (236-(#("a99e : ace" .. VERSIONSTRING)*8))*scale, 207*scale)
		elseif optionstab == 4 then
			love.graphics.setColor(255, 255, 255, 255)
			if not gamefinished then
				properprint("unlock this by completing", 30*scale, 40*scale)
				properprint("the original levels pack!", 30*scale, 50*scale)
			else
				properprint("have fun with these!", 30*scale, 45*scale)
			end
			
			if optionsselection == 2 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("mode:", 30*scale, 65*scale)
			properprint("{" .. playertype .. "}", (180-(string.len(playertype)+2)*8)*scale, 65*scale)
			
			if optionsselection == 3 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("knockback:", 30*scale, 80*scale)
			if portalknockback then
				properprint("on", (180-16)*scale, 80*scale)
			else
				properprint("off", (180-24)*scale, 80*scale)
			end
			
			if optionsselection == 4 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("bullettime:", 30*scale, 95*scale)
			if bullettime then
				properprint("on", (180-16)*scale, 95*scale)
			else
				properprint("off", (180-24)*scale, 95*scale)
			end
			
			if optionsselection == 5 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("huge mario:", 30*scale, 110*scale)
			if bigmario then
				properprint("on", (180-16)*scale, 110*scale)
			else
				properprint("off", (180-24)*scale, 110*scale)
			end
			
			if optionsselection == 6 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("goomba attack:", 30*scale, 125*scale)
			if goombaattack then
				properprint("on", (180-16)*scale, 125*scale)
			else
				properprint("off", (180-24)*scale, 125*scale)
			end
			
			if optionsselection == 7 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("sonic rainboom:", 30*scale, 140*scale)
			if sonicrainboom then
				properprint("on", (180-16)*scale, 140*scale)
			else
				properprint("off", (180-24)*scale, 140*scale)
			end
			
			if optionsselection == 8 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("playercollision:", 30*scale, 155*scale)
			if playercollisions then
				properprint("on", (180-16)*scale, 155*scale)
			else
				properprint("off", (180-24)*scale, 155*scale)
			end
			
			if optionsselection == 9 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("infinite time:", 30*scale, 170*scale)
			if infinitetime then
				properprint("on", (180-16)*scale, 170*scale)
			else
				properprint("off", (180-24)*scale, 170*scale)
			end
			
			if optionsselection == 10 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("infinite lives:", 30*scale, 185*scale)
			if infinitelives then
				properprint("on", (180-16)*scale, 185*scale)
			else
				properprint("off", (180-24)*scale, 185*scale)
			end
			
			if optionsselection == 11 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("dark mode:", 30*scale, 200*scale)
			if darkmode then
				properprint("on", (180-16)*scale, 200*scale)
			else
				properprint("off", (180-24)*scale, 200*scale)
			end

			--[[if optionsselection == 12 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("page:", 30*scale, 215*scale)
			properprint("{" .. cheatspage .. "}", (180-(string.len(cheatspage)+2)*8)*scale, 215*scale)]]
		elseif optionstab == 5 then
			love.graphics.setColor(255, 255, 255, 255)
			if not gamefinished then
				properprint("unlock this by completing", 30*scale, 40*scale)
				properprint("the original levels pack!", 30*scale, 50*scale)
			else
				properprint("have fun with these!", 30*scale, 45*scale)
			end

			if optionsselection == 2 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("3d mode:", 30*scale, 65*scale)
			if _3DMODE then
				properprint("on", (180-16)*scale, 65*scale)
			else
				properprint("off", (180-24)*scale, 65*scale)
			end

			if optionsselection == 3 then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(100, 100, 100, 255)
			end
			
			properprint("corrupter:", 30*scale, 80*scale)
			if _CORRUPTER then
				properprint("on", (180-16)*scale, 80*scale)
			else
				properprint("off", (180-24)*scale, 80*scale)
			end

			if _CORRUPTER then
				if optionsselection == 4 then
					love.graphics.setColor(255, 255, 255, 255)
				else
					love.graphics.setColor(100, 100, 100, 255)
				end

				properprint("mode:", 30*scale, 95*scale)
				if _CORRUPTER_MODE then
					properprint("error 404", (180-72)*scale, 95*scale)
				else
					properprint("stable", (180-48)*scale, 95*scale)
				end
			end
		end
	end
	love.graphics.translate(0, yoffset*scale)
end

function loadbackground(background)
	loadanimatedtiles()
	enemies_load()
	loadcustomsprites()
	loadcustomtext()
	loadcustomsounds()
	loadcustommusic()
	loadcustombackgrounds()
	getmappacklevels()
	titleframe = 1
	titletimer = 0

	--dropshadow
	if mappackselection and mappackdropshadow then
		dropshadow = mappackdropshadow[mappackselection]
	end

	--BLOCKTOGGLE STUFF
	solidblockperma = {false, false, false, false}
	collectables = {} --[marioworld-mariolevel-mariosublevel][x-y]
	collectableslist = {{},{},{},{},{},{},{},{},{},{}}
	collectablescount = {0,0,0,0,0,0,0,0,0,0}
	animationnumbers = {}
	
	if love.filesystem.exists(mappackfolder .. "/" .. mappack .. "/" .. background) == false then
	
		map = {}
		mapwidth = width
		originalmapwidth = mapwidth
		mapheight = 15
		for x = 1, width do
			map[x] = {}
			for y = 1, 13 do
				map[x][y] = {1}
			end
		
			for y = 14, mapheight do
				map[x][y] = {2}
			end
		end
		startx = 3
		starty = 13
		custombackground = false
		backgroundi = 1
		love.graphics.setBackgroundColor(backgroundcolor[backgroundi])
		portalgun = true
		portalguni = 1
		levelversion = VERSION
	else
		local s = love.filesystem.read( mappackfolder .. "/" .. mappack .. "/" .. background )
		local s2 = s:split(";")
		
		--remove custom sprites
		for i = smbtilecount+portaltilecount+1, #tilequads do
			tilequads[i] = nil
		end
		
		for i = smbtilecount+portaltilecount+1, #rgblist do
			rgblist[i] = nil
		end
		
		--add custom tiles
		if love.filesystem.exists(mappackfolder .. "/" .. mappack .. "/tiles.png") then
			customtiles = true
			customtilesimg = love.graphics.newImage(mappackfolder .. "/" .. mappack .. "/tiles.png")
			local imgwidth, imgheight = customtilesimg:getWidth(), customtilesimg:getHeight()
			local width = math.floor(imgwidth/17)
			local height = math.floor(imgheight/17)
			local imgdata = love.image.newImageData(mappackfolder .. "/" .. mappack .. "/tiles.png")
			
			for y = 1, height do
				for x = 1, width do
					table.insert(tilequads, quad:new(customtilesimg, imgdata, x, y, imgwidth, imgheight))
					local r, g, b = getaveragecolor(imgdata, x, y)
					table.insert(rgblist, {r, g, b})
				end
			end
			customtilecount = width*height
		else
			customtiles = false
			customtilecount = 0
		end

		local files = love.filesystem.getDirectoryItems(mappackfolder .. "/" .. mappack .. "/tiles")
		if files ~= 0 then
			modcustomtiles = #files
			modcustomtilesimg = {}
			modcustomtilecount = {}
			for i = 1, modcustomtiles do
				modcustomtilesimg[i] = love.graphics.newImage(mappackfolder .. "/" .. mappack .. "/tiles/" .. files[i])
				local imgwidth, imgheight = modcustomtilesimg[i]:getWidth(), modcustomtilesimg[i]:getHeight()
				local width = math.floor(imgwidth/17)
				local height = math.floor(imgheight/17)
				local imgdata = love.image.newImageData(mappackfolder .. "/" .. mappack .. "/tiles/" .. files[i])
				
				for y = 1, height do
					for x = 1, width do
						table.insert(tilequads, quad:new(modcustomtilesimg[i], imgdata, x, y, imgwidth, imgheight))
						local r, g, b = getaveragecolor(imgdata, x, y)
						table.insert(rgblist, {r, g, b})
					end
				end
				modcustomtilecount[i] = (modcustomtilecount[i-1] or 0) + width*height
			end
		else
			modcustomtiles = false
			modcustomtilecount = {0}
		end
			
		--MAP ITSELF
		local t = s2[1]:split(",")
		
		mapheight = 15
		if s2[2] and s2[2]:sub(1,7) == "height=" then
			mapheight = tonumber(s2[2]:sub(8,-1)) or 15
		elseif love.filesystem.exists(mappackfolder .. "/" .. mappack .. "/heights/1-1_0.txt") then
			local s11 = love.filesystem.read(mappackfolder .. "/" .. mappack .. "/heights/" .. marioworld .. "-" .. mariolevel .. "_" .. mariosublevel .. ".txt")
			mapheight = tonumber(s11)
		end
		
		if math.mod(#t, mapheight) ~= 0 then
			print("Incorrect number of entries: " .. #t)
			return false
		end

		mapwidth = #t/mapheight
		originalmapwidth = mapwidth
		startx = 3
		starty = 13
		
		map = {} --foreground map
		bmap_on = false
		local r --map[x][y]
		local nr --map[x][y][1]
		
		for y = 1, mapheight do
			for x = 1, mapwidth do
				if y == 1 then
					map[x] = {}
				end
				
				map[x][y] = t[(y-1)*(#t/mapheight)+x]:split("-")
				
				r = map[x][y]
				
				if #r > 1 then
					if tonumber(r[2]) and entityquads[tonumber(r[2])] and entityquads[tonumber(r[2])].t == "spawn" then
						startx = x
						starty = y
					end
				end

				nr = tonumber(r[1])
				if not nr then
					--background tile
					if not bmap_on then
						bmap_on = true
					end
					local tiles = r[1]:split("~")
					r[1] = tonumber(tiles[1])
					map[x][y]["back"] = tonumber(tiles[2])
				elseif (nr > smbtilecount+portaltilecount+customtilecount+modcustomtilecount[modcustomtiles] and nr <= 90000) or nr > 90000+animatedtilecount then
					--tile doesn't exist
					r[1] = 1
				end
			end
		end
		
		--get background color and portal gun
		custombackground = false
		customforeground = false
		portalgun = true
		portalguni = 1
		levelversion = false
		nofunallowed = nil
		
		for i = 2, #s2 do
			s3 = s2[i]:split("=")
			if s3[1] == "background" then
				if tonumber(s3[2]) ~= nil then
					local backgroundi = tonumber(s3[2])
					love.graphics.setBackgroundColor(backgroundcolor[backgroundi])
				else
					local s4 = s3[2]:split(",")
					local backgroundrgbon = true
					local backgroundrgb = {tonumber(s4[1]), tonumber(s4[2]), tonumber(s4[3])}
					love.graphics.setBackgroundColor(unpack(backgroundrgb))
				end
			elseif s3[1] == "spriteset" then
				spriteset = tonumber(s3[2])
			elseif s3[1] == "custombackground" or s3[1] == "portalbackground" then
				custombackground = (s3[2] or true)
			elseif s3[1] == "customforeground" then
				customforeground = (s3[2] or true)
			elseif s3[1] == "noportalgun" then
				portalgun = false
				portalguni = 2
			elseif s3[1] == "portalguni" then
				portalguni = tonumber(s3[2])
				if portalguni == 2 then
					portalgun = false
				else
					portalgun = true
				end
			elseif s3[1] == "nofunallowed" then
				nofunallowed = true
			elseif s3[1] == "vs" then
				local vs = tonumber(s3[2])
				if vs and vs > VERSION then
					if math.abs(vs-VERSION) < 0.1 then
						notice.new("This map was made for a|new patch of mari0 ae|download the new version", notice.white, 4.5)
					else
						notice.new("This map was made for a|newer version of mari0 ae|download the new version!", notice.red, 8)
					end
				end
			end
		end
		if custombackground then
			loadcustombackground(custombackground)
		end
		if customforeground then
			loadcustomforeground(customforeground)
		end
	end
end

function updatescroll()
	--check if current focus is completely on screen
	if inrange(mappackselection, 1+mappackscroll, 3+mappackscroll, true) == false then
		if mappackselection < 1+mappackscroll then --above window
			mappackscroll = mappackselection-1
		else
			mappackscroll = mappackselection-3.233
		end
	end
end

function onlineupdatescroll()
	--check if current focus is completely onscreen
	if inrange(onlinemappackselection, 1+onlinemappackscroll, 3+onlinemappackscroll, true) == false then
		if onlinemappackselection < 1+onlinemappackscroll then --above window
			onlinemappackscroll = onlinemappackselection-1
		else
			onlinemappackscroll = onlinemappackselection-3.233
		end
	end
end

function mappacks()
	opendlcbutton.active = false
	if mappackhorscroll == 0 then
		loadmappacks()
	elseif mappackhorscroll == 1 then
		if (not onlinemappacklist) or onlinemappacklisterror then
			loadonlinemappacks()
		end
		opendlcbutton.active = true
	elseif mappackhorscroll == 2 then
		loaddailychallenge()
	end
end

function loadmappacks()
	mappacktype = "local"
	mappacklist = love.filesystem.getDirectoryItems( mappackfolder )

	if onlinedlc then
		local zips = love.filesystem.getDirectoryItems("alesans_entities/onlinemappacks")
		if #zips > 0 then
			for j, w in pairs(zips) do
				if not love.filesystem.exists(mappackfolder .. "/" .. w) then
					mountmappack(w)
				end
			end
		end
	end
	
	local delete = {}
	for i = 1, #mappacklist do
		if ((not onlinedlc) and (love.filesystem.exists("alesans_entities/onlinemappacks/" .. mappacklist[i] .. ".zip") 
		or love.filesystem.exists(mappackfolder .. "/" .. mappacklist[i] .. "/version.txt"))) 
		or not love.filesystem.exists(mappackfolder .. "/" .. mappacklist[i] .. "/settings.txt") then
			table.insert(delete, i)
		end
	end
	
	table.sort(delete, function(a,b) return a>b end)
	
	for i, v in pairs(delete) do
		table.remove(mappacklist, v) --remove
	end
	
	mappackicon = {}
	
	--get info
	mappackname = {}
	mappackauthor = {}
	mappackdescription = {}
	mappackbackground = {}
	mappackdropshadow = {}
	
	mappacklist[#mappacklist+1] = "custom_mappack"
	mappackname[#mappacklist] = "{new mappack}"
	mappackauthor[#mappacklist] = "you"
	mappackdescription[#mappacklist] = "create a mappack from scratch withthis!"
	mappackdropshadow[#mappacklist] = false
	
	--get the current cursorposition
	for i = 1, #mappacklist do
		if mappacklist[i] == mappack then
			mappackselection = i
		end
	end
	
	mappack = mappacklist[mappackselection]
	
	--load background
	--[[if mappackbackground[mappackselection] then
		loadbackground(mappackbackground[mappackselection] .. ".txt")
	else
		loadbackground("1-1.txt")
	end]]
	
	if mappacklistthread then
		mappacklistthreadchannelin:clear()
		--mappacklistthreadchannelin:push({"stop"})
	end
	mappacklistthreadn = 1
	mappacklistthreadchannelin = love.thread.getChannel("mappackin")
	mappacklistthreadchannelout = love.thread.getChannel("mappackout")
	mappacklistthread = love.thread.newThread("mappacklistthread.lua")
	mappacklistthreadchannelin:push({mappackfolder .. "/" .. mappacklist[mappacklistthreadn], love.filesystem.getIdentity()})
	mappacklistthread:start()
	
	mappackscroll = 0
	updatescroll()
	mappackscrollsmooth = mappackscroll
end

function loadonlinemappacks()
	mappacktype = "online"
	if onlinedlc then
		onlinemappacklisterror = nil
		local s, iconlink = downloadmappackinfo()
		if not s then
			onlinemappackscroll = 0
			onlineupdatescroll()
			onlinemappackscrollsmooth = onlinemappackscroll
			onlinemappacklist = {1}
			onlinemappackname = {"error"}
			onlinemappackauthor = {"error"}
			onlinemappackdescription = {"error"}
			onlinemappackbackground = {"1-1"}
			onlinemappackurl = {"error"}
			onlinemappackfilename = {"error"}
			onlinemappacksize = {"error"}
			onlinemappacklisterror = true
			return false
		end
		
		--get info
		onlinemappackname = {}
		onlinemappackauthor = {}
		onlinemappackdescription = {}
		onlinemappackbackground = {}
		onlinemappackurl = {}
		onlinemappackfilename = {}
		onlinemappacksize = {} --can be byte number, or the string "url"
		onlinemappackiconi = {}
		onlinemappackicon = false
		onlinemappackiconquad = {}
		
		local onlinemappackinfo = s:split(";")
		onlinemappacklist = s:split(";")
		
		for i = 1, #onlinemappackinfo do
			onlinemappackname[i] = "error"
			onlinemappackauthor[i] = "error"
			onlinemappackdescription[i] = "error"
			onlinemappackbackground[i] = "1-1"
			onlinemappackurl[i] = "error"
			onlinemappackfilename[i] = "error"
			onlinemappacksize[i] = "error"
			onlinemappackiconi[i] = false
			
			local s1 = onlinemappackinfo[i]:split("~")
			for j = 1, #s1 do
				if j == 1 then
					onlinemappackurl[i] = s1[j]
				elseif j == 2 then
					onlinemappackfilename[i] = s1[j]
				elseif j == 3 then
					onlinemappackname[i] = s1[j]
				elseif j == 4 then
					onlinemappackauthor[i] = s1[j]
				elseif j == 5 then
					onlinemappackdescription[i] = s1[j]
				elseif j == 6 then
					if tonumber(s1[j]) then
						onlinemappacksize[i] = tonumber(s1[j])
					else
						onlinemappacksize[i] = s1[j]
					end
				elseif j == 7 then
					onlinemappackiconi[i] = tonumber(s1[j])
				end
			end
		end
		
		if iconlink then
			onlinemappackiconchannel = love.thread.getChannel("command")
			onlinemappackiconchannel2 = love.thread.getChannel("data")
			onlinemappackiconthread = love.thread.newThread("onlineimage.lua")
			onlinemappackiconchannel:push(iconlink)
			onlinemappackiconthread:start()
		end
		
		onlinemappackscroll = 0
		onlineupdatescroll()
		onlinemappackscrollsmooth = onlinemappackscroll
		return true
	else
		--"download" mappacks
		downloadingmappack = true
		love.graphics.clear(love.graphics.getBackgroundColor())
		if resizable then
			love.graphics.scale(winwidth/(width*16*scale), winheight/(224*scale))
		end
		menu_draw()
		love.graphics.present()

		--copy included zip dlcs to save folder (because of course you can't mount from source directory :/)
		local zips = love.filesystem.getDirectoryItems("alesans_entities/dlc_mappacks")
		if #zips > 0 then
			for j, w in pairs(zips) do
				if not love.filesystem.exists("alesans_entities/onlinemappacks/" .. w) then
					local filedata = love.filesystem.newFileData("alesans_entities/dlc_mappacks/" .. w)
					love.filesystem.write("alesans_entities/onlinemappacks/" .. w, filedata)
					if j == 1 and not love.filesystem.exists("alesans_entities/onlinemappacks/" .. w) then
						break
					end
				end
			end
		end

		--mount dlc zip files
		local zips = love.filesystem.getDirectoryItems("alesans_entities/onlinemappacks")
		if #zips > 0 then
			for j, w in pairs(zips) do
				mountmappack(w)
			end
		end

		onlinemappacklist = love.filesystem.getDirectoryItems( mappackfolder )
		
		local delete = {}
		for i = 1, #onlinemappacklist do
			if (not (love.filesystem.exists("alesans_entities/onlinemappacks/" .. onlinemappacklist[i] .. ".zip") or love.filesystem.exists(mappackfolder .. "/" .. onlinemappacklist[i] .. "/version.txt"))) or (not love.filesystem.exists( mappackfolder .. "/" .. onlinemappacklist[i] .. "/settings.txt")) then
				table.insert(delete, i)
			end
		end
		
		table.sort(delete, function(a,b) return a>b end)
		
		for i, v in pairs(delete) do
			table.remove(onlinemappacklist, v) --remove
		end

		downloadingmappack = false
		
		onlinemappackicon = {}
		
		--get info
		onlinemappackname = {}
		onlinemappackauthor = {}
		onlinemappackdescription = {}
		onlinemappackbackground = {}
		
		for i = 1, #onlinemappacklist do
			if love.filesystem.exists( mappackfolder .. "/" .. onlinemappacklist[i] .. "/icon.png" ) then
				onlinemappackicon[i] = love.graphics.newImage(mappackfolder .. "/" .. onlinemappacklist[i] .. "/icon.png")
			else
				onlinemappackicon[i] = nil
			end
			
			onlinemappackauthor[i] = nil
			onlinemappackdescription[i] = nil
			onlinemappackbackground[i] = nil
			if love.filesystem.exists( mappackfolder .. "/" .. onlinemappacklist[i] .. "/settings.txt" ) then		
				local s = love.filesystem.read( mappackfolder .. "/" .. onlinemappacklist[i] .. "/settings.txt" )
				local s1 = s:split("\n")
				for j = 1, #s1 do
					local s2 = s1[j]:split("=")
					if s2[1] == "name" then
						onlinemappackname[i] = s2[2]
					elseif s2[1] == "author" then
						onlinemappackauthor[i] = s2[2]
					elseif s2[1] == "description" then
						onlinemappackdescription[i] = s2[2]
					elseif s2[1] == "background" then
						onlinemappackbackground[i] = s2[2]
					end
				end
			else
				onlinemappackname[i] = onlinemappacklist[i]
			end
		end
		
		--[[get the current cursorposition
		for i = 1, #onlinemappacklist do
			if onlinemappacklist[i] == mappack then
				onlinemappackselection = i
			end
		end
		
		if #onlinemappacklist >= 1 then
			mappack = onlinemappacklist[onlinemappackselection]
		end
		
		--load background
		if onlinemappackbackground[onlinemappackselection] then
			loadbackground(onlinemappackbackground[onlinemappackselection] .. ".txt")
		else
			loadbackground("1-1.txt")
		end]]
		
		onlinemappackscroll = 0
		onlineupdatescroll()
		onlinemappackscrollsmooth = onlinemappackscroll
	end
end

function loaddailychallenge()
	mappacktype = "daily_challenge"
	return true
end

function menu_keypressed(key, unicode)
	if gamestate == "menu" then
		if selectworldopen then
			if (key == "right" or key == "d") then
				local target = selectworldcursor+1
				while target <= #mappacklevels and not reachedworlds[mappack][target] do
					target = target + 1
				end
				if target <= #mappacklevels then
					selectworldcursor = target
				end
			elseif (key == "left" or key == "a") then
				local target = selectworldcursor-1
				while target > 0 and not reachedworlds[mappack][target] do
					target = target - 1
				end
				if target > 0 then
					selectworldcursor = target
				end
			elseif (key == "return" or key == "enter" or key == "kpenter" or key == " ") then
				selectworldopen = false
				game_load(selectworldcursor)
			elseif key == "escape" then
				selectworldopen = false
			end
			return
		end
		if (key == "up" or key == "w") then
			if continueavailable then
				if selection > 0 then
					selection = selection - 1
				end
			else
				if selection > 1 then
					selection = selection - 1
				end
			end
		elseif (key == "down" or key == "s") then
			if selection < 4 then
				selection = selection + 1
			end
		elseif (key == "return" or key == "enter" or key == "kpenter" or key == " ") then
			if selection == 0 then
				game_load(true)
			elseif selection == 1 then
				selectworld()
			elseif selection == 2 then
				if nofunallowed then
					notice.new("Creator disabled the editor.", notice.white, 2)
					return false
				end
				editormode = true
				players = 1
				playertype = "portal"
				playertypei = 1
				disablecheats()
				loadeditormetadata()
				game_load()
			elseif selection == 3 then
				gamestate = "mappackmenu"
				mappacks()
			elseif selection == 4 then
				gamestate = "options"
			end
		elseif key == "escape" then
			love.event.quit()
		elseif (key == "left" or key == "a") then
			if players > 1 then
				players = players - 1
			elseif players == 1 then
				onlinemenu_load()
			end
		elseif (key == "right" or key == "d") then
			players = players + 1
			if players > 4 then
				players = 4
			end
		end
	elseif gamestate == "mappackmenu" then
		if (key == "up" or key == "w") then
			if mappacktype == "local" then
				if mappackselection > 1 then
					mappackselection = mappackselection - 1
					updatescroll()
				end
			elseif mappacktype == "online" then
				if onlinemappackselection > 1 then
					onlinemappackselection = onlinemappackselection - 1
					
					onlineupdatescroll()
				end
			end
		elseif (key == "down" or key == "s") then
			if mappacktype == "local" then
				if mappackselection < #mappacklist then
					mappackselection = mappackselection + 1
					
					updatescroll()
				end
			elseif mappacktype == "online" then
				if onlinemappackselection < #onlinemappacklist then
					onlinemappackselection = onlinemappackselection + 1
					
					onlineupdatescroll()
				end
			end
		elseif mappacktype == "online" and (key == "return" or key == "enter" or key == "kenter" or key == " ") then
			if onlinedlc then
				local i = onlinemappackselection
				local onlinemappackerror = false
				--download mappack
				downloadingmappack = true
				love.graphics.clear(love.graphics.getBackgroundColor())
				if resizable then
					love.graphics.scale(winwidth/(width*16*scale), winheight/(224*scale))
				end
				menu_draw()
				love.graphics.present()
				
				if onlinemappackurl[i] ~= "error" then
					onlinemappackerror = not downloadmappack(onlinemappackurl[i], onlinemappackfilename[i] or "mappack.zip", onlinemappacksize[i])
					if onlinemappacksize[i] == "url" then
						--link
						if not onlinemappackerror then
							notice.new("Opened Download Link", notice.white, 2)
						else
							notice.new("Couldn't Open Link", notice.red, 2)
						end
					else
						if not onlinemappackerror then
							mountmappack(onlinemappackfilename[i] or "mappack.zip")
							loadmappacks()
							mappackhorscroll = 0
							mappacktype = "local"
							downloadedmappacks[i] = true
							onlineupdatescroll()
							notice.new("DLC downloaded!", notice.white, 2)
						else
							downloadedmappacks[i] = "false"
							notice.new("Download failed", notice.red, 2)
						end
					end
				else
					onlinemappackerror = true
					downloadedmappacks[i] = "false"
					notice.new("DLC not found", notice.red, 2)
				end
				downloadingmappack = false
			else
				--local dlc
				mappack = onlinemappacklist[onlinemappackselection]
				--load background
				if onlinemappackbackground[mappackselection] then
					loadbackground(onlinemappackbackground[onlinemappackselection] .. ".txt")
				else
					loadbackground("1-1.txt")
				end
				gamestate = "menu"
				saveconfig()
			end
		elseif mappacktype == "daily_challenge" and (key == "return" or key == "enter" or key == "kenter" or key == " ") then
			infinitetime = false
			game_load("dailychallenge")
		elseif key == "escape" or (key == "return" or key == "enter" or key == "kpenter" or key == " ") then
			--stop loading mappacks
			if mappacklistthread and mappacklistthread:isRunning() then
				mappacklistthreadchannelin:push({"stop"})
			end

			mappack = mappacklist[mappackselection]
			--load background					
			if mappackbackground[mappackselection] then
				loadbackground(mappackbackground[mappackselection] .. ".txt")
			else
				loadbackground("1-1.txt")
			end

			gamestate = "menu"
			saveconfig()
			if mappack == "custom_mappack" then
				createmappack()
			end
		elseif (key == "right" or key == "d") or (key == "left" or key == "a") then
			--change mappack selection tab
			if (key == "right" or key == "d") then
				mappackhorscroll = mappackhorscroll + 1
			else
				mappackhorscroll = mappackhorscroll - 1
			end
			if mappackhorscroll > 2 then
				mappackhorscroll = 0
			elseif mappackhorscroll < 0 then
				mappackhorscroll = 2
			end
			opendlcbutton.active = false
			if mappackhorscroll == 0 then
				loadmappacks()
			elseif mappackhorscroll == 1 then
				if (not onlinemappacklist) or onlinemappacklisterror then
					loadonlinemappacks()
				end
				mappacktype = "online"
				opendlcbutton.active = true
			elseif mappackhorscroll == 2 then
				loaddailychallenge()
			end
		elseif key == "m" then
			if not openSaveFolder( mappackfolder ) then
				savefolderfailed = true
			end
		end
	elseif gamestate == "onlinemenu" then
		if key == "escape" then
			guielements = {}
			gamestate = "menu"
		end
	elseif gamestate == "options" then
		if optionsselection == 1 then
			if (key == "left" or key == "a") then
				if optionstab > 1 then
					optionstab = optionstab - 1
				else
					optionstab = 5
				end
			elseif (key == "right" or key == "d") then
				if optionstab < 5 then
					optionstab = optionstab + 1
				else
					optionstab = 1
				end
			end
		elseif optionsselection == 2 then
			if (key == "left" or key == "a") then
				if optionstab == 2 or optionstab == 1 then
					if skinningplayer > 1 then
						skinningplayer = skinningplayer - 1
					end
				end
			elseif (key == "right" or key == "d") then
				if optionstab == 2 or optionstab == 1 then
					if skinningplayer < 4 then
						skinningplayer = skinningplayer + 1
						if players > #controls then
							loadconfig()
						end
					end
				end
			end
		end
		
		if (key == "return" or key == "enter" or key == "kpenter" or key == " ") then
			if optionstab == 1 then
				if optionsselection == 3 then
					if mouseowner == skinningplayer then
						mouseowner = 0
					else
						mouseowner = skinningplayer
					end
				elseif optionsselection > 3 then
					keypromptstart()
				end
			elseif optionstab == 3 then
				if optionsselection == 7 then
					reset_mappacks()
				elseif optionsselection == 8 then
					resetconfig()
				end
			end
		elseif (key == "down" or key == "s") then
			if optionstab == 1 then
				if skinningplayer ~= mouseowner then
					if optionsselection < 15 then
						optionsselection = optionsselection + 1
					else
						optionsselection = 1
					end
				else
					if optionsselection < 11 then
						optionsselection = optionsselection + 1
					else
						optionsselection = 1
					end
				end
			elseif optionstab == 2 then
				local limit = 6
				if characters.data[mariocharacter[skinningplayer]].colorables then
					limit = 10
				end

				if optionsselection < limit then
					optionsselection = optionsselection + 1
				else
					optionsselection = 1
				end
			elseif optionstab == 3 then
				if optionsselection < 10 then
					optionsselection = optionsselection + 1
				else
					optionsselection = 1
				end
			elseif optionstab == 4 and gamefinished then
				if optionsselection < 11 then
					optionsselection = optionsselection + 1
				else
					optionsselection = 1
				end
			elseif optionstab == 5 and gamefinished then
				if (_CORRUPTER and optionsselection < 4) or (not _CORRUPTER and optionsselection < 3) then
					optionsselection = optionsselection + 1
				else
					optionsselection = 1
				end
			end
		elseif (key == "up" or key == "w") then
			if optionsselection > 1 then
				optionsselection = optionsselection - 1
			else
				if optionstab == 1 then
					if skinningplayer ~= mouseowner then
						optionsselection = 15
					else
						optionsselection = 11
					end
				elseif optionstab == 2 then
					local limit = 6
					if characters.data[mariocharacter[skinningplayer]].colorables then
						limit = 10
					end
					optionsselection = limit
				elseif optionstab == 3 then
					optionsselection = 10
				elseif optionstab == 4 and gamefinished then
					optionsselection = 11
				elseif optionstab == 5 and gamefinished then
					if _CORRUPTER then
						optionsselection = 4
					else
						optionsselection = 3
					end
				end
			end
		elseif (key == "right" or key == "d") then
			if optionstab == 2 then
				if optionsselection == 3 then
					if #characters.list > 0 then
						local t = characters.list
						local i = characters.data[mariocharacter[skinningplayer]].i+1 or 1
						if i > #t then
							i = 1
						end

						colorsetedit = 1
						setcustomplayer(t[i], skinningplayer)
					end
				elseif optionsselection == 4 and not (mariocharacter[skinningplayer] and not characters.data[mariocharacter[skinningplayer]].hats) then
					if mariohats[skinningplayer][1] == nil then
						mariohats[skinningplayer][1] = 1
					elseif mariohats[skinningplayer][1] < #hat then
						mariohats[skinningplayer][1] = mariohats[skinningplayer][1] + 1
					end
				elseif characters.data[mariocharacter[skinningplayer]].colorables and optionsselection == 5 then
					--next color set
					colorsetedit = colorsetedit + 1
					if colorsetedit > #characters.data[mariocharacter[skinningplayer]].colorables then
						colorsetedit = 1
					end
				end
			elseif optionstab == 3 then
				if optionsselection == 2 then
					if resizable then
					elseif scale < 5 then
						changescale(scale+1)
					end
				elseif optionsselection == 3 then
					letterboxfullscreen = not letterboxfullscreen
				elseif optionsselection == 4 then
					currentshaderi1 = currentshaderi1 + 1
					if currentshaderi1 > #shaderlist then
						currentshaderi1 = 1
					end
					if shaderlist[currentshaderi1] == "none" then
						shaders:set(1, nil)
					else
						shaders:set(1, shaderlist[currentshaderi1])
					end
					
				elseif optionsselection == 5 then
					currentshaderi2 = currentshaderi2 + 1
					if currentshaderi2 > #shaderlist then
						currentshaderi2 = 1
					end
					if shaderlist[currentshaderi2] == "none" then
						shaders:set(2, nil)
					else
						shaders:set(2, shaderlist[currentshaderi2])
					end
					
				elseif optionsselection == 6 then
					if volume < 1 then
						volume = volume + 0.1
						if volume > 1 then
							volume = 1
						end
						love.audio.setVolume( volume )
						playsound(coinsound)
						soundenabled = true
					end
				elseif optionsselection == 9 then
					vsync = not vsync
					changescale(scale)
				elseif optionsselection == 10 then
					if mappackfolder == "mappacks" then
						mappackfolder = "alesans_entities/mappacks"
						mappack = "smb"
						loadbackground("1-1.txt")
					end
				end
			elseif optionstab == 4 then
				if optionsselection == 2 then
					playertypei = playertypei + 1
					if playertypei > #playertypelist then
						playertypei = 1
					end
					playertype = playertypelist[playertypei]
					if playertype == "minecraft" then
						portalknockback = false
						bullettime = false
						bigmario = false
						sonicrainboom = false
					elseif playertype == "gelcannon" then
						sonicrainboom = false
					elseif playertype == "classic" then
						portalknockback = false
						sonicrainboom = false
					end
				elseif optionsselection == 3 then
					portalknockback = not portalknockback
					if portalknockback then
						if playertype == "minecraft" then
							playertypei = 1
							playertype = "portal"
						end
					end
				elseif optionsselection == 4 then
					bullettime = not bullettime
					if bullettime then
						if playertype == "minecraft" then
							playertypei = 1
							playertype = "portal"
						end
					end
				elseif optionsselection == 5 then
					bigmario = not bigmario
					if bigmario then
						if playertype == "minecraft" then
							playertypei = 1
							playertype = "portal"
						end
					end
				elseif optionsselection == 6 then
					goombaattack = not goombaattack
				elseif optionsselection == 7 then
					sonicrainboom = not sonicrainboom
					playertype = "portal"
					playertypei = 1
				elseif optionsselection == 8 then
					playercollisions = not playercollisions
				elseif optionsselection == 9 then
					infinitetime = not infinitetime
				elseif optionsselection == 10 then
					infinitelives = not infinitelives
				elseif optionsselection == 11 then
					darkmode = not darkmode
				end
			elseif optionstab == 5 then
				if optionsselection == 2 then
					_3DMODE = not _3DMODE
					if _3DMODE then
						notice.new("3d mode may slow down|performance", notice.white, 2)
					end
				elseif optionsselection == 3 then
					_CORRUPTER = not _CORRUPTER
				elseif optionsselection == 4 then
					_CORRUPTER_MODE = not _CORRUPTER_MODE
				end
			end				
		elseif (key == "left" or key == "a") then
			if optionstab == 2 then
				if optionsselection == 3 then
					if #characters.list > 0 then
						local t = characters.list
						local i = characters.data[mariocharacter[skinningplayer]].i-1
						if i < 1 then
							i = #t
						end

						colorsetedit = 1
						setcustomplayer(t[i], skinningplayer)
					end
				elseif optionsselection == 4 and not (mariocharacter[skinningplayer] and not characters.data[mariocharacter[skinningplayer]].hats) then
					if mariohats[skinningplayer][1] == 1 then
						mariohats[skinningplayer] = {}
					elseif mariohats[skinningplayer][1] and mariohats[skinningplayer][1] > 1 then
						mariohats[skinningplayer][1] = mariohats[skinningplayer][1] - 1
					end
				elseif characters.data[mariocharacter[skinningplayer]].colorables and optionsselection == 5 then
					--previous color set
					colorsetedit = colorsetedit - 1
					if colorsetedit < 1 then
						colorsetedit = #characters.data[mariocharacter[skinningplayer]].colorables
					end
				end
			elseif optionstab == 3 then
				if optionsselection == 2 then
					if resizable then
						changescale(4)
					elseif scale > 1 then
						changescale(scale-1)
					end
				elseif optionsselection == 3 then
					letterboxfullscreen = not letterboxfullscreen
				elseif optionsselection == 4 then
					currentshaderi1 = currentshaderi1 - 1
					if currentshaderi1 < 1 then
						currentshaderi1 = #shaderlist
					end
					
					if shaderlist[currentshaderi1] == "none" then
						shaders:set(1, nil)
					else
						shaders:set(1, shaderlist[currentshaderi1])
					end
				elseif optionsselection == 5 then
					currentshaderi2 = currentshaderi2 - 1
					if currentshaderi2 < 1 then
						currentshaderi2 = #shaderlist
					end
					
					if shaderlist[currentshaderi2] == "none" then
						shaders:set(2, nil)
					else
						shaders:set(2, shaderlist[currentshaderi2])
					end
					
				elseif optionsselection == 6 then
					if volume > 0 then
						volume = volume - 0.1
						if volume <= 0 then
							volume = 0
							soundenabled = false
						end
						love.audio.setVolume( volume )
						playsound(coinsound)
					end
				elseif optionsselection == 9 then
					vsync = not vsync
					changescale(scale)
				elseif optionsselection == 10 then
					if mappackfolder == "alesans_entities/mappacks" then
						mappackfolder = "mappacks"
						mappack = "smb"
						loadbackground("1-1.txt")
					end
				end
			elseif optionstab == 4 then
				if optionsselection == 2 then
					playertypei = playertypei - 1
					if playertypei < 1 then
						playertypei = #playertypelist
					end
					playertype = playertypelist[playertypei]
					if playertype == "minecraft" then
						portalknockback = false
						bullettime = false
						bigmario = false
						sonicrainboom = false
					elseif playertype == "gelcannon" then
						sonicrainboom = false
					end
				elseif optionsselection == 3 then
					portalknockback = not portalknockback
					if portalknockback then
						if playertype == "minecraft" then
							playertypei = 1
							playertype = "portal"
						end
					end
				elseif optionsselection == 4 then
					bullettime = not bullettime
					if bullettime then
						if playertype == "minecraft" then
							playertypei = 1
							playertype = "portal"
						end
					end
				elseif optionsselection == 5 then
					bigmario = not bigmario
					if bigmario then
						if playertype == "minecraft" then
							playertypei = 1
							playertype = "portal"
						end
					end
				elseif optionsselection == 6 then
					goombaattack = not goombaattack
				elseif optionsselection == 7 then
					sonicrainboom = not sonicrainboom
					playertype = "portal"
					playertypei = 1
				elseif optionsselection == 8 then
					playercollisions = not playercollisions
				elseif optionsselection == 9 then
					infinitetime = not infinitetime
				elseif optionsselection == 10 then
					infinitelives = not infinitelives
				elseif optionsselection == 11 then
					darkmode = not darkmode
				end
			elseif optionstab == 5 then
				if optionsselection == 2 then
					_3DMODE = not _3DMODE
					if _3DMODE then
						notice.new("3d mode may slow down|performance", notice.white, 4.5)
					end
				elseif optionsselection == 3 then
					_CORRUPTER = not _CORRUPTER
				elseif optionsselection == 4 then
					_CORRUPTER_MODE = not _CORRUPTER_MODE
				end
			end
		elseif key == "m" then
			if optionstab == 2 then
				if optionsselection == 3 then
					--open characters folder
					if android then
						notice.new("On android use a file manager|and go to:|Android > data > Love.to.mario >|files > save > mari0_android >|alesans_entities > characters", notice.red, 15)
						return false
					end
					if not love.filesystem.exists("alesans_entities/characters") then
						love.filesystem.createDirectory("alesans_entities/characters")
					end
					love.system.openURL("file://" .. love.filesystem.getSaveDirectory() .. "/alesans_entities/characters")
				end
			end
		elseif key == "escape" then
			gamestate = "menu"
			saveconfig()
		end
	end
end

function menu_keyreleased(key, unicode)

end

function menu_mousepressed(x, y, button)
	if gamestate == "menu" then
		if mouseonselect then
			if selectworldopen then
				local x, y = x/scale, y/scale
				local sc = selectworldcursor
				local v = math.ceil(sc/8)*8-7
				if x > 35 and x < 43 and y > 130 and y < 138 then
					local target = selectworldcursor-1
					while target > 0 and not reachedworlds[mappack][target] do
						target = target - 1
					end
					if target > 0 then
						selectworldcursor = target
					end
					return
				end
				if x > 215 and x < 223 and y > 130 and y < 138 then
					local target = selectworldcursor+1
					while target <= #mappacklevels and not reachedworlds[mappack][target] do
						target = target + 1
					end
					if target <= #mappacklevels then
						selectworldcursor = target
					end
					return
				end
				local i2 = 1
				for i = v, v+7 do
					local world = i
					if hudworldletter and i > 9 and i <= 9+#alphabet then
						world = alphabet:sub(i-9, i-9)
					end
					if reachedworlds[mappack][i] and x > (54+(i2-1)*20) and x < (54+(i2-1)*20)+12 and y > 128 and y < 140 then
						selectworldopen = false
						game_load(i)
						break
					end
					i2 = i2 + 1
				end
			else
				--hold down menu buttons
				mouseonselecthold = true
			end
		end
		--sausage D:
		if button == "l" and (not customsprites) and x > 179*scale and y > 71*scale and x < 201*scale and y < 96*scale then
			dothesausage(1)
			dothesausage()
		end
	elseif gamestate == "mappackmenu" then
		opendlcbutton:click(x, y, button)
		if button == "wu" then
			menu_keypressed("up")
		elseif button == "wd" then
			menu_keypressed("down")
		elseif button == "l" then
			if y > 4*scale and y < 15*scale then --tab buttons
				local oldmappackhorscroll = mappackhorscroll
				if x > 23*scale and x < 65*scale then
					mappackhorscroll = 0
				elseif x > 71*scale and x < 98*scale then
					mappackhorscroll = 1
				elseif x > 103*scale and x < 225*scale then
					mappackhorscroll = 2
				end
				if oldmappackhorscroll ~= mappackhorscroll then
					opendlcbutton.active = false
					if mappackhorscroll == 0 then
						loadmappacks()
						return
					elseif mappackhorscroll == 1 then
						if (not onlinemappacklist) or onlinemappacklisterror then
							loadonlinemappacks()
						end
						opendlcbutton.active = true
						mappacktype = "online"
						return
					elseif mappackhorscroll == 2 then
						loaddailychallenge()
						return
					end
				end
			end
			--mappack selection
			if not android then
				if mappacktype ~= "daily_challenge" then
					local i = mappackselection
					local scrollsmooth = mappackscrollsmooth
					if mappacktype == "online" then
						i = onlinemappackselection
						scrollsmooth = onlinemappackscrollsmooth
					end
					if x > 25*scale and y > (20+(i-1)*60-round(scrollsmooth*60))*scale and y > 15*scale
						and x < (mappackhighlight:getWidth()-30)*scale and y < (20+mappackhighlight:getHeight()+(i-1)*60-round(scrollsmooth*60))*scale then
						menu_keypressed("return")
					end
				else
					menu_keypressed("return")
				end
			end
			--mappack scrollbar
			local i = mappackscrollsmooth / (#mappacklist-3.233)
			if mappacktype == "online" then
				i = onlinemappackscrollsmooth / (#onlinemappacklist-3.233)
			end
			if x > 227*scale and x < 235*scale and y > (20+i*160)*scale and y < (52+i*160)*scale then --scrollbar
				mappackscrollmouse = true
			end
		end
	end
end

function menu_mousereleased(x, y, button)
	if gamestate == "menu" then
		if mouseonselect and mouseonselecthold then
			if mouseonselect == 0 then
				game_load(true)
			elseif mouseonselect == 1 then
				selectworld()
			elseif mouseonselect == 2 then
				if nofunallowed then
					notice.new("Creator disabled the editor.", notice.white, 2)
					return false
				end
				editormode = true
				players = 1
				playertype = "portal"
				playertypei = 1
				disablecheats()
				loadeditormetadata()
				game_load()
				return
			elseif mouseonselect == 3 then
				gamestate = "mappackmenu"
				mappacks()
			elseif mouseonselect == 4 then
				gamestate = "options"
			end
		end
		mouseonselecthold = false
	elseif gamestate == "mappackmenu" then
		mappackscrollmouse = false
	end
end

function menu_mousemoved(x, y, dx, dy)
	if DisableMouseInMainMenu then
		return false
	end
	if gamestate == "mappackmenu" then
		--mappack selection
		if (not android) and mappacktype ~= "daily_challenge" then
			local scrollsmooth = mappackscrollsmooth
			local list = mappacklist
			if mappacktype == "online" then
				scrollsmooth = onlinemappackscrollsmooth
				list = onlinemappacklist
			end
			for i = math.max(1, math.floor(scrollsmooth+1)), math.min(#mappacklist, math.floor(scrollsmooth+5)) do
				if x > 25*scale and y > (20+(i-1)*60-round(scrollsmooth*60))*scale
					and x < (mappackhighlight:getWidth()-30)*scale and y < (20+mappackhighlight:getHeight()+(i-1)*60-round(scrollsmooth*60))*scale then
					if mappacktype == "online" then
						onlinemappackselection = i
					else
						mappackselection = i
					end
				end
			end
		end
		--mappack scrollbar
		if mappackscrollmouse then
			if mappacktype == "online" then
				onlinemappackscroll = math.min(math.max(onlinemappackscroll+((dy/(159*scale)) * ((#onlinemappacklist-3.233))), 0), #onlinemappacklist-3.233)
				onlinemappackscrollsmooth = onlinemappackscroll
				onlinemappackselection = math.min(math.max(math.ceil(onlinemappackscroll), onlinemappackselection), math.ceil(onlinemappackscroll)+3)
			else
				mappackscroll = math.min(math.max(mappackscroll+((dy/(159*scale)) * ((#mappacklist-3.233))), 0), #mappacklist-3.233)
				mappackscrollsmooth = mappackscroll
				mappackselection = math.min(math.max(math.ceil(mappackscroll), mappackselection), math.ceil(mappackscroll)+3)
			end
		end
	end
end

function menu_joystickpressed(joystick, button)
	local s1 = controls[1]["right"]
	local s2 = controls[1]["left"]
	local s3 = controls[1]["down"]
	local s4 = controls[1]["up"]
	local s5 = controls[1]["jump"]
	local s6 = controls[1]["run"]
	if s1[1] == "joy" and joystick == s1[2] and s1[3] == "but" and button == s1[4] then
		menu_keypressed("right")
		return
	elseif s2[1] == "joy" and joystick == s2[2] and s2[3] == "but" and button == s2[4] then
		menu_keypressed("left")
		return
	elseif s3[1] == "joy" and joystick == s3[2] and s3[3] == "but" and button == s3[4] then
		menu_keypressed("down")
		return
	elseif s4[1] == "joy" and joystick == s4[2] and s4[3] == "but" and button == s4[4] then
		menu_keypressed("up")
		return
	elseif s5[1] == "joy" and joystick == s5[2] and s5[3] == "but" and button == s5[4] then
		menu_keypressed("return")
		return
	elseif s6[1] == "joy" and joystick == s6[2] and s6[3] == "but" and button == s6[4] then
		menu_keypressed("escape")
		return
	end
end

function menu_joystickreleased(joystick, button)

end

function keypromptenter(t, ...)
	arg = {...}
	if t == "key" and (arg[1] == ";" or arg[1] == "," or arg[1] == "," or arg[1] == "-") then
		return
	end
	buttonerror = false
	axiserror = false
	local buttononly = {"run", "jump", "reload", "use", "portal1", "portal2"}
	local axisonly = {"aimx", "aimy"}
	if t ~= "key" or arg[1] ~= "escape" then
		if t == "key" then
			if tablecontains(axisonly, controlstable[optionsselection-3]) then
				axiserror = true
			else
				controls[skinningplayer][controlstable[optionsselection-3]] = {arg[1]}
			end
		elseif t == "joybutton" then
			if tablecontains(axisonly, controlstable[optionsselection-3]) then
				axiserror = true
			else
				controls[skinningplayer][controlstable[optionsselection-3]] = {"joy", arg[1], "but", arg[2]}
			end
		elseif t == "joyhat" then
			if tablecontains(buttononly, controlstable[optionsselection-3]) then
				buttonerror = true
			elseif tablecontains(axisonly, controlstable[optionsselection-3]) then
				axiserror = true
			else
				controls[skinningplayer][controlstable[optionsselection-3]] = {"joy", arg[1], "hat", arg[2], arg[3]}
			end
		elseif t == "joyaxis" then
			if tablecontains(buttononly, controlstable[optionsselection-3]) then
				buttonerror = true
			else
				controls[skinningplayer][controlstable[optionsselection-3]] = {"joy", arg[1], "axe", arg[2], arg[3]}
			end
		end
	end
	
	if (not buttonerror and not axiserror) or arg[1] == "escape" then
		keyprompt = false
	end
end

function keypromptstart()
	keyprompt = true
	buttonerror = false
	axiserror = false
	
	--save number of stuff
	prompt = {}
	prompt.joystick = {}
	prompt.joysticks = love.joystick.getJoystickCount()
	
	for i = 1, prompt.joysticks do
		prompt.joystick[i] = {}
		prompt.joystick[i].hats = love.joystick.getHatCount(i)
		prompt.joystick[i].axes = love.joystick.getAxisCount(i)
		
		prompt.joystick[i].validhats = {}
		for j = 1, prompt.joystick[i].hats do
			if love.joystick.getHat(i, j) == "c" then
				table.insert(prompt.joystick[i].validhats, j)
			end
		end
		
		prompt.joystick[i].axisposition = {}
		for j = 1, prompt.joystick[i].axes do
			table.insert(prompt.joystick[i].axisposition, love.joystick.getAxis(i, j))
		end
	end
end

function reset_mappacks()
	delete_mappack("smb")
	delete_mappack("portal")
	delete_mappack("only_for_alesans_entities")
	delete_mappack("alesans_entities_mappack")

	--[[local dlclist = love.filesystem.getDirectoryItems("alesans_entities/onlinemappacks/")
	for i = 1, #dlclist do
		love.filesystem.remove("alesans_entities/onlinemappacks/" .. dlclist[i])
	end]]
	
	loadbackground("1-1.txt")

	playsound(oneupsound)
end

function delete_mappack(pack)
	if not love.filesystem.exists(mappackfolder .. "/" .. pack .. "/") then
		return false
	end
	
	local list = love.filesystem.getDirectoryItems(mappackfolder .. "/" .. pack .. "/")
	for i = 1, #list do
		love.filesystem.remove(mappackfolder .. "/" .. pack .. "/" .. list[i])
	end
	local list2 = love.filesystem.getDirectoryItems(mappackfolder .. "/" .. pack .. "/heights")
	for i = 1, #list2 do
		love.filesystem.remove(mappackfolder .. "/" .. pack .. "/heights/" .. list2[i])
	end
	
	love.filesystem.remove(mappackfolder .. "/" .. pack .. "/")
end

function createmappack()
	local i = 1
	while love.filesystem.exists( mappackfolder .. "/custom_mappack_" .. i .. "/") do
		i = i + 1
	end
	
	mappack = "custom_mappack_" .. i
	
	love.filesystem.createDirectory(mappackfolder .. "/" .. mappack .. "/")
	
	love.filesystem.createDirectory(mappackfolder .. "/" .. mappack .. "/custom/")
	love.filesystem.createDirectory(mappackfolder .. "/" .. mappack .. "/sounds/")
	love.filesystem.createDirectory(mappackfolder .. "/" .. mappack .. "/animated/")
	love.filesystem.createDirectory(mappackfolder .. "/" .. mappack .. "/enemies/")
	love.filesystem.createDirectory(mappackfolder .. "/" .. mappack .. "/music/")
	love.filesystem.createDirectory(mappackfolder .. "/" .. mappack .. "/backgrounds/")
	love.filesystem.createDirectory(mappackfolder .. "/" .. mappack .. "/animations/")
	
	local s = ""
	s = s .. "name=new mappack" .. "\n"
	s = s .. "author=you" .. "\n"
	s = s .. "description=the newest best  mappack?" .. "\n"
	
	love.filesystem.write(mappackfolder .. "/" .. mappack .. "/settings.txt", s)
end

function resetconfig()
	defaultconfig()
	
	changescale(scale)
	--loadplayersprites()
	love.audio.setVolume(volume)
	currentshaderi1 = 1
	currentshaderi2 = 1
	shaders:set(1, nil)
	shaders:set(2, nil)
	saveconfig()
	loadbackground("1-1.txt")
end

function selectworld()
	if not reachedworlds[mappack] then
		game_load()
	end
	
	local noworlds = true
	for i = 2, #mappacklevels do
		if reachedworlds[mappack][i] then
			noworlds = false
			break
		end
	end
	
	if noworlds then
		game_load()
		return
	end
	
	selectworldopen = true
	selectworldcursor = 1
	
	selectworldexists = {}
	for i = 1, #mappacklevels do
		if love.filesystem.exists(mappackfolder .. "/" .. mappack .. "/" .. i .. "-1.txt") then
			selectworldexists[i] = true
		end
	end
end

function opendlcfolder()
	if android then
		notice.new("On android use a file manager|and go to:|Android > data > Love.to.mario >|files > save > mari0_android >|alesans_entities > onlinemappacks", notice.red, 15)
		return false
	end
	if not love.filesystem.exists("alesans_entities/onlinemappacks") then
		love.filesystem.createDirectory("alesans_entities/onlinemappacks")
	end
	love.system.openURL("file://" .. love.filesystem.getSaveDirectory() .. "/alesans_entities/onlinemappacks")
end