local GameState = require('GameState')
local baton = require('baton')
local Assets = require('assets_shared')
local Network = require('Network')

local mt = {}
mt.__index = mt

local fields = {
  address = { x=20, y=45, w=200, h=30 },
  port =    { x=20, y=85, w=120, h=30 },
  key =     { x=20, y=125, w=200, h=30 },
}

local buttons = {
  singleplay ={x=20,y=200,w=160,h=30},
  multiplay ={x=220,y=200,w=160,h=30},
}

function mt:loadAssets()
  -- preload and reuse images via shared cache
  if not self.title_image then
    self.title_image = Assets.load('assets/title.png', 'title')
  end
  if not self.title_font then
    self.title_font = love.graphics.newFont("assets/ari_dis.ttf", 11)
  end
end
function mt:update(dt)
  self.player:update()
  
  -- Network update
  if self.network_instance then
    self.network_instance:update()
  end
end

function mt:draw(screen)
  self:loadAssets()
  love.graphics.setFont(self.title_font)
  love.graphics.setColor(1,1,1,1)

  -- Title
  love.graphics.print("Network Settings", 20, 10)

  -- Address
  love.graphics.setColor(1,1,1,1)
  love.graphics.print(":Server", fields.address.x+203, fields.address.y)
  love.graphics.print("Address", fields.address.x+203, fields.address.y+15)
  love.graphics.setColor(self.active_field == "address" and {1,1,0,1} or {1,1,1,1})
  love.graphics.rectangle("line", fields.address.x, fields.address.y, fields.address.w, fields.address.h)
  love.graphics.setColor(1,1,1,1)
  love.graphics.print(self.server_address, fields.address.x + 15, fields.address.y + 10)

  -- Port
  love.graphics.setColor(1,1,1,1)
  love.graphics.print(":Port", fields.port.x+123, fields.port.y+6)
  love.graphics.setColor(self.active_field == "port" and {1,1,0,1} or {1,1,1,1})
  love.graphics.rectangle("line", fields.port.x, fields.port.y, fields.port.w, fields.port.h)
  love.graphics.setColor(1,1,1,1)
  love.graphics.print(self.server_port, fields.port.x + 15, fields.port.y + 10)

  -- Encryption Key
  love.graphics.setColor(1,1,1,1)
  love.graphics.print(":Encryption", fields.key.x+203, fields.key.y)
  love.graphics.print("Key", fields.key.x+203, fields.key.y+15)
  love.graphics.setColor(self.active_field == "key" and {1,1,0,1} or {1,1,1,1})
  love.graphics.rectangle("line", fields.key.x, fields.key.y, fields.key.w, fields.key.h)
  love.graphics.setColor(1,1,1,1)
  love.graphics.print(string.rep("*", #self.encryption_key), fields.key.x + 15, fields.key.y + 10)

  -- Connection Status and Error Message
  --love.graphics.setFont(self.small_font)
  local status_y = 10
  
  if self.network_instance and self.network_instance:isConnected() then
    love.graphics.setColor(0.2, 1, 0.2, 1)
    love.graphics.print("Connected & Verified", 240 - string.len("Not logged in"), status_y)
  elseif self.network_instance and self.network_instance.connected then
    love.graphics.setColor(1, 1, 0.2, 1)
    love.graphics.print("Connected (waiting to verify...)", 240 - string.len("Not logged in"), status_y)
  else
    love.graphics.setColor(1, 0.2, 0.2, 1)
    love.graphics.print("Disconnected", 240 - string.len("Not logged in"), status_y)
  end
  
  -- Display error message if any
  if self.network_instance and self.network_instance:getLastError() then
    love.graphics.setColor(1, 0.5, 0.5, 1)
    love.graphics.print("Error: " .. self.network_instance:getLastError(), 20, status_y + 15)
  end

  -- Instructions
  love.graphics.setColor(0.7, 0.7, 0.7, 1)
  love.graphics.print("Click a field to edit", 20, status_y + 150)
  
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", buttons.singleplay.x, buttons.singleplay.y, buttons.singleplay.w, buttons.singleplay.h)
  love.graphics.rectangle("fill", buttons.multiplay.x, buttons.multiplay.y, buttons.multiplay.w, buttons.multiplay.h)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("line", buttons.singleplay.x, buttons.singleplay.y, buttons.singleplay.w, buttons.singleplay.h)
  love.graphics.rectangle("line", buttons.multiplay.x, buttons.multiplay.y, buttons.multiplay.w, buttons.multiplay.h)
  love.graphics.printf("CONNECT", buttons.singleplay.x-20, buttons.singleplay.y+10, buttons.singleplay.y+2, "center")
  love.graphics.printf("BACK", buttons.multiplay.x-20, buttons.multiplay.y+10, buttons.multiplay.y, "center")
  
  if love._console =="3DS" and screen ~= "bottom" then
    love.graphics.draw(self.title_image,0,0)
    else
  end
end

function mt:activateField(fname)
  self.active_field = fname
  self.field_just_activated = true  -- next input replaces instead of appending
  love.keyboard.setTextInput(true)
end

function mt:mousepressed(x, y, button)
    if button ~= 1 then return end

    for fname, rect in pairs(fields) do
        if x >= rect.x*3 and x <= rect.x*3 + rect.w*3
        and y >= rect.y*3 and y <= rect.y*3 + rect.h*3 then
            self:activateField(fname)
            return
        end
    end

  if x >= buttons.singleplay.x*3 and x <= buttons.singleplay.x*3 + buttons.singleplay.w*3
    and y >= buttons.singleplay.y*3 and y <= buttons.singleplay.y*3 + buttons.singleplay.h*3 then
      self:connectToServer()
      return
    end
    
  if x >= buttons.multiplay.x*3 and x <= buttons.multiplay.x*3 + buttons.multiplay.w*3
    and y >= buttons.multiplay.y*3 and y <= buttons.multiplay.y*3 + buttons.multiplay.h*3 then
      love.keyboard.setTextInput(false)
      GameState.setCurrent('Play',0)
      return
    end
    
    self.active_field = nil
    self.field_just_activated = false
    love.keyboard.setTextInput(false)
end

function mt:touchpressed(id, x, y, dx, dy, pressure)
    if pressure ~= 1 then return end

    for fname, rect in pairs(fields) do
        if x >= rect.x and x <= rect.x + rect.w
        and y >= rect.y and y <= rect.y + rect.h then
            self:activateField(fname)
            return
        end
    end
    
  if x >= buttons.singleplay.x*3 and x <= buttons.singleplay.x*3 + buttons.singleplay.w*3
    and y >= buttons.singleplay.y*3 and y <= buttons.singleplay.y*3 + buttons.singleplay.h*3 then
      self:connectToServer()
      return
    end
    
  if x >= buttons.multiplay.x*3 and x <= buttons.multiplay.x*3 + buttons.multiplay.w*3
    and y >= buttons.multiplay.y*3 and y <= buttons.multiplay.y*3 + buttons.multiplay.h*3 then
      love.keyboard.setTextInput(false)
      GameState.setCurrent('Play',0)
      return
    end

    self.active_field = nil
    self.field_just_activated = false
    love.keyboard.setTextInput(false)
end

function mt:keypressed(key)
  if not self.active_field then return end
  
  if key == "backspace" then
    -- Just-focused: backspace clears the whole field (mirrors select-all behaviour)
    if self.field_just_activated then
      if     self.active_field == "address" then self.server_address = ""
      elseif self.active_field == "port"    then self.server_port    = ""
      elseif self.active_field == "key"     then self.encryption_key = ""
      end
      self.field_just_activated = false
    else
      if self.active_field == "address" then
        self.server_address = self.server_address:sub(1, -2)
      elseif self.active_field == "port" then
        self.server_port = self.server_port:sub(1, -2)
      elseif self.active_field == "key" then
        self.encryption_key = self.encryption_key:sub(1, -2)
      end
    end
  end
end

function mt:textinput(text)
  if not self.active_field then return end
  
  -- First character after focusing replaces the whole field (select-all-on-focus)
  if self.field_just_activated then
    if self.active_field == "address" then
      self.server_address = text
    elseif self.active_field == "port" then
      if tonumber(text) then self.server_port = text end
    elseif self.active_field == "key" then
      self.encryption_key = text
    end
    self.field_just_activated = false
    return
  end

  -- Subsequent characters append normally
  if self.active_field == "address" then
    self.server_address = self.server_address .. text
  elseif self.active_field == "port" then
    if tonumber(text) then
      self.server_port = self.server_port .. text
    end
  elseif self.active_field == "key" then
    self.encryption_key = self.encryption_key .. text
  end
end

function mt:connectToServer()
  print("\n" .. string.rep("=", 80))
  print("[SettingsState] Connect button pressed")
  print(string.format("  Address field: '%s'", self.server_address))
  print(string.format("  Port field: '%s'", self.server_port))
  print(string.format("  Key field: '%s'", self.encryption_key))
  print(string.rep("=", 80))
  
  -- Validate inputs
  if not self.server_address or self.server_address == "" then
    print("[SettingsState] ERROR: Address is empty!")
    return
  end
  
  if not self.server_port or self.server_port == "" then
    print("[SettingsState] ERROR: Port is empty!")
    return
  end
  
  local port = tonumber(self.server_port)
  if not port then
    print(string.format("[SettingsState] ERROR: Port '%s' is not a valid number!", self.server_port))
    return
  end
  
  if not self.network_instance then
    self.network_instance = Network
  end
  
  -- Initialize network with validated parameters
  self.network_instance:init(self.server_address, port, self.encryption_key)
end

function mt:trigger() end

return {
  new = function()
    local state = setmetatable({
      name = 'Settings_State',
      server_address = "000.000.00.000",
      server_port = "12345",
      encryption_key = "default-key",
      active_field = nil,
      network_instance = nil,
    }, mt)

    state.player = baton.new {
      controls = {
        jump = {'key:return','button:b'},
        back = {'key:escape','button:back'},
        backspace = {'key:backspace','button:a'},
      },
      joystick = love.joystick.getJoysticks()[1],
      deadzone = .33,
    }
    return state
  end
}