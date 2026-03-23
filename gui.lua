local GUI = {}
local GameState = require("GameState")

function GUI:load()
   self.coins = {}
   if not self.coins.img then
     self.coins.img = love.graphics.newImage("assets/coin.png")
   end
   self.coins.width = self.coins.img:getWidth()
   self.coins.height = self.coins.img:getHeight()
   self.coins.scale = 1
   self.coins.x = love.graphics.getWidth() - 130
   self.coins.y = 10

   self.font = love.graphics.newFont("assets/bit.ttf", 36)
end

function GUI:draw()
  self:displayCoins()
  self:displayCoinText()
  self:displayDuckCoords()
end

function GUI:displayCoins()
  if love.console=="3DS" then
   love.graphics.setColor(0,0,0,0.5)
   love.graphics.draw(self.coins.img, self.coins.x - 14, self.coins.y, 0, self.coins.scale, self.coins.scale)
   love.graphics.setColor(1,1,1,1)
   love.graphics.draw(self.coins.img, self.coins.x - 12, self.coins.y - 2, 0, self.coins.scale, self.coins.scale)
 else
   love.graphics.setColor(0,0,0,0.5)
   love.graphics.draw(self.coins.img, self.coins.x - 754, self.coins.y, 0, self.coins.scale, self.coins.scale)
   love.graphics.setColor(1,1,1,1)
   love.graphics.draw(self.coins.img, self.coins.x - 752, self.coins.y - 2, 0, self.coins.scale, self.coins.scale)
  end
end

function GUI:displayCoinText()
  love.graphics.setFont(self.font)
  local x = self.coins.x + self.coins.width * self.coins.scale
  local y = self.coins.y + self.coins.height / 2 * self.coins.scale - self.font:getHeight() / 2
  local doors = GameState.doors_passed or 0
  if love.console=="3DS" then
    love.graphics.print(":".. doors, x-12, y-2)
  else
    love.graphics.print(":".. doors, x-772, y+23)
  end
end

function GUI:displayDuckCoords()
  -- use GameState API explicitly
  local duckGetter = GameState.getDuckObject
  if type(duckGetter) ~= "function" then
    -- diagnostic: function missing
    -- print only once to avoid spamming the console
    if not self._duckGetterWarn then
      print("GUI: GameState.getDuckObject is missing or not a function (type=" .. type(duckGetter) .. ")")
      self._duckGetterWarn = true
    end
    return
  end

  local duck = duckGetter()
  if not duck then
    -- no duck found — not an error, but print once to help debugging
    if not self._noDuckWarn then
      print("GUI: no duck found in current GameState (GameState.getCurrent() = " .. tostring(GameState.getCurrent()) .. ")")
      self._noDuckWarn = true
    end
    return
  end

  love.graphics.setFont(self.font)
  local coordText = string.format("Duck: X=%d Y=%d", duck.x or 0, duck.y or 0)
  love.graphics.setColor(1,1,1,1)
  love.graphics.print(coordText, 20, love.graphics.getHeight() - self.font:getHeight() - 10)
end

return GUI