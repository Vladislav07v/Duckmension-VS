local socket = require "socket"

-- Configuration
local PORT = 12345
local HOST = "0.0.0.0"  -- Changed from "*" to explicit 0.0.0.0
local ENCRYPTION_KEY = "default-key"
local UPDATE_RATE = 1 / 30  -- 30 FPS
local PLAYER_TIMEOUT = 5    -- seconds before disconnecting inactive players

-- Server state
local server = {
  socket = nil,
  port = PORT,
  host = HOST,
  encryption_key = ENCRYPTION_KEY,
  clients = {},  -- Connected clients
  next_client_id = 1,
  last_update = socket.gettime(),
  running = true
}

-- Get local IP address
local function getLocalIP()
  local sock = socket.udp()
  sock:setoption("reuseaddr", true)
  
  -- Try to connect to an external address to determine local IP
  local success, err = sock:setpeername("8.8.8.8", 80)
  if success then
    local ip = sock:getsockname()
    sock:close()
    return ip or "127.0.0.1"
  else
    sock:close()
    -- Fallback: try localhost
    return "127.0.0.1"
  end
end

-- Check if port is already in use
local function isPortInUse(port)
  local test_socket = socket.tcp()
  test_socket:setoption("reuseaddr", true)
  local success, err = test_socket:bind("0.0.0.0", port)
  test_socket:close()
  
  if success then
    print(string.format("[Server] Port %d appears to be available", port))
    return false
  else
    print(string.format("[Server] Port %d check result: %s", port, err))
    return true
  end
end

-- Initialize server
local function initServer()
  print("[Server] ========================================")
  print("[Server] Starting Duckmension Server")
  print("[Server] ========================================")
  
  print(string.format("[Server] Configuration: PORT=%d, HOST=%s, KEY=%s", 
    server.port, server.host, server.encryption_key))
  
  -- Check if port is in use
  print("[Server] Checking if port is available...")
  isPortInUse(server.port)
  
  print("[Server] Creating TCP socket...")
  server.socket = socket.tcp()
  
  if not server.socket then
    print("[Server] ERROR: Failed to create TCP socket!")
    os.exit(1)
  end
  
  print("[Server] Setting socket options...")
  local opt_success, opt_err = server.socket:setoption("reuseaddr", true)
  if not opt_success then
    print(string.format("[Server] Warning: Could not set reuseaddr: %s", opt_err))
  end
  
  print(string.format("[Server] Attempting to bind to %s:%d...", server.host, server.port))
  local bind_success, bind_err = server.socket:bind(server.host, server.port)
  
  if not bind_success then
    print(string.format("[Server] ERROR: Failed to bind to %s:%d", server.host, server.port))
    print(string.format("[Server] Bind error: %s", bind_err))
    print("[Server] Trying alternative binding methods...")
    
    -- Try binding to 127.0.0.1 instead
    print("[Server] Attempting to bind to 127.0.0.1:12345...")
    bind_success, bind_err = server.socket:bind("127.0.0.1", server.port)
    if not bind_success then
      print(string.format("[Server] ERROR: Also failed to bind to 127.0.0.1: %s", bind_err))
      os.exit(1)
    end
    print("[Server] Successfully bound to 127.0.0.1")
  else
    print("[Server] Successfully bound to socket")
  end
  
  print("[Server] Setting socket to listen...")
  local listen_success, listen_err = server.socket:listen(5)
  if not listen_success then
    print(string.format("[Server] ERROR: Failed to listen: %s", listen_err))
    os.exit(1)
  end
  
  server.socket:settimeout(0)  -- Non-blocking
  
  print("\n" .. string.rep("=", 80))
  print("  DUCKMENSION VERSUS - MULTIPLAYER SERVER")
  print(string.rep("=", 80))
  print(string.format("IP Address: %s", getLocalIP()))
  print(string.format("Port: %d", server.port))
  print(string.format("Encryption Key: %s", server.encryption_key))
  print(string.rep("=", 80))
  print("Server is ready and waiting for connections...")
  print("Use 127.0.0.1 as address for local connections")
  print("Use the IP address shown above for network connections\n")
end

