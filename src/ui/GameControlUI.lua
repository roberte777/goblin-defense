-- @class GameControlUI
-- Handles the UI elements for the game controls, including hand and deck
local GameControlUI = {}
GameControlUI.__index = GameControlUI

-- Create a new GameControlUI
-- @param config table Configuration parameters for the game
-- @return GameControlUI The created UI controller
function GameControlUI.new(config)
	local self = setmetatable({}, GameControlUI)

	-- UI section properties
	self.sectionHeight = 202 -- Height of the control section
	self.sectionY = config.virtual_height - self.sectionHeight

	-- Card rendering properties
	self.cardScale = 0.7 -- Scale for drawing cards in the UI
	self.cardSpacing = 140 -- Space between cards

	-- Calculate the vertical center for cards
	local cardHeight = 180 * self.cardScale -- Scaled card height
	local sectionCenterY = self.sectionY + (self.sectionHeight / 2)
	self.handY = sectionCenterY - (cardHeight / 2) -- Center the card in the section

	-- Hover effect
	self.hoveredOffsetY = 25 -- How much to elevate hovered cards

	-- Game controls section (left side)
	self.controlsX = 40
	self.controlsY = self.sectionY + 30
	self.controlsWidth = 180
	self.controlsHeight = 140

	-- Hand section (middle)
	-- Will be calculated dynamically in drawHand

	-- Deck visualization position (right side of the UI area)
	self.deckX = config.virtual_width - 140
	self.deckY = self.sectionY + (self.sectionHeight / 2) - 40 -- Center relative to hand section

	-- Fonts for UI elements
	self.titleFont = love.graphics.newFont(16)
	self.countFont = love.graphics.newFont(14)
	self.resourceFont = love.graphics.newFont(18)
	self.buttonFont = love.graphics.newFont(16)

	return self
end

-- Draw the UI section at the bottom of the screen
-- @param gameState table The current game state
function GameControlUI:drawSection(gameState)
	local config = require("src.config")

	-- Draw UI section background with gradient effect
	love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
	love.graphics.rectangle("fill", 0, self.sectionY, config.virtual_width, self.sectionHeight)

	-- Draw a subtle gradient overlay
	local gradient = {
		{ 0, self.sectionY, config.virtual_width, 0, 0.2, 0.2, 0.2, 0.7 },
		{ 0, self.sectionY + self.sectionHeight, config.virtual_width, 0, 0.1, 0.1, 0.1, 0.7 },
	}

	for _, points in ipairs(gradient) do
		love.graphics.setColor(points[5], points[6], points[7], points[8])
		love.graphics.rectangle("fill", points[1], points[2], points[3], 20)
	end

	-- Draw divider line
	love.graphics.setColor(0.4, 0.4, 0.4)
	love.graphics.setLineWidth(2)
	love.graphics.line(0, self.sectionY, config.virtual_width, self.sectionY)

	-- Reset color
	love.graphics.setColor(1, 1, 1)
end

