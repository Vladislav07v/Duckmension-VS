local GameState = {}
GameState.doors_passed = 0

function GameState.setCurrent(state_name, args)
  GameState.next_current = require(state_name .. 'State').new(args)
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

return GameState
