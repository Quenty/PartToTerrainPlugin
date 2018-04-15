---
-- @classmod MaterialList
-- @author Quenty

local Maid = require(script.Parent.Maid)
local ValueObject = require(script.Parent.ValueObject)
local MaterialButton = require(script.Parent.MaterialButton)
local terrainMaterialList = require(script.Parent.terrainMaterialList)
local BasicPane = require(script.Parent.BasicPane)

local MaterialList = setmetatable({}, BasicPane)
MaterialList.ClassName = "MaterialList"
MaterialList.__index = MaterialList

function MaterialList.new(gui)
	local self = setmetatable(BasicPane.new(gui), MaterialList)

	self.SelectedMaterial = ValueObject.new()
	self._maid:GiveTask(self.SelectedMaterial)

	self._materialToButton = {}
	for _, materialData in pairs(terrainMaterialList) do
		local button = MaterialButton.new(materialData)
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