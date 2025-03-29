-- @class Card
-- @field name string The name of the card
-- @field description string Description of what the card does
-- @field cost number The cost to play the card
-- @field rarity string The rarity of the card (common, uncommon, rare, etc.)
-- @field image string The path to the card's image
local Card = {}
Card.__index = Card

-- Create a new Card
-- @param name string The name of the card
-- @param description string Description of what the card does
-- @param cost number The cost to play the card
-- @param rarity string The rarity of the card
-- @param image string The path to the card's image (optional)
-- @return Card The created card
function Card.new(name, description, cost, rarity, image)
	local self = setmetatable({}, Card)

	self.name = name
	self.description = description
	self.cost = cost
	self.rarity = rarity
	self.image = image or "assets/cards/default.png" -- Default image if none provided

	-- Card dimensions
	self.width = 120
	self.height = 180

	-- Card states
	self.isSelected = false
	self.isHovered = false

	-- Card font sizes
	self.titleFontSize = 14
	self.costFontSize = 14
	self.descriptionFontSize = 10

	return self
end

-- Update the card state
-- @param dt number Delta time
-- @param gameState table The current game state
function Card:update(dt, gameState)
	-- Base update logic
	-- Child classes may extend this
end

-- Draw the card
-- @param x number The x-coordinate to draw at
-- @param y number The y-coordinate to draw at
-- @param scale number Scale factor for drawing (default: 1)
function Card:draw(x, y, scale)
	scale = scale or 1
	local width = self.width * scale
	local height = self.height * scale

	-- Save current graphics state
	local prevLineWidth = love.graphics.getLineWidth()

	-- Draw card background based on rarity
	if self.rarity == "common" then
		love.graphics.setColor(0.8, 0.8, 0.8)
	elseif self.rarity == "uncommon" then
		love.graphics.setColor(0.2, 0.8, 0.2)
	elseif self.rarity == "rare" then
		love.graphics.setColor(0.2, 0.2, 0.8)
	elseif self.rarity == "epic" then
		love.graphics.setColor(0.8, 0.2, 0.8)
	end

	-- Draw card outline (thicker if selected)
	if self.isSelected then
		love.graphics.setLineWidth(4)
		love.graphics.setColor(1, 1, 0)
	elseif self.isHovered then
		love.graphics.setLineWidth(2)
		love.graphics.setColor(1, 1, 1)
	else
		love.graphics.setLineWidth(1)
	end

	-- Draw card rectangle
	love.graphics.rectangle("fill", x, y, width, height, 10, 10) -- Rounded corners
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("line", x, y, width, height, 10, 10)

	-- Reset line width after drawing the outline
	love.graphics.setLineWidth(prevLineWidth)

	-- Store the default font
	local defaultFont = love.graphics.getFont()

	-- Set up coordinates for cost circle (moved up)
	local circleX = x + width / 2 -- Center horizontally
	local circleY = y + 15 * scale -- Position near the top
	local circleRadius = 12 * scale -- Make it a bit smaller

	-- Draw cost with smaller font
	love.graphics.setColor(1, 1, 1)
	love.graphics.circle("fill", circleX, circleY, circleRadius)
	love.graphics.setColor(0, 0, 0)

	-- Make cost font slightly smaller
	self.costFontSize = 12
	local costFont = love.graphics.newFont(self.costFontSize * scale)
	love.graphics.setFont(costFont)

	-- Calculate the vertical center for the cost based on font height
	local costFontHeight = costFont:getHeight()
	local costY = circleY - costFontHeight / 2

	-- Center the cost horizontally and vertically in the circle
	love.graphics.printf(tostring(self.cost), circleX - circleRadius, costY, circleRadius * 2, "center")

	-- Draw card name with smaller font, below the cost circle
	love.graphics.setColor(0, 0, 0)
	local titleFont = love.graphics.newFont(self.titleFontSize * scale)
	love.graphics.setFont(titleFont)
	local fontHeight = titleFont:getHeight()
	local titleY = circleY + circleRadius + 5 * scale -- Position below the cost circle

	-- Center the title on the whole card
	love.graphics.printf(self.name, x, titleY, width, "center")

	-- Draw description with smaller font
	love.graphics.setColor(0, 0, 0)
	local descFont = love.graphics.newFont(self.descriptionFontSize * scale)
	love.graphics.setFont(descFont)
	love.graphics.printf(self.description, x + 10, y + height - 60, width - 20, "center")

	-- Reset font to default
	love.graphics.setFont(defaultFont)

	-- Reset color
	love.graphics.setColor(1, 1, 1)
end

-- Check if the point is inside the card
-- @param pointX number The x-coordinate of the point
-- @param pointY number The y-coordinate of the point
-- @param cardX number The x-coordinate of the card
-- @param cardY number The y-coordinate of the card
-- @param scale number Scale factor for the card (default: 1)
-- @return boolean True if the point is inside the card
function Card:isPointInside(pointX, pointY, cardX, cardY, scale)
	scale = scale or 1
	local width = self.width * scale
	local height = self.height * scale

	return pointX >= cardX and pointX <= cardX + width and pointY >= cardY and pointY <= cardY + height
end

-- Called when the card is played
-- @param gameState table The current game state
-- @param x number The x-coordinate where the card is played (optional)
-- @param y number The y-coordinate where the card is played (optional)
-- @return boolean True if the card was played successfully
function Card:play(gameState, x, y)
	-- Base implementation, should be overridden by child classes
	print("Playing card: " .. self.name)
	gameState.needsPathRecalculation = true

	-- Deduct the cost
	-- gameState.player.resources = gameState.player.resources - self.cost

	return true -- Card played successfully
end

-- Called when the card is discarded
-- @param gameState table The current game state
function Card:discard(gameState)
	-- Base implementation, can be overridden by child classes
	print("Discarding card: " .. self.name)
end

-- Called when the card is upgraded
-- @return Card The upgraded card
function Card:upgrade()
	-- Base implementation, should be overridden by child classes
	print("Upgrading card: " .. self.name)

	-- Create an upgraded version of the card
	local upgradedCard = Card.new(self.name .. "+", self.description, self.cost, self.rarity, self.image)

	return upgradedCard
end

return Card
