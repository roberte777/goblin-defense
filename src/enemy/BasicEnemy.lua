-- BasicEnemy.lua
-- A simple enemy that follows the path

local Enemy = require("src.enemy.Enemy")

local BasicEnemy = {}
BasicEnemy.__index = BasicEnemy
setmetatable(BasicEnemy, { __index = Enemy })

-- Create a new BasicEnemy object
-- @param pixelX Initial x position in pixel coordinates
-- @param pixelY Initial y position in pixel coordinates
-- @param health Optional health points (defaults to 10)
-- @param speed Optional movement speed (defaults to 1)
function BasicEnemy.new(pixelX, pixelY, health, speed)
	-- Set default values
	health = health or 10
	speed = speed or 1.5 -- Slightly faster default speed

	-- Create a new instance using the Enemy constructor
	local self = Enemy.new(pixelX, pixelY, health, speed)

	-- Set up BasicEnemy specifics
	setmetatable(self, BasicEnemy)
	self.color = { 0.8, 0.2, 0.2 } -- Slightly darker red
	self.size = 0.7 -- Slightly smaller

	return self
end

-- BasicEnemy update may add specific behavior in the future
function BasicEnemy:update(dt, gameState)
	-- Call the parent class update method
	Enemy.update(self, dt, gameState)

	-- Add any BasicEnemy-specific update logic here
	-- For now, BasicEnemy just follows the path without special behavior
end

-- BasicEnemy draw may add specific visuals in the future
function BasicEnemy:draw(gameState)
	-- Call the parent class draw method
	Enemy.draw(self, gameState)

	-- Add any BasicEnemy-specific draw logic here
	-- For example, we could add eyes or other visual elements later
end

return BasicEnemy
