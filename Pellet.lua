local GameState = require('GameState')
local const = require('const')

local mt = {}
mt.__index = mt

function mt:update(dt)
  self.life = (self.life or 0) + dt

  if not self.world then return end

  -- move along the velocity (either vx or vy is non-zero)
  if self.vx and self.vx ~= 0 then
    local tx = self.x + self.vx * dt
    self.world:move(self, tx, self.y)
  elseif self.vy and self.vy ~= 0 then
    local ty = self.y + self.vy * dt
    self.world:move(self, self.x, ty)
  end
  
  -- safety lifetime
  if (self.max_life and self.life > self.max_life) or self.x < -500 or self.x > 500 or self.y < -500 or self.y > 500 then
    self.world:remove(self)
    return
  end
end

function mt:draw()
  -- simple pellet visual; replace with a sprite/quad if you prefer
  love.graphics.setColor(0.8, 0.8, 0.8, 1)
  love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
  love.graphics.setColor(1, 1, 1, 1)
end

function mt:onTouch(other)
  if other.is_duck then
    GameState.getCurrent():trigger('duck:kill', self, other)
  end
end

return {
  new = function(x, y, dir, world, opts)
    opts = opts or {}
    local speed = opts.speed or 200
    local w = opts.w or 6
    local h = opts.h or 6
    local vx, vy = 0, 0
    if dir == 1 then -- up
      vy = -speed
    elseif dir == 2 then -- right
      vx = speed
    elseif dir == 3 then -- down
      vy = speed
    elseif dir == 4 then -- left
      vx = -speed
    else
      vx = speed
    end

    local p = setmetatable({
      is_touchable = true,
      x = x,
      y = y,
      w = w,
      h = h,
      vx = vx,
      vy = vy,
      life = 0,
      max_life = opts.max_life or 5,
      world = world,
      z_index = opts.z_index or 12,
    }, mt)

    return p
  end
}