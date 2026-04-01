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
   self.timer_font = love.graphics.newFont("assets/bit.ttf", 24)
   
   -- Initialize timed level display state
   self.timed_level_active = false
   self.timed_level_timer = 0
end

function GUI:setTimedLevel(active, timer)
  self.timed_level_active = active
  self.timed_level_timer = timer
end

function GUI:draw()
  self:displayCoins()
  self:displayCoinText()
  self:displayDuckCoords()
  self:displayTimer()
end

function GUI:displayCoins()
  if love._console=="3DS" then
   love.graphics.setColor(0,0,0,0.5)
   love.graphics.draw(self.coins.img, self.coins.x - 14, self.coins.y, 0, self.coins.scale, self.coins.scale)
   love.graphics.setColor(1,1,1,1)
   love.graphics.draw(self.coins.img, self.coins.x - 12, self.coins.y - 2, 0, self.coins.scale, self.coins.scale)
 else
   love.graphics.setColor(0,0,0,0.5)
   love.graphics.draw(self.coins.img, self.coins.x - 75, self.coins.y, 0, self.coins.scale, self.coins.scale)
   love.graphics.setColor(1,1,1,1)
   love.graphics.draw(self.coins.img, self.coins.x - 752, self.coins.y - 2, 0, self.coins.scale, self.coins.scale)
  end
end

function GUI:displayCoinText()
  love.graphics.setFont(self.font)
  local x = self.coins.x + self.coins.width * self.coins.scale
  local y = self.coins.y + self.coins.height / 2 * self.coins.scale - self.font:getHeight() / 2
  local doors = GameState.doors_passed or 0
  if love._console=="3DS" then
    love.graphics.print(":".. doors, x-12, y-2)
  else
    love.graphics.print(":", x-754, y-2)
    love.graphics.print(doors, x-774, y+23)
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

function GUI:displayTimer()
  if self.timed_level_active and self.timed_level_timer and self.timed_level_timer > 0 then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.timer_font)
    local minutes = math.floor(self.timed_level_timer / 60)
    local seconds = math.floor(self.timed_level_timer % 60)
    local time_text = string.format("%d:%02d", minutes, seconds)
    local text_width = self.timer_font:getWidth(time_text)
    love.graphics.print(time_text, love.graphics.getWidth() / 5 - text_width / 2, 20)
  end
end

return GUI