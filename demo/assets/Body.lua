Body = Core.class(Sprite)

function Body:init()
	self.speed = 0
	self.vel = vec2.new()
end

function Body:update(dt)
	local x,y = self:getPosition()
	self.vel:limit(self.speed)
	
	x += self.vel.x * dt
	y += self.vel.y * dt
	
	self:setPosition(x,y)
end

