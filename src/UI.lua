---
-- @classmod UI
-- @author Quenty

local BasicPane = require(script.Parent.BasicPane)
local MaterialList = require(script.Parent.MaterialList)
local Signal = require(script.Parent.Signal)
local ConvertPane = require(script.Parent.ConvertPane)
local Checkbox = require(script.Parent.Checkbox)

local UI = {}
UI.ClassName = "UI"
UI.__index = UI

function UI.new(gui, selectonService, terrainConverter)
	assert(gui)
	local self = setmetatable(BasicPane.new(gui), UI)

	self._terrainConverter = terrainConverter or error("No terrainConverter")
	self._selectionService = selectonService or error("No selectonService")

	self.RequestClose = Signal.new()
	self.RequestConvert = Signal.new() -- :Fire(selection, material)

	self._materialList = MaterialList.new(self.Gui.Content.MaterialList)
	self._maid:GiveTask(self._materialList)

	self._convertPane = ConvertPane.new(self.Gui.Content.ConvertPane, selectonService, terrainConverter)
	self._maid:GiveTask(self._convertPane.RequestConvert:Connect(function(selection)
		self.RequestConvert:Fire(selection, self._materialList.SelectedMaterial.Value)
	end))
	self._maid:GiveTask(self._convertPane)

	self.Gui.Header.CloseButton.MouseButton1Click:Connect(function()
		self.RequestClose:Fire()
	end)

	self._optionsFrame = self.Gui.Content.Options

	self._removePartCheckBox = Checkbox.new({
		Name = "Keep converted part";
		BoolValue = self._terrainConverter.KeepConvertedPart
	})
	self:_addOptionGui(self._removePartCheckBox)

	self._replaceExistingTerrain = Checkbox.new({
		Name = "Overwrite terrain";
		BoolValue = self._terrainConverter.OverwriteTerrain;
	})
	self:_addOptionGui(self._replaceExistingTerrain)

	self._ignoreWater = Checkbox.new({
		Name = "Overwrite water";
		BoolValue = self._terrainConverter.OverwriteWater;
	})
	self:_addOptionGui(self._ignoreWater)

	return self
end

function UI:_addOptionGui(option)
	option.Gui.LayoutOrder = #self._optionsFrame:GetChildren() + 1
	option.Gui.Parent = self._optionsFrame
	self._maid:GiveTask(option)
end

function UI:SetMaterialInput(materialInput)
	self._materialInput = materialInput or error("No materialInput")
	self._maid:GiveTask(materialInput)

	self._maid:GiveTask(materialInput.MaterialSelected:Connect(function(material)
		self._materialList.SelectedMaterial.Value = material
	end))

	self._maid:GiveTask(materialInput.ConvertRequest:Connect(function()
		local selection = self._selectionService:Get()
		if #selection > 0 then
			self.RequestConvert:Fire(selection, self._materialList.SelectedMaterial.Value)
		end
	end))
end

return UI