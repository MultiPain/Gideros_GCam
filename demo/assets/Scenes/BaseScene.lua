--!NOEXEC
assert(ImGui ~= nil, "ImGui plugin not found!")

local MAIN_WINDOW_FLAGS =
	ImGui.WindowFlags_NoDecoration | 
	ImGui.WindowFlags_NoBackground

BaseScene = Core.class(Sprite)

function BaseScene:init()
	self.keys = {}
	
	self.ui = ImGui.new()
	self.io = self.ui:getIO()
	self:addEventListener("applicationResize", self.onAppResize, self)

	self:addEventListener("keyDown", self.keyDown, self)
	self:addEventListener("keyUp", self.keyUp, self)
	
	self:addEventListener("enterFrame", self.onEnterFrame, self)
	
	self:onAppResize()
end
--
function BaseScene:goBack()
	Scenes:changeScene("Selection", 1, SceneManager.fade)
	if controller then 
		controller:removeAllListeners()
	end
end
--
function BaseScene:onAppResize()
	local minX, minY, maxX, maxY = application:getLogicalBounds()
	local scaleX = application:getLogicalScaleX()
	local scaleY = application:getLogicalScaleY()
	local W = (maxX - minX) * scaleX
	local H = (maxY - minY) * scaleY
	
	self.io:setDisplaySize(W, H)
	self.ui:setPosition(minX, minY)
	self.ui:setScale(1 / scaleX, 1 / scaleY)
end
--
function BaseScene:setNewKey(keyCode, state, repeatFlag )
	local t = self.keys[keyCode]
	if state == nil then state = false end
	if repeatFlag == nil then repeatFlag = false end
	if (t == nil) then
		t = 
		{
			state = state, 
			repeatFlag = repeatFlag
		}
		self.keys[keyCode] = t
		return t
	else
		t.state = state
		t.repeatFlag = repeatFlag
	end
end
--
function BaseScene:keyUp(e)
	self:setNewKey(e.keyCode, false, false)
end
--
function BaseScene:keyDown(e)
	self:setNewKey(e.keyCode, true, false)
	
end
-- continiousCall (bool): function called from "enterFrame"
function BaseScene:checkKey(keyCode, continiousCall)
	local v = self.keys[keyCode]
	if (v == nil) then 
		return false
	end
	
	if (continiousCall) then 
		if (not v.repeatFlag) then 
			v.repeatFlag = true
			return v.state
		else
			return false
		end
	end
	
	return v.state
end
--
function BaseScene:onJoystickLeft(e)
end
--
function BaseScene:onJoystickLeftTrigger(e)	
	local state = not (e.strength == 0)
	self:setNewKey("L_TRIGGER", state, false)
end
--
function BaseScene:onJoystickRightTrigger(e)
	local state = not (e.strength == 0)
	self:setNewKey("R_TRIGGER", state, false)
end
--
function BaseScene:initControllerInput()	
	pcall(function() require "controller" end)

	if controller then 
		controller:addEventListener(Event.LEFT_JOYSTICK, self.onJoystickLeft, self)
		controller:addEventListener(Event.KEY_DOWN, self.keyDown, self)
		controller:addEventListener(Event.KEY_UP, self.keyUp, self)
		controller:addEventListener(Event.LEFT_TRIGGER, self.onJoystickLeftTrigger, self)
		controller:addEventListener(Event.RIGHT_TRIGGER, self.onJoystickRightTrigger, self)
	end
end
--
function BaseScene:onDrawUI(dt)
	
end
--
function BaseScene:onEnterFrame(e)
	local dt = e.deltaTime
	local ui = self.ui
	local IO = self.io
	local dw, dh = IO:getDisplaySize()
	
	ui:newFrame(dt)
	
	ui:setNextWindowPos(0, 0)
	ui:setNextWindowSize(450, dh)
	ui:beginWindow("##CameraSettings", nil, MAIN_WINDOW_FLAGS)
	
	self:onDrawUI(dt)
	
	ui:endWindow()	
	ui:render()
	ui:endFrame()
end