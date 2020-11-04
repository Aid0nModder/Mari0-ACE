enemytool = class:new()

function enemytool:init(x, y, r, e)
	self.cox = x
	self.coy = y
	self.x = x-1
	self.y = y-1
	self.r = r
	self.customenemy = true
	self.animation = false
	if e:find("|") then
		local v = convertr(e, {"string", "num", "num", "bool", "string"}, true)
		self.enemy = v[1]
		self.xvel = v[2]
		self.yvel = v[3]
		if v[4] == nil then
			if tablecontains(customenemies, self.enemy) then
				self.customenemy = true
			else
				self.customenemy = false
			end
		else
			self.customenemy = v[4]
		end
		if v[5] and v[5] ~= "none" then
			self.animation = v[5]
		end
	else
		self.enemy = e or "goomba"
		self.xvel = 0
		self.yvel = 0
	end
	self:translateenemy()
	self.drawable = false
	
	self.linked = false
	self.pass = false
	self.outtable = {}
	self.timer = 0

	print(self.animation)
	if self.animation == "cannon" then
		self.time = math.random(bulletbilltimemin*10, bulletbilltimemax*10)/10
	elseif self.animation == "pipeup" or self.animation == "pipedown" or self.animation == "pipeleft" or self.animation == "piperight" then
		self.pipe = true
		self.spawned = {}
		self.spawnmax = math.huge
		self.timer = pipespawndelay/2
	end

	--is it supersized?
	if ismaptile(x, y) and map[x][y]["argument"] then
		if map[x][y]["argument"] == "b" then --supersized
			self.supersized = 2
		end
	end
end

function enemytool:update(dt)
	if (not self.linked) and onscreen(self.x-2, self.y-2, 4, 4) then
		--automatic spawning
		if self.pipe then
			local cx, cy, cw, ch = self.x, self.y, 2, 1
			if self.animation == "pipeleft" or self.animation == "piperight" then
				cx, cy, cw, ch = self.x, self.y-1, 1, 2
			end
			if #self.spawned > 0 then
				--only have one object spawned
				local delete = {}
				for i, v in pairs(self.spawned) do
					if v.delete then
						table.insert(delete, i)
					end
				end
				table.sort(delete, function(a,b) return a>b end)
				for i, v in pairs(delete) do
					table.remove(self.spawned, v) --remove
				end
			end
			if #self.spawned < self.spawnmax then
				local col = checkrect(cx, cy, cw, ch, {"player"}, nil)
				if #col == 0 then
					self.timer = self.timer + dt
					while self.timer > pipespawndelay do
						self:spawn()
						self.timer = self.timer - pipespawndelay
					end
				end
			end
		elseif self.animation == "cannon" then
			local cx, cy, cw, ch = self.x-1, self.y-6, 3, 12
			local col = checkrect(cx, cy, cw, ch, {"player"}, nil)
			if #col == 0 then
				self.timer = self.timer + dt
				while self.timer > self.time do
					self:spawn()
					self.timer = self.timer - pipespawndelay
					self.time = math.random(bulletbilltimemin*10, bulletbilltimemax*10)/10
				end
			end
		end
	end
end

function enemytool:link()
	if #self.r > 3 then
		for j, w in pairs(outputs) do
			for i, v in pairs(objects[w]) do
				if tonumber(self.r[5]) == v.cox and tonumber(self.r[6]) == v.coy then
					v:addoutput(self)
					self.linked = true
				end
			end
		end
	end
end

function enemytool:input(t)
	if t == "on" then
		if not self.pass then
			self:spawn()
			self.pass = true
		end
	elseif t == "off" then
		self.pass = false
	elseif t == "toggle" then
		self:spawn()
	end
end

