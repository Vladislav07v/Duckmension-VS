local GameState = require('GameState')
local baton = require('baton')
local Assets = require('assets_shared')

local mt = {}
mt.__index = mt

local buttons = {
  singleplay = {x=20,  y=200, w=160, h=30},
  multiplay  = {x=220, y=200, w=160, h=30},
}

function mt:loadAssets()
  if not self.title_image then
    self.title_image = Assets.load('assets/title.png', 'title')
  end
  if not self.font then
    self.font = love.graphics.newFont("assets/ari_dis.ttf", 11)
  end
end

-- ── Actions ───────────────────────────────────────────────────────────────────

local function doStart(state)
  local net = GameState.network
  if net and net:isConnected() then
    net:send("START_LOBBY")
  end
end

local function doBack(state)
  local net = GameState.network
  if net and net:isConnected() then
    net:send("LEAVE_LOBBY")
    net.in_lobby    = false
    net.lobby_state = nil
  end
  GameState.setCurrent('Play', 0)
end

-- ── State methods ─────────────────────────────────────────────────────────────

function mt:update(dt)
  self:loadAssets()
  self.player:update()
  local net = GameState.network

  if net and net:isConnected() then
    net:update()

    -- If the network states the room has started, enter map 1
    if net.lobby_state == "playing" then
      local timed = self.mode == "timed"
      GameState.setCurrent('Play', 1)
      if timed then
        GameState.next_current.timed_level_active = true
        GameState.next_current.timed_level_timer  = 120
      end
      return
    end

    if self.player:pressed("jump") then
      doStart(self)
    end
    if self.player:pressed("change") then
      doBack(self)
    end
  else
    if self.player:pressed("change") then
      doBack(self)
    end
  end
end

local function handlePress(state, x, y)
  if x >= buttons.singleplay.x*3 and x <= buttons.singleplay.x*3 + buttons.singleplay.w*3
  and y >= buttons.singleplay.y*3 and y <= buttons.singleplay.y*3 + buttons.singleplay.h*3 then
    doStart(state)
    return
  end

  if x >= buttons.multiplay.x*3 and x <= buttons.multiplay.x*3 + buttons.multiplay.w*3
  and y >= buttons.multiplay.y*3 and y <= buttons.multiplay.y*3 + buttons.multiplay.h*3 then
    doBack(state)
    return
  end
end

function mt:mousepressed(x, y, button)
  if button ~= 1 then return end
  handlePress(self, x, y)
end

function mt:touchpressed(id, x, y, dx, dy, pressure)
  if pressure ~= 1 then return end
  handlePress(self, x, y)
end

function mt:draw()
  self:loadAssets()
  love.graphics.clear(0.1, 0.1, 0.1)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(self.font)

  love.graphics.print("WAITING IN LOBBY", 20, 20)
  love.graphics.print("Game Mode: " .. tostring(self.mode), 20, 50)

  local net = GameState.network
  if net and net.in_lobby then
    local lobby_info = net.lobbies and net.lobbies[net.lobby_id]
    local count = lobby_info and lobby_info.players or 1
    love.graphics.print("Players joined: " .. count .. " / 4", 20, 80)
  elseif net and net.last_error then
    love.graphics.setColor(1, 0.2, 0.2, 1)
    love.graphics.print("Error: " .. net.last_error, 20, 80)
    love.graphics.setColor(1, 1, 1, 1)
  end

  -- Buttons
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", buttons.singleplay.x, buttons.singleplay.y, buttons.singleplay.w, buttons.singleplay.h)
  love.graphics.rectangle("fill", buttons.multiplay.x,  buttons.multiplay.y,  buttons.multiplay.w,  buttons.multiplay.h)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("line", buttons.singleplay.x, buttons.singleplay.y, buttons.singleplay.w, buttons.singleplay.h)
  love.graphics.rectangle("line", buttons.multiplay.x,  buttons.multiplay.y,  buttons.multiplay.w,  buttons.multiplay.h)
  love.graphics.printf("START",  buttons.singleplay.x - 20, buttons.singleplay.y + 10, buttons.singleplay.y + 2, "center")
  love.graphics.printf("CANCEL", buttons.multiplay.x  - 20, buttons.multiplay.y  + 10, buttons.multiplay.y,     "center")
end

function mt:trigger() end

-- ── Constructor ───────────────────────────────────────────────────────────────

return {
  new = function(args)
    args = args or {}
    local state = setmetatable({
      name = 'Lobby_State',
      mode = args.mode or "full",
    }, mt)

    state.player = baton.new {
      controls = {
        jump   = {'key:z',      'button:b', 'mouse:1'},
        change = {'key:escape', 'button:back', 'key:x'},
      },
      joystick = love.joystick.getJoysticks()[1],
      deadzone = .33,
    }

    return state
  end
}