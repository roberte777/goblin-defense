-- Path.lua
-- Handles path finding and path management for enemies

local Path = {}
Path.__index = Path

-- Create a new Path object
-- @param map The game map
-- @param startX The starting X position (in grid coordinates)
-- @param startY The starting Y position (in grid coordinates)
-- @param endX The ending X position (in grid coordinates)
-- @param endY The ending Y position (in grid coordinates)
function Path.new(map, startX, startY, endX, endY)
	local self = setmetatable({}, Path)

	self.map = map
	self.startX = startX
	self.startY = startY
	self.endX = endX
	self.endY = endY

	-- The actual path nodes as a sequence of {x, y} coordinates
	self.nodes = {}

	-- Find the initial path
	self:findPath()

	return self
end

-- Check if a cell is walkable (can be part of the path)
-- @param x The x coordinate to check
-- @param y The y coordinate to check
-- @return Boolean indicating if the cell is walkable
function Path:isWalkable(x, y)
	-- Check bounds
	if x < 1 or x > self.map.width or y < 1 or y > self.map.height then
		return false
	end

	-- Get the cell and check its type
	local cell = self.map:getCell(x, y)
	if not cell then
		return false
	end

	-- Start and end points are always walkable
	if (x == self.startX and y == self.startY) or (x == self.endX and y == self.endY) then
		return true
	end

	-- Use GameFunctions to check if square is available
	local GameFunctions = require("src.GameFunctions")
	return GameFunctions.isSquareAvailable(self.map, x, y)
end

-- Calculate Manhattan distance heuristic for A* algorithm
-- @param x1 The x coordinate of the first point
-- @param y1 The y coordinate of the first point
-- @param x2 The x coordinate of the second point
-- @param y2 The y coordinate of the second point
-- @return number The Manhattan distance between the points
function Path:heuristic(x1, y1, x2, y2)
	return math.abs(x2 - x1) + math.abs(y2 - y1)
end

-- Find the path from start to end using A* algorithm
function Path:findPath()
	-- Clear the current path
	self.nodes = {}

	-- Priority queue for A* (implemented as a simple array)
	local openSet = {}

	-- Insert the start node into the open set
	table.insert(openSet, {
		x = self.startX,
		y = self.startY,
		g = 0, -- Cost from start to current node
		h = self:heuristic(self.startX, self.startY, self.endX, self.endY), -- Heuristic (estimated cost to goal)
		f = self:heuristic(self.startX, self.startY, self.endX, self.endY), -- f = g + h
		path = {}, -- Path taken to reach this node
	})

	-- Keep track of visited cells and their costs
	local closedSet = {}
	for y = 1, self.map.height do
		closedSet[y] = {}
		for x = 1, self.map.width do
			closedSet[y][x] = false
		end
	end

	-- Track the best g score for each cell
	local gScore = {}
	for y = 1, self.map.height do
		gScore[y] = {}
		for x = 1, self.map.width do
			gScore[y][x] = math.huge -- Initialize with infinity
		end
	end
	gScore[self.startY][self.startX] = 0

	-- Directions for adjacent cells (up, right, down, left)
	local directions = {
		{ dx = 0, dy = -1 },
		{ dx = 1, dy = 0 },
		{ dx = 0, dy = 1 },
		{ dx = -1, dy = 0 },
	}

	-- A* algorithm
	while #openSet > 0 do
		-- Find the node with the lowest f score in the open set
		local lowestIndex = 1
		for i = 2, #openSet do
			if openSet[i].f < openSet[lowestIndex].f then
				lowestIndex = i
			end
		end
		local current = table.remove(openSet, lowestIndex)

		-- If we've reached the end, we have our path
		if current.x == self.endX and current.y == self.endY then
			-- Copy the path
			for _, node in ipairs(current.path) do
				table.insert(self.nodes, { x = node.x, y = node.y })
			end
			-- Add the end node
			table.insert(self.nodes, { x = self.endX, y = self.endY })

			-- Mark path cells in the map
			self:markPathOnMap()
			return
		end

		-- Mark current node as visited
		closedSet[current.y][current.x] = true

		-- Check each adjacent cell
		for _, dir in ipairs(directions) do
			local nextX = current.x + dir.dx
			local nextY = current.y + dir.dy

			-- If the cell is walkable and not in the closed set
			if self:isWalkable(nextX, nextY) and not closedSet[nextY][nextX] then
				-- Calculate tentative g score (cost from start)
				local tentativeG = current.g + 1 -- Assume cost of 1 to move to adjacent cell

				-- Check if this path is better than any previous path to this node
				if tentativeG < gScore[nextY][nextX] then
					-- This is a better path, record it
					gScore[nextY][nextX] = tentativeG

					-- Create a new path by copying the current path and adding the new position
					local newPath = {}
					for _, node in ipairs(current.path) do
						table.insert(newPath, { x = node.x, y = node.y })
					end
					table.insert(newPath, { x = current.x, y = current.y })

					-- Calculate heuristic (Manhattan distance to goal)
					local h = self:heuristic(nextX, nextY, self.endX, self.endY)
					local f = tentativeG + h

					-- Check if the node is already in the open set
					local inOpenSet = false
					for i, node in ipairs(openSet) do
						if node.x == nextX and node.y == nextY then
							inOpenSet = true
							-- Update the node if this path is better
							if tentativeG < node.g then
								node.g = tentativeG
								node.f = f
								node.path = newPath
							end
							break
						end
					end

					-- If the node is not in the open set, add it
					if not inOpenSet then
						table.insert(openSet, {
							x = nextX,
							y = nextY,
							g = tentativeG,
							h = h,
							f = f,
							path = newPath,
						})
					end
				end
			end
		end
	end

	-- If we get here, there's no path
	print("No path found from start to end!")
