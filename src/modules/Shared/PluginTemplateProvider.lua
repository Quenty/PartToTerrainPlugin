--[=[
	Retrieves PluginTemplateProvider
	@class PluginTemplateProvider
]=]

local require = require(script.Parent.loader).load(script)

local TemplateProvider = require("TemplateProvider")
local QuentyPartToTerrain = script:FindFirstAncestor("QuentyPartToTerrain")

return TemplateProvider.new(script.Name, QuentyPartToTerrain.GuiTemplates)