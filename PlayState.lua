local GameState = require('GameState')
local Level = require('Level')
local World = require('World')
local GUI = require('gui')
local Spikes = require('Spikes')
local duck_assets = require('assets_duck')
local Assets = require('assets_shared')

local MAX_LEVEL = 50

local mt = {}
mt.__index = mt

function mt:update(dt)
  if not self._initialized then
    if not self.background then
      Assets.load('assets/bg_dark.png', 'bg_dark')
      Assets.load('assets/bg_light.png', 'bg_light')
      Assets.load('assets/bottom.png', 'bg_bottom')
      self.background = Assets.get('bg_dark')
    end
    if not self.bottombg then
      self.bottombg = Assets.get('bg_bottom')
    end
    GUI:load()
    self.sleep = 0
    self.is_light_dimension = false
    self.remote_players = {}
    self.time_up_handled = false
    
    if not self.timed_level_active and not self.timed_level_timer then
      self.timed_level_active = false
      self.timed_level_timer = 0
      self.timed_level_duration = 120
    end
    self._initialized = true
  end

  -- Detect network game overs
  if GameState.network and GameState.network.lobby_state == "game_over" then
    local winner = GameState.network.winner_id
    GameState.network.lobby_state = nil
    GameState.network.in_lobby = false
    GameState.network:send("LEAVE_LOBBY")
    
    if winner == GameState.network.client_id then
      GameState.setCurrent('Win')
    else
      GameState.setCurrent('Play', 0) -- Kick back to hub
    end
    return
  end

  for i, item in ipairs(self.world.items) do
    if item.update then item:update(dt, self.world) end
  end

  -- Handle timed level countdown
  if self.timed_level_active then
    self.timed_level_timer = self.timed_level_timer - dt
    if self.timed_level_timer <= 0 then
      self.timed_level_timer = 0
      if not self.time_up_handled then
        self.time_up_handled = true
        if GameState.network and GameState.network:isConnected() and GameState.network.lobby_state == "playing" then
          -- Tell server time's up, server will respond with GAME_OVER to redirect the player
          GameState.network:send("TIME_UP")
        else
          self.timed_level_active = false
          GUI:setTimedLevel(false, 0)
          GameState.setCurrent('Play', 0)
        end
      end
    end
  end

  if self.close_t then
    self.close_t = self.close_t - dt
    if self.close_t < 0 then
      GameState.setCurrent('Play', self.level_num - 1)
      GameState.doors_passed = math.max((GameState.doors_passed or 1) - 1, 0)
      if self.level_num < 2 then GameState.setCurrent('Play', self.level_num) end
    end
  end
  
  local duck = GameState.getDuckObject()
  if duck and duck.dimension_toggled then
    self.is_light_dimension = not self.is_light_dimension
    if self.is_light_dimension then
      self.background = Assets.get('bg_light')
    else
      self.background = Assets.get('bg_dark')
    end
    duck.dimension_toggled = false
  end
  
  GUI:setTimedLevel(self.timed_level_active, self.timed_level_timer)
  
  if GameState.network then
    if duck then GameState.network:sendPlayerPosition(duck.x, duck.y) end
    GameState.network:update()
    self.remote_players = GameState.network:getRemotePlayers()
  end
end

function mt:draw()
  for _, item in ipairs(self.world.items) do item:draw() end
  
  if self.remote_players then
    love.graphics.setColor(1, 1, 0, 1)
    for player_id, player_data in pairs(self.remote_players) do
      if player_data.x and player_data.y then
        love.graphics.rectangle('fill', player_data.x - 6, player_data.y, 20, 30)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf("P" .. player_id, player_data.x - 10, player_data.y + 35, 40, "center")
        love.graphics.setColor(1, 1, 0, 1)
      end
    end
    love.graphics.setColor(1, 1, 1, 1)
  end
end

function mt:trigger(event, actor, data)
  if event == 'door:open' then
    data = data or {}
    
    if self.level_num == 0 then
      -- HUB World (map_0): Interact with a door creates/joins a room
      if GameState.network and GameState.network:isConnected() then
        local mode = data.timed and "timed" or "full"
        GameState.network:send("JOIN_OR_CREATE:" .. mode)
        GameState.setCurrent('Lobby', {mode = mode})
      else
        -- Offline fallback
        if data.timed then
          self.timed_level_active = true
          self.timed_level_timer = self.timed_level_duration
        end
        GameState.setCurrent('Play', data.target_level or 1)
      end
    else
      -- Regular door progression
      if not self.timed_level_active then self.timed_level_timer = 0 end
      
      GameState.doors_passed = (GameState.doors_passed or 0) + 1
      if GameState.network and GameState.network:isConnected() then
        GameState.network:send("SCORE:" .. GameState.doors_passed)
      end
      
      if self.level_num < MAX_LEVEL then
        GameState.setCurrent('Play', self.level_num + 1)
      else
        self.timed_level_active = false
        self.timed_level_timer = 0
        GUI:setTimedLevel(false, 0)
        
        if GameState.network and GameState.network:isConnected() then
          GameState.network:send("FINISH")
        end
        GameState.setCurrent('Win')
      end
    end
  elseif event == 'duck:kill' then
    local duck = data
    duck.is_disabled = true
    self.close_t = (self.close_t or 1)
    duck.dimension_toggled = false
    duck_assets.setDuckSprite("assets/duck.png")
    duck_assets.setDuckColor(219, 186, 74)
  elseif event == 'duck:action' then
    local actables = self.world:find(actor, 'is_actable')
    if actables[1] then actables[1]:onduckAction() end
  end
end

return {
  new = function(level_num, parent_state)
    local Portal = require('Portal')
    Portal.clearPortalManager()
    
    local state = setmetatable({ name = 'Play_State', score = 0 }, mt)
    state.world = World.new()
    state.level = Level.new('map_' .. level_num, state)
    state.level_num = level_num
    state.remote_players = {}
    
    if parent_state then
      state.timed_level_active = parent_state.timed_level_active or false
      state.timed_level_timer = parent_state.timed_level_timer or 0
      state.timed_level_duration = parent_state.timed_level_duration or 120
    else
      state.timed_level_active = false
      state.timed_level_timer = 0
      state.timed_level_duration = 120
    end
    
    return state
  end
}