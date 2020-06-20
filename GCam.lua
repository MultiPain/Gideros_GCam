local cos,sin,log,random = math.cos,math.sin,math.log,math.random

-- ref: 
-- https://www.gamedev.net/tutorials/programming/general-and-gameplay-programming/a-brief-introduction-to-lerp-r4954/#:~:text=Linear%20interpolation%20(sometimes%20called%20'lerp,0..1%5D%20range.
local function smoothOver(dt, smoothTime, convergenceFraction) return 1 - (1 - convergenceFraction)^(dt / smoothTime) end
local function lerp(a,b,t) return a + (b-a) * t end
local function clamp(v,mn,mx) return (v><mx)<>mn end

GCam = Core.class(Sprite)

function GCam:init(content, ax, ay)
	assert(content ~= stage, "bad argument #1 (сontent should be different from the 'stage')")
	self.content = content
	
	self.viewport = Viewport.new()
	self.viewport:setContent(content)
	self:addChild(self.viewport)
	
	self.matrix = Matrix.new()
	self.viewport:setMatrix(self.matrix)
	
	-- 
	self.ax = ax or 0.5
	self.ay = ay or 0.5
	self.x = 0
	self.y = 0
	self.w = 0
	self.h = 0
	self.factor = 1
	self.rotation = 0
	
	-- Bounds
	self.leftBound = -1000000
	self.rightBound = 1000000
	self.topBound = -1000000
	self.bottomBound = 1000000
	
	-- Shaker
	self.shaking = false
	self.shakeTime = 0
	self.shakeAmount = 1
	self.shakeGrowth = 5
	self.shakeAmplitude = 10
	self.shakeFrequency = 100
	
	-- Follow
	-- 0 - instant move
	self.smoothX = 0.9
	self.smoothY = 0.9
	-- Dead zone [0;1]
	self.deadWidth = 0.5
	self.deadHeight = 0.5
	-- Soft zone
	self.softWidth = 1
	self.softHeight = 1
	
	self:addEventListener(Event.APPLICATION_RESIZE, self.appResize, self)
	self:appResize()
end
---------------------------------------------------
------------------- DEBUG STUFF -------------------
---------------------------------------------------
function GCam:setDebug(flag)
	self.__debug__ = flag
	
	if flag then 
		if not self.__debugDeadZoneMesh then 
			local softColor = 0x00ffff
			local anchorColor = 0xff0000
			local dotColor = 0x00ff00
			local alpha = 0.4
			
			self.__debugMesh = Mesh.new()
			self.__debugMesh:setIndexArray(1,3,4, 1,2,4, 1,3,7, 3,5,7, 2,4,8, 4,8,6, 5,6,8, 5,8,7, 9,10,11, 9,11,12, 13,14,15, 13,15,16, 17,18,19, 17,19,20)
			self.__debugMesh:setColorArray(
				softColor,alpha, softColor,alpha, softColor,alpha, softColor,alpha, 
				softColor,alpha, softColor,alpha, softColor,alpha, softColor,alpha,  
				
				anchorColor,alpha, anchorColor,alpha, anchorColor,alpha, anchorColor,alpha, 
				anchorColor,alpha, anchorColor,alpha, anchorColor,alpha, anchorColor,alpha,
				
				dotColor,alpha, dotColor,alpha, dotColor,alpha, dotColor,alpha 
			)
			self:addChild(self.__debugMesh)
		else
			self:addChild(self.__debugMesh)
			self:addChild(self.__debugDot)
		end
		self:debugUpdate()
		self:debugUpdate(true, 0, 0)
	else
		if self.__debugMesh and self:contains(self.__debugMesh) then 
			self:removeChild(self.__debugMesh)
		end
	end
	
