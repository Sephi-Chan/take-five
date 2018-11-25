local UI = {}
local Game = require("game")

local PORTRAIT_WIDTH  = 45
local PORTRAIT_HEIGHT = 45
local PORTRAIT_MARGIN = 5

local CARD_WIDTH  = 70
local CARD_HEIGHT = 100
local CARD_MARGIN = 5
local CARD_OVERLAP = 30
local CARD_PICKED_OFFSET  = 20
local CARD_HOVERED_OFFSET = 10
local HAND_OFFSET         = -20
local BURDEN_OVERLAP      = 70

local CARD_FONT = love.graphics.newFont(13)

local COLORS = {
  { 1, 0, 0 },
  { 0, 1, 0 },
  { 0, 0, 1 }
}

function UI.create(width, height)
  return {
    window = {
      width = width,
      height = height
    },

    hand = {
      x                  = 0,
      y                  = 0,
      width              = 0,
      height             = 0,
      cards              = {},
      waiting_for_choice = false
    },

    board = {
      x      = 0,
      y      = 0,
      width  = 0,
      height = 0,
    },

    portraits = {
      x      = 0,
      y      = 0,
      width  = 0,
      height = 0,
    },

    burden = {
      x      = 0,
      y      = 0,
      width  = 0,
      height = 0,
      cards  = {}
    }
  }
end


function UI.update(ui, mouse, game, current_player)
  update_replacement(ui, mouse, game, current_player)
  update_portraits(ui, mouse, game, current_player)
  update_hand(ui, mouse, game, current_player)
  update_board(ui, mouse, game, current_player)
  update_burden(ui, mouse, game, current_player)
end


function update_replacement(ui, mouse, game, current_player)
  if game.data.replacement.replacing_player_index == current_player then
    ui.replacement = true -- handle hover/click on a column to replace.
  else
    ui.replacement = nil
  end
end


function update_portraits(ui, mouse, game, current_player)
  for player_index = 1, #game.data.players do
    local x = current_player == player_index and 0 or -10
    local y = 100 + (player_index - 1) * (PORTRAIT_HEIGHT + PORTRAIT_MARGIN)

    ui.portraits[player_index] = {
      x                  = x,
      y                  = y,
      width              = PORTRAIT_WIDTH,
      height             = PORTRAIT_HEIGHT,
      waiting_for_choice = game.data.choices[player_index] == Game.NIL_CARD
    }
  end
end


function update_hand(ui, mouse, game, current_player)
  ui.hand.visible = game.current == "waiting_for_choices"
  ui.hand.width  = (CARD_WIDTH + CARD_MARGIN) * #game.data.hands[current_player] - CARD_MARGIN
  ui.hand.height = CARD_HEIGHT
  ui.hand.x      = ui.window.width/2 - ui.hand.width/2
  ui.hand.y      = ui.window.height - CARD_HEIGHT - HAND_OFFSET
  ui.hand.hover  = ui.hand.y <= mouse.y
  ui.hand.cards  = {}

  for card_index = 1, #game.data.hands[current_player] do
    local card   = game.data.hands[current_player][card_index]
    local picked = game.data.choices[current_player] == card
    local x      = ui.hand.x + (card_index - 1) * (CARD_WIDTH + CARD_MARGIN)
    local y      = picked and ui.hand.y - CARD_PICKED_OFFSET or ui.hand.y
    local hover  = ui.hand.visible and ui.hand.hover and x <= mouse.x and mouse.x <= x + CARD_WIDTH

    if hover and not picked then
      y = y - CARD_HOVERED_OFFSET
    end

    ui.hand.cards[card_index] = {
      x      = x,
      y      = y,
      width  = CARD_WIDTH,
      height = CARD_HEIGHT,
      picked = picked,
      hover  = hover,
      labels = card_labels(card, x, y)
    }
  end
end