end

-- Mark all nodes in the current path on the map
function Path:markPathOnMap()
	-- First, clear any existing path cells (except start/end)
	for y = 1, self.map.height do
		for x = 1, self.map.width do
			local cell = self.map:getCell(x, y)
			if
				cell.type == "path"
				and not ((x == self.startX and y == self.startY) or (x == self.endX and y == self.endY))
			then
				self.map:setCell(x, y, "empty")
			end
		end
	end

	-- Mark start and end points
	self.map:setCell(self.startX, self.startY, "path")
	self.map:setCell(self.endX, self.endY, "path")

	-- Mark each node in the path, but skip cells where towers are already placed
	for _, node in ipairs(self.nodes) do
		local cell = self.map:getCell(node.x, node.y)
		-- Only mark as path if the cell is empty or already a path
		if cell and (cell.type == "empty" or cell.type == "path") then
			self.map:setCell(node.x, node.y, "path")
		end
	end
end

-- Update the path when the map changes
-- @param x The x coordinate that changed
-- @param y The y coordinate that changed
function Path:updatePath()
	self:findPath()
end

-- Draw the path
function Path:draw()
	love.graphics.setColor(1, 0.7, 0.3, 0.7) -- Orange-yellow for the path

	-- Draw start point (green)
	local startX, startY = self.map:gridToPixel(self.startX, self.startY)
	love.graphics.setColor(0, 1, 0, 0.8)
	love.graphics.rectangle("fill", startX, startY, self.map.cellSize, self.map.cellSize)

	-- Draw path
	love.graphics.setColor(1, 0.7, 0.3, 0.7)
	for i = 1, #self.nodes do
		local node = self.nodes[i]
		local x, y = self.map:gridToPixel(node.x, node.y)
		love.graphics.rectangle("fill", x, y, self.map.cellSize, self.map.cellSize)
	end

	-- Draw end point (red)
	local endX, endY = self.map:gridToPixel(self.endX, self.endY)
	love.graphics.setColor(1, 0, 0, 0.8)
	love.graphics.rectangle("fill", endX, endY, self.map.cellSize, self.map.cellSize)

	-- Draw path connections
	love.graphics.setColor(1, 0.7, 0.3, 0.9)
	love.graphics.setLineWidth(3)

	-- Connect from start to first node if path exists
	if #self.nodes > 0 then
		local startCenterX = startX + self.map.cellSize / 2
		local startCenterY = startY + self.map.cellSize / 2

		local firstNode = self.nodes[1]
		local firstNodeX, firstNodeY = self.map:gridToPixel(firstNode.x, firstNode.y)
		local firstNodeCenterX = firstNodeX + self.map.cellSize / 2
		local firstNodeCenterY = firstNodeY + self.map.cellSize / 2

		love.graphics.line(startCenterX, startCenterY, firstNodeCenterX, firstNodeCenterY)

		-- Connect nodes
		for i = 1, #self.nodes - 1 do
			local node1 = self.nodes[i]
			local node2 = self.nodes[i + 1]

			local x1, y1 = self.map:gridToPixel(node1.x, node1.y)
			local x2, y2 = self.map:gridToPixel(node2.x, node2.y)

			local centerX1 = x1 + self.map.cellSize / 2
			local centerY1 = y1 + self.map.cellSize / 2
			local centerX2 = x2 + self.map.cellSize / 2
			local centerY2 = y2 + self.map.cellSize / 2

			love.graphics.line(centerX1, centerY1, centerX2, centerY2)
		end
	end

	-- Reset line width
	love.graphics.setLineWidth(1)
end

return Path
