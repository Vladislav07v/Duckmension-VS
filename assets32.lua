local assets, quads, tex = {}, {}, nil

function assets.qdraw(id, x, y, r, sx, sy)
  if not tex then
    tex = love.graphics.newImage('assets/tex32.png')
    for tileY = 0, tex:getHeight()-1, 32 do
      for tileX = 0, tex:getWidth()-1, 32 do
        quads[#quads+1] = love.graphics.newQuad(tileX, tileY, 32, 32, tex:getDimensions())
      end
    end
  end

  love.graphics.draw(tex, quads[id], x, y, r, sx, sy)
end
return assets