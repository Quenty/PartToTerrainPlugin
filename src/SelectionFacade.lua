--- The things I do for testing...
-- @author Quenty

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Signal = require(script.Parent.Signal)

local SelectionFacade = {}
SelectionFacade.__index = SelectionFacade
SelectionFacade.ClassName = "SelectionFacade"

function SelectionFacade.new()
	local self = setmetatable({}, SelectionFacade)

	self._items = {}
	self.SelectionChanged = Signal.new()

	local mouse = Players.LocalPlayer:GetMouse()
	mouse.Button1Down:connect(function()
		local new = {}
		if mouse.Target and mouse.Target:IsA("BasePart") then
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				for _, item in pairs(self:Get()) do
					table.insert(new, item)
				end
			end
			if not mouse.Target.Locked then
				table.insert(new, mouse.Target)
			end
		end
		self:Set(new)
	end)

	return self
end

function SelectionFacade:Get()
	return self._items
end

function SelectionFacade:Set(items)
	assert(type(items) == "table")
	self._items = items
	self.SelectionChanged:Fire()
end

return SelectionFacade