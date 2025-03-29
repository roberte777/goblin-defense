-- ProjectileManager.lua
-- Manages projectiles in the game with a free list for efficient memory usage

local Projectile = require("src.projectile.Projectile")

local ProjectileManager = {}
ProjectileManager.__index = ProjectileManager

-- Create a new ProjectileManager
-- @param maxProjectiles Maximum number of projectiles that can exist at once
function ProjectileManager.new(maxProjectiles)
	local self = setmetatable({}, ProjectileManager)

	self.maxProjectiles = maxProjectiles or 200 -- Default to 200 if not specified

	-- Active projectiles list
	self.projectiles = {}

	-- Free list - pool of reusable projectile objects
	self.freeList = {}

	-- Pre-allocate the free list with inactive projectiles
	for i = 1, self.maxProjectiles do
		table.insert(self.freeList, Projectile.new(0, 0, nil, 0, 0))
	end

	return self
end

-- Create or reuse a projectile from the free list
-- @param x Initial x position
-- @param y Initial y position
-- @param target Enemy target
-- @param damage Damage amount
-- @param speed Movement speed
-- @param size Size of the projectile
-- @return The created or reused projectile, or nil if none available
function ProjectileManager:createProjectile(x, y, target, damage, speed, size)
	-- Check if we have a free projectile
	if #self.freeList > 0 then
		-- Get a projectile from the free list
		local projectile = table.remove(self.freeList)

		-- Reset and initialize projectile properties
		projectile.x = x
		projectile.y = y
		projectile.target = target
		projectile.damage = damage
		projectile.speed = speed
		projectile.size = size or 4
		projectile.active = true

		-- Add to active projectiles
		table.insert(self.projectiles, projectile)
		return projectile
	elseif #self.projectiles < self.maxProjectiles then
		-- Free list is empty but we haven't reached max, create a new one
		local projectile = Projectile.new(x, y, target, damage, speed, size)
		table.insert(self.projectiles, projectile)
		return projectile
	end

	-- No projectiles available
	return nil
end

-- Update all active projectiles
-- @param dt Delta time
-- @param gameState The current game state
function ProjectileManager:update(dt, gameState)
	-- Update each projectile and track which ones to remove
	for i = #self.projectiles, 1, -1 do
		local projectile = self.projectiles[i]
		local shouldRemove = projectile:update(dt, gameState)

		if shouldRemove then
			-- Move the projectile from active list to free list
			table.remove(self.projectiles, i)

			-- Reset properties before adding to free list
			projectile.active = false
			projectile.target = nil

			-- Add to free list if we're not exceeding the max
			if #self.freeList < self.maxProjectiles then
				table.insert(self.freeList, projectile)
			end
		end
	end
end

-- Draw all active projectiles
-- @param gameState The current game state
function ProjectileManager:draw(gameState)
	for _, projectile in ipairs(self.projectiles) do
		projectile:draw(gameState)
	end
end

-- Get the number of active projectiles
-- @return The number of active projectiles
function ProjectileManager:getActiveCount()
	return #self.projectiles
end

-- Get the number of free projectiles
-- @return The number of free projectiles
function ProjectileManager:getFreeCount()
	return #self.freeList
end

return ProjectileManager
