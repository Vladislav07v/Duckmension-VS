local GameState = require('GameState')
local baton = require('baton')
local Assets = require('assets_shared')

local mt = {}
mt.__index = mt

function mt:loadAssets()
  -- preload and reuse images via shared cache
  if not self.title_image then
    self.title_image = Assets.load('assets/title.png', 'title')
  end
  if not self.font then
    self.font = love.graphics.newFont("assets/upheavtt.ttf", 20)
  end
end

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
        -- Mutate newly setup current PlayState to have timed variables active
        GameState.next_current.timed_level_active = true
        GameState.next_current.timed_level_timer = 120
      end
      return
    end

    if self.player:pressed("jump") then
      net:send("START_LOBBY")
    end
    if self.player:pressed("back") then
      net:send("LEAVE_LOBBY")
      net.in_lobby = false
      net.lobby_state = nil
      GameState.setCurrent('Play', 0)
    end
  else
    if self.player:pressed("back") then
      GameState.setCurrent('Play', 0)
    end
  end
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
    
    -- Can start when at least 1 person is present (easy for dev testing) 
    -- The server allows this, but the prompt strictly says up to 4 can join.
    love.graphics.print("Press (jump) to Start", 20, 110)
    love.graphics.print("Press (back) to Cancel", 20, 140)
    
  elseif net and net.last_error then
    love.graphics.setColor(1, 0.2, 0.2, 1)
    love.graphics.print("Error: " .. net.last_error, 20, 80)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Press (back) to return", 20, 110)
  end
end

function mt:trigger() end

return {
  new = function(args)
    args = args or {}
    local state = setmetatable({
      name = 'Lobby_State',
      mode = args.mode or "full",
    }, mt)
    
    state.player = baton.new {
      controls = {
        jump = {'key:z','button:b','mouse:1'},
        back = {'key:escape','button:back','key:x'},
      },
      joystick = love.joystick.getJoysticks()[1],
      deadzone = .33,
    }
    -- Using the game's standardized font styling
    return state
  end

}