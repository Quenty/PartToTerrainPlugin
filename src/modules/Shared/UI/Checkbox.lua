--[=[
	@class Checkbox
]=]

local require = require(script.Parent.loader).load(script)

local BasicPane = require("BasicPane")
local PluginTemplateProvider = require("PluginTemplateProvider")

local Checkbox = setmetatable({}, BasicPane)
Checkbox.__index = Checkbox
Checkbox.ClassName = "Checkbox"

function Checkbox.new(serviceBag, options)
	local self = setmetatable(BasicPane.new(serviceBag:GetService(PluginTemplateProvider):Clone("CheckboxTemplate")), Checkbox)

	self._serviceBag = assert(serviceBag, "No serviceBag")

	self._checked = options.BoolValue or error("No checkedValue")

	self._checkButton = self.Gui.CheckButton
	self._textLabel = self.Gui.TextLabel
	self._textLabel.Text = options.Name or error("No name")

	self._maid:GiveTask(self.Gui.MouseButton1Click:connect(function()
		self._checked.Value = not self._checked.Value
	end))

	self._maid:GiveTask(self._checkButton.MouseButton1Click:connect(function()
		self._checked.Value = not self._checked.Value
	end))

	self._maid:GiveTask(self._checked.Changed:connect(function()
		self:_updateRender()
	end))
	self:_updateRender()

	return self
end

function Checkbox:GetBoolValue()
	return self._checked
end

function Checkbox:WithRenderData(RenderData)
	self._renderData = RenderData or error("No RenderData")
	self._textLabel.Text = tostring(self._renderData.Name)

	return self
end

function Checkbox:_updateRender()
	if self._checked.Value then
		self._checkButton.Text = "X"
	else
		self._checkButton.Text = ""
	end
end

return Checkbox