-- @class Game
-- @field gameState table The game's state table containing map and other game elements
-- @field update fun(dt: number)
-- @field draw fun()
local Game = {}
Game.__index = Game

local Map = require("src.Map")
local ArcherTower = require("src.tower.ArcherTower")
local Path = require("src.Path")
local config = require("src.config")
local CardManager = require("src.card.CardManager")
local Deck = require("src.card.Deck")
local Hand = require("src.card.Hand")
local GameControlUI = require("src.ui.GameControlUI")
local GameFunctions = require("src.GameFunctions")
-- Add enemy requires
local BasicEnemy = require("src.enemy.BasicEnemy")
-- Add projectile requires
local ProjectileManager = require("src.projectile.ProjectileManager")

-- Define game states
local GameStates = {
	PRE_WAVE = "pre_wave", -- Building allowed, actions can be spent
	WAVE = "wave", -- Building not allowed, wave in progress
	POST_WAVE = "post_wave", -- Reward selection state
}

function Game.new()
	local self = setmetatable({}, Game)

	-- Calculate how many cells can fit in the virtual resolution
	local mapWidth = math.floor(config.virtual_width / 32)
	-- Limit map height to leave space for the card UI section
	local mapHeight = 16 -- Fixed at 16 cells tall to leave room for hand

	-- Initialize the game state table with map created directly
	self.gameState = {
		-- Map configuration
		map = Map.new(mapWidth, mapHeight),
		-- Tower management
		towers = {},
		-- Enemy management
		enemies = {},
		-- Projectile management
		projectileManager = ProjectileManager.new(200), -- Create with max of 200 projectiles
		-- Game state
		currentState = GameStates.PRE_WAVE, -- Start in pre-wave state
		-- Player resources
		player = {
			resources = 150, -- Starting resources
			health = 100, -- Starting health
			wave = 0, -- Current wave number
		},
		-- Card system
		cardManager = CardManager.new(),
		selectedCard = nil, -- Currently selected card
		placingTower = false, -- Whether we're placing a tower
	}

	-- Create the enemy path (from left to right across the map)
	local startX = 1
	local startY = math.floor(mapHeight / 2)
	local endX = mapWidth
	local endY = math.floor(mapHeight / 2)

	self.gameState.path = Path.new(self.gameState.map, startX, startY, endX, endY)

	-- Initialize the player's deck and hand
	self.gameState.deck = self.gameState.cardManager:createStarterDeck()
	self.gameState.hand = self.gameState.cardManager:createStarterHand()

	-- Initialize the game control UI
	self.gameControlUI = GameControlUI.new(config)

	-- Draw initial hand of 3 cards
	self.gameState.cardManager:dealCards(self.gameState.deck, self.gameState.hand, 3)

	-- Add a test archer tower at cell (6, 6)
	local testTower = ArcherTower.new(6, 6)
	table.insert(self.gameState.towers, testTower)

	return self
end

function Game:update(dt)
	-- Game update logic

	-- Get virtual mouse position using GameFunctions
	local mouseX, mouseY = GameFunctions.getVirtualMousePosition(config)

	-- Convert to grid coordinates
	local gridX, gridY = self.gameState.map:pixelToGrid(mouseX, mouseY)

	-- Update the hovered cell
	self.gameState.map:setHoveredCell(gridX, gridY)

	-- Update all towers
	for _, tower in ipairs(self.gameState.towers) do
		tower:update(dt, self.gameState)
	end

	-- Update all enemies
	for i = #self.gameState.enemies, 1, -1 do
		local enemy = self.gameState.enemies[i]
		enemy:update(dt, self.gameState)

		-- Remove dead or enemies that reached the end
		if enemy:isDead() or enemy:hasReachedEnd() then
			table.remove(self.gameState.enemies, i)
		end
	end

	-- Update all projectiles
	self.gameState.projectileManager:update(dt, self.gameState)

	-- State-specific updates
	if self.gameState.currentState == GameStates.PRE_WAVE then
		self:updatePreWaveState(dt)
	elseif self.gameState.currentState == GameStates.WAVE then
		self:updateWaveState(dt)
	elseif self.gameState.currentState == GameStates.POST_WAVE then
		self:updatePostWaveState(dt)
	end

	-- Shared updates for all states
	if self.gameState.needsPathRecalculation then
		print("Recalculating path")
		self.gameState.path:updatePath(self.gameState.map.hoveredCell.x, self.gameState.map.hoveredCell.y)
		self.gameState.needsPathRecalculation = false
	end
