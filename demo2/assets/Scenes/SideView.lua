SideView = Core.class(Sprite)

function SideView:init()
	self.keys = {}
	self.joystickVec = vec2.new()
	self.layers = Sprite.new()

	self.player = Player2.new(32,32)

	self.cam = GCam.new(self.layers)
	self.cam:setAutoSize(true)
	self.cam:setFollow(self.player)
	self:addChild(self.cam)

	local w,h=self.cam.w + 512, self.cam.h + 512
	self.bg = Pixel.new(Texture.new("bg.png", true, {wrap = Texture.REPEAT}), w,h)
	self.bg:setPosition(-self.cam.w / 2 - 256, - self.cam.h / 2 - 256)
	
	self.ground = Pixel.new(0x323232,1,w,h)
	self.ground:setY(h/2)
	self.bg:addChild(self.ground)
	
	self.player.groundLevel = self.ground:getY()

	self.layers:addChild(self.bg)
	self.layers:addChild(self.player)
	self:createUI()
	self:addInput()
end
--
function SideView:createUI(e)
	self.ui = SUI.new("mouse")
	
	local g = self.ui:hGroup(5, 5)
	
	local tf = TextField.new(nil,"","|")
	tf:setText([[Controls:
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
	tf:setTextColor(0xffffff)
	tf:setPosition(20,20)
	g:add(tf)
	g:hSeparator()
	
	local l1 = self.ui:label(150,10,"Rect shape")
	l1:setTextColor(0xffffff)
	g:add(l1)
	g:add(
		self.ui:hSlider(0,600,self.cam.deadWidth,false,{Pixel.new(0x404040,1,150,16),Pixel.new(0xffffff, 1, 16, 16)}, 
			function(obj,value,state) 
				self.cam:setDeadWidth(value)
			end
		):addValueText("Dead W")
	)
	g:add(
		self.ui:hSlider(0,600,self.cam.deadHeight,false,{Pixel.new(0x404040,1,150,16),Pixel.new(0xffffff, 1, 16, 16)}, 
			function(obj,value,state) 
				self.cam:setDeadHeight(value)
			end
		):addValueText("Dead H")
	)
	g:add(
		self.ui:hSlider(0,600,self.cam.softWidth,false,{Pixel.new(0x404040,1,150,16),Pixel.new(0xffffff, 1, 16, 16)}, 
			function(obj,value,state) 
				self.cam:setSoftWidth(value)
			end
		):addValueText("Soft W")
	)
	g:add(
		self.ui:hSlider(0,600,self.cam.softHeight,false,{Pixel.new(0x404040,1,150,16),Pixel.new(0xffffff, 1, 16, 16)}, 
			function(obj,value,state) 
				self.cam:setSoftHeight(value)
			end
		):addValueText("Soft H")
	)
	g:hSeparator()
	local l2 = self.ui:label(150,10,"Circle shape")
	l2:setTextColor(0xffffff)
	g:add(l2)
	g:add(
		self.ui:hSlider(0,600,self.cam.deadRadius,false,{Pixel.new(0x404040,1,150,16),Pixel.new(0xffffff, 1, 16, 16)}, 
			function(obj,value,state) 
				self.cam:setDeadRadius(value)
			end
		):addValueText("Dead R")
	)
	g:add(
		self.ui:hSlider(0,600,self.cam.softRadius,false,{Pixel.new(0x404040,1,150,16),Pixel.new(0xffffff, 1, 16, 16)}, 
			function(obj,value,state) 
				self.cam:setSoftRadius(value)
			end
		):addValueText("Soft R")
	)
	g:hSeparator()
	g:add(
		self.ui:hSlider(0,10,self.cam.smoothX,false,{Pixel.new(0x404040,1,150,16),Pixel.new(0xffffff, 1, 16, 16)}, 
			function(obj,value,state) 
				self.cam:setSmoothX(value)
			end
		):addValueText("Smooth X")
	)
	g:add(
		self.ui:hSlider(0,10,self.cam.smoothY,false,{Pixel.new(0x404040,1,150,16),Pixel.new(0xffffff, 1, 16, 16)}, 
			function(obj,value,state) 
				self.cam:setSmoothY(value)
			end
		):addValueText("Smooth Y")
	)
	g:hSeparator()
	g:add(
		self.ui:checkBox("", self.cam.__debug__ and 1 or 0, {Pixel.new(0x404040,1,150,16),Pixel.new(0xf0f0f0,1,150,16)},
		function(obj,state) 
			self.cam:setDebug(state == 1)
		end
	):addText("Debug mode"), "debug")
	g:add(
		self.ui:checkBox("shapeType", self.cam.shapeType == "circle" and 1 or 0, {Pixel.new(0x404040,1,150,16),Pixel.new(0xf0f0f0,1,150,16)},
		function(obj,state) 
			if state == 1 then self.cam:setShape("circle") end 
		end
	):addText("Circle"), "circle")
	g:add(
		self.ui:checkBox("shapeType", self.cam.shapeType == "rectangle" and 1 or 0, {Pixel.new(0x404040,1,150,16),Pixel.new(0xf0f0f0,1,150,16)},
		function(obj,state) 
			if state == 1 then self.cam:setShape("rectangle") end 
		end
	):addText("Rectangle"), "rect")
	self.uiGroup = g
	
	self.cam:addChild(self.ui)
	
end
--
function SideView:switchDebug()
	self.cam:switchDebug() 
	self.uiGroup:getByID("debug"):setState(self.cam.__debug__ and 1 or 0,false,true)
end
--
function SideView:setAsCircle()
	self.cam:setShape("circle") 
	self.uiGroup:getByID("circle"):setState(1,false,true)
end
--
function SideView:setAsRect()
	self.cam:setShape("rectangle") 
	self.uiGroup:getByID("rect"):setState(1,false,true)
end
--
function SideView:goBack()
	Scenes:changeScene("Selection", 1, SceneManager.fade)
	if controller then 
		controller:removeAllListeners()
	end
end
--
function SideView:addInput(e)
	
	self:addEventListener("enterFrame", self.enterFrame, self)
	self:addEventListener("keyDown", self.keyDown, self)
	self:addEventListener("keyUp", self.keyUp, self)

	pcall(function() require "controller" end)

	if controller then 
		controller:addEventListener(Event.LEFT_JOYSTICK, function(e)
			if e.x < 0 then 
				self.keys[KeyCode.LEFT] = true
			elseif e.x > 0 then 
				self.keys[KeyCode.RIGHT] = true
			else
				self.keys[KeyCode.LEFT] = false
				self.keys[KeyCode.RIGHT] = false
			end
		end)
		
		controller:addEventListener(Event.KEY_DOWN, function(e)
			local k=e.keyCode
			if k==KeyCode.BUTTON_BACK then self.cam:setZoom(1) self.cam:setAngle(0)
			elseif k==KeyCode.BUTTON_MENU then self:goBack()
			elseif k==KeyCode.BUTTON_A then self.keys[KeyCode.UP] = true
			elseif k==KeyCode.BUTTON_X then self:switchDebug()
			elseif k==KeyCode.BUTTON_B then self.cam:shake(2)
			elseif k==KeyCode.DPAD_UP then self:setAsCircle()
			elseif k==KeyCode.DPAD_DOWN then self:setAsRect()
			elseif k==KeyCode.DPAD_LEFT then self.keys[KeyCode.LEFT] = true
			elseif k==KeyCode.DPAD_RIGHT then self.keys[KeyCode.RIGHT] = true
			elseif k==KeyCode.BUTTON_L1 then self.keys["L_BTN"] = true
			elseif k==KeyCode.BUTTON_R1 then self.keys["R_BTN"] = true
			end
		end)
		
		controller:addEventListener(Event.KEY_UP, function(e)
			local k=e.keyCode
			if k==KeyCode.BUTTON_A then self.keys[KeyCode.UP] = false
			elseif k==KeyCode.DPAD_LEFT then self.keys[KeyCode.LEFT] = false
			elseif k==KeyCode.DPAD_RIGHT then self.keys[KeyCode.RIGHT] = false
			elseif k==KeyCode.BUTTON_L1 then self.keys["L_BTN"] = false
			elseif k==KeyCode.BUTTON_R1 then self.keys["R_BTN"] = false
			end
		end)
		
		controller:addEventListener(Event.LEFT_TRIGGER, function(e)
			self.keys["L_TRIGGER"] = not (e.strength == 0)
		end)
		
		controller:addEventListener(Event.RIGHT_TRIGGER, function(e)
			self.keys["R_TRIGGER"] = not (e.strength == 0)
		end)
	end
end
--
function SideView:isPressed(key) return rawget(self.keys, key) end
--
function SideView:enterFrame(e)
	local dt = e.deltaTime
	
	self.player:moveLeft(self:isPressed(KeyCode.LEFT))
	self.player:moveRight(self:isPressed(KeyCode.RIGHT))
	if self:isPressed(KeyCode.UP) then
		self.player:jump()
	end
	if self:isPressed("L_TRIGGER") or self.keys[KeyCode.O] then 
		self.cam:zoom(-0.001)
	elseif self:isPressed("R_TRIGGER") or self.keys[KeyCode.P] then 
		self.cam:zoom(0.001)
	end
	if self:isPressed("L_BTN") or self:isPressed(KeyCode.Q) then 
		self.cam:rotate(-0.1)
	elseif self:isPressed("R_BTN") or self:isPressed(KeyCode.E) then 
		self.cam:rotate(0.1)
	end
	
	self.player:update(dt)
	self.cam:update(dt)
	
	local x,y = self.cam.x,self.cam.y
	
	x = (x // 256) * 256
	y = (y // 256) * 256
	
	self.bg:setPosition(x-self.cam.w / 2 - 256, 0)
end
--
function SideView:keyDown(e)
	self.keys[e.keyCode] = true
	
	if e.keyCode == KeyCode.F then 
		self:switchDebug()
	elseif e.keyCode == KeyCode.ESC then 
		self:goBack()
	elseif e.keyCode == KeyCode.R then 
		self.cam:setZoom(1)
		self.cam:setAngle(0)
	elseif e.keyCode == KeyCode.Z then 
		self:setAsCircle()
	elseif e.keyCode == KeyCode.X then 
		self:setAsRect()
	elseif e.keyCode == KeyCode.G then 
		self.cam:shake(2)
	elseif e.keyCode == KeyCode.H then 
		self.ui:setVisible(not self.ui:isVisible())
	end
end
--
function SideView:keyUp(e)
	self.keys[e.keyCode] = false
end