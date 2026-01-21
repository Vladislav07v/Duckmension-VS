local assets, quads, tex = {}, {}, nil

function assets.loadTiles(path, tileSize)
    tex = love.graphics.newImage("assets/tiles.png")
  local tileW, tileH = tex:getWidth(), tex:getHeight()
  local id = 1
  for y = 0, tileH - tileSize, tileSize do
    for x = 0, tileW - tileSize, tileSize do
      quads[id] = love.graphics.newQuad(x, y, tileSize, tileSize, tex:getDimensions())
      id = id + 1
    end
  end
end

function assets.qdraw(id, x, y, r, sx, sy)
  love.graphics.draw(tex, quads[id], x, y, r or 0, sx or 1, sy or 1)
end

return assets