local Tower = {}
Tower.__index = Tower

-- Constructor for the Tower class
-- @param x number The x position of the tower
-- @param y number The y position of the tower
-- @param cost number The cost to build the tower
-- @param range number The attack range of the tower
-- @param damage number The damage dealt by the tower
-- @param attackSpeed number The attack speed (attacks per second)
function Tower.new(x, y, cost, range, damage, attackSpeed)
	local self = setmetatable({}, Tower)

	-- Position
	self.x = x
	self.y = y

	-- Stats
	self.cost = cost
	self.range = range
	self.damage = damage
	self.attackSpeed = attackSpeed
	self.lastAttackTime = 0

	-- State
	self.target = nil
	self.isActive = true

	-- Projectile properties (to be overridden by subclasses)
	self.projectileSpeed = 300 -- Default speed in pixels per second
	self.projectileSize = 4 -- Default size in pixels

	return self
end

-- Update the tower's state
-- @param dt number Delta time
-- @param gameState table The current game state
function Tower:update(dt, gameState)
	-- Find a target if we don't have one or our current target is dead/gone
	if not self.target or self.target:isDead() or self.target:hasReachedEnd() then
		self.target = self:findTarget(gameState)
	end

	-- Attack if we have a target and enough time has passed
	if self.target and self.isActive then
		local currentTime = love.timer.getTime()
		if currentTime - self.lastAttackTime >= 1 / self.attackSpeed then
			self:attack(gameState)
			self.lastAttackTime = currentTime
		end
	end
end

-- Draw the tower
function Tower:draw()
	-- To be implemented by subclasses
end

-- Find a target from the enemies in range
-- @param gameState table The current game state
-- @return The target enemy or nil if none in range
function Tower:findTarget(gameState)
	local closestEnemy = nil
	local closestDistance = self.range

	-- Get center position
	local centerX, centerY
	if self.cellX and self.cellY then
		-- If we have cell coordinates, use them to get pixel coordinates
		centerX = (self.cellX - 1) * gameState.map.cellSize + gameState.map.cellSize / 2
		centerY = (self.cellY - 1) * gameState.map.cellSize + gameState.map.cellSize / 2
	else
		-- Otherwise, use the tower's current position
		centerX = self.x
		centerY = self.y
	end

	-- Find the closest enemy in range
	for _, enemy in ipairs(gameState.enemies) do
		if not enemy:isDead() and not enemy:hasReachedEnd() then
			local dx = enemy.pixelX - centerX
			local dy = enemy.pixelY - centerY
			local distance = math.sqrt(dx * dx + dy * dy)

			if distance <= self.range and (not closestEnemy or distance < closestDistance) then
				closestEnemy = enemy
				closestDistance = distance
			end
		end
	end

	return closestEnemy
end

-- Attack the current target
-- @param gameState table The current game state
function Tower:attack(gameState)
	if self.target then
		-- Calculate projectile start position (center of tower)
		local startX, startY
		if self.cellX and self.cellY then
			-- Use cell coordinates if available
			startX = (self.cellX - 1) * gameState.map.cellSize + gameState.map.cellSize / 2
			startY = (self.cellY - 1) * gameState.map.cellSize + gameState.map.cellSize / 2
		else
			-- Otherwise use tower position
			startX = self.x
			startY = self.y
		end

		-- Create a projectile aimed at the target
		if gameState.projectileManager then
			gameState.projectileManager:createProjectile(
				startX,
				startY,
				self.target,
				self.damage,
				self.projectileSpeed,
				self.projectileSize
			)
		end
	end
end

return Tower
