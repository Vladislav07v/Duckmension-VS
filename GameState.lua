local GameState = {}
GameState.doors_passed = 0
GameState.coins = 0
GameState.network = nil  -- Add network reference

function GameState.setCurrent(state_name, args)
  local parent = GameState.current
  GameState.next_current = require(state_name .. 'State').new(args, parent)
  if not GameState.current then
    GameState.update()
  end
end

function GameState.getCurrent()
  return GameState.current
end

function GameState.update(dt)
  GameState.current = GameState.next_current
end

function GameState.getDuckObject()
  local current = GameState.getCurrent()
  if not current or not current.world then return nil end
  for _, item in ipairs(current.world.items) do
    if item.is_duck then
      return item
    end
  end
end

function GameState.setNetwork(network)
  GameState.network = network
end

return GameState
