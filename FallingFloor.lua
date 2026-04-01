local assets = require('assets')
local const = require('const')
local GameState = require('GameState')

local mt = {}
mt.__index = mt

function mt:update(dt)
  -- Check if a duck is standing on top of this platform
  -- by checking if there's a duck directly above the platform
  local duck_on_platform = false
  local ducks = GameState.getCurrent().world:find('all', 'is_duck')
  
  for _, duck in ipairs(ducks) do
    -- Check if duck is directly above this platform and is grounded on it
    if duck.x < self.x + self.w and 
       duck.x + duck.w > self.x and
       duck.y + duck.h >= self.y and 
       duck.y + duck.h <= self.y + 2 and
       not self.is_falling then
      duck_on_platform = true
      break
    end
  end
  
  if duck_on_platform then
    if not self.duck_landed then
      self.duck_landed = true
      self.fall_timer = 0
    end
    
    if self.duck_landed then
      self.fall_timer = self.fall_timer + dt
      
      -- After 1 second, start falling
      if self.fall_timer >= 0.5 then
        self.is_falling = true
      end
    end
  else
    -- No duck on platform, reset for next use
    self.duck_landed = false
    self.fall_timer = 0
  end
  
  -- Apply falling physics
  if self.is_falling then
    self.vy = self.vy + 900 * dt -- gravity
    self.y = self.y + self.vy * dt
    
    -- Remove if it falls off screen
    if self.y > 250 then
      GameState.getCurrent().world:remove(self)
    end
  end
end

function mt:draw()
  --love.graphics.setColor(0.6, 0.4, 0.2, 1) -- Brown color
  --love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
  --love.graphics.setColor(1, 1, 1, 1)
  fl = love.graphics.newImage('assets/tile_wide.png')
  love.graphics.draw(fl, self.x, self.y)
end

return {
  new = function(x, y, game_state)
    return setmetatable({
      is_solid = true,
      x = x,
      y = y,
      w = const.tilesize * 3,  -- 3 tiles wide
      h = const.tilesize,      -- 1 tile tall
      vy = 0,
      duck_landed = false,
      fall_timer = 0,
      is_falling = false,
      z_index = 4,
      world = game_state and game_state.world or nil
    }, mt)
  end
}