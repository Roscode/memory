defmodule Memory.Game.Board do

  # 2D is a PITA so we'll just use a 1d array and some indirection
  def new() do
    ["A", "A", "B", "B", "C", "C", "D", "D", "E", "E", "F", "F", "G", "G", "H", "H"]
    |> Enum.shuffle
    |> Enum.map(fn letter -> %{letter: letter, completed: false, visible: false} end)
  end

  def update_tile(tiles, {x, y}, update_map) do
    List.update_at(tiles, index(x, y), &(Map.merge(&1, update_map)))
  end

  def same_letter(tiles, {x1, y1}, {x2, y2}) do
    %{letter: l1} = Enum.at(tiles, index(x1, y1));
    %{letter: l2} = Enum.at(tiles, index(x2, y2));
    l1 == l2
  end

  def index(x, y) do
    4 * y + x
  end

  def client_view(tiles) do
    {_, result} = List.foldr(tiles, {[], []}, fn (tile, {row, columns}) ->
      if length(row) == 3 do
        {[], [[tile|row]|columns]}
      else
        {[tile|row], columns}
      end
    end)
    result
  end
end

