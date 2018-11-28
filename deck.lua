local Deck = {}


function Deck.create(size)
  local cards = {}

  for i = 1, size do
    cards[i] = i
  end

  return cards
end


function Deck.shuffle(deck)
  for i = #deck, 1, -1 do
    local j = math.random(i)
    deck[i], deck[j] = deck[j], deck[i]
  end

  return deck
end


return Deck
