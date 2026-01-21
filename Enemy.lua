local assets = require('assets')
local const = require('const')
local GameState = require('GameState')
local Animation = require('Animation')

local mt = {}
mt.__index = mt

function mt:draw()
  if self.is_dead then
    love.graphics.setColor(255, 255, 255, 128)
    assets.qdraw(self.anim:getFrame(), self.x + 16, self.y+1, math.pi / 2)
    love.graphics.setColor(255, 255, 255)
  else
    if self.dir == -1 then
      assets.qdraw(self.anim:getFrame(), self.x + 16, self.y, 0, -1, 1)
    else
      assets.qdraw(self.anim:getFrame(), self.x, self.y)
    end
  end
end

function mt:update(dt)
  if self.is_dead then return end

  self.anim:update(dt)

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

  if is_obstacle_ahead or not is_floor_ahead then
    self:turnBack()
  end
end

function mt:turnBack()
  self.dir = self.dir * -1
end

function mt:onTouch(other)
  if other.is_duck then
    GameState.getCurrent():trigger('duck:kill', self, other)
  end
end

function mt:onStomp()
  self.is_touchable = false
  self.is_stompable = false
  self.is_dead = true
end

return {
  new = function(x, y)
    return setmetatable({
      is_touchable = true,
      is_stompable = true,
      x = x,
      y = y,
      w = const.tilesize,
      h = const.tilesize,
      dir = 1,
      speed = 60,
      anim = Animation.new(21, 4, 0.5)
    }, mt)
  end
}
