-- @class CardManager
-- @field cards table Table of all available cards
local CardManager = {}
CardManager.__index = CardManager

local Card = require("src.card.Card")
local TowerCard = require("src.card.TowerCard")
local WallCard = require("src.card.WallCard")
local Deck = require("src.card.Deck")
local Hand = require("src.card.Hand")

-- Create a new CardManager
-- @return CardManager The created card manager
function CardManager.new()
	local self = setmetatable({}, CardManager)

	-- Initialize with all available cards (simple list)
	self.cards = {}

	-- Populate with predefined cards
	self:initializeCards()

	return self
end

-- Initialize available cards
function CardManager:initializeCards()
	-- Add tower cards
	table.insert(self.cards, TowerCard.new())
	table.insert(self.cards, TowerCard.new())
	table.insert(self.cards, TowerCard.new())
	table.insert(self.cards, TowerCard.new())

	-- Add wall cards
	table.insert(self.cards, WallCard.new())
	table.insert(self.cards, WallCard.new())

	-- Add more cards as needed
end

-- Create a starter deck
-- @return Deck The created starter deck
function CardManager:createStarterDeck()
	local starterCards = {
		-- Add 3 basic archer towers
		TowerCard.new(),
		TowerCard.new(),
		TowerCard.new(),
		-- Add 2 basic walls
		WallCard.new(),
		WallCard.new(),
	}

	return Deck.new(starterCards)
end

-- Create a custom deck with specified cards
-- @param cardList table List of cards to include in the deck
-- @return Deck The created custom deck
function CardManager:createCustomDeck(cardList)
	return Deck.new(cardList)
end

-- Create a starter hand (empty)
-- @return Hand The created hand
function CardManager:createStarterHand()
	return Hand.new()
end

-- Deal cards from deck to hand
-- @param deck Deck The deck to draw from
-- @param hand Hand The hand to deal to
-- @param count number The number of cards to deal
-- @return table The cards that were drawn
function CardManager:dealCards(deck, hand, count)
	-- Draw cards from the deck
	local drawnCards = deck:draw(count)

	-- Add each drawn card to the hand
	for _, card in ipairs(drawnCards) do
		hand:addCard(card)
	end

	return drawnCards
end

-- Discard cards from hand to discard pile
-- @param hand Hand The hand to discard from
-- @param deck Deck The deck containing the discard pile
-- @param gameState table The current game state
-- @param indices table Array of indices to discard (optional, discards all if nil)
function CardManager:discardFromHand(hand, deck, gameState, indices)
	local discarded = {}

	if indices then
		-- Sort indices in descending order to avoid shifting issues
		table.sort(indices, function(a, b)
			return a > b
		end)

		-- Discard specific cards
		for _, index in ipairs(indices) do
			local card = hand:discardCard(index, gameState)
			if card then
				table.insert(discarded, card)
			end
		end
	else
		-- Discard all cards
		discarded = hand:discardAll(gameState)
	end

	-- Add discarded cards to the deck's discard pile
	deck:discardMultiple(discarded)

	return discarded
end

-- Handle playing a card from hand
-- @param hand Hand The hand containing the card
-- @param deck Deck The deck to discard to
-- @param cardIndex number Index of the card in hand
-- @param gameState table The current game state
-- @param x number The x coordinate where the card is played (optional)
-- @param y number The y coordinate where the card is played (optional)
-- @return boolean True if the card was played successfully
function CardManager:playCard(hand, deck, cardIndex, gameState, x, y)
	-- Try to play the card
	local success, card = hand:playCard(cardIndex, gameState, x, y)

	-- If successful, add to discard pile
	if success and card then
		deck:discard(card)
		return true
	end

	return false
end

-- Add a card to the deck
-- @param deck Deck The deck to add the card to
-- @param card Card The card to add
-- @param position string Where to add the card: "top", "bottom", "random"
function CardManager:addCardToDeck(deck, card, position)
	deck:addCard(card, position)
end

-- Get all available card types
-- @return table List of all available cards
function CardManager:getAllCards()
	return self.cards
end

-- Get a card by name
-- @param name string The name of the card to find
-- @return Card The found card or nil if not found
function CardManager:getCardByName(name)
	for _, card in ipairs(self.cards) do
		if card.name == name then
			return card
		end
	end
	return nil
end

return CardManager
