------------- STATES ------------
IDLE @ "idle"				-- OK
RUN @ "run"					-- OK
JUMP2 @ "jump2"				-- OK
FALL @ "fall"				-- OK
GROUND @ "ground"			-- OK
HIT @ "hit"					-- OK
DEAD_HIT @ "deadhit"		-- OK
DEAD_GROUND @ "deadground"	-- OK
---------------------------------
DETECTOR_SIZE @ 5

GRAVITY @ 1500
DEBUG_STR @ [[
Y:%.8f
State: %s
Jumps: %i (%i)
stickDir: %i
onFloor: %s
onOneWay:%s
justLanded: %s
jumpControll: %s
fallOffFlag: %s
isSticked: %s
dx: %.2f
dy: %.2f
]]
local animationsData = require "data/animations"
-- bump filter function
local function filter(item, other) 
	if (other.isWall) then 
		return "slide"
	else
		return "cross"
	end
end

Base = Core.class(Sprite)
-- t(table):
-- 	name(string): animation set name
-- 	world(table): bump world
-- 	w, h(number): collision box size
-- 	ax,ay(number): image offset
function Base:init(t)
	assert(t.world, "[Base]: Bump world expected, got nil")
	assert(t.w, "[Base]: Body width expected, got nil")
	assert(t.h, "[Base]: Body height expected, got nil")
	assert(t.name, "[Base]: Animation name expected, got nil")
	local w = t.w
	local h = t.h
	
	self.world = t.world
	self.w = w
	self.h = h
	self.mirror = 1
	
	local animData = animationsData[t.name]
	if animData.mirror then 
		self.mirror = -1
		animData.mirror = nil
	end
	
	self.anim = Animation.new(t.name)
	self.anim:loadData(animData)
	self.anim:setAnchorPoint(t.ax or 0, t.ay or 0)
	self.anim:setPosition(w/2,h-self.anim:getHeight())
	self:addChild(self.anim)
	
	if (DEBUG) then 
		self.body = Pixel.new(0xff0000, 0.3, w, h)
		self:addChild(self.body)
		
		self.tf = TextField.new(nil, "", "Aq|")
		self.tf:setScale(1.5)
		self.tf:setPosition(w,-50)
		self.tf:setAlpha(.8)
		self:addChild(self.tf)
		
		self.query = Pixel.new(0x00ff00, 0.5, self.w, DETECTOR_SIZE)
		self.query:setY(self.h+1)
		self:addChild(self.query)
		
		self.leftQ = Pixel.new(0x00ff00, 0.5, DETECTOR_SIZE,self.h)
		self.leftQ:setPosition(-DETECTOR_SIZE, 0)
		self:addChild(self.leftQ)
		
		self.rightQ = Pixel.new(0x00ff00, 0.5, DETECTOR_SIZE,self.h)
		self.rightQ:setPosition(w, 0)
		self:addChild(self.rightQ)
	end
	
	self.anim:setCallback(self.animationFinished, self)
	
	self.lookDirX = 1 -- looking to the right OR to the left
	
	self.dx = 0
	self.dy = 0
	
	self.friction = 20 -- movement friction
	self.moveSpeed = 8000 -- movement speed
	self.jumpStr = 550 -- fixed jump strength
	self.jumpCount = 1 -- how many air jumps available
	self.curJumps = 1 -- current amount of jumps
	
	self.minJumpStr = 550 -- minimum jusmp strength for controllable jump
	self.jumpScale = 1 -- while holding jump button, scale jump strength
	
	self.prev = false -- previous isOnFloor
	
	self.stickDir = 0
	self.stickSlide = 0 -- gravity while sticked to the wall 
	self.stickJumpPower = 0 -- side jump strength while sticked to the wall
	
	self.stickToWall = false -- can this object stick to walls
	self.isSticked = false -- is sticked to the wall right now
	self.applyGravityWhenSticked = false -- apply gravity while sticked (see self.stickSlide)
	
	self.justLanded = false -- 
	self.isOnFloor = false -- is standing on floor
	self.movingLeft = false -- is moving left
	self.movingRight = false -- is moving right
	self.invincible = false -- to prevent geting hit during HIT animation
	self.isDead = false -- is dead?
	self.isOnOneWay = false -- standing on one way platform
	self.jumpControll = false -- is in controllable hump
	
	self.state = FALL -- animation state
	self.prevState = "" -- previous animation state
	
	self.world:add(self, 0, 0, w, h)
