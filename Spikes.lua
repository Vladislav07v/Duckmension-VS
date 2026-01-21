local assets = require('assets')
local const = require('const')
local GameState = require('GameState')

local mt = {}
mt.__index = mt

function mt:draw()
  assets.qdraw(6, self.x, self.y)
end

function mt:onTouch(other)
  if other.is_duck then
    GameState.getCurrent():trigger('duck:kill', self, other)
  end
end

return {
  new = function(x, y)
    return setmetatable({
      is_touchable = true,
      x = x,
      y = y,
      w = const.tilesize,
      h = const.tilesize / 3
    }, mt)
  end
}