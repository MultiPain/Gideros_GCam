local GRAVITY = 1500

Player2 = Core.class(Body)

function Player2:init(w,h)
	self.w = w 
	self.h = h
	self.px = Pixel.new(0x0000ff, 1, w, h)
	self.px:setAnchorPoint(.5, 1)
	self:addChild(self.px)
	
	self.friction = 5
	self.maxSpeed = 2500
	self.moveSpeed = 2500
	
	self.groundLevel = 0
	self.isOnGround = false
	self.movingLeft = false
	self.movingRight = false
	
	self.jumpStr = -700
end
--
function Player2:moveLeft(flag)
	self.movingLeft = flag
end
--
function Player2:moveRight(flag)
	self.movingRight = flag
end
--
function Player2:jump()
	if self.isOnGround then 
		self.vel.y = self.jumpStr
		self.isOnGround = false	
	end
end
--
function Player2:update(dt)
	if self.movingLeft then 
		self.vel.x -= self.moveSpeed * dt
	end
	if self.movingRight then 
		self.vel.x += self.moveSpeed * dt
	end
	self.vel.x *= (1 - ((dt * self.friction)><1))
	
	if not self.isOnGround then 
		self.vel.y += GRAVITY * dt
		local y = self:getY()
		if y > self.groundLevel then 
			y = self.groundLevel
			self.isOnGround = true
			self.vel.y = 0
			self:setY(y)
		end
	end
	
	Body.update(self,dt)
end