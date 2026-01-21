local assets = {}
local quads = {}
local tex = nil
local TILE_SIZE = 16

local function ensure_init()
  if tex then return end
  tex = love.graphics.newImage('assets/tex.png')
  quads = {}
  local w, h = tex:getWidth(), tex:getHeight()
  local id = 1
  for tileY = 0, h - 1, TILE_SIZE do
    for tileX = 0, w - 1, TILE_SIZE do
      quads[id] = love.graphics.newQuad(tileX, tileY, TILE_SIZE, TILE_SIZE, tex:getDimensions())
      id = id + 1
    end
  end
end

function assets.qdraw(id, x, y, r, sx, sy)
  ensure_init()
  if not quads[id] then
    -- fallback: draw first quad if id not found
    id = 1
  end
  love.graphics.draw(tex, quads[id], x, y, r or 0, sx or 1, sy or 1)
end

return assets