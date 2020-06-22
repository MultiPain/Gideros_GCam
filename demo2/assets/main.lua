application:setBackgroundColor(0)
application:setFullScreen(true)

require "SceneManager"

Scenes = SceneManager.new{
	["Selection"] = Selection,
	["TopDown"] = TopDown,
	["SideView"] = SideView,
}

Scenes:changeScene("Selection")
stage:addChild(Scenes)