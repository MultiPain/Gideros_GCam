local minX,minY,maxX,maxY=app:getDeviceSafeArea(true)
local CX,CY=app:getContentWidth()/2, app:getContentHeight()/2
local SW = maxX - minX
local SH = maxY - minY
local Utils = require "utils"

GameScene = Core.class(Sprite)

function GameScene:init()
	self.world = BumpWorld.new()
	self.layers = Layers.new()
	
	self.cam = GCam.new(self.layers)
	self.cam:setBounds(450, 200, 1200, 600)
	self.cam:setDeadZone(.1,.1)
	self.cam:setSoftZone(.2,.2)
	self.cam:setSmooth(2,1)
	self:addChild(self.cam)	
	
	self:createLevel()
	
	self:addEventListener(Event.ENTER_FRAME, self.update, self)
	self.keys = {}
	self:addEventListener(Event.KEY_UP, self.keyUP, self)
	self:addEventListener(Event.KEY_DOWN, self.keyDown, self)
	self:addEventListener(Event.MOUSE_WHEEL, self.mouseWheel, self)
end	

function GameScene:createLevel()
	self.level = Level.new(self.world)
	local data = self.level:load("test_2")
	self.layers:load(data.layers)
	
	self.player = Player.new(self.world)
	self.player:setPosition(data.playerData.x, data.playerData.y)
	self.layers:add("walls", self.player)
	
	self.cam:setFollow(self.player)
	
	self.uiLayer = self.layers:addLayer("ui")
	
	self.FPS_counter = TextField.new(nil, "FPS: 0", "|")
	self.FPS_counter:setScale(2)
	self.FPS_counter:setTextColor(0xffffff)
	self.uiLayer:addChild(self.FPS_counter)
	
	self.cam:addChild(self.uiLayer)
end

local timer = 0
function GameScene:update(e)
	local dt = e.deltaTime
	timer += dt
	if (timer > 1) then 
		timer = 0
		self.FPS_counter:setText(string.format("FPS: %.2f", 1/dt))
	end
	
	self.player:update(dt)
	self.cam:update(dt)
end

function GameScene:mouseWheel(e)
	if e.wheel < 0 then 
		self.cam:zoom(-0.05)
	else
		self.cam:zoom(0.05)
		print("?")
	end
end

function GameScene:keyUP(e)
	if (e.keyCode == KeyCode.RIGHT) then 
		self.player.movingRight = false
	end
	
	if (e.keyCode == KeyCode.LEFT) then
		self.player.movingLeft = false		
	end
	
	if (e.keyCode == KeyCode.UP) then 
		self.player:stopJump()
	end
end	

function GameScene:keyDown(e)
	if (e.keyCode == KeyCode.RIGHT) then 
		self.player.movingRight = true
	end
	
	if (e.keyCode == KeyCode.LEFT) then
		self.player.movingLeft = true
	end
	
	if (e.keyCode == KeyCode.UP) then 
		self.player:controlableJump()
	elseif (e.keyCode == KeyCode.Z) then 
		self.player:fixedJump()
	elseif (e.keyCode == KeyCode.P) then 
		local rt = RenderTarget.new(SW, SH)
		rt:draw(stage)
		rt:save("|D|screen.png")
	elseif (e.keyCode == KeyCode.DOWN) then 
		self.player:fallOff()
		self.player:unstick()
	elseif (e.keyCode == KeyCode.K) then 
		self.player:kill()
	elseif (e.keyCode == KeyCode.X) then 
		self.player:hit()
	elseif (e.keyCode == KeyCode.D) then
		self.cam:setDebug(not self.cam.__debug__)
	elseif (e.keyCode == KeyCode.Q) then
		self.cam:rotate(-10)
	elseif (e.keyCode == KeyCode.E) then
		self.cam:rotate(10)
	elseif (e.keyCode == KeyCode.S) then
		self.cam:shake()
	end
end	
