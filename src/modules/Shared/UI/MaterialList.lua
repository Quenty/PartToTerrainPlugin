--[=[
	@class MaterialList
]=]

local require = require(script.Parent.loader).load(script)

local Maid = require("Maid")
local ValueObject = require("ValueObject")
local MaterialButton = require("MaterialButton")
local TerrainMaterialList = require("TerrainMaterialList")
local BasicPane = require("BasicPane")

local MaterialList = setmetatable({}, BasicPane)
MaterialList.ClassName = "MaterialList"
MaterialList.__index = MaterialList

function MaterialList.new(serviceBag, gui)
	local self = setmetatable(BasicPane.new(gui), MaterialList)

	self._serviceBag = assert(serviceBag, "No serviceBag")

	self.SelectedMaterial = self._maid:Add(ValueObject.new())

	self._materialToButton = {}
	for _, materialData in pairs(TerrainMaterialList) do
		local button = MaterialButton.new(self._serviceBag, materialData)
		self:_addButton(button)
	end

	self._maid:GiveTask(self.SelectedMaterial.Changed:Connect(function(newValue, oldValue)
		if newValue then
			local newButton = self._materialToButton[newValue]
			if newButton then
				newButton.Selected.Value = true
			end
		end

		if oldValue then
			local oldButton = self._materialToButton[oldValue]
			if oldButton then
				oldButton.Selected.Value = false
			end
		end
	end))

	self.SelectedMaterial.Value = Enum.Material.Grass

	return self
end

function MaterialList:_addButton(materialButton)
	self._materialToButton[materialButton:GetMaterial()] = materialButton

	local maid = Maid.new()
	maid:GiveTask(materialButton)

	maid:GiveTask(materialButton.Activated:Connect(function()
		self.SelectedMaterial.Value = materialButton:GetMaterial()
	end))
	materialButton.Gui.Parent = self.Gui

	self._maid:GiveTask(maid)
end

return MaterialList