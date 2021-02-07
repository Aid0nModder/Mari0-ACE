rouletteblock = class:new()

function rouletteblock:init(x, y, r)
	--PHYSICS STUFF
	self.cox = x
	self.coy = y
	self.x = x-1
	self.y = y-1
	
	self.width = 1
	self.height = 1
	
	self.static = true
	self.active = true
	
	self.category = 2
	self.mask = {true}
	self.gravity = 0
	self.portalable = false
	self.autodelete = false

	self.trackplatform = true
	self.trackplatformpush = true

	self.item = {}
	self.time = 0.15
	self.random = false

	local v = convertr(r, {"string", "num", "boolean"})
	local list = v[1]:split("`")
	self.item = list
	if v[2] ~= nil then
		self.time = tonumber(v[2])
	end
	if v[3] == "true" then
		self.random = true
	end
	self.timer = 0
	self.curitem = 1

	blockedportaltiles[tilemap(self.cox, self.coy)] = true
	self.blocked = true
end

function rouletteblock:update(dt)
	self.timer = self.timer + dt
	if self.timer > self.time then
		self.timer = self.timer - self.time
		if self.random then
			local last = self.curitem
			while self.curitem == last do
				self.curitem = math.random(1, #self.item)
			end
		else
			self.curitem = self.curitem + 1
			if self.curitem > #self.item then
				self.curitem = 1
			end
		end
	end
	if self.tracked and self.blocked then
		blockedportaltiles[tilemap(self.cox, self.coy)] = nil
		self.blocked = false
	end
end

function rouletteblock:draw()
	local i = self.item[self.curitem]
	local img, quad
	if i == "coin" then
		img = coinimage
		quad = coinblockquads[spriteset][1]
	elseif i == "mushroom" then
		img = itemsimg
		quad = itemsquad[spriteset][1]
	elseif i == "fireflower" then
		img = flowerimg
		quad = flowerquad[spriteset][1]
	elseif i == "iceflower" then
		img = iceflowerimg
		quad = flowerquad[spriteset][1]
	elseif i == "oneup" then
		img = itemsimg
		quad = itemsquad[spriteset][2]
	elseif i == "star" then
		img = starimg
		quad = starquad[spriteset][1]
	end
	if img and quad then
		love.graphics.draw(img, quad, math.floor((self.x-xscroll)*16*scale), ((self.y-yscroll)*16-8)*scale, 0, scale, scale)
	end
	love.graphics.draw(rouletteblockimg, coinblockquads[spriteset][coinframe],  math.floor((self.x-xscroll)*16*scale), ((self.y-yscroll)*16-8)*scale, 0, scale, scale)
end

function rouletteblock:hit()
	local x, y = self.cox, self.coy
	local t = 0
	if spriteset == 1 then
		t = 113
	elseif spriteset == 2 then
		t = 114
	elseif spriteset == 3 then
		t = 117
	else
		tt = 113
	end
	if self.tracked then
		--welcome to downtown jank
		local fx, fy = math.floor(self.x+1), math.floor(self.y+1)
		obj = tilemoving:new(fx, fy, t)
		table.insert(objects["tilemoving"], obj)
		for i, v in pairs(objects["trackcontroller"]) do
			if v.b == self then
				v.b = obj
			end
		end
	else
		map[x][y][1] = t
		if tilequads[map[x][y][1]].collision then
			objects["tile"][tilemap(x, y)] = tile:new(x-1, y-1, 1, 1, true)
		end
		updatespritebatch()

		local bounce = createblockbounce(x, y)
		bounce.timer = 0.000000001
		bounce.x = x
		bounce.y = y
	end

	local t = self.item[self.curitem]
	if t == "fireflower" or t == "iceflower" then
		playsound("mushroomappear")
		item(t, self.x+1, self.y+1, 2)
	elseif t == "coin" then
		playsound(coinsound)
		table.insert(coinblockanimations, coinblockanimation:new(self.x+1-0.5, self.y+1-1))
		mariocoincount = mariocoincount + 1
		if mariocoincount == 100 and (not nocoinlimit) then
			if mariolivecount ~= false then
				for i = 1, players do
					mariolives[i] = mariolives[i] + 1
					respawnplayers()
				end
			end
			mariocoincount = 0
			playsound(oneupsound)
		end
		addpoints(200)
	else
		playsound("mushroomappear")
		item(t, self.x+1, self.y+1)
	end
	blockedportaltiles[tilemap(self.cox, self.coy)] = nil
	self.instantdelete = true
end

function rouletteblock:leftcollide(a, b)
	if (a == "thwomp" and b.t == "right") or ((a == "koopa" or b.shellanimal) and b.small) or (a == "bigkoopa" and b.small) or a == "shell" or a == "spikeball" then
		self:hit()
	end
end

function rouletteblock:rightcollide(a, b)
	if (a == "thwomp" and b.t == "left") or ((a == "koopa" or b.shellanimal) and b.small) or (a == "bigkoopa" and b.small) or a == "shell" or a == "spikeball" then
		self:hit()
	end
end

function rouletteblock:ceilcollide(a, b)
	if (a == "thwomp" and b.t == "down") or a == "skewer" or a == "icicle" or a == "spikeball" then
		self:hit()
	end
end

function rouletteblock:floorcollide(a, b)
	if a == "player" or a == "spikeball" then
		self:hit()
	end
end

function rouletteblock:globalcollide(a, b)

end