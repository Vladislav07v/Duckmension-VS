local const = require('const')

local mt = {}
mt.__index = mt

function mt:draw()
  for i, tile in pairs(self.tiles) do
    love.graphics.rectangle('line', tile.x, tile.y, tile.w, tile.h)
  end
end

-- locally wrap require so TILES_TYPES entries can be written with default options:
-- e.g. [71] = require('Button', { Id = 1 })
local _orig_require = require
local function require(name, opts)
  local mod = _orig_require(name)
  if opts then
    -- if the module is a factory function, call it with opts
    if type(mod) == "function" then
      return mod(opts)
    end
    -- otherwise attach default opts so Level.new can pass them to .new
    return setmetatable({ _default_opts = opts }, { __index = mod })
  end
  return mod
end

local TILES_TYPES = {
  [9] = require('Duck'),
  [1] = require('Floor'),
  [2] = require('ToggleFloor'),
  [3] = require('ReverseToggleFloor'),
  [4] = require('Door'),
  --[5] = require('Spikes'),
  [6] = require('Trampoline'),
  [7] = require('Button'),
  [71] = require('Button', { Id = 1 }),
  [72] = require('Button', { Id = 2 }),
  [8] = require('Button_Floor'),
  [81] = require('Button_Floor', { Id = 1 }),
  [82] = require('Button_Floor', { Id = 2 }),
  [91] = require('PelletLauncher', { Direction = 1 }),
  [92] = require('PelletLauncher', { Direction = 2 }),
  [93] = require('PelletLauncher', { Direction = 3 }),
  [94] = require('PelletLauncher', { Direction = 4 }),
  [11] = require('Portal', { Direction = 1, PairId = 1 }),
  [12] = require('Portal', { Direction = 1, PairId = 1 }),
  [13] = require('Portal', { Direction = 2, PairId = 1 }),
  [14] = require('Portal', { Direction = 3, PairId = 1 }),
  [14] = require('Portal', { Direction = 4, PairId = 1 }),
  [21] = require('Portal', { Direction = 1, PairId = 2 }),
  [22] = require('Portal', { Direction = 2, PairId = 2 }),
  [23] = require('Portal', { Direction = 3, PairId = 2 }),
  [24] = require('Portal', { Direction = 4, PairId = 2 }),
  --[7] = require('Trampoline', is_moving == true),
  --[21] = require('Enemy'),
}

return {
  new = function(lvl_name, game_state)
    local lvl = setmetatable({ columns = 25, tiles = {} }, mt)
    lvl.data = require('levels/'..lvl_name)

    for i, v in ipairs(lvl.data) do
      local x, y = (i-1) % lvl.columns * const.tilesize, math.floor((i-1) / lvl.columns) * const.tilesize
      local tileModule = TILES_TYPES[v]
      if tileModule then
        -- pass default options stored on module (if any) as a final arg to .new
        local opts = tileModule._default_opts
        -- many modules define new(x,y,game_state) — we add opts as a fourth parameter;
        -- modules that don't expect opts will simply ignore it
        game_state.world:add( tileModule.new(x, y, game_state, opts) )
      end
    end

    return lvl
  end
}