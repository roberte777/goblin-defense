local Card = require("src.card.Card")
local TowerCard = setmetatable({}, { __index = Card })
TowerCard.__index = TowerCard

-- Create a new Tower Card with default values
-- @return TowerCard The created tower card
function TowerCard.new()
	local self = Card.new(
		"Tower",
		"Creates a basic tower to defend against goblins",
		50, -- default cost
		"common", -- default rarity
		"assets/cards/tower.png" -- default image
	)
	setmetatable(self, TowerCard)

	self.towerType = "archer" -- Default tower type
	self.towerStats = {
		damage = 10,
		range = 120,
		attackSpeed = 1.0,
	}

	-- Tower stats font size
	self.statsFontSize = 10

	return self
end

-- Draw the tower card with tower-specific details
-- @param x number The x-coordinate to draw at
-- @param y number The y-coordinate to draw at
-- @param scale number Scale factor for drawing (default: 1)
function TowerCard:draw(x, y, scale)
	-- Call the parent draw method first
	Card.draw(self, x, y, scale)

	scale = scale or 1
	local width = self.width * scale
	local height = self.height * scale

	-- Add tower-specific visuals (tower icon in the middle)
	love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
	love.graphics.rectangle("fill", x + width / 4, y + height / 3, width / 2, width / 2, 5, 5)

	-- Store the default font
	local defaultFont = love.graphics.getFont()

	-- Set smaller font for tower stats
	local statsFont = love.graphics.newFont(self.statsFontSize * scale)
	love.graphics.setFont(statsFont)

	-- Show tower stats
	local statsY = y + height / 3 + width / 2 + 10
	love.graphics.setColor(0, 0, 0)
	if self.towerStats.damage then
		love.graphics.printf("DMG: " .. self.towerStats.damage, x + 10, statsY, width - 20, "left")
	end
	if self.towerStats.range then
		love.graphics.printf("RNG: " .. self.towerStats.range, x + 10, statsY + 15 * scale, width - 20, "left")
	end
	if self.towerStats.attackSpeed then
		love.graphics.printf("SPD: " .. self.towerStats.attackSpeed, x + 10, statsY + 30 * scale, width - 20, "left")
	end

	-- Reset font to default
	love.graphics.setFont(defaultFont)

	-- Reset color
	love.graphics.setColor(1, 1, 1)
end

-- Called when the tower card is played
-- @param gameState table The current game state
-- @param x number The x grid coordinate where the tower is placed
-- @param y number The y grid coordinate where the tower is placed
-- @return boolean True if the tower was placed successfully
function TowerCard:play(gameState, x, y)
	-- Check if the location is valid
	local cell = gameState.map:getCell(x, y)
	if not cell then
		print("Cannot place tower outside the map")
		return false
	end

	-- Use GameFunctions to check if square is available
	local GameFunctions = require("src.GameFunctions")
	if not GameFunctions.isSquareAvailable(gameState.map, x, y) then
		print("Cannot place tower on this cell type: " .. cell.type)
		return false
	end

	-- Create the tower
	local ArcherTower = require("src.tower.ArcherTower")
	local tower = ArcherTower.new(x, y)

	-- Apply the default stats from the card
	tower.damage = self.towerStats.damage
	tower.range = self.towerStats.range
	tower.attackSpeed = self.towerStats.attackSpeed

	-- Add the tower to the game
	table.insert(gameState.towers, tower)

	-- Mark the cell as occupied
	cell.type = "tower"
	cell.occupant = tower

	-- Trigger path recalculation
	if gameState.path then
		gameState.path:updatePath()
	end

	-- Call the parent play method to handle resources etc.
	return Card.play(self, gameState, x, y)
end

-- Called when the tower card is upgraded
-- @return TowerCard The upgraded tower card
function TowerCard:upgrade()
	-- Create an upgraded version with better stats
	local upgradedCard = TowerCard.new()

	-- Customize the upgraded version
	upgradedCard.name = self.name .. "+"
	upgradedCard.description = self.description .. " (Upgraded)"
	upgradedCard.towerStats = {
		damage = math.floor(self.towerStats.damage * 1.2),
		range = math.floor(self.towerStats.range * 1.2),
		attackSpeed = math.floor(self.towerStats.attackSpeed * 1.2),
	}

	return upgradedCard
end

return TowerCard
