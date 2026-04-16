local GameState = require('GameState')
local baton = require('baton')
local Assets = require('assets_shared')

local mt = {}
mt.__index = mt

function mt:loadAssets()
  -- preload and reuse images via shared cache
  if not self.title_image then
    self.title_image = Assets.load('assets/title_temp.png', 'title')
  end
  if not self.bottom_image then
    self.bottom_image = Assets.load('assets/bg_dark.png', 'bg_dark')
  end
  if not self.title_font then
    self.title_font = love.graphics.newFont("assets/upheavtt.ttf", 30)
  end
end

function mt:update(dt)
  self.player:update()
  if self.player:pressed("start") then
    GameState.setCurrent('Play', 0)
  end
  if self.player:pressed("change") then
    GameState.setCurrent('Settings')
  end
end

function mt:draw(screen)
  self:loadAssets()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self.title_image, 0, 0)

  if screen == "bottom" then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.title_font)
    love.graphics.draw(self.bottom_image, 0, 0)
    love.graphics.printf("Press (jump) to Start", 0, love.graphics.getHeight()-130, love.graphics.getWidth()-70, "center")
    love.graphics.printf("Press (change) for Network", 0, love.graphics.getHeight()-65, love.graphics.getWidth()-70, "center")
  end
end

function mt:trigger() end

return {
  new = function()
    local state = setmetatable({name = 'Title_State'}, mt)
    state.player = baton.new {
      controls = {
        start = {'key:z','button:b','mouse:1'},
        change = {'key:x','button:a'},
      },
      joystick = love.joystick.getJoysticks()[1],
      deadzone = .33,
    }
    -- preload assets/font so draw doesn't allocate on first frame
    state:loadAssets()
    return state
  end
}