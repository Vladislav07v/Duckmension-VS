local GameState = require('GameState')
local baton = require('baton')
local Duck = require('Duck')
local mt = {}
mt.__index = mt
local player = baton.new {
	controls = {
    jump = {'key:z', 'button:b', 'mouse:1'},
	},
	joystick = love.joystick.getJoysticks()[1],
	deadzone = .33,
}
function mt:update(dt)
      player:update()
      
      local jumpPressed = player:pressed('jump')
  if jumpPressed then
    GameState.doors_passed = math.max((GameState.doors_passed or 1) - 1, 0)
    GameState.setCurrent('Play', 1)
  end
end

function mt:draw()
  love.graphics.print('game over\npress (jump) to\nrestart', 80, 80)
end

function mt:trigger()
end


return {
  new = function() 
    return setmetatable({ name = 'dead_state' }, mt)
  end
}
