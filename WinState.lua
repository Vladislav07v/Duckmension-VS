-- WinState.lua
-- Shown to ALL players (winner and losers) when a match ends.
-- Responsible for:
--   • Displaying who won and who lost
--   • Syncing cookies to the website (winner only)
--   • Sending LEAVE_LOBBY exactly once and resetting network lobby state
--   • Returning all players to the hub (Play 0) ready for a new room

local GameState = require('GameState')
local baton     = require('baton')
local socket    = require('socket')

-- ── Configuration (must match LoginState.lua) ─────────────────────────────────
local WEBSITE_HOST = "duckmensionvs.runasp.net"
local WEBSITE_PORT = 80
-- ──────────────────────────────────────────────────────────────────────────────

local mt = {}
mt.__index = mt

-- ── HTTP helpers (same pattern as LoginState) ─────────────────────────────────

local function http_post(host, port, path, json_body)
    local sock = socket.tcp()
    sock:settimeout(10)
    local ok, err = sock:connect(host, port)
    if not ok then
        sock:close()
        print("[WinState] ERROR: connect() failed: " .. tostring(err))
        return nil, err
    end

    local request = table.concat({
        "POST " .. path .. " HTTP/1.1",
        "Host: " .. host,
        "Content-Type: application/json",
        "Content-Length: " .. #json_body,
        "Connection: close",
        "",
        json_body
    }, "\r\n")

    local bytes, serr = sock:send(request)
    if not bytes then
        sock:close()
        print("[WinState] ERROR: send() failed: " .. tostring(serr))
        return nil, serr
    end

    local full, rerr = sock:receive('*a')
    sock:close()

    if not full or full == "" then
        print("[WinState] ERROR: empty response: " .. tostring(rerr))
        return nil, "Empty response"
    end

    local body = full:match("\r\n\r\n(.+)$") or full:match("\n\n(.+)$") or full
    return body, nil
end

local function encode_json(t)
    local parts = {}
    for k, v in pairs(t) do
        local val
        if type(v) == "string" then
            val = '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
        elseif type(v) == "number" then
            val = tostring(v)
        end
        if val then table.insert(parts, '"' .. k .. '":' .. val) end
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function json_get_number(json, key)
    local v = json:match('"' .. key .. '":%s*(%-?%d+)')
    return v and tonumber(v) or nil
end

-- ── Cookie sync ───────────────────────────────────────────────────────────────

local function sync_cookies(cookies_to_add)
    if not GameState.logged_in_user then
        print("[WinState] Not logged in, skipping cookie sync.")
        return
    end
    if cookies_to_add <= 0 then
        print("[WinState] No cookies to sync.")
        return
    end

    print(string.format("[WinState] Syncing %d cookies for '%s'...",
        cookies_to_add, GameState.logged_in_user))

    local body = encode_json({
        Username     = GameState.logged_in_user,
        CookiesToAdd = cookies_to_add,
    })

    local resp, err = http_post(WEBSITE_HOST, WEBSITE_PORT, "/api/game/update-cookies", body)
    if not resp then
        print("[WinState] Cookie sync failed: " .. tostring(err))
        return
    end

    local total = json_get_number(resp, "totalCookies")
    if total then
        GameState.logged_in_cookies = total
        print(string.format("[WinState] Cookie sync OK. New total: %d", total))
    else
        print("[WinState] Cookie sync: unexpected response: " .. tostring(resp))
    end
end

-- ── State methods ─────────────────────────────────────────────────────────────

function mt:update(dt)
    self.player:update()

    if self.player:pressed('jump') then
        local earned = GameState.doors_passed or 0

        if self.is_winner then
            -- Winner: sync cookies to website then add to local coin total
            sync_cookies(earned)
            GameState.coins = (GameState.coins or 0) + earned
        end
        -- Everyone: reset doors_passed for the next match
        GameState.doors_passed = 0

        -- Clean up lobby state exactly once here (not in PlayState)
        if GameState.network then
            GameState.network:send("LEAVE_LOBBY")
            GameState.network.lobby_state = nil
            GameState.network.in_lobby    = false
            GameState.network.winner_id   = nil
            GameState.network.winner_name = nil
        end

        -- Return everyone to the hub, ready to create or join a new room
        GameState.setCurrent('Play', 0)
    end
end

function mt:draw()
    local font = love.graphics.newFont("assets/upheavtt.ttf", 20)
    local small = love.graphics.newFont("assets/upheavtt.ttf", 15)
    love.graphics.setFont(font)

    local earned     = GameState.doors_passed or 0
    local winner_name = "Unknown"
    if GameState.network and GameState.network.winner_name then
        winner_name = GameState.network.winner_name
    elseif self.is_winner and GameState.logged_in_user then
        -- Offline / single-player win
        winner_name = GameState.logged_in_user
    end

    -- ── Heading ───────────────────────────────────────────────────────────
    if self.is_winner then
        love.graphics.setColor(0.2, 1, 0.2, 1)
        love.graphics.print("YOU WON!", 80, 30)
    else
        love.graphics.setColor(1, 0.3, 0.3, 1)
        love.graphics.print("YOU LOST!", 80, 30)
    end

    -- ── Winner name ───────────────────────────────────────────────────────
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Winner: " .. winner_name, 80, 65)

    -- ── Local player result ───────────────────────────────────────────────
    love.graphics.setFont(small)
    local my_name = GameState.logged_in_user or "You"
    if self.is_winner then
        love.graphics.setColor(0.2, 1, 0.2, 1)
        love.graphics.print(my_name .. " - WINNER", 80, 100)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(string.format("Cookies earned this match: %d", earned), 80, 120)
        if GameState.logged_in_user then
            love.graphics.print(string.format("Total on website: %d",
                GameState.logged_in_cookies or 0), 80, 140)
        end
    else
        love.graphics.setColor(1, 0.5, 0.5, 1)
        love.graphics.print(my_name .. " - lost", 80, 100)
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.print(string.format("Doors passed: %d (not added to cookies)", earned), 80, 120)
    end

    -- ── Prompt ────────────────────────────────────────────────────────────
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.print("Press (jump) to return to hub", 80, 170)
end

function mt:trigger() end

-- ── Constructor ───────────────────────────────────────────────────────────────

return {
    new = function(args)
        args = args or {}
        local state = setmetatable({
            name       = 'Win',
            -- Default to winner=true so offline single-player works unchanged
            is_winner  = (args.is_winner ~= false),
        }, mt)

        state.player = baton.new {
            controls = {
                jump = { 'key:z', 'button:b', 'mouse:1' },
            },
            joystick = love.joystick.getJoysticks()[1],
            deadzone = .33,
        }

        return state
    end
}
