emancipationgrill = class:new()

function emancipationgrill:init(x, y, dir, r)
	self.cox = x
	self.coy = y
	self.x = x
	self.y = y
	self.dir = dir
	self.active = true
	self.inputstate = "off"

	self.t = "fizzler"

	self.r = {unpack(r)}
	table.remove(self.r, 1)
	table.remove(self.r, 1)
	if #self.r > 0 and self.r[1] ~= "link" then
		local v = convertr(self.r[1], {"string", "bool", "string"}, true)
		
		if v[1] ~= nil then
			self.dir = v[1]
		end
		if v[2] ~= nil and v[2] then
			self.active = false
		end
		if v[3] ~= nil and v[3] then
			self.t = v[3]
		end
		table.remove(self.r, 1)
	end

	--self.quad = 1
	--self.moving = false
	--self.endquad = 1

	--self.fizzleitems = false
	--self.blockitems = false
	--self.blockplayer = false
	--self.blockportals = false
	--self.blockgel = false
	--self.washitems = false
	--self.clearportals = false
	--self.killsplayer = false

	if self.t == "fizzler" then
		self.quad = 1 
		self.moving = true 
		self.endquad = 1 

		self.fizzleitems = true 
		self.blockportals = true
		if portalguni > 4 then
			self.blockgel = true
		end
		self.clearportals = true
	elseif self.t == "laserfield" then
		self.quad = 1
		self.moving = false
		self.endquad = 2

		self.killsplayer = true
	elseif self.t == "deathfizzler" then
		self.quad = 2
		self.moving = true
		self.endquad = 3

		self.fizzleitems = true
		self.blockportals = true
		self.clearportals = true
		self.killsplayer = true
	elseif self.t == "closedsolid" then
		self.quad = 2
		self.moving = false
		self.endquad = 4

		self.blockitems = true
		self.fizzleitems = true
		self.blockplayer = true
		self.blockportals = true
		self.blockgel = true
	elseif self.t == "physicsrepulsion" then
		self.quad = 3
		self.moving = false
		self.endquad = 5

		self.blockitems = true
		self.fizzleitems = true
	elseif self.t == "compressedsmoke" then
		self.quad = 3
		self.moving = true
		self.endquad = 6

		self.blockplayer = true
		self.blockportals = true
	elseif self.t == "forcedeflection" then
		self.quad = 4
		self.moving = false
		self.endquad = 7

		self.blockplayer = true
		self.blockitems = true
		self.fizzleitems = true
	elseif self.t == "matterinquisition" then
		self.quad = 4
		self.moving = true
		self.endquad = 8

		self.fizzleitems = true
		self.blockportals = true
	elseif self.t == "paintfizzler" then
		self.quad = 5
		self.moving = true
		self.endquad = 9

		self.blockgel = true
		self.washitems = true
	end
	
	self.destroy = false
	if getTile(self.x, self.y) == true then
		self.destroy = true
	end
	
	for i, v in pairs(emancipationgrills) do
		local a, b = v:getTileInvolved(self.x, self.y)
		if a and b == self.dir then
			self.destroy = true
		end
	end
	
	self.particles = {}
	self.particles.i = {}
	self.particles.dir = {}
	self.particles.speed = {}
	self.particles.mod = {}
	
	self.involvedtiles = {}
	
	--find start and end
	if self.dir == "hor" then
		local curx = self.x
		while curx >= 1 and getTile(curx, self.y) == false do
			self.involvedtiles[curx] = self.y
			curx = curx - 1
		end
		self.startx = curx + 1
		
		local curx = self.x
		while curx <= mapwidth and getTile(curx, self.y) == false do
			self.involvedtiles[curx] = self.y
			curx = curx + 1
		end
		self.endx = curx - 1
		
		self.range = math.floor(((self.endx - self.startx + 1 + emanceimgwidth/16)*16)*scale)
	else
		local cury = self.y
		while cury >= 1 and getTile(self.x, cury) == false do
			self.involvedtiles[cury] = self.x
			cury = cury - 1
		end
		self.starty = cury + 1
		
		local cury = self.y
		while cury <= mapheight and getTile(self.x, cury) == false do
			self.involvedtiles[cury] = self.x
			cury = cury + 1
		end
		self.endy = cury - 1
		
		self.range = math.floor(((self.endy - self.starty + 1 + emanceimgwidth/16)*16)*scale)
	end
	
	for i = 1, self.range/16/scale do
		table.insert(self.particles.i, math.random())
		table.insert(self.particles.speed, (1-emanceparticlespeedmod)+math.random()*emanceparticlespeedmod*2)
		if math.random(2) == 1 then
			table.insert(self.particles.dir, 1)
		else
			table.insert(self.particles.dir, -1)
		end
		table.insert(self.particles.mod, math.random(4)-2)
	end
	
	self.childtable = {}
	self.outtable = {}

	self:updaterange()
