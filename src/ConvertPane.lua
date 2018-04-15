---
-- @classmod ConvertPane
-- @author Quenty

local BasicPane = require(script.Parent.BasicPane)
local Signal = require(script.Parent.Signal)

local ConvertPane = setmetatable({}, BasicPane)
ConvertPane.ClassName = "ConvertPane"
ConvertPane.__index = ConvertPane

function ConvertPane.new(gui, selectionService, terrainConverter)
	local self = setmetatable(BasicPane.new(gui), ConvertPane)

	self.RequestConvert = Signal.new() -- :Fire(selection)

	self._terrainConverter = terrainConverter or error("No terrainConverter")
	self._selectionService = selectionService or error("No selectionService")

	self._canConvert = Instance.new("BoolValue")
	self._canConvert.Value = false

	self._maid:GiveTask(self._canConvert.Changed:Connect(function()
		self:_updateButton()
	end))

	self._convertButton = self.Gui.ConvertButton
	self._statusLabel = self.Gui.StatusLabel

	self._maid:GiveTask(self._convertButton.MouseButton1Click:Connect(function()
		if self._canConvert.Value then
			local selection = self._selectionService:Get()
			if #selection > 0 then
				self.RequestConvert:Fire(selection)
			end
		end
	end))

	self._maid:GiveTask(self._selectionService.SelectionChanged:Connect(function()
		self:_updateStatus()
	end))
	self:_updateStatus()
	self:_updateButton()

	return self
end

function ConvertPane:_updateButton()
	if self._canConvert.Value then
		self._convertButton.AutoButtonColor = true
		self._convertButton.TextTransparency = 0
		self._convertButton.Active = true
		self._convertButton.Style = Enum.ButtonStyle.RobloxRoundDefaultButton
	else
		self._convertButton.AutoButtonColor = false
		self._convertButton.Active = false
		self._convertButton.TextTransparency = 0.7
		self._convertButton.Style = Enum.ButtonStyle.RobloxRoundButton
	end
end

function ConvertPane:_updateStatus()
	local selection = self._selectionService:Get()

	local canConvert
	if #selection == 0 then
		self._statusLabel.Text = "Nothing selected"
		canConvert = false
	elseif not self._terrainConverter:CanConvert(selection) then
		self._statusLabel.Text = ("Cannot convert %d item%s"):format(#selection, #selection == 1 and "" or "s")
		canConvert = false
	else
		self._statusLabel.Text = ("%d item%s selected"):format(#selection, #selection == 1 and "" or "s")
		canConvert = true
	end

	self._canConvert.Value = canConvert
end

return ConvertPane