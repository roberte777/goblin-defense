-- @class Hand
-- @field cards table Array of Card objects in the hand
local Hand = {}
Hand.__index = Hand

-- Create a new Hand
-- @param initialCards table Array of initial Card objects in hand (optional)
-- @return Hand The created hand
function Hand.new(initialCards)
    local self = setmetatable({}, Hand)
    
    self.cards = initialCards or {} -- Cards in hand
    
    return self
end

-- Add a card to the hand
-- @param card Card The card to add to the hand
function Hand:addCard(card)
    table.insert(self.cards, card)
end

-- Remove a card from the hand
-- @param index number Index of the card to remove
-- @return Card The removed card or nil if index is invalid
function Hand:removeCard(index)
    if index >= 1 and index <= #self.cards then
        return table.remove(self.cards, index)
    end
    return nil
end

-- Get the number of cards in the hand
-- @return number Count of cards in the hand
function Hand:getCount()
    return #self.cards
end

-- Play a card from the hand
-- @param cardIndex number Index of the card in the hand
-- @param gameState table The current game state
-- @param x number The x coordinate where the card is played (optional)
-- @param y number The y coordinate where the card is played (optional)
-- @return boolean, Card True and the card if played successfully, false and nil otherwise
function Hand:playCard(cardIndex, gameState, x, y)
    if cardIndex < 1 or cardIndex > #self.cards then
        print("Invalid card index")
        return false, nil
    end
    
    local card = self.cards[cardIndex]
    local success = card:play(gameState, x, y)
    
    if success then
        -- Remove from hand and return the card
        return true, table.remove(self.cards, cardIndex)
    end
    
    return false, nil
end

-- Discard a card from the hand
-- @param cardIndex number Index of the card in the hand
-- @param gameState table The current game state
-- @return Card The discarded card or nil if index is invalid
function Hand:discardCard(cardIndex, gameState)
    if cardIndex >= 1 and cardIndex <= #self.cards then
        local card = table.remove(self.cards, cardIndex)
        card:discard(gameState)
        return card
    end
    return nil
end

-- Discard all cards from the hand
-- @param gameState table The current game state
-- @return table Array of discarded cards
function Hand:discardAll(gameState)
    local discarded = {}
    for i = #self.cards, 1, -1 do
        local card = self:discardCard(i, gameState)
        table.insert(discarded, card)
    end
    return discarded
end

-- Update the cards in the hand
-- @param dt number Delta time
-- @param gameState table The current game state
function Hand:update(dt, gameState)
    -- Update cards in hand
    for _, card in ipairs(self.cards) do
        card:update(dt, gameState)
    end
end

-- Draw the hand of cards at the specified position
-- @param x number The x position to start drawing from
-- @param y number The y position to draw at
-- @param cardSpacing number The spacing between cards
-- @param scale number The scale to draw the cards at (default: 1)
-- @param hoveredOffsetY number How much to elevate hovered cards (default: 0)
function Hand:draw(x, y, cardSpacing, scale, hoveredOffsetY)
    scale = scale or 1
    hoveredOffsetY = hoveredOffsetY or 0
    
    -- Draw each card in the hand
    for i, card in ipairs(self.cards) do
        local cardX = x + (i - 1) * cardSpacing
        local cardY = y
        
        -- If card is hovered, elevate it slightly
        if card.isHovered then
            cardY = cardY - hoveredOffsetY
        end
        
        card:draw(cardX, cardY, scale)
    end
end

-- Set the hover state for each card based on the given mouse position
-- @param mouseX number Mouse X coordinate
-- @param mouseY number Mouse Y coordinate
-- @param x number Base X position for cards
-- @param y number Base Y position for cards
-- @param cardSpacing number Spacing between cards
-- @param scale number Scale of the cards
function Hand:updateHoverStates(mouseX, mouseY, x, y, cardSpacing, scale)
    scale = scale or 1
    
    -- Check each card in hand
    for i, card in ipairs(self.cards) do
        local cardX = x + (i - 1) * cardSpacing
        local cardY = y
        
        card.isHovered = card:isPointInside(mouseX, mouseY, cardX, cardY, scale)
    end
end

-- Get a card at a specific index
-- @param index number The index of the card to get
-- @return Card The card at the specified index or nil if invalid
function Hand:getCard(index)
    if index >= 1 and index <= #self.cards then
        return self.cards[index]
    end
    return nil
end

-- Find the index of the card under the cursor
-- @param mouseX number Mouse X coordinate
-- @param mouseY number Mouse Y coordinate
-- @param x number Base X position for cards
-- @param y number Base Y position for cards
-- @param cardSpacing number Spacing between cards
-- @param scale number Scale of the cards
-- @return number Index of the card under cursor, or nil if none
function Hand:getCardIndexAtPosition(mouseX, mouseY, x, y, cardSpacing, scale)
    scale = scale or 1
    
    for i, card in ipairs(self.cards) do
        local cardX = x + (i - 1) * cardSpacing
        local cardY = y
        
        if card:isPointInside(mouseX, mouseY, cardX, cardY, scale) then
            return i
        end
    end
    
    return nil
end

return Hand 