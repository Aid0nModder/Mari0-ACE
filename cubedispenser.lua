cubedispenser = class:new()

function cubedispenser:init(x, y, r)
	--PHYSICS STUFF
	self.cox = x
	self.coy = y
	self.x = x-1
	self.y = y-1
	self.speedy = 0
	self.speedx = 0
	self.width = 2
	self.height = 2
	self.static = true
	self.active = true
	self.category = 7
	self.mask = {true, false, false, false, false, false, false, false, true}

	self.timer = cubedispensertime
	self.spawnondestroy = true
	self.t = "cube"
	self.legacy = true

	--Input list
	self.input1state = "off"
	self.r = {unpack(r)}
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	if #self.r > 0 and self.r[1] ~= "link" then
		local v = convertr(self.r[1], {"bool", "bool", "string"}, true)
		--DROP ON LOAD
		if v[1]  then
			self.timer = 0
		end
		--RESPAWN
		if v[2] ~= nil then
			self.spawnondestroy = v[2]
		end
		--TYPE
		if v[3] then
			self.t = v[3]
		end
		self.legacy = false
		table.remove(self.r, 1)
	end
	
	self.inputactive = false
	self.boxexists = false
	self.box = nil
end

function cubedispenser:input(t, input)
	--if input == "drop" or input == "drop_enemy_triggered" then
		if (t == "on" and self.input1state == "off") or (t == "toggle") then
			if self.boxexists then
				self.boxexists = false
				if input ~= "drop_enemy_triggered" then
					self:removebox()
				end
			end
			
			self.timer = 0
		end
	--end
end

function cubedispenser:link()
	while #self.r >= 3 do
		for j, w in pairs(outputs) do
			for i, v in pairs(objects[w]) do
				if tonumber(self.r[2]) == v.cox and tonumber(self.r[3]) == v.coy then
					v:addoutput(self, self.r[4])
					if self.t == "cube" and self.legacy and (map[v.cox][v.coy][2] and (entityquads[map[v.cox][v.coy][2]].t == "box2" or entityquads[map[v.cox][v.coy][2]].t == "edgelessbox")) then
						if map[v.cox][v.coy][2] and entityquads[map[v.cox][v.coy][2]].t == "box2" then
							self.t = "companion cube"
						elseif map[v.cox][v.coy][2] and entityquads[map[v.cox][v.coy][2]].t == "edgelessbox" then
							self.t = "edgeless cube"
						end
					end
				end
			end
		end
		table.remove(self.r, 1)
		table.remove(self.r, 1)
		table.remove(self.r, 1)
		table.remove(self.r, 1)
	end
end

function cubedispenser:update(dt)
	if self.timer < cubedispensertime then
		self.timer = self.timer + dt
		if self.timer > 0.6 and not self.boxexists then
			local spawndir
			if self.t == "turret" or self.t == "defective turret" then
				local closestplayer = 1
				local closestdist = math.sqrt((objects["player"][1].x-self.cox)^2+(objects["player"][1].y-self.coy)^2)
				for i = 2, players do
					local v = objects["player"][i]
					local dist = math.sqrt((v.x-self.cox)^2+(v.y-self.coy)^2)
					if dist < closestdist then
						closestdist = dist
						closestplayer = i
					end
				end
		
				if objects["player"][closestplayer].x + objects["player"][closestplayer].width/2 > self.cox + self.width/2 then
					spawndir = "right"
				else
					spawndir = "left"
				end
			end

			local obj, tble, enemy
			if self.t == "cube" then
				obj = box:new(self.cox+.5, self.coy)
				tble = "box"
			elseif self.t == "companion cube" then
				obj = box:new(self.cox+.5, self.coy, "box2")
				tble = "box"
			elseif self.t == "edgeless cube" then
				obj = box:new(self.cox+.5, self.coy, "edgeless")
				tble = "box"
			elseif self.t == "core1" then
				obj = core:new(self.cox+.5, self.coy, "morality")
				tble = "core"
			elseif self.t == "core2" then
				obj = core:new(self.cox+.5, self.coy, "curiosity")
				tble = "core"
			elseif self.t == "core3" then
				obj = core:new(self.cox+.5, self.coy, "cakemix")
				tble = "core"
			elseif self.t == "core4" then
				obj = core:new(self.cox+.5, self.coy, "anger")
				tble = "core"
			elseif self.t == "turret" then
				obj = turret:new(self.cox+.5, self.coy, spawndir, "turret")
				tble = "turret"
			elseif self.t == "defective turret" then
				obj = turret:new(self.cox+.5, self.coy, spawndir, "turret2")
				tble = "turret"
			elseif tablecontains(customenemies, self.t) then
				obj = enemy:new(self.cox+.5, self.coy+2-enemiesdata[self.t].height, self.t)
				obj.mask[7] = true
				tble = "enemy"
				enemy = true
			end
			if self.spawnondestroy then
				if enemy then
					obj:addoutput(self, "drop_enemy_triggered")
				else
					obj:addoutput(self, "drop")
				end
			end
			table.insert(objects[tble], obj)

			self.box = obj
			self.boxexists = true
		elseif self.timer > 1 then
			self.timer = 1
		end	
	end
	return false
end

function cubedispenser:draw()
	love.graphics.draw(cubedispenserimg, cubedispenserquad[spriteset], math.floor((self.cox-xscroll-1)*16*scale), (self.coy-yscroll-1.5)*16*scale, 0, scale, scale, 0, 0)
end

function cubedispenser:removebox()
	if self.box then
		self.box:emancipate()
		--self.box.userect.delete = true
		--self.box.destroying = true
	end
end