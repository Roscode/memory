defmodule MemoryWeb.GamesChannel do
  use MemoryWeb, :channel

  alias Memory.Game
  alias Memory.BackupAgent

  def join("games:" <> name, payload, socket) do
    if authorized?(payload) do
      game = BackupAgent.get(name) || Game.new()
      socket = socket
               |> assign(:game, game)
               |> assign(:name, name)
      BackupAgent.put(name, game)
      {:ok, %{"join" => name, "game" => Game.client_view(game)}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("guess", %{"x" => x, "y" => y}, socket) do
    name = socket.assigns[:name]
    {final_game, temp_game} = Game.flip(socket.assigns[:game], {x, y})
    socket = assign(socket, :game, final_game)
    BackupAgent.put(name, final_game)
    temp = !!temp_game
    game = if temp do temp_game else final_game end
    {:reply, {:ok, %{"game" => Game.client_view(game), "temp" => temp}}, socket}
  end

  def handle_in("restart", _, socket) do
    game = Game.new()
    name = socket.assigns[:name]
    socket = assign(socket, :game, game)
    BackupAgent.put(name, game)
    {:reply, {:ok, %{"game" => Game.client_view(game)}}, socket}
  end

  def handle_in("get", _, socket) do
    {:reply, {:ok, %{"game" => Game.client_view(socket.assigns[:game])}}, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
