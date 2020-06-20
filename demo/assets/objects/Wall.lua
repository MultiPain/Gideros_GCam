Wall = Core.class(Sprite)

function Wall:init(world, w, h, color)
	self.px = Pixel.new(color or 0xffffff, 1, w, h)
	self:addChild(self.px)
	self.world = world
	self.world:add(self, 0, 0, w, h)
end

function Wall:setPosition(x, y)
	Sprite.setPosition(self, x, y)
	self.world:update(self, x, y)
end