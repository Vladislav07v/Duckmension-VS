--require('nest-master/nest').init({console = "3ds", emulateJoystick="true", scale=2})
local GameState  = require('GameState')
local TitleState = require('TitleState')
local GUI = require('gui')
local Music = require('Music')
GameState.network = require('Network')

-- Fixed timestep params
local PHYSICS_STEP = 1 / 30         -- physics tick (seconds)
local MAX_DT = 0.25                 -- clamp incoming dt to avoid spiral-of-death
local accumulator = 0

function love.load()
  GameState.setCurrent('Title')
  love.graphics.setDefaultFilter('nearest', 'nearest')
  
end

function love.update(dt)
  -- clamp very large dt (caused by loading, paused debugger, CPU hiccups)
  if dt > MAX_DT then dt = MAX_DT end

  accumulator = accumulator + dt

  -- run fixed-size physics/logic steps
  while accumulator >= PHYSICS_STEP do
    -- apply pending state switch before each physics tick so setCurrent() takes effect immediately
    GameState.update()

    local current_state = GameState.getCurrent()
    if current_state and current_state.update then
      -- pass a stable physics step to all state updates
      current_state:update(PHYSICS_STEP)
    end

    accumulator = accumulator - PHYSICS_STEP
  end

  -- run once-per-frame non-physics updates (music, UI timers if desired)
  Music:update()
    
  function love.keypressed(key)
    local current_state = GameState.getCurrent()
    if current_state and current_state.keypressed then
    current_state:keypressed(key)
    end
  end

  function love.mousepressed(x, y, button)
    local current_state = GameState.getCurrent()
    if current_state and current_state.mousepressed then
      current_state:mousepressed(x, y, button)
    end
  end

  function love.touchpressed(id, x, y, dx, dy, pressure)
    local current_state = GameState.getCurrent()
    if current_state and current_state.touchpressed then
      current_state:touchpressed(id, x, y, dx, dy, pressure)
    end
  end
end

function love.draw(screen)
  if love._console =="3DS" then
    love.graphics.scale(1, 1)
    local currentState = GameState.getCurrent()
    if currentState and currentState.background then
      love.graphics.draw(currentState.background)
    end

    if currentState and currentState.draw then
      currentState:draw(screen)
    end

    if screen == "bottom" and currentState and currentState.bottombg then
      love.graphics.setColor(1,1,1,1)
      love.graphics.draw(currentState.bottombg)
      GUI:draw()
      love.graphics.print(love.timer.getFPS())
    end
  elseif love._console=="WiiU" then
    love.graphics.scale(3, 3)
    local currentState = GameState.getCurrent()
    if currentState and currentState.background then
      love.graphics.draw(currentState.background)
    end

    if currentState and currentState.draw then
      currentState:draw(screen)
    end

    if screen == "bottom" and currentState and currentState.bottombg then
      love.graphics.setColor(1,1,1,1)
      love.graphics.draw(currentState.bottombg)
      GUI:draw()
      love.graphics.print(love.timer.getFPS())
    end
  else
    love.graphics.scale(3, 3)
    local currentState = GameState.getCurrent()
    if currentState and currentState.background then
      love.graphics.draw(currentState.background)
      GUI:draw()
      love.graphics.print(love.timer.getFPS())
    end

    if currentState and currentState.draw then
      currentState:draw(screen)
    end
  end
end
