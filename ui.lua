local UI = {}
local Game = require("game")

local PORTRAIT_WIDTH  = 45
local PORTRAIT_HEIGHT = 45
local PORTRAIT_MARGIN = 5

local CARD_WIDTH          = 70
local CARD_HEIGHT         = 100
local CARD_MARGIN         = 5
local CARD_OVERLAP        = 30
local CARD_PICKED_OFFSET  = 20
local CARD_HOVERED_OFFSET = 10
local HAND_OFFSET         = -20
local BURDEN_OVERLAP      = 70

local CARD_FONT        = love.graphics.newFont(13)
local INSTRUCTION_FONT = love.graphics.newFont(13)

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
    },

    choices = {
      x      = 0,
      y      = 0,
      width  = 0,
      height = 0,
      cards  = {}
    },

    replacement = false
  }
end


function UI.update(ui, mouse, game, current_player)
  update_replacement(ui, mouse, game, current_player)
  update_portraits(ui, mouse, game, current_player)
  update_hand(ui, mouse, game, current_player)
  update_board(ui, mouse, game, current_player)
  update_burden(ui, mouse, game, current_player)
  update_choices(ui, mouse, game, current_player)
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
    local x      = current_player == player_index and 0 or -10
    local y      = 100 + (player_index - 1) * (PORTRAIT_HEIGHT + PORTRAIT_MARGIN)
    local burden = game.is("finished") and count_burden(game.data.burden[player_index])

    ui.portraits[player_index] = {
      x                  = x,
      y                  = y,
      width              = PORTRAIT_WIDTH,
      height             = PORTRAIT_HEIGHT,
      waiting_for_choice = game.data.choices[player_index] == Game.NIL_CARD,
      burden             = burden
    }
  end
end


function update_hand(ui, mouse, game, current_player)
  ui.hand.visible = game.is("waiting_for_choices")
  ui.hand.width   = (CARD_WIDTH + CARD_MARGIN) * #game.data.hands[current_player] - CARD_MARGIN
  ui.hand.height  = CARD_HEIGHT
  ui.hand.x       = ui.window.width/2 - ui.hand.width/2
  ui.hand.y       = ui.window.height - CARD_HEIGHT - HAND_OFFSET
  ui.hand.hover   = ui.hand.y <= mouse.y
  ui.hand.cards   = {}

  for card_index = 1, #game.data.hands[current_player] do
    local card   = game.data.hands[current_player][card_index]
    local picked = game.data.choices[current_player] == card
    local card_x = ui.hand.x + (card_index - 1) * (CARD_WIDTH + CARD_MARGIN)
    local card_y = picked and ui.hand.y - CARD_PICKED_OFFSET or ui.hand.y
    local hover  = ui.hand.visible and ui.hand.hover and card_x <= mouse.x and mouse.x <= card_x + CARD_WIDTH

    if hover and not picked then
      card_y = card_y - CARD_HOVERED_OFFSET
    end

    ui.hand.cards[card_index] = {
      x      = card_x,
      y      = card_y,
      width  = CARD_WIDTH,
      height = CARD_HEIGHT,
      picked = picked,
      hover  = hover,
      color  = card_color(card),
      labels = card_labels(card, card_x, card_y)
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
        color  = card_color(card),
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
      color  = card_color(card),
      labels = card_labels(card, card_x, card_y)
    }
  end
end


