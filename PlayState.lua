local GameState   = require('GameState')
local Level       = require('Level')
local World       = require('World')
local GUI         = require('gui')
local Spikes      = require('Spikes')
local duck_assets = require('assets_duck')
local Assets      = require('assets_shared')
local Animation   = require('Animation')

-- Distinct colors (r,g,b in 0-255) assigned to remote players by ID.
-- Chosen to stand out from the local duck's yellow (219,186,74)
-- and light-dimension pink (239,154,239).
local REMOTE_COLORS = {
  {  80, 200, 240 },   -- cyan
  { 240,  80,  80 },   -- red
  {  80, 220, 100 },   -- green
  { 240, 150,  50 },   -- orange
}

local function remoteColor(player_id)
  return REMOTE_COLORS[((player_id - 1) % #REMOTE_COLORS) + 1]
end

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
    if not self.title_font then
      self.title_font = love.graphics.newFont("assets/ari_dis.ttf", 11)
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

  -- ── Network game-over detection ───────────────────────────────────────────
  -- Route ALL players (winner and losers alike) to WinState so everyone sees
  -- the results screen. WinState is responsible for sending LEAVE_LOBBY and
  -- resetting lobby state — we do NOT touch that here to avoid double-sends.
  if GameState.network and GameState.network.lobby_state == "game_over" then
    local is_winner = (GameState.network.winner_id == GameState.network.client_id)
    GameState.setCurrent('Win', { is_winner = is_winner })
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

  -- Advance each remote player's animation independently.
  -- We create Animation objects on first sight and update the one that
  -- matches the anim name inferred from their position delta in Network.lua.
  for player_id, player_data in pairs(self.remote_players) do
    if not self.remote_anims[player_id] then
      self.remote_anims[player_id] = {
        idle = Animation.new(1,  8, 1),
        run  = Animation.new(9,  8, 0.75),
        jump = Animation.new(17, 8, 0.75),
      }
    end
    local anim_name = player_data.anim or "idle"
    self.remote_anims[player_id][anim_name]:update(dt)
  end
end

function mt:draw()
  for _, item in ipairs(self.world.items) do item:draw() end

  -- ── Draw remote players as animated ducks ───────────────────────────────
  if self.remote_players then
    for player_id, player_data in pairs(self.remote_players) do
      if player_data.x and player_data.y then
        local color = remoteColor(player_id)
        duck_assets.setDuckColor(color[1], color[2], color[3])

        local anims     = self.remote_anims and self.remote_anims[player_id]
        local anim_name = player_data.anim or "idle"
        local frame     = anims and anims[anim_name]:getFrame() or 1
        local dir       = player_data.dir or 1

        if dir == -1 then
          -- Flipped: same offset as Duck.lua uses for left-facing
          duck_assets.qdraw(frame, player_data.x - 6 + 32, player_data.y, 0, -1, 1)
        else
          duck_assets.qdraw(frame, player_data.x - 6, player_data.y)
        end

        -- Username label above the duck (qdraw resets color to white, so this is safe)
        local label = GameState.network and
                      GameState.network:getPlayerName(player_id) or
                      ("P" .. player_id)
        love.graphics.setFont(self.title_font)
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.printf(label, player_data.x - 20, player_data.y - 32, 60, "center")
        love.graphics.setColor(1, 1, 1, 1)
      end
    end
  end

  -- Restore local duck's color so anything drawn after uses the right tint.
  -- (qdraw always resets to white, but being explicit here costs nothing.)
  if self.is_light_dimension then
    duck_assets.setDuckColor(239, 154, 239)
  else
    duck_assets.setDuckColor(219, 186, 74)
  end

  -- ── Draw local player's username above their duck ────────────────────────
  if GameState.logged_in_user then
    local duck = GameState.getDuckObject()
    if duck then
      love.graphics.setFont(self.title_font)
      love.graphics.setColor(0.5, 0.5, 0.5, 1)
      love.graphics.printf(GameState.logged_in_user, duck.x - 20, duck.y + 32, 60, "center")
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function mt:trigger(event, actor, data)
  if event == 'door:open' then
    data = data or {}

    if self.level_num == 0 then
      if GameState.network and GameState.network:isConnected() then
        local mode = data.timed and "timed" or "full"
        GameState.network:send("JOIN_OR_CREATE:" .. mode)
        GameState.setCurrent('Lobby', {mode = mode})
      else
        if data.timed then
          self.timed_level_active = true
          self.timed_level_timer = self.timed_level_duration
        end
        GameState.setCurrent('Play', data.target_level or 1)
      end
    else
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
        -- Offline / single-player win — no network args needed
        GameState.setCurrent('Win', { is_winner = true })
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
    state.remote_anims   = {}

    if parent_state then
      state.timed_level_active = parent_state.timed_level_active or false
      state.timed_level_timer  = parent_state.timed_level_timer  or 0
      state.timed_level_duration = parent_state.timed_level_duration or 120
    else
      state.timed_level_active = false
      state.timed_level_timer  = 0
      state.timed_level_duration = 120
    end

    return state
  end
}