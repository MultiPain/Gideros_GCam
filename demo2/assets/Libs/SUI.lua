local function clamp(v, min, max)
	return (v <> min) >< max
end
local function map(v, minSrc, maxSrc, minDst, maxDst, clampValue)
	local newV = (v - minSrc) / (maxSrc - minSrc) * (maxDst - minDst) + minDst
	return not clampValue and newV or clamp(newV, minDst >< maxDst, minDst <> maxDst)
end
local abs = math.abs
------------------------------------------------------------------------
---------------------------- MAIN UI MODULE ----------------------------
------------------------------------------------------------------------
SUI = Core.class(Sprite)
SUI.NULL = function() end
SUI.clamp = clamp
SUI.map = map
SUI.defaultCheckBoxState = 0 -- initial checkbox state (0 or 1)
SUI.throwCheckBoxCallback = false -- if true then all checkboxes in SAME group will call its callbacks

-------------------------------------------------------
---------------------- GESTURE ------------------------
-------------------------------------------------------
local Gesture = Core.class()

function Gesture:init(owner, eventName)
	assert(owner and type(owner) == "table" and owner.getClass, "[Gesture]: owner must be an object")
	self.owner = owner
	self.touches = {}
	self.events = {}
	self.enabled = true
	self.doNotOverlapTouches = false
	
	if (eventName and eventName ~= "") then 
		self:register(eventName)
	end
end
-- state: "begin", "move", "end"
function Gesture:touch(x,y,state,id, ...)
	if not self.enabled then return end
	local owner = self.owner
	
	--if (owner.childInput and owner:childInput(x,y,state,id)) then return true end
	
	if (state == "begin") then 
		self.touches[id] = {x = x, y = y}
	end
	
	local eventSucceed = false
	for eventName, func in pairs(self.events) do 
		eventSucceed = eventSucceed or func(self, x,y,state,id, ...)
	end
	
	if (state == "end") then 
		self.touches[id] = nil
	end
	
	if self.doNotOverlapTouches then eventSucceed = false end
	if eventSucceed then SUI.focus = owner else SUI.focus = nil end
	
	return eventSucceed
end
--
function Gesture:register(eventName) 
	local update = self["on"..eventName]
	self.events[eventName] = update
end
--
function Gesture:unregister(eventName) 
	self.events[eventName] = nil
end
--
function Gesture:clear()
	self.owner = nil
	self.touches = nil
	self.events = nil
end
--
function Gesture:onClick(x, y, state, id, ...)
	local flag = false
	local t = self.touches[id]
	if t then
		local owner = self.owner
		local hit = owner:hitTestPoint(x, y)
		
		if state == "begin" then
			t.tocuhed = hit
			owner:highlight(hit)
			flag = hit
		elseif state == "move" and t.tocuhed then
			owner:highlight(hit)
			flag = hit
		elseif state == "end" and t.tocuhed and owner.isHightlighted then
			owner:highlight(false)
			owner:callback(...)
			t.tocuhed = nil
			flag = true
		end
	end
	return flag
end
--
function Gesture:onDrag(x, y, state, id, ...)
	local t = self.touches[id]
	local flag = false
	if t then
		local owner = self.owner
		local dx = x - t.x
		local dy = y - t.y
		t.x = x
		t.y = y
		
		if state == "begin" then
			if owner:hitTestPoint(x, y) then 
				t.tocuhed = true
				owner:highlight(true)
				owner:callback(dx, dy, "dragStart", ...)
			end
		elseif state == "move" and t.tocuhed then
			owner:callback(dx, dy, "dragMove", ...)
		elseif state == "end" and t.tocuhed then
			owner:highlight(false)
			owner:callback(dx, dy, "drop", ...)
			t.tocuhed = nil
        end
		flag = t.tocuhed
    end
	return flag

end
--
-------------------------------------------------------
------------------------ LABEL ------------------------
-------------------------------------------------------

