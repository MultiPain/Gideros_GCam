local sqrt,atan2,cos,sin = math.sqrt,math.atan2,math.cos,math.sin

vec2 = Core.class()

function vec2:init(x,y)
	self.x = x or 0
	self.y = y or 0
end
function vec2:__tostring() return "["..self.x .. ", "..self.y.."]" end
function vec2:__unm(vec) return vec2.new(-self.x, -self.y) end
function vec2:__add(vec) return vec2.new(self.x + vec.x, self.y + vec.y) end
function vec2:__sub(vec) return vec2.new(self.x - vec.x, self.y - vec.y) end
function vec2.__div(v1,v2)
	local t1,t2 = type(v1), type(v2)
	if t1 == "number" and t2 == "table" then 
		assert(v2.x ~= 0 and v2.y ~= 0, "[vec2]: division by 0!")
		return vec2.new(v1 / v2.x, v1 / v2.y) 
	elseif t1 == "table" and t2 == "number" then 
		assert(v2 ~= 0, "[vec2]: division by 0!")
		return vec2.new(v1.x / v2, v1.y / v2) 
	else
		assert(v2.x ~= 0 and v2.y ~= 0, "[vec2]: division by 0!")
		return vec2.new(v1.x / v2.x, v1.y / v2.y) 
	end 
end
function vec2.__mul(v1,v2) 
	local t1,t2 = type(v1), type(v2)
	if t1 == "number" and t2 == "table" then 
		return vec2.new(v1 * v2.x, v1 * v2.y) 
	elseif t1 == "table" and t2 == "number" then 
		return vec2.new(v1.x * v2, v1.y * v2) 
	else
		return vec2.new(v1.x * v2.x, v1.y * v2.y) 
	end
end
function vec2:__eq(vec) return self.x == vec.x and self.y == vec.y end
function vec2:dot(vec) return self.x*vec.x+self.y*vec.y end
function vec2:angle(vec) return atan2(vec.y-self.y, vec.x-self.x) end
function vec2:dist(vec) return sqrt((self.x-vec.x)^2+(self.y-vec.y)^2) end
function vec2:distSq(vec) return (self.x-vec.x)^2+(self.y-vec.y)^2 end
function vec2:len() return sqrt(self.x*self.x+self.y*self.y) end
function vec2:lenSq() return self.x*self.x+self.y*self.y end
function vec2:copy() return vec2.new(self.x, self.y) end
function vec2:invert() return vec2.new(self.y,self.x) end
function vec2:midPoint(v) return (self + v) / 2 end
function vec2:norm()
	local l = self:len()
	if l > 0 then 
		self.x /= l
		self.y /= l
	end
	return self
end
function vec2:perpCW() return vec2.new(-self.y,self.x) end
function vec2:perpCCW() return vec2.new(self.y,-self.x) end
function vec2:rotate(ang)
	local a = ^>ang
	local cosa = cos(a)
	local sina = sin(a)
	return vec2.new(self.x*c-self.y*s, self.x*s+self.y*c)
end
function vec2:rotateAround(point, ang)
	local a = ^>ang
	local cosa = cos(a)
	local sina = sin(a)
	return vec2.new(
		(point.x + self.x) * c - (point.y + self.y) * s,
		(point.x + self.x) * s + (point.y + self.y) * c
	)
end

function vec2:limit(len)
	local l = self:len()
	if l > len then 
		self.x /= l
		self.y /= l
		self.x *= len
		self.y *= len
	end
end
function vec2:unpack() return self.x, self.y end
vec2.ZERO = vec2.new()
vec2.LEFT = vec2.new(-1,0)
vec2.RIGHT = vec2.new(1,0)
vec2.UP = vec2.new(0,-1)
vec2.DOWN = vec2.new(0,1)