-- Draw the game controls on the left side
-- @param gameState table The current game state
function GameControlUI:drawGameControls(gameState)
	-- Draw controls box
	love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
	love.graphics.rectangle("fill", self.controlsX, self.controlsY, self.controlsWidth, self.controlsHeight, 5, 5)

	-- Draw outline
	love.graphics.setColor(0.5, 0.5, 0.5)
	love.graphics.rectangle("line", self.controlsX, self.controlsY, self.controlsWidth, self.controlsHeight, 5, 5)

	-- Save current font
	local prevFont = love.graphics.getFont()
	love.graphics.setFont(self.titleFont)

	-- Title
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("GAME CONTROLS", self.controlsX + 10, self.controlsY + 10)

	-- Wave info
	love.graphics.setFont(self.countFont)
	love.graphics.print("Wave: " .. gameState.player.wave, self.controlsX + 10, self.controlsY + 40)

	-- Wave state/button
	if gameState.currentState == "pre_wave" then
		-- Draw start wave button
		love.graphics.setColor(0.2, 0.6, 0.2)
		love.graphics.rectangle("fill", self.controlsX + 10, self.controlsY + 70, 160, 40, 5, 5)
		love.graphics.setColor(0.8, 1, 0.8)
		love.graphics.rectangle("line", self.controlsX + 10, self.controlsY + 70, 160, 40, 5, 5)

		love.graphics.setColor(1, 1, 1)
		love.graphics.setFont(self.buttonFont)
		love.graphics.printf("START WAVE", self.controlsX + 10, self.controlsY + 82, 160, "center")
	elseif gameState.currentState == "wave" then
		love.graphics.print(
			"Enemies: " .. gameState.waveData.spawnedEnemies .. "/" .. gameState.waveData.totalEnemies,
			self.controlsX + 10,
			self.controlsY + 60
		)
		-- Show wave progress
		love.graphics.setColor(0.8, 0.4, 0.3)
		if gameState.waveData then
			local percent = gameState.waveData.spawnedEnemies / gameState.waveData.totalEnemies
			love.graphics.rectangle("fill", self.controlsX + 10, self.controlsY + 90, 160 * percent, 40, 5, 5)
		end

		love.graphics.setColor(1, 0.6, 0.4)
		love.graphics.rectangle("line", self.controlsX + 10, self.controlsY + 90, 160, 40, 5, 5)

		love.graphics.setColor(1, 1, 1)
		love.graphics.setFont(self.buttonFont)

		if gameState.waveData then
			local text = "WAVE IN PROGRESS"
			if gameState.waveData.spawnedEnemies == gameState.waveData.totalEnemies then
				text = "DEFEAT ALL ENEMIES"
			end
			love.graphics.printf(text, self.controlsX + 10, self.controlsY + 98, 160, "center")
		end
	elseif gameState.currentState == "post_wave" then
		-- Show wave complete
		love.graphics.setColor(0.3, 0.3, 0.8)
		love.graphics.rectangle("fill", self.controlsX + 10, self.controlsY + 70, 160, 40, 5, 5)
		love.graphics.setColor(0.5, 0.5, 1)
		love.graphics.rectangle("line", self.controlsX + 10, self.controlsY + 70, 160, 40, 5, 5)

		love.graphics.setColor(1, 1, 1)
		love.graphics.setFont(self.buttonFont)
		love.graphics.printf("WAVE COMPLETE", self.controlsX + 10, self.controlsY + 82, 160, "center")
	end

	-- Draw resources
	self:drawResources(gameState)

	-- Restore previous font
	love.graphics.setFont(prevFont)
end

-- Draw the hand of cards
-- @param hand Hand The player's hand object
-- @param gameState table The current game state
function GameControlUI:drawHand(hand, gameState)
	local config = require("src.config")

	-- Calculate center position for cards in the center section
	local totalWidth = (hand:getCount() - 1) * self.cardSpacing
	local startX = (config.virtual_width - totalWidth) / 2

	-- Draw the hand
	hand:draw(startX, self.handY, self.cardSpacing, self.cardScale, self.hoveredOffsetY)
end

-- Draw the deck visualization
-- @param deck Deck The player's deck object
-- @param gameState table The current game state
function GameControlUI:drawDeck(deck, gameState)
	if not deck then
		return
	end

	-- Draw a decorative card stack for the deck (right side)
	local deckHeight = 80
	local deckWidth = 100

	-- Styles for the deck visualization
	love.graphics.setColor(0.3, 0.3, 0.3)
	love.graphics.rectangle("fill", self.deckX, self.deckY, deckWidth, deckHeight, 5, 5)

	-- Add a stack effect with offset rectangles
	love.graphics.setColor(0.4, 0.4, 0.4)
	love.graphics.rectangle("fill", self.deckX - 3, self.deckY - 3, deckWidth, deckHeight, 5, 5)
	love.graphics.setColor(0.5, 0.5, 0.5)
	love.graphics.rectangle("fill", self.deckX - 6, self.deckY - 6, deckWidth, deckHeight, 5, 5)

	-- Draw deck outline
	love.graphics.setColor(0.6, 0.6, 0.6)
	love.graphics.rectangle("line", self.deckX, self.deckY, deckWidth, deckHeight, 5, 5)

	-- Save current font
	local prevFont = love.graphics.getFont()

	-- Draw deck counts
	love.graphics.setColor(1, 1, 1)
	love.graphics.setFont(self.titleFont)
	love.graphics.print("DECK", self.deckX + 5, self.deckY + 5)

	love.graphics.setFont(self.countFont)
	love.graphics.print("Cards: " .. deck:getCount(), self.deckX + 10, self.deckY + 25)
	love.graphics.print("Discard: " .. deck:getDiscardCount(), self.deckX + 10, self.deckY + 45)

	-- Restore previous font
	love.graphics.setFont(prevFont)
end

-- Draw resources and other player info
-- @param gameState table The current game state
function GameControlUI:drawResources(gameState)
	local resources = gameState.player.resources or 0

	-- Save current font
	local prevFont = love.graphics.getFont()

	-- Draw resources
	love.graphics.setFont(self.resourceFont)
	love.graphics.setColor(1, 0.8, 0.2)
	love.graphics.print("Resources: " .. resources, self.controlsX + 10, self.controlsY - 30)

	-- Restore previous font
	love.graphics.setFont(prevFont)

	-- Reset color
	love.graphics.setColor(1, 1, 1)
