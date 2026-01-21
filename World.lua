local const = require('const')

local mt = {}
mt.__index = mt

-- simple spatial hash / grid using tile-sized buckets
local function bucket_key(x, y)
  return x .. ':' .. y
end

local function world_bucket_coords_for_item(item)
  -- compute covered tiles (min..max) to be safe for larger items
  local minx = math.floor(item.x / const.tilesize)
  local miny = math.floor(item.y / const.tilesize)
  local maxx = math.floor((item.x + (item.w or 0)) / const.tilesize)
  local maxy = math.floor((item.y + (item.h or 0)) / const.tilesize)
  return minx, miny, maxx, maxy
end

function mt:newBucket()
  return {}
end

function mt:add(item)
  -- keep items array for iteration/draw; insert by z_index to avoid global sort
  local z = item.z_index or 0
  local inserted = false
  for i = 1, #self.items do
    if (self.items[i].z_index or 0) > z then
      table.insert(self.items, i, item)
      inserted = true
      break
    end
  end
  if not inserted then
    self.items[#self.items + 1] = item
  end

  -- add to buckets
  local minx, miny, maxx, maxy = world_bucket_coords_for_item(item)
  for bx = minx, maxx do
    for by = miny, maxy do
      local k = bucket_key(bx, by)
      local bucket = self.buckets[k]
      if not bucket then
        bucket = {}
        self.buckets[k] = bucket
      end
      bucket[#bucket + 1] = item
    end
  end
  -- track which buckets the item occupies
  item._bucket_range = {minx = minx, miny = miny, maxx = maxx, maxy = maxy}
end

-- remove an item from the world (items list and buckets)
function mt:remove(item)
  -- remove from items array
  for i = #self.items, 1, -1 do
    if self.items[i] == item then
      table.remove(self.items, i)
      -- don't break; remove any duplicates if present
    end
  end
  
  -- remove from buckets
  local old = item._bucket_range or {}
  if old.minx then
    for bx = old.minx, old.maxx do
      for by = old.miny, old.maxy do
        local k = bucket_key(bx, by)
        local bucket = self.buckets[k]
        if bucket then
          for i = #bucket, 1, -1 do
            if bucket[i] == item then
              table.remove(bucket, i)
            end
          end
          if #bucket == 0 then
            self.buckets[k] = nil
          end
        end
      end
    end
  end

  item._bucket_range = nil
end
  
local function checkCollision(a, b)
  return a.x < b.x + (b.w or 0) and
         (a.x + (a.w or 0)) > b.x and
         a.y < b.y + (b.h or 0) and
         (a.h or 0) + a.y > b.y
end

-- internal helper: iterate candidate nearby items overlapping item's bbox
function mt:iterCandidates(item)
  local minx, miny, maxx, maxy
  if type(item) == "table" and item.x and item.w then
    minx, miny, maxx, maxy = world_bucket_coords_for_item(item)
  else
    -- 'item' might be a key bounding table (like check/find callers pass 'item' as area)
    minx = math.floor((item.x or 0) / const.tilesize)
    miny = math.floor((item.y or 0) / const.tilesize)
    maxx = math.floor(((item.x or 0) + (item.w or 0)) / const.tilesize)
    maxy = math.floor(((item.y or 0) + (item.h or 0)) / const.tilesize)
  end

  local seen = {}
  return function()
    for bx = minx, maxx do
      for by = miny, maxy do
        local k = bucket_key(bx, by)
        local bucket = self.buckets[k]
        if bucket then
          for i = 1, #bucket do
            local other = bucket[i]
            if not seen[other] then
              seen[other] = true
              coroutine.yield(other)
            end
          end
        end
      end
    end
  end
end

-- Note: we can't yield in simple iteration without coroutines; provide function that returns iter list
local function gather_candidates(self, minx, miny, maxx, maxy)
  local t = {}
  local seen = {}
  for bx = minx, maxx do
    for by = miny, maxy do
      local k = bucket_key(bx, by)
      local bucket = self.buckets[k]
      if bucket then
        for i = 1, #bucket do
          local other = bucket[i]
          if not seen[other] then
            seen[other] = true
            t[#t+1] = other
          end
        end
      end
    end
  end
  return t
end

function mt:check(item, param)
  local minx, miny, maxx, maxy = world_bucket_coords_for_item(item)
  local candidates = gather_candidates(self, minx, miny, maxx, maxy)
  for i = 1, #candidates do
    local other = candidates[i]
    if other ~= item and checkCollision(item, other) and (param == 'all' or other[param]) then
      return true
    end
  end
  return false
end

function mt:find(item, param)
  local minx, miny, maxx, maxy
  if item == 'all' then
    -- return all items that match param
    local t = {}
    for i = 1, #self.items do
      local other = self.items[i]
      if param == 'all' or other[param] then
        t[#t+1] = other
      end
    end
    return t
  else
    minx, miny, maxx, maxy = world_bucket_coords_for_item(item)
  end

  local t = {}
  local candidates = gather_candidates(self, minx, miny, maxx, maxy)
  for i = 1, #candidates do
    local other = candidates[i]
    if other ~= item and checkCollision(item, other) and (param == 'all' or other[param]) then
      t[#t+1] = other
    end
  end
  return t
end

function mt:move(item, new_x, new_y, param)
  local prev_x, prev_y = item.x, item.y

  -- move on X and handle collisions
  item.x = new_x
  local minx, miny, maxx, maxy = world_bucket_coords_for_item(item)
  local candidates = gather_candidates(self, minx, miny, maxx, maxy)
  for i = 1, #candidates do
    local other = candidates[i]
    if other ~= item and checkCollision(item, other) and (param == 'all' or other[param]) then
      if new_x > prev_x then
        item.x = other.x - item.w
      else
        item.x = other.x + other.w
      end
      break
    end
  end

  -- move on Y and handle collisions
  item.y = new_y
  minx, miny, maxx, maxy = world_bucket_coords_for_item(item)
  candidates = gather_candidates(self, minx, miny, maxx, maxy)
  for i = 1, #candidates do
    local other = candidates[i]
    if other ~= item and checkCollision(item, other) and (param == 'all' or other[param]) then
      if new_y > prev_y then
        item.y = other.y - item.h
      else
        item.y = other.y + other.h
      end
      break
    end
  end

  -- update bucket occupancy if it moved bucket-space
  local old = item._bucket_range or {}
  local new_minx, new_miny, new_maxx, new_maxy = world_bucket_coords_for_item(item)
  if old.minx ~= new_minx or old.miny ~= new_miny or old.maxx ~= new_maxx or old.maxy ~= new_maxy then
    -- remove from old buckets
    if old.minx then
      for bx = old.minx, old.maxx do
        for by = old.miny, old.maxy do
          local k = bucket_key(bx, by)
          local bucket = self.buckets[k]
          if bucket then
            for i = #bucket, 1, -1 do
              if bucket[i] == item then table.remove(bucket, i) end
            end
            if #bucket == 0 then self.buckets[k] = nil end
          end
        end
      end
    end
    -- add to new buckets
    for bx = new_minx, new_maxx do
      for by = new_miny, new_maxy do
        local k = bucket_key(bx, by)
        local bucket = self.buckets[k]
        if not bucket then
          bucket = {}
          self.buckets[k] = bucket
        end
        bucket[#bucket + 1] = item
      end
    end
    item._bucket_range = {minx = new_minx, miny = new_miny, maxx = new_maxx, maxy = new_maxy}
  end
end

return {
  new = function()
    return setmetatable({ items = {}, buckets = {} }, mt)
  end
}