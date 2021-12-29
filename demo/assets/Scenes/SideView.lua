--!NOEXEC

SideView = Core.class(BaseScene)

function SideView:init()
	self.layers = Sprite.new()

	self.player = Player2.new(32, 32)

	self.cam = GCam.new(self.layers)
	self.cam:setAutoSize(true)
	self.cam:setFollow(self.player)
	self:addChild(self.cam)

	-- Infinite background
	local w, h = self.cam.w + 512, self.cam.h + 512
	self.bg = Pixel.new(Texture.new("bg.png", true, {wrap = Texture.REPEAT}), w,h)
	self.bg:setPosition(-self.cam.w / 2 - 256, - self.cam.h / 2 - 256)
	
	-- Ground level
	self.ground = Pixel.new(0x323232,1,w,h)
	self.ground:setY(h/2)
	self.bg:addChild(self.ground)
	
	self.player.groundLevel = self.ground:getY()

	self.layers:addChild(self.bg)
	self.layers:addChild(self.player)
	
	
	-- GUI helper variables
	self.currentShapeIndex = 0
end
--
function SideView:postInit()
	self.cam:addChild(self.ui)
	
	self:initControllerInput()
end
--
function SideView:onJoystickLeft(e)
	if e.x < 0 then 
		self:setNewKey(KeyCode.LEFT, true)
	elseif e.x > 0 then 
		self:setNewKey(KeyCode.RIGHT, true)
	else
		self:setNewKey(KeyCode.LEFT, false)
		self:setNewKey(KeyCode.RIGHT, false)
	end
	
	if (e.y < -0.5) then 
		self:setNewKey(KeyCode.UP, true)
	end
end
--
function SideView:checkInputs()
	self.player:moveLeft(self:checkKey(KeyCode.LEFT) or self:checkKey(KeyCode.DPAD_LEFT))
	self.player:moveRight(self:checkKey(KeyCode.RIGHT) or self:checkKey(KeyCode.DPAD_RIGHT))
	
	if (self:checkKey(KeyCode.F, true) or self:checkKey(KeyCode.BUTTON_X, true)) then 
		self.cam:switchDebug()
	elseif (self:checkKey(KeyCode.ESC, true) or self:checkKey(KeyCode.BUTTON_MENU, true)) then 
		self:goBack()
	elseif (self:checkKey(KeyCode.R, true) or self:checkKey(KeyCode.BUTTON_BACK, true)) then 
		self.cam:setZoom(1)
		self.cam:setAngle(0)
	elseif (self:checkKey(KeyCode.Z, true) or self:checkKey(KeyCode.BUTTON_A, true)) then 
		self.currentShapeIndex = 1
		self.cam:setShape("circle")
	elseif (self:checkKey(KeyCode.X, true) or self:checkKey(KeyCode.BUTTON_Y, true)) then 
		self.currentShapeIndex = 0
		self.cam:setShape("rectangle")
	elseif (self:checkKey(KeyCode.G, true) or self:checkKey(KeyCode.BUTTON_B, true)) then 
		self.cam:shake(2)
	elseif (self:checkKey(KeyCode.H, true) or self:checkKey(KeyCode.BUTTON_L3, true)) then 
		self.ui:setVisible(not self.ui:isVisible())
	end
	
	if (self:checkKey(KeyCode.UP, true) or self:checkKey(KeyCode.DPAD_UP)) then
		self.player:jump()
	end
	
	if self:checkKey("L_TRIGGER") or self:checkKey(KeyCode.O) then 
		self.cam:zoom(-0.001)
	elseif self:checkKey("R_TRIGGER") or self:checkKey(KeyCode.P) then 
		self.cam:zoom(0.001)
	end
	
	if self:checkKey(KeyCode.BUTTON_L1) or self:checkKey(KeyCode.Q) then 
		self.cam:rotate(-0.1)
	elseif self:checkKey(KeyCode.BUTTON_R1) or self:checkKey(KeyCode.E) then 
		self.cam:rotate(0.1)
	end
