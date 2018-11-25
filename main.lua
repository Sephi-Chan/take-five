io.stdout:setvbuf('no')
if arg[#arg] == "-debug" then require("mobdebug").start() end

local Game = require("game")
local UI   = require("ui")
local JSON = require("lib.json")


function love.load()
  love.window.setTitle("6 qui prend !")

  mouse          = { x = 0, y = 0 }
  game           = Game.create()
  ui             = UI.create(love.graphics.getWidth(), love.graphics.getHeight())
  current_player = 1

  game.add_player("corwin")
  game.add_player("mandor")
  game.add_player("eric")
  game.start_game(shuffle(deck()))
  game.player_picks_card("corwin", 68)
  game.player_picks_card("mandor", 35)
  game.player_picks_card("eric", 42)

  game.player_picks_card("corwin", 56)
  game.player_picks_card("mandor", 51)
  game.player_picks_card("eric", 95)

  game.player_picks_card("corwin", 63)
  game.player_picks_card("mandor", 22)
  game.player_picks_card("eric", 26)

  game.player_picks_card("corwin", 29)
  game.player_picks_card("mandor", 100)
  game.player_picks_card("eric", 104)

  game.player_picks_card("corwin", 76)
  game.player_picks_card("mandor", 28)
  game.player_picks_card("eric", 20)
end


function love.update(delta)
  mouse.x = love.mouse.getX()
  mouse.y = love.mouse.getY()
  UI.update(ui, mouse, game, current_player)

  _track("state", game.current)
  _track("replacement", JSON.encode(game.data.replacement))
end


function love.draw()
  UI.draw(ui)
  _show_dump(10, 10)
end


function love.keypressed(key)
  if key == "escape" then
    love.event.quit()

  elseif key == "space" then
    current_player = current_player + 1
    if current_player == #game.data.players + 1 then current_player = 1 end
  end
end


function love.mousepressed(mouse_x, mouse_y, button)
  if game.current == "waiting_for_choices" and ui.hand.y < mouse_y then
    for card_index = 1, #ui.hand.cards do
      local card = ui.hand.cards[card_index]
      if card.x <= mouse_x and mouse_x <= card.x + card.width then
        local player_name = game.data.players[current_player]
        local value = game.data.hands[current_player][card_index]
        game.player_picks_card(player_name, game.data.hands[current_player][card_index])
        break
      end
    end
  end
end


function deck()
  local cards = {}
  for i = 1, 104 do
    cards[i] = i
  end
  return cards
end


function shuffle(table)
  for i = #table, 1, -1 do
    local j = math.random(i)
    table[i], table[j] = table[j], table[i]
  end
  return table
end


_dumped_values = {}
function _track(key, string)
  _dumped_values[key] = tostring(string)
end


function _show_dump(x, y)
  love.graphics.setColor(1, 1, 1)
  local i = 0
  for key, value in pairs(_dumped_values) do
    love.graphics.print(key .. " : " .. value, x, y + 15 * i)
    i = i + 1
  end
end
