# GCam
A simple 2D camera for Gideros.

# Features

* Dead zone
* Soft zone
* Shaking
* Bounds
* Smooth object follow
* Zooming
* Rotating

# API
Create camera:
```lua
camera = GCam.new(yourScene [, anchorX, anchorY]) -- anchor by default is (0.5, 0.5)
stage:addChild(camera)
```

Following:
```lua
camera:setFollow(myObject)
stage:addEventListener("enterFrame", function(e)
	local dt = e.deltaTime
	camera:update(dt)
end)
-- remove following:
camera:setFollow(nil)
```

Change position:
```lua
camera:goto(x, y)
```

Sets camera size to window size
```lua
camera:setAutoSize(flag)
```

Shaking:
```lua
-- duration (number): time is s.
-- distance (number): maximum shake offset
camera:shake(duraion [, distance])
```

Zooming:
```lua
camera:zoom(step)
-- for example
camera:zoom(0.1) -- zoom in by 0.1
camera:zoom(-0.1) -- zoom out by 0.1
camera:setZoom(2) -- set zoom directly
```

Shape:
```lua
-- shapeType(string): function name
--	can be "rectangle" or "circle"
--	you can create custom shape by 
--	adding a new method to a class
--	then use its name as shapeType
camera:setShape(shapeType)
```

Dead zone:
Camera does not move in this zone
```lua
camera:setDeadSize(w, h) -- dead zone size
camera:setDeadRadius(w, h) -- dead zone radius (only for "circle" shape)
```

Soft zone:
Camera intepolate its position towards target
```lua
camera:setSoftSize(w, h) -- soft zone size
camera:setSoftRadius(r) -- soft zone radius (only for "circle" shape)
```
Bounds:
```lua
camera:setBounds([left, top, right, bottom]) -- default value is 0 for each
-- or
camera:setLeftBound(left)
camera:seTopBound(top)
camera:setRightBound(right)
camera:setBottomBound(bottom)
```

Movement smoothing:
```lua
camera:setSmooth(x, y)
```
Debug graphics:
```lua
camera:setDebug(flag)
-- or
camera:switchDebug() -- turn on/off
```
