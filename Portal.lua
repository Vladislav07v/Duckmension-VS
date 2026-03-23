local const = require('const')
local GameState = require('GameState')
local Animation = require('Animation')

local mt = {}
mt.__index = mt

-- Static table to track all portals in the world and manage teleportation
local portalManager = {
  portals = {},
  nextPortalId = 1,
}

function mt:update(dt)
  -- Advance animation timer
  if self.current_anim then
    self.current_anim:update(dt)
  end

  -- Update cooldown timer
  if self.cooldown > 0 then
    self.cooldown = self.cooldown - dt
  end

  -- Check if duck is touching this portal
  local ducks = self.world:find(self, 'is_duck')
  if #ducks > 0 then
    local duck = ducks[1]
    -- Only teleport if cooldown has expired
    if self.cooldown <= 0 then
      self:teleportDuck(duck)
    end
  end
end

function mt:draw()
  -- Draw portal with color based on pair ID
  if self.pair_id == 1 then
    love.graphics.setColor(0.2, 0.8, 0.9, 1) -- Cyan for first portal pair
  else
    love.graphics.setColor(0.9, 0.2, 0.8, 1) -- Magenta for second portal pair
  end
  
  -- Draw portal as a circle or animated effect
  love.graphics.circle('fill', self.x + self.w/2, self.y + self.h/2, self.w/2)
  
  -- Draw direction indicator
  love.graphics.setColor(1, 1, 1, 1)
  local dx, dy = self:getDirectionVector()
  love.graphics.line(
    self.x + self.w/2,
    self.y + self.h/2,
    self.x + self.w/2 + dx * 8,
    self.y + self.h/2 + dy * 8
  )
end

function mt:onTouch(duck)
  -- Only teleport if cooldown has expired and duck is valid
  if self.cooldown <= 0 and duck then
    self:teleportDuck(duck)
  end
end

function mt:getDirectionVector()
  if self.direction == 1 then -- up
    return 0, -1
  elseif self.direction == 2 then -- right
    return 1, 0
  elseif self.direction == 3 then -- down
    return 0, 1
  else -- left (4)
    return -1, 0
  end
end

function mt:teleportDuck(duck)
  -- Find the linked portal (same pair_id, different portal)
  local target_portal = nil
  for _, portal in ipairs(portalManager.portals) do
    if portal.pair_id == self.pair_id and portal ~= self then
      target_portal = portal
      break
    end
  end

  if not target_portal then
    return -- No linked portal found
  end

  -- Get the exit direction from the target portal
  local dx, dy = target_portal:getDirectionVector()

  -- Teleport duck to target portal with offset in exit direction
  local offset = 12
  duck.x = target_portal.x + self.w/2 + dx * offset
  duck.y = target_portal.y + self.h/2 + dy * offset

  -- Set velocity based on portal exit direction
  local exit_speed = 300
  duck.vy = dy * exit_speed
  -- Horizontal momentum is preserved but adjusted for direction
  if dx ~= 0 then
    duck.vx = dx * exit_speed
  end

  -- Set cooldown on both portals to prevent immediate re-entry
  self.cooldown = 0.5
  if target_portal then
    target_portal.cooldown = 0.5
  end
end

function mt:setAnim(name)
  if self.current_anim ~= self.anims[name] then
    self.current_anim = self.anims[name]
    self.current_anim.t = 0
  end
end

return {
  -- new signature accepts opts table with Direction and PairId
  -- opts.Direction: 1=up, 2=right, 3=down, 4=left
  -- opts.PairId: 1 or 2 (portals with same PairId are linked)
  new = function(x, y, game_state, opts)
    opts = opts or {}
    local direction = opts.Direction or 2 -- default right
    local pair_id = opts.PairId or 1 -- default first pair

    local portal = setmetatable({
      is_portal = true,
      is_touchable = true,
      x = x,
      y = y,
      w = const.tilesize,
      h = const.tilesize,
      direction = direction,
      pair_id = pair_id,
      world = game_state and game_state.world or nil,
      cooldown = 0,
      current_anim = nil,
      anims = {
        idle = Animation.new(1, 1, 0.1),
      },
      z_index = 6,
    }, mt)

    portal:setAnim('idle')

    -- Register portal in global manager
    portalManager.portals[#portalManager.portals + 1] = portal

    return portal
  end,

  -- Helper function to get all portals (for cleanup if needed)
  getPortalManager = function()
    return portalManager
  end,
}