end

function emancipationgrill:input(t)
	if t == "on" and self.inputstate == "off" then
		self.active = not self.active
		self:updaterange()
	elseif t == "off" and self.inputstate == "on" then
		self.active = not self.active
		self:updaterange()
	elseif t == "toggle" then
		self.active = not self.active
		self:updaterange()
	end
	
	self.inputstate = t
end

function emancipationgrill:link()
	while #self.r >= 3 do
		for j, w in pairs(outputs) do
			for i, v in pairs(objects[w]) do
				if tonumber(self.r[2]) == v.cox and tonumber(self.r[3]) == v.coy then
					v:addoutput(self)
				end
			end
		end
		table.remove(self.r, 1)
		table.remove(self.r, 1)
		table.remove(self.r, 1)
		table.remove(self.r, 1)
	end
end

function emancipationgrill:update(dt)
	if self.destroy then
		return true
	end

	for i, v in pairs(self.particles.i) do
		self.particles.i[i] = self.particles.i[i] + emanceparticlespeed/(self.range/16/scale)*dt*self.particles.speed[i]
		while self.particles.i[i] > 1 do
			self.particles.i[i] = self.particles.i[i]-1
			self.particles.speed[i] = (1-emanceparticlespeedmod)+math.random()*emanceparticlespeedmod*2
			if math.random(2) == 1 then
				self.particles.dir[i] = 1
			else
				self.particles.dir[i] = -1
			end
			self.particles.mod[i] = math.random(4)-2
		end
	end
end

