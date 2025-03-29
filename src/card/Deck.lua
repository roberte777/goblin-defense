-- @class Deck
-- @field cards table Array of Card objects in the deck
-- @field discardPile table Array of Card objects in the discard pile
local Deck = {}
Deck.__index = Deck

-- Create a new Deck
-- @param initialCards table Array of initial Card objects (optional)
-- @return Deck The created deck
function Deck.new(initialCards)
    local self = setmetatable({}, Deck)
    
    self.cards = initialCards or {} -- Main deck
    self.discardPile = {} -- Discard pile
    
    -- Shuffle initial deck
    if #self.cards > 0 then
        self:shuffle()
    end
    
    return self
end

-- Shuffle the deck
function Deck:shuffle()
    local cards = self.cards
    local n = #cards
    
    -- Fisher-Yates shuffle algorithm
    for i = n, 2, -1 do
        local j = math.random(i)
        cards[i], cards[j] = cards[j], cards[i]
    end
end

-- Draw a specified number of cards from the deck
-- @param count number Number of cards to draw
-- @return table Array of drawn Card objects
function Deck:draw(count)
    local drawnCards = {}
    
    for i = 1, count do
        if #self.cards == 0 then
            -- If deck is empty, shuffle discard pile into deck
            if #self.discardPile > 0 then
                self.cards = self.discardPile
                self.discardPile = {}
                self:shuffle()
            else
                -- No cards left to draw
                break
            end
        end
        
        -- Draw top card from deck
        local card = table.remove(self.cards, 1)
        table.insert(drawnCards, card)
    end
    
    return drawnCards
end

-- Add a card to the discard pile
-- @param card Card The card to discard
function Deck:discard(card)
    table.insert(self.discardPile, card)
end

-- Add multiple cards to the discard pile
-- @param cards table Array of Card objects to discard
function Deck:discardMultiple(cards)
    for _, card in ipairs(cards) do
        table.insert(self.discardPile, card)
    end
end

-- Shuffle the discard pile into the deck
function Deck:shuffleDiscardIntoDeck()
    -- Add all cards from discard pile to the deck
    for _, card in ipairs(self.discardPile) do
        table.insert(self.cards, card)
    end
    
    -- Clear discard pile
    self.discardPile = {}
    
    -- Shuffle the deck
    self:shuffle()
end

-- Add a card to the deck
-- @param card Card The card to add
-- @param position string Where to add the card: "top", "bottom", "random" (default: "top")
function Deck:addCard(card, position)
    position = position or "top"
    
    if position == "top" then
        table.insert(self.cards, 1, card)
    elseif position == "bottom" then
        table.insert(self.cards, card)
    elseif position == "random" then
        local pos = math.random(#self.cards + 1)
        table.insert(self.cards, pos, card)
    end
end

-- Remove a card from the deck
-- @param cardIndex number Index of the card in the deck
-- @return Card The removed card or nil if index is invalid
function Deck:removeCard(cardIndex)
    if cardIndex >= 1 and cardIndex <= #self.cards then
        return table.remove(self.cards, cardIndex)
    end
    return nil
end

-- Get the number of cards in the deck
-- @return number Count of cards in the deck
function Deck:getCount()
    return #self.cards
end

-- Get the number of cards in the discard pile
-- @return number Count of cards in the discard pile
function Deck:getDiscardCount()
    return #self.discardPile
end

-- Get the total number of cards (deck + discard)
-- @return number Total card count
function Deck:getTotalCount()
    return #self.cards + #self.discardPile
end

-- Peek at the top card without removing it
-- @param depth number How deep to peek (default: 1)
-- @return Card The card at the specified depth or nil if not available
function Deck:peek(depth)
    depth = depth or 1
    if depth >= 1 and depth <= #self.cards then
        return self.cards[depth]
    end
    return nil
end

-- Draw the deck and discard pile counts (for UI)
-- @param x number X position to draw at
-- @param y number Y position to draw at
function Deck:drawCounts(x, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Deck: " .. #self.cards, x, y)
    love.graphics.print("Discard: " .. #self.discardPile, x, y + 20)
end

return Deck 