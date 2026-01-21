local assets = require('assets32')
local const = require('const')
local GameState = require('GameState')

local mt = {}
mt.__index = mt

function mt:update(dt)
  self.touches_duck = GameState.getCurrent().world:check(self, 'is_duck')
    if self.touches_duck then
      --sleep(1)
      GameState.getCurrent():trigger('door:open')
      local state = GameState.getCurrent()
  end
end

function mt:draw()
  assets.qdraw(9, self.x, self.y)
  if self.touches_duck then
  end
end

return {
  new = function(x, y, game_state)
    return setmetatable({
      is_door = true,
      is_actable = true,
      x = x,
      y = y,
      w = const.tilesize,
      h = const.tilesize,
    }, mt)
  end
}
