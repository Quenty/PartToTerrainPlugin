---
-- @classmod MaterialButton
-- @author Quenty

local TextService = game:GetService("TextService")

local BasicPane = require(script.Parent.BasicPane)
local Signal = require(script.Parent.Signal)

local MaterialButton = {}
MaterialButton.ClassName = "MaterialButton"
MaterialButton.__index = MaterialButton

function MaterialButton.new(data)
	local gui = script.Parent.Parent.GuiTemplates.MaterialButtonTemplate:Clone()
	gui.Name = "MaterialButton"
	local self = setmetatable(BasicPane.new(gui), MaterialButton)

	-- handle activation
	self.Activated = Signal.new()
	self._maid:GiveTask(self.Gui.MouseButton1Click:Connect(function()
		self.Activated:Fire()
	end))

	-- setup highlighting
	self.Selected = Instance.new("BoolValue")
	self.Selected.Value = false
	self._maid:GiveTask(self.Selected.Changed:Connect(function()
		self:_updateHighlight()
	end))
	self:_updateHighlight()

	-- init tooltip
	self._toolTip = self.Gui.ToolTip
	self._maid:GiveTask(self.Gui.MouseEnter:Connect(function()
		self._toolTip.Visible = true
	end))
	self._maid:GiveTask(self.Gui.MouseLeave:Connect(function()
		self._toolTip.Visible = false
	end))

	-- setup data
	self._data = data or error("No material data")
	self:SetImage(self._data.image)
	self:SetToolTip(self._data.text)

	return self
end

function MaterialButton:GetMaterial()
	return self._data.enum
end

function MaterialButton:SetToolTip(text)
	local textLabel = self._toolTip.TextLabel
	textLabel.Text = text

	local size = TextService:GetTextSize(text, textLabel.TextSize, textLabel.Font, Vector2.new(1e6, 1e6))
	self._toolTip.Size = UDim2.new(UDim.new(0, 30 + size.x), self._toolTip.Size.Y)
end

function MaterialButton:SetImage(image)
	self.Gui.Image = image
end

function MaterialButton:_updateHighlight()
	if self.Selected.Value then
		self.Gui.BackgroundTransparency = 0
	else
		self.Gui.BackgroundTransparency = 1
	end
end

function MaterialButton:Destroy()
	self._maid:DoCleaning()
end

return MaterialButton