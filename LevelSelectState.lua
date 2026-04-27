local GameState = require('GameState')
local baton = require('baton')
local Assets = require('assets_shared')

local mt = {}
mt.__index = mt

local MAX_LEVEL = 50

function mt:update(dt)
  self.player:update()
  
  -- Navigate levels with arrow keys or analog stick
  if self.player:pressed("left") then
    self.selected_level = math.max(self.selected_level - 1, 1)
  end
  if self.player:pressed("right") then
    self.selected_level = math.min(self.selected_level + 1, MAX_LEVEL)
  end
  
  -- Select current level to play
  if self.player:pressed("jump") then
    GameState.setCurrent('Play', self.selected_level)
  end
  
  -- Exit level select (only if not connected to server)
  if self.player:pressed("back") and not GameState.network then
    GameState.setCurrent('Title')
  end
end

function mt:draw()
  love.graphics.setFont(self.title_font)
  love.graphics.setColor(1, 1, 1, 1)
  
  -- Title
  love.graphics.print("Level Select", 20, 10)
  
  -- Status
  if GameState.network then
    love.graphics.setColor(1, 0.5, 0.5, 1)
    love.graphics.print("(Connected to server - level select disabled)", 20, 50)
  else
    love.graphics.setColor(0.5, 1, 0.5, 1)
    love.graphics.print("(Not connected - free play mode)", 20, 50)
  end
  
  -- Display current selection
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Selected Level: " .. self.selected_level, 20, 100)
  
  -- Navigation help
  love.graphics.setFont(self.small_font)
  love.graphics.setColor(0.8, 0.8, 0.8, 1)
  love.graphics.print("LEFT/RIGHT - Navigate | (jump) - Select | (back) - Exit", 20, 150)
end

function mt:trigger()
end

return {
  new = function()
    local state = setmetatable({ name = 'LevelSelect_State' }, mt)
    
    -- Load fonts
    if not state.title_font then
      state.title_font = love.graphics.newFont("assets/upheavtt.ttf", 20)
    end
    if not state.small_font then
      state.small_font = love.graphics.newFont("assets/upheavtt.ttf", 10)
    end
    
    -- Initialize player controller
    state.player = baton.new {
      controls = {
        jump = {'key:c','button:b','mouse:1'},
        back = {'key:x','button:a'},
        left = {'key:left','button:dpleft','axis:leftx-'},
        right = {'key:right','button:dpright','axis:leftx+'},
      },
      joystick = love.joystick.getJoysticks()[1],
      deadzone = .33,
    }
    
    state.selected_level = 1
    
    return state
  end

}