# GCam
A simple 2D camera for Gideros.

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
camera:setPosition(x, y)
```

Shaking:
```lua
camera:shake()
```

Zooming:
```lua
camera:zoom(step)
-- for example
camera:zoom(0.1) -- zoom in by 0.1
camera:zoom(-0.1) -- zoom out by 0.1
camera:setScale(2) -- set zoom
```

Dead zone:
```lua
camera:setDeadZone(w, h) -- w and h in range [0..1] % of camera's size
```

Soft zone:
```lua
camera:setSoftZone(w, h) -- w and h in range [0..1] % of camera's size
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
```
