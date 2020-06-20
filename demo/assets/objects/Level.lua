--local function rotateAround(angle, x, y) local t,cosa,sina = self.x,cos(angle),sin(angle) self.x = cosa * ( t - point.x ) - sina * ( self.y - point.y ) + point.x self.y = sina * ( t - point.x ) + cosa * ( self.y - point.y ) + point.y return self end

Level = Core.class(Sprite)

function Level:init(world)
	self.world = world
	self.width = 0
	self.height = 0
	self.tilewidth = 0
	self.tileheight = 0
end
--
function Level:load(name)
	local map = require("maps/" .. name)
	self.width = map.width
	self.height = map.height
	self.tilewidth = map.tilewidth
	self.tileheight = map.tileheight
	
	local tilesetTexture = Texture.new(map.tilesets[1].image)
	local tilesetWidth   = tilesetTexture:getWidth() // self.tilewidth
	local tilesetFGid    = map.tilesets[1].firstgid
	
	local imageSet      = Texture.new(map.tilesets[2].image)
	local imageSetWidth = imageSet:getWidth() // self.tilewidth
	local imageFGid     = map.tilesets[2].firstgid
	
	local data = {
		layers = {},
		playerData = {}
	}
	
	for i = 1, #map.layers do
		local layer = map.layers[i]
		
		if (layer.type == "imagelayer") then
			local camLayer = Layer.new(layer.name)
			local bmp = Bitmap.new(Texture.new(layer.image, true))
			bmp:setAnchorPosition(-layer.offsetx, -layer.offsety)
			camLayer:setAlpha(layer.opacity)
			camLayer:addChild(bmp)
			
			--camLayer:setPosition(layer.offsetx, layer.offsety)
			data.layers[#data.layers+1] = camLayer
		elseif (layer.type == "tilelayer") then
			local camLayer = Layer.new(layer.name)
			local tilemap = TileMap.new(layer.width, layer.height, tilesetTexture, self.tilewidth, self.tileheight)
			
			for y=1,layer.height do
				for x=1,layer.width do
					local i = x + (y - 1) * layer.width
					local gid = layer.data[i]
					
					if (gid > 0) then
						local tx = (gid - tilesetFGid) %  tilesetWidth + 1
						local ty = (gid - tilesetFGid) // tilesetWidth + 1
						
						tilemap:setTile(x, y, tx, ty)
					end
				end
			end
			camLayer:setAlpha(layer.opacity)
			camLayer:addChild(tilemap)
			data.layers[#data.layers+1] = camLayer
		elseif (layer.type == "objectgroup" and self.world ~= nil) then
			if (layer.name == "objects") then
				local debugLayer = Layer.new("debug")
				for _,v in ipairs(layer.objects) do
					-- ONLY non rotated rectangles, becouse collision engine is for AABB's (:
					if (v.shape == "rectangle" and v.rotation == 0) then
						if (v.type == "movingOneWay") then 
							local w = MovingWall.new(self.world, v.width, v.height, v.properties) 
							w:setPosition(v.x, v.y)
						else
							--
							if (DEBUG) then 
								local px = Pixel.new(v.type == "wall" and 0xff0000 or 0x0000ff, 1, v.width, v.height)
								px:setPosition(v.x,v.y)
								debugLayer:addChild(px)
							end
							--
							local w = Wall.new(self.world, v.width, v.height)
							w:setAlpha(.25)
							w:setPosition(v.x, v.y)
							
							if (v.type == "wall") then 
								w.isWall = true
							elseif (v.type == "oneWay") then 
								w.isOneWay = true
							end
						end
					elseif (v.shape == "point" and v.rotation == 0) then
						data.playerData = v.properties
						data.playerData.x = v.x
						data.playerData.y = v.y
					end
				end
				debugLayer:setAlpha(0.3)
				data.layers[#data.layers+1] = debugLayer
			elseif (layer.name == "images") then
				local imageLayer = Layer.new(layer.name)
				for _,v in ipairs(layer.objects) do
					if (v.gid > 0) then 
						local tx = (v.gid - imageFGid) %  imageSetWidth + 0
						local ty = (v.gid - imageFGid) // imageSetWidth + 0
						
						local tex = TextureRegion.new(imageSet, tx*self.tilewidth,ty*self.tilewidth,self.tilewidth,self.tilewidth)
						local btm = Bitmap.new(tex)
						btm:setAnchorPoint(0,1)
						btm:setRotation(v.rotation)
						btm:setPosition(v.x, v.y)
						imageLayer:addChild(btm)
						
						local x,y,w,h = btm:getBounds(imageLayer)
						local px = Pixel.new(0x0000ff, 0.4,w,h)
						px:setPosition(x,y)
					end
				end
				imageLayer:setAlpha(layer.opacity)
				data.layers[#data.layers+1] = imageLayer
			end
		end
		
	end
	
	return data
end