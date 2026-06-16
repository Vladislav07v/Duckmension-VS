local GameState = require('GameState')
local baton = require('baton')
local Assets = require('assets_shared')

local mt = {}
mt.__index = mt

local MAX_LEVEL = 50

local buttons = {
  singleplay = {x=20,  y=200, w=160, h=30},
  multiplay  = {x=220, y=200, w=160, h=30},
}

-- ── Actions ───────────────────────────────────────────────────────────────────

local function doStart(state)
  GameState.setCurrent('Play', state.selected_level)
end

-- ── State methods ─────────────────────────────────────────────────────────────

function mt:update(dt)
  self.player:update()

  -- Navigate levels with arrow keys or analog stick
  if self.player:pressed("left") then
    self.selected_level = math.max(self.selected_level - 1, 1)
  end
  if self.player:pressed("right") then
    self.selected_level = math.min(self.selected_level + 1, MAX_LEVEL)
  end

  -- Left button: enter selected level
  if self.player:pressed("jump") then
    doStart(self)
  end

  -- Right button: go back
  if self.player:pressed("change") then
    GameState.setCurrent('Title')
  end
end

local function handlePress(state, x, y)
  if x >= buttons.singleplay.x*3 and x <= buttons.singleplay.x*3 + buttons.singleplay.w*3
  and y >= buttons.singleplay.y*3 and y <= buttons.singleplay.y*3 + buttons.singleplay.h*3 then
    doStart(state)
    return
  end

  if x >= buttons.multiplay.x*3 and x <= buttons.multiplay.x*3 + buttons.multiplay.w*3
  and y >= buttons.multiplay.y*3 and y <= buttons.multiplay.y*3 + buttons.multiplay.h*3 then
      GameState.setCurrent('Title')
    return
  end
end

function mt:mousepressed(x, y, button)
  if button ~= 1 then return end
  handlePress(self, x, y)
end

function mt:touchpressed(id, x, y, dx, dy, pressure)
  if pressure ~= 1 then return end
  handlePress(self, x, y)
end

function mt:draw()
  love.graphics.setFont(self.title_font)
  love.graphics.setColor(1, 1, 1, 1)

  -- Title
  love.graphics.print("Level Select", 20, 10)

  -- Status
  if GameState.network then
    love.graphics.setColor(1, 0.5, 0.5, 1)
    love.graphics.print("Disconnect from server first!", 20, 50)
  end

  -- Display current selection
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Selected Level: " .. self.selected_level, 20, 100)

  -- Navigation help
  love.graphics.setColor(0.8, 0.8, 0.8, 1)
  love.graphics.print("LEFT/RIGHT - Navigate | (jump) - Start | (change) - Back", 20, 150)

  -- Buttons
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", buttons.singleplay.x, buttons.singleplay.y, buttons.singleplay.w, buttons.singleplay.h)
  love.graphics.rectangle("fill", buttons.multiplay.x,  buttons.multiplay.y,  buttons.multiplay.w,  buttons.multiplay.h)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("line", buttons.singleplay.x, buttons.singleplay.y, buttons.singleplay.w, buttons.singleplay.h)
  love.graphics.rectangle("line", buttons.multiplay.x,  buttons.multiplay.y,  buttons.multiplay.w,  buttons.multiplay.h)
  love.graphics.printf("START (B)", buttons.singleplay.x - 20, buttons.singleplay.y + 10, buttons.singleplay.y + 2, "center")
  love.graphics.printf("BACK (A)",  buttons.multiplay.x  - 20, buttons.multiplay.y  + 10, buttons.multiplay.y,     "center")
end

function mt:trigger() end

-- ── Constructor ───────────────────────────────────────────────────────────────

return {
  new = function()
    local state = setmetatable({ name = 'LevelSelect_State' }, mt)

    -- Load font
    state.title_font = love.graphics.newFont("assets/ari_dis.ttf", 11)

    -- Initialize player controller
    state.player = baton.new {
      controls = {
        jump   = {'key:z', 'button:a'},
        change = {'key:x', 'button:b'},
        left   = {'key:left',  'button:dpleft',  'axis:leftx-'},
        right  = {'key:right', 'button:dpright', 'axis:leftx+'},
      },
      joystick = love.joystick.getJoysticks()[1],
      deadzone = .33,
    }

    state.selected_level = 1
    return state
  end
}