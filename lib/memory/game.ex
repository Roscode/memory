defmodule Memory.Game do
  alias Memory.Game.Board

  def new() do
    %{tiles: Board.new(), guesses: [], partial_guess: nil, players: %{}, turn: nil}
  end

  def won_game(tiles) do
    Enum.all?(tiles, &(&1[:completed]))
  end

  def get_score(guesses, partial_guess) do
    2 * length(guesses) + (if partial_guess do 1 else 0 end)
  end

  def client_view(%{tiles: tiles, guesses: g, partial_guess: pg, players: players, turn: t}) do
    %{tiles: Board.client_view(tiles),
      score: get_score(g, pg),
      won: won_game(tiles),
      flip_delay: length(g) > 0 and !pg,
      players: players}
        |> Jason.encode!
  end

  def add_player(game, user) do
    put_in(game, [:players, user], 0)
    if (!game[:turn]) do
      put_in(game, [:turn], user)
    end
  end

  def next_turn(players, user) do
    player_keys = Map.keys(players)
    if (player_keys[0] == user) do
      player_keys[1]
    else
      player_keys[0]
    end
  end

  def flip(%{tiles: tiles, guesses: guesses, partial_guess: pg, players: players, turn: t}, new_guess, user) do
    if (user == t) do
      if pg do
        is_correct = Board.same_letter(tiles, pg, new_guess)
        if is_correct do
          tile_state = %{ completed: true }
          new_score = players[user] + 1
          new_players = put_in(players, [user], new_score)
          tiles = tiles
                  |> Board.update_tile(pg, tile_state)
                  |> Board.update_tile(new_guess, tile_state)
          {%{tiles: tiles,
            guesses: [{pg, new_guess}|guesses],
            partial_guess: nil,
            players: new_players,
            turn: next_turn(players, t)}, nil}
        else
          tile_state = %{ visible: true }
          visible_tiles = tiles
                  |> Board.update_tile(pg, tile_state)
                  |> Board.update_tile(new_guess, tile_state)
          tile_state = %{ visible: false }
          hidden_tiles = tiles
                  |> Board.update_tile(pg, tile_state)
                  |> Board.update_tile(new_guess, tile_state)
          {%{tiles: hidden_tiles,
            guesses: [{pg, new_guess}|guesses],
            partial_guess: nil,
            players: players,
            turn: next_turn(players, t)},
            %{tiles: visible_tiles,
            guesses: [{pg, new_guess}|guesses],
            partial_guess: nil,
            players: players,
            turn: next_turn(players, t)}}
        end
      else
        {%{tiles: Board.update_tile(tiles, new_guess, %{ visible: true }),
          guesses: guesses,
          partial_guess: new_guess,
          players: players,
          turn: t}, nil}
      end
    end
  end

end
