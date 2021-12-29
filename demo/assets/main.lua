application:setBackgroundColor(0)
--application:setFullScreen(true)

require "SceneManager"
require "ImGui"

require "Scenes/BaseScene"
require "Scenes/TestScene"
-- [[
require "Scenes/Selection"
require "Scenes/SideView"
require "Scenes/TopDown"

Scenes = SceneManager.new{
	["Selection"] = Selection,
	["TopDown"] = TopDown,
	["SideView"] = SideView,
	["TestScene"] = TestScene,
}

--Scenes:changeScene("SideView")
Scenes:changeScene("Selection")
--Scenes:changeScene("TestScene")
stage:addChild(Scenes)
--]]