-- Accept new connections
local function acceptConnections()
  local client_socket, err = server.socket:accept()
  if client_socket then
    print(string.format("[%s] *** NEW CONNECTION ***", os.date("%H:%M:%S")))
    client_socket:settimeout(0)
    local client = {
      id = server.next_client_id,
      socket = client_socket,
      x = 0,
      y = 0,
      last_update = socket.gettime(),
      verified = false,
      encryption_key = nil
    }
    server.next_client_id = server.next_client_id + 1
    server.clients[client.id] = client
    
    print(string.format("[%s] Client #%d registered (total clients: %d)", 
      os.date("%H:%M:%S"), client.id, #server.clients))
  elseif err ~= "timeout" then
    print(string.format("[Server] Accept error: %s", err))
  end
end

-- Verify client encryption key
local function verifyClient(client)
  if client.verified then return true end
  
  if client.encryption_key and client.encryption_key == server.encryption_key then
    client.verified = true
    print(string.format("[%s] ✓ Client #%d VERIFIED", 
      os.date("%H:%M:%S"), client.id))
    -- Send verification response
    local success, err = client.socket:send("VERIFIED\n")
    if not success then
      print(string.format("[%s] Failed to send VERIFIED: %s", os.date("%H:%M:%S"), err))
    end
    return true
  elseif client.encryption_key then
    print(string.format("[%s] ✗ Client #%d REJECTED (key mismatch)", 
      os.date("%H:%M:%S"), client.id))
    print(string.format("    Received: '%s' | Expected: '%s'", 
      client.encryption_key, server.encryption_key))
    return false
  end
  
  return nil  -- Still waiting for key
end

-- Parse and handle client messages
local function handleClientMessage(client, message)
  -- Message format: "AUTH:key" or "POS:x,y" or "PING"
  local command, data = message:match("^([A-Z]+):(.*)$")
  
  if not command then
    command = message:match("^([A-Z]+)$")
  end
  
  if command == "AUTH" then
    client.encryption_key = data
    print(string.format("[%s] Client #%d AUTH attempt: '%s'", 
      os.date("%H:%M:%S"), client.id, data))
    verifyClient(client)
  elseif command == "POS" then
    if not client.verified then
      return
    end
    local x, y = data:match("([^,]+),(.+)")
    if x and y then
      client.x = tonumber(x)
      client.y = tonumber(y)
      client.last_update = socket.gettime()
    end
  elseif command == "PING" then
    if client.verified then
      local success, err = client.socket:send("PONG\n")
      if not success and err ~= "timeout" then
        print(string.format("[%s] Failed to send PONG to client #%d: %s", 
          os.date("%H:%M:%S"), client.id, err))
      end
    end
  else
    print(string.format("[%s] Client #%d unknown command: '%s'", 
      os.date("%H:%M:%S"), client.id, message))
  end
end

-- Receive data from client
local function receiveFromClient(client)
  local data, err = client.socket:receive("*l")
  if data then
    handleClientMessage(client, data)
  elseif err == "closed" then
    return false  -- Connection closed
  elseif err ~= "timeout" and err ~= nil then
    if err ~= "Connection reset by peer" then
      print(string.format("[%s] Client #%d error: %s", 
        os.date("%H:%M:%S"), client.id, err))
    end
    return false
  end
  return true
end

-- Send player data to all verified clients
local function broadcastPlayerData()
  local verified_clients = {}
  for id, client in pairs(server.clients) do
    if client.verified then
      table.insert(verified_clients, client)
    end
  end
  
  for _, client in pairs(server.clients) do
    if client.verified then
      for _, other in ipairs(verified_clients) do
        if other.id ~= client.id then
          local msg = string.format("PLAYER:%d:%.1f:%.1f\n", other.id, other.x, other.y)
          local success, err = client.socket:send(msg)
          if not success and err ~= "timeout" then
            print(string.format("[%s] Failed to send PLAYER data to client #%d: %s", 
              os.date("%H:%M:%S"), client.id, err))
          end
        end
      end
    end
  end
end

-- Update server
local function updateServer()
  acceptConnections()
  
  -- Handle client messages and check timeouts
  local clients_to_remove = {}
  for id, client in pairs(server.clients) do
    local success = receiveFromClient(client)
    
    if not success then
      print(string.format("[%s] Client #%d DISCONNECTED", 
        os.date("%H:%M:%S"), client.id))
      table.insert(clients_to_remove, id)
    else
      -- Check for timeout
      local time_since_update = socket.gettime() - client.last_update
      if client.verified and time_since_update > PLAYER_TIMEOUT then
        print(string.format("[%s] Client #%d TIMEOUT (%.1fs inactive)", 
          os.date("%H:%M:%S"), client.id, time_since_update))
        table.insert(clients_to_remove, id)
      end
    end
  end
  
  -- Remove disconnected clients
  for _, id in ipairs(clients_to_remove) do
    local client = server.clients[id]
    if client and client.socket then
      pcall(function() client.socket:close() end)
    end
    server.clients[id] = nil
  end
  
  -- Broadcast player data
  broadcastPlayerData()
end

-- Main server loop
local function run()
  initServer()
  
  print("Press Ctrl+C to stop the server\n")
  
  while server.running do
    local now = socket.gettime()
    if now - server.last_update >= UPDATE_RATE then
      updateServer()
      server.last_update = now
    end
    
    socket.sleep(0.001)  -- Small sleep to prevent CPU spinning
  end
  
  -- Cleanup
  if server.socket then
    server.socket:close()
  end
  for id, client in pairs(server.clients) do
    if client.socket then
      pcall(function() client.socket:close() end)
    end
  end
  
  print("\n" .. string.rep("=", 80))
  print("Server shutdown")
  print(string.rep("=", 80))
end

-- Run server
run()