end

-- Update logic specific to pre-wave state
function Game:updatePreWaveState(dt)
	-- Update hand cards
	self.gameState.hand:update(dt, self.gameState)

	-- Update hover states for cards in the hand and UI controls
	self.gameControlUI:updateHoverStates(self.gameState.hand, self.gameState)
end

-- Update logic specific to wave state
function Game:updateWaveState(dt)
	-- Only allow limited card interactions during wave
	self.gameState.hand:update(dt, self.gameState)
	self.gameControlUI:updateHoverStates(self.gameState.hand, self.gameState)

	-- Handle wave spawning logic
	if self.gameState.waveData then
		local wave = self.gameState.waveData

		-- Update spawn timer
		wave.spawnTimer = wave.spawnTimer + dt

		-- Spawn enemies at intervals until we've spawned all for this wave
		if wave.spawnedEnemies < wave.totalEnemies and wave.spawnTimer >= wave.spawnInterval then
			if self:spawnEnemy() then
				wave.spawnedEnemies = wave.spawnedEnemies + 1
				wave.spawnTimer = 0
			end
		end

		-- Check if wave is complete (all enemies spawned and none left alive)
		if wave.spawnedEnemies >= wave.totalEnemies and #self.gameState.enemies == 0 and not wave.waveComplete then
			wave.waveComplete = true
			-- Transition to post-wave state
			self:transitionToState(GameStates.POST_WAVE)
		end
	end
end

-- Update logic specific to post-wave state
function Game:updatePostWaveState(dt)
	-- Minimal updates during reward state
	-- Most interaction happens through keypresses
end

