doorsprite = class:new()

function doorsprite:init(x, y, r, i)
	self.cox = x
	self.coy = y
	self.i = i

	self.r = {unpack(r)}
	table.remove(self.r, 1)
	table.remove(self.r, 1)

	if #self.r > 0 and self.r[1] ~= "link" then
		local v = convertr(r[3], {"num", "num", "bool", "num"}, true)
		self.targetsublevel = v[1] or 0
		self.exitid = v[2] or 1
		self.visible = true
		if v[3] ~= nil then
			self.visible = v[3]
		end
		table.remove(self.r, 1)
	end

	if pipeexitid and pipeexitid > 1 and pipeexitid == self.exitid then
		pipestartx = x+.5
		pipestarty = y
		pipestartdir = "up"
	end
	
	if self.i == "door" then
		self.quad = doorspritequad[1]
	elseif self.i == "pdoor" then
		self.quad = doorspritequad[2]
		self.locked = true
	elseif self.i == "keydoor" then
		self.quad = doorspritequad[3]
		self.locked = true
	end
	
	self.frame = 1
	self.active = false
	self.static = true

	self.player = false
	self.outtable = {}
end

function doorsprite:draw()
	print(self.locked)
	if self.visible then
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(doorspriteimg, self.quad[self.frame], math.floor((self.cox-1-xscroll)*16*scale), math.floor((self.coy-2-(8/16)-yscroll)*16*scale), 0, scale, scale)
	end
end

function doorsprite:lock(lock)
	self.locked = lock
	if self.i ~= "door" then
		if self.locked then
			self.frame = 1
		else
			self.frame = 2
			if self.i == "keydoor" then
				playsound(keyopensound)
			end
		end
	end
end

function doorsprite:link()
	while #self.r > 3 do
		for j, w in pairs(outputs) do
			for i, v in pairs(objects[w]) do
				if tonumber(self.r[2]) == v.cox and tonumber(self.r[3]) == v.coy then
					if self.r[4] == "exit" then
						self.exit = true
						self.exitx = v.cox
						self.exity = v.coy
					elseif self.r[4] == "openable" then
						v:addoutput(self, self.r[4])
						self.locked = true
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

function doorsprite:addoutput(a, t)
end

function doorsprite:out()
end

function doorsprite:input(t, input)
	if input == "openable" then
		if t == "on" then
			self.locked = false
		elseif t == "off" then
			self.locked = true
		elseif t == "toggle" then
			self.locked = not self.locked
		end
	end
end