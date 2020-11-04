claw = class:new()

function claw:init(x, y, r)
	self.cox = x
	self.coy = y
	self.x = x-1
	self.y = y-1
	self.grabx = 0
	self.graby = 0

	self.falls = false

	self.r = {unpack(r)}
	table.remove(self.r, 1)
	table.remove(self.r, 1)

	if #self.r > 0 and self.r[1] ~= "link" then
		local v = convertr(self.r[1], {"bool"}, true)
		if v[1] then
			self.falls = true
		end
		table.remove(self.r, 1)
	end

	self.width = 1
	self.height = 1

	--rotation stuff
	self.timer = 0
	self.dirstate = "right"
	self.movedir = "right"
	self.angle = 0
	self.distance = 2
	self.chains = 4

	self.speed = 1
	self.swingspeed = 0

	self.quad = 1

	self.grabbed = false
	self.grabchild = false
	self.grabchildtype = false
	self.grabchildplayerno = false
	self.storex = 0
	self.storey = 0
	self.cooldown = 0
	
	self.active = true
	self.static = true
	self.catagory = 34
	self.mask = {true, 
				true, true, true, true, true,
				true, true, true, true, true,
				true, true, true, true, true,
				true, true, true, true, true,
				true, true, true, true, true,
				true, true, true, true, true,
				true, true, true}

	self.grabtable = {"player", "enemy", "goomba", "koopa", "mushroom", "oneup", "star", "flower", "hammerbro",
					  "cheep", "upfire", "squid", "poisonmush", "splunkin", "muncher", "ninji",
					  "mole", "bigmole", "bomb", "spike", "spikeball", "pokey", "smallspring",
					  "powblock", "pbutton", "thwomp"}

	self.truegrabtable = {}
	self.truegrabtable["goomba"] = {"goomba", "goombrat", "drygoomba", "paragoomba", "spikey",
									"spiketop", "spiketopup", "biggoomba", "tinygoomba", "bigspikey"}
	self.truegrabtable["koopa"] = {"green", "red", "blue", "beetle", "beetleshell", "spikeyshell",
								   "bigkoopa", "bigbeetle"}
end

function claw:link()
	if #self.r > 3 then
		for j, w in pairs(outputs) do
			for i, v in pairs(objects[w]) do
				if tonumber(self.r[2]) == v.cox and tonumber(self.r[3]) == v.coy then
					v:addoutput(self)
				end
			end
		end
	end
end

function claw:input(t)
	if self.grabbed then
		self.grabchild.claw = false
		self:ungrab()
	end
end

