
DOOR_IN @ "door_in"
DOOR_OUT @ "door_out"

Player = Core.class(Base, function(world) return {name="Player", world=world, w=30, h=45, ax=0.5} end)

function Player:init()
	self.jumpStr = 480
	self.minJumpStr = 300
	self.jumpScale = 0.58
	self.jumpCount = 3
	
	self.stickToWall = true
	self.applyGravityWhenSticked = true
	self.stickSlide = 50
	self.stickJumpPower = 1000
end