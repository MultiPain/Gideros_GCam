Body = Core.class(Sprite)

function Body:init()
	self.maxSpeed = 1
	self.vel = vec2.new()
end

function Body:update(dt)
	local x,y = self:getPosition()
	self.vel:limit(self.maxSpeed)
	
	x += self.vel.x * dt
	y += self.vel.y * dt
	
	self:setPosition(x,y)
end

