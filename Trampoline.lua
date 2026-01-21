local assets = require('assets32')
local const = require('const')
local GameState = require('GameState')
local Animation = require('Animation')
local Duck = require('Duck')

local mt = {}
mt.__index = mt

function mt:update(dt)
  if is_moving == true then
    GameState.getCurrent().world:move(self, self.x+self.dir*self.speed*dt, self.y, 'is_solid')

    local is_obstacle_ahead = GameState.getCurrent().world:check({
      x = self.x + self.w/2 + self.w*2/3  * self.dir,
      y = self.y + self.h/2,
      w = 2,
      h = 2
    }, 'is_solid')

    local is_floor_ahead = GameState.getCurrent().world:check({
      x = self.x + self.w/2 + self.w*2/3  * self.dir,
      y = self.y + self.h + 1,
      w = 2,
      h = 2
    }, 'all')
  end

  if self.pushed then
    self.push_timer = (self.push_timer or 0) + dt
    self.current_anim: update(dt)
    if self.push_timer >= self.anims. push. duration then
      self.pushed = false
      self.push_timer = 0
      self: setAnim('idle')
    end
  else
    self.current_anim:update(dt)
    self: setAnim('idle')
  end
end

function mt:draw()
  assets.qdraw(self.current_anim:getFrame(), self.x, self.y)
end

function mt:onTouch()
  local duck = GameState.getDuckObject()
  if duck then
    duck. vy = -500
    self:setAnim('push')
    self.pushed = true
    self.push_timer = 0
  end
end

function mt:setAnim(name)
  if self.current_anim ~= self.anims[name] then
    self.current_anim = self.anims[name]
    -- reset anim timer when switching
    self.current_anim. t = 0
  end
end

return {
  new = function(x, y)
    return setmetatable({
      is_touchable = true,
      is_moving = false,
      x = x,
      y = y,
      w = const.tilesize,
      h = const.tilesize,
      speed = 60,
      anims = {
        idle = Animation. new(1,1,0.1),
        push = Animation.new(2,6,0.3),
      },
      current_anim = Animation.new(1,1,0.1),
      pushed = false,
      push_timer = 0,
    }, mt)
  end
}