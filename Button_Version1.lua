local assets = require('assets32')
local const = require('const')
local Animation = require('Animation')

local mt = {}
mt.__index = mt

function mt:update(dt)
  self: setAnim('idle')
  -- reset pressed state when duck is no longer colliding so the button can be toggled again
  if not self.world:check(self, 'is_duck') then
    self.down = false
  end
end

function mt:draw()
    assets.qdraw(self.current_anim:getFrame(), self.x - 6, self.y)
end

function mt:setAnim(name)
  self.current_anim = self.anims[name]
end

function mt:onTouch(other)
  if not other.is_duck then return end
  -- only toggle on initial contact (debounce)
  if self.down then return end
  self.down = true
  self: setAnim('pushed')

  -- find all button_floor instances in the world and toggle their presence
  local floors = self.world:find('all', 'is_button_floor')
  if self.floor_active == nil then self.floor_active = true end

  if self.floor_active then
    -- remove all floors and remember them so we can re-add later
    self.removed_floors = {}
    for _, f in ipairs(floors) do
      -- remove from world but keep the object reference
      self.world:remove(f)
      self.removed_floors[#self.removed_floors + 1] = f
    end
    self.floor_active = false
  else
    -- re-add previously removed floors (if any)
    if self.removed_floors then
      for _, f in ipairs(self.removed_floors) do
        self.world:add(f)
      end
      self.removed_floors = {}
    end
    self.floor_active = true
  end
end

return {
  new = function(x, y, game_state)
    local h = setmetatable({
      is_touchable = true,
      x = x,
      y = y,
      w = const.tilesize,
      h = const.tilesize,
      anims = {
        idle = Animation.new(13, 8, 1),
        pushed = Animation.new(13, 8, 0.75)},
      world = (game_state and game_state.world) or nil,
      down = false,
      floor_active = true,
      removed_floors = {},
      z_index = 5
    }, mt)
    h: setAnim('idle')
    return h
  end
}