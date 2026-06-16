-- LoginState.lua
-- Shown when the player presses the (X) button on the title screen.
-- Controls match SettingsState exactly:
--   Click/touch a field to activate it
--   First keypress after focusing replaces the whole field
--   Backspace on a just-focused field clears it entirely
--   Enter / jump  – submit login
--   Escape / back – return to TitleState without logging in

local GameState = require('GameState')
local baton     = require('baton')
local socket    = require('socket')

-- ── Configuration ─────────────────────────────────────────────────────────────
local WEBSITE_HOST = "duckmensionvs.runasp.net"
local WEBSITE_PORT = 80
-- ──────────────────────────────────────────────────────────────────────────────

local mt = {}
mt.__index = mt

local fields = {
    username = { x=20, y=45,  w=200, h=30 },
    password = { x=20, y=85,  w=200, h=30 },
}

local buttons = {
  singleplay ={x=20,y=200,w=160,h=30},
  multiplay ={x=220,y=200,w=160,h=30},
  }

-- ── HTTP helpers ──────────────────────────────────────────────────────────────

local function http_post(host, port, path, json_body)
    print("\n" .. string.rep("=", 80))
    print("[LoginState] Attempting HTTP POST")
    print(string.format("  Host: %s  Port: %d  Path: %s", host, port, path))
    print(string.format("  Body: %s", json_body))

    local sock = socket.tcp()
    sock:settimeout(10)

    local ok, err = sock:connect(host, port)
    if not ok then
        print("[LoginState] ERROR: connect() failed: " .. tostring(err))
        sock:close()
        return nil, "Connection failed: " .. tostring(err)
    end
    print("[LoginState] Socket connected")

    local request = table.concat({
        "POST " .. path .. " HTTP/1.1",
        "Host: " .. host,
        "Content-Type: application/json",
        "Content-Length: " .. #json_body,
        "Connection: close",
        "",
        json_body
    }, "\r\n")

    print("[LoginState] Sending request:\n" .. request)

    local bytes, serr = sock:send(request)
    if not bytes then
        print("[LoginState] ERROR: send() failed: " .. tostring(serr))
        sock:close()
        return nil, "Send failed: " .. tostring(serr)
    end
    print(string.format("[LoginState] Sent %d bytes", bytes))

    -- receive('*a') reads the entire response until the server closes the
    -- connection. This is the correct method for Connection:close HTTP and
    -- avoids the timing bug where chunked receive(1024) gets 'closed' before
    -- the buffer is delivered.
    local full, rerr = sock:receive('*a')
    sock:close()

    print("[LoginState] Receive result: " .. tostring(rerr))
    print("[LoginState] Full raw response:\n" .. tostring(full))

    if not full or full == "" then
        return nil, "Empty response from server (HTTPS redirect or no data): " .. tostring(rerr)
    end

    local status_line = full:match("^(HTTP/%S+ %d+ [^\r\n]*)")
    print("[LoginState] HTTP status: " .. tostring(status_line))

    local body = full:match("\r\n\r\n(.+)$") or full:match("\n\n(.+)$") or full
    print("[LoginState] Extracted body: " .. tostring(body))

    return body, nil
end

local function encode_json(t)
    local parts = {}
    for k, v in pairs(t) do
        local val
        if type(v) == "string" then
            val = '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
        elseif type(v) == "number" then
            val = tostring(v)
        elseif type(v) == "boolean" then
            val = tostring(v)
        end
        if val then
            table.insert(parts, '"' .. k .. '":' .. val)
        end
    end
    local result = "{" .. table.concat(parts, ",") .. "}"
    print("[LoginState] encode_json result: " .. result)
    return result
end

local function json_get(json, key)
    print(string.format("[LoginState] json_get looking for key '%s' in: %s", key, tostring(json)))

    local v = json:match('"' .. key .. '":%s*"([^"]*)"')
    if v then
        print(string.format("[LoginState] json_get '%s' = (string) '%s'", key, v))
        return v
    end
    v = json:match('"' .. key .. '":%s*(%-?%d+)')
    if v then
        print(string.format("[LoginState] json_get '%s' = (number) %s", key, v))
        return tonumber(v)
    end
    if json:match('"' .. key .. '":%s*true') then
        print(string.format("[LoginState] json_get '%s' = true", key))
        return true
    end
    if json:match('"' .. key .. '":%s*false') then
        print(string.format("[LoginState] json_get '%s' = false", key))
        return false
    end

    print(string.format("[LoginState] json_get '%s' = nil (not found)", key))
    return nil
