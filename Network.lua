-- Network module for UDP communication with server
-- Integrates with the game's GameState and World systems

local socket = require "socket"

local Network = {}
Network.enabled = false
Network.entity = nil
Network.udp = nil
Network.address = "localhost"
Network.port = 12345
Network.updaterate = 0.1
Network.accumulator = 0
Network.world = {} -- remote entities state

-- Initialize network connection
function Network:init(address, port)
  self.address = address or "localhost"
  self.port = port or 12345
  
  self.udp = socket.udp()
  self.udp:settimeout(0)
  self.udp:setpeername(self.address, self.port)
  
  -- Generate unique entity ID
  math.randomseed(os.time())
  self.entity = tostring(math.random(99999))
  
  self.enabled = true
  self.accumulator = 0
  
  -- Send initial position (will be filled in by game)
  local dg = string.format("%s %s %d %d", self.entity, 'at', 320, 240)
  self.udp:send(dg)
  
  print("Network initialized. Entity ID: " .. self.entity)
end

-- Send duck position update
function Network:sendDuckPosition(x, y)
  if not self.enabled or not self.udp then return end
  
  self.accumulator = self.accumulator + (self.lastDt or 0.016)
  
  if self.accumulator > self.updaterate then
    local dg = string.format("%s %s %f %f", self.entity, 'at', x, y)
    self.udp:send(dg)
    
    -- Request world state update
    local dg_update = string.format("%s %s $", self.entity, 'update')
    self.udp:send(dg_update)
    
    self.accumulator = self.accumulator - self.updaterate
  end
end

-- Receive and process network messages
function Network:update(dt)
  if not self.enabled or not self.udp then return end
  
  self.lastDt = dt
  
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

-- Draw remote entities (optional visualization)
function Network:draw()
  if not self.enabled then return end
  
  love.graphics.setColor(1, 0, 0, 0.7)
  for ent, pos in pairs(self.world) do
    if ent ~= self.entity then
      love.graphics.print("P:" .. ent, pos.x, pos.y)
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
end

-- Cleanup
function Network:shutdown()
  if self.udp then
    self.udp:close()
  end
  self.enabled = false
end

return Network