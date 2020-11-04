--Some SE functions (Also keep track of AE ADDITION s)
local function twistdirection(gravitydir, dir) --mario.lua
	if not gravitydir or (gravitydir > math.pi/4*1 and gravitydir <= math.pi/4*3) then
		if dir == "floor" then
			return "floor"
		elseif dir == "left" then
			return "left"
		elseif dir == "ceil" then
			return "ceil"
		elseif dir == "right" then
			return "right"
		end
	elseif gravitydir > math.pi/4*3 and gravitydir <= math.pi/4*5 then
		if dir == "floor" then
			return "left"
		elseif dir == "left" then
			return "ceil"
		elseif dir == "ceil" then
			return "right"
		elseif dir == "right" then
			return "floor"
		end
	elseif gravitydir > math.pi/4*5 and gravitydir <= math.pi/4*7 then
		if dir == "floor" then
			return "ceil"
		elseif dir == "left" then
			return "right"
		elseif dir == "ceil" then
			return "floor"
		elseif dir == "right" then
			return "left"
		end
	else
		if dir == "floor" then
			return "right"
		elseif dir == "left" then
			return "floor"
		elseif dir == "ceil" then
			return "left"
		elseif dir == "right" then
			return "ceil"
		end
	end
end

local function unwrap(a)
	while a < 0 do
		a = a + (math.pi*2)
	end
	while a > (math.pi*2) do
		a = a - (math.pi*2)
	end
	return a
end
local function angles(a1, a2)
	local a1 = unwrap(a1)-math.pi
	local a2 = unwrap(a2)-math.pi
	local diff = a1-a2
	if math.abs(diff) < math.pi then
		return a1 > a2
	else
		return diff < 0
	end
end
local function anglesdiff(a1, a2)
	local a1 = unwrap(a1)-math.pi
	local a2 = unwrap(a2)-math.pi
	return math.abs(a1-a2) --diff
end

enemy = class:new()

