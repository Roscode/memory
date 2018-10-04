defmodule Memory.Game do
  alias Memory.Game.Board

  def new() do
    %{tiles: Board.new(), guesses: [], partial_guess: nil}
  end

  def won_game(tiles) do
    Enum.all?(tiles, &(&1[:completed]))
  end

  def get_score(guesses, partial_guess) do
    2 * length(guesses) + (if partial_guess do 1 else 0 end)
  end

  def client_view(%{tiles: tiles, guesses: g, partial_guess: pg}) do
      %{tiles: Board.client_view(tiles),
        score: get_score(g, pg),
        won: won_game(tiles)}
        |> Jason.encode!
  end

  def flip(%{tiles: tiles, guesses: guesses, partial_guess: pg}, new_guess) do
    if pg do
      is_correct = Board.same_letter(tiles, pg, new_guess)
      tile_state = %{ visible: false, completed: is_correct }
      tiles = tiles
              |> Board.update_tile(pg, tile_state)
              |> Board.update_tile(new_guess, tile_state)
      %{tiles: tiles,
        guesses: [{pg, new_guess}|guesses],
        partial_guess: nil}
    else
      %{tiles: Board.update_tile(tiles, new_guess, %{ visible: true }),
        guesses: guesses,
        partial_guess: new_guess}
    end
  end

end
