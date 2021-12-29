local atan2,sqrt,cos,sin,log,random = math.atan2,math.sqrt,math.cos,math.sin,math.log,math.random
local PI = math.pi
local INF = math.huge
local abs = math.abs

-- ref: 
-- https://www.gamedev.net/tutorials/programming/general-and-gameplay-programming/a-brief-introduction-to-lerp-r4954/#:~:text=Linear%20interpolation%20(sometimes%20called%20'lerp,0..1%5D%20range.
local function smoothOver(dt, smoothTime, convergenceFraction) return 1 - (1 - convergenceFraction)^(dt / smoothTime) end
local function lerp(a,b,t) return a + (b-a) * t end
local function clamp(v,mn,mx) return (v><mx)<>mn end
local function map(v, minSrc, maxSrc, minDst, maxDst, clampValue)
	local newV = (v - minSrc) / (maxSrc - minSrc) * (maxDst - minDst) + minDst
	return not clampValue and newV or clamp(newV, minDst >< maxDst, minDst <> maxDst)
end
local function distance(x1,y1, x2,y2) return (x2-x1)^2 + (y2-y1)^2 end
local function distanceSq(x1,y1, x2,y2) return sqrt((x2-x1)^2 + (y2-y1)^2) end
local function angle(x1,y1, x2,y2) return atan2(y2-y1,x2-x1) end
local function setMeshAsCircle(m, ox, oy, rad_in_x, rad_in_y, rad_out_x, rad_out_y, color, alpha, edges)
	edges = edges or 16
	local step = (PI*2)/edges
	
	local vi = m:getVertexArraySize() + 1
	local ii = m:getIndexArraySize() + 1
	local svi = vi
	local sii = ii
	
	for i = 0, edges-1 do 
		local ang = i * step
		local cosa = cos(ang)
		local sina = sin(ang)
		
		local x_in = ox + rad_in_x * cosa
		local y_in = oy + rad_in_y * sina
		
		local x_out = ox + rad_out_x * cosa
		local y_out = oy + rad_out_y * sina
		
		m:setVertex(vi+0,x_in,y_in)
		m:setVertex(vi+1,x_out,y_out)
		
		m:setColor(vi+0,color, alpha)
		m:setColor(vi+1,color, alpha)
		
		vi += 2
		if i <= edges-2 then
			local si = (svi-1)+((i+1)*2)-1
			m:setIndex(ii+0,si)
			m:setIndex(ii+1,si+1)
			m:setIndex(ii+2,si+3)
			m:setIndex(ii+3,si)
			m:setIndex(ii+4,si+3)
			m:setIndex(ii+5,si+2)			
			ii += 6
		end
	end
	local si = (svi-1)+(edges*2)-1
	m:setIndex(ii+0,si)
	m:setIndex(ii+1,si+1)
	m:setIndex(ii+2,svi)
	
	m:setIndex(ii+3,si+1)
	m:setIndex(ii+4,svi+1)
	m:setIndex(ii+5,svi)
end

local function outExponential(ratio) if ratio == 1 then return 1 end return 1-2^(-10 * ratio) end

GCam = Core.class(Sprite)
GCam.SHAKE_DELAY = 10

