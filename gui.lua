local GUI = {}
local GameState = require("GameState")

function GUI:load()
  self.font = love.graphics.newFont("assets/upheavtt.ttf", 20)
   
  -- Initialize timed level display state
  self.timed_level_active = false
  self.timed_level_timer = 0
end

function GUI:setTimedLevel(active, timer)
  self.timed_level_active = active
  self.timed_level_timer = timer
end

function GUI:draw()
  self:displayCookieText()
  self:displayCoinText()
  self:displayTimer()
  self:displayDuckCoords()
end

function GUI:displayCookieText()
  love.graphics.setFont(self.font)
  local doors = GameState.doors_passed or 0
  if love._console =="3DS" then
    love.graphics.print(doors, 39, 1)
  else
    love.graphics.print(doors, 410, 52)
    end
end
function GUI:displayCoinText()
  love.graphics.setFont(self.font)
  local coins = GameState.coins or 0
  if love._console =="3DS" then
    love.graphics.print(coins, 97, 1)
  else
    love.graphics.print(coins, 410, 110)
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
    love.graphics.setFont(self.font)
    
    
    if love._console =="3DS" then
      local minutes = math.floor(self.timed_level_timer / 60)
      local seconds = math.floor(self.timed_level_timer % 60)
      local time_min = string.format("%d %02d", minutes, seconds)
      love.graphics.print(time_min, 162, 1)
    else
      local minutes = math.floor(self.timed_level_timer / 60)
      local seconds = math.floor(self.timed_level_timer % 60)
      local time_min = string.format("%d", minutes)
      local time_sec = string.format("%02d", seconds)
      love.graphics.print(time_min, 410, 168)
      love.graphics.print(time_sec, 404, 185)
    end

  end
end

return GUI