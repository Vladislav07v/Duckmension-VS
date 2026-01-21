-- Central asset cache: load images once and keep references globally.
-- Provides duck sprite path + color storage and helpers.

local Assets = {}
local cache = {}

-- Load an image once and cache it under `key`.
function Assets.load(path, key)
  if not cache[key] then
    cache[key] = love.graphics.newImage(path)
  end
  return cache[key]
end

-- Get a cached image by key (returns nil if not loaded).
function Assets.get(key)
  return cache[key]
end

-- Preload common images (optional helper)
function Assets.preloadDefaults()
  Assets.load('assets/bg_dark.png', 'bg_dark')
  Assets.load('assets/bg_light.png', 'bg_light')
  Assets.load('assets/title_temp.png', 'title')
  Assets.load('assets/ducks.png', 'ducks')
  Assets.load('assets/tiles.png', 'tiles')
  Assets.load('assets/tex.png', 'tex16')
  Assets.load('assets/tex32.png', 'tex32')
end

-- Duck sprite and color management (kept here so duck image and color are single global values)
Assets.current_duck_sprite = 'assets/duck.png'
Assets.current_duck_color = {219, 186, 74} -- bytes

-- Return the current duck image, loading it if needed or if path changed.
function Assets.getDuckSprite()
  if cache['_duck_img'] and cache['_duck_img_path'] == Assets.current_duck_sprite then
    return cache['_duck_img']
  end
  local img = love.graphics.newImage(Assets.current_duck_sprite)
  cache['_duck_img'] = img
  cache['_duck_img_path'] = Assets.current_duck_sprite
  return img
end

function Assets.setDuckSprite(path)
  if path == Assets.current_duck_sprite then return end
  Assets.current_duck_sprite = path
  -- invalidate cached duck image so next getDuckSprite reloads
  cache['_duck_img'] = nil
  cache['_duck_img_path'] = nil
end

function Assets.getDuckColor()
  return Assets.current_duck_color
end

function Assets.setDuckColor(r, g, b)
  Assets.current_duck_color = {r, g, b}
end

return Assets