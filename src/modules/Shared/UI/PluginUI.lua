--[=[
	@class PluginUI
]=]

local require = require(script.Parent.loader).load(script)

local BasicPane = require("BasicPane")
local MaterialList = require("MaterialList")
local Signal = require("Signal")
local ConvertPane = require("ConvertPane")
local Checkbox = require("Checkbox")

local PluginUI = setmetatable({}, BasicPane)
PluginUI.ClassName = "PluginUI"
PluginUI.__index = PluginUI

function PluginUI.new(serviceBag, gui, selectonService, terrainConverter)
	local self = setmetatable(BasicPane.new(gui), PluginUI)

	self._serviceBag = assert(serviceBag, "No serviceBag")

	self._terrainConverter = terrainConverter or error("No terrainConverter")
	self._selectionService = selectonService or error("No selectonService")

	self.RequestClose = self._maid:Add(Signal.new())
	self.RequestConvert = self._maid:Add(Signal.new()) -- :Fire(selection, material)

	self._materialList = MaterialList.new(self._serviceBag, self.Gui.Content.MaterialList)
	self._maid:GiveTask(self._materialList)

	self._convertPane = ConvertPane.new(self._serviceBag, self.Gui.Content.ConvertPane, selectonService, terrainConverter)
	self._maid:GiveTask(self._convertPane)
	self._maid:GiveTask(self._convertPane.RequestConvert:Connect(function(selection)
		self.RequestConvert:Fire(selection, self._materialList.SelectedMaterial.Value)
	end))

	self.Gui.Header.CloseButton.MouseButton1Click:Connect(function()
		self.RequestClose:Fire()
	end)

	self._optionsFrame = self.Gui.Content.Options

	self._removePartCheckBox = Checkbox.new(self._serviceBag, {
		Name = "Keep converted part";
		BoolValue = self._terrainConverter.KeepConvertedPart
	})
	self:_addOptionGui(self._removePartCheckBox)

	self._replaceExistingTerrain = Checkbox.new(self._serviceBag, {
		Name = "Overwrite terrain";
		BoolValue = self._terrainConverter.OverwriteTerrain;
	})
	self:_addOptionGui(self._replaceExistingTerrain)

	self._ignoreWater = Checkbox.new(self._serviceBag, {
		Name = "Overwrite water";
		BoolValue = self._terrainConverter.OverwriteWater;
	})
	self:_addOptionGui(self._ignoreWater)

	return self
end

function PluginUI:_addOptionGui(option)
	option.Gui.LayoutOrder = #self._optionsFrame:GetChildren() + 1
	option.Gui.Parent = self._optionsFrame
	self._maid:GiveTask(option)
end

function PluginUI:SetMaterialInput(materialInput)
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

return PluginUI