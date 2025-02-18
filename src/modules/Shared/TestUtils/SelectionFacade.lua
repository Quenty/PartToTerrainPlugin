--[=[
	Selection facade
	@class SelectionFacade
]=]

local require = require(script.Parent.loader).load(script)

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Signal = require("Signal")
local BaseObject = require("BaseObject")
local Raycaster = require("Raycaster")
local InputObjectRayUtils = require("InputObjectRayUtils")
local Draw = require("Draw")

local DEBUG_VISUALIZE = false

local SelectionFacade = setmetatable({}, BaseObject)
SelectionFacade.__index = SelectionFacade
SelectionFacade.ClassName = "SelectionFacade"

function SelectionFacade.new(plugin)
	local self = setmetatable(BaseObject.new(), SelectionFacade)

	self._plugin = assert(plugin, "No plugin")
	self._selectedItems = {}
	self.SelectionChanged = self._maid:Add(Signal.new())

	self._raycaster = Raycaster.new()
	self._raycaster.Filter = function(hitData)
		return false
	end

	-- Fake selection
	self._maid:GiveTask(UserInputService.InputBegan:connect(function(inputObject)
		if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
			local new = {}
			local target = self:_findTarget(inputObject)
			if target and target:IsA("BasePart") then
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
					for _, item in pairs(self:Get()) do
						table.insert(new, item)
					end
				end
				if not target.Locked then
					table.insert(new, target)
				end
			end

			self:Set(new)
		end
	end))

	return self
end

function SelectionFacade:_findTarget(inputObject)
	local mouseRay = InputObjectRayUtils.cameraRayFromInputObject(inputObject, 1000)

	if DEBUG_VISUALIZE then
		Draw.ray(mouseRay)
	end

	local hitData = self._raycaster:FindPartOnRay(mouseRay)
	if hitData then
		return hitData.Part
	end
end


function SelectionFacade:Get()
	return self._selectedItems
end

function SelectionFacade:Set(items)
	assert(type(items) == "table", "Bad items")

	self._selectedItems = items
	self.SelectionChanged:Fire()
end

return SelectionFacade