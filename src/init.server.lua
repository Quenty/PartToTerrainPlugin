--- Part to terrain plugin
-- @author Quenty

local HttpService = game:GetService("HttpService")

local Maid = require(script.Maid)
local MaterialInput = require(script.MaterialInput)
local plugin = plugin
local TerrainConverter = require(script.TerrainConverter)
local UI = require(script.UI)

local IS_DEBUG_MODE = script:IsDescendantOf(game)

local selectionService
if IS_DEBUG_MODE then
	warn("Starting plugin in debug mode")
	plugin = require(script.PluginFacade).new(plugin)
	selectionService = require(script.SelectionFacade).new()
else
	selectionService = game.Selection
end

local screenGui = script.Parent:WaitForChild("QuentyPartToTerrainScreenGui")
screenGui.Enabled = false

local mainMaid = Maid.new()

local isActive = false
local function deactivate(button)
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

	local converter = TerrainConverter.new()

	local newScreenGui = screenGui:Clone()
	maid:GiveTask(newScreenGui)
	newScreenGui.Enabled = true
	newScreenGui.Parent = IS_DEBUG_MODE and game.Players.LocalPlayer.PlayerGui or game.CoreGui

	local ui = UI.new(newScreenGui.Main, selectionService, converter)

	maid:GiveTask(ui)
	maid:GiveTask(ui.RequestClose:Connect(function()
		deactivate()
	end))

	maid:GiveTask(ui.RequestConvert:Connect(function(selection, material)
		converter:Convert(selection, material)
	end))

	local materialInput = MaterialInput.new(plugin:GetMouse())
	ui:SetMaterialInput(materialInput)

	-- Handle change history service
	if not IS_DEBUG_MODE then
		local ChangeHistoryService = game:GetService("ChangeHistoryService")
		converter.ConversionStarting:Connect(function()
			ChangeHistoryService:SetWaypoint("Conversion_" .. HttpService:GenerateGUID(true))
		end)
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
	local button = toolbar:CreateButton(
		"Part to Terrain",
		"Converts roblox parts to terrain",
		"rbxassetid://1618168422"
	)

	button.Click:connect(function()
		if not isActive then
			activate(button)
		else
			deactivate(button)
		end
	end)
end