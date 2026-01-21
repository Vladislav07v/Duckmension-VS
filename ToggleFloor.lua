local assets = require('assets')
local const = require('const')

local mt = {}
mt.__index = mt

function mt:draw()
  if not self.is_solid then
    assets.qdraw(2, self.x, self.y)
  else
    assets.qdraw(4, self.x, self.y)
  end
end

function mt:toggle()
  self.is_solid = not self.is_solid
end

return {
  new = function(x, y)
    return setmetatable({
      is_toggle_floor = true,
      x = x,
      y = y,
      w = const.tilesize,
      h = const.tilesize
    }, mt)
  end
}
