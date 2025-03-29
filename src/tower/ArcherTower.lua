local Tower = require("src.tower.Tower")
local ArcherTower = setmetatable({}, { __index = Tower })
ArcherTower.__index = ArcherTower

-- Constructor for the ArcherTower class
-- @param cellX number The x cell coordinate of the tower
-- @param cellY number The y cell coordinate of the tower
function ArcherTower.new(cellX, cellY)
	-- Archer tower stats
	local cost = 100
	local range = 200
	local damage = 20
	local attackSpeed = 1.0 -- attacks per second

	-- Call parent constructor with pixel coordinates
	local self = Tower.new(cellX, cellY, cost, range, damage, attackSpeed)
	setmetatable(self, ArcherTower)

	-- Store cell coordinates
	self.cellX = cellX
	self.cellY = cellY

	-- Archer-specific projectile properties
	self.projectileSpeed = 300 -- pixels per second
	self.projectileSize = 4

	-- Custom arrow color
	self.projectileColor = { 0.8, 0.8, 0.2 } -- Yellow-ish arrows

	return self
end

-- Update the archer tower's state
-- @param dt number Delta time
-- @param gameState table The current game state
function ArcherTower:update(dt, gameState)
	-- Call parent update (handles target finding and attacking)
	Tower.update(self, dt, gameState)
end

-- Draw the archer tower
-- @param gameState table The current game state
function ArcherTower:draw(gameState)
	-- Get cell size from the game state
	local cellSize = gameState.map.cellSize

	-- Calculate position at bottom middle of cell
	local x = (self.cellX - 1) * cellSize + cellSize / 2 -- Center of cell
	local y = (self.cellY - 1) * cellSize + cellSize -- Bottom of cell

	-- Draw tower top (brown rectangle)
	love.graphics.setColor(0.6, 0.4, 0.2)
	love.graphics.rectangle("fill", x - cellSize / 4, y - cellSize * 0.75, cellSize / 2, cellSize * 0.75)

	-- Draw range indicator when tower is selected or hovered (semi-transparent circle)
	if
		gameState.selectedTower == self
		or (
			gameState.map.hoveredCell
			and gameState.map.hoveredCell.x == self.cellX
			and gameState.map.hoveredCell.y == self.cellY
		)
	then
		love.graphics.setColor(0, 0, 0, 0.1)
		love.graphics.circle("fill", x, y - cellSize / 2, self.range)
	end
end

-- Custom projectile creation for archer tower
-- @param gameState table The current game state
function ArcherTower:attack(gameState)
	if self.target then
		-- Calculate projectile start position (center of tower)
		local startX = (self.cellX - 1) * gameState.map.cellSize + gameState.map.cellSize / 2
		local startY = (self.cellY - 1) * gameState.map.cellSize + gameState.map.cellSize / 2

		-- Create a projectile aimed at the target
		if gameState.projectileManager then
			local projectile = gameState.projectileManager:createProjectile(
				startX,
				startY,
				self.target,
				self.damage,
				self.projectileSpeed,
				self.projectileSize
			)

			-- Set custom color if projectile was created
			if projectile then
				projectile.color = self.projectileColor
			end
		end
	end
end

return ArcherTower
