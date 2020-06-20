app:setBackgroundColor(0x323443)
--app:setFullScreen(true)

function LoadGame()
	timeStamp
	
	Inspect = require "libs/inspect"
	require "cbump"
	
	local scene = GameScene.new()
	stage:addChild(scene)
	
	printStamp
end

Core.asyncCall(LoadGame)