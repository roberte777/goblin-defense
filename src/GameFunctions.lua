-- GameFunctions.lua
-- A collection of utility functions for the game

local GameFunctions = {}

-- Check if a cell is available (either path or empty)
-- @param map The game map
-- @param x The x coordinate to check
-- @param y The y coordinate to check
-- @return Boolean indicating if the cell is available
function GameFunctions.isSquareAvailable(map, x, y)
	-- Check bounds
	if x < 1 or x > map.width or y < 1 or y > map.height then
		return false
	end

	-- Get the cell
	local cell = map:getCell(x, y)
	if not cell then
		return false
	end

	-- Cell is available if it's either empty or a path
	return cell.type == "empty" or cell.type == "path"
end

-- Convert physical mouse coordinates to virtual coordinates
-- @param config table The game config containing scaling information
-- @return number, number The virtual x and y coordinates
function GameFunctions.getVirtualMousePosition(config)
	local mouseX, mouseY = love.mouse.getPosition()

	-- Convert screen coordinates to virtual coordinates
	local virtualX = (mouseX - config.offset_x) / config.scale_x
	local virtualY = (mouseY - config.offset_y) / config.scale_y

	return virtualX, virtualY
end

-- Get the center pixel coordinates of a cell
-- @param map The game map
-- @param gridX The x grid coordinate
-- @param gridY The y grid coordinate
-- @return number, number The pixel coordinates of the cell center
function GameFunctions.getCellCenterPixels(map, gridX, gridY)
	-- First get the top-left corner of the cell
	local pixelX, pixelY = map:gridToPixel(gridX, gridY)

	-- Add half the cell size to get to the center of the cell
	pixelX = pixelX + map.cellSize / 2
	pixelY = pixelY + map.cellSize / 2

	return pixelX, pixelY
end

return GameFunctions
