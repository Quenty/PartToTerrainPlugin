---
-- @classmod BasicPane
-- @author Quenty

local Maid = require(script.Parent.Maid)

local BasicPane = {}
BasicPane.ClassName = "BasicPane"
BasicPane.__index = BasicPane

function BasicPane.new(gui)
	local self = setmetatable({}, BasicPane)

	self._maid = Maid.new()

	if gui then
		self.Gui = gui
		self._maid:GiveTask(self.Gui)
	end

	return self
end

function BasicPane:Destroy()
	self._maid:DoCleaning()
	setmetatable(self, nil)
end

return BasicPane