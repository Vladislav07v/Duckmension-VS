local GameState = require('GameState')
local baton = require('baton')
local Assets = require('assets_shared')
local Network = require('Network')

local mt = {}
mt.__index = mt

local fields = {
  address = { x=20, y=60, w=300, h=30 },
  port =    { x=20, y=130, w=120, h=30 },
  key =     { x=20, y=200, w=300, h=30 },
}

function mt:update(dt)
  self.player:update()
  if self.player:pressed("back") then
    love.keyboard.setTextInput(false)
    GameState.setCurrent('Title')
    return
  end
  if self.player:pressed("jump") then
    self:connectToServer()
  end
end

function mt:draw(screen)
  love.graphics.setFont(self.title_font)
  love.graphics.setColor(1,1,1,1)

  -- Title
  love.graphics.print("Network Settings", 20, 10)

  -- Address
  love.graphics.setColor(1,1,1,1)
  love.graphics.print("Server Address:", fields.address.x, fields.address.y - 25)
  love.graphics.setColor(self.active_field == "address" and {1,1,0,1} or {1,1,1,1})
  love.graphics.rectangle("line", fields.address.x, fields.address.y, fields.address.w, fields.address.h)
  love.graphics.setColor(1,1,1,1)
  love.graphics.print(self.server_address, fields.address.x + 10, fields.address.y + 5)

  -- Port
  love.graphics.setColor(1,1,1,1)
  love.graphics.print("Port:", fields.port.x, fields.port.y - 25)
  love.graphics.setColor(self.active_field == "port" and {1,1,0,1} or {1,1,1,1})
  love.graphics.rectangle("line", fields.port.x, fields.port.y, fields.port.w, fields.port.h)
  love.graphics.setColor(1,1,1,1)
  love.graphics.print(self.server_port, fields.port.x + 10, fields.port.y + 5)

  -- Encryption Key
  love.graphics.setColor(1,1,1,1)
  love.graphics.print("Encryption Key:", fields.key.x, fields.key.y - 25)
  love.graphics.setColor(self.active_field == "key" and {1,1,0,1} or {1,1,1,1})
  love.graphics.rectangle("line", fields.key.x, fields.key.y, fields.key.w, fields.key.h)
  love.graphics.setColor(1,1,1,1)
  love.graphics.print(string.rep("*", #self.encryption_key), fields.key.x + 10, fields.key.y + 5)

  -- Instructions
  love.graphics.setColor(0.7, 0.7, 0.7, 1)
  love.graphics.setFont(self.small_font)
  love.graphics.print("Click a field to edit", 20, fields.key.y + 50)
  love.graphics.print("Press (jump) to connect", 20, fields.key.y + 75)
  love.graphics.print("Press (back) to return to title", 20, fields.key.y + 100)
end

function mt:mousepressed(x, y, button)
  if button ~= 1 then return end
  
  -- Check which field was clicked
  for fname, rect in pairs(fields) do
    if x >= rect.x*3 and x <= rect.x*3 + rect.w*3 and y >= rect.y*3 and y <= rect.y*3 + rect.h*3 then
      self.active_field = fname
      love.keyboard.setTextInput(true)
      return
    end
  end
  
  -- Deselect if clicking outside fields
  self.active_field = nil
  love.keyboard.setTextInput(false)
end

function mt:touchpressed(id, x, y, dx, dy, pressure)
  if pressure ~= 1 then return end
  
  -- Check which field was pressed
  for fname, rect in pairs(fields) do
    if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
      self.active_field = fname
      love.keyboard.setTextInput(true)
      return
    end
  end
  
  -- Deselect if pressing outside fields
  self.active_field = nil
  love.keyboard.setTextInput(false)
end

function mt:keypressed(key)
  if not self.active_field then return end
  
  if key == "backspace" then
    if self.active_field == "address" then
      self.server_address = self.server_address:sub(1, -2)
    elseif self.active_field == "port" then
      self.server_port = self.server_port:sub(1, -2)
    elseif self.active_field == "key" then
      self.encryption_key = self.encryption_key:sub(1, -2)
    end
  elseif key:len() == 1 then
    if self.active_field == "address" then
      self.server_address = self.server_address .. key
    elseif self.active_field == "port" then
      if tonumber(key) then
        self.server_port = self.server_port .. key
      end
    elseif self.active_field == "key" then
      self.encryption_key = self.encryption_key .. key
    end
  end
end

function mt:textinput(text)
  if not self.active_field then return end
  
  if self.active_field == "address" then
    self.server_address = self.server_address .. text
  elseif self.active_field == "port" then
    -- Only allow numeric input for port
    if tonumber(text) then
      self.server_port = self.server_port .. text
    end
  elseif self.active_field == "key" then
    self.encryption_key = self.encryption_key .. text
  end
end

function mt:connectToServer()
  local port = tonumber(self.server_port) or 12345
  Network:init(self.server_address, port, self.encryption_key)
  print("Connecting to " .. self.server_address .. ":" .. port)
  print("Encryption key set to: " .. self.encryption_key)
  love.keyboard.setTextInput(false)
  GameState.setCurrent('Title')
end

function mt:trigger() end

return {
  new = function()
    local state = setmetatable({
      name = 'Settings_State',
      server_address = "localhost",
      server_port = "12345",
      encryption_key = "",
      active_field = nil
    }, mt)

    state.player = baton.new {
      controls = {
        jump = {'key:z','button:b'},
        back = {'key:escape','button:back'},
        backspace = {'key:backspace','button:a'},
      },
      joystick = love.joystick.getJoysticks()[1],
      deadzone = .33,
    }
    state.title_font = love.graphics.newFont("assets/bit.ttf", 20)
    state.small_font = love.graphics.newFont("assets/bit.ttf", 14)
    return state
  end
}