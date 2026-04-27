local GameState = require('GameState')
local baton = require('baton')
local Assets = require('assets_shared')

local mt = {}
mt.__index = mt

local fields = {
  singleplay ={x=20,y=200,w=160,h=30},
  multiplay ={x=220,y=200,w=160,h=30},
  }

function mt:loadAssets()
  -- preload and reuse images via shared cache
  if not self.title_image then
    self.title_image = Assets.load('assets/title.png', 'title')
  end
  if not self.bottom_image then
    self.bottom_image = Assets.load('assets/bg_dark.png', 'bg_dark')
  end
  if not self.title_font then
    self.title_font = love.graphics.newFont("assets/upheavtt.ttf", 20)
  end
end

function mt:update(dt)
  self.player:update()
  if self.player:pressed("start") then
    GameState.setCurrent('LevelSelect', 0)
  end
  if self.player:pressed("change") then
    GameState.setCurrent('Settings')
  end
end

function mt:draw(screen)
  self:loadAssets()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self.title_image, 0, 0)
  love.graphics.setFont(self.title_font)
  if love._console =="3DS" then
    if screen == "bottom" then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(self.bottom_image, 0, 0)
      love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", 75, 110, 170, 20)
  love.graphics.rectangle("fill",75,175,170,20)
    love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("line", 75, 110, 170, 20)
  love.graphics.rectangle("line",75,175,170,20)
      love.graphics.printf("Singleplay (B)",20,110,280,"center")
      love.graphics.printf("Multiplay (A)",20,175,280, "center")
    end
  else
      love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", fields.singleplay.x, fields.singleplay.y, fields.singleplay.w, fields.singleplay.h)
  love.graphics.rectangle("fill", fields.multiplay.x, fields.multiplay.y, fields.multiplay.w, fields.multiplay.h)
    love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("line", fields.singleplay.x, fields.singleplay.y, fields.singleplay.w, fields.singleplay.h)
  love.graphics.rectangle("line", fields.multiplay.x, fields.multiplay.y, fields.multiplay.w, fields.multiplay.h)
  love.graphics.printf("Singleplay (Z)", fields.singleplay.x-20, fields.singleplay.y+5, fields.singleplay.y+2, "center")
  love.graphics.printf("Multiplay (X)", fields.multiplay.x-20, fields.multiplay.y+5, fields.multiplay.y, "center")
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