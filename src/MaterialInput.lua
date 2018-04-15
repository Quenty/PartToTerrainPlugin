---
-- @classmod MaterialInput
-- @author Quenty

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local BasicPane = require(script.Parent.BasicPane)
local Raycaster = require(script.Parent.Raycaster)
local Signal = require(script.Parent.Signal)

local MaterialInput = setmetatable({}, BasicPane)
MaterialInput.ClassName = "MaterialInput"
MaterialInput.__index = MaterialInput

function MaterialInput.new(mouse)
	local self = setmetatable(BasicPane.new(), MaterialInput)

	self._mouse = mouse or error("No mouse")

	self.MaterialSelected = Signal.new() -- :Fire(material)
	self.ConvertRequest = Signal.new() -- :Fire()

	self._raycaster = Raycaster.new()
	self._raycaster.Filter = function(hitData)
		if hitData.Part ~= Workspace.Terrain then
			return true
		end
	end

	self._maid:GiveTask(UserInputService.InputBegan:Connect(function(inputObject, gameProcessed)
		if gameProcessed then
			return
		end

		if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt) then
				local material = self:_findMaterial()
				if material then
					self.MaterialSelected:Fire(material)
				end
			end
		elseif inputObject.KeyCode == Enum.KeyCode.B then
			self.ConvertRequest:Fire()
		end
	end))

	self._maid:GiveTask(function()

	end)

	return self
end

function MaterialInput:_startUpdate()

end

function MaterialInput:_findMaterial()
	local mouseRay = Ray.new(self._mouse.Origin.p, self._mouse.UnitRay.Direction*10000)
	local hitData = self._raycaster:FindPartOnRay(mouseRay)
	if hitData then
		return hitData.Material
	end
end

return MaterialInput