function emancipationgrill:draw()
	if self.destroy == false then
		if self.dir == "hor" then
			parstartleft = math.floor((self.startx-1-xscroll)*16*scale)
			parstartright = math.floor((self.endx-1-xscroll)*16*scale)
			if self.active then
				if self.moving then
					love.graphics.setScissor(parstartleft, ((self.y-1-yscroll)*16-2)*scale, self.range - emanceimgwidth*scale, scale*4)
					
					love.graphics.setColor(unpack(emancelinecolor))
					love.graphics.rectangle("fill", math.floor((self.startx-1-xscroll)*16*scale), ((self.y-1-yscroll)*16-2)*scale, self.range, scale*4)
					love.graphics.setColor(255, 255, 255)
					
					for i, v in pairs(self.particles.i) do
						local y = ((self.y-yscroll-1)*16-self.particles.mod[i])*scale
						if self.particles.dir[i] == 1 then
							local x = parstartleft+self.range*v
							love.graphics.draw(emanceparticleimg, emanceparticlequad[self.quad], math.floor(x), math.floor(y), math.pi/2, scale, scale)
						else
							local x = parstartright-self.range*v
							love.graphics.draw(emanceparticleimg, emanceparticlequad[self.quad], math.floor(x), math.floor(y), -math.pi/2, scale, scale, 1)
						end
					end
					love.graphics.setScissor()
				else
					for x = self.startx, self.endx do
						love.graphics.draw(emancelaserimg, emancelaserquad[self.quad], math.floor((x-xscroll-1)*16*scale), (self.y-20/16-yscroll)*16*scale, 0, scale, scale)
					end
				end
			end
			--Sidethings
			love.graphics.draw(emancesideimg, emancesidequad[spriteset][self.endquad], parstartleft, ((self.y-1-yscroll)*16-4)*scale, 0, scale, scale)
			love.graphics.draw(emancesideimg, emancesidequad[spriteset][self.endquad], parstartright+16*scale, ((self.y-1-yscroll)*16+4)*scale, math.pi, scale, scale)
		else
			parstartup = math.floor((self.starty-1-yscroll)*16*scale)
			parstartdown = math.floor((self.endy-1-yscroll)*16*scale)
			if self.active then
				if self.moving then
					love.graphics.setScissor(math.floor(((self.x-1-xscroll)*16+6)*scale), parstartup-8*scale, scale*4, self.range - emanceimgwidth*scale)
					
					love.graphics.setColor(unpack(emancelinecolor))
					love.graphics.rectangle("fill", math.floor(((self.x-1-xscroll)*16+6)*scale), parstartup-8*scale, scale*4, self.range - emanceimgwidth*scale)
					love.graphics.setColor(255, 255, 255)
					
					for i, v in pairs(self.particles.i) do
						local x = ((self.x-1-xscroll)*16-self.particles.mod[i]+9)*scale
						if self.particles.dir[i] == 1 then
							local y = parstartup+self.range*v
							love.graphics.draw(emanceparticleimg, emanceparticlequad[self.quad], math.floor(x), math.floor(y), math.pi, scale, scale)
						else
							local y = parstartdown-self.range*v
							love.graphics.draw(emanceparticleimg, emanceparticlequad[self.quad], math.floor(x), math.floor(y), 0, scale, scale, 1)
						end
					end
					love.graphics.setScissor()
				else
					for y = self.starty, self.endy do
						love.graphics.draw(emancelaserimg, emancelaserquad[self.quad], math.floor((self.x-xscroll-5/16)*16*scale), (y-1-yscroll)*16*scale, math.pi/2, scale, scale, 8, 1)
					end
				end
			end
			--Sidethings
			love.graphics.draw(emancesideimg, emancesidequad[spriteset][self.endquad], math.floor(((self.x-xscroll)*16-4)*scale), parstartup-8*scale, math.pi/2, scale, scale)
			love.graphics.draw(emancesideimg, emancesidequad[spriteset][self.endquad], math.floor(((self.x-xscroll)*16-12)*scale), parstartdown+8*scale, -math.pi/2, scale, scale)
		end
	end
end

function emancipationgrill:updaterange()
	for i, v in pairs(self.childtable) do
		v.destroy = true
	end
	self.childtable = {} 
	
	if self.active == false then
		self:updateoutputs()
		return
	end
	
	local dir = self.dir
	local startx, starty = self.cox, self.coy
	local x, y = self.cox, self.coy
	self.children = 0
	
	local firstcheck = true
	local quit = false

	--sets middle
	if dir == "hor" then
		table.insert(objects["emancipationgrillbody"], emancipationgrillbody:new(self, self.x, self.y, "hor", self.children, self.blockitems, self.blockplayer))
	else
		table.insert(objects["emancipationgrillbody"], emancipationgrillbody:new(self, self.x, self.y, "ver", self.children, self.blockitems, self.blockplayer))
	end

	while x >= 1 and x <= mapwidth and y >= 1 and y <= mapheight and (tilequads[map[x][y][1]].collision == false or tilequads[map[x][y][1]].grate == true) and (x ~= startx or y ~= starty or dir ~= self.dir or firstcheck == true) and quit == false do
		firstcheck = false
		self.children = self.children + 1
		if dir == "hor" then
			local curx = self.x
			while curx >= 1 and getTile(curx, self.y) == false do
				self.involvedtiles[curx] = self.y
				table.insert(objects["emancipationgrillbody"], emancipationgrillbody:new(self, curx-1, self.y, "hor", self.children, self.blockitems, self.blockplayer))
				curx = curx - 1
			end
			self.startx = curx + 1
			
			local curx = self.x
			while curx <= mapwidth and getTile(curx, self.y) == false do
				self.involvedtiles[curx] = self.y
				table.insert(objects["emancipationgrillbody"], emancipationgrillbody:new(self, curx+1, self.y, "hor", self.children, self.blockitems, self.blockplayer))
				curx = curx + 1
			end
			self.endx = curx - 1
		else
			local cury = self.y
			while cury >= 1 and getTile(self.x, cury) == false do
				self.involvedtiles[cury] = self.x
				table.insert(objects["emancipationgrillbody"], emancipationgrillbody:new(self, self.x, cury-1, "ver", self.children, self.blockitems, self.blockplayer))
				cury = cury - 1
			end
			self.starty = cury + 1
			
			local cury = self.y
			while cury <= mapheight and getTile(self.x, cury) == false do
				self.involvedtiles[cury] = self.x
				table.insert(objects["emancipationgrillbody"], emancipationgrillbody:new(self, self.x, cury+1, "ver", self.children, self.blockitems, self.blockplayer))
				cury = cury + 1
			end
			self.endy = cury - 1
		end
	end
	
	self:updateoutputs()