end
--
function GCam:debugMeshUpdate()
	local w,h = self.w, self.h
	local sx,sy = self:getScale()
	local rot = self:getRotation()
	
	local ax,ay = w * self.ax,h * self.ay
	
	local dw = (self.deadWidth * w * sx) / 2
	local dh = (self.deadHeight * h * sy) / 2
	local sw = (self.softWidth * w * sx) / 2
	local sh = (self.softHeight * h * sy) / 2
	
	local l = (w-dw) * self.ax
	local r = w-dw-l
	local t = (h-dh) * self.ay
	local b = h-dh-t
	local TS = 1
	
	--[[
	Mesh vertices
	
	1-----------------2
	| \  soft zone  / |
	|  3-----------4  |
	|  | dead zone |  |
	|  5-----------6  |
	| /             \ |
	7-----------------8
	]]	
	local off = w <> h
	self.__debugMesh:setVertexArray(
		ax-sw,ay-sh, 
		ax+sw,ay-sh,
		
		ax-dw,ay-dh,
		ax+dw,ay-dh,
		ax-dw,ay+dh,
		ax+dw,ay+dh,
		
		ax-sw,ay+sh,
		ax+sw,ay+sh,
		
		ax-TS,-off, ax+TS,-off,
		ax+TS,h+off, ax-TS,h+off,
		
		-off,ay-TS, -off,ay+TS,
		w+off,ay+TS, w+off,ay-TS
	)
	self.__debugMesh:setAnchorPosition(ax,ay)
	self.__debugMesh:setPosition(ax,ay)
	self.__debugMesh:setRotation(rot)
	
end
--
function GCam:debugUpdate(dotOnly, gx,gy)
	if self.__debug__ then 
		if dotOnly then 
			local sx,sy = self:getScale()
			local ax = self.w * self.ax
			local ay = self.h * self.ay
			local size = 4
			
			local w = size * sx
			local h = size * sy
			local x = (gx * sx - self.x * sx) + ax
			local y = (gy * sy - self.y * sy) + ay
			self.__debugMesh:setVertex(17, x-w,y-h)
			self.__debugMesh:setVertex(18, x+w,y-h)
			self.__debugMesh:setVertex(19, x+w,y+h)
			self.__debugMesh:setVertex(20, x-w,y+h)
		else
			self:debugMeshUpdate()
		end
	end
end
---------------------------------------------------
----------------- RESIZE LISTENER -----------------
---------------------------------------------------
function GCam:appResize()
	local minX,minY,maxX,maxY = app:getLogicalBounds()
	self.w = maxX+minX
	self.h = maxY+minY
	self.matrix:setPosition(self.w * self.ax,self.h * self.ay)
	self.viewport:setMatrix(self.matrix)
	
	self:debugUpdate()
end
--
---------------------------------------------------
---------------------- UPDATE ---------------------
---------------------------------------------------
function GCam:update(dt)
	local obj = self.followObj
	if obj then 
		local x,y = obj:getPosition()
		
		local sw = (self.softWidth * self.w) / 2
		local sh = (self.softHeight * self.h) / 2
		local dw = (self.deadWidth * self.w) / 2
		local dh = (self.deadHeight * self.h) / 2
		
		local dstX = self.x
		local dstY = self.y
		
		-- X smoothing
		if x > self.x + dw then -- out of dead zone on right side
			local dx = x - self.x - dw
			local fx = smoothOver(dt, self.smoothX, 0.99)
			dstX = lerp(self.x, self.x + dx, fx)
		elseif x < self.x - dw then  -- out of dead zone on left side
			local dx = self.x - dw - x
			local fx = smoothOver(dt, self.smoothX, 0.99)
			dstX = lerp(self.x, self.x - dx, fx)
		end
		-- clamp to soft zone
		dstX = clamp(dstX, x - sw,x + sw)
		
		
		-- Y smoothing
		if y > self.y + dh then -- out of dead zone on bottom side
			local dy = y - self.y - dh
			local fy = smoothOver(dt, self.smoothY, 0.99)
			dstY = lerp(self.y, self.y + dy, fy)
		elseif y < self.y - dh then  -- out of dead zone on top side
			local dy = self.y - dh - y
			local fy = smoothOver(dt, self.smoothY, 0.99)
			dstY = lerp(self.y, self.y - dy, fy)
		end
		-- clamp to soft zone
		dstY = clamp(dstY, y - sh,y + sh)
		
		if self.x ~= dstX or self.y ~= dstY then 
			self:setPosition(dstX,dstY)
		end
		
		self:debugUpdate(true,x,y)
	end
	
	if (self.shaking) then
		self.shakeAmount = 1 <> (self.shakeAmount^0.9)
		
		self.shakeTime += dt
		local noise = random() * self.shakeTime
		
		local shakeFactor = self.shakeAmplitude * log(self.shakeAmount)
		local waveX = sin(noise * self.shakeFrequency)
		local waveY = cos(noise * self.shakeFrequency)
		
		local dx = shakeFactor * waveX
		local dy = shakeFactor * waveY
		--self:move(dx, dy)
		
		self:rawSetPosition(self.x + dx, self.y + dy)
		
		self.shaking = not(self.shakeAmount <= 1.001)
		if not self.shaking then 
			self:resetShake()
		end
	end
	
	
