-- now is also groundlights

wallindicator = class:new()

function wallindicator:init(x, y, t, r)
	self.x = x
	self.y = y
	self.t = t or "wallindicator"

	self.lighted = false
	self.timer = 0
	self.defaulton = false
	self.grid = false

	self.r = {unpack(r)}
	table.remove(self.r, 1)
	table.remove(self.r, 1)

	if #self.r > 0 and self.r[1] ~= "link" then
		if self.t ~= "wallindicator" then
			local v = convertr(self.r[1], {"bool", "bool", "bool", "bool", "bool", "bool", "bool", "bool", "bool", "bool"})
			local id = 1
			self.defaulton = v[1]
			self.grid = {}
			for x = 1, 3 do
				self.grid[x] = {}
				for y = 1, 3 do
					id = id + 1
					self.grid[x][y] = v[id]
				end
			end
			table.remove(self.r, 1)
		else
			local v = convertr(self.r[1], {"bool"})
			self.defaulton = v[1]
			table.remove(self.r, 1)
		end
	end
	self.lighted = self.defaulton
end

function wallindicator:link()
	self.outtable = {}
	if #self.r > 2 then
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
	end
end

function wallindicator:update(dt)
	if self.t ~= "wallindicator" and self.timer > 0 then
		self.timer = self.timer - dt
		if self.timer <= 0 then
			self.timer = 0
			self:input("off")
		end
	end
end

function wallindicator:draw()
	love.graphics.setColor(255, 255, 255)
	if self.t == "wallindicator" then
		local statei = 1
		if self.lighted then
			statei = 2
		end
		
		love.graphics.draw(wallindicatorimg, wallindicatorquad[spriteset][statei], math.floor((self.x-1-xscroll)*16*scale), ((self.y-1-yscroll)*16-8)*scale, 0, scale, scale)
	else
		if self.grid then
			for x = 1, 3 do
				for y = 1, 3 do
					local exist = self.grid[x][y]
					if exist then
						local statei = 1
						if self.lighted then
							statei = 2
						end

						love.graphics.draw(antlineimg, antlinequad[spriteset][statei], math.floor((self.x+((x-1)*0.3125)-1-xscroll)*16*scale), ((self.y+((y-1)*0.3125)-1-yscroll)*16-8)*scale, 0, scale, scale)
					end
				end
			end
		else --epic fail, just do the old stuff
			local statei = 1
			if self.lighted then
				statei = 2
			end

			love.graphics.draw(groundlightimg, groundlightquad[spriteset][self.t][statei], math.floor((self.x-1-xscroll)*16*scale), ((self.y-1-yscroll)*16-8)*scale, 0, scale, scale)
		end
	end
end

function wallindicator:input(t)
	if t == "on" then
		self.lighted = not self.defaulton
	elseif t == "off" then
		self.lighted = self.defaulton
	elseif t == "toggle" then
		self.lighted = not self.lighted
		self.timer = groundlightdelay
	end
end