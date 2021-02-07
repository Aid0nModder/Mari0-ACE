commander = class:new()

function commander:init(x, y, r)
	self.x = x-1
	self.y = y-1
	self.cox = x
	self.coy = y

	self.r = {unpack(r)}
	table.remove(self.r, 1)
	table.remove(self.r, 1)

	if #self.r > 0 and self.r[1] ~= "link" then
		local v = convertr(self.r[1], {"string"})
		self.command = v[1]
		table.remove(self.r, 1)
	end
	
	self.outtable = {}
end

function commander:update(dt)
end

function commander:link()
	if #self.r >= 3 then
		for j, w in pairs(outputs) do
			for i, v in pairs(objects[w]) do
				if tonumber(self.r[2]) == v.cox and tonumber(self.r[3]) == v.coy then
					v:addoutput(self)
				end
			end
		end
	end
end

function commander:addoutput(a, t)
	table.insert(self.outtable, {a, t})
end

function commander:input(t)
	if t ~= "off" then
		local command = self.command
		local com = command:gsub("B","-")
		local c = com:split("_")
		for i = 1, #c do --for numbers
			if string.find(c[i], "n/") then --find out if it has "n/""
				local c2 = c[i]:split("/") --split it into 2
				c[i] = animationnumbers[c2[2]] --set it to animation number with same name as the second part
			end
		end
		if c[1] == "player" then --player
			local l = 1
			if c[2] == "all" then
				l = players
			end
			for i = 1, l do
				local playerno
				if c[2] == "all" then
					playerno = i
				else
					playerno = tonumber(c[2])
				end
				---------
				if c[3] == "lives" then
					if c[4] == "add" then
						if mariolives[playerno] then
							mariolives[playerno] = mariolives[playerno] + tonumber(c[5])
						end
					else
						mariolives[playerno] = tonumber(c[4])
					end
				elseif c[3] == "keys" then
					if c[4] == "add" then
						if objects["player"][playerno] and objects["player"][playerno].key then
							objects["player"][playerno].key = objects["player"][playerno].key + tonumber(c[5])
						end
					else
						objects["player"][playerno].key = tonumber(c[4])
					end
				elseif c[3] == "size" then
					if objects["player"][playerno] then
						objects["player"][playerno].size = tonumber(c[4])
						objects["player"][playerno]:setsize(tonumber(c[4]))
					end
				elseif c[3] == "hurt" then
					if objects["player"][playerno] and not objects["player"][playerno].dead then
						objects["player"][playerno]:die("script")
					end
				elseif c[3] == "clearportal" then
					if objects["player"][playerno] then
						if c[4] == "1" then
							objects["player"][playerno].portal:removeportal(1)
						elseif c[4] == "2" then
							objects["player"][playerno].portal:removeportal(2)
						elseif c[4] == "both" then
							objects["player"][playerno].portal:removeportal(1)
							objects["player"][playerno].portal:removeportal(2)
						end
					end
				else
					if c[4] == "true" then
						objects["player"][playerno][c[3]] = true
					elseif c[4] == "false" then
						objects["player"][playerno][c[3]] = false
					elseif c[4] == "flip" then
						objects["player"][playerno][c[3]] = not objects["player"][playerno][c[3]]
					elseif c[4] == "add" then
						objects["player"][playerno][c[3]] = objects["player"][playerno][c[3]] + tonumber(c[5])
					elseif tonumber(c[4]) then
						objects["player"][playerno][c[3]] = tonumber(c[4])
					else
						objects["player"][playerno][c[3]] = c[4]
					end
				end
			end
		elseif c[1] == "time" then --time
			if c[2] == "add" then
				if mariotime then
					mariotime = mariotime + tonumber(c[3])
				end
			else
				mariotime = tonumber(c[2])
			end
		elseif c[1] == "score" then --score
			if c[2] == "add" then
				if marioscore then
					marioscore = marioscore + tonumber(c[3])
				end
			else
				marioscore = tonumber(c[2])
			end
		elseif c[1] == "coins" then --coins
			if c[2] == "add" then
				if mariocoincount then
					mariocoincount = mariocoincount + tonumber(c[3])
				end
			else
				mariocoincount = tonumber(c[2])
			end
		elseif c[1] == "collectable" then --collectables
			local type = tonumber(c[2])
			if c[3] == "add" then
				if collectablescount[type] then
					collectablescount[type] = collectablescount[type] + tonumber(c[4])
				end
			elseif c[3] == "reset" then
				--iterate through collected collectable list and remove any saved locations
				local w, l, s = tostring(marioworld), tostring(mariolevel), tostring(actualsublevel)
				local level = w .. "-" .. l .. "-" .. s
				for n, t in pairs(collectableslist[type]) do
					collectables[t[1]][t[2]] = nil
					if level == t[1] then
						--respawn collectable
						local s = t[2]:split("-") --find coords
						local x, y = tonumber(s[1]), tonumber(s[2])
						local coinblock = (ismaptile(x, y) and tilequads[map[x][y][1]].collision and tilequads[map[x][y][1]].coinblock)
						objects["collectable"][t[2]] = collectable:new(x, y, map[x][y], false, coinblock)
					end
				end
				collectableslist[type] = {}
				--finally, reset the amount and update locks
				collectablescount[type] = 0
			else
				collectablescount[type] = tonumber(c[3])
			end
			for i, o in pairs(objects["collectablelock"]) do
				o:removecheck()
			end
		elseif c[1] == "number" then --animation numbers
			local num = c[2]
			if c[3] == "add" then
				if animationnumbers[num] then
					animationnumbers[num] = animationnumbers[num] + tonumber(c[4])
				end
			else
				animationnumbers[num] = tonumber(c[3])
			end
		elseif c[1] == "dialog" then --dialog
			if c[2] == "destroy" then
				dialogboxes = {}
			elseif  c[2] == "create" then
				if c[3] and c[4] and c[5] then
					createdialogbox(c[3], c[4], c[5])
				end
			end
		elseif c[1] == "sound" then --play sound
			playsound(_G[c[2] .. "sound"])
		elseif c[1] == "camera" then
			if c[2] == "set" then
				if c[3] == "x" then
					xscroll = tonumber(c[4])
				elseif c[3] == "y" then
					yscroll = tonumber(c[4])
				end
			elseif c[2] == "pan" then
				if c[3] == "x" then
					autoscrollx = false
					if tonumber(c[5]) == 0 then
						camerasnap(tonumber(c[4]), yscroll, "animation")
						generatespritebatch()
					else
						cameraxpan(tonumber(c[4]), tonumber(c[5]))
					end
				elseif c[3] == "y" then
					autoscrolly = false
					if tonumber(c[5]) == 0 then
						camerasnap(xscroll, tonumber(c[4]), "animation")
						generatespritebatch()
					else
						cameraypan(tonumber(c[4]), tonumber(c[5]))
					end
				end
			elseif c[2] == "enable" then
				if c[3] == "x" then
					autoscrollx = true
				elseif c[3] == "y" then
					autoscrolly = true
				end
			elseif c[2] == "disable" then
				if c[3] == "x" then
					autoscrollx = false
				elseif c[3] == "y" then
					autoscrolly = false
				end
			elseif c[2] == "autoenable" then
				if c[3] == "x" then
					autoscrolling = true
					autoscrollingx = tonumber(c[4]) or autoscrollingdefaultspeed
					if autoscrollingx == 0 then
						autoscrollingx = false
					end
				elseif c[3] == "y" then
					autoscrolling = true
					autoscrollingy = tonumber(c[4]) or autoscrollingdefaultspeed
					if autoscrollingy == 0 then
						autoscrollingy = false
					end
				end
			elseif c[2] == "autodisable" then
				if c[3] == "x" then
					autoscrolling = false
					autoscrollx = false
				elseif c[3] == "y" then
					autoscrolling = false
					autoscrolly = false
				end
			end
		elseif c[1] == "shake" then --earthquake
			earthquake = tonumber(c[2])
		elseif c[1] == "minecraft" then --AWW MAN
			playertype = "minecraft"
		elseif c[1] == "setphysics" then --physics
			setphysics(tonumber(c[2]))
		elseif c[1] == "setcamera" then --camera setting
			setcamerasetting(tonumber(c[2]))
		elseif c[1] == "dropshadow" then --dropshadow
			dropshadow = not dropshadow
		elseif c[1] == "lightsout" then --lightsout
			lightsout = not lightsout
		elseif c[1] == "lowgravity" then --lowgravity
			lowgravity = not lowgravity
		elseif c[1] == "cheats" then --cheats
			if c[2] == "set" then
				if c[3] == "knockback" then
					portalknockback = not portalknockback
				elseif c[3] == "bullettime" then
					bullettime = not bullettime
				elseif c[3] == "bigmario" then
					bigmario = not bigmario
				elseif c[3] == "goombaattack" then
					goombaattack = not goombaattack
				elseif c[3] == "rainboom" then
					sonicrainboom = not sonicrainboom
				elseif c[3] == "playercollisions" then
					playercollisions = not playercollisions
				elseif c[3] == "infinitetime" then
					infinitetime = not infinitetime
				elseif c[3] == "infinitelives" then
					infinitelives = not infinitelives
				elseif c[3] == "darkmode" then
					darkmode = not darkmode
				elseif c[3] == "3d" then
					_3DMODE = not _3DMODE
					generatespritebatch()
				end
			elseif c[2] == "reset" then
				portalknockback = false
				bullettime = false
				bigmario = false
				goombaattack = false
				sonicrainboom = false
				playercollisions = false
				infinitetime = false
				infinitelives = false
				darkmode = false
				_3DMODE = false
			end
		elseif c[1] == "killenemies" then
			local type = c[2]
			for i2, v2 in pairs(objects) do
				if i1 ~= "tile" and i2 ~= "pixeltile" and i2 ~= "buttonblock" and (type == "all" or type == i2) then
					for i, v in pairs(objects[i2]) do
						if v.active and v.shotted and (not v.resistseverything) then
							local dir = "right"
							if math.random(1,2) == 1 then
								dir = "left"
							end
							v:shotted(dir)
						end
					end
				end
			end
		elseif c[1] == "spawn" then
			if c[2] == "enemy" then
				spawnenemy(c[5], tonumber(c[3]), tonumber(c[4]))
			elseif c[2] == "entity" then
				loadentity(c[5], tonumber(c[3]), tonumber(c[4]))
			end
		elseif c[1] == "data" then
			local x, y
			if tonumber(c[2]) and tonumber(c[3]) then
				x, y = tonumber(c[2]), tonumber(c[3])
				for a, b in pairs(objects) do
					for i, v in pairs(b) do
						local cox, coy
						if v.cox and v.coy then
							cox, coy = v.cox, v.coy
						elseif v.x and v.y then
							cox, coy = v.x, v.y
						end
						if (cox == x and coy == y) or (cox == x-1 and coy == y-1) then --dumb fix, blame maurice
							self:dodata(v, c[4], c[5], c[6])
						end
					end
				end
			elseif c[2] == "all" then
				for a, b in pairs(objects) do
					for i, v in pairs(b) do
						self:dodata(v, c[3], c[4], c[5])
					end
				end
			else
				for i, v in pairs(objects[c[2]]) do
					self:dodata(v, c[3], c[4], c[5])
				end
			end
		end
		-- toggle other connected commanders after actions, easier than delays
		for i = 1, #self.outtable do
			self.outtable[i][1]:input("toggle", self.outtable[i][2])
		end
	end
