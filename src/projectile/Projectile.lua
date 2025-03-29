-- Projectile.lua
-- Base class for all projectiles in the game

local Projectile = {}
Projectile.__index = Projectile

-- Create a new Projectile object
-- @param x Initial x position in pixel coordinates
-- @param y Initial y position in pixel coordinates
-- @param target Enemy target to track
-- @param damage Amount of damage this projectile deals
-- @param speed Movement speed in pixels per second
-- @param size Size of the projectile (radius for circular projectiles)
function Projectile.new(x, y, target, damage, speed, size)
	local self = setmetatable({}, Projectile)

	-- Position (in pixel coordinates)
	self.x = x
	self.y = y

	-- Stats
	self.target = target -- The enemy this projectile is targeting
	self.damage = damage
	self.speed = speed -- pixels per second
	self.size = size or 4 -- Default radius of 4 pixels

	-- State
	self.active = true -- Whether this projectile is active (should be updated/drawn)

	-- Visual properties
	self.color = { 1, 1, 0 } -- Default yellow

	return self
end

-- Update projectile position and check for collision
-- @param dt Delta time
-- @param gameState The current game state
-- @return boolean Whether this projectile should be removed
function Projectile:update(dt, gameState)
	if not self.active or not self.target or self.target:isDead() or self.target:hasReachedEnd() then
		-- Target is dead or reached the end, deactivate projectile
		self.active = false
		return true
	end

	-- Move toward target
	local dx = self.target.pixelX - self.x
	local dy = self.target.pixelY - self.y
	local distance = math.sqrt(dx * dx + dy * dy)

	if distance > 0 then
		-- Normalize direction vector
		local nx = dx / distance
		local ny = dy / distance

		-- Move projectile
		local moveAmount = self.speed * dt
		self.x = self.x + nx * moveAmount
		self.y = self.y + ny * moveAmount

		-- Check if we've hit the target
		if distance <= moveAmount + self.size + (self.target.size * gameState.map.cellSize / 2) then
			-- Deal damage to the enemy
			local killed = self.target:takeDamage(self.damage)

			-- Deactivate projectile since it hit
			self.active = false
			return true
		end
	end

	return false
end

-- Draw the projectile
-- @param gameState The current game state
function Projectile:draw(gameState)
	if not self.active then
		return
	end

	-- Set color
	love.graphics.setColor(unpack(self.color))

	-- Draw as a circle
	love.graphics.circle("fill", self.x, self.y, self.size)
end

return Projectile
