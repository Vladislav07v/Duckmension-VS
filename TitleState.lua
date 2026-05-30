local GameState = require('GameState')
local baton = require('baton')
local Assets = require('assets_shared')

local mt = {}
mt.__index = mt

local buttons = {
  singleplay ={x=20,y=200,w=160,h=30},
  multiplay ={x=220,y=200,w=160,h=30},
}

local buttons3DS = {
  singleplay = {x=75, y=110, w=170, h=20},
  multiplay  = {x=75, y=175, w=170, h=20},
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
      -- DEBUG: draw hitboxes in green
      love.graphics.setColor(0, 1, 0, 1)
      love.graphics.rectangle("line", buttons3DS.singleplay.x, buttons3DS.singleplay.y, buttons3DS.singleplay.w, buttons3DS.singleplay.h)
      love.graphics.rectangle("line", buttons3DS.multiplay.x,  buttons3DS.multiplay.y,  buttons3DS.multiplay.w,  buttons3DS.multiplay.h)
    end
  else
      love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", buttons.singleplay.x, buttons.singleplay.y, buttons.singleplay.w, buttons.singleplay.h)
  love.graphics.rectangle("fill", buttons.multiplay.x, buttons.multiplay.y, buttons.multiplay.w, buttons.multiplay.h)
    love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("line", buttons.singleplay.x, buttons.singleplay.y, buttons.singleplay.w, buttons.singleplay.h)
  love.graphics.rectangle("line", buttons.multiplay.x, buttons.multiplay.y, buttons.multiplay.w, buttons.multiplay.h)
  love.graphics.printf("Singleplay", buttons.singleplay.x-20, buttons.singleplay.y+5, buttons.singleplay.y+2, "center")
  love.graphics.printf("Multiplay", buttons.multiplay.x-20, buttons.multiplay.y+5, buttons.multiplay.y, "center")
  -- DEBUG: draw hitboxes in green (hitbox coords are *3 scaled)
  love.graphics.setColor(0, 1, 0, 1)
  love.graphics.rectangle("line", buttons.singleplay.x*3, buttons.singleplay.y*3, buttons.singleplay.w*3, buttons.singleplay.h*3)
  love.graphics.rectangle("line", buttons.multiplay.x*3,  buttons.multiplay.y*3,  buttons.multiplay.w*3,  buttons.multiplay.h*3)
  end
end

function mt:trigger() end

local function handlePress(x, y)
  if love._console == "3DS" then
    if x >= buttons3DS.singleplay.x and x <= buttons3DS.singleplay.x + buttons3DS.singleplay.w
      and y >= buttons3DS.singleplay.y and y <= buttons3DS.singleplay.y + buttons3DS.singleplay.h then
        GameState.setCurrent('LevelSelect', 0)
        return
      end
    if x >= buttons3DS.multiplay.x and x <= buttons3DS.multiplay.x + buttons3DS.multiplay.w
      and y >= buttons3DS.multiplay.y and y <= buttons3DS.multiplay.y + buttons3DS.multiplay.h then
        GameState.setCurrent('Login')
        return
      end
  else
    if x >= buttons.singleplay.x*3 and x <= buttons.singleplay.x*3 + buttons.singleplay.w*3
      and y >= buttons.singleplay.y*3 and y <= buttons.singleplay.y*3 + buttons.singleplay.h*3 then
        GameState.setCurrent('LevelSelect', 0)
        return
      end
    if x >= buttons.multiplay.x*3 and x <= buttons.multiplay.x*3 + buttons.multiplay.w*3
      and y >= buttons.multiplay.y*3 and y <= buttons.multiplay.y*3 + buttons.multiplay.h*3 then
        GameState.setCurrent('Login')
        return
      end
  end
end

function mt:mousepressed(x, y, button)
  if button ~= 1 then return end
  handlePress(x, y)
end

function mt:touchpressed(id, x, y, dx, dy, pressure)
  if pressure ~= 1 then return end
  handlePress(x, y)
end

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