end

-- ── State methods ─────────────────────────────────────────────────────────────

function mt:update(dt)
    self.player:update()

    -- Left button: submit login
    if self.player:pressed('jump') then
        self:submit()
    end

    -- Right button: return to title
    if self.player:pressed('change') then
        love.keyboard.setTextInput(false)
        GameState.setCurrent('Title')
    end
end

function mt:loadAssets()
    if not self.title_image then
        self.title_image = love.graphics.newImage('assets/title.png')
    end
    if not self.title_font then
        self.title_font = love.graphics.newFont("assets/ari_dis.ttf", 11)
    end
end

function mt:activateField(fname)
    self.active_field = fname
    self.field_just_activated = true
    love.keyboard.setTextInput(true)
end

function mt:submit()
    print("\n" .. string.rep("=", 80))
    print("[LoginState] Submit called")
    print(string.format("  username field: '%s'", self.username))
    print(string.format("  password field: '%s' (%d chars)", string.rep("*", #self.password), #self.password))
    print(string.rep("=", 80))

    if #self.username == 0 then
        self.status = "Enter a username."
        return
    end
    if #self.password == 0 then
        self.status = "Enter a password."
        return
    end

    self.status = "Logging in..."
    self.busy   = true

    local body = encode_json({ Username = self.username, Password = self.password })
    local resp, err = http_post(WEBSITE_HOST, WEBSITE_PORT, "/api/game/login", body)

    self.busy = false

    if not resp then
        print("[LoginState] http_post returned nil: " .. tostring(err))
        self.status = "Cannot reach website: " .. tostring(err)
        return
    end

    local ok      = json_get(resp, "ok")
    local errMsg  = json_get(resp, "error")
    local uname   = json_get(resp, "username")
    local cookies = json_get(resp, "cookies")

    print(string.format("[LoginState] Parsed values: ok=%s  error=%s  username=%s  cookies=%s",
        tostring(ok), tostring(errMsg), tostring(uname), tostring(cookies)))

    if ok == true then
        print("[LoginState] Login SUCCESS, switching to Title")
        GameState.logged_in_user    = uname
        GameState.logged_in_cookies = cookies or 0
        GameState.coins             = cookies or 0
        love.keyboard.setTextInput(false)
        GameState.setCurrent('Settings')
    else
        print("[LoginState] Login FAILED, showing error: " .. tostring(errMsg))
        self.status = tostring(errMsg or "Login failed.")
    end
end

-- ── Input handlers ────────────────────────────────────────────────────────────

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
      self:submit()
      return
    end
    
  if x >= buttons.multiplay.x*3 and x <= buttons.multiplay.x*3 + buttons.multiplay.w*3
    and y >= buttons.multiplay.y*3 and y <= buttons.multiplay.y*3 + buttons.multiplay.h*3 then
      love.keyboard.setTextInput(false)
      GameState.setCurrent('Title')
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
      self:submit()
      return
    end
    
  if x >= buttons.multiplay.x*3 and x <= buttons.multiplay.x*3 + buttons.multiplay.w*3
    and y >= buttons.multiplay.y*3 and y <= buttons.multiplay.y*3 + buttons.multiplay.h*3 then
      love.keyboard.setTextInput(false)
      GameState.setCurrent('Title')
      return
    end

    self.active_field = nil
    self.field_just_activated = false
    love.keyboard.setTextInput(false)
end

function mt:keypressed(key)
    if not self.active_field then return end

    if key == "backspace" then
        if self.field_just_activated then
            if     self.active_field == "username" then self.username = ""
            elseif self.active_field == "password" then self.password = ""
            end
            self.field_just_activated = false
        else
            if     self.active_field == "username" then self.username = self.username:sub(1, -2)
            elseif self.active_field == "password" then self.password = self.password:sub(1, -2)
            end
        end
    end
end

function mt:textinput(text)
    if not self.active_field then return end

    if self.field_just_activated then
        if     self.active_field == "username" then self.username = text
        elseif self.active_field == "password" then self.password = text
        end
        self.field_just_activated = false
        return
    end

    if     self.active_field == "username" then self.username = self.username .. text
    elseif self.active_field == "password" then self.password = self.password .. text
    end
end

-- ── Draw ──────────────────────────────────────────────────────────────────────

function mt:draw(screen)
    self:loadAssets()
    love.graphics.setFont(self.title_font)
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.print("Account Login", 20, 10)

    -- Username field
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(":Username", fields.username.x + 203, fields.username.y+10)
    love.graphics.setColor(self.active_field == "username" and {1,1,0,1} or {1,1,1,1})
    love.graphics.rectangle("line", fields.username.x, fields.username.y, fields.username.w, fields.username.h)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(self.username, fields.username.x + 10, fields.username.y + 10)

    -- Password field (masked)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(":Password", fields.password.x + 203, fields.password.y+10)
    love.graphics.setColor(self.active_field == "password" and {1,1,0,1} or {1,1,1,1})
    love.graphics.rectangle("line", fields.password.x, fields.password.y, fields.password.w, fields.password.h)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.rep("*", #self.password), fields.password.x + 10, fields.password.y + 10)

    -- Status line
    local status_y = 10

    if self.busy then
        love.graphics.setColor(1, 1, 0.2, 1)
        love.graphics.print("Logging in...", 240 - string.len("Logging in..."), status_y)
    elseif GameState.logged_in_user then
        love.graphics.setColor(0.2, 1, 0.2, 1)
        love.graphics.print("Logged in as " .. GameState.logged_in_user, 240 - string.len("Logged in as "), status_y)
    else
        love.graphics.setColor(1, 0.2, 0.2, 1)
        love.graphics.print("Not logged in", 240 - string.len("Not logged in"), status_y)
    end

    if self.status ~= "" and not self.busy then
        love.graphics.setColor(1, 0.5, 0.5, 1)
        love.graphics.print("Error: " .. self.status, 20, status_y + 15)
    end

    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("Click a field to edit", 20, 120)
    love.graphics.print("Don't have an account?", 20, buttons.singleplay.y-30)
    love.graphics.print("Visit http://duckmensionvs.runasp.net/ to make one!", 20, buttons.singleplay.y-15)

  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", buttons.singleplay.x, buttons.singleplay.y, buttons.singleplay.w, buttons.singleplay.h)
  love.graphics.rectangle("fill", buttons.multiplay.x, buttons.multiplay.y, buttons.multiplay.w, buttons.multiplay.h)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("line", buttons.singleplay.x, buttons.singleplay.y, buttons.singleplay.w, buttons.singleplay.h)
  love.graphics.rectangle("line", buttons.multiplay.x, buttons.multiplay.y, buttons.multiplay.w, buttons.multiplay.h)
  love.graphics.printf("LOGIN (B)", buttons.singleplay.x-20, buttons.singleplay.y+10, buttons.singleplay.y+2, "center")
  love.graphics.printf("BACK (A)", buttons.multiplay.x-20, buttons.multiplay.y+10, buttons.multiplay.y, "center")
  
    if love._console == "3DS" and screen ~= "bottom" then
        love.graphics.draw(self.title_image, 0, 0)
    end
end

function mt:trigger() end

-- ── Constructor ───────────────────────────────────────────────────────────────

return {
    new = function()
        local state = setmetatable({
            name                  = 'Login_State',
            username              = "",
            password              = "",
            status                = "",
            busy                  = false,
            active_field          = nil,
            field_just_activated  = false,
        }, mt)

        state.player = baton.new {
            controls = {
                jump   = { 'key:return', 'button:b' },
                change = { 'key:escape', 'button:back' },
            },
            joystick = love.joystick.getJoysticks()[1],
            deadzone = .33,
        }

        return state
    end
}