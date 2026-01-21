--require('nest-master/nest').init({console = "3ds", emulateJoystick="true", scale=3})
local GameState  = require('GameState')
local TitleState = require('TitleState')
local GUI = require('gui')
local Music = require('Music')

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
  
end

function love.draw(screen)
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
end