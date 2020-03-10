---
-- @classmod TerrainConverter
-- @author Quenty

local Workspace = game:GetService("Workspace")

local Signal = require(script.Parent.Signal)
local BoundingBox = require(script.Parent.BoundingBox)
local BasicPane = require(script.Parent.BasicPane)
local terrainMaterialList = require(script.Parent.terrainMaterialList)

local TerrainConverter = setmetatable({}, BasicPane)
TerrainConverter.ClassName = "TerrainConverter"
TerrainConverter.__index = TerrainConverter
TerrainConverter.RESOLUTION = 4

function TerrainConverter.new()
	local self = setmetatable(BasicPane.new(), TerrainConverter)

	self.KeepConvertedPart = Instance.new("BoolValue")
	self.KeepConvertedPart.Value = true
	self._maid:GiveTask(self.KeepConvertedPart)

	self.OverwriteTerrain = Instance.new("BoolValue")
	self.OverwriteTerrain.Value = true
	self._maid:GiveTask(self.OverwriteTerrain)

	self.OverwriteWater = Instance.new("BoolValue")
	self.OverwriteWater.Value = true
	self._maid:GiveTask(self.OverwriteWater)

	self.ConversionStarting = Signal.new()
	self._maid:GiveTask(self.ConversionStarting)

	return self
end

function TerrainConverter:Convert(items, material)
	assert(items)
	assert(typeof(material) == "EnumItem")

	local convertables = {}
	for _, item in pairs(items) do
		if self:_canConvertPart(item) then
			table.insert(convertables, item)
		end
	end

	-- don't fire change history service of nothing converts
	if #convertables <= 0 then
		return false
	end

	self.ConversionStarting:Fire()
	for _, item in pairs(convertables) do
		self:_convertPart(item, material)
	end
	return true
end

function TerrainConverter:CanConvert(items)
	if #items <= 0 then
		return false
	end

	for _, item in pairs(items) do
		if self:_canConvertPart(item) then
			return true
		end
	end

	return false
end


function TerrainConverter:_canConvertPart(item)
	if not (item:IsA("Part") or item:IsA("WedgePart")) then
		return false
	end

	if item == Workspace.Terrain then
		return false
	end

	if item:IsA("WedgePart") then
		return true
	elseif item.Shape == Enum.PartType.Block then
		return true
	elseif item.Shape == Enum.PartType.Ball then
		return true
	elseif item.Shape == Enum.PartType.Cylinder then
		return true
	else
		return false
	end
end

function TerrainConverter:_getOverwriteMaterials()
	local materials = {}
	materials[Enum.Material.Air] = true

	if self.OverwriteTerrain.Value then
		for _, item in pairs(terrainMaterialList) do
			materials[item.enum] = true
		end
	end

	if self.OverwriteWater.Value then
		materials[Enum.Material.Water] = true
	else
		materials[Enum.Material.Water] = nil
	end

	return materials
end

function TerrainConverter:_doFillUpwards(cellMaterial, desiredMaterial)
	if desiredMaterial == Enum.Material.Air then
		return false
	end
	if desiredMaterial == Enum.Material.Water then
		if cellMaterial == Enum.Material.Air or cellMaterial == Enum.Material.Water then
			return true
		else
			return false
		end
	end

	return true
end

function TerrainConverter:_convertPart(part, material)
	assert(typeof(material) == "EnumItem")
	assert(part:IsA("Part") or part:IsA("WedgePart"))

	if part:IsA("WedgePart") then
		self:_fillWedge(part.CFrame, part.Size, material)
	elseif part.Shape == Enum.PartType.Block then
		self:_fillBlock(part.CFrame, part.Size, material)
	elseif part.Shape == Enum.PartType.Ball then
		self:_fillBall(part.Position, part.Size.x/2, material)
	elseif part.Shape == Enum.PartType.Cylinder then
		local size = part.Size
		local height = size.x
		local radius = math.min(size.y, size.z)
		self:_fillCylinder(part.CFrame * CFrame.Angles(0, 0, math.pi/2), height, radius, material)
	else
		warn(("[PartToTerrain] - Bad part.Shape, '%s' is not supported"):format(tostring(part.Shape.Name)))
		return false
	end

	if not self.KeepConvertedPart.Value then
		part:Remove()
	end

	return true
end

function TerrainConverter:_fillWedge(wedgeCFrame, wedgeSize, desiredMaterial)
	if (self.OverwriteTerrain.Value and self.OverwriteWater.Value) then
		Workspace.Terrain:FillWedge(wedgeCFrame, wedgeSize, desiredMaterial)
		return
	end

	warn("[TerrainConverter._fillWedge] - Cannot convert wedge with overwrite terrain, or overwrite water enabled!")
end

function TerrainConverter:_fillCylinder(cylinderCFrame, height, radius, desiredMaterial)
	if (self.OverwriteTerrain.Value and self.OverwriteWater.Value) then
		Workspace.Terrain:FillCylinder(cylinderCFrame, height, radius, desiredMaterial)
		return
	end

	warn("[TerrainConverter._fillCylinder] - Cannot convert wedge with overwrite terrain, or overwrite water enabled!")
end

