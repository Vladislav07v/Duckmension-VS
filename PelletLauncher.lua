local Pellet = require('Pellet')
local const = require('const')

local mt = {}
mt.__index = mt

function mt:update(dt)
  self.timer = (self.timer or 0) + dt
  local interval = self.interval or 1
  if self.timer >= interval then
    self.timer = self.timer - interval

    -- spawn pellet just outside the launcher so it doesn't immediately collide
    local pw = self.pw or 6
    local ph = self.ph or 6
    local sx, sy = self.x, self.y

    if self.dir == 1 then -- up
      sx = self.x + (self.w / 2) - (pw / 2)
      sy = self.y - ph - 1
    elseif self.dir == 2 then -- right
      sx = self.x + self.w + 1
      sy = self.y + (self.h / 2) - (ph / 2)
    elseif self.dir == 3 then -- down
      sx = self.x + (self.w / 2) - (pw / 2)
      sy = self.y + self.h + 1
    elseif self.dir == 4 then -- left
      sx = self.x - pw - 1
      sy = self.y + (self.h / 2) - (ph / 2)
    end

    local pellet = Pellet.new(sx, sy, self.dir, self.world, { w = pw, h = ph, speed = self.speed or 200 })
    if self.world then
      self.world:add(pellet)
    end
  end
end

function mt:draw()
  -- visual for the launcher; swap to a tileset quad if you want
  love.graphics.setColor(0.55, 0.55, 0.6, 1)
  love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
  love.graphics.setColor(0.25, 0.25, 0.25, 1)
  if self.dir == 1 then
    love.graphics.rectangle('fill', self.x + (self.w/2) - 4, self.y - 6, 8, 6)
  elseif self.dir == 2 then
    love.graphics.rectangle('fill', self.x + self.w, self.y + (self.h/2) - 4, 6, 8)
  elseif self.dir == 3 then
    love.graphics.rectangle('fill', self.x + (self.w/2) - 4, self.y + self.h, 8, 6)
  else
    love.graphics.rectangle('fill', self.x - 6, self.y + (self.h/2) - 4, 6, 8)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

return {
  -- new signature matches other tiles: new(x, y, game_state, opts)
  new = function(x, y, game_state, opts)
    opts = opts or ( (type(game_state) == 'table' and game_state._default_opts) and game_state._default_opts ) or opts
    -- Level.lua will pass opts as the 4th arg. The require wrapper stores opts in _default_opts
    -- so this function receives them as `opts` normally.
    local dir = (opts and opts.Direction) or 2 -- default right
    local t = setmetatable({
      is_launcher = true,
      is_touchable = false, -- launcher itself does not kill the duck
      x = x,
      y = y,
      w = opts and opts.W or const.tilesize,
      h = opts and opts.H or const.tilesize,
      dir = dir,
      interval = opts and opts.Interval or 1.0,
      timer = 0,
      world = game_state and game_state.world or nil,
      speed = opts and opts.Speed or 200,
      pw = opts and opts.PelletW or 6,
      ph = opts and opts.PelletH or 6,
      z_index = opts and opts.ZIndex or 5,
    }, mt)

    return t
  end

}