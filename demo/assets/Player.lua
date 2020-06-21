Player = Core.class(Body)

function Player:init()
	self.px = Pixel.new(0xffffff,1,32,32)
	self.px:setAnchorPoint(.5,.5)
	self:addChild(self.px)
	
	self.speed = 500
end
--