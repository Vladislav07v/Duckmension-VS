-- Duck-specific drawing API, now backed by assets_shared cache so the duck image
-- is only loaded once and changes are globally visible.

local shared = require('assets_shared')
local quads = {}
local duck_img = nil
local TILE_SIZE = 32

local function ensure_init()
  -- getDuckSprite loads or returns a cached duck image
  duck_img = shared.getDuckSprite()
  if duck_img and #quads > 0 then
    -- if quads already built and image path unchanged, keep them
    return
  end
  quads = {}
  local w, h = duck_img:getWidth(), duck_img:getHeight()
  local id = 1
  for tileY = 0, h - 1, TILE_SIZE do
    for tileX = 0, w - 1, TILE_SIZE do
      quads[id] = love.graphics.newQuad(tileX, tileY, TILE_SIZE, TILE_SIZE, duck_img:getDimensions())
      id = id + 1
    end
  end
end

local assets = {}

function assets.setDuckSprite(path)
  shared.setDuckSprite(path)
  -- force re-init next draw
  duck_img = nil
  quads = {}
end

function assets.setDuckColor(r, g, b)
  shared.setDuckColor(r, g, b)
end

function assets.qdraw(id, x, y, r, sx, sy)
  ensure_init()
  if not quads[id] then id = 1 end
  local color = shared.getDuckColor()
  if love.math and love.math.colorFromBytes then
    love.graphics.setColor(love.math.colorFromBytes(color[1], color[2], color[3]))
  else
    -- fallback: normalize bytes to 0..1
    love.graphics.setColor(color[1]/255, color[2]/255, color[3]/255)
  end
  love.graphics.draw(duck_img, quads[id], x, y, r or 0, sx or 1, sy or 1)
  love.graphics.setColor(1, 1, 1, 1)
end

return assets