end
-------------------------------------------------------
----------------------- PHYSICS -----------------------
-------------------------------------------------------
function Base:update(dt)
	if (not self.isDead) then
		local x,y = self:getPosition()
		
		if (self.jumpControll and self.dy < 0) then
			self.dy -= GRAVITY * self.jumpScale * dt
		end
		
		self:move(dt)
		self.dx *= (1 - ((dt * self.friction)><1))
		
		if (not self.isOnFloor) then 
			if (not self.isSticked) then 
				self.dy += GRAVITY * dt
			elseif (self.applyGravityWhenSticked) then 
				self.dy = self.stickSlide
				self:checkStickWalls()
			end
		else
			self:checkFall()
		end
		
		x += self.dx * dt
		y += self.dy * dt		
		
		self.prev = self.isOnFloor
		self:checkCollisions(self.world:move(self, x, y, filter))
		self:updateAnimation()
		
		if (DEBUG) then
			self.tf:setText(
				string.format(DEBUG_STR,
					self:getY(),self.state, self.curJumps, self.jumpCount, 
					self.stickDir,
					tostring(self.isOnFloor), tostring(self.isOnOneWay), tostring(self.justLanded), tostring(self.jumpControll),
					tostring(self.fallOffFlag),tostring(self.isSticked),
					self.dx, self.dy
				)
			)
		end
		self.anim:update(dt)
	end
end
-- check collisions
function Base:checkCollisions(actualX, actualY, cols, colLen)
	for k, col in ipairs(cols) do
		-- colliding with one-way platforms
		if (col.other.isOneWay) then
			if (col.normal.y == -1) then
				self:onLanded()
				actualY = col.touch.y
			end
		elseif (col.other.isWall) then
			-- hit wall from top
			if (col.normal.y == -1) then
				self:onLanded()
			-- hit wall from bottom
			elseif (col.normal.y == 1) then 
				self.dy = 0
			end
			
			-- hit wall from right
			if (col.normal.x == -1) then
				self.dx = 0
				self:stick(1)
			-- hit wall from left
			elseif (col.normal.x == 1) then
				self.dx = 0
				self:stick(-1)
			end
		end
	end	
	self:setPosition(actualX, actualY)
end

-- left and right movement
function Base:move(dt)
	if (self.state ~= HIT) then 
		if (self.movingLeft) then
			if (not self.isSticked) then 
				self.dx -= self.moveSpeed * dt
			end
			self.anim:setScaleX(-1 * self.mirror)
			self.lookDirX = -1
		end if (self.movingRight) then
			if (not self.isSticked) then 
				self.dx += self.moveSpeed * dt
			end
			self.anim:setScaleX(1 * self.mirror)
			self.lookDirX = 1
		end
		
	end
end
-- force fall off one way platform
function Base:fallOff()
	if not self.isDead then
		local x,y = self:getPosition()
		local _,n = self.world:queryRect(x,y+self.h+1,self.w,4)
		if (self.isOnOneWay and n <= 1) then 
			-- teleport 1 pixel below one way platform
			self:setPosition(x, y+1)
			self.isOnFloor = false
			self.fallOffFlag = true
		end
	end
end
-- check if base need to fall
function Base:checkFall()
	local x,y = self:getPosition()
	local items,n = self.world:queryRect(x,y+self.h+1,self.w,DETECTOR_SIZE)
	if (n == 0) then 
		self.fallOffFlag = false
	end
	
	if (not self.fallOffFlag) then 
		self.isOnFloor = n > 0
	end
	
	self.isOnOneWay = false
	for k,v in pairs(items) do 
		if (v.isOneWay and self.isOnFloor) then 
			self.isOnOneWay = true
			break
		end
	end
end

-------------------------------------------------------
---------------------- ANIMATION ----------------------
-------------------------------------------------------
-- play "hit" animation
function Base:hit()
	if (self.state ~= HIT and not (self.isDead)) then 
		self.dx = 1000 * (self.isSticked and self.stickDir or -self.lookDirX)
		
		self.dy = -220
		self.isOnFloor = false
		self.isOnOneWay = false
		self.isSticked = false
		self.invincible = true
		self.prevState = self.state
		self.state = HIT
		self.anim:play(self.state)
	end
end
-- play dead animation sequance
function Base:kill()
	if (not (self.isDead)) then
		self.state = DEAD_HIT
		self.anim:play(self.state)
		self.dx = 1000 * -self.lookDirX
		self.dy = -220
		self.isOnFloor = false
	end