function TerrainConverter:_fillBlock(blockCFrame, blockSize, desiredMaterial)
	if (self.OverwriteTerrain.Value and self.OverwriteWater.Value) then
		Workspace.Terrain:FillBlock(blockCFrame, blockSize, desiredMaterial)
		return
	end

	local overwriteMaterials = self:_getOverwriteMaterials()
	-- local shouldFillUpwards = self:_shouldFillUpwards(desiredMaterial)

	-- https://pastebin.com/S03Q8ftH

	local aa_size, aa_position = BoundingBox.GetBoundingBox({{
		Size = blockSize;
		CFrame = blockCFrame;
	}})

	local smallestSize = math.min(blockSize.x, blockSize.y, blockSize.z)
	local resolution = self.RESOLUTION

	-- make sure to get all grids
	local min = aa_position - aa_size/2
	local max = aa_position + aa_size/2
	local region = Region3.new(min, max):ExpandToGrid(resolution)
	min = region.CFrame.p - region.Size/2

	-- luacheck: push ignore
	max = region.CFrame.p + region.Size/2
	-- luacheck: pop ignore

	local materialVoxels, occupancyVoxels = Workspace.Terrain:ReadVoxels(region, resolution)
	local size = materialVoxels.Size

	-- Draw.Point(min)
	-- Draw.Point(max)
	-- Draw.SetRandomColor()

	-- Since we only care about the size if it's less than one cell, we clamp this to make the calculations below faster.
	local sizeCellClamped = (blockSize / resolution)
	sizeCellClamped = Vector3.new(
		math.min(1, sizeCellClamped.x),
		math.min(1, sizeCellClamped.y),
		math.min(1, sizeCellClamped.z))
	local sizeCellsHalfOffset = blockSize * (0.5 / resolution) + Vector3.new(0.5, 0.5, 0.5)

	for x=1, size.X do
		local cellPosX = min.x + (x - 0.5) * resolution
		for y=1, size.Y do
			local cellPosY = min.y + (y - 0.5) * resolution
			for z=1, size.Z do
				local cellPosZ = min.z + (z - 0.5) * resolution
				local position = Vector3.new(cellPosX, cellPosY, cellPosZ)

				-- -0.5 to 0.5
				local offset = blockCFrame:pointToObjectSpace(position)/resolution

				-- Draw.Point(position)

				local distX = sizeCellsHalfOffset.x - math.abs(offset.X)
				local distY = sizeCellsHalfOffset.y - math.abs(offset.Y)
				local distZ = sizeCellsHalfOffset.z - math.abs(offset.Z)

				local factorX = math.max(0, math.min(distX, sizeCellClamped.x))
				local factorY = math.max(0, math.min(distY, sizeCellClamped.y))
				local factorZ = math.max(0, math.min(distZ, sizeCellClamped.z))

				local brushOccupancy = math.min(factorX, factorY, factorZ)

				local cellMaterial = materialVoxels[x][y][z]
				local cellOccupancy = occupancyVoxels[x][y][z]

				-- Use terrain tools filling behavior here
				if smallestSize <= 2 then
					if brushOccupancy >= 0.1 then
						if overwriteMaterials[cellMaterial] or cellOccupancy <= 0 then
							materialVoxels[x][y][z] = desiredMaterial
						end
						occupancyVoxels[x][y][z] = 1
					end
				else
					--- fills upwards!
					if brushOccupancy > cellOccupancy and self:_doFillUpwards(cellMaterial, desiredMaterial) then
						occupancyVoxels[x][y][z] = brushOccupancy
					end
					if brushOccupancy >= 0.1 and overwriteMaterials[cellMaterial] then
						materialVoxels[x][y][z] = desiredMaterial
					end
				end
			end
		end
	end

	Workspace.Terrain:WriteVoxels(region, self.RESOLUTION, materialVoxels, occupancyVoxels)
end

function TerrainConverter:_fillBall(center, radius, desiredMaterial)
	if (self.OverwriteTerrain.Value and self.OverwriteWater.Value) then
		Workspace.Terrain:FillBall(center, radius, desiredMaterial)
		return
	end

	local overwriteMaterials = self:_getOverwriteMaterials()

	local resolution = self.RESOLUTION

	local radius3 = Vector3.new(radius, radius, radius)
	local min = center - radius3
	local max = center + radius3
	local region = Region3.new(min, max):ExpandToGrid(resolution)

	min = region.CFrame.p - region.Size/2
	-- luacheck: push ignore
	max = region.CFrame.p + region.Size/2
	-- luacheck: pop ignore

	local materialVoxels, occupancyVoxels = Workspace.Terrain:ReadVoxels(region, resolution)
	local size = materialVoxels.Size
	for x=1, size.X do
		local cellX = min.x + (x - 0.5) * resolution - center.x
		for y=1, size.Y do
			local cellY = min.y + (y - 0.5) * resolution - center.y
			for z=1, size.Z do
				local cellZ = min.z + (z - 0.5) * resolution - center.z

				local cellMaterial = materialVoxels[x][y][z]
				local cellOccupancy = occupancyVoxels[x][y][z]
				local distance = math.sqrt(cellX*cellX + cellY*cellY + cellZ*cellZ)
				local brushOccupancy = math.max(0, math.min(1, (radius + 0.5 * resolution - distance) / resolution))

				-- Use terrain tools filling behavior here
				if radius <= 2 then
					if brushOccupancy >= 0.5 then
						if overwriteMaterials[cellMaterial] or cellOccupancy <= 0 then
							materialVoxels[x][y][z] = desiredMaterial
						end
						occupancyVoxels[x][y][z] = 1
					end
				else
					--- fills upwards!
					if brushOccupancy > cellOccupancy and self:_doFillUpwards(cellMaterial, desiredMaterial) then
						occupancyVoxels[x][y][z] = brushOccupancy
					end
					if brushOccupancy >= 0.5 and overwriteMaterials[cellMaterial] then
						materialVoxels[x][y][z] = desiredMaterial
					end
				end
			end
		end
	end

	Workspace.Terrain:WriteVoxels(region, resolution, materialVoxels, occupancyVoxels)
end

return TerrainConverter