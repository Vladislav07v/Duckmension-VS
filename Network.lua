-- Network.lua
-- Client-side multiplayer networking

local socket = require "socket"

local Network = {
  socket = nil,
  host = nil,
  port = nil,
  encryption_key = nil,
  client_id = nil,
  connected = false,
  verified = false,
  remote_players = {},  -- id -> {x, y}
  last_ping = 0,
  ping_interval = 5,  -- Send ping every 5 seconds
  last_error = nil,
  last_pos_update = 0,
  pos_update_interval = 0.1,  -- Send position every 0.1 seconds (10 times per second)
}

function Network:init(address, port, encryption_key)
  print(string.rep("=", 80))
  print("[Network] Initializing connection parameters:")
  print(string.format("  Address: '%s' (type: %s, length: %d)", 
    tostring(address), type(address), address and #address or 0))
  print(string.format("  Port: '%s' (type: %s)", 
    tostring(port), type(port)))
  print(string.format("  Encryption Key: '%s' (type: %s)", 
    tostring(encryption_key), type(encryption_key)))
  
  -- Validate and convert port
  if type(port) == "string" then
    port = tonumber(port)
    print(string.format("  Port converted to number: %d", port or 0))
  end
  
  if not port or port < 1 or port > 65535 then
    print(string.format("[Network] ERROR: Invalid port number: %s", port))
    self.last_error = "Invalid port number"
    return false
  end
  
  if not address or address == "" then
    print("[Network] ERROR: Address is empty")
    self.last_error = "Address is empty"
    return false
  end
  
  self.host = tostring(address):match("^%s*(.-)%s*$")  -- Trim whitespace
  self.port = port
  self.encryption_key = tostring(encryption_key)
  self.remote_players = {}
  self.last_ping = socket.gettime()
  self.last_pos_update = socket.gettime()
  
  print(string.format("  Trimmed Address: '%s'", self.host))
  print(string.format("  Final Port: %d", self.port))
  print(string.rep("=", 80))
  
  return self:connect()
end

function Network:connect()
  if self.socket then
    self:disconnect()
  end
  
  print(string.format("[Network] Attempting to connect to %s:%d...", self.host, self.port))
  
  self.socket = socket.tcp()
  self.socket:settimeout(3)  -- 3 second timeout for connection
  
  -- Try connection multiple times
  local max_attempts = 3
  local success = nil
  local err = nil
  
  for attempt = 1, max_attempts do
    print(string.format("[Network] Connection attempt %d/%d...", attempt, max_attempts))
    success, err = self.socket:connect(self.host, self.port)
    
    if success then
      break
    end
    
    if attempt < max_attempts then
      socket.sleep(0.5)  -- Wait before retrying
    end
  end
  
  print(string.format("[Network] Connect result - Success: %s, Error: %s", 
    tostring(success), tostring(err)))
  
  if success then
    self.socket:settimeout(0)  -- Switch to non-blocking
    self.connected = true
    print(string.format("[Network] Connected successfully to %s:%d", self.host, self.port))
    
    -- Send authentication immediately
    self:send("AUTH:" .. self.encryption_key)
    
    return true
  else
    self.socket:settimeout(0)
    self.last_error = err
    print(string.format("[Network] Connection failed: %s", err))
    
    -- Provide helpful suggestions
    if err:find("host or service not provided") then
      print("[Network] HINT: Address might be empty or invalid")
      print("[Network] HINT: Try using 'localhost', '127.0.0.1', or an IP address")
    elseif err:find("Connection refused") then
      print("[Network] HINT: Server is not running or not listening on this port")
      print("[Network] HINT: Make sure main_server.lua is running")
      print("[Network] HINT: Try 'lua main_server.lua' in a terminal")
    elseif err:find("Network is unreachable") then
      print("[Network] HINT: Cannot reach the network/IP address")
      print("[Network] HINT: Check your network connection and firewall")
    elseif err:find("No such host") then
      print("[Network] HINT: Hostname/IP address is invalid or cannot be resolved")
    end
    
    self.connected = false
    return false
  end
end

function Network:send(message)
  if not self.socket or not self.connected then
    print(string.format("[Network] Cannot send - Connected: %s, Socket: %s", 
      tostring(self.connected), tostring(self.socket ~= nil)))
    return false
  end
  
  local success, err = self.socket:send(message .. "\n")
  
  if not success then
    print(string.format("[Network] Send error: %s", err))
    if err ~= "timeout" then
      self:disconnect()
    end
    return false
  end
  
  return true
end

function Network:sendPlayerPosition(x, y)
  if not self.verified then 
    return false 
  end
  
  local now = socket.gettime()
  -- Only send if enough time has passed since last position update
  if now - self.last_pos_update < self.pos_update_interval then
    return true  -- Not an error, just rate limiting
  end
  
  local msg = string.format("POS:%.1f,%.1f", x, y)
  local success = self:send(msg)
  
  if success then
    self.last_pos_update = now
  end
  
  return success
end

function Network:update()
  if not self.socket or not self.connected then
    return
  end
  
  -- Receive messages
  local data, err = self.socket:receive("*l")
  
  if data then
    self:handleMessage(data)
  elseif err == "closed" then
    print("[Network] Connection closed by server")
    self:disconnect()
  elseif err ~= "timeout" and err ~= nil then
    print(string.format("[Network] Receive error: %s", err))
    self:disconnect()
  end
  
  -- Send periodic ping
  local now = socket.gettime()
  if self.verified and now - self.last_ping >= self.ping_interval then
    self:send("PING")
    self.last_ping = now
  end
end

function Network:handleMessage(message)
  if message == "VERIFIED" then
    self.verified = true
    print("[Network] Successfully authenticated with server")
  elseif message == "PONG" then
    -- Ping response received
  else
    local command, data = message:match("^([A-Z]+):(.*)$")
    
    if command == "PLAYER" then
      local player_id, x, y = data:match("^([^:]+):([^:]+):(.+)$")
      if player_id and x and y then
        self.remote_players[tonumber(player_id)] = {
          x = tonumber(x),
          y = tonumber(y)
        }
      end
    end
  end
end

function Network:getRemotePlayers()
  return self.remote_players
end

function Network:disconnect()
  if self.socket then
    self.socket:close()
    self.socket = nil
  end
  
  self.connected = false
  self.verified = false
  self.remote_players = {}
  print("[Network] Disconnected from server")
end

function Network:isConnected()
  return self.connected and self.verified
end

function Network:getLastError()
  return self.last_error
end

return Network