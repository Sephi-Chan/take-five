io.stdout:setvbuf('no')
if arg[#arg] == "-debug" then require("mobdebug").start() end

local Deck = require("deck")
local Game = require("game")
local UI   = require("ui")
local JSON = require("lib.json")


function love.load()
  love.window.setTitle("6 qui prend !")

  mouse          = { x = 0, y = 0 }
  game           = Game.create()
  ui             = UI.create(love.graphics.getWidth(), love.graphics.getHeight())
  current_player = 1

  local deck = Deck.create(104)

 game.player_joins("corwin")
 game.player_joins("mandor")
 game.player_joins("eric")
 game.start_game(Deck.shuffle(deck))

  -- game.player_picks_card("corwin", 68)
  -- game.player_picks_card("mandor", 35)
  -- game.player_picks_card("eric", 42)
  -- game.resolve_round()

  -- game.player_picks_card("corwin", 56)
  -- game.player_picks_card("mandor", 51)
  -- game.player_picks_card("eric", 95)
  -- game.resolve_round()

  -- game.player_picks_card("corwin", 63)
  -- game.player_picks_card("mandor", 22)
  -- game.player_picks_card("eric", 26)
  -- game.resolve_round()

  -- game.player_picks_card("corwin", 29)
  -- game.player_picks_card("mandor", 100)
  -- game.player_picks_card("eric", 104)
  -- game.resolve_round()

  -- game.player_picks_card("corwin", 76)
  -- game.player_picks_card("mandor", 28)
  -- game.player_picks_card("eric", 20)
  -- game.resolve_round()

  -- game.player_replaces_column("eric", 3)

  -- game.player_picks_card("corwin", 40)
  -- game.player_picks_card("mandor", 48)
  -- game.player_picks_card("eric", 45)
  -- game.resolve_round()

  -- game.player_picks_card("corwin", 50)
  -- game.player_picks_card("mandor", 52)
  -- game.player_picks_card("eric", 97)
  -- game.resolve_round()

  -- game.player_picks_card("corwin", 73)
  -- game.player_picks_card("mandor", 88)
  -- game.player_picks_card("eric", 98)
  -- game.resolve_round()

  -- game.player_picks_card("corwin", 14)
  -- game.player_picks_card("mandor", 101)
  -- game.player_picks_card("eric", 20)
  -- game.resolve_round()

  -- game.player_replaces_column("corwin", 2)

  -- game.player_picks_card("corwin", 92)
  -- game.player_picks_card("mandor", 91)
  -- game.player_picks_card("eric", 5)
  -- game.resolve_round()

  -- game.player_replaces_column("eric", 3)
end


function love.update(delta)
  mouse.x = love.mouse.getX()
  mouse.y = love.mouse.getY()
  UI.update(ui, mouse, game, current_player)
end


function love.draw()
  UI.draw(ui, game)
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
  local player_name = game.data.players[current_player]

  if game.is("waiting_for_choices") then
    player_picks_card(player_name, mouse_x, mouse_y)

  elseif game.is("waiting_for_column_replacement") then
    player_replaces_column(player_name, mouse_x, mouse_y)
  end
end


function player_picks_card(player_name, mouse_x, mouse_y)
  local card_index = UI.card_at_coordinates(ui, mouse_x, mouse_y, ui.hand)

  if card_index then
    local card = game.data.hands[current_player][card_index]

    game.player_picks_card(player_name, card)

    if game.can("resolve_round") then
      game.resolve_round()
    end
  end
end


function player_replaces_column(player_name, mouse_x, mouse_y)
  if game.data.replacement.replacing_player_index == current_player then
    for column_index, ui_column in ipairs(ui.board.columns) do
      local card_index = UI.card_at_coordinates(ui, mouse_x, mouse_y, ui_column)

      if card_index then
        game.player_replaces_column(player_name, column_index)
        break
      end
    end
  end
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
