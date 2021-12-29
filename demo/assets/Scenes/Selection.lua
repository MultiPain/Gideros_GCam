--!NOEXEC

Selection = Core.class(Sprite)

function Selection:init()
	local minx,miny,maxx,maxy = application:getLogicalBounds()
	local w = maxx-minx
	local h = maxy-miny
	
	local tf1 = TextField.new(nil, "Side view demo")
	tf1:setTextColor(0xffffff)
	tf1:setScale(2)
	tf1:setPosition(w / 4 - tf1:getWidth() / 2, miny + h / 2)
	self:addChild(tf1)
	
	local tf2 = TextField.new(nil, "Top down view demo")
	tf2:setTextColor(0xffffff)
	tf2:setScale(2)
	tf2:setPosition(w/ 2 + w / 4 - tf2:getWidth() / 2, miny + h / 2)
	self:addChild(tf2)

	local px = Pixel.new(0xffffff, 1, 2, h)
	px:setPosition(w / 2, miny)
	self:addChild(px)
	
	self.w = w
	self:addEventListener("mouseUp", self.mouseUp, self)
end

function Selection:mouseUp(e)
	if e.x < self.w / 2 then 
		Scenes:changeScene("SideView", 1, SceneManager.fade)
	else
		Scenes:changeScene("TopDown", 1, SceneManager.fade)
	end
end