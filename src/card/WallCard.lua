local Card = require("src.card.Card")
local WallCard = setmetatable({}, { __index = Card })
WallCard.__index = WallCard

-- Create a new Wall Card with default values
-- @return WallCard The created wall card
function WallCard.new()
    local self = Card.new(
        "Wall",
        "Creates a defensive wall that blocks enemy movement",
        10, -- cost
        "common", -- rarity
        "assets/cards/wall.png" -- image
    )
    setmetatable(self, WallCard)

    -- Set tower type to identify this as a tower card
    self.towerType = "wall"

    return self
end

-- Draw the wall card with wall-specific details
-- @param x number The x-coordinate to draw at
-- @param y number The y-coordinate to draw at
-- @param scale number Scale factor for drawing (default: 1)
function WallCard:draw(x, y, scale)
    -- Call the parent draw method first
    Card.draw(self, x, y, scale)

    scale = scale or 1
    local width = self.width * scale
    local height = self.height * scale

    -- Add wall-specific visuals (wall icon in the middle)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", x + width / 4, y + height / 3, width / 2, width / 2, 5, 5)

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Called when the wall card is played
-- @param gameState table The current game state
-- @param x number The x grid coordinate where the wall is placed
-- @param y number The y grid coordinate where the wall is placed
-- @return boolean True if the wall was placed successfully
function WallCard:play(gameState, x, y)
    -- Check if the grid coordinates are valid
    if not x or not y or x < 1 or x > gameState.map.width or y < 1 or y > gameState.map.height then
        print("Cannot place wall outside the map")
        return false
    end

    -- Check if the location is valid
    local cell = gameState.map:getCell(x, y)
    if not cell then
        print("Cannot place wall outside the map")
        return false
    end

    -- Check if the cell is on the enemy path
    if cell.type ~= "path" then
        print("Cannot place wall outside of enemy path")
        return false
    end

    -- Create the wall
    local WallTower = require("src.tower.WallTower")
    local wall = WallTower.new(x, y)

    -- Add the wall to the game
    table.insert(gameState.towers, wall)

    -- Mark the cell as occupied by a wall
    cell.type = "wall"
    cell.occupant = wall
    cell.isPath = true -- Keep the cell marked as path
    cell.isBlocked = true -- Mark as blocked to prevent path recalculation

    -- Trigger path recalculation
    if gameState.path then
        gameState.path:updatePath()
    end

    -- Call the parent play method to handle resources etc.
    return Card.play(self, gameState, x, y)
end

-- Called when the wall card is upgraded
-- @return WallCard The upgraded wall card
function WallCard:upgrade()
    -- Create an upgraded version with better stats
    local upgradedCard = WallCard.new()

    -- Customize the upgraded version
    upgradedCard.name = self.name .. "+"
    upgradedCard.description = self.description .. " (Upgraded)"

    return upgradedCard
end

return WallCard 