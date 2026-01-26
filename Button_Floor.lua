local assets = require('assets')
local const = require('const')

local mt = {}
mt.__index = mt

function mt:draw()
  if not self.is_solid then
    assets.qdraw(2, self.x, self.y)
  else
    assets.qdraw(5, self.x, self.y)
  end
end

function mt:toggle()
  self.is_solid = not self.is_solid
end

return {
  -- new accepts optional opts as 4th arg; opts.Id will be attached to the floor
  new = function(x, y, starts_solid, opts)
    return setmetatable({
      is_button_floor = true,
      x = x,
      y = y,
      is_solid = (starts_solid == nil) and true or starts_solid,
      w = const.tilesize,
      h = const.tilesize,
      id = opts and opts.Id or nil,
    }, mt)
  end
}