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
  end

  def flip(%{tiles: tiles, guesses: guesses, partial_guess: pg, players: players, turn: t}, new_guess) do
    if pg do
      is_correct = Board.same_letter(tiles, pg, new_guess)
      if is_correct do
        tile_state = %{ completed: true }
        tiles = tiles
                |> Board.update_tile(pg, tile_state)
                |> Board.update_tile(new_guess, tile_state)
        {%{tiles: tiles,
          guesses: [{pg, new_guess}|guesses],
          partial_guess: nil}, nil}
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
          partial_guess: nil},
          %{tiles: visible_tiles,
          guesses: [{pg, new_guess}|guesses],
          partial_guess: nil}}
      end
    else
      {%{tiles: Board.update_tile(tiles, new_guess, %{ visible: true }),
        guesses: guesses,
        partial_guess: new_guess}, nil}
    end
  end

end
