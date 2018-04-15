---
-- @classmod TerrainConverter
-- @author Quenty

local Signal = require(script.Parent.Signal)
local BoundingBox = require(script.Parent.BoundingBox)
local Draw = require(script.Parent.Draw)

local MATERIAL_AIR = Enum.Material.Air

local TerrainConverter = {}
TerrainConverter.ClassName = "TerrainConverter"
TerrainConverter.__index = TerrainConverter
TerrainConverter.RESOLUTION = 4

function TerrainConverter.new()
	local self = setmetatable({}, TerrainConverter)

	self.KeepConvertedPart = Instance.new("BoolValue")
	self.KeepConvertedPart.Value = true

	self.ReplaceExistingTerrain = Instance.new("BoolValue")
	self.ReplaceExistingTerrain.Value = true

	self.ConversionStarting = Signal.new()

	return self
end

function TerrainConverter:_canConvertPart(item)
	if not item:IsA("Part") then
		return false
	end

	if item == workspace.Terrain then
		return false
	end

	if item.Shape == Enum.PartType.Block then
		return true
	elseif item.Shape == Enum.PartType.Ball then
		return true
	else
		return false
	end
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

function TerrainConverter:_fillBlock(blockCFrame, blockSize, desiredMaterial)
	if self.ReplaceExistingTerrain.Value then
		workspace.Terrain:FillBlock(blockCFrame, blockSize, desiredMaterial)
		return
	end

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
	max = region.CFrame.p + region.Size/2

	local materialVoxels, occupancyVoxels = workspace.Terrain:ReadVoxels(region, resolution)
	local size = materialVoxels.Size

	-- Draw.Point(min)
	-- Draw.Point(max)
	-- Draw.SetRandomColor()

	-- Since we only care about the size if it's less than one cell, we clamp this to make the calculations below faster.
	local sizeCellClamped = (blockSize / resolution)
	sizeCellClamped = Vector3.new(math.min(1, sizeCellClamped.x), math.min(1, sizeCellClamped.y), math.min(1, sizeCellClamped.z))
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
						if cellMaterial == MATERIAL_AIR or cellOccupancy <= 0 then
							materialVoxels[x][y][z] = desiredMaterial
						end
						occupancyVoxels[x][y][z] = 1
					end
				else
					if brushOccupancy > cellOccupancy then
						occupancyVoxels[x][y][z] = brushOccupancy
					end
					if brushOccupancy >= 0.1 and cellMaterial == MATERIAL_AIR then
						materialVoxels[x][y][z] = desiredMaterial
					end
				end
			end
		end
	end

	workspace.Terrain:WriteVoxels(region, self.RESOLUTION, materialVoxels, occupancyVoxels)
end


function TerrainConverter:_fillBall(center, radius, desiredMaterial)
	if self.ReplaceExistingTerrain.Value then
		workspace.Terrain:FillBall(center, radius, desiredMaterial)
		return
	end

	local resolution = self.RESOLUTION

	local radius3 = Vector3.new(radius, radius, radius)
	local min = center - radius3
	local max = center + radius3
	local region = Region3.new(min, max):ExpandToGrid(resolution)

	min = region.CFrame.p - region.Size/2
	max = region.CFrame.p + region.Size/2

	local materialVoxels, occupancyVoxels = workspace.Terrain:ReadVoxels(region, resolution)
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
						if cellMaterial == MATERIAL_AIR or cellOccupancy <= 0 then
							materialVoxels[x][y][z] = desiredMaterial
						end
						occupancyVoxels[x][y][z] = 1
					end
				else
					if brushOccupancy > cellOccupancy then
						occupancyVoxels[x][y][z] = brushOccupancy
					end
					if brushOccupancy >= 0.5 and cellMaterial == MATERIAL_AIR then
						materialVoxels[x][y][z] = desiredMaterial
					end
				end
			end
		end
	end

	workspace.Terrain:WriteVoxels(region, resolution, materialVoxels, occupancyVoxels)
	print("Done writing voxels")
end

function TerrainConverter:_convertPart(part, material)
	assert(typeof(material) == "EnumItem")
	assert(part:IsA("Part"))

	if part.Shape == Enum.PartType.Block then
		self:_fillBlock(part.CFrame, part.Size, material)
	elseif part.Shape == Enum.PartType.Ball then
		self:_fillBall(part.Position, part.Size.x/2, material)
	else
		warn(("[PartToTerrain] - Bad part.Shape, '%s' is not supported"):format(tostring(part.Shape.Name)))
		return false
	end

	if not self.KeepConvertedPart.Value then
		part:Remove()
	end

	return true
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

return TerrainConverter