function enemy:init(x, y, t, a, properties)
	if not enemiesdata[t] then
		return nil
	end
	
	self.t = t
	if a then
		self.a = {unpack(a)}
	else
		self.a = {}
	end
	
	--Some standard values..
	self.rotation = 0
	self.active = true
	self.static = false
	self.mask = {}
	self.gravitydirection = math.pi/2
	
	self.combo = 1
	
	self.falling = false
	
	self.shot = false
	self.outtable = {}
	
	self.speedx = 0
	self.speedy = 0
	
	--Get our enemy's properties from the property table
	for i, v in pairs(enemiesdata[self.t]) do
		self[i] = v
	end
	if properties then
		for i, v in pairs(properties) do
			self[i] = v
		end
	end

	--right click menu
	if self.rightclickmenu and self.a[3] then
		local s = tostring(self.a[3])
		if self.rightclickmenutable then
			if tonumber(self.a[3]) then
				self.a[3] = tonumber(self.a[3])
			end
			if self.rightclickmenumultipleproperties then
				local t = self.rightclickmenu[self.a[3]]
				if t then
					for i, v in pairs(t) do
						local name = v[1]
						local value = v[2]
						if type(value) == "table" then
							self[name] = deepcopy(value)
						else
							self[name] = value
						end
						if name == "quadno" then
							self.quad = self.quadgroup[self.quadno]
						end
					end
				elseif testinglevel then
					notice.new("No rightclickmenu entry|for number:" .. tostring(self.a[3]), notice.red, 3)
				end
			else
				if type(self.rightclickmenu[self.a[3]]) == "table" then
					self[self.rightclickmenu[1]] = deepcopy(self.rightclickmenu[self.a[3]])
				else
					self[self.rightclickmenu[1]] = self.rightclickmenu[self.a[3]]
				end
				if self.rightclickmenu[1] == "quadno" then
					self.quad = self.quadgroup[self.quadno]
				end
			end
		else
			self.a[3] = s:gsub("B", "-")
			if tonumber(self.a[3]) then
				self.a[3] = tonumber(self.a[3])
			end

			if self.rightclickmenuboolean then
				self[self.rightclickmenu[1]] = (self.a[3] == "true")
			else
				self[self.rightclickmenu[1]] = self.a[3]
			end
			if self.rightclickmenu[1] == "quadno" then
				self.quad = self.quadgroup[self.quadno]
			end
		end
	end
	
	self.customtimer = deepcopy(self.customtimer)
	if self.customtimer then
		self.customtimertimer = 0
		self.currentcustomtimerstage = 1
		for i = 1, #self.customtimer do
			if type(self.customtimer[i]) == "string" then
				--comments
				table.remove(self.customtimer, i)
			end
		end
	end

	self.loops = 0
	self.startstage = {}
	self.endstage = {}
	self.looped = {}

	self.runtimer = false
	self.runtimerstage = 1
	self.runtimertimer = 0

	--Decide on a random movement if it's random..
	if self.movementrandoms then
		self.movement = self.movementrandoms[math.random(#self.movementrandoms)]
	end
	
	self.x = x-.5-self.width/2+(self.spawnoffsetx or 0)
	self.y = y-self.height+(self.spawnoffsety or 0)
	
	if self.animationtype == "mirror" then
		self.animationtimer = 0
		self.animationdirection = "left"
	elseif self.animationtype == "frames" then
		self.quadi = self.animationstart
		self.quad = self.quadgroup[self.quadi]
		self.animationtimer = 0

		if type(self.animationspeed) == "table" then
			self.animationtimerstage = 1
		end
	end

	if self.smallanimationstart and self.smallanimationframes then
		self.smallanimationtimer = 0
		self.smallanimationquadi = self.smallanimationstart
	end
	
	if self.stompanimation then
		self.deathtimer = 0
	end
	
	if self.shellanimal then
		self.upsidedown = false
		self.resettimer = 0
		self.wiggletimer = 0
		self.wiggleleft = true
		--self.returntilemaskontrackrelease = true
	end
	
	if self.customscissor then
		self.customscissor = {unpack(self.customscissor)}
		self.customscissor[1] = self.customscissor[1] + x - 1
		self.customscissor[2] = self.customscissor[2] + y - 1
	end
	
	if self.starttowardsplayerhorizontal or self.startawayfromplayerhorizontal then --Prize for best property name
		local closestplayer = 1
		self.animationdirection = "right"
		local closestdist = math.huge
		for i = 1, #objects["player"] do
			local v = objects["player"][i]
			local dist = math.sqrt((v.x-self.x)^2+(v.y-self.y)^2)
			if dist < closestdist then
				closestdist = dist
				closestplayer = i
			end
		end
		if objects["player"][closestplayer] then
			if objects["player"][closestplayer].x+objects["player"][closestplayer].width/2 < self.x+self.width/2 then
				self.speedx = -math.abs(self.speedx)
				if not self.dontmirror then --AE ADDITION
					self.animationdirection = "right"
				end
				if self.movement == "homing" then
					self.homingrotation = 0
				end
			else
				self.speedx = math.abs(self.speedx)
				if not self.dontmirror then --AE ADDITION
					self.animationdirection = "left"
				end
				if self.movement == "homing" then
					self.homingrotation = math.pi
				end
			end
			if self.startawayfromplayerhorizontal then
				self.speedx = -self.speedx
			end
		end
	end
	
	self.firstmovement = self.movement
	self.firstanimationtype = self.animationtype
	self.startoffsetY = self.offsetY
	self.startquadcenterY = self.quadcenterY
	self.startgravity = self.gravity
	self.startx = self.x
	self.starty = self.y
	
	self.spawnallow = true
	self.spawnedenemies = {}
	if self.movement == "piston" then
		self.pistontimer = self.pistonretracttime
		self.pistonstate = "retracting"
		
		if self.spawnonlyonextended then
			self.spawnallow = false
		end
	elseif self.movement == "flyvertical" or self.movement == "flyhorizontal" then
		self.flyingtimer = 0
		self.startx = self.x
		self.starty = self.y
	elseif self.movement == "squid" then
		self.squidstate = "idle"
	elseif self.movement == "circle" then
		self.startx = self.x
		self.starty = self.y
		if not self.circletimer then
			self.circletimer = 0
		end
	elseif self.movement == "path" then
		self.startx = self.x
		self.starty = self.y
		self.movementpathstep = 1
		self.movementpathbackwards = false
	elseif self.movement == "crawl" then
		if self.crawlfloor == "up" then
			self.gravity = -self.crawlgravity
			self.gravityx = 0
			if self.crawldirection == "left" then self.speedx = self.crawlspeed else self.speedx = -self.crawlspeed end
		elseif self.crawlfloor == "left" then
			self.gravity = 0
			self.gravityx = -self.crawlgravity
			if self.crawldirection == "left" then self.speedy = -self.crawlspeed else self.speedy = self.crawlspeed end
		elseif self.crawlfloor == "right" then
			self.gravity = 0
			self.gravityx = self.crawlgravity
			if self.crawldirection == "left" then self.speedy = self.crawlspeed else self.speedy = -self.crawlspeed end
		else
			self.gravity = self.crawlgravity
			if self.crawldirection == "left" then self.speedx = -self.crawlspeed else self.speedx = self.crawlspeed end
			self.gravityx = 0
		end
		self.ignorelowgravity = true
		self.aroundcorner = false
	elseif self.movement == "homing" then
		if self.starthomingrotationtowardsplayer then --starting rotation is towards player
			local closestplayer = 1 --find closest player
			local relativex, relativey, dist
			for i = 1, players do
				local v = objects["player"][i]
				relativex, relativey = (v.x + -self.x), (v.y + -self.y)
				distance = math.sqrt(relativex*relativex+relativey*relativey)
				if ((not dist) or (distance < dist)) and not v.dead then
					closestplayer = i
				end
			end
			local p = objects["player"][closestplayer]
			if p then
				local angle = -math.atan2((p.x+p.width/2)-(self.x+self.width/2), (p.y+p.height/2)-(self.y+self.height/2))-math.pi/2
				self.homingrotation = unwrap(angle)
			end
		end
		if self.upsidedownifhomingrotationright then
			if (self.homingrotation >= math.pi*.5 and self.homingrotation <= math.pi*1.5) then
				self.upsidedown = true
			end
		end
	elseif self.movement == "chase" then
		self.movedirection = "left"
		self.movedirectiony = "left"
	end
	
	if self.speedxtowardsplayer or self.speedxawayfromplayer then
		local closestplayer = 1
		local closestdist = math.sqrt((objects["player"][1].x-self.x)^2+(objects["player"][1].y-self.y)^2)
		for i = 2, players do
			local v = objects["player"][i]
			local dist = math.sqrt((v.x-self.x)^2+(v.y-self.y)^2)
			if dist < closestdist then
				closestdist = dist
				closestplayer = i
			end
		end
		
		if objects["player"][closestplayer].x + objects["player"][closestplayer].width/2 > self.x + self.width/2 then
			self:leftcollide("", {}, "", {})
			self.speedx = math.abs(self.speedx)
		else
			self:rightcollide("", {}, "", {})
			self.speedx = -math.abs(self.speedx)
		end

		
		if self.speedxawayfromplayer then
			self.speedx = -self.speedx
		end
	end
	
	if self.lifetimerandoms then
		self.lifetime = self.lifetimerandoms[math.random(#self.lifetimerandoms)]
	end
	if self.lifetime and self.lifetime >= 0 then
		self.lifetimer = self.lifetime
	end
	
	if self.jumps then
		self.jumptimer = 0
	end
	
	if self.spawnsenemy then
		self.spawnenemytimer = 0
		self.spawnenemydelay = self.spawnenemydelays[math.random(#self.spawnenemydelays)]
	end

	if self.bounces and (self.bouncedelay or self.bouncedelays) then
		self.bouncetimer = 0
		if self.bouncedelays then
			if self.bouncedelaysrandoms then
				self.bouncedelay = self.bouncedelays[math.random(#self.bouncedelays)]
			else
				self.bouncetimerstage = 1
				self.bouncedelay = self.bouncedelays[self.bouncetimerstage]
			end
		end
	end
	
	self.throwanimationstate = 0
	
	if self.chasetime then
		self.chasetimer = 0
	end
	
	if self.spawnsound then
		if self.sound and self.spawnsound == self.t then
			playsound(self.sound)
		else
			playsound(self.spawnsound)
		end
	end

	if self.poofonspawn then
		makepoof(self.x+self.width/2, self.y+self.height/2, self.poofonspawn)
	end

	self.children = {}
	if self.spawnchildren then
		if not (self.a and self.a[1] == "ignorespawnchildren") then
			for i = 1, #self.spawnchildren do
				local offsetx = self.spawnchildrenoffsetx or 0
				if type(self.spawnchildrenoffsetx) == "table" then
					offsetx = self.spawnchildrenoffsetx[i]
				end
				local offsety = self.spawnchildrenoffsety or 0
				if type(self.spawnchildrenoffsety) == "table" then
					offsety = self.spawnchildrenoffsety[i]
				end
				local temp = enemy:new(self.x+self.width/2+.5+offsetx, self.y+self.height+offsety, self.spawnchildren[i], {"ignorespawnchildren"})
				table.insert(objects["enemy"], temp)

				--set
				local set = self.spawnchildrenset or nil
				if type(self.spawnchildrenset) == "table" then
					set = self.spawnchildrenset[i]
				end
				if set then
					for p = 1, #set do
						temp[set[p][1]] = set[p][2]
					end
				end

				--pass
				local pass = self.spawnchildrenpass or nil 
				if type(self.spawnchildrenpass) == "table" then
					pass = self.spawnchildrenpass[i]
				end
				if pass then
					for p = 1, #pass do
						temp[pass[p][1]] = self[pass[p][1]] or nil
					end
				end
			end
		end
	end

	if self.carryable then
		self.rigidgrab = true
		self.carryparent = false
		self.userect = adduserect(self.x+self.carryrange[1], self.y+self.carryrange[2], self.carryrange[3], self.carryrange[4], self)
		if self.throwntime then
			self.throwntimer = 0
		end
	end

	if self.jumps or self.noplayercollisiononthrow then
		--make copy of mask table, otherwise it modifies it for every enemy
		self.mask = deepcopy(self.mask)
	end

	if self.freezable == nil then
		self.freezable = true --AE ADDITION
	end

	if self.movement == "circle" then
		if self.circletimer ~= 0 then
			local v = ((self.circletimer/(self.circletime or 1))*math.pi*2)
			local newx = math.sin(v)*(self.circleradiusx or self.circleradius or 1) + self.startx
			local newy = math.cos(v)*(self.circleradiusy or self.circleradius or 1) + self.starty
			self.x = newx
			self.y = newy
		end
	end

	--snap position to tile grid
	if self.snapxtogrid then
		self.x = round(self.x)+(self.snapxtogridoffset or 0)
	end
	if self.snapytogrid then
		self.y = round(self.y)+(self.snapytogridoffset or 0)
	end

	--platform collision (ignore side collisions without any callbacks)
	if self.platformcollisionup then self.PLATFORM = true end
	if self.platformcollisiondown then self.PLATFORMDOWN = true end
	if self.platformcollisionleft then self.PLATFORMLEFT = true end
	if self.platformcollisionright then self.PLATFORMRIGHT = true end

	--block portals
	if self.blockportaltile then
		local t = {math.floor(x), math.floor(y)}
		if type(self.blockportaltile) == "table" then
			t = {math.floor(x)+math.floor(self.blockportaltile[1]), math.floor(y)+math.floor(self.blockportaltile[2])}
		end
		self.blockportaltilecoordinate = tilemap(t[1], t[2])
		blockedportaltiles[self.blockportaltilecoordinate] = true
	end
	
	self.outtable = {}
end

function enemy:dosupersize()
	if self.supersizescript then
		self:script(self.supersizescript, "supersize")
	end
end

function enemy:update(dt)
	--Just spawned
	if self.justspawned then
		self.justspawned = nil
	end

	--perish
	if levelfinished and levelfinishtype == "flag" and self.deleteonflagpole then
		self.instantdelete = true
		return
	end

	--Funnels and fuck
	if self.funnel and not self.infunnel then
		self:enteredfunnel(true)
	end
	
	if self.infunnel and not self.funnel then
		self:enteredfunnel(false)
	end

	self.funnel = false
	if self.lifetimer and not self.shot then
		self.lifetimer = self.lifetimer - dt
		if self.lifetimer <= 0 then
			if self.transforms and self:gettransformtrigger("lifetime") then
				self:transform(self:gettransformsinto("lifetime"))
			end
			self:output()
			self.dead = true
			
			return true
		end
	end
	
	if self.transformkill then
		if self.transformkilldeath then
			self:output()
		else
			self:output("transformed")
		end
		self.dead = true
		
		return true
	elseif self.kill then
		self:output()
		self.dead = true
		
		return true
	end
	
	if self.stompanimation and self.dead then
		self.deathtimer = self.deathtimer + dt
		if self.deathtimer > (self.stompanimationtime or 0.5) then
			self:output()
			
			return true
		else
			return false
		end
	end
	
	if (not self.doesntunrotate) and (not self.rotationanimation) and (not self.rollanimation) then
		self.rotation = unrotate(self.rotation, self.gravitydirection, dt)
	end
	
	if self.shot then
		self.speedy = self.speedy + shotgravity*dt
		
		self.x = self.x+self.speedx*dt
		self.y = self.y+self.speedy*dt
		
		return false
	end

	if self.frozen then
		return false
	end

	if self.rotationanimation then
		self.rotation = self.rotation + (self.rotationanimationspeed or 1)*dt
	end
	if self.rollanimation then
		self.rotation = self.rotation + self.speedx*math.pi*dt
	end

	local oldx, oldy
	if self.platform then
		oldx, oldy = self.x, self.y
	end

	if self.float then
		self.risingwater = false
	end
	
	if self.animationtype == "mirror" then
		self.animationtimer = self.animationtimer + dt
		while self.animationtimer > self.animationspeed do
			self.animationtimer = self.animationtimer - self.animationspeed
			if self.animationdirection == "left" then
				self.animationdirection = "right"
			else
				self.animationdirection = "left"
			end
		end
	elseif self.animationtype == "frames" then
		self.animationtimer = self.animationtimer + dt
		if type(self.animationspeed) == "table" then
			while self.animationtimer > self.animationspeed[self.animationtimerstage] do
				self.animationtimer = self.animationtimer - self.animationspeed[self.animationtimerstage]
				self.quadi = self.quadi + 1
				if self.quadi > self.animationstart + self.animationframes - 1 then
					self.quadi = self.quadi - self.animationframes
				end
				self.quad = self.quadgroup[self.quadi]
				self.animationtimerstage = self.animationtimerstage + 1
				if self.animationtimerstage > #self.animationspeed then
					self.animationtimerstage = 1
				end
			end
		else
			while self.animationtimer > self.animationspeed do
				self.animationtimer = self.animationtimer - self.animationspeed
				self.quadi = self.quadi + 1
				if self.quadi > self.animationstart + self.animationframes - 1 then
					self.quadi = self.quadi - self.animationframes
				end
				self.quad = self.quadgroup[self.quadi]
			end
		end
		
		if not self.dontmirror then --AE ADDITION
			if self.speedx > 0 then
				self.animationdirection = "left"
			elseif self.speedx < 0 then
				self.animationdirection = "right"
			end
		end
	end
	
	if self.spawnsenemy then
		if lakitoend and self.movement == "follow" and (not self.ignorelakitoend) then
			self.speedx = -3
			return false
		end
		
		local playernear = false
		if self.dontspawnenemyonplayernear or self.spawnenemyonplayernear then
			local dist = self.spawnenemydist or self.dontspawnenemydist or 3
			if type(dist) == "table" then
				local col = checkrect(self.x+dist[1], self.y+dist[2], dist[3], dist[4], {"player"})
				if #col > 0 then
					playernear = true
				end
			else
				for i = 1, players do
					local v = objects["player"][i]
					if inrange(v.x+v.width/2, self.x+self.width/2-(dist), self.x+self.width/2+(dist)) then
						playernear = true
						break
					end
				end
			end
			if self.spawnenemyonplayernear then
				playernear = not playernear
			end
		end

		if (not playernear) then
			self.spawnenemytimer = self.spawnenemytimer + dt
			while self.spawnenemytimer >= self.spawnenemydelay and self.spawnallow and (not self.spawnmax or self:getspawnedenemies() < self.spawnmax) do
				if self.spawnsenemyrandoms then
					self.spawnsenemy = self.spawnsenemyrandoms[math.random(#self.spawnsenemyrandoms)]
				end
				self:spawnenemy(self.spawnsenemy)
				self.spawnenemytimer = 0
				self.spawnenemydelay = self.spawnenemydelays[math.random(#self.spawnenemydelays)]
				self.throwanimationstate = 0
				if self.animationtype == "frames" then
					self.quad = self.quadgroup[self.quadi + self.throwanimationstate]
				end
			end
			
			if self.throwpreparetime and self.spawnenemytimer >= (self.spawnenemydelay - self.throwpreparetime) then
				self.throwanimationstate = self.throwquadoffset
				if self.animationtype == "frames" then
					self.quad = self.quadgroup[self.quadi + self.throwanimationstate]
				end
			end
		end
	end

	if self.bounces and self.bouncedelay and (not self.falling) then
		self.bouncetimer = self.bouncetimer + dt
		if self.bouncetimer > self.bouncedelay then
			local force = self.bounceforce
			if type(self.bounceforce) == "table" then
				if self.bouncetimerstage and not self.bounceforcerandom then
					force = self.bounceforce[self.bouncetimerstage]
				else
					force = self.bounceforce[math.floor(#self.bounceforce)]
				end
			end
			self.speedy = -(force or 10)
			self.bouncetimer = 0
			if self.bouncetimerstage then
				self.bouncetimerstage = self.bouncetimerstage + 1
				if self.bouncetimerstage > #self.bouncedelays then
					self.bouncetimerstage = 1
				end
				self.bouncedelay = self.bouncedelays[self.bouncetimerstage]
			elseif self.bouncedelaysrandoms then
				self.bouncedelay = self.bouncedelays[math.random(#self.bouncedelays)]
			end
		end
	end
	
	if self.movement == "truffleshuffle" then
		if self.speedx > 0 then
			if self.speedx > self.truffleshufflespeed then
				self.speedx = self.speedx - self.truffleshuffleacceleration*dt*2
				if self.speedx < self.truffleshufflespeed then
					self.speedx = self.truffleshufflespeed
				end
			elseif self.speedx < self.truffleshufflespeed then
				self.speedx = self.speedx + self.truffleshuffleacceleration*dt*2
				if self.speedx > self.truffleshufflespeed then
					self.speedx = self.truffleshufflespeed
				end
			end
		else
			if self.speedx < -self.truffleshufflespeed then
				self.speedx = self.speedx + self.truffleshuffleacceleration*dt*2
				if self.speedx > -self.truffleshufflespeed then
					self.speedx = -self.truffleshufflespeed
				end
			elseif self.speedx > -self.truffleshufflespeed then
				self.speedx = self.speedx - self.truffleshuffleacceleration*dt*2
				if self.speedx < -self.truffleshufflespeed then
					self.speedx = -self.truffleshufflespeed
				end
			end
		end
		
		if self.turnaroundoncliff and self.falling == false then
			--check if nothing below
			local x, y = math.floor(self.x + self.width/2+1), math.floor(self.y + self.height+1.5)
			if inmap(x, y) and (not checkfortileincoord(x, y)) and ((inmap(x+.5, y) and checkfortileincoord(math.ceil(x+.5), y)) or (inmap(x-.5, y) and checkfortileincoord(math.floor(x-.5), y))) then
				if self.speedx < 0 then
					self.x = x-self.width/2
				else
					self.x = x-1-self.width/2
				end
				self.speedx = -self.speedx
			end
		end

		if edgewrapping then --wrap around screen
			local minx, maxx = -self.width, mapwidth
			if self.x < minx then
				self.x = maxx
			elseif self.x > maxx then
				self.x = minx
			end
		end
		
	elseif self.movement == "shell" then
		if self.small then
			if self.wakesup then
				if math.abs(self.speedx) < 0.0001 then
					self.resettimer = self.resettimer + dt
					if self.resettimer > self.resettime then
						self.offsetY = self.startoffsetY
						self.quadcenterY = self.startquadcenterY
						self.quad = self.quadgroup[self.animationstart]
						self.small = false
						self.speedx = -self.truffleshufflespeed
						self.resettimer = 0
						self.upsidedown = false
						self.kickedupsidedown = false
						self.movement = self.firstmovement
						self.animationtype = self.firstanimationtype
						
						if self.chasemarioonwakeup then
							local px = objects["player"][getclosestplayer(self.x)].x --AE ADDITION (changed x to self.x)
							if px > self.x then
								self.speedx = -self.speedx
							end
						end
					elseif self.resettimer > self.resettime-self.wiggletime then
						self.wiggletimer = self.wiggletimer + dt
						while self.wiggletimer > self.wiggledelay do
							self.wiggletimer = self.wiggletimer - self.wiggledelay
							if self.wiggleleft then
								if self.wigglequad then
									self.offsetY = self.wiggleoffsety or self.startoffsetY
									self.quadcenterY = self.wigglequadcentery or self.startquadcenterY
									if self.upsidedown then
										self.offsetY = self.upsidedownwiggleoffsety or self.upsidedownoffsety or 4
										self.quadcenterY = self.upsidedownwigglequadcentery or self.wigglequadcentery or self.upsidedownquadcentery or self.startquadcenterY
									end
									self.quad = self.quadgroup[self.wigglequad]
								else
									self.x = self.x + 1/16
								end
							else
								if self.wigglequad then
									self.offsetY = self.startoffsetY
									self.quadcenterY = self.startquadcenterY
									if self.upsidedown then
										self.offsetY = self.upsidedownoffsety or 4
										self.quadcenterY = self.upsidedownquadcentery or self.startquadcenterY
									end
									self.quad = self.quadgroup[self.smallquad]
								else
									self.x = self.x - 1/16
								end
							end
							self.wiggleleft = not self.wiggleleft
						end
					end
				else
					self.resettimer = 0
				end
			end
			if math.abs(self.speedx) >= 0.0001 then
				--shell animation
				if self.smallanimationstart and self.smallanimationframes and not self.kickedupsidedown then
					self.smallanimationtimer = self.smallanimationtimer + dt
					while self.smallanimationtimer > self.smallanimationspeed do
						self.smallanimationtimer = self.smallanimationtimer - self.smallanimationspeed
						self.smallanimationquadi = self.smallanimationquadi + 1
						if self.smallanimationquadi > self.smallanimationstart + self.smallanimationframes - 1 then
							self.smallanimationquadi = self.smallanimationquadi - self.smallanimationframes
						end
						self.quad = self.quadgroup[self.smallanimationquadi]
					end
				end
			end
		end
		
		if edgewrapping then --wrap around screen
			local minx, maxx = -self.width, mapwidth
			if self.x < minx then
				self.x = maxx
			elseif self.x > maxx then
				self.x = minx
			end
		end
		
	elseif self.movement == "follow" then
		local nearestplayer = 1
		while objects["player"][nearestplayer] and objects["player"][nearestplayer].dead do
			nearestplayer = nearestplayer + 1
		end
		
		if objects["player"][nearestplayer] then
			local nearestplayerx = objects["player"][nearestplayer].x
			for i = 2, players do
				local v = objects["player"][i]
				if v.x > nearestplayerx and not v.dead then
					nearestplayer = i
				end
			end
			
			nearestplayerx = nearestplayerx + objects["player"][nearestplayer].speedx*(self.distancetime or 1)
			
			local distance = math.abs(self.x - nearestplayerx)
			
			--check if too far in wrong direction
			if (not self.direction or self.direction == "left") and self.x < nearestplayerx-self.followspace then
				self.direction = "right"
				if not self.dontmirror then --AE ADDITION
					self.animationdirection = "right"
				end
			elseif self.direction == "right" and self.x > nearestplayerx+self.followspace then
				self.direction = "left"
				if not self.dontmirror then --AE ADDITION
					self.animationdirection = "left"
				end
			end
			
			if self.direction == "right" then
				if self.nofollowspeedup then
					self.speedx = self.followspeed or 2
				else
					self.speedx = math.max((self.followspeed or 2), round((distance-3)*2))
				end
			else
				self.speedx = -(self.followspeed or 2)
			end
		end
	elseif self.movement == "chase" then
		local closestplayer = 1 --find closest player
		for i = 2, players do
			local v = objects["player"][i]
			if math.abs(self.x - v.x) < math.abs(self.x - objects["player"][closestplayer].x) then
				closestplayer = i
			end
		end
		local p = objects["player"][closestplayer]
		if self.chasespeed then
			if self.x+self.width/2 > p.x+p.width/2 + (self.chasespace or 2) then
				if not self.dontmirror then
					self.animationdirection = "right"
				end
				self.movedirection = "right"
			elseif self.x+self.width/2 < p.x+p.width/2 - (self.chasespace or 2) then
				if not self.dontmirror then
					self.animationdirection = "left"
				end
				self.movedirection = "left"
			end
			if self.movedirection == "left" then
				if self.speedx > self.chasespeed then
					self.speedx = self.speedx - self.chaseacceleration*dt*2
					if self.speedx < self.chasespeed then
						self.speedx = self.chasespeed
					end
				elseif self.speedx < self.chasespeed then
					self.speedx = self.speedx + self.chaseacceleration*dt*2
					if self.speedx > self.chasespeed then
						self.speedx = self.chasespeed
					end
				end
			else
				if self.speedx < -self.chasespeed then
					self.speedx = self.speedx + self.chaseacceleration*dt*2
					if self.speedx > -self.chasespeed then
						self.speedx = -self.chasespeed
					end
				elseif self.speedx > -self.chasespeed then
					self.speedx = self.speedx - self.chaseacceleration*dt*2
					if self.speedx < -self.chasespeed then
						self.speedx = -self.chasespeed
					end
				end
			end
		end
		if self.chasespeedy then
			if self.y+self.height/2 > p.y+p.height/2 + (self.chasespacey or 2) then
				if not self.dontmirror then
					self.animationdirectiony = "right"
				end
				self.movedirectiony = "right"
			elseif self.y+self.height/2 < p.y+p.height/2 - (self.chasespacey or 2) then
				if not self.dontmirror then
					self.animationdirectiony = "left"
				end
				self.movedirectiony = "left"
			end
			if self.movedirectiony == "left" then
				if self.speedy > self.chasespeedy then
					self.speedy = self.speedy - self.chaseaccelerationy*dt*2
					if self.speedy < self.chasespeedy then
						self.speedy = self.chasespeedy
					end
				elseif self.speedy < self.chasespeedy then
					self.speedy = self.speedy + self.chaseaccelerationy*dt*2
					if self.speedy > self.chasespeedy then
						self.speedy = self.chasespeedy
					end
				end
			else
				if self.speedy < -self.chasespeedy then
					self.speedy = self.speedy + self.chaseaccelerationy*dt*2
					if self.speedy > -self.chasespeedy then
						self.speedy = -self.chasespeedy
					end
				elseif self.speedy > -self.chasespeedy then
					self.speedy = self.speedy - self.chaseaccelerationy*dt*2
					if self.speedy < -self.chasespeedy then
						self.speedy = -self.chasespeedy
					end
				end
			end
		end

		if self.turnaroundoncliff and self.falling == false then
			--check if nothing below
			local x, y = math.floor(self.x + self.width/2+1), math.floor(self.y + self.height+1.5)
			if inmap(x, y) and tilequads[map[x][y][1]]:getproperty("collision", x, y) == false and ((inmap(x+.5, y) and tilequads[map[math.ceil(x+.5)][y][1]]:getproperty("collision", math.ceil(x+.5), y)) or (inmap(x-.5, y) and tilequads[map[math.floor(x-.5)][y][1]]:getproperty("collision", math.floor(x-.5), y))) then
				if self.speedx < 0 then
					self.x = x-self.width/2
					self.movedirection = "right"
				else
					self.x = x-1-self.width/2
					self.movedirection = "left"
				end
				self.speedx = -self.speedx
			end
		end

		if edgewrapping then --wrap around screen
			local minx, maxx = -self.width, mapwidth
			if self.x < minx then
				self.x = maxx
			elseif self.x > maxx then
				self.x = minx
			end
		end
	elseif self.movement == "piston" then
		self.pistontimer = self.pistontimer + dt
		
		if self.pistonstate == "extending" then		
			--move X
			if self.x > self.startx + self.pistondistx then
				self.x = self.x - self.pistonspeedx*dt
				if self.x < self.startx + self.pistondistx then
					self.x = self.startx + self.pistondistx
				end
			elseif self.x < self.startx + self.pistondistx then
				self.x = self.x + self.pistonspeedx*dt
				if self.x > self.startx + self.pistondistx then
					self.x = self.startx + self.pistondistx
				end
			end
			
			--move Y
			if self.y > self.starty + self.pistondisty then
				self.y = self.y - self.pistonspeedy*dt
				if self.y < self.starty + self.pistondisty then
					self.y = self.starty + self.pistondisty
				end
			elseif self.y < self.starty + self.pistondisty then
				self.y = self.y + self.pistonspeedy*dt
				if self.y > self.starty + self.pistondisty then
					self.y = self.starty + self.pistondisty
				end
			end
			
			if self.x == self.startx + self.pistondistx and self.y == self.starty + self.pistondisty and not self.spawnallow then
				self.spawnallow = true
				self.spawnenemytimer = self.spawnenemydelay
			end
			
			if self.pistontimer > self.pistonextendtime then
				self.pistontimer = 0
				self.spawnallow = false
				self.pistonstate = "retracting"
			end
			
			
		else --retracting			
			--move X
			if self.x > self.startx then
				self.x = self.x - self.pistonspeedx*dt
				if self.x < self.startx then
					self.x = self.startx
				end
			elseif self.x < self.startx then
				self.x = self.x + self.pistonspeedx*dt
				if self.x > self.startx then
					self.x = self.startx
				end
			end
			
			--move Y
			if self.y > self.starty then
				self.y = self.y - self.pistonspeedy*dt
				if self.y < self.starty then
					self.y = self.starty
				end
			elseif self.y < self.starty then
				self.y = self.y + self.pistonspeedy*dt
				if self.y > self.starty then
					self.y = self.starty
				end
			end
			
			if self.inactiveonretracted and self.x == self.startx and self.y == self.starty then
				self.active = false
			end
			
			if self.pistontimer > self.pistonretracttime then
				local playernear = false
				for i = 1, players do
					local v = objects["player"][i]
					if inrange(v.x+v.width/2, self.x+self.width/2-(self.dontpistondist or 3), self.x+self.width/2+(self.dontpistondist or 3)) then
						playernear = true
						break
					end
				end
				
				if not self.dontpistonnearplayer or not playernear then
					self.pistontimer = 0
					self.pistonstate = "extending"
					self.active = true
				end
			end
		end
	elseif self.movement == "wiggle" and (not self.track) then
		if self.speedx < 0 then
			if self.x < self.startx-self.wiggledistance then
				self.speedx = self.wigglespeed or 1
			end
		elseif self.speedx > 0 then
			if self.x > self.startx then
				self.speedx = -self.wigglespeed or 1
			end
		else
			self.speedx = self.wigglespeed or 1
		end
		
	elseif self.movement == "verticalwiggle" and (not self.track) then
		if self.speedy < 0 then
			if self.y < self.starty-self.verticalwiggledistance then
				self.speedy = self.verticalwigglespeed or 1
			end
		elseif self.speedy > 0 then
			if self.y > self.starty then
				self.speedy = -self.verticalwigglespeed or 1
			end
		else
			self.speedy = self.verticalwigglespeed or 1
		end
		
	elseif self.movement == "rocket" then
		if self.y > self.starty+(self.rocketdistance or 15) and self.speedy > 0 then
			self.y = self.starty+(self.rocketdistance or 15)
			
			self.speedy = -math.sqrt(2*(self.gravity or yacceleration)*(self.rocketdistance or 15))
		end
		
		if self.speedy < 0 then
			self.upsidedown = false
		else
			self.upsidedown = true
		end
		
	elseif self.movement == "squid" and (not self.track) then
		local closestplayer = 1
		local closestdist = math.sqrt((objects["player"][1].x-self.x)^2+(objects["player"][1].y-self.y)^2)
		for i = 2, players do
			local v = objects["player"][i]
			local dist = math.sqrt((v.x-self.x)^2+(v.y-self.y)^2)
			if dist < closestdist then
				closestdist = dist
				closestplayer = i
			end
		end
		
		if self.squidstate == "idle" then
			self.speedy = self.squidfallspeed
			
			--get if change state to upward
			if (self.y+self.speedy*dt) + self.height + 0.0625 >= (objects["player"][closestplayer].y - (24/16 - objects["player"][closestplayer].height)) then
				self.squidstate = "upward"
				self.upx = self.x
				self.speedx = 0
				self.speedy = 0
				
				if self.animationtype == "squid" then
					self.quad = self.quadgroup[2]
				end
				
				--get if to change direction
				if true then--math.random(2) == 1 then
					if self.direction == "right" then
						if self.x > objects["player"][closestplayer].x then
							self.direction = "left"
						end
					else
						if self.x < objects["player"][closestplayer].x then
							self.direction = "right"
						end
					end
				end
			end
			
		elseif self.squidstate == "upward" then
			if self.direction == "right" then
				self.speedx = self.speedx + self.squidacceleration*dt
				if self.speedx > self.squidxspeed then
					self.speedx = self.squidxspeed
				end
			else
				self.speedx = self.speedx - self.squidacceleration*dt
				if self.speedx < -self.squidxspeed then
					self.speedx = -self.squidxspeed
				end
			end
			
			self.speedy = self.speedy - self.squidacceleration*dt
			
			if self.speedy < -self.squidupspeed then
				self.speedy = -self.squidupspeed
			end
			
			if math.abs(self.x - self.upx) >= (self.squidhordistance or 2) then
				self.squidstate = "downward"
				self.downy = self.y
				self.speedx = 0
			end
			
		elseif self.squidstate == "downward" then
			self.speedy = self.squidfallspeed
			if self.y > self.downy + self.squiddowndistance then
				self.squidstate = "idle"
			end
			
			if self.animationtype == "squid" then
				self.quad = self.quadgroup[1]
			end
		end
		
	elseif self.movement == "targety" and (not self.track) then
		if self.y > self.targety then
			self.y = self.y - self.targetyspeed*dt
			if self.y < self.targety then
				self.y = self.targety
			end
		elseif self.y < self.targety then
			self.y = self.y + self.targetyspeed*dt
			if self.y > self.targety then
				self.y = self.targety
			end
		end
	elseif self.movement == "flyvertical" and (not self.track) then
		self.flyingtimer = self.flyingtimer + dt
		
		while self.flyingtimer > (self.flyingtime or 7) do
			self.flyingtimer = self.flyingtimer - (self.flyingtime or 7)
		end
		
		local newy = self:func(self.flyingtimer/(self.flyingtime or 7))*(self.flyingdistance or 7.5) + self.starty
		self.y = newy
	elseif self.movement == "flyhorizontal" and (not self.track) then
		self.flyingtimer = self.flyingtimer + dt
		
		while self.flyingtimer > (self.flyingtime or 7) do
			self.flyingtimer = self.flyingtimer - (self.flyingtime or 7)
		end
		
		local newx = self:func(self.flyingtimer/(self.flyingtime or 7))*(self.flyingdistance or 7.5) + self.startx
		if not self.dontmirror then
			if newx > self.x then --AE ADDITION
				self.animationdirection = "left"
			else
				self.animationdirection = "right"
			end
		end

		self.x = newx
	elseif self.movement == "circle" then --AE ADDITION
		self.circletimer = self.circletimer + dt
		
		while self.circletimer > math.abs(self.circletime or 1) do
			self.circletimer = self.circletimer - math.abs(self.circletime or 1)
		end
		
		local v = ((self.circletimer/(self.circletime or 1))*math.pi*2)
		local newx = math.sin(v)*(self.circleradiusx or self.circleradius or 1) + self.startx
		local newy = math.cos(v)*(self.circleradiusy or self.circleradius or 1) + self.starty
		self.x = newx
		self.y = newy
	elseif self.movement == "homing" then --AE ADDITION
		local p
		local pass = true
		if self.homingatenemy then
			local dist
			for i, v in pairs(objects["enemy"]) do
				if (type(self.homingatenemy) == "string" and v.t == self.homingatenemy) or (type(self.homingatenemy) == "table" and tablecontains(self.homingatenemy, v.t)) then
					local relativex, relativey = (v.x + -self.x), (v.y + -self.y)
					local distance = math.sqrt(relativex*relativex+relativey*relativey)
					if ((not dist) or (distance < dist)) then
						p = v; dist = distance
					end
				end
			end
		else
			local closestplayer = 1 --find closest player
			local relativex, relativey, dist, distance
			for i = 1, players do
				local v = objects["player"][i]
				relativex, relativey = (v.x + -self.x), (v.y + -self.y)
				distance = math.sqrt(relativex*relativex+relativey*relativey)
				if ((not dist) or (distance < dist)) and (not v.dead) then
					closestplayer = i; dist = distance
				end
			end
			p = objects["player"][closestplayer]
		end
		if p and self.stophomingdist then --stop homing if player is too close
			local relativex, relativey = (p.x + -self.x), (p.y + -self.y)
			if math.sqrt(relativex*relativex+relativey*relativey) < self.stophomingdist then
				self.speedx, self.speedy = 0, 0
				pass = false
			end
		end
		if p and pass then
			local oldhomingrotation = self.homingrotation
			local angle = -math.atan2((p.x+p.width/2)-(self.x+self.width/2), (p.y+p.height/2)-(self.y+self.height/2))-math.pi/2
			if angles(angle, self.homingrotation) then
				self.homingrotation = self.homingrotation + self.homingturnspeed*dt
			else
				self.homingrotation = self.homingrotation - self.homingturnspeed*dt
			end
			if self.onlymovewhenhomingrotationatplayer and anglesdiff(angle, self.homingrotation) > self.onlymovewhenhomingrotationatplayerthreshold then
				--stop chasing if not facing player
				self.speedx, self.speedy = 0, 0
			else
				self.speedx, self.speedy = math.cos(self.homingrotation+math.pi)*(self.homingspeed), math.sin(self.homingrotation+math.pi)*(self.homingspeed)
				if self.dontchangehomingrotationwhenmoving then
					self.homingrotation = oldhomingrotation
				end
			end
		end
		if self.rotationishomingrotation then
			self.rotation = self.homingrotation
		end
	elseif self.movement == "path" then
		local speedx, speedy = 0, 0
		local oldx, oldy = self.x, self.y
		local timedist = dt --how much time passed
		while timedist > 0 do
			local movedpasttarget = false
			local tx, ty = self.startx+self.movementpath[self.movementpathstep][1]+(self.movementpathoffsetx or 0), self.starty+self.movementpath[self.movementpathstep][2]+(self.movementpathoffsety or 0)
			local angle = -math.atan2(tx-self.x, ty-self.y)-math.pi/2
			local speed = self.movementpathspeed
			if type(self.movementpathspeed) == "table" then
				speed = self.movementpathspeed[self.movementpathstep]
			end

			self.x = self.x + (math.cos(angle+math.pi)*(speed))*timedist
			self.y = self.y + (math.sin(angle+math.pi)*(speed))*timedist

			--face or rotate
			if self.rotatetowardsmovementpath then
				self.rotation = angle
			else
				if not self.dontmirror then
					if self.x > oldx then
						self.animationdirection = "left"
					else
						self.animationdirection = "right"
					end
				end
			end

			--check if it is past target
			if ((oldx < tx and self.x > tx) or (oldx > tx and self.x < tx)) or ((oldy < ty and self.y > ty) or (oldy > ty and self.y < ty)) then
				movedpasttarget = true
			end

			if movedpasttarget then
				local distancemoved = math.sqrt((oldx-self.x)*(oldx-self.x)+(oldy-self.y)*(oldy-self.y))
				local targetdistance = math.sqrt((oldx-tx)*(oldx-tx)+(oldy-ty)*(oldy-ty))
				if self.movementpathbackwards then
					self.movementpathstep = self.movementpathstep - 1
					if self.movementpathstep < 1 then
						self.movementpathbackwards = false
						self.movementpathstep = 2
					end
				else
					self.movementpathstep = self.movementpathstep + 1
					--end of path, either loop back or bounce
					if self.movementpathstep > #self.movementpath then
						if self.transforms and self:gettransformtrigger("movementpathend") then
							self:transform(self:gettransformsinto("movementpathend"))
							return
						end
						if self.movementpathturnaround then
							self.movementpathstep = math.max(1, self.movementpathstep - 2)
							self.movementpathbackwards = true
						else
							self.movementpathstep = 1
						end
					end
				end
				self.x = tx
				self.y = ty
				oldx, oldy = self.x, self.y
				timedist = timedist - math.abs(distancemoved-targetdistance)/speed
			else
				timedist = 0
			end
		end
	elseif self.movement == "crawl" then
		if self.crawlrotation then 
			if self.crawlfloor == "down" then
				self.rotation = 0
			elseif self.crawlfloor == "up" then
				self.rotation = math.pi
			elseif self.crawlfloor == "right" then
				self.rotation = math.pi*1.5
			elseif self.crawlfloor == "left" then
				self.rotation = math.pi*.5
			end
		end
		
		if not self.dontmirror then
			if self.crawldirection == "right" then
				self.animationdirection = "left"
			else
				self.animationdirection = "right"
			end
		end
		
		if not self.aroundcorner then
			--go around corner?
			if self.crawldirection == "left" then
				if self.crawlfloor == "left" or self.crawlfloor == "right" then
					if self.speedx > 0 and self.crawlfloor == "right" then
						self.speedx = self.crawlspeed
						self.speedy = 0
						self.gravity = -(self.crawlgravity or yacceleration)
						self.gravityx = 0
						self.aroundcorner = true
						self.crawlfloor = "up"
					elseif self.speedx < 0 and self.crawlfloor == "left" then
						self.speedx = -self.crawlspeed
						self.speedy = 0
						self.gravity = (self.crawlgravity or yacceleration)
						self.gravityx = 0
						self.aroundcorner = true
						self.crawlfloor = "down"
					end
				elseif self.crawlfloor == "up" or self.crawlfloor == "down" then
					if self.speedy > 0 and self.crawlfloor == "down" then
						self.speedy = self.crawlspeed
						self.speedx = 0
						self.gravity = 0
						self.gravityx = (self.crawlgravity or yacceleration)
						self.aroundcorner = true
						self.crawlfloor = "right"
					elseif self.speedy < 0 and self.crawlfloor == "up" then
						self.speedy = -self.crawlspeed
						self.speedx = 0
						self.gravity = 0
						self.gravityx = -(self.crawlgravity or yacceleration)
						self.aroundcorner = true
						self.crawlfloor = "left"
					end
				end
			else
				if self.crawlfloor == "left" or self.crawlfloor == "right" then
					if self.speedx > 0 and self.crawlfloor == "right" then
						self.speedx = self.crawlspeed
						self.speedy = 0
						self.gravity = (self.crawlgravity or yacceleration)
						self.gravityx = 0
						self.aroundcorner = true
						self.crawlfloor = "down"
					elseif self.speedx < 0 and self.crawlfloor == "left" then
						self.speedx = -self.crawlspeed
						self.speedy = 0
						self.gravity = -(self.crawlgravity or yacceleration)
						self.gravityx = 0
						self.aroundcorner = true
						self.crawlfloor = "up"
					end
				elseif self.crawlfloor == "up" or self.crawlfloor == "down" then
					if self.speedy > 0 and self.crawlfloor == "down" then
						self.speedy = self.crawlspeed
						self.speedx = 0
						self.gravity = 0
						self.gravityx = -(self.crawlgravity or yacceleration)
						self.aroundcorner = true
						self.crawlfloor = "left"
					elseif self.speedy < 0 and self.crawlfloor == "up" then
						self.speedy = -self.crawlspeed
						self.speedx = 0
						self.gravity = 0
						self.gravityx = (self.crawlgravity or yacceleration)
						self.aroundcorner = true
						self.crawlfloor = "right"
					end
				end
			end
		end
	end
	if self.friction and self.movement ~= "truffleshuffle" then
		local friction = friction
		if type(self.friction) == "number" then
			friction = self.friction
		end
		if self.speedx > 0 then
			self.speedx = self.speedx - friction*dt
			if self.speedx < 0 then
				self.speedx = 0
			end
		else
			self.speedx = self.speedx + friction*dt
			if self.speedx > 0 then
				self.speedx = 0
			end
		end
	end

	if self.xrelativetocamera then
		self.x = xscroll + self.xrelativetocamera
	end
	if self.yrelativetocamera then
		self.y = yscroll + self.yrelativetocamera
	end

	if self.sticktonearestplayer then --moves to where player is
		local closestplayer = 1
		local closestdist = math.sqrt((objects["player"][1].x-self.x)^2+(objects["player"][1].y-self.y)^2)
		for i = 2, players do
			local v = objects["player"][i]
			local dist = math.sqrt((v.x-self.x)^2+(v.y-self.y)^2)
			if dist < closestdist then closestdist = dist; closestplayer = i end
		end
		self.sticktoplayer = closestplayer
	end
	if self.sticktoplayer then
		local p = objects["player"][self.sticktoplayer]
		if p then
			local ox, oy = self.sticktoplayeroffsetx or 0, self.sticktoplayeroffsety or 0
			self.x = p.x+p.width/2-self.width/2+ox
			self.y = p.y+p.height/2-self.height/2+oy
		end
	end
	if self.teleportnearestplayer then --teleports player to enemy's position
		local closestplayer = 1
		local closestdist = math.sqrt((objects["player"][1].x-self.x)^2+(objects["player"][1].y-self.y)^2)
		for i = 2, players do
			local v = objects["player"][i]
			local dist = math.sqrt((v.x-self.x)^2+(v.y-self.y)^2)
			if dist < closestdist then closestdist = dist; closestplayer = i end
		end
		self.teleportplayer = closestplayer
	end
	if self.teleportplayer then
		local startp, endp = self.teleportplayer, self.teleportplayer
		if type(self.teleportplayer) == "boolean" then
			startp, endp = 1, players
		end
		for i = startp, endp do
			local p = objects["player"][i]
			if p then
				local ox, oy = self.teleportplayeroffsetx or 0, self.teleportplayeroffsety or 0
				p.x = (self.x+self.width/2)-(p.width/2)+ox
				p.y = (self.y+self.height/2)-(p.height/2)+oy
				if self.teleportplayerspeedx and self.teleportplayerspeedy then
					p.speedx = self.teleportplayerspeedx
					p.speedy = self.teleportplayerspeedy
				end
			end
		end
	end
	
	if self.jumps then
		self.jumptimer = self.jumptimer + dt
		if self.jumptimer > self.jumptime then
			self.jumptimer = self.jumptimer - self.jumptime
			--decide whether up or down
			local dir
			if self.y > 12 then
				dir = "up"
			elseif self.y < 6 then
				dir = "down"
			else
				if math.random(2) == 1 then
					dir = "up"
				else
					dir = "down"
				end
			end
			
			if dir == "up" then
				self.speedy = -self.jumpforce
				self.mask[2] = true
				self.jumping = "up"
				self.falling = true
			else
				self.speedy = -self.jumpforcedown
				self.mask[2] = true
				self.jumping = "down"
				self.jumpingy = self.y
				self.falling = true
			end
		end
		
		if self.jumping then
			if self.jumping == "up" then
				if self.speedy > 0 then
					self.jumping = false
					self.mask[2] = false
				end
			elseif self.jumping == "down" then
				if self.y > self.jumpingy + self.height+1.1 then
					self.jumping = false
					self.mask[2] = false
				end
			end
		end
	end
	
	if self.facesplayer then
		local closestplayer = 1
		local closestdist = math.sqrt((objects["player"][1].x-self.x)^2+(objects["player"][1].y-self.y)^2)
		for i = 2, players do
			local v = objects["player"][i]
			local dist = math.sqrt((v.x-self.x)^2+(v.y-self.y)^2)
			if dist < closestdist then
				closestdist = dist
				closestplayer = i
			end
		end
		
		if objects["player"][closestplayer].x + objects["player"][closestplayer].width/2 > self.x + self.width/2 then
			self.animationdirection = "left"
		else
			self.animationdirection = "right"
		end
	end
	
	if self.chasetime then
		if self.chasetimer > self.chasetime then
			local closestplayer = 1
			local closestdist = math.sqrt((objects["player"][1].x-self.x)^2+(objects["player"][1].y-self.y)^2)
			for i = 2, players do
				local v = objects["player"][i]
				local dist = math.sqrt((v.x-self.x)^2+(v.y-self.y)^2)
				if dist < closestdist then
					closestdist = dist
					closestplayer = i
				end
			end
			
			if objects["player"][closestplayer].x + objects["player"][closestplayer].width/2 < self.x + self.width/2 then
				self.speedx = -(self.chasespeed or 1.5)
				self.chasemariowasleft = true
			elseif self.chasemariowasleft then
				self.chasemariowasleft = nil
				self.chasetimer = 0
				self.startx = self.x
			end
		else
			self.chasetimer = self.chasetimer + dt
		end
	end

	--transform if falling
	if self.falling and self:gettransformtrigger("falling") then
		self:transform(self:gettransformsinto("falling"))
		return true
	end

	--platform
	if self.platform and self.platformchecktable and (not (self.trackplatform and self.tracked)) then
		local xdiff = self.speedx*dt
		if self.speedx == 0 and self.x ~= oldx then
			xdiff = self.x-oldx
		end
		local ydiff = self.speedy*dt
		if self.speedy == 0 and self.y ~= oldy then
			ydiff = self.y-oldy
		end
		local condition = false
		if ydiff < 0 then
			condition = "ignoreplatforms"
		end
		for i, v in pairs(self.platformchecktable) do
			for j, w in pairs(objects[v]) do
				if (not w.ignoreplatform) then
					if (not self.noplatformcarrying) and inrange(w.x, self.x-w.width, self.x+self.width) then --vertical carry
						if ((w.y == self.y - w.height) or 
							((self.movement == "circle" or self.movement == "flyvertical" or self.movement == "path" or self.speedy ~= 0) and w.y+w.height >= self.y-0.1 and w.y+w.height < self.y+0.1))
							and (not w.jumping) and not (self.speedy > 0 and w.speedy < 0) then --and w.speedy >= self.speedy
							if #checkrect(w.x+xdiff, self.y-w.height, w.width, w.height, {"exclude", w}, true, condition) == 0 then
								w.x = w.x + xdiff
								w.y = self.y-w.height
								w.falling = false
								w.speedy = self.speedy
							end
						end
					end
					if self.platformpush and xdiff ~= 0 then --horizontal push
						if inrange(w.y+w.height/2, self.y, self.y+self.height) then
							if xdiff > 0 and w.x < self.x+self.width and w.x+w.width > self.x+self.width then --right
								if #checkrect(self.x+self.width, w.y, w.width, w.height, {"exclude", w}, true, "ignoreplatforms") == 0 then
									w.x = self.x+self.width
								end
							elseif xdiff < 0 and w.x+w.width > self.x and w.x < self.x then
								if #checkrect(self.x-w.width, w.y, w.width, w.height, {"exclude", w}, true, "ignoreplatforms") == 0 then
									w.x = self.x-w.width
								end
							end
						end
					end
				end
			end
		end
	end

	--Check if player is near
	if self.transforms and (self:gettransformtrigger("playernear") or self:gettransformtrigger("playernotnear")) then
		if type(self.playerneardist) == "number" then
			for i = 1, players do
				local v = objects["player"][i]
				if self.playerneardistvertical then
					if inrange(v.y+v.height/2, self.y+self.height/2-(self.playerneardist or 3), self.y+self.height/2+(self.playerneardist or 3)) then
						if self:gettransformtrigger("playernear") then
							self:transform(self:gettransformsinto("playernear"))
							return
						end
					elseif self:gettransformtrigger("playernotnear") then
						self:transform(self:gettransformsinto("playernotnear"))
						return
					end
				else
					if inrange(v.x+v.width/2, self.x+self.width/2-(self.playerneardist or 3), self.x+self.width/2+(self.playerneardist or 3)) then
						if self:gettransformtrigger("playernear") then
							self:transform(self:gettransformsinto("playernear"))
							return
						end
					elseif self:gettransformtrigger("playernotnear") then
						self:transform(self:gettransformsinto("playernotnear"))
						return
					end
				end
			end
		elseif type(self.playerneardist) == "table" and #self.playerneardist == 4 then
			local col = checkrect(self.x+self.playerneardist[1], self.y+self.playerneardist[2], self.playerneardist[3], self.playerneardist[4], {"player"})
			if #col > 0 then
				if self:gettransformtrigger("playernear") then
					self:transform(self:gettransformsinto("playernear"))
					return
				end
			elseif self:gettransformtrigger("playernotnear") then
				self:transform(self:gettransformsinto("playernotnear"))
				return
			end
		end
	end
	
	--Check if player if facing the enemy
	if self.staticifseen or self.staticifnotseen or (self.transforms and (self:gettransformtrigger("seen") or self:gettransformtrigger("notseen"))) then
		local lookedat = false
		for i = 1, players do
			local v = objects["player"][i]
			if v.x+(self.width/2) > self.x+(self.width/2) then
				if v.portals ~= "none" then --AE ADDITION (change)
					if v.pointingangle > 0 then
						lookedat = true
					end
				else
					if v.animationdirection == "left" then
						lookedat = true
					end
				end
			else
				if v.portals ~= "none" then --AE ADDITION (change)
					if v.pointingangle < 0 then
						lookedat = true
					end
				else
					if v.animationdirection == "right" then
						lookedat = true
					end
				end
			end
		end
		if (self.transforms and self:gettransformtrigger("notseen")) or self.staticifnotseen then
			lookedat = not lookedat
		end
		if lookedat then
			if self.staticifseen or self.staticifnotseen then
				self.static = true
			else
				if self:gettransformtrigger("seen") then
					self:transform(self:gettransformsinto("seen"))
				else
					self:transform(self:gettransformsinto("notseen"))
				end
				return
			end
		else
			if self.staticifseen or self.staticifnotseen then
				self.static = false
			end
		end
	end
	
	if self.rotatetowardsplayer then
		for i = 1, players do
			local v = objects["player"][i]
			if not v.dead then
				self.rotation = (-math.atan2((v.x+v.width/2)-(self.x+self.width/2), (v.y+v.height/2)-(self.y+self.height/2-3/16)))-math.pi/2
			end
		end
	end

	if self.carryable then
		if self.thrown then
			if self.throwntime then
				self.throwntimer = self.throwntimer - dt
				if self.throwntimer < 0 then
					if self.fliponcarry then
						self.flipped = false
					end
					if self.noplayercollisiononthrow then
						self.mask[3] = not self.mask[1] --no player collision
					end
					self.thrown = false
					if self.speedx > 0 then
						if not self.dontmirror then
							self.animationdirection = "left"
						end
						self.speedx = math.abs(self.speedx)
					elseif self.speedx < 0 then
						if not self.dontmirror then
							self.animationdirection = "right"
						end
						self.speedx = -math.abs(self.speedx)
					end
				end
			end
		elseif self.carryparent then
			local oldx = self.x
			local oldy = self.y
			
			local offsetx = (self.carryoffsetx or 0)
			if self.carryoffsetx then
				if self.carryparent.pointingangle > 0 then
					offsetx = -offsetx
				end
			end
			self.x = (self.carryparent.x+self.carryparent.width/2-self.width/2) + offsetx
			self.y = (self.carryparent.y-self.height)+(self.carryoffsety or 0)

			if self.carryquad then
				self.quadi = self.carryquad
				self.quad = self.quadgroup[self.quadi]
			end

			--drop if not holding button
			if self.carryifholdingrunbutton and not runkey(self.carryparent.playernumber) then
				self.carryparent:use()
			end
		else
			self.pickupready = false
			for j, w in pairs(objects["player"]) do
				local col = checkrect(self.x+self.carryrange[1], self.y+self.carryrange[2], self.carryrange[3], self.carryrange[4], {"player"})
				if #col > 0 then
					w.pickupready = self
					self.pickupready = true
					
					--carry if holding button
					if self.carryifholdingrunbutton and runkey(w.playernumber) and not w.pickup then
						self:used(w.playernumber)
						w.pickupready = false
						break
					end
				end
			end
			self.userect.x, self.userect.y = self.x+self.carryrange[1], self.y+self.carryrange[2]
		end
	end

	--blow entities kreygasm
	if self.blowrange then
		local col = checkrect(self.x+self.blowrange[1], self.y+self.blowrange[2], self.blowrange[3], self.blowrange[4], self.blowchecktable)
		for j = 1, #col, 2 do
			local a, b = col[j], objects[col[j]][col[j+1]]
			if (b.active or self.blownotactiveenemies) and ((not b.static) or self.blowstaticenemies) and b.blowable ~= false and (b.speedx or b.blowstrong) then
				if self.blowstrong then
					local fx, fy = b.x+(self.blowspeedx or 0)*dt, b.y+(self.blowspeedy or 0)*dt --future position
					
					local condition = "ignoreplatforms"
					if fy > b.y then
						condition = false
					end
					if not checkintile(fx, fy, b.width, b.height, tileentities, b, condition) then
						b.x = fx
						b.y = fy
					end
				else
					b.speedx = b.speedx+(self.blowspeedx or 0)*dt
					b.speedy = b.speedy+(self.blowspeedy or 0)*dt
				end
				if b.speedx then
					if self.blowminspeedx then
						b.speedx = math.max(self.blowminspeedx, b.speedx)
					end
					if self.blowmaxspeedx then
						b.speedx = math.min(self.blowmaxspeedx, b.speedx)
					end
					if self.blowminspeedy then
						b.speedy = math.max(self.blowminspeedy, b.speedy)
					end
					if self.blowmaxspeedy then
						b.speedy = math.min(self.blowmaxspeedy, b.speedy)
					end
				end
				if (not self.blowstrong) and a == "player" and b.speedy < 0 then
					b.falling = true
				end
			end
		end
	end

	if self.customtimer then
		self.customtimertimer = self.customtimertimer + dt
		while self.customtimertimer > self.customtimer[self.currentcustomtimerstage][1] do
			self.customtimertimer = self.customtimertimer - self.customtimer[self.currentcustomtimerstage][1]
			self:customtimeraction(self.customtimer[self.currentcustomtimerstage][2], self.customtimer[self.currentcustomtimerstage][3])
			self.currentcustomtimerstage = self.currentcustomtimerstage + 1
			if self.currentcustomtimerstage > #self.customtimer then
				self.currentcustomtimerstage = 1
				if self.dontloopcustomtimer then
					self.customtimer = false
					break
				end
			end
		end
	end

	if self.runtimer then
		self.runtimertimer = self.runtimertimer + dt
		while self.runtimertimer > self[self.runtimer][self.runtimerstage][1] do
			self.runtimertimer = self.runtimertimer - self[self.runtimer][self.runtimerstage][1]
			self:customtimeraction(self[self.runtimer][self.runtimerstage][2], self[self.runtimer][self.runtimerstage][3], "script")
			self.runtimerstage = self.runtimerstage + 1
			if self.runtimerstage > #self[self.runtimer] then
				self.runtimer = false
				break
			end
		end
	end

	if self.transforms and inmap(round(self.x+1),round(self.y+1)) and not tilequads[map[round(self.x+1)][round(self.y+1)][1]].collision then --changed
		if self.transformtriggertilepropertycollide then
			if type(self.transformtriggertilepropertycollide) == "table" then
				for i = 1, #self.transformtriggertilepropertycollide do
					if self.transformtriggertilepropertycollide[i] ~= false then
						if type(self.transformtriggerobjectcollide) == "table" then
							if self.transformtriggerobjectcollide[i] == "tile" and tilequads[map[round(self.x+1)][round(self.y+1)][1]][self.transformtriggertilepropertycollide[i]] then
								if type(self.transformsinto) == "table" then
									self:transform(self.transformsinto[i])
								else
									self:transform(self.transformsinto)
								end
								return true
							end
						else
							if self.transformtriggerobjectcollide == "tile" and tilequads[map[round(self.x+1)][round(self.y+1)][1]][self.transformtriggertilepropertycollide[i]] then
								if type(self.transformsinto) == "table" then
									self:transform(self.transformsinto[i])
								else
									self:transform(self:gettransformsinto(side))
								end
								return true
							end
						end
					end
				end
			else
				for i = 1, #self.transformtriggerobjectcollide do --changed
					if type(self.transformtriggerobjectcollide) == "table" then
						if self.transformtriggerobjectcollide[i] == "tile" and tilequads[map[round(self.x+1)][round(self.y+1)][1]][self.transformtriggertilepropertycollide] then
							if type(self.transformsinto) == "table" then
								self:transform(self.transformsinto[i])
							else
								self:transform(self:gettransformsinto(side))
							end
							return true
						end
					else
						if self.transformtriggerobjectcollide == "tile" and tilequads[map[round(self.x+1)][round(self.y+1)][1]][self.transformtriggertilepropertycollide] then
							if type(self.transformsinto) == "table" then
								self:transform(self.transformsinto[i])
							else
								self:transform(self:gettransformsinto(side))
							end
							return true
						end
					end
				end 
			end
		end
	end

	if self.placetile then
        local cox = round(self.x+(self.placetileoffsetx or 0)+1)
		local coy = round(self.y+(self.placetileoffsety or 0)+1)
		if inmap(cox,coy) and map[cox][coy][1] ~= self.placetile then
			self:addtile(cox, coy, self.placetile)
		end
	end

	if self.gotomouse then
		local x, y = love.mouse.getPosition()
		x = ((x/(16*scale))-0.5)+(self.gotomouseoffsetx or 0)
		y = (y/(16*scale))+(self.gotomouseoffsety or 0)
		self.x, self.y = x+xscroll, y+yscroll
		if self.gotomousesnapx then
			self.x = math.floor(self.x)
		end
		if self.gotomousesnapy then
			self.y = math.floor(self.y)
		end
	end

	--don't re-enable
	--[[if self.savelevel then
		savelevel()
		self.savelevel = false
	end

	if self.quit then
		love.event.quit()
	end]]

	if self.pickupcoins or self.pickupcollectables then
		for x = math.ceil(self.x), math.ceil(self.x+self.width) do
			for y = math.ceil(self.y), math.ceil(self.y+self.height) do
				if inmap(x, y) then
					if tilequads[map[x][y][1]].coin and self.pickupcoins then
						if self.givecoinstoplayer then
							collectcoin(x, y)
						else
							--greedy enemy
							collectcoin(x, y, 0, nil, true)
						end
					elseif objects["coin"][tilemap(x, y)] and self.pickupcoins then
						if self.givecoinstoplayer then
							collectcoin2(x, y)
						else
							--greedy enemy
							collectcoin2(x, y, 0, true)
						end
					elseif objects["collectable"][tilemap(x, y)] and not objects["collectable"][tilemap(x, y)].coinblock and self.pickupcollectables then
						getcollectable(x, y)
					end
				end
			end
		end
	end

	if self.checkif then
		for i = 1, #self.checkif do
			self:ifstatement(self.checkif[i][1], self.checkif[i][2], self.checkif[i][3], self.checkif[i][4], self.checkif[i][5])
		end
	end
	
	--old
	--[[if self.checkif then
        self.currentcheckifstage = 1
        self.checkiftimer = 0 + dt
        while self.checkiftimer > 0.000001 do
            self.checkiftimer = self.checkiftimer - 0.000001
            self:ifstatement(self.checkif[self.currentcheckifstage][1], self.checkif[self.currentcheckifstage][2], self.checkif[self.currentcheckifstage][3], self.checkif[self.currentcheckifstage][4], self.checkif[self.currentcheckifstage][5])
            self.currentcheckifstage = self.currentcheckifstage + 1
            if self.currentcheckifstage > #self.checkif then
                self.currentcheckifstage = 1
            end
        end
	end]]

	self:convertallvariables(self)
end

function enemy:convertallvariables(s,parent)
    for k, v in pairs(s) do
        if k == "spawner" or k == "__baseclass" or k == "fireballthrower" then
            return
        end
        if type(s[k]) == "table" then
            self:convertallvariables(s[k],k)
        elseif type(s[k]) == "string" then
            local namecopy = v
            if s[k]:sub(1, #"v.") == "v." and animationnumbers then
                s[k] = string.gsub(s[k], "v.", "")
                if type(animationnumbers[s[k]]) == "number" and animationnumbers[s[k]] then 
                    local num = tonumber(animationnumbers[s[k]])
                    s[k] = tonumber(num)
                elseif type(animationnumbers[s[k]]) == "string" and animationnumbers[s[k]] then
                    local num = tostring(animationnumbers[s[k]])
                    s[k] = tostring(num)
                else
                	s[k] = v
                end
            end 
        end
    end
end

function enemy:addoutput(a, t)
	table.insert(self.outtable, {a, t})
end

function enemy:shotted(dir, cause, high, fireball, star)
	self.claw = false
	if self.resistseverything then
		return false
	end

	if fireball and self.resistsfire then
		return false
	end
	
	if star and self.resistsstar then
		return false
	end

	if cause and cause == "dkhammer" and self.resistsdkhammer then
		return false
	end

	if self.shothealth then
		if self.shothealth > 1 then
			self.shothealth = self.shothealth - 1
			if self.transforms then
				if self:gettransformtrigger("shotdamage") then
					self:transform(self:gettransformsinto("shotdamage"))
					return
				elseif self:gettransformtrigger("damage") then
					self:transform(self:gettransformsinto("damage"))
					return
				end
			end
			return
		end
	elseif self.health then --AE ADDITION
		if self.health > 1 then
			self.health = self.health - 1
			if self.transforms then
				if self:gettransformtrigger("damage") then
					self:transform(self:gettransformsinto("damage"))
					return
				end
			end
			return
		end
	end
	
	if self.givecoinwhenshot then
		collectcoin(nil, nil, tonumber(self.givecoinwhenshot) or 1)
	end
	
	if not self.noshotsound then
		playsound("shot")
	end
	
	if self.transforms then
		if self:gettransformtrigger("shot") then
			self:transform(self:gettransformsinto("shot"), nil, "death")
			return
		elseif self:gettransformtrigger("death") then
			self:transform(self:gettransformsinto("death"), nil, "death")
			return
		end
	end

	self.speedy = -(self.shotjumpforce or shotjumpforce)
	if high then
		self.speedy = self.speedy*2
	end
	self.direction = dir or "right"
	self.gravity = shotgravity
	
	if self.direction == "left" then
		self.speedx = -(self.shotspeedx or shotspeedx)
	else
		self.speedx = self.shotspeedx or shotspeedx
	end
	
	if self.shellanimal then
		self.small = true
		self.quad = self.quadgroup[self.smallquad]
		if cause == true then --below
			self.upsidedown = true
			self.kickedupsidedown = true
			self.offsetY = self.upsidedownoffsety or 4
			self.quadcenterY = self.upsidedownquadcentery or self.startquadcenterY
			self.movement = self.smallmovement
			self.animationtype = "none"
		else
			self.shot = true
			self.active = false
		end
	else
		self.shot = true
		self.active = false
	end
	
	if self.doesntflyawayonfireball then
		self.kill = true
		self.drawable = false
	end
	
	return true
end

function enemy:customtimeraction(action, arg, t)
	--set to a variable
	if arg and type(arg) == "table" and arg[1] and arg[2] and arg[1] == "property" then
		arg = self[arg[2]]
	end

	if type(action) == "table" then --The new *better* custom timer format
		local a = action[1] --action
		local p = action[2] --parameter
		if a == "set" then
			self[p] = arg
			if p == "quadno" then
				--update frame
				self.quad = self.quadgroup[self.quadno]
			end
		elseif a == "add" then
			self[p] = self[p] + arg
		elseif a == "minus" then
			self[p] = self[p] - arg
		elseif a == "multiply" then
			self[p] = self[p] * arg
		elseif a == "divide" then
			self[p] = self[p] / arg
		elseif a == "reverse" then
			if type(self[p]) == "boolean" then
				self[p] = not self[p]
			else
				self[p] = -self[p]
			end
		elseif a == "random" then
			if arg[1] == "range" then
				self[p] = math.random(arg[2], arg[3])
			else
				self[p] = arg[math.random(#arg)]
			end
		elseif a == "abs" then
			self[p] = math.abs(self[p])
		elseif a == "floor" then
			self[p] = math.floor(self[p])
		elseif a == "ceil" or a == "ceiling" then
			self[p] = math.ceil(self[p])
		end
	else --backwards compatibility
		if action == "break" then
			if t then
				self.runtimerstage = #self[self.runtimer]
			else
				self.currentcustomtimerstage = #self.customtimer
			end
		elseif action == "bounce" then
			if self.speedy == 0 then self.speedy = -(arg or 10) end
		elseif action == "playsound" then
			if self.sound and arg == self.t then
				playsound(self.sound)
			else
				playsound(arg)
			end
		elseif action == "spawnenemy" then
			if self.spawnsenemyrandoms then
				self.spawnsenemy = self.spawnsenemyrandoms[math.random(#self.spawnsenemyrandoms)]
			end
			self:spawnenemy(self.spawnsenemy)
		elseif not t and action == "startloop" then
			table.insert(self.startstage, self.currentcustomtimerstage)
			table.insert(self.endstage, 0)
			table.insert(self.looped, 0)
			self.loops = self.loops + 1
		elseif not t and action == "loop" then
			if self.looped[self.loops] == 0 then
				self.endstage[self.loops] = self.currentcustomtimerstage
				self.looped[self.loops] = arg
			end

			if self.looped[self.loops] == 1 then
				table.remove(self.startstage, self.loops)
				table.remove(self.endstage, self.loops)
				table.remove(self.looped, self.loops)
				self.loops = self.loops - 1
			else
				self.looped[self.loops] = self.looped[self.loops] - 1
				self.currentcustomtimerstage = self.startstage[self.loops]
				self.customtimertimer = self.customtimer[self.currentcustomtimerstage][1]
			end
		elseif action == "skip" then
			if t then
				self.runtimerstage = self.runtimerstage + arg or 1
				self.runtimertimer = self[self.runtimer][self.runtimerstage][1]
			else
				self.currentcustomtimerstage = self.currentcustomtimerstage + arg or 1
				self.customtimertimer = self.customtimer[self.currentcustomtimerstage][1]
			end
		elseif action == "stage" then
			if t then
				self.runtimerstage = arg or 1
				self.runtimertimer = self[self.runtimer][self.runtimerstage][1]
			else
				self.currentcustomtimerstage = arg or 1
				self.customtimertimer = self.customtimer[self.currentcustomtimerstage][1]
			end
		elseif action == "if" then
			self:ifstatement(arg[1],arg[2],arg[3],arg[4],arg[5],t)
		elseif action == "runtimer" then
			self:startruntimer(arg)
		elseif string.sub(action, 0, 7) == "reverse" then
			local parameter = string.sub(action, 8, string.len(action))
			self[parameter] = -self[parameter]
		elseif string.sub(action, 0, 3) == "add" then
			local parameter = string.sub(action, 4, string.len(action))
			self[parameter] = self[parameter] + arg
		elseif string.sub(action, 0, 8) == "multiply" then
			local parameter = string.sub(action, 9, string.len(action))
			self[parameter] = self[parameter] * arg
		elseif action == "setframe" then
			self.quad = self.quadgroup[arg]
		elseif action == "nextframe" then
			if self.quad == self.quadcount then
				self.quad = self.quadgroup[1]
			else
				self.quad = self.quadgroup[self.quad+1]
			end
		elseif action == "placetile" then
			local cox = round(self.x+(self.placetileoffsetx or 0)+1)
			local coy = round(self.y+(self.placetileoffsety or 0)+1)
			local tile = arg or self.placetile or 2
			self:addtile(cox, coy, tile)
		elseif action == "placeentity" then
			-- ONLY FOR PEOPLE WHO KNOW WHAT THEIR DOING
			local cox = round(self.x+(self.placetileoffsetx or 0)+1)
			local coy = round(self.y+(self.placetileoffsety or 0)+1)
			map[cox][coy][2] = arg or nil
		elseif action == "loadentity" then
			-- STILL ONLY FOR PEOPLE WHO KNOW WHAT THEIR DOING
			self:spawnentity(arg[1], arg[2], arg[3], arg[4])
		elseif action == "print" then
			if self[arg] then
				print(self[arg])
			else
				print(arg)
			end
		elseif action == "transform" then
			self:transform(arg)
		elseif string.sub(action, 0, 3) == "set" then
			self[string.sub(action, 4, string.len(action))] = arg
		end
	end
end

function enemy:ifstatement(first, symbol, second, action, arg, t)
	--["speedx","==","speedy",["set","speedy"],10]
	
	if type(first) == "table" then
		if first[1] == "tileid" then
			local x, y = first[2], first[3]
			if type(first[2]) == "string" then
				x = self[first[2]]
			end
			if type(first[3]) == "string" then
				y = self[first[3]]
			end
			x, y = math.ceil(x), math.ceil(y)
			first = map[x][y][1]
		elseif first[1] == "tileproperty" then
			local x, y = first[2], first[3]
			if tilequads[map[x][y][1]]:getproperty(first[4], x, y) then
				first = true
			else
				first = false
			end
		end
	else
		if self[first] then
			first = self[first]
		end	
	end

	if type(second) == "table" then
		if second[1] == "tileid" then
			local x, y = second[2], second[3]
			if type(second[2]) == "string" then
				x = self[second[2]]
			end
			if type(second[3]) == "string" then
				y = self[second[3]]
			end
			x, y = math.ceil(x), math.ceil(y)
			second = map[x][y][1]
		elseif second[1] == "tileproperty" then
			local x, y = second[2], second[3]
			if tilequads[map[x][y][1]]:getproperty(second[4], x, y) then
				second = true
			else
				second = false
			end
		end
	else
		if self[second] then
			second = self[second]
		end	
	end
	

	if type(first) == "boolean" and type(second) == "boolean" then
		if first and second then
			self:customtimeraction(action,arg,t)
			return true
		elseif (not first) and (not second) then
			self:customtimeraction(action,arg,t)
			return true
		end
    end

    if symbol == "=" or symbol == "==" then
        if first == second then
            self:customtimeraction(action,arg,t)
            return true
        end
    elseif symbol == ">" then
        if first > second then
            self:customtimeraction(action,arg,t)
            return true
        end
    elseif symbol == "<" then
        if first < second then
            self:customtimeraction(action,arg,t)
            return true
        end
    elseif symbol == ">=" then
        if first >= second then
            self:customtimeraction(action,arg,t)
            return true
        end
    elseif symbol == "<=" then
        if first <= second then
            self:customtimeraction(action,arg,t)
            return true
        end
    elseif symbol == "~=" then
        if first ~= second then
            self:customtimeraction(action,arg,t)
            return true
        end
    end
end

function enemy:startruntimer(arg)
	self.runtimer = arg
	self.runtimerstage = 1
	self.runtimertimer = 0
	for i = 1, #self.runtimer do
		if type(self.runtimer[i]) == "string" then
			--comments
			table.remove(self.runtimer, i)
		end
	end
end

function enemy:script(list, cause, a, b)
	for i = 1, #list do
		if cause == "supersize" then
			self[list[i][1]] = list[i][2]
		elseif cause == "collide" then
			if type(list[i][1]) == "table" then
				for t = 1, #list[i][1] do
					if list[i][1][t] == a or list[i][1][t] == "all" or (list[i][1][t] == "enemies" and tablecontains(enemies, a)) then
						if list[i][2] == "unoreversecard" then
							b[list[i][3]] = list[i][4]
						else
							self[list[i][2]] = list[i][3]
						end
					end
				end
			else
				if list[i][1] == a or list[i][1] == "all" or (list[i][1] == "enemies" and tablecontains(enemies, a)) then
					if list[i][2] == "unoreversecard" then
						b[list[i][3]] = list[i][4]
					else
						self[list[i][2]] = list[i][3]
					end
				end
			end
		end
	end
end

function enemy:func(i) -- 0-1 in please
	return (-math.cos(i*math.pi*2)+1)/2
end

function enemy:globalcollide(a, b, c, d, dir)
	if self.globalcollidescript then
		self:script(self.globalcollidescript, "collide", a, b)
	end

	if a == "tile" then
		if not self.resistsspikes then
			dir = twistdirection(self.gravitydirection, dir)
			if dir == "ceil" and tilequads[map[b.cox][b.coy][1]]:getproperty("spikesdown", b.cox, b.coy) then
				self:shotted()
				return false
			elseif dir == "right" and tilequads[map[b.cox][b.coy][1]]:getproperty("spikesleft", b.cox, b.coy) then
				self:shotted()
				return false
			elseif dir == "left" and tilequads[map[b.cox][b.coy][1]]:getproperty("spikesright", b.cox, b.coy) then
				self:shotted()
				return false
			elseif dir == "floor" and tilequads[map[b.cox][b.coy][1]]:getproperty("spikesup", b.cox, b.coy) then
				self:shotted()
				return false
			end
		end

		--sorry kant :p, got boared and made it myself (tho feel free to replace if yours is better)
		if self.replacetileoncollide then --changed
			local con = self.replacetileoncollide[1]
			local tile = self.replacetileoncollide[2]
			local cox, coy = b.cox, b.coy
			local pass = false
			if type(con) == "table" then 
				for i = 1, #con do
					if type(con[i]) == "string" then
						if tilequads[map[cox][coy][1]]:getproperty(con[i], cox, coy) then
							pass = true
						end
					else
						if map[cox][coy][1] == con[i] then
							pass = true
						end
					end
				end
			else 
				if type(con) == "string" then
					if tilequads[map[cox][coy][1]]:getproperty(con, cox, coy) then
						pass = true
					end
				else
					if map[cox][coy][1] == con then
						pass = true
					end
				end
			end
			if pass == true then
				self:addtile(cox, coy, tile)
			end
		end

		if self.transforms and self:gettransformtrigger("tilecollide") then
			local con = self.transformtilecollide
			local cox, coy = b.cox, b.coy
			local pass = false
			if type(con) == "table" then 
				for i = 1, #con do
					if type(con[i]) == "string" then
						if tilequads[map[cox][coy][1]]:getproperty(con[i], cox, coy) then
							pass = true
						end
					else
						if map[cox][coy][1] == con[i] then
							pass = true
						end
					end
				end
			else 
				if type(con[i]) == "string" then
					if tilequads[map[cox][coy][1]]:getproperty(con, cox, coy) then
						pass = true
					end
				else
					if map[cox][coy][1] == con then
						pass = true
					end
				end
			end
			if pass == true then
				self:transform(self:gettransformsinto("tilecollide"))
			end
		end
	end

	if a == "platform" or a == "seesawplatform" then
		if dir == "floor" then
			if self.jumping and self.speedy < -jumpforce + 0.1 then
				return true
			end
		else
			return true
		end
	end
	
	if a == "player" and self.removeonmariocontact then
		self.claw = false
		if self.transforms then
			if self:gettransformtrigger("mariocontact") then
				self:transform(self:gettransformsinto("mariocontact"), nil, "death")
			elseif self:gettransformtrigger("death") then
				self:transform(self:gettransformsinto("death"), nil, "death")
				return
			end
		end
		self.kill = true
		self.drawable = false
		return true
	end

	if self.kickable then
		if a == "player" then
			if b.x+b.width/2 > self.x+self.width/2 then
				self:kick("left")
			else
				self:kick("right")
			end
			return true
		end
	end

	if self.meltice and b.meltsice and self.transforms and self:gettransformtrigger("melt") then
		self:transform(self:gettransformsinto("melt"))
	end

	if b.meltice and self.meltsice then
		return true
	end
	
	if self.transforms and (self:gettransformtrigger("globalcollide") or self:gettransformtrigger("collide")) and (not self.justspawned) then
		if self:gettransformtrigger("globalcollide") then
			if self:handlecollisiontransform("globalcollide",a,b) then
				return true
			end
		else
			if self:handlecollisiontransform("collide",a,b) then
				return true
			end
		end
	end

	if self.thrown and (not self.dontkillwhenthrown) and not (b.resistsenemykill or b.resistseverything) then
		if a == "enemy" then
			if b:shotted("right", false, false, true) ~= false then
				addpoints(b.firepoints or 200, self.x, self.y)
				if self.throwncollisionignore then
					return true
				end
			end
			if not self.throwncombo then
				self.thrown = false
				self:shotted(self.animationdirection)
			elseif self.throwncombospeedx and self.throwncombospeedy then
				if self.speedx > 0 then
					self.speedx = self.throwncombospeedx
				else
					self.speedx = -self.throwncombospeedx
				end
				self.speedy = self.throwncombospeedy
			end
		elseif fireballkill[a] then
			if b:shotted("right") ~= false and a ~= "bowser" then
				addpoints(firepoints[a] or 200, self.x, self.y)
				if self.throwncollisionignore then
					return true
				end
			end
			if not self.throwncombo then
				self.thrown = false
				self:shotted(self.animationdirection)
			elseif self.throwncombospeedx and self.throwncombospeedy then
				if self.speedx > 0 then
					self.speedx = self.throwncombospeedx
				else
					self.speedx = -self.throwncombospeedx
				end
				self.speedy = self.throwncombospeedy
			end
		end
	end
	
	if self.killsenemies and a == "enemy" and not (b.resistsenemykill or b.resistseverything) then
		return true
	end
	
	if a ~= "enemy" then
		if self.freezesenemies then
			if iceballfreeze[a] then
				if b.freezable and (not b.frozen) and (not b.resistseverything) then
					table.insert(objects["ice"], ice:new(b.x+b.width/2, b.y+b.height, b.width, b.height, a, b))
				end
			end
		end
		if self.killsenemies then --AE ADDITION
			if b.shotted and not (b.resistsenemykill or b.resistseverything) then
				local dir = "right"
				if self.speedx < 0 then
					dir = "left"
				end
				
				if b:shotted(dir) ~= false then
					if self.bouncesonenemykill then
						self.speedy = -(self.bounceforce or 10)
					end
					addpoints((firepoints[b.t] or 200), self.x, self.y)
					return true
				end
			end
		end
	end
	
	if a == "fireball" and self.resistsfire then
		return true
	end
	
	if b.freezesenemies and self.freezable and a == "enemy" then
		if iceballfreeze[a] then
			if b.freezable and (not b.frozen) and (not b.resistseverything) then
				table.insert(objects["ice"], ice:new(b.x+b.width/2, b.y+b.height, b.width, b.height, a, b))
				return true
			end
		end
	end
	
	if b.killsenemies and not (self.resistsenemykill or self.resistseverything) then
		local dir = "right"
		if b.speedx < 0 then
			dir = "left"
		end
		if b.enemykillsdontflyaway then
			self.doesntflyawayonfireball = true
		end
		self:shotted(dir)

		if b.bouncesonenemykill then
			b.speedy = -(b.bounceforce or 10)
		end

		if b.enemykillsinstantly then
			self.instantdelete = true
		end
		
		addpoints((firepoints[self.t] or 200), self.x, self.y)
		return true
	end
	
	if self.breaksblocks then
		if (self.breakblockside == nil or self.breakblockside == "global") then
			if a == "tile" then
				if self.breakshardblocks and (tilequads[map[b.cox][b.coy][1]].coinblock or (tilequads[map[b.cox][b.coy][1]].debris and blockdebrisquads[tilequads[map[b.cox][b.coy][1]].debris])) then -- hard block
					destroyblock(b.cox, b.coy)
				else
					hitblock(b.cox, b.coy, self, true)
				end
			elseif a == "flipblock" then
				if self.breaksflipblocks then
					b:destroy()
				end
			end
		end
	end
	
	if self.nocollidestops or b.nocollidestops then
		return true
	end
end

function enemy:leftcollide(a, b, c, d)
	if self.leftcollidescript then
		self:script(self.leftcollidescript, "collide", a, b)
	end

	if self:globalcollide(a, b, c, d, "left") then
		return false
	end

	if self.ignoreleftcollide or b.ignorerightcollide then --AE ADDITION
		return false
	end
	
	if a == "tile" then
		--AE ADDITION
		--slant
		if self.onslant == "right" and self.y+self.height-2/16 <= b.y then
			self.y = b.y-self.height
			return false
		end
	end

	if a == "pixeltile" and b.dir == "right" and self.y < b.y then --AE ADDITION
		self.y = self.y - b.step
		return false
	end
	
	if self.transforms and self:gettransformtrigger("leftcollide") and (not self.justspawned) then
		if self:handlecollisiontransform("leftcollide",a,b) then
			return
		end
	end

	if a == "player" then --AE ADDITION
		return false
	end

	if self.movement == "crawl" then
		if (a == "tile" or a == "buttonblock" or a == "flipblock" or a == "frozencoin" or (a == "enemy" and b.static)) then
			if self.crawlfloor ~= "left" then
				if self.crawldirection == "left" then
					self.speedy = -self.crawlspeed
				else
					self.speedy = self.crawlspeed
				end
			end
			self.speedx = 0
			self.gravity = 0
			self.gravityx = -(self.crawlgravity or yacceleration)
			self.crawlfloor = "left"
			self.aroundcorner = false
			return true
		elseif self.crawlfloor == "up" or self.crawlfloor == "down" then
			if self.crawldirection == "left" then
				self.crawldirection = "right"
			else
				self.crawldirection = "left"
			end
			self.speedx = self.crawlspeed
			return true
		end
	end
	
	if (not self.frozen) and (self.reflects or self.reflectsx) then
		self.speedx = math.abs(self.speedx)
	end
	
	if self.breaksblocks then
		if (self.breakblockside == "sides" or self.breakblockside == "left") then
			if a == "tile" then
				if self.breakshardblocks and (tilequads[map[b.cox][b.coy][1]].coinblock or (tilequads[map[b.cox][b.coy][1]].debris and blockdebrisquads[tilequads[map[b.cox][b.coy][1]].debris])) then -- hard block
					destroyblock(b.cox, b.coy)
				else
					hitblock(b.cox, b.coy, self, true)
				end
			elseif a == "flipblock" then
				if self.breaksflipblocks then
					b:destroy()
				end
			end
		end
	end

	if self.gel then
		if a == "tile" then
			local x, y = b.cox, b.coy
			if (inmap(x+1, y) and tilequads[map[x+1][y][1]].collision) or (inmap(x, y) and tilequads[map[x][y][1]].collision == false) then
				return
			end
			--see if adjsajcjet tile is a better fit
			if math.floor(self.y+self.height/2)+1 ~= y then
				if inmap(x, math.floor(self.y+self.height/2)+1) and tilequads[map[x][math.floor(self.y+self.height/2)+1][1]].collision then
					y = math.floor(self.y+self.height/2)+1
				end
			end
			self:applygel("right", x, y)
		elseif a == "lightbridgebody" and b.dir == "ver" then
			self:applygel("right", b)
		end
	end
	
	if self.movement == "chase" and self.chasebounceforcex then
		self.speedx = self.chasebounceforcex
		if self.speedy == 0 and self.chasebounceforcey then
			self.speedy = -self.chasebounceforcey
		end
		return false
	end
	
	if (not self.frozen) and self.movement == "truffleshuffle" then
		self.speedx = self.truffleshufflespeed
		if not self.dontmirror then
			self.animationdirection = "left"
		end
		return false
	elseif (not self.frozen) and self.small then
		if (a ~= "enemy" and not tablecontains(enemies, a)) or (b.resistsenemykill or b.resistseverything) then
			self.speedx = self.smallspeed
			
			if not self.kickedupsidedown then
				if a == "tile" then
					hitblock(b.cox, b.coy, self, true)
				else
					playsound("blockhit")
				end
			end
			return false
		end
	end
end

function enemy:rightcollide(a, b, c, d)
	if self.rightcollidescript then
		self:script(self.rightcollidescript, "collide", a, b)
	end

	if self:globalcollide(a, b, c, d, "right") then
		return false
	end

	if self.ignorerightcollide or b.ignoreleftcollide then --AE ADDITION
		return false
	end
	
	if a == "tile" then
		--AE ADDITION
		--slant
		if self.onslant == "left" and self.y+self.height-2/16 <= b.y then
			self.y = b.y-self.height
			return false
		end
	end

	if a == "pixeltile" and b.dir == "left" and self.y < b.y then --AE ADDITION
		self.y = self.y - b.step
		return false
	end
	
	if self.transforms and self:gettransformtrigger("rightcollide") and (not self.justspawned) then
		if self:handlecollisiontransform("rightcollide",a,b) then
			return
		end
	end

	if a == "player" then --AE ADDITION
		return false
	end

	if self.movement == "crawl" then
		if (a == "tile" or a == "buttonblock" or a == "flipblock" or a == "frozencoin" or (a == "enemy" and b.static)) then
			if self.crawlfloor ~= "right" then
				if self.crawldirection == "left" then
					self.speedy = self.crawlspeed
				else
					self.speedy = -self.crawlspeed
				end
			end
			self.speedx = 0
			self.gravity = 0
			self.gravityx = (self.crawlgravity or yacceleration)
			self.crawlfloor = "right"
			self.aroundcorner = false
			return true
		elseif self.crawlfloor == "up" or self.crawlfloor == "down" then
			if self.crawldirection == "right" then
				self.crawldirection = "left"
			else
				self.crawldirection = "right"
			end
			self.speedx = -self.crawlspeed
			return true
		end
	end
	
	if (not self.frozen) and (self.reflects or self.reflectsx) then
		self.speedx = -math.abs(self.speedx)
	end
	
	if self.breaksblocks then
		if (self.breakblockside == "sides" or self.breakblockside == "right") then
			if a == "tile" then
				if self.breakshardblocks and (tilequads[map[b.cox][b.coy][1]].coinblock or (tilequads[map[b.cox][b.coy][1]].debris and blockdebrisquads[tilequads[map[b.cox][b.coy][1]].debris])) then -- hard block
					destroyblock(b.cox, b.coy)
				else
					hitblock(b.cox, b.coy, self, true)
				end
			elseif a == "flipblock" then
				if self.breaksflipblocks then
					b:destroy()
				end
			end
		end
	end

	if self.gel then
		if a == "tile" then
			local x, y = b.cox, b.coy
			if (inmap(x-1, y) and tilequads[map[x-1][y][1]].collision) or (inmap(x, y) and tilequads[map[x][y][1]].collision == false) then
				return
			end
			--see if adjsajcjet tile is a better fit
			if math.floor(self.y+self.height/2)+1 ~= y then
				if inmap(x, math.floor(self.y+self.height/2)+1) and tilequads[map[x][math.floor(self.y+self.height/2)+1][1]].collision then
					y = math.floor(self.y+self.height/2)+1
				end
			end
			
			self:applygel("left", x, y)
		elseif a == "lightbridgebody" and b.dir == "ver" then
			self:applygel("left", b)
		end
	end
	
	if self.movement == "chase" and self.chasebounceforcex then
		self.speedx = -self.chasebounceforcex
		if self.speedy == 0 and self.chasebounceforcey then
			self.speedy = -self.chasebounceforcey
		end
		return false
	end

	if (not self.frozen) and self.movement == "truffleshuffle" then
		self.speedx = -self.truffleshufflespeed
		if not self.dontmirror then
			self.animationdirection = "right"
		end
		return false
	elseif (not self.frozen) and self.small then
		if (a ~= "enemy" and not tablecontains(enemies, a)) or (b.resistsenemykill or b.resistseverything) then
			self.speedx = -self.smallspeed
			
			if not self.kickedupsidedown then
				if a == "tile" then
					hitblock(b.cox, b.coy, self, true)
				else
					playsound("blockhit")
				end
			end
			return false
		end
	end
end

function enemy:ceilcollide(a, b, c, d)
	if self.ceilcollidescript then
		self:script(self.ceilcollidescript, "collide", a, b)
	end

	if self:globalcollide(a, b, c, d, "ceil") then
		return false
	end

	if self.ignoreceilcollide or b.ignorefloorcollide then --AE ADDITION
		return false
	end
	
	if self.transforms and self:gettransformtrigger("ceilcollide") and (not self.justspawned) then
		if self:handlecollisiontransform("ceilcollide",a,b) then
			return
		end
	end

	if a == "player" then --AE ADDITION
		return false
	end

	if self.movement == "crawl" then
		if (a == "tile" or a == "buttonblock" or a == "flipblock" or a == "frozencoin" or (a == "enemy" and b.static)) then
			if self.crawlfloor ~= "up" then
				if self.crawldirection == "left" then
					self.speedx = self.crawlspeed
				else
					self.speedx = -self.crawlspeed
				end
			end
			self.speedy = 0
			self.gravity = -(self.crawlgravity or yacceleration)
			self.gravityx = 0
			self.aroundcorner = false
			self.crawlfloor = "up"
			return true
		elseif self.crawlfloor == "left" or self.crawlfloor == "right" then
			if self.crawldirection == "left" then
				self.crawldirection = "right"
			else
				self.crawldirection = "left"
			end
			self.speedy = self.crawlspeed
			return true
		end
	end
	
	if (not self.frozen) and (self.reflects or self.reflectsy) then
		self.speedy = math.abs(self.speedy)
	end
	
	if self.breaksblocks then
		if self.breakblockside == "ceil" then
			if a == "tile" then
				if self.breakshardblocks and (tilequads[map[b.cox][b.coy][1]].coinblock or (tilequads[map[b.cox][b.coy][1]].debris and blockdebrisquads[tilequads[map[b.cox][b.coy][1]].debris])) then -- hard block
					destroyblock(b.cox, b.coy)
				else
					hitblock(b.cox, b.coy, self, true)
				end
			elseif a == "flipblock" then
				if self.breaksflipblocks then
					b:destroy()
				end
			end
		end
	end

	if self.gel then
		if a == "tile" then
			local x, y = b.cox, b.coy
			if not inmap(x, y+1) or tilequads[map[x][y+1][1]].collision == false then
				local x, y = b.cox, b.coy
				self:applygel("bottom", x, y)
			end
		elseif a == "lightbridgebody" and b.dir == "hor" then
			self:applygel("bottom", b)
		end
	end
end

function enemy:floorcollide(a, b, c, d)
	if self.floorcollidescript then
		self:script(self.floorcollidescript, "collide", a, b)
	end

	if self:globalcollide(a, b, c, d, "floor") then
		return false
	end

	if self.ignorefloorcollide or b.ignoreceilcollide then --AE ADDITION
		return false
	end

	--Shake Ground --AE ADDITION
	if self.shakesground and (a == "tile") and self.falling and onscreen(self.x, self.y, self.width, self.height) then
		for i = 1, players do
			objects["player"][i]:groundshock()
		end
		earthquake = 4
		playsound(thwompsound)
		self.speedy = 0
	end
	
	if self.transforms and self:gettransformtrigger("floorcollide") and (not self.justspawned) then
		if self:handlecollisiontransform("floorcollide",a,b) then
			return
		end
	end

	if a == "player" then --AE ADDITION
		return false
	end

	if self.movement == "crawl" then
		if (a == "tile" or a == "buttonblock" or a == "flipblock" or a == "frozencoin" or (a == "enemy" and b.static)) then
			if self.crawlfloor ~= "down" then
				if self.crawldirection == "right" then
					self.speedx = self.crawlspeed
				else
					self.speedx = -self.crawlspeed
				end
			end
			self.speedy = 0
			self.gravity = (self.crawlgravity or yacceleration)
			self.gravityx = 0
			self.aroundcorner = false
			self.crawlfloor = "down"
			return true
		elseif self.crawlfloor == "left" or self.crawlfloor == "right" then
			if self.crawldirection == "right" then
				self.crawldirection = "left"
			else
				self.crawldirection = "right"
			end
			self.speedy = -self.crawlspeed
			return true
		end
	end

	--slants/slopes --AE ADDITION
	local onslant = (a == "pixeltile")
	if onslant then
		self.onslant = b.dir
		self.onslantstep = b.step
	else
		self.onslant = false
	end
	
	if (not self.frozen) and (self.reflects or self.reflectsy) then
		self.speedy = -math.abs(self.speedy)
	end
	
	if self.kickedupsidedown then
		self.speedx = 0
		self.kickedupsidedown = false
	end

	if self.thrown then
		if self.thrownbounce then
			self.speedy = -math.abs(self.speedy)*self.thrownbounce
			if self.throwndamping then
				self.speedx = self.speedx*self.throwndamping
			end
		end
		if self.throwntimeendonfloorcollide then
			self.throwntimer = 0
		end
	end

	if self.breaksblocks then
		if self.breakblockside == "floor" then
			if a == "tile" then
				if self.breakshardblocks and (tilequads[map[b.cox][b.coy][1]].coinblock or (tilequads[map[b.cox][b.coy][1]].debris and blockdebrisquads[tilequads[map[b.cox][b.coy][1]].debris])) then -- hard block
					destroyblock(b.cox, b.coy)
				else
					hitblock(b.cox, b.coy, self, true)
				end
			elseif a == "flipblock" then
				if self.breaksflipblocks then
					b:destroy()
				end
			end
		end
	end

	if self.gel then
		if a == "tile" then
			local x, y = b.cox, b.coy
			if (inmap(x, y-1) and tilequads[map[x][y-1][1]].collision) or (inmap(x, y) and tilequads[map[x][y][1]].collision == false) then
				return
			end
			--see if adjsajcjet tile is a better fit
			if math.floor(self.x+self.width/2)+1 ~= x then
				if inmap(x, y) and tilequads[map[x][y][1]].collision then
					x = math.floor(self.x+self.width/2)+1
				end
			end
			
			if inmap(x, y) and tilequads[map[x][y][1]].collision then
				if map[x][y]["gels"]["top"] == self.gel or (self.gel == 5 and not map[x][y]["gels"]["top"]) then
					if self.speedx > 0 then
						for cox = x+1, x+self.speedx*0.2 do
							if inmap(cox, y-1) and tilequads[map[cox][y][1]].collision == true and tilequads[map[cox][y-1][1]].collision == false then
								if self:applygel("top", cox, y) then break end
							else break end
						end
					elseif self.speedx < 0 then
						for cox = x-1, x+self.speedx*0.2, -1 do
							if inmap(cox, y-1) and tilequads[map[cox][y][1]].collision and tilequads[map[cox][y-1][1]].collision == false then
								if self:applygel("top", cox, y) then break end
							else break end
						end
					end
				else
					self:applygel("top", x, y)
				end
			end
		elseif a == "lightbridgebody" and b.dir == "hor" then
			self:applygel("top", b)
		end
	end
	
	self.falling = false

	if (not self.frozen) and self.bounces and (not self.bouncedelay) then
		self.speedy = -(self.bounceforce or 10)
		self.falling = true
	end
end

function enemy:passivecollide(a, b, c, d)
	if self:globalcollide(a, b, c, d, "passive") then
		return false
	end

	if a == "player" then --AE ADDITION
		return false
	end
end

function enemy:startfall()
	self.falling = true
end

function enemy:stomp(x, b)
	self.claw = false
	if self.stompable or (self.shellanimal and self.small) then
		if self.pushmariowhenstomped and b then
			b.y = self.y - b.height-1/16
		end

		if self.stomphealth then
			if self.stomphealth > 1 then
				self.stomphealth = self.stomphealth - 1
				if self.transforms then
					if self:gettransformtrigger("stompdamage") then
						self:transform(self:gettransformsinto("stompdamage"))
						return
					elseif self:gettransformtrigger("damage") then
						self:transform(self:gettransformsinto("damage"))
						return
					end
				end
				return
			end
		elseif self.health then --AE ADDITION
			if self.health > 1 then
				self.health = self.health - 1
				if self.transforms then
					if self:gettransformtrigger("damage") then
						self:transform(self:gettransformsinto("damage"))
						return
					end
				end
				return
			end
		end
	
		if self.transforms then
			if self:gettransformtrigger("stomp") then
				self:transform(self:gettransformsinto("stomp"), nil, "death")
				return
			elseif self:gettransformtrigger("death") then
				self:transform(self:gettransformsinto("death"), nil, "death")
				return
			end
		end
		
		if self.givecoinwhenstomped then
			collectcoin(nil, nil, tonumber(self.givecoinwhenstomped) or 1)
		end
		
		if self.shellanimal then
			if not self.small then
				self.quadcenterY = self.smallquadcentery or 19--self.startquadcenterY
				self.offsetY = self.smalloffsety or 0--self.startoffsetY
				self.quad = self.quadgroup[self.smallquad]
				self.small = true
				self.trackable = false
				self.movement = self.smallmovement
				self.speedx = 0
				self.animationtype = "none"
			elseif self.speedx == 0 then
				if self.x > x then
					self.speedx = self.smallspeed
					self.x = x+12/16+self.smallspeed*gdt
					if b then
						self.size = b.size
					else
						self.size = 1
					end
					self.killsenemies = true
				else
					self.speedx = -self.smallspeed
					self.x = x-self.width-self.smallspeed*gdt
					if b then
						self.size = b.size
					else
						self.size = 1
					end
					self.killsenemies = true
				end
			else
				self.speedx = 0
				self.combo = 1
				self.quad = self.quadgroup[self.smallquad]
			end
		else
			self.active = false
			if self.stompanimation then
				self.quad = self.quadgroup[self.stompedframe]
				if self.fallswhenstomped then
					self.shot = true
					self.gravity = shotgravity
				else
					self.dead = true
				end
			elseif self.doesntflyawayonstomp then
				self.kill = true
				self.drawable = false
			else
				self.shot = true
				self.gravity = shotgravity
			end
		end
	end
end

function enemy:autodeleted()
	self.dead = true
	if self.shot then
		self:output()
	else
		self:output("autodeleted")
	end
end

function enemy:output(transformed)
	if (not self.outtable) then
		--for some reason the enemy hasn't spawned correctly
		return false
	end
	for i = 1, #self.outtable do
		if self.outtable[i][1].input then
			self.outtable[i][1]:input("toggle", self.outtable[i][2])
		end
	end
	if self.fireballthrower then
		self.fireballthrower:fireballcallback(self.t)
	end
	if self.carryparent then
		self.carryparent.pickup = nil
		self.userect.delete = true
		self.destroying = true
	end
	if self.blockportaltile and not self.dontremoveblockportaltileondeath then
		blockedportaltiles[self.blockportaltilecoordinate] = false
	end

	if (not transformed) or self.treattransformasdeath then
		--only happen on real deaths
		if self.givecoinondeath then --AE ADDITION
			collectcoin(nil, nil, tonumber(self.givecoinondeath) or 1)
		end
		if self.deathsound then --AE ADDITION
			if self.sound and self.deathsound == self.t then
				playsound(self.sound)
			else
				playsound(self.deathsound)
			end
		end
		if self.droplevelballondeath then
			table.insert(objects["levelball"], levelball:new(self.x+self.width/2, self.y+self.height/2+5/6))
		end
		if self.givekeyondeath then
			local closestplayer = 1
			local closestdist = math.sqrt((objects["player"][1].x-self.x)^2+(objects["player"][1].y-self.y)^2)
			for i = 2, players do
				local v = objects["player"][i]
				local dist = math.sqrt((v.x-self.x)^2+(v.y-self.y)^2)
				if dist < closestdist then
					closestdist = dist
					closestplayer = i
				end
			end

			objects["player"][closestplayer].key = (objects["player"][closestplayer].key or 0) + round(self.givekeyondeath or 1)
			if self.keysound then
				playsound(keysound)
			end
		end
		if self.animationtriggerondeath or self.triggeranimationondeath then
			if animationtriggerfuncs[self.animationtriggerondeath or self.triggeranimationondeath] then
				for i = 1, #animationtriggerfuncs[self.animationtriggerondeath or self.triggeranimationondeath] do
					local anim = animationtriggerfuncs[self.animationtriggerondeath or self.triggeranimationondeath][i]
					if anim.running and self.queueanimationtrigger then --you ever notice how queue has 4 silent letters?
						table.insert(anim.queue, "enemy")
					else
						anim:trigger()
					end
				end
			end
		end
		if self.transformenemyanimationondeath then
			transformenemyanimation(self.transformenemyanimationondeath)
		end
		if self.poofondeath then
			makepoof(self.x+self.width/2, self.y+self.height/2, self.poofondeath)
		end
	end
end

function enemy:portaled()
	if self.killsenemiesafterportal then
		self.killsenemies = true
	end
end

function enemy:spawnenemy(t)
	local speedx, speedy = 0, 0
	if self.spawnenemyspeedx then
		speedx = self.spawnenemyspeedx
	end
	if self.spawnenemyspeedy then
		speedy = self.spawnenemyspeedy
	end
	
	if (self.spawnenemyspeedxrandomstart and self.spawnenemyspeedxrandomend) then
		speedx = math.random()*(self.spawnenemyspeedxrandomend-self.spawnenemyspeedxrandomstart) + self.spawnenemyspeedxrandomstart
	end
	
	if (self.spawnenemyspeedyrandomstart and self.spawnenemyspeedyrandomend) then
		speedy = math.random()*(self.spawnenemyspeedyrandomend-self.spawnenemyspeedyrandomstart) + self.spawnenemyspeedyrandomstart
	end
	
	local closestplayer = 1
	local closestdist = math.sqrt((objects["player"][1].x-self.x)^2+(objects["player"][1].y-self.y)^2)
	for i = 2, players do
		local v = objects["player"][i]
		local dist = math.sqrt((v.x-self.x)^2+(v.y-self.y)^2)
		if dist < closestdist then
			closestdist = dist
			closestplayer = i
		end
	end

	if self.spawnenemytowardsplayer then
		local a = -math.atan2(objects["player"][closestplayer].x-self.x, objects["player"][closestplayer].y-self.y)+math.pi/2
		
		speedx = math.cos(a)*self.spawnenemyspeed
		speedy = math.sin(a)*self.spawnenemyspeed
	end
	
	if self.spawnenemyspeedxtowardsplayer then
		if objects["player"][closestplayer].x + objects["player"][closestplayer].width/2 > self.x + self.width/2 then
			speedx = math.abs(speedx)
		else
			speedx = -math.abs(speedx)
		end
	end
	
	local xoffset = self.spawnenemyoffsetx or 0
	local yoffset = self.spawnenemyoffsety or 0

	local properties
	--set parameters before spawn
	if self.spawnpassedparametersbeforespawn then
		if not properties then properties = {} end
		if self.spawnpassedparameters then --pass parameters
			for i = 1, #self.spawnpassedparameters do
				if self.spawnpassedparameters[i] ~= nil then
					properties[self.spawnpassedparameters[i]] = self[self.spawnpassedparameters[i]]
				end
			end
		end
	end
	if self.spawnsetparametersbeforespawn then
		if not properties then properties = {} end
		if self.spawnsetparameters then --set new parameters
			for i = 1, #self.spawnsetparameters do
				if self.spawnsetparameters[i] ~= nil then
					properties[self.spawnsetparameters[i][1]] = self.spawnsetparameters[i][2]
				end
			end
		end
	end
	
	local temp = enemy:new(self.x+self.width/2+.5+xoffset, self.y+self.height+yoffset, t, {}, properties)
	temp.justspawned = true

	if not self.spawnpassedparametersbeforespawn then
		if self.spawnpassedparameters then --pass parameters
			for i = 1, #self.spawnpassedparameters do
				if self.spawnpassedparameters[i] ~= nil then
					temp[self.spawnpassedparameters[i]] = self[self.spawnpassedparameters[i]]
				end
			end
		end
	end
	if not self.spawnsetparametersbeforespawn then
		if self.spawnsetparameters then --set new parameters
			for i = 1, #self.spawnsetparameters do
				if self.spawnsetparameters[i] ~= nil then
					temp[self.spawnsetparameters[i][1]] = self.spawnsetparameters[i][2]
				end
			end
		end
	end

	table.insert(objects["enemy"], temp)
	
	temp.speedx = speedx
	temp.speedy = speedy
	
	if temp.movement == "truffleshuffle" and temp.speedx > 0 then
		temp.animationdirection = "left"
	end
	
	table.insert(self.spawnedenemies, temp)
	temp.spawner = self
end

function enemy:transform(t, returntransform, death)
	if self.justspawned then
		return false
	end

	if (self.kill or self.transformkill) and self.drawable == false then
		--already transformed!
		return false
	end
	local xoffset = self.transformsoffsetx or 0
	local yoffset = self.transformsoffsety or 0

	if self.transformsintorandoms then
		self.transformsinto = self.transformsintorandoms[math.random(#self.transformsintorandoms)]
		t = self.transformsinto
	end

	local properties
	--set parameters before spawn
	if self.transformpassedparametersbeforespawn then
		if self.transformpassedparameters then
			if not self.transformpassedparametersallow or self.transformpassedparametersallow[t] then
				if not properties then properties = {} end
				for i = 1, #self.transformpassedparameters do
					if self.transformpassedparameters[i] ~= nil then
						properties[self.transformpassedparameters[i]] = self[self.transformpassedparameters[i]]
					end
				end
			end
		end
	end
	if self.transformsetparametersbeforespawn then
		if self.transformsetparameters then --set new parameters
			if not self.transformsetparametersallow or self.transformsetparametersallow[t] then
				if not properties then properties = {} end
				for i = 1, #self.transformsetparameters do
					if self.transformsetparameters[i] ~= nil then
						properties[self.transformsetparameters[i][1]] = self.transformsetparameters[i][2]
					end
				end
			end
		end
	end

	local temp = enemy:new(self.x+self.width/2+.5+xoffset, self.y+self.height+yoffset, t, {}, properties)
	temp.justspawned = true
	
	--set parameters after spawn
	if not self.transformpassedparametersbeforespawn then
		if self.transformpassedparameters then
			if not self.transformpassedparametersallow or self.transformpassedparametersallow[t] then
				for i = 1, #self.transformpassedparameters do
					if self.transformpassedparameters[i] ~= nil then
						temp[self.transformpassedparameters[i]] = self[self.transformpassedparameters[i]]
					end
				end
			end
		end
	end
	if not self.transformsetparametersbeforespawn then
		if self.transformsetparameters then --set new parameters
			if not self.transformsetparametersallow or self.transformsetparametersallow[t] then
				for i = 1, #self.transformsetparameters do
					if self.transformsetparameters[i] ~= nil then
						temp[self.transformsetparameters[i][1]] = self.transformsetparameters[i][2]
					end
				end
			end
		end
	end

	if self.frozen and (not self.dontpassfrozen) and self.iceblock then --TODO FIX
		self.iceblock.enemy = temp
		temp:freeze()
	end
	
	table.insert(objects["enemy"], temp)
	
	if self.spawner then
		table.insert(self.spawner.spawnedenemies, temp)
	end
	
	self.active = false
	self.transformkill = true
	if death then
		self.transformkilldeath = true --still do output death stuff
	end
	if self.tracked or self.clearpipe then
		self.transformedinto = temp
	end
	if self.fireenemyrideaftertransform then --DON'T set this property
		--is mario riding the enemy? should he still ride after enemy transforms?
		local v = self.fireenemyrideaftertransform
		v.fireenemyride = temp
		temp.fireenemyrideaftertransform = self.fireenemyrideaftertransform
		self.fireenemyrideaftertransform = nil
	end
	--self.kill = true
	self.drawable = false

	if returntransform then
		return temp
	end
end
 
function enemy:gettransformtrigger(n) --AE ADDITION
	if not self.transformtrigger then
		return false
	elseif type(self.transformtrigger) == "table" then
		return tablecontainsi(self.transformtrigger, n)
	else
		return (self.transformtrigger == n)
	end
end

function enemy:gettransformsinto(n) --AE ADDITION
	if not self.transformsinto then
		return false
	elseif type(self.transformsinto) == "table" and type(self.transformtrigger) == "table" then
		local i = tablecontainsi(self.transformtrigger, n)
		return self.transformsinto[i]
	else
		return self.transformsinto
	end
end

function enemy:emancipate()
	if not self.kill then
		table.insert(emancipateanimations, emancipateanimation:new(self.x, self.y, self.width, self.height, self.graphic, self.quad, self.speedx, self.speedy, self.rotation, self.offsetX, self.offsetY, self.quadcenterX, self.quadcenterY))
		self.kill = true
		self.drawable = false
	end
end

function enemy:laser(guns, pewpew)
	if not self.laserresistant then
		self:shotted()
	end
end

function enemy:enteredfunnel(inside)
	if inside then
		self.infunnel = true
	else
		self.infunnel = false
		self.gravity = self.startgravity
	end
end

function enemy:getspawnedenemies()
	local count = 0
	for i, v in pairs(self.spawnedenemies) do
		if not v.dead then
			count = count + 1
		end
	end
	
	return count
end

function enemy:dive(water) --AE ADDITION
	if water then
		--self.water = true
		--self.speedx = self.speedx*waterdamping
		self.speedy = self.speedy*waterdamping
	else
		--self.water = false
		if self.speedy < 0 then
			self.speedy = -waterjumpforce
		end
	end
end

function enemy:used(id)
	if self.thrown or self.frozen then
		return false
	end

	if self.dontcarryifmoving and math.abs(self.speedx) > 0.0001 then
		return false
	end

	if self.transforms and self:gettransformtrigger("carry") then
		local temp = self:transform(self:gettransformsinto("carry"), "returntransform")
		if temp and temp.carryable then
			temp:used(id)
		end
		return false
	end

	self.carryparent = objects["player"][id]
	self.active = self.activeoncarry
	self.startstatic = self.static
	self.static = true
	self.trackable = false
	if self.tracked then
		self.startstatic = false
	end

	if self.fliponcarry then
		self.flipped = true
	end

	objects["player"][id]:pickupbox(self)
	self.pickupready = false

	if self.grabsound then
		playsound(self.grabsound)
	elseif not self.nograbsound then
		playsound(grabsound)
	end
end

function enemy:dropped(gravitydir)
	self.active = self.activeonthrow
	self.static = self.startstatic
	if self.staticonthrow ~= nil then
		self.static = self.staticonthrow
	end

	if self.noplayercollisiononthrow then
		self.mask[3] = self.mask[1] --no player collision
	end

	self.thrown = true
	if self.throwntime then
		self.throwntimer = self.throwntime or 1.3
	end
	self.speedy = self.thrownspeedy or 0
	if not self.thrownignorecarryspeed then
		if self.carryparent.pointingangle > 0 then --left
			self.speedx = self.carryparent.speedx-(self.thrownspeedx or 0)
		else
			self.speedx = self.carryparent.speedx+(self.thrownspeedx or 0)
		end
	else
		if self.carryparent.pointingangle > 0 then --left
			self.speedx = -(self.thrownspeedx or 0)
		else
			self.speedx = (self.thrownspeedx or 0)
		end
	end

	local offsetx = (self.carryoffsetx or 0)
	if self.carryoffsetx and self.carryparent.pointingangle > 0 then
		offsetx = -offsetx
	end
	self.x = (self.carryparent.x+self.carryparent.width/2-self.width/2) + offsetx
	self.y = (self.carryparent.y-self.height)+(self.carryoffsety or 0)

	if self.throwsound then
		playsound(self.throwsound)
	elseif not self.nothrowsound then
		playsound(throwsound)
	end
	self.carryparent = nil
	
	if self.transforms and self:gettransformtrigger("thrown") then
		self:transform(self:gettransformsinto("thrown"))
	end
end

function enemy:freeze()
	if self.transforms and self:gettransformtrigger("freeze") then
		self:transform(self:gettransformsinto("freeze"))
		return
	end
	self.frozen = true
	self.speedx = 0
	self.speedy = 0
end

function enemy:kick(dir)
	if not (math.abs(self.speedx) < self.kickspeed*0.8) then
		return false
	end
	if not self.nokicksound then
		playsound(shotsound)
	end
	if dir == "left" then
		self.speedx = -self.kickspeed
		if not self.dontmirror then
			self.animationdirection = "right"
		end
	else
		self.speedx = self.kickspeed
		if not self.dontmirror then	
			self.animationdirection = "left"
		end
	end
	self.speedy = self.kickspeedy
end

function enemy:dotrack()
	self.track = true
	
	if self.trackedscript then
		self:script(self.trackedscript, "supersize")
	end
end

function enemy:applygel(side, x, y)
	if x and (not y) then
		local b = x
		local id = b.gels[side]
		if id and id == 5 then
			--can't put gel
			return false
		elseif self.gel == 5 then
			b.gels[side] = nil
		else
			b.gels[side] = self.gel
		end
	else
		local id = map[x][y]["gels"][side]
		if id and id == 5 then
			--can't put gel
			return false
		elseif self.gel == 5 then
			map[x][y]["gels"][side] = false
		else
			map[x][y]["gels"][side] = self.gel
		end
		if id ~= self.gel then
			return true
		end
	end
	return false
end

function enemy:handlecollisiontransform(side,a,b)
	local docancel = false
	if self.transformtriggerenemycollide then
		--mutliple enemy collides
		if type(self.transformtriggerenemycollide) == "table" and type(self.transformtrigger) == "table" then
			for i, s in pairs(self.transformtrigger) do
				if s == side and a == "enemy" and self.transformtriggerenemycollide[i] == b.t then
					if type(self.transformsinto) == "table" then
						self:transform(self.transformsinto[i])
					else
						self:transform(self:gettransformsinto(side))
					end
					if self.transformtriggerenemycollidekill then
						if self.enemykillsdontflyaway then
							b.doesntflyawayonfireball = true
						end
						b:shotted(dir)
					end
					return true
				end
			end
		else
			if a == "enemy" and b.t == self.transformtriggerenemycollide then
				self:transform(self:gettransformsinto(side))
				if self.transformtriggerenemycollidekill then
					if self.enemykillsdontflyaway then
						b.doesntflyawayonfireball = true
					end
					b:shotted(dir)
				end
				return true
			end
		end
		docancel = true
	end
	if self.transformtriggerobjectcollide then
		--mutliple entity collides
		if type(self.transformtriggerobjectcollide) == "table" and type(self.transformtrigger) == "table" then
			for i, s in pairs(self.transformtrigger) do
				if s == side and self.transformtriggerobjectcollide[i] == a then
					if self.transformtriggertilepropertycollide then
						if type(self.transformtriggertilepropertycollide) == "table" then
							if self.transformtriggertilepropertycollide[i] then
								if self.transformtriggerobjectcollide[i] == "tile" and tilequads[map[b.cox][b.coy][1]][self.transformtriggertilepropertycollide[i]] then
									if type(self.transformsinto) == "table" then
										self:transform(self.transformsinto[i])
									else
										self:transform(self:gettransformsinto(side))
									end
									return true
								else
									return
								end
							end
						else
							if self.transformtriggerobjectcollide[i] == "tile" and tilequads[map[b.cox][b.coy][1]][self.transformtriggertilepropertycollide] then
								if type(self.transformsinto) == "table" then
									self:transform(self.transformsinto[i])
								else
									self:transform(self:gettransformsinto(side))
								end
								return true
							else
								return
							end
						end
					end
					if type(self.transformsinto) == "table" then
						self:transform(self.transformsinto[i])
					else
						self:transform(self:gettransformsinto(side))
					end
					return true
				end
			end
		else
			if a == self.transformtriggerobjectcollide then
				if self.transformtriggertilepropertycollide then
					print("tiletransformexists")
					if type(self.transformtriggertilepropertycollide) == "table" then
						for i,v in pairs(self.transformtriggertilepropertycollide) do
							print("itstable")
							if self.transformtriggertilepropertycollide[i] then
								print("isn'tfalse")
								if self.transformtriggerobjectcollide == "tile" and tilequads[map[b.cox][b.coy][1]][self.transformtriggertilepropertycollide[i]] then
									print("transformmeeeng")
									self:transform(self:gettransformsinto(side))
									return true
								else
									return
								end
							end
						end
					else
						if self.transformtriggerobjectcollide == "tile" and tilequads[map[b.cox][b.coy][1]][self.transformtriggertilepropertycollide] then
							self:transform(self:gettransformsinto(side))
							return true
						else
							return
						end
					end
				end
				print("fallo la condition")
				self:transform(self:gettransformsinto(side))
				return true
			end
		end
	end
	if docancel then
		return false
	end
	self:transform(self:gettransformsinto(side))
	return true
end

function enemy:addtile(x, y, id)
	local all = smbtilecount + portaltilecount + customtilecount + (modcustomtilecount[modcustomtiles] or 0) -1
	if inmap(x, y) and id > 0 and id < all then
		map[x][y][1] = id
		objects["tile"][tilemap(x, y)] = nil
		if tilequads[map[x][y][1]].collision then
			objects["tile"][tilemap(x, y)] = tile:new(x-1, y-1, 1, 1, true)
		end
		checkportalremove(x, y)
		updatespritebatch()
		updateranges()
	end
end

function enemy:spawnentity(t, x, y, r)
	--poperty stuff
	if t and type(t) == "table" and t[1] and t[2] and t[1] == "property" then
		t = self[t[2]]
	end
	if x and type(x) == "table" and x[1] and x[2] and x[1] == "property" then
		x = self[x[2]]
	end
	if y and type(y) == "table" and y[1] and y[2] and y[1] == "property" then
		y = self[y[2]]
	end
	if r and type(r) == "table" and r[1] and r[2] and r[1] == "property" then
		r = self[r[2]]
	end

	local r = {x, y, r}

	--do it
	loadentity(t, x, y, r)
end