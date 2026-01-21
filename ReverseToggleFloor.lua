local assets = require('assets')
local const = require('const')

local mt = {}
mt.__index = mt
    
function mt:draw()
  if not self.is_solid then
    assets.qdraw(2, self.x, self.y)
  else
    assets.qdraw(3, self.x, self.y)
  end
end

function mt:toggle()
  self.is_solid = not self.is_solid
end

return {
  new = function(x, y, starts_solid)
    return setmetatable({
      is_toggle_reversefloor = true,
      x = x,
      y = y,
      is_solid = starts_solid,
      w = const.tilesize,
      h = const.tilesize
    }, mt)
  end
}