end

function emancipationgrill:addChild(t)
	table.insert(self.childtable, t)
end

function emancipationgrill:updateoutputs()
	for i, v in pairs(self.outtable) do
		v:clear()
	end
end

function emancipationgrill:getTileInvolved(x, y)
	if self.active and self.blockportals then
		if self.dir == "hor" then
			if self.involvedtiles[x] == y then
				return true, "hor"
			else
				return false, "hor"
			end
		else
			if self.involvedtiles[y] == x then
				return true, "ver"
			else
				return false, "ver"
			end
		end
	else
		return false
	end
end

------------------------------------

emancipationgrillbody = class:new()

function emancipationgrillbody:init(parent, x, y, dir, i, items, player)
	parent:addChild(self)
	self.i = i
	self.cox = x
	self.coy = y
	self.dir = dir
	self.parent = parent

	--PHYSICS STUFF
	if dir == "hor" then
		self.x = x-1
		self.y = y-9/16
		self.width = 1
		self.height = 1/8
	else
		self.x = x-9/16
		self.y = y-1
		self.width= 1/8
		self.height = 1
	end
	self.static = true
	self.active = true
	self.category = 6
	
	self.blockitems = items
	self.blockplayer = player
	self.mask = {true, true, true, true, true, true, true, true, true}

	if self.blockitems then
		self.mask[4] = false
		self.mask[5] = false
		self.mask[9] = false
	end

	if self.blockplayer then
		self.mask[3] = false
	end

	self:pushstuff()
end

function emancipationgrillbody:pushstuff()
	local col = checkrect(self.x, self.y, self.width, self.height, {"box", "player"})
	for i = 1, #col, 2 do
		local v = objects[col[i]][col[i+1]]
		if self.dir == "ver" then
			if v.speedx >= 0 then
				if #checkrect(self.x + self.width, v.y, v.width, v.height, {"exclude", v}, true) > 0 then
					v.x = self.x - v.width
				else
					v.x = self.x + self.width
				end
			else
				if #checkrect(self.x - v.width, v.y, v.width, v.height, {"exclude", v}, true) > 0 then
					v.x = self.x + self.width
				else
					v.x = self.x - v.width
				end
			end
		elseif self.dir == "hor" then
			if v.speedy <= 0 then
				if #checkrect(v.x, self.y - v.height, v.width, v.height, {"exclude", v}, true) > 0 then
					v.y = self.y + self.height
				else
					v.y = self.y - v.height
				end
			else
				if #checkrect(v.x, self.y + self.height, v.width, v.height, {"exclude", v}, true) > 0 then
					v.y = self.y - v.height
				else
					v.y = self.y + self.height
				end
			end
		end
	end
end

function emancipationgrillbody:update(dt)
	if self.destroy then
		return true
	else
		return false
	end
end

function emancipationgrillbody:draw()

end