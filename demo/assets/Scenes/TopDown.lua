TopDown = Core.class(Sprite)

function TopDown:init()
	self.keys = {}
	self.joystickVec = vec2.new()
	self.layers = Sprite.new()

	self.player = Player.new()

	self.cam = GCam.new(self.layers)
	self.cam:setAutoSize(true)
	self.cam:setFollow(self.player)
	self:addChild(self.cam)

	self.bg = Pixel.new(Texture.new("bg.png", true, {wrap = Texture.REPEAT}), self.cam.w + 512, self.cam.h + 512)
	self.bg:setPosition(-self.cam.w / 2 - 256, - self.cam.h / 2 - 256)

	self.layers:addChild(self.bg)
	self.layers:addChild(self.player)
	
	self.uiLayer = Sprite.new()
	local tf = TextField.new(nil,"","|")
	tf:setText([[Controls:
H or Menu (gamepad) - show/hide this text
W,S,A,D or Left stick (gamepad) - movement
Q,E or L1,R1 (gamepad) - rotate camera
G or B (gamepad) - shake camera
O,P or Left trigger, Right trigger (gamepad) - scale camera
R or Back (gamepad) - reset roation and scale
F or X (gamepad) - switch debug view
Z or A (gamepad) - set camera shape to "circle"
X or Y (gamepad) - set camera shape to "rectangle"]])
	tf:setTextColor(0xffffff)
	tf:setPosition(20,20)
	tf:setScale(2)
	self.uiLayer:addChild(tf)
	self.cam:addChild(self.uiLayer)
	
	self:addInput()
end

function TopDown:addInput(e)
	
	self:addEventListener("enterFrame", self.enterFrame, self)
	self:addEventListener("keyDown", self.keyDown, self)
	self:addEventListener("keyUp", self.keyUp, self)

	pcall(function() require "controller" end)

	if controller then 
		controller:addEventListener(Event.LEFT_JOYSTICK, function(e)
			--print("LEFT_JOYSTICK:", "x:"..e.x, "y:"..e.y, "angle:"..e.angle, "strength:"..e.strength)
			self.joystickVec.x = e.x
			self.joystickVec.y = e.y
			--self.player:setRotation(^>e.angle or 0)
		end)
		
		controller:addEventListener(Event.RIGHT_JOYSTICK, function(e)
			--print("RIGHT_JOYSTICK:", "x:"..e.x, "y:"..e.y, "angle:"..e.angle, "strength:"..e.strength)
		end)
		
		controller:addEventListener(Event.KEY_DOWN, function(e)
			local k=e.keyCode
			if k==KeyCode.BUTTON_BACK then self.cam:setZoom(1) self.cam:setAngle(0)
			elseif k==KeyCode.BUTTON_MENU then self.uiLayer:setVisible(not self.uiLayer:isVisible())
			elseif k==KeyCode.BUTTON_Y then self.cam:setShape("rectangle")
			elseif k==KeyCode.BUTTON_A then self.cam:setShape("circle")
			elseif k==KeyCode.BUTTON_X then self.cam:switchDebug()
			elseif k==KeyCode.BUTTON_B then self.cam:shake(2)
			elseif k==KeyCode.DPAD_UP then self.joystickVec.y = -1
			elseif k==KeyCode.DPAD_DOWN then self.joystickVec.y = 1
			elseif k==KeyCode.DPAD_LEFT then self.joystickVec.x = -1
			elseif k==KeyCode.DPAD_RIGHT then self.joystickVec.x = 1
			elseif k==KeyCode.BUTTON_L3 then
			elseif k==KeyCode.BUTTON_R3 then
			elseif k==KeyCode.BUTTON_L1 then self.keys["L_BTN"] = true
			elseif k==KeyCode.BUTTON_R1 then self.keys["R_BTN"] = true
			end
		end)
		
		controller:addEventListener(Event.KEY_UP, function(e)
			local k=e.keyCode
			if k==KeyCode.BUTTON_BACK then 
			elseif k==KeyCode.BUTTON_MENU then
			elseif k==KeyCode.BUTTON_Y then 
			elseif k==KeyCode.BUTTON_A then 
			elseif k==KeyCode.BUTTON_X then 
			elseif k==KeyCode.BUTTON_B then
			elseif k==KeyCode.DPAD_UP then self.joystickVec.y = 0
			elseif k==KeyCode.DPAD_DOWN then self.joystickVec.y = 0
			elseif k==KeyCode.DPAD_LEFT then self.joystickVec.x = 0
			elseif k==KeyCode.DPAD_RIGHT then self.joystickVec.x = 0
			elseif k==KeyCode.BUTTON_L3 then
			elseif k==KeyCode.BUTTON_R3 then
			elseif k==KeyCode.BUTTON_L1 then self.keys["L_BTN"] = false
			elseif k==KeyCode.BUTTON_R1 then self.keys["R_BTN"] = false
			end
		end)
		
		controller:addEventListener(Event.LEFT_TRIGGER, function(e)
			--print("LEFT_TRIGGER:", "strength:"..e.strength)
			self.keys["L_TRIGGER"] = not (e.strength == 0)
		end)
		
		controller:addEventListener(Event.RIGHT_TRIGGER, function(e)
			--print("RIGHT_TRIGGER:", "strength:"..e.strength)
			self.keys["R_TRIGGER"] = not (e.strength == 0)
		end)
	end
end

function TopDown:enterFrame(e)
	local dt = e.deltaTime
	
	self.player.vel.x = self.player.speed * self.joystickVec.x
	self.player.vel.y = self.player.speed * self.joystickVec.y
	
	if self.keys[KeyCode.A] then 
		self.player.vel.x = -self.player.speed
	end
	if self.keys[KeyCode.D] then 
		self.player.vel.x = self.player.speed
	end
	if self.keys[KeyCode.W] then 
		self.player.vel.y = -self.player.speed
	end
	if self.keys[KeyCode.S] then 
		self.player.vel.y = self.player.speed
	end
	if self.keys["L_TRIGGER"] or self.keys[KeyCode.O] then 
		self.cam:zoom(-0.001)
	elseif self.keys["R_TRIGGER"] or self.keys[KeyCode.P] then 
		self.cam:zoom(0.001)
	end
	if self.keys["L_BTN"] or self.keys[KeyCode.Q] then 
		self.cam:rotate(-0.1)
	elseif self.keys["R_BTN"] or self.keys[KeyCode.E] then 
		self.cam:rotate(0.1)
	end
	
	self.player:update(dt)
	self.cam:update(dt)
	
	local x,y = self.cam.x,self.cam.y
	
	x = (x // 256) * 256
	y = (y // 256) * 256
	
	self.bg:setPosition(x-self.cam.w / 2 - 256, y-self.cam.h / 2 - 256)
end

function TopDown:keyDown(e)
	self.keys[e.keyCode] = true
	
	if e.keyCode == KeyCode.F then 
		self.cam:switchDebug()
	elseif e.keyCode == KeyCode.R then 
		self.cam:setZoom(1)
		self.cam:setAngle(0)
	elseif e.keyCode == KeyCode.Z then 
		self.cam:setShape("circle")
	elseif e.keyCode == KeyCode.X then 
		self.cam:setShape("rectangle")
	elseif e.keyCode == KeyCode.G then 
		self.cam:shake(2)
	elseif e.keyCode == KeyCode.H then 
		self.uiLayer:setVisible(not self.uiLayer:isVisible())
	end
end

function TopDown:keyUp(e)
	self.keys[e.keyCode] = false
end