local Label = Core.class(TextField, function(w, h, text, flags, font) return font, text end)
-- w,h (number): label size
-- flags (number): see TextFields layout parameter (https://wiki.giderosmobile.com/index.php/TextField:setLayout)
function Label:init(w, h, text, flags)
	assert(w and type(w) == "number", "[Label]: label width must be a number value")
	flags = flags or FontBase.TLF_REF_TOP|FontBase.TLF_VCENTER|FontBase.TLF_CENTER
	self:setLayout{
		flags = flags,
		w = w, h = h or 0
	}
	
	self.w = w
	self.h = h or 0
end

-------------------------------------------------------
------------------------ BASE -------------------------
-------------------------------------------------------

local Base = Core.class(Pixel, function(c,a,w,h) return 0,0,0,0 end)
-- images(table OR sprite object): image(s) to show
-- callback (function): function to call when gesture fires an event
-- args (table): extra parameters for some classes (must be key/value pair)
--	availiable keys:
--		labelOffsetX, labelOffsetY: offset label position when using "addText" method
--		labelWidth, labelHeight: set label size when using "addText" method
--		width, height: pixel size of the slider/progress bar. 
--			For the slider - used to set maximum X/Y value of the knob.
--			For the progress bar - used to set maximum bar width/height
function Base:init(images, callback, args)
	self.__isUI = true
	self.enabled = true
	self.callback = callback or SUI.NULL
	self.onHightlight = SUI.NULL
	self.highlighted = false
	
	if (images) then
		-- if we have one (or more) image(s) with parameters
		if (type(images) == "table" and images.getClass == nil) then 
			for i,imgData in ipairs(images) do 
				if (imgData.img) then 
					for k,v in pairs(imgData.set or {}) do 
						imgData.img:set(k,v)
					end
					if imgData.ninePatch then 
						imgData.img:setNinePatch(unpack(imgData.ninePatch))
					end
					self:addChild(imgData.img)
				else
					self:addChild(imgData)
				end
			end
		-- if only one image without parameters
		else
			self:addChild(images)
		end
	end
	
	if (args) then 
		for k,v in pairs(args) do 
			self[k] = v
		end
	end
	
	self.gesture = Gesture.new(self)
end
--
function Base:setCallback(callback)
	self.callback = callback 
	return self
end
--
function Base:enable()
	self:setAlpha(1)
	self.enabled = true
	return self
end
--
function Base:disable()
	self:setAlpha(0.5)
	self.enabled = false
	return self
end
-- adds normal text
function Base:addText(text, font, flags)
	local w=self.labelWidth or self:getWidth()
	local h=self.labelHeight or self:getHeight()
	self.label = Label.new(w, h, text, flags, font)
	self.label:setPosition(self.labelOffsetX or 0, self.labelOffsetY or 0)
	self:addChild(self.label)
	return self
end
-- adds text that will be updated with assigned component
function Base:addValueText(prefix, font, flags)
	local w=self.labelWidth or self:getWidth()
	local h=self.labelHeight or self:getHeight()
	self.prefix = prefix
	self.value_label = Label.new(w, h, prefix, flags, font)
	self.value_label:setPosition(self.labelOffsetX or 0, self.labelOffsetY or 0)
	self:addChild(self.value_label)
	return self
end
--
function Base:setTextColor(color)
	if self.label then 
		self.label:setTextColor(color)
		return self
	end
end
--
function Base:updateText(text)
	if (self.label) then 
		self.label:setText(tostring(text))
		return self
	end
end
--
function Base:updateValueText(value)
	if (self.value_label) then 
		self.value_label:setText(self.prefix..": "..tostring(value))
		return self
	end
end
--
function Base:getLabel()
	return self.label
end
--
function Base:getValueLabel()
	return self.value_label
end
--
function Base:removeText()
	if (self.label) then 
		self:removeChild(self.label)
		self.label = nil
		return self
	end
end
--
function Base:removeValueText()
	if (self.value_label) then 
		self:removeChild(self.value_label)
		self.value_label = nil
		self.prefix = nil
		return self
	end
end
--
function Base:highlight(flag)
	self.isHightlighted = flag
	self:onHightlight(flag)
	return self
end
--
function Base:setHightlight(func)
	self.onHightlight = func 
	return self
end
-- Adds drag&drop behaviour
function Base:addDragDrop()
	self.__oldCallback = self.callback
	self.gesture:unregister("Click")
	self.gesture:register("Drag")
	self.callback = function(o,dx,dy,state)
		local x,y = self:getPosition()
		x += dx
		y += dy 
		self:setPosition(x,y)
		self:__oldCallback(state)
	end
end
-------------------------------------------------------
--
-------------------------------------------------------
function Base:input(e)
	return self[e.type](self,e) 
end
-------------------------------------------------------
------------------------ MOUSE ------------------------
-------------------------------------------------------
-- ... - extra parameters that will be send to user's callback function at the end
-- as an example, "Grid" sends tile coordinates
function Base:mouseDown(e, ...)
	local x, y = e.x, e.y
	if (self.gesture:touch(x,y,"begin",1, ...)) then 
		return true
	end
end
--
function Base:mouseHover(e, ...)
	local x, y = e.x, e.y
	if (self.gesture:touch(x,y,"hover",1, ...)) then 
		return true
	end
end
--
function Base:mouseMove(e, ...)
	local x, y = e.x, e.y
	if (self.gesture:touch(x,y,"move",1, ...)) then 
		return true
	end
end
--
function Base:mouseUp(e, ...)
	local x, y = e.x, e.y
	if (self.gesture:touch(x,y,"end",1, ...)) then 
		return true
	end
end
--
-------------------------------------------------------
------------------------ TOUCH ------------------------
-------------------------------------------------------
function Base:touchesBegin(e, ...)
	local x,y,id = e.touch.x,e.touch.y,e.touch.id
	if (self.gesture:touch(x,y,"begin",id, ...)) then 
		return true
	end
end
--
function Base:touchesMove(e, ...)
	local x,y,id = e.touch.x,e.touch.y,e.touch.id
	if (self.gesture:touch(x,y,"move",id, ...)) then 
		return true
	end
end
--
function Base:touchesEnd(e, ...)
	local x,y,id = e.touch.x,e.touch.y,e.touch.id
	if (self.gesture:touch(x,y,"end",id, ...)) then 
		return true
	end
end
--
-------------------------------------------------------
----------------------- BUTTTON -----------------------
-------------------------------------------------------

local Button = Core.class(Base)

function Button:init()
	local n = self:getNumChildren()
	
	if (n == 2) then 
		self.__userCallback = self.callback
		
		self.pressed = self:getChildAt(1)
		self.normal = self:getChildAt(2)
		self.pressed:setVisible(false)
	end
	self.gesture:register("Click")
end
--
function Button:highlight(flag)
	Base.highlight(self, flag)
	if (self.pressed) then
		self.pressed:setVisible(flag)
		self.normal:setVisible(not flag)
	end
end
--
-------------------------------------------------------
---------------------- CHECK BOX ----------------------
-------------------------------------------------------

local CheckBox = Core.class(Base, function(groupName, state,...) return ... end)
--  groupName (string): 
function CheckBox:init(groupName, state)
	-- get images
	local n = self:getNumChildren()
	assert(n == 2 or n == 3, "[CheckBox]: incorrect amount of images. Must be 2 or 3, but was "..n)
	if (n == 3) then 
		self.bg = self:getChildAt(1)
		self.turnOff= self:getChildAt(2)
		self.turnOn = self:getChildAt(3)
	elseif (n == 2) then
		self.turnOff= self:getChildAt(1)
		self.turnOn = self:getChildAt(2)
	end
	
	self.groupName = ""
	if (groupName ~= "") then 
		self:setGroup(groupName)
	end
	
	self:setState(state or SUI.defaultCheckBoxState, false)
	
	-- save user callback 
	self.__userCallback = self.callback
	-- replace users callback
	self.callback = function()
		self:setState(abs(self.state - 1), true, true)
	end
	
	self.gesture:register("Click")
end
-- state - 0 or 1 (0 - off, 1 - on)
-- throwCallback - call callback function or not
function CheckBox:setState(state, throwCallback, switchOthers)
	-- turn off every other element in the same group
	if (self.groupName ~= "" and switchOthers) then 
		for cb,_ in pairs(SUI.__checkBoxGroup[self.groupName]) do 
			if cb ~= self then 
				cb:setState(0, SUI.throwCheckBoxCallback)
			end
		end
	end
	-- set state
	self.state = clamp(state, 0, 1)
	-- set images visibility
	local flag = self.state == 1
	self.turnOn:setVisible(flag)
	self.turnOff:setVisible(not flag)
	-- trigger callback or not
	if (throwCallback) then 
		self:__userCallback(self.state)
		self:updateValueText(self.state)
	end
end
-- change group
-- name (string): 
function CheckBox:setGroup(name)
	-- remove from current group (if needed)
	if (self.groupName ~= "") then 
		self:removeFromGroup()
	end
	-- set new group
	self.groupName = name
	local t = SUI.__checkBoxGroup[self.groupName]
	if (not t) then 
		t = {}
		SUI.__checkBoxGroup[self.groupName] = t
	end	
	-- key is the object itself (to make it easy to remove later)
	t[self] = true
end
-- delete fomr current group
function CheckBox:removeFromGroup()
	assert(self.groupName ~= "", "[CheckBox]: unable to remove from empty group")
	SUI.__checkBoxGroup[self.groupName][self] = nil
end


-- 
function CheckBox:addValueText(...)
	local l = Base.addValueText(self,...)
	self:updateValueText(self.state)
	return l
end
-------------------------------------------------------
------------------------ SLIDER -----------------------
-------------------------------------------------------
local Slider = Core.class(Base, function(min, max, value, int, ...) return ... end)
-- min, max (number): slider range
-- value (number): initial slider value
-- int (boolean): use only integer values
function Slider:init(min, max, value, int)

	self.min = min or 0
	self.max = max or 100
	self.value = clamp(value, self.min, self.max)

	-- get images
	self.bg = self:getChildAt(1)
	self.knob = self:getChildAt(2)

	-- calculate minimum and maximum X coord
	local pxW = self.width or self.bg:getWidth()
	local pxH = self.height or self.bg:getHeight()

	local lax,lay = self.bg:getAnchorPoint()

	local lW = pxW * lax
	local lH = pxH * lay

	self.minX = -lW
	self.maxX = -lW + pxW

	self.minY = -lH
	self.maxY = -lH + pxH

	-- colculate knob offset to make it move inside
	local ax,ay = self.knob:getAnchorPoint()
	local kW = self.knob:getWidth()
	local kH = self.knob:getHeight()
	self.kWR = kW * (1-ax)
	self.kWL = kW * ax

	self.kHB = kH * (1-ay)
	self.kHT = kH * ay

	-- floor value or not
	self.int = int

	-- prev value
	self.prevValue = -1

	self.state = ""

	-- save user callback
	self.__userCallback = self.callback
	
	-- register drag gesture
	self.gesture:register("Drag")
end
--
function Slider:setValue(value, throwCallback)
	-- call callback only when value is changing (useful for int values)
	if (throwCallback and self.prevValue ~= self.value) then
		self.__userCallback(self, self.value, self.state)
		self:updateValueText(
			((self.value*1000)//1)/1000
		)
	end
end

--
function Slider:addValueText(...)
	local l = Base.addValueText(self,...)
	self:updateValueText(self.value)
	return l
end
-------------------------------------------------------
local HSlider = Core.class(Slider)

function HSlider:init()
	-- initial position
	local initX = map(self.value, self.min, self.max, self.minX + self.kWL, self.maxX - self.kWR)
	self.knob:setX(initX)
	self.posX = initX

	-- replace users callback
	self.callback = function(_,dx,dy,state)
		self.state = state
		local val = self.value
		if (state == "dragStart" or state == "drop") then
			self.posX = self.knob:getX()
			self.prevValue = nil
		elseif (state == "dragMove") then
			-- translate coordinates range to value range
			local actualX = clamp(self.posX+dx, self.minX + self.kWL, self.maxX - self.kWR)
			self.posX = actualX
			self.prevValue = self.value
			-- find value
			val = map(actualX, self.minX + self.kWL, self.maxX - self.kWR, self.min, self.max)
		end
		-- set value
		self:setValue(val, true)
	end
end

--
function HSlider:setValue(value, throwCallback)
	local actualX = self.posX
	self.value = clamp(value, self.min, self.max)
	if (self.int) then
		self.value = self.value // 1
	end
	actualX = map(self.value, self.min, self.max, self.minX + self.kWL, self.maxX - self.kWR)
	self.knob:setX(actualX)
	Slider.setValue(self, value, throwCallback)
end
-------------------------------------------------------
local VSlider = Core.class(Slider)

function VSlider:init()
	-- initial position
	local initY = map(self.value, self.min, self.max, self.minY + self.kHT, self.maxY - self.kHB)
	self.knob:setY(initY)
	self.posY = initY

	-- replace users callback
	self.callback = function(_,dx,dy,state)
		self.state = state
		local val = self.value
		if (state == "dragStart" or state == "drop") then
			self.posY = self.knob:getY()
			self.prevValue = nil
		elseif (state == "dragMove") then
			-- translate coordinates range to value range
			local actualY = clamp(self.posY+dy, self.minY + self.kHT, self.maxY - self.kHB)
			self.posY = actualY
			self.prevValue = self.value
			-- find value
			val = map(actualY, self.minY + self.kHT, self.maxY - self.kHB, self.min, self.max)
		end
		-- set value
		self:setValue(val, true)
	end
end
--
function VSlider:setValue(value, throwCallback)
	local actualY = self.posY
	self.value = clamp(value, self.min, self.max)
	if (self.int) then
		self.value = self.value // 1
	end
	actualY = map(self.value, self.min, self.max, self.minY + self.kHT, self.maxY - self.kHB)
	self.knob:setY(actualY)
	Slider.setValue(self, value, throwCallback)
end

-------------------------------------------------------
--------------------- PROGESS BAR ---------------------
-------------------------------------------------------

local Progress = Core.class(Base, function(max, inverted, ...) return ... end)
-- 1st image - bg
-- 2d  image - progess line
function Progress:init(max, inverted)
	local n = self:getNumChildren()
	assert(n == 2, "[Progress]: incorrect amount of images. Must be 2, but was "..n)
	
	self.inverted = inverted
	
	self.bg = self:getChildAt(1)
	self.bar = self:getChildAt(2)
	
	self.progress = 0
	self.maxProgress = max or 100
	local bw = self.width or self.bar:getWidth()
	local bh = self.height or self.bar:getHeight()
	
	self.maxWidth = bw or self.width
	self.maxHeight = bh or self.height
	
	self.barHeight = bh
	self.barWidth = bw
	
	self.prevProg = nil
	
	self.setSZFlag = not (self.bar.setWidth == nil or self.bar.setHeight == nil) -- if bar object can change its width
	self.setDFlag = not (self.bar.setDimensions == nil) -- if bar object is Pixel
	self.setSFlag = (not self.setWFlag and not self.setDFlag) -- user scale if there is not setWidth OR setDimensions method
	
	self:setProgress(0)
end
--
function Progress:setProgress(value)
	self.prevProg = self.progress
	self.progress = clamp(value//1, 0, self.maxProgress)
	
	if (self.prevProg ~= self.progress) then 
		self:callback(self.progress)
		self:updateImage()
		self:updateValueText(self.progress)
	end
end
--
function Progress:updateImage()
end
--
function Progress:getProgress()
	return self.progress
end
--
function Progress:addValueText(...)
	local l = Base.addValueText(self,...)
	self:updateValueText(self.progress)
	return l
end
-------------------------------------------------------
local HProgress = Core.class(Progress)

function HProgress:init()
	if (self.inverted) then 
		local ax,ay,az = self.bar:getAnchorPosition()
		self.bar:setAnchorPosition(ax + self.barWidth, ay + self.barHeight, az)
		self.bar:setRotation(180)
	end
end

function HProgress:updateImage()
	if (self.useClip) then 
		self.bar:setClip(0,0,map(self.progress, 0, self.maxProgress, 0, self.maxWidth),self.barHeight)
	elseif (self.setSFlag) then 
		self.bar:setScaleX(map(self.progress, 0, self.maxProgress, 0, 1))
	elseif (self.setSZFlag) then 
		self.bar:setWidth(map(self.progress, 0, self.maxProgress, 0, self.maxWidth))
	elseif (self.setDFlag) then 
		local _,h = self.bar:getDimensions()
		self.bar:setDimensions(map(self.progress, 0, self.maxProgress, 0, self.maxWidth), h)
	end
end
-------------------------------------------------------
local VProgress = Core.class(Progress)

function VProgress:init()
	if (self.inverted) then 
		local ax,ay,az = self.bar:getAnchorPosition()
		self.bar:setAnchorPosition(self.barWidth, self.barHeight, az)
		self.bar:setRotation(180)
	end
end
--
function VProgress:updateImage()
	if (self.useClip) then 
		self.bar:setClip(0,0,self.barWidth,map(self.progress, 0, self.maxProgress, 0, self.maxHeight))
	elseif (self.setSFlag) then 
		self.bar:setScaleY(map(self.progress, 0, self.maxProgress, 0, 1))
	elseif (self.setSZFlag) then 
		self.bar:setHeight(map(self.progress, 0, self.maxProgress, 0, self.maxHeight))
	elseif (self.setDFlag) then 
		local w = self.bar:getDimensions()
		self.bar:setDimensions(w, map(self.progress, 0, self.maxProgress, 0, self.maxHeight))
	end
end
-------------------------------------------------------
------------------------ GROUP ------------------------
-------------------------------------------------------
local Group = Core.class(Base, function(orientation, margin, offset, ...) return ... end)

function Group:init(orientation, margin, offset)
	self.enabled = true
	self.orientation = orientation or "h"
	self.margin = margin or 0
	self.offset = offset or 0
	self.ids = {}
end
--
function Group:updatePosition(obj, n)
	n = n or self:getNumChildren()
	local last = self:getChildAt(n)
	local w,h = last:getSize()
	local x,y = last:getPosition()
	
	if (self.orientation == "h") then 
		y += h + self.offset
	elseif (self.orientation == "v") then 
		x += w + self.offset
	end
	obj:setPosition(x,y)
end
--
function Group:add(obj,id)
	local n = self:getNumChildren()
	if (n == 0) then 
		obj:setPosition(self.margin,self.margin)
	else
		self:updatePosition(obj, n)
	end
	if id then 
		self.ids[id] = obj
	end
	self:addChild(obj)
end
--
function Group:remove(obj)
	local s = self:getChildIndex(obj)
	obj:removeFromParent()
	
	for i = s , self:getNumChildren() do 	
		self:updatePosition(self:getChildAt(i), s-1)
	end
end
--
function Group:removeAt(ind)
	self:remove(self:getChildAt(ind))
end
--
function Group:input(event)
	local n = self:getNumChildren()
	for i = n, 1, -1 do 
		local spr = self:getChildAt(i)
		if spr.enabled and spr.input and spr:input(event) then 
			return true
		end
	end
end
--
function Group:hSeparator(color, size)
	local n = self:getNumChildren()
	local w = 10
	if n > 0 then 
		local last = self:getChildAt(n)
		w = last:getWidth()
	end
	local s = Pixel.new(color or 0xffffff, 1, w, size or 2)
	s.enabled = false
	self:add(s)
	return s
end
--
function Group:vSeparator(color, size)
	local n = self:getNumChildren()
	local h = 10
	if n > 0 then 
		local last = self:getChildAt(n)
		h = last:getHeight()
	end
	local s = Pixel.new(color or 0xffffff, 1, size or 2, h)
	s.enabled = false
	self:add(s)
	return s
end

--
function Group:getByID(id)
	return self.ids[id]
end
-------------------------------------------------------
-------------------- MAIN UI CLASS --------------------
-------------------------------------------------------
function SUI:init(controllType)
	SUI.__checkBoxGroup = {} -- all checkboxes
	self.touchedElement = nil
	
	if (controllType == "touch") then 
		self:addEventListener("touchesBegin", self.input, self)
		self:addEventListener("touchesMove", self.input, self)
		self:addEventListener("touchesEnd", self.input, self)
	elseif (controllType == "mouse") then
		self:addEventListener("mouseDown", self.input, self)
		self:addEventListener("mouseHover", self.input, self)
		self:addEventListener("mouseMove", self.input, self)
		self:addEventListener("mouseUp", self.input, self)
	end
end
-------------------------------------------------------
function SUI:button(...)
	local b = Button.new(...)
	self:addChild(b)
	return b
end
-------------------------------------------------------
function SUI:checkBox(...)
	local cb = CheckBox.new(...)
	self:addChild(cb)
	return cb
end
-------------------------------------------------------
function SUI:hSlider(...)
	local s = HSlider.new(...)
	self:addChild(s)
	return s
end
--
function SUI:vSlider(...)
	local s = VSlider.new(...)
	self:addChild(s)
	return s
end
-------------------------------------------------------
function SUI:hProgress(...)
	local p = HProgress.new(...)
	self:addChild(p)
	return p
end
--
function SUI:vProgress(...)
	local p = VProgress.new(...)
	self:addChild(p)
	return p
end
-------------------------------------------------------
function SUI:label(...)
	local l = Label.new(...)
	self:addChild(l)
	return l
end
-------------------------------------------------------
function SUI:layout(...)
	local l = Layout.new(...)
	self:addChild(l)
	return l
end
-------------------------------------------------------
function SUI:hGroup(...)
	local g = Group.new("h",...)
	self:addChild(g)
	return g
end
--
function SUI:vGroup(...)
	local g = Group.new("v",...)
	self:addChild(g)
	return g
end
-------------------------------------------------------
function SUI:updateCheckBoxGroup(groupName, state)
	for cb,_ in pairs(SUI.__checkBoxGroup[groupName]) do 
		cb:setState(state, true)
	end
end
--
function SUI:updateCheckBoxGroups(state)
	for name, t in pairs(SUI.__checkBoxGroup) do 
		for cb,_ in pairs(t) do 
			cb:setState(state, true)
		end
	end
end
-------------------------------------------------------
------------------------ INPUT ------------------------
--------------------- MOUSE/TOUCH ---------------------
-------------------------------------------------------
function SUI:input(event)
	local evType = event.type
	
	-- if there is focused elemnt then check only its input
	--[[
	local focus = SUI.focus
	if focus and focus.enabled then 
		return focus:input(event) 
	end
	]]
	
	-- if not find element that is touching
	local n = self:getNumChildren()
	for i = n, 1, -1 do 
		local spr = self:getChildAt(i)
		if spr.enabled and spr.input and spr:input(event) then 
			return true
		end
	end
end