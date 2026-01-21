local GameState = require('GameState')

local Music = {}

local currentMusic = nil
local currentStateName = nil
local sources = {}

local function getSourceForPath(musicPath)
  if sources[musicPath] then
    return sources[musicPath]
  end
  local s = love.audio.newSource(musicPath, "stream")
  s:setLooping(true)
  sources[musicPath] = s
  return s
end

local function setMusicForState(stateName)
  -- normalize state names and choose a music path
  local lower = (stateName or ""):lower()
  local musicPath
  if lower:find("play") then
    musicPath = "assets/game.mp3"
  else
    musicPath = "assets/title.mp3"
  end

  local newSource = getSourceForPath(musicPath)

  if currentMusic == newSource then
    if not currentMusic:isPlaying() then
      love.audio.play(currentMusic)
    end
    return
  end

  if currentMusic then
    pcall(function() currentMusic:stop() end)
  end

  currentMusic = newSource
  love.audio.play(currentMusic)
end

function Music:load()
  local currentState = GameState.getCurrent()
  if currentState then
    currentStateName = currentState.name
    setMusicForState(currentStateName)
  end
end

function Music:update()
  local currentState = GameState.getCurrent()
  if currentState and currentState.name ~= currentStateName then
    currentStateName = currentState.name
    setMusicForState(currentStateName)
  end
end

function Music:stop()
  if currentMusic then currentMusic:stop() end
end

function Music:play()
  if currentMusic then love.audio.play(currentMusic) end
end

return Music