end
--
function SideView:drawUI(dt)
	local cam = self.cam
	local player = self.player
	
	local ui = self.ui
	
	if (ui:button("Back", -1, 40)) then
		self:goBack()
	end
	
	
	ui:textWrapped([[Controls:
ESC or Menu (gamepad) - go back
Arrows or DPad Left/Right (gamepad) - movement
A (gamepad) - jump
Q,E or L1,R1 (gamepad) - rotate camera
G or B (gamepad) - shake camera
O,P or Left trigger, Right trigger (gamepad) - scale camera
R or Back (gamepad) - reset roation and scale
F or X (gamepad) - switch debug view
Z or DPad UP (gamepad) - set camera shape to "circle"
X or DPad Down (gamepad) - set camera shape to "rectangle"]])
	
	local newValue, flag = ui:checkbox("Debug mode", cam.__debug__)
	if (flag) then 
		cam:setDebug(newValue)
	end
	
	newValue, flag = ui:checkbox("Follow mode", cam.followObj ~= nil)
	if (flag) then 
		if (not newValue) then 
			cam:setFollow(nil)
		else
			cam:setFollow(self.player)
		end
	end
	
	cam.predictMode = ui:checkbox("Predict mode", cam.predictMode)
	
	if (cam.predictMode) then 
	
		ui:sameLine()
		cam.lockPredX = ui:checkbox("Lock X", cam.lockPredX)
		ui:sameLine()
		cam.lockPredY = ui:checkbox("Lock Y", cam.lockPredY)
	
		newValue, flag = ui:sliderFloat("Prediction fraction", cam.prediction, 0, 3)
		if (flag) then 
			cam:setPrediction(newValue)
		end
		newValue, flag = ui:sliderFloat("Prediction smooth", cam.predictSmooth, 0, 1)
		if (flag) then 
			cam:setPredictionSmoothing(newValue)
		end
		
		ui:separator()
	end
	
	local newShapeIndex, flag = ui:combo("Shape", self.currentShapeIndex, "rectangle\0circle\0\0")
	if (flag) then 
		self.currentShapeIndex = newShapeIndex
		if (newShapeIndex == 0) then 
			cam:setShape("rectangle")
		else
			cam:setShape("circle")
		end
	end
	
	if (cam.shapeType == "rectangle") then 
		local newW, newH, flag = ui:sliderFloat2("Dead zone size", cam.deadWidth, cam.deadHeight, 0, 2000)
		if (flag) then 
			cam:setDeadWidth(newW)
			cam:setDeadHeight(newH)
		end
		
		newW, newH, flag = ui:sliderFloat2("Soft zone size", cam.softWidth, cam.softHeight, 0, 2000)
		if (flag) then 
			cam:setSoftWidth(newW)
			cam:setSoftHeight(newH)
		end
	elseif (cam.shapeType == "circle") then
		local newRadius, flag = ui:sliderFloat("Dead zone radius", cam.deadRadius, 0, 2000)
		if (flag) then 
			cam:setDeadRadius(newRadius)
		end
		
		local newRadius, flag = ui:sliderFloat("Soft zone radius", cam.deadRadius, 0, 2000)
		if (flag) then 
			cam:setSoftRadius(newRadius)
		end
	else
		ui:text("No settings for "..cam.shapeType)
	end
	ui:separator()
	
	-- smooth
	
	if (ui:button("Reset##Smooth")) then
		cam:setSmoothX(0.9)
		cam:setSmoothY(0.9)
	end
	ui:sameLine()
	local newSmoothX, newSmoothY, sflag = ui:sliderFloat2("Smooth", cam.smoothX, cam.smoothY, 0, 1)
	if (sflag) then 
		cam:setSmoothX(newSmoothX)
		cam:setSmoothY(newSmoothY)
	end
	
	-- anchor
	
	if (ui:button("Reset##Anchor")) then
		cam:setAnchorX(0.5)
		cam:setAnchorY(0.5)
	end
	ui:sameLine()
	local newAX, newAY, flag = ui:sliderFloat2("Anchor", cam.ax, cam.ay, 0, 1)
	if (flag) then 
		cam:setAnchorX(newAX)
		cam:setAnchorY(newAY)
	end
	
	-- offset
	if (ui:button("Reset##Offset")) then
		cam:setFollowOffsetX(0)
		cam:setFollowOffsetY(0)
	end
	ui:sameLine()
	local newOffsetX, newOffsetY, flag = ui:sliderFloat2("Follow offset", cam.followOX, cam.followOY, -500, 500)
	if (flag) then 
		cam:setFollowOffsetX(newOffsetX)
		cam:setFollowOffsetY(newOffsetY)
	end
	
	-- zoom
	if (ui:button("Reset##Zoom")) then
		cam:setZoom(1)
	end
	ui:sameLine()
	local newZoom, flag = ui:sliderFloat("Zoom", cam.zoomFactor, 0.01, 4)
	if (flag) then 
		cam:setZoom(newZoom)
	end
	
	-- rotation
	if (ui:button("Reset##Rotation")) then
		cam:setAngle(0)
	end
	ui:sameLine()
	local newRotation, flag = ui:dragFloat("Rotation", cam.rotation)
	if (flag) then 
		cam:setAngle(newRotation)
	end
	
	if (ui:button("Reset all", -1)) then 
		cam:setSmoothX(0.9)
		cam:setSmoothY(0.9)
		cam:setAnchorX(0.5)
		cam:setAnchorY(0.5)
		cam:setFollowOffsetX(0)
		cam:setFollowOffsetY(0)
		cam:setZoom(1)
		cam:setAngle(0)
	end
	
	-- bounds
	ui:separator()
	
	local newBoundLeft, newBoundRight, flag = ui:dragFloat2("Left/Right bounds", cam.leftBound, cam.rightBound)
	if (flag) then 
		cam:setLeftBound(newBoundLeft)
		cam:setRightBound(newBoundRight)
	end
	local newBoundTop, newBoundBottom, flag = ui:dragFloat2("Top/bottom bounds", cam.topBound, cam.bottomBound)
	if (flag) then 
		cam:setTopBound(newBoundTop)
		cam:setBottomBound(newBoundBottom)
	end
	
end
--
function SideView:onDrawUI(dt)	
	self:checkInputs()
	self.player:update(dt)
	self.cam:update(dt)
	
	self:drawUI(dt)
	
	local x, y = self.cam.x, self.cam.y
	
	x = (x // 256) * 256
	y = (y // 256) * 256
	
	self.bg:setPosition(x - self.cam.w / 2 - 256, 0)
end