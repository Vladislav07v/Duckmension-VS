local GameState = require('GameState')
local Level = require('Level')
local World = require('World')
local GUI = require('gui')
local Spikes = require('Spikes')
local duck_assets = require('assets_duck')
local Assets = require('assets_shared')

local MAX_LEVEL = 25

local mt = {}
mt.__index = mt

function mt:update(dt)
  if not self._initialized then
    -- preload backgrounds via shared assets (loaded once)
    if not self.background then
      Assets.load('assets/bg_dark.png', 'bg_dark')
      Assets.load('assets/bg_light.png', 'bg_light')
      Assets.load('assets/ducks.png', 'bg_ducks')
      self.background = Assets.get('bg_dark')
    end
    if not self.bottombg then
      -- previous code used invbg (undefined). Use dark background as bottom by default.
      self.bottombg = Assets.get('bg_ducks')
    end
    GUI:load()
    self.sleep = 0
    self.is_light_dimension = false
    self._initialized = true
  end

  for i, item in ipairs(self.world.items) do
    if item.update then
      item: update(dt, self.world)
    end
  end

  if self.close_t then
    self.close_t = self.close_t - dt
    if self.close_t < 0 then
      GameState.setCurrent('Play', self.level_num - 1)
      GameState.doors_passed = math.max((GameState.doors_passed or 1) - 1, 0)
      if self.level_num < 2 then
        GameState.setCurrent('Play', self.level_num)
      end
    end
  end
  
  -- Dimension background switching logic
  local duck = GameState.getDuckObject()
  if duck and duck.dimension_toggled then
    self.is_light_dimension = not self.is_light_dimension
    if self.is_light_dimension then
      Assets.load('assets/bg_light.png', 'bg_light')
      self.background = Assets.get('bg_light')
    else
      Assets.load('assets/bg_dark.png', 'bg_dark')
      self.background = Assets.get('bg_dark')
    end
    duck.dimension_toggled = false
  end
end

function mt:draw()
  for _, item in ipairs(self.world.items) do
    item:draw()
  end
end

function mt:trigger(event, actor, data)
  if event == 'door:open' then
    GameState.doors_passed = (GameState.doors_passed or 0) + 1
    if self.level_num < MAX_LEVEL then
      GameState.setCurrent('Play', self.level_num + 1)
    else
      GameState.setCurrent('Win')
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
    if actables[1] then
      actables[1]:onduckAction()
    end
  end
end

return {
  new = function(level_num)
    local state = setmetatable({ name = 'Play_State', score = 0 }, mt)
    state.world = World.new()
    state.level = Level.new('map_' .. level_num, state)
    state.level_num = level_num
    return state
  end
}