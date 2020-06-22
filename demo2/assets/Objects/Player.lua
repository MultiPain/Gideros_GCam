Player = Core.class(Body)

function Player:init()
	self.px = Pixel.new(0xffffff,1,32,32)
	self.px:setAnchorPoint(.5,.5)
	self:addChild(self.px)
	
	self.maxSpeed = 500
end
--
function Player:setMoveVec(vec)
	self.vel.x = self.maxSpeed * vec.x
	self.vel.y = self.maxSpeed * vec.y
end
--
function Player:setMoveVecX(x)
	self.vel.x = self.maxSpeed * x
end
--
function Player:setMoveVecY(y)
	self.vel.y = self.maxSpeed * y
end