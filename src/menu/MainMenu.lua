-- MainMenu.lua
-- Main menu for Goblin Defense

local MainMenu = {}
MainMenu.__index = MainMenu

function MainMenu.new()
    local self = setmetatable({}, MainMenu)
    
    -- Button properties
    self.playButton = {
        x = 640, -- Center of virtual width (1280/2)
        y = 400,
        width = 200,
        height = 60,
        text = "Play",
        hovered = false
    }
    
    return self
end

function MainMenu:update(dt)
    -- Get mouse position and scale it to virtual coordinates
    local mouseX, mouseY = love.mouse.getPosition()
    local config = require("src.config") -- We'll need to create this
    
    -- Scale mouse coordinates to match virtual resolution
    mouseX = (mouseX - config.offset_x) / config.scale_x
    mouseY = (mouseY - config.offset_y) / config.scale_y
    
    -- Check if mouse is over the play button
    self.playButton.hovered = mouseX >= self.playButton.x - self.playButton.width/2 and
                             mouseX <= self.playButton.x + self.playButton.width/2 and
                             mouseY >= self.playButton.y - self.playButton.height/2 and
                             mouseY <= self.playButton.y + self.playButton.height/2
end

function MainMenu:draw()
    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.printf("Goblin Defense", 0, 200, 1280, "center")
    
    -- Draw play button
    if self.playButton.hovered then
        love.graphics.setColor(0.9, 0.9, 0.9)
    else
        love.graphics.setColor(0.7, 0.7, 0.7)
    end
    
    -- Button background
    love.graphics.rectangle(
        "fill",
        self.playButton.x - self.playButton.width/2,
        self.playButton.y - self.playButton.height/2,
        self.playButton.width,
        self.playButton.height,
        10, -- rounded corners
        10
    )
    
    -- Button text
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf(
        self.playButton.text,
        self.playButton.x - self.playButton.width/2,
        self.playButton.y - 12, -- Center text vertically (approx)
        self.playButton.width,
        "center"
    )
end

function MainMenu:mousepressed(x, y, button)
    if button == 1 and self.playButton.hovered then -- Left mouse button
        return true
    end
    return false
end

return MainMenu 