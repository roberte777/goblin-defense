-- Enemy.lua
-- Base class for all enemies in the game

local Enemy = {}
Enemy.__index = Enemy

-- Create a new Enemy object
-- @param pixelX Initial x position in pixel coordinates
-- @param pixelY Initial y position in pixel coordinates
-- @param health Health points of the enemy
-- @param speed Movement speed in tiles per second
function Enemy.new(pixelX, pixelY, health, speed)
	local self = setmetatable({}, Enemy)

	-- Position (in pixel coordinates)
	self.pixelX = pixelX
	self.pixelY = pixelY

	-- Stats
	self.health = health
	self.maxHealth = health
	self.speed = speed -- tiles per second

	-- Path following
	self.currentNodeIndex = 1
	self.reachedEnd = false

	-- Visual properties
	self.color = { 1, 0, 0 } -- Default red
	self.size = 0.8 -- Size relative to a tile (0.8 = 80% of tile size)

	print("Enemy created at pixel coordinates: " .. pixelX .. ", " .. pixelY)

	return self
end

-- Get current grid coordinates based on pixel position
-- @param gameState The current game state
-- @return x, y Grid coordinates
function Enemy:getGridPosition(gameState)
	return gameState.map:pixelToGrid(self.pixelX, self.pixelY)
end

-- Update enemy position and state
-- @param dt Delta time
-- @param gameState The current game state
function Enemy:update(dt, gameState)
	if self.health <= 0 or self.reachedEnd then
		return
	end

	-- Follow the path by moving toward the next node
	if gameState.path and gameState.path.nodes and #gameState.path.nodes > 0 then
		-- Get next node on the path
		if self.currentNodeIndex <= #gameState.path.nodes then
			local targetNode = gameState.path.nodes[self.currentNodeIndex]

			-- Get target pixel coordinates (cell center)
			local targetPixelX, targetPixelY = gameState.map:gridToPixel(targetNode.x, targetNode.y)
			targetPixelX = targetPixelX + gameState.map.cellSize / 2
			targetPixelY = targetPixelY + gameState.map.cellSize / 2

			-- Calculate distance to move this frame
			local distanceToMove = self.speed * gameState.map.cellSize * dt

			-- Calculate direction vector to target
			local dx = targetPixelX - self.pixelX
			local dy = targetPixelY - self.pixelY
			local distance = math.sqrt(dx * dx + dy * dy)

			-- Move toward the target
			if distance > 0 then
				-- Normalize direction vector
				local nx = dx / distance
				local ny = dy / distance

				-- Move by the smaller of distanceToMove or the remaining distance
				local moveAmount = math.min(distanceToMove, distance)
				self.pixelX = self.pixelX + nx * moveAmount
				self.pixelY = self.pixelY + ny * moveAmount

				-- If we've reached the target node (with a small tolerance), move to the next one
				if distance <= distanceToMove + 1 then -- Adding 1 pixel tolerance
					self.currentNodeIndex = self.currentNodeIndex + 1

					-- Check if we've reached the end of the path
					if self.currentNodeIndex > #gameState.path.nodes then
						self.reachedEnd = true
						-- Damage player when enemy reaches the end
						gameState.player.health = gameState.player.health - 1
					end
				end
			elseif distance == 0 then
				-- Already at the target, move to next node
				self.currentNodeIndex = self.currentNodeIndex + 1

				-- Check if we've reached the end of the path
				if self.currentNodeIndex > #gameState.path.nodes then
					self.reachedEnd = true
					gameState.player.health = gameState.player.health - 1
				end
			end
		else
			-- Failsafe in case we don't have a valid node index
			self.reachedEnd = true
			gameState.player.health = gameState.player.health - 1
		end
	else
		-- If there's no path, treat it as if the enemy reached the end
		self.reachedEnd = true
	end
end

-- Draw the enemy
-- @param gameState The current game state
function Enemy:draw(gameState)
	if self.health <= 0 then
		return
	end

	-- Set the enemy's color
	love.graphics.setColor(unpack(self.color))

	-- Calculate size
	local cellSize = gameState.map.cellSize
	local enemySize = cellSize * self.size

	-- Draw the enemy body centered on pixel coordinates
	love.graphics.rectangle(
		"fill",
		self.pixelX - enemySize / 2,
		self.pixelY - enemySize / 2,
		enemySize,
		enemySize,
		enemySize * 0.2, -- rounded corners
		enemySize * 0.2
	)

	-- Draw health bar centered above the enemy
	local healthBarWidth = enemySize
	local healthBarHeight = enemySize * 0.1
	local healthPercent = self.health / self.maxHealth

	-- Health bar background
	love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
	love.graphics.rectangle(
		"fill",
		self.pixelX - healthBarWidth / 2,
		self.pixelY - enemySize / 2 - healthBarHeight - 2,
		healthBarWidth,
		healthBarHeight
	)

	-- Health bar fill
	love.graphics.setColor(0.2, 0.8, 0.2, 0.8) -- Green
	love.graphics.rectangle(
		"fill",
		self.pixelX - healthBarWidth / 2,
		self.pixelY - enemySize / 2 - healthBarHeight - 2,
		healthBarWidth * healthPercent,
		healthBarHeight
	)

	-- Debug: Draw a small dot at the exact pixel position
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.circle("fill", self.pixelX, self.pixelY, 2)
end

-- Take damage
-- @param amount The amount of damage to take
function Enemy:takeDamage(amount)
	self.health = self.health - amount
	if self.health <= 0 then
		-- Enemy is defeated
		return true
	end
	return false
end

-- Check if the enemy is dead
-- @return boolean Whether the enemy is dead
function Enemy:isDead()
	return self.health <= 0
end

-- Check if the enemy has reached the end of the path
-- @return boolean Whether the enemy has reached the end
function Enemy:hasReachedEnd()
	return self.reachedEnd
end

return Enemy