end
--
---------------------------------------------------
--------------------- FOLLOW ----------------------
---------------------------------------------------
function GCam:setFollow(obj)
	self.followObj = obj
end
--
---------------------------------------------------
-------------------- TRANSFORM --------------------
---------------------------------------------------
function GCam:move(dx, dy)
	self:setPosition(self.x + dx, self.y + dy)
end
--
function GCam:zoom(factor)
	if self.factor + factor > 0 then 
		self.factor += factor
		self:setScale(self.factor)
	end
end
--
function GCam:rotate(ang)
	self.rotation += ang
	self:setRotation(self.rotation)
end
---------------------------------------------------
---------------------- SHAKE ----------------------
---------------------------------------------------
function GCam:shake() 
	self.shaking = true
	self.shakeAmount += self.shakeGrowth
end
--
function GCam:resetShake() 
	self.shaking = false
	self.shakeAmount = 1
	self.shakeTime = 0
end
--
function GCam:setShake(growth, amplitude, frequency)
	self.shakeGrowth = growth
	self.shakeAmplitude = amplitude or 10
	self.shakeFrequency = frequency or 100
end
--------------------------------------------------
--------------------- ZONES ----------------------
--------------------------------------------------
function GCam:setSoftZone(w,h)
	self.softWidth = w
	self.softHeight = h
	self:debugUpdate()
end
--
function GCam:setSoftZoneWidth(w)
	self.softWidth = w
	self:debugUpdate()
end
--
function GCam:setSoftZoneHeight(h)
	self.softHeight = h
	self:debugUpdate()
end
--
--
function GCam:setDeadZone(w,h)
	self.deadWidth = w
	self.deadHeight = h
	self:debugUpdate()
end
--
function GCam:setDeadZoneWidth(w)
	self.deadWidth = w
	self:debugUpdate()
end
--
function GCam:setDeadZoneHeight(h)
	self.deadHeight = h
	self:debugUpdate()
end
--
--
function GCam:setSmooth(x,y)
	self.smoothX = x
	self.smoothY = y
end
--
function GCam:setSmoothX(x)
	self.smoothX = x
end
--
function GCam:setSmoothY(y)
	self.smoothY = y
end
--
--------------------------------------------------
--------------------- BOUNDS ---------------------
--------------------------------------------------
function GCam:updateBounds()
	local x = clamp(self.x, self.leftBound, self.rightBound)
	local y = clamp(self.y, self.topBound, self.bottomBound)
	if x ~= self.x or y ~= self.y then 
		self:setPosition(x,y)
	end
end
--
function GCam:setBounds(left, top, right, bottom)
	self.leftBound = left or 0
	self.topBound = top or 0
	self.rightBound = right or 0
	self.bottomBound = bottom or 0
	
	self:updateBounds()
end
--
function GCam:setLeftBound(left)
	self.leftBound = left or 0
	self:updateBounds()
end
--
function GCam:setTopBound(top)
	self.topBound = top or 0
	self:updateBounds()
