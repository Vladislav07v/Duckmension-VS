local assets = require('assets_duck')
local GameState = require('GameState')
local Animation = require('Animation')
local ToggleFloor = require('ToggleFloor')
local RevToggleFloor = require('ReverseToggleFloor')
local baton = require('baton')

local GRAVITY = 900
local JUMP_SPEED = -400
local ducksprite = "assets/duck.png"
local invducksprite = "assets/duck_inv.png"

local mt = {}
mt.__index = mt

function mt:update(dt)
  self.player:update()

  local jumpPressed = self.player:pressed('jump')
  local leftPressed = self.player:down('left')
  local rightPressed = self.player:down('right')
  local dimensionPressed = self.player:pressed('dimension')
  local cheatPressed = self.player:pressed('cheat')

  if self.is_disabled then return end

  self:setAnim('idle')

  -- Go forward a level
  if cheatPressed then
    GameState.getCurrent():trigger('door:open')
  end
  
  -- Handle jumping
  if jumpPressed and not self.was_jump_pressed_in_previous_frame and self: isGrounded() then
    self:setAnim('jump')
    self.vy = JUMP_SPEED
  end

  -- Horizontal movement (velocity, not position)
  local dx = 0
  if leftPressed then
    self:setAnim('run')
    self.last_direction = -1
    dx = dx - self.speed * dt
  end
  if rightPressed then
    self:setAnim('run')
    self.last_direction = 1
    dx = dx + self.speed * dt
  end

  -- Apply gravity to vertical velocity
  self.vy = self.vy + GRAVITY * dt

  -- Move with physics, using dt
  local new_x = self.x + dx
  local new_y = self.y + self.vy * dt

  -- Use your world/collision system to move the duck
  GameState.getCurrent().world:move(self, new_x, new_y, 'is_solid')

  -- Kill the duck if it falls below the screen
  if self.y > 250 then
    GameState.getCurrent():trigger('duck:kill', self, self)
    return
  end

  -- If grounded, stop vertical movement
  if self:isGrounded() then
    self.vy = -1
    if jumpPressed then
      self:setAnim('jump')
    elseif leftPressed or rightPressed then
      self:setAnim('run')
    else
      self:setAnim('idle')
    end
  else
    self:setAnim('jump')
  end

  -- Check collision from above
  if self.vy < 0 and self:isCollidingAbove() then
    self.vy = 0
  end

  -- Dimension toggle action
  if dimensionPressed and not self.was_dimension_pressed_in_previous_frame then
    if self.is_light_dimension then
      assets.setDuckSprite(ducksprite)
      assets.setDuckColor(219, 186, 74)
      self.is_light_dimension = false
    else
      assets.setDuckSprite(invducksprite)
      assets.setDuckColor(239, 154, 239)
      self.is_light_dimension = true
    end
    
    -- floor toggle code
    local floors = GameState.getCurrent().world:find('all', 'is_toggle_floor')
    local revfloors = GameState.getCurrent().world:find('all', 'is_toggle_reversefloor')
    for _, floor in ipairs(floors) do
      floor:toggle()
    end
    for _, revfloor in ipairs(revfloors) do
      revfloor:toggle()
    end
    self.dimension_toggled = true
  end

  -- Touch handling
  local touchables = GameState.getCurrent().world:find(self, 'is_touchable')
  for _, touchable in ipairs(touchables) do
    touchable:onTouch(self)
  end

  -- Animation update
  self.current_anim:update(dt)

  -- Store previous frame input state
  self.was_jump_pressed_in_previous_frame = jumpPressed
  self.was_dimension_pressed_in_previous_frame = dimensionPressed
end

function mt:draw()
  if self.last_direction == -1 then
    assets.qdraw(self.current_anim:getFrame(), self.x + 32 - 6, self.y, 0, -1, 1)
  else
    assets.qdraw(self.current_anim:getFrame(), self.x - 6, self.y)
  end
end

function mt:setAnim(name)
  self.current_anim = self.anims[name]
end

function mt:isGrounded()
  return GameState.getCurrent().world:check({ x = self.x, y = self.y + self.h, w = self.w, h = 2 }, 'is_solid')
end

function mt:isCollidingAbove()
  -- Check for solid objects directly above the duck
  return GameState.getCurrent().world:check({
    x = self.x,
    y = self.y - 1,
    w = self.w,
    h = 2
  }, 'is_solid')
end

return {
  new = function(x, y)
    local state = baton.new {
      controls = {
        left = {'key:left','key:a','axis:leftx-','button:dpleft'},
        right = {'key:right','key:d','axis:leftx+','button:dpright'},
        up = {'key:up','axis:lefty-','button:dpup'},
        down = {'key:down','axis:lefty+','button:dpdown'},
        dimension = {'key:x','button:a','mouse:2'},
        jump = {'key:z','button:b','mouse:1'},
        cheat = {'key:1','button:back'},
      },
      pairs = {
        move = {'left','right','up','down'}
      },
      joystick = love.joystick.getJoysticks()[1],
      deadzone = .33,
    }

    local h = setmetatable({       
      is_duck = true,
      player = state,
      x = x,
      y = y,
      w = 20,
      h = 30,
      vy = 0,
      speed = 250,
      last_direction = 1,
      is_light_dimension = false,
      is_disabled = false,
      was_jump_pressed_in_previous_frame = false,
      was_dimension_pressed_in_previous_frame = false,
      anims = {
        idle = Animation.new(1, 8, 1),
        run = Animation.new(9, 8, 0.75),
        jump = Animation.new(17, 8, 0.75)},
      z_index = 10
    }, mt)
    
    h: setAnim('idle')
    -- ensure assets module uses the right starting sprite & color
    assets.setDuckSprite("assets/duck.png")
    assets.setDuckColor(219, 186, 74)
    return h
  end
}