function GCam:init(content, ax, ay)
	assert(content ~= stage, "bad argument #1 (сontent should be different from the 'stage')")
	
	self.viewport = Viewport.new()
	self.viewport:setContent(content)
	
	self.content = Sprite.new()
	self.content:addChild(self.viewport)
	self:addChild(self.content)
	
	self.matrix = Matrix.new()
	self.viewport:setMatrix(self.matrix)
	
	-- 
	self.w = 0
	self.h = 0
	self.ax = ax or 0.5
	self.ay = ay or 0.5
	self.x = 0
	self.y = 0
	self.zoomFactor = 1
	self.rotation = 0
	
	self.followOX = 0
	self.followOY = 0
	
	-- Bounds
	self.leftBound   = -INF
	self.rightBound  = INF
	self.topBound    = -INF
	self.bottomBound = INF
	
	-- Shaker
	self.shakeTimer = Timer.new(GCam.SHAKE_DELAY, 1)
	self.shakeDistance = 0
	self.shakeCount = 0
	self.shakeAmount = 0
	self.shakeTimer:addEventListener("timerComplete", self.shakeDone, self)
	self.shakeTimer:addEventListener("timer", self.shakeUpdate, self)
	self.shakeTimer:stop()
	
	-- prediction
	self.predictMode = false
	self.predictSmooth = 0
	self.prediction = 0.5
	self.lockPredX = false
	self.lockPredY = false
	-- to detect object velocity
	self.__prevPosX = 0
	self.__prevPosY = 0
	self.__predictOffsetX = 0
	self.__predictOffsetY = 0
		
	
	-- Follow
	-- 0 - instant move
	self.smoothX = 0.9
	self.smoothY = 0.9
	-- Dead zone
	self.deadWidth  = 50
	self.deadHeight = 50
	self.deadRadius = 25
	-- Soft zone
	self.softWidth  = 150
	self.softHeight = 150
	self.softRadius = 75
	
	---------------------------------------
	------------- debug stuff -------------
	---------------------------------------
	self.__debugSoftColor = 0xffff00
	self.__debugAnchorColor = 0xff0000
	self.__debugDotColor = 0x00ff00
	self.__debugAlpha = 0.5
	
	self.__debugRMesh = Mesh.new()
	self.__debugRMesh:setIndexArray(1,3,4, 1,2,4, 1,3,7, 3,5,7, 2,4,8, 4,8,6, 5,6,8, 5,8,7, 9,10,11, 9,11,12, 13,14,15, 13,15,16, 17,18,19, 17,19,20)
	self.__debugRMesh:setColorArray(self.__debugSoftColor,self.__debugAlpha, self.__debugSoftColor,self.__debugAlpha, self.__debugSoftColor,self.__debugAlpha, self.__debugSoftColor,self.__debugAlpha,  self.__debugSoftColor,self.__debugAlpha, self.__debugSoftColor,self.__debugAlpha, self.__debugSoftColor,self.__debugAlpha, self.__debugSoftColor,self.__debugAlpha, self.__debugAnchorColor,self.__debugAlpha, self.__debugAnchorColor,self.__debugAlpha, self.__debugAnchorColor,self.__debugAlpha, self.__debugAnchorColor,self.__debugAlpha,  self.__debugAnchorColor,self.__debugAlpha, self.__debugAnchorColor,self.__debugAlpha, self.__debugAnchorColor,self.__debugAlpha, self.__debugAnchorColor,self.__debugAlpha, self.__debugDotColor,self.__debugAlpha, self.__debugDotColor,self.__debugAlpha, self.__debugDotColor,self.__debugAlpha, self.__debugDotColor,self.__debugAlpha)
	
	self.__debugCMesh = Mesh.new()
	---------------------------------------
	---------------------------------------
	---------------------------------------
	
	self:setShape("rectangle")	
	self:setAnchor(self.ax,self.ay)
	self:updateClip()
end
---------------------------------------------------
------------------- DEBUG STUFF -------------------
---------------------------------------------------
function GCam:setDebug(flag)
	self.__debug__ = flag
	
	if flag then 
		if self.shapeType == "rectangle" then
			self.__debugCMesh:removeFromParent()
			self:addChild(self.__debugRMesh)
		elseif self.shapeType == "circle" then
			self.__debugRMesh:removeFromParent()
			self:addChild(self.__debugCMesh)
		end
		self:debugUpdate()
		self:debugUpdate(true, 0, 0)
	else
		self.__debugCMesh:removeFromParent()
		self.__debugRMesh:removeFromParent()
	end
	
end
--
function GCam:switchDebug()
	self:setDebug(not self.__debug__)