end

function commander:dodata(v, var, val, valifadd)
	if var == "delete" then
		table.remove(b, i)
	else
		local p = var
		if val == "true" then --boolean stuff
			v[p] = true
		elseif val == "false" then
			v[p] = false
		elseif val == "flip" then
			v[p] = not v[p]
		elseif type(v[p]) == "number" then --number
			if val == "add" then
				v[p] = v[p] + tonumber(valifadd)
			else
				v[p] = tonumber(val)
			end
		else --strings
			v[p] = val
		end
	end
end

----------------------------------------------------

local function commandermaketext(list, pos, options)
	local t = ""
	for i = 1, pos do
		t = t .. list[i] .. "_"
	end
	t = t .. "<" .. options .. ">"
	return t
end

function commandert(val) --hell
	--print("test, command is " .. val)

	local text, textb, textc, yes, no = "", "", "", "command set!", "error"
	local command = val
	local com = command:gsub("B","-")
	local c = com:split("_")

	if com == "" then
		text = "please start inputing command."
	elseif #c == 1 then
		text = no
	else
		if c[1] == "player" then
			if #c == 2 then
				text = commandermaketext(c, 1, "player number or all")
			elseif #c == 3 then
				text = commandermaketext(c, 2, "lives/keys/size/hurt/kill/clearportal or any variable")
			elseif #c == 4 then
				if c[3] == "lives" or c[3] == "keys" then
					text = commandermaketext(c, 3, "add or a value")
				elseif c[3] == "size" then
					text = commandermaketext(c, 3, "powerBup id")
				elseif c[3] == "clearportal" then
					text = commandermaketext(c, 3, "1/2/both")
				elseif c[3] == "hurt" or c[3] == "kill" then
					text = yes
				else
					text = commandermaketext(c, 3, "true/false/flip/add or string/value")
				end
			elseif #c == 5 then
				if c[3] == "lives" or c[3] == "keys" then
					if c[4] == "add" then
						text = commandermaketext(c, 4, "value")
					else
						text = yes
					end
				elseif c[3] == "size" or c[3] == "hurt" or c[3] == "kill" then
					text = yes
				elseif c[4] == "add" then
					text = commandermaketext(c, 4, "value")
				else
					text = yes
				end
			elseif #c > 5 then
				text = yes
			else
				text = no
			end
		elseif c[1] == "time" or c[1] == "score" or c[1] == "coins" then
			if #c == 2 then
				text = commandermaketext(c, 1, "add or a value")
			elseif #c == 3 then
				if c[2] == "add" then
					text = commandermaketext(c, 2, "value")
				else
					text = yes
				end
			elseif #c > 3 then
				text = yes
			else
				text = no
			end
		elseif c[1] == "collectable" then
			if #c == 2 then
				text = commandermaketext(c, 1, "collectable type")
			elseif #c == 3 then	
				text = commandermaketext(c, 2, "add/reset or a value")
			elseif #c == 4 then
				if c[3] == "add" then
					text = commandermaketext(c, 3, "value")
				else
					text = yes
				end
			elseif #c > 4 then
				text = yes
			else
				text = no
			end
		elseif c[1] == "number" then
			if #c == 2 then
				text = commandermaketext(c, 1, "number name")
			elseif #c == 3 then
				text = commandermaketext(c, 2, "add or a value")
			elseif #c == 4 then
				if c[3] == "add" then
					text = commandermaketext(c, 3, "value")
				else
					text = yes
				end
			elseif #c > 4 then
				text = yes
			else
				text = no
			end
		elseif c[1] == "dialog" then
			if #c == 2 then
				text = commandermaketext(c, 1, "destroy/create")
			elseif #c == 3 then
				if c[2] == "create" then
					text = commandermaketext(c, 2, "name")
				else
					text = yes
				end
			elseif #c == 4 then
				if c[2] == "create" then
					text = commandermaketext(c, 3, "text")
				else
					text = yes
				end
			elseif #c == 5 then
				if c[2] == "create" then
					text = commandermaketext(c, 4, "color")
				else
					text = yes
				end
			elseif #c > 5 then
				text = yes
			else
				text = no
			end
		elseif c[1] == "sound" then
			if #c == 2 then
				text = commandermaketext(c, 1, "sound")
			elseif #c > 2 then
				text = yes
			else
				text = no
			end
		elseif c[1] == "camera" then
			if #c == 2 then
				text = commandermaketext(c, 1, "set/pan/enable/disable/autoenable/autodisable")
			elseif #c == 3 then
				text = commandermaketext(c, 2, "x/y")
			elseif #c == 4 then
				if c[2] == "set" or c[2] == "pan" then
					text = commandermaketext(c, 3, "position")
				elseif c[2] == "autoenable" then
					text = commandermaketext(c, 3, "speed")
				else
					text = yes
				end
			elseif #c == 5 then	
				if c[2] == "pan" then
					text = commandermaketext(c, 4, "sound")
				else
					text = yes
				end
			elseif #c > 5 then
				text = yes
			else
				text = no
			end
		elseif c[1] == "shake" then
			if #c == 2 then
				text = commandermaketext(c, 1, "force")
			elseif #c > 2 then
				text = yes
			else
				text = no
			end
		elseif c[1] == "minecraft" or c[1] == "dropshadow" or c[1] == "lightsout" or c[1] == "lowgravity" then
			text = yes
		elseif c[1] == "setphysics" or c[1] == "setcamera" then
			if #c == 2 then
				text = commandermaketext(c, 1, "type")
			elseif #c > 2 then
				text = yes
			else
				text = no
			end
		elseif c[1] == "cheats" then
			if #c == 2 then
				text = commandermaketext(c, 1, "set/reset")
			elseif #c == 3 then
				if c[2] == "set" then
					text = commandermaketext(c, 2, "type")
				else
					text = yes
				end
			elseif #c > 3 then
				text = yes
			else
				text = no
			end
		elseif c[1] == "killenemies" then
			if #c == 2 then
				text = commandermaketext(c, 1, "group or all")
			elseif #c > 2 then
				text = yes
			else
				text = no
			end
		elseif c[1] == "spawn" then
			if #c == 2 then
				text = commandermaketext(c, 1, "enemy/entity")
			elseif #c == 3 then
				text = commandermaketext(c, 2, "x position")
			elseif #c == 4 then
				text = commandermaketext(c, 3, "y position")
			elseif #c == 5 then
				text = commandermaketext(c, 4, "name")
			elseif #c > 5 then
				text = yes
			else
				text = no
			end
		elseif c[1] == "data" then
			if #c == 2 then
				text = commandermaketext(c, 1, "x pos/object type/all")
			elseif #c == 3 then
				if tonumber(c[2]) then
					text = commandermaketext(c, 2, "y position")
				else
					text = commandermaketext(c, 2, "delete or variable")
				end
			elseif #c == 4 then
				if tonumber(c[2]) then
					text = commandermaketext(c, 3, "delete or variable")
				else
					if c[3] == "delete" then
						text = yes
					else
						text = commandermaketext(c, 3, "true/false/flip/add or a value/string")
					end
				end
			elseif #c == 5 then
				if tonumber(c[2]) then
					if c[4] == "delete" then
						text = yes
					else
						text = commandermaketext(c, 4, "true/false/flip/add or a value/string")
					end
				else
					if c[3] == "delete" then
						text = yes
					else
						if c[4] == "add" then
							text = commandermaketext(c, 4, "value")
						else
							text = yes
						end
					end
				end
			elseif #c == 6 then
				if tonumber(c[2]) then
					if c[4] == "delete" then
						text = yes
					else
						if c[5] == "add" then
							text = commandermaketext(c, 5, "value")
						else
							text = yes
						end
					end
				else
					text = yes
				end
			elseif #c > 6 then
				text = yes
			else
				text = no
			end
		else
			text = no
		end
	end

	local textmax = 30
	if #text > textmax then
		textb = string.sub(text, textmax+1, string.len(text))
		text = string.sub(text, 1, textmax)
	end
	if #textb > textmax then
		textc = string.sub(textb, textmax+1, string.len(textb))
		textb = string.sub(textb, 1, textmax)
	end
	rightclicktype[customrcopen].settext(text, textb, textc)
end