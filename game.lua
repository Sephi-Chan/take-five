local FSM = require("lib.fsm")
local JSON = require("lib.json")

local Game = {
  NIL_CARD         = -1,
  REPLACEMENT_CARD = -2,
  HAND_SIZE        = 10,
  COLUMNS_COUNT    = 4,
  COLUMN_SIZE      = 5
}


function Game.create()
  return FSM.create({
    initial = "idle",

    events = {
      { name = "player_joins",           from = "idle",                           to = "idle" },
      { name = "player_leaves",          from = "idle",                           to = "idle" },
      { name = "start_game",             from = "idle",                           to = "waiting_for_choices" },
      { name = "start_game",             from = "idle",                           to = "waiting_for_choices" },
      { name = "player_picks_card",      from = "waiting_for_choices",            to = "waiting_for_choices" },
      { name = "player_picks_card",      from = "waiting_for_choices",            to = "waiting_for_resolution" },
      { name = "resolve_round",          from = "waiting_for_resolution",         to = "waiting_for_choices" },
      { name = "resolve_round",          from = "waiting_for_resolution",         to = "waiting_for_column_replacemen" },
      { name = "resolve_round",          from = "waiting_for_resolution",         to = "finished" },
      { name = "player_replaces_column", from = "waiting_for_column_replacement", to = "waiting_for_choices" },
      { name = "player_replaces_column", from = "waiting_for_column_replacement", to = "finished" }
    },

    callbacks = {
      on_startup = function(self, event, from, to)
        self.data = {
          players     = {},
          hands       = {},
          columns     = {},
          choices     = {},
          burden      = {},
          replacement = {}
        }
      end,


      on_player_joins = function(self, event, from, to, player_name)
        table.insert(self.data.players, player_name)
        table.insert(self.data.hands,   {})
        table.insert(self.data.choices, Game.NIL_CARD)
        table.insert(self.data.burden,  {})
      end,


      on_player_leaves = function(self, event, from, to, player_name)
        local player_index = indexOf(self.data.players, player_name)

        if player_index then
          self.data.players[player_index] = nil
          self.data.hands[player_index]   = nil
          self.data.choices[player_index] = nil
          self.data.burden[player_index]  = nil
        end
      end,


      on_start_game = function(self, event, from, to, deck)
        local needed_cards = #self.data.players * 10 + Game.COLUMNS_COUNT

        if 3 <= #self.data.players and needed_cards <= #deck  then
          for player_index = 1, #self.data.players do
            for i = 1, Game.HAND_SIZE do
              local card = table.remove(deck, 1)
              table.insert(self.data.hands[player_index], card)
            end
          end

          for column_index = 1, Game.COLUMNS_COUNT do
            local card = table.remove(deck, 1)
            self.data.columns[column_index] = {}
            table.insert(self.data.columns[column_index], card)
          end

          self.current = "waiting_for_choices"
        else
          self.current = "idle"
        end
      end,


      on_player_picks_card = function(self, event, from, to, player_name, card)
        local player_index = index_of(self.data.players, player_name)
        local card_index   = index_of(self.data.hands[player_index], card)
        assert(player_index, "The player is not in the game.")
        assert(card_index, "The player doesn't have the card.")

        self.data.choices[player_index] = card

        if did_all_player_choose(self.data.choices) then
          self.current = "waiting_for_resolution"
        else
          self.current = "waiting_for_choices"
        end
      end,


      on_resolve_round = function(self, event, from, to)
        local needs_replacement, replacing_player_index, replacing_card = is_replacement_needed(self.data.columns, self.data.choices)

        if needs_replacement then
          self.current = "waiting_for_column_replacement"
          self.data.replacement.replacing_player_index = replacing_player_index
          self.data.replacement.replacing_card         = replacing_card
        else
          resolve_choices(self)
        end
      end,


      on_player_replaces_column = function(self, event, from, to, player_name, column_index)
        local player_index = index_of(self.data.players, player_name)
        local needs_replacement, replacing_player_index, replacing_card = is_replacement_needed(self.data.columns, self.data.choices)

        assert(needs_replacement, "There is no need for a column replacement.")
        assert(1 <= column_index and column_index <= Game.COLUMNS_COUNT, "The column is out of bounds.")
        assert(player_index == replacing_player_index, "The player is not the one who needs to replace a column.")

        for i = 1, #self.data.columns[column_index] do
          table.insert(self.data.burden[player_index], self.data.columns[column_index][i])
        end
        self.data.columns[column_index] = { replacing_card }
        self.data.choices[player_index] = Game.REPLACEMENT_CARD

        card_index = index_of(self.data.hands[player_index], replacing_card)
        table.remove(self.data.hands[player_index], card_index)

        resolve_choices(self)
        self.data.replacement = {}
      end
    }
  })
end


function resolve_choices(self)
  local player_for_card = {}
  local sorted_cards    = {}

  for player_index = 1, #self.data.choices do
    player_for_card[self.data.choices[player_index]] = player_index
    sorted_cards[player_index] = self.data.choices[player_index]
  end
  table.sort(sorted_cards)

  for sorted_card_index, card in ipairs(sorted_cards) do
    if card ~= Game.REPLACEMENT_CARD then
      local player_index      = player_for_card[card]
      local best_column_index = find_best_column_index(card, self.data.columns)
      local card_hand_index   = index_of(self.data.hands[player_index], card)

      if #self.data.columns[best_column_index] == Game.COLUMN_SIZE then
        for card_index = 1, #self.data.columns[best_column_index] do
          table.insert(self.data.burden[player_index], self.data.columns[best_column_index][card_index])
        end
        self.data.columns[best_column_index] = {}
      end

      table.remove(self.data.hands[player_index], card_hand_index)
      table.insert(self.data.columns[best_column_index], card)
    end
  end

  if is_game_finished(self.data) then
    self.current = "finished"

  else -- setup new round
    self.current = "waiting_for_choices"
    for player_index = 1, #self.data.players do
      self.data.choices[player_index] = Game.NIL_CARD
    end
  end
end


function index_of(table, needle)
  for i, value in pairs(table) do
    if needle == value then
      return i
    end
  end
end


function did_all_player_choose(choices)
  for i = 1, #choices do
    if choices[i] == Game.NIL_CARD then
      return false
    end
  end
  return true
end


function is_replacement_needed(columns, choices)
  local replacing_player_index     = nil
  local replacing_player_card      = nil
  local smallest_card_on_board     = 99999
  local smallest_card_chosen       = 99999
  local smallest_card_player_index = nil

  for column_index = 1, #columns do
    local last_card = columns[column_index][#columns[column_index]]

    if last_card < smallest_card_on_board then
      smallest_card_on_board = last_card
    end
  end

  for player_index = 1, #choices do
    if choices[player_index] < smallest_card_chosen then
      smallest_card_chosen       = choices[player_index]
      smallest_card_player_index = player_index
    end
  end

  local replacement_needed = smallest_card_chosen < smallest_card_on_board
  return replacement_needed, smallest_card_player_index, smallest_card_chosen
end


function is_game_finished(data)
  return data.hands[1][1] == nil
end


function find_best_column_index(card, columns)
  local smallest_positive_difference = 99999
  local best_column_index            = nil

  for column_index = 1, #columns do
    local last_card  = columns[column_index][#columns[column_index]] or 0
    local difference = card - last_card

    if 0 < difference and difference < smallest_positive_difference then
      smallest_positive_difference = difference
      best_column_index            = column_index
    end
  end

  return best_column_index
end


return Game
