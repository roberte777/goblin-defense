-- @class Map
-- @field grid table A 2D grid of cells
-- @field cellSize number Size of each cell in pixels (32x32)
-- @field width number Map width in cells
-- @field height number Map height in cells
-- @field hoveredCell table The cell currently being hovered, or nil if none
local Map = {}
Map.__index = Map

-- Create a new Map with the specified dimensions
-- @param width number Width of the map in cells
-- @param height number Height of the map in cells
-- @return Map The created map
function Map.new(width, height)
	local self = setmetatable({}, Map)

	self.cellSize = 32 -- 32x32 pixel cells
	self.width = width
	self.height = height
	self.hoveredCell = nil -- Tracks {x, y} of hovered cell

	-- Initialize the grid with empty cells
	self.grid = {}
	for y = 1, height do
		self.grid[y] = {}
		for x = 1, width do
			self.grid[y][x] = {
				type = "empty",
				-- Add more properties as needed (e.g., walkable, occupant, etc.)
			}
		end
	end

	return self
end

-- Get the cell at the specified grid coordinates
-- @param x number Grid x-coordinate (1-based)
-- @param y number Grid y-coordinate (1-based)
-- @return table The cell at the specified coordinates, or nil if out of bounds
function Map:getCell(x, y)
	if x < 1 or x > self.width or y < 1 or y > self.height then
		return nil
	end
	return self.grid[y][x]
end

-- Set a cell's type at the specified grid coordinates
-- @param x number Grid x-coordinate (1-based)
-- @param y number Grid y-coordinate (1-based)
-- @param cellType string The type to set the cell to
function Map:setCell(x, y, cellType)
	if x >= 1 and x <= self.width and y >= 1 and y <= self.height then
		self.grid[y][x].type = cellType
	end
end

-- Convert pixel coordinates to grid coordinates
-- @param pixelX number X-coordinate in pixels
-- @param pixelY number Y-coordinate in pixels
-- @return number, number The grid coordinates (x, y)
function Map:pixelToGrid(pixelX, pixelY)
	local gridX = math.floor(pixelX / self.cellSize) + 1
	local gridY = math.floor(pixelY / self.cellSize) + 1
	return gridX, gridY
end

-- Convert grid coordinates to pixel coordinates (returns the top-left corner of the cell)
-- @param gridX number X-coordinate in the grid
-- @param gridY number Y-coordinate in the grid
-- @return number, number The pixel coordinates (x, y)
function Map:gridToPixel(gridX, gridY)
	local pixelX = (gridX - 1) * self.cellSize
	local pixelY = (gridY - 1) * self.cellSize
	return pixelX, pixelY
end

-- Draw the map grid
-- @param showGrid boolean Whether to show grid lines
function Map:draw(showGrid)
	-- Draw cells
	for y = 1, self.height do
		for x = 1, self.width do
			local cell = self.grid[y][x]
			local pixelX, pixelY = self:gridToPixel(x, y)

			-- Draw different cell types
			if cell.type == "empty" then
				love.graphics.setColor(0.2, 0.2, 0.2)
			elseif cell.type == "wall" then
				love.graphics.setColor(0.6, 0.6, 0.6)
			elseif cell.type == "path" then
				love.graphics.setColor(0.4, 0.4, 0.8)
			elseif cell.type == "tower" then
				-- For tower cells, just use the base background color
				-- Towers will be drawn separately in the Game:draw method
				love.graphics.setColor(0.2, 0.2, 0.2)
			end

			love.graphics.rectangle("fill", pixelX, pixelY, self.cellSize, self.cellSize)

			-- Highlight the hovered cell
			if self.hoveredCell and self.hoveredCell.x == x and self.hoveredCell.y == y then
				-- Save current color
				local r, g, b, a = love.graphics.getColor()

				-- Draw highlight overlay
				love.graphics.setColor(1, 1, 1, 0.3)
				love.graphics.rectangle("fill", pixelX, pixelY, self.cellSize, self.cellSize)

				-- Draw a slightly brighter border
				love.graphics.setColor(1, 1, 1, 0.5)
				love.graphics.rectangle("line", pixelX, pixelY, self.cellSize, self.cellSize)

				-- Restore previous color
				love.graphics.setColor(r, g, b, a)
			end
		end
	end

	-- Draw grid lines if requested
	if showGrid then
		love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
		-- Vertical lines
		for x = 0, self.width do
			local pixelX = x * self.cellSize
			love.graphics.line(pixelX, 0, pixelX, self.height * self.cellSize)
		end
		-- Horizontal lines
		for y = 0, self.height do
			local pixelY = y * self.cellSize
			love.graphics.line(0, pixelY, self.width * self.cellSize, pixelY)
		end
	end
end

-- Set the hovered cell
-- @param x number Grid x-coordinate (1-based), or nil to clear hover
-- @param y number Grid y-coordinate (1-based), or nil to clear hover
function Map:setHoveredCell(x, y)
	if x and y and x >= 1 and x <= self.width and y >= 1 and y <= self.height then
		self.hoveredCell = { x = x, y = y }
	else
		self.hoveredCell = nil
	end
end

return Map
