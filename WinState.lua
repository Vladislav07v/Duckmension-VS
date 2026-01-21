local GameState = require('GameState')
local baton = require('baton')

local mt = {}
mt.__index = mt

function mt:update(dt)
  self.player:update()
      
  local jumpPressed = self.player:pressed('jump')
  if jumpPressed then
    GameState.setCurrent('Play', 1)
  end
end

function mt:draw()
  love.graphics.print('you won\npress (jump) to\nrestart', 80, 80)
end

function mt:trigger()
end

return {
  new = function()
    local state = setmetatable({ name = 'Win' }, mt)
    state.player = baton.new {
      controls = {
        jump = {'key:z','button:b','mouse:1'},
      },
      joystick = love. joystick.getJoysticks()[1],
      deadzone = .33,
    }
    return state
  end
}