end
--
function GCam:setRightBound(right)
	self.rightBound = right or 0
	self:updateBounds()
end
--
function GCam:setBottomBound(bottom)
	self.bottomBound = bottom or 0
	self:updateBounds()
end
--
function GCam:getBounds() 
	return self.leftBound, self.topBound, self.rightBound, self.bottomBound
end
--------------------------------------------------
-------------------- OVERRIDE --------------------
--------------------------------------------------

------------------------------------------
---------------- POSITION ----------------
------------------------------------------
function GCam:rawSetPosition(x,y)
	x = clamp(x, self.leftBound, self.rightBound)
	y = clamp(y, self.topBound, self.bottomBound)
	self.matrix:setAnchorPosition(x,y)
	self.viewport:setMatrix(self.matrix)	
end
--
function GCam:setPosition(x,y)
	x = clamp(x, self.leftBound, self.rightBound)
	y = clamp(y, self.topBound, self.bottomBound)
	
	self.x = x
	self.y = y
	self.matrix:setAnchorPosition(x,y)
	self.viewport:setMatrix(self.matrix)
end
--
function GCam:setX(x)
	x = clamp(x, self.leftBound, self.rightBound)
	self.x = x
	self.matrix:setAnchorPosition(x,self.y)
	self.viewport:setMatrix(self.matrix)
end
--
function GCam:setY(y)
	y = clamp(y, self.topBound, self.bottomBound)
	self.y = y
	self.matrix:setAnchorPosition(self.x,y)
	self.viewport:setMatrix(self.matrix)
end
--
--
function GCam:getPosition()
	return self.x, self.y
end
--
function GCam:getX()
	return self.x
end
--
function GCam:getY()
	return self.y
end
------------------------------------------
----------------- SCALE ------------------
------------------------------------------
function GCam:setScale(scaleX, scaleY)
	self.matrix:setScale(scaleX, scaleY or scaleX, 1)
	self.viewport:setMatrix(self.matrix)
	self:debugUpdate()
end
--
function GCam:setScaleX(scaleX)
	self.matrix:setScaleX(scaleX)
	self.viewport:setMatrix(self.matrix)
	self:debugUpdate()
end
--
function GCam:setScaleY(scaleY)
	self.matrix:setScaleY(scaleY)
	self.viewport:setMatrix(self.matrix)
	self:debugUpdate()
end
--
--
function GCam:getScale()
	return self.matrix:getScale()
end
--
function GCam:getScaleX()
	return self.matrix:getScaleX()
end
--
function GCam:getScaleY()
	return self.matrix:getScaleY()
end
------------------------------------------
---------------- ROTATION ----------------
------------------------------------------
function GCam:setRotation(angle)
	self.matrix:setRotationZ(angle)
	self.viewport:setMatrix(self.matrix)
	self:debugUpdate()
end
--
--
function GCam:getRotation()
	return self.matrix:getRotationZ()
end
------------------------------------------
------------- ANCHOR POSITION ------------
------------------------------------------
function GCam:setAnchorPosition(anchorX, anchorY)
	self.ax = anchorX
	self.ay = anchorY
	self.matrix:setPosition(self.w * anchorX,self.h * anchorY)
	self.viewport:setMatrix(self.matrix)
	self:debugUpdate()
end
--
function GCam:setAnchorX(anchorX)
	self.ax = anchorX
	self.matrix:setPosition(self.w * anchorX,self.h * self.ay)
	self.viewport:setMatrix(self.matrix)
	self:debugUpdate()
end
--
function GCam:setAnchorY(anchorY)
	self.ay = anchorY
	self.matrix:setPosition(self.w * self.ax,self.h * anchorY)
	self.viewport:setMatrix(self.matrix)
	self:debugUpdate()
end
--
--
function GCam:getAnchorPosition()
	return self.ax, self.ay
end
------------------------------------------
------------------ SIZE ------------------
------------------------------------------
function GCam:getSize()
	return self.w, self.h
end
--
function GCam:getWidth()
	return self.w
end
--
function GCam:getHeight()
	return self.h
end