function enemytool:spawn()
	local i = self.enemy
	local x = self.cox
	local y = self.coy
	if self.animation == "offset" then
		x = x + 0.5
	end
	local dir = "left"
	if self.xvel > 0 then
		dir = "right"
	end
	--if objects["player"][1].x < self.cox then
	--	dir = "left"
	--end
	
	if i == nil then
		return false
	end

	local obj, wasenemy, objtable
	if self.customenemy and tablecontains(customenemies, i) then
		obj, wasenemy, objtable = enemy:new(x, y, i)
		table.insert(objects["enemy"], obj)
	elseif i == "groundmole" or i == "ground mole" then
		obj = mole:new(x-0.5, y-1/16)
		table.insert(objects["mole"], obj)
	elseif i == "mole" or i == "monty mole" then
		obj = mole:new(x-0.5, y-1/16)
		table.insert(objects["mole"], obj)
		obj.width = 12/16
		obj.height = 12/16
		obj.quad = molequad[spriteset][3]
		obj.gravity = yacceleration
		obj.mask = {	true, 
					false, false, false, false, true,
					false, true, false, true, false,
					false, false, true, false, false,
					true, true, false, false, false,
					false, true, true, false, false,
					true, false, true, true, true}
		obj.inground = false
	elseif i == "bowser" then
		obj = bowser:new(x-4, y-1/16)
		table.insert(objects["bowser"], obj)
	elseif i == "bowserfire" then
		obj = fire:new(x,y)
		table.insert(objects["fire"], obj)
	elseif i == "bulletbillsingle" or i == "bulletbill" or i == "bullet bill" then
		obj = bulletbill:new(x, y, dir)
		table.insert(objects["bulletbill"], obj)
	elseif i == "bulletbill right" then
		table.insert(objects["bulletbill"], bulletbill:new(x, y, "right"))
	elseif  i == "bulletbill left" then
		table.insert(objects["bulletbill"], bulletbill:new(x, y, "left"))
	elseif i == "bigbillsingle" or i == "bigbill" or i == "banzai bill" then
		obj = bigbill:new(x, y, dir)
		table.insert(objects["bigbill"], obj)
	elseif i == "banzai bill left" or i == "bigbillleft" or i == "big bill left" or i == "bigbill left" then
		table.insert(objects["bigbill"], bigbill:new(x, y, "left"))
	elseif i == "bigbillright" or i == "bigbill right" or i == "banzai bill right" or i == "big bill right" then
		table.insert(objects["bigbill"], bigbill:new(x, y, "right"))
	elseif i == "kingbill" or i == "king bill" then
		table.insert(objects["kingbill"], kingbill:new(xscroll-200/16, y))
	elseif i == "cannonballsingle" or i == "cannonball" or i == "cannon ball" then
		table.insert(objects["cannonball"], cannonball:new(x, y, "left"))
	elseif i == "hammer" then
		if dir == "left" then
			obj = hammer:new(x-1-5/16, y, "left")
		else
			obj = hammer:new(x, y, "right")
		end
		table.insert(objects["hammer"], obj)
	elseif i == "brofireball" then
		obj = brofireball:new(x-1, y-1, dir)
		table.insert(objects["brofireball"], obj)
	elseif i == "broboomerang" then
		obj = boomerang:new(x-1, y-1, dir)
		table.insert(objects["boomerang"], obj)
	elseif i == "broiceball" then
		obj = brofireball:new(x-1, y-1, dir, "ice")
		table.insert(objects["brofireball"], obj)
	elseif i == "flyingfish" or i == "jumping fish" then
		obj = flyingfish:new()
		table.insert(objects["flyingfish"], obj)
	elseif i == "meteor" then
		obj = meteor:new(x-1)
		table.insert(objects["meteor"], obj)
	elseif i == "turretleft" or i == "turret left" then
		table.insert(objects["turret"], turret:new(x, y, "left"))
	elseif i == "turretright" or i == "turret" or i == "turret right" then
		table.insert(objects["turret"], turret:new(x, y, "right"))
	elseif i == "turret2left" or i == "defective turret left" then
		table.insert(objects["turret"], turret:new(x, y, "left", "turret2"))
	elseif i == "turret2right" or i == "defective turret" then
		table.insert(objects["turret"], turret:new(x, y, "right", "turret2"))
	elseif i == "spring" then
		table.insert(objects["spring"], spring:new(x, y, nil))
	elseif i == "moving spring" then
		table.insert(objects["spring"], spring:new(x, y, nil, true))
	elseif i == "greenspring" or i == "green spring" then
		table.insert(objects["spring"], spring:new(x, y, "green"))
	elseif i == "moving greenspring" or i == "moving green spring" then
		table.insert(objects["spring"], spring:new(x, y, "green", true))
	elseif i == "spike snow" then
		obj = spike:new(x-0.5, y-1/16, "snow")
		table.insert(objects["spike"], obj)
	elseif i == "snowball" then
		obj = spikeball:new(x-0.5, y, "snow", "left", true)
		table.insert(objects["spikeball"], obj)
	elseif string.find(i, "koopaling") then
		local num = 1
		if i ~= "koopaling" then
			num = string.sub(i, 10, 10)
		end
		num = tonumber(num)
		table.insert(objects["koopaling"], koopaling:new(x-0.5, y-1/16, num))
	elseif i == "box" then --change to enemy? (be wary of region triggers)
		obj = box:new(x, y)
		table.insert(objects["box"], obj)
	elseif i == "box2" then
		obj = box:new(x, y, "box2")
		table.insert(objects["box"], obj)
	elseif i == "edgelessbox" then
		obj = box:new(x, y, "edgeless")
		table.insert(objects["box"], obj)
	elseif i == "coin" then
		if self.animation then
			obj = tilemoving:new(x, y, 116)
			table.insert(objects["tilemoving"], obj)
		else
			objects["coin"][tilemap(x, y)] = coin:new(x, y)
		end
	elseif i == "spikeyfall" then
		obj = goomba:new(x+6/16, y, "spikeyfall")
		table.insert(objects["goomba"], obj)
	elseif i == "gel1" then
		obj = gel:new(x, y, 1)
		table.insert(objects["gel"], obj)
	elseif i == "gel2" then
		obj = gel:new(x, y, 2)
		table.insert(objects["gel"], obj)
	elseif i == "gel3" then
		obj = gel:new(x, y, 3)
		table.insert(objects["gel"], obj)
	elseif i == "gel4" then
		obj = gel:new(x, y, 4)
		table.insert(objects["gel"], obj)
	elseif i == "gelcleanse" then
		obj = gel:new(x, y, 5)
		table.insert(objects["gel"], obj)
	elseif i == "core1" then
		obj = core:new(x, y, "morality")
		table.insert(objects["core"], obj)
	elseif i == "core2" then
		obj = core:new(x, y, "curiosity")
		table.insert(objects["core"], obj)
	elseif i == "core3" then
		obj = core:new(x, y, "cakemix")
		table.insert(objects["core"], obj)
	elseif i == "core4" then
		obj = core:new(x, y, "anger")
		table.insert(objects["core"], obj)
	elseif i == "magic" then
		obj = plantfire:new(x, y, {nil, nil, "magikoopa"})
		table.insert(objects["plantfire"], obj)	
	elseif i == "angrysun" then
		obj = angrysun:new(x, y, "sun")
		table.insert(objects["angrysun"], obj)	
	elseif i == "moon" then
		obj = angrysun:new(x, y, "moon")
		table.insert(objects["angrysun"], obj)
	else
		obj, wasenemy, objtable = spawnenemy(i, x, y, false, "spawner")
		--turn in the right direction
		if obj and dir == "right" and obj.animationdirection then
			if obj.animationdirection == "right" then
				obj.animationdirection = "left"
			else
				obj.animationdirection = "right"
			end
		end
	end

	if obj then
		local poof = "powpoof"
		if self.supersized and (not self.customenemy) then
			for n, t in pairs(entitylist) do
				if i == t.t and t.supersize then --is the enemy supersizable?
					supersizeentity(obj)
					poof = "powpoofbig"
				end
			end
			--hidden rights!
			for n, t in pairs(hiddenentitylist) do
				if i == t.t and t.supersize then --is the enemy supersizable?
					supersizeentity(obj)
					poof = "powpoofbig"
				end
			end
		end

		if obj.speedx then
			if self.animation == "cannon" and self.xvel == 0 then
				--default cannon
				local pl = 1
				for i = 2, players do
					if math.abs(objects["player"][i].x+objects["player"][i].width/2 - (self.cox-.5)) 
						< math.abs(objects["player"][pl].x+objects["player"][pl].width/2 - (self.cox-.5)) then
						pl = i
					end
				end
				if objects["player"][pl].x+objects["player"][pl].width/2 > (self.cox-.5) then
					obj.speedx = obj.speedx+bulletbillspeed
				else
					obj.speedx = obj.speedx-bulletbillspeed
				end
				obj.speedy = obj.speedy+self.yvel
			else
				obj.speedx = obj.speedx+self.xvel
				obj.speedy = obj.speedy+self.yvel
			end
		end

		if self.pipe and obj.pipespawnmax then
			self.spawnmax = obj.pipespawnmax
			table.insert(self.spawned, obj)
		end

		if self.animation == "poof" then
			makepoof(obj.x+obj.width/2, obj.y+obj.height/2, poof)
		elseif self.animation and self.animation ~= "offset" then
			if obj.width and obj.height and (not obj.children) and (not obj.child) and not (obj.nospawnanimation) then
				table.insert(spawnanimations, spawnanimation:new(self.cox, self.coy, self.animation, obj))
			end
		end
		if not self.animation or self.animation == "poof" then
			--track
			if objtable and obj.width and obj.height then
				trackobject(self.cox, self.coy, obj, objtable)
			end
		end
	end
end

function enemytool:translateenemy()
	local t = self.enemy
	if t == "? ball" then
		self.enemy = "levelball"
	end
end