end

-- Draw the entire game control UI (section, hand, deck, resources)
-- @param hand Hand The player's hand object
-- @param deck Deck The player's deck object
-- @param gameState table The current game state
function GameControlUI:draw(hand, deck, gameState)
	-- Draw the background section
	self:drawSection(gameState)

	-- Draw the game controls on the left
	self:drawGameControls(gameState)

	-- Draw the hand of cards in the center
	self:drawHand(hand, gameState)

	-- Draw the deck visualization on the right
	self:drawDeck(deck, gameState)
end

-- Update the hover states for cards in the hand
-- @param hand Hand The player's hand object
-- @param gameState table The current game state
function GameControlUI:updateHoverStates(hand, gameState)
	-- Get mouse position
	local mouseX, mouseY = love.mouse.getPosition()

	-- Convert screen coordinates to virtual coordinates
	local config = require("src.config")
	mouseX = (mouseX - config.offset_x) / config.scale_x
	mouseY = (mouseY - config.offset_y) / config.scale_y

	-- Calculate position for cards (centered)
	local totalWidth = (hand:getCount() - 1) * self.cardSpacing
	local startX = (config.virtual_width - totalWidth) / 2

	-- Update hover states for cards in hand
	hand:updateHoverStates(mouseX, mouseY, startX, self.handY, self.cardSpacing, self.cardScale)

	-- Check if start wave button is hovered
	if gameState.currentState == "pre_wave" then
		if
			mouseX >= self.controlsX + 10
			and mouseX <= self.controlsX + 170
			and mouseY >= self.controlsY + 70
			and mouseY <= self.controlsY + 110
		then
			self.startButtonHovered = true
		else
			self.startButtonHovered = false
		end
	else
		self.startButtonHovered = false
	end
end

-- Get the index of the card at the current mouse position
-- @param hand Hand The player's hand object
-- @param gameState table The current game state
-- @return number The index of the card under the cursor, or nil if none
function GameControlUI:getCardIndexAtPosition(hand, gameState)
	-- Get mouse position
	local mouseX, mouseY = love.mouse.getPosition()

	-- Convert screen coordinates to virtual coordinates
	local config = require("src.config")
	mouseX = (mouseX - config.offset_x) / config.scale_x
	mouseY = (mouseY - config.offset_y) / config.scale_y

	-- Calculate position for cards (centered)
	local totalWidth = (hand:getCount() - 1) * self.cardSpacing
	local startX = (config.virtual_width - totalWidth) / 2

	-- Get the card at position
	return hand:getCardIndexAtPosition(mouseX, mouseY, startX, self.handY, self.cardSpacing, self.cardScale)
end

-- Check if the mouse is over the UI section
-- @return boolean True if mouse is over the UI section
function GameControlUI:isMouseOverSection()
	-- Get mouse position
	local mouseX, mouseY = love.mouse.getPosition()

	-- Convert screen coordinates to virtual coordinates
	local config = require("src.config")
	mouseX = (mouseX - config.offset_x) / config.scale_x
	mouseY = (mouseY - config.offset_y) / config.scale_y

	-- Check if mouse is within the UI section area
	return mouseY >= self.sectionY
end

-- Check if mouse is over the start wave button
-- @return boolean True if mouse is over the start wave button and it's pre-wave state
function GameControlUI:isMouseOverStartButton(gameState)
	if gameState.currentState ~= "pre_wave" then
		return false
	end

	-- Get mouse position
	local mouseX, mouseY = love.mouse.getPosition()

	-- Convert screen coordinates to virtual coordinates
	local config = require("src.config")
	mouseX = (mouseX - config.offset_x) / config.scale_x
	mouseY = (mouseY - config.offset_y) / config.scale_y

	-- Check if mouse is over the start wave button
	return mouseX >= self.controlsX + 10
		and mouseX <= self.controlsX + 170
		and mouseY >= self.controlsY + 70
		and mouseY <= self.controlsY + 110
end

-- Set custom fonts for the UI elements
-- @param titleFont Font The font for titles
-- @param countFont Font The font for counts
-- @param resourceFont Font The font for resource display
function GameControlUI:setFonts(titleFont, countFont, resourceFont)
	self.titleFont = titleFont or self.titleFont
	self.countFont = countFont or self.countFont
	self.resourceFont = resourceFont or self.resourceFont
end

return GameControlUI
