MovingWall = Core.class(Sprite)

function MovingWall:init(world, width, height, properties)
	self.world = world
	self.w = width
	self.h = height
	self.isOneWay = properties.isOneWay
	self.bounce = properties.bounce
	self.sin = properties.sin
	self.xDir = properties.xDir
	self.yDir = properties.yDir
	self.xDistance = properties.xDistance
	self.yDistance = properties.yDistance
	
	self.speed = 100
	self.sx = 0
	self.sy = 0
	self.timer = 0
	
	self.isMoving = false
	
	self.world:add(self, 0, 0, self.w, self.h)
end

function MovingWall:startMove()
	self.sx, self.sy = self:getPosition()
	self.isMoving = true
end

function MovingWall:update(dt)
	if (self.isMoving) then 
		local x,y = self:getPosition()
		if (self.sin) then 
			local sina = math.sin(self.timer)
			x = self.sx + sina * self.xDistance
			y = self.sy + sina * self.yDistance
			return 
		end
		
		x += self.xDir * self.speed * dt
		y += self.yDir * self.speed * dt
		
		if (math.abs(self.sx - x) > self.xDistance) then 
			x = self.sx + self.xDistance * self.xDir
			
			if (self.bounce) then 
				self.xDir *= -1
			end
		end		
		
		if (math.abs(self.sy - y) > self.yDistance) then 
			y = self.sy + self.yDistance * self.yDir
			
			if (self.bounce) then 
				self.yDir *= -1
			end
		end
		
		self:setPosition(x,y)
	end
end

function MovingWall:setPosition(x, y)
	self.world:update(self, x, y)
	Sprite.setPosition(self, x, y)
end