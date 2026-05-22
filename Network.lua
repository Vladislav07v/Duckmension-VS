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
  remote_players = {},    -- id -> {x, y}
  player_names  = {},     -- id -> username string
  winner_id   = nil,
  winner_name = nil,      -- resolved username of the winner
  lobbies = {},
  in_lobby = false,
  lobby_id = nil,
  lobby_state = nil,
  last_ping = 0,
  ping_interval = 5,
  last_error = nil,
  last_pos_update = 0,
  pos_update_interval = 0.1,
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

  self.host = tostring(address):match("^%s*(.-)%s*$")
  self.port = port
  self.encryption_key = tostring(encryption_key)
  self.remote_players = {}
  self.player_names   = {}
  self.winner_id      = nil
  self.winner_name    = nil
  self.lobbies = {}
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
  self.socket:settimeout(3)

  local max_attempts = 3
  local success = nil
  local err = nil

  for attempt = 1, max_attempts do
    print(string.format("[Network] Connection attempt %d/%d...", attempt, max_attempts))
    success, err = self.socket:connect(self.host, self.port)
    if success then break end
    if attempt < max_attempts then socket.sleep(0.5) end
  end

  print(string.format("[Network] Connect result - Success: %s, Error: %s",
    tostring(success), tostring(err)))

  if success then
    self.socket:settimeout(0)
    self.connected = true
    print(string.format("[Network] Connected successfully to %s:%d", self.host, self.port))
    self:send("AUTH:" .. self.encryption_key)
    return true
  else
    self.socket:settimeout(0)
    self.last_error = err
    print(string.format("[Network] Connection failed: %s", err))
    if err:find("host or service not provided") then
      print("[Network] HINT: Address might be empty or invalid")
    elseif err:find("Connection refused") then
      print("[Network] HINT: Server is not running or not listening on this port")
    elseif err:find("Network is unreachable") then
      print("[Network] HINT: Cannot reach the network/IP address")
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
  if not self.verified then return false end

  local now = socket.gettime()
  if now - self.last_pos_update < self.pos_update_interval then
    return true
  end

  local msg = string.format("POS:%.1f,%.1f", x, y)
  local success = self:send(msg)
  if success then
    self.last_pos_update = now
  end
  return success
end

function Network:update()
  if not self.socket or not self.connected then return end

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

  local now = socket.gettime()
  if self.verified and now - self.last_ping >= self.ping_interval then
    self:send("PING")
    self.last_ping = now
  end
end

function Network:handleMessage(message)
  if message:match("^VERIFIED") then
    self.verified = true
    local id = message:match("^VERIFIED:(%d+)")
    if id then
      self.client_id = tonumber(id)
    end
    print("[Network] Successfully authenticated with server. Assigned ID: " .. tostring(self.client_id))

    -- Announce our username to the server so other clients can display it.
    -- The server should forward this as PLAYER_NAME:<id>:<name> to all clients.
    local GameState = require('GameState')
    if GameState.logged_in_user then
      self:send("PLAYER_NAME:" .. GameState.logged_in_user)
      -- Store our own name locally immediately so we don't need a round-trip
      self.player_names[self.client_id] = GameState.logged_in_user
      print("[Network] Announced username: " .. GameState.logged_in_user)
    end

  elseif message == "PONG" then
    -- ping response, nothing to do

  else
    local command, data = message:match("^([A-Z_]+):(.*)$")
    if not command then
      command = message:match("^([A-Z_]+)$")
    end

    if command == "PLAYER" then
      -- Position update: PLAYER:<id>:<x>:<y>
      local player_id, x, y = data:match("^([^:]+):([^:]+):(.+)$")
      if player_id and x and y then
        local pid = tonumber(player_id)
        local nx, ny = tonumber(x), tonumber(y)
        local prev = self.remote_players[pid]

        -- Infer facing direction and animation from position delta.
        -- Updates arrive at ~10Hz so running at 250px/s gives ~25px per update.
        local dir  = (prev and prev.dir)  or 1
        local anim = (prev and prev.anim) or "idle"

        if prev and prev.x and prev.y then
          local dx = nx - prev.x
          local dy = ny - prev.y
          -- Horizontal movement → direction
          if math.abs(dx) > 1 then
            dir = dx > 0 and 1 or -1
          end
          -- Vertical movement takes priority (airborne)
          if math.abs(dy) > 2 then
            anim = "jump"
          elseif math.abs(dx) > 1 then
            anim = "run"
          else
            anim = "idle"
          end
        end

        self.remote_players[pid] = { x = nx, y = ny, dir = dir, anim = anim }
      end

    elseif command == "PLAYER_NAME" then
      -- Name broadcast: PLAYER_NAME:<id>:<username>
      -- The server forwards this when a client sends PLAYER_NAME:<username>
      local pid, name = data:match("^(%d+):(.+)$")
      if pid and name then
        self.player_names[tonumber(pid)] = name
        print("[Network] Player " .. pid .. " is named: " .. name)
      end

    elseif command == "LOBBY_CREATED" or command == "LOBBY_JOINED" then
      self.in_lobby = true
      self.lobby_id = tonumber(data)
      self.lobby_state = "waiting"
      self.last_error = nil
      print("[Network] Joined lobby #" .. tostring(self.lobby_id))

    elseif command == "LOBBY_START" then
      self.lobby_state = "playing"
      print("[Network] Lobby started playing!")

    elseif command == "LOBBY_ERROR" then
      self.last_error = data
      self.in_lobby = false
      print("[Network] Lobby Error: " .. tostring(data))

    elseif command == "GAME_OVER" then
      self.lobby_state = "game_over"
      self.winner_id   = tonumber(data)
      self.in_lobby    = false

      -- Resolve winner's display name from stored player_names table.
      -- Falls back to "Player <id>" when the server hasn't forwarded the name yet.
      self.winner_name = self.player_names[self.winner_id]
                      or ("Player " .. tostring(self.winner_id))
      print("[Network] Game Over! Winner: " .. tostring(self.winner_name)
            .. " (id=" .. tostring(self.winner_id) .. ")")

    elseif command == "LOBBIES" then
      self.lobbies = {}
      for lobby_str in data:gmatch("([^;]+);") do
        local lid, mode, players, started = lobby_str:match("^(%d+):([%w_]+):(%d+):(%d+)$")
        if lid then
          self.lobbies[tonumber(lid)] = {
            mode    = mode,
            players = tonumber(players),
            started = (started == "1")
          }
        end
      end
    end
  end
end

-- Returns the display name for a given player id.
-- Uses player_names if available, falls back to "Player <id>".
function Network:getPlayerName(id)
  return self.player_names[id] or ("Player " .. tostring(id))
end

function Network:getRemotePlayers()
  return self.remote_players
end

function Network:disconnect()
  if self.socket then
    self.socket:close()
    self.socket = nil
  end
  self.connected    = false
  self.verified     = false
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