end
-- triggers when animation is finished
function Base:animationFinished(animName)
	if (self.state == DEAD_GROUND) then
		self.isDead = true
	elseif (self.state == GROUND) then
		self.state = IDLE
		self.anim:play(self.state)
		self.justLanded = false
	elseif (self.state == HIT) then
		self.state = self.prevState
		self.anim:play(self.state)
		self.invincible = false
	end
end
-- animation state machine
function Base:updateAnimation()
	if (self.state == DEAD_HIT) then 
		if (self.isOnFloor and self.state ~= DEAD_GROUND) then 
			self.state = DEAD_GROUND
			self.anim:play(self.state)
		end
	elseif (self.state ~= DEAD_GROUND) then
		if (self.isOnFloor and self.state ~= HIT) then 
			local fdx = math.abs(self.dx) // 1
			
			if (fdx == 0) then 
				if (self.justLanded) then 
					if (self.state ~= GROUND and fdx == 0) then 
						self.state = GROUND
						self.anim:play(self.state)
					end
				else
					if (self.state ~= IDLE) then
						self.state = IDLE
						self.anim:play(self.state)
					end
				end
			end
			
			if (fdx > 0 and self.state ~= RUN) then  
				self.state = RUN
				self.anim:play(self.state)
				self.justLanded = false
			end
		else
			if (self.state ~= HIT) then 	
				if (self.dy < 0 and self.state ~= JUMP2) then 
					self.state = JUMP2
					self.anim:play(self.state)
				elseif (self.dy > 0 and self.state ~= FALL) then 
					self.state = FALL
					self.anim:play(self.state)
				end
			end
		end
	end
end

-------------------------------------------------------
----------------------- STCIKING ----------------------
-------------------------------------------------------
-- check if there is no wall on any side while player is sliding along wall when sticked
function Base:checkStickWalls()
	local x,y = self:getPosition()
	-- if sticked to left wall
	if (self.stickDir == -1) then 
		local _,n = self.world:queryRect(x - DETECTOR_SIZE,y,DETECTOR_SIZE,self.h)
		if (n == 0) then 
			self:unstick()
		end
	else
		local _,n = self.world:queryRect(x + self.w + DETECTOR_SIZE,y,DETECTOR_SIZE, self.h)
		if (n == 0) then 
			self:unstick()
		end
	end
end
-- unstick from wall
function Base:unstick()
	if (self.stickToWall) then 
		self.isSticked = false
		self.stickDir = 0
	end
end
-- stick to wall 
function Base:stick(dir)
	if (self.stickToWall and not self.isOnFloor and self.state ~= HIT and (self.movingLeft or self.movingRight)) then 
		self.dy = 0
		self.isSticked = true
		self.stickDir = dir
		self.curJumps = 1
	end
end
-- jump while sticked to the wall
function Base:stcikJump()
	if (self.isSticked) then 
		self.isSticked = false
		self.curJumps = 1
		self.dx = self.stickJumpPower * -self.stickDir
	end
end

-------------------------------------------------------
------------------------ JUMPS ------------------------
-------------------------------------------------------
-- fixed jump height 
function Base:fixedJump(str)
	str = tonumber(str) or -self.jumpStr
	if (self.isOnFloor) then
		self.isOnFloor = false
		self.justLanded = false
		self.curJumps = 1
		self.dy = str
	elseif (self.curJumps + 1 <= self.jumpCount) then
		self.curJumps += 1
		self.dy = str
	end
	self:stcikJump()
end

-- varying jump height 
function Base:controlableJump(minStr)
	minStr = tonumber(maxStr) or -self.minJumpStr
	
	if (self.isOnFloor) then
		self.isOnFloor = false
		self.justLanded = false
		self.curJumps = 1
		self.jumpControll = true
		self.dy = minStr
	elseif (self.curJumps + 1 <= self.jumpCount) then
		self.curJumps += 1
		self.dy = minStr
		self.jumpControll = true
	end
	self:stcikJump()
end

-- stop varying jump height 
function Base:stopJump()
	self.jumpControll = false
end

-------------------------------------------------------
---------------------- OVERRIDE -----------------------
-------------------------------------------------------

-- override parent method to update body in bump world
function Base:setPosition(x, y)
	Sprite.setPosition(self, x, y)
	self.world:update(self, x, y)
end
------------------------------------------------------
----------------------- EVENTS -----------------------
------------------------------------------------------

-- triggers when hitting floor
function Base:onLanded()
	self.isOnFloor = true
	self.curJumps = 0
	self.dy = 0
	self.isSticked = false
	self.fallOffFlag = false
	if (self.prev ~= self.isOnFloor) then 
		self.justLanded = true
	end
end