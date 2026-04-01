local assets = require('assets32')
local const = require('const')
local GameState = require('GameState')
local Animation = require('Animation')

local mt = {}
mt.__index = mt

function mt:update(dt)
  self.touches_duck = GameState.getCurrent().world:check(self, 'is_duck')
    if self.touches_duck then
      if self.door_type == 'timed' then
        -- Timed door: start the timer and trigger the level
        GameState.getCurrent():trigger('door:open', self, { timed = true, target_level = self.target_level })
      else
        -- Normal door: go to next level
        GameState.getCurrent():trigger('door:open', self, { timed = false })
      end
      local state = GameState.getCurrent()
  end

  -- advance animation timer so frames progress
  if self.current_anim then
    self.current_anim:update(dt)
  end
end

function mt:draw()
    love.graphics.setColor(0.85, 0.72, 0.28,1)
    assets.qdraw(self.current_anim:getFrame(), self.x - 6, self.y)
    love.graphics.setColor(1,1,1,1)
end

function mt:setAnim(name)
  -- change animation only if different and reset timer when switching
  if self.current_anim ~= self.anims[name] then
    self.current_anim = self.anims[name]
    self.current_anim.t = 0
  end
end

return {
  new = function(x, y, game_state, opts)
    opts = opts or {}
    local h = setmetatable({
      is_door = true,
      is_actable = true,
      x = x,
      y = y,
      w = const.tilesize,
      h = const.tilesize,
      door_type = opts.DoorType or 'normal', -- 'normal' or 'timed'
      target_level = opts.TargetLevel or 1, -- used for timed doors
      anims = {
        idle = Animation.new(9, 8, 1),
        }
    }, mt)
    h:setAnim('idle')
    return h
  end
}