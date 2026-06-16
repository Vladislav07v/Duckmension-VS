-- ScaleManager.lua
-- Manages dynamic scaling based on window size and reference image

local ScaleManager = {}

-- The base resolution that the game was designed for
ScaleManager.BASE_WIDTH = 1280
ScaleManager.BASE_HEIGHT = 720

function ScaleManager:getScale(referenceImage)
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    local dpi_scale = love.window.getDPIScale()
    
    -- If we have a reference image, use its dimensions as the base
    local base_width = self.BASE_WIDTH
    local base_height = self.BASE_HEIGHT
    
    if referenceImage then
        base_width = referenceImage:getWidth()
        base_height = referenceImage:getHeight()
    end
    
    -- Calculate how many times the base resolution fits in the current window
    -- Account for DPI by dividing window dimensions by DPI scale first
    local window_width_scaled = window_width / dpi_scale
    local window_height_scaled = window_height / dpi_scale
    
    local scale_x = window_width_scaled / base_width
    local scale_y = window_height_scaled / base_height
    
    -- Use the minimum to maintain aspect ratio
    -- Floor to keep pixel-perfect scaling
    return math.max(1, math.floor(math.min(scale_x, scale_y)))
end

function ScaleManager:getDPIScale()
    return love.window.getDPIScale()
end

return ScaleManager