function Game:draw()
	-- Clear the screen with a background color
	love.graphics.setColor(0.1, 0.1, 0.1)
	love.graphics.rectangle("fill", 0, 0, config.virtual_width, config.virtual_height)

	-- Draw the map with grid lines
	self.gameState.map:draw(true)

	-- Draw the path
	self.gameState.path:draw()

	-- Draw all towers
	for _, tower in ipairs(self.gameState.towers) do
		tower:draw(self.gameState)
	end

	-- Draw all enemies
	for _, enemy in ipairs(self.gameState.enemies) do
		enemy:draw(self.gameState)
	end

	-- Draw all projectiles
	self.gameState.projectileManager:draw(self.gameState)

	-- Draw game status in the top-left corner
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Wave: " .. self.gameState.player.wave, 10, 10)
	love.graphics.print("Health: " .. self.gameState.player.health, 10, 30)
	love.graphics.print("Enemies: " .. #self.gameState.enemies, 10, 50)
	love.graphics.print("State: " .. self.gameState.currentState, 10, 70)

	-- State-specific drawing
	if self.gameState.currentState == GameStates.PRE_WAVE then
		self:drawPreWaveState()
	elseif self.gameState.currentState == GameStates.WAVE then
		self:drawWaveState()
	elseif self.gameState.currentState == GameStates.POST_WAVE then
		self:drawPostWaveState()
	end

	-- Draw game control UI (hand, deck, resources)
	self.gameControlUI:draw(self.gameState.hand, self.gameState.deck, self.gameState)
end

-- Draw specific elements for pre-wave state
function Game:drawPreWaveState()
	-- Draw tower placement preview if placing a tower
	if self.gameState.placingTower and self.gameState.selectedCard then
		-- Draw a preview of the tower at the hovered cell
		local cell = self.gameState.map.hoveredCell

		if cell then
			local pixelX, pixelY = self.gameState.map:gridToPixel(cell.x, cell.y)
			love.graphics.setColor(1, 1, 1, 0.5)
			love.graphics.rectangle("fill", pixelX, pixelY, self.gameState.map.cellSize, self.gameState.map.cellSize)
		end
	end

	-- Note: "Press SPACE to start wave" prompt removed as it's now shown in the UI control panel
end

-- Draw specific elements for wave state
function Game:drawWaveState()
	-- Draw wave status info
	if self.gameState.waveData then
		local wave = self.gameState.waveData
		love.graphics.setColor(1, 0.7, 0.3)
		love.graphics.printf(
			"Wave " .. self.gameState.player.wave .. " - Enemies: " .. wave.spawnedEnemies .. "/" .. wave.totalEnemies,
			0,
			config.virtual_height - 80,
			config.virtual_width,
			"center"
		)
	end
end

-- Draw specific elements for post-wave state
function Game:drawPostWaveState()
	-- Darken the background
	love.graphics.setColor(0, 0, 0, 0.7)
	love.graphics.rectangle("fill", 0, 0, config.virtual_width, config.virtual_height)

	-- Draw title
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf("SELECT YOUR REWARD", 0, 100, config.virtual_width, "center")

	-- Draw reward cards if available
	if self.gameState.rewards then
		local cardSpacing = 200
		local startX = (config.virtual_width - ((#self.gameState.rewards - 1) * cardSpacing)) / 2
		local cardY = 200

		for i, card in ipairs(self.gameState.rewards) do
			local cardX = startX + (i - 1) * cardSpacing
			card:draw(cardX, cardY, 1) -- Add the scale parameter (1 = normal size)

			-- Draw selection indicator
			love.graphics.setColor(1, 1, 1)
			love.graphics.print("Press " .. i .. " to select", cardX + 20, cardY + 200)
		end
	end
end

function Game:mousepressed(x, y, button)
	-- Get virtual mouse position using GameFunctions
	local mouseX, mouseY = GameFunctions.getVirtualMousePosition(config)

	-- Convert to grid coordinates
	local gridX, gridY = self.gameState.map:pixelToGrid(mouseX, mouseY)

	-- Different mouse handling based on current state
	if self.gameState.currentState == GameStates.PRE_WAVE then
		self:mouseHandlePreWave(mouseX, mouseY, gridX, gridY, button)
	elseif self.gameState.currentState == GameStates.WAVE then
		self:mouseHandleWave(mouseX, mouseY, gridX, gridY, button)
	end
end

-- Handle mouse interaction during pre-wave state
function Game:mouseHandlePreWave(mouseX, mouseY, gridX, gridY, button)
	-- Check if we clicked on the start wave button
	if button == 1 and self.gameControlUI:isMouseOverStartButton(self.gameState) then
		self:startWave()
		return
	end

	-- Check if we clicked on a card in the hand
	local cardIndex = self.gameControlUI:getCardIndexAtPosition(self.gameState.hand, self.gameState)

	if button == 1 then -- Left mouse button
		if cardIndex then
			-- We clicked on a card
			local card = self.gameState.hand:getCard(cardIndex)

			-- Select the card
			self.gameState.selectedCard = cardIndex

			-- If it's a tower card, enter placement mode
			if card and card.towerType then
				self.gameState.placingTower = true
				print("Selected tower card: " .. card.name)
			else
				-- For other cards, play them immediately
				self.gameState.cardManager:playCard(self.gameState.hand, self.gameState.deck, cardIndex, self.gameState)
			end
		elseif self.gameState.placingTower and self.gameState.selectedCard then
			-- We're placing a tower card
			local success = self.gameState.cardManager:playCard(
				self.gameState.hand,
				self.gameState.deck,
				self.gameState.selectedCard,
				self.gameState,
				gridX,
				gridY
			)

			if success then
				-- Reset state after placing
				self.gameState.placingTower = false
				self.gameState.selectedCard = nil
				print("Placed tower at " .. gridX .. ", " .. gridY)
			else
				print("Cannot place tower here")
			end
		end
	elseif button == 2 then -- Right mouse button
		if self.gameState.placingTower then
			-- Cancel tower placement
			self.gameState.placingTower = false
			self.gameState.selectedCard = nil
			print("Cancelled tower placement")
		else
			-- Set the clicked cell to empty
			self.gameState.map:setCell(gridX, gridY, "empty")

			-- Update the path
			self.gameState.path:updatePath(gridX, gridY)
		end
	end
end

-- Handle mouse interaction during wave state
function Game:mouseHandleWave(mouseX, mouseY, gridX, gridY, button)
	-- Limited interaction during wave
	if button == 1 then -- Left mouse button
		-- Check if we clicked on a non-tower card in the hand
		local cardIndex = self.gameControlUI:getCardIndexAtPosition(self.gameState.hand, self.gameState)

		if cardIndex then
			local card = self.gameState.hand:getCard(cardIndex)
			-- Only allow non-tower cards during wave
			if card and not card.towerType then
				self.gameState.cardManager:playCard(self.gameState.hand, self.gameState.deck, cardIndex, self.gameState)
			else
				print("Cannot place towers during a wave!")
			end
		end
	end
end

-- Handle key presses based on current state
function Game:keypressed(key)
	if self.gameState.currentState == GameStates.PRE_WAVE then
		if key == "space" then
			self:startWave()
		elseif key == "e" then
			-- Test key to spawn a single enemy
			self:spawnEnemy()
			print("Test enemy spawned")
		end
	elseif self.gameState.currentState == GameStates.POST_WAVE then
		-- Handle reward selection
		if self.gameState.rewards then
			local index = tonumber(key)
			if index and index >= 1 and index <= #self.gameState.rewards then
				self:selectReward(index)
			end
		end
	end
end

-- Transition to a new game state
function Game:transitionToState(newState)
	print("Transitioning from " .. self.gameState.currentState .. " to " .. newState)

	-- Handle exit actions from current state
	if self.gameState.currentState == GameStates.PRE_WAVE then
		-- Nothing special needed when exiting pre-wave
	elseif self.gameState.currentState == GameStates.WAVE then
		-- Cleanup after wave ends
		self.gameState.waveData.waveComplete = true
	elseif self.gameState.currentState == GameStates.POST_WAVE then
		-- Clear rewards when exiting post-wave
		self.gameState.rewards = nil
	end

	-- Set the new state
	self.gameState.currentState = newState

	-- Handle enter actions for new state
	if newState == GameStates.PRE_WAVE then
		-- Reset placement state
		self.gameState.placingTower = false
		self.gameState.selectedCard = nil

		-- Draw a new hand for the next wave
		self:drawNewHand(3)
	elseif newState == GameStates.WAVE then
		-- Wave setup already handled in startWave()
	elseif newState == GameStates.POST_WAVE then
		-- Generate rewards based on wave difficulty
		self:generateRewards()
	end
end

-- Handle drawing a new hand at the start of a turn
function Game:drawNewHand(cardCount)
	cardCount = cardCount or 3 -- Default to 3 cards

	-- First discard any remaining cards
	self.gameState.cardManager:discardFromHand(self.gameState.hand, self.gameState.deck, self.gameState)

	-- Then draw a new hand
	self.gameState.cardManager:dealCards(self.gameState.deck, self.gameState.hand, cardCount)
end

-- Start a new wave
function Game:startWave()
	-- Increment wave counter
	self.gameState.player.wave = self.gameState.player.wave + 1

	-- Change game state
	self:transitionToState(GameStates.WAVE)

	-- Set up enemy spawning for this wave
	self.gameState.waveData = {
		totalEnemies = 5 + (self.gameState.player.wave * 2), -- More enemies per wave
		spawnedEnemies = 0,
		spawnTimer = 0,
		spawnInterval = 1.5, -- Seconds between enemy spawns
		waveComplete = false,
	}

	print("Starting wave " .. self.gameState.player.wave)
end

-- Spawn a new enemy at the start of the path
function Game:spawnEnemy()
	if not self.gameState.path then
		return false
	end

	-- Get the start position from the path
	local startX = self.gameState.path.startX
	local startY = self.gameState.path.startY

	-- Convert grid position to center pixel coordinates
	local startPixelX, startPixelY = GameFunctions.getCellCenterPixels(self.gameState.map, startX, startY)

	-- Create a new basic enemy with pixel coordinates
	local enemy = BasicEnemy.new(startPixelX, startPixelY)

	-- Scale difficulty based on wave number
	if self.gameState.player.wave > 1 then
		-- Increase health by 5 per wave
		enemy.health = enemy.health + ((self.gameState.player.wave - 1) * 5)
		enemy.maxHealth = enemy.health

		-- Slightly increase speed after wave 3
		if self.gameState.player.wave > 3 then
			enemy.speed = enemy.speed * (1 + (self.gameState.player.wave - 3) * 0.1)
		end
	end

	-- Add enemy to the game
	table.insert(self.gameState.enemies, enemy)
	return true
end

-- Generate rewards after completing a wave
function Game:generateRewards()
	-- Generate rewards based on wave difficulty
	local quality = math.min(0.1 + (self.gameState.player.wave * 0.05), 0.9)

	-- Create reward cards (assuming this function exists in CardManager)
	-- self.gameState.rewards = self.gameState.cardManager:generateRewardCards(quality, 3)

	print("Wave " .. self.gameState.player.wave .. " completed! Choose a reward.")
end

-- Select a reward card and add it to the deck
function Game:selectReward(index)
	if self.gameState.rewards and self.gameState.rewards[index] then
		local card = self.gameState.rewards[index]

		-- Add the card to the deck
		self.gameState.deck:addCard(card, "random")

		-- Transition back to pre-wave state
		self:transitionToState(GameStates.PRE_WAVE)

		print("Added " .. card.name .. " to your deck!")
	end
end

return Game