function claw:update(dt)
	--make sure the last grabbed item is gone before deleteing it
	if self.lastgrab and onscreen(self.x, self.y, self.width, self.height) then
		local v = self.lastgrab
		if not aabb(self.grabx+self.x+2/16, self.graby+self.y+(3+2/16), 0.75, 0.75, v.x, v.y, v.width, v.height) then
			self.lastgrab = nil
		end
	end

	--grab time
	if onscreen(self.x, self.y, self.width, self.height) then
		if anyiteminclaw then
			for a, b in pairs(objects) do
				for i, v in pairs(b) do
					if (not self.grabbed) and (not v.dead) and v.active and (not v.claw) and (not v.tracked) and (not v.clearpipe) and aabb(self.grabx+self.x+2/16, self.graby+self.y+(3+2/16), 0.75, 0.75, v.x, v.y, v.width, v.height) then
						self:grab(i, v, b)
					end
				end
			end
		else
			for g = 1, #self.grabtable do
				local type = self.grabtable[g]
				for i, v in pairs(objects[type]) do
					--holy shit that is a lot of conditions
					--not grabbed / dead / inactive / claw (already grabed by another claw) / tracked / clearpipe / enemy and not clawable / in area
					if (not self.grabbed) and (not v.dead) and v.active and (not v.claw) and (not v.tracked) and (not v.clearpipe) and aabb(self.grabx+self.x+2/16, self.graby+self.y+(3+2/16), 0.75, 0.75, v.x, v.y, v.width, v.height) then
						if self.truegrabtable[type] then
							for g2 = 1, #self.truegrabtable[type] do
								if v.t == self.truegrabtable[type][g2] then
									self:grab(i, v, type)
								end
							end
						else
							self:grab(i, v, type)
						end
					end
				end
			end
		end
	end

	--SWEENG
	--timer
	local timer
	if self.dirstate == "right" then
		self.timer = self.timer + dt*2
		if self.timer > math.pi then
			self.timer = self.timer - math.pi
			self.dirstate = "left"
		end
		timer = math.cos(self.timer)
	elseif self.dirstate == "left" then
		self.timer = self.timer - dt*2
		if self.timer < -math.pi then
			self.timer = self.timer + math.pi
			self.dirstate = "right"
		end
		timer = -math.cos(self.timer)
	end

	--speed
	if self.grabbed then
		if self.speed > 0.5 then
			self.speed = self.speed - 0.025
		else
			self.speed = 0.5
		end
	else
		if self.speed < 1 then
			self.speed = self.speed + 0.025
		else
			self.speed = 1
		end
	end
	
	--sort out it's child
	if self.grabbed then
		local c = self.grabchild
		if not c.claw then
			self:ungrab()
		end
		--use future positions to detect wall collisions (probbably messy)
		if c and self.grabchildtype == "player" and checkintile(self.x+self.grabx-(c.width-1)/2, self.y+self.graby+3.825, c.width, c.height, tileentities, c, "ignoreplatforms") then
			self:ungrab()
		end
		--other probbably cool stuff .__.
		c.x = self.x+self.grabx-(c.width-1)/2
		c.y = self.y+self.graby+3.825
		c.speedx = 0
		c.speedy = 0
		if c and self.grabchildtype == "player" then
			if leftkey(self.grabchildplayerno) then --swing left
				c.animationdirection = "left"
				if self.movedir == "left" then
					self.swingspeed = self.swingspeed + 0.01
				end
			elseif rightkey(self.grabchildplayerno) then --swing right
				c.animationdirection = "right"
				if self.movedir == "right" then
					self.swingspeed = self.swingspeed + 0.01
				end
			elseif downkey(self.grabchildplayerno) then --fall
				c.claw = false
				self:ungrab()
			end
		end
	end

	--swing speed
	self.swingspeed = self.swingspeed - 0.005
	if self.swingspeed > 1 then
		self.swingspeed = 1
	elseif self.swingspeed < 0 then
		self.swingspeed = 0
	end
	
	--drop it like it's hot
	if self.falls and self.grabbed and self.grabchildtype ~= "player" and onscreen(self.x, self.y, self.width, self.height) then
		for i, v in pairs(objects["player"]) do
			if aabb(self.grabx+self.x-1.5, self.graby+self.y+(3+12/16), 4, math.huge, v.x, v.y, v.width, v.height) then
				self:ungrab()
			end
		end
	end

	--ok i guess you can update angle now
	local oldangle = self.angle
	self.angle = self.angle + timer * dt
	if self.angle > oldangle then
		self.movedir = "right"
	elseif self.angle < oldangle then
		self.movedir = "left"
	end

	self.grabx = math.sin(self.angle*(self.speed+self.swingspeed))*3
	self.graby = (math.cos(self.angle*(self.speed+self.swingspeed))*3)-3

	--print(self.timer, self.speed, self.swingspeed, self.speed+self.swingspeed, self.dirstate, self.movedir)
end

function claw:draw(drop)
	local clawx, clawy = self.grabx+self.x-1, self.graby+self.y+2.825
	--bolt
	love.graphics.draw(clawimg, clawquad[spriteset][4], math.floor((self.x-xscroll)*16*scale), ((self.y-yscroll)*16-8)*scale, 0, scale, scale)
	--chain
	if not drop then
		for i = 1, self.chains do
			local x = math.sin(self.angle*(self.speed+self.swingspeed))*(self.distance/self.chains)*(i+0.25) --basically divide the distance by the number of chains to make them evenly spaced
			local y = math.cos(self.angle*(self.speed+self.swingspeed))*(self.distance/self.chains)*(i+0.25)
			love.graphics.draw(clawimg, clawquad[spriteset][5], math.floor((self.x+x-xscroll)*16*scale), ((self.y+y-yscroll)*16-8)*scale, 0, scale, scale)
		end
	end
	--clawwww
	love.graphics.draw(clawimg, clawquad[spriteset][self.quad], math.floor(((self.grabx+self.x-1)-xscroll)*16*scale), (((self.graby+self.y+2.825)-yscroll)*16-8)*scale, 0, scale, scale)
end

function claw:grab(num, child, name)
	if self.lastgrab ~= child or (name == "enemy" and child.grabable) then
		playsound(clawsound)
		self.grabbed = true
		self.grabchild = child
		self.grabchild.claw = true
		self.grabchildtype = name
		self.grabchildplayerno = num
		--speed
		self.storex = 0
		if self.grabchildtype ~= "player" then
			if self.grabchild.speedx then
				self.storex = self.grabchild.speedx
			end
		else
			self.grabchild.animationstate = "idle"
		end
		--make the quad accurate
		if self.grabchild.width >= 1.5 then
			self.quad = 2
		else
			self.quad = 3
		end
	end
end

function claw:ungrab()
	playsound(clawexitsound)
	self.quad = 1
	self.grabbed = false
	self.lastgrab = self.grabchild
	--ahhh
	if self.grabchildtype ~= "player" then
		self.grabchild.claw = false
		self.grabchild.speedx = self.storex
	end
	self.grabchild = false
	self.grabchildtype = false
	self.grabchildplayerno = false
end