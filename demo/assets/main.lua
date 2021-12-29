application:setBackgroundColor(0)
--application:setFullScreen(true)

require "SceneManager"
require "ImGui"
require "Scenes/BaseScene"
require "Scenes/Selection"
require "Scenes/SideView"
require "Scenes/TopDown"

Scenes = SceneManager.new{
	["Selection"] = Selection,
	["TopDown"] = TopDown,
	["SideView"] = SideView,
}

Scenes:changeScene("Selection")
stage:addChild(Scenes)