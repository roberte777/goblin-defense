-- Require modules
local config = require("src.config")
local MainMenu = require("src.menu.MainMenu")
local Game = require("src.Game")
-- Game state
-- @field current string
-- @field mainMenu MainMenu?
-- @field game Game?
local gameState = {
    current = "menu", -- menu, playing, gameover, etc.
    mainMenu = nil,
    game = nil
}

-- Initialize the game
function love.load()
    -- Set default filter mode to avoid blurry scaling
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    -- Set initial window properties
    love.window.setTitle("Goblin Defense")
    
    -- Allow resizing the window
    love.window.setMode(config.virtual_width, config.virtual_height, {
        resizable = true,
        vsync = true,
        minwidth = 400,
        minheight = 300
    })
    
    -- Calculate initial scale
    updateScale()
    -- Initialize game states
    gameState.mainMenu = MainMenu.new()
end

-- Update scale factors when window is resized
function love.resize(w, h)
    updateScale()
end

-- Update game logic
function love.update(dt)
    if gameState.current == "menu" then
        gameState.mainMenu:update(dt)
    elseif gameState.current == "playing" then
        assert(gameState.game, "Game is not initialized")
        gameState.game:update(dt)
    end
end

-- Draw the game
function love.draw()
    -- Apply scaling transformation
    love.graphics.push()
    love.graphics.translate(config.offset_x, config.offset_y)
    love.graphics.scale(config.scale_x, config.scale_y)
    
    -- Draw based on game state
    if gameState.current == "menu" then
        gameState.mainMenu:draw()
    elseif gameState.current == "playing" then
        assert(gameState.game, "Game is not initialized")
        gameState.game:draw()
    end
    
    -- Display resolution info for testing
    -- love.graphics.setColor(1, 1, 1)
    -- love.graphics.print("Virtual: " .. config.virtual_width .. "x" .. config.virtual_height, 10, 10)
    -- love.graphics.print("Actual: " .. love.graphics.getWidth() .. "x" .. love.graphics.getHeight(), 10, 30)
    -- love.graphics.print("Scale: " .. string.format("%.2f", config.scale_x) .. "x" .. string.format("%.2f", config.scale_y), 10, 50)
    
    -- Reset transformation
    love.graphics.pop()
end

-- Mouse button pressed event
function love.mousepressed(x, y, button)
    if gameState.current == "menu" then
        if gameState.mainMenu:mousepressed(x, y, button) then
            gameState.current = "playing"
            gameState.game = Game.new()
        end
    elseif gameState.current == "playing" then
        assert(gameState.game, "Game is not initialized")
        gameState.game:mousepressed(x, y, button)
    end
end

-- Key pressed event
function love.keypressed(key)
    if gameState.current == "menu" then
        -- Handle menu key presses if needed
        -- gameState.mainMenu:keypressed(key)
    elseif gameState.current == "playing" then
        assert(gameState.game, "Game is not initialized")
        gameState.game:keypressed(key)
    end
    
    -- Global key handlers
    if key == "escape" then
        if gameState.current == "playing" then
            -- Return to menu
            gameState.current = "menu"
        else
            love.event.quit()
        end
    end
end

-- Calculate scale factors based on window size
function updateScale()
    local window_width, window_height = love.graphics.getDimensions()
    
    -- Determine which dimension to scale by (maintain aspect ratio)
    local scale_x = window_width / config.virtual_width
    local scale_y = window_height / config.virtual_height
    
    -- Choose the smaller scale to ensure everything fits (letterboxing)
    local scale = math.min(scale_x, scale_y)
    
    -- Update the configuration
    config.scale_x = scale
    config.scale_y = scale
    
    -- Calculate offsets to center the game in the window
    config.offset_x = (window_width - (config.virtual_width * scale)) / 2
    config.offset_y = (window_height - (config.virtual_height * scale)) / 2
end