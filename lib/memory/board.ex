defmodule Memory.Game.Board do

  # 2D is a PITA so we'll just use a 1d array and some indirection
  def new() do
    ["A", "A", "B", "B", "C", "C", "D", "D", "E", "E", "F", "F", "G", "G", "H", "H"]
    |> Enum.shuffle
    |> Enum.map(fn letter -> %{letter: letter, completed: false, visible: false} end)
  end

  def update_tile(tiles, {x, y}, update_map) do
    List.update_at(tiles, 4 * y + x, &(Map.merge(&1, update_map)))
  end

  def same_letter(tiles, {x1, y1}, {x2, y2}) do
    Enum.at(tiles, 4 * y1 + x1) == Enum.at(tiles, 4 * y2 + x2)
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

