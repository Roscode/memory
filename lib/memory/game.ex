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

  def winner?(tiles, players) do
    if won_game(tiles) do
      player_keys = Map.keys(players)
      player1_score = Map.fetch(players, hd player_keys)
      player2_score = Map.fetch(players, hd tl player_keys)
      if player1_score > player2_score do
        hd player_keys
      else
        hd tl player_keys
      end
    else
      false
    end
  end

  def client_view(%{tiles: tiles, players: players, turn: t}) do
    %{tiles: Board.client_view(tiles),
      winner: winner?(tiles, players),
      players: players,
      turn: if t do t else false end,
      inProgress: Enum.count(players) > 1}
      |> Jason.encode!
  end

  def add_player(game, user) do
    if Enum.count(game[:players]) < 2 do
      IO.inspect("there are fewer than 2 players")
      new_game = put_in(game, [:players, user], 0)
      if (!game[:turn]) do
        put_in(new_game, [:turn], user)
      else
        new_game
      end
    else
      game
    end
  end

  def next_turn(players, user) do
    player_keys = Map.keys(players)
    IO.inspect(player_keys)
    if ((hd player_keys) == user) do
      hd tl player_keys
    else
      hd player_keys
    end
  end

  def flip(game, new_guess, user) do
    %{tiles: tiles, guesses: guesses, partial_guess: pg, players: players, turn: t} = game
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
    else
      {game, nil}
    end
  end

end
