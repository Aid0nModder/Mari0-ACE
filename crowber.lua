crowber = class:new()

function crowber:init(x)
	self.cox = x-1
	self.x = x-1
	self.y = 2.5
	self.startx = self.x

	self.height = 0.75
	self.width = 1.5
	self.speedy = 0
	self.speedx = -8

	self.static = false
	self.active = true
	self.autodelete = true
	self.gravity = 0
	
	self.category = 11
	self.mask = {	true, 
					true, false, true, true, true,
					true, true, true, true, true,
					true, false, true, true, true,
					true, true, true, true, true,
					true, true, true, true, true,
					true, true, true, true, true,
					true, true}

	self.drawable = true
	self.offsetX = 16
	self.offsetY = 2
	self.quadcenterX = 16
	self.quadcenterY = 8

	self.graphic = crowberimg
	self.quad = torpedotedquad[spriteset][1]

	self.phase = "left"
	self.animationdirection = "right"

	self.killstuff = true

	self.animationtimer = 0
end

function crowber:update(dt)
	if self.phase == "left" and self.x < self.startx-20 then
		self.phase = "right"
		self.animationdirection = "left"
		self.speedx = 8
	elseif self.phase == "right" and self.x > self.startx-5 then
		self.phase = "attack"
		self.animationdirection = "right"
		self.speedx = 0
		self.speedy = 6
	elseif self.phase == "attack" then
		self.speedx = self.speedx - 6*dt
	end

	if self.y > 11.5 then
		self.speedy = 0
	end

	self.animationtimer = self.animationtimer + dt
	while self.animationtimer > 0.1 do
		self.animationtimer = self.animationtimer - 0.1
		if self.quad == torpedotedquad[spriteset][1] then
			self.quad = torpedotedquad[spriteset][2]
		else
			self.quad = torpedotedquad[spriteset][1]
		end
	end
end

function crowber:shotted(dir)
	self.shot = true
	self.speedy = 0
	self.direction = dir or "right"
	self.active = false
	self.gravity = shotgravity
	if self.direction == "left" then
		self.speedx = -shotspeedx
	else
		self.speedx = shotspeedx
	end
end

function crowber:leftcollide(a, b)
	return true
end

function crowber:rightcollide(a, b)
	return true
end

function crowber:ceilcollide(a, b)
	return true
end

function crowber:floorcollide(a, b)
	return true
end