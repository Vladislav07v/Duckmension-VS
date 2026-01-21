local assets = require('assets')
local const = require('const')

local mt = {}
mt.__index = mt

function mt:draw()
  assets.qdraw(1, self.x, self.y)
end

return {
  new = function(x, y, world)
    return setmetatable({
      is_solid = true,
      x = x,
      y = y,
      w = const.tilesize,
      h = const.tilesize
    }, mt)
  end
}