function update_board(ui, mouse, game, current_player)
  local visible_card_height = CARD_HEIGHT - CARD_OVERLAP
  ui.board.width   = (CARD_WIDTH + CARD_MARGIN) * #game.data.columns - CARD_MARGIN
  ui.board.height  = CARD_HEIGHT + (Game.COLUMN_SIZE - 1) * visible_card_height
  ui.board.x       = ui.window.width/2 - ui.board.width/2
  ui.board.y       = ui.hand.y - ui.board.height - CARD_PICKED_OFFSET * 2
  ui.board.columns = {}

  for column_index = 1, #game.data.columns do
    ui.board.columns[column_index] = {
      x      = ui.board.x + (column_index - 1) * (CARD_WIDTH + CARD_MARGIN),
      y      = ui.board.y,
      width  = CARD_WIDTH,
      height = ui.board.height,
      cards  = {}
    }

    for card_index = 1, #game.data.columns[column_index] do
      local card   = game.data.columns[column_index][card_index]
      local card_x = ui.board.columns[column_index].x
      local card_y = ui.board.y + ui.board.height - CARD_HEIGHT - (card_index - 1) * visible_card_height

      ui.board.columns[column_index].cards[card_index] = {
        x      = card_x,
        y      = card_y,
        width  = CARD_WIDTH,
        height = CARD_HEIGHT,
        labels = card_labels(card, card_x, card_y)
      }
    end
  end
end


function update_burden(ui, mouse, game, current_player)
  local visible_card_height = CARD_HEIGHT - BURDEN_OVERLAP
  ui.burden.height = CARD_HEIGHT + (#game.data.burden[current_player] - 1) * visible_card_height
  ui.burden.width  = CARD_WIDTH
  ui.burden.x      = ui.window.width - CARD_WIDTH/2
  ui.burden.y      = ui.window.height/2 - ui.burden.height/2
  ui.burden.cards  = {}

  for card_index = 1, #game.data.burden[current_player] do
    local card   = game.data.burden[current_player][card_index]
    local card_x = ui.burden.x
    local card_y = ui.burden.y + (card_index - 1) * visible_card_height

    ui.burden.cards[card_index] = {
      x      = card_x,
      y      = card_y,
      width  = CARD_WIDTH,
      height = CARD_HEIGHT,
      labels = card_labels(card, card_x, card_y)
    }
  end
end


function card_labels(card, x, y)
  local label_width  = CARD_FONT:getWidth(card)
  local label_height = CARD_FONT:getHeight()

  return {
    top = {
      text   = card,
      x      = x + 8,
      y      = y + 5,
      width  = label_width,
      height = label_height
    },
    bottom = {
      text   = card,
      x      = x + CARD_WIDTH - 8 - label_width,
      y      = y + CARD_HEIGHT - 5 - label_height,
      width  = label_width,
      height = label_height
    }
  }
end


function UI.draw(ui)
  draw_portraits(ui)
  if ui.hand.visible then draw_hand(ui) end
  draw_board(ui)
  draw_burden(ui)
end


function draw_portraits(ui)
  for player_index = 1, #ui.portraits do
    local portrait = ui.portraits[player_index]
    love.graphics.setColor(COLORS[player_index])
    love.graphics.rectangle("fill", portrait.x, portrait.y, portrait.width, portrait.height)

    if portrait.waiting_for_choice then
      love.graphics.setColor(0, 0, 0)
      love.graphics.print("...", portrait.x + 15, portrait.y + 10)
    end
  end
end


function draw_hand(ui)
  for card_index = 1, #ui.hand.cards do
    local card = ui.hand.cards[card_index]
    draw_card(card)
  end
end


function draw_board(ui)
  for column_index = 1, #ui.board.columns do
    local column = ui.board.columns[column_index]
    for card_index = 1, #column.cards do
      local card = column.cards[card_index]
      draw_card(card)
    end
  end
end


function draw_burden(ui)
  for card_index = 1, #ui.burden.cards do
    local card = ui.burden.cards[card_index]
    draw_card(card)
  end
end


function draw_card(card)
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle("fill", card.x, card.y, card.width, card.height)

  love.graphics.setFont(CARD_FONT)
  love.graphics.setColor(0, 0, 0)
  love.graphics.print(card.labels.top.text, card.labels.top.x, card.labels.top.y)
  love.graphics.print(card.labels.bottom.text, card.labels.bottom.x, card.labels.bottom.y)
  love.graphics.rectangle("line", card.x, card.y, card.width, card.height)
end


function draw_instructions(ui)
end


return UI
