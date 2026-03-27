-- Network module for UDP communication with server
-- Integrates with the game's GameState and World systems

local socket = require "socket"
local Animation = require('Animation')
local assets_duck = require('assets_duck')

local Network = {}
Network.enabled = false
Network.entity = nil
Network.udp = nil
Network.address = "localhost"
Network.port = 12345
Network.updaterate = 0.1
Network.accumulator = 0
Network.world = {} -- remote entities state
Network.encryption_key = "default_key"
Network.remote_ducks = {} -- track remote duck animations

-- Simple XOR encryption function
local function simpleEncrypt(text, key)
  local encrypted = ""
  key = key or "default_key"
  for i = 1, #text do
    local char = text:sub(i, i)
    local keyChar = key:sub((i - 1) % #key + 1, (i - 1) % #key + 1)
    encrypted = encrypted .. string.char(bit.bxor(string.byte(char), string.byte(keyChar)))
  end
  return encrypted
end

-- Convert encrypted binary to hex string for display
local function toHex(str)
  local hex = ""
  for i = 1, #str do
    hex = hex .. string.format("%02x", string.byte(str:sub(i, i)))
  end
  return hex
end

-- Initialize network connection
function Network:init(address, port, encryption_key)
  self.address = address or "localhost"
  self.port = port or 12345
  self.encryption_key = encryption_key or "default_key"
  
  self.udp = socket.udp()
  self.udp:settimeout(0)
  self.udp:setpeername(self.address, self.port)
  
  -- Generate unique entity ID
  math.randomseed(os.time())
  self.entity = tostring(math.random(99999))
  
  self.enabled = true
  self.accumulator = 0
  
  -- Encrypt entity ID for initial message
  local encrypted_entity = simpleEncrypt(self.entity, self.encryption_key)
  local encrypted_hex = toHex(encrypted_entity)
  
  -- Send initial position (will be filled in by game)
  local dg = string.format("%s %s %d %d", encrypted_hex, 'at', 320, 240)
  self.udp:send(dg)
  
  print("Network initialized.")
  print("  Server: " .. self.address .. ":" .. self.port)
  print("  Entity ID: " .. self.entity .. " (encrypted: " .. encrypted_hex .. ")")
  print("  Encryption key: " .. self.encryption_key)
end

-- Send duck position update
function Network:sendDuckPosition(x, y)
  if not self.enabled or not self.udp then return end
  
  self.accumulator = self.accumulator + (self.lastDt or 0.016)
  
  if self.accumulator > self.updaterate then
    local encrypted_entity = simpleEncrypt(self.entity, self.encryption_key)
    local encrypted_hex = toHex(encrypted_entity)
    
    local dg = string.format("%s %s %f %f", encrypted_hex, 'at', x, y)
    self.udp:send(dg)
    
    -- Request world state update
    local dg_update = string.format("%s %s $", encrypted_hex, 'update')
    self.udp:send(dg_update)
    
    self.accumulator = self.accumulator - self.updaterate
  end
end

-- Receive and process network messages
function Network:update(dt)
  if not self.enabled or not self.udp then return end
  
  self.lastDt = dt
  
  -- Update animations for all remote ducks
  for ent_id, duck_data in pairs(self.remote_ducks) do
    if duck_data.anim then
      duck_data.anim:update(dt)
    end
  end
  
  repeat
    local data, msg = self.udp:receive()
    
    if data then
      local ent, cmd, parms = data:match("^(%S*) (%S*) (.*)")
      
      if cmd == 'at' then
        -- Parse position update
        local x, y = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
        if x and y then
          x, y = tonumber(x), tonumber(y)
          self.world[ent] = { x = x, y = y }
          
          -- Initialize animation for this remote duck if not exists
          if not self.remote_ducks[ent] then
            self.remote_ducks[ent] = {
              anim = Animation.new(1, 8, 1), -- idle animation
              direction = 1 -- 1 for right, -1 for left
            }
          end
        end
      elseif cmd == 'move' then
        -- Handle move commands if needed
        local x, y = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
        if x and y then
          x, y = tonumber(x), tonumber(y)
          if self.world[ent] then
            self.world[ent].x = self.world[ent].x + x
            self.world[ent].y = self.world[ent].y + y
          else
            self.world[ent] = { x = x, y = y }
          end
        end
      else
        print("Unrecognised network command:", cmd)
      end
    elseif msg ~= 'timeout' then
      print("Network error: " .. tostring(msg))
    end
  until not data
end

-- Draw remote entities as semi-transparent animated ducks
function Network:draw()
  if not self.enabled then return end
  
  love.graphics.setColor(0.5, 0.5, 0.5, 0.5) -- Semi-transparent white
  
  for ent, pos in pairs(self.world) do
    if ent ~= self.entity then
      local duck_data = self.remote_ducks[ent]
      if duck_data and duck_data.anim then
        -- Draw the duck sprite with the current animation frame
        -- Using the same sprite and approach as the local duck
        local frame = duck_data.anim:getFrame()
        if duck_data.direction == -1 then
          assets_duck.qdraw(frame, pos.x + 32 - 6, pos.y, 0, -1, 1)
        else
          assets_duck.qdraw(frame, pos.x - 6, pos.y)
        end
      end
    end
  end
  
  love.graphics.setColor(1, 1, 1, 1) -- Reset to opaque
end

-- Cleanup
function Network:shutdown()
  if self.udp then
    self.udp:close()
  end
  self.enabled = false
  self.remote_ducks = {}
end

return Network