end
--
function GCam:debugMeshUpdate()
	local w,h = self.w, self.h
	local zoom = self.zoomFactor
	local rot = self.rotation
	
	local ax,ay = w * self.ax,h * self.ay
	
	local TS = 1
	local off = w <> h
	
	if self.shapeType == "rectangle" then
		local dw = (self.deadWidth  * zoom) / 2
		local dh = (self.deadHeight * zoom) / 2
		local sw = (self.softWidth  * zoom) / 2
		local sh = (self.softHeight * zoom) / 2
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
		
		self.__debugRMesh:setVertexArray(
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
		self.__debugRMesh:setAnchorPosition(ax,ay)
		self.__debugRMesh:setPosition(ax,ay)
		self.__debugRMesh:setRotation(rot)
	elseif self.shapeType == "circle" then
		--[[
		Mesh:
		
		-- first 4 vertex is green target point
		1--2
		|  |
		4--3
		
		next, vertical anchor line
		5--6
		|  |
		|  |
		|  |
		8--7
		next, horizontal anchor line
		9--------10
		|         |
		12-------11
		and finaly, circle 
		
		8 edges "circle" look like this:
		
		 24--------------26--------------28 
		 | \   soft zone  |             / |
		 |  23-----------25-----------27  |
		 |  |                         |   |
		 |  |           dead          |   |
		22--21          zone         13--14
		 |  |                         |   |
		 |  |                         |   |
		 |  19-----------17-----------15  |
		 | /              |             \ |
		 20--------------18--------------16
		]]
		local dr = self.deadRadius * zoom
		local sr = self.softRadius * zoom
		
		self.__debugCMesh:setVertexArray(0,0,0,0,0,0,0,0,ax-TS,-off, ax+TS,-off,ax+TS,h+off, ax-TS,h+off, -off,ay-TS, -off,ay+TS, w+off,ay+TS, w+off,ay-TS)
		self.__debugCMesh:setIndexArray(1,2,3, 1,3,4, 5,6,7, 5,7,8, 9,10,11, 9,11,12)
		self.__debugCMesh:setColorArray(self.__debugDotColor,self.__debugAlpha, self.__debugDotColor,self.__debugAlpha, self.__debugDotColor,self.__debugAlpha, self.__debugDotColor,self.__debugAlpha, self.__debugAnchorColor,self.__debugAlpha, self.__debugAnchorColor,self.__debugAlpha, self.__debugAnchorColor,self.__debugAlpha, self.__debugAnchorColor,self.__debugAlpha, self.__debugAnchorColor,self.__debugAlpha, self.__debugAnchorColor,self.__debugAlpha, self.__debugAnchorColor,self.__debugAlpha, self.__debugAnchorColor,self.__debugAlpha)
		
		setMeshAsCircle(self.__debugCMesh, ax,ay, dr, dr, sr, sr, self.__debugSoftColor,self.__debugAlpha, 32)
		
		self.__debugCMesh:setAnchorPosition(ax,ay)
		self.__debugCMesh:setPosition(ax,ay)
		self.__debugCMesh:setRotation(rot)
	end
	
end
--
function GCam:debugUpdate(dotOnly, gx,gy)
	if self.__debug__ then 
		if dotOnly then 
			local zoom = self:getZoom()
			local ax = self.w * self.ax
			local ay = self.h * self.ay
			local size = 4 * zoom
			
			local x = (gx * zoom - self.x * zoom) + ax
			local y = (gy * zoom - self.y * zoom) + ay
			if self.shapeType == "rectangle" then
				self.__debugRMesh:setVertex(17, x-size,y-size)
				self.__debugRMesh:setVertex(18, x+size,y-size)
				self.__debugRMesh:setVertex(19, x+size,y+size)
				self.__debugRMesh:setVertex(20, x-size,y+size)
			elseif self.shapeType == "circle" then
				self.__debugCMesh:setVertex(1, x-size,y-size)
				self.__debugCMesh:setVertex(2, x+size,y-size)
				self.__debugCMesh:setVertex(3, x+size,y+size)
				self.__debugCMesh:setVertex(4, x-size,y+size)
			end
		else
			self:debugMeshUpdate()
		end
	end
end
---------------------------------------------------
----------------- RESIZE LISTENER -----------------
---------------------------------------------------
-- set camera size to window size
function GCam:setAutoSize(flag)
	if flag then 
		self:addEventListener(Event.APPLICATION_RESIZE, self.appResize, self)
		self:appResize()
	elseif self:hasEventListener(Event.APPLICATION_RESIZE) then
		self:removeEventListener(Event.APPLICATION_RESIZE, self.appResize, self)
	end
end
--
function GCam:appResize()
	local minX,minY,maxX,maxY = application:getLogicalBounds()
	self.w = maxX+minX
	self.h = maxY+minY
	self.matrix:setPosition(self.w * self.ax,self.h * self.ay)
	self.viewport:setMatrix(self.matrix)
	
	self:debugUpdate()
	self:updateClip()
end
--
---------------------------------------------------
---------------------- SHAPES ---------------------
---------------------------------------------------
-- 
function GCam:rectangle(dt,x,y)
	local sw = self.softWidth  / 2
	local sh = self.softHeight / 2
	local dw = self.deadWidth  / 2
	local dh = self.deadHeight / 2
	
	local dstX = self.x
	local dstY = self.y
	
	-- X smoothing
	if x > self.x + dw then -- out of dead zone on right side
		local t = smoothOver(dt, self.smoothX, 0.99)
		local newX = lerp(self.x, x - dw, t)
		dstX = clamp(newX, x - sw, x + sw)
	elseif x < self.x - dw then  -- out of dead zone on left side
		local t = smoothOver(dt, self.smoothX, 0.99)
		local newX = lerp(self.x, x + dw, t)
		dstX = clamp(newX, x - sw, x + sw)
	end
	-- clamp to soft zone
	
	-- Y smoothing
	if y > self.y + dh then -- out of dead zone on bottom side
		local t = smoothOver(dt, self.smoothY, 0.99)
		local newY = lerp(self.y, y - dh, t)
		dstY = clamp(newY, y - sh,y + sh)
	elseif y < self.y - dh then  -- out of dead zone on top side
		local t = smoothOver(dt, self.smoothY, 0.99)
		local newY = lerp(self.y, y + dh, t)
		dstY = clamp(newY, y - sh,y + sh)
	end
	-- clamp to soft zone
	
	return dstX, dstY
end
-- 
function GCam:circle(dt,x,y)
	local dr = self.deadRadius
	local sr = self.softRadius
	
	local dstX, dstY = self.x, self.y
	
	local d = distanceSq(self.x, self.y, x, y)
	
	if d > dr and d <= sr then -- out of dead zone on bottom side
		local offset = d-dr		
		local ang = angle(self.x, self.y, x, y)
		local fx = smoothOver(dt, self.smoothX, 0.99)
		local fy = smoothOver(dt, self.smoothY, 0.99)
		dstX = lerp(self.x, self.x + cos(ang) * offset, fx)
		dstY = lerp(self.y, self.y + sin(ang) * offset, fy)
	elseif d > sr then
		local ang = angle(self.x, self.y, x, y)
		local offset = d-sr+120*dt
		dstX = self.x + cos(ang) * offset
		dstY = self.y + sin(ang) * offset
	end
	
	return dstX, dstY
end
-- shapeType(string): function name
--		can be "rectangle" or "circle"
--		you can create custom shape by 
--		adding a new method to a class
--		then use its name as shapeType
function GCam:setShape(shapeType)
	self.shapeType = shapeType
	self.shapeFunction = self[shapeType]
	assert(self.shapeFunction ~= nil, "[GCam]: shape with name \""..shapeType.."\" does not exist")
	assert(type(self.shapeFunction) == "function", "[GCam]: incorrect shape type. Must be\"function\", but was: "..type(shapeFunction))
	-- DEBUG --
	self:setDebug(self.__debug__)
	self:debugUpdate()
	self:debugUpdate(true, 0, 0)
end
--
function GCam:getShape()
	return self.shapeFunction
end
--
function GCam:getShapeType()
	return self.shapeType
end
---------------------------------------------------
---------------------- UPDATE ---------------------
---------------------------------------------------
function GCam:update(dt)
	local obj = self.followObj
	if obj then 
		local x,y = obj:getPosition()
		
		if (self.predictMode) then 
			if (dt == 0) then dt = 0.00001 end
			local dx = (x - self.__prevPosX) / dt * self.prediction
			local dy = (y - self.__prevPosY) / dt * self.prediction
			
			if (self.predictSmooth > 0) then 
				local t = smoothOver(dt, self.predictSmooth, 0.99)--1 - self.predictSmooth ^ dt
				self.__predictOffsetX = lerp(self.__predictOffsetX, dx, t)
				self.__predictOffsetY = lerp(self.__predictOffsetY, dy, t)
			else
				self.__predictOffsetX = dx
				self.__predictOffsetY = dy
			end
			
			if (self.lockPredX) then 
				self.__predictOffsetX = 0
			end
			
			if (self.lockPredY) then 
				self.__predictOffsetY = 0
			end
		end
		
		self.__prevPosX = x
		self.__prevPosY = y
		
		x += self.followOX + self.__predictOffsetX
		y += self.followOY + self.__predictOffsetY
		
		local dstX, dstY = self:shapeFunction(dt, x, y)
		
		if self.x ~= dstX or self.y ~= dstY then 
			self:goto(dstX,dstY)
		end
		
		self:debugUpdate(true,x,y)
		
	end
	self:updateClip()
end
--
---------------------------------------------------
------------------- PREDICTION --------------------
---------------------------------------------------
function GCam:setPredictMode(mode)
	self.predictMode = mode
end
--
function GCam:setPrediction(num)
	self.prediction = num
end
--
function GCam:lockPredictionX()
	self.lockPredX = true
end
--
function GCam:lockPredictionY()
	self.lockPredY = true
end
--
function GCam:setLockPredictionX(flag)
	self.lockPredX = flag
end
--
function GCam:setLockPredictionY(flag)
	self.lockPredY = flag
end
--
function GCam:setPredictionSmoothing(num)
	self.predictSmooth = num
end
--
---------------------------------------------------
--------------------- FOLLOW ----------------------
---------------------------------------------------
function GCam:setFollow(obj)
	if (obj ~= nil) then 
		assert(obj.getPosition and obj:getClass() == 'Sprite', "Invalid follow object!")
		self.__prevPosX, self.__prevPosY = obj:getPosition()	
	end
	
	self.followObj = obj	
end
--
function GCam:setFollowOffset(x,y)
	self.followOX = x
	self.followOY = y
end
--
function GCam:setFollowOffsetX(x)
	self.followOX = x
end
--
function GCam:setFollowOffsetY(y)
	self.followOY = y
end
---------------------------------------------------
---------------------- SHAKE ----------------------
---------------------------------------------------
-- duration (number): time is s.
--	distance (number): maximum shake offset
function GCam:shake(duration, distance)
	self.shaking = true
	
	self.shakeCount = 0
	self.shakeDistance = distance or 100
	self.shakeAmount = (duration*1000) // GCam.SHAKE_DELAY
	
	self.shakeTimer:reset()
	self.shakeTimer:setRepeatCount(self.shakeAmount)
	self.shakeTimer:start()
end
--
function GCam:shakeDone()
	self.shaking = false
	self.shakeCount = 0
	self.content:setPosition(0,0)
end
--
function GCam:shakeUpdate()
	self.shakeCount += 1
	local amplitude = 1 - outExponential(self.shakeCount/self.shakeAmount)
	local hd = self.shakeDistance / 2
	local x = random(-hd,hd)*amplitude
	local y = random(-hd,hd)*amplitude
	self.content:setPosition(x, y)
end
--------------------------------------------------
--------------------- ZONES ----------------------
--------------------------------------------------
--	Camera intepolate its position towards target
-- w (number): soft zone width
-- h (number): soft zone height
function GCam:setSoftSize(w,h)
	self.softWidth = w
	self.softHeight = h or w
	self:debugUpdate()
end
--
function GCam:setSoftWidth(w)
	self.softWidth = w
	self:debugUpdate()
end
--
function GCam:setSoftHeight(h)
	self.softHeight = h
	self:debugUpdate()
end
-- r (number): soft zone radius (only if shape type is "circle")
function GCam:setSoftRadius(r)
	self.softRadius = r
	self:debugUpdate()
end
--
--
--	Camera does not move in dead zone
-- w (number): dead zone width
-- h (number): dead zone height
function GCam:setDeadSize(w,h)
	self.deadWidth = w
	self.deadHeight = h or w
	self:debugUpdate()
end
--
function GCam:setDeadWidth(w)
	self.deadWidth = w
	self:debugUpdate()
end
--
function GCam:setDeadHeight(h)
	self.deadHeight = h
	self:debugUpdate()
end
--
function GCam:setDeadRadius(r)
	self.deadRadius = r
	self:debugUpdate()
end
--
--
-- Smooth factor
--	x (number):
--	y (number):
function GCam:setSmooth(x,y)
	self.smoothX = x
	self.smoothY = y or x
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
function GCam:checkBounds(x,y)
	local offX = self.w * self.ax
	local offY = self.h * self.ay
	local newX = clamp(x, self.leftBound + offX, self.rightBound - offX)
	local newY = clamp(y, self.topBound + offY, self.bottomBound - offY)
	return newX,newY
end
--
function GCam:updateBounds()
	local x,y = self:checkBounds(self.x, self.y)
	if x ~= self.x or y ~= self.y then 
		self:goto(x,y)
	end
end
--
-- Camera can move only inside given bbox

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
---------------------------------------------------
----------------- TRANSFORMATIONS -----------------
---------------------------------------------------
function GCam:move(dx, dy)
	self:goto(self.x + dx, self.y + dy)
end
--
function GCam:zoom(value)
	local v = self.zoomFactor + value
	if v > 0 then 
		self:setZoom(v)
	end
end
--
function GCam:rotate(ang)
	self.rotation += ang
	self:setAngle(self.rotation)
end

------------------------------------------
---------------- POSITION ----------------
------------------------------------------
function GCam:rawGoto(x,y)
	x, y = self:checkBounds(x,y)
	
	self.matrix:setAnchorPosition(x,y)
	self.viewport:setMatrix(self.matrix)	
end
--
function GCam:goto(x,y)
	self.x, self.y = self:checkBounds(x,y)
	
	self.matrix:setAnchorPosition(self.x, self.y)
	self.viewport:setMatrix(self.matrix)
end
--
function GCam:gotoX(x)
	self.x, self.y = self:checkBounds(x, self.y)
	
	self.matrix:setAnchorPosition(self.x, self.y)
	self.viewport:setMatrix(self.matrix)
end
--
function GCam:gotoY(y)
	self.x, self.y = self:checkBounds(self.x, y)
	
	self.matrix:setAnchorPosition(self.x, self.y)
	self.viewport:setMatrix(self.matrix)
end
--
------------------------------------------
------------------ ZOOM ------------------
------------------------------------------
function GCam:setZoom(zoom)
	self.zoomFactor = zoom
	self.matrix:setScale(zoom, zoom, 1)
	self.viewport:setMatrix(self.matrix)
	self:debugUpdate()
end
--
--
function GCam:getZoom()
	return self.zoomFactor
end
--
------------------------------------------
---------------- ROTATION ----------------
------------------------------------------
function GCam:setAngle(angle)
	self.rotation = angle
	self.matrix:setRotationZ(angle)
	self.viewport:setMatrix(self.matrix)
	self:debugUpdate()
end
--
--
function GCam:getAngle()
	return self.matrix:getRotationZ()
end
------------------------------------------
-------------- ANCHOR POINT --------------
------------------------------------------
function GCam:setAnchor(anchorX, anchorY)
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
function GCam:getAnchor()
	return self.ax, self.ay
end
------------------------------------------
------------------ SIZE ------------------
------------------------------------------
function GCam:updateClip()
	local ax = self.w * self.ax
	local ay = self.h * self.ay
	--self.viewport:setClip(self.x-ax,self.y-ay,self.w,self.h+ay)
	--self.viewport:setAnchorPosition(self.x,self.y)
end
--
function GCam:setSize(w,h)
	self.w = w
	self.h = h
	
	self:debugUpdate()
	self:updateClip()
end
--
