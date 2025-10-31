--[=[
	Part to terrain plugin
	@class PartToTerrainPlugin
]=]

local HttpService = game:GetService("HttpService")

local modules = script:WaitForChild("modules")
local loader = modules:FindFirstChild("LoaderUtils", true).Parent

local require = require(loader).bootstrapPlugin(modules)

local Maid = require("Maid")
local MaterialInput = require("MaterialInput")
local TerrainConverter = require("TerrainConverter")
local PluginUI = require("PluginUI")
local ServiceBag = require("ServiceBag")

-- luacheck: push ignore
local plugin = plugin
-- luacheck: pop ignore

local IS_DEBUG_MODE = script:IsDescendantOf(game) and not script:FindFirstAncestorWhichIsA("PluginDebugService")

local selectionService
if IS_DEBUG_MODE then
	warn("Starting plugin in debug mode")
	plugin = require("PluginFacade").new(plugin)
	selectionService = require("SelectionFacade").new(plugin)
else
	selectionService = game.Selection
end

local screenGui = script.Parent:WaitForChild("QuentyPartToTerrainScreenGui")
screenGui.Enabled = false

local mainMaid = Maid.new()

local isActive = false
local function deactivate(_button)
	if not isActive then
		return
	end

	isActive = false
	mainMaid._current = nil
end

local function activate(button)
	if isActive then
		return
	end
	isActive = true
	local maid = Maid.new()
	local serviceBag = maid:Add(ServiceBag.new())
	serviceBag:GetService(require("PluginTemplateProvider"))

	serviceBag:Init()
	serviceBag:Start()

	local converter = maid:Add(TerrainConverter.new(serviceBag))
	local newScreenGui = maid:Add(screenGui:Clone())

	newScreenGui.Enabled = true
	newScreenGui.Parent = IS_DEBUG_MODE and game.Players.LocalPlayer.PlayerGui or game.CoreGui

	local pluginUI = PluginUI.new(serviceBag, newScreenGui.Main, selectionService, converter)
	maid:GiveTask(pluginUI)
	maid:GiveTask(pluginUI.RequestClose:Connect(function()
		deactivate()
	end))

	maid:GiveTask(pluginUI.RequestConvert:Connect(function(selection, material)
		converter:Convert(selection, material)
	end))

	local materialInput = MaterialInput.new(plugin:GetMouse())
	pluginUI:SetMaterialInput(materialInput)

	-- Handle change history service
	if not IS_DEBUG_MODE then
		local ChangeHistoryService = game:GetService("ChangeHistoryService")
		maid:GiveTask(converter.ConversionStarting:Connect(function()
			ChangeHistoryService:SetWaypoint("Conversion_" .. HttpService:GenerateGUID(true))
		end))
	end

	-- Handle plugin button
	if button then
		button:SetActive(true)
		maid:GiveTask(function()
			button:SetActive(false)
		end)
	end

	mainMaid._current = maid
end

if IS_DEBUG_MODE then
	activate()
else
	local toolbar = plugin:CreateToolbar("Object")
	local button =
		toolbar:CreateButton("Part to Terrain", "Converts roblox parts to terrain", "rbxassetid://1618168422")

	button.Click:Connect(function()
		if not isActive then
			activate(button)
		else
			deactivate(button)
		end
	end)

	plugin.Unloading:Connect(function()
		deactivate(button)
	end)
end
