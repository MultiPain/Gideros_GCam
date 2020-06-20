local function null() end

Animation = Core.class(Sprite)

function Animation:init(name, initAnim)
	self.data = {}
	self.callback = null
	
	self.tp = TexturePack.new("gfx/Animations/"..name..".txt", "gfx/Animations/"..name..".png")
	self.frame = 1
	self.aName = initAnim or "idle"
	self.speed = 2
	self.count = 0
	self.isPlaying = false
	
	self.btm = Bitmap.new(self.tp:getTextureRegion(self.aName.."/1.png"))
	self:addChild(self.btm)
end

function Animation:setCallback(callback, arg)
	self.callback = callback
	self.callbackArg = arg
end

function Animation:loadData(t)
	for k,v in pairs(t) do 
		self.data[k] = {speed = v[1], maxFrames = v[2], loop = v[3]}
	end
end

function Animation:updateSprite()
	self.btm:setTextureRegion(self.tp:getTextureRegion(self.aName.."/"..self.frame..".png"))
end

function Animation:play(name, frame)
	self.aName = name
	self.frame = frame or 1
	self.speed = self.data[self.aName].speed
	self:updateSprite()
	
	self.isPlaying = true
end

function Animation:setFrame(frame)
	self.frame = frame
	self:updateSprite()
end

function Animation:update(dt)
	if (self.isPlaying) then
		self.count += 1
		if (self.count > self.speed) then
			local data = self.data[self.aName]
			
			self.count = 0
			self.frame += 1 
			
			if (self.frame > data.maxFrames) then 
				if (data.loop) then 
					self.frame = 1 
				else
					self.frame = data.maxFrames
					self.isPlaying = false
					self.callback(self.callbackArg or self, self.aName)
				end
			end
			self:setFrame(self.frame)
		end
	end
end