function update_choices(ui, mouse, game, current_player)
  local player_for_card = {}
  local sorted_cards    = {}

  ui.choices.height = CARD_HEIGHT
  ui.choices.width  = (CARD_WIDTH * #game.data.choices) + (CARD_MARGIN * (#game.data.choices - 1))
  ui.choices.x      = ui.window.width/2 - ui.choices.width/2
  ui.choices.y      = ui.window.height - CARD_HEIGHT - HAND_OFFSET
  ui.choices.cards  = {}
  for player_index, card in ipairs(game.data.choices) do
    player_for_card[card] = player_index
    table.insert(sorted_cards, card)
  end
  table.sort(sorted_cards)

  for card_index, card in ipairs(sorted_cards) do
    local player_index      = player_for_card[card]
    local card_x            = ui.choices.x + (card_index - 1) * (CARD_WIDTH + CARD_MARGIN)
    local card_y            = ui.choices.y
    local is_replacing_card = card == game.data.replacement.replacing_card

    if is_replacing_card then
      card_y = card_y - CARD_HOVERED_OFFSET
    end

    ui.choices.cards[card_index] = {
      x                 = card_x,
      y                 = card_y,
      width             = CARD_WIDTH,
      height            = CARD_HEIGHT,
      color             = card_color(card),
      labels            = card_labels(card, card_x, card_y),
      player_index      = player_index,
      is_replacing_card = is_replacing_card
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


function UI.draw(ui, game)
  draw_portraits(ui, game)
  draw_hand(ui, game)
  draw_choices(ui, game)
  draw_board(ui, game)
  draw_burden(ui, game)
end


function draw_portraits(ui, game)
  for player_index, portrait in ipairs(ui.portraits) do
    love.graphics.setColor(COLORS[player_index])
    love.graphics.rectangle("fill", portrait.x, portrait.y, portrait.width, portrait.height)

    if portrait.waiting_for_choice then
      love.graphics.setColor(0, 0, 0)
      love.graphics.print("...", portrait.x + 15, portrait.y + 10)
    end

    if portrait.burden then
      love.graphics.setColor(0, 0, 0)
      love.graphics.print(portrait.burden, portrait.x + 15, portrait.y + 10)
    end
  end
end


function draw_hand(ui, game)
  if ui.hand.visible then
    for card_index, card in ipairs(ui.hand.cards) do
      draw_card(card)
    end
  end
end


function draw_board(ui, game)
  for column_index, column in ipairs(ui.board.columns) do
    for card_index, card in ipairs(column.cards) do
      draw_card(card)
    end
  end
end


function draw_burden(ui, game)
  for card_index, card in ipairs(ui.burden.cards) do
    draw_card(card)
  end
end


function draw_choices(ui, game)
  if game.is("waiting_for_column_replacement") then
    for card_index, card in ipairs(ui.choices.cards) do
      draw_card(card, border)
    end

    local instruction
    if ui.replacement then
      instruction = "Cliquez sur la colonne que vous allez ramasser pour poser votre " .. game.data.replacement.replacing_card .. "."
    else
      local player_name = game.data.players[game.data.replacement.replacing_player_index]
      instruction = "En attente de " .. player_name .. " pour remplacer une colonne et poser son " .. game.data.replacement.replacing_card .. "."
    end

    love.graphics.setColor(1, 1, 1)
    local instruction_width = INSTRUCTION_FONT:getWidth(instruction)
    local instruction_x     = math.floor(ui.window.width/2 - instruction_width/2)
    local instruction_y     = math.floor(ui.board.y - 40)
    love.graphics.print(instruction, instruction_x, instruction_y)
  end
end


function draw_card(card)
  love.graphics.setColor(card.color)
  love.graphics.rectangle("fill", card.x, card.y, card.width, card.height)

  love.graphics.setFont(CARD_FONT)
  love.graphics.setColor(0, 0, 0)
  love.graphics.print(card.labels.top.text, card.labels.top.x, card.labels.top.y)
  love.graphics.print(card.labels.bottom.text, card.labels.bottom.x, card.labels.bottom.y)

  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle("line", card.x, card.y, card.width, card.height)
end


-- A block must respond to x, y, width, height and cards.
function UI.card_at_coordinates(ui, mouse_x, mouse_y, block)
  if block.y <= mouse_y and mouse_y < block.y + block.height then
    for card_index, card in ipairs(block.cards) do
      if card.x <= mouse_x and mouse_x < card.x + card.width then
        return card_index
      end
    end
  end
end


function count_burden(burden)
  local total = 0
  for _, card in ipairs(burden) do
    if     card == 55     then total = total + 7
    elseif card % 11 == 0 then total = total + 5
    elseif card % 10 == 0 then total = total + 3
    elseif card %  5 == 0 then total = total + 2
    else                       total = total + 1
    end
  end
  return total
end


local COLORS = {
  PURPLE = { 118/255, 66/255, 138/255 },
  RED    = { 172/255, 50/255, 50/255 },
  GREEN  = { 106/255, 190/255, 48/255 },
  BLUE   = { 91/255, 110/255, 225/255 },
  WHITE  = { 1, 1, 1 }
}
function card_color(card)
  if     card == 55     then return COLORS.PURPLE
  elseif card % 11 == 0 then return COLORS.RED
  elseif card % 10 == 0 then return COLORS.GREEN
  elseif card %  5 == 0 then return COLORS.BLUE
  else                       return COLORS.WHITE
  end
end


return UI
