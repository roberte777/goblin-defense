local Tower = require("src.tower.Tower")
local WallTower = setmetatable({}, { __index = Tower })
WallTower.__index = WallTower

-- Constructor for the WallTower class
-- @param cellX number The x cell coordinate of the tower
-- @param cellY number The y cell coordinate of the tower
function WallTower.new(cellX, cellY)
    -- Wall tower stats
    local cost = 10
    local range = 0 -- Walls don't attack
    local damage = 0 -- Walls don't attack
    local attackSpeed = 0 -- Walls don't attack

    -- Call parent constructor with pixel coordinates
    local self = Tower.new(cellX, cellY, cost, range, damage, attackSpeed)
    setmetatable(self, WallTower)

    -- Store cell coordinates
    self.cellX = cellX
    self.cellY = cellY

    return self
end

-- Update the wall tower's state
-- @param dt number Delta time
-- @param gameState table The current game state
function WallTower:update(dt, gameState)
    -- Walls don't need to update since they don't attack
end

-- Draw the wall tower
-- @param gameState table The current game state
function WallTower:draw(gameState)
    -- Get cell size from the game state
    local cellSize = gameState.map.cellSize

    -- Calculate position at bottom middle of cell
    local x = (self.cellX - 1) * cellSize
    local y = (self.cellY - 1) * cellSize

    -- Draw wall (gray rectangle)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", x, y, cellSize, cellSize)

    -- Draw border
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", x, y, cellSize, cellSize)
end

return WallTower 